import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/safe_bottom_action_bar.dart';
import 'manual_series_screen.dart';
import 'series_detail_screen.dart';
import 'session_edit_sheet.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({
    required this.sessionId,
    this.openEditOnLoad = false,
    super.key,
  });

  final String sessionId;
  final bool openEditOnLoad;

  @override
  ConsumerState<ActiveSessionScreen> createState() =>
      _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  final _picker = ImagePicker();
  final _storage = ImageStorageService();
  bool _openedInitialEdit = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(sessionDetailProvider(widget.sessionId));
    final value = detail.valueOrNull;
    if (widget.openEditOnLoad && value != null && !_openedInitialEdit) {
      _openedInitialEdit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_editSession(value));
      });
    }

    final isActive = value?.session.status == domain.SessionStatus.active.name;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessie'),
        actions: [
          if (value != null)
            IconButton(
              onPressed: () => _addSessionPhoto(value),
              tooltip: 'Sessiefoto toevoegen',
              icon: const Icon(Icons.add_a_photo_outlined),
            ),
          if (value != null)
            PopupMenuButton<String>(
              tooltip: 'Sessieacties',
              onSelected: (action) => _handleAction(action, value),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Sessie bewerken'),
                  ),
                ),
                if (isActive)
                  const PopupMenuItem(
                    value: 'complete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.flag_outlined),
                      title: Text('Sessie beëindigen'),
                    ),
                  )
                else
                  const PopupMenuItem(
                    value: 'reopen',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.play_arrow_outlined),
                      title: Text('Sessie hervatten'),
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline),
                    title: Text('Sessie verwijderen'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: detail.when(
        data: (item) => item == null
            ? const Center(child: Text('Deze sessie bestaat niet meer.'))
            : _SessionBody(detail: item),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Laden mislukt: $error')),
      ),
      bottomNavigationBar: isActive && value != null
          ? SafeBottomActionBar(
              actions: [
                FilledButton.icon(
                  onPressed: () => _openDraft(value),
                  icon: Icon(
                    value.draftSeries == null ? Icons.add : Icons.play_arrow,
                  ),
                  label: Text(
                    value.draftSeries == null
                        ? 'Nieuwe reeks'
                        : 'Verdergaan met reeks',
                  ),
                ),
              ],
            )
          : null,
    );
  }

  void _handleAction(String action, SessionDetail detail) {
    switch (action) {
      case 'edit':
        unawaited(_editSession(detail));
      case 'complete':
        unawaited(_complete(detail));
      case 'reopen':
        unawaited(_reopen());
      case 'delete':
        unawaited(_delete(detail));
    }
  }

  Future<void> _editSession(SessionDetail detail) async {
    final ranges =
        ref.read(rangesProvider).valueOrNull ?? const <RangeRecord>[];
    final values = await showSessionEditSheet(
      context: context,
      session: detail.session,
      ranges: ranges,
    );
    if (values == null) return;
    await ref
        .read(repositoryProvider)
        .updateSessionDetails(
          sessionId: widget.sessionId,
          startedAtUtc: values.startedAtLocal.toUtc(),
          localUtcOffsetMinutes: values.startedAtLocal.timeZoneOffset.inMinutes,
          rangeId: values.rangeId,
          trainingGoal: values.trainingGoal,
          conditions: values.conditions,
          notes: values.notes,
        );
  }

  Future<void> _openDraft(SessionDetail detail) async {
    final id =
        detail.draftSeries?.id ??
        await ref
            .read(repositoryProvider)
            .createOrResumeDraftSeries(widget.sessionId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ManualSeriesScreen(sessionId: widget.sessionId, seriesId: id),
      ),
    );
  }

  Future<void> _complete(SessionDetail detail) async {
    final draft = detail.draftSeries;
    if (draft != null && draft.shotCount > 0) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Conceptreeks is nog niet bewaard'),
          content: Text(
            'Reeks ${draft.sequenceNumber} bevat ${draft.shotCount} schoten.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text('Concept verwijderen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'open'),
              child: const Text('Reeks openen'),
            ),
          ],
        ),
      );
      if (choice == 'open') {
        await _openDraft(detail);
        return;
      }
      if (choice != 'discard') return;
      await ref.read(repositoryProvider).deleteSeries(draft.id);
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sessie beëindigen?'),
          content: const Text(
            'Alle bevestigde reeksen blijven lokaal bewaard.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuleren'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Beëindigen'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref.read(repositoryProvider).completeSession(widget.sessionId);
    if (!mounted) return;
    final stillExists = await ref
        .read(repositoryProvider)
        .getSessionDetail(widget.sessionId);
    if (!mounted) return;
    if (stillExists == null) Navigator.pop(context, true);
  }

  Future<void> _reopen() async {
    try {
      await ref.read(repositoryProvider).reopenSession(widget.sessionId);
    } on ActiveSessionExistsException catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Er is al een actieve sessie'),
          content: const Text(
            'Beëindig eerst de huidige actieve sessie voordat je deze hervat.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Begrepen'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _delete(SessionDetail detail) async {
    final date = DateFormat(
      'dd/MM/yyyy HH:mm',
      'nl_BE',
    ).format(detail.session.startedAtUtc.toLocal());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sessie verwijderen?'),
        content: Text(
          '$date\n${detail.seriesCount} reeksen · ${detail.photoCount} foto’s\n\n'
          'Alle gekoppelde punten, uitlijningen en bestanden verdwijnen.',
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
    await ref.read(repositoryProvider).deleteSession(widget.sessionId);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _addSessionPhoto(SessionDetail detail) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Galerij'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
    if (source == null || !mounted) return;
    if (source == ImageSource.camera &&
        detail.session.photoSafetyAcknowledgedAtUtc == null) {
      final safe = await _confirmPhotoSafety();
      if (!safe) return;
    }
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;
    final caption = await _askCaption();
    StagedImage? staged;
    StoredImage? stored;
    var attached = false;
    try {
      staged = await _storage.stageJpeg(picked.path);
      stored = await _storage.finalizeStagedImage(staged);
      await ref
          .read(repositoryProvider)
          .attachImage(
            NewImageAsset(
              sessionId: widget.sessionId,
              role: domain.ImageRole.attachment,
              path: stored.path,
              sha256: stored.sha256,
              width: stored.width,
              height: stored.height,
              sizeBytes: stored.sizeBytes,
              caption: caption,
            ),
          );
      attached = true;
    } catch (error) {
      if (staged != null && stored == null) {
        await _storage.discardStagedImage(staged);
      }
      if (stored != null && !attached) {
        await _storage.deleteStoredImage(stored.path);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto toevoegen mislukt: $error')),
        );
      }
    }
  }

  Future<bool> _confirmPhotoSafety() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veilig fotograferen'),
        content: const Text(
          'Bevestig dat de baan veilig is en fotograferen is toegestaan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ik bevestig dit'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    await ref.read(repositoryProvider).acknowledgePhotoSafety(widget.sessionId);
    return true;
  }

  Future<String?> _askCaption() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beschrijving (optioneel)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(
            hintText: 'Bijvoorbeeld opstelling',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Overslaan'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Bewaren'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result == null || result.isEmpty ? null : result;
  }
}

class _SessionBody extends ConsumerWidget {
  const _SessionBody({required this.detail});

  final SessionDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = detail.session;
    final formatter = DateFormat('EEEE d MMMM yyyy · HH:mm', 'nl_BE');
    final ranges =
        ref.watch(rangesProvider).valueOrNull ?? const <RangeRecord>[];
    final range = ranges
        .where((item) => item.id == session.rangeId)
        .firstOrNull;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        128 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatter.format(session.startedAtUtc.toLocal()),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    session.status == domain.SessionStatus.active.name
                        ? 'Actief${range == null ? '' : ' · ${range.name}'}'
                        : 'Beëindigd${range == null ? '' : ' · ${range.name}'}',
                  ),
                ],
              ),
            ),
            Chip(
              avatar: Icon(
                session.status == domain.SessionStatus.active.name
                    ? Icons.play_arrow
                    : Icons.check,
                size: 18,
              ),
              label: Text(
                session.status == domain.SessionStatus.active.name
                    ? 'Actief'
                    : 'Beëindigd',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ResponsiveMetricGrid(
          items: [
            MetricItem(label: 'Reeksen', value: '${detail.seriesCount}'),
            MetricItem(label: 'Schoten', value: '${detail.shotCount}'),
            MetricItem(
              label: 'Score',
              value: '${detail.totalScore}/${detail.maximumPossibleScore}',
            ),
            MetricItem(label: 'X', value: '${detail.innerTenCount}'),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Notities',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                final state = context
                    .findAncestorStateOfType<_ActiveSessionScreenState>();
                if (state != null) unawaited(state._editSession(detail));
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Bewerken'),
            ),
          ],
        ),
        Text(
          session.notes ??
              session.trainingGoal ??
              'Nog geen notitie. Voeg details toe wanneer het uitkomt.',
        ),
        if (session.conditions != null) ...[
          const SizedBox(height: 4),
          Text('Omstandigheden: ${session.conditions}'),
        ],
        if (detail.images.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Foto’s', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final image = detail.images[index];
                return InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _PhotoViewerPage(image: image),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(image.path),
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.square(
                        dimension: 92,
                        child: ColoredBox(
                          color: Colors.black12,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Reeksen', style: Theme.of(context).textTheme.titleMedium),
        if (detail.draftSeries case final draft?)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.edit_outlined)),
            title: Text('Reeks ${draft.sequenceNumber} · concept'),
            subtitle: Text('${draft.shotCount} schoten · nog niet bevestigd'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ManualSeriesScreen(
                  sessionId: session.id,
                  seriesId: draft.id,
                ),
              ),
            ),
          ),
        if (detail.confirmedSeries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Nog geen bevestigde reeks.'),
          )
        else
          ...detail.confirmedSeries.map(
            (series) => _SeriesTile(series: series),
          ),
      ],
    );
  }
}

