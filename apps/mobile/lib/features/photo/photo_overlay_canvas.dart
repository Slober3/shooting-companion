import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shooting_companion_photo_geometry/photo_geometry.dart';

import '../../app/theme.dart';
import '../scoring/transformable_scoring_viewport.dart';
import 'photo_canvas_models.dart';

class PhotoOverlayCanvas extends StatelessWidget {
  const PhotoOverlayCanvas({
    required this.imageProvider,
    required this.imagePixelSize,
    required this.alignment,
    required this.impacts,
    this.projectileDiameterMm = 0,
    this.accessMode = CanvasAccessMode.editable,
    this.tool = ScoringTool.place,
    this.showOverlay = true,
    this.precisionMode = false,
    this.selectedImpactId,
    this.onCanvasTap,
    this.onImpactMoved,
    this.onImpactSelected,
    this.onImpactLongPressed,
    this.onImpactMoveStart,
    this.onImpactMoveEnd,
    this.onImpactMoveCancel,
    this.onInvalidPosition,
    this.viewportController,
    this.showControls = true,
    this.semanticsLabel,
    super.key,
  });

  final ImageProvider<Object> imageProvider;
  final Size imagePixelSize;
  final ManualPhotoAlignment alignment;
  final List<PhotoCanvasImpact> impacts;
  final double projectileDiameterMm;
  final CanvasAccessMode accessMode;
  final ScoringTool tool;
  final bool showOverlay;
  final bool precisionMode;
  final String? selectedImpactId;
  final ValueChanged<PhotoCanvasPosition>? onCanvasTap;
  final PhotoImpactMoved? onImpactMoved;
  final ValueChanged<String?>? onImpactSelected;
  final ValueChanged<String>? onImpactLongPressed;
  final ValueChanged<String>? onImpactMoveStart;
  final ValueChanged<String>? onImpactMoveEnd;
  final ValueChanged<String>? onImpactMoveCancel;
  final VoidCallback? onInvalidPosition;
  final ScoringViewportController? viewportController;
  final bool showControls;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final ordered = [...impacts]
      ..sort((first, second) {
        if (first.id == selectedImpactId) return 1;
        if (second.id == selectedImpactId) return -1;
        return first.sequenceNumber.compareTo(second.sequenceNumber);
      });

