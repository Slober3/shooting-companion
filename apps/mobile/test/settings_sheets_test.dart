import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/session/series_settings_sheet.dart';
import 'package:shooting_companion/features/session/session_edit_sheet.dart';
import 'package:shooting_companion/widgets/app_expandable_section.dart';
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
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notities'),
      'Bewaarde wijziging',
    );
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Sessie wijzigen'), findsOneWidget);
    expect(find.text('Wijzigingen niet bewaren?'), findsNothing);
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

  testWidgets('series settings keeps snapshot target when catalog omits it', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ShootingRepository(database);
    await repository.seedDefaults();
    final targetRecord =
        (await database.select(database.targetProfiles).get()).first;
    final target = TargetProfile.fromJsonString(targetRecord.profileJson);
    final cartridges = await database.select(database.cartridges).get();

    await _pumpHost(
      tester,
      label: 'Historische reeks wijzigen',
      onOpen: (context) => showSeriesSettingsSheet(
        context: context,
        initial: SeriesSettingsValues(
          target: target,
          cartridgeId: cartridges.first.id,
          distanceMeters: 25,
        ),
        targets: const [],
        cartridges: cartridges,
        firearms: const [],
        ammoLots: const [],
      ),
    );
    await tester.tap(find.text('Historische reeks wijzigen'));
    await tester.pumpAndSettle();

    expect(find.text('${target.displayName} (historisch)'), findsOneWidget);
    expect(find.text('Keuze niet beschikbaar'), findsNothing);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  testWidgets(
    'expanded session details have breathing room and focused field stays visible',
    (tester) async {
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
        label: 'Details wijzigen',
        mediaQueryData: const MediaQueryData(
          size: Size(360, 800),
          padding: EdgeInsets.only(bottom: 24),
          viewPadding: EdgeInsets.only(bottom: 24),
          viewInsets: EdgeInsets.only(bottom: 280),
          textScaler: TextScaler.linear(1.3),
        ),
        onOpen: (context) => showSessionEditSheet(
          context: context,
          session: session,
          ranges: ranges,
        ),
      );
      await tester.tap(find.text('Details wijzigen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meer details'));
      await tester.pumpAndSettle();

      final section = find.byType(AppExpandableSection);
      final goal = find.widgetWithText(TextFormField, 'Trainingsdoel');
      final conditions = find.widgetWithText(TextFormField, 'Omstandigheden');
      expect(section, findsOneWidget);
      expect(goal, findsOneWidget);
      expect(conditions, findsOneWidget);
      expect(
        tester.getTopLeft(goal).dy -
            tester.getBottomLeft(find.text('Meer details')).dy,
        greaterThanOrEqualTo(12),
      );
      expect(
        tester.getBottomLeft(section).dy - tester.getBottomLeft(conditions).dy,
        greaterThanOrEqualTo(20),
      );

      await tester.ensureVisible(goal);
      await tester.pump();
      await tester.tap(goal);
      await tester.pump(const Duration(milliseconds: 320));
      final dockTop = tester
          .getTopLeft(find.byKey(const ValueKey('app-action-dock-surface')))
          .dy;
      expect(tester.getTopLeft(goal).dy, greaterThanOrEqualTo(kToolbarHeight));
      expect(tester.getBottomLeft(goal).dy, lessThanOrEqualTo(dockTop));
      expect(tester.takeException(), isNull);
      await _disposeTree(tester);
    },
  );

  testWidgets('series settings rebuild keeps selected ammunition profile', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = ShootingRepository(database);
    await repository.seedDefaults();
    final targets = await database.select(database.targetProfiles).get();
    final cartridges = await database.select(database.cartridges).get();
    final cartridge = cartridges.first;
    final ammoId = await repository.addAmmoLot(
      cartridgeId: cartridge.id,
      displayName: 'Precisielot',
    );
    final ammoLots = await database.select(database.ammoLots).get();

    await _pumpHost(
      tester,
      label: 'Munitie wijzigen',
      onOpen: (context) => showSeriesSettingsSheet(
        context: context,
        initial: SeriesSettingsValues(
          target: TargetProfile.fromJsonString(targets.first.profileJson),
          cartridgeId: cartridge.id,
          distanceMeters: 25,
          ammoLotId: ammoId,
        ),
        targets: targets,
        cartridges: cartridges,
        firearms: const [],
        ammoLots: ammoLots,
      ),
    );
    await tester.tap(find.text('Munitie wijzigen'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Materiaal en notitie'));
    await tester.pump();
    await tester.tap(find.text('Materiaal en notitie'));
    await tester.pumpAndSettle();
    expect(find.text('Precisielot'), findsOneWidget);

    final notes = find.widgetWithText(
      TextFormField,
      'Reeksnotitie (optioneel)',
    );
    await tester.ensureVisible(notes);
    await tester.pump();
    await tester.enterText(notes, 'Rebuild zonder munitiewijziging');
    await tester.pump();

    expect(find.text('Precisielot'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required String label,
  required Future<Object?> Function(BuildContext context) onOpen,
  MediaQueryData mediaQueryData = const MediaQueryData(
    size: Size(320, 640),
    padding: EdgeInsets.only(bottom: 48),
    viewPadding: EdgeInsets.only(bottom: 48),
    textScaler: TextScaler.linear(2),
  ),
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
