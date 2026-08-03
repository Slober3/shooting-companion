import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shooting_companion_photo_geometry/photo_geometry.dart';

import 'photo_canvas_models.dart';

/// Shows an immutable photo with manually positioned impacts as a live overlay.
///
/// In [PhotoCanvasInteractionMode.editImpacts], taps and marker drags are
/// reported through callbacks. In [PhotoCanvasInteractionMode.panAndZoom], the
/// photo is read-only and can be explored with pinch-to-zoom and pan gestures.
class PhotoOverlayCanvas extends StatefulWidget {
  PhotoOverlayCanvas({
    required this.imageProvider,
    required this.imagePixelSize,
    required this.alignment,
    required this.impacts,
    this.interactionMode = PhotoCanvasInteractionMode.editImpacts,
    this.showOverlay = true,
    this.selectedImpactId,
    this.onCanvasTap,
    this.onImpactMoved,
    this.onImpactSelected,
    this.transformationController,
    this.minimumZoom = 1,
    this.maximumZoom = 6,
    super.key,
  }) : assert(imagePixelSize.width > 0),
       assert(imagePixelSize.height > 0),
       assert(minimumZoom > 0),
       assert(maximumZoom >= minimumZoom);

  final ImageProvider<Object> imageProvider;
  final Size imagePixelSize;
  final ManualPhotoAlignment alignment;
  final List<PhotoCanvasImpact> impacts;
  final PhotoCanvasInteractionMode interactionMode;
  final bool showOverlay;
  final String? selectedImpactId;
  final ValueChanged<PhotoCanvasPosition>? onCanvasTap;
  final PhotoImpactMoved? onImpactMoved;
  final ValueChanged<String>? onImpactSelected;
  final TransformationController? transformationController;
  final double minimumZoom;
  final double maximumZoom;

  @override
  State<PhotoOverlayCanvas> createState() => _PhotoOverlayCanvasState();
}

class _PhotoOverlayCanvasState extends State<PhotoOverlayCanvas> {
  String? _draggedImpactId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = _containedSize(widget.imagePixelSize, constraints);
        final surface = _PhotoSurface(
          size: viewportSize,
          imageProvider: widget.imageProvider,
          alignment: widget.alignment,
          impacts: widget.impacts,
          showOverlay: widget.showOverlay,
          selectedImpactId: widget.selectedImpactId,
          editable:
              widget.interactionMode == PhotoCanvasInteractionMode.editImpacts,
          onTap: _handleTap,
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: () => _draggedImpactId = null,
        );

        final content =
            widget.interactionMode == PhotoCanvasInteractionMode.panAndZoom
            ? InteractiveViewer(
                transformationController: widget.transformationController,
                minScale: widget.minimumZoom,
                maxScale: widget.maximumZoom,
                boundaryMargin: const EdgeInsets.all(24),
                child: surface,
              )
            : surface;

