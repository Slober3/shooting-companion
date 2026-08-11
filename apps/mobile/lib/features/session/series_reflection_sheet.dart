import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/safe_sheet_scaffold.dart';

enum SeriesReflectionPromptResult { disabled, skipped, saved, failed }

class SeriesReflectionDraft {
  const SeriesReflectionDraft({
    required this.perceivedQuality,
    this.contextTags = const {},
  });

  final PerceivedQuality perceivedQuality;
  final Set<ReflectionContextTag> contextTags;
}

/// Shows the stored self-evaluation on the series itself and keeps it editable.
class SeriesReflectionCard extends ConsumerWidget {
  const SeriesReflectionCard({required this.seriesId, super.key});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reflection = ref.watch(seriesReflectionProvider(seriesId));
    return Card(
      key: const ValueKey('series-reflection-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: reflection.when(
          data: (value) => _ReflectionCardContent(
            reflection: value,
            onEdit: () => _edit(context, ref, value),
          ),
          loading: () => const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => Row(
            children: [
              const Expanded(
                child: Text('Zelfevaluatie kon niet worden geladen.'),
              ),
              IconButton(
                tooltip: 'Opnieuw laden',
                onPressed: () =>
                    ref.invalidate(seriesReflectionProvider(seriesId)),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    SeriesReflectionRecord? reflection,
  ) async {
    final draft = await showSeriesReflectionSheet(
      context: context,
      initial: reflection == null ? null : seriesReflectionDraft(reflection),
    );
    if (draft == null || !context.mounted) return;
    try {
      await ref
          .read(repositoryProvider)
          .saveSeriesReflection(
            seriesId: seriesId,
            perceivedQuality: draft.perceivedQuality,
            contextTags: draft.contextTags,
          );
      if (context.mounted) {
        AppMessenger.success(context, 'Zelfevaluatie bewaard');
      }
    } on Object {
      if (context.mounted) {
        AppMessenger.error(context, 'Zelfevaluatie kon niet worden bewaard.');
      }
    }
  }
}

class _ReflectionCardContent extends StatelessWidget {
  const _ReflectionCardContent({
    required this.reflection,
    required this.onEdit,
  });

  final SeriesReflectionRecord? reflection;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final value = reflection;
    final tags = value == null
        ? const <ReflectionContextTag>{}
        : seriesReflectionDraft(value).contextTags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.self_improvement_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Zelfevaluatie',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              key: const ValueKey('edit-series-reflection'),
              onPressed: onEdit,
              icon: Icon(value == null ? Icons.add : Icons.edit_outlined),
              label: Text(value == null ? 'Toevoegen' : 'Bewerken'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (value == null)
          const Text('Nog geen gevoel of context voor deze reeks vastgelegd.')
        else ...[
          Row(
            children: [
              Icon(seriesReflectionQualityIcon(_quality(value))),
              const SizedBox(width: 8),
              Text(
                seriesReflectionQualityLabel(_quality(value)),
                key: const ValueKey('series-reflection-quality'),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  Chip(label: Text(seriesReflectionTagLabel(tag))),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

/// Shows the optional five-second reflection and stores it for [seriesId].
///
/// Call this after the series transaction has completed. When coach mode is
/// disabled this returns immediately without building a route. The score flow
/// therefore remains unchanged for users who do not opt in.
Future<SeriesReflectionPromptResult> maybeShowSeriesReflectionPrompt({
  required BuildContext context,
  required WidgetRef ref,
  required String seriesId,
}) async {
  final preferences = ref.read(coachingPreferencesRepositoryProvider);
  final repository = ref.read(repositoryProvider);
  if (!await preferences.readCoachMode()) {
    return SeriesReflectionPromptResult.disabled;
  }
  if (!context.mounted) return SeriesReflectionPromptResult.skipped;

  final draft = await showSeriesReflectionSheet(context: context);
  if (draft == null) return SeriesReflectionPromptResult.skipped;

  try {
    await repository.saveSeriesReflection(
      seriesId: seriesId,
      perceivedQuality: draft.perceivedQuality,
      contextTags: draft.contextTags,
    );
    return SeriesReflectionPromptResult.saved;
  } catch (_) {
    if (context.mounted) {
      AppMessenger.error(context, 'Reflectie kon niet worden opgeslagen.');
    }
    return SeriesReflectionPromptResult.failed;
  }
}

Future<SeriesReflectionDraft?> showSeriesReflectionSheet({
  required BuildContext context,
  SeriesReflectionDraft? initial,
}) => showSafeModalSheet<SeriesReflectionDraft>(
  context: context,
  presentation: SafeSheetPresentation.compact,
  builder: (_) => SeriesReflectionSheet(initial: initial),
);

class SeriesReflectionSheet extends StatefulWidget {
  const SeriesReflectionSheet({this.initial, super.key});

  final SeriesReflectionDraft? initial;

  @override
  State<SeriesReflectionSheet> createState() => _SeriesReflectionSheetState();
}

class _SeriesReflectionSheetState extends State<SeriesReflectionSheet> {
  late bool _showContext;
  late PerceivedQuality? _quality;
  late Set<ReflectionContextTag> _contextTags;
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _showContext = widget.initial != null;
    _quality = widget.initial?.perceivedQuality;
    _contextTags = {...?widget.initial?.contextTags};
  }

  @override
  Widget build(BuildContext context) => SafeSheetScaffold(
    title: 'Korte reflectie',
    contentSized: true,
    bodyPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    body: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hoe voelde deze reeks?',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Optioneel en in ongeveer vijf seconden klaar.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final quality in PerceivedQuality.values)
              _QualityButton(
                quality: quality,
                selected: _quality == quality,
                onPressed: () => _selectQuality(quality),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_showContext) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('reflection-more-context'),
              onPressed: () => setState(() => _showContext = true),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Meer context'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('reflection-skip'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Overslaan'),
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text(
            'Context (maximaal 3)',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in ReflectionContextTag.values)
                FilterChip(
                  key: ValueKey('reflection-tag-${tag.name}'),
                  label: Text(seriesReflectionTagLabel(tag)),
                  selected: _contextTags.contains(tag),
                  onSelected: (_) => _toggleTag(tag),
                ),
            ],
          ),
          if (_limitReached) ...[
            const SizedBox(height: 8),
            Text(
              'Kies maximaal drie contexttags.',
              key: const ValueKey('reflection-tag-limit'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ],
    ),
    actions: _showContext
        ? [
            TextButton(
              key: const ValueKey('reflection-skip'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Overslaan'),
            ),
            FilledButton(
              key: const ValueKey('reflection-save'),
              onPressed: _quality == null ? null : _complete,
              child: const Text('Bewaren'),
            ),
          ]
        : const [],
  );

  void _selectQuality(PerceivedQuality quality) {
    if (!_showContext) {
      Navigator.pop(context, SeriesReflectionDraft(perceivedQuality: quality));
      return;
    }
    setState(() => _quality = quality);
  }

  void _toggleTag(ReflectionContextTag tag) {
    setState(() {
      if (_contextTags.remove(tag)) {
        _limitReached = false;
      } else if (_contextTags.length >= 3) {
        _limitReached = true;
      } else {
        _contextTags.add(tag);
        _limitReached = false;
      }
    });
  }

  void _complete() => Navigator.pop(
    context,
    SeriesReflectionDraft(
      perceivedQuality: _quality!,
      contextTags: Set.unmodifiable(_contextTags),
    ),
  );
}

class _QualityButton extends StatelessWidget {
  const _QualityButton({
    required this.quality,
    required this.selected,
    required this.onPressed,
  });

  final PerceivedQuality quality;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = seriesReflectionQualityLabel(quality);
    final icon = seriesReflectionQualityIcon(quality);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label als gevoel van de reeks',
      child: selected
          ? FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}

String seriesReflectionQualityLabel(PerceivedQuality quality) =>
    switch (quality) {
      PerceivedQuality.good => 'Goed',
      PerceivedQuality.neutral => 'Neutraal',
      PerceivedQuality.difficult => 'Moeilijk',
    };

IconData seriesReflectionQualityIcon(PerceivedQuality quality) =>
    switch (quality) {
      PerceivedQuality.good => Icons.sentiment_satisfied_alt,
      PerceivedQuality.neutral => Icons.sentiment_neutral,
      PerceivedQuality.difficult => Icons.sentiment_dissatisfied,
    };

String seriesReflectionTagLabel(ReflectionContextTag tag) => switch (tag) {
  ReflectionContextTag.sightPicture => 'Richtbeeld',
  ReflectionContextTag.trigger => 'Trekker',
  ReflectionContextTag.gripOrPosition => 'Grip/houding',
  ReflectionContextTag.breathing => 'Ademhaling',
  ReflectionContextTag.followThrough => 'Follow-through',
  ReflectionContextTag.tempo => 'Tempo',
  ReflectionContextTag.lightOrWind => 'Licht/wind',
  ReflectionContextTag.equipment => 'Materiaal',
  ReflectionContextTag.perceivedFatigue => 'Vermoeid gevoel',
};

SeriesReflectionDraft seriesReflectionDraft(SeriesReflectionRecord record) =>
    SeriesReflectionDraft(
      perceivedQuality: _quality(record),
      contextTags: _decodeReflectionTags(record.contextTagsJson),
    );

PerceivedQuality _quality(SeriesReflectionRecord record) =>
    PerceivedQuality.values.firstWhere(
      (value) => value.name == record.perceivedQuality,
      orElse: () => PerceivedQuality.neutral,
    );

Set<ReflectionContextTag> _decodeReflectionTags(String source) {
  try {
    final names = (jsonDecode(source) as List).whereType<String>().toSet();
    return {
      for (final value in ReflectionContextTag.values)
        if (names.contains(value.name)) value,
    };
  } on Object {
    return const {};
  }
}
