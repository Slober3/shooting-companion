import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shooting_companion_domain/domain.dart';

import '../../app/theme.dart';
import 'transformable_scoring_viewport.dart';

class TargetCanvas extends StatelessWidget {
  const TargetCanvas({
    required this.target,
    required this.impacts,
    required this.projectileDiameterMm,
    this.onChanged,
    this.onImpactSelected,
    this.onImpactLongPressed,
    this.onImpactMoveStart,
    this.onImpactMoveEnd,
    this.onImpactMoveCancel,
    this.onInvalidPosition,
    this.selectedImpactId,
    this.scoreValues = const {},
    this.tool = ScoringTool.place,
    this.precisionMode = false,
    this.viewportController,
    this.showControls = true,
    super.key,
  });

  final TargetProfile target;
  final List<ShotImpact> impacts;
  final double projectileDiameterMm;
  final ValueChanged<List<ShotImpact>>? onChanged;
  final ValueChanged<String?>? onImpactSelected;
  final ValueChanged<String>? onImpactLongPressed;
  final ValueChanged<String>? onImpactMoveStart;
  final ValueChanged<String>? onImpactMoveEnd;
  final ValueChanged<String>? onImpactMoveCancel;
  final VoidCallback? onInvalidPosition;
  final String? selectedImpactId;
  final Map<String, int> scoreValues;
  final ScoringTool tool;
  final bool precisionMode;
  final ScoringViewportController? viewportController;
  final bool showControls;

  @override
  Widget build(BuildContext context) {
    final visible = <({int index, ShotImpact impact})>[
      for (var index = 0; index < impacts.length; index++)
        if (!impacts[index].isMiss) (index: index, impact: impacts[index]),
    ];
    visible.sort((first, second) {
      if (first.impact.id == selectedImpactId) return 1;
      if (second.impact.id == selectedImpactId) return -1;
      return first.index.compareTo(second.index);
    });

    return Semantics(
      label: 'Doelkaart met ${visible.length} zichtbare treffers',
      image: true,
      child: TransformableScoringViewport(
        aspectRatio: target.physicalCardWidthMm / target.physicalCardHeightMm,
        controller: viewportController,
        accessMode: onChanged == null
            ? CanvasAccessMode.readOnly
            : CanvasAccessMode.editable,
        tool: tool,
        precisionMode: precisionMode,
        showControls: showControls,
        onInvalidPosition: onInvalidPosition,
        onBackgroundTap: (normalized) {
          if (tool == ScoringTool.edit) {
            onImpactSelected?.call(null);
            return;
          }
          final point = _toMillimeters(normalized);
          final impact = ShotImpact(
            id: 'impact-${DateTime.now().microsecondsSinceEpoch}',
            xMm: point.dx,
            yMm: point.dy,
          );
          onChanged?.call([...impacts, impact]);
          onImpactSelected?.call(impact.id);
        },
        onMarkerSelected: (id) => onImpactSelected?.call(id),
        onMarkerLongPressed: onImpactLongPressed,
        onMarkerDragStart: onImpactMoveStart,
        onMarkerDragEnd: onImpactMoveEnd,
        onMarkerDragCancel: onImpactMoveCancel,
        onMarkerMoved: (id, normalized) {
          final point = _toMillimeters(normalized);
          onChanged?.call([
            for (final impact in impacts)
              if (impact.id == id)
                impact.copyWith(xMm: point.dx, yMm: point.dy)
              else
                impact,
          ]);
        },
        markers: [
          for (final item in visible)
            ScoringViewportMarker(
              id: item.impact.id,
              normalizedPosition: _toNormalized(item.impact),
              semanticsLabel: _semanticsLabel(item.index, item.impact),
              selectionPriority: item.index,
              child: _ImpactMarker(
                selected: item.impact.id == selectedImpactId,
                uncertain: item.impact.isPositionUncertain,
                label: _markerLabel(item.index, item.impact),
              ),
            ),
        ],
        contentBuilder: (context, size, zoom) => CustomPaint(
          size: size,
          painter: TargetPainter(
            target: target,
            impacts: impacts,
            projectileDiameterMm: projectileDiameterMm,
            colorScheme: Theme.of(context).colorScheme,
          ),
        ),
      ),
    );
  }

