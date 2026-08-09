import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
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
    this.targetProfile,
    this.overlayOpacity = 0.72,
    this.displayRotationQuarterTurns,
    this.showAlignmentStatus = true,
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
  final domain.TargetProfile? targetProfile;
  final double overlayOpacity;

  /// Optional temporary viewer rotation. Stored alignment coordinates remain
  /// authoritative and are transformed without modifying the original photo.
  final int? displayRotationQuarterTurns;
  final bool showAlignmentStatus;
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
    final renderedRotation =
        (displayRotationQuarterTurns ?? alignment.rotationQuarterTurns) % 4;
    final displaySize = renderedRotation.isOdd
        ? Size(imagePixelSize.height, imagePixelSize.width)
        : imagePixelSize;
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
        aspectRatio: displaySize.width / displaySize.height,
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
                    normalizedPosition: _normalizedForImpact(
                      impact,
                      renderedRotation,
                    ),
                    semanticsLabel:
                        'Treffer ${impact.sequenceNumber}, ${impact.scoreLabel ?? 'onbekende score'}, multipliciteit ${impact.multiplicity}',
                    selectionPriority: impact.sequenceNumber,
                    child: _PhotoMarker(
                      key: ValueKey('photo-impact-marker-${impact.id}'),
                      impact: impact,
                      selected: impact.id == selectedImpactId,
                    ),
                  ),
              ]
            : const [],
        contentBuilder: (context, size, zoom) => Stack(
          fit: StackFit.expand,
          children: [
            RotatedBox(
              quarterTurns: renderedRotation,
              child: Image(
                image: imageProvider,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, size: 48),
                  ),
                ),
              ),
            ),
            if (showOverlay)
              PhotoAlignmentGeometryOverlay(
                alignment: alignment,
                renderedRotationQuarterTurns: renderedRotation,
                targetProfile: targetProfile,
                impacts: impacts,
                projectileDiameterMm: projectileDiameterMm,
                opacity: overlayOpacity,
              ),
            if (showOverlay && showAlignmentStatus)
              Positioned(
                left: 8,
                bottom: 8,
                child: _AlignmentQualityBadge(alignment: alignment),
              ),
          ],
        ),
      ),
    );
  }

  Offset _normalizedForImpact(PhotoCanvasImpact impact, int renderedRotation) {
    final normalized = _fromAlignmentCoordinates(
      alignment.physicalToNormalized(impact.positionMm),
      renderedRotation,
    );
    return Offset(normalized.x, normalized.y);
  }

  PhotoCanvasPosition? _positionFromNormalized(Offset normalized) {
    final displayedPoint = NormalizedPoint(normalized.dx, normalized.dy);
    final renderedRotation =
        (displayRotationQuarterTurns ?? alignment.rotationQuarterTurns) % 4;
    final sourcePoint = unrotateNormalizedPoint(
      displayedPoint,
      renderedRotation,
    );
    final imagePoint = _toAlignmentCoordinates(
      displayedPoint,
      renderedRotation,
    );
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
      normalized: sourcePoint,
      displayedNormalized: displayedPoint,
      physicalMm: PhysicalPointMm(
        physical.x.clamp(-halfWidth, halfWidth).toDouble(),
        physical.y.clamp(-halfHeight, halfHeight).toDouble(),
      ),
    );
  }

  NormalizedPoint _toAlignmentCoordinates(
    NormalizedPoint displayed,
    int renderedRotation,
  ) => rotateNormalizedPoint(
    unrotateNormalizedPoint(displayed, renderedRotation),
    alignment.rotationQuarterTurns,
  );

  NormalizedPoint _fromAlignmentCoordinates(
    NormalizedPoint stored,
    int renderedRotation,
  ) => rotateNormalizedPoint(
    unrotateNormalizedPoint(stored, alignment.rotationQuarterTurns),
    renderedRotation,
  );
}

/// Reusable projection layer for alignment editors and read-only viewers.
///
/// The painter always projects from physical card millimetres through the
/// stored homography. [renderedRotationQuarterTurns] only controls the current
/// display orientation and never mutates the immutable source photo.
class PhotoAlignmentGeometryOverlay extends StatelessWidget {
  const PhotoAlignmentGeometryOverlay({
    required this.alignment,
    required this.renderedRotationQuarterTurns,
    this.targetProfile,
    this.impacts = const [],
    this.projectileDiameterMm = 0,
    this.opacity = 0.72,
    super.key,
  });

