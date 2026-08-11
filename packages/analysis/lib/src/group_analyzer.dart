import 'dart:math' as math;

import 'package:shooting_companion_domain/domain.dart';

import 'models.dart';

/// Pure, deterministic calculations for manually confirmed shot positions.
abstract final class GroupAnalyzer {
  static const minimumSubgroupShotCount = 10;
  static const minimumSilhouetteScore = 0.55;
  static const minimumSubgroupStability = 0.80;

  /// Produces metrics, reliability, warnings, normalized positions and an
  /// optional possible-subgroup suggestion for one series.
  static SeriesAnalysis analyze({
    required String seriesId,
    required Iterable<ShotImpact> impacts,
    required TargetProfile targetProfile,
    double? distanceMeters,
    bool includeUncertainPositions = true,
    bool detectSubgroups = true,
  }) {
    final prepared = _preparePositions(
      impacts,
      targetProfile,
      includeUncertainPositions: includeUncertainPositions,
    );
    final warningCounts = <AnalysisWarningCode, int>{...prepared.warningCounts};
    final reliability = _reliabilityFor(prepared.positionedShotCount);
    _addReliabilityWarning(
      warningCounts,
      reliability,
      prepared.positionedShotCount,
    );

    final extremeSpread = _extremeSpread(prepared.positions);
    double? moa;
    double? milliradians;
    if (distanceMeters != null) {
      if (distanceMeters > 0 && distanceMeters.isFinite) {
        final radians = extremeSpread.distanceMm / (distanceMeters * 1000);
        moa = radians * 180 / math.pi * 60;
        milliradians = extremeSpread.distanceMm / distanceMeters;
      } else {
        warningCounts[AnalysisWarningCode.invalidDistance] =
            prepared.positionedShotCount;
      }
    }

    final metrics = _calculateMetrics(
      prepared.actualShotCount,
      prepared.positions,
      extremeSpread: extremeSpread,
      extremeSpreadMoa: moa,
      extremeSpreadMilliradians: milliradians,
    );
    final suggestion = detectSubgroups
        ? _SubgroupDetector.detect(prepared.positions)
        : null;

    return SeriesAnalysis(
      seriesId: seriesId,
      metrics: metrics,
      reliability: reliability,
      warnings: warningCounts.entries
          .map(
            (entry) => AnalysisWarning(
              code: entry.key,
              affectedShotCount: entry.value,
            ),
          )
          .toList(growable: false),
      positions: prepared.positions,
      subgroupSuggestion: suggestion,
    );
  }

  /// Convenience API when only the measurements are needed.
  static GroupMetrics calculate(
    Iterable<ShotImpact> impacts, {
    required TargetProfile targetProfile,
    double? distanceMeters,
    bool includeUncertainPositions = true,
  }) => analyze(
    seriesId: '',
    impacts: impacts,
    targetProfile: targetProfile,
    distanceMeters: distanceMeters,
    includeUncertainPositions: includeUncertainPositions,
    detectSubgroups: false,
  ).metrics;

  /// Runs only the deterministic subgroup detector over valid positions.
  static SubgroupSuggestion? suggestSubgroups(
    Iterable<ShotImpact> impacts, {
    required TargetProfile targetProfile,
    bool includeUncertainPositions = true,
  }) {
    final prepared = _preparePositions(
      impacts,
      targetProfile,
      includeUncertainPositions: includeUncertainPositions,
    );
    return _SubgroupDetector.detect(prepared.positions);
  }

