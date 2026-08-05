import 'dart:convert';
import 'dart:math' as math;

import 'package:shooting_companion_analysis/analysis.dart';
import 'package:shooting_companion_coaching/coaching.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;

import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';

class AnalyzedSeriesView {
  const AnalyzedSeriesView({
    required this.source,
    required this.target,
    required this.impacts,
    required this.analysis,
  });

  final AnalysisSeriesData source;
  final domain.TargetProfile target;
  final List<domain.ShotImpact> impacts;
  final SeriesAnalysis analysis;

  double get scorePercentage => source.series.maximumPossibleScore <= 0
      ? 0
      : source.series.totalScore / source.series.maximumPossibleScore * 100;
}

List<AnalyzedSeriesView> analyzeSeriesDataset(
  Iterable<AnalysisSeriesData> source, {
  bool includeUncertainPositions = true,
}) => source
    .map((item) {
      final target = domain.TargetProfile.fromJsonString(
        item.series.targetProfileJson,
      );
      final impacts = item.impacts
          .map(impactRecordToDomain)
          .toList(growable: false);
      return AnalyzedSeriesView(
        source: item,
        target: target,
        impacts: impacts,
        analysis: GroupAnalyzer.analyze(
          seriesId: item.series.id,
          impacts: impacts,
          targetProfile: target,
          distanceMeters: item.series.distanceMeters,
          includeUncertainPositions: includeUncertainPositions,
        ),
      );
    })
    .toList(growable: false);

domain.ShotImpact impactRecordToDomain(ImpactRecord record) =>
    domain.ShotImpact(
      id: record.id,
      xMm: record.xMm,
      yMm: record.yMm,
      sourceImageId: record.sourceImageId,
      imageXNormalized: record.imageXNormalized,
      imageYNormalized: record.imageYNormalized,
      multiplicity: record.multiplicity,
      isMiss: record.isMiss,
      isPositionUncertain: record.isPositionUncertain,
      targetBullId: record.targetBullId,
      rawScoreValue: record.rawScoreValue,
      scoreDisposition: domain.ScoreDisposition.values.firstWhere(
        (value) => value.name == record.scoreDisposition,
        orElse: () => domain.ScoreDisposition.counted,
      ),
    );

List<CoachInsight> buildCoachInsights(Iterable<AnalyzedSeriesView> source) {
  final groups = <_CoachCohortKey, List<AnalyzedSeriesView>>{};
  for (final item in source) {
    final series = item.source.series;
    groups
        .putIfAbsent(
          _CoachCohortKey(
            targetId: series.targetProfileVersionedId,
            distanceMeters: series.distanceMeters,
            projectileDiameterMm: series.projectileDiameterMm,
            cartridgeId: series.cartridgeId,
            firearmId: series.firearmId,
          ),
          () => [],
        )
        .add(item);
  }
  final result = <CoachInsight>[];
  for (final entry in groups.entries) {
    final items = entry.value;
    final target = items.first.target;
    final observations = items.map(_coachObservation).toList(growable: false);
    final labels = <CoachMaterialLabel>[
      for (final item in items)
        if (item.source.firearm case final firearm?)
          CoachMaterialLabel(
            kind: CoachMaterialKind.firearm,
            id: firearm.id,
            displayName: firearm.name,
          ),
      for (final item in items)
        if (item.source.ammoLot case final ammo?)
          CoachMaterialLabel(
            kind: CoachMaterialKind.ammoLot,
            id: ammo.id,
            displayName: ammo.displayName,
          ),
    ];
    final outerDiameter = target.rings
        .map((ring) => ring.outerDiameterMm)
        .reduce(math.max);
    final localRadius =
        target.targetKind == domain.TargetKind.multiBullConcentric
        ? outerDiameter / 2
        : math.min(
            outerDiameter / 2,
            math.min(target.physicalCardWidthMm, target.physicalCardHeightMm) /
                2,
          );
    result.addAll(
      const CoachRuleEngine().evaluate(
        CoachAnalysisSnapshot(
          cohort: CoachCohortReference(
            targetProfileVersionedId: entry.key.targetId,
            distanceMeters: entry.key.distanceMeters,
            firearmId: entry.key.firearmId,
          ),
          thresholds: CoachThresholds(
            biasToleranceMm: math.max(1, localRadius * 0.08),
            compactMeanRadiusMm: math.max(0.5, localRadius * 0.10),
            wideMeanRadiusMm: math.max(1.5, localRadius * 0.28),
          ),
          series: observations,
          materialLabels: _uniqueMaterialLabels(labels),
        ),
      ),
    );
  }
  result.sort((a, b) {
    final strength = b.evidenceStrength.index.compareTo(
      a.evidenceStrength.index,
    );
    return strength != 0 ? strength : a.ruleId.compareTo(b.ruleId);
  });
  return result;
}

CohortSeriesInput cohortInputFromAnalyzed(AnalyzedSeriesView item) =>
    CohortSeriesInput(
      seriesId: item.source.series.id,
      occurredAtUtc: item.source.session.startedAtUtc,
      sequenceNumber: item.source.series.sequenceNumber,
      updatedAtUtc: item.source.series.updatedAtUtc,
      targetProfileVersionedId: item.source.series.targetProfileVersionedId,
      targetProfile: item.target,
      distanceMeters: item.source.series.distanceMeters,
      projectileDiameterMm: item.source.series.projectileDiameterMm,
      cartridgeId: item.source.series.cartridgeId,
      firearmId: item.source.series.firearmId,
      ammoLotId: item.source.series.ammoLotId,
      scorePercentage: item.scorePercentage,
      impacts: item.impacts,
    );

