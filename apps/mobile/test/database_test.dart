import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';

void main() {
  late AppDatabase database;
  late ShootingRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ShootingRepository(database);
    await repository.seedDefaults();
  });

  tearDown(() => database.close());

  test('quick start creates one active session and one empty draft', () async {
    final result = await repository.startQuickSession();
    final detail = await repository.getSessionDetail(result.sessionId);

    expect(detail, isNotNull);
    expect(detail!.session.status, SessionStatus.active.name);
    expect(detail.draftSeries!.id, result.draftSeriesId);
    expect(
      detail.draftSeries!.targetProfileVersionedId,
      IssfTargetProfiles.precision25m50m.versionedId,
    );
    expect(detail.draftSeries!.cartridgeId, CartridgePresets.twentyTwoLr.id);
    expect(detail.draftSeries!.shotCount, 0);
    expect(
      () => repository.startQuickSession(),
      throwsA(isA<ActiveSessionExistsException>()),
    );
  });

  test(
    'draft scoring uses actual impacts and can be edited after confirm',
    () async {
      final quick = await repository.startQuickSession();
      final impacts = const [
        ShotImpact(id: 'center', xMm: 0, yMm: 0, multiplicity: 2),
        ShotImpact(id: 'miss', xMm: 0, yMm: 0, isMiss: true),
      ];
      await repository.saveSeriesDraft(
        seriesId: quick.draftSeriesId,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: impacts,
        cartridgeId: CartridgePresets.twentyTwoLr.id,
        notes: 'Eerste notitie',
      );

      var detail = await repository.getSeriesDetail(quick.draftSeriesId);
      expect(detail!.series.shotCount, 3);
      expect(detail.series.maximumPossibleScore, 30);
      expect(detail.series.totalScore, 20);
      expect(detail.series.missCount, 1);

      await repository.confirmSeries(quick.draftSeriesId);
      final createdAt = detail.series.createdAtUtc;
      await repository.replaceConfirmedSeries(
        seriesId: quick.draftSeriesId,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 50,
        projectileDiameterMm: 5.6,
        impacts: const [ShotImpact(id: 'edited', xMm: 0, yMm: 0)],
        cartridgeId: CartridgePresets.twentyTwoLr.id,
        notes: null,
      );

      detail = await repository.getSeriesDetail(quick.draftSeriesId);
      expect(detail!.series.status, SeriesStatus.confirmed.name);
      expect(detail.series.createdAtUtc, createdAt);
      expect(detail.series.shotCount, 1);
      expect(detail.series.maximumPossibleScore, 10);
      expect(detail.series.notes, isNull);
      expect(detail.impacts.single.id, 'edited');
    },
  );

  test(
    'complete removes truly empty session and reopen enforces uniqueness',
    () async {
      final empty = await repository.startQuickSession();
      await repository.completeSession(empty.sessionId);
      expect(await repository.getSessionDetail(empty.sessionId), isNull);

      final first = await repository.startQuickSession();
      await repository.saveSeriesDraft(
        seriesId: first.draftSeriesId,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: const [ShotImpact(id: 'shot', xMm: 0, yMm: 0)],
      );
      await repository.confirmSeries(first.draftSeriesId);
      await repository.completeSession(first.sessionId);

      final second = await repository.startQuickSession();
      expect(
        () => repository.reopenSession(first.sessionId),
        throwsA(isA<ActiveSessionExistsException>()),
      );
      await repository.completeSession(second.sessionId);
      await repository.reopenSession(first.sessionId);
      expect(
        (await repository.getSessionDetail(first.sessionId))!.session.status,
        SessionStatus.active.name,
      );
    },
  );

  test('session fields can be changed and explicitly cleared', () async {
    final quick = await repository.startQuickSession();
    final changedAt = DateTime.utc(2026, 8, 2, 18, 30);
    await repository.updateSessionDetails(
      sessionId: quick.sessionId,
      startedAtUtc: changedAt,
      localUtcOffsetMinutes: 120,
      rangeId: null,
      trainingGoal: 'Groepering',
      conditions: 'Binnen',
      notes: 'Test',
    );
    await repository.updateSessionDetails(
      sessionId: quick.sessionId,
      startedAtUtc: changedAt,
      localUtcOffsetMinutes: 120,
      rangeId: null,
      trainingGoal: null,
      conditions: null,
      notes: null,
    );

    final session = (await repository.getSessionDetail(
      quick.sessionId,
    ))!.session;
    expect(session.startedAtUtc.toUtc(), changedAt);
    expect(session.trainingGoal, isNull);
    expect(session.conditions, isNull);
    expect(session.notes, isNull);
  });

  test('primary photo, alignment and impact provenance persist', () async {
    final quick = await repository.startQuickSession();
    final firstImageId = await repository.attachImage(
      NewImageAsset(
        id: 'first-image',
        sessionId: quick.sessionId,
        seriesId: quick.draftSeriesId,
        role: ImageRole.primaryScoringPhoto,
        path: 'missing-first.jpg',
        sha256: 'a',
        width: 2000,
        height: 2000,
        sizeBytes: 10,
      ),
    );
    await repository.savePhotoAlignment(
      StoredPhotoAlignment(
        imageId: firstImageId,
        orderedCorners: const [
          NormalizedPoint(x: 0.1, y: 0.1),
          NormalizedPoint(x: 0.9, y: 0.1),
          NormalizedPoint(x: 0.9, y: 0.9),
          NormalizedPoint(x: 0.1, y: 0.9),
        ],
        homographyMatrix: const [1, 0, 0, 0, 1, 0, 0, 0, 1],
        algorithmVersion: 'manual-homography-v1',
        updatedAtUtc: DateTime.utc(2026, 8, 3),
      ),
    );
    await repository.saveSeriesDraft(
      seriesId: quick.draftSeriesId,
      target: IssfTargetProfiles.precision25m50m,
      distanceMeters: 25,
      projectileDiameterMm: 5.6,
      impacts: const [
        ShotImpact(
          id: 'photo-shot',
          xMm: 0,
          yMm: 0,
          sourceImageId: 'first-image',
          imageXNormalized: 0.5,
          imageYNormalized: 0.5,
        ),
      ],
    );

    final secondImageId = await repository.attachImage(
      NewImageAsset(
        id: 'second-image',
        sessionId: quick.sessionId,
        seriesId: quick.draftSeriesId,
        role: ImageRole.primaryScoringPhoto,
        path: 'missing-second.jpg',
        sha256: 'b',
        width: 2000,
        height: 2000,
        sizeBytes: 10,
      ),
    );
    var detail = await repository.getSeriesDetail(quick.draftSeriesId);
    expect(detail!.primaryImage!.id, secondImageId);
    expect(
      detail.images.singleWhere((image) => image.id == firstImageId).role,
      ImageRole.attachment.name,
    );
    expect(detail.photoAlignment, isNull);

    await repository.deleteImage(firstImageId);
    detail = await repository.getSeriesDetail(quick.draftSeriesId);
    expect(detail!.impacts.single.sourceImageId, isNull);
  });

  test(
    'deleting series renumbers siblings and deleting session removes files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'shooting-data-test',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final image = File(
        '${directory.path}${Platform.pathSeparator}target.jpg',
      );
      await image.writeAsBytes([1, 2, 3]);

      final quick = await repository.startQuickSession();
      await repository.saveSeriesDraft(
        seriesId: quick.draftSeriesId,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: const [ShotImpact(id: 'one', xMm: 0, yMm: 0)],
      );
      await repository.confirmSeries(quick.draftSeriesId);
      final second = await repository.createOrResumeDraftSeries(
        quick.sessionId,
      );
      await repository.saveSeriesDraft(
        seriesId: second,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: const [ShotImpact(id: 'two', xMm: 0, yMm: 0)],
      );
      await repository.confirmSeries(second);
      await repository.attachImage(
        NewImageAsset(
          sessionId: quick.sessionId,
          seriesId: second,
          role: ImageRole.attachment,
          path: image.path,
          sha256: 'hash',
          width: 100,
          height: 100,
          sizeBytes: 3,
        ),
      );

      await repository.deleteSeries(quick.draftSeriesId);
      expect(
        (await repository.getSeriesDetail(second))!.series.sequenceNumber,
        1,
      );
      await repository.deleteSession(quick.sessionId);
      expect(await image.exists(), isFalse);
      expect(await database.select(database.shotImpacts).get(), isEmpty);
      expect(await database.select(database.imageAssets).get(), isEmpty);
    },
  );

  test(
    'library removal deletes unused records and archives used records',
    () async {
      final unusedRange = await repository.addRange(
        name: 'Ongebruikte stand',
        isIndoor: true,
      );
      expect(
        await repository.removeRange(unusedRange),
        LibraryRemovalResult.deleted,
      );

      final firearm = await repository.addFirearm(
        name: 'Gebruikt pistool',
        type: FirearmType.pistol,
      );
      final quick = await repository.startQuickSession();
      await repository.saveSeriesDraft(
        seriesId: quick.draftSeriesId,
        target: IssfTargetProfiles.precision25m50m,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: const [ShotImpact(id: 'library-shot', xMm: 0, yMm: 0)],
        firearmId: firearm,
      );
      await repository.confirmSeries(quick.draftSeriesId);

      expect(
        await repository.removeFirearm(firearm),
        LibraryRemovalResult.archived,
      );
      expect(
        (await database.select(database.firearms).getSingle()).archived,
        isTrue,
      );
      await repository.restoreFirearm(firearm);
      expect(
        (await database.select(database.firearms).getSingle()).archived,
        isFalse,
      );
    },
  );

  test('invalid firearm update leaves the stored record unchanged', () async {
    final firearmId = await repository.addFirearm(
      name: 'Bewaar mijn naam',
      type: FirearmType.pistol,
    );

    await expectLater(
      repository.updateFirearm(
        id: firearmId,
        name: '   ',
        type: FirearmType.revolver,
      ),
      throwsArgumentError,
    );

    final firearm = await (database.select(
      database.firearms,
    )..where((row) => row.id.equals(firearmId))).getSingle();
    expect(firearm.name, 'Bewaar mijn naam');
    expect(firearm.type, FirearmType.pistol.name);
  });

  test(
    'built-ins are protected and custom cartridge dependencies archive atomically',
    () async {
      expect(
        await repository.removeCartridge(CartridgePresets.twentyTwoLr.id),
        LibraryRemovalResult.blockedBuiltIn,
      );
      final custom = await repository.duplicateCartridge(
        CartridgePresets.twentyTwoLr.id,
      );
      final ammo = await repository.addAmmoLot(
        cartridgeId: custom,
        displayName: 'Testlot',
      );
      expect(
        await repository.removeCartridge(custom),
        LibraryRemovalResult.blockedDependency,
      );
      expect(
        await repository.removeCartridge(custom, archiveDependents: true),
        LibraryRemovalResult.archived,
      );
      expect(
        (await (database.select(
          database.cartridges,
        )..where((row) => row.id.equals(custom))).getSingle()).archived,
        isTrue,
      );
      expect(
        (await (database.select(
          database.ammoLots,
        )..where((row) => row.id.equals(ammo))).getSingle()).archived,
        isTrue,
      );
    },
  );

  test(
    'editing a used custom target creates a new immutable version',
    () async {
      final duplicateId = await repository.duplicateTargetProfile(
        IssfTargetProfiles.precision25m50m.versionedId,
      );
      final duplicateRecord = await (database.select(
        database.targetProfiles,
      )..where((row) => row.versionedId.equals(duplicateId))).getSingle();
      final duplicate = TargetProfile.fromJsonString(
        duplicateRecord.profileJson,
      );
      final quick = await repository.startQuickSession(
        defaults: SeriesDefaults(
          target: duplicate,
          distanceMeters: 25,
          projectileDiameterMm: 5.6,
        ),
      );
      await repository.saveSeriesDraft(
        seriesId: quick.draftSeriesId,
        target: duplicate,
        distanceMeters: 25,
        projectileDiameterMm: 5.6,
        impacts: const [ShotImpact(id: 'target-shot', xMm: 0, yMm: 0)],
      );
      await repository.confirmSeries(quick.draftSeriesId);

      final edited = TargetProfile(
        schemaVersion: duplicate.schemaVersion,
        profileId: duplicate.profileId,
        profileVersion: duplicate.profileVersion,
        displayName: 'Nieuwe kaartnaam',
        authority: duplicate.authority,
        rulesEdition: duplicate.rulesEdition,
        physicalCardWidthMm: duplicate.physicalCardWidthMm,
        physicalCardHeightMm: duplicate.physicalCardHeightMm,
        rings: duplicate.rings,
        lineThicknessMm: duplicate.lineThicknessMm,
        lineBreakingRule: duplicate.lineBreakingRule,
        validationStatus: duplicate.validationStatus,
      );
      final newId = await repository.saveCustomTargetEdit(duplicateId, edited);
      expect(newId, '${duplicate.profileId}@2');
      expect(
        (await (database.select(
              database.targetProfiles,
            )..where((row) => row.versionedId.equals(duplicateId))).getSingle())
            .archived,
        isTrue,
      );
      expect(
        (await (database.select(
              database.shootingSeries,
            )..where((row) => row.id.equals(quick.draftSeriesId))).getSingle())
            .targetProfileVersionedId,
        duplicateId,
      );
    },
  );
}
