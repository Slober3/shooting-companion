import 'dart:convert';
import 'dart:io';

import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_vision_api/vision_api.dart';
import 'package:test/test.dart';

void main() {
  group('AnalyzeTargetRequest', () {
    test('round-trips an immutable target snapshot', () {
      final request = AnalyzeTargetRequest(
        imagePath: r'C:\private\target.jpg',
        targetProfileSnapshot: _profile,
        projectileDiameterMm: 5.6,
        processingOptions: const VisionProcessingOptions(
          enableCandidateDetection: false,
        ),
      );
      final restored = AnalyzeTargetRequest.fromJsonString(
        request.toJsonString(),
      );
      expect(restored.imagePath, request.imagePath);
      expect(restored.targetProfileSnapshot.versionedId, _profile.versionedId);
      expect(restored.targetProfileSnapshot.rings, hasLength(2));
      expect(restored.projectileDiameterMm, 5.6);
      expect(restored.processingOptions.enableCandidateDetection, isFalse);
    });

    test('rejects a future schema explicitly', () {
      final json =
          jsonDecode(
                AnalyzeTargetRequest(
                  imagePath: 'target.jpg',
                  targetProfileSnapshot: _profile,
                  projectileDiameterMm: 5.6,
                ).toJsonString(),
              )
              as Map<String, Object?>;
      json['schemaVersion'] = 99;
      expect(
        () => AnalyzeTargetRequest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('AnalyzeTargetResult', () {
    test('round-trips registration, quality, candidates and provenance', () {
      final result = AnalyzeTargetResult(
        status: VisionAnalysisStatus.completed,
        engineVersion: 'vision-core-0.1.0',
        provenance: VisionProvenance(
          backend: VisionBackend.openCv,
          abiVersion: 1,
          engineVersion: 'vision-core-0.1.0',
          capabilities: const ['quality', 'registration', 'candidates'],
          algorithmVersions: const {
            'quality': 'quality-v1',
            'registration': 'contour-rings-v1',
          },
          analyzedAtUtc: DateTime.utc(2026, 8, 4, 20),
        ),
        registrationResult: VisionRegistrationResult(
          status: VisionRegistrationStatus.registered,
          orderedSourceCornersNormalized: const [
            VisionPoint(x: 0.1, y: 0.1),
            VisionPoint(x: 0.9, y: 0.1),
            VisionPoint(x: 0.9, y: 0.9),
            VisionPoint(x: 0.1, y: 0.9),
          ],
          sourceNormalizedToCardMmHomography: const [1, 0, 0, 0, 1, 0, 0, 0, 1],
          reprojectionErrorPx: 0.4,
          algorithmVersion: 'contour-rings-v1',
        ),
        qualityAssessment: VisionQualityAssessment(
          status: VisionQualityStatus.accepted,
          widthPx: 3024,
          heightPx: 4032,
          blurScore: 180,
          contrastScore: 42,
        ),
        candidateImpacts: [
          VisionCandidateImpact(
            id: 'candidate-1',
            sourceImageXNormalized: 0.5,
            sourceImageYNormalized: 0.5,
            cardXMm: 0,
            cardYMm: 0,
            estimatedDiameterMm: 5.7,
            confidenceBand: VisionConfidenceBand.medium,
            reasons: const [
              VisionCandidateReason.localContrast,
              VisionCandidateReason.diameterMatchesProjectile,
            ],
            boundaryUncertaintyMm: 0.8,
          ),
        ],
        warnings: const [
          VisionWarning(
            code: VisionWarningCode.candidatesRequireReview,
            message: 'Controleer iedere voorgestelde treffer.',
          ),
        ],
        diagnosticMetrics: const {'processing_ms': 320},
      );
      final restored = AnalyzeTargetResult.fromJsonString(
        result.toJsonString(),
      );
      expect(restored.status, VisionAnalysisStatus.completed);
      expect(restored.modelVersion, isNull);
      expect(restored.candidateImpacts.single.id, 'candidate-1');
      expect(
        restored.registrationResult.sourceNormalizedToCardMmHomography,
        hasLength(9),
      );
      expect(restored.provenance.backend, VisionBackend.openCv);
      expect(restored.requiresManualReview, isTrue);
      expect(
        () => restored.candidateImpacts.add(restored.candidateImpacts.single),
        throwsUnsupportedError,
      );
      expect(
        () => restored.provenance.capabilities.add('silentConfirmation'),
        throwsUnsupportedError,
      );
      expect(
        () => restored.provenance.algorithmVersions['quality'] = 'changed',
        throwsUnsupportedError,
      );
    });

    test('unsupported results are honest and contain no candidates', () {
      final result = AnalyzeTargetResult(
        status: VisionAnalysisStatus.unsupported,
        engineVersion: 'vision-core-0.1.0',
        provenance: VisionProvenance(
          backend: VisionBackend.geometryOnly,
          abiVersion: 1,
          engineVersion: 'vision-core-0.1.0',
          capabilities: const ['imageMetadata', 'grayscaleQuality'],
          algorithmVersions: const {'quality': 'quality-v1'},
        ),
        registrationResult: VisionRegistrationResult(
          status: VisionRegistrationStatus.unsupported,
        ),
        qualityAssessment: VisionQualityAssessment(
          status: VisionQualityStatus.notAnalyzed,
        ),
        warnings: const [
          VisionWarning(
            code: VisionWarningCode.openCvUnavailable,
            message: 'Deze build bevat geen OpenCV-backend.',
          ),
        ],
      );
      final restored = AnalyzeTargetResult.fromJsonString(
        result.toJsonString(),
      );
      expect(restored.candidateImpacts, isEmpty);
      expect(restored.status, VisionAnalysisStatus.unsupported);
      expect(restored.requiresManualReview, isTrue);
    });

    test('parses the native geometry-only CLI fixture', () {
      final result = AnalyzeTargetResult.fromJsonString(
        File('test/fixtures/native_unsupported_result.json').readAsStringSync(),
      );
      expect(result.status, VisionAnalysisStatus.unsupported);
      expect(result.provenance.backend, VisionBackend.geometryOnly);
      expect(result.qualityAssessment.status, VisionQualityStatus.review);
      expect(result.candidateImpacts, isEmpty);
      expect(
        result.warnings.map((warning) => warning.code),
        contains(VisionWarningCode.openCvUnavailable),
      );
    });

    test('non-completed results cannot expose candidate impacts', () {
      expect(
        () => AnalyzeTargetResult(
          status: VisionAnalysisStatus.unsupported,
          engineVersion: 'vision-core-0.1.0',
          provenance: VisionProvenance(
            backend: VisionBackend.geometryOnly,
            abiVersion: 1,
            engineVersion: 'vision-core-0.1.0',
            capabilities: const [],
            algorithmVersions: const {},
          ),
          registrationResult: VisionRegistrationResult(
            status: VisionRegistrationStatus.unsupported,
          ),
          qualityAssessment: VisionQualityAssessment(
            status: VisionQualityStatus.unsupported,
          ),
          candidateImpacts: [
            VisionCandidateImpact(
              id: 'fake',
              sourceImageXNormalized: 0.5,
              sourceImageYNormalized: 0.5,
              cardXMm: 0,
              cardYMm: 0,
              estimatedDiameterMm: 5.6,
              confidenceBand: VisionConfidenceBand.low,
              reasons: const [VisionCandidateReason.geometryUnverified],
              boundaryUncertaintyMm: 2,
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

final _profile = TargetProfile(
  schemaVersion: 1,
  profileId: 'test-target',
  profileVersion: 1,
  displayName: 'Testkaart',
  authority: 'Test',
  rulesEdition: '1',
  physicalCardWidthMm: 550,
  physicalCardHeightMm: 550,
  rings: const [
    RingZone(value: 10, outerDiameterMm: 50),
    RingZone(value: 9, outerDiameterMm: 100),
  ],
  lineThicknessMm: 0.5,
  lineBreakingRule: LineBreakingRule.bulletEdgeTouchesHigherRing,
  validationStatus: ValidationStatus.experimental,
);
