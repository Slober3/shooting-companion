import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_scoring/scoring.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:shooting_companion_vision_api/vision_api.dart';
import 'package:uuid/uuid.dart';

import '../services/image_storage_service.dart';
import 'app_database.dart';

enum VisionScanDraftStatus {
  analysisNeeded,
  analyzing,
  reviewNeeded,
  readyToLink,
  failed,
}

enum VisionScanDestination {
  newSeriesInActiveSession,
  useEmptyActiveDraft,
  newQuickSession,
}

class VisionScanCommitResult {
  const VisionScanCommitResult({
    required this.sessionId,
    required this.seriesId,
    required this.createdSession,
  });

  final String sessionId;
  final String seriesId;
  final bool createdSession;
}

class VisionSeriesMetadata {
  const VisionSeriesMetadata({
    required this.distanceMeters,
    this.firearmId,
    this.ammoLotId,
  });

  final double distanceMeters;
  final String? firearmId;
  final String? ammoLotId;

  VisionSeriesMetadata copyWith({
    double? distanceMeters,
    String? firearmId,
    bool clearFirearm = false,
    String? ammoLotId,
    bool clearAmmoLot = false,
  }) => VisionSeriesMetadata(
    distanceMeters: distanceMeters ?? this.distanceMeters,
    firearmId: clearFirearm ? null : firearmId ?? this.firearmId,
    ammoLotId: clearAmmoLot ? null : ammoLotId ?? this.ammoLotId,
  );
}

class VisionScanRepository {
  VisionScanRepository(
    this.database, {
    ImageStorageService? imageStorage,
    Uuid? uuid,
  }) : _imageStorage = imageStorage ?? ImageStorageService(),
       _uuid = uuid ?? const Uuid();

  final AppDatabase database;
  final ImageStorageService _imageStorage;
  final Uuid _uuid;

  Stream<List<VisionScanDraftRecord>> watchDrafts() => (database.select(
    database.visionScanDrafts,
  )..orderBy([(row) => OrderingTerm.desc(row.updatedAtUtc)])).watch();

  Stream<int> watchDraftCount() {
    final count = database.visionScanDrafts.id.count();
    final query = database.selectOnly(database.visionScanDrafts)
      ..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<int> getDraftStorageBytes() async {
    final total = database.visionScanDrafts.sizeBytes.sum();
    final query = database.selectOnly(database.visionScanDrafts)
      ..addColumns([total]);
    return (await query.getSingle()).read(total) ?? 0;
  }

  Future<VisionSeriesMetadata> suggestedSeriesMetadata() async {
    final last =
        await (database.select(database.shootingSeries)
              ..where(
                (row) =>
                    row.targetProfileVersionedId.equals(
                      IssfTargetProfiles.precision25m50m.versionedId,
                    ) &
                    row.cartridgeId.equals(CartridgePresets.twentyTwoLr.id),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.updatedAtUtc)])
              ..limit(1))
            .getSingleOrNull();
    if (last == null) return const VisionSeriesMetadata(distanceMeters: 25);

