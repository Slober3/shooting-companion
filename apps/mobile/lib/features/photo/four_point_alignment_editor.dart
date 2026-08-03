import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shooting_companion_photo_geometry/photo_geometry.dart';

/// Manual target-card alignment. Points are always selected in target-relative
/// TL, TR, BR, BL order; this also supports a rotated card photo.
class FourPointAlignmentEditor extends StatefulWidget {
  FourPointAlignmentEditor({
    required this.imageProvider,
    required this.imagePixelSize,
    required this.cardWidthMm,
    required this.cardHeightMm,
    required this.onConfirmed,
    this.initialCorners,
    this.onCornersChanged,
    this.onUseAsAttachment,
    this.minimumAreaFraction = QuadValidator.defaultMinimumAreaFraction,
    this.maximumImageHeight = 560,
    super.key,
  }) : assert(imagePixelSize.width > 0),
       assert(imagePixelSize.height > 0),
       assert(cardWidthMm > 0),
       assert(cardHeightMm > 0),
       assert(maximumImageHeight > 0);

  final ImageProvider<Object> imageProvider;
  final Size imagePixelSize;
  final double cardWidthMm;
  final double cardHeightMm;
  final NormalizedQuad? initialCorners;
  final double minimumAreaFraction;
  final double maximumImageHeight;
  final ValueChanged<List<NormalizedPoint>>? onCornersChanged;
  final ValueChanged<ManualPhotoAlignment> onConfirmed;
  final VoidCallback? onUseAsAttachment;

  @override
  State<FourPointAlignmentEditor> createState() =>
      _FourPointAlignmentEditorState();
}

class _FourPointAlignmentEditorState extends State<FourPointAlignmentEditor> {
  static const _cornerNames = [
    'linksboven',
    'rechtsboven',
    'rechtsonder',
    'linksonder',
  ];

  late List<NormalizedPoint> _points;
  int? _draggedIndex;

  @override
  void initState() {
    super.initState();
    _points = widget.initialCorners?.points.toList() ?? [];
  }

  @override
  void didUpdateWidget(covariant FourPointAlignmentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCorners != widget.initialCorners) {
      _points = widget.initialCorners?.points.toList() ?? [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final buildResult = _buildAlignment();
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_instructionText(buildResult), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = _containedSize(constraints.maxWidth);
            return Center(
              child: Semantics(
                label:
                    'Handmatige kaartuitlijning, ${_points.length} van 4 hoekpunten gekozen',
                child: SizedBox.fromSize(
                  size: size,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) =>
                        _addPoint(details.localPosition, size),
                    onPanStart: (details) =>
                        _beginDrag(details.localPosition, size),
                    onPanUpdate: (details) =>
                        _updateDrag(details.localPosition, size),
                    onPanEnd: (_) => _draggedIndex = null,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image(
                          image: widget.imageProvider,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 48,
                                  ),
                                ),
                              ),
                        ),
                        IgnorePointer(
                          child: CustomPaint(
                            painter: _AlignmentPainter(
                              points: _points,
                              colorScheme: theme.colorScheme,
                              isValid: buildResult?.isValid ?? false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (_points.length == 4 && buildResult != null)
          _ValidationStatus(validation: buildResult.validation),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.onUseAsAttachment != null)
              TextButton.icon(
                onPressed: widget.onUseAsAttachment,
                icon: const Icon(Icons.attach_file),
                label: const Text('Alleen als foto bewaren'),
              ),
            TextButton.icon(
              onPressed: _points.isEmpty ? null : _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Opnieuw'),
            ),
            FilledButton.icon(
              onPressed: buildResult?.alignment == null
                  ? null
                  : () => widget.onConfirmed(buildResult!.alignment!),
              icon: const Icon(Icons.check),
              label: const Text('Uitlijning gebruiken'),
            ),
          ],
        ),
      ],
    );
  }

  AlignmentBuildResult? _buildAlignment() {
    if (_points.length != 4) return null;
    return ManualPhotoAlignment.build(
      corners: NormalizedQuad.fromOrderedPoints(_points),
      cardWidthMm: widget.cardWidthMm,
      cardHeightMm: widget.cardHeightMm,
      minimumAreaFraction: widget.minimumAreaFraction,
    );
  }

  String _instructionText(AlignmentBuildResult? result) {
    if (_points.length < 4) {
      return 'Tik op de hoek ${_points.length + 1}/4: '
          '${_cornerNames[_points.length]} van de kaart.';
    }
    if (result?.isValid ?? false) {
      return 'De uitlijning is geldig. Versleep een punt om ze te verfijnen.';
    }
    return 'Versleep de genummerde punten tot de volledige kaart correct is omlijnd.';
  }

  void _addPoint(Offset local, Size size) {
    if (_points.length >= 4) return;
    final point = _normalized(local, size);
    setState(() => _points = [..._points, point]);
    widget.onCornersChanged?.call(List.unmodifiable(_points));
  }

  void _beginDrag(Offset local, Size size) {
    var nearestDistance = 34.0;
    int? nearest;
    for (var index = 0; index < _points.length; index++) {
      final rendered = Offset(
        _points[index].x * size.width,
        _points[index].y * size.height,
      );
      final distance = (rendered - local).distance;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = index;
      }
    }
    _draggedIndex = nearest;
  }

  void _updateDrag(Offset local, Size size) {
    final index = _draggedIndex;
    if (index == null) return;
    final updated = [..._points];
    updated[index] = _normalized(local, size);
    setState(() => _points = updated);
    widget.onCornersChanged?.call(List.unmodifiable(_points));
  }

  NormalizedPoint _normalized(Offset local, Size size) => NormalizedPoint(
    (local.dx / size.width).clamp(0, 1).toDouble(),
    (local.dy / size.height).clamp(0, 1).toDouble(),
  );

  void _reset() {
    setState(() => _points = []);
    widget.onCornersChanged?.call(const []);
  }

  Size _containedSize(double availableWidth) {
    final naturalHeight =
        availableWidth *
        widget.imagePixelSize.height /
        widget.imagePixelSize.width;
    if (naturalHeight <= widget.maximumImageHeight) {
      return Size(availableWidth, naturalHeight);
    }
    final width =
        widget.maximumImageHeight *
        widget.imagePixelSize.width /
        widget.imagePixelSize.height;
    return Size(math.min(width, availableWidth), widget.maximumImageHeight);
  }
}

