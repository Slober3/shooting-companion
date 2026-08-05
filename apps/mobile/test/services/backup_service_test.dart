import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/services/backup_service.dart';

void main() {
  group('BackupPayloadAdapter v1-v5 -> v6', () {
    test('uses impact multiplicity for actual count and ignores scans', () {
      final data = _v1Data(
        expectedShots: 99,
        impacts: [
          {'id': 'i1', 'seriesId': 'series-1', 'multiplicity': 2},
          {'id': 'i2', 'seriesId': 'series-1', 'multiplicity': 3},
        ],
        images: [
          {
            'id': 'after-1',
            'seriesId': 'series-1',
            'kind': 'after',
            'createdAtUtc': '2026-01-01T10:02:00.000Z',
          },
          {
            'id': 'baseline-1',
            'seriesId': 'series-1',
            'kind': 'baseline',
            'createdAtUtc': '2026-01-01T10:01:00.000Z',
          },
        ],
      );
      final payload = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1, images: 2),
        data: data,
      );

      final series = (payload.data['series']! as List).single as Map;
      expect(series['shotCount'], 5);
      expect(series['maximumPossibleScore'], 35);
      expect(series.containsKey('expectedShots'), isFalse);
      expect(series['cartridgeId'], 'cartridge-1');

      final impacts = payload.data['impacts']! as List;
      expect(impacts, hasLength(2));
      expect((impacts.first as Map).containsKey('origin'), isFalse);
      expect((impacts.first as Map).containsKey('confidence'), isFalse);
      expect((impacts.first as Map)['sourceImageId'], isNull);
      expect((impacts.first as Map)['targetBullId'], isNull);
      expect((impacts.first as Map)['scoreDisposition'], 'counted');

      final images = payload.data['images']! as List;
      expect((images.first as Map)['role'], 'primaryScoringPhoto');
      expect((images.last as Map)['role'], 'attachment');
      expect((images.first as Map)['sessionId'], 'session-1');
      expect(payload.data['photoAlignments'], isEmpty);
      expect(payload.data.containsKey('scans'), isFalse);
      expect(payload.data.containsKey('scanEdits'), isFalse);
      expect(payload.data['settings'], data['preferences']);
    });

    test('falls back to v1 expectedShots only when no impacts exist', () {
      final payload = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(expectedShots: 8),
      );

      final series = (payload.data['series']! as List).single as Map;
      expect(series['shotCount'], 8);
      expect(series['maximumPossibleScore'], 56);
    });

    test('rejects future versions and inconsistent record counts', () {
      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 7),
          data: _v1Data(expectedShots: 1),
        ),
        throwsFormatException,
      );
      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: {..._manifest(version: 1), 'seriesCount': 2},
          data: _v1Data(expectedShots: 1),
        ),
        throwsFormatException,
      );
    });

    test('rejects a v4 impact with an unknown target bull', () {
      final legacy = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(
          expectedShots: 1,
          impacts: const [
            {
              'id': 'impact-1',
              'seriesId': 'series-1',
              'multiplicity': 1,
              'scoreValue': 7,
            },
          ],
        ),
      );
      final data = <String, dynamic>{
        for (final entry in legacy.data.entries) entry.key: entry.value,
      };
      data['impacts'] = [
        for (final value in data['impacts']! as List)
          Map<String, dynamic>.from(value as Map)
            ..['targetBullId'] = 'unknown-bull',
      ];

      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 4),
          data: data,
        ),
        throwsFormatException,
      );
    });

    test('rejects orphan goals and malformed coaching records in v5', () {
      final valid = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(expectedShots: 1),
      ).data;

      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 5),
          data: {
            ...valid,
            'goals': [
              {
                'id': 'orphan-goal',
                'targetProfileVersionedId': 'missing@1',
                'distanceMeters': 25.0,
                'firearmId': null,
                'ammoLotId': null,
                'metric': 'scorePercentage',
                'targetValue': 80.0,
                'comparison': 'atLeast',
                'active': true,
              },
            ],
          },
        ),
        throwsFormatException,
      );

      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 5),
          data: {
            ...valid,
            'seriesReflections': [
              {
                'seriesId': 'series-1',
                'perceivedQuality': 'good',
                'contextTagsJson': '["unknown-tag"]',
                'note': null,
                'createdAtUtc': '2026-01-01T11:00:00.000Z',
                'updatedAtUtc': '2026-01-01T11:00:00.000Z',
              },
            ],
          },
        ),
        throwsFormatException,
      );

      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 5),
          data: {
            ...valid,
            'coachFeedback': [
              {
                'insightFingerprint': 'insight-1',
                'ruleId': 'bias.persistent',
                'ruleVersion': 1,
                'response': 'future-response',
                'snoozedUntilUtc': null,
                'updatedAtUtc': '2026-01-01T11:00:00.000Z',
              },
            ],
          },
        ),
        throwsFormatException,
      );
    });

    test('v5 payload gains an empty schema-6 training layer', () {
      final normalizedV6 = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(expectedShots: 1),
      ).data;
      final payload = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 5),
        data: normalizedV6,
      );

      expect(payload.data['trainingActivities'], isEmpty);
      expect(payload.data['trainingActivitySeriesLinks'], isEmpty);
      expect(payload.data['shotTimerEvents'], isEmpty);
      expect(payload.data['timerPresets'], isEmpty);
      expect(payload.data['acousticCalibrationProfiles'], isEmpty);
    });

    test('rejects orphan or non-monotone timer data in v6', () {
      final valid = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(expectedShots: 1),
      ).data;
      final activity = {
        'id': 'timer-1',
        'kind': 'acousticLiveFire',
        'schemaVersion': 1,
        'status': 'completed',
        'sessionId': 'session-1',
        'configurationJson': '{}',
        'summaryJson': '{}',
        'detectorVersion': 'impulse-v1',
        'startedAtUtc': '2026-01-01T10:00:00.000Z',
        'localUtcOffsetMinutes': 60,
        'completedAtUtc': '2026-01-01T10:00:02.000Z',
        'notes': null,
        'createdAtUtc': '2026-01-01T10:00:00.000Z',
        'updatedAtUtc': '2026-01-01T10:00:02.000Z',
      };
      final data = <String, dynamic>{
        for (final entry in valid.entries) entry.key: entry.value,
        'trainingActivities': [activity],
        'trainingActivitySeriesLinks': <Map<String, dynamic>>[],
        'shotTimerEvents': [
          {
            'id': 'event-1',
            'activityId': 'timer-1',
            'sequenceNumber': 1,
            'elapsedMicroseconds': 1000000,
            'splitMicroseconds': 1000000,
            'source': 'acoustic',
            'disposition': 'counted',
            'normalizedPeak': 0.8,
            'detectionQuality': 'high',
            'exclusionReason': null,
          },
          {
            'id': 'event-2',
            'activityId': 'timer-1',
            'sequenceNumber': 2,
            'elapsedMicroseconds': 900000,
            'splitMicroseconds': 0,
            'source': 'acoustic',
            'disposition': 'counted',
            'normalizedPeak': null,
            'detectionQuality': null,
            'exclusionReason': null,
          },
        ],
      };

      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 6),
          data: data,
        ),
        throwsFormatException,
      );
    });

    test('validates splits against the previous counted timer event', () {
      final valid = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(expectedShots: 1),
      ).data;
      final data = <String, dynamic>{
        for (final entry in valid.entries) entry.key: entry.value,
        'trainingActivities': [
          {
            'id': 'timer-counted-splits',
            'kind': 'acousticLiveFire',
            'schemaVersion': 1,
            'status': 'completed',
            'sessionId': 'session-1',
            'configurationJson': '{}',
            'summaryJson': '{}',
            'detectorVersion': 'impulse-v1',
            'startedAtUtc': '2026-01-01T10:00:00.000Z',
            'localUtcOffsetMinutes': 60,
            'completedAtUtc': '2026-01-01T10:00:02.000Z',
            'notes': null,
            'createdAtUtc': '2026-01-01T10:00:00.000Z',
            'updatedAtUtc': '2026-01-01T10:00:02.000Z',
          },
        ],
        'trainingActivitySeriesLinks': <Map<String, dynamic>>[],
        'shotTimerEvents': [
          _timerEventFixture(
            id: 'counted-1',
            sequenceNumber: 1,
            elapsedMicroseconds: 1000000,
            splitMicroseconds: 1000000,
          ),
          _timerEventFixture(
            id: 'excluded-2',
            sequenceNumber: 2,
            elapsedMicroseconds: 1100000,
            splitMicroseconds: 100000,
            disposition: 'excluded',
            exclusionReason: 'Mogelijke echo',
          ),
          _timerEventFixture(
            id: 'counted-3',
            sequenceNumber: 3,
            elapsedMicroseconds: 1500000,
            splitMicroseconds: 500000,
          ),
        ],
      };

      final payload = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 6),
        data: data,
      );

      expect(payload.data['shotTimerEvents'], hasLength(3));
      expect(
        (payload.data['shotTimerEvents'] as List).last['splitMicroseconds'],
        500000,
      );

      final invalidEvents = [
        for (final event in data['shotTimerEvents']! as List)
          Map<String, dynamic>.from(event as Map),
      ];
      invalidEvents.last['splitMicroseconds'] = 400000;
      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 6),
          data: {...data, 'shotTimerEvents': invalidEvents},
        ),
        throwsFormatException,
      );
    });
  });

  group('BackupMediaIntegrity', () {
    test('accepts matching hash and length', () {
      final bytes = utf8.encode('synthetic-image');
      final digest = sha256.convert(bytes).toString();

      expect(
        () => BackupMediaIntegrity.verify(
          imageId: 'fixture',
          bytes: bytes,
          recordSha256: digest,
          recordSizeBytes: bytes.length,
          manifestSha256: digest,
          manifestSizeBytes: bytes.length,
        ),
        returnsNormally,
      );
    });

    test('rejects a corrupt hash before restore', () {
      final bytes = utf8.encode('synthetic-image');
      final digest = sha256.convert(bytes).toString();

      expect(
        () => BackupMediaIntegrity.verify(
          imageId: 'fixture',
          bytes: bytes,
          recordSha256: digest,
          recordSizeBytes: bytes.length,
          manifestSha256: '0' * 64,
          manifestSizeBytes: bytes.length,
        ),
        throwsFormatException,
      );
    });
  });

  test(
    'SCB1 v6 roundtrip preserves training, insights, media and settings',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'shooting-companion-backup-test-',
      );
      final documents = Directory(path.join(workspace.path, 'documents'));
      final temporary = Directory(path.join(workspace.path, 'temporary'));
      await documents.create(recursive: true);
      await temporary.create(recursive: true);
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async {
        await database.close();
        if (await workspace.exists()) await workspace.delete(recursive: true);
      });

      final now = DateTime.utc(2026, 1, 2, 9);
      final targetJson = jsonEncode({
        'displayName': 'Synthetische zevenring',
        'rings': [
          {'value': 7},
          {'value': 3},
        ],
      });
      await database
          .into(database.cartridges)
          .insert(
            const CartridgesCompanion(
              id: Value('cartridge-1'),
              name: Value('.22 test'),
              projectileDiameterMm: Value(5.6),
              builtIn: Value(false),
              archived: Value(true),
            ),
          );
      await database
          .into(database.targetProfiles)
          .insert(
            TargetProfilesCompanion.insert(
              versionedId: 'target@1',
              profileId: 'target',
              profileVersion: 1,
              displayName: 'Synthetische zevenring',
              validationStatus: 'experimental',
              profileJson: targetJson,
              archived: const Value(true),
              createdAtUtc: now,
            ),
          );
      await database
          .into(database.trainingSessions)
          .insert(
            TrainingSessionsCompanion.insert(
              id: 'session-1',
              status: 'active',
              startedAtUtc: now,
              localUtcOffsetMinutes: 60,
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
              status: 'draft',
              targetProfileVersionedId: 'target@1',
              targetProfileJson: targetJson,
              distanceMeters: 25,
              projectileDiameterMm: 5.6,
              cartridgeId: const Value('cartridge-1'),
              shotCount: const Value(2),
              maximumPossibleScore: const Value(14),
              totalScore: const Value(14),
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );

      final imageBytes = utf8.encode('synthetic-offline-photo');
      final imageHash = sha256.convert(imageBytes).toString();
      final originals = Directory(
        path.join(documents.path, 'target_images', 'originals'),
      );
      await originals.create(recursive: true);
      final original = File(path.join(originals.path, 'fixture.jpg'));
      await original.writeAsBytes(imageBytes, flush: true);
      await database
          .into(database.imageAssets)
          .insert(
            ImageAssetsCompanion.insert(
              id: 'image-1',
              sessionId: 'session-1',
              seriesId: const Value('series-1'),
              role: 'primaryScoringPhoto',
              path: original.path,
              sha256: imageHash,
              width: 10,
              height: 10,
              sizeBytes: imageBytes.length,
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      await database
          .into(database.shotImpacts)
          .insert(
            const ShotImpactsCompanion(
              id: Value('impact-1'),
              seriesId: Value('series-1'),
              xMm: Value(0),
              yMm: Value(0),
              sourceImageId: Value('image-1'),
              imageXNormalized: Value(0.5),
              imageYNormalized: Value(0.5),
              multiplicity: Value(2),
              scoreValue: Value(7),
            ),
          );
      await database
          .into(database.photoAlignments)
          .insert(
            PhotoAlignmentsCompanion.insert(
              imageId: 'image-1',
              cornersJson: '[[0,0],[1,0],[1,1],[0,1]]',
              matrixJson: '[1,0,0,0,1,0,0,0,1]',
              algorithmVersion: 'manual-homography-v1',
              updatedAtUtc: now,
            ),
          );
      await database
          .into(database.preferences)
          .insert(
            const PreferencesCompanion(
              key: Value('theme'),
              value: Value('dark'),
            ),
          );
      await database
          .into(database.preferences)
          .insert(
            const PreferencesCompanion(
              key: Value('coaching.mode.enabled'),
              value: Value('true'),
            ),
          );
      await database
          .into(database.goals)
          .insert(
            const GoalsCompanion(
              id: Value('goal-1'),
              targetProfileVersionedId: Value('target@1'),
              distanceMeters: Value(25),
              metric: Value('meanRadiusMm'),
              targetValue: Value(18),
              comparison: Value('atMost'),
            ),
          );
      await database
          .into(database.seriesReflections)
          .insert(
            SeriesReflectionsCompanion.insert(
              seriesId: 'series-1',
              perceivedQuality: 'good',
              contextTagsJson: const Value('["followThrough"]'),
              note: const Value('Rustig uitgevoerd'),
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      await database
          .into(database.coachFeedback)
          .insert(
            CoachFeedbackCompanion.insert(
              insightFingerprint: 'insight-1',
              ruleId: 'persistent-bias',
              ruleVersion: 1,
              response: 'useful',
              updatedAtUtc: now,
            ),
          );
      await database
          .into(database.trainingActivities)
          .insert(
            TrainingActivitiesCompanion.insert(
              id: 'timer-1',
              kind: 'acousticLiveFire',
              status: 'completed',
              sessionId: const Value('session-1'),
              configurationJson: '{"mode":"acousticLiveFire"}',
              summaryJson:
                  '{"countedShotCount":3,"firstShotTimeMicros":1000000,'
                  '"lastShotTimeMicros":1500000,"totalTimeMicros":1500000,'
                  '"fastestSplitMicros":100000,"slowestSplitMicros":400000,'
                  '"averageSplitMicros":250000}',
              detectorVersion: const Value('impulse-v1'),
              startedAtUtc: now,
              localUtcOffsetMinutes: 60,
              completedAtUtc: Value(now.add(const Duration(seconds: 1))),
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      await database
          .into(database.trainingActivitySeriesLinks)
          .insert(
            const TrainingActivitySeriesLinksCompanion(
              activityId: Value('timer-1'),
              seriesId: Value('series-1'),
              sequenceNumber: Value(1),
            ),
          );
      await database
          .into(database.shotTimerEvents)
          .insert(
            const ShotTimerEventsCompanion(
              id: Value('timer-event-1'),
              activityId: Value('timer-1'),
              sequenceNumber: Value(1),
              elapsedMicroseconds: Value(1000000),
              splitMicroseconds: Value(1000000),
              source: Value('acoustic'),
              disposition: Value('counted'),
              normalizedPeak: Value(0.8),
              detectionQuality: Value('high'),
            ),
          );
      await database
          .into(database.shotTimerEvents)
          .insert(
            const ShotTimerEventsCompanion(
              id: Value('timer-event-echo'),
              activityId: Value('timer-1'),
              sequenceNumber: Value(2),
              elapsedMicroseconds: Value(1100000),
              splitMicroseconds: Value(100000),
              source: Value('acoustic'),
              disposition: Value('counted'),
            ),
          );
      await database
          .into(database.shotTimerEvents)
          .insert(
            const ShotTimerEventsCompanion(
              id: Value('timer-event-3'),
              activityId: Value('timer-1'),
              sequenceNumber: Value(3),
              elapsedMicroseconds: Value(1500000),
              splitMicroseconds: Value(400000),
              source: Value('acoustic'),
              disposition: Value('counted'),
              detectionQuality: Value('high'),
            ),
          );

      final repository = ShootingRepository(database);
      await repository.excludeTimerEvent('timer-event-echo', 'Mogelijke echo');
      final normalizedBeforeBackup = await (database.select(
        database.shotTimerEvents,
      )..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)])).get();
      expect(normalizedBeforeBackup.map((event) => event.disposition), [
        'counted',
        'excluded',
        'counted',
      ]);
      expect(normalizedBeforeBackup.map((event) => event.splitMicroseconds), [
        1000000,
        100000,
        500000,
      ]);
      await database
          .into(database.timerPresets)
          .insert(
            TimerPresetsCompanion.insert(
              id: 'timer-preset-1',
              name: 'Testpreset',
              mode: 'acousticLiveFire',
              configurationJson: '{"mode":"acousticLiveFire"}',
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      await database
          .into(database.acousticCalibrationProfiles)
          .insert(
            AcousticCalibrationProfilesCompanion.insert(
              id: 'calibration-1',
              name: 'Binnenstand',
              cartridgeId: const Value('cartridge-1'),
              environment: 'indoor',
              audioRoute: 'builtIn',
              sampleRate: 48000,
              sensitivity: 0.65,
              echoLockoutMicroseconds: 90000,
              beepBlankingMicroseconds: 250000,
              detectorVersion: 'impulse-v1',
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );

      final service = BackupService(
        database,
        temporaryDirectory: () async => temporary,
        applicationDocumentsDirectory: () async => documents,
      );
      final backup = await service.createEncryptedBackup('test-password-123');
      final inspected = await service.inspectEncryptedBackup(
        backup,
        'test-password-123',
      );
      expect(inspected.formatVersion, 6);
      expect(inspected.sessionCount, 1);
      expect(inspected.seriesCount, 1);
      expect(inspected.imageCount, 1);

      await database.delete(database.trainingSessions).go();
      await database.delete(database.preferences).go();
      await database.delete(database.timerPresets).go();
      await database.delete(database.acousticCalibrationProfiles).go();
      if (await original.exists()) await original.delete();

      final restored = await service.restoreEncryptedBackup(
        backup,
        'test-password-123',
      );
      expect(restored.summary.formatVersion, 6);
      expect(
        await database.select(database.trainingSessions).get(),
        hasLength(1),
      );
      final restoredSeries =
          (await database.select(database.shootingSeries).get()).single;
      expect(restoredSeries.status, 'draft');
      expect(restoredSeries.shotCount, 2);
      expect(restoredSeries.maximumPossibleScore, 14);
      final restoredImpact =
          (await database.select(database.shotImpacts).get()).single;
      expect(restoredImpact.sourceImageId, 'image-1');
      expect(restoredImpact.multiplicity, 2);
      final restoredImage =
          (await database.select(database.imageAssets).get()).single;
      expect(await File(restoredImage.path).readAsBytes(), imageBytes);
      expect(
        (await database.select(database.photoAlignments).get())
            .single
            .algorithmVersion,
        'manual-homography-v1',
      );
      final restoredPreferences = {
        for (final item in await database.select(database.preferences).get())
          item.key: item.value,
      };
      expect(restoredPreferences['theme'], 'dark');
      expect(restoredPreferences['coaching.mode.enabled'], 'true');
      final restoredCartridge =
          (await database.select(database.cartridges).get()).single;
      expect(restoredCartridge.builtIn, isFalse);
      expect(restoredCartridge.archived, isTrue);
      expect(
        (await database.select(database.targetProfiles).get()).single.archived,
        isTrue,
      );
      final restoredGoal = (await database.select(database.goals).get()).single;
      expect(restoredGoal.metric, 'meanRadiusMm');
      expect(restoredGoal.targetValue, 18);
      expect(restoredGoal.comparison, 'atMost');
      final restoredReflection =
          (await database.select(database.seriesReflections).get()).single;
      expect(restoredReflection.perceivedQuality, 'good');
      expect(restoredReflection.note, 'Rustig uitgevoerd');
      expect(
        (await database.select(database.coachFeedback).get()).single.response,
        'useful',
      );
      final restoredActivity =
          (await database.select(database.trainingActivities).get()).single;
      expect(restoredActivity.kind, 'acousticLiveFire');
      expect(restoredActivity.status, 'completed');
      expect(
        (await database.select(database.trainingActivitySeriesLinks).get())
            .single
            .seriesId,
        'series-1',
      );
      final restoredTimerEvents = await (database.select(
        database.shotTimerEvents,
      )..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)])).get();
      expect(restoredTimerEvents, hasLength(3));
      expect(restoredTimerEvents.first.elapsedMicroseconds, 1000000);
      expect(restoredTimerEvents.first.normalizedPeak, 0.8);
      expect(restoredTimerEvents[1].disposition, 'excluded');
      expect(restoredTimerEvents[1].exclusionReason, 'Mogelijke echo');
      expect(restoredTimerEvents.last.elapsedMicroseconds, 1500000);
      expect(restoredTimerEvents.last.splitMicroseconds, 500000);
      final restoredPresets = await database
          .select(database.timerPresets)
          .get();
      expect(restoredPresets, hasLength(4));
      expect(
        restoredPresets
            .singleWhere((preset) => preset.id == 'timer-preset-1')
            .name,
        'Testpreset',
      );
      expect(restoredPresets.where((preset) => preset.builtIn), hasLength(3));
      expect(
        (await database.select(database.acousticCalibrationProfiles).get())
            .single
            .sampleRate,
        48000,
      );
    },
  );

  test(
    'SCB1 roundtrip preserves an external summary without invented events',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'shooting-companion-external-summary-backup-',
      );
      final documents = Directory(path.join(workspace.path, 'documents'))
        ..createSync(recursive: true);
      final temporary = Directory(path.join(workspace.path, 'temporary'))
        ..createSync(recursive: true);
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async {
        await database.close();
        if (await workspace.exists()) await workspace.delete(recursive: true);
      });
      final repository = ShootingRepository(database);
      final started = DateTime.utc(2026, 8, 5, 10);
      await repository.saveCompletedTimerActivity(
        id: 'external-summary-only',
        kind: StoredTrainingActivityKind.externalManual,
        summary: const {
          'countedShotCount': null,
          'firstShotTimeMicros': 1140000,
          'lastShotTimeMicros': 4720000,
          'totalTimeMicros': 4720000,
          'externalTimingCompleteness': 'summaryOnly',
          'shotCountKnown': false,
          'userEdited': true,
        },
        events: const [],
        startedAtUtc: started,
        localUtcOffsetMinutes: 120,
        completedAtUtc: started.add(const Duration(seconds: 5)),
      );
      final service = BackupService(
        database,
        temporaryDirectory: () async => temporary,
        applicationDocumentsDirectory: () async => documents,
      );
      final backup = await service.createEncryptedBackup('test-password-123');

      await database.delete(database.trainingActivities).go();
      await service.restoreEncryptedBackup(backup, 'test-password-123');

      final restored = await repository.getTrainingActivity(
        'external-summary-only',
      );
      final summary =
          jsonDecode(restored!.activity.summaryJson) as Map<String, dynamic>;
      expect(restored.events, isEmpty);
      expect(summary['countedShotCount'], isNull);
      expect(summary['firstShotTimeMicros'], 1140000);
      expect(summary['lastShotTimeMicros'], 4720000);
      expect(summary['totalTimeMicros'], 4720000);
      expect(summary['externalTimingCompleteness'], 'summaryOnly');
      expect(summary['shotCountKnown'], false);
    },
  );

  test('legacy restore immediately seeds built-in timer presets', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'shooting-companion-legacy-restore-',
    );
    final documents = Directory('${temporary.path}/documents')
      ..createSync(recursive: true);
    addTearDown(() async {
      if (await temporary.exists()) {
        await temporary.delete(recursive: true);
      }
    });
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final legacyBackup = await _writeEncryptedFixture(
      directory: temporary,
      password: 'test-password-123',
      manifest: _manifest(version: 1),
      data: _v1Data(expectedShots: 1),
    );
    final service = BackupService(
      database,
      temporaryDirectory: () async => temporary,
      applicationDocumentsDirectory: () async => documents,
    );

    final result = await service.restoreEncryptedBackup(
      legacyBackup,
      'test-password-123',
    );

    expect(result.summary.formatVersion, 1);
    final presets = await database.select(database.timerPresets).get();
    expect(presets, hasLength(3));
    expect(presets.every((preset) => preset.builtIn), isTrue);
    expect(presets.map((preset) => preset.id).toSet(), {
      'builtin-live-fire-random-2-4',
      'builtin-par-5-seconds',
      'builtin-cadence-1-second',
    });
  });
}

