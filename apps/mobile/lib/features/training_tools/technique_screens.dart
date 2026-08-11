import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shooting_companion_training/training.dart';

import '../../widgets/app_action_dock.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/compact_page_scaffold.dart';
import 'training_diagram_canvas.dart';

class TechniqueLibraryScreen extends StatefulWidget {
  const TechniqueLibraryScreen({
    this.lessons,
    this.onOpenDrill,
    this.embedded = false,
    super.key,
  });

  final List<TechniqueLessonV2>? lessons;
  final ValueChanged<String>? onOpenDrill;
  final bool embedded;

  @override
  State<TechniqueLibraryScreen> createState() => _TechniqueLibraryScreenState();
}

class _TechniqueLibraryScreenState extends State<TechniqueLibraryScreen> {
  String _query = '';
  TrainingDiscipline? _discipline;
  TechniqueCategoryV2? _category;
  TrainingSkillLevel? _skillLevel;
  int? _maximumMinutes;
  CoachReviewStatus? _reviewStatus;

  int get _activeFilterCount => <Object?>[
    _discipline,
    _category,
    _skillLevel,
    _maximumMinutes,
    _reviewStatus,
  ].whereType<Object>().length;

  void _clearFilters() {
    setState(() {
      _discipline = null;
      _category = null;
      _skillLevel = null;
      _maximumMinutes = null;
      _reviewStatus = null;
    });
  }

  List<TechniqueLessonV2> get _allLessons =>
      widget.lessons ?? BuiltInTrainingContent.catalog.lessons;

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final lessons = _allLessons
        .where((lesson) {
          final disciplineMatches =
              _discipline == null || lesson.disciplines.contains(_discipline);
          final categoryMatches =
              _category == null || lesson.category == _category;
          final levelMatches =
              _skillLevel == null || lesson.levels.contains(_skillLevel);
          final timeMatches =
              _maximumMinutes == null ||
              lesson.estimatedMinutes <= _maximumMinutes!;
          final reviewMatches =
              _reviewStatus == null ||
              lesson.review.coachReviewStatus == _reviewStatus;
          final queryMatches =
              query.isEmpty ||
              lesson.title.toLowerCase().contains(query) ||
              lesson.shortPromise.toLowerCase().contains(query) ||
              lesson.applicability.any(
                (value) => value.toLowerCase().contains(query),
              );
          return disciplineMatches &&
              categoryMatches &&
              levelMatches &&
              timeMatches &&
              reviewMatches &&
              queryMatches;
        })
        .toList(growable: false);