  static _PreparedPositions _preparePositions(
    Iterable<ShotImpact> source,
    TargetProfile targetProfile, {
    required bool includeUncertainPositions,
  }) {
    final impacts = source.toList(growable: false);
    final warningCounts = <AnalysisWarningCode, int>{};
    final positions = <AnalyzedImpactPosition>[];
    var actualShotCount = 0;

    void warn(AnalysisWarningCode code, int count) {
      warningCounts.update(
        code,
        (value) => value + count,
        ifAbsent: () => count,
      );
    }

    for (final impact in impacts) {
      actualShotCount += impact.multiplicity;
      final isMiss =
          impact.isMiss || impact.scoreDisposition == ScoreDisposition.miss;
      if (isMiss) {
        warn(AnalysisWarningCode.missWithoutPosition, impact.multiplicity);
        continue;
      }

      if (!impact.xMm.isFinite || !impact.yMm.isFinite) {
        warn(AnalysisWarningCode.nonFinitePosition, impact.multiplicity);
        continue;
      }

      if (impact.isPositionUncertain) {
        if (!includeUncertainPositions) {
          warn(
            AnalysisWarningCode.uncertainPositionsExcluded,
            impact.multiplicity,
          );
          continue;
        }
        warn(
          AnalysisWarningCode.uncertainPositionsIncluded,
          impact.multiplicity,
        );
      }

      var xMm = impact.xMm;
      var yMm = impact.yMm;
      if (targetProfile.targetKind == TargetKind.multiBullConcentric) {
        final bullId = impact.targetBullId;
        if (bullId == null) {
          warn(AnalysisWarningCode.missingTargetBull, impact.multiplicity);
          continue;
        }
        final bull = targetProfile.bullById(bullId);
        if (bull == null) {
          warn(AnalysisWarningCode.unknownTargetBull, impact.multiplicity);
          continue;
        }
        if (bull.role != TargetBullRole.record) {
          warn(AnalysisWarningCode.sighterBullExcluded, impact.multiplicity);
          continue;
        }
        xMm -= bull.centerXMm;
        yMm -= bull.centerYMm;
      }

      if (impact.multiplicity > 1) {
        warn(
          AnalysisWarningCode.multiplicityApproximation,
          impact.multiplicity,
        );
      }
      positions.add(
        AnalyzedImpactPosition(
          impactId: impact.id,
          xMm: xMm,
          yMm: yMm,
          multiplicity: impact.multiplicity,
          isPositionUncertain: impact.isPositionUncertain,
          targetBullId: impact.targetBullId,
        ),
      );
    }

    return _PreparedPositions(
      actualShotCount: actualShotCount,
      positions: positions,
      warningCounts: warningCounts,
    );
  }

  static AnalysisReliability _reliabilityFor(int positionedShotCount) {
    if (positionedShotCount == 0) {
      return AnalysisReliability.noPositionData;
    }
    if (positionedShotCount <= 2) {
      return AnalysisReliability.positionsOnly;
    }
    if (positionedShotCount <= 4) {
      return AnalysisReliability.provisional;
    }
    if (positionedShotCount <= 9) {
      return AnalysisReliability.smallSample;
    }
    return AnalysisReliability.full;
  }

  static void _addReliabilityWarning(
    Map<AnalysisWarningCode, int> warnings,
    AnalysisReliability reliability,
    int positionedShotCount,
  ) {
    final code = switch (reliability) {
      AnalysisReliability.noPositionData => AnalysisWarningCode.noPositionData,
      AnalysisReliability.positionsOnly => AnalysisWarningCode.positionsOnly,
      AnalysisReliability.provisional => AnalysisWarningCode.provisionalSample,
      AnalysisReliability.smallSample => AnalysisWarningCode.smallSample,
      AnalysisReliability.full => null,
    };
    if (code != null) warnings[code] = positionedShotCount;
  }

