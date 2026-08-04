import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/widgets/app_select_field.dart';

void main() {
  testWidgets('selected option has contrast, weight and a check mark', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3F6F8F),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => AppSelectField<String>(
              label: 'Kaliber',
              initialValue: '22',
              options: const [
                AppSelectOption(value: '22', label: '.22 LR'),
                AppSelectOption(value: '9', label: '9×19 mm'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('.22 LR'));
    await tester.pumpAndSettle();

    final selectedTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, '.22 LR'),
    );
    final scheme = Theme.of(
      tester.element(find.byType(ListTile).first),
    ).colorScheme;
    expect(selectedTile.tileColor, scheme.secondaryContainer);
    expect(selectedTile.textColor, scheme.onSecondaryContainer);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect((selectedTile.title! as Text).style?.fontWeight, FontWeight.w700);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long option lists expose search without losing selection', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => AppSelectField<int>(
              label: 'Stand',
              initialValue: selected,
              options: List.generate(
                9,
                (index) =>
                    AppSelectOption(value: index, label: 'Schietstand $index'),
              ),
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Schietstand 0'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Zoeken'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Zoeken'), '8');
    await tester.pump();
    await tester.tap(find.text('Schietstand 8'));
    await tester.pumpAndSettle();
    expect(selected, 8);
  });
}
