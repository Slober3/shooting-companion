import 'dart:math' as math;

import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_scoring/scoring.dart';

class PotentialScoreSearchConfig {
  const PotentialScoreSearchConfig({
    this.coarseStepMm = 5,
    this.refinementLevels = 4,
    this.refinementFactor = 5,
    this.maximumTranslationMm,
  }) : assert(coarseStepMm > 0),
       assert(refinementLevels >= 1),
       assert(refinementFactor > 1),
       assert(maximumTranslationMm == null || maximumTranslationMm > 0);

  final double coarseStepMm;
  final int refinementLevels;
  final double refinementFactor;

  /// Maximum absolute translation on either axis. When omitted, half of the
  /// target's largest physical card dimension is searched.
  final double? maximumTranslationMm;
}

class PotentialScoreResult {
  const PotentialScoreResult({
    required this.currentScore,
    required this.bestScore,
    required this.maximumPossible,
    required this.translationXMm,
    required this.translationYMm,
  });

  final int currentScore;
  final int bestScore;
  final int maximumPossible;
  final double translationXMm;
  final double translationYMm;

  double get translationDistanceMm => math.sqrt(
    translationXMm * translationXMm + translationYMm * translationYMm,
  );

  /// Portion of the original score gap recoverable by translating the intact
  /// group without changing its shape.
  int get groupCenteringGain => bestScore - currentScore;

  /// Score gap that remains after the best tested translation.
  int get remainingGap => maximumPossible - bestScore;

  int get currentGap => maximumPossible - currentScore;
}

/// Deterministic what-if scoring for a rigidly translated impact pattern.
abstract final class PotentialScoreAnalyzer {
  static PotentialScoreResult analyze({
    required TargetProfile target,
    required Iterable<ShotImpact> impacts,
    required double projectileDiameterMm,
    double positionUncertaintyMm = 0.75,
    PotentialScoreSearchConfig config = const PotentialScoreSearchConfig(),
  }) {
    if (!config.coarseStepMm.isFinite || config.coarseStepMm <= 0) {
      throw ArgumentError.value(config.coarseStepMm, 'config.coarseStepMm');
    }
    if (config.refinementLevels < 1 ||
        !config.refinementFactor.isFinite ||
        config.refinementFactor <= 1) {
      throw ArgumentError('Ongeldige verfijningsconfiguratie.');
    }
    final configuredMaximum = config.maximumTranslationMm;
    if (configuredMaximum != null &&
        (!configuredMaximum.isFinite || configuredMaximum <= 0)) {
      throw ArgumentError.value(
        configuredMaximum,
        'config.maximumTranslationMm',
      );
    }

    final source = impacts.toList(growable: false);
    final current = ScoreEngine.score(
      target: target,
      impacts: source,
      projectileDiameterMm: projectileDiameterMm,
      positionUncertaintyMm: positionUncertaintyMm,
    );
    var best = _TranslationCandidate(dxMm: 0, dyMm: 0, score: current.total);
    if (source.every((impact) => impact.isMiss)) {
      return _result(current, best);
    }

    final maximumTranslation =
        configuredMaximum ??
        math.max(target.physicalCardWidthMm, target.physicalCardHeightMm) / 2;
    final coarseSteps = (maximumTranslation / config.coarseStepMm).ceil();
    for (var xIndex = -coarseSteps; xIndex <= coarseSteps; xIndex++) {
      final dx = xIndex * config.coarseStepMm;
      if (dx.abs() > maximumTranslation + 1e-9) continue;
      for (var yIndex = -coarseSteps; yIndex <= coarseSteps; yIndex++) {
        final dy = yIndex * config.coarseStepMm;
        if (dy.abs() > maximumTranslation + 1e-9) continue;
        best = _evaluate(
          target: target,
          source: source,
          projectileDiameterMm: projectileDiameterMm,
          positionUncertaintyMm: positionUncertaintyMm,
          dxMm: dx,
          dyMm: dy,
          currentBest: best,
        );
      }
    }

    var previousStep = config.coarseStepMm;
    for (var level = 1; level < config.refinementLevels; level++) {
      final step = previousStep / config.refinementFactor;
      final radiusInSteps = config.refinementFactor.ceil();
      final center = best;
      for (var xIndex = -radiusInSteps; xIndex <= radiusInSteps; xIndex++) {
        final dx = center.dxMm + xIndex * step;
        if (dx.abs() > maximumTranslation + 1e-9) continue;
        for (var yIndex = -radiusInSteps; yIndex <= radiusInSteps; yIndex++) {
          final dy = center.dyMm + yIndex * step;
          if (dy.abs() > maximumTranslation + 1e-9) continue;
          best = _evaluate(
            target: target,
            source: source,
            projectileDiameterMm: projectileDiameterMm,
            positionUncertaintyMm: positionUncertaintyMm,
            dxMm: dx,
            dyMm: dy,
            currentBest: best,
          );
        }
      }
      previousStep = step;
    }

    return _result(current, best);
  }

  static _TranslationCandidate _evaluate({
    required TargetProfile target,
    required List<ShotImpact> source,
    required double projectileDiameterMm,
    required double positionUncertaintyMm,
    required double dxMm,
    required double dyMm,
    required _TranslationCandidate currentBest,
  }) {
    if ((dxMm - currentBest.dxMm).abs() <= 1e-12 &&
        (dyMm - currentBest.dyMm).abs() <= 1e-12) {
      return currentBest;
    }
    final shifted = [
      for (final impact in source)
        if (impact.isMiss)
          impact
        else
          impact.copyWith(xMm: impact.xMm + dxMm, yMm: impact.yMm + dyMm),
    ];
    final score = ScoreEngine.score(
      target: target,
      impacts: shifted,
      projectileDiameterMm: projectileDiameterMm,
      positionUncertaintyMm: positionUncertaintyMm,
    ).total;
    final candidate = _TranslationCandidate(
      dxMm: _normalizedZero(dxMm),
      dyMm: _normalizedZero(dyMm),
      score: score,
    );
    return _isBetter(candidate, currentBest) ? candidate : currentBest;
  }

  static bool _isBetter(
    _TranslationCandidate candidate,
    _TranslationCandidate current,
  ) {
    if (candidate.score != current.score) {
      return candidate.score > current.score;
    }
    final candidateDistanceSquared =
        candidate.dxMm * candidate.dxMm + candidate.dyMm * candidate.dyMm;
    final currentDistanceSquared =
        current.dxMm * current.dxMm + current.dyMm * current.dyMm;
    if ((candidateDistanceSquared - currentDistanceSquared).abs() > 1e-9) {
      return candidateDistanceSquared < currentDistanceSquared;
    }
    if ((candidate.dxMm - current.dxMm).abs() > 1e-9) {
      return candidate.dxMm < current.dxMm;
    }
    return candidate.dyMm < current.dyMm - 1e-9;
  }

  static PotentialScoreResult _result(
    ScoreResult current,
    _TranslationCandidate best,
  ) => PotentialScoreResult(
    currentScore: current.total,
    bestScore: best.score,
    maximumPossible: current.maximumPossible,
    translationXMm: best.dxMm,
    translationYMm: best.dyMm,
  );

  static double _normalizedZero(double value) =>
      value.abs() <= 1e-12 ? 0 : value;
}

class _TranslationCandidate {
  const _TranslationCandidate({
    required this.dxMm,
    required this.dyMm,
    required this.score,
  });

  final double dxMm;
  final double dyMm;
  final int score;
}
