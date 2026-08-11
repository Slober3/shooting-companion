import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;
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

const double _visionPreviewToleranceMm = 0.05;

class _VisionAlignmentData {
  const _VisionAlignmentData({
    required this.transform,
    required this.matrix,
    required this.corners,
    required this.rotationQuarterTurns,
    required this.alignmentMode,
    required this.anchorsJson,
    required this.reprojectionRmsMm,
    required this.reprojectionMaxMm,
    required this.planarityStatus,
    required this.algorithmVersion,
    required this.confirmedAtUtc,
  });

  final geo.ProjectiveTransform? transform;
  final List<double> matrix;
  final List<geo.NormalizedPoint> corners;
  final int rotationQuarterTurns;
  final String alignmentMode;
  final String? anchorsJson;
  final double? reprojectionRmsMm;
  final double? reprojectionMaxMm;
  final String planarityStatus;
  final String algorithmVersion;
  final DateTime? confirmedAtUtc;
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
    selectedTarget.validateRuntime().requireValid(argumentName: 'target');
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

  /// Persists detector output while keeping source-image coordinates in the
  /// immutable, EXIF-normalized original coordinate space.
  ///
  /// A manually confirmed v2 alignment can be supplied by the alignment UI.
  /// Without it, native registration is stored as an unrotated full-card
  /// alignment that still requires review before commit.
  Future<void> saveAnalysisResult(
    String scanId,
    AnalyzeTargetResult result, {
    domain.StoredPhotoAlignment? confirmedAlignment,
  }) async {
    final scan = await getDraft(scanId);
    if (scan == null) throw StateError('De conceptscan bestaat niet meer.');
    final target = domain.TargetProfile.fromJsonString(scan.targetProfileJson);
    target.validateRuntime().requireValid(argumentName: 'target');
    if (confirmedAlignment != null && confirmedAlignment.imageId != scanId) {
      throw StateError('De bevestigde uitlijning hoort niet bij deze scan.');
    }
    final registration = result.registrationResult;
    final previousConfirmedAlignment = confirmedAlignment == null
        ? _confirmedAlignmentFromDraft(scan, target: target)
        : null;
    final alignmentData = confirmedAlignment != null
        ? _alignmentDataFromStored(
            alignment: confirmedAlignment,
            target: target,
          )
        : previousConfirmedAlignment ??
              _alignmentDataFromRegistration(
                registration: registration,
                quality: result.qualityAssessment,
                target: target,
              );
    final storedRegistration =
        confirmedAlignment != null || previousConfirmedAlignment != null
        ? _registrationFromAlignment(alignmentData)
        : registration;
    final candidates = _canonicalizeCandidates(
      result.candidateImpacts,
      alignment: alignmentData,
    );
    await _updateDraft(
      scanId,
      VisionScanDraftsCompanion(
        status: Value(VisionScanDraftStatus.reviewNeeded.name),
        qualityJson: Value(_encodeAnalysisQuality(result)),
        registrationJson: Value(jsonEncode(storedRegistration.toJson())),
        candidatesJson: Value(
          jsonEncode(
            candidates
                .map((candidate) => candidate.toJson())
                .toList(growable: false),
          ),
        ),
        reviewJson: const Value(null),
        engineVersion: Value(result.engineVersion),
        failureCode: const Value(null),
        rotationQuarterTurns: Value(alignmentData.rotationQuarterTurns),
        alignmentMode: Value(alignmentData.alignmentMode),
        anchorsJson: Value(alignmentData.anchorsJson),
        reprojectionRmsMm: Value(alignmentData.reprojectionRmsMm),
        reprojectionMaxMm: Value(alignmentData.reprojectionMaxMm),
        planarityStatus: Value(alignmentData.planarityStatus),
        alignmentAlgorithmVersion: Value(alignmentData.algorithmVersion),
        alignmentConfirmedAtUtc: Value(alignmentData.confirmedAtUtc),
        updatedAtUtc: Value(DateTime.now().toUtc()),
      ),
    );
  }

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
    for (var index = 0; index < confirmedImpacts.length; index++) {
      confirmedImpacts[index].validateRuntime().requireValid(
        argumentName: 'confirmedImpacts[$index]',
      );
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
      target.validateRuntime().requireValid(argumentName: 'target');
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
      final alignmentData = _alignmentDataFromDraft(
        scan: scan,
        registration: registration,
        target: target,
      );
      if (alignmentData.planarityStatus == 'rejected' ||
          alignmentData.planarityStatus == 'unknown') {
        throw StateError(
          'De kaartuitlijning is afgekeurd. Lijn de foto opnieuw uit.',
        );
      }
      final authoritativeReviewedImpacts = _authoritativeReviewedImpacts(
        confirmedImpacts,
        alignment: alignmentData,
      );

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
      final normalizedImpacts = authoritativeReviewedImpacts
          .map(
            (impact) => impact.copyWith(
              sourceImageId: impact.isMiss ? null : imageId,
              clearSourceImage: impact.isMiss,
              visionAnalysisId: analysisId,
              clearVisionAnalysis: false,
            ),
          )
          .toList(growable: false);
      for (var index = 0; index < normalizedImpacts.length; index++) {
        normalizedImpacts[index].validateRuntime().requireValid(
          argumentName: 'normalizedImpacts[$index]',
        );
      }
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
                alignmentData.corners
                    .map((point) => point.toJson())
                    .toList(growable: false),
              ),
              matrixJson: jsonEncode(alignmentData.matrix),
              algorithmVersion: alignmentData.algorithmVersion,
              rotationQuarterTurns: Value(alignmentData.rotationQuarterTurns),
              alignmentMode: Value(alignmentData.alignmentMode),
              anchorsJson: Value(alignmentData.anchorsJson),
              reprojectionRmsMm: Value(alignmentData.reprojectionRmsMm),
              reprojectionMaxMm: Value(alignmentData.reprojectionMaxMm),
              planarityStatus: Value(alignmentData.planarityStatus),
              confirmedAtUtc: Value(now),
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

