import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';

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
      kind: StoredTrainingActivityKind.drill,
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
}

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
