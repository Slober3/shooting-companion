import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/features/more/data_transfer_screen.dart';

void main() {
  testWidgets('backup password sheet validates inline and can reveal input', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: BackupRestoreScreen()),
      ),
    );

    await tester.tap(find.text('Nieuwe back-up maken'));
    await tester.pumpAndSettle();

    final submit = find.widgetWithText(FilledButton, 'Back-up maken');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(find.byTooltip('Wachtwoord tonen'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'kort');
    await tester.enterText(fields.at(1), 'anders');
    await tester.pump();
    expect(find.text('Gebruik minstens 10 tekens.'), findsOneWidget);
    expect(find.text('De wachtwoorden komen niet overeen.'), findsOneWidget);

    await tester.tap(find.byTooltip('Wachtwoord tonen'));
    await tester.pump();
    expect(find.byTooltip('Wachtwoord verbergen'), findsOneWidget);

    await tester.enterText(fields.at(0), 'veilig-passwoord');
    await tester.enterText(fields.at(1), 'veilig-passwoord');
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
