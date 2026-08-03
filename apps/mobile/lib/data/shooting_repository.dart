import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_scoring/scoring.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

class ActiveSessionExistsException implements Exception {
  const ActiveSessionExistsException(this.sessionId);

  final String sessionId;

  @override
  String toString() => 'Er is al een actieve sessie: $sessionId';
}

class QuickSessionResult {
  const QuickSessionResult({
    required this.sessionId,
    required this.draftSeriesId,
  });

  final String sessionId;
  final String draftSeriesId;
}

class SeriesDefaults {
  const SeriesDefaults({
    required this.target,
    required this.distanceMeters,
    required this.projectileDiameterMm,
    this.cartridgeId,
    this.firearmId,
    this.ammoLotId,
  });

  factory SeriesDefaults.standard() => SeriesDefaults(
    target: IssfTargetProfiles.precision25m50m,
    distanceMeters: 25,
    projectileDiameterMm: CartridgePresets.twentyTwoLr.projectileDiameterMm,
    cartridgeId: CartridgePresets.twentyTwoLr.id,
  );

  factory SeriesDefaults.fromRecord(SeriesRecord record) => SeriesDefaults(
    target: domain.TargetProfile.fromJsonString(record.targetProfileJson),
    distanceMeters: record.distanceMeters,
    projectileDiameterMm: record.projectileDiameterMm,
    cartridgeId: record.cartridgeId,
    firearmId: record.firearmId,
    ammoLotId: record.ammoLotId,
  );

  final domain.TargetProfile target;
  final double distanceMeters;
  final double projectileDiameterMm;
  final String? cartridgeId;
  final String? firearmId;
  final String? ammoLotId;
}

class NewImageAsset {
  const NewImageAsset({
    this.id,
    required this.sessionId,
    this.seriesId,
    required this.role,
    required this.path,
    required this.sha256,
    required this.width,
    required this.height,
    required this.sizeBytes,
    this.caption,
  });

  final String? id;
  final String sessionId;
  final String? seriesId;
  final domain.ImageRole role;
  final String path;
  final String sha256;
  final int width;
  final int height;
  final int sizeBytes;
  final String? caption;
}

class SessionDetail {
  const SessionDetail({
    required this.session,
    required this.confirmedSeries,
    required this.draftSeries,
    required this.images,
  });

  final SessionRecord session;
  final List<SeriesRecord> confirmedSeries;
  final SeriesRecord? draftSeries;
  final List<ImageAssetRecord> images;

  int get seriesCount => confirmedSeries.length;
  int get shotCount =>
      confirmedSeries.fold(0, (sum, series) => sum + series.shotCount);
  int get totalScore =>
      confirmedSeries.fold(0, (sum, series) => sum + series.totalScore);
  int get maximumPossibleScore => confirmedSeries.fold(
    0,
    (sum, series) => sum + series.maximumPossibleScore,
  );
  int get innerTenCount =>
      confirmedSeries.fold(0, (sum, series) => sum + series.innerTenCount);
  int get photoCount => images.length;
}

class SeriesDetail {
  const SeriesDetail({
    required this.series,
    required this.impacts,
    required this.images,
    required this.primaryImage,
    required this.photoAlignment,
  });

  final SeriesRecord series;
  final List<ImpactRecord> impacts;
  final List<ImageAssetRecord> images;
  final ImageAssetRecord? primaryImage;
  final PhotoAlignmentRecord? photoAlignment;

  domain.TargetProfile get target =>
      domain.TargetProfile.fromJsonString(series.targetProfileJson);
}

