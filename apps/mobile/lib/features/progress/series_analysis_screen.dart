import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shooting_companion_analysis/analysis.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/app_expandable_section.dart';
import '../scoring/target_canvas.dart';
import 'analysis_adapter.dart';
import 'analysis_explanations.dart';
import 'group_analysis_widgets.dart';
import 'potential_score_compute_service.dart';

enum SeriesAnalysisPlotMode { target, group, heatmap }

/// Contextual analysis of one stored series.
///
/// The screen deliberately uses the target snapshot and confirmed impact
/// positions attached to [seriesId]. It never mutates the stored series.
class SeriesAnalysisScreen extends ConsumerStatefulWidget {
  const SeriesAnalysisScreen({required this.seriesId, super.key});

  final String seriesId;

  @override
  ConsumerState<SeriesAnalysisScreen> createState() =>
      _SeriesAnalysisScreenState();
}

class _SeriesAnalysisScreenState extends ConsumerState<SeriesAnalysisScreen> {
  SeriesAnalysisPlotMode _plotMode = SeriesAnalysisPlotMode.group;
  PotentialScoreResult? _potentialScore;
  bool _calculatingPotential = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(seriesDetailProvider(widget.seriesId));
    return Scaffold(
      appBar: AppBar(title: const Text('Reeksanalyse')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Analyse laden mislukt: $error'),
          ),
        ),
        data: (value) => value == null
            ? const Center(child: Text('Deze reeks bestaat niet meer.'))
            : _buildAnalysis(context, value),
      ),
    );
  }

  Widget _buildAnalysis(BuildContext context, SeriesDetail detail) {
    final target = detail.target;
    final impacts = detail.impacts
        .map(impactRecordToDomain)
        .toList(growable: false);
    final analysis = GroupAnalyzer.analyze(
      seriesId: detail.series.id,
      impacts: impacts,
      targetProfile: target,
      distanceMeters: detail.series.distanceMeters,
    );
    final parentSession = ref
        .watch(sessionDetailProvider(detail.series.sessionId))
        .valueOrNull
        ?.session;
    final evidence = AnalysisEvidence.fromReliability(
      reliability: analysis.reliability,
      actualShotCount: analysis.actualShotCount,
      positionedShotCount: analysis.positionedShotCount,
      seriesCount: 1,
      limitations: analysis.warnings.map(analysisWarningText),
    );
    final sessionSeries = ref.watch(seriesProvider(detail.series.sessionId));
    final navigation = _navigationFor(
      sessionSeries.valueOrNull ?? const <SeriesRecord>[],
      detail.series.id,
    );
    return ListView(
      key: const ValueKey('series-analysis-scroll-view'),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        _SeriesContextCard(
          detail: detail,
          analysis: analysis,
          occurredAtUtc:
              parentSession?.startedAtUtc ?? detail.series.createdAtUtc,
        ),
        const SizedBox(height: 12),
        AnalysisScopeBar(
          scope: AnalysisScope(
            dimensions: [
              detail.target.displayName,
              '${detail.series.distanceMeters.toStringAsFixed(_distanceDigits(detail.series.distanceMeters))} m',
              detail.cartridge?.name ??
                  '${detail.series.projectileDiameterMm.toStringAsFixed(2)} mm',
              detail.firearm?.name ?? 'Wapen niet opgegeven',
              detail.ammoLot?.displayName ?? 'Munitieprofiel niet opgegeven',
            ],
          ),
          evidence: evidence,
          title: 'Vergelijkbare context',
        ),
        const SizedBox(height: 16),
        _PlotModePicker(
          selected: _plotMode,
          onChanged: (value) => setState(() => _plotMode = value),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: switch (_plotMode) {
            SeriesAnalysisPlotMode.target => TargetCanvas(
              key: const ValueKey('series-analysis-target-view'),
              target: target,
              impacts: impacts,
              projectileDiameterMm: detail.series.projectileDiameterMm,
              scoreValues: {
                for (final record in detail.impacts)
                  record.id: record.rawScoreValue,
              },
              showControls: false,
            ),
            SeriesAnalysisPlotMode.group => GroupAnalysisPlot(
              key: const ValueKey('series-analysis-group-view'),
              analysis: analysis,
            ),
            SeriesAnalysisPlotMode.heatmap => GroupAnalysisPlot(
              key: const ValueKey('series-analysis-heatmap-view'),
              analysis: analysis,
              showDensity: true,
            ),
          },
        ),
        const SizedBox(height: 16),
        GroupAnalysisMetrics(analysis: analysis),
        const SizedBox(height: 16),
        _AdvancedMetricsCard(analysis: analysis, evidence: evidence),
        const SizedBox(height: 16),
        AnalysisDataBasisCard(
          analysis: analysis,
          isMultiBull:
              target.targetKind == domain.TargetKind.multiBullConcentric,
        ),
        if (analysis.subgroupSuggestion case final suggestion?) ...[
          const SizedBox(height: 16),
          _SubgroupCard(suggestion: suggestion, evidence: evidence),
        ],
        const SizedBox(height: 16),
        _PotentialScoreCard(
          result: _potentialScore,
          storedScore: detail.series.totalScore,
          calculating: _calculatingPotential,
          enabled: analysis.positionedShotCount > 0,
          onCalculate: () => _calculatePotentialScore(detail, impacts),
          evidence: evidence,
        ),
        const SizedBox(height: 16),
        _SeriesNavigationCard(
          currentSequence: detail.series.sequenceNumber,
          currentIndex: navigation.currentIndex,
          total: navigation.total,
          previous: navigation.previous,
          next: navigation.next,
          onNavigate: _navigateToSeries,
        ),
      ],
    );
  }

  Future<void> _calculatePotentialScore(
    SeriesDetail detail,
    List<domain.ShotImpact> impacts,
  ) async {
    if (_calculatingPotential) return;
    setState(() => _calculatingPotential = true);
    try {
      final response = await potentialScoreComputeService.calculate(
        PotentialScoreComputeRequest(
          seriesId: detail.series.id,
          seriesUpdatedAtUtc: detail.series.updatedAtUtc,
          target: detail.target,
          impacts: impacts,
          projectileDiameterMm: detail.series.projectileDiameterMm,
        ),
      );
      if (!mounted) return;
      final current = ref
          .read(seriesDetailProvider(widget.seriesId))
          .valueOrNull;
      if (current?.series.updatedAtUtc != detail.series.updatedAtUtc) return;
      setState(() => _potentialScore = response.result);
    } catch (_) {
      if (mounted) {
        AppMessenger.error(
          context,
          'Potential score kon niet worden berekend. Probeer opnieuw.',
        );
      }
    } finally {
      if (mounted) setState(() => _calculatingPotential = false);
    }
  }

  void _navigateToSeries(SeriesRecord series) {
    if (series.id == widget.seriesId) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SeriesAnalysisScreen(seriesId: series.id),
      ),
    );
  }
}