    return Semantics(
      label:
          semanticsLabel ??
          'Doelkaartfoto met ${impacts.length} gemarkeerde treffers',
      image: true,
      child: TransformableScoringViewport(
        aspectRatio: imagePixelSize.width / imagePixelSize.height,
        controller: viewportController,
        accessMode: accessMode,
        tool: tool,
        precisionMode: precisionMode,
        showControls: showControls,
        onInvalidPosition: onInvalidPosition,
        onBackgroundTap: (normalized) {
          if (tool == ScoringTool.edit) {
            onImpactSelected?.call(null);
            return;
          }
          final position = _positionFromNormalized(normalized);
          if (position == null) {
            onInvalidPosition?.call();
            return;
          }
          onCanvasTap?.call(position);
        },
        onMarkerSelected: (id) => onImpactSelected?.call(id),
        onMarkerLongPressed: onImpactLongPressed,
        onMarkerDragStart: onImpactMoveStart,
        onMarkerDragEnd: onImpactMoveEnd,
        onMarkerDragCancel: onImpactMoveCancel,
        onMarkerMoved: (id, normalized) {
          final position = _positionFromNormalized(normalized);
          if (position == null) {
            onInvalidPosition?.call();
            return;
          }
          onImpactMoved?.call(id, position);
        },
        markers: showOverlay
            ? [
                for (final impact in ordered)
                  ScoringViewportMarker(
                    id: impact.id,
                    normalizedPosition: _normalizedForImpact(impact),
                    semanticsLabel:
                        'Treffer ${impact.sequenceNumber}, ${impact.scoreLabel ?? 'onbekende score'}, multipliciteit ${impact.multiplicity}',
                    selectionPriority: impact.sequenceNumber,
                    child: _PhotoMarker(
                      impact: impact,
                      selected: impact.id == selectedImpactId,
                    ),
                  ),
              ]
            : const [],
        contentBuilder: (context, size, zoom) => Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: imageProvider,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
            if (showOverlay)
              IgnorePointer(
                child: CustomPaint(
                  painter: _AlignmentOutlinePainter(
                    alignment: alignment,
                    impacts: impacts,
                    projectileDiameterMm: projectileDiameterMm,
                    color: Theme.of(context).colorScheme.primary,
                    impactColor: AppContrastTokens.of(context).positive,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Offset _normalizedForImpact(PhotoCanvasImpact impact) {
    final normalized = alignment.physicalToNormalized(impact.positionMm);
    return Offset(normalized.x, normalized.y);
  }

  PhotoCanvasPosition? _positionFromNormalized(Offset normalized) {
    final imagePoint = NormalizedPoint(normalized.dx, normalized.dy);
    if (!imagePoint.isInsideImage) return null;
    late final PhysicalPointMm physical;
    try {
      physical = alignment.normalizedToPhysical(imagePoint);
    } on StateError {
      return null;
    }
    if (!physical.x.isFinite || !physical.y.isFinite) return null;
    final halfWidth = alignment.cardWidthMm / 2;
    final halfHeight = alignment.cardHeightMm / 2;
    const edgeToleranceMm = 1e-6;
    if (physical.x < -halfWidth - edgeToleranceMm ||
        physical.x > halfWidth + edgeToleranceMm ||
        physical.y < -halfHeight - edgeToleranceMm ||
        physical.y > halfHeight + edgeToleranceMm) {
      return null;
    }
    return PhotoCanvasPosition(
      normalized: imagePoint,
      physicalMm: PhysicalPointMm(
        physical.x.clamp(-halfWidth, halfWidth).toDouble(),
        physical.y.clamp(-halfHeight, halfHeight).toDouble(),
      ),
    );
  }
}

class _PhotoMarker extends StatelessWidget {
  const _PhotoMarker({required this.impact, required this.selected});

  final PhotoCanvasImpact impact;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = AppContrastTokens.of(context);
    final fill = switch (impact.style) {
      PhotoCanvasImpactStyle.confirmed =>
        impact.isPositionUncertain ? tokens.critical : tokens.positive,
      PhotoCanvasImpactStyle.needsReview => tokens.caution,
      PhotoCanvasImpactStyle.suggestion => colors.surfaceContainerHighest,
    };
    final foreground = switch (impact.style) {
      PhotoCanvasImpactStyle.confirmed =>
        impact.isPositionUncertain ? tokens.onCritical : tokens.onPositive,
      PhotoCanvasImpactStyle.needsReview => tokens.onCaution,
      PhotoCanvasImpactStyle.suggestion => colors.onSurfaceVariant,
    };
    final multiplicity = impact.multiplicity > 1
        ? '×${impact.multiplicity}'
        : '';
    return SizedBox.square(
      dimension: 48,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: selected ? 34 : 30,
            height: selected ? 34 : 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill.withValues(alpha: 0.94),
              border: Border.all(
                color: selected ? tokens.markerOutline : colors.surface,
                width: selected ? 4 : 2,
                style: impact.style == PhotoCanvasImpactStyle.suggestion
                    ? BorderStyle.none
                    : BorderStyle.solid,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Text(
                  '${impact.sequenceNumber}$multiplicity',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          if (impact.style == PhotoCanvasImpactStyle.suggestion)
            CustomPaint(
              size: Size.square(selected ? 38 : 34),
              painter: _DashedCirclePainter(
                color: selected ? tokens.markerOutline : colors.outline,
              ),
            ),
          if (impact.style == PhotoCanvasImpactStyle.needsReview)
            Positioned(
              right: 1,
              bottom: 1,
              child: Icon(
                Icons.warning_amber_rounded,
                size: 15,
                color: foreground,
              ),
            ),
          if (impact.scoreLabel case final score?)
            Positioned(
              left: 32,
              top: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  child: Text(
                    score,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    const dashCount = 12;
    const dashFraction = 0.55;
    final sweep = math.pi * 2 / dashCount;
    for (var index = 0; index < dashCount; index++) {
      canvas.drawArc(
        rect.deflate(paint.strokeWidth / 2),
        index * sweep,
        sweep * dashFraction,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _AlignmentOutlinePainter extends CustomPainter {
  const _AlignmentOutlinePainter({
    required this.alignment,
    required this.impacts,
    required this.projectileDiameterMm,
    required this.color,
    required this.impactColor,
  });

  final ManualPhotoAlignment alignment;
  final List<PhotoCanvasImpact> impacts;
  final double projectileDiameterMm;
  final Color color;
  final Color impactColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var index = 0; index < alignment.corners.points.length; index++) {
      final point = alignment.corners.points[index];
      final rendered = Offset(point.x * size.width, point.y * size.height);
      if (index == 0) {
        path.moveTo(rendered.dx, rendered.dy);
      } else {
        path.lineTo(rendered.dx, rendered.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
    if (projectileDiameterMm <= 0) return;
    final radius = projectileDiameterMm / 2;
    for (final impact in impacts) {
      const segments = 40;
      final projectilePath = Path();
      for (var index = 0; index <= segments; index++) {
        final angle = index * math.pi * 2 / segments;
        final normalized = alignment.physicalToNormalized(
          PhysicalPointMm(
            impact.positionMm.x + math.cos(angle) * radius,
            impact.positionMm.y + math.sin(angle) * radius,
          ),
        );
        final rendered = Offset(
          normalized.x * size.width,
          normalized.y * size.height,
        );
        if (index == 0) {
          projectilePath.moveTo(rendered.dx, rendered.dy);
        } else {
          projectilePath.lineTo(rendered.dx, rendered.dy);
        }
      }
      projectilePath.close();
      canvas.drawPath(
        projectilePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = impactColor.withValues(alpha: 0.65),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AlignmentOutlinePainter oldDelegate) =>
      oldDelegate.alignment != alignment ||
      oldDelegate.impacts != impacts ||
      oldDelegate.projectileDiameterMm != projectileDiameterMm ||
      oldDelegate.color != color ||
      oldDelegate.impactColor != impactColor;
}
