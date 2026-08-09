import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart';

import '../scoring/transformable_scoring_viewport.dart';
import '../../widgets/app_notice.dart';
import 'photo_overlay_canvas.dart';

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
    this.initialRotationQuarterTurns = 0,
    this.targetProfile,
    this.overlayOpacity = 0.72,
    this.onCornersChanged,
    this.onRotationChanged,
    this.onUseAsAttachment,
    this.minimumAreaFraction = QuadValidator.defaultMinimumAreaFraction,
    this.maximumImageHeight = 560,
    super.key,
  }) : assert(imagePixelSize.width > 0),
       assert(imagePixelSize.height > 0),
       assert(cardWidthMm > 0),
       assert(cardHeightMm > 0),
       assert(
         initialRotationQuarterTurns >= 0 && initialRotationQuarterTurns <= 3,
       ),
       assert(maximumImageHeight > 0);

  final ImageProvider<Object> imageProvider;
  final Size imagePixelSize;
  final double cardWidthMm;
  final double cardHeightMm;
  final NormalizedQuad? initialCorners;
  final int initialRotationQuarterTurns;
  final domain.TargetProfile? targetProfile;
  final double overlayOpacity;
  final double minimumAreaFraction;
  final double maximumImageHeight;
  final ValueChanged<List<NormalizedPoint>>? onCornersChanged;
  final ValueChanged<int>? onRotationChanged;
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
  final _viewportController = ScoringViewportController();
  bool _precisionMode = false;
  int? _selectedCornerIndex;
  late int _rotationQuarterTurns;
  DateTime? _lastInvalidFeedbackAt;

  @override
  void initState() {
    super.initState();
    _rotationQuarterTurns = widget.initialRotationQuarterTurns;
    _points = widget.initialCorners?.points.toList() ?? [];
  }

  @override
  void didUpdateWidget(covariant FourPointAlignmentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cornersChanged = oldWidget.initialCorners != widget.initialCorners;
    final rotationChanged =
        oldWidget.initialRotationQuarterTurns !=
        widget.initialRotationQuarterTurns;

    if (cornersChanged && rotationChanged) {
      _points = widget.initialCorners?.points.toList() ?? [];
      _rotationQuarterTurns = widget.initialRotationQuarterTurns;
      _selectedCornerIndex = null;
      return;
    }

    if (cornersChanged) {
      _points = widget.initialCorners?.points.toList() ?? [];
      _selectedCornerIndex = null;
    }
    if (rotationChanged) {
      _setRotation(widget.initialRotationQuarterTurns, notify: false);
    }
  }

  @override
  void dispose() {
    _viewportController.dispose();
    super.dispose();
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
        const SizedBox(height: 8),
        _RotationControls(
          rotationQuarterTurns: _rotationQuarterTurns,
          onRotateLeft: () => _setRotation(_rotationQuarterTurns - 1),
          onRotateRight: () => _setRotation(_rotationQuarterTurns + 1),
          onReset: () => _setRotation(0),
        ),
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
                  child: TransformableScoringViewport(
                    aspectRatio:
                        _displayImageSize.width / _displayImageSize.height,
                    controller: _viewportController,
                    accessMode: CanvasAccessMode.editable,
                    tool: ScoringTool.edit,
                    precisionMode: _precisionMode,
                    markers: [
                      for (var index = 0; index < _points.length; index++)
                        ScoringViewportMarker(
                          id: '$index',
                          normalizedPosition: Offset(
                            _points[index].x,
                            _points[index].y,
                          ),
                          semanticsLabel:
                              'Hoek ${index + 1}, ${_cornerNames[index]}',
                          selectionPriority: index,
                          child: _CornerMarker(
                            number: index + 1,
                            isValid: buildResult?.isValid ?? false,
                            selected: index == _selectedCornerIndex,
                          ),
                        ),
                    ],
                    onBackgroundTap: _addNormalizedPoint,
                    onMarkerSelected: (id) {
                      final index = int.tryParse(id);
                      if (index != null && index < _points.length) {
                        setState(() => _selectedCornerIndex = index);
                      }
                    },
                    onMarkerMoved: _movePoint,
                    onInvalidPosition: _showOutsideMessage,
                    contentBuilder: (context, contentSize, zoom) => Stack(
                      fit: StackFit.expand,
                      children: [
                        RotatedBox(
                          quarterTurns: _rotationQuarterTurns,
                          child: Image(
                            image: widget.imageProvider,
                            fit: BoxFit.contain,
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
                        if (buildResult?.alignment case final alignment?)
                          PhotoAlignmentGeometryOverlay(
                            key: const ValueKey(
                              'four-point-projected-target-overlay',
                            ),
                            alignment: alignment,
                            renderedRotationQuarterTurns: _rotationQuarterTurns,
                            targetProfile: widget.targetProfile,
                            opacity: widget.overlayOpacity,
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
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              selected: _precisionMode,
              avatar: const Icon(Icons.center_focus_strong, size: 18),
              label: const Text('Precisie'),
              onSelected: (value) => setState(() => _precisionMode = value),
            ),
            if (_precisionMode)
              FilledButton.tonalIcon(
                onPressed: _points.length < 4 || _selectedCornerIndex != null
                    ? _placeAtCrosshair
                    : null,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: Text(
                  _points.length < 4 ? 'Hoek vastleggen' : 'Hoek verplaatsen',
                ),
              ),
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
              label: const Text('Uitlijning klopt'),
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
      rotationQuarterTurns: _rotationQuarterTurns,
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

  void _addNormalizedPoint(Offset normalized) {
    if (_points.length >= 4) return;
    final point = NormalizedPoint(normalized.dx, normalized.dy);
    setState(() => _points = [..._points, point]);
    widget.onCornersChanged?.call(List.unmodifiable(_points));
  }

  void _movePoint(String id, Offset normalized) {
    final index = int.tryParse(id);
    if (index == null || index < 0 || index >= _points.length) return;
    final updated = [..._points];
    updated[index] = NormalizedPoint(normalized.dx, normalized.dy);
    setState(() {
      _points = updated;
      _selectedCornerIndex = index;
    });
    widget.onCornersChanged?.call(List.unmodifiable(_points));
  }

  void _placeAtCrosshair() {
    final normalized = _viewportController.viewportCenterNormalized;
    if (normalized == null) {
      _showOutsideMessage();
      return;
    }
    if (_points.length < 4) {
      _addNormalizedPoint(normalized);
      return;
    }
    final selected = _selectedCornerIndex;
    if (selected == null) {
      AppMessenger.show(
        context,
        kind: AppNoticeKind.info,
        message: 'Selecteer eerst een genummerde hoek.',
      );
      return;
    }
    _movePoint('$selected', normalized);
  }

  void _showOutsideMessage() {
    final now = DateTime.now();
    if (_lastInvalidFeedbackAt != null &&
        now.difference(_lastInvalidFeedbackAt!) <
            const Duration(milliseconds: 800)) {
      return;
    }
    _lastInvalidFeedbackAt = now;
    AppMessenger.show(
      context,
      kind: AppNoticeKind.warning,
      message: 'De gekozen positie ligt buiten de foto.',
    );
  }

  void _reset() {
    setState(() {
      _points = [];
      _selectedCornerIndex = null;
    });
    widget.onCornersChanged?.call(const []);
  }

  void _setRotation(int requested, {bool notify = true}) {
    final next = requested % 4;
    final normalizedNext = next < 0 ? next + 4 : next;
    if (normalizedNext == _rotationQuarterTurns) return;
    final oldRotation = _rotationQuarterTurns;
    final rotatedPoints = _points
        .map(
          (point) => rotateNormalizedPoint(
            unrotateNormalizedPoint(point, oldRotation),
            normalizedNext,
          ),
        )
        .toList(growable: false);
    setState(() {
      _rotationQuarterTurns = normalizedNext;
      _points = rotatedPoints;
    });
    widget.onCornersChanged?.call(List.unmodifiable(_points));
    if (notify) widget.onRotationChanged?.call(_rotationQuarterTurns);
    _viewportController.fitToView();
  }

  Size get _displayImageSize => _rotationQuarterTurns.isOdd
      ? Size(widget.imagePixelSize.height, widget.imagePixelSize.width)
      : widget.imagePixelSize;

  Size _containedSize(double availableWidth) {
    final naturalHeight =
        availableWidth * _displayImageSize.height / _displayImageSize.width;
    if (naturalHeight <= widget.maximumImageHeight) {
      return Size(availableWidth, naturalHeight);
    }
    final width =
        widget.maximumImageHeight *
        _displayImageSize.width /
        _displayImageSize.height;
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
  }

  @override
  bool shouldRepaint(covariant _AlignmentPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.colorScheme != colorScheme ||
      oldDelegate.isValid != isValid;
}

class _CornerMarker extends StatelessWidget {
  const _CornerMarker({
    required this.number,
    required this.isValid,
    required this.selected,
  });

  final int number;
  final bool isValid;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isValid ? colors.primary : colors.error;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface.withValues(alpha: 0.94),
        border: Border.all(color: color, width: selected ? 5 : 3),
        boxShadow: selected ? [BoxShadow(color: color, blurRadius: 8)] : null,
      ),
      child: Text(
        '$number',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RotationControls extends StatelessWidget {
  const _RotationControls({
    required this.rotationQuarterTurns,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onReset,
  });

  final int rotationQuarterTurns;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Fotostand ${rotationQuarterTurns * 90} graden',
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton.outlined(
          tooltip: '90 graden linksom',
          onPressed: onRotateLeft,
          icon: const Icon(Icons.rotate_left),
        ),
        IconButton.outlined(
          tooltip: '90 graden rechtsom',
          onPressed: onRotateRight,
          icon: const Icon(Icons.rotate_right),
        ),
        TextButton.icon(
          onPressed: rotationQuarterTurns == 0 ? null : onReset,
          icon: const Icon(Icons.photo_size_select_actual_outlined),
          label: const Text('Originele stand'),
        ),
      ],
    ),
  );
}