    final body = ListView(
      key: const ValueKey('technique-library-list'),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Text(
          'Techniekbibliotheek',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Korte, progressieve lessen met observeerbare controlepunten. '
          'De uitleg helpt je oefenen en stelt geen diagnose uit één treffer.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('technique-search'),
          decoration: const InputDecoration(
            labelText: 'Zoeken in technieken',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                _activeFilterCount == 0
                    ? 'Filters'
                    : 'Filters ($_activeFilterCount actief)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (_activeFilterCount > 0)
              TextButton(
                key: const ValueKey('technique-clear-filters'),
                onPressed: _clearFilters,
                child: const Text('Alles wissen'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _FilterRow<TrainingDiscipline>(
          label: 'Discipline',
          value: _discipline,
          values: TrainingDiscipline.values,
          itemLabel: _disciplineLabel,
          onChanged: (value) => setState(() => _discipline = value),
        ),
        const SizedBox(height: 8),
        _FilterRow<TechniqueCategoryV2>(
          label: 'Onderwerp',
          value: _category,
          values: TechniqueCategoryV2.values,
          itemLabel: _categoryLabel,
          onChanged: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: 8),
        _FilterRow<TrainingSkillLevel>(
          label: 'Niveau',
          value: _skillLevel,
          values: TrainingSkillLevel.values,
          itemLabel: _levelLabel,
          onChanged: (value) => setState(() => _skillLevel = value),
        ),
        const SizedBox(height: 8),
        _FilterRow<int>(
          label: 'Benodigde tijd',
          value: _maximumMinutes,
          values: const [5, 10, 15, 30],
          itemLabel: (minutes) => 'Tot $minutes min',
          onChanged: (value) => setState(() => _maximumMinutes = value),
        ),
        const SizedBox(height: 8),
        _FilterRow<CoachReviewStatus>(
          label: 'Reviewstatus',
          value: _reviewStatus,
          values: CoachReviewStatus.values,
          itemLabel: _coachReviewLabel,
          onChanged: (value) => setState(() => _reviewStatus = value),
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: Text(
            '${lessons.length} ${lessons.length == 1 ? 'les' : 'lessen'}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 8),
        if (lessons.isEmpty)
          const _EmptyLibraryResult()
        else
          for (final lesson in lessons)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LessonCard(
                lesson: lesson,
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TechniqueLessonScreen(
                      lesson: lesson,
                      onOpenDrill: widget.onOpenDrill,
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
    return widget.embedded
        ? body
        : CompactPageScaffold(title: 'Technieken', body: body);
  }
}

class TechniqueLessonScreen extends StatefulWidget {
  const TechniqueLessonScreen({
    required this.lesson,
    this.onOpenDrill,
    super.key,
  });

  final TechniqueLessonV2 lesson;
  final ValueChanged<String>? onOpenDrill;

  @override
  State<TechniqueLessonScreen> createState() => _TechniqueLessonScreenState();
}

class _TechniqueLessonScreenState extends State<TechniqueLessonScreen> {
  final _scrollController = ScrollController();
  var _step = 0;

  static const _layerTitles = [
    'In één minuut',
    'Stap voor stap',
    'Waarom en bronnen',
  ];

  int get _stepCount => _layerTitles.length;

  void _moveTo(int next) {
    setState(() => _step = next.clamp(0, _stepCount - 1));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const ValueKey('technique-lesson-scroll'),
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(_categoryLabel(lesson.category))),
                Chip(
                  avatar: const Icon(Icons.schedule_outlined, size: 18),
                  label: Text('${lesson.estimatedMinutes} min'),
                ),
                _ReviewChip(review: lesson.review),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lesson.shortPromise,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              label: 'Stap ${_step + 1} van $_stepCount',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _layerTitles[_step],
                          key: const ValueKey('technique-step-title'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${_step + 1}/$_stepCount'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_step + 1) / _stepCount,
                    semanticsLabel:
                        'Voortgang van deze les, stap ${_step + 1} van $_stepCount',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: switch (_step) {
                0 => _OneMinuteLayer(
                  key: const ValueKey('technique-layer-one-minute'),
                  lesson: lesson,
                ),
                1 => _StepByStepLayer(
                  key: const ValueKey('technique-layer-step-by-step'),
                  lesson: lesson,
                  onOpenDrill: widget.onOpenDrill,
                ),
                _ => _WhyAndSourcesLayer(
                  key: const ValueKey('technique-layer-why-sources'),
                  lesson: lesson,
                ),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppActionDock(
        actions: [
          if (_step > 0)
            OutlinedButton.icon(
              key: const ValueKey('technique-previous-step'),
              onPressed: () => _moveTo(_step - 1),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Vorige'),
            ),
          FilledButton.icon(
            key: const ValueKey('technique-next-step'),
            onPressed: _step < _stepCount - 1
                ? () => _moveTo(_step + 1)
                : () => Navigator.pop(context),
            icon: Icon(
              _step < _stepCount - 1 ? Icons.arrow_forward : Icons.check,
            ),
            label: Text(_step < _stepCount - 1 ? 'Volgende' : 'Les afronden'),
          ),
        ],
      ),
    );
  }
}

class _OneMinuteLayer extends StatelessWidget {
  const _OneMinuteLayer({required this.lesson, super.key});

  final TechniqueLessonV2 lesson;

  @override
  Widget build(BuildContext context) {
    final overview = lesson.sections
        .where((section) => section.type == TechniqueSectionType.overview)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lesson.shortPromise,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (lesson.applicability.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Wanneer is dit bruikbaar?',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final item in lesson.applicability) _BulletText(value: item),
        ],
        for (final section in overview) ...[
          const SizedBox(height: 18),
          _TechniqueSectionBlock(section: section),
        ],
      ],
    );
  }
}

class _StepByStepLayer extends StatelessWidget {
  const _StepByStepLayer({
    required this.lesson,
    required this.onOpenDrill,
    super.key,
  });

  final TechniqueLessonV2 lesson;
  final ValueChanged<String>? onOpenDrill;

  @override
  Widget build(BuildContext context) {
    final sections = lesson.sections
        .where((section) {
          return switch (section.type) {
            TechniqueSectionType.overview ||
            TechniqueSectionType.evidence ||
            TechniqueSectionType.limits => false,
            _ => true,
          };
        })
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final safety in lesson.safetyCallouts) ...[
          _SafetyCard(safety: safety),
          const SizedBox(height: 10),
        ],
        for (final section in sections) ...[
          _TechniqueSectionBlock(section: section),
          const SizedBox(height: 20),
        ],
        for (final diagramId in lesson.diagramIds) ...[
          TrainingDiagramCanvas(
            key: ValueKey('lesson-diagram-$diagramId'),
            diagramId: diagramId,
          ),
          const SizedBox(height: 16),
        ],
        if (lesson.selfChecks.isNotEmpty) ...[
          Text(
            'Zelfcontrole',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Controleer observeerbaar gedrag, niet alleen de score.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < lesson.selfChecks.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SelfCheckCard(
                index: index,
                selfCheck: lesson.selfChecks[index],
              ),
            ),
        ],
        if (lesson.linkedDrillIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Oefen verder',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final drillId in lesson.linkedDrillIds)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: onOpenDrill == null
                    ? null
                    : () => onOpenDrill!(drillId),
                icon: const Icon(Icons.fitness_center_outlined),
                label: Text(_contentTitle(drillId)),
              ),
            ),
        ],
      ],
    );
  }
}

class _WhyAndSourcesLayer extends StatelessWidget {
  const _WhyAndSourcesLayer({required this.lesson, super.key});

