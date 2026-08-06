import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/data/vision_scan_repository.dart';
import 'package:shooting_companion/services/image_storage_service.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_vision_api/vision_api.dart';

void main() {
  late Directory workspace;
  late Directory documents;
  late AppDatabase database;
  late VisionScanRepository repository;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp(
      'shooting-companion-vision-repository-',
    );
    documents = Directory(path.join(workspace.path, 'documents'))
      ..createSync(recursive: true);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await ShootingRepository(database).seedDefaults();
    repository = VisionScanRepository(
      database,
      imageStorage: ImageStorageService(
        applicationDocumentsDirectory: () async => documents,
      ),
    );
  });

  tearDown(() async {
    await database.close();
    if (await workspace.exists()) await workspace.delete(recursive: true);
  });

  test(
    'reviewed scan commits photo, alignment and provenance atomically',
    () async {
      final image = await _storedImage(documents, 'reviewed.jpg');
      final scanId = await repository.createDraft(image: image);
      expect(await repository.getDraftStorageBytes(), image.sizeBytes);
      await repository.saveAnalysisResult(scanId, _completedAnalysis());
      await database
          .into(database.firearms)
          .insert(
            const FirearmsCompanion(
              id: Value('firearm-1'),
              name: Value('Testpistool'),
              type: Value('pistol'),
              defaultCartridgeId: Value('cartridge-22-lr'),
            ),
          );
      await database
          .into(database.ammoLots)
          .insert(
            const AmmoLotsCompanion(
              id: Value('ammo-1'),
              cartridgeId: Value('cartridge-22-lr'),
              displayName: Value('Test .22 lot'),
            ),
          );

      final result = await repository.commitReviewedVisionScan(
        scanId: scanId,
        destination: VisionScanDestination.newQuickSession,
        confirmedImpacts: const [
          ShotImpact(
            id: 'candidate-1',
            xMm: 0,
            yMm: 0,
            imageXNormalized: 0.5,
            imageYNormalized: 0.5,
            placementMethod: ImpactPlacementMethod.assistedAccepted,
            positionalUncertaintyMm: 0.4,
          ),
        ],
        review: const {
          'decisions': [
            {'candidateId': 'candidate-1', 'decision': 'accepted'},
          ],
        },
        distanceMeters: 50,
        firearmId: 'firearm-1',
        ammoLotId: 'ammo-1',
      );

      expect(result.createdSession, isTrue);
      expect(await repository.getDraft(scanId), null);
      expect(await repository.getDraftStorageBytes(), 0);
      expect(
        await database.select(database.trainingSessions).get(),
        hasLength(1),
      );
      final series =
          (await database.select(database.shootingSeries).get()).single;
      expect(series.id, result.seriesId);
      expect(series.status, SeriesStatus.confirmed.name);
      expect(series.shotCount, 1);
      expect(series.maximumPossibleScore, 10);
      expect(series.distanceMeters, 50);
      expect(series.firearmId, 'firearm-1');
      expect(series.ammoLotId, 'ammo-1');
      final suggested = await repository.suggestedSeriesMetadata();
      expect(suggested.distanceMeters, 50);
      expect(suggested.firearmId, 'firearm-1');
      expect(suggested.ammoLotId, 'ammo-1');
      final storedImage =
          (await database.select(database.imageAssets).get()).single;
      expect(storedImage.path, image.path);
      expect(storedImage.role, ImageRole.primaryScoringPhoto.name);
      expect(await File(storedImage.path).exists(), isTrue);
      expect(
        await database.select(database.photoAlignments).get(),
        hasLength(1),
      );
      final analysis =
          (await database.select(database.visionAnalyses).get()).single;
      expect(analysis.imageId, storedImage.id);
      expect(analysis.engineVersion, 'vision-core-test');
      final impact = (await database.select(database.shotImpacts).get()).single;
      expect(
        impact.placementMethod,
        ImpactPlacementMethod.assistedAccepted.name,
      );
      expect(impact.visionAnalysisId, analysis.id);
      expect(impact.sourceImageId, storedImage.id);
      expect(impact.positionalUncertaintyMm, 0.4);
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    },
  );

  test(
    'failed commit preserves the concept and existing database state',
    () async {
      final image = await _storedImage(documents, 'unfinished.jpg');
      final scanId = await repository.createDraft(image: image);

      await expectLater(
        repository.commitReviewedVisionScan(
          scanId: scanId,
          destination: VisionScanDestination.newQuickSession,
          confirmedImpacts: const [ShotImpact(id: 'manual-1', xMm: 0, yMm: 0)],
          review: const {'decisions': <Object?>[]},
        ),
        throwsA(isA<StateError>()),
      );

      expect(await repository.getDraft(scanId), isNotNull);
      expect(await File(image.path).exists(), isTrue);
      expect(await database.select(database.trainingSessions).get(), isEmpty);
      expect(await database.select(database.shootingSeries).get(), isEmpty);
      expect(await database.select(database.imageAssets).get(), isEmpty);
      expect(await database.select(database.visionAnalyses).get(), isEmpty);
    },
  );
}

Future<StoredImage> _storedImage(Directory documents, String name) async {
  final directory = Directory(
    path.join(documents.path, 'target_images', 'originals'),
  )..createSync(recursive: true);
  final file = File(path.join(directory.path, name));
  final bytes = List<int>.generate(128, (index) => index);
  await file.writeAsBytes(bytes, flush: true);
  return StoredImage(
    path: file.path,
    sha256: 'fixture-sha256',
    width: 2400,
    height: 2400,
    sizeBytes: bytes.length,
  );
}

AnalyzeTargetResult _completedAnalysis() => AnalyzeTargetResult(
  status: VisionAnalysisStatus.completed,
  engineVersion: 'vision-core-test',
  provenance: VisionProvenance(
    backend: VisionBackend.openCv,
    abiVersion: 2,
    engineVersion: 'vision-core-test',
    capabilities: const ['quality', 'registration', 'candidates'],
    algorithmVersions: const {
      'quality': 'quality-v1',
      'registration': 'registration-v2',
      'candidates': 'candidates-v1',
    },
  ),
  registrationResult: VisionRegistrationResult(
    status: VisionRegistrationStatus.registered,
    orderedSourceCornersNormalized: const [
      VisionPoint(x: 0.05, y: 0.05),
      VisionPoint(x: 0.95, y: 0.05),
      VisionPoint(x: 0.95, y: 0.95),
      VisionPoint(x: 0.05, y: 0.95),
    ],
    sourceNormalizedToCardMmHomography: const [1, 0, 0, 0, 1, 0, 0, 0, 1],
    reprojectionErrorPx: 0.4,
    estimatedPerspectiveAngleDegrees: 3,
    algorithmVersion: 'registration-v2',
  ),
  qualityAssessment: VisionQualityAssessment(
    status: VisionQualityStatus.accepted,
    widthPx: 2400,
    heightPx: 2400,
  ),
  candidateImpacts: [
    VisionCandidateImpact(
      id: 'candidate-1',
      sourceImageXNormalized: 0.5,
      sourceImageYNormalized: 0.5,
      cardXMm: 0,
      cardYMm: 0,
      estimatedDiameterMm: 5.6,
      confidenceBand: VisionConfidenceBand.high,
      reasons: const [VisionCandidateReason.diameterMatchesProjectile],
      boundaryUncertaintyMm: 0.4,
    ),
  ],
);
