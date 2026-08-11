import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/features/training_tools/shot_timer_screens.dart';

void main() {
  testWidgets('first and total only return a summary without fake shots', (
    tester,
  ) async {
    ShotTimerDraft? captured;
    await tester.pumpWidget(_testApp((value) => captured = value));

    await tester.tap(find.text('Externe timer openen'));
    await tester.pumpAndSettle();
    expect(find.text('Eerste schot'), findsOneWidget);
    expect(find.text('Totale tijd'), findsOneWidget);
    expect(find.text('Volledige schottijden (optioneel)'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('external-timer-first-shot')),
      '1,14',
    );
    await tester.enterText(
      find.byKey(const ValueKey('external-timer-total-time')),
      '4,72',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('external-timer-save')),
    );
    await tester.tap(find.byKey(const ValueKey('external-timer-save')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.result.events, isEmpty);
    expect(captured!.result.firstShotTime, const Duration(milliseconds: 1140));
    expect(captured!.result.totalTime, const Duration(milliseconds: 4720));
  });

  testWidgets('incomplete cumulative list stays visible with a clear error', (
    tester,
  ) async {
    ShotTimerDraft? captured;
    await tester.pumpWidget(_testApp((value) => captured = value));
    await tester.tap(find.text('Externe timer openen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('external-timer-first-shot')),
      '1,14',
    );
    await tester.enterText(
      find.byKey(const ValueKey('external-timer-total-time')),
      '4,72',
    );
    await tester.enterText(
      find.byKey(const ValueKey('external-timer-cumulative-times')),
      '1,14\n2,12\n4,50',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('external-timer-save')),
    );
    await tester.tap(find.byKey(const ValueKey('external-timer-save')));
    await tester.pumpAndSettle();

    expect(captured, isNull);
    expect(
      find.text('De laatste detailtijd moet gelijk zijn aan de totale tijd'),
      findsOneWidget,
    );
    expect(find.text('Externe timer'), findsOneWidget);
  });
}

Widget _testApp(ValueChanged<ShotTimerDraft> onResult) => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<ShotTimerDraft>(
              MaterialPageRoute(
                builder: (_) => const ExternalTimerEntryScreen(),
              ),
            );
            if (result != null) onResult(result);
          },
          child: const Text('Externe timer openen'),
        ),
      ),
    ),
  ),
);
