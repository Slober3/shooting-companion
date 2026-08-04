import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/compact_page_scaffold.dart';
import '../session/active_session_screen.dart';
import '../session/manual_series_screen.dart';
import '../session/session_completion_flow.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const _allSessions = SessionListFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionListItemsProvider(_allSessions));
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
          ref.invalidate(sessionListItemsProvider(_allSessions));
          await ref.read(sessionListItemsProvider(_allSessions).future);
        },
        child: sessions.when(
          data: (items) {
            final active = _activeSession(items);
            final recent = items
                .where((item) => item.session.status == 'completed')
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
                    item: active,
                    onContinue: () => _continue(context, ref, active),
                    onEndSession: () => _endActive(context, ref, active),
                    onNewSession: () => _replaceActive(context, ref, active),
                    onOpenDetails: () =>
                        _openDetails(context, active.session.id),
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
                          _RecentSessionRow(item: recent[index]),
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
                    onPressed: () =>
                        ref.invalidate(sessionListItemsProvider(_allSessions)),
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
    SessionListItem item,
  ) async {
    final draftId =
        item.draftSeriesId ??
        await ref
            .read(repositoryProvider)
            .createOrResumeDraftSeries(item.session.id);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ManualSeriesScreen(sessionId: item.session.id, seriesId: draftId),
      ),
    );
  }

  Future<void> _replaceActive(
    BuildContext context,
    WidgetRef ref,
    SessionListItem item,
  ) async {
    if (item.hasMeaningfulDraft) {
      final decision = await showDialog<_DraftReplacementDecision>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Conceptreeks nog niet bewaard'),
          content: Text(
            'Deze reeks bevat ${_draftContentDescription(item)}. '
            'Open de reeks om ze te bewaren, of verwijder het concept voordat je een nieuwe sessie start.',
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
        final draftId = item.draftSeriesId;
        if (draftId == null) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ManualSeriesScreen(
              sessionId: item.session.id,
              seriesId: draftId,
            ),
          ),
        );
        return;
      }
      await ref
          .read(repositoryProvider)
          .discardDraftAndCompleteSession(item.session.id);
      if (!context.mounted) return;
      await _startQuick(context, ref);
      return;
    }

    final confirmedCount = item.confirmedSeriesCount;
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
    await ref.read(repositoryProvider).completeSession(item.session.id);
    if (!context.mounted) return;
    await _startQuick(context, ref);
  }

  Future<void> _endActive(
    BuildContext context,
    WidgetRef ref,
    SessionListItem item,
  ) async {
    await SessionCompletionCoordinator.run(
      context: context,
      repository: ref.read(repositoryProvider),
      sessionId: item.session.id,
      promptData: SessionEndPromptData(
        confirmedSeriesCount: item.confirmedSeriesCount,
        draftSeriesId: item.draftSeriesId,
        draftShotCount: item.draftShotCount,
        draftPhotoCount: item.draftPhotoCount,
        draftHasNotes: item.draftHasNotes,
        draftWasEdited: item.draftWasEdited,
        sessionPhotoCount: item.sessionPhotoCount,
        hasSessionDetails: item.session.hasUserDetails,
      ),
      openDraft: (_) => _continue(context, ref, item),
    );
  }

  void _openDetails(BuildContext context, String sessionId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveSessionScreen(sessionId: sessionId),
      ),
    );
  }
}

String _draftContentDescription(SessionListItem item) {
  final parts = <String>[];
  if (item.draftShotCount > 0) {
    parts.add(
      '${item.draftShotCount} ${item.draftShotCount == 1 ? 'schot' : 'schoten'}',
    );
  }
  if (item.draftPhotoCount > 0) {
    parts.add(
      '${item.draftPhotoCount} ${item.draftPhotoCount == 1 ? 'foto' : 'foto’s'}',
    );
  }
  if (item.draftHasNotes) parts.add('een notitie');
  if (parts.isEmpty && item.draftWasEdited) {
    parts.add('gewijzigde instellingen');
  }
  return parts.join(' en ');
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

class _ActiveSessionPanel extends StatelessWidget {
  const _ActiveSessionPanel({
    required this.item,
    required this.onContinue,
    required this.onEndSession,
    required this.onNewSession,
    required this.onOpenDetails,
  });

  final SessionListItem item;
  final VoidCallback onContinue;
  final VoidCallback onEndSession;
  final VoidCallback onNewSession;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final session = item.session;
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
                        label: item.confirmedSeriesCount == 1
                            ? 'reeks'
                            : 'reeksen',
                        value: '${item.confirmedSeriesCount}',
                      ),
                      _CompactMetric(
                        label: 'score',
                        value:
                            '${item.totalScore}/${item.maximumPossibleScore}',
                      ),
                      _CompactMetric(
                        label: 'schoten',
                        value: '${item.shotCount}',
                      ),
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
            onPressed: onContinue,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Verdergaan'),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onEndSession,
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Sessie beëindigen'),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: onNewSession,
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

class _RecentSessionRow extends StatelessWidget {
  const _RecentSessionRow({required this.item});

  final SessionListItem item;

  @override
  Widget build(BuildContext context) {
    final session = item.session;
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
      subtitle: Text(
        '${item.totalScore}/${item.maximumPossibleScore} · '
        '${item.confirmedSeriesCount} reeksen',
      ),
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

SessionListItem? _activeSession(List<SessionListItem> sessions) {
  for (final item in sessions) {
    if (item.session.status == 'active') return item;
  }
  return null;
}

enum _DraftReplacementDecision { openDraft, deleteDraft }