class _ValidationStatus extends StatelessWidget {
  const _ValidationStatus({required this.validation});

  final QuadValidationResult validation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final valid = validation.isValid;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            valid ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: valid ? colors.primary : colors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              valid
                  ? 'Geldige kaartomtrek '
                        '(${(validation.areaFraction * 100).round()}% van de foto).'
                  : _validationMessage(validation),
            ),
          ),
        ],
      ),
    );
  }

  String _validationMessage(QuadValidationResult result) {
    final issues = result.issues;
    if (issues.contains(QuadValidationIssue.nonFiniteCoordinate) ||
        issues.contains(QuadValidationIssue.pointOutsideImage)) {
      return 'Een of meer punten liggen buiten de foto.';
    }
    if (issues.contains(QuadValidationIssue.duplicatePoints)) {
      return 'De vier hoekpunten moeten van elkaar verschillen.';
    }
    if (issues.contains(QuadValidationIssue.selfIntersecting) ||
        issues.contains(QuadValidationIssue.wrongPointOrder)) {
      return 'De kaartlijnen kruisen. Controleer de volgorde linksboven, '
          'rechtsboven, rechtsonder, linksonder.';
    }
    if (issues.contains(QuadValidationIssue.notConvex)) {
      return 'De vier punten moeten de buitenhoeken van de volledige kaart volgen.';
    }
    if (issues.contains(QuadValidationIssue.areaTooSmall)) {
      return 'De kaart is te klein in beeld. Ze moet minstens '
          '${(result.minimumAreaFraction * 100).round()}% van de foto innemen.';
    }
    return 'De kaartomtrek is nog niet bruikbaar.';
  }
}

class _AlignmentPainter extends CustomPainter {
  _AlignmentPainter({
    required this.points,
    required this.colorScheme,
    required this.isValid,
  });

  final List<NormalizedPoint> points;
  final ColorScheme colorScheme;
  final bool isValid;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final rendered = points
        .map((point) => Offset(point.x * size.width, point.y * size.height))
        .toList();
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = isValid ? colorScheme.primary : colorScheme.error;
    final path = Path()..moveTo(rendered.first.dx, rendered.first.dy);
    for (var index = 1; index < rendered.length; index++) {
      path.lineTo(rendered[index].dx, rendered[index].dy);
    }
    if (rendered.length == 4) path.close();
    canvas.drawPath(path, line);

    for (var index = 0; index < rendered.length; index++) {
      final centre = rendered[index];
      canvas.drawCircle(
        centre,
        16,
        Paint()..color = colorScheme.surface.withValues(alpha: 0.92),
      );
      canvas.drawCircle(centre, 16, line);
      final label = TextPainter(
        text: TextSpan(
          text: '${index + 1}',
          style: TextStyle(
            color: isValid ? colorScheme.primary : colorScheme.error,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, centre - Offset(label.width / 2, label.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _AlignmentPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.colorScheme != colorScheme ||
      oldDelegate.isValid != isValid;
}
