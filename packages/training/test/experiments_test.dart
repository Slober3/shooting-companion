import 'package:shooting_companion_training/training.dart';
import 'package:test/test.dart';

void main() {
  group('ExperimentDefinition and planner', () {
    test('roundtrips a versioned experiment definition', () {
      final source = _definition();
      final restored = ExperimentDefinition.fromJson(source.toJson());

      expect(restored.toJson(), source.toJson());
      expect(restored.versionedId, 'ammo-ab@1');
      expect(restored.variantA.label, 'Lot A');
      expect(restored.variantB.label, 'Lot B');
    });

    test('creates deterministic balanced A-B-B-A blocks', () {
      final definition = _definition(plannedBlocks: 3);
      final first = ExperimentPlanner.create(definition);
      final second = ExperimentPlanner.create(definition);
      final ids = first.assignments
          .map((assignment) => assignment.variantId)
          .toList();

      expect(ids, ['a', 'b', 'b', 'a', 'a', 'b', 'b', 'a', 'a', 'b', 'b', 'a']);
      expect(ids.where((id) => id == 'a'), hasLength(6));
      expect(ids.where((id) => id == 'b'), hasLength(6));
      expect(
        first.assignments.map((assignment) => assignment.sequenceNumber),
        List<int>.generate(12, (index) => index + 1),
      );
      expect(first.toJson(), second.toJson());
      expect(ExperimentPlan.fromJson(first.toJson()).toJson(), first.toJson());
    });

    test('rejects variants that cannot form a controlled comparison', () {
      expect(
        () => ExperimentDefinition(
          id: 'invalid',
          version: 1,
          name: 'Invalid',
          variable: ExperimentVariable.ammoLot,
          variantA: ExperimentVariant(id: 'same', label: 'A'),
          variantB: ExperimentVariant(id: 'same', label: 'B'),
          targetProfileVersionedId: 'target@1',
          distanceMeters: 25,
        ),
        throwsArgumentError,
      );
      expect(() => _definition(distanceMeters: 0), throwsArgumentError);
    });
  });

  group('minimum data status', () {
    test('starts with explicit deficits for both variants', () {
      final status = ExperimentEvaluator.minimumDataStatus(
        _definition(),
        const [],
      );

      expect(status.state, ExperimentDataState.notStarted);
      expect(status.variantA.missingSeriesCount, 5);
      expect(status.variantA.missingPositionedShotCount, 50);
      expect(status.variantB.missingSeriesCount, 5);
      expect(status.isSufficient, isFalse);
    });

    test('requires both series and positioned-shot thresholds', () {
      final definition = _definition();
      final seriesEnoughButShotsShort = [
        for (var index = 0; index < 5; index++)
          const ExperimentSample(variantId: 'a', positionedShotCount: 9),
        for (var index = 0; index < 5; index++)
          const ExperimentSample(variantId: 'b', positionedShotCount: 10),
      ];
      final status = ExperimentEvaluator.minimumDataStatus(
        definition,
        seriesEnoughButShotsShort,
      );

      expect(status.state, ExperimentDataState.collectingVariantA);
      expect(status.variantA.missingSeriesCount, 0);
      expect(status.variantA.missingPositionedShotCount, 5);
      expect(status.variantB.minimumReached, isTrue);
    });

    test('reports readiness exactly at both minimums', () {
      final samples = [
        for (var index = 0; index < 5; index++)
          const ExperimentSample(variantId: 'a', positionedShotCount: 10),
        for (var index = 0; index < 5; index++)
          const ExperimentSample(variantId: 'b', positionedShotCount: 10),
      ];
      final status = ExperimentEvaluator.minimumDataStatus(
        _definition(),
        samples,
      );

      expect(status.state, ExperimentDataState.sufficient);
      expect(status.isSufficient, isTrue);
      expect(status.variantA.missingSeriesCount, 0);
      expect(status.variantB.missingPositionedShotCount, 0);
    });

    test('rejects samples from an unknown variant', () {
      expect(
        () => ExperimentEvaluator.minimumDataStatus(_definition(), const [
          ExperimentSample(variantId: 'unknown', positionedShotCount: 10),
        ]),
        throwsArgumentError,
      );
    });
  });
}

ExperimentDefinition _definition({
  int plannedBlocks = 3,
  double distanceMeters = 25,
}) => ExperimentDefinition(
  id: 'ammo-ab',
  version: 1,
  name: 'Munitielot A/B',
  variable: ExperimentVariable.ammoLot,
  variantA: ExperimentVariant(id: 'a', label: 'Lot A'),
  variantB: ExperimentVariant(id: 'b', label: 'Lot B'),
  targetProfileVersionedId: 'issf@1',
  distanceMeters: distanceMeters,
  plannedBlocks: plannedBlocks,
  minimumSeriesPerVariant: 5,
  minimumPositionedShotsPerVariant: 50,
);