class _SeriesTile extends ConsumerWidget {
  const _SeriesTile({required this.series});

  final SeriesRecord series;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(child: Text('${series.sequenceNumber}')),
    title: Text(
      '${series.totalScore}/${series.maximumPossibleScore} · '
      '${series.innerTenCount} X',
    ),
    subtitle: Text(
      '${series.distanceMeters.toStringAsFixed(0)} m · '
      '${series.shotCount} schoten',
    ),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeriesDetailScreen(seriesId: series.id),
      ),
    ),
    trailing: PopupMenuButton<String>(
      tooltip: 'Reeksacties',
      onSelected: (action) async {
        if (action == 'view') {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SeriesDetailScreen(seriesId: series.id),
            ),
          );
        } else if (action == 'edit') {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ManualSeriesScreen(
                sessionId: series.sessionId,
                seriesId: series.id,
              ),
            ),
          );
        } else if (action == 'delete') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reeks verwijderen?'),
              content: Text(
                'Reeks ${series.sequenceNumber} en gekoppelde foto’s verdwijnen.',
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
          if (confirmed == true) {
            await ref.read(repositoryProvider).deleteSeries(series.id);
          }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'view', child: Text('Bekijken')),
        PopupMenuItem(value: 'edit', child: Text('Bewerken')),
        PopupMenuItem(value: 'delete', child: Text('Verwijderen')),
      ],
    ),
  );
}

