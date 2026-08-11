import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shooting_companion/features/training_tools/training_diagram_canvas.dart';
import 'package:shooting_companion_training/training.dart';

void main() {
  test('every catalog diagram has a distinct explicit spec and transcript', () {
    final catalog = BuiltInTrainingContent.catalog;
    final catalogIds = <String>{
      for (final lesson in catalog.lessons) ...lesson.diagramIds,
      for (final drill in catalog.drills) ...drill.diagramIds,
    };

    expect(catalogIds, hasLength(19));
    expect(TrainingDiagramRegistry.supportedIds, catalogIds);
    final definitions = catalogIds
        .map(TrainingDiagramRegistry.require)
        .toList(growable: false);
    expect(definitions.map((value) => value.kind).toSet(), hasLength(19));
    expect(definitions.map((value) => value.transcript).toSet(), hasLength(19));
    for (final definition in definitions) {
      expect(definition.semanticDescription.trim(), isNotEmpty);
      expect(definition.callouts, isNotEmpty, reason: definition.id);
      expect(definition.transcript, contains(definition.callouts.first.label));
    }
    expect(
      () => TrainingDiagramRegistry.require('onbekend-diagram'),
      throwsArgumentError,
    );

    final registrySnapshot = <String, String>{
      for (final id in TrainingDiagramRegistry.supportedIds.toList()..sort())
        id: _sceneFingerprint(TrainingDiagramRegistry.require(id)),
    };
    expect(registrySnapshot, _diagramRegistryGolden);
  });

  // These bitmap goldens deliberately lock the complete, default
  // TrainingDiagramCanvas presentation: title, controls, example scene,
  // numbered anchors and the matching callout transcript. The test uses the
  // Flutter test font, a fixed Android theme, a 412 dp content width and DPR 1
  // so the output does not depend on a host fontconfig or display scale.
  for (final id in TrainingDiagramRegistry.supportedIds.toList()..sort()) {
    testWidgets('bitmap golden $id', (tester) async {
      tester.view.physicalSize = const Size(460, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final boundaryKey = ValueKey('golden-$id');
      await tester.pumpWidget(
        _goldenApp(
          RepaintBoundary(
            key: boundaryKey,
            child: TrainingDiagramCanvas(diagramId: id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/training_diagrams/$id.png'),
      );
      expect(tester.takeException(), isNull, reason: id);
    });
  }

  testWidgets('all 19 diagrams render in a fixed 320 dp frame with semantics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    for (final id in TrainingDiagramRegistry.supportedIds.toList()..sort()) {
      final definition = TrainingDiagramRegistry.require(id);
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(child: TrainingDiagramCanvas(diagramId: id)),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('training-diagram-canvas')),
        findsOneWidget,
        reason: id,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(definition.semanticDescription)),
        ),
        findsOneWidget,
        reason: 'Semantisch transcript ontbreekt voor $id',
      );
      expect(tester.takeException(), isNull, reason: id);
    }
    semantics.dispose();
  });

  testWidgets('diagram exposes controls, callouts and live semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _app(
        const SingleChildScrollView(
          child: TrainingDiagramCanvas(
            diagramId: 'br50-rest-overview',
            title: 'Steun testen',
          ),
        ),
      ),
    );

    expect(find.text('Steun testen'), findsOneWidget);
    expect(find.text('Aandachtspunten'), findsOneWidget);
    expect(find.textContaining('voorsteun'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('training-diagram-canvas')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('training-diagram-mirror')),
      findsOneWidget,
    );

    await tester.tap(find.text('Afwijking'));
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp('Voorbeeld en afwijking worden samen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('training-diagram-mirror')));
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp('De voorstelling is gespiegeld')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Inzoomen'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('training-diagram-fit')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('non-mirrorable diagram survives 320 dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        const SingleChildScrollView(
          child: TrainingDiagramCanvas(diagramId: 'pistol-sight-relationship'),
        ),
        mediaQueryData: const MediaQueryData(
          size: Size(320, 760),
          textScaler: TextScaler.linear(2),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Vier vizierrelaties'), findsOneWidget);
    expect(find.byKey(const ValueKey('training-diagram-mirror')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const <({String name, Size size})>[
    (name: '320 portrait', size: Size(320, 640)),
    (name: '360 portrait', size: Size(360, 800)),
    (name: '412 portrait', size: Size(412, 915)),
    (name: 'tablet', size: Size(1024, 768)),
    (name: '640 landscape', size: Size(640, 320)),
  ]) {
    for (final textScale in const [1.0, 1.3, 2.0]) {
      testWidgets(
        'all diagrams fit ${viewport.name} at text scale $textScale',
        (tester) async {
          tester.view.physicalSize = viewport.size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          for (final id
              in TrainingDiagramRegistry.supportedIds.toList()..sort()) {
            await tester.pumpWidget(
              _app(
                SingleChildScrollView(
                  child: TrainingDiagramCanvas(diagramId: id),
                ),
                mediaQueryData: MediaQueryData(
                  size: viewport.size,
                  textScaler: TextScaler.linear(textScale),
                ),
              ),
            );
            await tester.pump();
            expect(
              find.descendant(
                of: find.byKey(const ValueKey('training-diagram-canvas')),
                matching: find.byType(CustomPaint),
              ),
              findsOneWidget,
              reason: '${viewport.name} @ $textScale: $id',
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${viewport.name} @ $textScale: $id',
            );
          }
        },
      );
    }
  }

  for (final variant in <({String name, ThemeData theme})>[
    (
      name: 'licht',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F6F8F)),
        useMaterial3: true,
      ),
    ),
    (
      name: 'donker',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F6F8F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    ),
    (
      name: 'hoog contrast',
      theme: ThemeData.from(
        colorScheme: const ColorScheme.highContrastDark(),
        useMaterial3: true,
      ),
    ),
  ]) {
    testWidgets('all diagrams render in ${variant.name}', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final id in TrainingDiagramRegistry.supportedIds.toList()..sort()) {
        final definition = TrainingDiagramRegistry.require(id);
        await tester.pumpWidget(
          _app(
            SingleChildScrollView(child: TrainingDiagramCanvas(diagramId: id)),
            theme: variant.theme,
          ),
        );
        await tester.pump();
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('training-diagram-canvas')),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
          reason: id,
        );
        expect(
          find.bySemanticsLabel(
            RegExp(RegExp.escape(definition.semanticDescription)),
          ),
          findsOneWidget,
          reason: '${variant.name}: $id',
        );
        expect(tester.takeException(), isNull, reason: '${variant.name}: $id');
      }
      semantics.dispose();
    });
  }
}

