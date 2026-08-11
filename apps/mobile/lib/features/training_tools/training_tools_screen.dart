import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_shot_timer/shot_timer.dart';
import 'package:shooting_companion_training/training.dart';

import '../../app/providers.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/compact_page_scaffold.dart';
import 'drill_plan_screen.dart';
import 'drill_screens.dart';
import 'experiment_planner_screen.dart';
import 'guided_drill_runner_screen.dart';
import 'learning_path_screens.dart';
import 'shot_timer_flow.dart';
import 'sight_calculator_screen.dart';
import 'technique_screens.dart';
import 'timer_history_screen.dart';

enum TrainingHubDestination {
  start,
  learningPaths,
  techniques,
  drills,
  history,
}

/// Offline learning and practice hub.
///
/// The hub keeps the existing timer, experiment and sight tools reachable from
/// Start while V2 lessons, learning paths and drills use the authoritative
/// [BuiltInTrainingContent] catalog.
class TrainingToolsScreen extends ConsumerStatefulWidget {
  const TrainingToolsScreen({
    this.initialTargetProfileVersionedId = 'issf-25m-precision-50m-pistol@1',
    this.initialDistanceMeters = 25,
    this.onDrillSelected,
    this.onExperimentPlanCreated,
    super.key,
  });

  final String initialTargetProfileVersionedId;
  final double initialDistanceMeters;
  final ValueChanged<DrillDefinitionV2>? onDrillSelected;
  final ValueChanged<ExperimentPlan>? onExperimentPlanCreated;

  @override
  ConsumerState<TrainingToolsScreen> createState() =>
      _TrainingToolsScreenState();
}

class _TrainingToolsScreenState extends ConsumerState<TrainingToolsScreen> {
  var _destination = TrainingHubDestination.start;

  void _select(int index) {
    setState(() => _destination = TrainingHubDestination.values[index]);
  }

