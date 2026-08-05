import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';

import 'generated/schema/schema.dart';
import 'generated/schema/schema_v1.dart' as v1;
import 'generated/schema/schema_v2.dart' as v2;
import 'generated/schema/schema_v3.dart' as v3;
import 'generated/schema/schema_v4.dart' as v4;
import 'generated/schema/schema_v5.dart' as v5;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('empty v1 schema migrates exactly to v6', () async {
    final schema = await verifier.schemaAt(1);
    final database = AppDatabase.forTesting(schema.newConnection());

    await verifier.migrateAndValidate(database, 6);

    await database.close();
    schema.close();
  });

  test('v1 sessions, impacts and photos survive the v6 migration', () async {
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
    await verifier.migrateAndValidate(database, 6);

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
      impacts.every((impact) => impact.rawScoreValue == impact.scoreValue),
      isTrue,
    );
    expect(
      impacts.every((impact) => impact.scoreDisposition == 'counted'),
      isTrue,
    );
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
      await verifier.migrateAndValidate(database, 6);

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

  test('v2 library data migrates to active built-ins in v4', () async {
    final schema = await verifier.schemaAt(2);
    final old = v2.DatabaseAtV2(schema.newConnection());

    await old
        .into(old.cartridges)
        .insert(
          v2.CartridgesCompanion.insert(
            id: 'legacy-cartridge',
            name: 'Legacy kaliber',
            projectileDiameterMm: 5.6,
          ),
        );
    await old
        .into(old.ammoLots)
        .insert(
          v2.AmmoLotsCompanion.insert(
            id: 'legacy-ammo',
            cartridgeId: 'legacy-cartridge',
            displayName: 'Legacy munitie',
          ),
        );
    await old
        .into(old.ranges)
        .insert(
          v2.RangesCompanion.insert(id: 'legacy-range', name: 'Legacy stand'),
        );
    await old.close();

    final database = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(database, 6);

    final cartridge = await database.select(database.cartridges).getSingle();
    final ammo = await database.select(database.ammoLots).getSingle();
    final range = await database.select(database.ranges).getSingle();
    expect(cartridge.builtIn, isTrue);
    expect(cartridge.archived, isFalse);
    expect(ammo.archived, isFalse);
    expect(range.archived, isFalse);
    expect(
      await database.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
    );

    await database.close();
    schema.close();
  });

  test('v3 score records migrate to v6 without recalculation', () async {
    final schema = await verifier.schemaAt(3);
    final old = v3.DatabaseAtV3(schema.newConnection());
    final timestamp =
        DateTime.utc(2026, 8, 4, 16).millisecondsSinceEpoch ~/ 1000;
    final target = IssfTargetProfiles.precision25m50m;

    await old
        .into(old.trainingSessions)
        .insert(
          v3.TrainingSessionsCompanion.insert(
            id: 'v3-session',
            status: 'completed',
            startedAtUtc: timestamp,
            localUtcOffsetMinutes: 120,
            updatedAtUtc: timestamp,
          ),
        );
    await old
        .into(old.shootingSeries)
        .insert(
          v3.ShootingSeriesCompanion.insert(
            id: 'v3-series',
            sessionId: 'v3-session',
            sequenceNumber: 1,
            status: 'confirmed',
            targetProfileVersionedId: target.versionedId,
            targetProfileJson: target.toJsonString(),
            distanceMeters: 25,
            projectileDiameterMm: 5.6,
            shotCount: const Value(1),
            maximumPossibleScore: const Value(10),
            totalScore: const Value(7),
            createdAtUtc: timestamp,
            updatedAtUtc: timestamp,
          ),
        );
    await old
        .into(old.shotImpacts)
        .insert(
          v3.ShotImpactsCompanion.insert(
            id: 'v3-impact',
            seriesId: 'v3-series',
            xMm: 40,
            yMm: 0,
            scoreValue: 7,
          ),
        );
    await old.close();

    final database = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(database, 6);
    final series = await database.select(database.shootingSeries).getSingle();
    final impact = await database.select(database.shotImpacts).getSingle();

    expect(series.totalScore, 7);
    expect(series.maximumPossibleScore, 10);
    expect(series.scorePenalty, 0);
    expect(series.scoredBullCount, null);
    expect(impact.scoreValue, 7);
    expect(impact.rawScoreValue, 7);
    expect(impact.targetBullId, null);
    expect(impact.scoreDisposition, 'counted');
    expect(
      await database.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
    );

    await database.close();
    schema.close();
  });

  test('v4 percentage goals migrate to typed v6 goals', () async {
    final schema = await verifier.schemaAt(4);
    final old = v4.DatabaseAtV4(schema.newConnection());

    // Schema-v4 verification code intentionally exposes table metadata only,
    // so seed the legacy row through SQL instead of a generated companion.
    await old.customStatement(
      'INSERT INTO goals '
      '(id, target_profile_versioned_id, distance_meters, '
      'target_percentage, active) VALUES (?, ?, ?, ?, ?)',
      ['legacy-goal', 'target@1', 25.0, 82.5, 1],
    );
    await old.close();

    final database = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(database, 6);

    final goal = await database.select(database.goals).getSingle();
    expect(goal.id, 'legacy-goal');
    expect(goal.metric, 'scorePercentage');
    expect(goal.targetValue, 82.5);
    expect(goal.comparison, 'atLeast');
    expect(goal.active, isTrue);
    expect(await database.select(database.seriesReflections).get(), isEmpty);
    expect(await database.select(database.coachFeedback).get(), isEmpty);
    expect(
      await database.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
    );

    await database.close();
    schema.close();
  });

  test('v5 data migrates to v6 with empty training storage', () async {
    final schema = await verifier.schemaAt(5);
    final old = v5.DatabaseAtV5(schema.newConnection());

    expect(old.schemaVersion, 5);
    await old.close();

    final database = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(database, 6);

    expect(await database.select(database.trainingActivities).get(), isEmpty);
    expect(
      await database.select(database.trainingActivitySeriesLinks).get(),
      isEmpty,
    );
    expect(await database.select(database.shotTimerEvents).get(), isEmpty);
    expect(await database.select(database.timerPresets).get(), isEmpty);
    expect(
      await database.select(database.acousticCalibrationProfiles).get(),
      isEmpty,
    );
    expect(
      await database.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
    );

    await database.close();
    schema.close();
  });
}
