import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart';

import '../../widgets/app_notice.dart';
import '../scoring/transformable_scoring_viewport.dart';
import 'alignment_fine_tune_controls.dart';
import 'photo_overlay_canvas.dart';

/// Guided alignment for photos where the card corners are cropped but two
/// complete scoring rings remain visible.
class RingAssistedAlignmentEditor extends StatefulWidget {
  RingAssistedAlignmentEditor({
    required this.imageProvider,
    required this.imagePixelSize,
    required this.cardWidthMm,
    required this.cardHeightMm,
    required this.ringRadiiMm,
    required this.onConfirmed,
    this.initialAlignment,
    this.initialRotationQuarterTurns = 0,
    this.targetProfile,
    this.overlayOpacity = 0.72,
    this.maximumImageHeight = 560,
    this.onUseAsAttachment,
    this.onDraftChanged,
    super.key,
  }) : assert(imagePixelSize.width > 0),
       assert(imagePixelSize.height > 0),
       assert(cardWidthMm > 0),
       assert(cardHeightMm > 0),
       assert(ringRadiiMm.length >= 2),
       assert(ringRadiiMm.every((radius) => radius > 0)),
       assert(
         initialRotationQuarterTurns >= 0 && initialRotationQuarterTurns <= 3,
       );

  final ImageProvider<Object> imageProvider;
  final Size imagePixelSize;
  final double cardWidthMm;
  final double cardHeightMm;
  final List<double> ringRadiiMm;
  final ManualPhotoAlignment? initialAlignment;
  final int initialRotationQuarterTurns;
  final domain.TargetProfile? targetProfile;
  final double overlayOpacity;
  final double maximumImageHeight;
  final ValueChanged<ManualPhotoAlignment> onConfirmed;
  final VoidCallback? onUseAsAttachment;
  final void Function(List<NormalizedPoint> points, int rotationQuarterTurns)?
  onDraftChanged;

  @override
  State<RingAssistedAlignmentEditor> createState() =>
      _RingAssistedAlignmentEditorState();
}

