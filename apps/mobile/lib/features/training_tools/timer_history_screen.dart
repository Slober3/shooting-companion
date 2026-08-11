import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_notice.dart';

class TimerHistoryScreen extends ConsumerWidget {
  const TimerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(trainingActivitiesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Timergeschiedenis')),
      body: activities.when(
        data: (items) {
          final timerItems = items
              .where((item) => _isTimerKind(item.kind))
              .toList();
          if (timerItems.isEmpty) {
            return const _EmptyTimerHistory();
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            itemCount: timerItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final activity = timerItems[index];
              final summary = _jsonObject(activity.summaryJson);
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minTileHeight: 76,
                  leading: Icon(_kindIcon(activity.kind)),
                  title: Text(_kindLabel(activity.kind)),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy HH:mm', 'nl_BE').format(activity.startedAtUtc.toLocal())}\n'
                    '${_summaryLine(summary, activity.status)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) =>
                          TimerActivityDetailScreen(activityId: activity.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('De timergeschiedenis kon niet worden geladen.'),
        ),
      ),
    );
  }
}

class TimerActivityDetailScreen extends ConsumerWidget {
  const TimerActivityDetailScreen({required this.activityId, super.key});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(trainingActivityProvider(activityId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timerresultaat'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Timeracties',
            onSelected: (value) {
              if (value == 'delete') unawaited(_delete(context, ref));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline),
                  title: Text('Timerrun verwijderen'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: detail.when(
        data: (value) => value == null
            ? const Center(child: Text('Deze timerrun bestaat niet meer.'))
            : _TimerActivityBody(detail: value),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Het timerresultaat kon niet worden geladen.'),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timerrun verwijderen?'),
        content: const Text(
          'De tijden, splits en eventuele reekskoppeling worden verwijderd. '
          'Scores en treffers veranderen niet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(repositoryProvider).deleteTrainingActivity(activityId);
    if (context.mounted) {
      Navigator.pop(context);
      AppMessenger.success(context, 'Timerrun verwijderd');
    }
  }
}

class AcousticCalibrationProfilesScreen extends ConsumerWidget {
  const AcousticCalibrationProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(acousticCalibrationProfilesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Akoestische profielen')),
      body: profiles.when(
        data: (items) => items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Nog geen profielen. Bewaar gevoeligheid en echofilter '
                    'vanuit de instellingen van de akoestische timer.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  24 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final profile = items[index];
                  return ListTile(
                    leading: const Icon(Icons.graphic_eq),
                    title: Text(profile.name),
                    subtitle: Text(
                      '${profile.environment} · gevoeligheid '
                      '${profile.sensitivity.toStringAsFixed(2).replaceAll('.', ',')} · '
                      'echo ${profile.echoLockoutMicroseconds ~/ 1000} ms',
                    ),
                    trailing: IconButton(
                      tooltip: 'Kalibratieprofiel verwijderen',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteProfile(
                        context,
                        ref,
                        profile.id,
                        profile.name,
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('De kalibratieprofielen konden niet worden geladen.'),
        ),
      ),
    );
  }

  Future<void> _deleteProfile(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kalibratieprofiel verwijderen?'),
        content: Text(
          '“$name” wordt verwijderd. Eerdere timerruns behouden hun '
          'opgeslagen configuratiesnapshot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(repositoryProvider).deleteCalibrationProfile(id);
    if (context.mounted) {
      AppMessenger.success(context, 'Kalibratieprofiel verwijderd');
    }
  }
}

class _TimerActivityBody extends ConsumerWidget {
  const _TimerActivityBody({required this.detail});

  final TrainingActivityDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = detail.activity;
    final summary = _jsonObject(activity.summaryJson);
    final counted = detail.events
        .where((event) => event.disposition == 'counted')
        .toList();
    final excludedCount = detail.events.length - counted.length;
    final isExternalSummaryOnly =
        summary['externalTimingCompleteness'] == 'summaryOnly';
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Text(
          _kindLabel(activity.kind),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat(
            'EEEE d MMMM yyyy · HH:mm',
            'nl_BE',
          ).format(activity.startedAtUtc.toLocal()),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _TimerMetric(
              value: isExternalSummaryOnly
                  ? 'Niet ingevoerd'
                  : '${summary['countedShotCount'] ?? counted.length}',
              label: 'Schotaantal',
            ),
            _TimerMetric(
              value: _micros(summary['firstShotTimeMicros']),
              label: 'Eerste schot',
            ),
            _TimerMetric(
              value: _micros(summary['totalTimeMicros']),
              label: 'Totale tijd',
            ),
            _TimerMetric(
              value: _micros(summary['averageSplitMicros']),
              label: 'Gemiddelde split',
            ),
          ],
        ),
        if (detail.links.isNotEmpty) ...[
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link),
            title: const Text('Aan een reeks gekoppeld'),
            subtitle: Text(
              detail.links.length == 1
                  ? 'Deze run hoort bij één reeks.'
                  : 'Deze activiteit hoort bij ${detail.links.length} reeksen.',
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Events',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (excludedCount > 0) Text('$excludedCount uitgesloten'),
          ],
        ),
        const SizedBox(height: 8),
        if (detail.events.isEmpty)
          Text(
            isExternalSummaryOnly
                ? 'Geen afzonderlijke schottijden of splits ingevoerd. '
                      'De eerste-schottijd en totale tijd blijven wel bewaard.'
                : 'Deze modus bevat geen schotdetecties.',
          )
        else
          for (final event in detail.events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text('${event.sequenceNumber}')),
              title: Text(
                '${_micros(event.elapsedMicroseconds)} · split ${_micros(event.splitMicroseconds)}',
              ),
              subtitle: Text(
                event.disposition == 'counted'
                    ? _sourceLabel(event.source)
                    : 'Uitgesloten${event.exclusionReason == null ? '' : ' · ${event.exclusionReason}'}',
              ),
              trailing: event.disposition == 'counted'
                  ? null
                  : const Icon(Icons.visibility_off_outlined),
            ),
        if (activity.notes != null) ...[
          const SizedBox(height: 16),
          Text('Notitie', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(activity.notes!),
        ],
        if (detail.links.length == 1) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _copySummaryToSeriesNote(
              context,
              ref,
              detail.links.single.seriesId,
              summary,
            ),
            icon: const Icon(Icons.note_add_outlined),
            label: const Text('Samenvatting naar reeksnotitie'),
          ),
        ],
        const SizedBox(height: 20),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Trainingsmeting — timer-events wijzigen nooit de score of het '
              'aantal treffers van een gekoppelde reeks.',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copySummaryToSeriesNote(
    BuildContext context,
    WidgetRef ref,
    String seriesId,
    Map<String, Object?> summary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aan reeksnotitie toevoegen?'),
        content: Text(_noteSummary(detail.activity.kind, summary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Toevoegen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(repositoryProvider)
        .appendTimerSummaryToSeriesNote(
          seriesId,
          _noteSummary(detail.activity.kind, summary),
        );
    if (context.mounted) {
      AppMessenger.success(
        context,
        'Samenvatting aan de reeksnotitie toegevoegd',
      );
    }
  }
}

class _TimerMetric extends StatelessWidget {
  const _TimerMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 148,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class _EmptyTimerHistory extends StatelessWidget {
  const _EmptyTimerHistory();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Nog geen timerruns',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Bewaarde live-fire-, par-, cadans- en externe metingen verschijnen hier.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Map<String, Object?> _jsonObject(String value) {
  try {
    return (jsonDecode(value) as Map).cast<String, Object?>();
  } catch (_) {
    return const {};
  }
}

bool _isTimerKind(String value) => const {
  'acousticLiveFire',
  'par',
  'cadence',
  'externalManual',
}.contains(value);

String _kindLabel(String value) => switch (value) {
  'acousticLiveFire' => 'Akoestische shot timer',
  'par' => 'Par timer',
  'cadence' => 'Cadanstrainer',
  'externalManual' => 'Extern gemeten',
  _ => 'Trainingsactiviteit',
};

IconData _kindIcon(String value) => switch (value) {
  'acousticLiveFire' => Icons.mic_outlined,
  'par' => Icons.notifications_active_outlined,
  'cadence' => Icons.multiline_chart,
  'externalManual' => Icons.edit_outlined,
  _ => Icons.fitness_center_outlined,
};

String _summaryLine(Map<String, Object?> summary, String status) {
  if (status == 'interrupted') return 'Onderbroken';
  if (summary['externalTimingCompleteness'] == 'summaryOnly') {
    final first = _micros(summary['firstShotTimeMicros']);
    final total = _micros(summary['totalTimeMicros']);
    return 'Eerste $first · totaal $total · splits niet ingevoerd';
  }
  final shots = (summary['countedShotCount'] as num?)?.toInt();
  final total = _micros(summary['totalTimeMicros']);
  if (shots == null) return total == '—' ? 'Voltooid' : total;
  return '$shots schoten · $total';
}

String _micros(Object? value) {
  final micros = (value as num?)?.toInt();
  if (micros == null) return '—';
  return '${(micros / 1000000).toStringAsFixed(2).replaceAll('.', ',')} s';
}

String _sourceLabel(String value) => switch (value) {
  'acoustic' => 'Akoestisch gedetecteerd',
  'manual' => 'Handmatig toegevoegd',
  'generatedPar' => 'Gegenereerd signaal',
  'external' => 'Extern gemeten',
  _ => value,
};

String _noteSummary(String kind, Map<String, Object?> summary) {
  final shots = (summary['countedShotCount'] as num?)?.toInt();
  final first = _micros(summary['firstShotTimeMicros']);
  final total = _micros(summary['totalTimeMicros']);
  final average = _micros(summary['averageSplitMicros']);
  final isExternalSummaryOnly =
      summary['externalTimingCompleteness'] == 'summaryOnly';
  return [
    'Timer — ${_kindLabel(kind)}',
    if (shots != null) '$shots schoten',
    if (first != '—') 'eerste schot $first',
    if (total != '—') 'totaal $total',
    if (average != '—') 'gemiddelde split $average',
    if (isExternalSummaryOnly) 'splits niet ingevoerd',
  ].join(' · ');
}
