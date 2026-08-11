import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/training_tools/guided_drill_runner_screen.dart';
import 'package:shooting_companion_training/training.dart';

void main() {
  late AppDatabase database;
  late ShootingRepository repository;
  late DrillDefinitionV2 drill;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ShootingRepository(database);
    drill = BuiltInTrainingContent.catalog.drills.singleWhere(
      (item) => item.id == 'pistol-three-baseline-groups',
    );
  });

  tearDown(() => database.close());

  test('baseline requires three valid executions over two sessions', () async {
    await _storeExecution(
      repository,
      drill: drill,
      index: 0,
      value: 20,
      sessionId: 'session-a',
    );
    await _storeExecution(
      repository,
      drill: drill,
      index: 1,
      value: 30,
      sessionId: 'session-a',
    );
    var activities = await database.select(database.trainingActivities).get();

    var result = DrillRunMeasurementEvaluator.evaluate(
      drill: drill,
      linked: const [],
      activityStartedAtUtc: DateTime.utc(2026, 8, 20),
      historicalActivities: activities,
      completedEvidenceCount: 0,
    );
    expect(result.baselineValue, isNull);
    expect(result.baselineExecutionCount, 2);
    expect(result.baselineSessionCount, 1);

    await _storeExecution(
      repository,
      drill: drill,
      index: 2,
      value: 40,
      sessionId: 'session-b',
    );
    activities = await database.select(database.trainingActivities).get();
    result = DrillRunMeasurementEvaluator.evaluate(
      drill: drill,
      linked: const [],
      activityStartedAtUtc: DateTime.utc(2026, 8, 20),
      historicalActivities: activities,
      completedEvidenceCount: 0,
    );
    expect(result.baselineValue, 30);
    expect(result.baselineExecutionCount, 3);
    expect(result.baselineSessionCount, 2);
  });

  test('baseline is median of at most five most recent executions', () async {
    final values = [999.0, 10.0, 20.0, 30.0, 40.0, 50.0];
    for (var index = 0; index < values.length; index++) {
      await _storeExecution(
        repository,
        drill: drill,
        index: index,
        value: values[index],
        sessionId: index.isEven ? 'session-a' : 'session-b',
      );
    }

    final result = DrillRunMeasurementEvaluator.evaluate(
      drill: drill,
      linked: const [],
      activityStartedAtUtc: DateTime.utc(2026, 8, 20),
      historicalActivities: await database
          .select(database.trainingActivities)
          .get(),
      completedEvidenceCount: 0,
    );

    expect(result.baselineExecutionCount, 5);
    expect(result.baselineValue, 30);
  });

  test(
    'mastery uses two successes inside latest three valid V2 runs',
    () async {
      for (var index = 0; index < 4; index++) {
        await _storeExecution(
          repository,
          drill: drill,
          index: index,
          value: 20 + index.toDouble(),
          sessionId: index.isEven ? 'session-a' : 'session-b',
          success: [false, true, false, true][index],
        );
      }
      await repository.createTrainingActivity(
        id: 'legacy-success-that-must-not-count',
        kind: StoredTrainingActivityKind.drill,
        status: StoredTrainingActivityStatus.completed,
        summary: {
          'drillVersionedId': drill.versionedId,
          'validExecution': true,
          'primaryMeasurementSuccess': true,
          'metricSnapshot': _metricSnapshot(
            drill: drill,
            value: 1,
            sessionId: 'legacy-session',
          ),
        },
        startedAtUtc: DateTime.utc(2026, 8, 10),
        localUtcOffsetMinutes: 120,
        completedAtUtc: DateTime.utc(2026, 8, 10, 0, 10),
      );

      final progress = DrillMasteryEvaluator.evaluate(
        rule: drill.masteryRule,
        drillVersionedId: drill.versionedId,
        activities: await database.select(database.trainingActivities).get(),
        cohort: const {},
      );

      expect(progress.evaluationWindow, 3);
      expect(progress.minimumValidExecutions, 3);
      expect(progress.requiredSuccesses, 2);
      expect(progress.validExecutionsInWindow, 3);
      expect(progress.successesInWindow, 2);
      expect(progress.mastered, isTrue);
    },
  );

  test('mastery excludes completed executions from another cohort', () async {
    const expectedCohort = <String, Object?>{
      'targetProfileVersionedId': 'target-a@1',
      'distanceMeters': 25.0,
      'firearmId': 'firearm-a',
    };
    const otherCohort = <String, Object?>{
      'targetProfileVersionedId': 'target-a@1',
      'distanceMeters': 50.0,
      'firearmId': 'firearm-b',
    };
    for (var index = 0; index < 3; index++) {
      await _storeExecution(
        repository,
        drill: drill,
        index: index,
        value: 20 + index.toDouble(),
        sessionId: index.isEven ? 'session-a' : 'session-b',
        success: index == 0,
        cohort: expectedCohort,
      );
    }
    for (var index = 3; index < 6; index++) {
      await _storeExecution(
        repository,
        drill: drill,
        index: index,
        value: 10,
        sessionId: 'other-session-$index',
        success: true,
        cohort: otherCohort,
      );
    }

    final progress = DrillMasteryEvaluator.evaluate(
      rule: drill.masteryRule,
      drillVersionedId: drill.versionedId,
      activities: await database.select(database.trainingActivities).get(),
      cohort: expectedCohort,
    );

    expect(progress.validExecutionsInWindow, 3);
    expect(progress.successesInWindow, 1);
    expect(progress.mastered, isFalse);
  });

  test('stabilize uses a symmetric band around the baseline', () {
    expect(
      DrillRunMeasurementEvaluator.isWithinStabilityBand(
        current: 95,
        baseline: 100,
        tolerance: 5,
      ),
      isTrue,
    );
    expect(
      DrillRunMeasurementEvaluator.isWithinStabilityBand(
        current: 105,
        baseline: 100,
        tolerance: 5,
      ),
      isTrue,
    );
    expect(
      DrillRunMeasurementEvaluator.isWithinStabilityBand(
        current: 94.9,
        baseline: 100,
        tolerance: 5,
      ),
      isFalse,
    );
    expect(
      DrillRunMeasurementEvaluator.isWithinStabilityBand(
        current: 105.1,
        baseline: 100,
        tolerance: 5,
      ),
      isFalse,
    );
  });
}