  final ManualPhotoAlignment alignment;
  final int renderedRotationQuarterTurns;
  final domain.TargetProfile? targetProfile;
  final List<PhotoCanvasImpact> impacts;
  final double projectileDiameterMm;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _TargetGeometryOverlayPainter(
        alignment: alignment,
        renderedRotationQuarterTurns: renderedRotationQuarterTurns % 4,
        targetProfile: targetProfile,
        impacts: impacts,
        projectileDiameterMm: projectileDiameterMm,
        color: Theme.of(context).colorScheme.primary,
        impactColor: AppContrastTokens.of(context).positive,
        opacity: opacity.clamp(0.05, 1),
      ),
    ),
  );
}

class _PhotoMarker extends StatelessWidget {
  const _PhotoMarker({required this.impact, required this.selected, super.key});

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

class _TargetGeometryOverlayPainter extends CustomPainter {
  const _TargetGeometryOverlayPainter({
    required this.alignment,
    required this.renderedRotationQuarterTurns,
    required this.targetProfile,
    required this.impacts,
    required this.projectileDiameterMm,
    required this.color,
    required this.impactColor,
    required this.opacity,
  });

  final ManualPhotoAlignment alignment;
  final int renderedRotationQuarterTurns;
  final domain.TargetProfile? targetProfile;
  final List<PhotoCanvasImpact> impacts;
  final double projectileDiameterMm;
  final Color color;
  final Color impactColor;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _physicalPolygon(
      [
        PhysicalPointMm(
          -alignment.cardWidthMm / 2,
          -alignment.cardHeightMm / 2,
        ),
        PhysicalPointMm(alignment.cardWidthMm / 2, -alignment.cardHeightMm / 2),
        PhysicalPointMm(alignment.cardWidthMm / 2, alignment.cardHeightMm / 2),
        PhysicalPointMm(-alignment.cardWidthMm / 2, alignment.cardHeightMm / 2),
      ],
      size,
      close: true,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = color.withValues(alpha: opacity),
    );

    _paintAxes(canvas, size);
    final target = targetProfile;
    if (target != null) _paintTarget(canvas, size, target);
    _paintAnchors(canvas, size);

    if (projectileDiameterMm <= 0) return;
    final radius = projectileDiameterMm / 2;
    for (final impact in impacts) {
      final projectilePath = _physicalCircle(
        PhysicalPointMm(impact.positionMm.x, impact.positionMm.y),
        radius,
        size,
      );
      canvas.drawPath(
        projectilePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = impactColor.withValues(alpha: opacity),
      );
    }
  }

  void _paintTarget(Canvas canvas, Size size, domain.TargetProfile target) {
    if (target.targetKind == domain.TargetKind.multiBullConcentric &&
        target.bulls.isNotEmpty) {
      for (final bull in target.bulls) {
        _paintBull(
          canvas,
          size,
          target,
          PhysicalPointMm(bull.centerXMm, bull.centerYMm),
          isSighter: bull.role == domain.TargetBullRole.sighter,
        );
      }
    } else {
      _paintBull(canvas, size, target, const PhysicalPointMm(0, 0));
    }
  }