class _SeriesContextCard extends StatelessWidget {
  const _SeriesContextCard({
    required this.detail,
    required this.analysis,
    required this.occurredAtUtc,
  });

  final SeriesDetail detail;
  final SeriesAnalysis analysis;
  final DateTime occurredAtUtc;

  @override
  Widget build(BuildContext context) {
    final series = detail.series;
    final material = [
      if (detail.firearm case final firearm?) firearm.name,
      if (detail.ammoLot case final ammo?) ammo.displayName,
    ].join(' · ');
    return Card(
      key: const ValueKey('series-analysis-context'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reeks ${series.sequenceNumber}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat(
                'd MMMM yyyy · HH:mm',
                'nl_BE',
              ).format(occurredAtUtc.toLocal()),
            ),
            const SizedBox(height: 12),
            Text(
              detail.target.displayName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${series.distanceMeters.toStringAsFixed(_distanceDigits(series.distanceMeters))} m · '
              '${detail.cartridge?.name ?? '${series.projectileDiameterMm.toStringAsFixed(2)} mm'} · '
              '${series.totalScore}/${series.maximumPossibleScore} · '
              '${series.innerTenCount} X',
            ),
            if (material.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(material),
            ],
            const SizedBox(height: 8),
            Text(
              '${analysis.positionedShotCount} positionele van '
              '${analysis.actualShotCount} geregistreerde schoten',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlotModePicker extends StatelessWidget {
  const _PlotModePicker({required this.selected, required this.onChanged});

  final SeriesAnalysisPlotMode selected;
  final ValueChanged<SeriesAnalysisPlotMode> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(1) >= 1.3;
      ButtonSegment<SeriesAnalysisPlotMode> segment({
        required SeriesAnalysisPlotMode value,
        required IconData icon,
        required String label,
      }) => ButtonSegment(
        value: value,
        icon: Tooltip(message: label, child: Icon(icon)),
        label: compact ? null : Text(label),
      );
      return Semantics(
        label: 'Weergavemodus',
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<SeriesAnalysisPlotMode>(
            showSelectedIcon: false,
            segments: [
              segment(
                value: SeriesAnalysisPlotMode.target,
                icon: Icons.gps_fixed,
                label: 'Kaart',
              ),
              segment(
                value: SeriesAnalysisPlotMode.group,
                icon: Icons.adjust,
                label: 'Groep',
              ),
              segment(
                value: SeriesAnalysisPlotMode.heatmap,
                icon: Icons.blur_on,
                label: 'Warmte',
              ),
            ],
            selected: {selected},
            onSelectionChanged: (values) => onChanged(values.single),
          ),
        ),
      );
    },
  );
}

class _AdvancedMetricsCard extends StatelessWidget {
  const _AdvancedMetricsCard({required this.analysis, required this.evidence});

