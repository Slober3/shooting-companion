import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_training/training.dart';

import '../../app/providers.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_action_dock.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/compact_page_scaffold.dart';
import 'drill_plan_screen.dart';
import 'guided_drill_runner_screen.dart';

/// The production V2 drill catalogue. Legacy V1 records are deliberately only
/// shown in history and can never enter the guided runner.
class DrillLibraryScreen extends ConsumerStatefulWidget {
  const DrillLibraryScreen({this.onDrillSelected, super.key});

  final ValueChanged<DrillDefinitionV2>? onDrillSelected;

  @override
  ConsumerState<DrillLibraryScreen> createState() => _DrillLibraryScreenState();
}

class _DrillLibraryScreenState extends ConsumerState<DrillLibraryScreen> {
  String _query = '';
  TrainingDiscipline? _discipline;
  TrainingSkillLevel? _level;

  @override
  Widget build(BuildContext context) {
    final catalog = BuiltInTrainingContent.catalog;
    final query = _query.trim().toLowerCase();
    final drills = catalog.drills
        .where((drill) {
          final disciplineMatches =
              _discipline == null ||
              drill.discipline == _discipline ||
              drill.discipline == TrainingDiscipline.universal;
          final levelMatches = _level == null || drill.skillLevel == _level;
          final searchMatches =
              query.isEmpty ||
              drill.title.toLowerCase().contains(query) ||
              drill.shortPurpose.toLowerCase().contains(query) ||
              drill.setup.dataBasis.toLowerCase().contains(query);
          return disciplineMatches && levelMatches && searchMatches;
        })
        .toList(growable: false);

    final overviews = ref.watch(guidedTrainingActivityOverviewsProvider);
    return CompactPageScaffold(
      title: 'Drillbibliotheek',
      body: ListView(
        key: const ValueKey('drill-library-list'),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          32 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Text(
            'Elke begeleide drill koppelt echte bevestigde reeksen. '
            'Voortgang, meetbasis en inhoudsversie blijven lokaal bewaard.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          if (widget.onDrillSelected == null)
            _PlannerEntryCard(
              onOpen: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => DeterministicDrillPlannerScreen(
                    drills: catalog.drills,
                    learningPaths: catalog.learningPaths,
                  ),
                ),
              ),
            ),
          if (widget.onDrillSelected == null) const SizedBox(height: 16),
          overviews.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const _InlineMessage(
              icon: Icons.sync_problem_outlined,
              text: 'Opgeslagen trainingsvoortgang kon niet worden geladen.',
            ),
            data: (items) =>
                _ActivityOverviewSections(items: items, onOpen: _openActivity),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const ValueKey('drill-search'),
            decoration: const InputDecoration(
              labelText: 'Zoek op doel of meetbasis',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Alle disciplines'),
                selected: _discipline == null,
                onSelected: (_) => setState(() => _discipline = null),
              ),
              for (final discipline in const [
                TrainingDiscipline.precisionPistol,
                TrainingDiscipline.br50,
              ])
                FilterChip(
                  label: Text(_disciplineLabel(discipline)),
                  selected: _discipline == discipline,
                  onSelected: (selected) => setState(
                    () => _discipline = selected ? discipline : null,
                  ),
                ),
              for (final level in TrainingSkillLevel.values)
                FilterChip(
                  label: Text(_levelLabel(level)),
                  selected: _level == level,
                  onSelected: (selected) =>
                      setState(() => _level = selected ? level : null),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${drills.length} passende drills',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (drills.isEmpty)
            const _InlineMessage(
              icon: Icons.search_off_outlined,
              text: 'Geen drill past bij deze filters.',
            )
          else
            for (final drill in drills)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DrillCard(
                  drill: drill,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => DrillDetailScreen(
                        drill: drill,
                        onDrillSelected: widget.onDrillSelected,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _openActivity(GuidedTrainingActivityOverview overview) async {
    final catalog = BuiltInTrainingContent.catalog;
    if (overview.isLegacyReadOnly || !overview.canResume) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => HistoricalTrainingActivityScreen(overview: overview),
        ),
      );
      return;
    }
    if (overview.isTrainingPlan) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DeterministicDrillPlannerScreen.resume(
            activityId: overview.activity.id,
            drills: catalog.drills,
            learningPaths: catalog.learningPaths,
          ),
        ),
      );
      return;
    }
    final drill = _drillSnapshot(overview, catalog);
    if (drill == null) {
      if (mounted) {
        AppMessenger.error(
          context,
          'De opgeslagen drillversie kan alleen in de geschiedenis worden bekeken.',
        );
      }
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GuidedDrillRunnerScreen(
          drill: drill,
          activityId: overview.activity.id,
        ),
      ),
    );
  }
}

