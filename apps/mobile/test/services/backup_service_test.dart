import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/services/backup_service.dart';

void main() {
  group('BackupPayloadAdapter v1/v2 -> v3', () {
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
          manifest: _manifest(version: 4),
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
    'SCB1 v3 roundtrip preserves library state, draft, media and settings',
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
      expect(inspected.formatVersion, 3);
      expect(inspected.sessionCount, 1);
      expect(inspected.seriesCount, 1);
      expect(inspected.imageCount, 1);

      await database.delete(database.trainingSessions).go();
      await database.delete(database.preferences).go();
      if (await original.exists()) await original.delete();

      final restored = await service.restoreEncryptedBackup(
        backup,
        'test-password-123',
      );
      expect(restored.summary.formatVersion, 3);
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
      expect(
        (await database.select(database.preferences).get()).single.value,
        'dark',
      );
      final restoredCartridge =
          (await database.select(database.cartridges).get()).single;
      expect(restoredCartridge.builtIn, isFalse);
      expect(restoredCartridge.archived, isTrue);
      expect(
        (await database.select(database.targetProfiles).get()).single.archived,
        isTrue,
      );
    },
  );
}

Map<String, dynamic> _manifest({required int version, int images = 0}) => {
  'format': 'shooting-companion-backup',
  'formatVersion': version,
  'createdAtUtc': '2026-01-01T11:00:00.000Z',
  'sessionCount': 1,
  'seriesCount': 1,
  'imageCount': images,
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
      'status': 'confirmed',
      'targetProfileJson': jsonEncode({
        'displayName': 'Synthetische kaart',
        'rings': [
          {'value': 7},
          {'value': 3},
        ],
      }),
      'expectedShots': expectedShots,
      'ammoLotId': 'ammo-1',
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
    {'id': 'cartridge-1'},
  ],
  'ammoLots': [
    {'id': 'ammo-1', 'cartridgeId': 'cartridge-1'},
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
