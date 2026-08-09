import 'dart:math' as math;

import 'package:shooting_companion_domain/domain.dart';

import 'radial_score_evaluator.dart';

class ScoredImpact {
  const ScoredImpact({
    required this.impact,
    required this.value,
    required this.countedValue,
    required this.disposition,
    required this.isInnerTen,
    required this.isBoundaryUncertain,
    required this.radialDistanceMm,
    this.countedMultiplicity = 1,
    this.duplicateMultiplicity = 0,
    this.targetBullId,
  });

  final ShotImpact impact;

  /// Physical ring value before multi-bull duplicate rules are applied.
  final int value;
  final int countedValue;
  final ScoreDisposition disposition;
  final bool isInnerTen;
  final bool isBoundaryUncertain;
  final double radialDistanceMm;
  final int countedMultiplicity;
  final int duplicateMultiplicity;
  final String? targetBullId;

  int get subtotal => countedValue;

  ScoredImpact withCounting({
    required int countedValue,
    required ScoreDisposition disposition,
    required bool isInnerTen,
    int? countedMultiplicity,
    int? duplicateMultiplicity,
  }) => ScoredImpact(
    impact: impact,
    value: value,
    countedValue: countedValue,
    disposition: disposition,
    isInnerTen: isInnerTen,
    isBoundaryUncertain: isBoundaryUncertain,
    radialDistanceMm: radialDistanceMm,
    countedMultiplicity: countedMultiplicity ?? this.countedMultiplicity,
    duplicateMultiplicity: duplicateMultiplicity ?? this.duplicateMultiplicity,
    targetBullId: targetBullId,
  );
}

class ScoreResult {
  const ScoreResult({
    required this.shots,
    required this.actualShotCount,
    required this.countedShotCount,
    required this.scoredBullCount,
    required this.totalBeforePenalty,
    required this.penalty,
    required this.total,
    required this.maximumPossible,
    required this.innerTenCount,
    required this.missCount,
    required this.hasBoundaryWarnings,
    this.duplicateShotCount = 0,
    this.explicitMissShotCount = 0,
    this.zeroValueShotCount = 0,
    this.unscoredBullCount,
  });

  final List<ScoredImpact> shots;
  final int actualShotCount;
  final int countedShotCount;
  final int? scoredBullCount;
  final int totalBeforePenalty;
  final int penalty;
  final int total;
  final int maximumPossible;
  final int innerTenCount;

  /// Legacy score-zero aggregate.
  ///
  /// On a single bull this is the number of zero-valued projectiles. On a
  /// fixed multi-bull target this is the number of record bulls whose final
  /// score is zero, including record bulls without a submitted outcome.
  final int missCount;
  final bool hasBoundaryWarnings;

  /// Projectiles ignored by the target's duplicate-shot policy.
  final int duplicateShotCount;

  /// Projectiles explicitly entered as a miss, independent of duplicate rules.
  final int explicitMissShotCount;

  /// Submitted projectiles whose raw radial value is zero.
  final int zeroValueShotCount;

  /// Fixed record bulls without any submitted outcome; `null` for single bull.
  final int? unscoredBullCount;

  double get percentage =>
      maximumPossible == 0 ? 0 : total / maximumPossible * 100;
}

abstract final class ScoreEngine {
  static ScoreResult score({
    required TargetProfile target,
    required Iterable<ShotImpact> impacts,
    required double projectileDiameterMm,
    double positionUncertaintyMm = 0.75,
  }) {
    target.validateRuntime().requireValid(argumentName: 'target');
    if (!projectileDiameterMm.isFinite || projectileDiameterMm <= 0) {
      throw ArgumentError.value(
        projectileDiameterMm,
        'projectileDiameterMm',
        'Moet eindig en groter zijn dan nul.',
      );
    }
    if (!positionUncertaintyMm.isFinite || positionUncertaintyMm < 0) {
      throw ArgumentError.value(
        positionUncertaintyMm,
        'positionUncertaintyMm',
        'Moet eindig en minstens nul zijn.',
      );
    }
    final impactList = impacts.toList(growable: false);
    final impactIds = <String>{};
    for (var index = 0; index < impactList.length; index++) {
      final impact = impactList[index];
      impact.validateRuntime().requireValid(argumentName: 'impacts[$index]');
      if (!impactIds.add(impact.id)) {
        throw ArgumentError.value(
          impact.id,
          'impacts[$index].id',
          'Impact-ID’s moeten binnen een scoreaanvraag uniek zijn.',
        );
      }
    }
    return switch (target.targetKind) {
      TargetKind.concentricRings => _scoreSingleBull(
        target: target,
        impacts: impactList,
        projectileDiameterMm: projectileDiameterMm,
        positionUncertaintyMm: positionUncertaintyMm,
      ),
      TargetKind.multiBullConcentric => _scoreMultiBull(
        target: target,
        impacts: impactList,
        projectileDiameterMm: projectileDiameterMm,
        positionUncertaintyMm: positionUncertaintyMm,
      ),
    };
  }

