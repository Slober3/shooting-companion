import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/features/vision/vision_candidate_geometry.dart';
import 'package:shooting_companion_photo_geometry/photo_geometry.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:shooting_companion_vision_api/vision_api.dart';

void main() {
  test('low-confidence candidates never count by default', () {
    final low = VisionCandidateImpact(
      id: 'low',
      sourceImageXNormalized: 0.5,
      sourceImageYNormalized: 0.5,
      cardXMm: 0,
      cardYMm: 0,
      estimatedDiameterMm: 5.6,
      confidenceBand: VisionConfidenceBand.low,
      reasons: const [VisionCandidateReason.darkCore],
      boundaryUncertaintyMm: 0.4,
    );
    final medium = VisionCandidateImpact(
      id: 'medium',
      sourceImageXNormalized: 0.5,
      sourceImageYNormalized: 0.5,
      cardXMm: 0,
      cardYMm: 0,
      estimatedDiameterMm: 5.6,
      confidenceBand: VisionConfidenceBand.medium,
      reasons: const [VisionCandidateReason.darkCore],
      boundaryUncertaintyMm: 0.4,
    );

    expect(visionCandidateAcceptedByDefault(low), isFalse);
    expect(visionCandidateAcceptedByDefault(medium), isTrue);
  });

  test('manual realignment reprojects candidates from source coordinates', () {
    final target = IssfTargetProfiles.precision25m50m;
    final result = ManualPhotoAlignment.build(
      corners: const NormalizedQuad(
        topLeft: NormalizedPoint(0.1, 0.1),
        topRight: NormalizedPoint(0.9, 0.1),
        bottomRight: NormalizedPoint(0.9, 0.9),
        bottomLeft: NormalizedPoint(0.1, 0.9),
      ),
      cardWidthMm: target.physicalCardWidthMm,
      cardHeightMm: target.physicalCardHeightMm,
    );
    final candidate = VisionCandidateImpact(
      id: 'candidate-1',
      sourceImageXNormalized: 0.5,
      sourceImageYNormalized: 0.5,
      cardXMm: 40,
      cardYMm: -30,
      estimatedDiameterMm: 5.6,
      confidenceBand: VisionConfidenceBand.high,
      reasons: const [VisionCandidateReason.darkCore],
      boundaryUncertaintyMm: 0.4,
    );

    final reprojected = reprojectVisionCandidates(
      candidates: [candidate],
      alignment: result.alignment!,
      target: target,
      projectileDiameterMm: 5.6,
    ).single;

    expect(reprojected.cardXMm, closeTo(0, 1e-7));
    expect(reprojected.cardYMm, closeTo(0, 1e-7));
    expect(reprojected.sourceImageXNormalized, 0.5);
    expect(reprojected.sourceImageYNormalized, 0.5);
  });

  test('manual realignment recomputes scoring-boundary warnings', () {
    final target = IssfTargetProfiles.precision25m50m;
    final result = ManualPhotoAlignment.build(
      corners: const NormalizedQuad(
        topLeft: NormalizedPoint(0, 0),
        topRight: NormalizedPoint(1, 0),
        bottomRight: NormalizedPoint(1, 1),
        bottomLeft: NormalizedPoint(0, 1),
      ),
      cardWidthMm: target.physicalCardWidthMm,
      cardHeightMm: target.physicalCardHeightMm,
    );
    final candidate = VisionCandidateImpact(
      id: 'candidate-2',
      sourceImageXNormalized: 0.5,
      sourceImageYNormalized: 0.5,
      cardXMm: 80,
      cardYMm: 80,
      estimatedDiameterMm: 5.6,
      confidenceBand: VisionConfidenceBand.medium,
      reasons: const [
        VisionCandidateReason.darkCore,
        VisionCandidateReason.nearScoringLine,
      ],
      boundaryUncertaintyMm: 0.4,
      nearScoringBoundary: true,
    );

    final reprojected = reprojectVisionCandidates(
      candidates: [candidate],
      alignment: result.alignment!,
      target: target,
      projectileDiameterMm: 5.6,
    ).single;

    expect(reprojected.nearScoringBoundary, isFalse);
    expect(
      reprojected.reasons,
      isNot(contains(VisionCandidateReason.nearScoringLine)),
    );
  });

  test('candidate source coordinates remain original across rotation', () {
    final target = IssfTargetProfiles.precision25m50m;
    const originalCorners = [
      NormalizedPoint(0, 0),
      NormalizedPoint(1, 0),
      NormalizedPoint(1, 1),
      NormalizedPoint(0, 1),
    ];
    final rotated = originalCorners
        .map((point) => rotateNormalizedPoint(point, 1))
        .toList(growable: false);
    final result = ManualPhotoAlignment.build(
      corners: NormalizedQuad.fromOrderedPoints(rotated),
      cardWidthMm: target.physicalCardWidthMm,
      cardHeightMm: target.physicalCardHeightMm,
      rotationQuarterTurns: 1,
    );
    expect(result.isValid, isTrue);
    final candidate = VisionCandidateImpact(
      id: 'rotated',
      sourceImageXNormalized: 0.25,
      sourceImageYNormalized: 0.40,
      cardXMm: 999,
      cardYMm: 999,
      estimatedDiameterMm: 5.6,
      confidenceBand: VisionConfidenceBand.high,
      reasons: const [VisionCandidateReason.darkCore],
      boundaryUncertaintyMm: 0.4,
    );

    final reprojected = reprojectVisionCandidates(
      candidates: [candidate],
      alignment: result.alignment!,
      target: target,
      projectileDiameterMm: 5.6,
    ).single;

    expect(reprojected.cardXMm, closeTo(-137.5, 1e-7));
    expect(reprojected.cardYMm, closeTo(-55, 1e-7));
    expect(reprojected.sourceImageXNormalized, 0.25);
    expect(reprojected.sourceImageYNormalized, 0.40);
  });
}
