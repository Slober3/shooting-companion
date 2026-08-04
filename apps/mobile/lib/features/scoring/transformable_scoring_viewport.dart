import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum CanvasAccessMode { editable, readOnly }

enum ScoringTool { place, edit }

class ScoringViewportMarker {
  const ScoringViewportMarker({
    required this.id,
    required this.normalizedPosition,
    required this.child,
    required this.semanticsLabel,
    this.selectionPriority = 0,
  });

  final String id;
  final Offset normalizedPosition;
  final Widget child;
  final String semanticsLabel;
  final int selectionPriority;
}

class ScoringViewportController extends ChangeNotifier {
  ScoringViewportController() {
    transformationController.addListener(_notifyTransformChanged);
  }

  final TransformationController transformationController =
      TransformationController();

  Size _viewportSize = Size.zero;
  Rect _contentRect = Rect.zero;
  Map<String, Offset> _impactPositions = const {};
  VoidCallback? _cancelInteraction;

  double get scale => transformationController.value.getMaxScaleOnAxis();
  Size get viewportSize => _viewportSize;
  Rect get contentRect => _contentRect;

  void attach({
    required Size viewportSize,
    required Rect contentRect,
    Iterable<ScoringViewportMarker> markers = const [],
    VoidCallback? cancelInteraction,
  }) {
    _viewportSize = viewportSize;
    _contentRect = contentRect;
    _impactPositions = {
      for (final marker in markers) marker.id: marker.normalizedPosition,
    };
    _cancelInteraction = cancelInteraction;
  }

  /// Stops an in-progress marker gesture before lifecycle or persistence work.
  /// Late pointer events are ignored by the viewport after this call.
  void cancelInteraction() => _cancelInteraction?.call();

  void detachInteraction(VoidCallback callback) {
    if (_cancelInteraction == callback) _cancelInteraction = null;
  }

  Offset viewportToScene(Offset viewportPosition) =>
      transformationController.toScene(viewportPosition);

  Offset sceneToViewport(Offset scenePosition) =>
      MatrixUtils.transformPoint(transformationController.value, scenePosition);

  Offset? viewportToNormalized(Offset viewportPosition) {
    if (_contentRect.isEmpty) return null;
    final scene = viewportToScene(viewportPosition);
    if (scene.dx < _contentRect.left ||
        scene.dx > _contentRect.right ||
        scene.dy < _contentRect.top ||
        scene.dy > _contentRect.bottom) {
      return null;
    }
    return Offset(
      ((scene.dx - _contentRect.left) / _contentRect.width)
          .clamp(0.0, 1.0)
          .toDouble(),
      ((scene.dy - _contentRect.top) / _contentRect.height)
          .clamp(0.0, 1.0)
          .toDouble(),
    );
  }

  Offset normalizedToViewport(Offset normalized) {
    final scene = Offset(
      _contentRect.left + normalized.dx * _contentRect.width,
      _contentRect.top + normalized.dy * _contentRect.height,
    );
    return sceneToViewport(scene);
  }

  Offset? get viewportCenterNormalized =>
      viewportToNormalized(_viewportSize.center(Offset.zero));

  void fitToView() {
    transformationController.value = Matrix4.identity();
  }

  void zoomIn() => _zoomTo((scale * 1.5).clamp(1.0, 8.0).toDouble());

  void zoomOut() => _zoomTo((scale / 1.5).clamp(1.0, 8.0).toDouble());

  void panByViewportDelta(Offset delta) {
    if (_viewportSize.isEmpty || scale <= 1) return;
    final matrix = transformationController.value.clone();
    final maximumX = 48.0;
    final maximumY = 48.0;
    final minimumX = _viewportSize.width - _viewportSize.width * scale - 48;
    final minimumY = _viewportSize.height - _viewportSize.height * scale - 48;
    matrix.setEntry(
      0,
      3,
      (matrix.storage[12] + delta.dx).clamp(minimumX, maximumX).toDouble(),
    );
    matrix.setEntry(
      1,
      3,
      (matrix.storage[13] + delta.dy).clamp(minimumY, maximumY).toDouble(),
    );
    transformationController.value = matrix;
  }

  void focusNormalized(Offset normalized, {double minimumScale = 3}) {
    if (_viewportSize.isEmpty || _contentRect.isEmpty) return;
    final targetScale = math
        .max(scale, minimumScale)
        .clamp(1.0, 8.0)
        .toDouble();
    final scene = Offset(
      _contentRect.left + normalized.dx * _contentRect.width,
      _contentRect.top + normalized.dy * _contentRect.height,
    );
    _setTransform(
      scale: targetScale,
      sceneFocus: scene,
      viewportFocus: _viewportSize.center(Offset.zero),
    );
  }