/// Code-native golden for the explicit vector registry. Bitmap goldens for
/// CustomPainter output are platform-sensitive on Windows; this snapshot locks
/// each catalog ID to its painter kind, mirror policy and normalized scene
/// anchors. Transcript uniqueness is asserted separately above.
const _diagramRegistryGolden = <String, String>{
  'abba-experiment': 'abbaExperiment|false|1@0.17,0.48;2@0.50,0.48;3@0.83,0.48',
  'br50-condition-blocks':
      'br50ConditionBlocks|false|1@0.18,0.31;2@0.51,0.54;3@0.84,0.72',
  'br50-contact-map': 'br50ContactMap|true|1@0.32,0.58;2@0.68,0.44;3@0.79,0.67',
  'br50-five-blocks':
      'br50FiveBlocks|false|1@0.18,0.48;2@0.51,0.48;3@0.84,0.48',
  'br50-recoil-return':
      'br50RecoilReturn|true|1@0.24,0.47;2@0.51,0.35;3@0.78,0.47',
  'br50-rest-axis-top-side': 'br50RestAxisTopSide|true|1@0.29,0.42;2@0.72,0.54',
  'br50-rest-overview':
      'br50RestOverview|true|1@0.30,0.57;2@0.70,0.58;3@0.54,0.28',
  'br50-sighter-record-map':
      'br50SighterRecordMap|false|1@0.13,0.49;2@0.56,0.48',
  'pistol-abort-reset-tree':
      'pistolAbortResetTree|false|1@0.50,0.24;2@0.76,0.55;3@0.25,0.72',
  'pistol-breath-trigger-timeline':
      'pistolBreathTriggerTimeline|false|1@0.26,0.28;2@0.52,0.52;3@0.76,0.73',
  'pistol-grip-contact':
      'pistolGripContact|true|1@0.42,0.48;2@0.57,0.62;3@0.72,0.36',
  'pistol-lift-approach':
      'pistolLiftApproach|true|1@0.28,0.76;2@0.54,0.44;3@0.76,0.31',
  'pistol-movement-zone': 'pistolMovementZone|false|1@0.49,0.52;2@0.70,0.35',
  'pistol-natural-alignment-top':
      'pistolNaturalAlignmentTop|true|1@0.33,0.72;2@0.56,0.43;3@0.80,0.27',
  'pistol-sight-relationship':
      'pistolSightRelationship|false|1@0.27,0.31;2@0.73,0.31;3@0.50,0.73',
  'pistol-stance-chain':
      'pistolStanceChain|true|1@0.34,0.80;2@0.43,0.53;3@0.68,0.31',
  'pistol-trigger-contact': 'pistolTriggerContact|true|1@0.42,0.43;2@0.65,0.57',
  'safe-phone-workflow':
      'safePhoneWorkflow|false|1@0.19,0.34;2@0.50,0.54;3@0.81,0.34',
  'target-evidence-layers':
      'targetEvidenceLayers|false|1@0.25,0.70;2@0.43,0.53;3@0.61,0.36;4@0.79,0.20',
};

String _sceneFingerprint(TrainingDiagramDefinition definition) =>
    '${definition.kind.name}|${definition.canMirror}|'
    '${definition.callouts.map((callout) => '${callout.number}@'
        '${callout.anchor.dx.toStringAsFixed(2)},'
        '${callout.anchor.dy.toStringAsFixed(2)}').join(';')}';

Widget _app(Widget home, {ThemeData? theme, MediaQueryData? mediaQueryData}) =>
    MaterialApp(
      theme:
          theme ??
          ThemeData.from(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3F6F8F),
            ),
            useMaterial3: true,
          ),
      builder: mediaQueryData == null
          ? null
          : (context, child) => MediaQuery(
              data: mediaQueryData,
              child: child ?? const SizedBox.shrink(),
            ),
      home: Scaffold(body: home),
    );

Widget _goldenApp(Widget diagram) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    useMaterial3: true,
    platform: TargetPlatform.android,
    fontFamily: 'Ahem',
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF315E78),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFCDE5F3),
      onPrimaryContainer: Color(0xFF0A2737),
      secondary: Color(0xFF4C635B),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFCFE8DD),
      onSecondaryContainer: Color(0xFF09271F),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF191C1E),
      outline: Color(0xFF70787D),
      outlineVariant: Color(0xFFC0C8CD),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
    ),
  ),
  home: Scaffold(
    backgroundColor: const Color(0xFFEFF2F4),
    body: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 412, child: diagram),
    ),
  ),
);