class DrillDetailScreen extends StatelessWidget {
  const DrillDetailScreen({
    required this.drill,
    this.onDrillSelected,
    this.planContext,
    super.key,
  });

  final DrillDefinitionV2 drill;
  final ValueChanged<DrillDefinitionV2>? onDrillSelected;
  final TrainingPlanContext? planContext;

  @override
  Widget build(BuildContext context) => CompactPageScaffold(
    title: drill.title,
    body: ListView(
      key: const ValueKey('drill-detail-list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
      children: [
        Text(
          drill.shortPurpose,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(_disciplineLabel(drill.discipline))),
            Chip(label: Text(_levelLabel(drill.skillLevel))),
            Chip(label: Text('${drill.estimatedDurationMinutes} min')),
            Chip(label: Text('${drill.ammunitionBudget} patronen')),
            Chip(label: Text(_modeLabel(drill.mode))),
            Chip(
              avatar: Icon(
                drill.review.coachReviewStatus == CoachReviewStatus.reviewed
                    ? Icons.verified_outlined
                    : Icons.science_outlined,
                size: 18,
              ),
              label: Text(_reviewLabel(drill.review)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (drill.prerequisites.isNotEmpty)
          _DetailSection(
            title: 'Startvoorwaarden',
            child: _BulletList(items: drill.prerequisites),
          ),
        _DetailSection(
          title: 'Opstelling',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabelValue(label: 'Kaart', value: drill.setup.target),
              _LabelValue(label: 'Afstand', value: drill.setup.distance),
              _LabelValue(
                label: 'Materiaal',
                value: drill.setup.equipment.join(' · '),
              ),
              _LabelValue(label: 'Meetbasis', value: drill.setup.dataBasis),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.health_and_safety_outlined),
                      const SizedBox(width: 10),
                      Expanded(child: Text(drill.setup.safetyGate)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _DetailSection(
          title: 'Uitvoering',
          child: Column(
            children: [
              for (var index = 0; index < drill.phases.length; index++)
                _PhasePreview(index: index, phase: drill.phases[index]),
            ],
          ),
        ),
        _DetailSection(
          title: 'Wat wordt gemeten?',
          child: Column(
            children: [
              for (final measurement in drill.measurements)
                _MeasurementPreview(measurement: measurement),
            ],
          ),
        ),
        _DetailSection(
          title: 'Wanneer beheers je dit?',
          child: Text(
            '${drill.masteryRule.explanation}\n\n'
            'Voortgang: ${drill.masteryRule.requiredSuccesses} geslaagde '
            'uitvoeringen binnen de laatste '
            '${drill.masteryRule.evaluationWindow}.',
          ),
        ),
        _DetailSection(
          title: 'Stop en reset',
          child: _BulletList(items: drill.stopRules),
        ),
        _DetailSection(
          title: 'Reflectie',
          child: _BulletList(items: drill.reflectionPrompts),
        ),
        _DetailSection(
          title: 'Vervolg',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(drill.progression.usableResult),
              const SizedBox(height: 8),
              Text(drill.progression.insufficientData),
              const SizedBox(height: 8),
              Text(drill.progression.unreliableResult),
            ],
          ),
        ),
        _DetailSection(
          title: 'Bronnen en beoordeling',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_evidenceLabel(drill.review.evidenceStatus)} · '
                '${drill.review.sourceEdition}',
              ),
              const SizedBox(height: 8),
              for (final reference in drill.references)
                _ReferenceTile(reference: reference),
            ],
          ),
        ),
      ],
    ),
    bottomNavigationBar: AppActionDock(
      actions: [
        FilledButton.icon(
          key: ValueKey(
            onDrillSelected == null ? 'start-guided-drill' : 'select-drill',
          ),
          onPressed: () async {
            if (onDrillSelected case final callback?) {
              callback(drill);
              Navigator.pop(context);
              return;
            }
            final completed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => GuidedDrillRunnerScreen(
                  drill: drill,
                  planContext: planContext,
                ),
              ),
            );
            if (context.mounted && completed == true) {
              AppMessenger.success(context, 'Drill afgerond');
            }
          },
          icon: const Icon(Icons.play_arrow),
          label: Text(
            onDrillSelected == null ? 'Begeleid starten' : 'Drill kiezen',
          ),
        ),
      ],
    ),
  );
}

class HistoricalTrainingActivityScreen extends StatelessWidget {
  const HistoricalTrainingActivityScreen({required this.overview, super.key});

  final GuidedTrainingActivityOverview overview;

