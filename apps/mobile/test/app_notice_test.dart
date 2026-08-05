import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/theme.dart';
import 'package:shooting_companion/widgets/app_action_dock.dart';
import 'package:shooting_companion/widgets/app_notice.dart';

void main() {
  testWidgets('notice is floating, dismissible and not duplicated', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          bottomNavigationBar: const SizedBox(height: 80),
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                AppMessenger.show(
                  context,
                  kind: AppNoticeKind.success,
                  message: 'Sessie beëindigd',
                );
              },
              child: const Text('Melding'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Melding'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Melding'));
    await tester.pumpAndSettle();

    expect(find.text('Sessie beëindigd'), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.showCloseIcon, isTrue);
    expect(
      tester.getBottomRight(find.text('Sessie beëindigd')).dy,
      lessThan(560 - 12),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Sessie beëindigd'), findsNothing);
  });

  testWidgets('short dock actions stay beside each other without wrapping', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          bottomNavigationBar: AppActionDock(
            actions: [
              Semantics(
                label: 'Actieve sessie beëindigen',
                button: true,
                child: const OutlinedButton(
                  onPressed: null,
                  child: Text('Beëindigen', maxLines: 1),
                ),
              ),
              Semantics(
                label: 'Nieuwe reeks starten',
                button: true,
                child: const FilledButton(
                  onPressed: null,
                  child: Text('Nieuwe reeks', maxLines: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final semantics = tester.ensureSemantics();

    final first = tester.getRect(find.text('Beëindigen'));
    final second = tester.getRect(find.text('Nieuwe reeks'));
    expect((second.top - first.top).abs(), lessThanOrEqualTo(1));
    expect(first.height, lessThan(30));
    expect(second.height, lessThan(30));
    expect(find.bySemanticsLabel('Actieve sessie beëindigen'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
