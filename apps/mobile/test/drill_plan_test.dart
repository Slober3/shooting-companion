import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/features/training_tools/drill_plan_screen.dart';
import 'package:shooting_companion_training/training.dart';

void main() {
  final catalog = BuiltInTrainingContent.catalog;
  const planner = DeterministicDrillPlanner();

  group('deterministic drill planner', () {
    for (final duration in const [30, 45, 60]) {
      test('$duration minute plan uses full drills without overrun', () {
        final plan = planner.generate(
          durationMinutes: duration,
          discipline: TrainingDiscipline.precisionPistol,
          skillLevel: TrainingSkillLevel.foundation,
          focus: TrainingPlanFocus.fundamentals,
          ammunitionBudget: 30,
          firearmId: 'firearm-a',
          ammoLotId: 'ammo-a',
          drills: catalog.drills,
          learningPaths: catalog.learningPaths,
        );

        expect(plan.plannedMinutes, lessThanOrEqualTo(duration));
        expect(plan.usedAmmunition, lessThanOrEqualTo(30));
        expect(plan.slots, isNotEmpty);
        expect(
          plan.slots.every(
            (slot) =>
                slot.allocatedMinutes == slot.drill.estimatedDurationMinutes,
          ),
          isTrue,
          reason: 'Een volledige drill mag nooit worden ingekort.',
        );
        expect(plan.steps.first.kind, TrainingPlanStepKind.safetyAndSetup);
        expect(plan.steps[1].kind, TrainingPlanStepKind.techniqueReview);
        expect(plan.steps[1].lessonVersionedId, isNotNull);
        final linkedLesson = catalog.lessonByVersionedId(
          plan.steps[1].lessonVersionedId!,
        );
        expect(linkedLesson, isNotNull);
        expect(plan.steps[1].lessonTitle, linkedLesson!.title);
        expect(plan.steps.last.kind, TrainingPlanStepKind.finalReflection);
        for (final slot in plan.slots) {
          expect(
            plan.steps.any(
              (step) =>
                  step.kind == TrainingPlanStepKind.drill &&
                  step.slotIndex == slot.index,
            ),
            isTrue,
          );
          expect(
            plan.steps.any(
              (step) =>
                  step.kind == TrainingPlanStepKind.restAndReview &&
                  step.slotIndex == slot.index,
            ),
            isTrue,
          );
        }
      });
    }

    test('same inputs produce byte-equivalent snapshot', () {
      GeneratedDrillPlan generate() => planner.generate(
        durationMinutes: 60,
        discipline: TrainingDiscipline.precisionPistol,
        skillLevel: TrainingSkillLevel.foundation,
        focus: TrainingPlanFocus.groupSize,
        ammunitionBudget: 25,
        firearmId: 'firearm-a',
        ammoLotId: 'ammo-a',
        drills: catalog.drills,
        learningPaths: catalog.learningPaths,
      );

      final first = generate();
      final second = generate();
      expect(jsonEncode(first.toJson()), jsonEncode(second.toJson()));
      expect(
        GeneratedDrillPlan.fromJson(first.toJson()).toJson(),
        first.toJson(),
      );
      expect(
        GeneratedDrillPlan.fromJson(first.toJson()).steps
            .firstWhere(
              (step) => step.kind == TrainingPlanStepKind.techniqueReview,
            )
            .lessonVersionedId,
        isNotNull,
      );
    });

    test('zero ammunition selects a complete dry-fire drill', () {
      final plan = planner.generate(
        durationMinutes: 30,
        discipline: TrainingDiscipline.precisionPistol,
        skillLevel: TrainingSkillLevel.foundation,
        focus: TrainingPlanFocus.fundamentals,
        ammunitionBudget: 0,
        drills: catalog.drills,
        learningPaths: catalog.learningPaths,
      );

      expect(plan.usedAmmunition, 0);
      expect(plan.slots.single.drill.mode, TrainingMode.rangeDryFire);
      expect(plan.plannedMinutes, lessThanOrEqualTo(30));
    });

    test('low ammunition never substitutes a partial live-fire drill', () {
      expect(
        () => planner.generate(
          durationMinutes: 30,
          discipline: TrainingDiscipline.br50,
          skillLevel: TrainingSkillLevel.foundation,
          focus: TrainingPlanFocus.fundamentals,
          ammunitionBudget: 0,
          drills: catalog.drills,
          learningPaths: catalog.learningPaths,
        ),
        throwsStateError,
      );
    });

    test('unsupported discipline is rejected instead of silently remapped', () {
      expect(
        () => planner.generate(
          durationMinutes: 30,
          discipline: TrainingDiscipline.universal,
          skillLevel: TrainingSkillLevel.foundation,
          focus: TrainingPlanFocus.fundamentals,
          ammunitionBudget: 25,
          drills: catalog.drills,
          learningPaths: catalog.learningPaths,
        ),
        throwsArgumentError,
      );
    });
  });
}