  Offset _toNormalized(ShotImpact impact) => Offset(
    impact.xMm / target.physicalCardWidthMm + 0.5,
    impact.yMm / target.physicalCardHeightMm + 0.5,
  );

  Offset _toMillimeters(Offset normalized) => Offset(
    (normalized.dx - 0.5) * target.physicalCardWidthMm,
    (normalized.dy - 0.5) * target.physicalCardHeightMm,
  );

  String _markerLabel(int index, ShotImpact impact) {
    final score = scoreValues[impact.id];
    final multiplicity = impact.multiplicity > 1
        ? '×${impact.multiplicity}'
        : '';
    return score == null
        ? '${index + 1}$multiplicity'
        : '${index + 1}·$score$multiplicity';
  }

  String _semanticsLabel(int index, ShotImpact impact) {
    final score = scoreValues[impact.id] ?? 0;
    return 'Treffer ${index + 1}, $score punten, multipliciteit ${impact.multiplicity}';
  }
}

class _ImpactMarker extends StatelessWidget {
  const _ImpactMarker({
    required this.selected,
    required this.uncertain,
    required this.label,
  });

  final bool selected;
  final bool uncertain;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = AppContrastTokens.of(context);
    final fill = uncertain ? tokens.critical : tokens.positive;
    return Container(
      width: selected ? 34 : 30,
      height: selected ? 34 : 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill.withValues(alpha: 0.94),
        border: Border.all(
          color: selected ? tokens.markerOutline : colors.surface,
          width: selected ? 4 : 2,
        ),
        boxShadow: selected
            ? [BoxShadow(color: tokens.markerOutline, blurRadius: 7)]
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Text(
            label,
            style: TextStyle(
              color: uncertain ? tokens.onCritical : tokens.onPositive,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class TargetPainter extends CustomPainter {
  TargetPainter({
    required this.target,
    required this.impacts,
    required this.projectileDiameterMm,
    required this.colorScheme,
  });

  final TargetProfile target;
  final List<ShotImpact> impacts;
  final double projectileDiameterMm;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / target.physicalCardWidthMm,
      size.height / target.physicalCardHeightMm,
    );
    final center = size.center(Offset.zero);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF2EEE3),
    );

    final blackDiameter = target.blackOuterDiameterMm;
    if (blackDiameter != null) {
      canvas.drawCircle(
        center,
        blackDiameter / 2 * scale,
        Paint()..color = const Color(0xFF171717),
      );
    }

    for (final ring in target.rings.reversed) {
      final inBlack =
          blackDiameter != null && ring.outerDiameterMm <= blackDiameter;
      canvas.drawCircle(
        center,
        ring.outerDiameterMm / 2 * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, target.lineThicknessMm * scale)
          ..color = inBlack ? const Color(0xFFECECEC) : const Color(0xFF2B2B2B),
      );
    }

    for (final impact in impacts) {
      if (impact.isMiss) continue;
      final point = Offset(
        center.dx + impact.xMm * scale,
        center.dy + impact.yMm * scale,
      );
      canvas.drawCircle(
        point,
        projectileDiameterMm / 2 * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, 0.5 * scale)
          ..color = colorScheme.tertiary.withValues(alpha: 0.6),
      );
    }

    canvas.drawCircle(center, 2, Paint()..color = colorScheme.error);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colorScheme.outline,
    );
  }

  @override
  bool shouldRepaint(covariant TargetPainter oldDelegate) =>
      oldDelegate.target.versionedId != target.versionedId ||
      oldDelegate.impacts != impacts ||
      oldDelegate.projectileDiameterMm != projectileDiameterMm ||
      oldDelegate.colorScheme != colorScheme;
}