  final TechniqueLessonV2 lesson;

  @override
  Widget build(BuildContext context) {
    final sections = lesson.sections
        .where((section) {
          return section.type == TechniqueSectionType.evidence ||
              section.type == TechniqueSectionType.limits;
        })
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections) ...[
          _TechniqueSectionBlock(section: section, showSources: true),
          const SizedBox(height: 20),
        ],
        Text(
          'Bronnen',
          key: const ValueKey('technique-references'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final reference in lesson.references)
          _ReferenceTile(reference: reference),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.update),
          title: Text('Broncontrole: ${lesson.review.sourceEdition}'),
          subtitle: Text(_dateLabel(lesson.review.lastSourceCheckUtc)),
        ),
      ],
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({required this.reference});

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

class _TechniqueSectionBlock extends StatelessWidget {
  const _TechniqueSectionBlock({
    required this.section,
    this.showSources = false,
  });

  final TechniqueSection section;
  final bool showSources;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        section.title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      for (final paragraph in section.paragraphs) ...[
        Text(paragraph, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
      ],
      for (var index = 0; index < section.steps.length; index++)
        _NumberedInstruction(index: index, value: section.steps[index]),
      if (showSources && section.sourceIds.isNotEmpty)
        Text(
          'Onderbouwing: ${section.sourceIds.join(', ')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ],
  );
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 7),
          child: Icon(Icons.circle, size: 7),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _FilterRow<T> extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> values;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label filter',
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Alle'),
            selected: value == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final item in values) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(itemLabel(item)),
              selected: value == item,
              onSelected: (_) => onChanged(item),
            ),
          ],
        ],
      ),
    ),
  );
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});

  final TechniqueLessonV2 lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('technique-${lesson.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_categoryIcon(lesson.category), size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(lesson.shortPromise),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MetadataPill(
                        icon: Icons.schedule_outlined,
                        label: '${lesson.estimatedMinutes} min',
                      ),
                      _MetadataPill(
                        icon: Icons.school_outlined,
                        label: _levelLabel(lesson.levels.first),
                      ),
                    ],
                  ),
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

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({required this.review});

  final ContentReview review;

  @override
  Widget build(BuildContext context) {
    final reviewed = review.coachReviewStatus == CoachReviewStatus.reviewed;
    final label = reviewed ? 'Coachgereviewd' : 'Coachreview open';
    return Semantics(
      label: label,
      child: Chip(
        avatar: Icon(
          reviewed ? Icons.verified_outlined : Icons.science_outlined,
          size: 18,
        ),
        label: Text(label),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({required this.safety});

  final SafetyCallout safety;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safety.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(safety.instruction),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _NumberedInstruction extends StatelessWidget {
  const _NumberedInstruction({required this.index, required this.value});

  final int index;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Text(
            '${index + 1}.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _SelfCheckCard extends StatelessWidget {
  const _SelfCheckCard({required this.index, required this.selfCheck});

  final int index;
  final TechniqueSelfCheck selfCheck;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${index + 1}. ${selfCheck.prompt}',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _LabeledText(
            icon: Icons.visibility_outlined,
            label: 'Waarneembaar gelukt',
            value: selfCheck.observableSuccess,
          ),
          const SizedBox(height: 8),
          _LabeledText(
            icon: Icons.replay_outlined,
            label: 'Reset wanneer',
            value: selfCheck.resetIf,
          ),
        ],
      ),
    ),
  );
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    ],
  );
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 16), const SizedBox(width: 5), Text(label)],
    ),
  );
}

