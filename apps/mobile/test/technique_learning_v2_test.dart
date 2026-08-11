import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/features/training_tools/technique_screens.dart';
import 'package:shooting_companion_training/training.dart';

void main() {
  testWidgets('lesson exposes the three progressive information layers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final lesson = BuiltInTrainingContent.catalog.lessons.first;

    await tester.pumpWidget(
      _app(
        TechniqueLessonScreen(lesson: lesson),
        mediaQueryData: const MediaQueryData(
          size: Size(320, 760),
          textScaler: TextScaler.linear(2),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('technique-step-title')),
      180,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('In één minuut'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('technique-layer-one-minute')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('technique-layer-one-minute')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('technique-next-step')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('technique-step-title')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Stap voor stap'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('technique-layer-step-by-step')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('technique-layer-step-by-step')),
      findsOneWidget,
    );
    for (final diagramId in lesson.diagramIds) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('lesson-diagram-$diagramId')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(ValueKey('lesson-diagram-$diagramId')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.byKey(const ValueKey('technique-next-step')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('technique-step-title')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Waarom en bronnen'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('technique-layer-why-sources')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('technique-layer-why-sources')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('technique-references')),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('technique-references')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('technique filters count and clear real active filters', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const TechniqueLibraryScreen()));
    await tester.pump();

    expect(find.text('Filters'), findsOneWidget);
    await tester.tap(find.text('Basis').first);
    await tester.pump();
    expect(find.text('Filters (1 actief)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('technique-clear-filters')));
    await tester.pump();
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Filters (1 actief)'), findsNothing);
  });
}

Widget _app(Widget home, {MediaQueryData? mediaQueryData}) => MaterialApp(
  theme: ThemeData.from(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F6F8F)),
    useMaterial3: true,
  ),
  builder: mediaQueryData == null
      ? null
      : (context, child) => MediaQuery(
          data: mediaQueryData,
          child: child ?? const SizedBox.shrink(),
        ),
  home: home,
);
