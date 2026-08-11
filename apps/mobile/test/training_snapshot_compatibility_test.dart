import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/training_activity_snapshot_validator.dart';
import 'package:shooting_companion/features/training_tools/drill_plan_screen.dart';
import 'package:shooting_companion_training/training.dart';

void main() {
  late GeneratedDrillPlan plan;
  late DrillDefinitionV2 drill;
  late LearningPathV2 learningPath;

  setUp(() {
    final catalog = BuiltInTrainingContent.catalog;
    plan = const DeterministicDrillPlanner().generate(
      durationMinutes: 30,
      discipline: TrainingDiscipline.precisionPistol,
      skillLevel: TrainingSkillLevel.foundation,
      focus: TrainingPlanFocus.fundamentals,
      ammunitionBudget: 25,
      drills: catalog.drills,
      learningPaths: catalog.learningPaths,
    );
    drill = plan.slots.single.drill;
    learningPath = catalog.learningPaths.first;
  });

  test('current encoded snapshots require valid persisted progress', () {
    final drillValidation = TrainingActivitySnapshotValidator.validateEncoded(
      kind: 'guidedDrillV2',
      activitySchemaVersion: 2,
      configurationJson: jsonEncode({
        'drillVersionedId': drill.versionedId,
        'drill': drill.toJson(),
      }),
      summaryJson: jsonEncode(_emptyDrillSummary(drill)),
      status: 'draft',
    );
    final planValidation = TrainingActivitySnapshotValidator.validateEncoded(
      kind: 'trainingPlan',
      activitySchemaVersion: 1,
      configurationJson: jsonEncode({'planId': plan.id, 'plan': plan.toJson()}),
      summaryJson: jsonEncode(_emptyPlanSummary()),
      status: 'draft',
    );
    final learningValidation =
        TrainingActivitySnapshotValidator.validateEncoded(
          kind: 'learningPathV2',
          activitySchemaVersion: 2,
          configurationJson: jsonEncode({
            'learningPathVersionedId': learningPath.versionedId,
            'learningPath': learningPath.toJson(),
          }),
          summaryJson: jsonEncode({
            'completedEntryIds': <String>[],
            'currentEntryIndex': 0,
          }),
          status: 'draft',
        );

    expect(drillValidation.canResume, isTrue);
    expect(planValidation.canResume, isTrue);
    expect(learningValidation.canResume, isTrue);
  });

  test(
    'learning path entry snapshots are complete, strict and legacy compatible',
    () {
      final entrySnapshots = _learningPathEntrySnapshots(learningPath);
      final complete = TrainingActivitySnapshotValidator.validate(
        kind: 'learningPathV2',
        activitySchemaVersion: 2,
        configuration: {
          'learningPathVersionedId': learningPath.versionedId,
          'learningPath': learningPath.toJson(),
          'entrySnapshots': entrySnapshots,
        },
      );
      final legacy = TrainingActivitySnapshotValidator.validate(
        kind: 'learningPathV2',
        activitySchemaVersion: 2,
        configuration: {
          'learningPathVersionedId': learningPath.versionedId,
          'learningPath': learningPath.toJson(),
        },
      );
      final partial = TrainingActivitySnapshotValidator.validate(
        kind: 'learningPathV2',
        activitySchemaVersion: 2,
        configuration: {
          'learningPathVersionedId': learningPath.versionedId,
          'learningPath': learningPath.toJson(),
          'entrySnapshots': entrySnapshots.take(1).toList(),
        },
      );
      final mismatched = entrySnapshots
          .map((item) => Map<String, Object?>.from(item))
          .toList();
      mismatched.first['versionedContentId'] = 'andere-inhoud@99';
      final wrongIdentity = TrainingActivitySnapshotValidator.validate(
        kind: 'learningPathV2',
        activitySchemaVersion: 2,
        configuration: {
          'learningPathVersionedId': learningPath.versionedId,
          'learningPath': learningPath.toJson(),
          'entrySnapshots': mismatched,
        },
      );

      expect(complete.canResume, isTrue);
      expect(legacy.canResume, isTrue);
      expect(partial.compatibility, TrainingSnapshotCompatibility.invalid);
      expect(
        wrongIdentity.compatibility,
        TrainingSnapshotCompatibility.invalid,
      );
    },
  );

  test('current snapshots reject missing or malformed progress', () {
    final configurationJson = jsonEncode({
      'planId': plan.id,
      'plan': plan.toJson(),
    });
    final missing = TrainingActivitySnapshotValidator.validateEncoded(
      kind: 'trainingPlan',
      activitySchemaVersion: 1,
      configurationJson: configurationJson,
    );
    final malformed = TrainingActivitySnapshotValidator.validateEncoded(
      kind: 'trainingPlan',
      activitySchemaVersion: 1,
      configurationJson: configurationJson,
      summaryJson: jsonEncode({..._emptyPlanSummary(), 'currentStepIndex': 99}),
      status: 'draft',
    );
    final wrongLearningIndex =
        TrainingActivitySnapshotValidator.validateEncoded(
          kind: 'learningPathV2',
          activitySchemaVersion: 2,
          configurationJson: jsonEncode({
            'learningPathVersionedId': learningPath.versionedId,
            'learningPath': learningPath.toJson(),
          }),
          summaryJson: jsonEncode({
            'completedEntryIds': <String>[],
            'currentEntryIndex': 1,
          }),
          status: 'draft',
        );

    expect(missing.compatibility, TrainingSnapshotCompatibility.invalid);
    expect(malformed.compatibility, TrainingSnapshotCompatibility.invalid);
    expect(
      wrongLearningIndex.compatibility,
      TrainingSnapshotCompatibility.invalid,
    );
  });

  test('future activity schemas remain read-only without current progress', () {
    for (final kind in const [
      'guidedDrillV2',
      'trainingPlan',
      'learningPathV2',
    ]) {
      final result = TrainingActivitySnapshotValidator.validateEncoded(
        kind: kind,
        activitySchemaVersion: switch (kind) {
          'trainingPlan' => 2,
          _ => 3,
        },
        configurationJson: const JsonEncoder().convert({'future': true}),
      );
      expect(
        result.compatibility,
        TrainingSnapshotCompatibility.futureReadOnly,
      );
      expect(result.isAcceptedForRestore, isTrue);
      expect(result.canResume, isFalse);
    }
  });

  test('current runtime drill, context and generated plan are resumable', () {
    final context = TrainingPlanContext(
      planActivityId: 'plan-activity',
      planId: plan.id,
      durationMinutes: plan.durationMinutes,
      slotIndex: 0,
      slotCount: plan.slots.length,
      discipline: plan.discipline,
      skillLevel: plan.skillLevel,
    );
    final drillValidation = TrainingActivitySnapshotValidator.validate(
      kind: 'guidedDrillV2',
      activitySchemaVersion: 2,
      configuration: {
        'drillVersionedId': drill.versionedId,
        'drill': drill.toJson(),
        'trainingPlan': context.toJson(),
      },
    );
    final planValidation = TrainingActivitySnapshotValidator.validate(
      kind: 'trainingPlan',
      activitySchemaVersion: 1,
      configuration: {'planId': plan.id, 'plan': plan.toJson()},
    );

    expect(drillValidation.canResume, isTrue);
    expect(planValidation.canResume, isTrue);
    expect(
      TrainingPlanContext.fromJson(context.toJson()).toJson(),
      context.toJson(),
    );
    expect(GeneratedDrillPlan.fromJson(plan.toJson()).toJson(), plan.toJson());
  });

  test('malformed current runtime snapshots are rejected', () {
    final wrongDrillId = TrainingActivitySnapshotValidator.validate(
      kind: 'guidedDrillV2',
      activitySchemaVersion: 2,
      configuration: {'drillVersionedId': 'wrong@99', 'drill': drill.toJson()},
    );
    final malformedPlan = Map<String, Object?>.from(plan.toJson())
      ..remove('steps');
    final wrongPlan = TrainingActivitySnapshotValidator.validate(
      kind: 'trainingPlan',
      activitySchemaVersion: 1,
      configuration: {'planId': plan.id, 'plan': malformedPlan},
    );

    expect(wrongDrillId.compatibility, TrainingSnapshotCompatibility.invalid);
    expect(wrongPlan.compatibility, TrainingSnapshotCompatibility.invalid);
  });

  test('future schema and planner versions are preserved as read-only', () {
    final futureSchema = TrainingActivitySnapshotValidator.validate(
      kind: 'guidedDrillV2',
      activitySchemaVersion: 3,
      configuration: const {'future': true},
    );
    final futurePlanJson = <String, Object?>{
      'plannerVersion': 2,
      'opaqueFuturePlan': true,
    };
    final futurePlan = TrainingActivitySnapshotValidator.validate(
      kind: 'trainingPlan',
      activitySchemaVersion: 1,
      configuration: {'plan': futurePlanJson},
    );

    expect(
      futureSchema.compatibility,
      TrainingSnapshotCompatibility.futureReadOnly,
    );
    expect(futureSchema.isAcceptedForRestore, isTrue);
    expect(futureSchema.canResume, isFalse);
    expect(
      futurePlan.compatibility,
      TrainingSnapshotCompatibility.futureReadOnly,
    );
    expect(futurePlan.isAcceptedForRestore, isTrue);
    expect(futurePlan.canResume, isFalse);
    expect(
      () => GeneratedDrillPlan.fromJson(futurePlanJson),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _emptyDrillSummary(DrillDefinitionV2 drill) => {
  'drillVersionedId': drill.versionedId,
  'setupConfirmed': false,
  'safetyConfirmed': false,
  'acknowledgedPhaseIds': <String>[],
  'timerActivityIds': <String, String>{},
  'phaseReflections': <String, String>{},
};

Map<String, Object?> _emptyPlanSummary() => {
  'completedSlotIndexes': <int>[],
  'completedStepIds': <String>[],
  'guidedDrillActivityIds': <String, String>{},
  'currentStepIndex': 0,
};

List<Map<String, Object?>> _learningPathEntrySnapshots(LearningPathV2 path) {
  final catalog = BuiltInTrainingContent.catalog;
  return path.entries
      .map((entry) {
        final content = switch (entry.kind) {
          LearningPathEntryKind.lesson =>
            catalog.lessonByVersionedId(entry.versionedContentId)!.toJson(),
          LearningPathEntryKind.drill =>
            catalog.drillByVersionedId(entry.versionedContentId)!.toJson(),
        };
        return <String, Object?>{
          'entryId': entry.id,
          'kind': entry.kind.name,
          'versionedContentId': entry.versionedContentId,
          'content': content,
        };
      })
      .toList(growable: false);
}
