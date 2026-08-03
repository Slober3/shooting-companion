import 'dart:math' as math;

import 'package:shooting_companion_domain/domain.dart';

class ScoredImpact {
  const ScoredImpact({
    required this.impact,
    required this.value,
    required this.isInnerTen,
    required this.isBoundaryUncertain,
    required this.radialDistanceMm,
  });

  final ShotImpact impact;
  final int value;
  final bool isInnerTen;
  final bool isBoundaryUncertain;
  final double radialDistanceMm;

  int get subtotal => value * impact.multiplicity;
}

class ScoreResult {
  const ScoreResult({
    required this.shots,
    required this.total,
    required this.maximumPossible,
    required this.innerTenCount,
    required this.missCount,
    required this.hasBoundaryWarnings,
  });

  final List<ScoredImpact> shots;
  final int total;
  final int maximumPossible;
  final int innerTenCount;
  final int missCount;
  final bool hasBoundaryWarnings;

  double get percentage =>
      maximumPossible == 0 ? 0 : total / maximumPossible * 100;

  int get actualShotCount =>
      shots.fold(0, (count, shot) => count + shot.impact.multiplicity);
}

abstract final class ScoreEngine {
  static ScoreResult score({
    required TargetProfile target,
    required Iterable<ShotImpact> impacts,
    required double projectileDiameterMm,
    double positionUncertaintyMm = 0.75,
  }) {
    if (projectileDiameterMm <= 0) {
      throw ArgumentError.value(
        projectileDiameterMm,
        'projectileDiameterMm',
        'Moet groter zijn dan nul',
      );
    }

    final scored = impacts
        .map(
          (impact) => _scoreImpact(
            target: target,
            impact: impact,
            projectileDiameterMm: projectileDiameterMm,
            positionUncertaintyMm: positionUncertaintyMm,
          ),
        )
        .toList(growable: false);

    final actualShots = scored.fold<int>(
      0,
      (sum, shot) => sum + shot.impact.multiplicity,
    );
    return ScoreResult(
      shots: scored,
      total: scored.fold(0, (sum, shot) => sum + shot.subtotal),
      maximumPossible: actualShots * target.maximumScore,
      innerTenCount: scored.fold(
        0,
        (sum, shot) => sum + (shot.isInnerTen ? shot.impact.multiplicity : 0),
      ),
      missCount: scored.fold(
        0,
        (sum, shot) => sum + (shot.value == 0 ? shot.impact.multiplicity : 0),
      ),
      hasBoundaryWarnings: scored.any((shot) => shot.isBoundaryUncertain),
    );
  }

  static ScoredImpact _scoreImpact({
    required TargetProfile target,
    required ShotImpact impact,
    required double projectileDiameterMm,
    required double positionUncertaintyMm,
  }) {
    final radialDistance = math.sqrt(
      impact.xMm * impact.xMm + impact.yMm * impact.yMm,
    );
    if (impact.isMiss) {
      return ScoredImpact(
        impact: impact,
        value: 0,
        isInnerTen: false,
        isBoundaryUncertain: false,
        radialDistanceMm: radialDistance,
      );
    }

    final bulletRadius = projectileDiameterMm / 2;
    final qualifyingRadius =
        target.lineBreakingRule == LineBreakingRule.bulletEdgeTouchesHigherRing
        ? math.max(0.0, radialDistance - bulletRadius)
        : radialDistance;

    var value = 0;
    for (final ring in target.rings) {
      if (qualifyingRadius <= ring.outerDiameterMm / 2) {
        value = ring.value;
        break;
      }
    }

    final nearestBoundaryDistance = target.rings
        .map((ring) => (qualifyingRadius - ring.outerDiameterMm / 2).abs())
        .reduce(math.min);
    final isBoundaryUncertain =
        impact.isPositionUncertain ||
        nearestBoundaryDistance <= positionUncertaintyMm;
    final innerTenDiameter = target.innerTenDiameterMm;
    final isInnerTen =
        value == target.maximumScore &&
        innerTenDiameter != null &&
        qualifyingRadius <= innerTenDiameter / 2;

    return ScoredImpact(
      impact: impact,
      value: value,
      isInnerTen: isInnerTen,
      isBoundaryUncertain: isBoundaryUncertain,
      radialDistanceMm: radialDistance,
    );
  }
}