  _VisionAlignmentData _alignmentDataFromRegistration({
    required VisionRegistrationResult registration,
    required VisionQualityAssessment quality,
    required domain.TargetProfile target,
  }) {
    final corners = registration.orderedSourceCornersNormalized
        .map((point) => geo.NormalizedPoint(point.x, point.y))
        .toList(growable: false);
    geo.ProjectiveTransform? transform;
    final matrix = registration.sourceNormalizedToCardMmHomography;
    try {
      if (matrix != null) transform = geo.ProjectiveTransform(matrix);
    } on Object {
      transform = null;
    }
    final validCorners =
        corners.length == 4 &&
        corners.every((point) => point.isFinite && point.isInsideImage);
    var geometryMatchesCorners = false;
    if (validCorners && transform != null) {
      try {
        final expected = geo.ManualPhotoAlignment.build(
          corners: geo.NormalizedQuad.fromOrderedPoints(corners),
          cardWidthMm: target.physicalCardWidthMm,
          cardHeightMm: target.physicalCardHeightMm,
        ).alignment;
        if (expected != null) {
          final samples = <geo.NormalizedPoint>{
            ...corners,
            const geo.NormalizedPoint(0.5, 0.5),
          };
          geometryMatchesCorners = samples.every((point) {
            final actual = transform!.apply(
              geo.TransformPoint(point.x, point.y),
            );
            final wanted = expected.normalizedToPhysical(point);
            return (actual.x - wanted.x).abs() <= _visionPreviewToleranceMm &&
                (actual.y - wanted.y).abs() <= _visionPreviewToleranceMm;
          });
        }
      } on Object {
        geometryMatchesCorners = false;
      }
    }
    final registered =
        registration.status == VisionRegistrationStatus.registered &&
        transform != null &&
        validCorners &&
        geometryMatchesCorners;
    final planarityStatus =
        !registered || quality.status == VisionQualityStatus.rejected
        ? 'rejected'
        : 'manualReviewOnly';
    return _VisionAlignmentData(
      transform: registered ? transform : null,
      matrix: matrix == null ? const [] : List.unmodifiable(matrix),
      corners: List.unmodifiable(corners),
      rotationQuarterTurns: 0,
      alignmentMode: 'fullCard',
      anchorsJson: validCorners
          ? _cornerAnchorsJson(corners, target: target)
          : null,
      reprojectionRmsMm: null,
      reprojectionMaxMm: null,
      planarityStatus: planarityStatus,
      algorithmVersion: geo.manualHomographyV2AlgorithmVersion,
      confirmedAtUtc: null,
    );
  }