  void _openDrill(DrillDefinitionV2 drill) {
    if (widget.onDrillSelected case final callback?) {
      callback(drill);
      return;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => DrillDetailScreen(drill: drill)),
    );
  }

  void _openDrillById(String versionedId) {
    final drill = BuiltInTrainingContent.catalog.drillByVersionedId(
      versionedId,
    );
    if (drill != null) _openDrill(drill);
  }

  void _openStoredTrainingActivity(GuidedTrainingActivityOverview overview) {
    final catalog = BuiltInTrainingContent.catalog;
    if (!_canResumeStoredActivity(overview)) {
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => HistoricalTrainingActivityScreen(overview: overview),
        ),
      );
      return;
    }
    if (overview.isTrainingPlan) {
      Navigator.push<void>(
        context,
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
    final raw = overview.configuration['drill'];
    if (raw is! Map) return;
    try {
      final drill = DrillDefinitionV2.fromJson(raw.cast<String, Object?>());
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => GuidedDrillRunnerScreen(
            drill: drill,
            activityId: overview.activity.id,
          ),
        ),
      );
    } on Object {
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => HistoricalTrainingActivityScreen(overview: overview),
        ),
      );
    }
  }

  void _openStoredLearningPath(LearningPathActivityOverview overview) {
    final rawPath = overview.configuration['learningPath'];
    if (rawPath is Map) {
      try {
        final path = LearningPathV2.fromJson(rawPath.cast<String, Object?>());
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => LearningPathDetailScreen(
              path: path,
              activityId: overview.activity.id,
              readOnly: !overview.canResume,
              onOpenDrill: _openDrillById,
              onOpenDrillDefinition: _openDrill,
              lessonSnapshotsByEntryId: overview.lessonSnapshotsByEntryId,
              drillSnapshotsByEntryId: overview.drillSnapshotsByEntryId,
            ),
          ),
        );
        return;
      } on Object {
        // Keep corrupt or future history inspectable without resuming it.
      }
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HistoricalLearningPathActivityScreen(overview: overview),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _destination.index;
    final content = switch (_destination) {
      TrainingHubDestination.start => _StartPane(
        initialTargetProfileVersionedId: widget.initialTargetProfileVersionedId,
        initialDistanceMeters: widget.initialDistanceMeters,
        onExperimentPlanCreated: widget.onExperimentPlanCreated,
        onOpenStoredActivity: _openStoredTrainingActivity,
        onOpenLearningPath: _openStoredLearningPath,
        onSelectDestination: (destination) =>
            setState(() => _destination = destination),
      ),
      TrainingHubDestination.learningPaths => LearningPathLibraryScreen(
        embedded: true,
        onOpenDrill: _openDrillById,
      ),
      TrainingHubDestination.techniques => TechniqueLibraryScreen(
        embedded: true,
        onOpenDrill: _openDrillById,
      ),
      TrainingHubDestination.drills => _DrillCatalogPane(
        onOpenDrill: _openDrill,
      ),
      TrainingHubDestination.history => _TrainingHistoryPane(
        onOpenStoredActivity: _openStoredTrainingActivity,
        onOpenLearningPath: _openStoredLearningPath,
      ),
    };

    return PopScope(
      canPop: _destination == TrainingHubDestination.start,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _destination != TrainingHubDestination.start) {
          setState(() => _destination = TrainingHubDestination.start);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          return CompactPageScaffold(
            title: 'Leren & oefenen',
            body: wide
                ? Row(
                    children: [
                      SafeArea(
                        top: false,
                        right: false,
                        child: NavigationRail(
                          key: const ValueKey('training-hub-navigation-rail'),
                          selectedIndex: selectedIndex,
                          onDestinationSelected: _select,
                          labelType: NavigationRailLabelType.all,
                          destinations: _railDestinations,
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: content),
                    ],
                  )
                : content,
            bottomNavigationBar: wide
                ? null
                : SafeArea(
                    top: false,
                    child: NavigationBar(
                      key: const ValueKey('training-hub-navigation-bar'),
                      selectedIndex: selectedIndex,
                      onDestinationSelected: _select,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.onlyShowSelected,
                      destinations: _navigationDestinations,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

const _navigationDestinations = <NavigationDestination>[
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: 'Start',
    tooltip: 'Start van Leren en oefenen',
  ),
  NavigationDestination(
    icon: Icon(Icons.route_outlined),
    selectedIcon: Icon(Icons.route),
    label: 'Leerpaden',
    tooltip: 'Leerpaden',
  ),
  NavigationDestination(
    icon: Icon(Icons.menu_book_outlined),
    selectedIcon: Icon(Icons.menu_book),
    label: 'Technieken',
    tooltip: 'Technieken',
  ),
  NavigationDestination(
    icon: Icon(Icons.fitness_center_outlined),
    selectedIcon: Icon(Icons.fitness_center),
    label: 'Drills',
    tooltip: 'Drills',
  ),
  NavigationDestination(
    icon: Icon(Icons.history_outlined),
    selectedIcon: Icon(Icons.history),
    label: 'Geschiedenis',
    tooltip: 'Trainingsgeschiedenis',
  ),
];

const _railDestinations = <NavigationRailDestination>[
  NavigationRailDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: Text('Start'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.route_outlined),
    selectedIcon: Icon(Icons.route),
    label: Text('Leerpaden'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.menu_book_outlined),
    selectedIcon: Icon(Icons.menu_book),
    label: Text('Technieken'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.fitness_center_outlined),
    selectedIcon: Icon(Icons.fitness_center),
    label: Text('Drills'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.history_outlined),
    selectedIcon: Icon(Icons.history),
    label: Text('Geschiedenis'),
  ),
];

class _StartPane extends ConsumerWidget {
  const _StartPane({
    required this.initialTargetProfileVersionedId,
    required this.initialDistanceMeters,
    required this.onExperimentPlanCreated,
    required this.onOpenStoredActivity,
    required this.onOpenLearningPath,
    required this.onSelectDestination,
  });

  final String initialTargetProfileVersionedId;
  final double initialDistanceMeters;
  final ValueChanged<ExperimentPlan>? onExperimentPlanCreated;
  final ValueChanged<GuidedTrainingActivityOverview> onOpenStoredActivity;
  final ValueChanged<LearningPathActivityOverview> onOpenLearningPath;
  final ValueChanged<TrainingHubDestination> onSelectDestination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = BuiltInTrainingContent.catalog;
    final activeTrainingPlan = ref
        .watch(activeTrainingPlanProvider)
        .valueOrNull;
    final activeLearningPath = ref
        .watch(activeLearningPathProvider)
        .valueOrNull;
    final overviews =
        ref.watch(guidedTrainingActivityOverviewsProvider).valueOrNull ??
        const <GuidedTrainingActivityOverview>[];
    final resumable = <GuidedTrainingActivityOverview>[
      if (activeTrainingPlan != null)
        ...overviews.where(
          (overview) =>
              overview.activity.id == activeTrainingPlan.id &&
              overview.isTrainingPlan &&
              _canResumeStoredActivity(overview),
        ),
      ...overviews.where(
        (overview) =>
            !overview.isTrainingPlan && _canResumeStoredActivity(overview),
      ),
    ];
    return ListView(
      key: const ValueKey('training-hub-start'),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Text(
          'Kies wat je nu wilt verbeteren',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Leer een techniek, oefen gericht of gebruik een losse trainingstool. '
          'Alles werkt offline en verandert nooit stil je score.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        if (activeLearningPath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              key: ValueKey(
                'training-resume-learning-path-${activeLearningPath.activity.id}',
              ),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                key: const ValueKey('training-resume-learning-path'),
                minTileHeight: 80,
                leading: const Icon(Icons.route_outlined),
                title: const Text('Leerpad hervatten'),
                subtitle: Text(
                  '${activeLearningPath.title} · '
                  '${activeLearningPath.completedEntryIds.length}/'
                  '${activeLearningPath.totalEntryCount}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenLearningPath(activeLearningPath),
              ),
            ),
          ),
        if (resumable.isNotEmpty) ...[
          for (final current in resumable)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                key: ValueKey('training-resume-${current.activity.id}'),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  key: ValueKey(
                    current.isTrainingPlan
                        ? 'training-resume-plan'
                        : 'training-resume-guided-drill',
                  ),
                  minTileHeight: 80,
                  leading: Icon(
                    current.isTrainingPlan
                        ? Icons.event_note_outlined
                        : Icons.play_circle_outline,
                  ),
                  title: Text(
                    current.isTrainingPlan
                        ? 'Trainingsplan hervatten'
                        : 'Actieve drill hervatten',
                  ),
                  subtitle: Text(current.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpenStoredActivity(current),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
        _HubSectionTitle(title: 'Leren en oefenen'),
        const SizedBox(height: 8),
        _PrimaryToolCard(
          key: const ValueKey('training-tool-planner'),
          icon: Icons.auto_awesome_outlined,
          title: 'Training plannen',
          description:
              'Maak lokaal een haalbaar plan op basis van discipline, tijd '
              'en beschikbare patronen.',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => DeterministicDrillPlannerScreen(
                drills: catalog.drills,
                learningPaths: catalog.learningPaths,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-learning-paths'),
          icon: Icons.route_outlined,
          title: 'Leerpaden',
          description:
              '${catalog.learningPaths.length} begeleide routes met lessen en drills.',
          onTap: () =>
              onSelectDestination(TrainingHubDestination.learningPaths),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-techniques'),
          icon: Icons.menu_book_outlined,
          title: 'Technieken',
          description:
              '${catalog.lessons.length} korte lessen in drie informatielagen.',
          onTap: () => onSelectDestination(TrainingHubDestination.techniques),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-drills'),
          icon: Icons.fitness_center_outlined,
          title: 'Drills',
          description:
              '${catalog.drills.length} meetbare oefeningen met duidelijke veiligheidsgrenzen.',
          onTap: () => onSelectDestination(TrainingHubDestination.drills),
        ),
        const SizedBox(height: 22),
        _HubSectionTitle(title: 'Timer en ritme'),
        const SizedBox(height: 8),
        _ToolCard(
          key: const ValueKey('training-tool-shot-timer'),
          icon: Icons.timer_outlined,
          title: 'Shot timer',
          description:
              'Meet live-firetijden en splits met een begeleide microfoonsetup.',
          onTap: () => launchShotTimerFlow(context: context, ref: ref),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-par-cadence'),
          icon: Icons.notifications_active_outlined,
          title: 'Par en cadans',
          description:
              'Train tijden, ritme en werk-rustblokken zonder microfoon.',
          onTap: () => launchShotTimerFlow(
            context: context,
            ref: ref,
            initialMode: ShotTimerMode.par,
          ),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-calibration-profiles'),
          icon: Icons.graphic_eq,
          title: 'Akoestische profielen',
          description:
              'Beheer lokale gevoeligheid en echofilters per omgeving.',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => const AcousticCalibrationProfilesScreen(),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _HubSectionTitle(title: 'Meten en vergelijken'),
        const SizedBox(height: 8),
        _ToolCard(
          key: const ValueKey('training-tool-experiment'),
          icon: Icons.compare_arrows,
          title: 'A/B-experiment',
          description: 'Maak een gebalanceerd A-B-B-A-plan voor één variabele.',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => ExperimentPlannerScreen(
                targetProfileVersionedId: initialTargetProfileVersionedId,
                initialDistanceMeters: initialDistanceMeters,
                onPlanCreated: onExperimentPlanCreated,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-sight'),
          icon: Icons.center_focus_strong,
          title: 'Viziercalculator',
          description:
              'Zet een gemeten afwijking om naar MOA- of mrad-klikken.',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const SightCalculatorScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-timer-history'),
          icon: Icons.history,
          title: 'Timergeschiedenis',
          description: 'Bekijk bewaarde runs, schottijden en uitsluitingen.',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const TimerHistoryScreen()),
          ),
        ),
        const SizedBox(height: 20),
        const _OfflineNotice(),
      ],
    );
  }
}

class _DrillCatalogPane extends StatefulWidget {
  const _DrillCatalogPane({required this.onOpenDrill});

  final ValueChanged<DrillDefinitionV2> onOpenDrill;

  @override
  State<_DrillCatalogPane> createState() => _DrillCatalogPaneState();
}

class _DrillCatalogPaneState extends State<_DrillCatalogPane> {
  String _query = '';
  TrainingDiscipline? _discipline;
  TrainingSkillLevel? _skillLevel;
  TrainingMode? _mode;
  TrainingMetricKind? _topic;
  int? _maximumMinutes;
  int? _maximumAmmunition;
  CoachReviewStatus? _reviewStatus;

  int get _activeFilterCount => <Object?>[
    _discipline,
    _skillLevel,
    _mode,
    _topic,
    _maximumMinutes,
    _maximumAmmunition,
    _reviewStatus,
  ].whereType<Object>().length;

  void _clearFilters() {
    setState(() {
      _discipline = null;
      _skillLevel = null;
      _mode = null;
      _topic = null;
      _maximumMinutes = null;
      _maximumAmmunition = null;
      _reviewStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final drills = BuiltInTrainingContent.catalog.drills
        .where((drill) {
          final primaryMetric = drill.measurements
              .firstWhere(
                (measurement) =>
                    measurement.role == TrainingMeasurementRole.primary,
              )
              .metric;
          final queryMatches =
              normalized.isEmpty ||
              drill.title.toLowerCase().contains(normalized) ||
              drill.shortPurpose.toLowerCase().contains(normalized) ||
              drill.setup.equipment.any(
                (item) => item.toLowerCase().contains(normalized),
              );
          return queryMatches &&
              (_discipline == null || drill.discipline == _discipline) &&
              (_skillLevel == null || drill.skillLevel == _skillLevel) &&
              (_mode == null || drill.mode == _mode) &&
              (_topic == null || primaryMetric == _topic) &&
              (_maximumMinutes == null ||
                  drill.estimatedDurationMinutes <= _maximumMinutes!) &&
              (_maximumAmmunition == null ||
                  drill.ammunitionBudget <= _maximumAmmunition!) &&
              (_reviewStatus == null ||
                  drill.review.coachReviewStatus == _reviewStatus);
        })
        .toList(growable: false);
    return ListView(
      key: const ValueKey('training-hub-drills'),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Text(
          'Drills',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Kies een meetbare oefening. Je snelle handmatige scoreflow blijft '
          'altijd bereikbaar.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('training-drill-search'),
          decoration: const InputDecoration(
            labelText: 'Drill zoeken',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: const ValueKey('training-drill-filters'),
            title: Text(
              _activeFilterCount == 0
                  ? 'Filters'
                  : 'Filters ($_activeFilterCount actief)',
            ),
            leading: const Icon(Icons.tune),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final fieldWidth = constraints.maxWidth >= 480
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _CatalogFilterField<TrainingDiscipline>(
                        key: const ValueKey('training-drill-filter-discipline'),
                        width: fieldWidth,
                        label: 'Discipline',
                        value: _discipline,
                        values: TrainingDiscipline.values,
                        itemLabel: _trainingDisciplineLabel,
                        onChanged: (value) =>
                            setState(() => _discipline = value),
                      ),
                      _CatalogFilterField<TrainingSkillLevel>(
                        key: const ValueKey('training-drill-filter-level'),
                        width: fieldWidth,
                        label: 'Niveau',
                        value: _skillLevel,
                        values: TrainingSkillLevel.values,
                        itemLabel: _trainingSkillLevelLabel,
                        onChanged: (value) =>
                            setState(() => _skillLevel = value),
                      ),
                      _CatalogFilterField<TrainingMetricKind>(
                        key: const ValueKey('training-drill-filter-topic'),
                        width: fieldWidth,
                        label: 'Onderwerp',
                        value: _topic,
                        values: TrainingMetricKind.values,
                        itemLabel: _trainingMetricLabel,
                        onChanged: (value) => setState(() => _topic = value),
                      ),
                      _CatalogFilterField<TrainingMode>(
                        key: const ValueKey('training-drill-filter-mode'),
                        width: fieldWidth,
                        label: 'Trainingsvorm',
                        value: _mode,
                        values: TrainingMode.values,
                        itemLabel: _trainingModeLabel,
                        onChanged: (value) => setState(() => _mode = value),
                      ),
                      _CatalogFilterField<int>(
                        key: const ValueKey('training-drill-filter-time'),
                        width: fieldWidth,
                        label: 'Maximale tijd',
                        value: _maximumMinutes,
                        values: const [10, 20, 30, 60],
                        itemLabel: (value) => '$value min',
                        onChanged: (value) =>
                            setState(() => _maximumMinutes = value),
                      ),
                      _CatalogFilterField<int>(
                        key: const ValueKey('training-drill-filter-ammunition'),
                        width: fieldWidth,
                        label: 'Munitiebudget',
                        value: _maximumAmmunition,
                        values: const [0, 5, 15, 25, 50],
                        itemLabel: (value) => value == 0
                            ? 'Zonder patronen'
                            : 'Maximaal $value patronen',
                        onChanged: (value) =>
                            setState(() => _maximumAmmunition = value),
                      ),
                      _CatalogFilterField<CoachReviewStatus>(
                        key: const ValueKey('training-drill-filter-review'),
                        width: fieldWidth,
                        label: 'Reviewstatus',
                        value: _reviewStatus,
                        values: CoachReviewStatus.values,
                        itemLabel: _reviewStatusLabel,
                        onChanged: (value) =>
                            setState(() => _reviewStatus = value),
                      ),
                    ],
                  );
                },
              ),
              if (_activeFilterCount > 0) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('training-drill-clear-filters'),
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Filters wissen'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            '${drills.length} ${drills.length == 1 ? 'drill' : 'drills'}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        for (final drill in drills)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                key: ValueKey('training-v2-drill-${drill.id}'),
                minTileHeight: 84,
                leading: const Icon(Icons.fitness_center_outlined),
                title: Text(drill.title),
                subtitle: Text(
                  '${drill.shortPurpose}\n'
                  '${drill.estimatedDurationMinutes} min · '
                  '${drill.ammunitionBudget} patronen',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onOpenDrill(drill),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrainingHistoryPane extends ConsumerWidget {
  const _TrainingHistoryPane({
    required this.onOpenStoredActivity,
    required this.onOpenLearningPath,
  });

  final ValueChanged<GuidedTrainingActivityOverview> onOpenStoredActivity;
  final ValueChanged<LearningPathActivityOverview> onOpenLearningPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningPaths = ref
        .watch(learningPathActivityOverviewsProvider)
        .valueOrNull;
    final activities = ref.watch(guidedTrainingActivityOverviewsProvider);
    final activityOverviews =
        activities.valueOrNull ?? const <GuidedTrainingActivityOverview>[];
    return ListView(
      key: const ValueKey('training-hub-history'),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Text(
          'Geschiedenis',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Voltooide en onderbroken drills en plannen blijven lokaal '
          'leesbaar. Oude drills worden nooit stil naar V2 omgezet.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        _ToolCard(
          key: const ValueKey('training-history-timers'),
          icon: Icons.timer_outlined,
          title: 'Timerruns',
          description: 'Bekijk akoestische, par-, cadans- en externe metingen.',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const TimerHistoryScreen()),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Leerpaden',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (learningPaths == null)
          const Center(child: CircularProgressIndicator())
        else if (learningPaths.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nog geen bewaarde leerpaden.'),
            ),
          )
        else
          for (final overview in learningPaths)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  key: ValueKey(
                    'training-history-learning-path-${overview.activity.id}',
                  ),
                  leading: const Icon(Icons.route_outlined),
                  title: Text(overview.title),
                  subtitle: Text(
                    '${_activityStatusLabel(overview.activity.status)} · '
                    '${overview.completedEntryIds.length}/'
                    '${overview.totalEntryCount} onderdelen',
                  ),
                  trailing: Icon(
                    overview.canResume ? Icons.play_arrow : Icons.chevron_right,
                  ),
                  onTap: () => onOpenLearningPath(overview),
                ),
              ),
            ),
        const SizedBox(height: 18),
        Text(
          'Drills en plannen',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (activities.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (activities.hasError)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('De trainingsgeschiedenis kon niet worden geladen.'),
            ),
          )
        else if (activityOverviews.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nog geen bewaarde drills of trainingsplannen.'),
            ),
          )
        else
          for (final overview in activityOverviews)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  key: ValueKey(
                    'training-history-activity-${overview.activity.id}',
                  ),
                  leading: Icon(
                    overview.isTrainingPlan
                        ? Icons.event_note_outlined
                        : Icons.fitness_center_outlined,
                  ),
                  title: Text(overview.title),
                  subtitle: Text(_historySubtitle(overview)),
                  trailing: Icon(
                    _canResumeStoredActivity(overview)
                        ? Icons.play_arrow
                        : Icons.chevron_right,
                  ),
                  onTap: () => onOpenStoredActivity(overview),
                ),
              ),
            ),
      ],
    );
  }
}

