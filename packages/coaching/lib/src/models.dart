enum CoachEvidenceStrength { moderate, strong }

enum CoachFeedbackResponse { useful, notUseful, later, dismiss }

enum CoachPerceivedQuality { good, neutral, difficult }

enum CoachMaterialKind { firearm, ammoLot }

class CoachCohortReference {
  const CoachCohortReference({
    required this.targetProfileVersionedId,
    required this.distanceMeters,
    this.firearmId,
    this.ammoLotId,
  }) : assert(distanceMeters > 0);

  final String targetProfileVersionedId;
  final double distanceMeters;
  final String? firearmId;
  final String? ammoLotId;

  String get canonicalKey => [
    targetProfileVersionedId,
    distanceMeters.toStringAsFixed(6),
    firearmId ?? '-',
    ammoLotId ?? '-',
  ].join('|');
}

/// Target-aware limits supplied by the analysis layer.
///
/// Absolute group sizes are deliberately not hard-coded in the coaching
/// package: a meaningful offset on a BR50 bull is not the same as on a pistol
/// target. Trend limits are dimensionless fractions.
class CoachThresholds {
  const CoachThresholds({
    required this.biasToleranceMm,
    required this.compactMeanRadiusMm,
    required this.wideMeanRadiusMm,
    this.trendChangeFraction = 0.08,
    this.plateauBandFraction = 0.03,
    this.variabilityCoefficient = 0.25,
    this.materialDifferenceFraction = 0.10,
    this.br50AreaGapPoints = 0.5,
    this.firstSeriesDifferenceFraction = 0.10,
    this.reflectionDifferenceFraction = 0.10,
  }) : assert(biasToleranceMm > 0),
       assert(compactMeanRadiusMm >= 0),
       assert(wideMeanRadiusMm > compactMeanRadiusMm),
       assert(trendChangeFraction > plateauBandFraction),
       assert(plateauBandFraction >= 0),
       assert(variabilityCoefficient > 0),
       assert(materialDifferenceFraction > 0),
       assert(br50AreaGapPoints > 0),
       assert(firstSeriesDifferenceFraction > 0),
       assert(reflectionDifferenceFraction > 0);

  final double biasToleranceMm;
  final double compactMeanRadiusMm;
  final double wideMeanRadiusMm;
  final double trendChangeFraction;
  final double plateauBandFraction;
  final double variabilityCoefficient;
  final double materialDifferenceFraction;
  final double br50AreaGapPoints;
  final double firstSeriesDifferenceFraction;
  final double reflectionDifferenceFraction;
}

class CoachAreaObservation {
  const CoachAreaObservation({
    required this.areaId,
    required this.label,
    required this.scoredBullCount,
    required this.averageScore,
  }) : assert(scoredBullCount > 0),
       assert(averageScore >= 0);

  final String areaId;
  final String label;
  final int scoredBullCount;
  final double averageScore;
}

class CoachSeriesObservation {
  CoachSeriesObservation({
    required this.seriesId,
    required this.sessionId,
    required this.sequenceNumber,
    required this.occurredAtUtc,
    required this.positionedHitCount,
    required this.centroidXMm,
    required this.centroidYMm,
    required this.meanRadiusMm,
    this.scorePercentage,
    this.firearmId,
    this.ammoLotId,
    this.perceivedQuality,
    this.hasApproximatePositions = false,
    List<CoachAreaObservation> br50Areas = const [],
  }) : assert(sequenceNumber > 0),
       assert(positionedHitCount >= 0),
       assert(meanRadiusMm >= 0),
       assert(
         scorePercentage == null ||
             (scorePercentage >= 0 && scorePercentage <= 100),
       ),
       br50Areas = List.unmodifiable(br50Areas);

  final String seriesId;
  final String sessionId;
  final int sequenceNumber;
  final DateTime occurredAtUtc;
  final int positionedHitCount;
  final double centroidXMm;
  final double centroidYMm;
  final double meanRadiusMm;
  final double? scorePercentage;
  final String? firearmId;
  final String? ammoLotId;
  final CoachPerceivedQuality? perceivedQuality;
  final bool hasApproximatePositions;
  final List<CoachAreaObservation> br50Areas;

