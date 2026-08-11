import 'dart:math' as math;

import 'package:shooting_companion_domain/domain.dart';

enum BoundaryKind { scoringRing, innerTen }

/// Deterministic evaluation of one radial impact against a target profile.
///
/// For line-breaking targets a projectile with radius `b` touches a circular
/// boundary with radius `r` when its centre distance `d` satisfies `d <= r+b`.
/// This is algebraically equivalent to evaluating `max(0, d-b) <= r`.
class BoundaryEvaluation {
  const BoundaryEvaluation({
    required this.value,
    required this.isInnerTen,
    required this.radialDistanceMm,
    required this.qualifyingRadiusMm,
    required this.nearestBoundaryDistanceMm,
    required this.nearestBoundaryKind,
    required this.nearestBoundaryValue,
    required this.effectivePositionUncertaintyMm,
    required this.isBoundaryUncertain,
  });

  final int value;
  final bool isInnerTen;
  final double radialDistanceMm;

  /// Radial distance after applying the projectile radius for line breaking.
  final double qualifyingRadiusMm;

  /// Absolute centre-distance to the nearest effective scoring threshold.
  final double nearestBoundaryDistanceMm;
  final BoundaryKind nearestBoundaryKind;

  /// Ring value for [BoundaryKind.scoringRing], otherwise `null`.
  final int? nearestBoundaryValue;
  final double effectivePositionUncertaintyMm;
  final bool isBoundaryUncertain;
}

abstract final class RadialScoreEvaluator {
  // Coordinate transforms and trigonometric projections can place a
  // mathematically tangent centre a few ulps beyond the same boundary. This
  // tiny comparison tolerance preserves the official tangent-inclusive rule;
  // it is many orders of magnitude below any physical or UI precision.
  static const _comparisonEpsilonMm = 1e-9;

  static BoundaryEvaluation evaluate({
    required TargetProfile target,
    required double xMm,
    required double yMm,
    required double projectileDiameterMm,
    double centerXMm = 0,
    double centerYMm = 0,
    double positionUncertaintyMm = 0,
    bool forceUncertain = false,
  }) {
    target.validateRuntime().requireValid(argumentName: 'target');
    _requireFinite(xMm, 'xMm');
    _requireFinite(yMm, 'yMm');
    _requireFinite(centerXMm, 'centerXMm');
    _requireFinite(centerYMm, 'centerYMm');
    if (!projectileDiameterMm.isFinite || projectileDiameterMm <= 0) {
      throw ArgumentError.value(
        projectileDiameterMm,
        'projectileDiameterMm',
        'Moet eindig en groter dan nul zijn.',
      );
    }
    if (!positionUncertaintyMm.isFinite || positionUncertaintyMm < 0) {
      throw ArgumentError.value(
        positionUncertaintyMm,
        'positionUncertaintyMm',
        'Moet eindig en minstens nul zijn.',
      );
    }

    final dx = xMm - centerXMm;
    final dy = yMm - centerYMm;
    final radialDistanceMm = math.sqrt(dx * dx + dy * dy);
    final lineBreaking =
        target.lineBreakingRule == LineBreakingRule.bulletEdgeTouchesHigherRing;
    final projectileRadiusMm = lineBreaking ? projectileDiameterMm / 2 : 0.0;
    final qualifyingRadiusMm = math.max(
      0.0,
      radialDistanceMm - projectileRadiusMm,
    );

    var value = 0;
    var nearestBoundaryDistanceMm = double.infinity;
    var nearestBoundaryKind = BoundaryKind.scoringRing;
    int? nearestBoundaryValue;

    for (final ring in target.rings) {
      final effectiveBoundaryMm = ring.outerDiameterMm / 2 + projectileRadiusMm;
      if (value == 0 &&
          radialDistanceMm <= effectiveBoundaryMm + _comparisonEpsilonMm) {
        value = ring.value;
      }
      final boundaryDistance = (radialDistanceMm - effectiveBoundaryMm).abs();
      if (boundaryDistance < nearestBoundaryDistanceMm) {
        nearestBoundaryDistanceMm = boundaryDistance;
        nearestBoundaryKind = BoundaryKind.scoringRing;
        nearestBoundaryValue = ring.value;
      }
    }

    final innerTenDiameterMm = target.innerTenDiameterMm;
    var isInnerTen = false;
    if (innerTenDiameterMm != null) {
      final effectiveInnerTenBoundaryMm =
          innerTenDiameterMm / 2 + projectileRadiusMm;
      isInnerTen =
          value == target.maximumScore &&
          radialDistanceMm <=
              effectiveInnerTenBoundaryMm + _comparisonEpsilonMm;
      final boundaryDistance = (radialDistanceMm - effectiveInnerTenBoundaryMm)
          .abs();
      if (boundaryDistance < nearestBoundaryDistanceMm) {
        nearestBoundaryDistanceMm = boundaryDistance;
        nearestBoundaryKind = BoundaryKind.innerTen;
        nearestBoundaryValue = null;
      }
    }

    return BoundaryEvaluation(
      value: value,
      isInnerTen: isInnerTen,
      radialDistanceMm: radialDistanceMm,
      qualifyingRadiusMm: qualifyingRadiusMm,
      nearestBoundaryDistanceMm: nearestBoundaryDistanceMm,
      nearestBoundaryKind: nearestBoundaryKind,
      nearestBoundaryValue: nearestBoundaryValue,
      effectivePositionUncertaintyMm: positionUncertaintyMm,
      isBoundaryUncertain:
          forceUncertain || nearestBoundaryDistanceMm <= positionUncertaintyMm,
    );
  }

  static void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'Moet eindig zijn.');
    }
  }
}
