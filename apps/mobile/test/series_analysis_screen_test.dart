import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shooting_companion/app/providers.dart';
import 'package:shooting_companion/data/app_database.dart';
import 'package:shooting_companion/data/shooting_repository.dart';
import 'package:shooting_companion/features/progress/group_analysis_widgets.dart';
import 'package:shooting_companion/features/progress/series_analysis_screen.dart';
import 'package:shooting_companion/features/progress/session_analysis_screen.dart';
import 'package:shooting_companion/features/session/series_detail_screen.dart';
import 'package:shooting_companion_analysis/analysis.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';

void main() {
  setUpAll(() => initializeDateFormatting('nl_BE'));

  testWidgets('series detail exposes a compact full-analysis entry point', (
    tester,
  ) async {
    final fixture = await _createIssfFixture();
    addTearDown(fixture.database.close);

    await _pumpDatabaseScreen(
      tester,
      database: fixture.database,
      home: SeriesDetailScreen(seriesId: fixture.firstSeriesId),
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('series-group-summary-card')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Trefbeeld'), findsOneWidget);
    expect(find.text('Volledige analyse'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('open-full-series-analysis')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-full-series-analysis')));
    await _pumpStreams(tester);

    expect(find.text('Reeksanalyse'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('series-analysis-context')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'contextual analysis switches modes and navigates within session',
    (tester) async {
      final fixture = await _createIssfFixture();
      addTearDown(fixture.database.close);

      await _pumpDatabaseScreen(
        tester,
        database: fixture.database,
        home: SeriesAnalysisScreen(seriesId: fixture.firstSeriesId),
      );

      expect(find.text('Reeks 1'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('series-analysis-context')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('series-analysis-group-view')),
        findsOneWidget,
      );

      await tester.tap(find.text('Warmte'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('series-analysis-heatmap-view')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('next-series-analysis')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
      await tester.pumpAndSettle();
      expect(find.text('Databasis'), findsOneWidget);
      expect(find.text('Potential score'), findsOneWidget);
      expect(find.text('Reeks 1 van 2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('next-series-analysis')));
      await _pumpStreams(tester);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SeriesAnalysisScreen &&
              widget.seriesId == fixture.secondSeriesId,
        ),
        findsOneWidget,
      );
      await tester.dragUntilVisible(
        find.text('Reeks 2 van 2'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      expect(find.text('Reeks 2 van 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('angle metrics expose their plain-language explanation', (
    tester,
  ) async {
    final fixture = await _createIssfFixture();
    addTearDown(fixture.database.close);

    await _pumpDatabaseScreen(
      tester,
      database: fixture.database,
      home: SeriesAnalysisScreen(seriesId: fixture.firstSeriesId),
    );

    await tester.scrollUntilVisible(
      find.text('Meer groepsmaten'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Meer groepsmaten'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Spreiding in MOA'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Spreiding in MOA'));
    await tester.pumpAndSettle();

    expect(find.text('Wat meet dit?'), findsOneWidget);
    expect(find.textContaining('minutes of angle'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'long analysis metrics stay readable across narrow widths and text scales',
    (tester) async {
      final fixture = await _createIssfFixture();
      addTearDown(fixture.database.close);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      const configurations = <({double width, double textScale})>[
        (width: 320, textScale: 1),
        (width: 320, textScale: 1.3),
        (width: 320, textScale: 2),
        (width: 360, textScale: 1),
        (width: 360, textScale: 1.3),
        (width: 360, textScale: 2),
        (width: 412, textScale: 1),
        (width: 412, textScale: 1.3),
        (width: 412, textScale: 2),
      ];

      for (final configuration in configurations) {
        tester.view.physicalSize = Size(configuration.width, 1200);
        await _pumpDatabaseScreen(
          tester,
          database: fixture.database,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(configuration.width, 1200),
              textScaler: TextScaler.linear(configuration.textScale),
            ),
            child: KeyedSubtree(
              key: ValueKey(
                'analysis-${configuration.width}-${configuration.textScale}',
              ),
              child: SeriesAnalysisScreen(seriesId: fixture.firstSeriesId),
            ),
          ),
        );

        await tester.scrollUntilVisible(
          find.text('Meer groepsmaten'),
          260,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Meer groepsmaten'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Meer groepsmaten'));
        await tester.pumpAndSettle();
        final stackedLayout = find.byKey(
          const ValueKey('metric-row-layout-stacked-Richting spreidingsellips'),
        );
        await tester.scrollUntilVisible(
          stackedLayout,
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(stackedLayout);
        await tester.pumpAndSettle();

        expect(stackedLayout, findsOneWidget);
        final value = tester.widget<Text>(
          find.byKey(
            const ValueKey('metric-row-value-Richting spreidingsellips'),
          ),
        );
        expect(value.data, contains('° · '));
        expect(value.maxLines, isNull);
        expect(tester.takeException(), isNull);
      }

      tester.view.physicalSize = const Size(800, 1200);
      await _pumpDatabaseScreen(
        tester,
        database: fixture.database,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 1200)),
          child: SeriesAnalysisScreen(seriesId: fixture.firstSeriesId),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Meer groepsmaten'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Meer groepsmaten'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meer groepsmaten'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('metric-row-layout-compact-Spreiding in MOA'),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('responsive metric row remains one explanation action', (
    tester,
  ) async {
    final fixture = await _createIssfFixture();
    addTearDown(fixture.database.close);
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await _pumpDatabaseScreen(
      tester,
      database: fixture.database,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 800),
          textScaler: TextScaler.linear(2),
        ),
        child: SeriesAnalysisScreen(seriesId: fixture.firstSeriesId),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Meer groepsmaten'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Meer groepsmaten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meer groepsmaten'));
    await tester.pumpAndSettle();
    final metricRow = find.byKey(
      const ValueKey('metric-row-Richting spreidingsellips'),
    );
    await tester.scrollUntilVisible(
      metricRow,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(metricRow);
    await tester.pumpAndSettle();
    final semanticsRow = find.bySemanticsLabel(
      RegExp('Richting spreidingsellips: .*Open uitleg'),
    );
    expect(semanticsRow, findsOneWidget);
    expect(
      tester
          .getSemantics(semanticsRow)
          .getSemanticsData()
          .hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(metricRow);
    await tester.pumpAndSettle();

    expect(find.text('Wat meet dit?'), findsOneWidget);
    expect(find.textContaining('spreidingsellips'), findsWidgets);
    expect(tester.takeException(), isNull);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('contextual potential score uses the sendable worker', (
    tester,
  ) async {
    final fixture = await _createIssfFixture();
    addTearDown(fixture.database.close);

    await _pumpDatabaseScreen(
      tester,
      database: fixture.database,
      home: SeriesAnalysisScreen(seriesId: fixture.firstSeriesId),
    );

    await tester.scrollUntilVisible(
      find.text('Potential score berekenen'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Potential score berekenen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Potential score berekenen'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('→'), findsOneWidget);
    expect(find.textContaining('object is unsendable'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('group plot explains inclusion and exposes display controls', (
    tester,
  ) async {
    final analysis = GroupAnalyzer.analyze(
      seriesId: 'explained-group',
      targetProfile: IssfTargetProfiles.precision25m50m,
      distanceMeters: 25,
      impacts: const [
        ShotImpact(id: 'a', xMm: -5, yMm: 0),
        ShotImpact(id: 'b', xMm: 0, yMm: 1, multiplicity: 2),
        ShotImpact(id: 'c', xMm: 6, yMm: -1),
        ShotImpact(id: 'far', xMm: 50, yMm: 10),
        ShotImpact(id: 'miss', xMm: 0, yMm: 0, isMiss: true),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GroupAnalysisPlot(analysis: analysis),
          ),
        ),
      ),
    );

    expect(find.text('Weergave'), findsOneWidget);
    expect(find.text('1σ-ellips'), findsOneWidget);
    expect(find.text('Extreme spreiding'), findsOneWidget);
    expect(find.textContaining('treffers erbuiten tellen mee'), findsOneWidget);
    expect(find.textContaining('markerposities'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('group-data-summary')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-data-summary')));
    await tester.pumpAndSettle();
    expect(find.text('Gebruikte gegevens'), findsOneWidget);
    expect(find.textContaining('niet automatisch als outlier'), findsOneWidget);
    expect(find.text('Missers zonder positie'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi-bull data basis explains local bull normalization', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    final target = WrabfTargetProfiles.rimfire50mBr50;
    final first = target.recordBulls[0];
    final second = target.recordBulls[1];
    final analysis = GroupAnalyzer.analyze(
      seriesId: 'br50-series',
      targetProfile: target,
      distanceMeters: 50,
      impacts: [
        ShotImpact(
          id: 'br50-1',
          xMm: first.centerXMm + 1,
          yMm: first.centerYMm - 2,
          targetBullId: first.id,
        ),
        ShotImpact(
          id: 'br50-2',
          xMm: second.centerXMm + 1,
          yMm: second.centerYMm - 2,
          targetBullId: second.id,
        ),
      ],
    );

    expect(analysis.positions.map((position) => position.xMm), everyElement(1));
    expect(
      analysis.positions.map((position) => position.yMm),
      everyElement(-2),
    );

    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GroupAnalysisPlot(analysis: analysis, showDensity: true),
                const SizedBox(height: 16),
                AnalysisDataBasisCard(analysis: analysis, isMultiBull: true),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.textContaining('Multi-bullnormalisatie'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Multi-bullnormalisatie'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Trefbeeld met 2 positionele schoten')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('session analysis compares individual series in one visit', (
    tester,
  ) async {
    final fixture = await _createIssfFixture();
    addTearDown(fixture.database.close);

    await _pumpDatabaseScreen(
      tester,
      database: fixture.database,
      home: SessionAnalysisScreen(sessionId: fixture.sessionId),
    );

    expect(find.text('Sessieanalyse'), findsOneWidget);
    expect(find.text('Vergelijk reeksen'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text('Gezamenlijke gemiddelde radius'), findsOneWidget);

    await tester.tap(find.byTooltip('Volledige analyse van reeks 1'));
    await _pumpStreams(tester);
    expect(find.text('Reeksanalyse'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Future<_IssfFixture> _createIssfFixture() async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final repository = ShootingRepository(database);
  await repository.seedDefaults();
  final defaults = SeriesDefaults(
    target: IssfTargetProfiles.precision25m50m,
    distanceMeters: 25,
    projectileDiameterMm: CartridgePresets.twentyTwoLr.projectileDiameterMm,
    cartridgeId: CartridgePresets.twentyTwoLr.id,
  );
  final quick = await repository.startQuickSession(defaults: defaults);
  await _saveAndConfirm(
    repository,
    seriesId: quick.draftSeriesId,
    impacts: const [
      ShotImpact(id: 'first-1', xMm: -8, yMm: 3),
      ShotImpact(id: 'first-2', xMm: -3, yMm: 1),
      ShotImpact(id: 'first-3', xMm: 0, yMm: 0),
      ShotImpact(id: 'first-4', xMm: 4, yMm: -2),
      ShotImpact(id: 'first-5', xMm: 7, yMm: -3),
    ],
  );
  final second = await repository.createOrResumeDraftSeries(quick.sessionId);
  await _saveAndConfirm(
    repository,
    seriesId: second,
    impacts: const [
      ShotImpact(id: 'second-1', xMm: 10, yMm: 4),
      ShotImpact(id: 'second-2', xMm: 12, yMm: 2),
      ShotImpact(id: 'second-3', xMm: 14, yMm: 0),
      ShotImpact(id: 'second-4', xMm: 16, yMm: -2),
      ShotImpact(id: 'second-5', xMm: 18, yMm: -4),
    ],
  );
  return _IssfFixture(
    database: database,
    sessionId: quick.sessionId,
    firstSeriesId: quick.draftSeriesId,
    secondSeriesId: second,
  );
}

Future<void> _saveAndConfirm(
  ShootingRepository repository, {
  required String seriesId,
  required List<ShotImpact> impacts,
}) async {
  await repository.saveSeriesDraft(
    seriesId: seriesId,
    target: IssfTargetProfiles.precision25m50m,
    distanceMeters: 25,
    projectileDiameterMm: CartridgePresets.twentyTwoLr.projectileDiameterMm,
    cartridgeId: CartridgePresets.twentyTwoLr.id,
    impacts: impacts,
  );
  await repository.confirmSeries(seriesId);
}

Future<void> _pumpDatabaseScreen(
  WidgetTester tester, {
  required AppDatabase database,
  required Widget home,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: MaterialApp(theme: ThemeData(useMaterial3: true), home: home),
    ),
  );
  await _pumpStreams(tester);
}

Future<void> _pumpStreams(WidgetTester tester) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}

class _IssfFixture {
  const _IssfFixture({
    required this.database,
    required this.sessionId,
    required this.firstSeriesId,
    required this.secondSeriesId,
  });

  final AppDatabase database;
  final String sessionId;
  final String firstSeriesId;
  final String secondSeriesId;
}