  static GroupMetrics _calculateMetrics(
    int actualShotCount,
    List<AnalyzedImpactPosition> positions, {
    required _ExtremeSpreadResult extremeSpread,
    required double? extremeSpreadMoa,
    required double? extremeSpreadMilliradians,
  }) {
    final positionedShotCount = positions.fold<int>(
      0,
      (sum, position) => sum + position.multiplicity,
    );
    if (positionedShotCount == 0) {
      return GroupMetrics(
        actualShotCount: actualShotCount,
        positionedShotCount: 0,
        centroidXMm: 0,
        centroidYMm: 0,
        extremeSpreadMm: 0,
        extremeSpreadSegment: null,
        meanRadiusMm: 0,
        sampleStandardDeviationXMm: 0,
        sampleStandardDeviationYMm: 0,
        empiricalR50Mm: 0,
        empiricalR90Mm: 0,
        covarianceEllipse: const CovarianceEllipse(
          semiMajorAxisMm: 0,
          semiMinorAxisMm: 0,
          angleDegrees: 0,
        ),
        extremeSpreadMoa: extremeSpreadMoa,
        extremeSpreadMilliradians: extremeSpreadMilliradians,
      );
    }

    final centroidX =
        positions.fold<double>(
          0,
          (sum, position) => sum + position.xMm * position.multiplicity,
        ) /
        positionedShotCount;
    final centroidY =
        positions.fold<double>(
          0,
          (sum, position) => sum + position.yMm * position.multiplicity,
        ) /
        positionedShotCount;

    var radialSum = 0.0;
    var covarianceXX = 0.0;
    var covarianceYY = 0.0;
    var covarianceXY = 0.0;
    final weightedRadii = <_WeightedValue>[];
    for (final position in positions) {
      final dx = position.xMm - centroidX;
      final dy = position.yMm - centroidY;
      final radius = math.sqrt(dx * dx + dy * dy);
      final weight = position.multiplicity;
      radialSum += radius * weight;
      covarianceXX += dx * dx * weight;
      covarianceYY += dy * dy * weight;
      covarianceXY += dx * dy * weight;
      weightedRadii.add(_WeightedValue(radius, weight));
    }

    if (positionedShotCount > 1) {
      final divisor = positionedShotCount - 1;
      covarianceXX /= divisor;
      covarianceYY /= divisor;
      covarianceXY /= divisor;
    } else {
      covarianceXX = 0;
      covarianceYY = 0;
      covarianceXY = 0;
    }

    final ellipse = _covarianceEllipse(
      covarianceXX,
      covarianceYY,
      covarianceXY,
    );
    return GroupMetrics(
      actualShotCount: actualShotCount,
      positionedShotCount: positionedShotCount,
      centroidXMm: centroidX,
      centroidYMm: centroidY,
      extremeSpreadMm: extremeSpread.distanceMm,
      extremeSpreadSegment: extremeSpread.segment,
      meanRadiusMm: radialSum / positionedShotCount,
      sampleStandardDeviationXMm: math.sqrt(math.max(0, covarianceXX)),
      sampleStandardDeviationYMm: math.sqrt(math.max(0, covarianceYY)),
      empiricalR50Mm: _weightedPercentile(weightedRadii, 0.50),
      empiricalR90Mm: _weightedPercentile(weightedRadii, 0.90),
      covarianceEllipse: ellipse,
      extremeSpreadMoa: extremeSpreadMoa,
      extremeSpreadMilliradians: extremeSpreadMilliradians,
    );
  }

  static _ExtremeSpreadResult _extremeSpread(
    List<AnalyzedImpactPosition> positions,
  ) {
    ExtremeSpreadSegment? best;
    for (var first = 0; first < positions.length; first++) {
      for (var second = first + 1; second < positions.length; second++) {
        final candidate = _canonicalSpreadSegment(
          positions[first],
          positions[second],
        );
        if (best == null || _isPreferredSpread(candidate, best)) {
          best = candidate;
        }
      }
    }
    return _ExtremeSpreadResult(
      distanceMm: best?.distanceMm ?? 0,
      segment: best,
    );
  }

  static ExtremeSpreadSegment _canonicalSpreadSegment(
    AnalyzedImpactPosition first,
    AnalyzedImpactPosition second,
  ) {
    final ordered = _comparePosition(first, second) <= 0
        ? (first: first, second: second)
        : (first: second, second: first);
    return ExtremeSpreadSegment(
      firstImpactId: ordered.first.impactId,
      secondImpactId: ordered.second.impactId,
      firstXMm: ordered.first.xMm,
      firstYMm: ordered.first.yMm,
      secondXMm: ordered.second.xMm,
      secondYMm: ordered.second.yMm,
      distanceMm: _distance(ordered.first, ordered.second),
    );
  }

  static bool _isPreferredSpread(
    ExtremeSpreadSegment candidate,
    ExtremeSpreadSegment current,
  ) {
    final distanceDifference = candidate.distanceMm - current.distanceMm;
    if (distanceDifference.abs() > 1e-12) return distanceDifference > 0;
    final firstX = candidate.firstXMm.compareTo(current.firstXMm);
    if (firstX != 0) return firstX < 0;
    final firstY = candidate.firstYMm.compareTo(current.firstYMm);
    if (firstY != 0) return firstY < 0;
    final firstId = candidate.firstImpactId.compareTo(current.firstImpactId);
    if (firstId != 0) return firstId < 0;
    final secondX = candidate.secondXMm.compareTo(current.secondXMm);
    if (secondX != 0) return secondX < 0;
    final secondY = candidate.secondYMm.compareTo(current.secondYMm);
    if (secondY != 0) return secondY < 0;
    return candidate.secondImpactId.compareTo(current.secondImpactId) < 0;
  }