class _RingAssistedAlignmentEditorState
    extends State<RingAssistedAlignmentEditor> {
  static const _steps = <String>[
    'richtpunt',
    'bovenrichting',
    'eerste ring boven',
    'eerste ring rechts',
    'eerste ring onder',
    'eerste ring links',
    'tweede ring boven',
    'tweede ring rechts',
    'tweede ring onder',
    'tweede ring links',
  ];

  final _viewportController = ScoringViewportController();
  late List<double> _availableRadii;
  late double _firstRadiusMm;
  late double _secondRadiusMm;
  late int _rotationQuarterTurns;
  List<NormalizedPoint> _points = const [];
  int? _selectedPointIndex;
  // Direct taps are the quickest default. Precision mode remains available
  // for zoomed, crosshair-based refinement of an anchor.
  bool _precisionMode = false;
  late double _overlayOpacity;
  bool _overlayAdjustmentMode = false;
  List<NormalizedPoint>? _refinementBaselinePoints;
  List<NormalizedPoint>? _gestureStartPoints;
  Offset? _gestureStartFocal;

  @override
  void initState() {
    super.initState();
    final initialRadii =
        widget.initialAlignment?.anchors
            .map((anchor) => anchor.ringRadiusMm)
            .whereType<double>() ??
        const <double>[];
    _availableRadii = {...widget.ringRadiiMm, ...initialRadii}.toList()
      ..sort((a, b) => b.compareTo(a));
    _firstRadiusMm = _availableRadii.first;
    _secondRadiusMm = _availableRadii[1];
    _rotationQuarterTurns = widget.initialRotationQuarterTurns;
    _overlayOpacity = widget.overlayOpacity.clamp(0.15, 1).toDouble();
    _loadInitialAlignment(widget.initialAlignment);
  }

  @override
  void didUpdateWidget(covariant RingAssistedAlignmentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.initialAlignment, widget.initialAlignment)) {
      _loadInitialAlignment(widget.initialAlignment);
    }
    if (oldWidget.overlayOpacity != widget.overlayOpacity) {
      _overlayOpacity = widget.overlayOpacity.clamp(0.15, 1).toDouble();
    }
  }

  @override
  void dispose() {
    _viewportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = _buildAlignment();
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_instruction(alignment), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        _buildRadiusSelectors(),
        const SizedBox(height: 12),
        _buildRotationControls(),
        if (_points.length == _steps.length) ...[
          const SizedBox(height: 12),
          AlignmentFineTuneControls(
            enabled: _overlayAdjustmentMode,
            opacity: _overlayOpacity,
            onEnabledChanged: _setOverlayAdjustmentMode,
            onTranslate: (dx, dy) =>
                _applyRefinement(translation: NormalizedPoint(dx, dy)),
            onScale: (scale) => _applyRefinement(scale: scale),
            onRotateDegrees: (degrees) =>
                _applyRefinement(rotationRadians: degrees * math.pi / 180),
            onOpacityChanged: (value) =>
                setState(() => _overlayOpacity = value),
            onReset: _resetRefinement,
          ),
        ],
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = _containedSize(constraints.maxWidth);
            return Center(
              child: SizedBox.fromSize(
                size: size,
                child: TransformableScoringViewport(
                  aspectRatio:
                      _displayImageSize.width / _displayImageSize.height,
                  controller: _viewportController,
                  accessMode: _overlayAdjustmentMode
                      ? CanvasAccessMode.readOnly
                      : CanvasAccessMode.editable,
                  tool: ScoringTool.edit,
                  precisionMode: _precisionMode,
                  viewportPanEnabled: !_overlayAdjustmentMode,
                  viewportScaleEnabled: !_overlayAdjustmentMode,
                  foregroundBuilder: _overlayAdjustmentMode
                      ? (context, contentSize) =>
                            AlignmentDirectManipulationLayer(
                              key: const ValueKey(
                                'ring-overlay-adjustment-gesture',
                              ),
                              onStart: (focal) =>
                                  _startOverlayGesture(focal, contentSize),
                              onUpdate: (update) =>
                                  _updateOverlayGesture(update, contentSize),
                              onEnd: _endOverlayGesture,
                            )
                      : null,
                  markers: [
                    for (var index = 0; index < _points.length; index++)
                      ScoringViewportMarker(
                        id: '$index',
                        normalizedPosition: Offset(
                          _points[index].x,
                          _points[index].y,
                        ),
                        semanticsLabel: 'Anker ${index + 1}, ${_steps[index]}',
                        selectionPriority: index,
                        child: _RingAnchorMarker(
                          number: index + 1,
                          selected: _selectedPointIndex == index,
                          valid: alignment != null,
                        ),
                      ),
                  ],
                  onBackgroundTap: _addPoint,
                  onMarkerSelected: (id) =>
                      setState(() => _selectedPointIndex = int.tryParse(id)),
                  onMarkerMoved: _movePoint,
                  contentBuilder: (_, contentSize, _) => Stack(
                    fit: StackFit.expand,
                    children: [
                      RotatedBox(
                        quarterTurns: _rotationQuarterTurns,
                        child: Image(
                          image: widget.imageProvider,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: theme.colorScheme.surfaceContainerHighest,
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
                          painter: _RingAssistedDraftPainter(
                            points: _points,
                            color: alignment == null
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      if (alignment != null)
                        PhotoAlignmentGeometryOverlay(
                          key: const ValueKey(
                            'ring-assisted-projected-target-overlay',
                          ),
                          alignment: alignment,
                          renderedRotationQuarterTurns: _rotationQuarterTurns,
                          targetProfile: widget.targetProfile,
                          opacity: _overlayOpacity,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (alignment != null) _RingAlignmentStatus(alignment: alignment),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            FilterChip(
              selected: _precisionMode,
              avatar: const Icon(Icons.center_focus_strong, size: 18),
              label: const Text('Precisie'),
              onSelected: (value) => setState(() => _precisionMode = value),
            ),
            if (_precisionMode)
              FilledButton.tonalIcon(
                onPressed:
                    _points.length < _steps.length ||
                        _selectedPointIndex != null
                    ? _placeAtCrosshair
                    : null,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: Text(
                  _points.length < _steps.length
                      ? 'Anker vastleggen'
                      : 'Anker verplaatsen',
                ),
              ),
            TextButton.icon(
              onPressed: _points.isEmpty ? null : _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Opnieuw'),
            ),
            if (widget.onUseAsAttachment != null)
              TextButton.icon(
                onPressed: widget.onUseAsAttachment,
                icon: const Icon(Icons.attach_file),
                label: const Text('Alleen als foto bewaren'),
              ),
            FilledButton.icon(
              onPressed: alignment == null
                  ? null
                  : () => widget.onConfirmed(alignment),
              icon: const Icon(Icons.check),
              label: const Text('Uitlijning klopt'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadiusSelectors() => LayoutBuilder(
    builder: (context, constraints) {
      final stack =
          constraints.maxWidth < 420 ||
          MediaQuery.textScalerOf(context).scale(1) >= 1.3;
      final first = _radiusSelector(
        label: 'Eerste ring',
        value: _firstRadiusMm,
        onChanged: (value) => setState(() => _firstRadiusMm = value),
      );
      final second = _radiusSelector(
        label: 'Tweede ring',
        value: _secondRadiusMm,
        onChanged: (value) => setState(() => _secondRadiusMm = value),
      );
      if (stack) {
        return Column(children: [first, const SizedBox(height: 12), second]);
      }
      return Row(
        children: [
          Expanded(child: first),
          const SizedBox(width: 12),
          Expanded(child: second),
        ],
      );
    },
  );

  Widget _radiusSelector({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) => DropdownButtonFormField<double>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final radius in _availableRadii)
        DropdownMenuItem(
          value: radius,
          child: Text(
            'Ø ${(radius * 2).toStringAsFixed(1)} mm',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ],
    onChanged: (selected) {
      if (selected != null) onChanged(selected);
    },
  );

  Widget _buildRotationControls() => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      IconButton.outlined(
        tooltip: '90 graden linksom',
        onPressed: () => _setRotation(_rotationQuarterTurns - 1),
        icon: const Icon(Icons.rotate_left),
      ),
      IconButton.outlined(
        tooltip: '90 graden rechtsom',
        onPressed: () => _setRotation(_rotationQuarterTurns + 1),
        icon: const Icon(Icons.rotate_right),
      ),
      TextButton.icon(
        onPressed: _rotationQuarterTurns == 0 ? null : () => _setRotation(0),
        icon: const Icon(Icons.photo_size_select_actual_outlined),
        label: const Text('Originele stand'),
      ),
    ],
  );

  ManualPhotoAlignment? _buildAlignment() {
    if (_points.length != _steps.length || _firstRadiusMm == _secondRadiusMm) {
      return null;
    }
    try {
      return ManualPhotoAlignment.buildRingAssisted(
        center: _points[0],
        topDirection: _points[1],
        ringSeries: [
          RingAnchorSeries(
            id: 'ring-1',
            radiusMm: _firstRadiusMm,
            top: _points[2],
            right: _points[3],
            bottom: _points[4],
            left: _points[5],
          ),
          RingAnchorSeries(
            id: 'ring-2',
            radiusMm: _secondRadiusMm,
            top: _points[6],
            right: _points[7],
            bottom: _points[8],
            left: _points[9],
          ),
        ],
        cardWidthMm: widget.cardWidthMm,
        cardHeightMm: widget.cardHeightMm,
        rotationQuarterTurns: _rotationQuarterTurns,
      ).alignment;
    } on ArgumentError {
      return null;
    } on StateError {
      return null;
    }
  }

  String _instruction(ManualPhotoAlignment? alignment) {
    if (_firstRadiusMm == _secondRadiusMm) {
      return 'Kies twee verschillende zichtbare scoringsringen.';
    }
    if (_points.length < _steps.length) {
      return 'Stap ${_points.length + 1}/${_steps.length}: duid ${_steps[_points.length]} aan.';
    }
    if (alignment == null) {
      return 'De ringankers leveren nog geen stabiele uitlijning. Verfijn de punten.';
    }
    return 'Controleer de geprojecteerde ringen en bevestig alleen als ze samenvallen.';
  }

  void _addPoint(Offset normalized) {
    if (_points.length >= _steps.length) return;
    setState(() {
      _points = [..._points, NormalizedPoint(normalized.dx, normalized.dy)];
    });
    _notifyDraft();
  }

  void _movePoint(String id, Offset normalized) {
    final index = int.tryParse(id);
    if (index == null || index < 0 || index >= _points.length) return;
    final updated = [..._points];
    updated[index] = NormalizedPoint(normalized.dx, normalized.dy);
    setState(() {
      _points = updated;
      _selectedPointIndex = index;
    });
    _notifyDraft();
  }

  void _placeAtCrosshair() {
    final normalized = _viewportController.viewportCenterNormalized;
    if (normalized == null) {
      AppMessenger.warning(context, 'Het precisiekruis ligt buiten de foto.');
      return;
    }
    if (_points.length < _steps.length) {
      _addPoint(normalized);
    } else if (_selectedPointIndex case final index?) {
      _movePoint('$index', normalized);
    }
  }

  void _setRotation(int requested) {
    final modulo = requested % 4;
    final next = modulo < 0 ? modulo + 4 : modulo;
    if (next == _rotationQuarterTurns) return;
    final old = _rotationQuarterTurns;
    setState(() {
      _rotationQuarterTurns = next;
      _points = _points
          .map(
            (point) => rotateNormalizedPoint(
              unrotateNormalizedPoint(point, old),
              next,
            ),
          )
          .toList(growable: false);
    });
    _notifyDraft();
    _viewportController.fitToView();
  }

  void _reset() {
    setState(() {
      _points = const [];
      _selectedPointIndex = null;
    });
    _notifyDraft();
  }

  void _setOverlayAdjustmentMode(bool enabled) {
    setState(() {
      _overlayAdjustmentMode = enabled;
      _precisionMode = false;
      _selectedPointIndex = null;
      if (enabled) {
        _refinementBaselinePoints = List.unmodifiable(_points);
      }
    });
  }

  void _applyRefinement({
    NormalizedPoint translation = const NormalizedPoint(0, 0),
    double scale = 1,
    double rotationRadians = 0,
  }) {
    if (_points.length != _steps.length) return;
    final transformed = AlignmentRefinementTransform(
      pivot: AlignmentRefinementTransform.centroid(_points),
      translation: translation,
      scale: scale,
      rotationRadians: rotationRadians,
    ).applyAll(_points);
    _acceptRefinedPoints(transformed);
  }

  void _startOverlayGesture(Offset focalPoint, Size contentSize) {
    _gestureStartPoints = List.unmodifiable(_points);
    _gestureStartFocal = focalPoint;
  }

  void _updateOverlayGesture(
    AlignmentManipulationUpdate update,
    Size contentSize,
  ) {
    final startPoints = _gestureStartPoints;
    final startFocal = _gestureStartFocal;
    if (startPoints == null || startFocal == null || contentSize.isEmpty) {
      return;
    }
    final pivot = NormalizedPoint(
      startFocal.dx / contentSize.width,
      startFocal.dy / contentSize.height,
    );
    final translation = NormalizedPoint(
      (update.focalPoint.dx - startFocal.dx) / contentSize.width,
      (update.focalPoint.dy - startFocal.dy) / contentSize.height,
    );
    final transformed = AlignmentRefinementTransform(
      pivot: pivot,
      translation: translation,
      scale: update.scale.clamp(0.5, 2).toDouble(),
      rotationRadians: update.rotationRadians,
    ).applyAll(startPoints);
    _acceptRefinedPoints(transformed);
  }

  void _endOverlayGesture() {
    _gestureStartPoints = null;
    _gestureStartFocal = null;
  }

  void _resetRefinement() {
    final baseline = _refinementBaselinePoints;
    if (baseline == null) return;
    _acceptRefinedPoints(baseline);
  }

  bool _acceptRefinedPoints(List<NormalizedPoint> points) {
    if (points.length != _steps.length ||
        points.any((point) => !point.isInsideImage)) {
      return false;
    }
    final previous = _points;
    _points = List.unmodifiable(points);
    final valid = _buildAlignment() != null;
    _points = previous;
    if (!valid) return false;
    setState(() => _points = List.unmodifiable(points));
    _notifyDraft();
    return true;
  }

  void _loadInitialAlignment(ManualPhotoAlignment? alignment) {
    if (alignment == null ||
        alignment.alignmentMode != PhotoAlignmentMode.ringAssisted) {
      return;
    }

    PhotoAlignmentAnchor? anchor(PhotoAlignmentAnchorRole role) {
      for (final candidate in alignment.anchors) {
        if (candidate.role == role) return candidate;
      }
      return null;
    }

    final center = anchor(PhotoAlignmentAnchorRole.targetCenter);
    final topDirection = anchor(PhotoAlignmentAnchorRole.topDirection);
    final grouped = <String, List<PhotoAlignmentAnchor>>{};
    for (final candidate in alignment.anchors) {
      final seriesId = candidate.seriesId;
      if (seriesId == null || candidate.ringRadiusMm == null) continue;
      grouped.putIfAbsent(seriesId, () => []).add(candidate);
    }
    final series =
        grouped.entries.where((entry) => entry.value.length >= 4).toList()
          ..sort((left, right) {
            final leftRadius = left.value.first.ringRadiusMm!;
            final rightRadius = right.value.first.ringRadiusMm!;
            return rightRadius.compareTo(leftRadius);
          });
    if (center == null || topDirection == null || series.length < 2) return;

    List<NormalizedPoint>? orderedPoints(List<PhotoAlignmentAnchor> anchors) {
      PhotoAlignmentAnchor? byRole(PhotoAlignmentAnchorRole role) {
        for (final candidate in anchors) {
          if (candidate.role == role) return candidate;
        }
        return null;
      }

      final top = byRole(PhotoAlignmentAnchorRole.ringTop);
      final right = byRole(PhotoAlignmentAnchorRole.ringRight);
      final bottom = byRole(PhotoAlignmentAnchorRole.ringBottom);
      final left = byRole(PhotoAlignmentAnchorRole.ringLeft);
      if (top == null || right == null || bottom == null || left == null) {
        return null;
      }
      return [
        top.sourcePoint,
        right.sourcePoint,
        bottom.sourcePoint,
        left.sourcePoint,
      ];
    }

    final firstPoints = orderedPoints(series[0].value);
    final secondPoints = orderedPoints(series[1].value);
    if (firstPoints == null || secondPoints == null) return;

    _rotationQuarterTurns = alignment.rotationQuarterTurns;
    _firstRadiusMm = series[0].value.first.ringRadiusMm!;
    _secondRadiusMm = series[1].value.first.ringRadiusMm!;
    _points = [
      center.sourcePoint,
      topDirection.sourcePoint,
      ...firstPoints,
      ...secondPoints,
    ];
    _selectedPointIndex = null;
  }

  void _notifyDraft() => widget.onDraftChanged?.call(
    List.unmodifiable(_points),
    _rotationQuarterTurns,
  );

  Size get _displayImageSize => _rotationQuarterTurns.isOdd
      ? Size(widget.imagePixelSize.height, widget.imagePixelSize.width)
      : widget.imagePixelSize;

  Size _containedSize(double availableWidth) {
    final height =
        availableWidth * _displayImageSize.height / _displayImageSize.width;
    if (height <= widget.maximumImageHeight) {
      return Size(availableWidth, height);
    }
    return Size(
      math.min(
        availableWidth,
        widget.maximumImageHeight *
            _displayImageSize.width /
            _displayImageSize.height,
      ),
      widget.maximumImageHeight,
    );
  }
}

class _RingAlignmentStatus extends StatelessWidget {
  const _RingAlignmentStatus({required this.alignment});

  final ManualPhotoAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final residuals = alignment.residuals;
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          const Icon(Icons.rule_folder_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'RMS ${residuals.rmsMm.toStringAsFixed(2)} mm · maximum ${residuals.maximumMm.toStringAsFixed(2)} mm · ${alignment.quality.name}',
            ),
          ),
        ],
      ),
    );
  }
}

class _RingAnchorMarker extends StatelessWidget {
  const _RingAnchorMarker({
    required this.number,
    required this.selected,
    required this.valid,
  });

  final int number;
  final bool selected;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = valid ? colors.primary : colors.error;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface.withValues(alpha: 0.94),
        border: Border.all(color: color, width: selected ? 5 : 3),
      ),
      child: Text(
        '$number',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RingAssistedDraftPainter extends CustomPainter {
  const _RingAssistedDraftPainter({required this.points, required this.color});

  final List<NormalizedPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    Offset render(NormalizedPoint point) =>
        Offset(point.x * size.width, point.y * size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.85);
    if (points.length >= 2) {
      canvas.drawLine(render(points[0]), render(points[1]), paint);
    }
    for (final start in const [2, 6]) {
      if (points.length <= start) continue;
      final available = math.min(4, points.length - start);
      final path = Path();
      for (var index = 0; index < available; index++) {
        final point = render(points[start + index]);
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      if (available == 4) path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingAssistedDraftPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