class _EmptyLibraryResult extends StatelessWidget {
  const _EmptyLibraryResult();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const Icon(Icons.search_off_outlined, size: 42),
        const SizedBox(height: 12),
        Text(
          'Geen passende lessen gevonden.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

String _categoryLabel(TechniqueCategoryV2 category) => switch (category) {
  TechniqueCategoryV2.safety => 'Veiligheid',
  TechniqueCategoryV2.measurement => 'Meten',
  TechniqueCategoryV2.position => 'Houding en steun',
  TechniqueCategoryV2.aiming => 'Richten',
  TechniqueCategoryV2.shotExecution => 'Schotuitvoering',
  TechniqueCategoryV2.routine => 'Routine',
  TechniqueCategoryV2.benchrest => 'Benchrest',
  TechniqueCategoryV2.matchProcess => 'Wedstrijdproces',
};

IconData _categoryIcon(TechniqueCategoryV2 category) => switch (category) {
  TechniqueCategoryV2.safety => Icons.shield_outlined,
  TechniqueCategoryV2.measurement => Icons.straighten,
  TechniqueCategoryV2.position => Icons.accessibility_new,
  TechniqueCategoryV2.aiming => Icons.center_focus_strong,
  TechniqueCategoryV2.shotExecution => Icons.touch_app_outlined,
  TechniqueCategoryV2.routine => Icons.repeat,
  TechniqueCategoryV2.benchrest => Icons.table_restaurant_outlined,
  TechniqueCategoryV2.matchProcess => Icons.flag_outlined,
};

String _disciplineLabel(TrainingDiscipline discipline) => switch (discipline) {
  TrainingDiscipline.universal => 'Algemeen',
  TrainingDiscipline.precisionPistol => 'Precisiepistool',
  TrainingDiscipline.br50 => 'BR50',
};

String _levelLabel(TrainingSkillLevel level) => switch (level) {
  TrainingSkillLevel.foundation => 'Basis',
  TrainingSkillLevel.development => 'Verdieping',
};

String _coachReviewLabel(CoachReviewStatus status) => switch (status) {
  CoachReviewStatus.pending => 'Coachreview open',
  CoachReviewStatus.reviewed => 'Coachgereviewd',
};

String _contentTitle(String versionedId) =>
    BuiltInTrainingContent.catalog.drillByVersionedId(versionedId)?.title ??
    versionedId;

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
