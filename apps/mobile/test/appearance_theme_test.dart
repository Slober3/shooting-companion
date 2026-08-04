import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/app.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/app/theme.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/appearance_repository.dart';
import 'package:shooting_companion/features/settings/appearance_settings_screen.dart';

void main() {
  test('all palettes build light and dark themes with contrast tokens', () {
    final primaryColours = <Color>{};

    for (final palette in AppearancePalette.values) {
      final light = AppTheme.light(palette);
      final dark = AppTheme.dark(palette);
      primaryColours.add(light.colorScheme.primary);

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.extension<AppContrastTokens>(), isNotNull);
      expect(dark.extension<AppContrastTokens>(), isNotNull);
      expect(
        light.extension<AppContrastTokens>()!.markerOutline,
        isNot(light.scaffoldBackgroundColor),
      );
      expect(
        dark.extension<AppContrastTokens>()!.markerOutline,
        isNot(dark.scaffoldBackgroundColor),
      );
    }

    expect(primaryColours, hasLength(AppearancePalette.values.length));
  });

  testWidgets('appearance screen persists a selection at large text scale', (
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: AppearanceSettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Systeem'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Donker'),
      120,
      scrollable: find.byType(Scrollable),
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Donker')),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.tap(find.text('Donker'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Staalblauw'),
      120,
      scrollable: find.byType(Scrollable),
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Staalblauw')),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.tap(find.text('Staalblauw'));
    await tester.pumpAndSettle();

    final settings = await AppearanceRepository(database).readSettings();
    expect(settings.mode, AppearanceMode.dark);
    expect(settings.palette, AppearancePalette.steelBlue);
    expect(tester.takeException(), isNull);

    // Dispose the provider stream while fake time can still flush Drift's
    // zero-duration stream-query cleanup timer.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('app root applies persisted appearance changes live', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const ShootingCompanionApp(),
      ),
    );
    await tester.pumpAndSettle();

    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);

    await AppearanceRepository(database).save(
      const AppearanceSettings(
        mode: AppearanceMode.dark,
        palette: AppearancePalette.highContrast,
      ),
    );
    await tester.pumpAndSettle();

    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(
      app.theme!.colorScheme.primary,
      AppTheme.light(AppearancePalette.highContrast).colorScheme.primary,
    );
    expect(
      app.darkTheme!.colorScheme.primary,
      AppTheme.dark(AppearancePalette.highContrast).colorScheme.primary,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