Future<void> _storeExecution(
  ShootingRepository repository, {
  required DrillDefinitionV2 drill,
  required int index,
  required double value,
  required String sessionId,
  bool success = true,
  Map<String, Object?> cohort = const {},
}) async {
  final started = DateTime.utc(2026, 8, 1).add(Duration(days: index));
  await repository.createTrainingActivity(
    id: 'execution-$index',
    kind: StoredTrainingActivityKind.guidedDrillV2,
    status: StoredTrainingActivityStatus.completed,
    configuration: {
      'drillVersionedId': drill.versionedId,
      'drill': drill.toJson(),
    },
    summary: {
      'drillVersionedId': drill.versionedId,
      'validExecution': true,
      'primaryMeasurementSuccess': success,
      'metricSnapshot': _metricSnapshot(
        drill: drill,
        value: value,
        sessionId: sessionId,
        cohort: cohort,
      ),
    },
    startedAtUtc: started,
    localUtcOffsetMinutes: 120,
    completedAtUtc: started.add(const Duration(minutes: 10)),
  );
}

Map<String, Object?> _metricSnapshot({
  required DrillDefinitionV2 drill,
  required double value,
  required String sessionId,
  Map<String, Object?> cohort = const {},
}) {
  final measurement = drill.measurements.singleWhere(
    (item) => item.role == TrainingMeasurementRole.primary,
  );
  return {
    'metric': measurement.metric.name,
    'direction': measurement.direction.name,
    'value': value,
    'sampleSize': measurement.minimumSampleSize,
    'minimumSampleSize': measurement.minimumSampleSize,
    'valid': true,
    'success': true,
    'cohort': cohort,
    'sessionIds': [sessionId],
  };
}
