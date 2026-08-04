import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/library/library_screen.dart';

void main() {
  testWidgets(
    'library form validates required data and stays safe at large text',
    (tester) async {
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
            home: const LibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'bibliotheekoverzicht');

      await tester.tap(find.text('Wapens'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'wapenlijst');
      await tester.tap(find.byTooltip('Wapens toevoegen'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'wapenformulier');

      final saveButton = find.widgetWithText(FilledButton, 'Bewaren');
      expect(find.text('Wapenprofiel'), findsOneWidget);
      expect(saveButton, findsOneWidget);
      expect(tester.getBottomRight(saveButton).dy, lessThanOrEqualTo(640 - 48));

      await tester.tap(saveButton);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'validatiefout');
      expect(find.text('Vul een naam in'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Naam *'),
        '  Testpistool  ',
      );
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final records = await database.select(database.firearms).get();
      expect(records.any((record) => record.name == 'Testpistool'), isTrue);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    },
  );

  testWidgets('all library forms fit a narrow large-text screen', (
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
          home: const LibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final category in const ['Munitie', 'Schietstanden', 'Doelkaarten']) {
      await tester.scrollUntilVisible(
        find.text(category),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(category).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('$category toevoegen'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '$category-formulier');
      await tester.tap(find.byTooltip('Sluiten'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('custom target uses structured rings and a live preview', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 900);
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
              size: Size(412, 900),
              padding: EdgeInsets.only(bottom: 34),
              viewPadding: EdgeInsets.only(bottom: 34),
              textScaler: TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: const LibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Doelkaarten'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Doelkaarten'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Doelkaarten toevoegen'));
    await tester.pumpAndSettle();

    expect(find.text('Stap 1 van 3 · Basis'), findsOneWidget);
    expect(find.text('Ringen: score:diameter'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Naam *'),
      'Clubkaart',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Volgende'));
    await tester.pumpAndSettle();

    expect(find.text('Stap 2 van 3 · Scoringsringen'), findsOneWidget);
    expect(find.text('Ring toevoegen'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('target-ring-1-score')),
      '10',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Voorbeeld'));
    await tester.pump();
    expect(find.text('Deze score komt al voor'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(const ValueKey('target-ring-1-score')),
      '9',
    );
    await tester.enterText(
      find.byKey(const ValueKey('target-ring-1-diameter')),
      '40',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Voorbeeld'));
    await tester.pump();
    expect(find.text('Moet groter zijn dan de ring erboven'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('target-ring-1-diameter')),
      '600',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Voorbeeld'));
    await tester.pump();
    expect(find.text('Past niet binnen de kaart'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('target-ring-1-diameter')),
      '100',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Voorbeeld'));
    await tester.pumpAndSettle();

    expect(find.text('Stap 3 van 3 · Voorbeeld'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Voorbeeld van Clubkaart')),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Profiel maken'));
    await tester.pumpAndSettle();

    final profiles = await database.select(database.targetProfiles).get();
    expect(
      profiles.any(
        (profile) => !profile.builtIn && profile.displayName == 'Clubkaart',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);

    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('range distances preserve a Dutch decimal comma', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await ShootingRepository(database).seedDefaults();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: LibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Schietstanden'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Schietstanden toevoegen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Naam *'),
      'Decimale stand',
    );
    await tester.enterText(
      find.byKey(const ValueKey('range-distance-0')),
      '12,5',
    );
    await tester.tap(find.byTooltip('Afstand 2 verwijderen'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Bewaren'));
    await tester.pumpAndSettle();

    final record = (await database.select(database.ranges).get()).singleWhere(
      (item) => item.name == 'Decimale stand',
    );
    expect(jsonDecode(record.availableDistancesJson), [12.5]);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
