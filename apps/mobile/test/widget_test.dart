import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion/features/photo/photo_canvas_models.dart';
import 'package:shooting_companion/features/photo/photo_overlay_canvas.dart';
import 'package:shooting_companion/features/scoring/target_canvas.dart';
import 'package:shooting_companion/features/scoring/transformable_scoring_viewport.dart';
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;
import 'package:shooting_companion_target_profiles/target_profiles.dart';

void main() {
  testWidgets('target canvas adds a manual impact', (tester) async {
    var impacts = <ShotImpact>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: StatefulBuilder(
              builder: (context, setState) => TargetCanvas(
                target: IssfTargetProfiles.precision25m50m,
                impacts: impacts,
                projectileDiameterMm: 5.6,
                onChanged: (value) => setState(() => impacts = value),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(200, 200));
    await tester.pump();

    expect(impacts, hasLength(1));
    expect(impacts.single.xMm, closeTo(0, 0.01));
    expect(impacts.single.yMm, closeTo(0, 0.01));
  });

  testWidgets('place mode never lets a nearby marker steal a new tap', (
    tester,
  ) async {
    var impacts = <ShotImpact>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: StatefulBuilder(
              builder: (context, setState) => TargetCanvas(
                target: IssfTargetProfiles.precision25m50m,
                impacts: impacts,
                projectileDiameterMm: 5.6,
                tool: ScoringTool.place,
                onChanged: (value) => setState(() => impacts = value),
              ),
            ),
          ),
        ),
      ),
    );

    for (final offset in const [0.0, 5.0, 15.0, 25.0]) {
      await tester.tapAt(Offset(200 + offset, 200));
      await tester.pump();
    }

    expect(impacts, hasLength(4));
    expect(impacts.map((impact) => impact.id).toSet(), hasLength(4));
  });

  testWidgets(
    'edit mode picks nearest marker and newest one for an exact tie',
    (tester) async {
      String? selected;
      final impacts = [
        const ShotImpact(id: 'older', xMm: 0, yMm: 0),
        const ShotImpact(id: 'newer', xMm: 0, yMm: 0),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 400,
              child: TargetCanvas(
                target: IssfTargetProfiles.precision25m50m,
                impacts: impacts,
                projectileDiameterMm: 5.6,
                tool: ScoringTool.edit,
                onChanged: (_) {},
                onImpactSelected: (id) => selected = id,
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(const Offset(200, 200));
      await tester.pump();

      expect(selected, 'newer');
    },
  );

  testWidgets(
    'long press in place mode selects newest overlap without adding or moving',
    (tester) async {
      var tool = ScoringTool.place;
      String? selected;
      var impacts = const [
        ShotImpact(id: 'older', xMm: 0, yMm: 0),
        ShotImpact(id: 'newer', xMm: 0, yMm: 0),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 400,
              child: StatefulBuilder(
                builder: (context, setState) => TargetCanvas(
                  target: IssfTargetProfiles.precision25m50m,
                  impacts: impacts,
                  projectileDiameterMm: 5.6,
                  tool: tool,
                  onChanged: (value) => setState(() => impacts = value),
                  onImpactSelected: (id) => selected = id,
                  onImpactLongPressed: (id) => setState(() {
                    selected = id;
                    tool = ScoringTool.edit;
                  }),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.longPressAt(const Offset(200, 200));
      await tester.pump();

      expect(selected, 'newer');
      expect(tool, ScoringTool.edit);
      expect(impacts, hasLength(2));
      expect(impacts[0].xMm, 0);
      expect(impacts[1].xMm, 0);
    },
  );

  testWidgets('movement cancels marker long press in place mode', (
    tester,
  ) async {
    String? selected;
    var impacts = const [ShotImpact(id: 'center', xMm: 0, yMm: 0)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: StatefulBuilder(
              builder: (context, setState) => TargetCanvas(
                target: IssfTargetProfiles.precision25m50m,
                impacts: impacts,
                projectileDiameterMm: 5.6,
                tool: ScoringTool.place,
                onChanged: (value) => setState(() => impacts = value),
                onImpactLongPressed: (id) => selected = id,
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(const Offset(200, 200));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pump();

    expect(selected, isNull);
    expect(impacts, hasLength(1));
  });

  testWidgets('pinch cancels marker long press in place mode', (tester) async {
    String? selected;
    final controller = ScoringViewportController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: TargetCanvas(
              target: IssfTargetProfiles.precision25m50m,
              impacts: const [ShotImpact(id: 'center', xMm: 0, yMm: 0)],
              projectileDiameterMm: 5.6,
              tool: ScoringTool.place,
              viewportController: controller,
              onChanged: (_) {},
              onImpactLongPressed: (id) => selected = id,
            ),
          ),
        ),
      ),
    );

    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);
    await first.down(const Offset(200, 200));
    await second.down(const Offset(270, 200));
    await first.moveTo(const Offset(165, 200));
    await second.moveTo(const Offset(305, 200));
    await tester.pump(const Duration(milliseconds: 700));
    await first.up();
    await second.up();
    await tester.pump();

    expect(selected, isNull);
    expect(controller.scale, greaterThan(1));
  });

  testWidgets('zoomed viewport maps the same scene point identically', (
    tester,
  ) async {
    final controller = ScoringViewportController();
    var impacts = <ShotImpact>[];
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: StatefulBuilder(
              builder: (context, setState) => TargetCanvas(
                target: IssfTargetProfiles.precision25m50m,
                impacts: impacts,
                projectileDiameterMm: 5.6,
                viewportController: controller,
                onChanged: (value) => setState(() => impacts = value),
              ),
            ),
          ),
        ),
      ),
    );

    const scenePoint = Offset(0.62, 0.43);
    await tester.tapAt(controller.normalizedToViewport(scenePoint));
    await tester.pump();
    controller.focusNormalized(scenePoint, minimumScale: 3);
    await tester.pump();
    await tester.tapAt(controller.normalizedToViewport(scenePoint));
    await tester.pump();

    expect(impacts, hasLength(2));
    expect(impacts[1].xMm, closeTo(impacts[0].xMm, 0.001));
    expect(impacts[1].yMm, closeTo(impacts[0].yMm, 0.001));
  });

  testWidgets('photo placement keeps normalized and physical coordinates', (
    tester,
  ) async {
    final controller = ScoringViewportController();
    addTearDown(controller.dispose);
    final alignment = geo.ManualPhotoAlignment.build(
      corners: const geo.NormalizedQuad(
        topLeft: geo.NormalizedPoint(0, 0),
        topRight: geo.NormalizedPoint(1, 0),
        bottomRight: geo.NormalizedPoint(1, 1),
        bottomLeft: geo.NormalizedPoint(0, 1),
      ),
      cardWidthMm: 400,
      cardHeightMm: 300,
    ).alignment!;
    final placements = <PhotoCanvasPosition>[];
    final image = MemoryImage(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
        'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 300,
              child: PhotoOverlayCanvas(
                imageProvider: image,
                imagePixelSize: const Size(400, 300),
                alignment: alignment,
                impacts: const [],
                viewportController: controller,
                onCanvasTap: placements.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    const scenePoint = Offset(0.7, 0.35);
    final canvasTopLeft = tester.getTopLeft(find.byType(PhotoOverlayCanvas));
    await tester.tapAt(
      canvasTopLeft + controller.normalizedToViewport(scenePoint),
    );
    await tester.pump();
    controller.focusNormalized(scenePoint, minimumScale: 4);
    await tester.pump();
    await tester.tapAt(
      canvasTopLeft + controller.normalizedToViewport(scenePoint),
    );
    await tester.pump();

    expect(placements, hasLength(2));
    expect(placements[0].normalized.x, closeTo(0.7, 0.001));
    expect(placements[0].normalized.y, closeTo(0.35, 0.001));
    expect(
      placements[1].normalized.x,
      closeTo(placements[0].normalized.x, 0.001),
    );
    expect(
      placements[1].normalized.y,
      closeTo(placements[0].normalized.y, 0.001),
    );
    expect(
      placements[1].physicalMm.x,
      closeTo(placements[0].physicalMm.x, 0.001),
    );
    expect(
      placements[1].physicalMm.y,
      closeTo(placements[0].physicalMm.y, 0.001),
    );
  });

  testWidgets('viewport preserves non-square content and inclusive edges', (
    tester,
  ) async {
    final controller = ScoringViewportController();
    addTearDown(controller.dispose);
    Size? renderedContentSize;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: TransformableScoringViewport(
              aspectRatio: 2,
              markers: const [],
              accessMode: CanvasAccessMode.readOnly,
              tool: ScoringTool.place,
              controller: controller,
              contentBuilder: (context, size, zoom) {
                renderedContentSize = size;
                return const ColoredBox(color: Colors.white);
              },
            ),
          ),
        ),
      ),
    );

    expect(renderedContentSize, const Size(400, 200));
    final bottomRight = controller.viewportToNormalized(
      controller.normalizedToViewport(const Offset(1, 1)),
    );
    expect(bottomRight, isNotNull);
    expect(bottomRight!.dx, 1);
    expect(bottomRight.dy, 1);
  });

  testWidgets('viewport resize preserves zoom and normalized center', (
    tester,
  ) async {
    final controller = ScoringViewportController();
    addTearDown(controller.dispose);
    var viewportSize = const Size(400, 400);
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox.fromSize(
                  size: viewportSize,
                  child: TransformableScoringViewport(
                    aspectRatio: 1,
                    markers: const [],
                    accessMode: CanvasAccessMode.readOnly,
                    tool: ScoringTool.place,
                    controller: controller,
                    contentBuilder: (_, _, _) =>
                        const ColoredBox(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    controller.focusNormalized(const Offset(.67, .38), minimumScale: 3);
    await tester.pump();
    final centerBefore = controller.viewportCenterNormalized!;
    final scaleBefore = controller.scale;

    updateHost(() => viewportSize = const Size(360, 300));
    await tester.pump();

    expect(controller.scale, closeTo(scaleBefore, .001));
    expect(
      controller.viewportCenterNormalized!.dx,
      closeTo(centerBefore.dx, .001),
    );
    expect(
      controller.viewportCenterNormalized!.dy,
      closeTo(centerBefore.dy, .001),
    );
  });

  testWidgets('drag keeps its marker identity after selection reorders it', (
    tester,
  ) async {
    final controller = ScoringViewportController();
    addTearDown(controller.dispose);
    var selectedId = 'right';
    var impacts = const [
      ShotImpact(id: 'left', xMm: -55, yMm: 0),
      ShotImpact(id: 'right', xMm: 55, yMm: 0),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: StatefulBuilder(
              builder: (context, setState) => TargetCanvas(
                target: IssfTargetProfiles.precision25m50m,
                impacts: impacts,
                projectileDiameterMm: 5.6,
                tool: ScoringTool.edit,
                selectedImpactId: selectedId,
                viewportController: controller,
                onImpactSelected: (id) =>
                    setState(() => selectedId = id ?? selectedId),
                onChanged: (value) => setState(() => impacts = value),
              ),
            ),
          ),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(TargetCanvas));
    final leftPosition =
        topLeft +
        controller.normalizedToViewport(
          Offset(
            impacts.first.xMm /
                    IssfTargetProfiles.precision25m50m.physicalCardWidthMm +
                0.5,
            0.5,
          ),
        );
    final gesture = await tester.startGesture(leftPosition);
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(selectedId, 'left');
    expect(impacts.first.xMm, greaterThan(-55));
    expect(impacts.last.xMm, 55);
    expect(
      controller.transformationController.value.storage[12],
      closeTo(0, 0.001),
    );
    expect(
      controller.transformationController.value.storage[13],
      closeTo(0, 0.001),
    );
  });

  testWidgets('edit mode pans a zoomed target only from empty space', (
    tester,
  ) async {
    final controller = ScoringViewportController();
    addTearDown(controller.dispose);
    var impacts = <ShotImpact>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: TargetCanvas(
              target: IssfTargetProfiles.precision25m50m,
              impacts: impacts,
              projectileDiameterMm: 5.6,
              tool: ScoringTool.edit,
              viewportController: controller,
              onChanged: (value) => impacts = value,
            ),
          ),
        ),
      ),
    );

    controller.focusNormalized(const Offset(.5, .5), minimumScale: 3);
    await tester.pump();
    final before = controller.transformationController.value.storage[12];
    final topLeft = tester.getTopLeft(find.byType(TargetCanvas));
    final gesture = await tester.startGesture(topLeft + const Offset(250, 200));
    await gesture.moveBy(const Offset(30, 0));
    await gesture.up();
    await tester.pump();

    expect(
      controller.transformationController.value.storage[12],
      greaterThan(before + 20),
    );
    expect(impacts, isEmpty);
  });

  testWidgets('small tap jitter selects without moving a marker', (
    tester,
  ) async {
    final controller = ScoringViewportController();
    addTearDown(controller.dispose);
    var selectedId = '';
    var changes = 0;
    var impacts = const [ShotImpact(id: 'center', xMm: 0, yMm: 0)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: StatefulBuilder(
              builder: (context, setState) => TargetCanvas(
                target: IssfTargetProfiles.precision25m50m,
                impacts: impacts,
                projectileDiameterMm: 5.6,
                tool: ScoringTool.edit,
                viewportController: controller,
                onImpactSelected: (id) => selectedId = id ?? '',
                onChanged: (value) {
                  changes++;
                  setState(() => impacts = value);
                },
              ),
            ),
          ),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(TargetCanvas));
    final center =
        topLeft + controller.normalizedToViewport(const Offset(.5, .5));
    final gesture = await tester.startGesture(center + const Offset(23, 0));
    await gesture.moveBy(const Offset(8, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(selectedId, 'center');
    expect(changes, 0);
    expect(impacts.single.xMm, 0);
    expect(impacts.single.yMm, 0);
  });

  testWidgets('pinch beginning on a marker zooms without moving the shot', (
    tester,
  ) async {
    final controller = ScoringViewportController();
    addTearDown(controller.dispose);
    var impacts = const [ShotImpact(id: 'center', xMm: 0, yMm: 0)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: StatefulBuilder(
              builder: (context, setState) => TargetCanvas(
                target: IssfTargetProfiles.precision25m50m,
                impacts: impacts,
                projectileDiameterMm: 5.6,
                tool: ScoringTool.edit,
                viewportController: controller,
                onChanged: (value) => setState(() => impacts = value),
              ),
            ),
          ),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(TargetCanvas));
    final center =
        topLeft + controller.normalizedToViewport(const Offset(.5, .5));
    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);
    await first.down(center);
    await second.down(center + const Offset(70, 0));
    await first.moveTo(center - const Offset(35, 0));
    await second.moveTo(center + const Offset(105, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pump();

    expect(controller.scale, greaterThan(1));
    expect(impacts.single.xMm, 0);
    expect(impacts.single.yMm, 0);
  });

  testWidgets('zoom controls never start a marker drag underneath them', (
    tester,
  ) async {
    final controller = ScoringViewportController();
    addTearDown(controller.dispose);
    final target = IssfTargetProfiles.precision25m50m;
    final impact = ShotImpact(
      id: 'under-control',
      xMm: (.8 - .5) * target.physicalCardWidthMm,
      yMm: (.08 - .5) * target.physicalCardHeightMm,
    );
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: TargetCanvas(
              target: target,
              impacts: [impact],
              projectileDiameterMm: 5.6,
              tool: ScoringTool.edit,
              viewportController: controller,
              onChanged: (_) => changes++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Inzoomen'));
    await tester.pump();

    expect(controller.scale, closeTo(1.5, 0.001));
    expect(changes, 0);
  });

  testWidgets('persistence cancellation ignores late drag events', (
    tester,
  ) async {
    final controller = ScoringViewportController();
    addTearDown(controller.dispose);
    var marker = const Offset(0.5, 0.5);
    var moveCount = 0;
    var cancelCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 300,
              child: StatefulBuilder(
                builder: (context, setLocalState) =>
                    TransformableScoringViewport(
                      aspectRatio: 1,
                      controller: controller,
                      accessMode: CanvasAccessMode.editable,
                      tool: ScoringTool.edit,
                      markers: [
                        ScoringViewportMarker(
                          id: 'shot',
                          normalizedPosition: marker,
                          semanticsLabel: 'Treffer',
                          child: const Icon(Icons.adjust),
                        ),
                      ],
                      contentBuilder: (_, _, _) =>
                          const ColoredBox(color: Colors.white),
                      onMarkerMoved: (_, value) {
                        moveCount++;
                        setLocalState(() => marker = value);
                      },
                      onMarkerDragCancel: (_) => cancelCount++,
                    ),
              ),
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(TransformableScoringViewport));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(moveCount, greaterThan(0));

    controller.cancelInteraction();
    await tester.pump();
    final movesAtCancellation = moveCount;
    await gesture.moveBy(const Offset(30, 0));
    await gesture.up();
    await tester.pump();

    expect(cancelCount, 1);
    expect(moveCount, movesAtCancellation);
  });

  testWidgets('perspective photo edge is accepted and horizon is rejected', (
    tester,
  ) async {
    const corners = geo.NormalizedQuad(
      topLeft: geo.NormalizedPoint(0.4, 0.4),
      topRight: geo.NormalizedPoint(0.6, 0.4),
      bottomRight: geo.NormalizedPoint(0.9, 0.9),
      bottomLeft: geo.NormalizedPoint(0.1, 0.9),
    );
    final alignment = geo.ManualPhotoAlignment.build(
      corners: corners,
      cardWidthMm: 400,
      cardHeightMm: 300,
    ).alignment!;
    final controller = ScoringViewportController();
    addTearDown(controller.dispose);
    final placements = <PhotoCanvasPosition>[];
    var invalidCount = 0;
    final image = MemoryImage(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
        'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: PhotoOverlayCanvas(
              imageProvider: image,
              imagePixelSize: const Size(400, 400),
              alignment: alignment,
              impacts: const [],
              viewportController: controller,
              onCanvasTap: placements.add,
              onInvalidPosition: () => invalidCount++,
            ),
          ),
        ),
      ),
    );
    final topLeft = tester.getTopLeft(find.byType(PhotoOverlayCanvas));

    await tester.tapAt(
      topLeft +
          controller.normalizedToViewport(
            Offset(corners.topLeft.x, corners.topLeft.y),
          ),
    );
    await tester.pump();
    expect(placements, hasLength(1));
    expect(placements.single.physicalMm.x, closeTo(-200, 1e-6));
    expect(placements.single.physicalMm.y, closeTo(-150, 1e-6));

    await tester.tapAt(
      topLeft + controller.normalizedToViewport(const Offset(0.5, 7 / 30)),
    );
    await tester.pump();
    expect(placements, hasLength(1));
    expect(invalidCount, 1);
  });
}
