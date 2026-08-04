import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/compact_page_scaffold.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/safe_sheet_scaffold.dart';
import '../session/active_session_screen.dart';
import '../session/manual_series_screen.dart';
import '../session/session_completion_flow.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _SessionStatusFilter _status = _SessionStatusFilter.all;
  _LogPeriod _period = _LogPeriod.all;

  int get _activeFilterCount =>
      (_status == _SessionStatusFilter.all ? 0 : 1) +
      (_period == _LogPeriod.all ? 0 : 1);

  SessionListFilters get _filters => SessionListFilters(
    status: switch (_status) {
      _SessionStatusFilter.all => SessionListStatusFilter.all,
      _SessionStatusFilter.active => SessionListStatusFilter.active,
      _SessionStatusFilter.completed => SessionListStatusFilter.completed,
    },
    startedAtOrAfterUtc: _cutoffFor(_period),
  );

  DateTime? _cutoffFor(_LogPeriod period) {
    if (period == _LogPeriod.all) return null;
    final now = DateTime.now().toUtc();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    return switch (period) {
      _LogPeriod.all => null,
      _LogPeriod.last30Days => todayUtc.subtract(const Duration(days: 30)),
      _LogPeriod.last90Days => todayUtc.subtract(const Duration(days: 90)),
      _LogPeriod.lastYear => todayUtc.subtract(const Duration(days: 365)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final filters = _filters;
    final sessions = ref.watch(sessionListItemsProvider(filters));
    return CompactPageScaffold(
      title: 'Logboek',
      actions: [
        IconButton(
          key: const Key('history-filter-button'),
          tooltip: 'Logboekfilters',
          onPressed: _showFilters,
          icon: _activeFilterCount == 0
              ? const Icon(Icons.filter_list)
              : Badge(
                  label: Text('$_activeFilterCount'),
                  child: const Icon(Icons.filter_list),
                ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sessionListItemsProvider(filters));
          await ref.read(sessionListItemsProvider(filters).future);
        },
        child: sessions.when(
          data: (visibleSessions) {
            return CustomScrollView(
              slivers: [
                if (_activeFilterCount > 0)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    sliver: SliverToBoxAdapter(
                      child: _ActiveFilterChips(
                        status: _status,
                        period: _period,
                        clearStatus: () =>
                            setState(() => _status = _SessionStatusFilter.all),
                        clearPeriod: () =>
                            setState(() => _period = _LogPeriod.all),
                      ),
                    ),
                  ),
                if (visibleSessions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyLogbook(filtered: _activeFilterCount > 0),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      _activeFilterCount == 0 ? 8 : 4,
                      16,
                      24 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    sliver: SliverList.separated(
                      itemCount: visibleSessions.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _SessionRow(item: visibleSessions[index]),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Logboek laden mislukt: $error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFilters() async {
    var selectedStatus = _status;
    var selectedPeriod = _period;
    final result = await showSafeModalSheet<(_SessionStatusFilter, _LogPeriod)>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeSheetScaffold(
          title: 'Logboek filteren',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in _SessionStatusFilter.values)
                    ChoiceChip(
                      label: Text(option.label),
                      selected: selectedStatus == option,
                      onSelected: (_) =>
                          setSheetState(() => selectedStatus = option),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Periode', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in _LogPeriod.values)
                    ChoiceChip(
                      label: Text(option.label),
                      selected: selectedPeriod == option,
                      onSelected: (_) =>
                          setSheetState(() => selectedPeriod = option),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => setSheetState(() {
                selectedStatus = _SessionStatusFilter.all;
                selectedPeriod = _LogPeriod.all;
              }),
              child: const Text('Filters wissen'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(sheetContext, (selectedStatus, selectedPeriod)),
              child: const Text('Toepassen'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _status = result.$1;
      _period = result.$2;
    });
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.status,
    required this.period,
    required this.clearStatus,
    required this.clearPeriod,
  });

  final _SessionStatusFilter status;
  final _LogPeriod period;
  final VoidCallback clearStatus;
  final VoidCallback clearPeriod;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        if (status != _SessionStatusFilter.all) ...[
          InputChip(
            label: Text('Status: ${status.label}'),
            onDeleted: clearStatus,
          ),
          const SizedBox(width: 8),
        ],
        if (period != _LogPeriod.all)
          InputChip(label: Text(period.label), onDeleted: clearPeriod),
      ],
    ),
  );
}

class _SessionRow extends ConsumerWidget {
  const _SessionRow({required this.item});

  final SessionListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = item.session;
    final date = DateFormat(
      'd MMM yyyy · HH:mm',
      'nl_BE',
    ).format(session.startedAtUtc.toLocal());

    return Semantics(
      container: true,
      label:
          '${session.status == 'active' ? 'Actieve' : 'Beëindigde'} sessie van $date, ${item.confirmedSeriesCount} reeksen, score ${item.totalScore} van ${item.maximumPossibleScore}',
      child: InkWell(
        onTap: () => _openDetails(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 76),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _OptionalThumbnail(path: item.thumbnailPath),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              session.trainingGoal?.trim().isNotEmpty == true
                                  ? session.trainingGoal!
                                  : 'Schietsessie',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (session.status == 'active') ...[
                            const SizedBox(width: 8),
                            const _StatusLabel(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(date, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        '${item.confirmedSeriesCount} ${item.confirmedSeriesCount == 1 ? 'reeks' : 'reeksen'} · '
                        '${item.totalScore}/${item.maximumPossibleScore} · '
                        '${item.photoCount} ${item.photoCount == 1 ? 'foto' : 'foto’s'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _SessionMenu(
                  isActive: session.status == 'active',
                  onSelected: (action) => _handleAction(context, ref, action),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, {bool edit = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveSessionScreen(
          sessionId: item.session.id,
          openEditOnLoad: edit,
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _SessionAction action,
  ) async {
    switch (action) {
      case _SessionAction.view:
        _openDetails(context);
      case _SessionAction.edit:
        _openDetails(context, edit: true);
      case _SessionAction.continueSession:
        await _continue(context, ref);
      case _SessionAction.endSession:
        await _end(context, ref);
      case _SessionAction.delete:
        await _delete(context, ref);
    }
  }

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    if (item.session.status == 'active') {
      final draftId =
          item.draftSeriesId ??
          await ref
              .read(repositoryProvider)
              .createOrResumeDraftSeries(item.session.id);
      if (!context.mounted) return;
      await _openEditor(context, draftId);
      return;
    }

    try {
      final repository = ref.read(repositoryProvider);
      await repository.reopenSession(item.session.id);
      if (!context.mounted) return;
      final draftId = await repository.createOrResumeDraftSeries(
        item.session.id,
      );
      if (!context.mounted) return;
      await _openEditor(context, draftId);
    } on ActiveSessionExistsException {
      if (!context.mounted) return;
      AppMessenger.show(
        context,
        kind: AppNoticeKind.warning,
        message: 'Beëindig eerst de andere actieve sessie.',
      );
    }
  }

  Future<void> _openEditor(BuildContext context, String draftId) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ManualSeriesScreen(sessionId: item.session.id, seriesId: draftId),
        ),
      );

  Future<void> _end(BuildContext context, WidgetRef ref) async {
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
      openDraft: (draftId) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ManualSeriesScreen(sessionId: item.session.id, seriesId: draftId),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final date = DateFormat(
      'd MMMM yyyy',
      'nl_BE',
    ).format(item.session.startedAtUtc.toLocal());
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sessie verwijderen?'),
        content: Text(
          'De sessie van $date bevat ${item.confirmedSeriesCount} '
          '${item.confirmedSeriesCount == 1 ? 'reeks' : 'reeksen'} en '
          '${item.photoCount} ${item.photoCount == 1 ? 'foto' : 'foto’s'}. '
          'Alle gekoppelde gegevens worden permanent verwijderd.',
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
    if (accepted != true) return;
    await ref.read(repositoryProvider).deleteSession(item.session.id);
    if (!context.mounted) return;
    AppMessenger.show(
      context,
      kind: AppNoticeKind.success,
      message: 'Sessie verwijderd',
    );
  }
}

class _OptionalThumbnail extends StatelessWidget {
  const _OptionalThumbnail({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final compactWidth = MediaQuery.sizeOf(context).width < 360;
    if (largeText || compactWidth) return const SizedBox.shrink();
    final file = path == null ? null : File(path!);
    final canShow = file?.existsSync() ?? false;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.square(
          dimension: 52,
          child: !canShow
              ? ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.adjust),
                )
              : Image.file(file!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text('Actief', style: Theme.of(context).textTheme.labelSmall),
    ),
  );
}

class _SessionMenu extends StatelessWidget {
  const _SessionMenu({required this.isActive, required this.onSelected});

  final bool isActive;
  final ValueChanged<_SessionAction> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_SessionAction>(
    tooltip: 'Sessieacties',
    onSelected: onSelected,
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: _SessionAction.view,
        child: _MenuLabel(icon: Icons.visibility_outlined, text: 'Bekijken'),
      ),
      const PopupMenuItem(
        value: _SessionAction.edit,
        child: _MenuLabel(icon: Icons.edit_outlined, text: 'Bewerken'),
      ),
      PopupMenuItem(
        value: _SessionAction.continueSession,
        child: _MenuLabel(
          icon: isActive ? Icons.play_arrow : Icons.replay,
          text: 'Verdergaan',
        ),
      ),
      if (isActive)
        const PopupMenuItem(
          value: _SessionAction.endSession,
          child: _MenuLabel(
            icon: Icons.flag_outlined,
            text: 'Sessie beëindigen',
          ),
        ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: _SessionAction.delete,
        child: _MenuLabel(icon: Icons.delete_outline, text: 'Verwijderen'),
      ),
    ],
  );
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) =>
      Row(children: [Icon(icon), const SizedBox(width: 12), Text(text)]);
}

class _EmptyLogbook extends StatelessWidget {
  const _EmptyLogbook({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            filtered
                ? 'Geen sessies passen bij deze filters.'
                : 'Je opgeslagen sessies verschijnen hier.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

enum _SessionAction { view, edit, continueSession, endSession, delete }

enum _SessionStatusFilter {
  all('Alle'),
  active('Actief'),
  completed('Beëindigd');

  const _SessionStatusFilter(this.label);
  final String label;
}

enum _LogPeriod {
  all('Alle datums'),
  last30Days('30 dagen'),
  last90Days('90 dagen'),
  lastYear('12 maanden');

  const _LogPeriod(this.label);
  final String label;
}
