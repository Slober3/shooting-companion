import 'package:shooting_companion_analysis/analysis.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_scoring/scoring.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';
import 'package:test/test.dart';

void main() {
  final issf = IssfTargetProfiles.precision25m50m;

  test('never returns less than current or more than the target maximum', () {
    final result = PotentialScoreAnalyzer.analyze(
      target: issf,
      impacts: const [
        ShotImpact(id: 'a', xMm: 80, yMm: 20),
        ShotImpact(id: 'b', xMm: 85, yMm: 22),
        ShotImpact(id: 'c', xMm: 78, yMm: 18),
        ShotImpact(id: 'miss', xMm: 0, yMm: 0, isMiss: true),
      ],
      projectileDiameterMm: 5.6,
      positionUncertaintyMm: 0,
      config: const PotentialScoreSearchConfig(maximumTranslationMm: 120),
    );

    expect(result.bestScore, greaterThanOrEqualTo(result.currentScore));
    expect(result.bestScore, lessThanOrEqualTo(result.maximumPossible));
    expect(result.groupCenteringGain + result.remainingGap, result.currentGap);
  });

  test('finds a better score by translating an intact off-centre group', () {
    const impacts = [
      ShotImpact(id: 'a', xMm: 61, yMm: 1),
      ShotImpact(id: 'b', xMm: 60, yMm: 0),
      ShotImpact(id: 'c', xMm: 59, yMm: -1),
    ];
    final current = ScoreEngine.score(
      target: issf,
      impacts: impacts,
      projectileDiameterMm: 5.6,
      positionUncertaintyMm: 0,
    );
    final result = PotentialScoreAnalyzer.analyze(
      target: issf,
      impacts: impacts,
      projectileDiameterMm: 5.6,
      positionUncertaintyMm: 0,
      config: const PotentialScoreSearchConfig(maximumTranslationMm: 80),
    );

    expect(result.currentScore, current.total);
    expect(result.bestScore, 30);
    expect(result.groupCenteringGain, 30 - current.total);
    expect(result.translationXMm, lessThan(0));
    expect(result.translationYMm.abs(), lessThanOrEqualTo(1));
  });

  test('score ties choose the smallest translation, including zero', () {
    final result = PotentialScoreAnalyzer.analyze(
      target: issf,
      impacts: const [ShotImpact(id: 'center', xMm: 0, yMm: 0)],
      projectileDiameterMm: 5.6,
      positionUncertaintyMm: 0,
      config: const PotentialScoreSearchConfig(
        coarseStepMm: 5,
        maximumTranslationMm: 50,
      ),
    );

    expect(result.currentScore, 10);
    expect(result.bestScore, 10);
    expect(result.translationXMm, 0);
    expect(result.translationYMm, 0);
    expect(result.translationDistanceMm, 0);
  });

  test('misses remain misses and are never translated into points', () {
    final result = PotentialScoreAnalyzer.analyze(
      target: issf,
      impacts: const [
        ShotImpact(id: 'hit', xMm: 60, yMm: 0),
        ShotImpact(id: 'miss', xMm: 0, yMm: 0, isMiss: true),
      ],
      projectileDiameterMm: 5.6,
      positionUncertaintyMm: 0,
      config: const PotentialScoreSearchConfig(maximumTranslationMm: 80),
    );

    expect(result.bestScore, 10);
    expect(result.maximumPossible, 20);
    expect(result.remainingGap, 10);
  });

  test('translates BR50 impacts within their referenced bull geometry', () {
    final target = WrabfTargetProfiles.rimfire50mBr50;
    final first = target.recordBulls.first;
    final second = target.recordBulls[1];
    final result = PotentialScoreAnalyzer.analyze(
      target: target,
      impacts: [
        ShotImpact(
          id: 'one',
          xMm: first.centerXMm + 8,
          yMm: first.centerYMm,
          targetBullId: first.id,
        ),
        ShotImpact(
          id: 'two',
          xMm: second.centerXMm + 8,
          yMm: second.centerYMm,
          targetBullId: second.id,
        ),
      ],
      projectileDiameterMm: 5.6,
      positionUncertaintyMm: 0,
      config: const PotentialScoreSearchConfig(
        coarseStepMm: 2,
        maximumTranslationMm: 15,
      ),
    );

    expect(result.bestScore, 20);
    expect(result.translationXMm, lessThan(0));
    expect(result.maximumPossible, 250);
  });

  test('is deterministic and leaves source impact instances unchanged', () {
    final impacts = [
      const ShotImpact(id: 'a', xMm: 40, yMm: 10),
      const ShotImpact(id: 'b', xMm: 45, yMm: 12),
    ];
    final identities = impacts.map(identityHashCode).toList();

    PotentialScoreResult run() => PotentialScoreAnalyzer.analyze(
      target: issf,
      impacts: impacts,
      projectileDiameterMm: 5.6,
      config: const PotentialScoreSearchConfig(maximumTranslationMm: 60),
    );

    final first = run();
    final second = run();
    expect(second.bestScore, first.bestScore);
    expect(second.translationXMm, first.translationXMm);
    expect(second.translationYMm, first.translationYMm);
    expect(impacts.map(identityHashCode), identities);
    expect(impacts.first.xMm, 40);
  });

  test('handles a series containing only misses without a search', () {
    final result = PotentialScoreAnalyzer.analyze(
      target: issf,
      impacts: const [ShotImpact(id: 'miss', xMm: 0, yMm: 0, isMiss: true)],
      projectileDiameterMm: 5.6,
    );

    expect(result.currentScore, 0);
    expect(result.bestScore, 0);
    expect(result.translationXMm, 0);
    expect(result.translationYMm, 0);
  });
}