  static ScoreResult _scoreSingleBull({
    required TargetProfile target,
    required List<ShotImpact> impacts,
    required double projectileDiameterMm,
    required double positionUncertaintyMm,
  }) {
    final scored = impacts
        .map(
          (impact) => _scoreImpact(
            target: target,
            impact: impact,
            projectileDiameterMm: projectileDiameterMm,
            positionUncertaintyMm: positionUncertaintyMm,
            centerXMm: 0,
            centerYMm: 0,
          ),
        )
        .toList(growable: false);
    final actualShots = scored.fold<int>(
      0,
      (sum, shot) => sum + shot.impact.multiplicity,
    );
    final total = scored.fold(
      0,
      (sum, shot) => sum + shot.value * shot.impact.multiplicity,
    );
    final explicitMissShotCount = scored.fold(
      0,
      (sum, shot) => sum + (shot.impact.isMiss ? shot.impact.multiplicity : 0),
    );
    final zeroValueShotCount = scored.fold(
      0,
      (sum, shot) => sum + (shot.value == 0 ? shot.impact.multiplicity : 0),
    );
    return ScoreResult(
      shots: [
        for (final shot in scored)
          shot.withCounting(
            countedValue: shot.value * shot.impact.multiplicity,
            disposition: shot.impact.isMiss
                ? ScoreDisposition.miss
                : ScoreDisposition.counted,
            isInnerTen: shot.isInnerTen,
            countedMultiplicity: shot.impact.multiplicity,
            duplicateMultiplicity: 0,
          ),
      ],
      actualShotCount: actualShots,
      countedShotCount: actualShots,
      scoredBullCount: null,
      totalBeforePenalty: total,
      penalty: 0,
      total: total,
      maximumPossible: actualShots * target.maximumScore,
      innerTenCount: scored.fold(
        0,
        (sum, shot) => sum + (shot.isInnerTen ? shot.impact.multiplicity : 0),
      ),
      missCount: zeroValueShotCount,
      hasBoundaryWarnings: scored.any((shot) => shot.isBoundaryUncertain),
      duplicateShotCount: 0,
      explicitMissShotCount: explicitMissShotCount,
      zeroValueShotCount: zeroValueShotCount,
      unscoredBullCount: null,
    );
  }

  static ScoreResult _scoreMultiBull({
    required TargetProfile target,
    required List<ShotImpact> impacts,
    required double projectileDiameterMm,
    required double positionUncertaintyMm,
  }) {
    final policy = target.multiBullScoringPolicy!;
    final originalOrder = <String, int>{};
    for (var index = 0; index < impacts.length; index++) {
      originalOrder[impacts[index].id] = index;
    }
    final rawById = <String, ScoredImpact>{};
    final byBull = <String, List<ScoredImpact>>{};
    var actualShotCount = 0;

    for (final impact in impacts) {
      final bull = _resolveRecordBull(target, impact);
      final normalizedImpact = impact.copyWith(targetBullId: bull.id);
      final scored = _scoreImpact(
        target: target,
        impact: normalizedImpact,
        projectileDiameterMm: projectileDiameterMm,
        positionUncertaintyMm: positionUncertaintyMm,
        centerXMm: bull.centerXMm,
        centerYMm: bull.centerYMm,
        targetBullId: bull.id,
      );
      rawById[impact.id] = scored;
      byBull.putIfAbsent(bull.id, () => []).add(scored);
      actualShotCount += impact.multiplicity;
    }

    final countedById = <String, ScoredImpact>{};
    var totalBeforePenalty = 0;
    var innerTenCount = 0;
    var bullsWithPositiveScore = 0;
    for (final entries in byBull.values) {
      var winnerIndex = 0;
      for (var index = 1; index < entries.length; index++) {
        final candidate = entries[index];
        final winner = entries[winnerIndex];
        if (_compareMultiBullResult(candidate, winner, originalOrder) < 0) {
          winnerIndex = index;
        }
      }
      final winner = entries[winnerIndex];
      totalBeforePenalty += winner.value;
      if (winner.isInnerTen) innerTenCount++;
      if (winner.value > 0) bullsWithPositiveScore++;
      countedById[winner.impact.id] = winner.withCounting(
        countedValue: winner.value,
        disposition: winner.value == 0
            ? ScoreDisposition.miss
            : ScoreDisposition.counted,
        isInnerTen: winner.isInnerTen,
        countedMultiplicity: 1,
        duplicateMultiplicity: winner.impact.multiplicity - 1,
      );
      for (var index = 0; index < entries.length; index++) {
        if (index == winnerIndex) continue;
        final duplicate = entries[index];
        countedById[duplicate.impact.id] = duplicate.withCounting(
          countedValue: 0,
          disposition: ScoreDisposition.duplicateNotCounted,
          isInnerTen: false,
          countedMultiplicity: 0,
          duplicateMultiplicity: duplicate.impact.multiplicity,
        );
      }
    }

    final shots = <ScoredImpact>[];
    for (final impact in impacts) {
      shots.add(countedById[impact.id] ?? rawById[impact.id]!);
    }
    final penalty =
        math.max(0, actualShotCount - policy.recordBullCount) *
        policy.excessShotPenalty;
    final duplicateShotCount = actualShotCount - byBull.length;
    final explicitMissShotCount = impacts.fold<int>(
      0,
      (sum, impact) => sum + (impact.isMiss ? impact.multiplicity : 0),
    );
    final zeroValueShotCount = rawById.values.fold<int>(
      0,
      (sum, shot) => sum + (shot.value == 0 ? shot.impact.multiplicity : 0),
    );
    final unscoredBullCount = policy.recordBullCount - byBull.length;

    return ScoreResult(
      shots: shots,
      actualShotCount: actualShotCount,
      countedShotCount: byBull.length,
      scoredBullCount: byBull.length,
      totalBeforePenalty: totalBeforePenalty,
      penalty: penalty,
      total: math.max(0, totalBeforePenalty - penalty),
      maximumPossible: policy.fixedMaximumScore,
      innerTenCount: innerTenCount,
      missCount: policy.recordBullCount - bullsWithPositiveScore,
      hasBoundaryWarnings: shots.any((shot) => shot.isBoundaryUncertain),
      duplicateShotCount: duplicateShotCount,
      explicitMissShotCount: explicitMissShotCount,
      zeroValueShotCount: zeroValueShotCount,
      unscoredBullCount: unscoredBullCount,
    );
  }