        return Center(
          child: Semantics(
            label:
                'Doelkaartfoto met ${widget.impacts.length} handmatig geplaatste treffers',
            image: true,
            child: SizedBox.fromSize(size: viewportSize, child: content),
          ),
        );
      },
    );
  }

  void _handleTap(Offset localPosition, Size size) {
    final nearby = _nearestImpact(localPosition, size);
    if (nearby != null) {
      widget.onImpactSelected?.call(nearby.id);
      return;
    }
    final position = _positionFromLocal(localPosition, size);
    if (position != null) widget.onCanvasTap?.call(position);
  }

  void _handlePanStart(Offset localPosition, Size size) {
    _draggedImpactId = _nearestImpact(localPosition, size)?.id;
    final id = _draggedImpactId;
    if (id != null) widget.onImpactSelected?.call(id);
  }

  void _handlePanUpdate(Offset localPosition, Size size) {
    final id = _draggedImpactId;
    if (id == null) return;
    final position = _positionFromLocal(localPosition, size);
    if (position != null) widget.onImpactMoved?.call(id, position);
  }

  PhotoCanvasPosition? _positionFromLocal(Offset local, Size size) {
    final normalized = NormalizedPoint(
      local.dx / size.width,
      local.dy / size.height,
    );
    if (!normalized.isInsideImage) return null;
    final physical = widget.alignment.normalizedToPhysical(normalized);
    if (physical.x < -widget.alignment.cardWidthMm / 2 ||
        physical.x > widget.alignment.cardWidthMm / 2 ||
        physical.y < -widget.alignment.cardHeightMm / 2 ||
        physical.y > widget.alignment.cardHeightMm / 2) {
      return null;
    }
    return PhotoCanvasPosition(normalized: normalized, physicalMm: physical);
  }

  PhotoCanvasImpact? _nearestImpact(Offset local, Size size) {
    PhotoCanvasImpact? nearest;
    var nearestDistance = 30.0;
    for (final impact in widget.impacts) {
      final normalized = widget.alignment.physicalToNormalized(
        impact.positionMm,
      );
      final rendered = Offset(
        normalized.x * size.width,
        normalized.y * size.height,
      );
      final distance = (rendered - local).distance;
      if (distance < nearestDistance) {
        nearest = impact;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  Size _containedSize(Size image, BoxConstraints constraints) {
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : image.width;
    final height = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : width * image.height / image.width;
    final scale = math.min(width / image.width, height / image.height);
    return Size(image.width * scale, image.height * scale);
  }
}

class _PhotoSurface extends StatelessWidget {
  const _PhotoSurface({
    required this.size,
    required this.imageProvider,
    required this.alignment,
    required this.impacts,
    required this.showOverlay,
    required this.selectedImpactId,
    required this.editable,
    required this.onTap,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final Size size;
  final ImageProvider<Object> imageProvider;
  final ManualPhotoAlignment alignment;
  final List<PhotoCanvasImpact> impacts;
  final bool showOverlay;
  final String? selectedImpactId;
  final bool editable;
  final void Function(Offset position, Size size) onTap;
  final void Function(Offset position, Size size) onPanStart;
  final void Function(Offset position, Size size) onPanUpdate;
  final VoidCallback onPanEnd;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.fromSize(
        size: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: imageProvider,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
            if (editable)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => onTap(details.localPosition, size),
                onPanStart: (details) =>
                    onPanStart(details.localPosition, size),
                onPanUpdate: (details) =>
                    onPanUpdate(details.localPosition, size),
                onPanEnd: (_) => onPanEnd(),
              ),
            if (showOverlay)
              IgnorePointer(
                child: CustomPaint(
                  painter: _PhotoImpactPainter(
                    alignment: alignment,
                    impacts: impacts,
                    selectedImpactId: selectedImpactId,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoImpactPainter extends CustomPainter {
  _PhotoImpactPainter({
    required this.alignment,
    required this.impacts,
    required this.selectedImpactId,
    required this.colorScheme,
  });

  final ManualPhotoAlignment alignment;
  final List<PhotoCanvasImpact> impacts;
  final String? selectedImpactId;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final cardPath = Path();
    for (var index = 0; index < alignment.corners.points.length; index++) {
      final point = alignment.corners.points[index];
      final rendered = Offset(point.x * size.width, point.y * size.height);
      if (index == 0) {
        cardPath.moveTo(rendered.dx, rendered.dy);
      } else {
        cardPath.lineTo(rendered.dx, rendered.dy);
      }
    }
    cardPath.close();
    canvas.drawPath(
      cardPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colorScheme.primary,
    );

    for (final impact in impacts) {
      final normalized = alignment.physicalToNormalized(impact.positionMm);
      final centre = Offset(
        normalized.x * size.width,
        normalized.y * size.height,
      );
      if (centre.dx < 0 ||
          centre.dy < 0 ||
          centre.dx > size.width ||
          centre.dy > size.height) {
        continue;
      }
      final selected = impact.id == selectedImpactId;
      final fillColor = impact.isPositionUncertain
          ? colorScheme.error
          : colorScheme.tertiary;
      canvas.drawCircle(
        centre,
        selected ? 16 : 13,
        Paint()..color = fillColor.withValues(alpha: 0.92),
      );
      canvas.drawCircle(
        centre,
        selected ? 17 : 14,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 3 : 2
          ..color = selected ? colorScheme.primary : colorScheme.surface,
      );

      final multiplicity = impact.multiplicity > 1
          ? ' ×${impact.multiplicity}'
          : '';
      final markerText = TextPainter(
        text: TextSpan(
          text: '${impact.sequenceNumber}$multiplicity',
          style: TextStyle(
            color: colorScheme.onTertiary,
            fontSize: impact.multiplicity > 1 ? 9 : 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 48);
      markerText.paint(
        canvas,
        centre - Offset(markerText.width / 2, markerText.height / 2),
      );

      final scoreLabel = impact.scoreLabel;
      if (scoreLabel != null && scoreLabel.isNotEmpty) {
        final scoreText = TextPainter(
          text: TextSpan(
            text: scoreLabel,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              backgroundColor: colorScheme.primaryContainer,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        scoreText.paint(canvas, centre + const Offset(16, -18));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PhotoImpactPainter oldDelegate) =>
      oldDelegate.alignment != alignment ||
      oldDelegate.impacts != impacts ||
      oldDelegate.selectedImpactId != selectedImpactId ||
      oldDelegate.colorScheme != colorScheme;
}
