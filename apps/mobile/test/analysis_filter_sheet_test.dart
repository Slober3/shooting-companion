import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/progress/progress_screen.dart';

void main() {
  testWidgets('analysis filters keep both actions visible at large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await ShootingRepository(database).seedDefaults();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              padding: EdgeInsets.only(bottom: 48),
              viewPadding: EdgeInsets.only(bottom: 48),
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: const ProgressScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'analyse in portret');

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();

    final apply = find.widgetWithText(FilledButton, 'Filters toepassen');
    expect(find.text('Analysefilters'), findsOneWidget);
    expect(apply, findsOneWidget);
    expect(find.text('Alles wissen'), findsOneWidget);
    expect(tester.getBottomRight(apply).dy, lessThanOrEqualTo(640 - 48));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('analysis filters fit landscape above the keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 320);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await ShootingRepository(database).seedDefaults();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(640, 320),
              viewInsets: EdgeInsets.only(bottom: 120),
              viewPadding: EdgeInsets.only(bottom: 24),
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: const ProgressScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'analyse in landschap');

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();

    final apply = find.widgetWithText(FilledButton, 'Filters toepassen');
    expect(apply, findsOneWidget);
    expect(find.text('Alles wissen'), findsOneWidget);
    expect(tester.getBottomRight(apply).dy, lessThanOrEqualTo(320 - 120));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
