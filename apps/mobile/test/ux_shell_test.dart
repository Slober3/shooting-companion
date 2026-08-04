import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/features/more/more_screen.dart';
import 'package:shooting_companion/features/shell/home_shell.dart';
import 'package:shooting_companion/widgets/compact_page_scaffold.dart';
import 'package:shooting_companion/widgets/responsive_metric_grid.dart';
import 'package:shooting_companion/widgets/safe_bottom_action_bar.dart';

void main() {
  testWidgets('home navigation hides labels at very large text scale', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(320, 640));
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            bottomNavigationBar: HomeNavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (value) => selected = value,
            ),
          ),
        ),
      ),
    );
    final semantics = tester.ensureSemantics();

    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      navigation.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysHide,
    );
    expect(find.bySemanticsLabel(RegExp('Logboek')), findsWidgets);
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    expect(selected, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('metric grid remains readable at 320 dp and 200 percent text', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(320, 640));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: ResponsiveMetricGrid(
                  items: [
                    MetricItem(label: 'Reeksen', value: '23'),
                    MetricItem(label: 'Schoten', value: '127'),
                    MetricItem(label: 'Gemiddeld', value: '86,4%'),
                    MetricItem(label: 'Beste', value: '94,0%'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Gemiddeld'), findsOneWidget);
    expect(find.text('94,0%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom actions stay above the system navigation inset', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(400, 800));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            padding: EdgeInsets.only(bottom: 32),
          ),
          child: Scaffold(
            bottomNavigationBar: SafeBottomActionBar(
              actions: [
                FilledButton(onPressed: () {}, child: const Text('Bewaren')),
              ],
            ),
          ),
        ),
      ),
    );

    final buttonBottom = tester.getBottomRight(find.text('Bewaren')).dy;
    expect(buttonBottom, lessThan(800 - 32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('more screen and compact app bar do not overflow', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(320, 640));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: const MoreScreen(),
        ),
      ),
    );

    expect(find.byType(CompactPageScaffold), findsOneWidget);
    expect(find.text('Bibliotheek'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Back-up en herstel'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Back-up en herstel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _setSurfaceSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}