  void focusImpact(String impactId, {double minimumScale = 3}) {
    final normalized = _impactPositions[impactId];
    if (normalized != null) {
      focusNormalized(normalized, minimumScale: minimumScale);
    }
  }

  void _zoomTo(double targetScale) {
    if (_viewportSize.isEmpty) return;
    final viewportFocus = _viewportSize.center(Offset.zero);
    final sceneFocus = viewportToScene(viewportFocus);
    _setTransform(
      scale: targetScale,
      sceneFocus: sceneFocus,
      viewportFocus: viewportFocus,
    );
  }

  void _setTransform({
    required double scale,
    required Offset sceneFocus,
    required Offset viewportFocus,
  }) {
    final matrix = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, viewportFocus.dx - sceneFocus.dx * scale)
      ..setEntry(1, 3, viewportFocus.dy - sceneFocus.dy * scale);
    transformationController.value = matrix;
  }

  void _notifyTransformChanged() => notifyListeners();

  @override
  void dispose() {
    transformationController.removeListener(_notifyTransformChanged);
    transformationController.dispose();
    super.dispose();
  }
}

typedef ViewportContentBuilder =
    Widget Function(BuildContext context, Size contentSize, double zoom);

class TransformableScoringViewport extends StatefulWidget {
  const TransformableScoringViewport({
    required this.aspectRatio,
    required this.contentBuilder,
    required this.markers,
    required this.accessMode,
    required this.tool,
    this.controller,
    this.onBackgroundTap,
    this.onMarkerSelected,
    this.onMarkerDragStart,
    this.onMarkerMoved,
    this.onMarkerDragEnd,
    this.onMarkerDragCancel,
    this.onInvalidPosition,
    this.precisionMode = false,
    this.showControls = true,
    super.key,
  }) : assert(aspectRatio > 0);

  final double aspectRatio;
  final ViewportContentBuilder contentBuilder;
  final List<ScoringViewportMarker> markers;
  final CanvasAccessMode accessMode;
  final ScoringTool tool;
  final ScoringViewportController? controller;
  final ValueChanged<Offset>? onBackgroundTap;
  final ValueChanged<String>? onMarkerSelected;
  final ValueChanged<String>? onMarkerDragStart;
  final void Function(String id, Offset normalizedPosition)? onMarkerMoved;
  final ValueChanged<String>? onMarkerDragEnd;
  final ValueChanged<String>? onMarkerDragCancel;
  final VoidCallback? onInvalidPosition;
  final bool precisionMode;
  final bool showControls;

  @override
  State<TransformableScoringViewport> createState() =>
      _TransformableScoringViewportState();
}

