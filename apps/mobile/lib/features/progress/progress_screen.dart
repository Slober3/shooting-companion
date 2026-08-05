import 'dart:math' as math;
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_analysis/analysis.dart';
import 'package:shooting_companion_coaching/coaching.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/compact_page_scaffold.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/safe_sheet_scaffold.dart';
import '../../widgets/app_notice.dart';
import 'analysis_adapter.dart';
import 'goal_editor_sheet.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  _AnalysisFilters _filters = const _AnalysisFilters();
  _AnalysisSection _section = _AnalysisSection.overview;
  List<AnalysisSeriesData>? _cachedSource;
  List<AnalyzedSeriesView> _cachedAnalysis = const [];

  @override
  Widget build(BuildContext context) {
    final dataset = ref.watch(analysisDatasetProvider);
    final targets =
        ref.watch(allTargetProfilesProvider).valueOrNull ?? const [];
    final firearms = ref.watch(allFirearmsProvider).valueOrNull ?? const [];
    final ammoLots = ref.watch(allAmmoLotsProvider).valueOrNull ?? const [];

    return CompactPageScaffold(
      title: 'Analyse',
      actions: [
        Semantics(
          button: true,
          label: _filters.activeCount == 0
              ? 'Analysefilters'
              : 'Analysefilters, ${_filters.activeCount} actief',
          child: IconButton(
            tooltip: 'Filters',
            onPressed: () => _showFilters(
              targets: targets,
              firearms: firearms,
              ammoLots: ammoLots,
            ),
            icon: Badge(
              isLabelVisible: _filters.activeCount > 0,
              label: Text('${_filters.activeCount}'),
              child: const Icon(Icons.tune),
            ),
          ),
        ),
      ],
      body: dataset.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MessagePanel(
          icon: Icons.error_outline,
          message: 'Analyse laden mislukt: $error',
        ),
        data: (allData) {
          final targetNames = {
            for (final target in targets)
              target.versionedId: target.displayName,
          };
          final filteredData = _filters.applyData(allData);
          final items = filteredData
              .map((item) => item.series)
              .toList(growable: false);
          final analysis = _analysisFor(allData)
              .where(
                (item) => filteredData.any(
                  (source) => source.series.id == item.source.series.id,
                ),
              )
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(analysisDatasetProvider);
              await ref.read(analysisDatasetProvider.future);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
                if (_filters.activeCount > 0) ...[
                  _ActiveFilterSummary(
                    filters: _filters,
                    targetNames: targetNames,
                    firearmNames: {
                      for (final firearm in firearms) firearm.id: firearm.name,
                    },
                    ammoNames: {
                      for (final ammo in ammoLots) ammo.id: ammo.displayName,
                    },
                    onClear: () =>
                        setState(() => _filters = const _AnalysisFilters()),
                  ),
                  const SizedBox(height: 12),
                ],
                if (allData.isEmpty)
                  const _MessagePanel(
                    icon: Icons.insights_outlined,
                    message: 'Sla minstens één reeks op om je analyse te zien.',
                  )
                else if (items.isEmpty)
                  const _MessagePanel(
                    icon: Icons.filter_alt_off,
                    message: 'Geen reeksen passen bij deze filters.',
                  )
                else ...[
                  _AnalysisSectionPicker(
                    selected: _section,
                    onChanged: (value) => setState(() => _section = value),
                  ),
                  const SizedBox(height: 16),
                  switch (_section) {
                    _AnalysisSection.overview => Column(
                      children: [
                        _Overview(items: items),
                        const SizedBox(height: 16),
                        _TrendCard(items: items),
                        const SizedBox(height: 16),
                        _Breakdown(items: items, targetNames: targetNames),
                        const SizedBox(height: 16),
                        _GoalsCard(
                          goals:
                              ref.watch(activeGoalsProvider).valueOrNull ??
                              const [],
                          targetNames: targetNames,
                          onAdd: () => _showGoalEditor(
                            targets: targets,
                            firearms: firearms,
                            ammoLots: ammoLots,
                          ),
                          onDelete: (id) =>
                              ref.read(repositoryProvider).deleteGoal(id),
                        ),
                      ],
                    ),
                    _AnalysisSection.groups => _GroupAnalysisSection(
                      items: analysis,
                      onPotentialScore: _showPotentialScore,
                    ),
                    _AnalysisSection.coach => _CoachSection(
                      insights: buildCoachInsights(analysis),
                      feedback:
                          ref.watch(coachFeedbackProvider).valueOrNull ??
                          const [],
                      onFeedback: _saveCoachFeedback,
                    ),
                  },
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<AnalyzedSeriesView> _analysisFor(List<AnalysisSeriesData> source) {
    if (identical(_cachedSource, source)) return _cachedAnalysis;
    _cachedSource = source;
    _cachedAnalysis = analyzeSeriesDataset(source);
    return _cachedAnalysis;
  }

  Future<void> _showPotentialScore(AnalyzedSeriesView item) async {
    AppMessenger.info(context, 'Mogelijke centreerwinst berekenen…');
    final result = await Isolate.run(
      () => PotentialScoreAnalyzer.analyze(
        target: item.target,
        impacts: item.impacts,
        projectileDiameterMm: item.source.series.projectileDiameterMm,
      ),
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potential score'),
        content: Text(
          'Huidig: ${result.currentScore}/${result.maximumPossible}\n'
          'Beste score met hetzelfde trefbeeld: ${result.bestScore}/${result.maximumPossible}\n'
          'Centreerwinst: +${result.groupCenteringGain}\n'
          'Verschuiving: ${_signedMm(result.translationXMm)} horizontaal, '
          '${_signedMm(result.translationYMm)} verticaal\n\n'
          'Dit is een reproduceerbare what-ifanalyse, geen automatisch '
          'vizieradvies.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCoachFeedback(
    CoachInsight insight,
    StoredCoachFeedbackResponse response,
  ) async {
    await ref
        .read(repositoryProvider)
        .saveCoachFeedback(
          insightFingerprint: insight.fingerprint,
          ruleId: insight.ruleId,
          ruleVersion: insight.ruleVersion,
          response: response,
          snoozedUntilUtc: response == StoredCoachFeedbackResponse.later
              ? DateTime.now().toUtc().add(const Duration(days: 14))
              : null,
        );
    if (mounted) AppMessenger.success(context, 'Coachvoorkeur bewaard');
  }

  Future<void> _showGoalEditor({
    required List<TargetProfileRecord> targets,
    required List<FirearmRecord> firearms,
    required List<AmmoLotRecord> ammoLots,
  }) async {
    final draft = await showGoalEditorSheet(
      context: context,
      targets: targets,
      firearms: firearms,
      ammoLots: ammoLots,
    );
    if (draft == null || !mounted) return;
    await ref
        .read(repositoryProvider)
        .saveGoal(
          targetProfileVersionedId: draft.targetProfileVersionedId,
          distanceMeters: draft.distanceMeters,
          firearmId: draft.firearmId,
          ammoLotId: draft.ammoLotId,
          metric: draft.metric,
          targetValue: draft.targetValue,
          comparison: draft.comparison,
        );
    if (mounted) AppMessenger.success(context, 'Persoonlijk doel bewaard');
  }

  Future<void> _showFilters({
    required List<TargetProfileRecord> targets,
    required List<FirearmRecord> firearms,
    required List<AmmoLotRecord> ammoLots,
  }) async {
    final allSeries = await ref.read(repositoryProvider).getConfirmedSeries();
    if (!mounted) return;
    final result = await showSafeModalSheet<_AnalysisFilters>(
      context: context,
      builder: (context) => _FilterSheet(
        initial: _filters,
        targets: targets,
        firearms: firearms,
        ammoLots: ammoLots,
        distances: allSeries.map((item) => item.distanceMeters).toSet().toList()
          ..sort(),
      ),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.items});

  final List<SeriesRecord> items;

  @override
  Widget build(BuildContext context) {
    final shots = items.fold(0, (sum, item) => sum + item.shotCount);
    final percentages = items.map(_percentage).toList();
    final average = percentages.reduce((a, b) => a + b) / items.length;
    final best = percentages.reduce(math.max);

    return ResponsiveMetricGrid(
      items: [
        MetricItem(
          label: 'Reeksen',
          value: '${items.length}',
          icon: Icons.layers_outlined,
        ),
        MetricItem(label: 'Schoten', value: '$shots', icon: Icons.adjust),
        MetricItem(
          label: 'Gemiddelde score',
          value: '${average.toStringAsFixed(1)}%',
          icon: Icons.show_chart,
        ),
        MetricItem(
          label: 'Beste score',
          value: '${best.toStringAsFixed(1)}%',
          icon: Icons.emoji_events_outlined,
        ),
      ],
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.goals,
    required this.targetNames,
    required this.onAdd,
    required this.onDelete,
  });

  final List<GoalRecord> goals;
  final Map<String, String> targetNames;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 360 ||
                  MediaQuery.textScalerOf(context).scale(1) >= 1.5;
              final title = Text(
                'Persoonlijke doelen',
                style: Theme.of(context).textTheme.titleMedium,
              );
              final addButton = TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Toevoegen'),
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.centerLeft, child: addButton),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  addButton,
                ],
              );
            },
          ),
          if (goals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Stel een doel in voor score, groepsgrootte, afwijking of '
                'trainingsfrequentie.',
              ),
            )
          else
            for (final goal in goals)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined),
                title: Text(
                  '${goalMetricLabel(GoalMetric.values.firstWhere((value) => value.name == goal.metric, orElse: () => GoalMetric.scorePercentage))}: ${goal.targetValue.toStringAsFixed(goal.targetValue == goal.targetValue.roundToDouble() ? 0 : 1)}${goalMetricUnit(GoalMetric.values.firstWhere((value) => value.name == goal.metric, orElse: () => GoalMetric.scorePercentage))}',
                ),
                subtitle: Text(
                  '${targetNames[goal.targetProfileVersionedId] ?? _fallbackTargetName(goal.targetProfileVersionedId)} · '
                  '${goal.distanceMeters.toStringAsFixed(_distanceDigits(goal.distanceMeters))} m',
                ),
                trailing: IconButton(
                  tooltip: 'Doel verwijderen',
                  onPressed: () => onDelete(goal.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
        ],
      ),
    ),
  );
}

