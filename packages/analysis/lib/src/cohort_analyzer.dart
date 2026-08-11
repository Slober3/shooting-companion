import 'dart:math' as math;

import 'package:shooting_companion_domain/domain.dart';

import 'group_analyzer.dart';
import 'models.dart';

class ComparableCohortKey {
  const ComparableCohortKey({
    required this.targetProfileVersionedId,
    required this.distanceMeters,
    required this.projectileDiameterMm,
    this.cartridgeId,
    this.firearmId,
    this.ammoLotId,
  });

  final String targetProfileVersionedId;
  final double distanceMeters;
  final double projectileDiameterMm;
  final String? cartridgeId;
  final String? firearmId;
  final String? ammoLotId;

  @override
  bool operator ==(Object other) =>
      other is ComparableCohortKey &&
      other.targetProfileVersionedId == targetProfileVersionedId &&
      _quantize(other.distanceMeters) == _quantize(distanceMeters) &&
      _quantize(other.projectileDiameterMm) ==
          _quantize(projectileDiameterMm) &&
      other.cartridgeId == cartridgeId &&
      other.firearmId == firearmId &&
      other.ammoLotId == ammoLotId;

  @override
  int get hashCode => Object.hash(
    targetProfileVersionedId,
    _quantize(distanceMeters),
    _quantize(projectileDiameterMm),
    cartridgeId,
    firearmId,
    ammoLotId,
  );
}

class CohortSeriesInput {
  CohortSeriesInput({
    required this.seriesId,
    required this.occurredAtUtc,
    required this.sequenceNumber,
    required this.updatedAtUtc,
    required this.targetProfileVersionedId,
    required this.targetProfile,
    required this.distanceMeters,
    required this.projectileDiameterMm,
    required this.scorePercentage,
    required Iterable<ShotImpact> impacts,
    this.cartridgeId,
    this.firearmId,
    this.ammoLotId,
  }) : impacts = List.unmodifiable(impacts);

  final String seriesId;
  final DateTime occurredAtUtc;
  final int sequenceNumber;
  final DateTime updatedAtUtc;
  final String targetProfileVersionedId;
  final TargetProfile targetProfile;
  final double distanceMeters;
  final double projectileDiameterMm;
  final String? cartridgeId;
  final String? firearmId;
  final String? ammoLotId;
  final double scorePercentage;
  final List<ShotImpact> impacts;

  ComparableCohortKey key({bool includeAmmoLot = true}) => ComparableCohortKey(
    targetProfileVersionedId: targetProfileVersionedId,
    distanceMeters: distanceMeters,
    projectileDiameterMm: projectileDiameterMm,
    cartridgeId: cartridgeId,
    firearmId: firearmId,
    ammoLotId: includeAmmoLot ? ammoLotId : null,
  );
}

class CohortScoreTrend {
  CohortScoreTrend({
    required Iterable<double> percentages,
    required this.linearSlopePercentagePointsPerSeries,
  }) : percentages = List.unmodifiable(percentages);

  final List<double> percentages;
  final double linearSlopePercentagePointsPerSeries;

  List<double> movingAverage(int window) {
    if (window <= 0) throw ArgumentError.value(window, 'window');
    return List<double>.generate(percentages.length, (index) {
      final start = math.max(0, index - window + 1);
      final values = percentages.sublist(start, index + 1);
      return values.reduce((a, b) => a + b) / values.length;
    }, growable: false);
  }
}

class CohortConsistency {
  const CohortConsistency({
    required this.scoreStandardDeviation,
    required this.meanRadiusStandardDeviationMm,
    required this.meanRadiusCoefficientOfVariation,
  });

  final double scoreStandardDeviation;
  final double meanRadiusStandardDeviationMm;
  final double meanRadiusCoefficientOfVariation;
}

class CohortAnalysis {
  CohortAnalysis({
    required this.cohort,
    required Iterable<SeriesAnalysis> seriesAnalyses,
    required this.pooledMetrics,
    required this.scoreTrend,
    required this.consistency,
    required Iterable<String> comparisonWarnings,
  }) : seriesAnalyses = List.unmodifiable(seriesAnalyses),
       comparisonWarnings = List.unmodifiable(comparisonWarnings);

  final ComparableCohortKey cohort;
  final List<SeriesAnalysis> seriesAnalyses;
  final GroupMetrics pooledMetrics;
  final CohortScoreTrend scoreTrend;
  final CohortConsistency consistency;
  final List<String> comparisonWarnings;
}

abstract final class CohortAnalyzer {
  static Map<ComparableCohortKey, CohortAnalysis> analyzeAll(
    Iterable<CohortSeriesInput> source, {
    bool includeAmmoLot = true,
    bool includeUncertainPositions = true,
  }) {
    final grouped = <ComparableCohortKey, List<CohortSeriesInput>>{};
    for (final item in source) {
      grouped
          .putIfAbsent(item.key(includeAmmoLot: includeAmmoLot), () => [])
          .add(item);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: analyze(
          entry.value,
          cohort: entry.key,
          includeAmmoLot: includeAmmoLot,
          includeUncertainPositions: includeUncertainPositions,
        ),
    };
  }

