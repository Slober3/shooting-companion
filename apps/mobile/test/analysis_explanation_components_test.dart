import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/features/progress/analysis_explanations.dart';
import 'package:shooting_companion/features/progress/group_analysis_widgets.dart';
import 'package:shooting_companion/widgets/responsive_metric_grid.dart';
import 'package:shooting_companion_analysis/analysis.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_target_profiles/target_profiles.dart';

void main() {
  group('metric definitions', () {
    test('registry contains one complete definition for every metric', () {
      expect(
        MetricDefinitions.values.map((definition) => definition.id).toSet(),
        AnalysisMetricId.values.toSet(),
      );
      for (final definition in MetricDefinitions.values) {
        expect(definition.label, isNotEmpty);
        expect(definition.shortDescription, isNotEmpty);
        expect(definition.calculation, isNotEmpty);
        expect(definition.interpretation, isNotEmpty);
        expect(definition.dataRequirement, isNotEmpty);
        expect(definition.limitations, isNotEmpty);
      }
    });

    test('what-if and subgroup definitions state their safety boundary', () {
      expect(
        MetricDefinitions.potentialScore.limitations.join(' '),
        contains('geen voorspelling of garantie'),
      );
      expect(
        MetricDefinitions.subgroupDetection.limitations.join(' '),
        contains('geen bewezen flyer'),
      );
      expect(
        MetricDefinitions.subgroupDetection.limitations.join(' '),
        contains('veranderen nooit'),
      );
    });
  });

  group('analysis evidence', () {
    test('maps engine reliability to restrained user-facing labels', () {
      final provisional = AnalysisEvidence.fromReliability(
        reliability: AnalysisReliability.provisional,
        actualShotCount: 5,
        positionedShotCount: 4,
        seriesCount: 1,
      );
      final full = AnalysisEvidence.fromReliability(
        reliability: AnalysisReliability.full,
        actualShotCount: 10,
        positionedShotCount: 10,
      );

      expect(provisional.quality, AnalysisDataQuality.provisional);
      expect(provisional.countSummary, '1 reeks · 4/5 schoten met positie');
      expect(provisional.shotsWithoutPosition, 1);
      expect(full.quality, AnalysisDataQuality.usable);
      expect(full.quality.label, isNot(contains('%')));
    });
  });

  testWidgets('metric tile exposes a discoverable explanation action', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsiveMetricGrid(
            items: [
              MetricItem(
                label: 'Mean radius',
                value: '12,4 mm',
                helpSemanticLabel: 'Leg mean radius uit',
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );
    final semantics = tester.ensureSemantics();

    expect(
      find.bySemanticsLabel('Mean radius: 12,4 mm. Leg mean radius uit'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    await tester.tap(find.text('12,4 mm'));
    expect(tapped, isTrue);
    semantics.dispose();
  });

  testWidgets('one or two positions do not present zero-valued group metrics', (
    tester,
  ) async {
    final analysis = GroupAnalyzer.analyze(
      seriesId: 'small-sample',
      impacts: const [
        ShotImpact(id: 'one', xMm: 1, yMm: 2),
        ShotImpact(id: 'two', xMm: 2, yMm: 3),
      ],
      targetProfile: IssfTargetProfiles.precision25m50m,
      distanceMeters: 25,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GroupAnalysisMetrics(analysis: analysis),
              GroupAnalysisSummaryCard(
                analysis: analysis,
                onOpenAnalysis: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Minstens drie'), findsOneWidget);
    expect(find.text('Mean radius'), findsNothing);
    expect(find.text('Extreme spreiding'), findsNothing);
    expect(find.textContaining('Alleen posities'), findsOneWidget);
  });

  testWidgets(
    'scope bar keeps scope, counts and quality visible at large text',
    (tester) async {
      _setSurfaceSize(tester, const Size(320, 640));
      final evidence = AnalysisEvidence(
        quality: AnalysisDataQuality.smallSample,
        actualShotCount: 12,
        positionedShotCount: 10,
        seriesCount: 2,
        limitations: const ['Twee missers hebben geen fysieke positie.'],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: AnalysisScopeBar(
                  scope: AnalysisScope(
                    dimensions: const ['ISSF 25 m', '25 m', 'Walther GSP'],
                  ),
                  evidence: evidence,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      final semantics = tester.ensureSemantics();

      expect(find.text('ISSF 25 m · 25 m · Walther GSP'), findsOneWidget);
      expect(find.text('Kleine steekproef'), findsOneWidget);
      expect(
        find.text('2 reeksen · 10/12 schoten met positie'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Vergelijkbare gegevens.*Open details')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('chart has a visible summary and expandable structured values', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(320, 640));
    const summary =
        'Mean radius daalde van ongeveer 18 naar 14 mm over 5 reeksen.';
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(8),
              child: AccessibleChartFrame(
                title: 'Mean-radiustrend',
                summary: summary,
                chart: SizedBox(
                  key: ValueKey('test-chart'),
                  height: 120,
                  child: ColoredBox(color: Colors.black12),
                ),
                dataRows: [
                  AccessibleChartDataRow(label: 'Reeks 1', value: '18,1 mm'),
                  AccessibleChartDataRow(
                    label: 'Reeks 5',
                    value: '14,0 mm',
                    detail: 'Laatste bevestigde reeks',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final semantics = tester.ensureSemantics();

    expect(find.text(summary), findsOneWidget);
    expect(find.text('Reeks 1'), findsNothing);
    expect(find.bySemanticsLabel('Mean-radiustrend. $summary'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Gegevens en uitleg'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Gegevens en uitleg'));
    await tester.pumpAndSettle();

    expect(find.text('Reeks 1'), findsOneWidget);
    expect(find.text('18,1 mm'), findsOneWidget);
    expect(find.text('Laatste bevestigde reeks'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('metric explanation shows current value, evidence and limits', (
    tester,
  ) async {
    _setSurfaceSize(tester, const Size(360, 800));
    final evidence = AnalysisEvidence(
      quality: AnalysisDataQuality.provisional,
      actualShotCount: 5,
      positionedShotCount: 4,
      seriesCount: 1,
      limitations: const ['Eén misser heeft geen fysieke positie.'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showMetricExplanationSheet(
                context: context,
                definition: MetricDefinitions.meanRadius,
                currentValue: '12,4 mm',
                evidence: evidence,
              ),
              child: const Text('Open uitleg'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open uitleg'));
    await tester.pumpAndSettle();

    expect(find.text('Mean radius'), findsOneWidget);
    expect(find.text('12,4 mm'), findsOneWidget);
    expect(find.text('Wat meet dit?'), findsOneWidget);
    expect(find.text('Databasis'), findsOneWidget);
    expect(find.text('Voorlopig'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Beperkingen'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Beperkingen'), findsOneWidget);
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
