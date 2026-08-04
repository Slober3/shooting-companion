import 'package:flutter/material.dart';
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
    this.title = 'Kaartfoto',
    this.initiallyShowOverlay = true,
    super.key,
  });

  final ImageProvider<Object> imageProvider;
  final Size imagePixelSize;
  final ManualPhotoAlignment alignment;
  final List<PhotoCanvasImpact> impacts;
  final double projectileDiameterMm;
  final String title;
  final bool initiallyShowOverlay;

  @override
  State<PhotoOverlayViewer> createState() => _PhotoOverlayViewerState();
}

class _PhotoOverlayViewerState extends State<PhotoOverlayViewer> {
  final _viewportController = ScoringViewportController();
  late bool _showOverlay;

  @override
  void initState() {
    super.initState();
    _showOverlay = widget.initiallyShowOverlay;
  }

  @override
  void dispose() {
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
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: PhotoOverlayCanvas(
            imageProvider: widget.imageProvider,
            imagePixelSize: widget.imagePixelSize,
            alignment: widget.alignment,
            impacts: widget.impacts,
            projectileDiameterMm: widget.projectileDiameterMm,
            showOverlay: _showOverlay,
            accessMode: CanvasAccessMode.readOnly,
            viewportController: _viewportController,
          ),
        ),
      ),
    );
  }
}
