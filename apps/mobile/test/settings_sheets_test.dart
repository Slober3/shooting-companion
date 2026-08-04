import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/session/series_settings_sheet.dart';
import 'package:shooting_companion/features/session/session_edit_sheet.dart';
import 'package:shooting_companion_domain/domain.dart';

void main() {
  testWidgets('session edit sheet remains usable with large text and insets', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ShootingRepository(database);
    await repository.seedDefaults();
    final quick = await repository.startQuickSession();
    final session = (await database.select(database.trainingSessions).get())
        .singleWhere((record) => record.id == quick.sessionId);
    final ranges = await database.select(database.ranges).get();

    await _pumpHost(
      tester,
      label: 'Sessie wijzigen',
      onOpen: (context) => showSessionEditSheet(
        context: context,
        session: session,
        ranges: ranges,
      ),
    );
    await tester.tap(find.text('Sessie wijzigen'));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(FilledButton, 'Wijzigingen bewaren');
    expect(save, findsOneWidget);
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(640 - 48));
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  testWidgets('series settings stacks inputs and validates distance', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ShootingRepository(database);
    await repository.seedDefaults();
    final targets = await database.select(database.targetProfiles).get();
    final cartridges = await database.select(database.cartridges).get();
    final firearms = await database.select(database.firearms).get();
    final ammoLots = await database.select(database.ammoLots).get();

    await _pumpHost(
      tester,
      label: 'Reeks wijzigen',
      onOpen: (context) => showSeriesSettingsSheet(
        context: context,
        initial: SeriesSettingsValues(
          target: TargetProfile.fromJsonString(targets.first.profileJson),
          cartridgeId: cartridges.first.id,
          distanceMeters: 25,
        ),
        targets: targets,
        cartridges: cartridges,
        firearms: firearms,
        ammoLots: ammoLots,
      ),
    );
    await tester.tap(find.text('Reeks wijzigen'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final distanceField = find.widgetWithText(TextFormField, 'Afstand');
    await tester.enterText(distanceField, '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Toepassen'));
    await tester.pump();

    expect(find.text('Vul een geldige afstand in'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required String label,
  required Future<Object?> Function(BuildContext context) onOpen,
}) async {
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
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => onOpen(context),
              child: Text(label),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
}