  static TargetBull _resolveRecordBull(
    TargetProfile target,
    ShotImpact impact,
  ) {
    final explicitBull = target.bullById(impact.targetBullId);
    if (impact.isMiss) {
      if (explicitBull == null || explicitBull.role != TargetBullRole.record) {
        throw ArgumentError.value(
          impact.targetBullId,
          'impact.targetBullId',
          'Een multi-bullmisser moet aan een bestaande recordbull gekoppeld zijn.',
        );
      }
      return explicitBull;
    }

    final geometricBull = target.bullAt(
      impact.xMm,
      impact.yMm,
      recordOnly: true,
    );
    if (geometricBull == null) {
      throw ArgumentError.value(
        '${impact.xMm}, ${impact.yMm}',
        'impact.position',
        'De impact ligt niet in het scoringsgebied van een recordbull.',
      );
    }
    if (impact.targetBullId != null &&
        (explicitBull == null ||
            explicitBull.role != TargetBullRole.record ||
            explicitBull.id != geometricBull.id)) {
      throw ArgumentError.value(
        impact.targetBullId,
        'impact.targetBullId',
        'De opgeslagen bull komt niet overeen met de geometrische positie.',
      );
    }
    return geometricBull;
  }

  static int _compareMultiBullResult(
    ScoredImpact a,
    ScoredImpact b,
    Map<String, int> originalOrder,
  ) {
    final valueOrder = a.value.compareTo(b.value);
    if (valueOrder != 0) return valueOrder;
    if (a.isInnerTen != b.isInnerTen) return a.isInnerTen ? 1 : -1;
    return (originalOrder[a.impact.id] ?? 0).compareTo(
      originalOrder[b.impact.id] ?? 0,
    );
  }

  static ScoredImpact _scoreImpact({
    required TargetProfile target,
    required ShotImpact impact,
    required double projectileDiameterMm,
    required double positionUncertaintyMm,
    required double centerXMm,
    required double centerYMm,
    String? targetBullId,
  }) {
    final dx = impact.xMm - centerXMm;
    final dy = impact.yMm - centerYMm;
    final radialDistance = math.sqrt(dx * dx + dy * dy);
    if (impact.isMiss) {
      return ScoredImpact(
        impact: impact,
        value: 0,
        countedValue: 0,
        disposition: ScoreDisposition.miss,
        isInnerTen: false,
        isBoundaryUncertain: false,
        radialDistanceMm: radialDistance,
        targetBullId: targetBullId,
      );
    }
    final evaluation = RadialScoreEvaluator.evaluate(
      target: target,
      xMm: impact.xMm,
      yMm: impact.yMm,
      centerXMm: centerXMm,
      centerYMm: centerYMm,
      projectileDiameterMm: projectileDiameterMm,
      positionUncertaintyMm:
          impact.positionalUncertaintyMm ?? positionUncertaintyMm,
      forceUncertain: impact.isPositionUncertain,
    );

    return ScoredImpact(
      impact: impact,
      value: evaluation.value,
      countedValue: evaluation.value,
      disposition: impact.isMiss
          ? ScoreDisposition.miss
          : ScoreDisposition.counted,
      isInnerTen: evaluation.isInnerTen,
      isBoundaryUncertain: evaluation.isBoundaryUncertain,
      radialDistanceMm: evaluation.radialDistanceMm,
      targetBullId: targetBullId,
    );
  }
}