  String get fingerprintKey {
    final areas =
        br50Areas
            .map(
              (area) => [
                area.areaId,
                area.label,
                area.scoredBullCount,
                area.averageScore.toStringAsFixed(6),
              ].join(':'),
            )
            .toList()
          ..sort();
    return [
      seriesId,
      sessionId,
      sequenceNumber,
      occurredAtUtc.toUtc().microsecondsSinceEpoch,
      positionedHitCount,
      centroidXMm.toStringAsFixed(6),
      centroidYMm.toStringAsFixed(6),
      meanRadiusMm.toStringAsFixed(6),
      scorePercentage?.toStringAsFixed(6) ?? '-',
      firearmId ?? '-',
      ammoLotId ?? '-',
      perceivedQuality?.name ?? '-',
      hasApproximatePositions,
      areas.join(','),
    ].join('|');
  }
}

class CoachMaterialLabel {
  const CoachMaterialLabel({
    required this.kind,
    required this.id,
    required this.displayName,
  });

  final CoachMaterialKind kind;
  final String id;
  final String displayName;
}

class CoachAnalysisSnapshot {
  CoachAnalysisSnapshot({
    required this.cohort,
    required this.thresholds,
    required List<CoachSeriesObservation> series,
    List<CoachMaterialLabel> materialLabels = const [],
  }) : series = List.unmodifiable(series),
       materialLabels = List.unmodifiable(materialLabels) {
    final uniqueSeriesIds = this.series.map((item) => item.seriesId).toSet();
    if (uniqueSeriesIds.length != this.series.length) {
      throw ArgumentError.value(
        series,
        'series',
        'Elke reeks mag maar één keer in een coachanalyse voorkomen.',
      );
    }
  }

  final CoachCohortReference cohort;
  final CoachThresholds thresholds;
  final List<CoachSeriesObservation> series;
  final List<CoachMaterialLabel> materialLabels;
}

class CoachEvidence {
  CoachEvidence({
    required this.summary,
    required this.seriesCount,
    required this.positionedHitCount,
    Map<String, double> metrics = const {},
  }) : metrics = Map.unmodifiable(metrics);

  final String summary;
  final int seriesCount;
  final int positionedHitCount;
  final Map<String, double> metrics;
}

class CoachExplanation {
  const CoachExplanation({required this.title, required this.detail});

  final String title;
  final String detail;
}

class CoachExperiment {
  const CoachExperiment({
    required this.title,
    required this.instructions,
    required this.controlledVariable,
  });

  final String title;
  final String instructions;
  final String controlledVariable;
}

class CoachNextMeasurement {
  const CoachNextMeasurement({required this.label, required this.instructions});

  final String label;
  final String instructions;
}

class CoachInsight {
  CoachInsight({
    required this.fingerprint,
    required this.ruleId,
    required this.ruleVersion,
    required this.observation,
    required this.evidence,
    required this.evidenceStrength,
    required List<CoachExplanation> possibleExplanations,
    required this.proposedExperiment,
    required this.nextMeasurement,
    required this.cohortReference,
    List<String> warnings = const [],
  }) : possibleExplanations = List.unmodifiable(possibleExplanations),
       warnings = List.unmodifiable(warnings);

  final String fingerprint;
  final String ruleId;
  final int ruleVersion;
  final String observation;
  final CoachEvidence evidence;
  final CoachEvidenceStrength evidenceStrength;
  final List<CoachExplanation> possibleExplanations;
  final CoachExperiment proposedExperiment;
  final CoachNextMeasurement nextMeasurement;
  final CoachCohortReference cohortReference;
  final List<String> warnings;
}

class CoachFeedback {
  const CoachFeedback({
    required this.insightFingerprint,
    required this.response,
    required this.updatedAtUtc,
    this.snoozedUntilUtc,
  });

  final String insightFingerprint;
  final CoachFeedbackResponse response;
  final DateTime updatedAtUtc;
  final DateTime? snoozedUntilUtc;
}
