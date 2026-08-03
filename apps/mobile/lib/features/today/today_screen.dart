import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/compact_page_scaffold.dart';
import '../session/active_session_screen.dart';
import '../session/manual_series_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    return CompactPageScaffold(
      title: 'Start',
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Tooltip(
            message: 'Volledig offline',
            child: Icon(Icons.offline_bolt_outlined),
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sessionsProvider);
          await ref.read(sessionsProvider.future);
        },
        child: sessions.when(
          data: (items) {
            final active = _activeSession(items);
            final recent = items
                .where((item) => item.status == 'completed')
                .take(3)
                .toList();
            return ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
                if (active == null)
                  _StartPrompt(onStart: () => _startQuick(context, ref))
                else
                  _ActiveSessionPanel(
                    session: active,
                    onContinue: (series) =>
                        _continue(context, ref, active, series),
                    onNewSession: (series) =>
                        _replaceActive(context, ref, active, series),
                    onOpenDetails: () => _openDetails(context, active.id),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (recent.isNotEmpty)
                      Text(
                        'Laatste ${recent.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recent.isEmpty)
                  const _EmptyRecent()
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        for (var index = 0; index < recent.length; index++) ...[
                          _RecentSessionRow(session: recent[index]),
                          if (index != recent.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Start laden mislukt: $error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(sessionsProvider),
                    child: const Text('Opnieuw proberen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startQuick(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(repositoryProvider).startQuickSession();
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ManualSeriesScreen(
            sessionId: result.sessionId,
            seriesId: result.draftSeriesId,
          ),
        ),
      );
    } on ActiveSessionExistsException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Er is al een actieve sessie.')),
      );
    }
  }

  Future<void> _continue(
    BuildContext context,
    WidgetRef ref,
    SessionRecord session,
    List<SeriesRecord> series,
  ) async {
    final drafts = series.where((item) => item.status == 'draft');
    final draftId = drafts.isNotEmpty
        ? drafts.first.id
        : await ref
              .read(repositoryProvider)
              .createOrResumeDraftSeries(session.id);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ManualSeriesScreen(sessionId: session.id, seriesId: draftId),
      ),
    );
  }

  Future<void> _replaceActive(
    BuildContext context,
    WidgetRef ref,
    SessionRecord session,
    List<SeriesRecord> series,
  ) async {
    final nonEmptyDrafts = series.where(
      (item) => item.status == 'draft' && item.shotCount > 0,
    );
    if (nonEmptyDrafts.isNotEmpty) {
      final draft = nonEmptyDrafts.first;
      final decision = await showDialog<_DraftReplacementDecision>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Conceptreeks nog niet bewaard'),
          content: Text(
            'Deze reeks bevat ${draft.shotCount} ${draft.shotCount == 1 ? 'schot' : 'schoten'}. Open de reeks om ze te bewaren, of verwijder het concept voordat je een nieuwe sessie start.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren'),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(context, _DraftReplacementDecision.openDraft),
              child: const Text('Reeks openen'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, _DraftReplacementDecision.deleteDraft),
              child: const Text('Concept verwijderen en nieuwe sessie'),
            ),
          ],
        ),
      );
      if (!context.mounted || decision == null) return;
      if (decision == _DraftReplacementDecision.openDraft) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ManualSeriesScreen(sessionId: session.id, seriesId: draft.id),
          ),
        );
        return;
      }
      await ref.read(repositoryProvider).deleteSeries(draft.id);
      if (!context.mounted) return;
      await ref.read(repositoryProvider).completeSession(session.id);
      if (!context.mounted) return;
      await _startQuick(context, ref);
      return;
    }

    final confirmedCount = series
        .where((item) => item.status == 'confirmed')
        .length;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuwe sessie starten?'),
        content: Text(
          confirmedCount == 0
              ? 'De huidige lege sessie wordt verwijderd. Daarna start meteen een nieuwe reeks.'
              : 'De huidige sessie met $confirmedCount ${confirmedCount == 1 ? 'reeks' : 'reeksen'} wordt eerst beëindigd.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Doorgaan'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await ref.read(repositoryProvider).completeSession(session.id);
    if (!context.mounted) return;
    await _startQuick(context, ref);
  }

  void _openDetails(BuildContext context, String sessionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveSessionScreen(sessionId: sessionId),
      ),
    );
  }
}

class _StartPrompt extends StatelessWidget {
  const _StartPrompt({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 8),
      Icon(
        Icons.adjust,
        size: 56,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 12),
      Text(
        'Klaar voor je volgende reeks?',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      const Text(
        'Je laatste kaart, kaliber en afstand worden automatisch overgenomen.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.add),
          label: const Text('Nieuwe sessie'),
        ),
      ),
    ],
  );
}

class _ActiveSessionPanel extends ConsumerWidget {
  const _ActiveSessionPanel({
    required this.session,
    required this.onContinue,
    required this.onNewSession,
    required this.onOpenDetails,
  });

  final SessionRecord session;
  final ValueChanged<List<SeriesRecord>> onContinue;
  final ValueChanged<List<SeriesRecord>> onNewSession;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSeries = ref.watch(seriesProvider(session.id));
    final series = asyncSeries.valueOrNull ?? const <SeriesRecord>[];
    final confirmed = series
        .where((item) => item.status == 'confirmed')
        .toList();
    final score = confirmed.fold(0, (sum, item) => sum + item.totalScore);
    final maximum = confirmed.fold(
      0,
      (sum, item) => sum + item.maximumPossibleScore,
    );
    final shots = confirmed.fold(0, (sum, item) => sum + item.shotCount);
    final note = session.notes?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onOpenDetails,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.play_circle_outline),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Actieve sessie',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              DateFormat(
                                'd MMM · HH:mm',
                                'nl_BE',
                              ).format(session.startedAtUtc.toLocal()),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _CompactMetric(
                        label: confirmed.length == 1 ? 'reeks' : 'reeksen',
                        value: '${confirmed.length}',
                      ),
                      _CompactMetric(label: 'score', value: '$score/$maximum'),
                      _CompactMetric(label: 'schoten', value: '$shots'),
                    ],
                  ),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: asyncSeries.isLoading ? null : () => onContinue(series),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Verdergaan'),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: asyncSeries.isLoading ? null : () => onNewSession(series),
          icon: const Icon(Icons.add),
          label: const Text('Nieuwe sessie'),
        ),
      ],
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' $label'),
        ],
      ),
    ),
  );
}

class _RecentSessionRow extends ConsumerWidget {
  const _RecentSessionRow({required this.session});

  final SessionRecord session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series =
        ref.watch(seriesProvider(session.id)).valueOrNull ??
        const <SeriesRecord>[];
    final confirmed = series.where((item) => item.status == 'confirmed');
    final score = confirmed.fold(0, (sum, item) => sum + item.totalScore);
    final maximum = confirmed.fold(
      0,
      (sum, item) => sum + item.maximumPossibleScore,
    );
    return ListTile(
      minTileHeight: 64,
      title: Text(
        session.trainingGoal?.trim().isNotEmpty == true
            ? session.trainingGoal!
            : DateFormat(
                'd MMMM yyyy',
                'nl_BE',
              ).format(session.startedAtUtc.toLocal()),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('$score/$maximum · ${confirmed.length} reeksen'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActiveSessionScreen(sessionId: session.id),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('Voltooide sessies verschijnen hier.'),
    ),
  );
}

SessionRecord? _activeSession(List<SessionRecord> sessions) {
  for (final session in sessions) {
    if (session.status == 'active') return session;
  }
  return null;
}

enum _DraftReplacementDecision { openDraft, deleteDraft }
