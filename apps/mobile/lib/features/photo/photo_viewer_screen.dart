import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../widgets/app_notice.dart';
import '../scoring/transformable_scoring_viewport.dart';
import 'photo_actions_sheet.dart';
import 'photo_canvas_models.dart';
import 'photo_overlay_canvas.dart';

class PhotoViewerOverlayData {
  const PhotoViewerOverlayData({
    required this.alignment,
    required this.impacts,
    required this.projectileDiameterMm,
  });

  final ManualPhotoAlignment alignment;
  final List<PhotoCanvasImpact> impacts;
  final double projectileDiameterMm;
}

/// A live photo viewer shared by session photos, series attachments and score
/// photos. It watches the database record by id so edited captions appear
/// without closing and reopening the route.
class PhotoViewerScreen extends ConsumerStatefulWidget {
  const PhotoViewerScreen({
    required this.imageId,
    this.sourceLabel,
    this.overlayData,
    this.initialOverlayVisibility = true,
    this.onMakePrimary,
    this.onAdjustAlignment,
    super.key,
  });

  final String imageId;
  final String? sourceLabel;
  final PhotoViewerOverlayData? overlayData;
  final bool initialOverlayVisibility;
  final FutureOr<void> Function()? onMakePrimary;
  final FutureOr<void> Function()? onAdjustAlignment;

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  final _overlayViewportController = ScoringViewportController();
  final _plainTransformationController = TransformationController();
  late bool _showOverlay;
  bool _showFullCaption = false;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _showOverlay = widget.initialOverlayVisibility;
  }

  @override
  void dispose() {
    _overlayViewportController.dispose();
    _plainTransformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = ref.watch(imageProvider(widget.imageId));
    return image.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Foto')),
        body: Center(child: Text('Foto laden mislukt: $error')),
      ),
      data: (record) => record == null
          ? Scaffold(
              appBar: AppBar(title: const Text('Foto')),
              body: const Center(child: Text('Deze foto bestaat niet meer.')),
            )
          : _buildViewer(context, record),
    );
  }

  Widget _buildViewer(BuildContext context, ImageAssetRecord image) {
    final overlay = widget.overlayData;
    final caption = image.caption?.trim();
    final isPrimary = image.role == domain.ImageRole.primaryScoringPhoto.name;
    return Scaffold(
      appBar: AppBar(
        title: Text(isPrimary ? 'Scorefoto' : 'Foto'),
        actions: [
          if (overlay != null)
            IconButton(
              tooltip: _showOverlay ? 'Overlay verbergen' : 'Overlay tonen',
              onPressed: () => setState(() => _showOverlay = !_showOverlay),
              icon: Icon(
                _showOverlay ? Icons.layers : Icons.layers_clear_outlined,
              ),
            ),
          IconButton(
            tooltip: 'Foto verwijderen',
            onPressed: _working
                ? null
                : () => unawaited(_handleAction(image, PhotoAction.delete)),
            icon: const Icon(Icons.delete_outline),
          ),
          PopupMenuButton<PhotoAction>(
            tooltip: 'Fotoacties',
            enabled: !_working,
            onSelected: (action) => unawaited(_handleAction(image, action)),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: PhotoAction.resetView,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.center_focus_strong),
                  title: Text('Passend weergeven'),
                ),
              ),
              PopupMenuItem(
                value: PhotoAction.editCaption,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_note_outlined),
                  title: Text(
                    caption == null || caption.isEmpty
                        ? 'Beschrijving toevoegen'
                        : 'Beschrijving wijzigen',
                  ),
                ),
              ),
              if (widget.onMakePrimary != null && !isPrimary)
                const PopupMenuItem(
                  value: PhotoAction.makePrimary,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.center_focus_strong),
                    title: Text('Als scorefoto gebruiken'),
                  ),
                ),
              if (widget.onAdjustAlignment != null && isPrimary)
                const PopupMenuItem(
                  value: PhotoAction.adjustAlignment,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.crop_free),
                    title: Text('Uitlijning aanpassen'),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: overlay == null
                    ? InteractiveViewer(
                        transformationController:
                            _plainTransformationController,
                        minScale: 1,
                        maxScale: 8,
                        child: Center(
                          child: Image.file(
                            File(image.path),
                            errorBuilder: (_, _, _) => const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.broken_image_outlined, size: 48),
                                  SizedBox(height: 8),
                                  Text('Het originele fotobestand ontbreekt.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : PhotoOverlayCanvas(
                        imageProvider: FileImage(File(image.path)),
                        imagePixelSize: Size(
                          image.width.toDouble(),
                          image.height.toDouble(),
                        ),
                        alignment: overlay.alignment,
                        impacts: overlay.impacts,
                        projectileDiameterMm: overlay.projectileDiameterMm,
                        showOverlay: _showOverlay,
                        accessMode: CanvasAccessMode.readOnly,
                        viewportController: _overlayViewportController,
                      ),
              ),
            ),
            if (caption != null && caption.isNotEmpty)
              _CaptionPanel(
                caption: caption,
                sourceLabel: widget.sourceLabel,
                createdAtUtc: image.createdAtUtc,
                expanded: _showFullCaption,
                onToggleExpanded: () =>
                    setState(() => _showFullCaption = !_showFullCaption),
              ),
          ],
        ),
      ),
    );
  }

  void _resetView() {
    if (widget.overlayData != null) {
      _overlayViewportController.fitToView();
    } else {
      _plainTransformationController.value = Matrix4.identity();
    }
  }

  Future<void> _handleAction(ImageAssetRecord image, PhotoAction action) async {
    if (_working) return;
    switch (action) {
      case PhotoAction.view:
        return;
      case PhotoAction.resetView:
        _resetView();
        return;
      case PhotoAction.editCaption:
        await editPhotoCaption(context: context, ref: ref, image: image);
        return;
      case PhotoAction.makePrimary:
        if (widget.onMakePrimary != null) await widget.onMakePrimary!();
        if (mounted) Navigator.of(context).pop();
        return;
      case PhotoAction.adjustAlignment:
        if (widget.onAdjustAlignment != null) {
          await widget.onAdjustAlignment!();
        }
        if (mounted) Navigator.of(context).pop();
        return;
      case PhotoAction.delete:
        setState(() => _working = true);
        final deleted = await deletePhotoWithConfirmation(
          context: context,
          ref: ref,
          image: image,
          sourceLabel: widget.sourceLabel,
        );
        if (!mounted) return;
        if (deleted) {
          Navigator.of(context).pop(true);
        } else {
          setState(() => _working = false);
        }
        return;
    }
  }
}