  void _paintBull(
    Canvas canvas,
    Size size,
    domain.TargetProfile target,
    PhysicalPointMm center, {
    bool isSighter = false,
  }) {
    final blackDiameter = target.blackOuterDiameterMm;
    if (blackDiameter != null && blackDiameter > 0) {
      canvas.drawPath(
        _physicalCircle(center, blackDiameter / 2, size),
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black.withValues(
            alpha: (isSighter ? 0.035 : 0.075) * opacity,
          ),
      );
      canvas.drawPath(
        _physicalCircle(center, blackDiameter / 2, size),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.3
          ..color = color.withValues(alpha: opacity),
      );
    }
    for (final ring in target.rings) {
      canvas.drawPath(
        _physicalCircle(center, ring.outerDiameterMm / 2, size),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSighter ? 1 : 1.4
          ..color = color.withValues(
            alpha: (isSighter ? 0.42 : 0.78) * opacity,
          ),
      );
    }
    final innerTen = target.innerTenDiameterMm;
    if (innerTen != null && innerTen > 0) {
      canvas.drawPath(
        _physicalCircle(center, innerTen / 2, size),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = color.withValues(alpha: 0.62 * opacity),
      );
    }
    final renderedCenter = _projectPhysical(center, size);
    canvas.drawLine(
      renderedCenter - const Offset(7, 0),
      renderedCenter + const Offset(7, 0),
      Paint()
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: opacity),
    );
    canvas.drawLine(
      renderedCenter - const Offset(0, 7),
      renderedCenter + const Offset(0, 7),
      Paint()
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: opacity),
    );
  }

  void _paintAxes(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.5 * opacity);
    canvas.drawPath(
      _physicalPolygon([
        PhysicalPointMm(-alignment.cardWidthMm / 2, 0),
        PhysicalPointMm(alignment.cardWidthMm / 2, 0),
      ], size),
      axisPaint,
    );
    canvas.drawPath(
      _physicalPolygon([
        PhysicalPointMm(0, -alignment.cardHeightMm / 2),
        PhysicalPointMm(0, alignment.cardHeightMm / 2),
      ], size),
      axisPaint,
    );
  }

  void _paintAnchors(Canvas canvas, Size size) {
    final anchors = alignment.anchors;
    for (var index = 0; index < anchors.length; index++) {
      final displayed = _fromAlignmentCoordinates(anchors[index].sourcePoint);
      final point = Offset(displayed.x * size.width, displayed.y * size.height);
      canvas.drawCircle(
        point,
        5,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.88 * opacity),
      );
      canvas.drawCircle(
        point,
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.9 * opacity),
      );
    }
  }

  Path _physicalCircle(PhysicalPointMm center, double radius, Size size) {
    const segments = 96;
    final points = <PhysicalPointMm>[
      for (var index = 0; index <= segments; index++)
        PhysicalPointMm(
          center.x + math.cos(index * math.pi * 2 / segments) * radius,
          center.y + math.sin(index * math.pi * 2 / segments) * radius,
        ),
    ];
    return _physicalPolygon(points, size, close: true);
  }

  Path _physicalPolygon(
    List<PhysicalPointMm> points,
    Size size, {
    bool close = false,
  }) {
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final rendered = _projectPhysical(points[index], size);
      if (index == 0) {
        path.moveTo(rendered.dx, rendered.dy);
      } else {
        path.lineTo(rendered.dx, rendered.dy);
      }
    }
    if (close) path.close();
    return path;
  }

  Offset _projectPhysical(PhysicalPointMm point, Size size) {
    final stored = alignment.physicalToNormalized(point);
    final displayed = _fromAlignmentCoordinates(stored);
    return Offset(displayed.x * size.width, displayed.y * size.height);
  }

  NormalizedPoint _fromAlignmentCoordinates(NormalizedPoint stored) =>
      rotateNormalizedPoint(
        unrotateNormalizedPoint(stored, alignment.rotationQuarterTurns),
        renderedRotationQuarterTurns,
      );

  @override
  bool shouldRepaint(covariant _TargetGeometryOverlayPainter oldDelegate) =>
      oldDelegate.alignment != alignment ||
      oldDelegate.renderedRotationQuarterTurns !=
          renderedRotationQuarterTurns ||
      oldDelegate.targetProfile != targetProfile ||
      oldDelegate.impacts != impacts ||
      oldDelegate.projectileDiameterMm != projectileDiameterMm ||
      oldDelegate.color != color ||
      oldDelegate.impactColor != impactColor ||
      oldDelegate.opacity != opacity;
}

class _AlignmentQualityBadge extends StatelessWidget {
  const _AlignmentQualityBadge({required this.alignment});

  final ManualPhotoAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, label, background, foreground) = switch (alignment.quality) {
      AlignmentQualityGrade.excellent => (
        Icons.verified_outlined,
        'Uitlijning goed',
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      AlignmentQualityGrade.acceptable => (
        Icons.check_circle_outline,
        'Uitlijning bruikbaar',
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      AlignmentQualityGrade.reviewRequired => (
        Icons.warning_amber_rounded,
        'Uitlijning controleren',
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      AlignmentQualityGrade.legacyUnverified => (
        Icons.help_outline,
        'Oude uitlijning',
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };
    final residual = alignment.residuals;
    final detail =
        '$label · RMS ${residual.rmsMm.toStringAsFixed(2)} mm · max ${residual.maximumMm.toStringAsFixed(2)} mm';
    return Semantics(
      label: detail,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 5),
              Text(
                '$label · ${residual.rmsMm.toStringAsFixed(2)} mm',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
