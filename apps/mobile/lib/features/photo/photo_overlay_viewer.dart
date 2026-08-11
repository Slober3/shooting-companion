import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart';

import '../scoring/transformable_scoring_viewport.dart';
import 'photo_canvas_models.dart';
import 'photo_overlay_canvas.dart';

/// Full-screen, read-only target photo viewer with persistent overlay control.
class PhotoOverlayViewer extends StatefulWidget {
  const PhotoOverlayViewer({
    required this.imageProvider,
    required this.imagePixelSize,
    required this.alignment,
    required this.impacts,
    this.projectileDiameterMm = 0,
    this.targetProfile,
    this.title = 'Kaartfoto',
    this.initiallyShowOverlay = true,
    super.key,
  });

  final ImageProvider<Object> imageProvider;
  final Size imagePixelSize;
  final ManualPhotoAlignment alignment;
  final List<PhotoCanvasImpact> impacts;
  final double projectileDiameterMm;
  final domain.TargetProfile? targetProfile;
  final String title;
  final bool initiallyShowOverlay;

  @override
  State<PhotoOverlayViewer> createState() => _PhotoOverlayViewerState();
}

class _PhotoOverlayViewerState extends State<PhotoOverlayViewer> {
  final _viewportController = ScoringViewportController();
  late bool _showOverlay;
  double _overlayOpacity = 0.72;
  late int _displayRotationQuarterTurns;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _showOverlay = widget.initiallyShowOverlay;
    _displayRotationQuarterTurns = widget.alignment.rotationQuarterTurns;
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _viewportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Foto en overlay vergelijken',
            onPressed: _blinkOverlay,
            icon: const Icon(Icons.compare_outlined),
          ),
          PopupMenuButton<int>(
            tooltip: 'Foto draaien',
            icon: const Icon(Icons.screen_rotation_outlined),
            onSelected: (value) => _setDisplayRotation(
              value == 0 ? 0 : (_displayRotationQuarterTurns + value) % 4,
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: -1, child: Text('90 graden linksom')),
              PopupMenuItem(value: 1, child: Text('90 graden rechtsom')),
              PopupMenuItem(value: 0, child: Text('Originele stand')),
            ],
          ),
          IconButton(
            tooltip: _showOverlay ? 'Overlay verbergen' : 'Overlay tonen',
            onPressed: () => setState(() => _showOverlay = !_showOverlay),
            icon: Icon(
              _showOverlay ? Icons.layers : Icons.layers_clear_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Weergave herstellen',
            onPressed: _viewportController.fitToView,
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: PhotoOverlayCanvas(
                  imageProvider: widget.imageProvider,
                  imagePixelSize: widget.imagePixelSize,
                  alignment: widget.alignment,
                  impacts: widget.impacts,
                  projectileDiameterMm: widget.projectileDiameterMm,
                  targetProfile: widget.targetProfile,
                  overlayOpacity: _overlayOpacity,
                  displayRotationQuarterTurns: _displayRotationQuarterTurns,
                  showOverlay: _showOverlay,
                  accessMode: CanvasAccessMode.readOnly,
                  viewportController: _viewportController,
                ),
              ),
            ),
            if (_showOverlay)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.opacity_outlined),
                    Expanded(
                      child: Slider(
                        value: _overlayOpacity,
                        min: 0.15,
                        max: 1,
                        divisions: 17,
                        label: '${(_overlayOpacity * 100).round()}%',
                        onChanged: (value) =>
                            setState(() => _overlayOpacity = value),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _blinkOverlay() {
    _blinkTimer?.cancel();
    setState(() => _showOverlay = false);
    _blinkTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showOverlay = true);
    });
  }

  void _setDisplayRotation(int requested) {
    final normalized = requested % 4;
    setState(
      () => _displayRotationQuarterTurns = normalized < 0
          ? normalized + 4
          : normalized,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _viewportController.fitToView();
    });
  }
}
