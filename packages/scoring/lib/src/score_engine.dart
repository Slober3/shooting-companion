import 'dart:math' as math;

import 'package:shooting_companion_domain/domain.dart';

class ScoredImpact {
  const ScoredImpact({
    required this.impact,
    required this.value,
    required this.countedValue,
    required this.disposition,
    required this.isInnerTen,
    required this.isBoundaryUncertain,
    required this.radialDistanceMm,
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
  final String? targetBullId;

  int get subtotal => countedValue;

  ScoredImpact withCounting({
    required int countedValue,
    required ScoreDisposition disposition,
    required bool isInnerTen,
  }) => ScoredImpact(
    impact: impact,
    value: value,
    countedValue: countedValue,
    disposition: disposition,
    isInnerTen: isInnerTen,
    isBoundaryUncertain: isBoundaryUncertain,
    radialDistanceMm: radialDistanceMm,
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
  final int missCount;
  final bool hasBoundaryWarnings;

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
    if (projectileDiameterMm <= 0) {
      throw ArgumentError.value(
        projectileDiameterMm,
        'projectileDiameterMm',
        'Moet groter zijn dan nul',
      );
    }
    final impactList = impacts.toList(growable: false);
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
    return ScoreResult(
      shots: [
        for (final shot in scored)
          shot.withCounting(
            countedValue: shot.value * shot.impact.multiplicity,
            disposition: shot.impact.isMiss
                ? ScoreDisposition.miss
                : ScoreDisposition.counted,
            isInnerTen: shot.isInnerTen,
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
      missCount: scored.fold(
        0,
        (sum, shot) => sum + (shot.value == 0 ? shot.impact.multiplicity : 0),
      ),
      hasBoundaryWarnings: scored.any((shot) => shot.isBoundaryUncertain),
    );
  }

  static ScoreResult _scoreMultiBull({
    required TargetProfile target,
    required List<ShotImpact> impacts,
    required double projectileDiameterMm,
    required double positionUncertaintyMm,
  }) {
    final policy = target.multiBullScoringPolicy!;
    final recordBulls = <String, TargetBull>{};
    for (final bull in target.bulls) {
      if (bull.role == TargetBullRole.record) recordBulls[bull.id] = bull;
    }
    final originalOrder = <String, int>{};
    for (var index = 0; index < impacts.length; index++) {
      originalOrder[impacts[index].id] = index;
    }
    final rawById = <String, ScoredImpact>{};
    final byBull = <String, List<ScoredImpact>>{};
    var actualShotCount = 0;

    for (final impact in impacts) {
      final explicitBull = target.bullById(impact.targetBullId);
      final bull = explicitBull?.role == TargetBullRole.record
          ? explicitBull
          : target.bullAt(impact.xMm, impact.yMm, recordOnly: true);
      if (bull == null || !recordBulls.containsKey(bull.id)) {
        rawById[impact.id] = ScoredImpact(
          impact: impact,
          value: 0,
          countedValue: 0,
          disposition: ScoreDisposition.duplicateNotCounted,
          isInnerTen: false,
          isBoundaryUncertain: impact.isPositionUncertain,
          radialDistanceMm: 0,
        );
        continue;
      }
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
      );
      for (var index = 0; index < entries.length; index++) {
        if (index == winnerIndex) continue;
        final duplicate = entries[index];
        countedById[duplicate.impact.id] = duplicate.withCounting(
          countedValue: 0,
          disposition: ScoreDisposition.duplicateNotCounted,
          isInnerTen: false,
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
    );
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
      countedValue: value,
      disposition: impact.isMiss
          ? ScoreDisposition.miss
          : ScoreDisposition.counted,
      isInnerTen: isInnerTen,
      isBoundaryUncertain: isBoundaryUncertain,
      radialDistanceMm: radialDistance,
      targetBullId: targetBullId,
    );
  }
}