  _VisionAlignmentData? _confirmedAlignmentFromDraft(
    VisionScanDraftRecord scan, {
    required domain.TargetProfile target,
  }) {
    if (scan.alignmentConfirmedAtUtc == null || scan.registrationJson == null) {
      return null;
    }
    try {
      final registration = VisionRegistrationResult.fromJson(
        (jsonDecode(scan.registrationJson!) as Map).cast<String, Object?>(),
      );
      return _alignmentDataFromDraft(
        scan: scan,
        registration: registration,
        target: target,
      );
    } on Object catch (error) {
      throw StateError(
        'De eerder bevestigde foto-uitlijning is ongeldig: $error',
      );
    }
  }

  VisionRegistrationResult _registrationFromAlignment(
    _VisionAlignmentData alignment,
  ) => VisionRegistrationResult(
    status: VisionRegistrationStatus.registered,
    orderedSourceCornersNormalized: alignment.corners
        .map((point) => VisionPoint(x: point.x, y: point.y))
        .toList(growable: false),
    sourceNormalizedToCardMmHomography: alignment.matrix,
    algorithmVersion: alignment.algorithmVersion,
  );

  _VisionAlignmentData _alignmentDataFromStored({
    required domain.StoredPhotoAlignment alignment,
    required domain.TargetProfile target,
    bool defaultConfirmationToUpdatedAt = true,
  }) {
    final status = alignment.planarityStatus.trim().toLowerCase();
    if (status == 'rejected' || status == 'unstable' || status == 'unknown') {
      throw StateError('De handmatige kaartuitlijning is afgekeurd.');
    }
    final mode = switch (alignment.alignmentMode.trim()) {
      'fullCard' || 'fourCorners' => geo.PhotoAlignmentMode.fourCorners,
      'ringAssisted' => geo.PhotoAlignmentMode.ringAssisted,
      _ => throw StateError('Onbekende foto-uitlijningsmodus.'),
    };
    Object? anchors;
    if (alignment.anchorsJson != null) {
      try {
        anchors = jsonDecode(alignment.anchorsJson!);
      } on Object {
        throw StateError('De uitlijningsankers zijn ongeldig.');
      }
      if (anchors is! List) {
        throw StateError('De uitlijningsankers zijn ongeldig.');
      }
    } else if (mode == geo.PhotoAlignmentMode.ringAssisted) {
      throw StateError('Ringuitlijning vereist opgeslagen ankers.');
    }
    final corners = alignment.orderedCorners
        .map((point) => geo.NormalizedPoint(point.x, point.y))
        .toList(growable: false);
    late final geo.ManualPhotoAlignment geometry;
    try {
      geometry = geo.ManualPhotoAlignment.fromJson({
        'schemaVersion': geo.photoAlignmentSchemaVersion,
        'algorithmVersion': alignment.algorithmVersion,
        'alignmentMode': mode.name,
        'anchors': ?anchors,
        'cardWidthMm': target.physicalCardWidthMm,
        'cardHeightMm': target.physicalCardHeightMm,
        'corners': geo.NormalizedQuad.fromOrderedPoints(corners).toJson(),
        'homographyMatrix': alignment.homographyMatrix,
        'rotationQuarterTurns': alignment.rotationQuarterTurns,
      });
    } on Object catch (error) {
      throw StateError('De handmatige kaartuitlijning is ongeldig: $error');
    }
    final residuals = geometry.residuals;
    if (!residuals.conditionEstimate.isFinite ||
        residuals.conditionEstimate > 1e10) {
      throw StateError('De handmatige kaartuitlijning is instabiel.');
    }
    final planarityStatus = switch ((residuals.rmsMm, residuals.maximumMm)) {
      (final rms, final maximum) when rms <= 0.75 && maximum <= 1.5 =>
        'accepted',
      (final rms, final maximum) when rms <= 1.5 && maximum <= 3.0 =>
        'manualReviewOnly',
      _ => throw StateError(
        'De handmatige kaartuitlijning overschrijdt de foutmarge.',
      ),
    };
    return _VisionAlignmentData(
      transform: geo.ProjectiveTransform(geometry.homographyMatrix),
      matrix: geometry.homographyMatrix,
      corners: geometry.corners.points,
      rotationQuarterTurns: geometry.rotationQuarterTurns,
      alignmentMode: mode == geo.PhotoAlignmentMode.fourCorners
          ? 'fullCard'
          : 'ringAssisted',
      anchorsJson: jsonEncode(
        geometry.anchors.map((anchor) => anchor.toJson()).toList(),
      ),
      reprojectionRmsMm: residuals.rmsMm,
      reprojectionMaxMm: residuals.maximumMm,
      planarityStatus: planarityStatus,
      algorithmVersion: geometry.algorithmVersion,
      confirmedAtUtc:
          alignment.confirmedAtUtc?.toUtc() ??
          (defaultConfirmationToUpdatedAt
              ? alignment.updatedAtUtc.toUtc()
              : null),
    );
  }

