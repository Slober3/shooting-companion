import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/features/training_tools/training_tools.dart';
import 'package:shooting_companion_training/training.dart';

void main() {
  testWidgets('opens drill library and a complete drill detail', (
    tester,
  ) async {
    DrillDefinition? selected;
    await tester.pumpWidget(
      _app(TrainingToolsScreen(onDrillSelected: (value) => selected = value)),
    );

    await _tapTool(tester, 'training-tool-drills');
    await tester.pumpAndSettle();
    expect(find.text('Drills'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('drill-cold-series-benchmark')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('drill-cold-series-benchmark')));
    await tester.pumpAndSettle();
    expect(find.text('Cold-series benchmark'), findsOneWidget);
    expect(find.text('Experimenteel'), findsOneWidget);
    expect(find.text('Stappen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('drill-safety-note')),
      240,
    );
    expect(find.textContaining('baanregels'), findsOneWidget);

    await tester.tap(find.text('Drill kiezen'));
    await tester.pumpAndSettle();
    expect(selected?.versionedId, 'cold-series-benchmark@1');
    expect(find.text('Drills'), findsOneWidget);
  });

  testWidgets('opens the structured shot timer setup', (tester) async {
    await tester.pumpWidget(_app(const TrainingToolsScreen()));

    expect(
      find.byKey(const ValueKey('training-tool-calibration-profiles')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('training-tool-shot-timer')));
    await tester.pumpAndSettle();

    expect(find.text('Timer instellen'), findsOneWidget);
    expect(find.text('Akoestische live fire'), findsNothing);
    expect(find.text('Live-firedetectie'), findsNothing);
    expect(find.text('Par timer'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-shot-timer')), findsOneWidget);
  });

  testWidgets('creates a balanced ABBA plan and explains minimum data', (
    tester,
  ) async {
    ExperimentPlan? captured;
    await tester.pumpWidget(
      _app(
        TrainingToolsScreen(onExperimentPlanCreated: (plan) => captured = plan),
      ),
    );

    await _tapTool(tester, 'training-tool-experiment');
    await tester.pumpAndSettle();
    expect(find.text('A/B-experiment'), findsOneWidget);
    expect(
      find.textContaining('Minimaal 5 bevestigde reeksen'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('create-experiment-plan')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.assignments.map((assignment) => assignment.variantId), [
      'a',
      'b',
      'b',
      'a',
      'a',
      'b',
      'b',
      'a',
      'a',
      'b',
      'b',
      'a',
    ]);
    expect(
      find.byKey(const ValueKey('experiment-plan-preview')),
      findsOneWidget,
    );
    expect(
      find.textContaining('6 reeksen per variant gepland'),
      findsOneWidget,
    );
  });

  testWidgets('sight calculator requires direction confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const TrainingToolsScreen()));
    await _tapTool(tester, 'training-tool-sight');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('sight-horizontal-offset')),
      '29,0888',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sight-vertical-offset')),
      '0',
    );
    await tester.enterText(find.byKey(const ValueKey('sight-distance')), '100');
    await tester.enterText(find.byKey(const ValueKey('sight-shot-count')), '5');
    await tester.enterText(
      find.byKey(const ValueKey('sight-click-value')),
      '0,25',
    );
    await tester.tap(find.byKey(const ValueKey('calculate-sight-correction')));
    await tester.pumpAndSettle();

    expect(find.text('Bevestig eerst de klikrichtingen'), findsOneWidget);
    expect(find.textContaining('richting nog niet bevestigd'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const ValueKey('sight-direction-confirmation')),
    );
    await tester.tap(
      find.byKey(const ValueKey('sight-direction-confirmation')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('calculate-sight-correction')));
    await tester.pumpAndSettle();

    expect(find.text('Voorgestelde correctie'), findsOneWidget);
    expect(find.textContaining('4 positieve klikken'), findsOneWidget);
  });

  testWidgets('remains usable at 320 dp and 200 percent text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(2),
        ),
        child: _app(const TrainingToolsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trainingstools'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tapTool(tester, 'training-tool-drills');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drill-library-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapTool(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget _app(Widget home) => ProviderScope(
  overrides: [
    timerPresetsProvider.overrideWith((ref) => Stream.value(const [])),
    acousticCalibrationProfilesProvider.overrideWith(
      (ref) => Stream.value(const []),
    ),
  ],
  child: MaterialApp(
    theme: ThemeData.from(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F6F8F)),
      useMaterial3: true,
    ),
    home: home,
  ),
);