Map<String, dynamic> _manifest({required int version, int images = 0}) => {
  'format': 'shooting-companion-backup',
  'formatVersion': version,
  'createdAtUtc': '2026-01-01T11:00:00.000Z',
  'sessionCount': 1,
  'seriesCount': 1,
  'imageCount': images,
};

Map<String, dynamic> _timerEventFixture({
  required String id,
  required int sequenceNumber,
  required int elapsedMicroseconds,
  required int splitMicroseconds,
  String disposition = 'counted',
  String? exclusionReason,
}) => {
  'id': id,
  'activityId': 'timer-counted-splits',
  'sequenceNumber': sequenceNumber,
  'elapsedMicroseconds': elapsedMicroseconds,
  'splitMicroseconds': splitMicroseconds,
  'source': 'acoustic',
  'disposition': disposition,
  'normalizedPeak': null,
  'detectionQuality': null,
  'exclusionReason': exclusionReason,
};

Map<String, dynamic> _v1Data({
  required int expectedShots,
  List<Map<String, dynamic>> impacts = const [],
  List<Map<String, dynamic>> images = const [],
}) => {
  'sessions': [
    {
      'id': 'session-1',
      'status': 'completed',
      'startedAtUtc': '2026-01-01T10:00:00.000Z',
      'endedAtUtc': '2026-01-01T10:30:00.000Z',
      'localUtcOffsetMinutes': 60,
    },
  ],
  'series': [
    {
      'id': 'series-1',
      'sessionId': 'session-1',
      'sequenceNumber': 1,
      'status': 'confirmed',
      'targetProfileVersionedId': 'synthetic@1',
      'targetProfileJson': jsonEncode({
        'displayName': 'Synthetische kaart',
        'rings': [
          {'value': 7},
          {'value': 3},
        ],
      }),
      'distanceMeters': 25.0,
      'projectileDiameterMm': 5.6,
      'expectedShots': expectedShots,
      'ammoLotId': 'ammo-1',
      'totalScore': 0,
      'innerTenCount': 0,
      'missCount': 0,
      'hasBoundaryWarnings': false,
      'createdAtUtc': '2026-01-01T10:01:00.000Z',
      'confirmedAtUtc': '2026-01-01T10:02:00.000Z',
    },
  ],
  'impacts': impacts
      .map((impact) => {'origin': 'manual', 'confidence': null, ...impact})
      .toList(),
  'images': images,
  'firearms': <Map<String, dynamic>>[],
  'cartridges': [
    {'id': 'cartridge-1', 'name': '.22 LR', 'projectileDiameterMm': 5.6},
  ],
  'ammoLots': [
    {
      'id': 'ammo-1',
      'cartridgeId': 'cartridge-1',
      'displayName': 'Testmunitie',
    },
  ],
  'ranges': <Map<String, dynamic>>[],
  'goals': <Map<String, dynamic>>[],
  'preferences': [
    {'key': 'theme', 'value': 'dark'},
  ],
  'targetProfiles': <Map<String, dynamic>>[],
  'scans': [
    {'id': 'discard-me'},
  ],
  'scanEdits': [
    {'id': 'discard-me-too'},
  ],
};

Future<File> _writeEncryptedFixture({
  required Directory directory,
  required String password,
  required Map<String, dynamic> manifest,
  required Map<String, dynamic> data,
}) async {
  final archive = Archive()
    ..addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)))
    ..addFile(ArchiveFile.string('database.json', jsonEncode(data)));
  final salt = List<int>.generate(16, (index) => index + 1);
  final nonce = List<int>.generate(12, (index) => index + 21);
  final key = await Argon2id(
    parallelism: 1,
    memory: 19 * 1024,
    iterations: 2,
    hashLength: 32,
  ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  final encrypted = await AesGcm.with256bits().encrypt(
    ZipEncoder().encode(archive),
    secretKey: key,
    nonce: nonce,
  );
  final container = BytesBuilder(copy: false)
    ..add(const [0x53, 0x43, 0x42, 0x31])
    ..add(salt)
    ..add(nonce)
    ..add(encrypted.mac.bytes)
    ..add(encrypted.cipherText);
  final file = File('${directory.path}/legacy-v1.scbackup');
  return file.writeAsBytes(container.takeBytes(), flush: true);
}