class _TransformableScoringViewportState
    extends State<TransformableScoringViewport> {
  ScoringViewportController? _ownedController;
  final _viewportKey = GlobalKey();
  String? _draggingMarkerId;
  int? _markerDragPointer;
  Offset? _markerPointerDownPosition;
  bool _markerDragStarted = false;
  bool _suppressNextBackgroundTap = false;
  final Set<int> _activePointers = <int>{};
  bool _multiTouchActive = false;
  int? _scenePanPointer;
  Offset? _scenePanDownPosition;
  Offset? _scenePanLastPosition;
  bool _scenePanStarted = false;

  ScoringViewportController get _controller =>
      widget.controller ?? (_ownedController ??= ScoringViewportController());

  @override
  void didUpdateWidget(covariant TransformableScoringViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detachInteraction(_cancelPointerInteraction);
    }
    if (oldWidget.controller == null && widget.controller != null) {
      _ownedController?.dispose();
      _ownedController = null;
    }
  }

  @override
  void dispose() {
    widget.controller?.detachInteraction(_cancelPointerInteraction);
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 320,
        );
        final contentRect = _containedRect(viewportSize, widget.aspectRatio);
        _controller.attach(
          viewportSize: viewportSize,
          contentRect: contentRect,
          markers: widget.markers,
          cancelInteraction: _cancelPointerInteraction,
        );
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => ClipRect(
            child: SizedBox.fromSize(
              key: _viewportKey,
              size: viewportSize,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _handlePointerDown,
                      onPointerMove: _handlePointerMove,
                      onPointerUp: _handlePointerEnded,
                      onPointerCancel: _handlePointerCanceled,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp:
                            widget.accessMode == CanvasAccessMode.editable &&
                                !widget.precisionMode
                            ? (details) =>
                                  _handleBackgroundTap(details.localPosition)
                            : null,
                        child: InteractiveViewer(
                          transformationController:
                              _controller.transformationController,
                          minScale: 1,
                          maxScale: 8,
                          panEnabled:
                              !(widget.accessMode ==
                                      CanvasAccessMode.editable &&
                                  widget.tool == ScoringTool.edit),
                          boundaryMargin: const EdgeInsets.all(48),
                          constrained: true,
                          child: SizedBox.fromSize(
                            size: viewportSize,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fromRect(
                                  rect: contentRect,
                                  child: widget.contentBuilder(
                                    context,
                                    contentRect.size,
                                    _controller.scale,
                                  ),
                                ),
                                for (final marker in widget.markers)
                                  _buildMarker(context, marker, contentRect),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.precisionMode)
                    const Positioned.fill(
                      child: IgnorePointer(child: _PrecisionCrosshair()),
                    ),
                  if (widget.showControls)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _ZoomControls(controller: _controller),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarker(
    BuildContext context,
    ScoringViewportMarker marker,
    Rect contentRect,
  ) {
    final position = Offset(
      contentRect.left + marker.normalizedPosition.dx * contentRect.width,
      contentRect.top + marker.normalizedPosition.dy * contentRect.height,
    );
    final interactive =
        widget.accessMode == CanvasAccessMode.editable &&
        widget.tool == ScoringTool.edit;
    return Positioned(
      key: ValueKey('scoring-marker-${marker.id}'),
      left: position.dx - 24,
      top: position.dy - 24,
      width: 48,
      height: 48,
      child: Transform.scale(
        scale: 1 / _controller.scale,
        child: Semantics(
          label: marker.semanticsLabel,
          button: interactive,
          onTap: interactive
              ? () => widget.onMarkerSelected?.call(marker.id)
              : null,
          child: IgnorePointer(
            child: _CircularMarkerHitRegion(child: Center(child: marker.child)),
          ),
        ),
      ),
    );
  }

  ScoringViewportMarker? _nearestMarkerAtViewport(Offset local) {
    final candidates =
        [
          for (final marker in widget.markers)
            (
              marker: marker,
              distance:
                  (_controller.normalizedToViewport(marker.normalizedPosition) -
                          local)
                      .distance,
            ),
        ].where((candidate) => candidate.distance <= 24).toList()..sort((
          first,
          second,
        ) {
          final distance = first.distance.compareTo(second.distance);
          if (distance != 0) return distance;
          return second.marker.selectionPriority.compareTo(
            first.marker.selectionPriority,
          );
        });
    return candidates.firstOrNull?.marker;
  }

  void _finishMarkerDrag() {
    final id = _draggingMarkerId;
    final started = _markerDragStarted;
    _draggingMarkerId = null;
    _markerDragPointer = null;
    _markerPointerDownPosition = null;
    _markerDragStarted = false;
    _suppressNextBackgroundTap = false;
    if (id != null && started) widget.onMarkerDragEnd?.call(id);
  }

  void _cancelActiveMarkerDrag() {
    final id = _draggingMarkerId;
    final started = _markerDragStarted;
    _draggingMarkerId = null;
    _markerDragPointer = null;
    _markerPointerDownPosition = null;
    _markerDragStarted = false;
    _suppressNextBackgroundTap = false;
    if (id != null && started) widget.onMarkerDragCancel?.call(id);
  }

  void _cancelPointerInteraction() {
    final hadInteraction =
        _markerDragPointer != null ||
        _scenePanPointer != null ||
        _activePointers.isNotEmpty ||
        _multiTouchActive;
    _cancelActiveMarkerDrag();
    _clearScenePan();
    _activePointers.clear();
    _multiTouchActive = false;
    if (hadInteraction && mounted) setState(() {});
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointers.isEmpty) _suppressNextBackgroundTap = false;
    _activePointers.add(event.pointer);
    if (_activePointers.length > 1) {
      _multiTouchActive = true;
      _cancelActiveMarkerDrag();
      _clearScenePan();
      if (mounted) setState(() {});
      return;
    }
    if (widget.accessMode != CanvasAccessMode.editable ||
        widget.tool != ScoringTool.edit) {
      return;
    }
    final marker = _nearestMarkerAtViewport(event.localPosition);
    if (marker != null) {
      _markerDragPointer = event.pointer;
      _draggingMarkerId = marker.id;
      _markerPointerDownPosition = event.localPosition;
      _markerDragStarted = false;
      _suppressNextBackgroundTap = !widget.precisionMode;
      widget.onMarkerSelected?.call(marker.id);
      if (mounted) setState(() {});
    } else {
      _scenePanPointer = event.pointer;
      _scenePanDownPosition = event.localPosition;
      _scenePanLastPosition = event.localPosition;
      _scenePanStarted = false;
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_multiTouchActive) return;
    if (event.pointer == _scenePanPointer) {
      final downPosition = _scenePanDownPosition;
      final lastPosition = _scenePanLastPosition;
      if (downPosition == null || lastPosition == null) return;
      if (!_scenePanStarted &&
          (event.localPosition - downPosition).distance < kTouchSlop) {
        return;
      }
      _scenePanStarted = true;
      _suppressNextBackgroundTap = true;
      _controller.panByViewportDelta(event.localPosition - lastPosition);
      _scenePanLastPosition = event.localPosition;
      return;
    }
    if (event.pointer != _markerDragPointer) return;
    final id = _draggingMarkerId;
    if (id == null) return;
    final downPosition = _markerPointerDownPosition;
    if (!_markerDragStarted) {
      if (downPosition == null ||
          (event.localPosition - downPosition).distance < kTouchSlop) {
        return;
      }
      _markerDragStarted = true;
      _suppressNextBackgroundTap = false;
      widget.onMarkerDragStart?.call(id);
    }
    final normalized = _controller.viewportToNormalized(event.localPosition);
    if (normalized == null) {
      widget.onInvalidPosition?.call();
      return;
    }
    widget.onMarkerMoved?.call(id, normalized);
  }

  void _handlePointerEnded(PointerEvent event) {
    final wasMarkerPointer = event.pointer == _markerDragPointer;
    _activePointers.remove(event.pointer);
    if (wasMarkerPointer && !_multiTouchActive) {
      if (_markerDragStarted) {
        _finishMarkerDrag();
      } else {
        _draggingMarkerId = null;
        _markerDragPointer = null;
        _markerPointerDownPosition = null;
      }
    }
    if (event.pointer == _scenePanPointer) _clearScenePan();
    if (_activePointers.isEmpty) {
      _multiTouchActive = false;
      if (mounted) setState(() {});
    }
  }

  void _handlePointerCanceled(PointerEvent event) {
    if (event.pointer == _markerDragPointer) _cancelActiveMarkerDrag();
    if (event.pointer == _scenePanPointer) _clearScenePan();
    _handlePointerEnded(event);
  }

  void _clearScenePan() {
    _scenePanPointer = null;
    _scenePanDownPosition = null;
    _scenePanLastPosition = null;
    _scenePanStarted = false;
  }

  void _handleBackgroundTap(Offset localPosition) {
    if (_suppressNextBackgroundTap) {
      _suppressNextBackgroundTap = false;
      return;
    }
    if (widget.tool == ScoringTool.edit &&
        _nearestMarkerAtViewport(localPosition) != null) {
      return;
    }
    final normalized = _controller.viewportToNormalized(localPosition);
    if (normalized == null) {
      widget.onInvalidPosition?.call();
      return;
    }
    widget.onBackgroundTap?.call(normalized);
  }

  Rect _containedRect(Size viewport, double aspectRatio) {
    if (viewport.isEmpty) return Rect.zero;
    final viewportRatio = viewport.width / viewport.height;
    if (viewportRatio > aspectRatio) {
      final width = viewport.height * aspectRatio;
      return Rect.fromLTWH(
        (viewport.width - width) / 2,
        0,
        width,
        viewport.height,
      );
    }
    final height = viewport.width / aspectRatio;
    return Rect.fromLTWH(
      0,
      (viewport.height - height) / 2,
      viewport.width,
      height,
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.controller});

  final ScoringViewportController controller;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
    borderRadius: BorderRadius.circular(12),
    elevation: 2,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: controller.scale > 1.01 ? controller.zoomOut : null,
          tooltip: 'Uitzoomen',
          icon: const Icon(Icons.remove),
        ),
        IconButton(
          onPressed: controller.scale < 7.99 ? controller.zoomIn : null,
          tooltip: 'Inzoomen',
          icon: const Icon(Icons.add),
        ),
        IconButton(
          onPressed: controller.fitToView,
          tooltip: 'Passend maken',
          icon: const Icon(Icons.fit_screen_outlined),
        ),
      ],
    ),
  );
}

class _CircularMarkerHitRegion extends SingleChildRenderObjectWidget {
  const _CircularMarkerHitRegion({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCircularMarkerHitRegion();
}

class _RenderCircularMarkerHitRegion extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    final radius = size.shortestSide / 2;
    if ((position - size.center(Offset.zero)).distance > radius) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}

class _PrecisionCrosshair extends StatelessWidget {
  const _PrecisionCrosshair();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CrosshairPainter(Theme.of(context).colorScheme.primary),
  );
}

class _CrosshairPainter extends CustomPainter {
  const _CrosshairPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas
      ..drawCircle(center, 14, paint)
      ..drawLine(
        center - const Offset(24, 0),
        center + const Offset(24, 0),
        paint,
      )
      ..drawLine(
        center - const Offset(0, 24),
        center + const Offset(0, 24),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) =>
      oldDelegate.color != color;
}