  @override
  Widget build(BuildContext context) {
    final metric = overview.summary['metricSnapshot'];
    final isLegacy = overview.isLegacyReadOnly;
    return CompactPageScaffold(
      title: overview.title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InlineMessage(
            icon: isLegacy
                ? Icons.history
                : _statusIcon(overview.activity.status),
            text: isLegacy
                ? 'Historische V1-drill. Deze registratie blijft leesbaar, '
                      'maar kan niet met de V2-runner worden hervat.'
                : _statusLabel(overview.activity.status),
          ),
          const SizedBox(height: 16),
          _LabelValue(
            label: 'Gestart',
            value: MaterialLocalizations.of(
              context,
            ).formatMediumDate(overview.activity.startedAtUtc.toLocal()),
          ),
          if (overview.versionedContentId case final id?)
            _LabelValue(label: 'Inhoudsversie', value: id),
          if (metric is Map) ...[
            const SizedBox(height: 12),
            Text(
              'Meetresultaat',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _LabelValue(
              label: '${metric['metric'] ?? 'Meting'}',
              value: '${metric['value'] ?? 'Geen waarde'}',
            ),
            _LabelValue(
              label: 'Meetbasis',
              value: '${metric['sampleSize'] ?? 0} eenheden',
            ),
          ],
        ],
      ),
    );
  }
}

class _PlannerEntryCard extends StatelessWidget {
  const _PlannerEntryCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: ListTile(
      key: const ValueKey('open-deterministic-planner'),
      leading: const Icon(Icons.event_note_outlined),
      title: const Text('Training plannen'),
      subtitle: const Text(
        'Bouw een controleerbare training van 30, 45 of 60 minuten.',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onOpen,
    ),
  );
}

class _ActivityOverviewSections extends StatelessWidget {
  const _ActivityOverviewSections({required this.items, required this.onOpen});

  final List<GuidedTrainingActivityOverview> items;
  final ValueChanged<GuidedTrainingActivityOverview> onOpen;

  @override
  Widget build(BuildContext context) {
    final resumable = items.where((item) => item.canResume).toList();
    final history = items.where((item) => !item.canResume).take(3).toList();
    if (resumable.isEmpty && history.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (resumable.isNotEmpty) ...[
          Text('Verdergaan', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final item in resumable)
            _ActivityTile(item: item, onTap: () => onOpen(item)),
          const SizedBox(height: 12),
        ],
        if (history.isNotEmpty) ...[
          Text(
            'Recente geschiedenis',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final item in history)
            _ActivityTile(item: item, onTap: () => onOpen(item)),
        ],
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item, required this.onTap});