  final SeriesAnalysis analysis;
  final AnalysisEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final metrics = analysis.metrics;
    if (metrics.positionedShotCount < 3) return const SizedBox.shrink();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppExpandableSection(
          title: 'Meer groepsmaten',
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tik op een maat voor uitleg.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (metrics.extremeSpreadMoa case final value?)
              _MetricRow(
                label: 'Spreiding in MOA',
                value: value.toStringAsFixed(2),
                definition: MetricDefinitions.moa,
                evidence: evidence,
              ),
            if (metrics.extremeSpreadMilliradians case final value?)
              _MetricRow(
                label: 'Spreiding in millirad',
                value: value.toStringAsFixed(2),
                definition: MetricDefinitions.milliradians,
                evidence: evidence,
              ),
            if (metrics.positionedShotCount >= 10) ...[
              _MetricRow(
                label: 'R50',
                value: '${metrics.empiricalR50Mm.toStringAsFixed(1)} mm',
                definition: MetricDefinitions.empiricalR50,
                evidence: evidence,
              ),
              _MetricRow(
                label: 'R90',
                value: '${metrics.empiricalR90Mm.toStringAsFixed(1)} mm',
                definition: MetricDefinitions.empiricalR90,
                evidence: evidence,
              ),
            ],
            _MetricRow(
              label: 'Standaardafwijking horizontaal',
              value:
                  '${metrics.sampleStandardDeviationXMm.toStringAsFixed(1)} mm',
              definition: MetricDefinitions.standardDeviationX,
              evidence: evidence,
            ),
            _MetricRow(
              label: 'Standaardafwijking verticaal',
              value:
                  '${metrics.sampleStandardDeviationYMm.toStringAsFixed(1)} mm',
              definition: MetricDefinitions.standardDeviationY,
              evidence: evidence,
            ),
            _MetricRow(
              label: 'Richting spreidingsellips',
              value:
                  '${metrics.covarianceEllipse.angleDegrees.toStringAsFixed(0)}° · '
                  '${formatEllipseDirection(metrics.covarianceEllipse.angleDegrees)}',
              definition: MetricDefinitions.covarianceEllipse,
              evidence: evidence,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
    this.definition,
    this.evidence,
  });

