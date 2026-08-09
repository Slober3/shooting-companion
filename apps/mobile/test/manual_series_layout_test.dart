import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/scoring/target_canvas.dart';
import 'package:shooting_companion/features/session/manual_series_screen.dart';
import 'package:shooting_companion/widgets/app_select_field.dart';

void main() {
  testWidgets(
    'immediate settings tap awaits catalogs and opens only once',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = ShootingRepository(database);
      await repository.seedDefaults();
      final quick = await repository.startQuickSession();
      final targets = await database.select(database.targetProfiles).get();
      final cartridges = await database.select(database.cartridges).get();
      final firearms = await database.select(database.firearms).get();
      final ammoLots = await database.select(database.ammoLots).get();
      final targetCatalog = Completer<List<TargetProfileRecord>>();
      final cartridgeCatalog = Completer<List<CartridgeRecord>>();
      final firearmCatalog = Completer<List<FirearmRecord>>();
      final ammoCatalog = Completer<List<AmmoLotRecord>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            allTargetProfilesProvider.overrideWith(
              (_) => targetCatalog.future.asStream(),
            ),
            allCartridgesProvider.overrideWith(
              (_) => cartridgeCatalog.future.asStream(),
            ),
            allFirearmsProvider.overrideWith(
              (_) => firearmCatalog.future.asStream(),
            ),
            allAmmoLotsProvider.overrideWith(
              (_) => ammoCatalog.future.asStream(),
            ),
          ],
          child: MaterialApp(
            home: ManualSeriesScreen(
              sessionId: quick.sessionId,
              seriesId: quick.draftSeriesId,
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      for (var attempt = 0; attempt < 30; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(TargetCanvas).evaluate().isNotEmpty) break;
      }

      expect(find.text('Wijzig'), findsOneWidget);
      await tester.tap(find.text('Wijzig'));
      await tester.tap(find.text('Wijzig'));
      await tester.pump();
      expect(find.text('Reeksinstellingen'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      targetCatalog.complete(targets);
      cartridgeCatalog.complete(cartridges);
      firearmCatalog.complete(firearms);
      ammoCatalog.complete(ammoLots);
      await tester.pumpAndSettle();

      expect(find.text('Reeksinstellingen'), findsOneWidget);
      expect(find.byType(AppSelectField<String>), findsNWidgets(2));
      expect(find.text('Keuze niet beschikbaar'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'manual editor keeps canvas and actions usable at 320 dp and 200 percent',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = ShootingRepository(database);
      await repository.seedDefaults();
      final quick = await repository.startQuickSession();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                padding: EdgeInsets.only(bottom: 48),
                viewPadding: EdgeInsets.only(bottom: 48),
                textScaler: TextScaler.linear(2),
              ),
              child: child!,
            ),
            home: ManualSeriesScreen(
              sessionId: quick.sessionId,
              seriesId: quick.draftSeriesId,
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      for (var attempt = 0; attempt < 30; attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(TargetCanvas).evaluate().isNotEmpty) break;
      }

      expect(find.byType(TargetCanvas), findsOneWidget);
      expect(
        tester.getSize(find.byType(TargetCanvas)).height,
        greaterThan(180),
      );
      await tester.tap(find.text('Precisie'));
      await tester.pump();
      await tester.tap(find.byTooltip('Punt op het precisiekruis plaatsen'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Punt 1'), findsOneWidget);
      final marker = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('scoring-marker-');
      });
      expect(marker, findsOneWidget);
      final originalMarkerCenter = tester.getCenter(marker);
      expect(
        (originalMarkerCenter - tester.getCenter(find.byType(TargetCanvas)))
            .distance,
        lessThan(1),
      );

      await tester.tap(find.byTooltip('Eén schot meer'));
      await tester.pump();
      expect(
        tester
            .widget<TargetCanvas>(find.byType(TargetCanvas))
            .impacts
            .single
            .multiplicity,
        2,
      );
      final targetRectBeforeUndo = tester.getRect(find.byType(TargetCanvas));
      final undoFinder = find
          .ancestor(
            of: find.byIcon(Icons.undo),
            matching: find.byType(IconButton),
          )
          .first;
      final undoCenterBefore = tester.getCenter(undoFinder);
      final undoButton = tester.widget<IconButton>(undoFinder);
      expect(undoButton.onPressed, isNotNull);
      undoButton.onPressed!();
      await tester.pump();
      expect(
        (tester.getCenter(marker) - originalMarkerCenter).distance,
        lessThan(1),
      );
      expect(
        tester
            .widget<TargetCanvas>(find.byType(TargetCanvas))
            .impacts
            .single
            .multiplicity,
        1,
      );
      expect(
        (tester.getCenter(undoFinder) - undoCenterBefore).distance,
        lessThanOrEqualTo(1),
      );
      final targetRectAfterUndo = tester.getRect(find.byType(TargetCanvas));
      expect(
        (targetRectAfterUndo.topLeft - targetRectBeforeUndo.topLeft).distance,
        lessThanOrEqualTo(1),
      );
      expect(
        (targetRectAfterUndo.bottomRight - targetRectBeforeUndo.bottomRight)
            .distance,
        lessThanOrEqualTo(1),
      );

      // A rapid second tap at the same screen coordinate must still hit undo,
      // never the canvas that used to shift underneath it.
      await tester.tapAt(undoCenterBefore);
      await tester.pump();
      expect(
        tester.widget<TargetCanvas>(find.byType(TargetCanvas)).impacts,
        isEmpty,
      );

      final save = find.widgetWithText(FilledButton, 'Bewaren');
      expect(save, findsOneWidget);
      expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(592));
      expect(find.byTooltip('Misser / 0 toevoegen'), findsOneWidget);
      expect(
        find.byTooltip('Laatste bewerking ongedaan maken'),
        findsOneWidget,
      );
      expect(find.byTooltip('Punten en missers'), findsOneWidget);
      expect(find.byTooltip('Foto toevoegen'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
