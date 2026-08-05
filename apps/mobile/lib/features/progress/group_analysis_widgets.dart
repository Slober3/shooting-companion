import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shooting_companion_analysis/analysis.dart';

import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/safe_sheet_scaffold.dart';
import 'analysis_evidence.dart';
import 'metric_definitions.dart';
import 'metric_explanation_sheet.dart';

/// Reusable, read-only plot of positions normalized by [GroupAnalyzer].
///
/// For multi-bull targets the supplied positions are already local to their
/// referenced record bull. The plot therefore deliberately has no dependency
/// on a concrete target renderer.
class GroupAnalysisPlot extends StatefulWidget {
  const GroupAnalysisPlot({
    required this.analysis,
    this.showDensity = false,
    this.aspectRatio = 1.35,
    super.key,
  });

  final SeriesAnalysis analysis;
  final bool showDensity;
  final double aspectRatio;

  @override
  State<GroupAnalysisPlot> createState() => _GroupAnalysisPlotState();
}

enum GroupPlotOverlay {
  impacts,
  centroid,
  covarianceEllipse,
  extremeSpread,
  impactNumbers,
  scaleRings,
}

class GroupPlotDisplayOptions {
  const GroupPlotDisplayOptions({
    this.showImpacts = true,
    this.showCentroid = true,
    this.showCovarianceEllipse = true,
    this.showExtremeSpread = true,
    this.showImpactNumbers = false,
    this.showScaleRings = true,
  });

  final bool showImpacts;
  final bool showCentroid;
  final bool showCovarianceEllipse;
  final bool showExtremeSpread;
  final bool showImpactNumbers;
  final bool showScaleRings;

  bool enabled(GroupPlotOverlay overlay) => switch (overlay) {
    GroupPlotOverlay.impacts => showImpacts,
    GroupPlotOverlay.centroid => showCentroid,
    GroupPlotOverlay.covarianceEllipse => showCovarianceEllipse,
    GroupPlotOverlay.extremeSpread => showExtremeSpread,
    GroupPlotOverlay.impactNumbers => showImpactNumbers,
    GroupPlotOverlay.scaleRings => showScaleRings,
  };

  GroupPlotDisplayOptions toggled(GroupPlotOverlay overlay) =>
      GroupPlotDisplayOptions(
        showImpacts: overlay == GroupPlotOverlay.impacts
            ? !showImpacts
            : showImpacts,
        showCentroid: overlay == GroupPlotOverlay.centroid
            ? !showCentroid
            : showCentroid,
        showCovarianceEllipse: overlay == GroupPlotOverlay.covarianceEllipse
            ? !showCovarianceEllipse
            : showCovarianceEllipse,
        showExtremeSpread: overlay == GroupPlotOverlay.extremeSpread
            ? !showExtremeSpread
            : showExtremeSpread,
        showImpactNumbers: overlay == GroupPlotOverlay.impactNumbers
            ? !showImpactNumbers
            : showImpactNumbers,
        showScaleRings: overlay == GroupPlotOverlay.scaleRings
            ? !showScaleRings
            : showScaleRings,
      );
}

