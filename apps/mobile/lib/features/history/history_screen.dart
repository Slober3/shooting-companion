import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/compact_page_scaffold.dart';
import '../session/active_session_screen.dart';
import '../session/manual_series_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _SessionStatusFilter _status = _SessionStatusFilter.all;
  _LogPeriod _period = _LogPeriod.all;

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    return CompactPageScaffold(
      title: 'Logboek',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sessionsProvider);
          await ref.read(sessionsProvider.future);
        },
        child: sessions.when(
          data: (allSessions) {
            final visibleSessions = allSessions.where(_isVisible).toList();
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  sliver: SliverToBoxAdapter(
                    child: _FilterBar(
                      status: _status,
                      period: _period,
                      onStatusChanged: (value) =>
                          setState(() => _status = value),
                      onPeriodChanged: (value) =>
                          setState(() => _period = value),
                    ),
                  ),
                ),
                if (visibleSessions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyLogbook(filtered: allSessions.isNotEmpty),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      24 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    sliver: SliverList.separated(
                      itemCount: visibleSessions.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _SessionRow(session: visibleSessions[index]),
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

  bool _isVisible(SessionRecord session) {
    final isActive = session.status == 'active';
    if (_status == _SessionStatusFilter.active && !isActive) return false;
    if (_status == _SessionStatusFilter.completed && isActive) return false;

    final cutoff = switch (_period) {
      _LogPeriod.all => null,
      _LogPeriod.last30Days => DateTime.now().toUtc().subtract(
        const Duration(days: 30),
      ),
      _LogPeriod.last90Days => DateTime.now().toUtc().subtract(
        const Duration(days: 90),
      ),
      _LogPeriod.lastYear => DateTime.now().toUtc().subtract(
        const Duration(days: 365),
      ),
    };
    return cutoff == null || !session.startedAtUtc.isBefore(cutoff);
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.status,
    required this.period,
    required this.onStatusChanged,
    required this.onPeriodChanged,
  });

  final _SessionStatusFilter status;
  final _LogPeriod period;
  final ValueChanged<_SessionStatusFilter> onStatusChanged;
  final ValueChanged<_LogPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final option in _SessionStatusFilter.values) ...[
              FilterChip(
                label: Text(option.label),
                selected: status == option,
                onSelected: (_) => onStatusChanged(option),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
      const SizedBox(height: 4),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.date_range_outlined, size: 20),
            const SizedBox(width: 8),
            for (final option in _LogPeriod.values) ...[
              ChoiceChip(
                label: Text(option.label),
                selected: period == option,
                onSelected: (_) => onPeriodChanged(option),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    ],
  );
}

class _SessionRow extends ConsumerWidget {
  const _SessionRow({required this.session});

  final SessionRecord session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(seriesProvider(session.id));
    final images = ref.watch(sessionImagesProvider(session.id));
    final records = series.valueOrNull ?? const <SeriesRecord>[];
    final confirmed = records
        .where((item) => item.status == 'confirmed')
        .toList();
    final total = confirmed.fold(0, (sum, item) => sum + item.totalScore);
    final maximum = confirmed.fold(
      0,
      (sum, item) => sum + item.maximumPossibleScore,
    );
    final imageRecords = images.valueOrNull ?? const <ImageAssetRecord>[];
    final date = DateFormat(
      'd MMM yyyy · HH:mm',
      'nl_BE',
    ).format(session.startedAtUtc.toLocal());

    return Semantics(
      container: true,
      label:
          '${session.status == 'active' ? 'Actieve' : 'Beëindigde'} sessie van $date, ${confirmed.length} reeksen, score $total van $maximum',
      child: InkWell(
        onTap: () => _openDetails(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 76),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _OptionalThumbnail(images: imageRecords),
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
                        '${confirmed.length} ${confirmed.length == 1 ? 'reeks' : 'reeksen'} · $total/$maximum · ${imageRecords.length} ${imageRecords.length == 1 ? 'foto' : 'foto’s'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _SessionMenu(
                  isActive: session.status == 'active',
                  onSelected: (action) => _handleAction(
                    context,
                    ref,
                    action,
                    records,
                    imageRecords.length,
                  ),
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
        builder: (_) =>
            ActiveSessionScreen(sessionId: session.id, openEditOnLoad: edit),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _SessionAction action,
    List<SeriesRecord> series,
    int photoCount,
  ) async {
    switch (action) {
      case _SessionAction.view:
        _openDetails(context);
        return;
      case _SessionAction.edit:
        _openDetails(context, edit: true);
        return;
      case _SessionAction.continueSession:
        await _continue(context, ref, series);
        return;
      case _SessionAction.delete:
        await _delete(context, ref, series, photoCount);
        return;
    }
  }

  Future<void> _continue(
    BuildContext context,
    WidgetRef ref,
    List<SeriesRecord> series,
  ) async {
    if (session.status == 'active') {
      final drafts = series.where((item) => item.status == 'draft');
      if (drafts.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ManualSeriesScreen(
              sessionId: session.id,
              seriesId: drafts.first.id,
            ),
          ),
        );
      } else {
        _openDetails(context);
      }
      return;
    }

    try {
      await ref.read(repositoryProvider).reopenSession(session.id);
      if (!context.mounted) return;
      _openDetails(context);
    } on ActiveSessionExistsException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beëindig eerst de andere actieve sessie.'),
        ),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    List<SeriesRecord> series,
    int photoCount,
  ) async {
    final confirmed = series.where((item) => item.status == 'confirmed').length;
    final date = DateFormat(
      'd MMMM yyyy',
      'nl_BE',
    ).format(session.startedAtUtc.toLocal());
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sessie verwijderen?'),
        content: Text(
          'De sessie van $date bevat $confirmed ${confirmed == 1 ? 'reeks' : 'reeksen'} en $photoCount ${photoCount == 1 ? 'foto' : 'foto’s'}. Alle gekoppelde gegevens worden permanent verwijderd.',
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
    await ref.read(repositoryProvider).deleteSession(session.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sessie verwijderd')));
  }
}

class _OptionalThumbnail extends StatelessWidget {
  const _OptionalThumbnail({required this.images});

  final List<ImageAssetRecord> images;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final compactWidth = MediaQuery.sizeOf(context).width < 360;
    if (largeText || compactWidth) return const SizedBox.shrink();
    final existing = images.where((image) => File(image.path).existsSync());
    final image = existing.isEmpty ? null : existing.first;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox.square(
          dimension: 52,
          child: image == null
              ? ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.adjust),
                )
              : Image.file(File(image.path), fit: BoxFit.cover),
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

enum _SessionAction { view, edit, continueSession, delete }

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