  static int _comparePosition(
    AnalyzedImpactPosition first,
    AnalyzedImpactPosition second,
  ) {
    final x = first.xMm.compareTo(second.xMm);
    if (x != 0) return x;
    final y = first.yMm.compareTo(second.yMm);
    if (y != 0) return y;
    return first.impactId.compareTo(second.impactId);
  }

  static CovarianceEllipse _covarianceEllipse(
    double covarianceXX,
    double covarianceYY,
    double covarianceXY,
  ) {
    final trace = covarianceXX + covarianceYY;
    final discriminant = math.sqrt(
      math.max(
        0,
        (covarianceXX - covarianceYY) * (covarianceXX - covarianceYY) +
            4 * covarianceXY * covarianceXY,
      ),
    );
    final majorEigenvalue = math.max(0, (trace + discriminant) / 2);
    final minorEigenvalue = math.max(0, (trace - discriminant) / 2);
    var angle = discriminant <= 1e-12
        ? 0.0
        : math.atan2(2 * covarianceXY, covarianceXX - covarianceYY) *
              90 /
              math.pi;
    while (angle >= 90) {
      angle -= 180;
    }
    while (angle < -90) {
      angle += 180;
    }
    return CovarianceEllipse(
      semiMajorAxisMm: math.sqrt(majorEigenvalue),
      semiMinorAxisMm: math.sqrt(minorEigenvalue),
      angleDegrees: angle,
    );
  }

  static double _weightedPercentile(
    List<_WeightedValue> source,
    double percentile,
  ) {
    if (source.isEmpty) return 0;
    final values = [...source]..sort((a, b) => a.value.compareTo(b.value));
    final count = values.fold<int>(0, (sum, value) => sum + value.weight);
    if (count == 1) return values.first.value;
    final position = (count - 1) * percentile;
    final lower = position.floor();
    final upper = position.ceil();
    final lowerValue = _weightedValueAt(values, lower);
    final upperValue = _weightedValueAt(values, upper);
    return lowerValue + (upperValue - lowerValue) * (position - lower);
  }

  static double _weightedValueAt(List<_WeightedValue> values, int index) {
    var cumulative = 0;
    for (final value in values) {
      cumulative += value.weight;
      if (index < cumulative) return value.value;
    }
    return values.last.value;
  }

  static double _distance(
    AnalyzedImpactPosition first,
    AnalyzedImpactPosition second,
  ) {
    final dx = first.xMm - second.xMm;
    final dy = first.yMm - second.yMm;
    return math.sqrt(dx * dx + dy * dy);
  }
}

class _PreparedPositions {
  const _PreparedPositions({
    required this.actualShotCount,
    required this.positions,
    required this.warningCounts,
  });

  final int actualShotCount;
  final List<AnalyzedImpactPosition> positions;
  final Map<AnalysisWarningCode, int> warningCounts;

  int get positionedShotCount =>
      positions.fold<int>(0, (sum, position) => sum + position.multiplicity);
}

class _WeightedValue {
  const _WeightedValue(this.value, this.weight);

  final double value;
  final int weight;
}

class _ExtremeSpreadResult {
  const _ExtremeSpreadResult({required this.distanceMm, required this.segment});

  final double distanceMm;
  final ExtremeSpreadSegment? segment;
}

abstract final class _SubgroupDetector {
  static const _stabilityTrials = 20;

  static SubgroupSuggestion? detect(List<AnalyzedImpactPosition> positions) {
    final canonicalPositions = [...positions]
      ..sort((first, second) {
        final x = first.xMm.compareTo(second.xMm);
        if (x != 0) return x;
        final y = first.yMm.compareTo(second.yMm);
        if (y != 0) return y;
        return first.impactId.compareTo(second.impactId);
      });
    final logicalShotCount = canonicalPositions.fold<int>(
      0,
      (sum, position) => sum + position.multiplicity,
    );
    if (logicalShotCount < GroupAnalyzer.minimumSubgroupShotCount ||
        canonicalPositions.length < 4) {
      return null;
    }

    _SubgroupCandidate? best;
    final maximumK = math.min(3, canonicalPositions.length ~/ 2);
    for (var k = 2; k <= maximumK; k++) {
      final fit = _fit(canonicalPositions, k);
      if (fit == null || fit.clusterWeights.any((weight) => weight < 2)) {
        continue;
      }
      final silhouette = _silhouette(canonicalPositions, fit.labels, k);
      if (silhouette + 1e-12 < GroupAnalyzer.minimumSilhouetteScore) {
        continue;
      }
      final stability = _stability(canonicalPositions, fit.labels, k);
      if (stability + 1e-12 < GroupAnalyzer.minimumSubgroupStability) {
        continue;
      }
      final candidate = _SubgroupCandidate(
        fit: fit,
        silhouette: silhouette,
        stability: stability,
      );
      if (_isBetter(candidate, best)) best = candidate;
    }

    if (best == null) return null;
    return _toSuggestion(canonicalPositions, best);
  }