  _VisionAlignmentData _alignmentDataFromDraft({
    required VisionScanDraftRecord scan,
    required VisionRegistrationResult registration,
    required domain.TargetProfile target,
  }) {
    if (scan.rotationQuarterTurns < 0 || scan.rotationQuarterTurns > 3) {
      throw StateError('De opgeslagen fotostand is ongeldig.');
    }
    if (scan.alignmentMode != 'fullCard' &&
        scan.alignmentMode != 'ringAssisted') {
      throw StateError('De opgeslagen uitlijningsmodus is ongeldig.');
    }
    final matrix = registration.sourceNormalizedToCardMmHomography;
    if (matrix == null) throw StateError('De uitlijningsmatrix ontbreekt.');
    final corners = registration.orderedSourceCornersNormalized
        .map((point) => domain.NormalizedPoint(x: point.x, y: point.y))
        .toList(growable: false);
    if (corners.length != 4 ||
        corners.any(
          (point) =>
              !point.x.isFinite ||
              !point.y.isFinite ||
              point.x < 0 ||
              point.x > 1 ||
              point.y < 0 ||
              point.y > 1,
        )) {
      throw StateError('De opgeslagen kaartpunten zijn ongeldig.');
    }
    if (scan.planarityStatus != 'accepted' &&
        scan.planarityStatus != 'manualReviewOnly' &&
        scan.planarityStatus != 'rejected' &&
        scan.planarityStatus != 'unknown') {
      throw StateError('De opgeslagen uitlijningskwaliteit is ongeldig.');
    }
    return _alignmentDataFromStored(
      alignment: domain.StoredPhotoAlignment(
        imageId: scan.id,
        orderedCorners: corners,
        homographyMatrix: matrix,
        algorithmVersion:
            scan.alignmentAlgorithmVersion ??
            registration.algorithmVersion ??
            geo.manualHomographyV2AlgorithmVersion,
        rotationQuarterTurns: scan.rotationQuarterTurns,
        alignmentMode: scan.alignmentMode,
        anchorsJson: scan.anchorsJson,
        reprojectionRmsMm: scan.reprojectionRmsMm,
        reprojectionMaxMm: scan.reprojectionMaxMm,
        planarityStatus: scan.planarityStatus,
        confirmedAtUtc: scan.alignmentConfirmedAtUtc,
        updatedAtUtc: scan.updatedAtUtc,
      ),
      target: target,
      defaultConfirmationToUpdatedAt: false,
    );
  }

  List<VisionCandidateImpact> _canonicalizeCandidates(
    List<VisionCandidateImpact> candidates, {
    required _VisionAlignmentData alignment,
  }) {
    final ids = <String>{};
    return candidates
        .map((candidate) {
          if (!ids.add(candidate.id) ||
              !candidate.sourceImageXNormalized.isFinite ||
              !candidate.sourceImageYNormalized.isFinite ||
              !candidate.cardXMm.isFinite ||
              !candidate.cardYMm.isFinite) {
            throw StateError(
              'Visionkandidaat bevat ongeldige coordinaten of ID.',
            );
          }
          final transform = alignment.transform;
          if (transform == null) return candidate;
          final original = geo.NormalizedPoint(
            candidate.sourceImageXNormalized,
            candidate.sourceImageYNormalized,
          );
          if (!original.isInsideImage) {
            throw StateError('Visionkandidaat ligt buiten de originele foto.');
          }
          final displayed = geo.rotateNormalizedPoint(
            original,
            alignment.rotationQuarterTurns,
          );
          final mapped = transform.apply(
            geo.TransformPoint(displayed.x, displayed.y),
          );
          return candidate.copyWith(cardXMm: mapped.x, cardYMm: mapped.y);
        })
        .toList(growable: false);
  }

