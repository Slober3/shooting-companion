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
import 'package:shooting_companion/features/training_tools/drill_plan_screen.dart';
import 'package:shooting_companion/services/backup_service.dart';
import 'package:shooting_companion_training/training.dart';

void main() {
  group('BackupPayloadAdapter v1-v7 -> v8', () {
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
          manifest: _manifest(version: 9),
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

    test('upgrades v7 vision drafts with deterministic alignment defaults', () {
      final legacy = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(expectedShots: 1),
      ).data;
      legacy['visionScanDrafts'] = [
        {
          'id': 'draft-v7',
          'status': 'reviewNeeded',
          'originalImagePath': 'private/fixture.jpg',
          'sha256': '0' * 64,
          'width': 1200,
          'height': 900,
          'sizeBytes': 42,
          'targetProfileJson': _validTargetJson(),
          'projectileDiameterMm': 5.6,
          'qualityJson': '{}',
          'registrationJson': '{}',
          'candidatesJson': '[]',
          'reviewJson': '{}',
          'engineVersion': 'vision-v7',
          'failureCode': null,
          'createdAtUtc': '2026-01-01T10:00:00.000Z',
          'updatedAtUtc': '2026-01-01T10:01:00.000Z',
        },
      ];

      final payload = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 7),
        data: legacy,
      );
      final draft = (payload.data['visionScanDrafts']! as List).single as Map;

      expect(draft['rotationQuarterTurns'], 0);
      expect(draft['alignmentMode'], 'fullCard');
      expect(draft['planarityStatus'], 'unknown');
      expect(draft['anchorsJson'], isNull);
      expect(draft['reprojectionRmsMm'], isNull);
      expect(draft['reprojectionMaxMm'], isNull);
    });

    test('rejects invalid v8 alignment rotation and residuals', () {
      final data = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(expectedShots: 1),
      ).data;
      data['photoAlignments'] = [
        {
          'imageId': 'image-1',
          'cornersJson': '[]',
          'matrixJson': '[1,0,0,0,1,0,0,0,1]',
          'algorithmVersion': 'manual-homography-v1',
          'rotationQuarterTurns': 4,
          'alignmentMode': 'fullCard',
          'anchorsJson': '[]',
          'reprojectionRmsMm': -0.1,
          'reprojectionMaxMm': 0.2,
          'planarityStatus': 'accepted',
          'confirmedAtUtc': '2026-01-01T10:00:00.000Z',
          'updatedAtUtc': '2026-01-01T10:00:00.000Z',
        },
      ];

      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 8),
          data: data,
        ),
        throwsFormatException,
      );
    });

    test('accepts a runtime-valid modern target snapshot', () {
      final data = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(
          expectedShots: 1,
          impacts: const [
            {'id': 'impact-1', 'seriesId': 'series-1'},
          ],
        ),
      ).data;
      final series = (data['series']! as List).cast<Map>().single;
      series['targetProfileVersionedId'] = 'runtime-target@1';
      series['targetProfileJson'] = _validTargetJson();

      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 8),
          data: data,
        ),
        returnsNormally,
      );
    });

    test('rejects non-finite target geometry at the import boundary', () {
      final data = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(expectedShots: 1),
      ).data;
      final series = (data['series']! as List).cast<Map>().single;
      series['targetProfileVersionedId'] = 'runtime-target@1';
      series['targetProfileJson'] = _validTargetJson().replaceFirst(
        '"physicalCardWidthMm":200.0',
        '"physicalCardWidthMm":1e999',
      );

      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 8),
          data: data,
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate target bull and impact identifiers', () {
      final data = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(
          expectedShots: 1,
          impacts: const [
            {'id': 'impact-1', 'seriesId': 'series-1'},
          ],
        ),
      ).data;
      final duplicateImpacts = [
        for (final value in data['impacts']! as List)
          Map<String, dynamic>.from(value as Map),
        Map<String, dynamic>.from((data['impacts']! as List).single as Map),
      ];
      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 8),
          data: {...data, 'impacts': duplicateImpacts},
        ),
        throwsFormatException,
      );

      final series = (data['series']! as List).cast<Map>().single;
      series['targetProfileVersionedId'] = 'multi-target@1';
      series['targetProfileJson'] = _validMultiBullTargetJson(
        duplicateBullIds: true,
      );
      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 8),
          data: data,
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid impact multiplicity and image coordinates', () {
      final valid = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(
          expectedShots: 1,
          impacts: const [
            {'id': 'impact-1', 'seriesId': 'series-1'},
          ],
        ),
      ).data;

      for (final mutation in <void Function(Map<String, dynamic>)>[
        (impact) => impact['multiplicity'] = 0,
        (impact) => impact['xMm'] = double.nan,
        (impact) {
          impact['imageXNormalized'] = 1.01;
          impact['imageYNormalized'] = 0.5;
        },
        (impact) {
          impact['imageXNormalized'] = 0.5;
          impact['imageYNormalized'] = null;
        },
      ]) {
        final impact = Map<String, dynamic>.from(
          (valid['impacts']! as List).single as Map,
        );
        mutation(impact);
        expect(
          () => BackupPayloadAdapter.normalize(
            manifest: _manifest(version: 8),
            data: {
              ...valid,
              'impacts': [impact],
            },
          ),
          throwsFormatException,
        );
      }
    });

    test('rejects a multi-bull impact whose position and bull disagree', () {
      final data = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(
          expectedShots: 1,
          impacts: const [
            {'id': 'impact-1', 'seriesId': 'series-1'},
          ],
        ),
      ).data;
      final series = (data['series']! as List).cast<Map>().single;
      series['targetProfileVersionedId'] = 'multi-target@1';
      series['targetProfileJson'] = _validMultiBullTargetJson();
      final impact = (data['impacts']! as List).cast<Map>().single;
      impact['xMm'] = 50.0;
      impact['yMm'] = 0.0;
      impact['targetBullId'] = 'left';

      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 8),
          data: data,
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

    test('v8 validates current guided drill and plan runtime snapshots', () {
      final valid = BackupPayloadAdapter.normalize(
        manifest: _manifest(version: 1),
        data: _v1Data(expectedShots: 1),
      ).data;
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
      final drill = plan.slots.single.drill;
      final learningPath = catalog.learningPaths.first;
      final baseActivity = <String, dynamic>{
        'id': 'guided-current',
        'kind': 'guidedDrillV2',
        'schemaVersion': 2,
        'status': 'draft',
        'sessionId': 'session-1',
        'configurationJson': jsonEncode({
          'drillVersionedId': drill.versionedId,
          'drill': drill.toJson(),
        }),
        'summaryJson': '{}',
        'detectorVersion': null,
        'startedAtUtc': '2026-01-01T10:00:00.000Z',
        'localUtcOffsetMinutes': 60,
        'completedAtUtc': null,
        'notes': null,
        'createdAtUtc': '2026-01-01T10:00:00.000Z',
        'updatedAtUtc': '2026-01-01T10:00:00.000Z',
      };
      final planActivity = <String, dynamic>{
        ...baseActivity,
        'id': 'plan-current',
        'kind': 'trainingPlan',
        'schemaVersion': 1,
        'configurationJson': jsonEncode({
          'planId': plan.id,
          'plan': plan.toJson(),
        }),
        'summaryJson': jsonEncode({
          'completedSlotIndexes': <int>[],
          'completedStepIds': <String>[],
          'guidedDrillActivityIds': <String, String>{},
          'currentStepIndex': 0,
        }),
      };
      final learningPathActivity = <String, dynamic>{
        ...baseActivity,
        'id': 'learning-path-current',
        'kind': 'learningPathV2',
        'schemaVersion': 2,
        'configurationJson': jsonEncode({
          'learningPathVersionedId': learningPath.versionedId,
          'learningPath': learningPath.toJson(),
        }),
        'summaryJson': jsonEncode({
          'completedEntryIds': <String>[],
          'currentEntryIndex': 0,
        }),
      };
      final currentData = <String, dynamic>{
        ...valid,
        'trainingActivities': [
          baseActivity,
          planActivity,
          learningPathActivity,
        ],
      };

      expect(
        BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 8),
          data: currentData,
        ).data['trainingActivities'],
        hasLength(3),
      );

      final wrongIdConfiguration =
          (jsonDecode(baseActivity['configurationJson'] as String) as Map)
              .cast<String, Object?>()
            ..['drillVersionedId'] = 'ander@999';
      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 8),
          data: {
            ...currentData,
            'trainingActivities': [
              {
                ...baseActivity,
                'configurationJson': jsonEncode(wrongIdConfiguration),
              },
            ],
          },
        ),
        throwsFormatException,
      );
      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 8),
          data: {
            ...currentData,
            'trainingActivities': [
              {
                ...learningPathActivity,
                'summaryJson': jsonEncode({
                  'completedEntryIds': <String>[],
                  'currentEntryIndex': 1,
                }),
              },
            ],
          },
        ),
        throwsFormatException,
      );
      final malformedPlan = Map<String, Object?>.from(plan.toJson())
        ..remove('steps');
      expect(
        () => BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 8),
          data: {
            ...currentData,
            'trainingActivities': [
              {
                ...planActivity,
                'configurationJson': jsonEncode({
                  'planId': plan.id,
                  'plan': malformedPlan,
                }),
              },
            ],
          },
        ),
        throwsFormatException,
      );
    });

    test(
      'v8 preserves unknown future training snapshots for read-only use',
      () {
        final valid = BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 1),
          data: _v1Data(expectedShots: 1),
        ).data;
        final base = <String, dynamic>{
          'status': 'draft',
          'sessionId': 'session-1',
          'summaryJson': '{}',
          'detectorVersion': null,
          'startedAtUtc': '2026-01-01T10:00:00.000Z',
          'localUtcOffsetMinutes': 60,
          'completedAtUtc': null,
          'notes': null,
          'createdAtUtc': '2026-01-01T10:00:00.000Z',
          'updatedAtUtc': '2026-01-01T10:00:00.000Z',
        };
        final futureActivities = [
          {
            ...base,
            'id': 'guided-future',
            'kind': 'guidedDrillV2',
            'schemaVersion': 3,
            'configurationJson': '{"futureSnapshot":true}',
          },
          {
            ...base,
            'id': 'plan-future',
            'kind': 'trainingPlan',
            'schemaVersion': 1,
            'configurationJson':
                '{"plan":{"plannerVersion":2,"opaqueFuturePlan":true}}',
          },
          {
            ...base,
            'id': 'learning-path-future',
            'kind': 'learningPathV2',
            'schemaVersion': 3,
            'configurationJson': '{"opaqueFutureLearningPath":true}',
          },
        ];

        final normalized = BackupPayloadAdapter.normalize(
          manifest: _manifest(version: 8),
          data: {...valid, 'trainingActivities': futureActivities},
        );

        expect(normalized.data['trainingActivities'], futureActivities);
      },
    );
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
    'backup creation rejects invalid domain records before export',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'shooting-companion-invalid-backup-test-',
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
      await database
          .into(database.targetProfiles)
          .insert(
            TargetProfilesCompanion.insert(
              versionedId: 'corrupt@1',
              profileId: 'corrupt',
              profileVersion: 1,
              displayName: 'Corrupt fixture',
              validationStatus: 'experimental',
              profileJson: '{"schemaVersion":1}',
              createdAtUtc: DateTime.utc(2026, 1, 1),
            ),
          );
      final service = BackupService(
        database,
        temporaryDirectory: () async => temporary,
        applicationDocumentsDirectory: () async => documents,
      );

      await expectLater(
        service.createEncryptedBackup('test-password-123'),
        throwsFormatException,
      );
    },
  );

  test(
    'SCB1 v8 roundtrip preserves alignment, vision, training and media',
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
      final targetJson = _validTargetJson(profileId: 'target');
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
          .into(database.visionAnalyses)
          .insert(
            VisionAnalysesCompanion.insert(
              id: 'vision-analysis-1',
              seriesId: 'series-1',
              imageId: 'image-1',
              engineVersion: 'vision-core-test',
              backendVersion: 'opencv-4.13.0',
              qualityJson: '{"status":"accepted"}',
              registrationJson:
                  '{"status":"registered","orderedSourceCornersNormalized":[]}',
              candidatesJson: '[]',
              reviewJson: '{"schemaVersion":1,"entries":[]}',
              createdAtUtc: now,
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
              placementMethod: Value('assistedEdited'),
              visionAnalysisId: Value('vision-analysis-1'),
              positionalUncertaintyMm: Value(0.7),
            ),
          );
      await database
          .into(database.photoAlignments)
          .insert(
            PhotoAlignmentsCompanion.insert(
              imageId: 'image-1',
              cornersJson: '[[0,0],[1,0],[1,1],[0,1]]',
              matrixJson: '[1,0,0,0,1,0,0,0,1]',
              algorithmVersion: 'ring-assisted-homography-v1',
              rotationQuarterTurns: const Value(3),
              alignmentMode: const Value('ringAssisted'),
              anchorsJson: const Value('{"schemaVersion":2,"anchors":[]}'),
              reprojectionRmsMm: const Value(0.42),
              reprojectionMaxMm: const Value(0.9),
              planarityStatus: const Value('accepted'),
              confirmedAtUtc: Value(now),
              updatedAtUtc: now,
            ),
          );
      final draftBytes = utf8.encode('synthetic-vision-draft-photo');
      final draftHash = sha256.convert(draftBytes).toString();
      final draftFile = File(path.join(originals.path, 'vision-draft.jpg'));
      await draftFile.writeAsBytes(draftBytes, flush: true);
      await database
          .into(database.visionScanDrafts)
          .insert(
            VisionScanDraftsCompanion.insert(
              id: 'vision-draft-1',
              status: 'reviewNeeded',
              originalImagePath: draftFile.path,
              sha256: draftHash,
              width: 20,
              height: 20,
              sizeBytes: draftBytes.length,
              targetProfileJson: targetJson,
              projectileDiameterMm: 5.6,
              qualityJson: const Value('{"status":"review"}'),
              registrationJson: const Value('{"status":"registered"}'),
              candidatesJson: const Value('[]'),
              reviewJson: const Value('{"schemaVersion":1,"entries":[]}'),
              engineVersion: const Value('vision-core-test'),
              rotationQuarterTurns: const Value(1),
              alignmentMode: const Value('ringAssisted'),
              anchorsJson: const Value('{"schemaVersion":2,"anchors":[]}'),
              reprojectionRmsMm: const Value(0.5),
              reprojectionMaxMm: const Value(1.0),
              planarityStatus: const Value('manualReviewOnly'),
              alignmentAlgorithmVersion: const Value(
                'ring-assisted-homography-v1',
              ),
              alignmentConfirmedAtUtc: Value(now),
              createdAtUtc: now,
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
      final catalog = BuiltInTrainingContent.catalog;
      final runtimePlan = const DeterministicDrillPlanner().generate(
        durationMinutes: 30,
        discipline: TrainingDiscipline.precisionPistol,
        skillLevel: TrainingSkillLevel.foundation,
        focus: TrainingPlanFocus.fundamentals,
        ammunitionBudget: 25,
        firearmId: null,
        ammoLotId: null,
        drills: catalog.drills,
        learningPaths: catalog.learningPaths,
      );
      final runtimeDrill = runtimePlan.slots.single.drill;
      final runtimeLearningPath = catalog.learningPaths.first;
      final runtimePlanContext = TrainingPlanContext(
        planActivityId: 'training-plan-1',
        planId: runtimePlan.id,
        durationMinutes: runtimePlan.durationMinutes,
        slotIndex: 0,
        slotCount: runtimePlan.slots.length,
        discipline: runtimePlan.discipline,
        skillLevel: runtimePlan.skillLevel,
      );
      final guidedDrillConfiguration = jsonEncode({
        'drillVersionedId': runtimeDrill.versionedId,
        'drill': runtimeDrill.toJson(),
        'trainingPlan': runtimePlanContext.toJson(),
      });
      final guidedDrillSummary = jsonEncode({
        'drillVersionedId': runtimeDrill.versionedId,
        'setupConfirmed': true,
        'safetyConfirmed': true,
        'acknowledgedPhaseIds': <String>[],
        'timerActivityIds': <String, String>{},
        'phaseReflections': <String, String>{},
      });
      final trainingPlanConfiguration = jsonEncode({
        'planId': runtimePlan.id,
        'plan': runtimePlan.toJson(),
      });
      final trainingPlanSummary = jsonEncode({
        'completedSlotIndexes': <int>[],
        'completedStepIds': <String>[],
        'guidedDrillActivityIds': <String, String>{'0': 'guided-drill-v2-1'},
        'currentStepIndex': 0,
      });
      final learningPathConfiguration = jsonEncode({
        'learningPathVersionedId': runtimeLearningPath.versionedId,
        'learningPath': runtimeLearningPath.toJson(),
      });
      final learningPathSummary = jsonEncode({
        'completedEntryIds': <String>[],
        'currentEntryIndex': 0,
      });
      await database.batch((batch) {
        batch.insert(
          database.trainingActivities,
          TrainingActivitiesCompanion.insert(
            id: 'guided-drill-v2-1',
            kind: 'guidedDrillV2',
            schemaVersion: const Value(2),
            status: 'draft',
            sessionId: const Value('session-1'),
            configurationJson: guidedDrillConfiguration,
            summaryJson: guidedDrillSummary,
            startedAtUtc: now,
            localUtcOffsetMinutes: 60,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        batch.insert(
          database.trainingActivities,
          TrainingActivitiesCompanion.insert(
            id: 'learning-path-v2-1',
            kind: 'learningPathV2',
            schemaVersion: const Value(2),
            status: 'draft',
            sessionId: const Value('session-1'),
            configurationJson: learningPathConfiguration,
            summaryJson: learningPathSummary,
            startedAtUtc: now,
            localUtcOffsetMinutes: 60,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        batch.insert(
          database.trainingActivities,
          TrainingActivitiesCompanion.insert(
            id: 'training-plan-1',
            kind: 'trainingPlan',
            status: 'draft',
            sessionId: const Value('session-1'),
            configurationJson: trainingPlanConfiguration,
            summaryJson: trainingPlanSummary,
            startedAtUtc: now,
            localUtcOffsetMinutes: 60,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        batch.insert(
          database.trainingActivities,
          TrainingActivitiesCompanion.insert(
            id: 'guided-drill-future',
            kind: 'guidedDrillV2',
            schemaVersion: const Value(3),
            status: 'draft',
            configurationJson: '{"futureSnapshot":true}',
            summaryJson: '{}',
            startedAtUtc: now,
            localUtcOffsetMinutes: 60,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        batch.insert(
          database.trainingActivities,
          TrainingActivitiesCompanion.insert(
            id: 'training-plan-future',
            kind: 'trainingPlan',
            status: 'draft',
            configurationJson:
                '{"plan":{"plannerVersion":2,"opaqueFuturePlan":true}}',
            summaryJson: '{}',
            startedAtUtc: now,
            localUtcOffsetMinutes: 60,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
        batch.insertAll(database.trainingActivitySeriesLinks, const [
          TrainingActivitySeriesLinksCompanion(
            activityId: Value('guided-drill-v2-1'),
            seriesId: Value('series-1'),
            sequenceNumber: Value(1),
          ),
          TrainingActivitySeriesLinksCompanion(
            activityId: Value('training-plan-1'),
            seriesId: Value('series-1'),
            sequenceNumber: Value(1),
          ),
        ]);
      });
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
      expect(inspected.formatVersion, 8);
      expect(inspected.sessionCount, 1);
      expect(inspected.seriesCount, 1);
      expect(inspected.imageCount, 1);

      await database.delete(database.trainingSessions).go();
      await database.delete(database.preferences).go();
      await database.delete(database.timerPresets).go();
      await database.delete(database.acousticCalibrationProfiles).go();
      await database.delete(database.visionScanDrafts).go();
      if (await original.exists()) await original.delete();
      if (await draftFile.exists()) await draftFile.delete();

      final restored = await service.restoreEncryptedBackup(
        backup,
        'test-password-123',
      );
      expect(restored.summary.formatVersion, 8);
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
      expect(restoredImpact.placementMethod, 'assistedEdited');
      expect(restoredImpact.visionAnalysisId, 'vision-analysis-1');
      expect(restoredImpact.positionalUncertaintyMm, 0.7);
      final restoredAnalysis =
          (await database.select(database.visionAnalyses).get()).single;
      expect(restoredAnalysis.engineVersion, 'vision-core-test');
      expect(restoredAnalysis.backendVersion, 'opencv-4.13.0');
      final restoredDraft =
          (await database.select(database.visionScanDrafts).get()).single;
      expect(restoredDraft.status, 'reviewNeeded');
      expect(restoredDraft.rotationQuarterTurns, 1);
      expect(restoredDraft.alignmentMode, 'ringAssisted');
      expect(restoredDraft.anchorsJson, '{"schemaVersion":2,"anchors":[]}');
      expect(restoredDraft.reprojectionRmsMm, 0.5);
      expect(restoredDraft.reprojectionMaxMm, 1.0);
      expect(restoredDraft.planarityStatus, 'manualReviewOnly');
      expect(
        restoredDraft.alignmentAlgorithmVersion,
        'ring-assisted-homography-v1',
      );
      expect(restoredDraft.alignmentConfirmedAtUtc?.toUtc(), now);
      expect(
        await File(restoredDraft.originalImagePath).readAsBytes(),
        draftBytes,
      );
      final restoredImage =
          (await database.select(database.imageAssets).get()).single;
      expect(await File(restoredImage.path).readAsBytes(), imageBytes);
      final restoredAlignment =
          (await database.select(database.photoAlignments).get()).single;
      expect(restoredAlignment.algorithmVersion, 'ring-assisted-homography-v1');
      expect(restoredAlignment.rotationQuarterTurns, 3);
      expect(restoredAlignment.alignmentMode, 'ringAssisted');
      expect(restoredAlignment.anchorsJson, '{"schemaVersion":2,"anchors":[]}');
      expect(restoredAlignment.reprojectionRmsMm, 0.42);
      expect(restoredAlignment.reprojectionMaxMm, 0.9);
      expect(restoredAlignment.planarityStatus, 'accepted');
      expect(restoredAlignment.confirmedAtUtc?.toUtc(), now);
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
      final restoredActivities = await database
          .select(database.trainingActivities)
          .get();
      final restoredActivity = restoredActivities.singleWhere(
        (activity) => activity.id == 'timer-1',
      );
      expect(restoredActivity.kind, 'acousticLiveFire');
      expect(restoredActivity.status, 'completed');
      final restoredGuidedDrill = restoredActivities.singleWhere(
        (activity) => activity.id == 'guided-drill-v2-1',
      );
      expect(restoredGuidedDrill.kind, 'guidedDrillV2');
      expect(restoredGuidedDrill.configurationJson, guidedDrillConfiguration);
      expect(restoredGuidedDrill.summaryJson, guidedDrillSummary);
      final restoredGuidedConfiguration =
          (jsonDecode(restoredGuidedDrill.configurationJson) as Map)
              .cast<String, Object?>();
      final restoredDrill = DrillDefinitionV2.fromJson(
        (restoredGuidedConfiguration['drill']! as Map).cast<String, Object?>(),
      );
      final restoredPlanContext = TrainingPlanContext.fromJson(
        (restoredGuidedConfiguration['trainingPlan']! as Map)
            .cast<String, Object?>(),
      );
      expect(restoredDrill.versionedId, runtimeDrill.versionedId);
      expect(restoredPlanContext.planActivityId, 'training-plan-1');
      final restoredTrainingPlan = restoredActivities.singleWhere(
        (activity) => activity.id == 'training-plan-1',
      );
      expect(restoredTrainingPlan.kind, 'trainingPlan');
      expect(restoredTrainingPlan.configurationJson, trainingPlanConfiguration);
      expect(restoredTrainingPlan.summaryJson, trainingPlanSummary);
      final restoredPlanConfiguration =
          (jsonDecode(restoredTrainingPlan.configurationJson) as Map)
              .cast<String, Object?>();
      final parsedRestoredPlan = GeneratedDrillPlan.fromJson(
        (restoredPlanConfiguration['plan']! as Map).cast<String, Object?>(),
      );
      expect(parsedRestoredPlan.toJson(), runtimePlan.toJson());
      final restoredLearningPath = restoredActivities.singleWhere(
        (activity) => activity.id == 'learning-path-v2-1',
      );
      expect(restoredLearningPath.configurationJson, learningPathConfiguration);
      expect(restoredLearningPath.summaryJson, learningPathSummary);
      final learningPathOverview =
          (await repository.watchLearningPathActivityOverviews().first)
              .singleWhere((item) => item.activity.id == 'learning-path-v2-1');
      expect(learningPathOverview.canResume, isTrue);
      expect(learningPathOverview.title, runtimeLearningPath.title);
      final resumableOverviews = await repository
          .watchGuidedTrainingActivityOverviews()
          .first;
      expect(
        resumableOverviews
            .singleWhere((item) => item.activity.id == 'guided-drill-v2-1')
            .canResume,
        isTrue,
      );
      expect(
        resumableOverviews
            .singleWhere((item) => item.activity.id == 'guided-drill-future')
            .canResume,
        isFalse,
      );
      expect(
        resumableOverviews
            .singleWhere((item) => item.activity.id == 'training-plan-future')
            .canResume,
        isFalse,
      );
      expect(
        resumableOverviews
            .singleWhere((item) => item.activity.id == 'training-plan-1')
            .canResume,
        isTrue,
      );
      expect(
        (await database.select(database.trainingActivitySeriesLinks).get())
            .where((link) => link.seriesId == 'series-1'),
        hasLength(3),
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
      .map(
        (impact) => {
          'origin': 'manual',
          'confidence': null,
          'xMm': 0.0,
          'yMm': 0.0,
          'multiplicity': 1,
          'isMiss': false,
          'isPositionUncertain': false,
          'scoreValue': 0,
          'isInnerTen': false,
          'isBoundaryUncertain': false,
          ...impact,
        },
      )
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

String _validTargetJson({String profileId = 'runtime-target'}) => jsonEncode({
  'schemaVersion': 1,
  'profileId': profileId,
  'profileVersion': 1,
  'displayName': 'Runtime target',
  'authority': 'Test',
  'rulesEdition': 'Fixture',
  'targetKind': 'concentricRings',
  'physicalCardWidthMm': 200.0,
  'physicalCardHeightMm': 200.0,
  'rings': [
    {'value': 10, 'outerDiameterMm': 20.0},
    {'value': 9, 'outerDiameterMm': 40.0},
  ],
  'innerTenDiameterMm': 10.0,
  'blackOuterDiameterMm': 40.0,
  'lineThicknessMm': 0.2,
  'lineBreakingRule': 'bulletEdgeTouchesHigherRing',
  'validationStatus': 'experimental',
  'defaultDistanceMeters': 25.0,
  'supportedDistancesMeters': [25.0],
  'bulls': <Object?>[],
  'multiBullScoringPolicy': null,
  'rendererKind': 'standard',
});

String _validMultiBullTargetJson({bool duplicateBullIds = false}) =>
    jsonEncode({
      'schemaVersion': 2,
      'profileId': 'multi-target',
      'profileVersion': 1,
      'displayName': 'Multi target',
      'authority': 'Test',
      'rulesEdition': 'Fixture',
      'targetKind': 'multiBullConcentric',
      'physicalCardWidthMm': 200.0,
      'physicalCardHeightMm': 100.0,
      'rings': [
        {'value': 10, 'outerDiameterMm': 20.0},
      ],
      'innerTenDiameterMm': 5.0,
      'blackOuterDiameterMm': 20.0,
      'lineThicknessMm': 0.2,
      'lineBreakingRule': 'bulletEdgeTouchesHigherRing',
      'validationStatus': 'experimental',
      'defaultDistanceMeters': 50.0,
      'supportedDistancesMeters': [50.0],
      'bulls': [
        {
          'id': 'left',
          'label': '1',
          'centerXMm': -50.0,
          'centerYMm': 0.0,
          'role': 'record',
          'scoringWidthMm': 40.0,
          'scoringHeightMm': 40.0,
        },
        {
          'id': duplicateBullIds ? 'left' : 'right',
          'label': '2',
          'centerXMm': 50.0,
          'centerYMm': 0.0,
          'role': 'record',
          'scoringWidthMm': 40.0,
          'scoringHeightMm': 40.0,
        },
      ],
      'multiBullScoringPolicy': {
        'recordBullCount': 2,
        'maximumShotsPerBull': 1,
        'duplicatePolicy': 'lowestScoreCounts',
        'excessShotPenalty': 1,
        'fixedMaximumScore': 20,
      },
      'rendererKind': 'standard',
    });

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