  final String label;
  final String value;
  final MetricDefinition? definition;
  final AnalysisEvidence? evidence;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final defaultStyle = DefaultTextStyle.of(context).style;
        final valueStyle = defaultStyle.copyWith(fontWeight: FontWeight.w600);
        final textScaler = MediaQuery.textScalerOf(context);
        final textDirection = Directionality.of(context);
        final labelWidth = _measureSingleLineWidth(
          label,
          style: defaultStyle,
          textScaler: textScaler,
          textDirection: textDirection,
        );
        final valueWidth = _measureSingleLineWidth(
          value,
          style: valueStyle,
          textScaler: textScaler,
          textDirection: textDirection,
        );
        final infoWidth = definition == null ? 0.0 : 48.0;
        final requiredWidth = labelWidth + 16 + valueWidth + infoWidth;
        final useCompactLayout = requiredWidth <= constraints.maxWidth;

        if (useCompactLayout) {
          return ConstrainedBox(
            key: ValueKey('metric-row-layout-compact-$label'),
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(child: Text(label, maxLines: 1)),
                const SizedBox(width: 16),
                Text(
                  value,
                  key: ValueKey('metric-row-value-$label'),
                  maxLines: 1,
                  style: valueStyle,
                ),
                if (definition != null)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(child: Icon(Icons.info_outline, size: 18)),
                  ),
              ],
            ),
          );
        }

        return ConstrainedBox(
          key: ValueKey('metric-row-layout-stacked-$label'),
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(label)),
                  if (definition != null)
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(child: Icon(Icons.info_outline, size: 18)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                key: ValueKey('metric-row-value-$label'),
                style: valueStyle,
              ),
            ],
          ),
        );
      },
    );
    void openExplanation() => showMetricExplanationSheet(
      context: context,
      definition: definition!,
      currentValue: value,
      evidence: evidence,
    );

    return Padding(
      key: ValueKey('metric-row-$label'),
      padding: const EdgeInsets.only(top: 10),
      child: definition == null
          ? content
          : Semantics(
              button: true,
              excludeSemantics: true,
              label: '$label: $value. Open uitleg.',
              onTap: openExplanation,
              child: InkWell(
                onTap: openExplanation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: content,
                ),
              ),
            ),
    );
  }

  double _measureSingleLineWidth(
    String text, {
    required TextStyle style,
    required TextScaler textScaler,
    required ui.TextDirection textDirection,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textScaler: textScaler,
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    return painter.width;
  }
}

class _SubgroupCard extends StatelessWidget {
  const _SubgroupCard({required this.suggestion, required this.evidence});

  final SubgroupSuggestion suggestion;
  final AnalysisEvidence evidence;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: ListTile(
      leading: const Icon(Icons.bubble_chart_outlined),
      title: const Text('Mogelijk meerdere groepen'),
      subtitle: Text(
        '${suggestion.clusterCount} kandidaatgroepen · '
        'silhouette ${suggestion.silhouetteScore.toStringAsFixed(2)} · '
        'stabiliteit ${(suggestion.stability * 100).toStringAsFixed(0)}%. '
        'Geen treffer wordt automatisch uitgesloten.',
      ),
      trailing: const Icon(Icons.info_outline),
      onTap: () => showMetricExplanationSheet(
        context: context,
        definition: MetricDefinitions.subgroupDetection,
        currentValue: '${suggestion.clusterCount} kandidaatgroepen',
        evidence: evidence,
      ),
    ),
  );
}