  List<domain.ShotImpact> _authoritativeReviewedImpacts(
    List<domain.ShotImpact> impacts, {
    required _VisionAlignmentData alignment,
  }) {
    final ids = <String>{};
    final transform = alignment.transform;
    if (transform == null) {
      throw StateError('De uitlijningsmatrix ontbreekt.');
    }
    return impacts
        .map((impact) {
          if (!ids.add(impact.id)) {
            throw StateError('Een gecontroleerde treffer-ID komt dubbel voor.');
          }
          if (impact.isMiss) {
            return impact.copyWith(
              clearSourceImage: true,
              clearImageCoordinates: true,
            );
          }
          final imageX = impact.imageXNormalized;
          final imageY = impact.imageYNormalized;
          if (imageX == null || imageY == null) {
            // A user may deliberately add a point on the drawn target fallback.
            if (!impact.xMm.isFinite || !impact.yMm.isFinite) {
              throw StateError(
                'Een handmatige treffer heeft ongeldige coordinaten.',
              );
            }
            return impact;
          }
          final original = geo.NormalizedPoint(imageX, imageY);
          if (!original.isFinite || !original.isInsideImage) {
            throw StateError('Een treffer ligt buiten de originele foto.');
          }
          final displayed = geo.rotateNormalizedPoint(
            original,
            alignment.rotationQuarterTurns,
          );
          final mapped = transform.apply(
            geo.TransformPoint(displayed.x, displayed.y),
          );
          if ((impact.xMm - mapped.x).abs() > _visionPreviewToleranceMm ||
              (impact.yMm - mapped.y).abs() > _visionPreviewToleranceMm) {
            throw StateError(
              'De gecontroleerde trefferpreview wijkt af van de opgeslagen '
              'foto-uitlijning.',
            );
          }
          final authoritative = impact.copyWith(xMm: mapped.x, yMm: mapped.y);
          authoritative.validateRuntime().requireValid(
            argumentName: 'authoritativeImpacts[${impact.id}]',
          );
          return authoritative;
        })
        .toList(growable: false);
  }

  String _cornerAnchorsJson(
    List<geo.NormalizedPoint> corners, {
    required domain.TargetProfile target,
  }) {
    if (corners.length != 4) {
      throw StateError('Vier kaartpunten zijn vereist.');
    }
    final halfWidth = target.physicalCardWidthMm / 2;
    final halfHeight = target.physicalCardHeightMm / 2;
    final roles = [
      geo.PhotoAlignmentAnchorRole.cornerTopLeft,
      geo.PhotoAlignmentAnchorRole.cornerTopRight,
      geo.PhotoAlignmentAnchorRole.cornerBottomRight,
      geo.PhotoAlignmentAnchorRole.cornerBottomLeft,
    ];
    final physical = [
      geo.PhysicalPointMm(-halfWidth, -halfHeight),
      geo.PhysicalPointMm(halfWidth, -halfHeight),
      geo.PhysicalPointMm(halfWidth, halfHeight),
      geo.PhysicalPointMm(-halfWidth, halfHeight),
    ];
    return jsonEncode(
      List.generate(
        4,
        (index) => geo.PhotoAlignmentAnchor(
          id: 'card.${roles[index].name}',
          role: roles[index],
          sourcePoint: corners[index],
          physicalPointMm: physical[index],
        ).toJson(),
      ),
    );
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

  String _encodeAnalysisQuality(AnalyzeTargetResult result) {
    final envelope = <String, Object?>{
      ...result.qualityAssessment.toJson(),
      // Keep detector diagnostics beside the existing quality payload. This is
      // additive and therefore remains readable by older v8 backups while a
      // resumed concept can still explain why no candidates survived.
      '_diagnosticMetrics': result.diagnosticMetrics,
      '_analysisWarnings': result.warnings
          .map((warning) => warning.toJson())
          .toList(growable: false),
      '_visionBackend': result.provenance.backend.name,
    };
    return jsonEncode(envelope);
  }
}
