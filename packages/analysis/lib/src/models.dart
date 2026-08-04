/// How much confidence a caller may place in descriptive group metrics.
///
/// Reliability is based on the number of positioned shots used in the
/// calculation. It does not turn observations into causal coaching advice.
enum AnalysisReliability {
  noPositionData,
  positionsOnly,
  provisional,
  smallSample,
  full,
}

/// Machine-readable reasons why an analysis needs qualification.
enum AnalysisWarningCode {
  noPositionData,
  positionsOnly,
  provisionalSample,
  smallSample,
  multiplicityApproximation,
  uncertainPositionsIncluded,
  uncertainPositionsExcluded,
  missingTargetBull,
  unknownTargetBull,
  sighterBullExcluded,
  nonFinitePosition,
  invalidDistance,
}

/// A warning and the number of logical shots to which it applies.
class AnalysisWarning {
  const AnalysisWarning({required this.code, required this.affectedShotCount});

  final AnalysisWarningCode code;
  final int affectedShotCount;
}

/// A one-standard-deviation ellipse derived from the sample covariance.
class CovarianceEllipse {
  const CovarianceEllipse({
    required this.semiMajorAxisMm,
    required this.semiMinorAxisMm,
    required this.angleDegrees,
  });

  /// Square root of the largest covariance eigenvalue.
  final double semiMajorAxisMm;

  /// Square root of the smallest covariance eigenvalue.
  final double semiMinorAxisMm;

  /// Counter-clockwise angle of the major axis, normalized to [-90, 90).
  final double angleDegrees;
}

/// An impact position in the coordinate system used by group analysis.
///
/// For a regular target these coordinates equal the stored target coordinates.
/// For a multi-bull target they are relative to the referenced record bull.
class AnalyzedImpactPosition {
  const AnalyzedImpactPosition({
    required this.impactId,
    required this.xMm,
    required this.yMm,
    required this.multiplicity,
    required this.isPositionUncertain,
    this.targetBullId,
  });

  final String impactId;
  final double xMm;
  final double yMm;
  final int multiplicity;
  final bool isPositionUncertain;
  final String? targetBullId;
}

/// Deterministic descriptive measurements for one set of impacts.
class GroupMetrics {
  const GroupMetrics({
    required this.actualShotCount,
    required this.positionedShotCount,
    required this.centroidXMm,
    required this.centroidYMm,
    required this.extremeSpreadMm,
    required this.meanRadiusMm,
    required this.sampleStandardDeviationXMm,
    required this.sampleStandardDeviationYMm,
    required this.empiricalR50Mm,
    required this.empiricalR90Mm,
    required this.covarianceEllipse,
    required this.extremeSpreadMoa,
    required this.extremeSpreadMilliradians,
  });

  final int actualShotCount;
  final int positionedShotCount;
  final double centroidXMm;
  final double centroidYMm;

  /// Horizontal displacement of the group centre from the aiming point.
  double get horizontalBiasMm => centroidXMm;

  /// Vertical displacement of the group centre from the aiming point.
  double get verticalBiasMm => centroidYMm;

  final double extremeSpreadMm;
  final double meanRadiusMm;
  final double sampleStandardDeviationXMm;
  final double sampleStandardDeviationYMm;
  final double empiricalR50Mm;
  final double empiricalR90Mm;
  final CovarianceEllipse covarianceEllipse;
  final double? extremeSpreadMoa;
  final double? extremeSpreadMilliradians;
}

/// One stable candidate subgroup within a group of positioned shots.
class SubgroupCluster {
  SubgroupCluster({
    required this.index,
    required this.centroidXMm,
    required this.centroidYMm,
    required this.logicalShotCount,
    required Iterable<String> impactIds,
  }) : impactIds = List.unmodifiable(impactIds);

  final int index;
  final double centroidXMm;
  final double centroidYMm;
  final int logicalShotCount;
  final List<String> impactIds;
}

/// A deterministic, non-authoritative suggestion that multiple groups exist.
class SubgroupSuggestion {
  SubgroupSuggestion({
    required this.clusterCount,
    required this.silhouetteScore,
    required this.stability,
    required Iterable<SubgroupCluster> clusters,
  }) : clusters = List.unmodifiable(clusters);

  final int clusterCount;
  final double silhouetteScore;
  final double stability;
  final List<SubgroupCluster> clusters;
}

/// Complete analysis result for one shooting series.
class SeriesAnalysis {
  SeriesAnalysis({
    required this.seriesId,
    required this.metrics,
    required this.reliability,
    required Iterable<AnalysisWarning> warnings,
    required Iterable<AnalyzedImpactPosition> positions,
    this.subgroupSuggestion,
  }) : warnings = List.unmodifiable(warnings),
       positions = List.unmodifiable(positions);

  final String seriesId;
  final GroupMetrics metrics;
  final AnalysisReliability reliability;
  final List<AnalysisWarning> warnings;
  final List<AnalyzedImpactPosition> positions;
  final SubgroupSuggestion? subgroupSuggestion;

  int get actualShotCount => metrics.actualShotCount;
  int get positionedShotCount => metrics.positionedShotCount;
}