    String? firearmId;
    if (last.firearmId case final id?) {
      final firearm =
          await (database.select(database.firearms)
                ..where((row) => row.id.equals(id) & row.archived.not())
                ..limit(1))
              .getSingleOrNull();
      firearmId = firearm?.id;
    }
    String? ammoLotId;
    if (last.ammoLotId case final id?) {
      final ammo =
          await (database.select(database.ammoLots)
                ..where(
                  (row) =>
                      row.id.equals(id) &
                      row.cartridgeId.equals(CartridgePresets.twentyTwoLr.id) &
                      row.archived.not(),
                )
                ..limit(1))
              .getSingleOrNull();
      ammoLotId = ammo?.id;
    }
    return VisionSeriesMetadata(
      distanceMeters: last.distanceMeters,
      firearmId: firearmId,
      ammoLotId: ammoLotId,
    );
  }

  Stream<VisionScanDraftRecord?> watchDraft(String id) => (database.select(
    database.visionScanDrafts,
  )..where((row) => row.id.equals(id))).watchSingleOrNull();

  Future<VisionScanDraftRecord?> getDraft(String id) => (database.select(
    database.visionScanDrafts,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<String> createDraft({
    required StoredImage image,
    domain.TargetProfile? target,
    double? projectileDiameterMm,
  }) async {
    final selectedTarget = target ?? IssfTargetProfiles.precision25m50m;
    final diameter =
        projectileDiameterMm ??
        CartridgePresets.twentyTwoLr.projectileDiameterMm;
    if (selectedTarget.versionedId !=
            IssfTargetProfiles.precision25m50m.versionedId ||
        (diameter - CartridgePresets.twentyTwoLr.projectileDiameterMm).abs() >
            0.01) {
      throw ArgumentError(
        'De experimentele detector ondersteunt alleen ISSF Precision met .22 LR.',
      );
    }
    final id = _uuid.v7();
    final now = DateTime.now().toUtc();
    try {
      await database
          .into(database.visionScanDrafts)
          .insert(
            VisionScanDraftsCompanion.insert(
              id: id,
              status: VisionScanDraftStatus.analysisNeeded.name,
              originalImagePath: image.path,
              sha256: image.sha256,
              width: image.width,
              height: image.height,
              sizeBytes: image.sizeBytes,
              targetProfileJson: selectedTarget.toJsonString(),
              projectileDiameterMm: diameter,
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          );
      return id;
    } catch (_) {
      await _imageStorage.deleteStoredImage(image.path);
      rethrow;
    }
  }

  Future<void> markAnalyzing(String scanId) => _updateDraft(
    scanId,
    VisionScanDraftsCompanion(
      status: Value(VisionScanDraftStatus.analyzing.name),
      failureCode: const Value(null),
      updatedAtUtc: Value(DateTime.now().toUtc()),
    ),
  );

  Future<void> saveAnalysisResult(String scanId, AnalyzeTargetResult result) =>
      _updateDraft(
        scanId,
        VisionScanDraftsCompanion(
          status: Value(VisionScanDraftStatus.reviewNeeded.name),
          qualityJson: Value(jsonEncode(result.qualityAssessment.toJson())),
          registrationJson: Value(
            jsonEncode(result.registrationResult.toJson()),
          ),
          candidatesJson: Value(
            jsonEncode(
              result.candidateImpacts
                  .map((candidate) => candidate.toJson())
                  .toList(growable: false),
            ),
          ),
          reviewJson: const Value(null),
          engineVersion: Value(result.engineVersion),
          failureCode: const Value(null),
          updatedAtUtc: Value(DateTime.now().toUtc()),
        ),
      );

  Future<void> saveAnalysisFailure(String scanId, String failureCode) =>
      _updateDraft(
        scanId,
        VisionScanDraftsCompanion(
          status: Value(VisionScanDraftStatus.failed.name),
          failureCode: Value(failureCode.trim()),
          updatedAtUtc: Value(DateTime.now().toUtc()),
        ),
      );

  Future<void> saveReview({
    required String scanId,
    required Map<String, Object?> review,
    required bool readyToLink,
  }) {
    final reviewJson = _encodeObject(review, 'visionreview');
    return _updateDraft(
      scanId,
      VisionScanDraftsCompanion(
        status: Value(
          readyToLink
              ? VisionScanDraftStatus.readyToLink.name
              : VisionScanDraftStatus.reviewNeeded.name,
        ),
        reviewJson: Value(reviewJson),
        updatedAtUtc: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> deleteDraft(String scanId) async {
    final draft = await getDraft(scanId);
    if (draft == null) return;
    await (database.delete(
      database.visionScanDrafts,
    )..where((row) => row.id.equals(scanId))).go();
    await _imageStorage.deleteStoredImage(draft.originalImagePath);
  }

  Future<VisionScanCommitResult> commitReviewedVisionScan({
    required String scanId,
    required VisionScanDestination destination,
    required List<domain.ShotImpact> confirmedImpacts,
    required Map<String, Object?> review,
    double? distanceMeters,
    String? firearmId,
    String? ammoLotId,
  }) async {
    if (confirmedImpacts.isEmpty) {
      throw StateError('Bevestig minstens één treffer of misser.');
    }
    final reviewJson = _encodeObject(review, 'visionreview');
    return database.transaction(() async {
      final scan = await getDraft(scanId);
      if (scan == null) throw StateError('De conceptscan bestaat niet meer.');
      if (scan.qualityJson == null ||
          scan.registrationJson == null ||
          scan.candidatesJson == null ||
          scan.engineVersion == null) {
        throw StateError('De conceptscan is nog niet volledig geanalyseerd.');
      }
      final target = domain.TargetProfile.fromJsonString(
        scan.targetProfileJson,
      );
      if (target.versionedId !=
              IssfTargetProfiles.precision25m50m.versionedId ||
          (scan.projectileDiameterMm -
                      CartridgePresets.twentyTwoLr.projectileDiameterMm)
                  .abs() >
              0.01) {
        throw StateError(
          'De scan valt buiten de ondersteunde detectorcombinatie.',
        );
      }
      if (firearmId != null) {
        final firearm =
            await (database.select(database.firearms)
                  ..where(
                    (row) => row.id.equals(firearmId) & row.archived.not(),
                  )
                  ..limit(1))
                .getSingleOrNull();
        if (firearm == null ||
            (firearm.defaultCartridgeId != null &&
                firearm.defaultCartridgeId !=
                    CartridgePresets.twentyTwoLr.id)) {
          throw StateError(
            'Het gekozen wapen is niet beschikbaar voor .22 LR.',
          );
        }
      }
      if (ammoLotId != null) {
        final ammo =
            await (database.select(database.ammoLots)
                  ..where(
                    (row) =>
                        row.id.equals(ammoLotId) &
                        row.cartridgeId.equals(
                          CartridgePresets.twentyTwoLr.id,
                        ) &
                        row.archived.not(),
                  )
                  ..limit(1))
                .getSingleOrNull();
        if (ammo == null) {
          throw StateError('Het gekozen munitieprofiel is niet beschikbaar.');
        }
      }
      final registration = VisionRegistrationResult.fromJson(
        (jsonDecode(scan.registrationJson!) as Map).cast<String, Object?>(),
      );
      final matrix = registration.sourceNormalizedToCardMmHomography;
      if (registration.status != VisionRegistrationStatus.registered ||
          registration.orderedSourceCornersNormalized.length != 4 ||
          matrix == null) {
        throw StateError('Bevestig eerst een geldige kaartuitlijning.');
      }

      final active =
          await (database.select(database.trainingSessions)
                ..where(
                  (row) => row.status.equals(domain.SessionStatus.active.name),
                )
                ..limit(1))
              .getSingleOrNull();
      final nowLocal = DateTime.now();
      final now = nowLocal.toUtc();
      late final String sessionId;
      var createdSession = false;
      if (destination == VisionScanDestination.newQuickSession) {
        if (active != null) {
          throw StateError(
            'Er is al een actieve sessie. Kies die sessie als bestemming.',
          );
        }
        sessionId = _uuid.v7();
        createdSession = true;
        await database
            .into(database.trainingSessions)
            .insert(
              TrainingSessionsCompanion.insert(
                id: sessionId,
                status: domain.SessionStatus.active.name,
                startedAtUtc: now,
                localUtcOffsetMinutes: nowLocal.timeZoneOffset.inMinutes,
                updatedAtUtc: now,
              ),
            );
      } else {
        if (active == null) {
          throw StateError('Er is geen actieve sessie meer.');
        }
        sessionId = active.id;
      }

      SeriesRecord? destinationDraft;
      if (destination == VisionScanDestination.useEmptyActiveDraft) {
        destinationDraft =
            await (database.select(database.shootingSeries)
                  ..where(
                    (row) =>
                        row.sessionId.equals(sessionId) &
                        row.status.equals(domain.SeriesStatus.draft.name),
                  )
                  ..limit(1))
                .getSingleOrNull();
        if (destinationDraft == null) {
          throw StateError('Er is geen actief concept om te gebruiken.');
        }
        final draftImages = await (database.select(
          database.imageAssets,
        )..where((row) => row.seriesId.equals(destinationDraft!.id))).get();
        if (destinationDraft.shotCount != 0 ||
            draftImages.isNotEmpty ||
            (destinationDraft.notes?.trim().isNotEmpty ?? false)) {
          throw StateError(
            'Het bestaande concept is niet leeg en wordt niet overschreven.',
          );
        }
      }

      final seriesId = destinationDraft?.id ?? _uuid.v7();
      final maxSequence = database.shootingSeries.sequenceNumber.max();
      final maxSequenceRow =
          await (database.selectOnly(database.shootingSeries)
                ..addColumns([maxSequence])
                ..where(database.shootingSeries.sessionId.equals(sessionId)))
              .getSingle();
      final sequenceNumber =
          destinationDraft?.sequenceNumber ??
          ((maxSequenceRow.read(maxSequence) ?? 0) + 1);
      final imageId = _uuid.v7();
      final analysisId = _uuid.v7();
      final normalizedImpacts = confirmedImpacts
          .map(
            (impact) => impact.copyWith(
              sourceImageId: impact.isMiss ? null : imageId,
              clearSourceImage: impact.isMiss,
              visionAnalysisId: analysisId,
              clearVisionAnalysis: false,
            ),
          )
          .toList(growable: false);
      final score = ScoreEngine.score(
        target: target,
        impacts: normalizedImpacts,
        projectileDiameterMm: scan.projectileDiameterMm,
      );
      final resolvedDistance =
          distanceMeters ?? target.defaultDistanceMeters ?? 25;

      final seriesCompanion = ShootingSeriesCompanion.insert(
        id: seriesId,
        sessionId: sessionId,
        sequenceNumber: sequenceNumber,
        status: domain.SeriesStatus.confirmed.name,
        targetProfileVersionedId: target.versionedId,
        targetProfileJson: target.toJsonString(),
        distanceMeters: resolvedDistance,
        projectileDiameterMm: scan.projectileDiameterMm,
        cartridgeId: Value(CartridgePresets.twentyTwoLr.id),
        firearmId: Value(firearmId),
        ammoLotId: Value(ammoLotId),
        shotCount: Value(score.actualShotCount),
        maximumPossibleScore: Value(score.maximumPossible),
        totalScore: Value(score.total),
        innerTenCount: Value(score.innerTenCount),
        missCount: Value(score.missCount),
        scorePenalty: Value(score.penalty),
        scoredBullCount: Value(score.scoredBullCount),
        hasBoundaryWarnings: Value(score.hasBoundaryWarnings),
        createdAtUtc: destinationDraft?.createdAtUtc ?? now,
        updatedAtUtc: now,
        confirmedAtUtc: Value(now),
      );
      if (destinationDraft == null) {
        await database.into(database.shootingSeries).insert(seriesCompanion);
      } else {
        await (database.update(
          database.shootingSeries,
        )..where((row) => row.id.equals(seriesId))).write(
          ShootingSeriesCompanion(
            status: Value(domain.SeriesStatus.confirmed.name),
            targetProfileVersionedId: Value(target.versionedId),
            targetProfileJson: Value(target.toJsonString()),
            distanceMeters: Value(resolvedDistance),
            projectileDiameterMm: Value(scan.projectileDiameterMm),
            cartridgeId: Value(CartridgePresets.twentyTwoLr.id),
            firearmId: Value(firearmId),
            ammoLotId: Value(ammoLotId),
            shotCount: Value(score.actualShotCount),
            maximumPossibleScore: Value(score.maximumPossible),
            totalScore: Value(score.total),
            innerTenCount: Value(score.innerTenCount),
            missCount: Value(score.missCount),
            scorePenalty: Value(score.penalty),
            scoredBullCount: Value(score.scoredBullCount),
            hasBoundaryWarnings: Value(score.hasBoundaryWarnings),
            updatedAtUtc: Value(now),
            confirmedAtUtc: Value(now),
          ),
        );
      }

      await database
          .into(database.imageAssets)
          .insert(
            ImageAssetsCompanion.insert(
              id: imageId,
              sessionId: sessionId,
              seriesId: Value(seriesId),
              role: domain.ImageRole.primaryScoringPhoto.name,
              path: scan.originalImagePath,
              sha256: scan.sha256,
              width: scan.width,
              height: scan.height,
              sizeBytes: scan.sizeBytes,
              createdAtUtc: scan.createdAtUtc,
              updatedAtUtc: now,
            ),
          );
      await database
          .into(database.visionAnalyses)
          .insert(
            VisionAnalysesCompanion.insert(
              id: analysisId,
              seriesId: seriesId,
              imageId: imageId,
              engineVersion: scan.engineVersion!,
              backendVersion: 'opencv-4.13.0',
              qualityJson: scan.qualityJson!,
              registrationJson: scan.registrationJson!,
              candidatesJson: scan.candidatesJson!,
              reviewJson: reviewJson,
              createdAtUtc: now,
            ),
          );
      await database
          .into(database.photoAlignments)
          .insert(
            PhotoAlignmentsCompanion.insert(
              imageId: imageId,
              cornersJson: jsonEncode(
                registration.orderedSourceCornersNormalized
                    .map((point) => point.toJson())
                    .toList(growable: false),
              ),
              matrixJson: jsonEncode(matrix),
              algorithmVersion:
                  registration.algorithmVersion ?? 'vision-registration-v2',
              updatedAtUtc: now,
            ),
          );
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
                targetBullId: Value(shot.targetBullId),
                scoreValue: shot.value,
                rawScoreValue: Value(shot.value),
                scoreDisposition: Value(shot.disposition.name),
                isInnerTen: Value(shot.isInnerTen),
                isBoundaryUncertain: Value(shot.isBoundaryUncertain),
                placementMethod: Value(shot.impact.placementMethod.name),
                visionAnalysisId: Value(analysisId),
                positionalUncertaintyMm: Value(
                  shot.impact.positionalUncertaintyMm,
                ),
              ),
            );
      }
      await (database.delete(
        database.visionScanDrafts,
      )..where((row) => row.id.equals(scanId))).go();
      await (database.update(database.trainingSessions)
            ..where((row) => row.id.equals(sessionId)))
          .write(TrainingSessionsCompanion(updatedAtUtc: Value(now)));
      return VisionScanCommitResult(
        sessionId: sessionId,
        seriesId: seriesId,
        createdSession: createdSession,
      );
    });
  }

  Future<void> _updateDraft(
    String scanId,
    VisionScanDraftsCompanion companion,
  ) async {
    final changed = await (database.update(
      database.visionScanDrafts,
    )..where((row) => row.id.equals(scanId))).write(companion);
    if (changed != 1) throw StateError('De conceptscan bestaat niet meer.');
  }

  String _encodeObject(Map<String, Object?> value, String label) {
    try {
      final encoded = jsonEncode(value);
      if (jsonDecode(encoded) is! Map) throw const FormatException();
      return encoded;
    } on Object {
      throw ArgumentError('$label bevat niet-serialiseerbare gegevens.');
    }
  }
}