  static CohortAnalysis analyze(
    Iterable<CohortSeriesInput> source, {
    ComparableCohortKey? cohort,
    bool includeAmmoLot = true,
    bool includeUncertainPositions = true,
  }) {
    final items = source.toList()
      ..sort((a, b) {
        final time = a.occurredAtUtc.compareTo(b.occurredAtUtc);
        if (time != 0) return time;
        final sequence = a.sequenceNumber.compareTo(b.sequenceNumber);
        return sequence != 0 ? sequence : a.seriesId.compareTo(b.seriesId);
      });
    if (items.isEmpty) {
      throw ArgumentError.value(source, 'source', 'Cohort mag niet leeg zijn.');
    }
    final key = cohort ?? items.first.key(includeAmmoLot: includeAmmoLot);
    for (final item in items) {
      if (item.targetProfileVersionedId != key.targetProfileVersionedId ||
          _quantize(item.distanceMeters) != _quantize(key.distanceMeters) ||
          _quantize(item.projectileDiameterMm) !=
              _quantize(key.projectileDiameterMm) ||
          item.cartridgeId != key.cartridgeId ||
          item.firearmId != key.firearmId ||
          (includeAmmoLot && item.ammoLotId != key.ammoLotId)) {
        throw ArgumentError(
          'Alle reeksen moeten tot exact hetzelfde vergelijkbare cohort behoren.',
        );
      }
    }

    final analyses = <SeriesAnalysis>[];
    final pooledImpacts = <ShotImpact>[];
    for (final item in items) {
      analyses.add(
        GroupAnalyzer.analyze(
          seriesId: item.seriesId,
          impacts: item.impacts,
          targetProfile: item.targetProfile,
          distanceMeters: item.distanceMeters,
          includeUncertainPositions: includeUncertainPositions,
        ),
      );
      for (var index = 0; index < item.impacts.length; index++) {
        final impact = item.impacts[index];
        pooledImpacts.add(
          ShotImpact(
            id: '${item.seriesId}:${impact.id}:$index',
            xMm: impact.xMm,
            yMm: impact.yMm,
            multiplicity: impact.multiplicity,
            isMiss: impact.isMiss,
            isPositionUncertain: impact.isPositionUncertain,
            targetBullId: impact.targetBullId,
            rawScoreValue: impact.rawScoreValue,
            scoreDisposition: impact.scoreDisposition,
          ),
        );
      }
    }
    final pooled = GroupAnalyzer.calculate(
      pooledImpacts,
      targetProfile: items.first.targetProfile,
      distanceMeters: key.distanceMeters,
      includeUncertainPositions: includeUncertainPositions,
    );
    final scores = items.map((item) => item.scorePercentage).toList();
    final radii = analyses
        .map((item) => item.metrics.meanRadiusMm)
        .toList(growable: false);
    final scoreSd = _sampleStandardDeviation(scores);
    final radiusSd = _sampleStandardDeviation(radii);
    final meanRadius = radii.reduce((a, b) => a + b) / radii.length;
    final warnings = <String>[];
    if (items.length < 3) {
      warnings.add('Minder dan drie vergelijkbare reeksen.');
    }
    if (pooled.positionedShotCount < 30) {
      warnings.add('Minder dan dertig positionele treffers.');
    }
    if (analyses.any(
      (item) => item.warnings.any(
        (warning) =>
            warning.code == AnalysisWarningCode.multiplicityApproximation,
      ),
    )) {
      warnings.add('Multipliciteit maakt de spreidingsmeting benaderend.');
    }
    return CohortAnalysis(
      cohort: key,
      seriesAnalyses: analyses,
      pooledMetrics: pooled,
      scoreTrend: CohortScoreTrend(
        percentages: scores,
        linearSlopePercentagePointsPerSeries: _linearSlope(scores),
      ),
      consistency: CohortConsistency(
        scoreStandardDeviation: scoreSd,
        meanRadiusStandardDeviationMm: radiusSd,
        meanRadiusCoefficientOfVariation: meanRadius == 0
            ? 0
            : radiusSd / meanRadius,
      ),
      comparisonWarnings: warnings,
    );
  }

  static double _sampleStandardDeviation(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        (values.length - 1);
    return math.sqrt(variance);
  }

  static double _linearSlope(List<double> values) {
    if (values.length < 2) return 0;
    final meanX = (values.length - 1) / 2;
    final meanY = values.reduce((a, b) => a + b) / values.length;
    var numerator = 0.0;
    var denominator = 0.0;
    for (var index = 0; index < values.length; index++) {
      numerator += (index - meanX) * (values[index] - meanY);
      denominator += math.pow(index - meanX, 2).toDouble();
    }
    return denominator == 0 ? 0 : numerator / denominator;
  }
}

int _quantize(double value) => (value * 1000000).round();
