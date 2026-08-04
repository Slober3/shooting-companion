import 'package:shooting_companion_coaching/coaching.dart';
import 'package:test/test.dart';

void main() {
  const engine = CoachRuleEngine();

  group('minimum evidence', () {
    test('rejects duplicate series instead of inflating evidence', () {
      final duplicate = _series(0, hits: 20, x: -10);
      expect(
        () => _snapshot([duplicate, duplicate]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns no pattern below three series', () {
      final result = engine.evaluate(
        _snapshot([_series(0, hits: 20, x: -10), _series(1, hits: 20, x: -10)]),
      );
      expect(result, isEmpty);
    });

    test('returns no pattern below thirty positioned hits', () {
      final result = engine.evaluate(
        _snapshot([
          _series(0, hits: 9, x: -10),
          _series(1, hits: 9, x: -10),
          _series(2, hits: 9, x: -10),
        ]),
      );
      expect(result, isEmpty);
    });

    test('marks five series and sixty hits as strong', () {
      final result = engine.evaluate(
        _snapshot([
          for (var index = 0; index < 5; index++)
            _series(index, hits: 12, x: -10),
        ]),
      );
      expect(
        _byRule(result, CoachRuleIds.persistentBias).evidenceStrength,
        CoachEvidenceStrength.strong,
      );
    });
  });

  group('group patterns', () {
    test('describes persistent bias as a hypothesis with an experiment', () {
      final result = engine.evaluate(
        _snapshot([
          for (var index = 0; index < 3; index++)
            _series(index, hits: 10, x: -10),
        ]),
      );
      final insight = _byRule(result, CoachRuleIds.persistentBias);
      expect(insight.observation, contains('links'));
      expect(insight.evidenceStrength, CoachEvidenceStrength.moderate);
      expect(insight.possibleExplanations, hasLength(greaterThanOrEqualTo(2)));
      expect(insight.proposedExperiment.controlledVariable, isNotEmpty);
      expect(CoachSafetyPolicy.violations(insight), isEmpty);
    });

    test('recognizes centered but wide groups', () {
      final result = engine.evaluate(
        _snapshot([
          for (var index = 0; index < 3; index++)
            _series(index, hits: 10, radius: 9),
        ]),
      );
      expect(
        _byRule(result, CoachRuleIds.centeredButWide).observation,
        contains('goed gecentreerd'),
      );
    });

    test('recognizes compact off-center groups', () {
      final result = engine.evaluate(
        _snapshot([
          for (var index = 0; index < 3; index++)
            _series(index, hits: 10, x: 8, radius: 2),
        ]),
      );
      expect(
        _byRule(result, CoachRuleIds.compactOffCenter).observation,
        contains('compact'),
      );
    });

    test('adds an approximation warning', () {
      final result = engine.evaluate(
        _snapshot([
          _series(0, hits: 10, x: -10, approximate: true),
          _series(1, hits: 10, x: -10),
          _series(2, hits: 10, x: -10),
        ]),
      );
      expect(
        _byRule(result, CoachRuleIds.persistentBias).warnings,
        contains(contains('benaderend')),
      );
    });
  });

  group('trends and consistency', () {
    test('recognizes improvement only with strong evidence', () {
      final radii = [10.0, 10.0, 8.0, 7.0, 6.0, 6.0];
      final result = engine.evaluate(
        _snapshot([
          for (var index = 0; index < radii.length; index++)
            _series(index, hits: 10, radius: radii[index]),
        ]),
      );
      expect(
        _byRule(result, CoachRuleIds.improving).observation,
        contains('kleinere'),
      );
    });

    test('recognizes decline', () {
      final radii = [5.0, 5.0, 6.0, 7.0, 9.0, 9.0];
      final result = engine.evaluate(
        _snapshot([
          for (var index = 0; index < radii.length; index++)
            _series(index, hits: 10, radius: radii[index]),
        ]),
      );
      expect(
        _byRule(result, CoachRuleIds.declining).observation,
        contains('grotere'),
      );
    });

    test('recognizes a plateau', () {
      final result = engine.evaluate(
        _snapshot([
          for (var index = 0; index < 6; index++)
            _series(index, hits: 10, radius: 5),
        ]),
      );
      expect(
        _byRule(result, CoachRuleIds.plateau).observation,
        contains('stabiel'),
      );
    });

    test('recognizes high variability', () {
      final radii = [2.0, 10.0, 2.0];
      final result = engine.evaluate(
        _snapshot([
          for (var index = 0; index < radii.length; index++)
            _series(index, hits: 10, radius: radii[index]),
        ]),
      );
      expect(
        _byRule(
          result,
          CoachRuleIds.variability,
        ).evidence.metrics['coefficient_of_variation'],
        greaterThan(0.25),
      );
    });
  });

  test(
    'compares material only after five series and fifty hits per variant',
    () {
      final result = engine.evaluate(
        _snapshot(
          [
            for (var index = 0; index < 5; index++)
              _series(index, hits: 10, radius: 4, ammoLotId: 'a'),
            for (var index = 5; index < 10; index++)
              _series(index, hits: 10, radius: 8, ammoLotId: 'b'),
          ],
          materialLabels: const [
            CoachMaterialLabel(
              kind: CoachMaterialKind.ammoLot,
              id: 'a',
              displayName: 'Lot A',
            ),
            CoachMaterialLabel(
              kind: CoachMaterialKind.ammoLot,
              id: 'b',
              displayName: 'Lot B',
            ),
          ],
        ),
      );
      final insight = _byRule(result, CoachRuleIds.materialComparison);
      expect(insight.observation, contains('Lot A'));
      expect(insight.observation, isNot(contains('beter')));
      expect(insight.evidenceStrength, CoachEvidenceStrength.strong);
    },
  );

  test('finds a BR50 area pattern without treating bull number as order', () {
    final result = engine.evaluate(
      _snapshot([
        for (var index = 0; index < 3; index++)
          _series(
            index,
            hits: 10,
            areas: const [
              CoachAreaObservation(
                areaId: 'top',
                label: 'boven',
                scoredBullCount: 5,
                averageScore: 8,
              ),
              CoachAreaObservation(
                areaId: 'bottom',
                label: 'onder',
                scoredBullCount: 5,
                averageScore: 9,
              ),
            ],
          ),
      ]),
    );
    final insight = _byRule(result, CoachRuleIds.br50AreaPattern);
    expect(insight.observation, contains('kaartzone boven'));
    expect(insight.nextMeasurement.instructions, contains('bullnummer'));
  });

  test('compares first and later series only across paired sessions', () {
    final samples = <CoachSeriesObservation>[];
    for (var session = 0; session < 3; session++) {
      samples
        ..add(
          _series(
            session * 2,
            hits: 5,
            radius: 8,
            sessionId: 'session-$session',
            sequence: 1,
          ),
        )
        ..add(
          _series(
            session * 2 + 1,
            hits: 5,
            radius: 4,
            sessionId: 'session-$session',
            sequence: 2,
          ),
        );
    }
    final insight = _byRule(
      engine.evaluate(_snapshot(samples)),
      CoachRuleIds.firstVersusLater,
    );
    expect(insight.observation, contains('eerste reeks'));
    expect(insight.evidenceStrength, CoachEvidenceStrength.moderate);
  });

  test('reports reflection association without claiming causality', () {
    final result = engine.evaluate(
      _snapshot([
        for (var index = 0; index < 3; index++)
          _series(
            index,
            hits: 5,
            radius: 4,
            quality: CoachPerceivedQuality.good,
          ),
        for (var index = 3; index < 6; index++)
          _series(
            index,
            hits: 5,
            radius: 8,
            quality: CoachPerceivedQuality.difficult,
          ),
      ]),
    );
    final insight = _byRule(result, CoachRuleIds.reflectionCorrelation);
    expect(insight.observation, contains('Moeilijk'));
    expect(insight.nextMeasurement.instructions, contains('oorzaak'));
    expect(CoachSafetyPolicy.violations(insight), isEmpty);
  });

  group('fingerprints and safety', () {
    test('fingerprint is order-independent and changes when data changes', () {
      final original = [
        _series(0, hits: 10, x: -10),
        _series(1, hits: 10, x: -10),
        _series(2, hits: 10, x: -10),
      ];
      final first = _byRule(
        engine.evaluate(_snapshot(original)),
        CoachRuleIds.persistentBias,
      );
      final reversed = _byRule(
        engine.evaluate(_snapshot(original.reversed.toList())),
        CoachRuleIds.persistentBias,
      );
      final changed = _byRule(
        engine.evaluate(
          _snapshot([
            _series(0, hits: 10, x: -11),
            _series(1, hits: 10, x: -10),
            _series(2, hits: 10, x: -10),
          ]),
        ),
        CoachRuleIds.persistentBias,
      );
      expect(first.fingerprint, reversed.fingerprint);
      expect(first.fingerprint, isNot(changed.fingerprint));
    });

    test('safety policy rejects causal or prescriptive copy', () {
      final unsafe = CoachInsight(
        fingerprint: 'unsafe',
        ruleId: 'test.unsafe',
        ruleVersion: 1,
        observation: 'Dit bewijst dat je een trekkerfout maakt.',
        evidence: CoachEvidence(
          summary: 'Test',
          seriesCount: 3,
          positionedHitCount: 30,
        ),
        evidenceStrength: CoachEvidenceStrength.moderate,
        possibleExplanations: const [
          CoachExplanation(title: 'A', detail: 'Mogelijk A.'),
          CoachExplanation(title: 'B', detail: 'Mogelijk B.'),
        ],
        proposedExperiment: const CoachExperiment(
          title: 'Test',
          instructions: 'Test veilig.',
          controlledVariable: 'Eén variabele',
        ),
        nextMeasurement: const CoachNextMeasurement(
          label: 'Meting',
          instructions: 'Meet opnieuw.',
        ),
        cohortReference: _cohort,
      );
      expect(
        () => CoachSafetyPolicy.ensureSafe(unsafe),
        throwsA(isA<StateError>()),
      );
    });

    test('feedback supports every response type', () {
      for (final response in CoachFeedbackResponse.values) {
        final feedback = CoachFeedback(
          insightFingerprint: 'ci_test',
          response: response,
          updatedAtUtc: DateTime.utc(2026, 8, 4),
        );
        expect(feedback.response, response);
      }
    });
  });
}

const _cohort = CoachCohortReference(
  targetProfileVersionedId: 'issf-25m@1',
  distanceMeters: 25,
);

CoachAnalysisSnapshot _snapshot(
  List<CoachSeriesObservation> series, {
  List<CoachMaterialLabel> materialLabels = const [],
}) => CoachAnalysisSnapshot(
  cohort: _cohort,
  thresholds: const CoachThresholds(
    biasToleranceMm: 5,
    compactMeanRadiusMm: 3,
    wideMeanRadiusMm: 8,
  ),
  series: series,
  materialLabels: materialLabels,
);

CoachSeriesObservation _series(
  int index, {
  int hits = 10,
  double x = 0,
  double y = 0,
  double radius = 5,
  String? sessionId,
  int sequence = 1,
  String? firearmId,
  String? ammoLotId,
  CoachPerceivedQuality? quality,
  bool approximate = false,
  List<CoachAreaObservation> areas = const [],
}) => CoachSeriesObservation(
  seriesId: 'series-$index',
  sessionId: sessionId ?? 'session-single-$index',
  sequenceNumber: sequence,
  occurredAtUtc: DateTime.utc(2026, 1, 1).add(Duration(days: index)),
  positionedHitCount: hits,
  centroidXMm: x,
  centroidYMm: y,
  meanRadiusMm: radius,
  firearmId: firearmId,
  ammoLotId: ammoLotId,
  perceivedQuality: quality,
  hasApproximatePositions: approximate,
  br50Areas: areas,
);

CoachInsight _byRule(List<CoachInsight> insights, String ruleId) =>
    insights.singleWhere((insight) => insight.ruleId == ruleId);
