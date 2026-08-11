import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/training_tools/drill_plan_screen.dart';
import 'package:shooting_companion/features/training_tools/guided_drill_runner_screen.dart';
import 'package:shooting_companion_training/training.dart';

void main() {
  testWidgets('interrupted guided V2 drill resumes its persisted gates', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ShootingRepository(database);
    final drill = BuiltInTrainingContent.catalog.drills.first;
    const planContext = TrainingPlanContext(
      planActivityId: 'stored-plan',
      planId: 'plan-v1',
      durationMinutes: 30,
      slotIndex: 0,
      slotCount: 1,
      discipline: TrainingDiscipline.precisionPistol,
      skillLevel: TrainingSkillLevel.foundation,
    );
    await repository.createTrainingActivity(
      id: 'resume-drill',
      kind: StoredTrainingActivityKind.guidedDrillV2,
      status: StoredTrainingActivityStatus.interrupted,
      configuration: {
        'drillVersionedId': drill.versionedId,
        'drill': drill.toJson(),
        'trainingPlan': planContext.toJson(),
      },
      summary: const {
        'drillVersionedId': 'ignored-in-favour-of-snapshot',
        'setupConfirmed': true,
        'safetyConfirmed': true,
        'acknowledgedPhaseIds': <String>[],
        'timerActivityIds': <String, String>{},
        'phaseReflections': <String, String>{},
      },
      startedAtUtc: DateTime.utc(2026, 8, 10, 9),
      localUtcOffsetMinutes: 120,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: GuidedDrillRunnerScreen(
            drill: drill,
            activityId: 'resume-drill',
          ),
        ),
      ),
    );
    await _pumpUntil(
      tester,
      find.byKey(const ValueKey('drill-setup-confirmed')),
    );

    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('drill-setup-confirmed')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('drill-safety-confirmed')),
          )
          .value,
      isTrue,
    );
    expect(
      (await repository.getTrainingActivity('resume-drill'))!.activity.status,
      StoredTrainingActivityStatus.draft.name,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('planner resumes the exact persisted step and snapshot', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ShootingRepository(database);
    final catalog = BuiltInTrainingContent.catalog;
    final plan = const DeterministicDrillPlanner().generate(
      durationMinutes: 30,
      discipline: TrainingDiscipline.precisionPistol,
      skillLevel: TrainingSkillLevel.foundation,
      focus: TrainingPlanFocus.fundamentals,
      ammunitionBudget: 25,
      firearmId: 'historical-firearm',
      ammoLotId: 'historical-ammo',
      drills: catalog.drills,
      learningPaths: catalog.learningPaths,
    );
    final drillStepIndex = plan.steps.indexWhere(
      (step) => step.kind == TrainingPlanStepKind.drill,
    );
    await repository.createTrainingActivity(
      id: 'resume-plan',
      kind: StoredTrainingActivityKind.trainingPlan,
      status: StoredTrainingActivityStatus.interrupted,
      configuration: {'planId': plan.id, 'plan': plan.toJson()},
      summary: {
        'completedSlotIndexes': <int>[],
        'completedStepIds': plan.steps
            .take(drillStepIndex)
            .map((step) => step.id)
            .toList(),
        'guidedDrillActivityIds': <String, String>{},
        'currentStepIndex': drillStepIndex,
      },
      startedAtUtc: DateTime.utc(2026, 8, 10, 9),
      localUtcOffsetMinutes: 120,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: DeterministicDrillPlannerScreen.resume(
            activityId: 'resume-plan',
            drills: catalog.drills,
            learningPaths: catalog.learningPaths,
          ),
        ),
      ),
    );
    final selectedStep = find.byKey(
      ValueKey('drill-plan-step-$drillStepIndex'),
    );
    await _pumpUntil(tester, selectedStep);

    expect(find.text(plan.title), findsOneWidget);
    final selectedStepTile = find.descendant(
      of: selectedStep,
      matching: find.byType(ListTile),
    );
    expect(tester.widget<ListTile>(selectedStepTile).selected, isTrue);
    expect(
      find.textContaining(
        '${plan.usedAmmunition}/${plan.ammunitionBudget} patronen',
      ),
      findsOneWidget,
    );
    expect(
      (await repository.getTrainingActivity('resume-plan'))!.activity.status,
      StoredTrainingActivityStatus.draft.name,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 40,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Widget werd niet geladen: $finder');
}
