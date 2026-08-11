import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_training/training.dart';
import 'package:test/test.dart';

void main() {
  group('DrillDefinition', () {
    test('roundtrips every built-in drill through stable JSON', () {
      for (final drill in BuiltInDrills.all) {
        final restored = DrillDefinition.fromJson(drill.toJson());
        expect(restored.toJson(), drill.toJson(), reason: drill.versionedId);
        expect(restored.versionedId, drill.versionedId);
      }
    });

    test('publishes the expanded offline drill library', () {
      expect(BuiltInDrills.all, hasLength(15));
      expect(
        BuiltInDrills.all.map((drill) => drill.versionedId).toSet(),
        hasLength(15),
      );
      expect(
        BuiltInDrills.all.every(
          (drill) =>
              drill.validationStatus == DrillValidationStatus.experimental,
        ),
        isTrue,
      );
      expect(
        BuiltInDrills.byVersionedId('cold-series-benchmark@1').name,
        'Cold-series benchmark',
      );
      expect(
        BuiltInDrills.all.map((drill) => drill.category).toSet(),
        containsAll([
          DrillCategory.baseline,
          DrillCategory.grouping,
          DrillCategory.equipment,
          DrillCategory.matchPreparation,
          DrillCategory.reflection,
        ]),
      );
    });

    test('keeps BR50 and ordinary target compatibility explicit', () {
      expect(
        BuiltInDrills.br50Discipline.supports(TargetKind.multiBullConcentric),
        isTrue,
      );
      expect(
        BuiltInDrills.br50Discipline.supports(TargetKind.concentricRings),
        isFalse,
      );
      expect(
        BuiltInDrills.groupSize.supports(TargetKind.concentricRings),
        isTrue,
      );
      expect(
        BuiltInDrills.groupSize.supports(TargetKind.multiBullConcentric),
        isFalse,
      );
    });

    test('normalizes text and exposes immutable collections', () {
      final drill = DrillDefinition(
        id: '  custom  ',
        version: 2,
        name: '  Custom drill  ',
        objective: ' Objectief ',
        compatibleTargetKinds: const [TargetKind.concentricRings],
        recommendedSeries: 2,
        successMetric: DrillSuccessMetric(
          metric: DrillMetric.completion,
          direction: DrillMetricDirection.complete,
        ),
        instructions: const ['  Stap een  ', '', 'Stap twee'],
        safetyNote: ' Veilig ',
      );

      expect(drill.versionedId, 'custom@2');
      expect(drill.name, 'Custom drill');
      expect(drill.instructions, ['Stap een', 'Stap twee']);
      expect(() => drill.instructions.add('extra'), throwsUnsupportedError);
      expect(
        () => drill.compatibleTargetKinds.add(TargetKind.multiBullConcentric),
        throwsUnsupportedError,
      );
    });

    test('rejects incomplete or contradictory definitions', () {
      expect(
        () => DrillDefinition(
          id: '',
          version: 1,
          name: 'Naam',
          objective: 'Doel',
          compatibleTargetKinds: const [TargetKind.concentricRings],
          recommendedSeries: 1,
          successMetric: DrillSuccessMetric(
            metric: DrillMetric.completion,
            direction: DrillMetricDirection.complete,
          ),
          instructions: const ['Stap'],
          safetyNote: 'Veilig',
        ),
        throwsArgumentError,
      );
      expect(() => DrillShotStructure(), throwsArgumentError);
      expect(
        () => DrillSuccessMetric(
          metric: DrillMetric.completion,
          direction: DrillMetricDirection.complete,
          targetValue: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
