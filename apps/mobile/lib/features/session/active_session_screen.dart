import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/app_action_dock.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/safe_sheet_scaffold.dart';
import '../photo/photo.dart';
import '../progress/series_analysis_screen.dart';
import '../progress/session_analysis_screen.dart';
import 'manual_series_screen.dart';
import 'series_detail_screen.dart';
import 'session_completion_flow.dart';
import 'session_edit_sheet.dart';

enum ActiveSessionResult { completed, deleted }

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
  bool _isCompleting = false;

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
          ? AppActionDock(
              actions: [
                Semantics(
                  button: true,
                  label: 'Actieve sessie beëindigen',
                  child: ExcludeSemantics(
                    child: OutlinedButton.icon(
                      onPressed: _isCompleting ? null : () => _complete(value),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Beëindigen', maxLines: 1),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: value.draftSeries == null
                      ? 'Nieuwe reeks starten'
                      : 'Verdergaan met huidige reeks',
                  child: ExcludeSemantics(
                    child: FilledButton.icon(
                      onPressed: _isCompleting ? null : () => _openDraft(value),
                      icon: Icon(
                        value.draftSeries == null
                            ? Icons.add
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        value.draftSeries == null ? 'Nieuwe reeks' : 'Doorgaan',
                        maxLines: 1,
                      ),
                    ),
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
        ref.read(allRangesProvider).valueOrNull ?? const <RangeRecord>[];
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
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    final draft = detail.draftSeries;
    final draftPhotoCount = draft == null
        ? 0
        : detail.images.where((image) => image.seriesId == draft.id).length;
    final outcome = await SessionCompletionCoordinator.run(
      context: context,
      repository: ref.read(repositoryProvider),
      sessionId: widget.sessionId,
      promptData: SessionEndPromptData(
        confirmedSeriesCount: detail.seriesCount,
        draftSeriesId: draft?.id,
        draftShotCount: draft?.shotCount ?? 0,
        draftPhotoCount: draftPhotoCount,
        draftHasNotes: draft?.notes?.trim().isNotEmpty ?? false,
        draftWasEdited:
            draft != null && draft.updatedAtUtc.isAfter(draft.createdAtUtc),
        sessionPhotoCount: detail.images
            .where((image) => image.seriesId == null)
            .length,
        hasSessionDetails: detail.session.hasUserDetails,
      ),
      openDraft: (_) => _openDraft(detail),
    );
    if (!mounted) return;
    switch (outcome) {
      case SessionCompletionUiOutcome.completed:
      case SessionCompletionUiOutcome.alreadyCompleted:
        Navigator.pop(context, ActiveSessionResult.completed);
      case SessionCompletionUiOutcome.deleted:
      case SessionCompletionUiOutcome.notFound:
        Navigator.pop(context, ActiveSessionResult.deleted);
      case SessionCompletionUiOutcome.canceled:
      case SessionCompletionUiOutcome.openedDraft:
      case SessionCompletionUiOutcome.failed:
      case SessionCompletionUiOutcome.busy:
        setState(() => _isCompleting = false);
    }
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
    final trainingCount = await ref
        .read(repositoryProvider)
        .countSessionTrainingActivities(widget.sessionId);
    if (!mounted) return;
    final date = DateFormat(
      'dd/MM/yyyy HH:mm',
      'nl_BE',
    ).format(detail.session.startedAtUtc.toLocal());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sessie verwijderen?'),
        content: Text(
          '$date\n${detail.seriesCount} reeksen · ${detail.photoCount} foto’s'
          '${trainingCount == 0 ? '' : ' · $trainingCount trainingsactiviteiten'}\n\n'
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
    if (mounted) Navigator.pop(context, ActiveSessionResult.deleted);
  }

  Future<void> _addSessionPhoto(SessionDetail detail) async {
    final source = await showSafeModalSheet<ImageSource>(
      context: context,
      presentation: SafeSheetPresentation.compact,
      builder: (sheetContext) => SafeSheetScaffold(
        title: 'Foto toevoegen',
        contentSized: true,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerij'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
        actions: const [],
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
    StagedImage? staged;
    StoredImage? stored;
    var attached = false;
    try {
      staged = await _storage.stageJpeg(picked.path);
      stored = await _storage.finalizeStagedImage(staged);
      final imageId = await ref
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
            ),
          );
      attached = true;
      if (mounted) {
        AppMessenger.show(
          context,
          kind: AppNoticeKind.success,
          message: 'Foto toegevoegd',
          action: AppNoticeAction(
            label: 'Beschrijving',
            onPressed: () => unawaited(_editAddedPhotoCaption(imageId)),
          ),
        );
      }
    } catch (error) {
      if (staged != null && stored == null) {
        await _storage.discardStagedImage(staged);
      }
      if (stored != null && !attached) {
        await _storage.deleteStoredImage(stored.path);
      }
      if (mounted) {
        AppMessenger.show(
          context,
          kind: AppNoticeKind.error,
          message: 'Foto toevoegen mislukt: $error',
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

  Future<void> _editAddedPhotoCaption(String imageId) async {
    final image = await ref.read(repositoryProvider).watchImage(imageId).first;
    if (!mounted || image == null) return;
    await editPhotoCaption(context: context, ref: ref, image: image);
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
        ref.watch(allRangesProvider).valueOrNull ?? const <RangeRecord>[];
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
                  if (range != null) Text(range.name),
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
        if (detail.confirmedSeriesItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      SessionAnalysisScreen(sessionId: detail.session.id),
                ),
              ),
              icon: const Icon(Icons.insights_outlined),
              label: const Text('Analyse sessie'),
            ),
          ),
        ],
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
            height: 98 + MediaQuery.textScalerOf(context).scale(38),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final image = detail.images[index];
                final sourceLabel = _photoSourceLabel(image);
                return PhotoThumbnailTile(
                  image: image,
                  badgeLabel: sourceLabel,
                  onTap: () => _openPhoto(context, image, sourceLabel),
                  onLongPress: () => unawaited(
                    _showPhotoActions(context, ref, image, sourceLabel),
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
        if (detail.confirmedSeriesItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Nog geen bevestigde reeks.'),
          )
        else
          ...detail.confirmedSeriesItems.map((item) => _SeriesTile(item: item)),
      ],
    );
  }

  String _photoSourceLabel(ImageAssetRecord image) {
    if (image.role == domain.ImageRole.primaryScoringPhoto.name) {
      return 'Scorefoto';
    }
    if (image.seriesId == null) return 'Sessiefoto';
    final item = [
      ...detail.confirmedSeriesItems,
      ?detail.draftSeriesItem,
    ].where((item) => item.series.id == image.seriesId).firstOrNull;
    return item == null ? 'Reeksfoto' : 'Reeks ${item.series.sequenceNumber}';
  }

  Future<void> _openPhoto(
    BuildContext context,
    ImageAssetRecord image,
    String sourceLabel,
  ) {
    final canMakePrimary =
        image.seriesId != null &&
        image.role != domain.ImageRole.primaryScoringPhoto.name;
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(
          imageId: image.id,
          sourceLabel: sourceLabel,
          onMakePrimary: canMakePrimary
              ? () => _openPhotoAlignment(context, image)
              : null,
        ),
      ),
    );
  }

  Future<void> _showPhotoActions(
    BuildContext context,
    WidgetRef ref,
    ImageAssetRecord image,
    String sourceLabel,
  ) async {
    final canMakePrimary =
        image.seriesId != null &&
        image.role != domain.ImageRole.primaryScoringPhoto.name;
    final action = await showPhotoActionsSheet(
      context: context,
      image: image,
      canMakePrimary: canMakePrimary,
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case PhotoAction.view:
        await _openPhoto(context, image, sourceLabel);
        return;
      case PhotoAction.resetView:
        return;
      case PhotoAction.editCaption:
        await editPhotoCaption(context: context, ref: ref, image: image);
        return;
      case PhotoAction.delete:
        await deletePhotoWithConfirmation(
          context: context,
          ref: ref,
          image: image,
          sourceLabel: sourceLabel,
        );
        return;
      case PhotoAction.makePrimary:
        await _openPhotoAlignment(context, image);
        return;
      case PhotoAction.adjustAlignment:
        return;
    }
  }

  Future<void> _openPhotoAlignment(
    BuildContext context,
    ImageAssetRecord image,
  ) {
    final seriesId = image.seriesId;
    if (seriesId == null) return Future<void>.value();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManualSeriesScreen(
          sessionId: detail.session.id,
          seriesId: seriesId,
          alignImageIdOnLoad: image.id,
        ),
      ),
    );
  }
}

class _SeriesTile extends ConsumerWidget {
  const _SeriesTile({required this.item});

  final SeriesOverviewItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = item.series;
    final material = [
      if (item.firearm != null) item.firearm!.name,
      if (item.ammoLot != null) item.ammoLot!.displayName,
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text('${series.sequenceNumber}')),
      title: Text(
        '${series.totalScore}/${series.maximumPossibleScore} · '
        '${series.innerTenCount} X',
      ),
      subtitle: Text(
        '${series.distanceMeters.toStringAsFixed(0)} m · '
        '${series.shotCount} schoten${material.isEmpty ? '' : '\n$material'}',
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
          } else if (action == 'analysis') {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SeriesAnalysisScreen(seriesId: series.id),
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
          PopupMenuItem(value: 'analysis', child: Text('Analyseer')),
          PopupMenuItem(value: 'edit', child: Text('Bewerken')),
          PopupMenuItem(value: 'delete', child: Text('Verwijderen')),
        ],
      ),
    );
  }
}
