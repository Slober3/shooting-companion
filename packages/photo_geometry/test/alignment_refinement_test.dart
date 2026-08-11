import 'dart:math' as math;

import 'package:shooting_companion_photo_geometry/photo_geometry.dart';
import 'package:test/test.dart';

void main() {
  test('translation moves every source anchor equally', () {
    const points = [NormalizedPoint(0.2, 0.3), NormalizedPoint(0.8, 0.7)];
    const refinement = AlignmentRefinementTransform(
      pivot: NormalizedPoint(0.5, 0.5),
      translation: NormalizedPoint(0.03, -0.02),
    );
    final result = refinement.applyAll(points);
    expect(result[0].x, closeTo(0.23, 1e-12));
    expect(result[0].y, closeTo(0.28, 1e-12));
    expect(result[1].x, closeTo(0.83, 1e-12));
    expect(result[1].y, closeTo(0.68, 1e-12));
  });

  test('scale and rotation preserve the pivot', () {
    const refinement = AlignmentRefinementTransform(
      pivot: NormalizedPoint(0.5, 0.5),
      scale: 2,
      rotationRadians: math.pi / 2,
    );
    final result = refinement.applyAll(const [
      NormalizedPoint(0.6, 0.5),
      NormalizedPoint(0.5, 0.5),
    ]);
    expect(result[0].x, closeTo(0.5, 1e-12));
    expect(result[0].y, closeTo(0.7, 1e-12));
    expect(result[1], const NormalizedPoint(0.5, 0.5));
  });

  test('centroid and invalid refinement are deterministic', () {
    expect(
      AlignmentRefinementTransform.centroid(const [
        NormalizedPoint(0.2, 0.4),
        NormalizedPoint(0.8, 0.6),
      ]),
      const NormalizedPoint(0.5, 0.5),
    );
    expect(
      () => const AlignmentRefinementTransform(
        pivot: NormalizedPoint(0.5, 0.5),
        scale: 0,
      ).applyAll(const [NormalizedPoint(0.2, 0.2)]),
      throwsArgumentError,
    );
  });
}