enum _AnalysisSection { overview, groups, coach }

class _AnalysisSectionPicker extends StatelessWidget {
  const _AnalysisSectionPicker({
    required this.selected,
    required this.onChanged,
  });

  final _AnalysisSection selected;
  final ValueChanged<_AnalysisSection> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final compact = constraints.maxWidth < 390 || textScale > 1.3;
      return SizedBox(
        width: double.infinity,
        child: SegmentedButton<_AnalysisSection>(
          segments: [
            _segment(
              value: _AnalysisSection.overview,
              icon: Icons.dashboard_outlined,
              label: 'Overzicht',
              compact: compact,
            ),
            _segment(
              value: _AnalysisSection.groups,
              icon: Icons.adjust,
              label: 'Groepen',
              compact: compact,
            ),
            _segment(
              value: _AnalysisSection.coach,
              icon: Icons.lightbulb_outline,
              label: 'Coach',
              compact: compact,
            ),
          ],
          selected: {selected},
          onSelectionChanged: (value) => onChanged(value.single),
          showSelectedIcon: false,
        ),
      );
    },
  );

  ButtonSegment<_AnalysisSection> _segment({
    required _AnalysisSection value,
    required IconData icon,
    required String label,
    required bool compact,
  }) => ButtonSegment(
    value: value,
    icon: Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        selected: selected == value,
        excludeSemantics: true,
        child: Icon(icon),
      ),
    ),
    label: compact ? null : Text(label),
  );
}

