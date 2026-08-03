import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';

import 'generated/schema/schema.dart';
import 'generated/schema/schema_v1.dart' as v1;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('empty v1 schema migrates exactly to v2', () async {
    final schema = await verifier.schemaAt(1);
    final database = AppDatabase.forTesting(schema.newConnection());

    await verifier.migrateAndValidate(database, 2);

    await database.close();
    schema.close();
  });

  test('v1 sessions, impacts and photos survive the v2 migration', () async {
    final schema = await verifier.schemaAt(1);
    final old = v1.DatabaseAtV1(schema.newConnection());
    final timestamp =
        DateTime.utc(2026, 8, 1, 18).millisecondsSinceEpoch ~/ 1000;
    final target = IssfTargetProfiles.precision25m50m;

    await old
        .into(old.cartridges)
        .insert(
          v1.CartridgesCompanion.insert(
            id: CartridgePresets.twentyTwoLr.id,
            name: CartridgePresets.twentyTwoLr.name,
            projectileDiameterMm:
                CartridgePresets.twentyTwoLr.projectileDiameterMm,
          ),
        );
    await old
        .into(old.trainingSessions)
        .insert(
          v1.TrainingSessionsCompanion.insert(
            id: 'session',
            status: 'active',
            startedAtUtc: timestamp,
            localUtcOffsetMinutes: 120,
            notes: const Value('bewaarde notitie'),
          ),
        );
    await old
        .into(old.shootingSeries)
        .insert(
          v1.ShootingSeriesCompanion.insert(
            id: 'series',
            sessionId: 'session',
            sequenceNumber: 1,
            status: 'confirmed',
            targetProfileVersionedId: target.versionedId,
            targetProfileJson: target.toJsonString(),
            distanceMeters: 25,
            projectileDiameterMm: 5.6,
            expectedShots: 9,
            totalScore: const Value(20),
            innerTenCount: const Value(2),
            missCount: const Value(1),
            createdAtUtc: timestamp,
            confirmedAtUtc: Value(timestamp),
          ),
        );
    await old
        .into(old.shotImpacts)
        .insert(
          v1.ShotImpactsCompanion.insert(
            id: 'center',
            seriesId: 'series',
            xMm: 0,
            yMm: 0,
            origin: 'manual',
            multiplicity: const Value(2),
            scoreValue: 10,
            isInnerTen: const Value(1),
          ),
        );
    await old
        .into(old.shotImpacts)
        .insert(
          v1.ShotImpactsCompanion.insert(
            id: 'miss',
            seriesId: 'series',
            xMm: 0,
            yMm: 0,
            origin: 'manual',
            isMiss: const Value(1),
            scoreValue: 0,
          ),
        );
    await old
        .into(old.imageAssets)
        .insert(
          v1.ImageAssetsCompanion.insert(
            id: 'after-image',
            seriesId: 'series',
            kind: 'after',
            path: 'after.jpg',
            sha256: 'after-hash',
            width: 2000,
            height: 2000,
            sizeBytes: 100,
            createdAtUtc: timestamp,
          ),
        );
    await old
        .into(old.imageAssets)
        .insert(
          v1.ImageAssetsCompanion.insert(
            id: 'baseline-image',
            seriesId: 'series',
            kind: 'baseline',
            path: 'baseline.jpg',
            sha256: 'baseline-hash',
            width: 2000,
            height: 2000,
            sizeBytes: 100,
            createdAtUtc: timestamp - 1,
          ),
        );
    await old.close();

    final database = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(database, 2);

    final session = await database
        .select(database.trainingSessions)
        .getSingle();
    final series = await database.select(database.shootingSeries).getSingle();
    final impacts = await database.select(database.shotImpacts).get();
    final images = await database.select(database.imageAssets).get();
    final foreignKeyViolations = await database
        .customSelect('PRAGMA foreign_key_check')
        .get();
    final obsoleteTables = await database.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name IN ('scans', 'scan_edits')
    ''').get();

    expect(session.notes, 'bewaarde notitie');
    expect(
      session.updatedAtUtc.toUtc(),
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true),
    );
    expect(series.shotCount, 3);
    expect(series.maximumPossibleScore, 30);
    expect(series.totalScore, 20);
    expect(series.cartridgeId, CartridgePresets.twentyTwoLr.id);
    expect(impacts, hasLength(2));
    expect(impacts.every((impact) => impact.sourceImageId == null), isTrue);
    expect(
      images.singleWhere((image) => image.id == 'after-image').role,
      'primaryScoringPhoto',
    );
    expect(
      images.singleWhere((image) => image.id == 'baseline-image').role,
      'attachment',
    );
    expect(foreignKeyViolations, isEmpty);
    expect(obsoleteTables, isEmpty);

    await database.close();
    schema.close();
  });

  test(
    'v1 series without impacts falls back to its legacy shot count',
    () async {
      final schema = await verifier.schemaAt(1);
      final old = v1.DatabaseAtV1(schema.newConnection());
      final timestamp =
          DateTime.utc(2026, 8, 2, 18).millisecondsSinceEpoch ~/ 1000;
      final target = TargetProfile(
        schemaVersion: 1,
        profileId: 'five-point-target',
        profileVersion: 1,
        displayName: 'Vijfpuntenkaart',
        authority: 'Test',
        rulesEdition: '1',
        physicalCardWidthMm: 100,
        physicalCardHeightMm: 100,
        rings: const [RingZone(value: 5, outerDiameterMm: 20)],
        lineThicknessMm: 0.5,
        lineBreakingRule: LineBreakingRule.centerOnly,
        validationStatus: ValidationStatus.experimental,
      );

      await old
          .into(old.trainingSessions)
          .insert(
            v1.TrainingSessionsCompanion.insert(
              id: 'empty-session',
              status: 'active',
              startedAtUtc: timestamp,
              localUtcOffsetMinutes: 120,
            ),
          );
      await old
          .into(old.shootingSeries)
          .insert(
            v1.ShootingSeriesCompanion.insert(
              id: 'empty-series',
              sessionId: 'empty-session',
              sequenceNumber: 1,
              status: 'draft',
              targetProfileVersionedId: target.versionedId,
              targetProfileJson: target.toJsonString(),
              distanceMeters: 25,
              projectileDiameterMm: 5.6,
              expectedShots: 4,
              createdAtUtc: timestamp,
            ),
          );
      await old.close();

      final database = AppDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(database, 2);

      final migrated = await database
          .select(database.shootingSeries)
          .getSingle();
      expect(migrated.shotCount, 4);
      expect(migrated.maximumPossibleScore, 20);
      expect(migrated.status, SeriesStatus.draft.name);

      await database.close();
      schema.close();
    },
  );
}