  final GuidedTrainingActivityOverview item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: ValueKey('training-activity-${item.activity.id}'),
      leading: Icon(
        item.isTrainingPlan
            ? Icons.event_note_outlined
            : item.isLegacyReadOnly
            ? Icons.history
            : Icons.route_outlined,
      ),
      title: Text(item.title),
      subtitle: Text(
        item.canResume
            ? item.activity.status ==
                      StoredTrainingActivityStatus.interrupted.name
                  ? 'Onderbroken · tik om exact te hervatten'
                  : 'Bezig · tik om verder te gaan'
            : item.isLegacyReadOnly
            ? 'Historische V1-registratie · alleen lezen'
            : _statusLabel(item.activity.status),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _DrillCard extends StatelessWidget {
  const _DrillCard({required this.drill, required this.onTap});

  final DrillDefinitionV2 drill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = drill.measurements.singleWhere(
      (item) => item.role == TrainingMeasurementRole.primary,
    );
    return Card(
      child: ListTile(
        key: ValueKey('drill-${drill.versionedId}'),
        contentPadding: const EdgeInsets.all(14),
        title: Text(drill.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${drill.shortPurpose}\n'
            '${drill.estimatedDurationMinutes} min · '
            '${drill.ammunitionBudget} patronen · '
            '${_metricLabel(primary.metric)}',
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _PhasePreview extends StatelessWidget {
  const _PhasePreview({required this.index, required this.phase});

  final int index;
  final DrillPhaseV2 phase;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 15, child: Text('${index + 1}')),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phase.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              for (final instruction in phase.instructions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $instruction'),
                ),
              Text(
                _phaseRequirement(phase),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MeasurementPreview extends StatelessWidget {
  const _MeasurementPreview({required this.measurement});

  final DrillMeasurementV2 measurement;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      measurement.role == TrainingMeasurementRole.primary
          ? Icons.track_changes
          : Icons.add_chart_outlined,
    ),
    title: Text(_metricLabel(measurement.metric)),
    subtitle: Text(
      '${measurement.interpretation}\n'
      'Minimum: ${measurement.minimumSampleSize} '
      '${_sampleUnitLabel(measurement.sampleUnit)}',
    ),
    isThreeLine: true,
  );
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({required this.reference});

  final TrainingReference reference;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${reference.publisher}: ${reference.title}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (reference.locator case final locator?) ...[
            const SizedBox(height: 4),
            Text(locator),
          ],
          const SizedBox(height: 6),
          Semantics(
            label: 'Bronlink ${reference.url}',
            child: SelectableText(
              reference.url,
              key: ValueKey('drill-reference-url-${reference.id}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              label: 'Link kopiëren voor ${reference.title}',
              button: true,
              excludeSemantics: true,
              child: TextButton.icon(
                key: ValueKey('copy-drill-reference-${reference.id}'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: reference.url));
                  if (context.mounted) {
                    AppMessenger.info(context, 'Link gekopieerd');
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Link kopiëren'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 2),
        Text(value),
      ],
    ),
  );
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text('• $item'),
        ),
    ],
  );
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

DrillDefinitionV2? _drillSnapshot(
  GuidedTrainingActivityOverview overview,
  TrainingContentCatalog catalog,
) {
  final raw = overview.configuration['drill'];
  if (raw is Map) {
    try {
      return DrillDefinitionV2.fromJson(raw.cast<String, Object?>());
    } on Object {
      return null;
    }
  }
  final id = overview.versionedContentId;
  return id == null ? null : catalog.drillByVersionedId(id);
}

String _disciplineLabel(TrainingDiscipline value) => switch (value) {
  TrainingDiscipline.universal => 'Algemeen',
  TrainingDiscipline.precisionPistol => 'Precisiepistool',
  TrainingDiscipline.br50 => 'BR50',
};

String _levelLabel(TrainingSkillLevel value) => switch (value) {
  TrainingSkillLevel.foundation => 'Basis',
  TrainingSkillLevel.development => 'Gevorderd',
};

String _modeLabel(TrainingMode value) => switch (value) {
  TrainingMode.rangeDryFire => 'Dry fire op de baan',
  TrainingMode.liveFire => 'Live fire',
  TrainingMode.mixedOnRange => 'Gemengd',
  TrainingMode.analysisOnly => 'Analyse',
  TrainingMode.matchSimulation => 'Wedstrijdsimulatie',
};

String _metricLabel(TrainingMetricKind metric) => switch (metric) {
  TrainingMetricKind.completion => 'Voltooiing',
  TrainingMetricKind.scorePercentage => 'Scorepercentage',
  TrainingMetricKind.meanRadiusMm => 'Mean radius',
  TrainingMetricKind.extremeSpreadMm => 'Extreme spreiding',
  TrainingMetricKind.consistency => 'Consistentie',
  TrainingMetricKind.absoluteBiasMm => 'Afwijking groepscentrum',
  TrainingMetricKind.selfEvaluation => 'Zelfevaluatie',
  TrainingMetricKind.shotCallAccuracy => 'Schotvoorspelling',
  TrainingMetricKind.filledBullCount => 'Beoordeelde recordroosjes',
};

String _sampleUnitLabel(TrainingSampleUnit unit) => switch (unit) {
  TrainingSampleUnit.evidenceLinks => 'geldige fasebewijzen',
  TrainingSampleUnit.linkedSeries => 'bevestigde reeksen',
  TrainingSampleUnit.positionedShots => 'positionele schoten',
  TrainingSampleUnit.recordBulls => 'beoordeelde recordroosjes',
  TrainingSampleUnit.reflections => 'gekoppelde reflecties',
  TrainingSampleUnit.comparableShotCalls => 'vergelijkbare schotvoorspellingen',
};

String _phaseRequirement(DrillPhaseV2 phase) {
  final parts = <String>[];
  if (phase.seriesCount case final count?) {
    parts.add('$count reeksen');
  }
  if (phase.shotsPerSeries case final shots?) {
    parts.add('$shots schoten per reeks');
  }
  if (phase.restSeconds case final rest?) parts.add('$rest s rust');
  return parts.isEmpty
      ? 'Bewijs: ${phase.completionKind.name}'
      : parts.join(' · ');
}

String _reviewLabel(ContentReview review) =>
    review.coachReviewStatus == CoachReviewStatus.reviewed
    ? 'Coachgereviewd'
    : 'Coachreview open';

String _evidenceLabel(ContentEvidenceStatus status) => switch (status) {
  ContentEvidenceStatus.officialGuidance => 'Officiële richtlijn',
  ContentEvidenceStatus.researchSupported => 'Onderzoeksondersteund',
  ContentEvidenceStatus.practiceBased => 'Praktijkgebaseerd',
};

String _statusLabel(String status) => switch (status) {
  'completed' => 'Voltooid',
  'interrupted' => 'Onderbroken',
  _ => 'Concept',
};

IconData _statusIcon(String status) => switch (status) {
  'completed' => Icons.check_circle_outline,
  'interrupted' => Icons.pause_circle_outline,
  _ => Icons.pending_outlined,
};
