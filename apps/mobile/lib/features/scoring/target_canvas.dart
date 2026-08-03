import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shooting_companion_domain/domain.dart';

class TargetCanvas extends StatefulWidget {
  const TargetCanvas({
    required this.target,
    required this.impacts,
    required this.projectileDiameterMm,
    this.onChanged,
    this.onImpactSelected,
    this.selectedImpactId,
    this.scoreValues = const {},
    super.key,
  });

  final TargetProfile target;
  final List<ShotImpact> impacts;
  final double projectileDiameterMm;
  final ValueChanged<List<ShotImpact>>? onChanged;
  final ValueChanged<String?>? onImpactSelected;
  final String? selectedImpactId;
  final Map<String, int> scoreValues;

  @override
  State<TargetCanvas> createState() => _TargetCanvasState();
}

class _TargetCanvasState extends State<TargetCanvas> {
  int? _dragIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: widget.onChanged == null
                ? null
                : (details) {
                    final existing = _nearestImpact(
                      details.localPosition,
                      size,
                    );
                    if (existing != null) {
                      widget.onImpactSelected?.call(
                        widget.impacts[existing].id,
                      );
                      return;
                    }
                    final point = _toMillimeters(details.localPosition, size);
                    final impact = ShotImpact(
                      id: 'impact-${DateTime.now().microsecondsSinceEpoch}',
                      xMm: point.dx,
                      yMm: point.dy,
                    );
                    widget.onChanged!([...widget.impacts, impact]);
                    widget.onImpactSelected?.call(impact.id);
                  },
            onPanStart: widget.onChanged == null
                ? null
                : (details) {
                    _dragIndex = _nearestImpact(details.localPosition, size);
                    final index = _dragIndex;
                    widget.onImpactSelected?.call(
                      index == null ? null : widget.impacts[index].id,
                    );
                  },
            onPanUpdate: widget.onChanged == null
                ? null
                : (details) {
                    final index = _dragIndex;
                    if (index == null) return;
                    final point = _toMillimeters(details.localPosition, size);
                    final updated = [...widget.impacts];
                    updated[index] = updated[index].copyWith(
                      xMm: point.dx,
                      yMm: point.dy,
                    );
                    widget.onChanged!(updated);
                  },
            onPanEnd: (_) => _dragIndex = null,
            child: Semantics(
              label:
                  'Doelkaart met ${widget.impacts.length} zichtbare treffers',
              child: CustomPaint(
                size: Size.square(size),
                painter: TargetPainter(
                  target: widget.target,
                  impacts: widget.impacts,
                  projectileDiameterMm: widget.projectileDiameterMm,
                  colorScheme: Theme.of(context).colorScheme,
                  selectedImpactId: widget.selectedImpactId,
                  scoreValues: widget.scoreValues,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _toMillimeters(Offset point, double size) => Offset(
    (point.dx / size - 0.5) * widget.target.physicalCardWidthMm,
    (point.dy / size - 0.5) * widget.target.physicalCardHeightMm,
  );

  int? _nearestImpact(Offset point, double size) {
    int? best;
    var bestDistance = 28.0;
    for (var index = 0; index < widget.impacts.length; index++) {
      if (widget.impacts[index].isMiss) continue;
      final rendered = Offset(
        (widget.impacts[index].xMm / widget.target.physicalCardWidthMm + 0.5) *
            size,
        (widget.impacts[index].yMm / widget.target.physicalCardHeightMm + 0.5) *
            size,
      );
      final distance = (rendered - point).distance;
      if (distance < bestDistance) {
        best = index;
        bestDistance = distance;
      }
    }
    return best;
  }
}

class TargetPainter extends CustomPainter {
  TargetPainter({
    required this.target,
    required this.impacts,
    required this.projectileDiameterMm,
    required this.colorScheme,
    required this.selectedImpactId,
    required this.scoreValues,
  });

  final TargetProfile target;
  final List<ShotImpact> impacts;
  final double projectileDiameterMm;
  final ColorScheme colorScheme;
  final String? selectedImpactId;
  final Map<String, int> scoreValues;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / target.physicalCardWidthMm;
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

    for (var index = 0; index < impacts.length; index++) {
      final impact = impacts[index];
      if (impact.isMiss) continue;
      final point = Offset(
        center.dx + impact.xMm * scale,
        center.dy + impact.yMm * scale,
      );
      final radius = math.max(5.0, projectileDiameterMm / 2 * scale);
      canvas.drawCircle(
        point,
        radius,
        Paint()
          ..color = impact.isPositionUncertain
              ? colorScheme.error
              : colorScheme.tertiary,
      );
      if (impact.id == selectedImpactId) {
        canvas.drawCircle(
          point,
          radius + 4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = colorScheme.primary,
        );
      }
      final text = TextPainter(
        text: TextSpan(
          text: scoreValues.containsKey(impact.id)
              ? '${index + 1}·${scoreValues[impact.id]}'
              : '${index + 1}',
          style: TextStyle(
            color: colorScheme.onTertiary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, point - Offset(text.width / 2, text.height / 2));
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
      oldDelegate.selectedImpactId != selectedImpactId ||
      oldDelegate.scoreValues != scoreValues ||
      oldDelegate.colorScheme != colorScheme;
}