CoachSeriesObservation _coachObservation(AnalyzedSeriesView item) {
  final series = item.source.series;
  final metrics = item.analysis.metrics;
  return CoachSeriesObservation(
    seriesId: series.id,
    sessionId: series.sessionId,
    sequenceNumber: series.sequenceNumber,
    occurredAtUtc: item.source.session.startedAtUtc,
    positionedHitCount: metrics.positionedShotCount,
    centroidXMm: metrics.centroidXMm,
    centroidYMm: metrics.centroidYMm,
    meanRadiusMm: metrics.meanRadiusMm,
    scorePercentage: item.scorePercentage,
    firearmId: series.firearmId,
    ammoLotId: series.ammoLotId,
    perceivedQuality: _perceivedQuality(item.source.reflection),
    hasApproximatePositions: item.analysis.warnings.any(
      (warning) =>
          warning.code == AnalysisWarningCode.multiplicityApproximation ||
          warning.code == AnalysisWarningCode.uncertainPositionsIncluded,
    ),
    br50Areas: _br50Areas(item),
  );
}

CoachPerceivedQuality? _perceivedQuality(SeriesReflectionRecord? reflection) {
  if (reflection == null) return null;
  return CoachPerceivedQuality.values
      .where((value) => value.name == reflection.perceivedQuality)
      .firstOrNull;
}

List<CoachAreaObservation> _br50Areas(AnalyzedSeriesView item) {
  final target = item.target;
  if (target.targetKind != domain.TargetKind.multiBullConcentric) {
    return const [];
  }
  final recordBulls = target.recordBulls;
  if (recordBulls.isEmpty) return const [];
  final minY = recordBulls.map((bull) => bull.centerYMm).reduce(math.min);
  final maxY = recordBulls.map((bull) => bull.centerYMm).reduce(math.max);
  final scoresByBull = <String, List<int>>{};
  for (final impact in item.source.impacts) {
    final bullId = impact.targetBullId;
    if (bullId == null ||
        (impact.scoreDisposition != domain.ScoreDisposition.counted.name &&
            impact.scoreDisposition != domain.ScoreDisposition.miss.name)) {
      continue;
    }
    scoresByBull.putIfAbsent(bullId, () => []).add(impact.scoreValue);
  }
  final areas = <String, _AreaScores>{};
  for (final bull in recordBulls) {
    final scores = scoresByBull[bull.id];
    if (scores == null || scores.isEmpty) continue;
    final fraction = maxY == minY
        ? 0.5
        : (bull.centerYMm - minY) / (maxY - minY);
    final (id, label) = fraction < 0.34
        ? ('top', 'boven')
        : fraction < 0.67
        ? ('middle', 'midden')
        : ('bottom', 'onder');
    (areas[id] ??= _AreaScores(label)).scores.add(scores.reduce(math.min));
  }
  return areas.entries
      .map(
        (entry) => CoachAreaObservation(
          areaId: entry.key,
          label: entry.value.label,
          scoredBullCount: entry.value.scores.length,
          averageScore:
              entry.value.scores.reduce((a, b) => a + b) /
              entry.value.scores.length,
        ),
      )
      .toList(growable: false);
}

List<CoachMaterialLabel> _uniqueMaterialLabels(
  Iterable<CoachMaterialLabel> labels,
) {
  final result = <String, CoachMaterialLabel>{};
  for (final label in labels) {
    result['${label.kind.name}|${label.id}'] = label;
  }
  return result.values.toList(growable: false);
}

Set<ReflectionContextTag> decodeReflectionTags(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List) return const {};
  return decoded
      .whereType<String>()
      .map(
        (name) => ReflectionContextTag.values
            .where((value) => value.name == name)
            .firstOrNull,
      )
      .whereType<ReflectionContextTag>()
      .toSet();
}

class _AreaScores {
  _AreaScores(this.label);

  final String label;
  final scores = <int>[];
}

class _CoachCohortKey {
  const _CoachCohortKey({
    required this.targetId,
    required this.distanceMeters,
    required this.projectileDiameterMm,
    required this.cartridgeId,
    required this.firearmId,
  });

  final String targetId;
  final double distanceMeters;
  final double projectileDiameterMm;
  final String? cartridgeId;
  final String? firearmId;

  @override
  bool operator ==(Object other) =>
      other is _CoachCohortKey &&
      other.targetId == targetId &&
      _quantizeCohortValue(other.distanceMeters) ==
          _quantizeCohortValue(distanceMeters) &&
      _quantizeCohortValue(other.projectileDiameterMm) ==
          _quantizeCohortValue(projectileDiameterMm) &&
      other.cartridgeId == cartridgeId &&
      other.firearmId == firearmId;

  @override
  int get hashCode => Object.hash(
    targetId,
    _quantizeCohortValue(distanceMeters),
    _quantizeCohortValue(projectileDiameterMm),
    cartridgeId,
    firearmId,
  );
}

int _quantizeCohortValue(double value) => (value * 1000000).round();
