import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/features/more/about_screen.dart';
import 'package:shooting_companion/features/more/more_screen.dart';
import 'package:shooting_companion/features/settings/settings_screen.dart';

void main() {
  testWidgets('settings defers storage work and does not duplicate privacy', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Opslagdetails'), findsOneWidget);
    expect(find.text('Volledig offline'), findsNothing);
    expect(find.text('Privéfoto’s'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('More exposes a dedicated Over en privacy destination', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MoreScreen()));

    expect(find.text('Over en privacy'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Over en privacy'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Volledig offline'), findsOneWidget);
    expect(find.text('Privéfoto’s'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Trainingshulpmiddel'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Trainingshulpmiddel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