bool _canResumeStoredActivity(GuidedTrainingActivityOverview overview) {
  if (!overview.canResume || overview.isLegacyReadOnly) return false;
  final raw =
      overview.configuration[overview.isTrainingPlan ? 'plan' : 'drill'];
  if (raw is! Map) return false;
  try {
    final json = raw.cast<String, Object?>();
    if (overview.isTrainingPlan) {
      GeneratedDrillPlan.fromJson(json);
    } else {
      DrillDefinitionV2.fromJson(json);
    }
    return true;
  } on Object {
    return false;
  }
}

String _historySubtitle(GuidedTrainingActivityOverview overview) {
  if (overview.isLegacyReadOnly) {
    return 'Historische drill · alleen lezen';
  }
  if (overview.canResume && !_canResumeStoredActivity(overview)) {
    return 'Alleen lezen · opgeslagen versie niet hervatbaar';
  }
  return _activityStatusLabel(overview.activity.status);
}

class _CatalogFilterField<T> extends StatelessWidget {
  const _CatalogFilterField({
    required this.width,
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
    super.key,
  });

  final double width;
  final String label;
  final T? value;
  final List<T> values;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: value == null
            ? null
            : IconButton(
                tooltip: '$label wissen',
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.close),
              ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: const Text('Alle'),
          items: [
            for (final item in values)
              DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

class _HubSectionTitle extends StatelessWidget {
  const _HubSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.offline_bolt_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Alle lessen, berekeningen en timerdetecties gebeuren lokaal. '
              'Er worden geen audio-opnames bewaard.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PrimaryToolCard extends StatelessWidget {
  const _PrimaryToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(description),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

String _activityStatusLabel(String status) => switch (status) {
  'completed' => 'Voltooid',
  'interrupted' => 'Onderbroken · kan hervat worden',
  'draft' => 'Actief · kan hervat worden',
  _ => status,
};

String _trainingDisciplineLabel(TrainingDiscipline discipline) =>
    switch (discipline) {
      TrainingDiscipline.universal => 'Algemeen',
      TrainingDiscipline.precisionPistol => 'Precisiepistool',
      TrainingDiscipline.br50 => 'BR50',
    };

String _trainingSkillLevelLabel(TrainingSkillLevel level) => switch (level) {
  TrainingSkillLevel.foundation => 'Basis',
  TrainingSkillLevel.development => 'Verdieping',
};

String _trainingModeLabel(TrainingMode mode) => switch (mode) {
  TrainingMode.rangeDryFire => 'Droogtraining op de baan',
  TrainingMode.liveFire => 'Live fire',
  TrainingMode.mixedOnRange => 'Gemengd op de baan',
  TrainingMode.analysisOnly => 'Alleen analyse',
  TrainingMode.matchSimulation => 'Wedstrijdsimulatie',
};

String _trainingMetricLabel(TrainingMetricKind metric) => switch (metric) {
  TrainingMetricKind.completion => 'Uitvoering',
  TrainingMetricKind.scorePercentage => 'Score',
  TrainingMetricKind.meanRadiusMm => 'Groepsgrootte',
  TrainingMetricKind.extremeSpreadMm => 'Extreme spreiding',
  TrainingMetricKind.consistency => 'Consistentie',
  TrainingMetricKind.absoluteBiasMm => 'Groepscentrum',
  TrainingMetricKind.selfEvaluation => 'Zelfevaluatie',
  TrainingMetricKind.shotCallAccuracy => 'Schotinschatting',
  TrainingMetricKind.filledBullCount => 'Gevulde roosjes',
};

String _reviewStatusLabel(CoachReviewStatus status) => switch (status) {
  CoachReviewStatus.pending => 'Coachreview open',
  CoachReviewStatus.reviewed => 'Coachgereviewd',
};
