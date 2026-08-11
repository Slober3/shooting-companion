import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shooting_companion_training/training.dart';

import '../../app/providers.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/compact_page_scaffold.dart';
import 'technique_screens.dart';

class LearningPathLibraryScreen extends StatelessWidget {
  const LearningPathLibraryScreen({
    this.paths,
    this.onOpenDrill,
    this.embedded = false,
    super.key,
  });

  final List<LearningPathV2>? paths;
  final ValueChanged<String>? onOpenDrill;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final available = paths ?? BuiltInTrainingContent.catalog.learningPaths;
    final body = ListView(
      key: const ValueKey('learning-path-library'),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Text(
          'Een duidelijke volgorde',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Combineer korte lessen en gerichte oefeningen zonder dat de '
          'gewone snelle scoreflow verandert.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        if (available.isEmpty)
          const _EmptyPaths()
        else
          for (final path in available)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LearningPathCard(
                path: path,
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LearningPathDetailScreen(
                      path: path,
                      onOpenDrill: onOpenDrill,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
    return embedded
        ? body
        : CompactPageScaffold(title: 'Leerpaden', body: body);
  }
}

class LearningPathDetailScreen extends ConsumerStatefulWidget {
  const LearningPathDetailScreen({
    required this.path,
    this.onOpenDrill,
    this.onOpenDrillDefinition,
    this.lessonSnapshotsByEntryId = const {},
    this.drillSnapshotsByEntryId = const {},
    this.activityId,
    this.readOnly = false,
    super.key,
  });

  final LearningPathV2 path;
  final ValueChanged<String>? onOpenDrill;
  final ValueChanged<DrillDefinitionV2>? onOpenDrillDefinition;
  final Map<String, TechniqueLessonV2> lessonSnapshotsByEntryId;
  final Map<String, DrillDefinitionV2> drillSnapshotsByEntryId;
  final String? activityId;
  final bool readOnly;

  @override
  ConsumerState<LearningPathDetailScreen> createState() =>
      _LearningPathDetailScreenState();
}

class _LearningPathDetailScreenState
    extends ConsumerState<LearningPathDetailScreen> {
  var _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      if (!mounted) return;
      AppMessenger.show(
        context,
        kind: AppNoticeKind.error,
        message: error is StateError || error is ArgumentError
            ? '$error'.replaceFirst(
                RegExp(r'^(Bad state|Invalid argument): '),
                '',
              )
            : 'Het leerpad kon niet worden aangepast.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = BuiltInTrainingContent.catalog;
    final overviews = ref
        .watch(learningPathActivityOverviewsProvider)
        .valueOrNull;
    final active = ref.watch(activeLearningPathProvider).valueOrNull;
    final overview = widget.activityId == null
        ? active?.versionedContentId == widget.path.versionedId
              ? active
              : null
        : overviews
              ?.where((item) => item.activity.id == widget.activityId)
              .firstOrNull;
    final completedIds = overview?.completedEntryIds ?? const <String>{};
    final isCompleted =
        overview?.activity.status ==
        StoredTrainingActivityStatus.completed.name;
    final isInterrupted =
        overview?.activity.status ==
        StoredTrainingActivityStatus.interrupted.name;
    final editable =
        !widget.readOnly &&
        overview != null &&
        overview.canResume &&
        !isInterrupted &&
        !_busy;
    final allCompleted =
        overview != null && completedIds.length == widget.path.entries.length;
    final anotherActive =
        active != null && active.versionedContentId != widget.path.versionedId;
    return CompactPageScaffold(
      title: widget.path.title,
      body: ListView(
        key: const ValueKey('learning-path-detail'),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.route_outlined, size: 18),
                label: Text(_disciplineLabel(widget.path.discipline)),
              ),
              Chip(
                avatar: const Icon(Icons.schedule_outlined, size: 18),
                label: Text('${widget.path.estimatedMinutes} min'),
              ),
              Semantics(
                label: _reviewLabel(widget.path.review.coachReviewStatus),
                child: Chip(
                  avatar: Icon(
                    widget.path.review.coachReviewStatus ==
                            CoachReviewStatus.reviewed
                        ? Icons.verified_outlined
                        : Icons.science_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _reviewLabel(widget.path.review.coachReviewStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.path.shortDescription,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _LearningPathProgressCard(
            key: const ValueKey('learning-path-progress-card'),
            overview: overview,
            totalEntries: widget.path.entries.length,
            anotherActive: anotherActive,
            busy: _busy,
            readOnly: widget.readOnly,
            onStart: anotherActive || widget.readOnly
                ? null
                : () => _run(() async {
                    await ref
                        .read(repositoryProvider)
                        .startLearningPathActivity(
                          learningPathVersionedId: widget.path.versionedId,
                          learningPathSnapshot: widget.path.toJson(),
                          startedAtUtc: DateTime.now().toUtc(),
                          localUtcOffsetMinutes:
                              DateTime.now().timeZoneOffset.inMinutes,
                        );
                  }),
            onResume: !isInterrupted || widget.readOnly || overview == null
                ? null
                : () => _run(
                    () => ref
                        .read(repositoryProvider)
                        .resumeLearningPath(overview.activity.id),
                  ),
            onInterrupt:
                overview == null ||
                    widget.readOnly ||
                    isCompleted ||
                    isInterrupted
                ? null
                : () => _run(
                    () => ref
                        .read(repositoryProvider)
                        .interruptLearningPath(
                          activityId: overview.activity.id,
                        ),
                  ),
            onComplete: !allCompleted || !editable
                ? null
                : () => _run(
                    () => ref
                        .read(repositoryProvider)
                        .completeLearningPath(
                          activityId: overview.activity.id,
                          completedAtUtc: DateTime.now().toUtc(),
                        ),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            'Onderdelen',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < widget.path.entries.length; index++) ...[
            _buildEntryCard(
              index: index,
              entry: widget.path.entries[index],
              overview: overview,
              catalog: catalog,
              completedIds: completedIds,
              editable: editable,
            ),
            if (index != widget.path.entries.length - 1) const _PathConnector(),
          ],
          const SizedBox(height: 24),
          ExpansionTile(
            key: const ValueKey('learning-path-references'),
            tilePadding: EdgeInsets.zero,
            title: const Text('Bronnen'),
            children: [
              for (final reference in widget.path.references)
                _PathReferenceTile(reference: reference),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard({
    required int index,
    required LearningPathEntryV2 entry,
    required LearningPathActivityOverview? overview,
    required TrainingContentCatalog catalog,
    required Set<String> completedIds,
    required bool editable,
  }) {
    final lesson =
        overview?.lessonSnapshotsByEntryId[entry.id] ??
        widget.lessonSnapshotsByEntryId[entry.id] ??
        catalog.lessonByVersionedId(entry.versionedContentId);
    final drill =
        overview?.drillSnapshotsByEntryId[entry.id] ??
        widget.drillSnapshotsByEntryId[entry.id] ??
        catalog.drillByVersionedId(entry.versionedContentId);
    final onOpen = switch (entry.kind) {
      LearningPathEntryKind.lesson when lesson != null => () {
        Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => TechniqueLessonScreen(
              lesson: lesson,
              onOpenDrill: widget.onOpenDrill,
            ),
          ),
        );
      },
      LearningPathEntryKind.drill
          when drill != null && widget.onOpenDrillDefinition != null =>
        () => widget.onOpenDrillDefinition!(drill),
      LearningPathEntryKind.drill when widget.onOpenDrill != null =>
        () => widget.onOpenDrill!(entry.versionedContentId),
      _ => null,
    };
    return _PathEntryCard(
      index: index,
      entry: entry,
      lesson: lesson,
      drill: drill,
      completed: completedIds.contains(entry.id),
      current: overview?.currentEntryIndex == index,
      onToggleCompleted: editable && overview != null
          ? (value) => _run(() async {
              final next = completedIds.toSet();
              if (value) {
                next.add(entry.id);
              } else {
                next.remove(entry.id);
              }
              await ref
                  .read(repositoryProvider)
                  .updateLearningPathProgress(
                    activityId: overview.activity.id,
                    completedEntryIds: next,
                  );
            })
          : null,
      onOpen: onOpen,
    );
  }
}

class HistoricalLearningPathActivityScreen extends StatelessWidget {
  const HistoricalLearningPathActivityScreen({
    required this.overview,
    super.key,
  });

  final LearningPathActivityOverview overview;

  @override
  Widget build(BuildContext context) => CompactPageScaffold(
    title: overview.title,
    body: ListView(
      key: const ValueKey('historical-learning-path'),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Deze opgeslagen leerpadversie blijft leesbaar, maar kan '
                    'niet met deze appversie worden hervat of gewijzigd.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Status'),
          subtitle: Text(overview.activity.status),
        ),
        if (overview.versionedContentId case final versionedId?)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Inhoudsversie'),
            subtitle: Text(versionedId),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Voortgang'),
          subtitle: Text(
            '${overview.completedEntryIds.length} van '
            '${overview.totalEntryCount} onderdelen',
          ),
        ),
      ],
    ),
  );
}

class _PathReferenceTile extends StatelessWidget {
  const _PathReferenceTile({required this.reference});

  final TrainingReference reference;

  @override
  Widget build(BuildContext context) {
    final details = [
      reference.publisher,
      if (reference.documentEdition != null) reference.documentEdition!,
      if (reference.locator != null) reference.locator!,
    ].join(' · ');
    return Semantics(
      label: 'Bron ${reference.title}. $details. Webadres beschikbaar.',
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        leading: const Icon(Icons.description_outlined),
        title: Text(reference.title),
        subtitle: Text(details),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(reference.url),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: reference.url));
                if (!context.mounted) return;
                AppMessenger.show(
                  context,
                  kind: AppNoticeKind.success,
                  message: 'Bronlink gekopieerd',
                );
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Link kopiëren'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningPathProgressCard extends StatelessWidget {
  const _LearningPathProgressCard({
    required this.overview,
    required this.totalEntries,
    required this.anotherActive,
    required this.busy,
    required this.readOnly,
    required this.onStart,
    required this.onResume,
    required this.onInterrupt,
    required this.onComplete,
    super.key,
  });

  final LearningPathActivityOverview? overview;
  final int totalEntries;
  final bool anotherActive;
  final bool busy;
  final bool readOnly;
  final VoidCallback? onStart;
  final VoidCallback? onResume;
  final VoidCallback? onInterrupt;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final completed = overview?.completedEntryIds.length ?? 0;
    final status = overview?.activity.status;
    final statusText = switch (status) {
      'completed' => 'Voltooid · $completed van $totalEntries onderdelen',
      'interrupted' => 'Onderbroken · $completed van $totalEntries onderdelen',
      'draft' => 'Bezig · $completed van $totalEntries onderdelen',
      _ when anotherActive => 'Er is al een ander leerpad actief.',
      _ => 'Nog niet gestart',
    };
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              statusText,
              key: const ValueKey('learning-path-progress-label'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (overview != null && totalEntries > 0) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: completed / totalEntries,
                semanticsLabel:
                    '$completed van $totalEntries onderdelen voltooid',
              ),
            ],
            if (!readOnly) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (overview == null)
                    FilledButton.icon(
                      key: const ValueKey('start-learning-path'),
                      onPressed: busy ? null : onStart,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Leerpad starten'),
                    ),
                  if (onResume != null)
                    FilledButton.icon(
                      key: const ValueKey('resume-learning-path'),
                      onPressed: busy ? null : onResume,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Leerpad hervatten'),
                    ),
                  if (onComplete != null)
                    FilledButton.icon(
                      key: const ValueKey('complete-learning-path'),
                      onPressed: busy ? null : onComplete,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Leerpad afronden'),
                    ),
                  if (onInterrupt != null)
                    OutlinedButton.icon(
                      key: const ValueKey('interrupt-learning-path'),
                      onPressed: busy ? null : onInterrupt,
                      icon: const Icon(Icons.pause_outlined),
                      label: const Text('Onderbreken'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LearningPathCard extends StatelessWidget {
  const _LearningPathCard({required this.path, required this.onTap});

  final LearningPathV2 path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('learning-path-${path.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.route_outlined, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    path.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 8),
            Text(path.shortDescription),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _CompactMetadata(
                  icon: Icons.schedule_outlined,
                  value: '${path.estimatedMinutes} min',
                ),
                _CompactMetadata(
                  icon: Icons.format_list_numbered,
                  value: '${path.entries.length} onderdelen',
                ),
                _CompactMetadata(
                  icon: Icons.adjust,
                  value: _disciplineLabel(path.discipline),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PathEntryCard extends StatelessWidget {
  const _PathEntryCard({
    required this.index,
    required this.entry,
    required this.lesson,
    required this.drill,
    required this.completed,
    required this.current,
    required this.onToggleCompleted,
    required this.onOpen,
  });

  final int index;
  final LearningPathEntryV2 entry;
  final TechniqueLessonV2? lesson;
  final DrillDefinitionV2? drill;
  final bool completed;
  final bool current;
  final ValueChanged<bool>? onToggleCompleted;
  final VoidCallback? onOpen;

  String get _title =>
      lesson?.title ?? drill?.title ?? entry.versionedContentId;
  String get _description =>
      lesson?.shortPromise ?? drill?.shortPurpose ?? 'Inhoud niet beschikbaar.';

  @override
  Widget build(BuildContext context) {
    final available = lesson != null || drill != null;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: current ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: InkWell(
        key: ValueKey('learning-path-entry-${entry.id}'),
        onTap: available ? onOpen : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.kind == LearningPathEntryKind.lesson
                          ? 'LES'
                          : 'DRILL',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_description),
                    if (entry.prerequisiteEntryIds.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Bouwt voort op ${entry.prerequisiteEntryIds.length} eerder onderdeel.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (entry.kind == LearningPathEntryKind.lesson &&
                  onToggleCompleted != null)
                Checkbox(
                  key: ValueKey('learning-path-entry-complete-${entry.id}'),
                  value: completed,
                  onChanged: (value) {
                    if (value != null) onToggleCompleted!(value);
                  },
                  semanticLabel: completed
                      ? 'Onderdeel ${index + 1} als niet voltooid markeren'
                      : 'Onderdeel ${index + 1} als voltooid markeren',
                )
              else if (completed)
                const Icon(Icons.check_circle, semanticLabel: 'Voltooid')
              else if (entry.kind == LearningPathEntryKind.drill &&
                  onToggleCompleted != null)
                IconButton(
                  key: ValueKey(
                    'learning-path-check-drill-evidence-${entry.id}',
                  ),
                  tooltip: 'Voltooide drill controleren',
                  onPressed: () => onToggleCompleted!(true),
                  icon: const Icon(Icons.fact_check_outlined),
                )
              else if (available && onOpen != null)
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathConnector extends StatelessWidget {
  const _PathConnector();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: 2,
      height: 16,
      margin: const EdgeInsets.only(left: 32),
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );
}

class _CompactMetadata extends StatelessWidget {
  const _CompactMetadata({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(icon, size: 17), const SizedBox(width: 5), Text(value)],
  );
}

class _EmptyPaths extends StatelessWidget {
  const _EmptyPaths();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.route_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            'Er zijn nog geen leerpaden beschikbaar.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

String _disciplineLabel(TrainingDiscipline discipline) => switch (discipline) {
  TrainingDiscipline.universal => 'Algemeen',
  TrainingDiscipline.precisionPistol => 'Precisiepistool',
  TrainingDiscipline.br50 => 'BR50',
};

String _reviewLabel(CoachReviewStatus status) => switch (status) {
  CoachReviewStatus.pending => 'Coachreview open',
  CoachReviewStatus.reviewed => 'Coachgereviewd',
};
