import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/features/photo/four_point_alignment_editor.dart';
import 'package:shooting_companion/features/photo/photo_canvas_models.dart';
import 'package:shooting_companion/features/photo/photo_overlay_canvas.dart';
import 'package:shooting_companion/features/photo/ring_assisted_alignment_editor.dart';
import 'package:shooting_companion/features/scoring/transformable_scoring_viewport.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('quarter-turn photo coordinates', () {
    for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
      testWidgets(
        'tap at rotation $quarterTurns persists original source coordinate',
        (tester) async {
          final sourceCorners = const geo.NormalizedQuad(
            topLeft: geo.NormalizedPoint(0, 0),
            topRight: geo.NormalizedPoint(1, 0),
            bottomRight: geo.NormalizedPoint(1, 1),
            bottomLeft: geo.NormalizedPoint(0, 1),
          );
          const storedRotation = 1;
          final displayedCorners = geo.NormalizedQuad.fromOrderedPoints(
            sourceCorners.points
                .map(
                  (point) => geo.rotateNormalizedPoint(point, storedRotation),
                )
                .toList(),
          );
          final alignment = geo.ManualPhotoAlignment.build(
            corners: displayedCorners,
            cardWidthMm: 400,
            cardHeightMm: 300,
            rotationQuarterTurns: storedRotation,
          ).alignment!;
          final controller = ScoringViewportController();
          addTearDown(controller.dispose);
          final placements = <PhotoCanvasPosition>[];
          final displaySize = quarterTurns.isOdd
              ? const Size(300, 400)
              : const Size(400, 300);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox.fromSize(
                    size: displaySize,
                    child: PhotoOverlayCanvas(
                      imageProvider: _testImage,
                      imagePixelSize: const Size(400, 300),
                      alignment: alignment,
                      impacts: const [
                        PhotoCanvasImpact(
                          id: 'marker',
                          positionMm: geo.PhysicalPointMm(100, 60),
                          sequenceNumber: 1,
                        ),
                      ],
                      displayRotationQuarterTurns: quarterTurns,
                      viewportController: controller,
                      onCanvasTap: placements.add,
                      showControls: false,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          const source = geo.NormalizedPoint(0.25, 0.3);
          final displayed = geo.rotateNormalizedPoint(source, quarterTurns);
          final topLeft = tester.getTopLeft(find.byType(PhotoOverlayCanvas));
          await tester.tapAt(
            topLeft +
                controller.normalizedToViewport(
                  Offset(displayed.x, displayed.y),
                ),
          );
          await tester.pump();

          expect(placements, hasLength(1));
          expect(placements.single.normalized.x, closeTo(source.x, 1e-6));
          expect(placements.single.normalized.y, closeTo(source.y, 1e-6));
          expect(
            placements.single.displayedNormalized,
            geo.NormalizedPoint(displayed.x, displayed.y),
          );
          expect(placements.single.physicalMm.x, closeTo(-100, 1e-5));
          expect(placements.single.physicalMm.y, closeTo(-60, 1e-5));

          const markerSource = geo.NormalizedPoint(0.75, 0.7);
          final markerDisplayed = geo.rotateNormalizedPoint(
            markerSource,
            quarterTurns,
          );
          final expectedMarkerCenter =
              topLeft +
              controller.normalizedToViewport(
                Offset(markerDisplayed.x, markerDisplayed.y),
              );
          final actualMarkerCenter = tester.getCenter(
            find.byKey(const ValueKey('photo-impact-marker-marker')),
          );
          expect(actualMarkerCenter.dx, closeTo(expectedMarkerCenter.dx, 1e-5));
          expect(actualMarkerCenter.dy, closeTo(expectedMarkerCenter.dy, 1e-5));
        },
      );
    }
  });

  testWidgets(
    'four-point rotation transforms anchors and builds v2 alignment',
    (tester) async {
      const initial = geo.NormalizedQuad(
        topLeft: geo.NormalizedPoint(0.1, 0.1),
        topRight: geo.NormalizedPoint(0.9, 0.1),
        bottomRight: geo.NormalizedPoint(0.9, 0.9),
        bottomLeft: geo.NormalizedPoint(0.1, 0.9),
      );
      geo.ManualPhotoAlignment? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FourPointAlignmentEditor(
                imageProvider: _testImage,
                imagePixelSize: const Size(400, 300),
                cardWidthMm: 400,
                cardHeightMm: 300,
                initialCorners: initial,
                targetProfile: _target,
                onConfirmed: (value) => confirmed = value,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('90 graden rechtsom'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('four-point-projected-target-overlay')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Uitlijning klopt'));
      await tester.tap(find.text('Uitlijning klopt'));
      await tester.pump();

      expect(confirmed, isNotNull);
      expect(confirmed!.rotationQuarterTurns, 1);
      expect(
        confirmed!.algorithmVersion,
        geo.manualHomographyV2AlgorithmVersion,
      );
      expect(
        confirmed!.corners.topLeft,
        geo.rotateNormalizedPoint(initial.topLeft, 1),
      );
    },
  );

  testWidgets(
    'four-point external corner and rotation update is not rotated twice',
    (tester) async {
      const originalCorners = geo.NormalizedQuad(
        topLeft: geo.NormalizedPoint(0.15, 0.1),
        topRight: geo.NormalizedPoint(0.85, 0.1),
        bottomRight: geo.NormalizedPoint(0.85, 0.9),
        bottomLeft: geo.NormalizedPoint(0.15, 0.9),
      );
      final rotatedCorners = geo.NormalizedQuad.fromOrderedPoints(
        originalCorners.points
            .map((point) => geo.rotateNormalizedPoint(point, 1))
            .toList(),
      );
      var currentCorners = originalCorners;
      var currentRotation = 0;
      geo.ManualPhotoAlignment? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        currentCorners = rotatedCorners;
                        currentRotation = 1;
                      }),
                      child: const Text('Externe uitlijning laden'),
                    ),
                    FourPointAlignmentEditor(
                      imageProvider: _testImage,
                      imagePixelSize: const Size(400, 300),
                      cardWidthMm: 400,
                      cardHeightMm: 300,
                      initialCorners: currentCorners,
                      initialRotationQuarterTurns: currentRotation,
                      onConfirmed: (value) => confirmed = value,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Externe uitlijning laden'));
      await tester.pump();
      await tester.ensureVisible(find.text('Uitlijning klopt'));
      await tester.tap(find.text('Uitlijning klopt'));
      await tester.pump();

      expect(confirmed, isNotNull);
      expect(confirmed!.rotationQuarterTurns, 1);
      expect(confirmed!.corners.points, rotatedCorners.points);
    },
  );

  testWidgets('overlay exposes target geometry and residual status', (
    tester,
  ) async {
    final alignment = geo.ManualPhotoAlignment.build(
      corners: const geo.NormalizedQuad(
        topLeft: geo.NormalizedPoint(0.05, 0.05),
        topRight: geo.NormalizedPoint(0.95, 0.05),
        bottomRight: geo.NormalizedPoint(0.95, 0.95),
        bottomLeft: geo.NormalizedPoint(0.05, 0.95),
      ),
      cardWidthMm: 550,
      cardHeightMm: 550,
    ).alignment!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 400,
            child: PhotoOverlayCanvas(
              imageProvider: _testImage,
              imagePixelSize: const Size(400, 400),
              alignment: alignment,
              targetProfile: _target,
              impacts: const [],
              overlayOpacity: 0.5,
              accessMode: CanvasAccessMode.readOnly,
              showControls: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Uitlijning'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ring-assisted wizard builds from two independent rings', (
    tester,
  ) async {
    geo.ManualPhotoAlignment? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: RingAssistedAlignmentEditor(
                imageProvider: _testImage,
                imagePixelSize: const Size(400, 400),
                cardWidthMm: 400,
                cardHeightMm: 400,
                ringRadiiMm: const [150, 100, 50],
                targetProfile: _target,
                maximumImageHeight: 400,
                onConfirmed: (value) => confirmed = value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final viewport = find.byType(TransformableScoringViewport);
    final rect = tester.getRect(viewport);
    const points = <Offset>[
      Offset(0.5, 0.5),
      Offset(0.5, 0.05),
      Offset(0.5, 0.125),
      Offset(0.875, 0.5),
      Offset(0.5, 0.875),
      Offset(0.125, 0.5),
      Offset(0.5, 0.25),
      Offset(0.75, 0.5),
      Offset(0.5, 0.75),
      Offset(0.25, 0.5),
    ];
    for (final point in points) {
      await tester.tapAt(
        rect.topLeft + Offset(point.dx * rect.width, point.dy * rect.height),
      );
      await tester.pump();
    }
    expect(
      find.byKey(const ValueKey('ring-assisted-projected-target-overlay')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Uitlijning klopt'));
    await tester.tap(find.text('Uitlijning klopt'));
    await tester.pump();

    expect(confirmed, isNotNull);
    expect(confirmed!.alignmentMode, geo.PhotoAlignmentMode.ringAssisted);
    expect(confirmed!.anchors, hasLength(10));
  });

  testWidgets('ring-assisted wizard resumes stored anchors and rotation', (
    tester,
  ) async {
    const sourcePoints = <geo.NormalizedPoint>[
      geo.NormalizedPoint(0.5, 0.5),
      geo.NormalizedPoint(0.5, 0.05),
      geo.NormalizedPoint(0.5, 0.125),
      geo.NormalizedPoint(0.875, 0.5),
      geo.NormalizedPoint(0.5, 0.875),
      geo.NormalizedPoint(0.125, 0.5),
      geo.NormalizedPoint(0.5, 0.25),
      geo.NormalizedPoint(0.75, 0.5),
      geo.NormalizedPoint(0.5, 0.75),
      geo.NormalizedPoint(0.25, 0.5),
    ];
    final displayed = sourcePoints
        .map((point) => geo.rotateNormalizedPoint(point, 1))
        .toList();
    final initial = geo.ManualPhotoAlignment.buildRingAssisted(
      center: displayed[0],
      topDirection: displayed[1],
      ringSeries: [
        geo.RingAnchorSeries(
          id: 'ring-1',
          radiusMm: 150,
          top: displayed[2],
          right: displayed[3],
          bottom: displayed[4],
          left: displayed[5],
        ),
        geo.RingAnchorSeries(
          id: 'ring-2',
          radiusMm: 100,
          top: displayed[6],
          right: displayed[7],
          bottom: displayed[8],
          left: displayed[9],
        ),
      ],
      cardWidthMm: 400,
      cardHeightMm: 400,
      rotationQuarterTurns: 1,
    ).alignment!;
    geo.ManualPhotoAlignment? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: RingAssistedAlignmentEditor(
                imageProvider: _testImage,
                imagePixelSize: const Size(400, 400),
                cardWidthMm: 400,
                cardHeightMm: 400,
                ringRadiiMm: const [150, 100, 50],
                initialAlignment: initial,
                maximumImageHeight: 400,
                onConfirmed: (value) => confirmed = value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('Controleer de geprojecteerde ringen'),
      findsOne,
    );
    await tester.ensureVisible(find.text('Uitlijning klopt'));
    await tester.tap(find.text('Uitlijning klopt'));
    await tester.pump();

    expect(confirmed, isNotNull);
    expect(confirmed!.rotationQuarterTurns, 1);
    expect(
      confirmed!.anchors.map((anchor) => anchor.sourcePoint),
      orderedEquals(initial.anchors.map((anchor) => anchor.sourcePoint)),
    );
  });
}

final _testImage = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
    'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ),
);

final _target = domain.TargetProfile(
  schemaVersion: 1,
  profileId: 'test',
  profileVersion: 1,
  displayName: 'Testkaart',
  authority: 'Test',
  rulesEdition: 'Test',
  physicalCardWidthMm: 550,
  physicalCardHeightMm: 550,
  rings: const [
    domain.RingZone(value: 10, outerDiameterMm: 50),
    domain.RingZone(value: 9, outerDiameterMm: 100),
    domain.RingZone(value: 8, outerDiameterMm: 150),
  ],
  lineThicknessMm: 0.5,
  lineBreakingRule: domain.LineBreakingRule.bulletEdgeTouchesHigherRing,
  validationStatus: domain.ValidationStatus.official,
  innerTenDiameterMm: 25,
  blackOuterDiameterMm: 150,
);