  static bool _isBetter(
    _SubgroupCandidate candidate,
    _SubgroupCandidate? current,
  ) {
    if (current == null) return true;
    if ((candidate.silhouette - current.silhouette).abs() > 1e-9) {
      return candidate.silhouette > current.silhouette;
    }
    if ((candidate.stability - current.stability).abs() > 1e-9) {
      return candidate.stability > current.stability;
    }
    return candidate.fit.centroids.length < current.fit.centroids.length;
  }

  static SubgroupSuggestion _toSuggestion(
    List<AnalyzedImpactPosition> positions,
    _SubgroupCandidate candidate,
  ) {
    final fit = candidate.fit;
    final oldIndices =
        List<int>.generate(fit.centroids.length, (index) => index)
          ..sort((first, second) {
            final x = fit.centroids[first].x.compareTo(fit.centroids[second].x);
            if (x != 0) return x;
            return fit.centroids[first].y.compareTo(fit.centroids[second].y);
          });

    final clusters = <SubgroupCluster>[];
    for (var sortedIndex = 0; sortedIndex < oldIndices.length; sortedIndex++) {
      final oldIndex = oldIndices[sortedIndex];
      final ids = <String>[];
      var logicalShotCount = 0;
      for (var pointIndex = 0; pointIndex < positions.length; pointIndex++) {
        if (fit.labels[pointIndex] != oldIndex) continue;
        ids.add(positions[pointIndex].impactId);
        logicalShotCount += positions[pointIndex].multiplicity;
      }
      clusters.add(
        SubgroupCluster(
          index: sortedIndex,
          centroidXMm: fit.centroids[oldIndex].x,
          centroidYMm: fit.centroids[oldIndex].y,
          logicalShotCount: logicalShotCount,
          impactIds: ids,
        ),
      );
    }

    return SubgroupSuggestion(
      clusterCount: clusters.length,
      silhouetteScore: candidate.silhouette,
      stability: candidate.stability,
      clusters: clusters,
    );
  }

  static _KMeansFit? _fit(List<AnalyzedImpactPosition> positions, int k) {
    if (positions.length < k) return null;
    final centroids = _initialCentroids(positions, k);
    if (centroids == null) return null;
    var labels = List<int>.filled(positions.length, -1);

    for (var iteration = 0; iteration < 100; iteration++) {
      final nextLabels = <int>[];
      for (final position in positions) {
        var bestCluster = 0;
        var bestDistance = double.infinity;
        for (var cluster = 0; cluster < k; cluster++) {
          final distance = _squaredDistanceToCentroid(
            position,
            centroids[cluster],
          );
          if (distance < bestDistance - 1e-12) {
            bestDistance = distance;
            bestCluster = cluster;
          }
        }
        nextLabels.add(bestCluster);
      }

      final sumsX = List<double>.filled(k, 0);
      final sumsY = List<double>.filled(k, 0);
      final weights = List<int>.filled(k, 0);
      for (var index = 0; index < positions.length; index++) {
        final cluster = nextLabels[index];
        final position = positions[index];
        sumsX[cluster] += position.xMm * position.multiplicity;
        sumsY[cluster] += position.yMm * position.multiplicity;
        weights[cluster] += position.multiplicity;
      }
      if (weights.any((weight) => weight == 0)) return null;

      var movement = 0.0;
      for (var cluster = 0; cluster < k; cluster++) {
        final next = _Centroid(
          sumsX[cluster] / weights[cluster],
          sumsY[cluster] / weights[cluster],
        );
        movement = math.max(
          movement,
          _centroidDistance(centroids[cluster], next),
        );
        centroids[cluster] = next;
      }
      final labelsUnchanged = _sameLabels(labels, nextLabels);
      labels = nextLabels;
      if (labelsUnchanged || movement <= 1e-9) {
        return _KMeansFit(
          labels: labels,
          centroids: List.unmodifiable(centroids),
          clusterWeights: weights,
        );
      }
    }

    final weights = List<int>.filled(k, 0);
    for (var index = 0; index < positions.length; index++) {
      weights[labels[index]] += positions[index].multiplicity;
    }
    return _KMeansFit(
      labels: labels,
      centroids: List.unmodifiable(centroids),
      clusterWeights: weights,
    );
  }

