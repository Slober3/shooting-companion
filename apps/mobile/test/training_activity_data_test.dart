import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/training_tools/drill_plan_screen.dart';
import 'package:shooting_companion_training/training.dart';

void main() {
  late AppDatabase database;
  late ShootingRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ShootingRepository(database);
    await _seedSessionAndSeries(database);
  });

  tearDown(() => database.close());

  test(
    'completed timer activity, events and link are one transaction',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      final activityId = await repository.saveCompletedTimerActivity(
        id: 'activity-1',
        kind: StoredTrainingActivityKind.acousticLiveFire,
        seriesId: 'series-1',
        configuration: const {
          'mode': 'acousticLiveFire',
          'delayMode': 'random',
        },
        summary: const {
          'countedShotCount': 99,
          'totalTimeMicros': 99000000,
          'actualStartDelayMicros': 750000,
        },
        events: const [
          NewShotTimerEvent(
            id: 'event-1',
            elapsedMicroseconds: 1000000,
            splitMicroseconds: 1000000,
            source: StoredTimerEventSource.acoustic,
            normalizedPeak: 0.8,
          ),
          NewShotTimerEvent(
            id: 'event-2',
            elapsedMicroseconds: 1500000,
            splitMicroseconds: 500000,
            source: StoredTimerEventSource.acoustic,
          ),
        ],
        detectorVersion: 'impulse-v1',
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
        completedAtUtc: started.add(const Duration(seconds: 2)),
      );

      expect(activityId, 'activity-1');
      final detail = await repository.getTrainingActivity(activityId);
      expect(detail, isNotNull);
      expect(detail!.activity.status, 'completed');
      expect(detail.activity.sessionId, 'session-1');
      final storedSummary =
          jsonDecode(detail.activity.summaryJson) as Map<String, dynamic>;
      expect(storedSummary, containsPair('countedShotCount', 2));
      expect(storedSummary, containsPair('firstShotTimeMicros', 1000000));
      expect(storedSummary, containsPair('lastShotTimeMicros', 1500000));
      expect(storedSummary, containsPair('totalTimeMicros', 1500000));
      expect(storedSummary, containsPair('averageSplitMicros', 500000));
      expect(storedSummary, containsPair('actualStartDelayMicros', 750000));
      expect(detail.links.single.seriesId, 'series-1');
      expect(detail.events.map((event) => event.id), ['event-1', 'event-2']);
      expect(detail.events.last.splitMicroseconds, 500000);

      final unchangedSeries = await database
          .select(database.shootingSeries)
          .getSingle();
      expect(unchangedSeries.shotCount, 1);
      expect(unchangedSeries.totalScore, 7);

      // A retry with the same stable activity id is idempotent.
      expect(
        await repository.saveCompletedTimerActivity(
          id: 'activity-1',
          kind: StoredTrainingActivityKind.acousticLiveFire,
          seriesId: 'series-1',
          summary: const {'ignoredRetry': true},
          events: const [],
          startedAtUtc: started,
          localUtcOffsetMinutes: 120,
          completedAtUtc: started.add(const Duration(seconds: 2)),
        ),
        'activity-1',
      );
      expect(
        await database.select(database.trainingActivities).get(),
        hasLength(1),
      );
      expect(
        await database.select(database.shotTimerEvents).get(),
        hasLength(2),
      );
    },
  );

  test('failed series link rolls the complete timer write back', () async {
    final started = DateTime.utc(2026, 8, 5, 10);
    await expectLater(
      repository.saveCompletedTimerActivity(
        id: 'rolled-back',
        kind: StoredTrainingActivityKind.par,
        seriesId: 'missing-series',
        summary: const {},
        events: const [],
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
        completedAtUtc: started.add(const Duration(seconds: 5)),
      ),
      throwsArgumentError,
    );

    expect(await database.select(database.trainingActivities).get(), isEmpty);
    expect(await database.select(database.shotTimerEvents).get(), isEmpty);
  });

  test(
    'series deletion unlinks a run and session deletion removes it',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      await repository.saveCompletedTimerActivity(
        id: 'linked-run',
        kind: StoredTrainingActivityKind.externalManual,
        seriesId: 'series-1',
        summary: const {'totalTimeMicros': 1000000},
        events: const [
          NewShotTimerEvent(
            id: 'manual-event',
            elapsedMicroseconds: 1000000,
            splitMicroseconds: 1000000,
            source: StoredTimerEventSource.external,
          ),
        ],
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
        completedAtUtc: started.add(const Duration(seconds: 1)),
      );

      await (database.delete(
        database.shootingSeries,
      )..where((row) => row.id.equals('series-1'))).go();
      expect(
        await database.select(database.trainingActivities).get(),
        hasLength(1),
      );
      expect(
        await database.select(database.trainingActivitySeriesLinks).get(),
        isEmpty,
      );
      expect(
        await database.select(database.shotTimerEvents).get(),
        hasLength(1),
      );

      await (database.delete(
        database.trainingSessions,
      )..where((row) => row.id.equals('session-1'))).go();
      expect(await database.select(database.trainingActivities).get(), isEmpty);
      expect(await database.select(database.shotTimerEvents).get(), isEmpty);
    },
  );

  test('timer summary is appended without replacing the series note', () async {
    await repository.appendTimerSummaryToSeriesNote(
      'series-1',
      'Timer: 5 schoten · 3,42 s',
    );

    final series = await database.select(database.shootingSeries).getSingle();
    expect(series.notes, 'Bestaande notitie\n\nTimer: 5 schoten · 3,42 s');
    final session = await database
        .select(database.trainingSessions)
        .getSingle();
    expect(session.updatedAtUtc, series.updatedAtUtc);
  });

  test('timer event APIs reject non-timer activities', () async {
    final started = DateTime.utc(2026, 8, 5, 10);
    await repository.createTrainingActivity(
      id: 'drill-1',
      kind: StoredTrainingActivityKind.guidedDrillV2,
      status: StoredTrainingActivityStatus.draft,
      startedAtUtc: started,
      localUtcOffsetMinutes: 120,
    );
    await expectLater(
      repository.completeTrainingActivity(
        activityId: 'drill-1',
        summary: const {},
        events: const [],
        completedAtUtc: started.add(const Duration(seconds: 1)),
      ),
      throwsStateError,
    );
    await expectLater(
      repository.replaceTimerEvents('drill-1', const []),
      throwsStateError,
    );

    await database
        .into(database.shotTimerEvents)
        .insert(
          const ShotTimerEventsCompanion(
            id: Value('invalid-drill-event'),
            activityId: Value('drill-1'),
            sequenceNumber: Value(1),
            elapsedMicroseconds: Value(1000000),
            splitMicroseconds: Value(1000000),
            source: Value('manual'),
            disposition: Value('counted'),
          ),
        );
    await expectLater(
      repository.excludeTimerEvent('invalid-drill-event', 'Test'),
      throwsStateError,
    );
    await expectLater(
      repository.restoreTimerEvent('invalid-drill-event'),
      throwsStateError,
    );
  });

  test('completion derives timer summary from the stored events', () async {
    final started = DateTime.utc(2026, 8, 5, 10);
    final activityId = await repository.createTrainingActivity(
      id: 'draft-timer',
      kind: StoredTrainingActivityKind.externalManual,
      status: StoredTrainingActivityStatus.draft,
      summary: const {'countedShotCount': 40, 'custom': 'behouden'},
      startedAtUtc: started,
      localUtcOffsetMinutes: 120,
    );

    await repository.completeTrainingActivity(
      activityId: activityId,
      summary: const {
        'countedShotCount': 40,
        'totalTimeMicros': 40000000,
        'custom': 'behouden',
      },
      events: const [
        NewShotTimerEvent(
          elapsedMicroseconds: 900000,
          splitMicroseconds: 900000,
          source: StoredTimerEventSource.external,
        ),
        NewShotTimerEvent(
          elapsedMicroseconds: 1400000,
          splitMicroseconds: 500000,
          source: StoredTimerEventSource.external,
        ),
      ],
      completedAtUtc: started.add(const Duration(seconds: 2)),
    );

    final summary =
        jsonDecode(
              (await repository.getTrainingActivity(
                activityId,
              ))!.activity.summaryJson,
            )
            as Map<String, dynamic>;
    expect(summary, containsPair('countedShotCount', 2));
    expect(summary, containsPair('firstShotTimeMicros', 900000));
    expect(summary, containsPair('lastShotTimeMicros', 1400000));
    expect(summary, containsPair('totalTimeMicros', 1400000));
    expect(summary, containsPair('averageSplitMicros', 500000));
    expect(summary, containsPair('custom', 'behouden'));
  });

  test('excluded events do not change counted split semantics', () async {
    final started = DateTime.utc(2026, 8, 5, 10);
    await repository.saveCompletedTimerActivity(
      id: 'excluded-middle',
      kind: StoredTrainingActivityKind.acousticLiveFire,
      summary: const {'countedShotCount': 2},
      events: const [
        NewShotTimerEvent(
          id: 'counted-1',
          elapsedMicroseconds: 1000000,
          splitMicroseconds: 1000000,
          source: StoredTimerEventSource.acoustic,
        ),
        NewShotTimerEvent(
          id: 'excluded-2',
          elapsedMicroseconds: 1500000,
          splitMicroseconds: 500000,
          source: StoredTimerEventSource.acoustic,
          disposition: StoredTimerEventDisposition.excluded,
          exclusionReason: 'Mogelijke echo',
        ),
        NewShotTimerEvent(
          id: 'counted-3',
          elapsedMicroseconds: 2000000,
          splitMicroseconds: 1000000,
          source: StoredTimerEventSource.acoustic,
        ),
      ],
      startedAtUtc: started,
      localUtcOffsetMinutes: 120,
      completedAtUtc: started.add(const Duration(seconds: 3)),
    );

    final detail = await repository.getTrainingActivity('excluded-middle');
    expect(detail!.events, hasLength(3));
    final summary = jsonDecode(detail.activity.summaryJson) as Map;
    expect(summary['countedShotCount'], 2);
    expect(summary['averageSplitMicros'], 1000000);
    expect(summary['totalTimeMicros'], 2000000);
  });

  test('empty par run preserves its signal duration', () async {
    final started = DateTime.utc(2026, 8, 5, 10);
    await repository.saveCompletedTimerActivity(
      id: 'par-run',
      kind: StoredTrainingActivityKind.par,
      summary: const {'countedShotCount': 0, 'totalTimeMicros': 6200000},
      events: const [],
      startedAtUtc: started,
      localUtcOffsetMinutes: 120,
      completedAtUtc: started.add(const Duration(seconds: 7)),
    );

    final summary =
        jsonDecode(
              (await repository.getTrainingActivity(
                'par-run',
              ))!.activity.summaryJson,
            )
            as Map;
    expect(summary['countedShotCount'], 0);
    expect(summary['totalTimeMicros'], 6200000);
  });

  test('event-free external result preserves entered timing summary', () async {
    final started = DateTime.utc(2026, 8, 5, 10);
    await repository.saveCompletedTimerActivity(
      id: 'external-summary-only',
      kind: StoredTrainingActivityKind.externalManual,
      summary: const {
        'countedShotCount': null,
        'firstShotTimeMicros': 1140000,
        'lastShotTimeMicros': 4720000,
        'totalTimeMicros': 4720000,
        'fastestSplitMicros': null,
        'slowestSplitMicros': null,
        'averageSplitMicros': null,
        'splitStandardDeviationMicros': null,
        'qualityWarnings': ['Geen afzonderlijke splits ingevoerd'],
        'externalTimingCompleteness': 'summaryOnly',
        'shotCountKnown': false,
        'userEdited': true,
      },
      events: const [],
      startedAtUtc: started,
      localUtcOffsetMinutes: 120,
      completedAtUtc: started.add(const Duration(seconds: 5)),
    );

    final detail = await repository.getTrainingActivity(
      'external-summary-only',
    );
    final summary =
        jsonDecode(detail!.activity.summaryJson) as Map<String, dynamic>;
    expect(detail.events, isEmpty);
    expect(summary['countedShotCount'], isNull);
    expect(summary, containsPair('firstShotTimeMicros', 1140000));
    expect(summary, containsPair('lastShotTimeMicros', 4720000));
    expect(summary, containsPair('totalTimeMicros', 4720000));
    expect(summary['averageSplitMicros'], isNull);
    expect(summary, containsPair('externalTimingCompleteness', 'summaryOnly'));
    expect(summary, containsPair('shotCountKnown', false));
  });

  test('event review mutations atomically refresh the timer summary', () async {
    final started = DateTime.utc(2026, 8, 5, 10);
    await repository.saveCompletedTimerActivity(
      id: 'reviewed-run',
      kind: StoredTrainingActivityKind.acousticLiveFire,
      summary: const {
        'countedShotCount': 3,
        'actualStartDelayMicros': 750000,
        'firstShotTimeMicros': 1000000,
        'lastShotTimeMicros': 2500000,
        'totalTimeMicros': 2500000,
        'fastestSplitMicros': 500000,
        'slowestSplitMicros': 1000000,
        'averageSplitMicros': 750000,
        'splitStandardDeviationMicros': 353553,
        'qualityWarnings': ['Mogelijke echo'],
        'userEdited': false,
      },
      events: const [
        NewShotTimerEvent(
          id: 'review-event-1',
          elapsedMicroseconds: 1000000,
          splitMicroseconds: 1000000,
          source: StoredTimerEventSource.acoustic,
        ),
        NewShotTimerEvent(
          id: 'review-event-2',
          elapsedMicroseconds: 1500000,
          splitMicroseconds: 500000,
          source: StoredTimerEventSource.acoustic,
        ),
        NewShotTimerEvent(
          id: 'review-event-3',
          elapsedMicroseconds: 2500000,
          splitMicroseconds: 1000000,
          source: StoredTimerEventSource.acoustic,
        ),
      ],
      startedAtUtc: started,
      localUtcOffsetMinutes: 120,
      completedAtUtc: started.add(const Duration(seconds: 3)),
    );

    await repository.excludeTimerEvent('review-event-2', 'Mogelijke echo');
    var summary =
        jsonDecode(
              (await repository.getTrainingActivity(
                'reviewed-run',
              ))!.activity.summaryJson,
            )
            as Map<String, dynamic>;
    expect(summary, containsPair('countedShotCount', 2));
    expect(summary, containsPair('firstShotTimeMicros', 1000000));
    expect(summary, containsPair('lastShotTimeMicros', 2500000));
    expect(summary, containsPair('totalTimeMicros', 2500000));
    expect(summary, containsPair('fastestSplitMicros', 1500000));
    expect(summary, containsPair('slowestSplitMicros', 1500000));
    expect(summary, containsPair('averageSplitMicros', 1500000));
    expect(summary['splitStandardDeviationMicros'], isNull);
    expect(summary, containsPair('actualStartDelayMicros', 750000));
    expect(summary['qualityWarnings'], ['Mogelijke echo']);
    expect(summary, containsPair('userEdited', true));
    var storedEvents =
        await (database.select(database.shotTimerEvents)
              ..where((row) => row.activityId.equals('reviewed-run'))
              ..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)]))
            .get();
    expect(storedEvents.map((event) => event.sequenceNumber), [1, 2, 3]);
    expect(storedEvents.map((event) => event.elapsedMicroseconds), [
      1000000,
      1500000,
      2500000,
    ]);
    expect(storedEvents.map((event) => event.disposition), [
      'counted',
      'excluded',
      'counted',
    ]);
    expect(storedEvents.map((event) => event.splitMicroseconds), [
      1000000,
      500000,
      1500000,
    ]);

    await repository.restoreTimerEvent('review-event-2');
    summary =
        jsonDecode(
              (await repository.getTrainingActivity(
                'reviewed-run',
              ))!.activity.summaryJson,
            )
            as Map<String, dynamic>;
    expect(summary, containsPair('countedShotCount', 3));
    expect(summary, containsPair('fastestSplitMicros', 500000));
    expect(summary, containsPair('slowestSplitMicros', 1000000));
    expect(summary, containsPair('averageSplitMicros', 750000));
    expect(summary, containsPair('splitStandardDeviationMicros', 353553));
    storedEvents =
        await (database.select(database.shotTimerEvents)
              ..where((row) => row.activityId.equals('reviewed-run'))
              ..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)]))
            .get();
    expect(storedEvents.map((event) => event.disposition), [
      'counted',
      'counted',
      'counted',
    ]);
    expect(storedEvents.map((event) => event.splitMicroseconds), [
      1000000,
      500000,
      1000000,
    ]);

    await repository.replaceTimerEvents('reviewed-run', const [
      NewShotTimerEvent(
        id: 'replacement-1',
        elapsedMicroseconds: 1200000,
        splitMicroseconds: 1200000,
        source: StoredTimerEventSource.manual,
      ),
      NewShotTimerEvent(
        id: 'replacement-2',
        elapsedMicroseconds: 2000000,
        splitMicroseconds: 800000,
        source: StoredTimerEventSource.manual,
      ),
    ]);
    final replacedSummary =
        jsonDecode(
              (await repository.getTrainingActivity(
                'reviewed-run',
              ))!.activity.summaryJson,
            )
            as Map<String, dynamic>;
    expect(replacedSummary, containsPair('countedShotCount', 2));
    expect(replacedSummary, containsPair('firstShotTimeMicros', 1200000));
    expect(replacedSummary, containsPair('lastShotTimeMicros', 2000000));
    expect(replacedSummary, containsPair('totalTimeMicros', 2000000));
    expect(replacedSummary, containsPair('averageSplitMicros', 800000));
  });

  test('default seeding creates readable built-in timer presets', () async {
    await repository.seedDefaults();
    await repository.seedDefaults();

    final presets = await database.select(database.timerPresets).get();
    expect(presets, hasLength(3));
    expect(presets.every((preset) => preset.builtIn), isTrue);
    expect(presets.map((preset) => preset.mode).toSet(), {
      'acousticLiveFire',
      'par',
      'cadence',
    });
    expect(
      presets.every((preset) => jsonDecode(preset.configurationJson) is Map),
      isTrue,
    );
  });

  test('drill progress survives interruption and resume', () async {
    final started = DateTime.utc(2026, 8, 5, 10);
    final fixture = _runtimeTrainingFixture();
    await repository.createTrainingActivity(
      id: 'drill-resume',
      kind: StoredTrainingActivityKind.guidedDrillV2,
      activitySchemaVersion: 2,
      status: StoredTrainingActivityStatus.draft,
      configuration: {
        'drillVersionedId': fixture.drill.versionedId,
        'drill': fixture.drill.toJson(),
      },
      summary: const {'currentPhaseIndex': 1},
      startedAtUtc: started,
      localUtcOffsetMinutes: 120,
    );

    await repository.updateDrillActivityProgress(
      activityId: 'drill-resume',
      summary: const {'currentPhaseIndex': 2, 'setupConfirmed': true},
    );
    await repository.interruptTrainingActivity(
      activityId: 'drill-resume',
      summary: const {'currentPhaseIndex': 2, 'setupConfirmed': true},
    );

    var detail = await repository.getTrainingActivity('drill-resume');
    expect(detail!.activity.status, 'interrupted');
    expect(
      jsonDecode(detail.activity.summaryJson),
      containsPair('currentPhaseIndex', 2),
    );
    expect(
      (await repository.watchResumableDrillActivities().first).map(
        (item) => item.id,
      ),
      contains('drill-resume'),
    );

    await repository.resumeDrillActivity('drill-resume');
    detail = await repository.getTrainingActivity('drill-resume');
    expect(detail!.activity.status, 'draft');
    expect(detail.activity.completedAtUtc, isNull);
    expect(
      jsonDecode(detail.activity.configurationJson),
      containsPair('drillVersionedId', fixture.drill.versionedId),
    );
  });

  test(
    'drill links only confirmed series and duplicate link is idempotent',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      await repository.createTrainingActivity(
        id: 'drill-links',
        kind: StoredTrainingActivityKind.guidedDrillV2,
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await database
          .into(database.shootingSeries)
          .insert(
            ShootingSeriesCompanion.insert(
              id: 'draft-series',
              sessionId: 'session-1',
              sequenceNumber: 2,
              status: 'draft',
              targetProfileVersionedId: 'test@1',
              targetProfileJson:
                  '{"displayName":"Testkaart","rings":[{"value":10}]}',
              distanceMeters: 25,
              projectileDiameterMm: 5.6,
              createdAtUtc: started,
              updatedAtUtc: started,
            ),
          );

      await expectLater(
        repository.linkConfirmedSeriesToDrillActivity(
          'drill-links',
          'draft-series',
        ),
        throwsStateError,
      );
      await repository.linkConfirmedSeriesToDrillActivity(
        'drill-links',
        'series-1',
        role: 'baseline',
      );
      await repository.linkConfirmedSeriesToDrillActivity(
        'drill-links',
        'series-1',
        role: 'baseline',
      );

      final detail = await repository.getTrainingActivity('drill-links');
      expect(detail!.links, hasLength(1));
      expect(detail.links.single.seriesId, 'series-1');
      expect(detail.links.single.role, 'baseline');
      expect(detail.activity.sessionId, 'session-1');
    },
  );

  test('drill completion requires its real confirmed-series minimum', () async {
    final started = DateTime.utc(2026, 8, 5, 10);
    final fixture = _runtimeTrainingFixture();
    await repository.createTrainingActivity(
      id: 'drill-complete',
      kind: StoredTrainingActivityKind.guidedDrillV2,
      activitySchemaVersion: 2,
      configuration: {
        'drillVersionedId': fixture.drill.versionedId,
        'drill': fixture.drill.toJson(),
      },
      summary: _guidedProgressSummary(fixture.drill),
      startedAtUtc: started,
      localUtcOffsetMinutes: 120,
    );
    final timerActivityIds = <String, String>{};
    for (final phase in fixture.drill.phases.where(
      (phase) => phase.completionKind == DrillPhaseCompletionKind.timerActivity,
    )) {
      final timerId = 'completion-timer-${phase.id}';
      await repository.createTrainingActivity(
        id: timerId,
        kind: StoredTrainingActivityKind.par,
        status: StoredTrainingActivityStatus.completed,
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
        completedAtUtc: started.add(const Duration(seconds: 5)),
      );
      timerActivityIds[phase.id] = timerId;
    }

    await expectLater(
      repository.completeDrillActivity(
        activityId: 'drill-complete',
        summary: _completedGuidedSummary(
          fixture.drill,
          timerActivityIds: timerActivityIds,
          linkedSeriesCount: 0,
        ),
        completedAtUtc: started.add(const Duration(minutes: 10)),
        minimumLinkedSeries: 1,
      ),
      throwsStateError,
    );
    expect(
      (await repository.getTrainingActivity('drill-complete'))!.activity.status,
      'draft',
    );

    await repository.linkConfirmedSeriesToDrillActivity(
      'drill-complete',
      'series-1',
    );
    await repository.completeDrillActivity(
      activityId: 'drill-complete',
      summary: _completedGuidedSummary(
        fixture.drill,
        timerActivityIds: timerActivityIds,
        linkedSeriesCount: 1,
      ),
      completedAtUtc: started.add(const Duration(minutes: 10)),
      minimumLinkedSeries: 1,
    );
    // A repeated completion tap is explicitly idempotent.
    await repository.completeDrillActivity(
      activityId: 'drill-complete',
      summary: const {'ignoredRetry': true},
      completedAtUtc: started.add(const Duration(minutes: 11)),
      minimumLinkedSeries: 1,
    );

    final detail = await repository.getTrainingActivity('drill-complete');
    expect(detail!.activity.status, 'completed');
    expect(
      jsonDecode(detail.activity.summaryJson),
      containsPair('linkedSeriesCount', 1),
    );
  });

  test(
    'training plan persists exact progress and resumes after interruption',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      final fixture = _runtimeTrainingFixture();
      await repository.createTrainingActivity(
        id: 'plan-resume',
        kind: StoredTrainingActivityKind.trainingPlan,
        configuration: {
          'planId': fixture.plan.id,
          'plan': fixture.plan.toJson(),
        },
        summary: _emptyPlanSummary(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await repository.interruptTrainingActivity(
        activityId: 'plan-resume',
        summary: {
          ..._emptyPlanSummary(),
          'completedStepIds': [fixture.plan.steps.first.id],
          'currentStepIndex': 1,
        },
      );

      var detail = await repository.getTrainingActivity('plan-resume');
      expect(detail!.activity.status, 'interrupted');
      expect(
        jsonDecode(detail.activity.summaryJson),
        containsPair('currentStepIndex', 1),
      );
      expect(
        (await repository.watchResumableTrainingPlans().first).single.id,
        'plan-resume',
      );
      expect(
        (await repository.watchActiveTrainingPlan().first)!.id,
        'plan-resume',
      );

      await repository.resumeTrainingPlan('plan-resume');
      detail = await repository.getTrainingActivity('plan-resume');
      expect(detail!.activity.status, 'draft');
      expect(
        jsonDecode(detail.activity.summaryJson),
        containsPair('completedStepIds', [fixture.plan.steps.first.id]),
      );
      expect(
        jsonDecode(detail.activity.configurationJson),
        containsPair('planId', fixture.plan.id),
      );
    },
  );

  test(
    'active plan stream fails closed for corrupted duplicate drafts',
    () async {
      final fixture = _runtimeTrainingFixture();
      final started = DateTime.utc(2026, 8, 5, 10);
      await repository.createTrainingPlanActivity(
        configuration: _planConfiguration(fixture.plan),
        summary: _emptyPlanSummary(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      final now = DateTime.now().toUtc();
      await database
          .into(database.trainingActivities)
          .insert(
            TrainingActivitiesCompanion.insert(
              id: 'corrupt-second-plan',
              kind: StoredTrainingActivityKind.trainingPlan.name,
              schemaVersion: const Value(1),
              status: StoredTrainingActivityStatus.draft.name,
              configurationJson: jsonEncode(_planConfiguration(fixture.plan)),
              summaryJson: jsonEncode(_emptyPlanSummary()),
              startedAtUtc: started.add(const Duration(minutes: 1)),
              localUtcOffsetMinutes: 120,
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );

      await expectLater(
        repository.watchActiveTrainingPlan().first,
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'plan and guided drill share one confirmed series idempotently',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      final fixture = _runtimeTrainingFixture();
      await repository.createTrainingActivity(
        id: 'plan-links',
        kind: StoredTrainingActivityKind.trainingPlan,
        configuration: _planConfiguration(fixture.plan),
        summary: _emptyPlanSummary(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      final guidedId = await repository.findOrCreateGuidedDrillSlot(
        planActivityId: 'plan-links',
        slotIndex: 0,
        drillVersionedId: fixture.drill.versionedId,
        drillSnapshot: fixture.drill.toJson(),
        trainingPlanContext: _planContext('plan-links', fixture.plan),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );

      for (var retry = 0; retry < 2; retry++) {
        await repository.linkConfirmedSeriesToGuidedDrill(
          drillActivityId: guidedId,
          seriesId: 'series-1',
          drillRole: 'phase-1',
          planActivityId: 'plan-links',
          planRole: 'slot:0:phase-1',
          variantId: fixture.drill.versionedId,
        );
      }

      expect(
        (await repository.getTrainingActivity(guidedId))!.links,
        hasLength(1),
      );
      final plan = await repository.getTrainingActivity('plan-links');
      expect(plan!.links, hasLength(1));
      expect(plan.activity.sessionId, 'session-1');
      expect(plan.links.single.variantId, fixture.drill.versionedId);

      await repository.unlinkConfirmedSeriesFromGuidedDrill(
        drillActivityId: guidedId,
        seriesId: 'series-1',
      );
      expect((await repository.getTrainingActivity(guidedId))!.links, isEmpty);
      expect(
        (await repository.getTrainingActivity('plan-links'))!.links,
        isEmpty,
      );
    },
  );

  test(
    'combined drill/plan link rolls back when its plan is invalid',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      final fixture = _runtimeTrainingFixture();
      await repository.createTrainingActivity(
        id: 'atomic-guided-slot',
        kind: StoredTrainingActivityKind.guidedDrillV2,
        activitySchemaVersion: 2,
        configuration: {
          'drillVersionedId': fixture.drill.versionedId,
          'drill': fixture.drill.toJson(),
        },
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );

      await expectLater(
        repository.linkConfirmedSeriesToGuidedDrill(
          drillActivityId: 'atomic-guided-slot',
          seriesId: 'series-1',
          drillRole: 'phase-1',
          planActivityId: 'missing-plan',
          planRole: 'slot:0:phase-1',
        ),
        throwsArgumentError,
      );

      expect(
        (await repository.getTrainingActivity('atomic-guided-slot'))!.links,
        isEmpty,
      );
    },
  );

  test(
    'guided completion records its slot but plan awaits every explicit step',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      final fixture = _runtimeTrainingFixture();
      await repository.createTrainingActivity(
        id: 'single-slot-plan',
        kind: StoredTrainingActivityKind.trainingPlan,
        configuration: _planConfiguration(fixture.plan),
        summary: _emptyPlanSummary(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      final guidedId = await repository.findOrCreateGuidedDrillSlot(
        planActivityId: 'single-slot-plan',
        slotIndex: 0,
        drillVersionedId: fixture.drill.versionedId,
        drillSnapshot: fixture.drill.toJson(),
        trainingPlanContext: _planContext('single-slot-plan', fixture.plan),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await repository.linkConfirmedSeriesToGuidedDrill(
        drillActivityId: guidedId,
        seriesId: 'series-1',
        drillRole: 'phase-1',
        planActivityId: 'single-slot-plan',
        planRole: 'slot:0:phase-1',
        variantId: fixture.drill.versionedId,
      );
      final timerActivityIds = <String, String>{};
      for (final phase in fixture.drill.phases.where(
        (phase) =>
            phase.completionKind == DrillPhaseCompletionKind.timerActivity,
      )) {
        final timerId = 'single-slot-timer-${phase.id}';
        await repository.createTrainingActivity(
          id: timerId,
          kind: StoredTrainingActivityKind.par,
          status: StoredTrainingActivityStatus.completed,
          startedAtUtc: started,
          localUtcOffsetMinutes: 120,
          completedAtUtc: started.add(const Duration(seconds: 5)),
        );
        timerActivityIds[phase.id] = timerId;
      }

      for (var retry = 0; retry < 2; retry++) {
        await repository.completeGuidedDrillActivity(
          activityId: guidedId,
          summary: _completedGuidedSummary(
            fixture.drill,
            timerActivityIds: timerActivityIds,
            linkedSeriesCount: 1,
          ),
          completedAtUtc: started.add(const Duration(minutes: 10)),
          minimumLinkedSeries: 1,
        );
      }

      var detail = await repository.getTrainingActivity('single-slot-plan');
      expect(detail!.activity.status, 'draft');
      var summary = jsonDecode(detail.activity.summaryJson) as Map;
      expect(summary['completedSlotIndexes'], [0]);
      expect(summary['guidedDrillActivityIds'], {'0': guidedId});

      await expectLater(
        repository.completeTrainingPlan(
          activityId: 'single-slot-plan',
          summary: summary.cast<String, Object?>(),
          completedAtUtc: started.add(const Duration(minutes: 11)),
        ),
        throwsStateError,
      );
      summary = {
        ...summary,
        'completedStepIds': fixture.plan.steps
            .map((step) => step.id)
            .toList(growable: false),
        'currentStepIndex': fixture.plan.steps.length - 1,
        'finalReflection': 'Veilig uitgevoerd; volgende keer dezelfde opbouw.',
      };
      await repository.completeTrainingPlan(
        activityId: 'single-slot-plan',
        summary: summary.cast<String, Object?>(),
        completedAtUtc: started.add(const Duration(minutes: 12)),
      );
      detail = await repository.getTrainingActivity('single-slot-plan');
      expect(detail!.activity.status, 'completed');
    },
  );

  test(
    'plan creation is singleton and guided slot creation is idempotent',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      final fixture = _runtimeTrainingFixture();
      final planId = await repository.createTrainingPlanActivity(
        configuration: _planConfiguration(fixture.plan),
        summary: _emptyPlanSummary(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await expectLater(
        repository.createTrainingPlanActivity(
          configuration: _planConfiguration(fixture.plan),
          summary: _emptyPlanSummary(),
          startedAtUtc: started,
          localUtcOffsetMinutes: 120,
        ),
        throwsStateError,
      );

      final ids = <String>{};
      for (var retry = 0; retry < 2; retry++) {
        ids.add(
          await repository.findOrCreateGuidedDrillSlot(
            planActivityId: planId,
            slotIndex: 0,
            drillVersionedId: fixture.drill.versionedId,
            drillSnapshot: fixture.drill.toJson(),
            trainingPlanContext: _planContext(planId, fixture.plan),
            startedAtUtc: started,
            localUtcOffsetMinutes: 120,
          ),
        );
      }
      expect(ids, hasLength(1));
      expect(
        await repository
            .watchTrainingActivities(
              const TrainingActivityFilters(
                kind: StoredTrainingActivityKind.guidedDrillV2,
              ),
            )
            .first,
        hasLength(1),
      );
    },
  );

  test(
    'stored plan snapshot rejects spoofed slot, count and drill version',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      final fixture = _runtimeTrainingFixture();
      await repository.createTrainingActivity(
        id: 'binding-plan',
        kind: StoredTrainingActivityKind.trainingPlan,
        configuration: _planConfiguration(fixture.plan),
        summary: _emptyPlanSummary(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );

      for (final invalidContext in [
        {..._planContext('binding-plan', fixture.plan), 'slotIndex': 9},
        {..._planContext('binding-plan', fixture.plan), 'slotCount': 99},
      ]) {
        await expectLater(
          repository.findOrCreateGuidedDrillSlot(
            planActivityId: 'binding-plan',
            slotIndex: 0,
            drillVersionedId: fixture.drill.versionedId,
            drillSnapshot: fixture.drill.toJson(),
            trainingPlanContext: invalidContext,
            startedAtUtc: started,
            localUtcOffsetMinutes: 120,
          ),
          throwsStateError,
        );
      }
      await expectLater(
        repository.findOrCreateGuidedDrillSlot(
          planActivityId: 'binding-plan',
          slotIndex: 0,
          drillVersionedId: 'unrelated@99',
          drillSnapshot: fixture.drill.toJson(),
          trainingPlanContext: _planContext('binding-plan', fixture.plan),
          startedAtUtc: started,
          localUtcOffsetMinutes: 120,
        ),
        throwsStateError,
      );
      expect(
        await repository
            .watchTrainingActivities(
              const TrainingActivityFilters(
                kind: StoredTrainingActivityKind.guidedDrillV2,
              ),
            )
            .first,
        isEmpty,
      );
    },
  );

  test(
    'planned drill completion rolls back when plan binding is corrupted',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      final fixture = _runtimeTrainingFixture();
      await repository.createTrainingActivity(
        id: 'rollback-plan',
        kind: StoredTrainingActivityKind.trainingPlan,
        configuration: _planConfiguration(fixture.plan),
        summary: _emptyPlanSummary(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      final guidedId = await repository.findOrCreateGuidedDrillSlot(
        planActivityId: 'rollback-plan',
        slotIndex: 0,
        drillVersionedId: fixture.drill.versionedId,
        drillSnapshot: fixture.drill.toJson(),
        trainingPlanContext: _planContext('rollback-plan', fixture.plan),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await (database.update(
        database.trainingActivities,
      )..where((row) => row.id.equals('rollback-plan'))).write(
        const TrainingActivitiesCompanion(
          configurationJson: Value('{"planId":"broken","plan":{}}'),
        ),
      );

      await expectLater(
        repository.completeGuidedDrillActivity(
          activityId: guidedId,
          summary: const {'validExecution': true},
          completedAtUtc: started.add(const Duration(minutes: 10)),
          minimumLinkedSeries: 0,
        ),
        throwsStateError,
      );
      expect(
        (await repository.getTrainingActivity(guidedId))!.activity.status,
        StoredTrainingActivityStatus.draft.name,
      );
    },
  );

  test('unrelated completed drill cannot fill a stored plan slot', () async {
    final started = DateTime.utc(2026, 8, 5, 10);
    final fixture = _runtimeTrainingFixture();
    await repository.createTrainingActivity(
      id: 'unrelated-plan',
      kind: StoredTrainingActivityKind.trainingPlan,
      configuration: _planConfiguration(fixture.plan),
      summary: _emptyPlanSummary(),
      startedAtUtc: started,
      localUtcOffsetMinutes: 120,
    );
    await repository.createTrainingActivity(
      id: 'unrelated-drill',
      kind: StoredTrainingActivityKind.guidedDrillV2,
      activitySchemaVersion: 2,
      status: StoredTrainingActivityStatus.completed,
      configuration: {
        'drillVersionedId': fixture.drill.versionedId,
        'drill': fixture.drill.toJson(),
      },
      summary: const {'validExecution': true},
      startedAtUtc: started,
      localUtcOffsetMinutes: 120,
      completedAtUtc: started.add(const Duration(minutes: 10)),
    );
    await expectLater(
      repository.recordCompletedDrillInTrainingPlan(
        activityId: 'unrelated-plan',
        slotIndex: 0,
        slotCount: fixture.plan.slots.length,
        guidedDrillActivityId: 'unrelated-drill',
        completedAtUtc: started.add(const Duration(minutes: 10)),
      ),
      throwsStateError,
    );
    final summary =
        jsonDecode(
              (await repository.getTrainingActivity(
                'unrelated-plan',
              ))!.activity.summaryJson,
            )
            as Map;
    expect(summary['completedSlotIndexes'], isEmpty);
  });

  test(
    'overview keeps V1 read-only and exposes V2/plan resume centrally',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      final fixture = _runtimeTrainingFixture();
      await repository.createTrainingActivity(
        id: 'legacy-drill',
        kind: StoredTrainingActivityKind.drill,
        configuration: const {
          'drillVersionedId': 'legacy@1',
          'drill': {'name': 'Oude checkboxdrill'},
        },
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await repository.createTrainingActivity(
        id: 'v2-drill',
        kind: StoredTrainingActivityKind.guidedDrillV2,
        activitySchemaVersion: 2,
        configuration: {
          'drillVersionedId': fixture.drill.versionedId,
          'drill': fixture.drill.toJson(),
        },
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await repository.createTrainingActivity(
        id: 'v2-plan',
        kind: StoredTrainingActivityKind.trainingPlan,
        configuration: {
          'planId': fixture.plan.id,
          'plan': fixture.plan.toJson(),
        },
        summary: _emptyPlanSummary(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await repository.createTrainingActivity(
        id: 'future-drill',
        kind: StoredTrainingActivityKind.guidedDrillV2,
        activitySchemaVersion: 3,
        configuration: const {'futureSnapshot': true},
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await repository.createTrainingActivity(
        id: 'future-plan',
        kind: StoredTrainingActivityKind.trainingPlan,
        configuration: const {
          'planId': 'future-plan',
          'plan': {'id': 'future-plan', 'plannerVersion': 2},
        },
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );

      final overview = {
        for (final item
            in await repository.watchGuidedTrainingActivityOverviews().first)
          item.activity.id: item,
      };
      expect(overview['legacy-drill']!.isLegacyReadOnly, isTrue);
      expect(overview['legacy-drill']!.canResume, isFalse);
      expect(overview['v2-drill']!.canResume, isTrue);
      expect(overview['v2-drill']!.title, fixture.drill.title);
      expect(overview['v2-plan']!.isTrainingPlan, isTrue);
      expect(overview['v2-plan']!.canResume, isTrue);
      expect(overview['future-drill']!.canResume, isFalse);
      expect(overview['future-plan']!.canResume, isFalse);
      expect(
        (await repository.watchResumableDrillActivities().first).map(
          (activity) => activity.id,
        ),
        contains('v2-drill'),
      );
      expect(
        (await repository.watchResumableDrillActivities().first).map(
          (activity) => activity.id,
        ),
        isNot(contains('future-drill')),
      );
      expect(
        (await repository.watchResumableTrainingPlans().first).map(
          (activity) => activity.id,
        ),
        contains('v2-plan'),
      );
      expect(
        (await repository.watchResumableTrainingPlans().first).map(
          (activity) => activity.id,
        ),
        isNot(contains('future-plan')),
      );
    },
  );

  test(
    'learning path start is idempotent and resumes its immutable snapshot',
    () async {
      final path = BuiltInTrainingContent.catalog.learningPaths.first;
      final started = DateTime.utc(2026, 8, 10, 10);
      final firstId = await repository.startLearningPathActivity(
        learningPathVersionedId: path.versionedId,
        learningPathSnapshot: path.toJson(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      final retriedId = await repository.startLearningPathActivity(
        learningPathVersionedId: path.versionedId,
        learningPathSnapshot: path.toJson(),
        startedAtUtc: started.add(const Duration(seconds: 1)),
        localUtcOffsetMinutes: 120,
      );
      expect(retriedId, firstId);
      final startedOverviews = await repository
          .watchLearningPathActivityOverviews()
          .first;
      expect(startedOverviews, hasLength(1));
      final startedOverview = startedOverviews.single;
      final rawEntrySnapshots = startedOverview.configuration['entrySnapshots'];
      expect(rawEntrySnapshots, isA<List<Object?>>());
      expect(rawEntrySnapshots as List, hasLength(path.entries.length));
      expect(startedOverview.hasCompleteEntrySnapshots, isTrue);
      for (final entry in path.entries) {
        switch (entry.kind) {
          case LearningPathEntryKind.lesson:
            expect(
              startedOverview.lessonSnapshotsByEntryId[entry.id]?.versionedId,
              entry.versionedContentId,
            );
          case LearningPathEntryKind.drill:
            expect(
              startedOverview.drillSnapshotsByEntryId[entry.id]?.versionedId,
              entry.versionedContentId,
            );
        }
      }

      final lessonId = path.entries
          .firstWhere((entry) => entry.kind == LearningPathEntryKind.lesson)
          .id;
      await repository.updateLearningPathProgress(
        activityId: firstId,
        completedEntryIds: [lessonId],
      );
      await repository.interruptLearningPath(activityId: firstId);
      var active = await repository.watchActiveLearningPath().first;
      expect(active!.activity.status, 'interrupted');
      expect(active.completedEntryIds, contains(lessonId));
      expect(active.configuration['learningPath'], equals(path.toJson()));

      await repository.resumeLearningPath(firstId);
      active = await repository.watchActiveLearningPath().first;
      expect(active!.activity.status, 'draft');
      expect(active.completedEntryIds, contains(lessonId));
      await expectLater(
        repository.startLearningPathActivity(
          learningPathVersionedId:
              BuiltInTrainingContent.catalog.learningPaths.last.versionedId,
          learningPathSnapshot: BuiltInTrainingContent
              .catalog
              .learningPaths
              .last
              .toJson(),
          startedAtUtc: started,
          localUtcOffsetMinutes: 120,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'learning path drill progress requires live evidence and is rechecked',
    () async {
      final source = BuiltInTrainingContent.catalog.learningPaths.firstWhere(
        (path) => path.entries.any(
          (entry) => entry.kind == LearningPathEntryKind.drill,
        ),
      );
      final sourceEntry = source.entries.firstWhere(
        (entry) => entry.kind == LearningPathEntryKind.drill,
      );
      final drillEntry = LearningPathEntryV2(
        id: 'evidence-drill',
        kind: LearningPathEntryKind.drill,
        versionedContentId: sourceEntry.versionedContentId,
      );
      final path = LearningPathV2(
        id: 'evidence-path',
        version: 1,
        title: 'Bewijsleerpad',
        shortDescription: 'Testpad voor echte drillvoortgang.',
        discipline: source.discipline,
        estimatedMinutes: 10,
        entries: [drillEntry],
        references: source.references,
        review: source.review,
      );
      final started = DateTime.utc(2026, 8, 10, 10);
      final pathId = await repository.startLearningPathActivity(
        learningPathVersionedId: path.versionedId,
        learningPathSnapshot: path.toJson(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );

      await expectLater(
        repository.updateLearningPathProgress(
          activityId: pathId,
          completedEntryIds: [drillEntry.id],
        ),
        throwsStateError,
      );
      await repository.createTrainingActivity(
        id: 'learning-path-drill-evidence',
        kind: StoredTrainingActivityKind.guidedDrillV2,
        activitySchemaVersion: 2,
        status: StoredTrainingActivityStatus.completed,
        configuration: {
          'drillVersionedId': drillEntry.versionedContentId,
          'drill': BuiltInTrainingContent.catalog
              .drillByVersionedId(drillEntry.versionedContentId)!
              .toJson(),
        },
        startedAtUtc: started.add(const Duration(minutes: 1)),
        completedAtUtc: started.add(const Duration(minutes: 5)),
        localUtcOffsetMinutes: 120,
      );
      await repository.updateLearningPathProgress(
        activityId: pathId,
        completedEntryIds: [drillEntry.id],
      );
      await repository.deleteTrainingActivity('learning-path-drill-evidence');
      await expectLater(
        repository.completeLearningPath(
          activityId: pathId,
          completedAtUtc: started.add(const Duration(minutes: 10)),
        ),
        throwsStateError,
      );
      expect(
        (await repository.getTrainingActivity(pathId))!.activity.status,
        'draft',
      );
    },
  );

  test(
    'legacy learning path uses exact catalog versions without rewriting history',
    () async {
      final path = BuiltInTrainingContent.catalog.learningPaths.first;
      await repository.createTrainingActivity(
        id: 'legacy-learning-path-with-ids',
        kind: StoredTrainingActivityKind.learningPathV2,
        activitySchemaVersion: 2,
        configuration: {
          'learningPathVersionedId': path.versionedId,
          'learningPath': path.toJson(),
        },
        summary: const {
          'completedEntryIds': <String>[],
          'currentEntryIndex': 0,
        },
        startedAtUtc: DateTime.utc(2026, 8, 10, 8),
        localUtcOffsetMinutes: 120,
      );

      final overview =
          (await repository.watchLearningPathActivityOverviews().first)
              .singleWhere(
                (item) => item.activity.id == 'legacy-learning-path-with-ids',
              );
      expect(overview.canResume, isTrue);
      expect(overview.hasCompleteEntrySnapshots, isTrue);
      expect(overview.configuration, isNot(contains('entrySnapshots')));
    },
  );

  test(
    'timer phase accepts only a completed timer and blocks referenced delete',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      final drill = BuiltInTrainingContent.catalog.drills.firstWhere(
        (item) => item.phases.any(
          (phase) =>
              phase.completionKind == DrillPhaseCompletionKind.timerActivity,
        ),
      );
      final timerPhase = drill.phases.singleWhere(
        (phase) =>
            phase.completionKind == DrillPhaseCompletionKind.timerActivity,
      );
      await repository.createTrainingActivity(
        id: 'timer-guided-drill',
        kind: StoredTrainingActivityKind.guidedDrillV2,
        activitySchemaVersion: 2,
        configuration: {
          'drillVersionedId': drill.versionedId,
          'drill': drill.toJson(),
        },
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await repository.createTrainingActivity(
        id: 'draft-timer-proof',
        kind: StoredTrainingActivityKind.par,
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      await repository.createTrainingActivity(
        id: 'wrong-kind-proof',
        kind: StoredTrainingActivityKind.coldSeries,
        status: StoredTrainingActivityStatus.completed,
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
        completedAtUtc: started.add(const Duration(seconds: 5)),
      );

      for (final invalidId in const ['draft-timer-proof', 'wrong-kind-proof']) {
        await expectLater(
          repository.updateDrillActivityProgress(
            activityId: 'timer-guided-drill',
            summary: _guidedProgressSummary(
              drill,
              timerActivityIds: {timerPhase.id: invalidId},
            ),
          ),
          throwsStateError,
        );
      }

      await repository.createTrainingActivity(
        id: 'completed-timer-proof',
        kind: StoredTrainingActivityKind.par,
        status: StoredTrainingActivityStatus.completed,
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
        completedAtUtc: started.add(const Duration(seconds: 5)),
      );
      await repository.updateDrillActivityProgress(
        activityId: 'timer-guided-drill',
        summary: _guidedProgressSummary(
          drill,
          timerActivityIds: {timerPhase.id: 'completed-timer-proof'},
        ),
      );
      await expectLater(
        repository.deleteTrainingActivity('completed-timer-proof'),
        throwsStateError,
      );
      expect(
        await repository.getTrainingActivity('completed-timer-proof'),
        isNotNull,
      );
    },
  );

  test(
    'plan completion verifies slots completed drills and final reflection',
    () async {
      final started = DateTime.utc(2026, 8, 5, 10);
      final fixture = _runtimeTrainingFixture();
      final planId = await repository.createTrainingPlanActivity(
        configuration: _planConfiguration(fixture.plan),
        summary: _emptyPlanSummary(),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      final guidedId = await repository.findOrCreateGuidedDrillSlot(
        planActivityId: planId,
        slotIndex: 0,
        drillVersionedId: fixture.drill.versionedId,
        drillSnapshot: fixture.drill.toJson(),
        trainingPlanContext: _planContext(planId, fixture.plan),
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
      );
      final timerActivityIds = <String, String>{};
      for (final phase in fixture.drill.phases.where(
        (phase) =>
            phase.completionKind == DrillPhaseCompletionKind.timerActivity,
      )) {
        final timerId = 'plan-timer-${phase.id}';
        await repository.createTrainingActivity(
          id: timerId,
          kind: StoredTrainingActivityKind.par,
          status: StoredTrainingActivityStatus.completed,
          startedAtUtc: started,
          localUtcOffsetMinutes: 120,
          completedAtUtc: started.add(const Duration(seconds: 5)),
        );
        timerActivityIds[phase.id] = timerId;
      }
      await repository.completeGuidedDrillActivity(
        activityId: guidedId,
        summary: _completedGuidedSummary(
          fixture.drill,
          timerActivityIds: timerActivityIds,
          linkedSeriesCount: 0,
        ),
        completedAtUtc: started.add(const Duration(minutes: 10)),
        minimumLinkedSeries: 0,
      );

      final completedStepIds = fixture.plan.steps
          .map((step) => step.id)
          .toList(growable: false);
      await expectLater(
        repository.completeTrainingPlan(
          activityId: planId,
          summary: {
            ..._emptyPlanSummary(),
            'completedStepIds': completedStepIds,
            'currentStepIndex': fixture.plan.steps.length - 1,
            'finalReflection': 'Veilige uitvoering en één volgende test.',
          },
          completedAtUtc: started.add(const Duration(minutes: 11)),
        ),
        throwsStateError,
      );

      final storedPlan = await repository.getTrainingActivity(planId);
      final authoritative =
          (jsonDecode(storedPlan!.activity.summaryJson) as Map)
              .cast<String, Object?>();
      await repository.completeTrainingPlan(
        activityId: planId,
        summary: {
          ...authoritative,
          'completedStepIds': completedStepIds,
          'currentStepIndex': fixture.plan.steps.length - 1,
          'finalReflection': 'Veilige uitvoering en één volgende test.',
        },
        completedAtUtc: started.add(const Duration(minutes: 12)),
      );
      expect(
        (await repository.getTrainingActivity(planId))!.activity.status,
        StoredTrainingActivityStatus.completed.name,
      );
    },
  );

  test('completed learning path history is read-only', () async {
    final source = BuiltInTrainingContent.catalog.learningPaths.first;
    final lesson = source.entries.firstWhere(
      (entry) => entry.kind == LearningPathEntryKind.lesson,
    );
    final path = LearningPathV2(
      id: 'read-only-path',
      version: 1,
      title: 'Afgerond leerpad',
      shortDescription: 'Blijft als snapshot leesbaar.',
      discipline: source.discipline,
      estimatedMinutes: 5,
      entries: [
        LearningPathEntryV2(
          id: lesson.id,
          kind: lesson.kind,
          versionedContentId: lesson.versionedContentId,
        ),
      ],
      references: source.references,
      review: source.review,
    );
    final started = DateTime.utc(2026, 8, 10, 10);
    final id = await repository.startLearningPathActivity(
      learningPathVersionedId: path.versionedId,
      learningPathSnapshot: path.toJson(),
      startedAtUtc: started,
      localUtcOffsetMinutes: 120,
    );
    await repository.updateLearningPathProgress(
      activityId: id,
      completedEntryIds: [lesson.id],
    );
    await repository.completeLearningPath(
      activityId: id,
      completedAtUtc: started.add(const Duration(minutes: 5)),
    );
    await repository.completeLearningPath(
      activityId: id,
      completedAtUtc: started.add(const Duration(minutes: 6)),
    );

    final overview =
        (await repository.watchLearningPathActivityOverviews().first).single;
    expect(overview.title, 'Afgerond leerpad');
    expect(overview.canResume, isFalse);
    expect(overview.isReadOnly, isTrue);
    expect(await repository.watchActiveLearningPath().first, isNull);
    await expectLater(
      repository.updateLearningPathProgress(
        activityId: id,
        completedEntryIds: const [],
      ),
      throwsStateError,
    );
  });
}

({GeneratedDrillPlan plan, DrillDefinitionV2 drill}) _runtimeTrainingFixture() {
  final catalog = BuiltInTrainingContent.catalog;
  final plan = const DeterministicDrillPlanner().generate(
    durationMinutes: 30,
    discipline: TrainingDiscipline.precisionPistol,
    skillLevel: TrainingSkillLevel.foundation,
    focus: TrainingPlanFocus.fundamentals,
    ammunitionBudget: 25,
    drills: catalog.drills,
    learningPaths: catalog.learningPaths,
  );
  return (plan: plan, drill: plan.slots.single.drill);
}

Map<String, Object?> _planConfiguration(GeneratedDrillPlan plan) => {
  'planId': plan.id,
  'plan': plan.toJson(),
};

Map<String, Object?> _emptyPlanSummary() => {
  'completedSlotIndexes': <int>[],
  'completedStepIds': <String>[],
  'guidedDrillActivityIds': <String, String>{},
  'currentStepIndex': 0,
};

Map<String, Object?> _guidedProgressSummary(
  DrillDefinitionV2 drill, {
  Map<String, String> timerActivityIds = const {},
}) => {
  'drillVersionedId': drill.versionedId,
  'setupConfirmed': false,
  'safetyConfirmed': false,
  'acknowledgedPhaseIds': <String>[],
  'timerActivityIds': timerActivityIds,
  'phaseReflections': <String, String>{},
};

Map<String, Object?> _completedGuidedSummary(
  DrillDefinitionV2 drill, {
  required Map<String, String> timerActivityIds,
  required int linkedSeriesCount,
}) => {
  'drillVersionedId': drill.versionedId,
  'setupConfirmed': true,
  'safetyConfirmed': true,
  'acknowledgedPhaseIds': drill.phases
      .where(
        (phase) =>
            phase.completionKind == DrillPhaseCompletionKind.acknowledged,
      )
      .map((phase) => phase.id)
      .toList(growable: false),
  'timerActivityIds': timerActivityIds,
  'phaseReflections': {
    for (final phase in drill.phases.where(
      (phase) => phase.completionKind == DrillPhaseCompletionKind.reflection,
    ))
      phase.id: 'Concrete reflectie voor ${phase.id}.',
  },
  'validExecution': true,
  'primaryMetric': drill.measurements.first.metric.name,
  'primaryMeasurementValue': 1,
  'primaryMeasurementSampleSize': 1,
  'primaryMeasurementSuccess': true,
  'metricSnapshot': <String, Object?>{
    'metric': drill.measurements.first.metric.name,
    'valid': true,
    'value': 1,
  },
  'sessionIds': <String>[],
  'linkedSeriesCount': linkedSeriesCount,
  'completedPhaseIds': drill.phases
      .map((phase) => phase.id)
      .toList(growable: false),
};

Map<String, Object?> _planContext(
  String planActivityId,
  GeneratedDrillPlan plan,
) => TrainingPlanContext(
  planActivityId: planActivityId,
  planId: plan.id,
  durationMinutes: plan.durationMinutes,
  slotIndex: 0,
  slotCount: plan.slots.length,
  discipline: plan.discipline,
  skillLevel: plan.skillLevel,
  firearmId: plan.firearmId,
  ammoLotId: plan.ammoLotId,
).toJson();

Future<void> _seedSessionAndSeries(AppDatabase database) async {
  final now = DateTime.utc(2026, 8, 5, 9);
  const targetJson = '{"displayName":"Testkaart","rings":[{"value":10}]}';
  await database
      .into(database.trainingSessions)
      .insert(
        TrainingSessionsCompanion.insert(
          id: 'session-1',
          status: 'active',
          startedAtUtc: now,
          localUtcOffsetMinutes: 120,
          updatedAtUtc: now,
        ),
      );
  await database
      .into(database.shootingSeries)
      .insert(
        ShootingSeriesCompanion.insert(
          id: 'series-1',
          sessionId: 'session-1',
          sequenceNumber: 1,
          status: 'confirmed',
          targetProfileVersionedId: 'test@1',
          targetProfileJson: targetJson,
          distanceMeters: 25,
          projectileDiameterMm: 5.6,
          shotCount: const Value(1),
          maximumPossibleScore: const Value(10),
          notes: const Value('Bestaande notitie'),
          totalScore: const Value(7),
          createdAtUtc: now,
          updatedAtUtc: now,
          confirmedAtUtc: Value(now),
        ),
      );
}