class _PhotoViewerPage extends ConsumerWidget {
  const _PhotoViewerPage({required this.image});

  final ImageAssetRecord image;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(image.caption ?? 'Foto'),
      actions: [
        PopupMenuButton<String>(
          onSelected: (action) async {
            if (action == 'caption') {
              final controller = TextEditingController(text: image.caption);
              final value = await showDialog<String?>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Beschrijving'),
                  content: TextField(controller: controller, maxLength: 120),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuleren'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, controller.text.trim()),
                      child: const Text('Bewaren'),
                    ),
                  ],
                ),
              );
              controller.dispose();
              if (value != null) {
                await ref
                    .read(repositoryProvider)
                    .updateImageCaption(image.id, value);
              }
            } else if (action == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Foto verwijderen?'),
                  content: const Text(
                    'Trefferposities blijven bestaan; alleen de foto verdwijnt.',
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
              if (confirmed == true) {
                await ref.read(repositoryProvider).deleteImage(image.id);
                if (context.mounted) Navigator.pop(context, true);
              }
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'caption',
              child: Text('Beschrijving wijzigen'),
            ),
            PopupMenuItem(value: 'delete', child: Text('Foto verwijderen')),
          ],
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 6,
        child: Center(child: Image.file(File(image.path))),
      ),
    ),
  );
}
