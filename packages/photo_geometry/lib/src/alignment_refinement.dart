import 'dart:math' as math;

import 'geometry_models.dart';

/// A deterministic image-space refinement applied to alignment anchors.
///
/// This is deliberately not a render-only offset. Callers rebuild their
/// [ManualPhotoAlignment] from the returned source points, so photo markers,
/// scoring and the visible overlay always use the same geometry.
class AlignmentRefinementTransform {
  const AlignmentRefinementTransform({
    required this.pivot,
    this.translation = const NormalizedPoint(0, 0),
    this.scale = 1,
    this.rotationRadians = 0,
  });

  final NormalizedPoint pivot;
  final NormalizedPoint translation;
  final double scale;
  final double rotationRadians;

  List<NormalizedPoint> applyAll(Iterable<NormalizedPoint> points) {
    if (!pivot.isFinite ||
        !translation.isFinite ||
        !scale.isFinite ||
        scale <= 0 ||
        !rotationRadians.isFinite) {
      throw ArgumentError('Alignment refinement must be finite and positive.');
    }
    final cosine = math.cos(rotationRadians);
    final sine = math.sin(rotationRadians);
    return List.unmodifiable(
      points.map((point) {
        if (!point.isFinite) {
          throw ArgumentError('Alignment points must be finite.');
        }
        final x = (point.x - pivot.x) * scale;
        final y = (point.y - pivot.y) * scale;
        return NormalizedPoint(
          pivot.x + translation.x + x * cosine - y * sine,
          pivot.y + translation.y + x * sine + y * cosine,
        );
      }),
    );
  }

  static NormalizedPoint centroid(Iterable<NormalizedPoint> points) {
    final values = points.toList(growable: false);
    if (values.isEmpty || values.any((point) => !point.isFinite)) {
      throw ArgumentError('At least one finite alignment point is required.');
    }
    return NormalizedPoint(
      values.fold<double>(0, (sum, point) => sum + point.x) / values.length,
      values.fold<double>(0, (sum, point) => sum + point.y) / values.length,
    );
  }
}