class _CaptionPanel extends StatelessWidget {
  const _CaptionPanel({
    required this.caption,
    required this.sourceLabel,
    required this.createdAtUtc,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final String caption;
  final String? sourceLabel;
  final DateTime createdAtUtc;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: caption, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 3,
          )..layout(maxWidth: constraints.maxWidth);
          final canExpand = painter.didExceedMaxLines;
          painter.dispose();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                key: const ValueKey('photo-caption'),
                maxLines: expanded ? null : 3,
                overflow: expanded ? null : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (sourceLabel != null && sourceLabel!.trim().isNotEmpty)
                    sourceLabel!.trim(),
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                    'nl_BE',
                  ).format(createdAtUtc.toLocal()),
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (canExpand)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onToggleExpanded,
                    child: Text(expanded ? 'Minder' : 'Meer'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> editPhotoCaption({
  required BuildContext context,
  required WidgetRef ref,
  required ImageAssetRecord image,
}) async {
  final controller = TextEditingController(text: image.caption);
  var submitted = false;
  final value = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        image.caption?.trim().isNotEmpty == true
            ? 'Beschrijving wijzigen'
            : 'Beschrijving toevoegen',
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 120,
        minLines: 2,
        maxLines: 4,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          hintText: 'Bijvoorbeeld opstelling of aandachtspunt',
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Annuleren'),
        ),
        FilledButton(
          onPressed: () {
            if (submitted) return;
            submitted = true;
            Navigator.pop(dialogContext, controller.text.trim());
          },
          child: const Text('Bewaren'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (value == null || !context.mounted) return;
  try {
    await ref.read(repositoryProvider).updateImageCaption(image.id, value);
  } catch (error) {
    if (context.mounted) {
      AppMessenger.error(context, 'Beschrijving bewaren mislukt: $error');
    }
  }
}

Future<bool> deletePhotoWithConfirmation({
  required BuildContext context,
  required WidgetRef ref,
  required ImageAssetRecord image,
  String? sourceLabel,
}) async {
  final isPrimary = image.role == domain.ImageRole.primaryScoringPhoto.name;
  final caption = image.caption?.trim();
  var submitted = false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Foto verwijderen?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(image.path),
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.square(
                  dimension: 88,
                  child: ColoredBox(
                    color: Colors.black12,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            if (sourceLabel != null && sourceLabel.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(sourceLabel, style: Theme.of(context).textTheme.labelLarge),
            ],
            if (caption != null && caption.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(caption),
            ],
            const SizedBox(height: 12),
            Text(
              isPrimary
                  ? 'De foto en uitlijning worden verwijderd. De geplaatste '
                        'treffers en score blijven bewaard en verschijnen op '
                        'de getekende kaart.'
                  : 'De foto en beschrijving worden verwijderd.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Annuleren'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () {
            if (submitted) return;
            submitted = true;
            Navigator.pop(dialogContext, true);
          },
          child: const Text('Verwijderen'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  try {
    await ref.read(repositoryProvider).deleteImage(image.id);
    return true;
  } catch (error) {
    if (context.mounted) {
      AppMessenger.error(context, 'Foto verwijderen mislukt: $error');
    }
    return false;
  }
}
