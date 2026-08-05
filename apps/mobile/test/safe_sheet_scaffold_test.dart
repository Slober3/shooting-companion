import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/widgets/app_action_dock.dart';
import 'package:shooting_companion/widgets/safe_sheet_scaffold.dart';

void main() {
  testWidgets(
    'safe sheet keeps its primary action above three-button navigation',
    (tester) async {
      await _pumpSheetHost(
        tester,
        mediaQueryData: const MediaQueryData(
          size: Size(320, 640),
          padding: EdgeInsets.only(bottom: 48),
          viewPadding: EdgeInsets.only(bottom: 48),
          textScaler: TextScaler.linear(2),
        ),
      );

      await tester.tap(find.text('Open formulier'));
      await tester.pumpAndSettle();

      final action = find.widgetWithText(FilledButton, 'Bewaren');
      expect(action, findsOneWidget);
      expect(tester.getBottomRight(action).dy, lessThanOrEqualTo(640 - 48));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('safe sheet moves fixed actions above the keyboard', (
    tester,
  ) async {
    await _pumpSheetHost(
      tester,
      mediaQueryData: const MediaQueryData(
        size: Size(320, 640),
        viewInsets: EdgeInsets.only(bottom: 260),
        viewPadding: EdgeInsets.only(bottom: 48),
        textScaler: TextScaler.linear(1.3),
      ),
    );

    await tester.tap(find.text('Open formulier'));
    await tester.pumpAndSettle();

    final action = find.widgetWithText(FilledButton, 'Bewaren');
    expect(action, findsOneWidget);
    expect(tester.getBottomRight(action).dy, lessThanOrEqualTo(640 - 260));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('safe sheet stays operable in landscape with the keyboard', (
    tester,
  ) async {
    await _pumpSheetHost(
      tester,
      mediaQueryData: const MediaQueryData(
        size: Size(640, 320),
        viewInsets: EdgeInsets.only(bottom: 120),
        viewPadding: EdgeInsets.only(bottom: 24),
        textScaler: TextScaler.linear(2),
      ),
    );

    await tester.tap(find.text('Open formulier'));
    await tester.pumpAndSettle();

    final action = find.widgetWithText(FilledButton, 'Bewaren');
    expect(action, findsOneWidget);
    expect(tester.getBottomRight(action).dy, lessThanOrEqualTo(320 - 120));
    expect(tester.takeException(), isNull);
  });

  testWidgets('adaptive form fields stack on a narrow large-text layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: AdaptiveFormRow(
                children: [
                  TextField(key: Key('first-field')),
                  TextField(key: Key('second-field')),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final first = tester.getTopLeft(find.byKey(const Key('first-field')));
    final second = tester.getTopLeft(find.byKey(const Key('second-field')));
    expect(second.dx, first.dx);
    expect(second.dy, greaterThan(first.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('action dock adds twelve dp above the system inset', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 640),
            padding: EdgeInsets.only(bottom: 48),
            viewPadding: EdgeInsets.only(bottom: 48),
          ),
          child: Scaffold(
            bottomNavigationBar: AppActionDock(
              actions: [FilledButton(onPressed: null, child: Text('Bewaren'))],
            ),
          ),
        ),
      ),
    );

    final surface = find.byKey(const ValueKey('app-action-dock-surface'));
    expect(surface, findsOneWidget);
    expect(tester.getBottomRight(surface).dy, closeTo(640 - 48 - 12, .01));
  });

  testWidgets('compact sheet stays content sized without a cancel footer', (
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
        builder: (context, child) => MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            padding: EdgeInsets.only(bottom: 48),
            viewPadding: EdgeInsets.only(bottom: 48),
            textScaler: TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showSafeModalSheet<void>(
                context: context,
                presentation: SafeSheetPresentation.compact,
                builder: (_) => const SafeSheetScaffold(
                  title: 'Foto toevoegen',
                  contentSized: true,
                  actions: [],
                  body: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.camera_alt),
                        title: Text('Camera'),
                      ),
                      ListTile(
                        leading: Icon(Icons.photo_library),
                        title: Text('Galerij'),
                      ),
                    ],
                  ),
                ),
              ),
              child: const Text('Open foto'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open foto'));
    await tester.pumpAndSettle();

    expect(find.text('Annuleren'), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('safe-sheet-surface'))).height,
      lessThan(500),
    );
    expect(tester.getBottomRight(find.text('Galerij')).dy, lessThan(640 - 48));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSheetHost(
  WidgetTester tester, {
  required MediaQueryData mediaQueryData,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = mediaQueryData.size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          MediaQuery(data: mediaQueryData, child: child!),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showSafeModalSheet<void>(
                context: context,
                builder: (_) => SafeSheetScaffold(
                  title: 'Lang formulier',
                  actions: const [
                    FilledButton(onPressed: null, child: Text('Bewaren')),
                    TextButton(onPressed: null, child: Text('Annuleren')),
                  ],
                  body: Column(
                    children: List.generate(
                      12,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Invoerveld ${index + 1}',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('Open formulier'),
            ),
          ),
        ),
      ),
    ),
  );
}
