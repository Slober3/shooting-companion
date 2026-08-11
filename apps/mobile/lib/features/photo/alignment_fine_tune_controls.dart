import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AlignmentManipulationUpdate {
  const AlignmentManipulationUpdate({
    required this.focalPoint,
    required this.scale,
    required this.rotationRadians,
  });

  final Offset focalPoint;
  final double scale;
  final double rotationRadians;
}

/// Raw multi-pointer manipulation that eagerly owns the gesture while the
/// explicit overlay tool is active. This prevents the surrounding form from
/// scrolling and prevents the photo viewport from panning underneath it.
class AlignmentDirectManipulationLayer extends StatefulWidget {
  const AlignmentDirectManipulationLayer({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    this.semanticLabel = 'Overlay aanpassen met slepen, knijpen en draaien',
    super.key,
  });

  final ValueChanged<Offset> onStart;
  final ValueChanged<AlignmentManipulationUpdate> onUpdate;
  final VoidCallback onEnd;
  final String semanticLabel;

  @override
  State<AlignmentDirectManipulationLayer> createState() =>
      _AlignmentDirectManipulationLayerState();
}

class _AlignmentDirectManipulationLayerState
    extends State<AlignmentDirectManipulationLayer> {
  final Map<int, Offset> _current = {};
  Map<int, Offset> _start = const {};

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticLabel,
    child: RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        EagerGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
              EagerGestureRecognizer.new,
              (_) {},
            ),
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _pointerDown,
        onPointerMove: _pointerMove,
        onPointerUp: _pointerEnd,
        onPointerCancel: _pointerEnd,
      ),
    ),
  );

  void _pointerDown(PointerDownEvent event) {
    _current[event.pointer] = event.localPosition;
    _restartBaseline();
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!_current.containsKey(event.pointer)) return;
    _current[event.pointer] = event.localPosition;
    final ids = _current.keys.where(_start.containsKey).take(2).toList();
    if (ids.isEmpty) return;
    final startFocal = _focal(_start, ids);
    final currentFocal = _focal(_current, ids);
    var scale = 1.0;
    var rotation = 0.0;
    if (ids.length == 2) {
      final startVector = _start[ids[1]]! - _start[ids[0]]!;
      final currentVector = _current[ids[1]]! - _current[ids[0]]!;
      if (startVector.distance > 1e-6 && currentVector.distance > 1e-6) {
        scale = currentVector.distance / startVector.distance;
        rotation = currentVector.direction - startVector.direction;
      }
    }
    widget.onUpdate(
      AlignmentManipulationUpdate(
        focalPoint: currentFocal,
        scale: scale,
        rotationRadians: rotation,
      ),
    );
    // Keep startFocal read to document that translation is represented by the
    // difference between the callback's focal point and onStart's focal point.
    assert(startFocal.isFinite);
  }

  void _pointerEnd(PointerEvent event) {
    _current.remove(event.pointer);
    if (_current.isEmpty) {
      _start = const {};
      widget.onEnd();
    } else {
      _restartBaseline();
    }
  }

  void _restartBaseline() {
    _start = Map.unmodifiable(_current);
    widget.onStart(_focal(_start, _start.keys.take(2).toList()));
  }

  Offset _focal(Map<int, Offset> values, List<int> ids) {
    var result = Offset.zero;
    for (final id in ids) {
      result += values[id]!;
    }
    return result / ids.length.toDouble();
  }
}

/// Shared controls for moving the actual alignment anchors as one overlay.
/// Individual anchor handles remain available for perspective corrections.
class AlignmentFineTuneControls extends StatelessWidget {
  const AlignmentFineTuneControls({
    required this.enabled,
    required this.opacity,
    required this.onEnabledChanged,
    required this.onTranslate,
    required this.onScale,
    required this.onRotateDegrees,
    required this.onOpacityChanged,
    required this.onReset,
    super.key,
  });

  final bool enabled;
  final double opacity;
  final ValueChanged<bool> onEnabledChanged;
  final void Function(double dx, double dy) onTranslate;
  final ValueChanged<double> onScale;
  final ValueChanged<double> onRotateDegrees;
  final ValueChanged<double> onOpacityChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: onEnabledChanged,
              title: const Text('Overlay aanpassen'),
              subtitle: Text(
                enabled
                    ? 'Sleep met één vinger; knijp of draai met twee vingers. Gebruik de hoekpunten voor perspectief.'
                    : 'Zoom en verschuif de foto zonder de uitlijning te wijzigen.',
              ),
              secondary: const Icon(Icons.tune),
            ),
            if (enabled) ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _control(
                    tooltip: 'Overlay naar links',
                    icon: Icons.arrow_left,
                    onPressed: () => onTranslate(-0.0025, 0),
                  ),
                  _control(
                    tooltip: 'Overlay omhoog',
                    icon: Icons.arrow_drop_up,
                    onPressed: () => onTranslate(0, -0.0025),
                  ),
                  _control(
                    tooltip: 'Overlay omlaag',
                    icon: Icons.arrow_drop_down,
                    onPressed: () => onTranslate(0, 0.0025),
                  ),
                  _control(
                    tooltip: 'Overlay naar rechts',
                    icon: Icons.arrow_right,
                    onPressed: () => onTranslate(0.0025, 0),
                  ),
                  _control(
                    tooltip: 'Overlay kleiner',
                    icon: Icons.zoom_out_map,
                    onPressed: () => onScale(0.995),
                  ),
                  _control(
                    tooltip: 'Overlay groter',
                    icon: Icons.zoom_in_map,
                    onPressed: () => onScale(1.005),
                  ),
                  _control(
                    tooltip: 'Overlay 0,25 graden linksom',
                    icon: Icons.rotate_left,
                    onPressed: () => onRotateDegrees(-0.25),
                  ),
                  _control(
                    tooltip: 'Overlay 0,25 graden rechtsom',
                    icon: Icons.rotate_right,
                    onPressed: () => onRotateDegrees(0.25),
                  ),
                  TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Herstel'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Semantics(
                label:
                    'Doorzichtigheid overlay ${(opacity * 100).round()} procent',
                slider: true,
                child: Row(
                  children: [
                    const Icon(Icons.opacity, size: 20),
                    const SizedBox(width: 8),
                    if (textScale < 1.5) const Text('Overlay'),
                    Expanded(
                      child: Slider(
                        value: opacity.clamp(0.15, 1),
                        min: 0.15,
                        max: 1,
                        divisions: 17,
                        label: '${(opacity * 100).round()}%',
                        onChanged: onOpacityChanged,
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text('${(opacity * 100).round()}%'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _control({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) => IconButton.outlined(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
  );
}