class ShootingRepository {
  ShootingRepository(this.database, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase database;
  final Uuid _uuid;

  Stream<List<SessionRecord>> watchSessions() => database.watchSessions();

  Stream<SessionRecord?> watchActiveSession() => database.watchActiveSession();

  Stream<List<SeriesRecord>> watchSeries(String sessionId) =>
      database.watchSeries(sessionId);

  Stream<List<SeriesRecord>> watchConfirmedSeries() =>
      database.watchConfirmedSeries();

  Stream<List<ImpactRecord>> watchImpacts(String seriesId) =>
      database.watchImpacts(seriesId);

  Stream<List<ImageAssetRecord>> watchSessionImages(String sessionId) =>
      database.watchSessionImages(sessionId);

  Stream<List<ImageAssetRecord>> watchSeriesImages(String seriesId) =>
      database.watchSeriesImages(seriesId);

  Stream<SessionDetail?> watchSessionDetail(String sessionId) => database
      .customSelect(
        'SELECT 1',
        readsFrom: {
          database.trainingSessions,
          database.shootingSeries,
          database.imageAssets,
        },
      )
      .watch()
      .asyncMap((_) => getSessionDetail(sessionId));

  Stream<SeriesDetail?> watchSeriesDetail(String seriesId) => database
      .customSelect(
        'SELECT 1',
        readsFrom: {
          database.shootingSeries,
          database.shotImpacts,
          database.imageAssets,
          database.photoAlignments,
        },
      )
      .watch()
      .asyncMap((_) => getSeriesDetail(seriesId));

  Stream<List<FirearmRecord>> watchFirearms() => database.watchFirearms();

  Stream<List<CartridgeRecord>> watchCartridges() => database.watchCartridges();

  Stream<List<AmmoLotRecord>> watchAmmoLots() => database.watchAmmoLots();

  Stream<List<RangeRecord>> watchRanges() => database.watchRanges();

  Stream<List<TargetProfileRecord>> watchTargetProfiles() =>
      database.watchTargetProfiles();

  Future<void> seedDefaults() async {
    await database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        database.cartridges,
        CartridgePresets.all
            .map(
              (cartridge) => CartridgesCompanion.insert(
                id: cartridge.id,
                name: cartridge.name,
                projectileDiameterMm: cartridge.projectileDiameterMm,
                notes: Value(cartridge.notes),
              ),
            )
            .toList(),
      );
      batch.insertAllOnConflictUpdate(
        database.targetProfiles,
        IssfTargetProfiles.all
            .map(
              (target) => TargetProfilesCompanion.insert(
                versionedId: target.versionedId,
                profileId: target.profileId,
                profileVersion: target.profileVersion,
                displayName: target.displayName,
                validationStatus: target.validationStatus.name,
                profileJson: target.toJsonString(),
                builtIn: const Value(true),
                createdAtUtc: DateTime.utc(2026, 1, 1),
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> addCustomTargetProfile(domain.TargetProfile profile) async {
    await database
        .into(database.targetProfiles)
        .insert(
          TargetProfilesCompanion.insert(
            versionedId: profile.versionedId,
            profileId: profile.profileId,
            profileVersion: profile.profileVersion,
            displayName: profile.displayName,
            validationStatus: profile.validationStatus.name,
            profileJson: profile.toJsonString(),
            createdAtUtc: DateTime.now().toUtc(),
          ),
        );
  }

  Future<String> addFirearm({
    required String name,
    required domain.FirearmType type,
    String? manufacturer,
    String? model,
    String? defaultCartridgeId,
    String? sightNotes,
  }) async {
    final id = _uuid.v7();
    await database
        .into(database.firearms)
        .insert(
          FirearmsCompanion.insert(
            id: id,
            name: name.trim(),
            type: type.name,
            manufacturer: Value(_nullIfBlank(manufacturer)),
            model: Value(_nullIfBlank(model)),
            defaultCartridgeId: Value(defaultCartridgeId),
            sightNotes: Value(_nullIfBlank(sightNotes)),
          ),
        );
    return id;
  }

  Future<String> addAmmoLot({
    required String cartridgeId,
    required String displayName,
    String? manufacturer,
    String? productName,
    String? lotNumber,
    double? bulletWeightGrains,
    String? projectileType,
    String? notes,
  }) async {
    final id = _uuid.v7();
    await database
        .into(database.ammoLots)
        .insert(
          AmmoLotsCompanion.insert(
            id: id,
            cartridgeId: cartridgeId,
            displayName: displayName.trim(),
            manufacturer: Value(_nullIfBlank(manufacturer)),
            productName: Value(_nullIfBlank(productName)),
            lotNumber: Value(_nullIfBlank(lotNumber)),
            bulletWeightGrains: Value(bulletWeightGrains),
            projectileType: Value(_nullIfBlank(projectileType)),
            notes: Value(_nullIfBlank(notes)),
          ),
        );
    return id;
  }

  Future<String> addRange({
    required String name,
    required bool isIndoor,
    String? locationDescription,
    List<double> availableDistances = const [],
    String? notes,
  }) async {
    final id = _uuid.v7();
    await database
        .into(database.ranges)
        .insert(
          RangesCompanion.insert(
            id: id,
            name: name.trim(),
            isIndoor: Value(isIndoor),
            locationDescription: Value(_nullIfBlank(locationDescription)),
            availableDistancesJson: Value(jsonEncode(availableDistances)),
            notes: Value(_nullIfBlank(notes)),
          ),
        );
    return id;
  }

  Future<QuickSessionResult> startQuickSession({SeriesDefaults? defaults}) =>
      database.transaction(() async {
        final active = await _activeSession();
        if (active != null) throw ActiveSessionExistsException(active.id);

        final now = DateTime.now();
        final sessionId = _uuid.v7();
        await database
            .into(database.trainingSessions)
            .insert(
              TrainingSessionsCompanion.insert(
                id: sessionId,
                status: domain.SessionStatus.active.name,
                startedAtUtc: now.toUtc(),
                localUtcOffsetMinutes: now.timeZoneOffset.inMinutes,
                updatedAtUtc: now.toUtc(),
              ),
            );
        final resolved = defaults ?? await _lastUsedDefaults();
        final seriesId = await _insertDraftSeries(
          sessionId: sessionId,
          sequenceNumber: 1,
          defaults: resolved,
        );
        return QuickSessionResult(
          sessionId: sessionId,
          draftSeriesId: seriesId,
        );
      });

  Future<String> createOrResumeDraftSeries(
    String sessionId, {
    SeriesDefaults? defaults,
  }) => database.transaction(() async {
    final session = await _session(sessionId);
    if (session == null) {
      throw StateError('De sessie bestaat niet.');
    }
    if (session.status != domain.SessionStatus.active.name) {
      throw StateError(
        'Alleen een actieve sessie kan een conceptreeks hebben.',
      );
    }
    final existing =
        await (database.select(database.shootingSeries)
              ..where(
                (row) =>
                    row.sessionId.equals(sessionId) &
                    row.status.equals(domain.SeriesStatus.draft.name),
              )
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) return existing.id;

    final sessionSeries =
        await (database.select(database.shootingSeries)
              ..where((row) => row.sessionId.equals(sessionId))
              ..orderBy([(row) => OrderingTerm.desc(row.sequenceNumber)]))
            .get();
    final resolved =
        defaults ??
        (sessionSeries.isEmpty
            ? await _lastUsedDefaults()
            : SeriesDefaults.fromRecord(sessionSeries.first));
    final nextSequence = sessionSeries.isEmpty
        ? 1
        : sessionSeries.first.sequenceNumber + 1;
    return _insertDraftSeries(
      sessionId: sessionId,
      sequenceNumber: nextSequence,
      defaults: resolved,
    );
  });

  Future<void> saveSeriesDraft({
    required String seriesId,
    required domain.TargetProfile target,
    required double distanceMeters,
    required double projectileDiameterMm,
    required List<domain.ShotImpact> impacts,
    String? cartridgeId,
    String? firearmId,
    String? ammoLotId,
    String? notes,
  }) => _replaceSeries(
    seriesId: seriesId,
    expectedStatus: domain.SeriesStatus.draft,
    target: target,
    distanceMeters: distanceMeters,
    projectileDiameterMm: projectileDiameterMm,
    impacts: impacts,
    cartridgeId: cartridgeId,
    firearmId: firearmId,
    ammoLotId: ammoLotId,
    notes: notes,
  );

  Future<void> replaceConfirmedSeries({
    required String seriesId,
    required domain.TargetProfile target,
    required double distanceMeters,
    required double projectileDiameterMm,
    required List<domain.ShotImpact> impacts,
    String? cartridgeId,
    String? firearmId,
    String? ammoLotId,
    String? notes,
  }) => _replaceSeries(
    seriesId: seriesId,
    expectedStatus: domain.SeriesStatus.confirmed,
    target: target,
    distanceMeters: distanceMeters,
    projectileDiameterMm: projectileDiameterMm,
    impacts: impacts,
    cartridgeId: cartridgeId,
    firearmId: firearmId,
    ammoLotId: ammoLotId,
    notes: notes,
  );

  Future<void> confirmSeries(String seriesId) => database.transaction(() async {
    final series = await _series(seriesId);
    if (series == null) throw StateError('De reeks bestaat niet.');
    if (series.status != domain.SeriesStatus.draft.name) {
      throw StateError('Alleen een conceptreeks kan worden bevestigd.');
    }
    if (series.shotCount <= 0) {
      throw StateError('Voeg minstens één treffer of misser toe.');
    }
    final now = DateTime.now().toUtc();
    await (database.update(
      database.shootingSeries,
    )..where((row) => row.id.equals(seriesId))).write(
      ShootingSeriesCompanion(
        status: Value(domain.SeriesStatus.confirmed.name),
        updatedAtUtc: Value(now),
        confirmedAtUtc: Value(now),
      ),
    );
    await _touchSession(series.sessionId, now);
  });

  Future<void> updateSessionDetails({
    required String sessionId,
    required DateTime startedAtUtc,
    required int localUtcOffsetMinutes,
    required String? rangeId,
    required String? trainingGoal,
    required String? conditions,
    required String? notes,
  }) async {
    final changed =
        await (database.update(
          database.trainingSessions,
        )..where((row) => row.id.equals(sessionId))).write(
          TrainingSessionsCompanion(
            startedAtUtc: Value(startedAtUtc.toUtc()),
            localUtcOffsetMinutes: Value(localUtcOffsetMinutes),
            updatedAtUtc: Value(DateTime.now().toUtc()),
            rangeId: Value(rangeId),
            trainingGoal: Value(_nullIfBlank(trainingGoal)),
            conditions: Value(_nullIfBlank(conditions)),
            notes: Value(_nullIfBlank(notes)),
          ),
        );
    if (changed != 1) throw StateError('De sessie bestaat niet.');
  }

  Future<void> acknowledgePhotoSafety(String sessionId) async {
    final now = DateTime.now().toUtc();
    final changed =
        await (database.update(
          database.trainingSessions,
        )..where((row) => row.id.equals(sessionId))).write(
          TrainingSessionsCompanion(
            photoSafetyAcknowledgedAtUtc: Value(now),
            updatedAtUtc: Value(now),
          ),
        );
    if (changed != 1) throw StateError('De sessie bestaat niet.');
  }

  Future<void> completeSession(String sessionId) async {
    final detail = await getSessionDetail(sessionId);
    if (detail == null) throw StateError('De sessie bestaat niet.');
    if (detail.confirmedSeries.isEmpty &&
        (detail.draftSeries == null || detail.draftSeries!.shotCount == 0) &&
        detail.images.isEmpty) {
      await deleteSession(sessionId);
      return;
    }

    await database.transaction(() async {
      final draft = detail.draftSeries;
      if (draft != null && draft.shotCount == 0) {
        await (database.delete(
          database.shootingSeries,
        )..where((row) => row.id.equals(draft.id))).go();
      }
      final now = DateTime.now().toUtc();
      await (database.update(
        database.trainingSessions,
      )..where((row) => row.id.equals(sessionId))).write(
        TrainingSessionsCompanion(
          status: Value(domain.SessionStatus.completed.name),
          endedAtUtc: Value(now),
          updatedAtUtc: Value(now),
        ),
      );
      await _renumberSeries(sessionId);
    });
  }

  Future<void> reopenSession(String sessionId) =>
      database.transaction(() async {
        final active = await _activeSession();
        if (active != null && active.id != sessionId) {
          throw ActiveSessionExistsException(active.id);
        }
        final now = DateTime.now().toUtc();
        final changed =
            await (database.update(
              database.trainingSessions,
            )..where((row) => row.id.equals(sessionId))).write(
              TrainingSessionsCompanion(
                status: Value(domain.SessionStatus.active.name),
                endedAtUtc: const Value(null),
                updatedAtUtc: Value(now),
              ),
            );
        if (changed != 1) throw StateError('De sessie bestaat niet.');
      });

  Future<List<String>> attachImagesAtomically(Iterable<NewImageAsset> assets) =>
      database.transaction(() async {
        final ids = <String>[];
        for (final asset in assets) {
          ids.add(await _attachImage(asset));
        }
        return ids;
      });

  Future<String> attachImage(NewImageAsset asset) =>
      database.transaction(() => _attachImage(asset));

  Future<void> setPrimaryScoringImage(String imageId) =>
      database.transaction(() async {
        final image = await _image(imageId);
        if (image == null) throw StateError('De foto bestaat niet.');
        final seriesId = image.seriesId;
        if (seriesId == null) {
          throw StateError('Een sessiefoto kan geen primaire scorefoto zijn.');
        }
        final oldPrimary =
            await (database.select(database.imageAssets)
                  ..where(
                    (row) =>
                        row.seriesId.equals(seriesId) &
                        row.role.equals(
                          domain.ImageRole.primaryScoringPhoto.name,
                        ),
                  )
                  ..limit(1))
                .getSingleOrNull();
        final now = DateTime.now().toUtc();
        if (oldPrimary != null && oldPrimary.id != imageId) {
          await (database.update(
            database.imageAssets,
          )..where((row) => row.id.equals(oldPrimary.id))).write(
            ImageAssetsCompanion(
              role: Value(domain.ImageRole.attachment.name),
              updatedAtUtc: Value(now),
            ),
          );
          await (database.delete(
            database.photoAlignments,
          )..where((row) => row.imageId.equals(oldPrimary.id))).go();
        }
        await (database.update(
          database.imageAssets,
        )..where((row) => row.id.equals(imageId))).write(
          ImageAssetsCompanion(
            role: Value(domain.ImageRole.primaryScoringPhoto.name),
            updatedAtUtc: Value(now),
          ),
        );
        await _touchSession(image.sessionId, now);
      });

  Future<void> updateImageCaption(String imageId, String? caption) async {
    final changed =
        await (database.update(
          database.imageAssets,
        )..where((row) => row.id.equals(imageId))).write(
          ImageAssetsCompanion(
            caption: Value(_nullIfBlank(caption)),
            updatedAtUtc: Value(DateTime.now().toUtc()),
          ),
        );
    if (changed != 1) throw StateError('De foto bestaat niet.');
  }

  Future<void> savePhotoAlignment(
    domain.StoredPhotoAlignment alignment,
  ) => database.transaction(() async {
    final image = await _image(alignment.imageId);
    if (image == null ||
        image.seriesId == null ||
        image.role != domain.ImageRole.primaryScoringPhoto.name) {
      throw StateError('Alleen een primaire scorefoto kan worden uitgelijnd.');
    }
    await database
        .into(database.photoAlignments)
        .insertOnConflictUpdate(
          PhotoAlignmentsCompanion.insert(
            imageId: alignment.imageId,
            cornersJson: jsonEncode(
              alignment.orderedCorners.map((point) => point.toJson()).toList(),
            ),
            matrixJson: jsonEncode(alignment.homographyMatrix),
            algorithmVersion: alignment.algorithmVersion,
            updatedAtUtc: alignment.updatedAtUtc.toUtc(),
          ),
        );
    await _touchSession(image.sessionId, alignment.updatedAtUtc.toUtc());
  });

  Future<void> deleteImage(String imageId) async {
    final image = await _image(imageId);
    if (image == null) return;
    await database.transaction(() async {
      await (database.delete(
        database.imageAssets,
      )..where((row) => row.id.equals(imageId))).go();
      await _touchSession(image.sessionId, DateTime.now().toUtc());
    });
    await _deleteFileIfPresent(image.path);
  }

  Future<SessionDetail?> getSessionDetail(String sessionId) async {
    final session = await _session(sessionId);
    if (session == null) return null;
    final series =
        await (database.select(database.shootingSeries)
              ..where((row) => row.sessionId.equals(sessionId))
              ..orderBy([(row) => OrderingTerm.asc(row.sequenceNumber)]))
            .get();
    final images =
        await (database.select(database.imageAssets)
              ..where((row) => row.sessionId.equals(sessionId))
              ..orderBy([(row) => OrderingTerm.desc(row.createdAtUtc)]))
            .get();
    return SessionDetail(
      session: session,
      confirmedSeries: series
          .where((item) => item.status == domain.SeriesStatus.confirmed.name)
          .toList(growable: false),
      draftSeries: series
          .where((item) => item.status == domain.SeriesStatus.draft.name)
          .firstOrNull,
      images: images,
    );
  }

  Future<SeriesDetail?> getSeriesDetail(String seriesId) async {
    final series = await _series(seriesId);
    if (series == null) return null;
    final impacts = await (database.select(
      database.shotImpacts,
    )..where((row) => row.seriesId.equals(seriesId))).get();
    final images =
        await (database.select(database.imageAssets)
              ..where((row) => row.seriesId.equals(seriesId))
              ..orderBy([(row) => OrderingTerm.desc(row.createdAtUtc)]))
            .get();
    final primary = images
        .where(
          (image) => image.role == domain.ImageRole.primaryScoringPhoto.name,
        )
        .firstOrNull;
    final alignment = primary == null
        ? null
        : await (database.select(
            database.photoAlignments,
          )..where((row) => row.imageId.equals(primary.id))).getSingleOrNull();
    return SeriesDetail(
      series: series,
      impacts: impacts,
      images: images,
      primaryImage: primary,
      photoAlignment: alignment,
    );
  }

  Future<List<SeriesRecord>> getConfirmedSeries() =>
      (database.select(database.shootingSeries)
            ..where(
              (row) => row.status.equals(domain.SeriesStatus.confirmed.name),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.createdAtUtc)]))
          .get();

  Future<List<ImpactRecord>> getAllImpacts() =>
      database.select(database.shotImpacts).get();

  String targetNameFor(SeriesRecord series) =>
      domain.TargetProfile.fromJsonString(series.targetProfileJson).displayName;

  Future<void> deleteSeries(String seriesId) async {
    final series = await _series(seriesId);
    if (series == null) return;
    final images = await (database.select(
      database.imageAssets,
    )..where((row) => row.seriesId.equals(seriesId))).get();
    await database.transaction(() async {
      await (database.delete(
        database.shootingSeries,
      )..where((row) => row.id.equals(seriesId))).go();
      await _renumberSeries(series.sessionId);
      await _touchSession(series.sessionId, DateTime.now().toUtc());
    });
    for (final image in images) {
      await _deleteFileIfPresent(image.path);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final images = await (database.select(
      database.imageAssets,
    )..where((row) => row.sessionId.equals(sessionId))).get();
    await (database.delete(
      database.trainingSessions,
    )..where((row) => row.id.equals(sessionId))).go();
    for (final image in images) {
      await _deleteFileIfPresent(image.path);
    }
  }

  Future<String> _insertDraftSeries({
    required String sessionId,
    required int sequenceNumber,
    required SeriesDefaults defaults,
  }) async {
    if (defaults.distanceMeters <= 0 || defaults.projectileDiameterMm <= 0) {
      throw ArgumentError(
        'Afstand en projectieldiameter moeten positief zijn.',
      );
    }
    final id = _uuid.v7();
    final now = DateTime.now().toUtc();
    await database
        .into(database.shootingSeries)
        .insert(
          ShootingSeriesCompanion.insert(
            id: id,
            sessionId: sessionId,
            sequenceNumber: sequenceNumber,
            status: domain.SeriesStatus.draft.name,
            targetProfileVersionedId: defaults.target.versionedId,
            targetProfileJson: defaults.target.toJsonString(),
            distanceMeters: defaults.distanceMeters,
            projectileDiameterMm: defaults.projectileDiameterMm,
            cartridgeId: Value(defaults.cartridgeId),
            firearmId: Value(defaults.firearmId),
            ammoLotId: Value(defaults.ammoLotId),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
    return id;
  }

  Future<void> _replaceSeries({
    required String seriesId,
    required domain.SeriesStatus expectedStatus,
    required domain.TargetProfile target,
    required double distanceMeters,
    required double projectileDiameterMm,
    required List<domain.ShotImpact> impacts,
    required String? cartridgeId,
    required String? firearmId,
    required String? ammoLotId,
    required String? notes,
  }) => database.transaction(() async {
    final existing = await _series(seriesId);
    if (existing == null) throw StateError('De reeks bestaat niet.');
    if (existing.status != expectedStatus.name) {
      throw StateError('De reeksstatus is intussen gewijzigd.');
    }
    if (distanceMeters <= 0 || projectileDiameterMm <= 0) {
      throw ArgumentError(
        'Afstand en projectieldiameter moeten positief zijn.',
      );
    }
    final targetChanged =
        existing.targetProfileVersionedId != target.versionedId;
    final normalizedImpacts = targetChanged
        ? impacts
              .map(
                (impact) => impact.copyWith(
                  clearSourceImage: true,
                  clearImageCoordinates: true,
                ),
              )
              .toList(growable: false)
        : impacts;
    final score = ScoreEngine.score(
      target: target,
      impacts: normalizedImpacts,
      projectileDiameterMm: projectileDiameterMm,
    );
    final now = DateTime.now().toUtc();

    await (database.update(
      database.shootingSeries,
    )..where((row) => row.id.equals(seriesId))).write(
      ShootingSeriesCompanion(
        targetProfileVersionedId: Value(target.versionedId),
        targetProfileJson: Value(target.toJsonString()),
        distanceMeters: Value(distanceMeters),
        projectileDiameterMm: Value(projectileDiameterMm),
        cartridgeId: Value(cartridgeId),
        firearmId: Value(firearmId),
        ammoLotId: Value(ammoLotId),
        notes: Value(_nullIfBlank(notes)),
        shotCount: Value(score.actualShotCount),
        maximumPossibleScore: Value(score.maximumPossible),
        totalScore: Value(score.total),
        innerTenCount: Value(score.innerTenCount),
        missCount: Value(score.missCount),
        hasBoundaryWarnings: Value(score.hasBoundaryWarnings),
        updatedAtUtc: Value(now),
      ),
    );
    await (database.delete(
      database.shotImpacts,
    )..where((row) => row.seriesId.equals(seriesId))).go();
    for (final shot in score.shots) {
      await database
          .into(database.shotImpacts)
          .insert(
            ShotImpactsCompanion.insert(
              id: shot.impact.id,
              seriesId: seriesId,
              xMm: shot.impact.xMm,
              yMm: shot.impact.yMm,
              sourceImageId: Value(shot.impact.sourceImageId),
              imageXNormalized: Value(shot.impact.imageXNormalized),
              imageYNormalized: Value(shot.impact.imageYNormalized),
              multiplicity: Value(shot.impact.multiplicity),
              isMiss: Value(shot.impact.isMiss),
              isPositionUncertain: Value(shot.impact.isPositionUncertain),
              scoreValue: shot.value,
              isInnerTen: Value(shot.isInnerTen),
              isBoundaryUncertain: Value(shot.isBoundaryUncertain),
            ),
          );
    }
    if (targetChanged) {
      final images = await (database.select(
        database.imageAssets,
      )..where((row) => row.seriesId.equals(seriesId))).get();
      for (final image in images) {
        await (database.delete(
          database.photoAlignments,
        )..where((row) => row.imageId.equals(image.id))).go();
      }
    }
    await _touchSession(existing.sessionId, now);
  });

  Future<String> _attachImage(NewImageAsset asset) async {
    final session = await _session(asset.sessionId);
    if (session == null) throw StateError('De sessie bestaat niet.');
    if (asset.width <= 0 || asset.height <= 0 || asset.sizeBytes <= 0) {
      throw ArgumentError('Ongeldige foto-eigenschappen.');
    }
    final seriesId = asset.seriesId;
    if (seriesId != null) {
      final series = await _series(seriesId);
      if (series == null || series.sessionId != asset.sessionId) {
        throw StateError('De reeks hoort niet bij deze sessie.');
      }
    } else if (asset.role == domain.ImageRole.primaryScoringPhoto) {
      throw StateError('Een sessiefoto kan geen primaire scorefoto zijn.');
    }

    final now = DateTime.now().toUtc();
    if (asset.role == domain.ImageRole.primaryScoringPhoto) {
      final existing =
          await (database.select(database.imageAssets)
                ..where(
                  (row) =>
                      row.seriesId.equals(seriesId!) &
                      row.role.equals(
                        domain.ImageRole.primaryScoringPhoto.name,
                      ),
                )
                ..limit(1))
              .getSingleOrNull();
      if (existing != null) {
        await (database.update(
          database.imageAssets,
        )..where((row) => row.id.equals(existing.id))).write(
          ImageAssetsCompanion(
            role: Value(domain.ImageRole.attachment.name),
            updatedAtUtc: Value(now),
          ),
        );
        await (database.delete(
          database.photoAlignments,
        )..where((row) => row.imageId.equals(existing.id))).go();
      }
    }

    final id = asset.id ?? _uuid.v7();
    await database
        .into(database.imageAssets)
        .insert(
          ImageAssetsCompanion.insert(
            id: id,
            sessionId: asset.sessionId,
            seriesId: Value(seriesId),
            role: asset.role.name,
            path: asset.path,
            sha256: asset.sha256,
            width: asset.width,
            height: asset.height,
            sizeBytes: asset.sizeBytes,
            caption: Value(_nullIfBlank(asset.caption)),
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
        );
    await _touchSession(asset.sessionId, now);
    return id;
  }

  Future<SeriesDefaults> _lastUsedDefaults() async {
    final last =
        await (database.select(database.shootingSeries)
              ..orderBy([(row) => OrderingTerm.desc(row.updatedAtUtc)])
              ..limit(1))
            .getSingleOrNull();
    return last == null
        ? SeriesDefaults.standard()
        : SeriesDefaults.fromRecord(last);
  }

  Future<SessionRecord?> _activeSession() =>
      (database.select(database.trainingSessions)
            ..where(
              (row) => row.status.equals(domain.SessionStatus.active.name),
            )
            ..limit(1))
          .getSingleOrNull();

  Future<SessionRecord?> _session(String id) =>
      (database.select(database.trainingSessions)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<SeriesRecord?> _series(String id) =>
      (database.select(database.shootingSeries)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<ImageAssetRecord?> _image(String id) =>
      (database.select(database.imageAssets)
            ..where((row) => row.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  Future<void> _touchSession(String id, DateTime atUtc) async {
    await (database.update(database.trainingSessions)
          ..where((row) => row.id.equals(id)))
        .write(TrainingSessionsCompanion(updatedAtUtc: Value(atUtc.toUtc())));
  }

  Future<void> _renumberSeries(String sessionId) async {
    final series =
        await (database.select(database.shootingSeries)
              ..where((row) => row.sessionId.equals(sessionId))
              ..orderBy([
                (row) => OrderingTerm.asc(row.sequenceNumber),
                (row) => OrderingTerm.asc(row.createdAtUtc),
              ]))
            .get();
    for (var index = 0; index < series.length; index++) {
      final expected = index + 1;
      if (series[index].sequenceNumber != expected) {
        await (database.update(database.shootingSeries)
              ..where((row) => row.id.equals(series[index].id)))
            .write(ShootingSeriesCompanion(sequenceNumber: Value(expected)));
      }
    }
  }

  Future<void> _deleteFileIfPresent(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
