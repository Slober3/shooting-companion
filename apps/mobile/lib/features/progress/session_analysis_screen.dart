import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shooting_companion_analysis/analysis.dart';

import '../../app/providers.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/responsive_metric_grid.dart';
import 'analysis_adapter.dart';
import 'analysis_explanations.dart';
import 'series_analysis_screen.dart';

/// Contextual analysis of every confirmed series in one range visit.
///
/// Series with different target versions, distances, firearms or ammunition
/// are deliberately split into separate cohorts. This prevents physically
/// incompatible groups from being pooled into one persuasive-looking plot.
class SessionAnalysisScreen extends ConsumerStatefulWidget {
  const SessionAnalysisScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<SessionAnalysisScreen> createState() =>
      _SessionAnalysisScreenState();
}

class _SessionAnalysisScreenState extends ConsumerState<SessionAnalysisScreen> {
  final Map<String, Set<String>> _selectedByCohort = {};

  @override
  Widget build(BuildContext context) {
    final detailValue = ref.watch(sessionDetailProvider(widget.sessionId));
    final datasetValue = ref.watch(analysisDatasetProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sessieanalyse')),
      body: detailValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Sessie laden mislukt: $error'),
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Deze sessie bestaat niet meer.'));
          }
          return datasetValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Analyse laden mislukt: $error'),
              ),
            ),
            data: (source) {
              final items =
                  analyzeSeriesDataset(
                    source.where(
                      (item) => item.series.sessionId == widget.sessionId,
                    ),
                  )..sort(
                    (a, b) => a.source.series.sequenceNumber.compareTo(
                      b.source.series.sequenceNumber,
                    ),
                  );
              return _buildContent(context, detail.session.startedAtUtc, items);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DateTime startedAtUtc,
    List<AnalyzedSeriesView> items,
  ) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Deze sessie bevat nog geen bevestigde reeksen om te analyseren.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final positioned = items.fold<int>(
      0,
      (sum, item) => sum + item.analysis.positionedShotCount,
    );
    final averageScore =
        items.map((item) => item.scorePercentage).reduce((a, b) => a + b) /
        items.length;
    final withPositions = items
        .where((item) => item.analysis.positionedShotCount >= 3)
        .toList(growable: false);
    final averageRadius = withPositions.isEmpty
        ? null
        : withPositions
                  .map((item) => item.analysis.metrics.meanRadiusMm)
                  .reduce((a, b) => a + b) /
              withPositions.length;
    final cohorts = _groupComparable(items);
    final formatter = DateFormat('EEEE d MMMM yyyy · HH:mm', 'nl_BE');

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Text(
          formatter.format(startedAtUtc.toLocal()),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Deze analyse gebruikt uitsluitend bevestigde reeksen uit dit '
          'standbezoek.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveMetricGrid(
          items: [
            MetricItem(label: 'Reeksen', value: '${items.length}'),
            MetricItem(label: 'Treffers met positie', value: '$positioned'),
            MetricItem(
              label: 'Gemiddelde score',
              value: '${averageScore.toStringAsFixed(1)}%',
            ),
            MetricItem(
              label: cohorts.length == 1
                  ? 'Gemiddelde radius'
                  : 'Vergelijkbare groepen',
              value: cohorts.length == 1
                  ? averageRadius == null
                        ? 'Niet beschikbaar'
                        : '${averageRadius.toStringAsFixed(1)} mm'
                  : '${cohorts.length}',
            ),
          ],
        ),
        if (cohorts.length > 1) ...[
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.call_split),
              title: Text('${cohorts.length} vergelijkbare groepen'),
              subtitle: const Text(
                'Verschillende kaarten, afstanden of materiaalcombinaties '
                'worden bewust niet samengevoegd.',
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        for (final entry in cohorts.entries) ...[
          _buildCohort(context, entry.key, entry.value),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildCohort(
    BuildContext context,
    String cohortId,
    List<AnalyzedSeriesView> items,
  ) {
    final defaults = items.take(5).map((item) => item.source.series.id).toSet();
    final selectedIds = _selectedByCohort[cohortId] ?? defaults;
    final selected = items
        .where((item) => selectedIds.contains(item.source.series.id))
        .toList(growable: false);
    final first = items.first;
    final series = first.source.series;
    final material = [
      if (first.source.firearm != null) first.source.firearm!.name,
      if (first.source.cartridge != null) first.source.cartridge!.name,
      if (first.source.ammoLot != null) first.source.ammoLot!.displayName,
    ].join(' · ');
    final selectedWithPositions = selected
        .where((item) => item.analysis.positionedShotCount > 0)
        .toList(growable: false);
    CohortAnalysis? pooled;
    if (selected.isNotEmpty) {
      pooled = CohortAnalyzer.analyze(selected.map(cohortInputFromAnalyzed));
    }
    final selectedActualShots = selected.fold<int>(
      0,
      (sum, item) => sum + item.analysis.actualShotCount,
    );
    final selectedPositionedShots =
        pooled?.pooledMetrics.positionedShotCount ?? 0;
    final comparisonEvidence = pooled == null
        ? null
        : AnalysisEvidence(
            quality:
                selectedWithPositions.length >= 5 &&
                    selectedPositionedShots >= 60
                ? AnalysisDataQuality.stronger
                : selectedWithPositions.length >= 3 &&
                      selectedPositionedShots >= 30
                ? AnalysisDataQuality.usable
                : selectedWithPositions.length >= 2
                ? AnalysisDataQuality.smallSample
                : AnalysisDataQuality.provisional,
            actualShotCount: selectedActualShots,
            positionedShotCount: selectedPositionedShots,
            seriesCount: selected.length,
            limitations: pooled.comparisonWarnings,
          );
    MetricItem explainedMetric({
      required String label,
      required String value,
      required MetricDefinition definition,
    }) => MetricItem(
      label: label,
      value: value,
      helpSemanticLabel: 'Uitleg over ${definition.label}',
      onTap: () => showMetricExplanationSheet(
        context: context,
        definition: definition,
        currentValue: value,
        evidence: comparisonEvidence,
      ),
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              first.target.displayName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${series.distanceMeters.toStringAsFixed(_distanceDigits(series.distanceMeters))} m'
              '${material.isEmpty ? '' : ' · $material'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vergelijk reeksen',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Selecteer maximaal vijf reeksen voor een leesbare overlay.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final item in items)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: selectedIds.contains(item.source.series.id),
                title: Text('Reeks ${item.source.series.sequenceNumber}'),
                subtitle: Text(
                  '${item.scorePercentage.toStringAsFixed(1)}% · '
                  '${item.analysis.positionedShotCount} positionele treffers · '
                  '${item.analysis.positionedShotCount >= 3 ? '${item.analysis.metrics.meanRadiusMm.toStringAsFixed(1)} mm gemiddelde radius' : 'nog geen groepsmaten'}',
                ),
                secondary: IconButton(
                  tooltip:
                      'Volledige analyse van reeks ${item.source.series.sequenceNumber}',
                  onPressed: () => _openSeries(item.source.series.id),
                  icon: const Icon(Icons.open_in_new),
                ),
                onChanged: (value) => _toggleSeries(
                  cohortId,
                  item.source.series.id,
                  value ?? false,
                  selectedIds,
                ),
              ),
            if (selectedWithPositions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SessionGroupOverlay(items: selectedWithPositions),
              const SizedBox(height: 12),
              _SeriesLegend(items: selectedWithPositions),
            ],
            if (selected.length > selectedWithPositions.length) ...[
              const SizedBox(height: 12),
              Text(
                '${selected.length - selectedWithPositions.length} geselecteerde '
                'reeks(en) zonder positionele treffers tellen wel mee voor '
                'scoretrend en scorevariatie, maar niet voor de overlay.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            if (pooled == null)
              const Text('Selecteer minstens één reeks.')
            else ...[
              if (selectedPositionedShots < 3 && selected.length < 2)
                const Text(
                  'Alleen de geplaatste posities worden getoond. Selecteer '
                  'minstens twee reeksen voor een scorevergelijking of zorg '
                  'voor minstens drie positionele treffers voor groepsmaten.',
                )
              else
                ResponsiveMetricGrid(
                  items: [
                    if (selectedPositionedShots >= 3) ...[
                      explainedMetric(
                        label: 'Gezamenlijke gemiddelde radius',
                        value:
                            '${pooled.pooledMetrics.meanRadiusMm.toStringAsFixed(1)} mm',
                        definition: MetricDefinitions.meanRadius,
                      ),
                      explainedMetric(
                        label: 'Extreme spreiding',
                        value:
                            '${pooled.pooledMetrics.extremeSpreadMm.toStringAsFixed(1)} mm',
                        definition: MetricDefinitions.extremeSpread,
                      ),
                    ],
                    if (selected.length >= 2) ...[
                      explainedMetric(
                        label: 'Scorevariatie',
                        value:
                            '${pooled.consistency.scoreStandardDeviation.toStringAsFixed(1)} pp',
                        definition: MetricDefinitions.scoreConsistency,
                      ),
                      explainedMetric(
                        label: 'Trend per reeks',
                        value:
                            '${pooled.scoreTrend.linearSlopePercentagePointsPerSeries >= 0 ? '+' : ''}'
                            '${pooled.scoreTrend.linearSlopePercentagePointsPerSeries.toStringAsFixed(1)} pp',
                        definition: MetricDefinitions.scoreTrend,
                      ),
                    ],
                  ],
                ),
              if (pooled.comparisonWarnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final warning in pooled.comparisonWarnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(warning)),
                      ],
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _toggleSeries(
    String cohortId,
    String seriesId,
    bool selected,
    Set<String> current,
  ) {
    final next = {...current};
    if (selected) {
      if (next.length >= 5) {
        AppMessenger.info(
          context,
          'Selecteer maximaal vijf reeksen voor de overlay.',
        );
        return;
      }
      next.add(seriesId);
    } else {
      next.remove(seriesId);
    }
    setState(() => _selectedByCohort[cohortId] = next);
  }

  Future<void> _openSeries(String seriesId) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => SeriesAnalysisScreen(seriesId: seriesId)),
  );

  Map<String, List<AnalyzedSeriesView>> _groupComparable(
    Iterable<AnalyzedSeriesView> items,
  ) {
    final result = <String, List<AnalyzedSeriesView>>{};
    for (final item in items) {
      final series = item.source.series;
      final key = [
        series.targetProfileVersionedId,
        series.distanceMeters.toStringAsFixed(6),
        series.projectileDiameterMm.toStringAsFixed(6),
        series.cartridgeId ?? '-',
        series.firearmId ?? '-',
        series.ammoLotId ?? '-',
      ].join('|');
      result.putIfAbsent(key, () => []).add(item);
    }
    return result;
  }
}

class _SessionGroupOverlay extends StatelessWidget {
  const _SessionGroupOverlay({required this.items});

  final List<AnalyzedSeriesView> items;

  @override
  Widget build(BuildContext context) {
    final shotCount = items.fold<int>(
      0,
      (sum, item) => sum + item.analysis.positionedShotCount,
    );
    final summary =
        'Genormaliseerde overlay van ${items.length} reeksen en $shotCount '
        'positionele treffers. Iedere vorm hoort bij één reeks.';
    return Semantics(
      image: true,
      label: summary,
      child: AspectRatio(
        aspectRatio: 1.35,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: CustomPaint(
            painter: _SessionGroupOverlayPainter(
              analyses: items.map((item) => item.analysis).toList(),
              colors: _seriesColors(context, items.length),
              axisColor: Theme.of(context).colorScheme.outlineVariant,
              textColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesLegend extends StatelessWidget {
  const _SeriesLegend({required this.items});

  final List<AnalyzedSeriesView> items;

  @override
  Widget build(BuildContext context) {
    final colors = _seriesColors(context, items.length);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (var index = 0; index < items.length; index++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size.square(16),
                painter: _LegendShapePainter(
                  color: colors[index],
                  shapeIndex: index,
                ),
              ),
              const SizedBox(width: 6),
              Text('Reeks ${items[index].source.series.sequenceNumber}'),
            ],
          ),
      ],
    );
  }
}

class _SessionGroupOverlayPainter extends CustomPainter {
  const _SessionGroupOverlayPainter({
    required this.analyses,
    required this.colors,
    required this.axisColor,
    required this.textColor,
  });

  final List<SeriesAnalysis> analyses;
  final List<Color> colors;
  final Color axisColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    var extent = 5.0;
    for (final analysis in analyses) {
      for (final point in analysis.positions) {
        extent = math.max(extent, math.max(point.xMm.abs(), point.yMm.abs()));
      }
    }
    extent *= 1.2;
    final scale = math.min(size.width, size.height) * 0.44 / extent;
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      axisPaint,
    );
    for (var seriesIndex = 0; seriesIndex < analyses.length; seriesIndex++) {
      final analysis = analyses[seriesIndex];
      final paint = Paint()
        ..color = colors[seriesIndex]
        ..style = PaintingStyle.fill;
      final outline = Paint()
        ..color = textColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      for (final point in analysis.positions) {
        final offset = Offset(
          center.dx + point.xMm * scale,
          center.dy + point.yMm * scale,
        );
        _drawShape(canvas, offset, 5.5, seriesIndex, paint, outline);
      }
      final centroid = Offset(
        center.dx + analysis.metrics.centroidXMm * scale,
        center.dy + analysis.metrics.centroidYMm * scale,
      );
      final centroidPaint = Paint()
        ..color = colors[seriesIndex]
        ..strokeWidth = 2;
      canvas.drawLine(
        centroid.translate(-7, 0),
        centroid.translate(7, 0),
        centroidPaint,
      );
      canvas.drawLine(
        centroid.translate(0, -7),
        centroid.translate(0, 7),
        centroidPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SessionGroupOverlayPainter oldDelegate) =>
      oldDelegate.analyses != analyses ||
      oldDelegate.colors != colors ||
      oldDelegate.axisColor != axisColor ||
      oldDelegate.textColor != textColor;
}

class _LegendShapePainter extends CustomPainter {
  const _LegendShapePainter({required this.color, required this.shapeIndex});

  final Color color;
  final int shapeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    _drawShape(
      canvas,
      Offset(size.width / 2, size.height / 2),
      5.5,
      shapeIndex,
      fill,
      outline,
    );
  }

  @override
  bool shouldRepaint(covariant _LegendShapePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.shapeIndex != shapeIndex;
}

void _drawShape(
  Canvas canvas,
  Offset center,
  double radius,
  int shapeIndex,
  Paint fill,
  Paint outline,
) {
  switch (shapeIndex % 4) {
    case 1:
      final rect = Rect.fromCenter(
        center: center,
        width: radius * 1.8,
        height: radius * 1.8,
      );
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, outline);
    case 2:
      final path = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius, center.dy + radius)
        ..lineTo(center.dx - radius, center.dy + radius)
        ..close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, outline);
    case 3:
      canvas.drawLine(
        center.translate(-radius, -radius),
        center.translate(radius, radius),
        outline..strokeWidth = 2.5,
      );
      canvas.drawLine(
        center.translate(radius, -radius),
        center.translate(-radius, radius),
        outline,
      );
    default:
      canvas.drawCircle(center, radius, fill);
      canvas.drawCircle(center, radius, outline);
  }
}

List<Color> _seriesColors(BuildContext context, int count) {
  final scheme = Theme.of(context).colorScheme;
  final candidates = [
    scheme.primary,
    scheme.tertiary,
    scheme.error,
    scheme.secondary,
    scheme.inversePrimary,
  ];
  return List<Color>.generate(count, (index) => candidates[index % 5]);
}

int _distanceDigits(double distance) =>
    distance == distance.roundToDouble() ? 0 : 1;