class _PotentialScoreCard extends StatelessWidget {
  const _PotentialScoreCard({
    required this.result,
    required this.storedScore,
    required this.calculating,
    required this.enabled,
    required this.onCalculate,
    required this.evidence,
  });

  final PotentialScoreResult? result;
  final int storedScore;
  final bool calculating;
  final bool enabled;
  final VoidCallback onCalculate;
  final AnalysisEvidence evidence;

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('potential-score-card'),
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Potential score',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Leg potential score uit',
                onPressed: () => showMetricExplanationSheet(
                  context: context,
                  definition: MetricDefinitions.potentialScore,
                  currentValue: result == null
                      ? null
                      : '${result!.bestScore}/${result!.maximumPossible}',
                  evidence: evidence,
                ),
                icon: const Icon(Icons.info_outline),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Wat zou hetzelfde trefbeeld scoren als het alleen als geheel '
            'beter gecentreerd werd?',
          ),
          if (result case final value?) ...[
            const SizedBox(height: 12),
            Text(
              '${value.currentScore}/${value.maximumPossible} → '
              '${value.bestScore}/${value.maximumPossible} · '
              'centreerwinst +${value.groupCenteringGain}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Verschuiving: ${formatHorizontalBias(value.translationXMm)}, '
              '${formatVerticalBias(value.translationYMm)}. '
              'Resterende scorekloof: ${value.remainingGap} punten.',
            ),
            if (value.currentScore != storedScore) ...[
              const SizedBox(height: 8),
              Text(
                'De historische score blijft $storedScore. De huidige '
                'what-if-engine berekende ${value.currentScore} als '
                'uitgangspunt en overschrijft niets.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
          const SizedBox(height: 10),
          Text(
            'Beschrijvende what-ifanalyse, geen automatisch vizieradvies.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: enabled && !calculating ? onCalculate : null,
            icon: calculating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.center_focus_strong),
            label: Text(
              calculating
                  ? 'Berekenen…'
                  : result == null
                  ? 'Potential score berekenen'
                  : 'Opnieuw berekenen',
            ),
          ),
        ],
      ),
    ),
  );
}

class _SeriesNavigationCard extends StatelessWidget {
  const _SeriesNavigationCard({
    required this.currentSequence,
    required this.currentIndex,
    required this.total,
    required this.previous,
    required this.next,
    required this.onNavigate,
  });

  final int currentSequence;
  final int currentIndex;
  final int total;
  final SeriesRecord? previous;
  final SeriesRecord? next;
  final ValueChanged<SeriesRecord> onNavigate;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            total == 0
                ? 'Reeks $currentSequence'
                : 'Reeks ${currentIndex + 1} van $total',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('previous-series-analysis'),
                  onPressed: previous == null
                      ? null
                      : () => onNavigate(previous!),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Vorige'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('next-series-analysis'),
                  onPressed: next == null ? null : () => onNavigate(next!),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Volgende'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SeriesNavigation {
  const _SeriesNavigation({
    required this.currentIndex,
    required this.total,
    this.previous,
    this.next,
  });

  final int currentIndex;
  final int total;
  final SeriesRecord? previous;
  final SeriesRecord? next;
}

_SeriesNavigation _navigationFor(List<SeriesRecord> source, String currentId) {
  final series =
      source
          .where(
            (item) =>
                item.status == domain.SeriesStatus.confirmed.name ||
                item.id == currentId,
          )
          .toList(growable: false)
        ..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
  final index = series.indexWhere((item) => item.id == currentId);
  if (index < 0) {
    return const _SeriesNavigation(currentIndex: 0, total: 0);
  }
  return _SeriesNavigation(
    currentIndex: index,
    total: series.length,
    previous: index > 0 ? series[index - 1] : null,
    next: index + 1 < series.length ? series[index + 1] : null,
  );
}

int _distanceDigits(double value) => value == value.roundToDouble() ? 0 : 1;
