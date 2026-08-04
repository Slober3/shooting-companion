import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/scoring/target_canvas.dart';
import 'package:shooting_companion/features/scoring/transformable_scoring_viewport.dart';
import 'package:shooting_companion/features/session/manual_series_screen.dart';

void main() {
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

      await tester.tap(find.byIcon(Icons.edit_location_alt_outlined));
      await tester.pump();
      expect(
        tester
            .widget<SegmentedButton<ScoringTool>>(
              find.byType(SegmentedButton<ScoringTool>),
            )
            .selected,
        {ScoringTool.edit},
      );
      final drag = await tester.startGesture(originalMarkerCenter);
      await drag.moveBy(const Offset(30, 0));
      await drag.up();
      await tester.pump();
      expect(
        (tester.getCenter(marker) - originalMarkerCenter).distance,
        greaterThan(20),
      );
      final undoButton = tester.widget<IconButton>(
        find
            .ancestor(
              of: find.byIcon(Icons.undo),
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(undoButton.onPressed, isNotNull);
      undoButton.onPressed!();
      await tester.pump();
      expect(
        (tester.getCenter(marker) - originalMarkerCenter).distance,
        lessThan(1),
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