  static List<_Centroid>? _initialCentroids(
    List<AnalyzedImpactPosition> positions,
    int k,
  ) {
    var firstIndex = 0;
    var secondIndex = 0;
    var maximumDistance = 0.0;
    for (var first = 0; first < positions.length; first++) {
      for (var second = first + 1; second < positions.length; second++) {
        final distance = _squaredDistance(positions[first], positions[second]);
        if (distance > maximumDistance + 1e-12) {
          maximumDistance = distance;
          firstIndex = first;
          secondIndex = second;
        }
      }
    }
    if (maximumDistance <= 1e-12) return null;

    final centroids = <_Centroid>[
      _Centroid(positions[firstIndex].xMm, positions[firstIndex].yMm),
      _Centroid(positions[secondIndex].xMm, positions[secondIndex].yMm),
    ];
    while (centroids.length < k) {
      var selectedIndex = -1;
      var selectedDistance = -1.0;
      for (var index = 0; index < positions.length; index++) {
        final minimumDistance = centroids
            .map(
              (centroid) =>
                  _squaredDistanceToCentroid(positions[index], centroid),
            )
            .reduce(math.min);
        if (minimumDistance > selectedDistance + 1e-12) {
          selectedDistance = minimumDistance;
          selectedIndex = index;
        }
      }
      if (selectedIndex < 0 || selectedDistance <= 1e-12) return null;
      centroids.add(
        _Centroid(positions[selectedIndex].xMm, positions[selectedIndex].yMm),
      );
    }
    return centroids;
  }

  static double _silhouette(
    List<AnalyzedImpactPosition> positions,
    List<int> labels,
    int k,
  ) {
    final clusterWeights = List<int>.filled(k, 0);
    for (var index = 0; index < positions.length; index++) {
      clusterWeights[labels[index]] += positions[index].multiplicity;
    }
    var weightedScore = 0.0;
    var totalWeight = 0;
    for (var index = 0; index < positions.length; index++) {
      final position = positions[index];
      final ownCluster = labels[index];
      final ownOtherWeight = clusterWeights[ownCluster] - 1;
      if (ownOtherWeight <= 0) continue;

      var ownDistanceSum = 0.0;
      final otherDistanceSums = List<double>.filled(k, 0);
      for (var other = 0; other < positions.length; other++) {
        final distance = _distance(positions[index], positions[other]);
        final logicalWeight = positions[other].multiplicity;
        if (labels[other] == ownCluster) {
          if (other != index) ownDistanceSum += distance * logicalWeight;
        } else {
          otherDistanceSums[labels[other]] += distance * logicalWeight;
        }
      }
      final within = ownDistanceSum / ownOtherWeight;
      var nearestOther = double.infinity;
      for (var cluster = 0; cluster < k; cluster++) {
        if (cluster == ownCluster || clusterWeights[cluster] == 0) continue;
        nearestOther = math.min(
          nearestOther,
          otherDistanceSums[cluster] / clusterWeights[cluster],
        );
      }
      final denominator = math.max(within, nearestOther);
      final score = denominator <= 1e-12
          ? 0.0
          : (nearestOther - within) / denominator;
      weightedScore += score * position.multiplicity;
      totalWeight += position.multiplicity;
    }
    return totalWeight == 0 ? 0 : weightedScore / totalWeight;
  }

