import 'dart:math' as math;

import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;
import 'package:shooting_companion_vision_api/vision_api.dart';

bool visionCandidateAcceptedByDefault(VisionCandidateImpact candidate) =>
    candidate.confidenceBand != VisionConfidenceBand.low;

/// Reprojects immutable native candidates after a user changes photo alignment.
///
/// Original-photo coordinates remain authoritative. Card coordinates and the
/// scoring-boundary warning are derived again from the confirmed homography.
List<VisionCandidateImpact> reprojectVisionCandidates({
  required Iterable<VisionCandidateImpact> candidates,
  required geo.ManualPhotoAlignment alignment,
  required domain.TargetProfile target,
  required double projectileDiameterMm,
}) => candidates
    .map((candidate) {
      final physical = alignment.normalizedToPhysical(
        geo.rotateNormalizedPoint(
          geo.NormalizedPoint(
            candidate.sourceImageXNormalized,
            candidate.sourceImageYNormalized,
          ),
          alignment.rotationQuarterTurns,
        ),
      );
      final radius = math.sqrt(
        physical.x * physical.x + physical.y * physical.y,
      );
      final boundaryMargin =
          projectileDiameterMm / 2 +
          candidate.boundaryUncertaintyMm +
          target.lineThicknessMm / 2;
      final nearBoundary = target.rings.any(
        (ring) => (radius - ring.outerDiameterMm / 2).abs() <= boundaryMargin,
      );
      final reasons = candidate.reasons
          .where((reason) => reason != VisionCandidateReason.nearScoringLine)
          .toList();
      if (nearBoundary) reasons.add(VisionCandidateReason.nearScoringLine);
      return candidate.copyWith(
        cardXMm: physical.x,
        cardYMm: physical.y,
        reasons: reasons,
        nearScoringBoundary: nearBoundary,
      );
    })
    .toList(growable: false);