class _GroupAnalysisSection extends StatefulWidget {
  const _GroupAnalysisSection({
    required this.items,
    required this.onPotentialScore,
  });

  final List<AnalyzedSeriesView> items;
  final ValueChanged<AnalyzedSeriesView> onPotentialScore;

  @override
  State<_GroupAnalysisSection> createState() => _GroupAnalysisSectionState();
}

class _GroupAnalysisSectionState extends State<_GroupAnalysisSection> {
  bool _showDensity = true;

  @override
  Widget build(BuildContext context) {
    final usable =
        widget.items
            .where((item) => item.analysis.positionedShotCount > 0)
            .toList(growable: false)
          ..sort(
            (a, b) => b.source.series.createdAtUtc.compareTo(
              a.source.series.createdAtUtc,
            ),
          );
    if (usable.isEmpty) {
      return const _MessagePanel(
        icon: Icons.adjust,
        message: 'Geen positionele treffers beschikbaar voor groepsanalyse.',
      );
    }
    final item = usable.first;
    final metrics = item.analysis.metrics;
    final comparable = usable
        .where(
          (candidate) =>
              candidate.source.series.targetProfileVersionedId ==
                  item.source.series.targetProfileVersionedId &&
              (candidate.source.series.distanceMeters -
                          item.source.series.distanceMeters)
                      .abs() <
                  0.000001 &&
              candidate.source.series.firearmId ==
                  item.source.series.firearmId &&
              candidate.source.series.ammoLotId == item.source.series.ammoLotId,
        )
        .take(20)
        .map(cohortInputFromAnalyzed)
        .toList(growable: false);
    final cohort = CohortAnalyzer.analyze(comparable);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laatste vergelijkbare trefbeeld',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.target.displayName} · '
                  '${item.source.series.distanceMeters.toStringAsFixed(_distanceDigits(item.source.series.distanceMeters))} m · '
                  '${metrics.positionedShotCount} positionele schoten',
                ),
                const SizedBox(height: 16),
                _GroupPlot(analysis: item.analysis, showDensity: _showDensity),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilterChip(
                    selected: _showDensity,
                    avatar: const Icon(Icons.blur_on, size: 18),
                    label: const Text('Warmtebeeld'),
                    onSelected: (value) => setState(() => _showDensity = value),
                  ),
                ),
                const SizedBox(height: 16),
                ResponsiveMetricGrid(
                  items: [
                    MetricItem(
                      label: 'Mean radius',
                      value: '${metrics.meanRadiusMm.toStringAsFixed(1)} mm',
                      icon: Icons.radio_button_checked,
                    ),
                    MetricItem(
                      label: 'Extreme spreiding',
                      value: '${metrics.extremeSpreadMm.toStringAsFixed(1)} mm',
                      icon: Icons.open_in_full,
                    ),
                    MetricItem(
                      label: 'Horizontale bias',
                      value: _signedMm(metrics.horizontalBiasMm),
                      icon: Icons.swap_horiz,
                    ),
                    MetricItem(
                      label: 'Verticale bias',
                      value: _signedMm(metrics.verticalBiasMm),
                      icon: Icons.swap_vert,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _reliabilityText(item.analysis.reliability),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (item.analysis.subgroupSuggestion case final suggestion?)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bubble_chart_outlined),
                      title: const Text('Mogelijk meerdere groepen'),
                      subtitle: Text(
                        '${suggestion.clusterCount} kandidaten · '
                        'silhouette ${suggestion.silhouetteScore.toStringAsFixed(2)} · '
                        'stabiliteit ${(suggestion.stability * 100).toStringAsFixed(0)}%',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => widget.onPotentialScore(item),
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Potential score berekenen'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vergelijkbare reeksen',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${comparable.length} reeks${comparable.length == 1 ? '' : 'en'} · '
                  '${cohort.pooledMetrics.positionedShotCount} positionele schoten',
                ),
                const SizedBox(height: 16),
                ResponsiveMetricGrid(
                  items: [
                    MetricItem(
                      label: 'Gezamenlijke mean radius',
                      value:
                          '${cohort.pooledMetrics.meanRadiusMm.toStringAsFixed(1)} mm',
                      icon: Icons.track_changes,
                    ),
                    MetricItem(
                      label: 'Scorevariatie',
                      value:
                          '${cohort.consistency.scoreStandardDeviation.toStringAsFixed(1)} pp',
                      icon: Icons.multiline_chart,
                    ),
                    MetricItem(
                      label: 'Trend per reeks',
                      value:
                          '${cohort.scoreTrend.linearSlopePercentagePointsPerSeries >= 0 ? '+' : ''}'
                          '${cohort.scoreTrend.linearSlopePercentagePointsPerSeries.toStringAsFixed(1)} pp',
                      icon: Icons.trending_up,
                    ),
                    MetricItem(
                      label: 'R90',
                      value:
                          '${cohort.pooledMetrics.empiricalR90Mm.toStringAsFixed(1)} mm',
                      icon: Icons.blur_circular,
                    ),
                  ],
                ),
                if (cohort.comparisonWarnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final warning in cohort.comparisonWarnings)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        warning,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        if (usable.length > 1) ...[
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recente groepsmetingen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final series in usable.take(10))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Reeks ${series.source.series.sequenceNumber}',
                      ),
                      subtitle: Text(
                        '${series.analysis.metrics.positionedShotCount} schoten · '
                        '${series.analysis.metrics.meanRadiusMm.toStringAsFixed(1)} mm mean radius',
                      ),
                      trailing: Text(
                        '${series.scorePercentage.toStringAsFixed(1)}%',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GroupPlot extends StatelessWidget {
  const _GroupPlot({required this.analysis, required this.showDensity});

  final SeriesAnalysis analysis;
  final bool showDensity;

  @override
  Widget build(BuildContext context) {
    final metrics = analysis.metrics;
    final summary =
        'Trefbeeld met ${metrics.positionedShotCount} positionele schoten. '
        'Groepscentrum ${_signedMm(metrics.horizontalBiasMm)} horizontaal en '
        '${_signedMm(metrics.verticalBiasMm)} verticaal. '
        'Mean radius ${metrics.meanRadiusMm.toStringAsFixed(1)} millimeter.';
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: CustomPaint(
              painter: _GroupPlotPainter(
                analysis: analysis,
                showDensity: showDensity,
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupPlotPainter extends CustomPainter {
  const _GroupPlotPainter({
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
        final radius = math.max(12.0, 6 + point.multiplicity * 2.0);
        canvas.drawCircle(
          location,
          radius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                colorScheme.tertiary.withValues(alpha: 0.42),
                colorScheme.tertiary.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: location, radius: radius)),
        );
      }
    }

    final ellipse = metrics.covarianceEllipse;
    final ellipseCenter = project(metrics.centroidXMm, metrics.centroidYMm);
    canvas.save();
    canvas.translate(ellipseCenter.dx, ellipseCenter.dy);
    canvas.rotate(ellipse.angleDegrees * math.pi / 180);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: math.max(2, ellipse.semiMajorAxisMm * 4 * scale),
        height: math.max(2, ellipse.semiMinorAxisMm * 4 * scale),
      ),
      Paint()
        ..color = colorScheme.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();

    for (final point in positions) {
      final location = project(point.xMm, point.yMm);
      canvas.drawCircle(
        location,
        4.5,
        Paint()
          ..color = point.isPositionUncertain
              ? colorScheme.error
              : colorScheme.primary
          ..style = PaintingStyle.fill,
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

  @override
  bool shouldRepaint(covariant _GroupPlotPainter oldDelegate) =>
      oldDelegate.analysis != analysis ||
      oldDelegate.showDensity != showDensity ||
      oldDelegate.colorScheme != colorScheme;
}

class _CoachSection extends StatelessWidget {
  const _CoachSection({
    required this.insights,
    required this.feedback,
    required this.onFeedback,
  });

  final List<CoachInsight> insights;
  final List<CoachFeedbackRecord> feedback;
  final void Function(
    CoachInsight insight,
    StoredCoachFeedbackResponse response,
  )
  onFeedback;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final feedbackById = {
      for (final item in feedback) item.insightFingerprint: item,
    };
    final visible = insights
        .where((insight) {
          final stored = feedbackById[insight.fingerprint];
          if (stored == null) return true;
          if (stored.response == StoredCoachFeedbackResponse.dismiss.name) {
            return false;
          }
          if (stored.response == StoredCoachFeedbackResponse.later.name &&
              stored.snoozedUntilUtc?.isAfter(now) == true) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    if (visible.isEmpty) {
      return const _MessagePanel(
        icon: Icons.lightbulb_outline,
        message:
            'Nog onvoldoende vergelijkbare gegevens voor voorzichtige '
            'coachinzichten. Minimaal 3 reeksen en 30 positionele treffers '
            'zijn nodig.',
      );
    }
    return Column(
      children: [
        for (final insight in visible) ...[
          _CoachInsightCard(insight: insight, onFeedback: onFeedback),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CoachInsightCard extends StatelessWidget {
  const _CoachInsightCard({required this.insight, required this.onFeedback});

  final CoachInsight insight;
  final void Function(
    CoachInsight insight,
    StoredCoachFeedbackResponse response,
  )
  onFeedback;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                insight.evidenceStrength == CoachEvidenceStrength.strong
                    ? Icons.verified_outlined
                    : Icons.science_outlined,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Waarneming',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                insight.evidenceStrength == CoachEvidenceStrength.strong
                    ? 'Sterker bewijs'
                    : 'Voorlopig',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(insight.observation),
          const SizedBox(height: 16),
          _CoachPart(title: 'Bewijs', body: insight.evidence.summary),
          _CoachPart(
            title: 'Mogelijke verklaringen',
            body: insight.possibleExplanations
                .map((item) => '${item.title}: ${item.detail}')
                .join('\n\n'),
          ),
          _CoachPart(
            title: 'Probeer dit',
            body:
                '${insight.proposedExperiment.title}\n'
                '${insight.proposedExperiment.instructions}',
          ),
          _CoachPart(
            title: 'Meet volgende keer',
            body:
                '${insight.nextMeasurement.label}\n'
                '${insight.nextMeasurement.instructions}',
          ),
          if (insight.warnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                insight.warnings.join('\n'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () =>
                    onFeedback(insight, StoredCoachFeedbackResponse.useful),
                icon: const Icon(Icons.thumb_up_outlined),
                label: const Text('Nuttig'),
              ),
              TextButton(
                onPressed: () =>
                    onFeedback(insight, StoredCoachFeedbackResponse.notUseful),
                child: const Text('Niet nuttig'),
              ),
              TextButton(
                onPressed: () =>
                    onFeedback(insight, StoredCoachFeedbackResponse.later),
                child: const Text('Later'),
              ),
              TextButton(
                onPressed: () =>
                    onFeedback(insight, StoredCoachFeedbackResponse.dismiss),
                child: const Text('Niet meer tonen'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _CoachPart extends StatelessWidget {
  const _CoachPart({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(body),
      ],
    ),
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.items});

  final List<SeriesRecord> items;

  @override
  Widget build(BuildContext context) {
    final values = items.map(_percentage).toList();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scoretrend', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Percentage van de maximumscore per reeks'),
            const SizedBox(height: 16),
            Semantics(
              label:
                  'Scoretrend van ${values.first.toStringAsFixed(1)} tot ${values.last.toStringAsFixed(1)} procent',
              image: true,
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: _TrendPainter(values, Theme.of(context).colorScheme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.scheme);

  final List<double> values;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = scheme.outlineVariant;
    for (final percentage in [0.25, 0.5, 0.75, 1.0]) {
      final y = size.height * (1 - percentage);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final linePaint = Paint()
      ..color = scheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (values.length == 1) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height * (1 - values.first / 100)),
        5,
        linePaint..style = PaintingStyle.fill,
      );
      return;
    }
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = index / (values.length - 1) * size.width;
      final y = size.height * (1 - values[index].clamp(0, 100) / 100);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.scheme != scheme;
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.items, required this.targetNames});

  final List<SeriesRecord> items;
  final Map<String, String> targetNames;

  @override
  Widget build(BuildContext context) {
    final groups = <_ComparableGroup, List<SeriesRecord>>{};
    for (final item in items) {
      final key = _ComparableGroup(
        targetId: item.targetProfileVersionedId,
        distanceMeters: item.distanceMeters,
      );
      groups.putIfAbsent(key, () => []).add(item);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vergelijkbare reeksen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final entry in groups.entries)
              _BreakdownRow(
                title:
                    targetNames[entry.key.targetId] ??
                    _fallbackTargetName(entry.key.targetId),
                subtitle:
                    '${entry.key.distanceMeters.toStringAsFixed(_distanceDigits(entry.key.distanceMeters))} m · ${entry.value.length} ${entry.value.length == 1 ? 'reeks' : 'reeksen'}',
                percentage:
                    '${_groupPercentage(entry.value).toStringAsFixed(1)}%',
              ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.title,
    required this.subtitle,
    required this.percentage,
  });

  final String title;
  final String subtitle;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final score = Text(
      percentage,
      style: Theme.of(context).textTheme.titleMedium,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                score,
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                score,
              ],
            ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
    child: Column(
      children: [
        Icon(icon, size: 40),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _ActiveFilterSummary extends StatelessWidget {
  const _ActiveFilterSummary({
    required this.filters,
    required this.targetNames,
    required this.firearmNames,
    required this.ammoNames,
    required this.onClear,
  });

  final _AnalysisFilters filters;
  final Map<String, String> targetNames;
  final Map<String, String> firearmNames;
  final Map<String, String> ammoNames;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (filters.period != _AnalysisPeriod.all)
        Chip(label: Text(filters.period.label)),
      if (filters.targetId case final id?)
        Chip(label: Text(targetNames[id] ?? _fallbackTargetName(id))),
      if (filters.distanceMeters case final distance?)
        Chip(
          label: Text(
            '${distance.toStringAsFixed(_distanceDigits(distance))} m',
          ),
        ),
      if (filters.firearmId case final id?)
        Chip(label: Text(firearmNames[id] ?? 'Onbekend wapen')),
      if (filters.ammoLotId case final id?)
        Chip(label: Text(ammoNames[id] ?? 'Onbekende munitie')),
      TextButton(onPressed: onClear, child: const Text('Wis filters')),
    ],
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.targets,
    required this.firearms,
    required this.ammoLots,
    required this.distances,
  });

  final _AnalysisFilters initial;
  final List<TargetProfileRecord> targets;
  final List<FirearmRecord> firearms;
  final List<AmmoLotRecord> ammoLots;
  final List<double> distances;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _AnalysisFilters filters;

  @override
  void initState() {
    super.initState();
    filters = widget.initial;
  }

  @override
  Widget build(BuildContext context) => SafeSheetScaffold(
    title: 'Analysefilters',
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context, filters),
        child: const Text('Filters toepassen'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, const _AnalysisFilters()),
        child: const Text('Alles wissen'),
      ),
    ],
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelectField<_AnalysisPeriod>(
          key: ValueKey(filters.period),
          label: 'Periode',
          initialValue: filters.period,
          options: [
            for (final period in _AnalysisPeriod.values)
              AppSelectOption(value: period, label: period.label),
          ],
          onChanged: (value) =>
              setState(() => filters = filters.copyWith(period: value)),
        ),
        const SizedBox(height: 16),
        _NullableDropdown<String>(
          label: 'Kaart',
          value: filters.targetId,
          items: {
            for (final target in widget.targets)
              target.versionedId: target.displayName,
          },
          onChanged: (value) => setState(
            () => filters = filters.copyWith(
              targetId: value,
              clearTarget: value == null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _NullableDropdown<double>(
          label: 'Afstand',
          value: filters.distanceMeters,
          items: {
            for (final distance in widget.distances)
              distance:
                  '${distance.toStringAsFixed(_distanceDigits(distance))} m',
          },
          onChanged: (value) => setState(
            () => filters = filters.copyWith(
              distanceMeters: value,
              clearDistance: value == null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _NullableDropdown<String>(
          label: 'Wapen',
          value: filters.firearmId,
          items: {
            for (final firearm in widget.firearms) firearm.id: firearm.name,
          },
          onChanged: (value) => setState(
            () => filters = filters.copyWith(
              firearmId: value,
              clearFirearm: value == null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _NullableDropdown<String>(
          label: 'Munitie',
          value: filters.ammoLotId,
          items: {
            for (final ammo in widget.ammoLots) ammo.id: ammo.displayName,
          },
          onChanged: (value) => setState(
            () => filters = filters.copyWith(
              ammoLotId: value,
              clearAmmo: value == null,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NullableDropdown<T> extends StatelessWidget {
  const _NullableDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => AppSelectField<T?>(
    key: ValueKey(value),
    label: label,
    initialValue: value,
    options: [
      AppSelectOption<T?>(value: null, label: 'Alle'),
      for (final entry in items.entries)
        AppSelectOption<T?>(value: entry.key, label: entry.value),
    ],
    onChanged: onChanged,
  );
}

enum _AnalysisPeriod {
  all('Alle datums'),
  last30Days('Laatste 30 dagen'),
  last90Days('Laatste 90 dagen'),
  lastYear('Laatste 12 maanden');

  const _AnalysisPeriod(this.label);
  final String label;
}

class _AnalysisFilters {
  const _AnalysisFilters({
    this.period = _AnalysisPeriod.all,
    this.targetId,
    this.distanceMeters,
    this.firearmId,
    this.ammoLotId,
  });

  final _AnalysisPeriod period;
  final String? targetId;
  final double? distanceMeters;
  final String? firearmId;
  final String? ammoLotId;

  int get activeCount =>
      (period == _AnalysisPeriod.all ? 0 : 1) +
      (targetId == null ? 0 : 1) +
      (distanceMeters == null ? 0 : 1) +
      (firearmId == null ? 0 : 1) +
      (ammoLotId == null ? 0 : 1);

  List<SeriesRecord> apply(List<SeriesRecord> items) {
    final cutoff = switch (period) {
      _AnalysisPeriod.all => null,
      _AnalysisPeriod.last30Days => DateTime.now().toUtc().subtract(
        const Duration(days: 30),
      ),
      _AnalysisPeriod.last90Days => DateTime.now().toUtc().subtract(
        const Duration(days: 90),
      ),
      _AnalysisPeriod.lastYear => DateTime.now().toUtc().subtract(
        const Duration(days: 365),
      ),
    };
    return items.where((item) {
      if (cutoff != null && item.createdAtUtc.isBefore(cutoff)) return false;
      if (targetId != null && item.targetProfileVersionedId != targetId) {
        return false;
      }
      if (distanceMeters != null &&
          (item.distanceMeters - distanceMeters!).abs() > 0.0001) {
        return false;
      }
      if (firearmId != null && item.firearmId != firearmId) return false;
      if (ammoLotId != null && item.ammoLotId != ammoLotId) return false;
      return true;
    }).toList();
  }

  List<AnalysisSeriesData> applyData(List<AnalysisSeriesData> items) {
    final acceptedIds = apply(
      items.map((item) => item.series).toList(growable: false),
    ).map((item) => item.id).toSet();
    return items
        .where((item) => acceptedIds.contains(item.series.id))
        .toList(growable: false);
  }

  _AnalysisFilters copyWith({
    _AnalysisPeriod? period,
    String? targetId,
    double? distanceMeters,
    String? firearmId,
    String? ammoLotId,
    bool clearTarget = false,
    bool clearDistance = false,
    bool clearFirearm = false,
    bool clearAmmo = false,
  }) => _AnalysisFilters(
    period: period ?? this.period,
    targetId: clearTarget ? null : targetId ?? this.targetId,
    distanceMeters: clearDistance
        ? null
        : distanceMeters ?? this.distanceMeters,
    firearmId: clearFirearm ? null : firearmId ?? this.firearmId,
    ammoLotId: clearAmmo ? null : ammoLotId ?? this.ammoLotId,
  );
}

class _ComparableGroup {
  const _ComparableGroup({
    required this.targetId,
    required this.distanceMeters,
  });

  final String targetId;
  final double distanceMeters;

  @override
  bool operator ==(Object other) =>
      other is _ComparableGroup &&
      other.targetId == targetId &&
      other.distanceMeters == distanceMeters;

  @override
  int get hashCode => Object.hash(targetId, distanceMeters);
}

double _percentage(SeriesRecord item) => item.maximumPossibleScore <= 0
    ? 0
    : item.totalScore / item.maximumPossibleScore * 100;

double _groupPercentage(List<SeriesRecord> items) {
  final total = items.fold(0, (sum, item) => sum + item.totalScore);
  final maximum = items.fold(0, (sum, item) => sum + item.maximumPossibleScore);
  return maximum <= 0 ? 0 : total / maximum * 100;
}

int _distanceDigits(double distance) =>
    distance == distance.roundToDouble() ? 0 : 1;

String _fallbackTargetName(String versionedId) {
  final profileId = versionedId.split('@').first;
  return profileId
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _signedMm(double value) {
  final normalized = value.abs() < 0.05 ? 0.0 : value;
  final sign = normalized > 0 ? '+' : '';
  return '$sign${normalized.toStringAsFixed(1)} mm';
}

String _reliabilityText(AnalysisReliability reliability) =>
    switch (reliability) {
      AnalysisReliability.noPositionData => 'Geen positionele gegevens.',
      AnalysisReliability.positionsOnly =>
        'Alleen posities: te weinig schoten voor groepsmaten.',
      AnalysisReliability.provisional =>
        'Voorlopige groepsmaten door de kleine steekproef.',
      AnalysisReliability.smallSample =>
        'Bruikbare beschrijving, maar nog een kleine steekproef.',
      AnalysisReliability.full => 'Volledige beschrijvende reeksanalyse.',
    };