  static double _stability(
    List<AnalyzedImpactPosition> positions,
    List<int> baseLabels,
    int k,
  ) {
    final spread = _maximumDistance(positions);
    final jitterAmplitude = math.max(0.01, spread * 0.005);
    var scoreSum = 0.0;

    for (var trial = 0; trial < _stabilityTrials; trial++) {
      final random = _DeterministicRandom(0x51f15e + trial * 7919 + k * 101);
      final indices = List<int>.generate(positions.length, (index) => index);
      for (var index = indices.length - 1; index > 0; index--) {
        final swapWith = random.nextInt(index + 1);
        final value = indices[index];
        indices[index] = indices[swapWith];
        indices[swapWith] = value;
      }
      final subsetSize = math.min(
        positions.length,
        math.max(k * 2, (positions.length * 0.8).ceil()),
      );
      final selected = indices.take(subsetSize).toList()..sort();
      final jittered = <AnalyzedImpactPosition>[];
      for (final originalIndex in selected) {
        final position = positions[originalIndex];
        jittered.add(
          AnalyzedImpactPosition(
            impactId: position.impactId,
            xMm: position.xMm + (random.nextDouble() * 2 - 1) * jitterAmplitude,
            yMm: position.yMm + (random.nextDouble() * 2 - 1) * jitterAmplitude,
            multiplicity: position.multiplicity,
            isPositionUncertain: position.isPositionUncertain,
            targetBullId: position.targetBullId,
          ),
        );
      }

      final fit = _fit(jittered, k);
      if (fit == null || fit.clusterWeights.any((weight) => weight < 2)) {
        continue;
      }
      final referenceLabels = selected
          .map((index) => baseLabels[index])
          .toList();
      scoreSum += _bestLabelAgreement(
        referenceLabels,
        fit.labels,
        jittered.map((position) => position.multiplicity).toList(),
        k,
      );
    }
    return scoreSum / _stabilityTrials;
  }

  static double _bestLabelAgreement(
    List<int> expected,
    List<int> actual,
    List<int> weights,
    int k,
  ) {
    final permutations = _permutations(List<int>.generate(k, (index) => index));
    var best = 0.0;
    final totalWeight = weights.fold<int>(0, (sum, weight) => sum + weight);
    for (final permutation in permutations) {
      var matchingWeight = 0;
      for (var index = 0; index < expected.length; index++) {
        if (permutation[actual[index]] == expected[index]) {
          matchingWeight += weights[index];
        }
      }
      best = math.max(best, matchingWeight / totalWeight);
    }
    return best;
  }

  static List<List<int>> _permutations(List<int> source) {
    if (source.length <= 1) return [source];
    final result = <List<int>>[];
    for (var index = 0; index < source.length; index++) {
      final head = source[index];
      final tail = [...source]..removeAt(index);
      for (final permutation in _permutations(tail)) {
        result.add([head, ...permutation]);
      }
    }
    return result;
  }

  static bool _sameLabels(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  static double _maximumDistance(List<AnalyzedImpactPosition> positions) {
    var result = 0.0;
    for (var first = 0; first < positions.length; first++) {
      for (var second = first + 1; second < positions.length; second++) {
        result = math.max(
          result,
          _distance(positions[first], positions[second]),
        );
      }
    }
    return result;
  }

  static double _distance(
    AnalyzedImpactPosition first,
    AnalyzedImpactPosition second,
  ) => math.sqrt(_squaredDistance(first, second));

  static double _squaredDistance(
    AnalyzedImpactPosition first,
    AnalyzedImpactPosition second,
  ) {
    final dx = first.xMm - second.xMm;
    final dy = first.yMm - second.yMm;
    return dx * dx + dy * dy;
  }

  static double _squaredDistanceToCentroid(
    AnalyzedImpactPosition position,
    _Centroid centroid,
  ) {
    final dx = position.xMm - centroid.x;
    final dy = position.yMm - centroid.y;
    return dx * dx + dy * dy;
  }

  static double _centroidDistance(_Centroid first, _Centroid second) {
    final dx = first.x - second.x;
    final dy = first.y - second.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}

class _SubgroupCandidate {
  const _SubgroupCandidate({
    required this.fit,
    required this.silhouette,
    required this.stability,
  });

  final _KMeansFit fit;
  final double silhouette;
  final double stability;
}

class _KMeansFit {
  const _KMeansFit({
    required this.labels,
    required this.centroids,
    required this.clusterWeights,
  });

  final List<int> labels;
  final List<_Centroid> centroids;
  final List<int> clusterWeights;
}

class _Centroid {
  const _Centroid(this.x, this.y);

  final double x;
  final double y;
}

class _DeterministicRandom {
  _DeterministicRandom(int seed) : _state = seed & 0x7fffffff;

  int _state;

  int _next() {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state;
  }

  int nextInt(int maximum) => _next() % maximum;

  double nextDouble() => _next() / 0x7fffffff;
}
