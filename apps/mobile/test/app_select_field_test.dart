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

  testWidgets('missing selection keeps label and fallback separated', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSelectField<String>(
            label: 'Doelkaart',
            initialValue: 'historisch-doel',
            options: const [],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final label = find.text('Doelkaart');
    final fallback = find.text('Keuze niet beschikbaar');
    expect(label, findsOneWidget);
    expect(fallback, findsOneWidget);
    expect(find.text('Kies een geldige optie'), findsOneWidget);
    expect(tester.getRect(label).overlaps(tester.getRect(fallback)), isFalse);

    final formField = tester.state<FormFieldState<String>>(
      find.byType(AppSelectField<String>),
    );
    expect(formField.validate(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external value changes update the visible selection', (
    tester,
  ) async {
    var selected = '22';
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Scaffold(
              body: AppSelectField<String>(
                label: 'Kaliber',
                initialValue: selected,
                options: const [
                  AppSelectOption(value: '22', label: '.22 LR'),
                  AppSelectOption(value: '9', label: '9×19 mm'),
                ],
                onChanged: (_) {},
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('.22 LR'), findsOneWidget);
    rebuild(() => selected = '9');
    await tester.pump();
    expect(find.text('9×19 mm'), findsOneWidget);
    expect(find.text('.22 LR'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an explicit optional null option remains valid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: AppSelectField<String?>(
              label: 'Wapen',
              initialValue: null,
              options: const [
                AppSelectOption<String?>(value: null, label: 'Niet opgegeven'),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final state = tester.state<FormFieldState<String?>>(
      find.byType(AppSelectField<String?>),
    );
    expect(state.validate(), isTrue);
    expect(find.text('Niet opgegeven'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
