import 'dart:math' as math;

import 'package:shooting_companion_domain/domain.dart';

class GroupMetrics {
  const GroupMetrics({
    required this.shotCount,
    required this.centroidXMm,
    required this.centroidYMm,
    required this.extremeSpreadMm,
    required this.meanRadiusMm,
  });

  final int shotCount;
  final double centroidXMm;
  final double centroidYMm;
  final double extremeSpreadMm;
  final double meanRadiusMm;

  double moaAt(double distanceMeters) {
    if (distanceMeters <= 0) return 0;
    final radians = extremeSpreadMm / (distanceMeters * 1000);
    return radians * 180 / math.pi * 60;
  }

  double milliradiansAt(double distanceMeters) {
    if (distanceMeters <= 0) return 0;
    return extremeSpreadMm / distanceMeters;
  }
}

abstract final class GroupAnalyzer {
  static GroupMetrics calculate(Iterable<ShotImpact> source) {
    final impacts = source.where((impact) => !impact.isMiss).toList();
    final shotCount = impacts.fold<int>(
      0,
      (sum, impact) => sum + impact.multiplicity,
    );
    if (shotCount == 0) {
      return const GroupMetrics(
        shotCount: 0,
        centroidXMm: 0,
        centroidYMm: 0,
        extremeSpreadMm: 0,
        meanRadiusMm: 0,
      );
    }

    final centroidX =
        impacts.fold<double>(
          0,
          (sum, impact) => sum + impact.xMm * impact.multiplicity,
        ) /
        shotCount;
    final centroidY =
        impacts.fold<double>(
          0,
          (sum, impact) => sum + impact.yMm * impact.multiplicity,
        ) /
        shotCount;

    var extremeSpread = 0.0;
    for (var first = 0; first < impacts.length; first++) {
      for (var second = first + 1; second < impacts.length; second++) {
        final dx = impacts[first].xMm - impacts[second].xMm;
        final dy = impacts[first].yMm - impacts[second].yMm;
        extremeSpread = math.max(extremeSpread, math.sqrt(dx * dx + dy * dy));
      }
    }

    final meanRadius =
        impacts.fold<double>(0, (sum, impact) {
          final dx = impact.xMm - centroidX;
          final dy = impact.yMm - centroidY;
          return sum + math.sqrt(dx * dx + dy * dy) * impact.multiplicity;
        }) /
        shotCount;

    return GroupMetrics(
      shotCount: shotCount,
      centroidXMm: centroidX,
      centroidYMm: centroidY,
      extremeSpreadMm: extremeSpread,
      meanRadiusMm: meanRadius,
    );
  }
}
