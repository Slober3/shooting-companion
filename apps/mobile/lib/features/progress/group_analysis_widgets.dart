import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shooting_companion_analysis/analysis.dart';

import '../../widgets/responsive_metric_grid.dart';
import 'analysis_evidence.dart';
import 'metric_definitions.dart';
import 'metric_explanation_sheet.dart';

/// Reusable, read-only plot of positions normalized by [GroupAnalyzer].
///
/// For multi-bull targets the supplied positions are already local to their
/// referenced record bull. The plot therefore deliberately has no dependency
/// on a concrete target renderer.
class GroupAnalysisPlot extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
    return Semantics(
      image: true,
      label: summary,
      child: AspectRatio(
        aspectRatio: aspectRatio,
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
                showDensity: showDensity,
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
    required this.colorScheme,
  });

  final SeriesAnalysis analysis;
  final bool showDensity;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final positions = analysis.positions;
    if (positions.isEmpty || size.isEmpty) return;
    final metrics = analysis.metrics;
    var extent = math.max(
      metrics.empiricalR90Mm,
      math.max(metrics.centroidXMm.abs(), metrics.centroidYMm.abs()),
    );
    for (final point in positions) {
      extent = math.max(extent, math.max(point.xMm.abs(), point.yMm.abs()));
    }
    extent = math.max(1, extent * 1.25);
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
    for (final fraction in const [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(
        center,
        extent * fraction * scale,
        Paint()
          ..color = colorScheme.outlineVariant.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke,
      );
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

    final ellipse = metrics.covarianceEllipse;
    final ellipseCenter = project(metrics.centroidXMm, metrics.centroidYMm);
    if (positions.length >= 3) {
      canvas.save();
      canvas.translate(ellipseCenter.dx, ellipseCenter.dy);
      canvas.rotate(ellipse.angleDegrees * math.pi / 180);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: math.max(2, ellipse.semiMajorAxisMm * 2 * scale),
          height: math.max(2, ellipse.semiMinorAxisMm * 2 * scale),
        ),
        Paint()
          ..color = colorScheme.primary
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      canvas.restore();
    }

    for (final point in positions) {
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
    }

    if (positions.length >= 3) {
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