class _GroupAnalysisPlotState extends State<GroupAnalysisPlot> {
  GroupPlotDisplayOptions _options = const GroupPlotDisplayOptions();

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final metrics = analysis.metrics;
    final summary = switch (metrics.positionedShotCount) {
      0 => 'Geen positionele treffers beschikbaar.',
      < 3 =>
        'Trefbeeld met ${metrics.positionedShotCount} positionele schoten. '
            'Er zijn nog te weinig treffers voor groepsmaten.',
      _ =>
        'Trefbeeld met ${metrics.positionedShotCount} positionele schoten. '
            'Groepscentrum ${formatHorizontalBias(metrics.horizontalBiasMm)} '
            'en ${formatVerticalBias(metrics.verticalBiasMm)}. '
            'Mean radius ${metrics.meanRadiusMm.toStringAsFixed(1)} millimeter.',
    };
    final extent = _plotExtentMm(analysis);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<GroupPlotOverlay>(
            key: const ValueKey('group-plot-display-menu'),
            tooltip: 'Weergave aanpassen',
            onSelected: (overlay) =>
                setState(() => _options = _options.toggled(overlay)),
            itemBuilder: (context) => [
              for (final overlay in GroupPlotOverlay.values)
                CheckedPopupMenuItem(
                  value: overlay,
                  checked: _options.enabled(overlay),
                  child: Text(_overlayLabel(overlay)),
                ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Weergave'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Semantics(
          image: true,
          label:
              '$summary Extreme spreiding '
              '${metrics.extremeSpreadMm.toStringAsFixed(1)} millimeter. '
              'Treffers buiten de één-sigma-ellips tellen mee.',
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CustomPaint(
                  key: const ValueKey('group-analysis-plot'),
                  painter: _GroupAnalysisPainter(
                    analysis: analysis,
                    showDensity: widget.showDensity,
                    options: _options,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                  child: analysis.positionedShotCount == 0
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Geen positionele treffers om weer te geven.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _GroupPlotLegend(options: _options),
        if (_options.showScaleRings) ...[
          const SizedBox(height: 6),
          Text(
            'Buitenste schaalring: ${_formatScale(extent)} mm vanaf centrum.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (metrics.positionedShotCount >= 3) ...[
          const SizedBox(height: 6),
          Text(
            'De 1σ-ellips toont richting en standaardspreiding. Ze is geen '
            'grens rond de groep; treffers erbuiten tellen mee.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        _GroupDataSummaryBar(analysis: analysis),
      ],
    );
  }
}

/// Compact entry point suitable for a series detail page.
class GroupAnalysisSummaryCard extends StatelessWidget {
  const GroupAnalysisSummaryCard({
    required this.analysis,
    required this.onOpenAnalysis,
    super.key,
  });

  final SeriesAnalysis analysis;
  final VoidCallback onOpenAnalysis;

  @override
  Widget build(BuildContext context) {
    final metrics = analysis.metrics;
    return Card(
      key: const ValueKey('series-group-summary-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.adjust),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Trefbeeld',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (metrics.positionedShotCount == 0)
              const Text(
                'Deze reeks heeft geen positionele treffers. Missers blijven '
                'wel onderdeel van de score.',
              )
            else if (metrics.positionedShotCount < 3) ...[
              Text(
                '${metrics.positionedShotCount} positionele '
                'treffer${metrics.positionedShotCount == 1 ? '' : 's'}.',
              ),
              const SizedBox(height: 6),
              Text(
                analysisReliabilityText(analysis.reliability),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _CompactMetric(
                    label: 'Mean radius',
                    value: '${metrics.meanRadiusMm.toStringAsFixed(1)} mm',
                  ),
                  _CompactMetric(
                    label: 'Extreme spreiding',
                    value: '${metrics.extremeSpreadMm.toStringAsFixed(1)} mm',
                  ),
                  _CompactMetric(
                    label: 'Groepscentrum',
                    value:
                        '${formatHorizontalBias(metrics.horizontalBiasMm)}, '
                        '${formatVerticalBias(metrics.verticalBiasMm)}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                analysisReliabilityText(analysis.reliability),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('open-full-series-analysis'),
                onPressed: onOpenAnalysis,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Volledige analyse'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Core metrics shared by contextual and future global analysis screens.
class GroupAnalysisMetrics extends StatelessWidget {
  const GroupAnalysisMetrics({required this.analysis, super.key});

  final SeriesAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final metrics = analysis.metrics;
    if (metrics.positionedShotCount < 3) {
      return Text(
        metrics.positionedShotCount == 0
            ? 'Geen groepsmaten zonder positionele treffers.'
            : 'Alleen de posities worden getoond. Minstens drie positionele '
                  'treffers zijn nodig voor voorlopige groepsmaten.',
      );
    }
    final evidence = AnalysisEvidence.fromReliability(
      reliability: analysis.reliability,
      actualShotCount: analysis.actualShotCount,
      positionedShotCount: analysis.positionedShotCount,
      limitations: analysis.warnings.map(analysisWarningText),
    );
    MetricItem explainedMetric({
      required String label,
      required String value,
      required IconData icon,
      required MetricDefinition definition,
    }) => MetricItem(
      label: label,
      value: value,
      icon: icon,
      helpSemanticLabel: 'Uitleg over ${definition.label}',
      onTap: () => showMetricExplanationSheet(
        context: context,
        definition: definition,
        currentValue: value,
        evidence: evidence,
      ),
    );
    return ResponsiveMetricGrid(
      items: [
        explainedMetric(
          label: 'Mean radius',
          value: '${metrics.meanRadiusMm.toStringAsFixed(1)} mm',
          icon: Icons.radio_button_checked,
          definition: MetricDefinitions.meanRadius,
        ),
        explainedMetric(
          label: 'Extreme spreiding',
          value: '${metrics.extremeSpreadMm.toStringAsFixed(1)} mm',
          icon: Icons.open_in_full,
          definition: MetricDefinitions.extremeSpread,
        ),
        explainedMetric(
          label: 'Horizontale bias',
          value: formatHorizontalBias(metrics.horizontalBiasMm),
          icon: Icons.swap_horiz,
          definition: MetricDefinitions.groupCenter,
        ),
        explainedMetric(
          label: 'Verticale bias',
          value: formatVerticalBias(metrics.verticalBiasMm),
          icon: Icons.swap_vert,
          definition: MetricDefinitions.groupCenter,
        ),
      ],
    );
  }
}

/// Explicit description of which stored shots contributed to the metrics.
class AnalysisDataBasisCard extends StatelessWidget {
  const AnalysisDataBasisCard({
    required this.analysis,
    required this.isMultiBull,
    super.key,
  });

  final SeriesAnalysis analysis;
  final bool isMultiBull;

  @override
  Widget build(BuildContext context) {
    final warnings = analysis.warnings
        .map(analysisWarningText)
        .toSet()
        .toList(growable: false);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Databasis', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${analysis.actualShotCount} geregistreerde schoten · '
              '${analysis.positionedShotCount} gebruikt voor fysieke '
              'groepsmaten.',
            ),
            const SizedBox(height: 6),
            Text(
              analysisReliabilityText(analysis.reliability),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (isMultiBull) ...[
              const SizedBox(height: 8),
              const Text(
                'Multi-bullnormalisatie: iedere geldige treffer is gemeten '
                'ten opzichte van het midden van het eigen wedstrijdroosje. '
                'Proefroosjes tellen niet mee.',
              ),
            ],
            for (final warning in warnings) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(warning)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupPlotLegend extends StatelessWidget {
  const _GroupPlotLegend({required this.options});

  final GroupPlotDisplayOptions options;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (options.showImpacts)
          _LegendItem(
            icon: Icons.circle,
            color: scheme.primary,
            label: 'Treffer',
          ),
        if (options.showCentroid)
          _LegendItem(
            icon: Icons.add,
            color: scheme.secondary,
            label: 'Groepscentrum',
          ),
        if (options.showCovarianceEllipse)
          _LegendItem(
            icon: Icons.radio_button_unchecked,
            color: scheme.primary,
            label: '1σ-ellips',
          ),
        if (options.showExtremeSpread)
          _LegendItem(
            icon: Icons.open_in_full,
            color: scheme.tertiary,
            label: 'Extreme spreiding',
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: math.max(0, MediaQuery.sizeOf(context).width - 48),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            softWrap: true,
          ),
        ),
      ],
    ),
  );
}

class _GroupDataSummaryBar extends StatelessWidget {
  const _GroupDataSummaryBar({required this.analysis});

  final SeriesAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final excluded = math.max(
      0,
      analysis.actualShotCount - analysis.positionedShotCount,
    );
    final hasMultiplicity = analysis.positions.any(
      (position) => position.multiplicity > 1,
    );
    final summary = hasMultiplicity
        ? '${analysis.positions.length} markerposities · '
              '${analysis.positionedShotCount} schoten meegerekend · '
              '$excluded uitgesloten · multipliciteit aanwezig'
        : '${analysis.positionedShotCount} positionele schoten meegerekend · '
              '$excluded uitgesloten';
    return Semantics(
      button: true,
      label: '$summary. Open gebruikte gegevens.',
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: const ValueKey('group-data-summary'),
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showUsedData(context, analysis),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.dataset_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(summary)),
                const SizedBox(width: 8),
                const Icon(Icons.info_outline, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showUsedData(
  BuildContext context,
  SeriesAnalysis analysis,
) => showSafeModalSheet<void>(
  context: context,
  presentation: SafeSheetPresentation.adaptive,
  builder: (sheetContext) {
    final excluded = math.max(
      0,
      analysis.actualShotCount - analysis.positionedShotCount,
    );
    final warnings = analysis.warnings
        .map(analysisWarningText)
        .toSet()
        .toList(growable: false);
    return SafeSheetScaffold(
      title: 'Gebruikte gegevens',
      actions: const [],
      contentSized: true,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DataDetailRow(
            label: 'Geregistreerde schoten',
            value: '${analysis.actualShotCount}',
          ),
          _DataDetailRow(
            label: 'Markerposities',
            value: '${analysis.positions.length}',
          ),
          _DataDetailRow(
            label: 'Positionele schoten meegerekend',
            value: '${analysis.positionedShotCount}',
          ),
          _DataDetailRow(label: 'Uitgesloten', value: '$excluded'),
          for (final reason in _exclusionReasonRows(analysis))
            _DataDetailRow(label: reason.label, value: '${reason.count}'),
          const SizedBox(height: 12),
          const Text(
            'Verre treffers worden niet automatisch als outlier verwijderd. '
            'Iedere geldige positionele treffer beïnvloedt het groepscentrum, '
            'de 1σ-ellips, mean radius en extreme spreiding.',
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Beperkingen',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            for (final warning in warnings)
              Padding(
                padding: const EdgeInsets.only(top: 6),
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
      ),
    );
  },
);

class _DataDetailRow extends StatelessWidget {
  const _DataDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 112),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    ),
  );
}

class _GroupAnalysisPainter extends CustomPainter {
  const _GroupAnalysisPainter({
    required this.analysis,
    required this.showDensity,
    required this.options,
    required this.colorScheme,
  });

  final SeriesAnalysis analysis;
  final bool showDensity;
  final GroupPlotDisplayOptions options;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = analysis.positions;
    if (positions.isEmpty || size.isEmpty) return;
    final metrics = analysis.metrics;
    final extent = _plotExtentMm(analysis);
    final plotRect = Rect.fromLTWH(18, 12, size.width - 36, size.height - 24);
    final scale = math.min(plotRect.width, plotRect.height) / (extent * 2);
    final center = plotRect.center;
    Offset project(double x, double y) => center + Offset(x * scale, y * scale);

    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(plotRect.left, center.dy),
      Offset(plotRect.right, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, plotRect.top),
      Offset(center.dx, plotRect.bottom),
      gridPaint,
    );
    if (options.showScaleRings) {
      for (final fraction in const [0.25, 0.5, 0.75, 1.0]) {
        canvas.drawCircle(
          center,
          extent * fraction * scale,
          Paint()
            ..color = colorScheme.outlineVariant.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke,
        );
      }
    }

    if (showDensity) {
      for (final point in positions) {
        final location = project(point.xMm, point.yMm);
        final radius = math.max(14.0, 8 + point.multiplicity * 2.0);
        canvas.drawCircle(
          location,
          radius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                colorScheme.tertiary.withValues(alpha: 0.46),
                colorScheme.tertiary.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: location, radius: radius)),
        );
      }
    }

    final segment = metrics.extremeSpreadSegment;
    if (options.showExtremeSpread && segment != null) {
      final first = project(segment.firstXMm, segment.firstYMm);
      final second = project(segment.secondXMm, segment.secondYMm);
      final spreadPaint = Paint()
        ..color = colorScheme.tertiary
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(first, second, spreadPaint);
      for (final endpoint in [first, second]) {
        canvas.drawCircle(
          endpoint,
          6,
          Paint()
            ..color = colorScheme.surface
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          endpoint,
          6,
          spreadPaint..style = PaintingStyle.stroke,
        );
      }
      final label = TextPainter(
        text: TextSpan(
          text: 'ES ${_formatDecimal(segment.distanceMm, 1)} mm',
          style: TextStyle(
            color: colorScheme.onTertiaryContainer,
            backgroundColor: colorScheme.tertiaryContainer,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final midpoint = Offset(
        (first.dx + second.dx) / 2,
        (first.dy + second.dy) / 2,
      );
      label.paint(
        canvas,
        Offset(
          (midpoint.dx - label.width / 2).clamp(
            plotRect.left,
            plotRect.right - label.width,
          ),
          (midpoint.dy - label.height - 5).clamp(
            plotRect.top,
            plotRect.bottom - label.height,
          ),
        ),
      );
    }

    final ellipse = metrics.covarianceEllipse;
    final ellipseCenter = project(metrics.centroidXMm, metrics.centroidYMm);
    if (options.showCovarianceEllipse && metrics.positionedShotCount >= 3) {
      canvas.save();
      canvas.translate(ellipseCenter.dx, ellipseCenter.dy);
      canvas.rotate(ellipse.angleDegrees * math.pi / 180);
      _drawDashedPath(
        canvas,
        Path()..addOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: math.max(2, ellipse.semiMajorAxisMm * 2 * scale),
            height: math.max(2, ellipse.semiMinorAxisMm * 2 * scale),
          ),
        ),
        Paint()
          ..color = colorScheme.primary
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      canvas.restore();
    }

    if (options.showImpacts) {
      for (var index = 0; index < positions.length; index++) {
        final point = positions[index];
        final location = project(point.xMm, point.yMm);
        canvas.drawCircle(
          location,
          4.5,
          Paint()
            ..color = point.isPositionUncertain
                ? colorScheme.error
                : colorScheme.primary,
        );
        canvas.drawCircle(
          location,
          4.5,
          Paint()
            ..color = colorScheme.onPrimary
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
        if (options.showImpactNumbers) {
          final number = TextPainter(
            text: TextSpan(
              text: '${index + 1}',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          number.paint(canvas, location + const Offset(6, -12));
        }
      }
    }

    if (options.showCentroid) {
      final centroidPaint = Paint()
        ..color = colorScheme.secondary
        ..strokeWidth = 2.5;
      canvas.drawLine(
        ellipseCenter + const Offset(-8, 0),
        ellipseCenter + const Offset(8, 0),
        centroidPaint,
      );
      canvas.drawLine(
        ellipseCenter + const Offset(0, -8),
        ellipseCenter + const Offset(0, 8),
        centroidPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GroupAnalysisPainter oldDelegate) =>
      oldDelegate.analysis != analysis ||
      oldDelegate.showDensity != showDensity ||
      oldDelegate.options != options ||
      oldDelegate.colorScheme != colorScheme;
}

String analysisReliabilityText(AnalysisReliability reliability) =>
    switch (reliability) {
      AnalysisReliability.noPositionData => 'Geen positionele gegevens.',
      AnalysisReliability.positionsOnly =>
        'Alleen posities: te weinig schoten voor betrouwbare groepsmaten.',
      AnalysisReliability.provisional =>
        'Voorlopige groepsmaten door de zeer kleine steekproef.',
      AnalysisReliability.smallSample =>
        'Bruikbare beschrijving, maar nog een kleine steekproef.',
      AnalysisReliability.full => 'Volledige beschrijvende reeksanalyse.',
    };

String analysisWarningText(AnalysisWarning warning) => switch (warning.code) {
  AnalysisWarningCode.noPositionData =>
    'Missers tellen voor de score, maar hebben geen fysieke positie.',
  AnalysisWarningCode.missWithoutPosition =>
    '${warning.affectedShotCount} missers zonder positie zijn uitgesloten van '
        'fysieke groepsmaten.',
  AnalysisWarningCode.positionsOnly =>
    'Er zijn te weinig positionele schoten voor spreidingsmaten.',
  AnalysisWarningCode.provisionalSample =>
    'Behandel deze groepsmaten als voorlopig.',
  AnalysisWarningCode.smallSample =>
    'De kleine steekproef kan sterk door één treffer worden beïnvloed.',
  AnalysisWarningCode.multiplicityApproximation =>
    '${warning.affectedShotCount} schoten delen een bevestigde positie; de '
        'spreidingsmeting is daarom benaderend.',
  AnalysisWarningCode.uncertainPositionsIncluded =>
    '${warning.affectedShotCount} positioneel onzekere schoten zijn '
        'meegenomen.',
  AnalysisWarningCode.uncertainPositionsExcluded =>
    '${warning.affectedShotCount} positioneel onzekere schoten zijn '
        'uitgesloten.',
  AnalysisWarningCode.missingTargetBull =>
    '${warning.affectedShotCount} treffers missen een geldig roosnummer.',
  AnalysisWarningCode.unknownTargetBull =>
    '${warning.affectedShotCount} treffers verwijzen naar een onbekend roosje.',
  AnalysisWarningCode.sighterBullExcluded =>
    '${warning.affectedShotCount} treffers op een proefroosje zijn uitgesloten.',
  AnalysisWarningCode.nonFinitePosition =>
    '${warning.affectedShotCount} ongeldige posities zijn uitgesloten.',
  AnalysisWarningCode.invalidDistance =>
    'Hoekspreiding kon niet worden berekend door een ongeldige afstand.',
};

List<({String label, int count})> _exclusionReasonRows(
  SeriesAnalysis analysis,
) {
  const labels = <AnalysisWarningCode, String>{
    AnalysisWarningCode.missWithoutPosition: 'Missers zonder positie',
    AnalysisWarningCode.sighterBullExcluded: 'Proefroosjes',
    AnalysisWarningCode.uncertainPositionsExcluded: 'Onzekere posities',
    AnalysisWarningCode.nonFinitePosition: 'Ongeldige coördinaten',
    AnalysisWarningCode.missingTargetBull: 'Ontbrekend roosnummer',
    AnalysisWarningCode.unknownTargetBull: 'Onbekend roosnummer',
  };
  return analysis.warnings
      .where((warning) => labels.containsKey(warning.code))
      .map(
        (warning) =>
            (label: labels[warning.code]!, count: warning.affectedShotCount),
      )
      .toList(growable: false);
}

String formatHorizontalBias(double value) {
  final normalized = value.abs() < 0.05 ? 0.0 : value;
  if (normalized == 0) return '0,0 mm horizontaal';
  return '${normalized.abs().toStringAsFixed(1)} mm '
      '${normalized > 0 ? 'rechts' : 'links'}';
}

String formatVerticalBias(double value) {
  final normalized = value.abs() < 0.05 ? 0.0 : value;
  if (normalized == 0) return '0,0 mm verticaal';
  return '${normalized.abs().toStringAsFixed(1)} mm '
      '${normalized > 0 ? 'onder' : 'boven'}';
}

String formatEllipseDirection(double angleDegrees) {
  final normalized = angleDegrees.clamp(-90.0, 90.0);
  if (normalized.abs() <= 15) return 'vrij horizontaal';
  if (normalized.abs() >= 75) return 'vrij verticaal';
  return normalized < 0
      ? 'linksonder naar rechtsboven'
      : 'linksboven naar rechtsonder';
}

String _overlayLabel(GroupPlotOverlay overlay) => switch (overlay) {
  GroupPlotOverlay.impacts => 'Treffermarkeringen',
  GroupPlotOverlay.centroid => 'Groepscentrum',
  GroupPlotOverlay.covarianceEllipse => '1σ-spreidingsellips',
  GroupPlotOverlay.extremeSpread => 'Extreme-spreadlijn',
  GroupPlotOverlay.impactNumbers => 'Treffernummers',
  GroupPlotOverlay.scaleRings => 'Schaalringen',
};

double _plotExtentMm(SeriesAnalysis analysis) {
  final metrics = analysis.metrics;
  var extent = math.max(
    metrics.empiricalR90Mm,
    math.max(metrics.centroidXMm.abs(), metrics.centroidYMm.abs()),
  );
  for (final point in analysis.positions) {
    extent = math.max(extent, math.max(point.xMm.abs(), point.yMm.abs()));
  }
  return math.max(1, extent * 1.25);
}

String _formatScale(double value) => _formatDecimal(
  value,
  value >= 100
      ? 0
      : value >= 10
      ? 1
      : 2,
);

String _formatDecimal(double value, int fractionDigits) =>
    value.toStringAsFixed(fractionDigits).replaceAll('.', ',');

void _drawDashedPath(
  Canvas canvas,
  Path path,
  Paint paint, {
  double dashLength = 7,
  double gapLength = 4,
}) {
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = math.min(distance + dashLength, metric.length);
      canvas.drawPath(metric.extractPath(distance, end), paint);
      distance = end + gapLength;
    }
  }
}
