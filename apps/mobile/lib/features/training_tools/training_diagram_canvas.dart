import 'dart:math' as math;

import 'package:flutter/material.dart';

enum TrainingDiagramView { example, deviation }

class TrainingDiagramCallout {
  const TrainingDiagramCallout({
    required this.number,
    required this.label,
    required this.anchor,
  });

  final int number;
  final String label;
  final Offset anchor;
}

/// Accessible, code-native training illustration.
///
/// The diagram deliberately uses no remote or bundled bitmap. It stays crisp
/// while zooming, follows the active theme and describes every numbered
/// callout as regular text below the canvas.
class TrainingDiagramCanvas extends StatefulWidget {
  const TrainingDiagramCanvas({
    required this.diagramId,
    this.title,
    this.semanticDescription,
    this.callouts,
    this.initialView = TrainingDiagramView.example,
    super.key,
  });

  final String diagramId;
  final String? title;
  final String? semanticDescription;
  final List<TrainingDiagramCallout>? callouts;
  final TrainingDiagramView initialView;

  @override
  State<TrainingDiagramCanvas> createState() => _TrainingDiagramCanvasState();
}

class _TrainingDiagramCanvasState extends State<TrainingDiagramCanvas> {
  late final TransformationController _transformationController;
  late TrainingDiagramView _view;
  var _mirrored = false;

  TrainingDiagramDefinition get _spec =>
      TrainingDiagramRegistry.require(widget.diagramId).overrideWith(
        title: widget.title,
        semanticDescription: widget.semanticDescription,
        callouts: widget.callouts,
      );

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _view = widget.initialView;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final current = _transformationController.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(1.0, 5.0);
    _transformationController.value = Matrix4.diagonal3Values(next, next, 1);
  }

  void _fit() => _transformationController.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final textScaler = MediaQuery.textScalerOf(context);
    final diagramSemantics = [
      spec.semanticDescription,
      _view == TrainingDiagramView.example
          ? 'Correct voorbeeld wordt getoond.'
          : 'Voorbeeld en afwijking worden samen getoond.',
      if (_mirrored) 'De voorstelling is gespiegeld.',
      for (final callout in spec.callouts)
        '${callout.number}. ${callout.label}',
    ].join(' ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  spec.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<TrainingDiagramView>(
                      key: const ValueKey('training-diagram-view-toggle'),
                      segments: const [
                        ButtonSegment(
                          value: TrainingDiagramView.example,
                          icon: Icon(Icons.check_circle_outline),
                          label: Text('Voorbeeld'),
                        ),
                        ButtonSegment(
                          value: TrainingDiagramView.deviation,
                          icon: Icon(Icons.compare_arrows),
                          label: Text('Afwijking'),
                        ),
                      ],
                      selected: {_view},
                      onSelectionChanged: (selection) =>
                          setState(() => _view = selection.single),
                      showSelectedIcon: false,
                    ),
                    if (spec.canMirror)
                      FilterChip(
                        key: const ValueKey('training-diagram-mirror'),
                        avatar: const Icon(Icons.flip, size: 18),
                        label: const Text('Spiegelen'),
                        selected: _mirrored,
                        onSelected: (value) =>
                            setState(() => _mirrored = value),
                      ),
                    _DiagramIconButton(
                      icon: Icons.remove,
                      tooltip: 'Uitzoomen',
                      onPressed: () => _zoom(1 / 1.4),
                    ),
                    _DiagramIconButton(
                      icon: Icons.add,
                      tooltip: 'Inzoomen',
                      onPressed: () => _zoom(1.4),
                    ),
                    _DiagramIconButton(
                      key: const ValueKey('training-diagram-fit'),
                      icon: Icons.fit_screen,
                      tooltip: 'Passend maken',
                      onPressed: _fit,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Semantics(
            label: diagramSemantics,
            image: true,
            child: ExcludeSemantics(
              child: Container(
                key: const ValueKey('training-diagram-canvas'),
                constraints: const BoxConstraints(minHeight: 240),
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRect(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1,
                      maxScale: 5,
                      boundaryMargin: const EdgeInsets.all(96),
                      constrained: true,
                      child: CustomPaint(
                        painter: _TrainingDiagramPainter(
                          spec: spec,
                          view: _view,
                          mirrored: _mirrored,
                          colorScheme: Theme.of(context).colorScheme,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (spec.callouts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Aandachtspunten',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final callout in spec.callouts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CalloutBadge(number: callout.number),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(callout.label, textScaler: textScaler),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DiagramIconButton extends StatelessWidget {
  const _DiagramIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.outlined(
    icon: Icon(icon),
    tooltip: tooltip,
    onPressed: onPressed,
  );
}

class _CalloutBadge extends StatelessWidget {
  const _CalloutBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Theme.of(context).colorScheme.primaryContainer,
      border: Border.all(color: Theme.of(context).colorScheme.primary),
    ),
    child: Text(
      '$number',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

enum TrainingDiagramKind {
  safePhoneWorkflow,
  targetEvidenceLayers,
  abbaExperiment,
  pistolNaturalAlignmentTop,
  pistolStanceChain,
  pistolGripContact,
  pistolSightRelationship,
  pistolMovementZone,
  pistolLiftApproach,
  pistolBreathTriggerTimeline,
  pistolTriggerContact,
  pistolAbortResetTree,
  br50RestOverview,
  br50RestAxisTopSide,
  br50ContactMap,
  br50RecoilReturn,
  br50SighterRecordMap,
  br50FiveBlocks,
  br50ConditionBlocks,
}

@immutable
class TrainingDiagramDefinition {
  const TrainingDiagramDefinition({
    required this.id,
    required this.kind,
    required this.title,
    required this.semanticDescription,
    required this.canMirror,
    required this.callouts,
  });

  final String id;
  final TrainingDiagramKind kind;
  final String title;
  final String semanticDescription;
  final bool canMirror;
  final List<TrainingDiagramCallout> callouts;

  String get transcript => <String>[
    semanticDescription,
    for (final callout in callouts) '${callout.number}. ${callout.label}',
  ].join(' ');

  TrainingDiagramDefinition overrideWith({
    String? title,
    String? semanticDescription,
    List<TrainingDiagramCallout>? callouts,
  }) => TrainingDiagramDefinition(
    id: id,
    kind: kind,
    title: title?.trim().isNotEmpty == true ? title!.trim() : this.title,
    semanticDescription: semanticDescription?.trim().isNotEmpty == true
        ? semanticDescription!.trim()
        : this.semanticDescription,
    canMirror: canMirror,
    callouts: callouts ?? this.callouts,
  );
}

/// Explicit registry for every code-native illustration used by V2 content.
///
/// There is deliberately no keyword or generic fallback. A missing registry
/// entry is a content/build defect and must fail loudly during development.
class TrainingDiagramRegistry {
  const TrainingDiagramRegistry._();

  static Set<String> get supportedIds => Set.unmodifiable(_definitions.keys);

  static bool supports(String id) => _definitions.containsKey(id);

  static TrainingDiagramDefinition require(String id) {
    final definition = _definitions[id];
    if (definition == null) {
      throw ArgumentError.value(
        id,
        'diagramId',
        'Geen expliciete TrainingDiagramDefinition geregistreerd.',
      );
    }
    return definition;
  }

  static String transcriptFor(String id) => require(id).transcript;

  static const Map<String, TrainingDiagramDefinition> _definitions = {
    'safe-phone-workflow': TrainingDiagramDefinition(
      id: 'safe-phone-workflow',
      kind: TrainingDiagramKind.safePhoneWorkflow,
      title: 'Veilige telefoonworkflow',
      semanticDescription:
          'Driedelige volgorde: veilige richting, zichtbaar ontladen en pas daarna de telefoon gebruiken.',
      canMirror: false,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Veilige mondingsrichting blijft eerst.',
          anchor: Offset(0.19, 0.34),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Controleer actie en kamer zichtbaar.',
          anchor: Offset(0.50, 0.54),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Gebruik de telefoon pas na veilig afleggen.',
          anchor: Offset(0.81, 0.34),
        ),
      ],
    ),
    'target-evidence-layers': TrainingDiagramDefinition(
      id: 'target-evidence-layers',
      kind: TrainingDiagramKind.targetEvidenceLayers,
      title: 'Lagen van meetbewijs',
      semanticDescription:
          'Vier gestapelde lagen onderscheiden originele foto, uitlijning, bevestigde treffers en afgeleide score.',
      canMirror: false,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'De originele foto blijft ongewijzigd.',
          anchor: Offset(0.25, 0.70),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'De overlay bewijst de uitlijning.',
          anchor: Offset(0.43, 0.53),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Alleen bevestigde punten zijn invoer.',
          anchor: Offset(0.61, 0.36),
        ),
        TrainingDiagramCallout(
          number: 4,
          label: 'Score en analyse blijven afleidbaar.',
          anchor: Offset(0.79, 0.20),
        ),
      ],
    ),
    'abba-experiment': TrainingDiagramDefinition(
      id: 'abba-experiment',
      kind: TrainingDiagramKind.abbaExperiment,
      title: 'A-B-B-A vergelijking',
      semanticDescription:
          'Vier opeenvolgende blokken A, B, B en A beperken het effect van opwarming en tijdsverloop.',
      canMirror: false,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Begin met variant A.',
          anchor: Offset(0.17, 0.48),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Voer variant B tweemaal in het midden uit.',
          anchor: Offset(0.50, 0.48),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Sluit opnieuw met A af.',
          anchor: Offset(0.83, 0.48),
        ),
      ],
    ),
    'pistol-natural-alignment-top': TrainingDiagramDefinition(
      id: 'pistol-natural-alignment-top',
      kind: TrainingDiagramKind.pistolNaturalAlignmentTop,
      title: 'Natuurlijke uitlijning van bovenaf',
      semanticDescription:
          'Bovenaanzicht met voeten, romp, schouder-arm-as en doelrichting; de hele houding draait wanneer de natuurlijke as afwijkt.',
      canMirror: true,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Voeten vormen het herhaalbare steunvlak.',
          anchor: Offset(0.33, 0.72),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Schouder en arm liggen ontspannen op één as.',
          anchor: Offset(0.56, 0.43),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Draai de houding, forceer niet alleen de arm.',
          anchor: Offset(0.80, 0.27),
        ),
      ],
    ),
    'pistol-stance-chain': TrainingDiagramDefinition(
      id: 'pistol-stance-chain',
      kind: TrainingDiagramKind.pistolStanceChain,
      title: 'Houdingsketen',
      semanticDescription:
          'Zijaanzicht verbindt voeten, knieën, bekken, romp, hoofd en schotarm tot één stabiele keten.',
      canMirror: true,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Balans begint bij beide voeten.',
          anchor: Offset(0.34, 0.80),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Bekken en romp blijven boven het steunvlak.',
          anchor: Offset(0.43, 0.53),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Hoofd en arm keren naar dezelfde lijn terug.',
          anchor: Offset(0.68, 0.31),
        ),
      ],
    ),
    'pistol-grip-contact': TrainingDiagramDefinition(
      id: 'pistol-grip-contact',
      kind: TrainingDiagramKind.pistolGripContact,
      title: 'Grip en contactzones',
      semanticDescription:
          'Schematische pistoolgreep met handpalm, vingers, duim en vrijgehouden trekkercontact als afzonderlijke contactzones.',
      canMirror: true,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Plaats de greep steeds in dezelfde handpalmzone.',
          anchor: Offset(0.42, 0.48),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Verdeel vingerdruk reproduceerbaar.',
          anchor: Offset(0.57, 0.62),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Laat de trekkervinger onafhankelijk bewegen.',
          anchor: Offset(0.72, 0.36),
        ),
      ],
    ),
    'pistol-sight-relationship': TrainingDiagramDefinition(
      id: 'pistol-sight-relationship',
      kind: TrainingDiagramKind.pistolSightRelationship,
      title: 'Vier vizierrelaties',
      semanticDescription:
          'Vier afzonderlijke vizierbeelden tonen correct, links, rechts en hoog-laag afwijkend met gelijke of ongelijke lichtspleten.',
      canMirror: false,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Correct: gelijke spleten en gelijke bovenzijde.',
          anchor: Offset(0.27, 0.31),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Horizontaal: korrel staat links of rechts.',
          anchor: Offset(0.73, 0.31),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Verticaal: korrel staat te hoog of te laag.',
          anchor: Offset(0.50, 0.73),
        ),
      ],
    ),
    'pistol-movement-zone': TrainingDiagramDefinition(
      id: 'pistol-movement-zone',
      kind: TrainingDiagramKind.pistolMovementZone,
      title: 'Bewegingszone en visuele focus',
      semanticDescription:
          'Doelringen met een natuurlijke bewegingslus; de aandacht blijft op het scherpe vizier in plaats van op een stilstaand punt.',
      canMirror: false,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Aanvaard een kleine natuurlijke bewegingszone.',
          anchor: Offset(0.49, 0.52),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Houd visuele aandacht bij de vizierrelatie.',
          anchor: Offset(0.70, 0.35),
        ),
      ],
    ),
    'pistol-lift-approach': TrainingDiagramDefinition(
      id: 'pistol-lift-approach',
      kind: TrainingDiagramKind.pistolLiftApproach,
      title: 'Lift en nadering',
      semanticDescription:
          'Een gebogen liftpad nadert de richtzone van onderen terwijl de voorbereidende trekkerdruk geleidelijk wordt opgebouwd.',
      canMirror: true,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Start elke lift vanuit dezelfde rustpositie.',
          anchor: Offset(0.28, 0.76),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Vertraag gecontroleerd bij de richtzone.',
          anchor: Offset(0.54, 0.44),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Bouw voorbereidende druk zonder een schot te forceren.',
          anchor: Offset(0.76, 0.31),
        ),
      ],
    ),
    'pistol-breath-trigger-timeline': TrainingDiagramDefinition(
      id: 'pistol-breath-trigger-timeline',
      kind: TrainingDiagramKind.pistolBreathTriggerTimeline,
      title: 'Adem-arm-trekker tijdlijn',
      semanticDescription:
          'Drie tijdlijnen tonen ademgolf, armbeweging en oplopende trekkerdruk met één comfortabel uitvoeringsvenster.',
      canMirror: false,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Adem normaal tijdens de voorbereiding.',
          anchor: Offset(0.26, 0.28),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'De lift stabiliseert vóór het uitvoeringsvenster.',
          anchor: Offset(0.52, 0.52),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Trekkerdruk bouwt vloeiend op; reset bij overschrijding.',
          anchor: Offset(0.76, 0.73),
        ),
      ],
    ),
    'pistol-trigger-contact': TrainingDiagramDefinition(
      id: 'pistol-trigger-contact',
      kind: TrainingDiagramKind.pistolTriggerContact,
      title: 'Trekkercontact en krachtrichting',
      semanticDescription:
          'Bovenaanzicht van trekkervinger en trekkerblad met recht-achterwaartse kracht en een zijdelingse foutvector.',
      canMirror: true,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Gebruik een herhaalbaar contactvlak.',
          anchor: Offset(0.42, 0.43),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Bouw kracht recht naar achteren op.',
          anchor: Offset(0.65, 0.57),
        ),
      ],
    ),
    'pistol-abort-reset-tree': TrainingDiagramDefinition(
      id: 'pistol-abort-reset-tree',
      kind: TrainingDiagramKind.pistolAbortResetTree,
      title: 'Afbreken en resetten',
      semanticDescription:
          'Beslisboom: is het beeld en gevoel uitvoerbaar, dan doorgaan; zo niet veilig zakken, ontspannen en opnieuw beginnen.',
      canMirror: false,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Beoordeel één duidelijke uitvoeringsvoorwaarde.',
          anchor: Offset(0.50, 0.24),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Voer alleen uit wanneer de voorwaarde klopt.',
          anchor: Offset(0.76, 0.55),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Zak veilig, ontspan en reset zonder haast.',
          anchor: Offset(0.25, 0.72),
        ),
      ],
    ),
    'br50-rest-overview': TrainingDiagramDefinition(
      id: 'br50-rest-overview',
      kind: TrainingDiagramKind.br50RestOverview,
      title: 'Benchrest steunoverzicht',
      semanticDescription:
          'Zijaanzicht van geweer, voorsteun, achterzak, tafel en vrije terugloopas.',
      canMirror: true,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Plaats de voorsteun reproduceerbaar.',
          anchor: Offset(0.30, 0.57),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Laat de kolf consistent in de achterzak rusten.',
          anchor: Offset(0.70, 0.58),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Houd de terugloopas vrij en recht.',
          anchor: Offset(0.54, 0.28),
        ),
      ],
    ),
    'br50-rest-axis-top-side': TrainingDiagramDefinition(
      id: 'br50-rest-axis-top-side',
      kind: TrainingDiagramKind.br50RestAxisTopSide,
      title: 'Steunas van boven en opzij',
      semanticDescription:
          'Twee panelen vergelijken bovenaanzicht en zijaanzicht van loopas, steunpunten en doelrichting.',
      canMirror: true,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Boven: loopas en steunpunten blijven collineair.',
          anchor: Offset(0.29, 0.42),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Zij: steunhoogtes laten vrije terugloop toe.',
          anchor: Offset(0.72, 0.54),
        ),
      ],
    ),
    'br50-contact-map': TrainingDiagramDefinition(
      id: 'br50-contact-map',
      kind: TrainingDiagramKind.br50ContactMap,
      title: 'Contactkaart',
      semanticDescription:
          'Geweercontour met afzonderlijke contactpunten voor voorsteun, achterzak, schouder, wang en trekkerhand.',
      canMirror: true,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Steuncontacten blijven op dezelfde plaats.',
          anchor: Offset(0.32, 0.58),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Lichaamscontact blijft licht en herhaalbaar.',
          anchor: Offset(0.68, 0.44),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Verander één contactvariabele per test.',
          anchor: Offset(0.79, 0.67),
        ),
      ],
    ),
    'br50-recoil-return': TrainingDiagramDefinition(
      id: 'br50-recoil-return',
      kind: TrainingDiagramKind.br50RecoilReturn,
      title: 'Terugloop en terugkeer',
      semanticDescription:
          'Voor-, tijdens- en na-positie tonen een rechte terugloop en gecontroleerde terugkeer naar de beginas.',
      canMirror: true,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Noteer het beginpunt vóór het schot.',
          anchor: Offset(0.24, 0.47),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Observeer richting en symmetrie van de terugloop.',
          anchor: Offset(0.51, 0.35),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Controleer terugkeer zonder het geweer te sturen.',
          anchor: Offset(0.78, 0.47),
        ),
      ],
    ),
    'br50-sighter-record-map': TrainingDiagramDefinition(
      id: 'br50-sighter-record-map',
      kind: TrainingDiagramKind.br50SighterRecordMap,
      title: 'Proef- en wedstrijdroosjes',
      semanticDescription:
          'Kaartgrid onderscheidt proefroosjes als gearceerde zone en 25 genummerde wedstrijdroosjes in een vijf-bij-vijf raster.',
      canMirror: false,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Proefroosjes tellen niet voor de wedstrijdscore.',
          anchor: Offset(0.13, 0.49),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Wedstrijdroosjes 1 tot en met 25 vormen het record.',
          anchor: Offset(0.56, 0.48),
        ),
      ],
    ),
    'br50-five-blocks': TrainingDiagramDefinition(
      id: 'br50-five-blocks',
      kind: TrainingDiagramKind.br50FiveBlocks,
      title: 'Vijf kaartblokken',
      semanticDescription:
          'De 25 wedstrijdroosjes zijn opgesplitst in vijf blokken van vijf met afzonderlijke voortgang en resetmomenten.',
      canMirror: false,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Werk per blok van vijf roosjes.',
          anchor: Offset(0.18, 0.48),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Observeer na ieder blok, niet na ieder schot.',
          anchor: Offset(0.51, 0.48),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Reset routine voor het volgende blok.',
          anchor: Offset(0.84, 0.48),
        ),
      ],
    ),
    'br50-condition-blocks': TrainingDiagramDefinition(
      id: 'br50-condition-blocks',
      kind: TrainingDiagramKind.br50ConditionBlocks,
      title: 'Omstandigheden per blok',
      semanticDescription:
          'Tijdlijn met vijf blokken koppelt windrichting en intensiteit aan de overeenkomstige kaartzone zonder schotvolgorde te verzinnen.',
      canMirror: false,
      callouts: [
        TrainingDiagramCallout(
          number: 1,
          label: 'Registreer toestand aan het begin van een blok.',
          anchor: Offset(0.18, 0.31),
        ),
        TrainingDiagramCallout(
          number: 2,
          label: 'Koppel observatie aan het hele blok.',
          anchor: Offset(0.51, 0.54),
        ),
        TrainingDiagramCallout(
          number: 3,
          label: 'Vergelijk pas na voldoende herhaalde blokken.',
          anchor: Offset(0.84, 0.72),
        ),
      ],
    ),
  };
}

class _TrainingDiagramPainter extends CustomPainter {
  const _TrainingDiagramPainter({
    required this.spec,
    required this.view,
    required this.mirrored,
    required this.colorScheme,
  });

  final TrainingDiagramDefinition spec;
  final TrainingDiagramView view;
  final bool mirrored;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mirrored) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final primary = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final secondary = Paint()
      ..color = colorScheme.secondary
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final guide = Paint()
      ..color = colorScheme.outlineVariant
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final deviation = Paint()
      ..color = colorScheme.error
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);

    switch (spec.kind) {
      case TrainingDiagramKind.safePhoneWorkflow:
        _paintSafety(
          canvas,
          size,
          center,
          primary,
          secondary,
          guide,
          deviation,
        );
      case TrainingDiagramKind.targetEvidenceLayers:
        _paintEvidenceLayers(
          canvas,
          size,
          primary,
          secondary,
          guide,
          deviation,
        );
      case TrainingDiagramKind.abbaExperiment:
        _paintAbba(canvas, size, primary, secondary, guide, deviation);
      case TrainingDiagramKind.pistolNaturalAlignmentTop:
        _paintNaturalAlignmentTop(
          canvas,
          size,
          primary,
          secondary,
          guide,
          deviation,
        );
      case TrainingDiagramKind.pistolStanceChain:
        _paintStance(
          canvas,
          size,
          center,
          primary,
          secondary,
          guide,
          deviation,
        );
      case TrainingDiagramKind.pistolGripContact:
        _paintGripContact(canvas, size, primary, secondary, guide, deviation);
      case TrainingDiagramKind.pistolSightRelationship:
        _paintSightVariants(canvas, size, primary, secondary, guide, deviation);
      case TrainingDiagramKind.pistolMovementZone:
        _paintMovementZone(canvas, size, primary, secondary, guide, deviation);
      case TrainingDiagramKind.pistolLiftApproach:
        _paintLiftApproach(canvas, size, primary, secondary, guide, deviation);
      case TrainingDiagramKind.pistolBreathTriggerTimeline:
        _paintBreathTriggerTimeline(
          canvas,
          size,
          primary,
          secondary,
          guide,
          deviation,
        );
      case TrainingDiagramKind.pistolTriggerContact:
        _paintTrigger(
          canvas,
          size,
          center,
          primary,
          secondary,
          guide,
          deviation,
        );
      case TrainingDiagramKind.pistolAbortResetTree:
        _paintAbortResetTree(
          canvas,
          size,
          primary,
          secondary,
          guide,
          deviation,
        );
      case TrainingDiagramKind.br50RestOverview:
        _paintBenchrest(
          canvas,
          size,
          center,
          primary,
          secondary,
          guide,
          deviation,
        );
      case TrainingDiagramKind.br50RestAxisTopSide:
        _paintRestAxisTopSide(
          canvas,
          size,
          primary,
          secondary,
          guide,
          deviation,
        );
      case TrainingDiagramKind.br50ContactMap:
        _paintContactMap(canvas, size, primary, secondary, guide, deviation);
      case TrainingDiagramKind.br50RecoilReturn:
        _paintRecoilReturn(canvas, size, primary, secondary, guide, deviation);
      case TrainingDiagramKind.br50SighterRecordMap:
        _paintSighterRecordMap(
          canvas,
          size,
          primary,
          secondary,
          guide,
          deviation,
        );
      case TrainingDiagramKind.br50FiveBlocks:
        _paintFiveBlocks(canvas, size, primary, secondary, guide, deviation);
      case TrainingDiagramKind.br50ConditionBlocks:
        _paintConditionBlocks(
          canvas,
          size,
          primary,
          secondary,
          guide,
          deviation,
        );
    }

    canvas.restore();
    for (final callout in spec.callouts) {
      final anchorX = mirrored ? 1 - callout.anchor.dx : callout.anchor.dx;
      _paintCallout(
        canvas,
        Offset(anchorX * size.width, callout.anchor.dy * size.height),
        callout.number,
      );
    }
  }

  bool get _showDeviation => view == TrainingDiagramView.deviation;

  void _paintEvidenceLayers(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    const labels = ['FOTO', 'UITLIJNING', 'TREFFERS', 'SCORE'];
    for (var index = 0; index < labels.length; index++) {
      final left = size.width * (0.12 + index * 0.16);
      final top = size.height * (0.57 - index * 0.13);
      final rect = Rect.fromLTWH(
        left,
        top,
        size.width * 0.40,
        size.height * 0.23,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        index.isEven ? primary : secondary,
      );
      _paintLabel(canvas, labels[index], rect.center, 12);
    }
    _paintArrow(
      canvas,
      Offset(size.width * 0.21, size.height * 0.86),
      Offset(size.width * 0.84, size.height * 0.17),
      guide,
    );
    if (_showDeviation) {
      final mismatch = Rect.fromLTWH(
        size.width * 0.45,
        size.height * 0.38,
        size.width * 0.40,
        size.height * 0.23,
      );
      _paintDashedRect(canvas, mismatch.translate(22, 10), deviation);
      _paintCross(canvas, mismatch.bottomRight.translate(5, 5), deviation);
    }
  }

  void _paintAbba(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final y = size.height * 0.42;
    final boxWidth = size.width * 0.16;
    final centers = <Offset>[];
    for (var index = 0; index < 4; index++) {
      final center = Offset(size.width * (0.17 + 0.22 * index), y);
      centers.add(center);
      final rect = Rect.fromCenter(
        center: center,
        width: boxWidth,
        height: size.height * 0.22,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        index == 0 || index == 3 ? primary : secondary,
      );
      _paintLabel(canvas, index == 0 || index == 3 ? 'A' : 'B', center, 30);
      if (index > 0) {
        _paintArrow(
          canvas,
          centers[index - 1].translate(boxWidth / 2 + 8, 0),
          center.translate(-boxWidth / 2 - 8, 0),
          guide,
        );
      }
    }
    canvas.drawLine(
      Offset(size.width * 0.17, size.height * 0.72),
      Offset(size.width * 0.83, size.height * 0.72),
      guide,
    );
    _paintLabel(
      canvas,
      'tijd en opwarming →',
      Offset(size.width * 0.50, size.height * 0.78),
      13,
    );
    if (_showDeviation) {
      _paintDashedRect(
        canvas,
        Rect.fromCenter(
          center: centers[3],
          width: boxWidth,
          height: size.height * 0.22,
        ),
        deviation,
      );
      _paintLabel(
        canvas,
        'A–B–A–B',
        Offset(size.width * 0.50, size.height * 0.18),
        15,
        color: deviation.color,
      );
    }
  }

  void _paintNaturalAlignmentTop(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final body = Offset(size.width * 0.38, size.height * 0.55);
    canvas.drawOval(
      Rect.fromCenter(
        center: body,
        width: size.width * 0.20,
        height: size.height * 0.24,
      ),
      primary,
    );
    for (final foot in [
      Offset(size.width * 0.29, size.height * 0.78),
      Offset(size.width * 0.47, size.height * 0.78),
    ]) {
      canvas.save();
      canvas.translate(foot.dx, foot.dy);
      canvas.rotate(foot.dx < body.dx ? -0.25 : 0.18);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 52, height: 22),
        secondary,
      );
      canvas.restore();
    }
    final shoulder = body.translate(size.width * 0.07, -size.height * 0.07);
    final hand = Offset(size.width * 0.73, size.height * 0.30);
    canvas.drawLine(shoulder, hand, primary);
    canvas.drawCircle(hand, 10, secondary);
    final target = Offset(size.width * 0.86, size.height * 0.20);
    _paintBull(canvas, target, size.shortestSide * 0.075, guide, secondary);
    _paintDashedLine(canvas, body, target, guide);
    if (_showDeviation) {
      final forcedHand = hand.translate(0, size.height * 0.18);
      _paintDashedLine(canvas, shoulder, forcedHand, deviation);
      _paintArrow(
        canvas,
        body,
        body.translate(0, size.height * 0.13),
        deviation,
      );
      _paintCross(canvas, forcedHand, deviation);
    }
  }

  void _paintGripContact(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final grip = Path()
      ..moveTo(size.width * 0.42, size.height * 0.20)
      ..lineTo(size.width * 0.64, size.height * 0.26)
      ..lineTo(size.width * 0.58, size.height * 0.78)
      ..lineTo(size.width * 0.35, size.height * 0.70)
      ..close();
    canvas.drawPath(grip, primary);
    final palm = Rect.fromCenter(
      center: Offset(size.width * 0.42, size.height * 0.50),
      width: size.width * 0.20,
      height: size.height * 0.42,
    );
    canvas.drawArc(palm, -math.pi / 2, math.pi, false, secondary);
    for (var index = 0; index < 3; index++) {
      final y = size.height * (0.42 + index * 0.11);
      canvas.drawLine(
        Offset(size.width * 0.50, y),
        Offset(size.width * 0.66, y + size.height * 0.03),
        secondary,
      );
    }
    final triggerFinger = Path()
      ..moveTo(size.width * 0.45, size.height * 0.31)
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.20,
        size.width * 0.72,
        size.height * 0.36,
      );
    canvas.drawPath(triggerFinger, guide);
    if (_showDeviation) {
      canvas.drawCircle(
        Offset(size.width * 0.54, size.height * 0.60),
        38,
        deviation,
      );
      _paintCross(
        canvas,
        Offset(size.width * 0.54, size.height * 0.60),
        deviation,
      );
    }
  }

  void _paintSightVariants(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final cells = <(Offset, String, double, double)>[
      (Offset(size.width * 0.27, size.height * 0.31), 'GOED', 0, 0),
      (Offset(size.width * 0.73, size.height * 0.31), 'LINKS', -16, 0),
      (Offset(size.width * 0.27, size.height * 0.72), 'RECHTS', 16, 0),
      (Offset(size.width * 0.73, size.height * 0.72), 'HOOG', 0, -14),
    ];
    for (var index = 0; index < cells.length; index++) {
      final item = cells[index];
      final rect = Rect.fromCenter(
        center: item.$1,
        width: size.width * 0.35,
        height: size.height * 0.30,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        guide,
      );
      final y = item.$1.dy + 12;
      canvas.drawLine(
        Offset(rect.left + 18, y),
        Offset(rect.left + 18, y - 56),
        primary,
      );
      canvas.drawLine(
        Offset(rect.right - 18, y),
        Offset(rect.right - 18, y - 56),
        primary,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(item.$1.dx + item.$3, y - 23 + item.$4),
          width: 28,
          height: 48,
        ),
        index == 0 ? secondary : deviation,
      );
      _paintLabel(
        canvas,
        item.$2,
        Offset(item.$1.dx, rect.bottom - 16),
        11,
        color: index == 0 ? null : deviation.color,
      );
    }
    if (_showDeviation) {
      _paintCross(canvas, cells[1].$1, deviation);
      _paintCross(canvas, cells[2].$1, deviation);
      _paintCross(canvas, cells[3].$1, deviation);
    }
  }

  void _paintMovementZone(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final center = Offset(size.width * 0.50, size.height * 0.50);
    _paintBull(canvas, center, size.shortestSide * 0.28, guide, primary);
    final movement = Path()..moveTo(center.dx - 50, center.dy - 10);
    for (var step = 0; step <= 80; step++) {
      final t = step / 80 * math.pi * 4;
      movement.lineTo(
        center.dx + math.cos(t) * (44 + 11 * math.sin(t * 2.3)),
        center.dy + math.sin(t) * (30 + 8 * math.cos(t * 1.7)),
      );
    }
    canvas.drawPath(movement, secondary);
    canvas.drawCircle(center, 18, primary);
    if (_showDeviation) {
      final chase = Rect.fromCenter(
        center: center.translate(size.width * 0.13, -size.height * 0.12),
        width: size.width * 0.28,
        height: size.height * 0.22,
      );
      _paintDashedRect(canvas, chase, deviation);
      _paintCross(canvas, chase.center, deviation);
    }
  }

  void _paintLiftApproach(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final target = Offset(size.width * 0.69, size.height * 0.31);
    _paintBull(canvas, target, size.shortestSide * 0.16, guide, primary);
    final lift = Path()
      ..moveTo(size.width * 0.25, size.height * 0.82)
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.62,
        size.width * 0.51,
        size.height * 0.48,
        target.dx,
        target.dy,
      );
    canvas.drawPath(lift, secondary);
    _paintArrow(
      canvas,
      Offset(size.width * 0.54, size.height * 0.47),
      target,
      secondary,
    );
    final pressure = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.16,
      size.width * 0.40,
      20,
    );
    canvas.drawRect(pressure, guide);
    canvas.drawRect(
      Rect.fromLTWH(
        pressure.left,
        pressure.top,
        pressure.width * 0.72,
        pressure.height,
      ),
      primary,
    );
    _paintLabel(
      canvas,
      'voorbereidende druk',
      Offset(pressure.center.dx, pressure.top - 16),
      12,
    );
    if (_showDeviation) {
      _paintDashedLine(
        canvas,
        Offset(size.width * 0.25, size.height * 0.82),
        target.translate(size.width * 0.15, 0),
        deviation,
      );
      _paintCross(canvas, target.translate(size.width * 0.15, 0), deviation);
    }
  }

  void _paintBreathTriggerTimeline(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final left = size.width * 0.15;
    final right = size.width * 0.90;
    final rows = [size.height * 0.27, size.height * 0.51, size.height * 0.75];
    for (final row in rows) {
      canvas.drawLine(Offset(left, row), Offset(right, row), guide);
    }
    _paintLabel(canvas, 'ADEM', Offset(size.width * 0.08, rows[0]), 11);
    _paintLabel(canvas, 'ARM', Offset(size.width * 0.08, rows[1]), 11);
    _paintLabel(canvas, 'DRUK', Offset(size.width * 0.08, rows[2]), 11);
    final breath = Path()..moveTo(left, rows[0]);
    for (var x = left; x <= right; x += 3) {
      final phase = (x - left) / (right - left) * math.pi * 3;
      breath.lineTo(x, rows[0] - math.sin(phase) * size.height * 0.08);
    }
    canvas.drawPath(breath, primary);
    final arm = Path()
      ..moveTo(left, rows[1] + size.height * 0.10)
      ..quadraticBezierTo(
        size.width * 0.45,
        rows[1] - size.height * 0.08,
        size.width * 0.62,
        rows[1],
      )
      ..lineTo(right, rows[1]);
    canvas.drawPath(arm, secondary);
    final pressure = Path()
      ..moveTo(left, rows[2])
      ..lineTo(size.width * 0.62, rows[2])
      ..lineTo(size.width * 0.76, rows[2] - size.height * 0.15)
      ..lineTo(right, rows[2] - size.height * 0.15);
    canvas.drawPath(pressure, primary);
    final window = Rect.fromLTWH(
      size.width * 0.60,
      size.height * 0.14,
      size.width * 0.18,
      size.height * 0.72,
    );
    _paintDashedRect(canvas, window, secondary);
    if (_showDeviation) {
      _paintDashedLine(
        canvas,
        Offset(size.width * 0.76, rows[2]),
        Offset(right, rows[2] - size.height * 0.20),
        deviation,
      );
      _paintCross(
        canvas,
        Offset(size.width * 0.87, rows[2] - size.height * 0.18),
        deviation,
      );
    }
  }

  void _paintAbortResetTree(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final decision = Path()
      ..moveTo(size.width * 0.50, size.height * 0.14)
      ..lineTo(size.width * 0.68, size.height * 0.31)
      ..lineTo(size.width * 0.50, size.height * 0.48)
      ..lineTo(size.width * 0.32, size.height * 0.31)
      ..close();
    canvas.drawPath(decision, primary);
    _paintLabel(
      canvas,
      'UITVOERBAAR?',
      Offset(size.width * 0.50, size.height * 0.31),
      11,
    );
    final execute = Rect.fromCenter(
      center: Offset(size.width * 0.76, size.height * 0.64),
      width: size.width * 0.28,
      height: size.height * 0.18,
    );
    final reset = Rect.fromCenter(
      center: Offset(size.width * 0.24, size.height * 0.64),
      width: size.width * 0.28,
      height: size.height * 0.18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(execute, const Radius.circular(12)),
      secondary,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(reset, const Radius.circular(12)),
      deviation,
    );
    _paintLabel(canvas, 'UITVOEREN', execute.center, 12);
    _paintLabel(
      canvas,
      'ZAKKEN + RESET',
      reset.center,
      11,
      color: deviation.color,
    );
    _paintArrow(
      canvas,
      Offset(size.width * 0.63, size.height * 0.42),
      execute.topCenter,
      secondary,
    );
    _paintArrow(
      canvas,
      Offset(size.width * 0.37, size.height * 0.42),
      reset.topCenter,
      deviation,
    );
    _paintLabel(
      canvas,
      'JA',
      Offset(size.width * 0.69, size.height * 0.46),
      11,
    );
    _paintLabel(
      canvas,
      'NEE',
      Offset(size.width * 0.31, size.height * 0.46),
      11,
      color: deviation.color,
    );
    if (_showDeviation) {
      _paintDashedLine(
        canvas,
        execute.bottomCenter,
        reset.bottomCenter,
        deviation,
      );
      _paintLabel(
        canvas,
        'niet forceren',
        Offset(size.width * 0.50, size.height * 0.87),
        12,
        color: deviation.color,
      );
    }
  }

  void _paintRestAxisTopSide(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final topPanel = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.14,
      size.width * 0.41,
      size.height * 0.70,
    );
    final sidePanel = Rect.fromLTWH(
      size.width * 0.53,
      size.height * 0.14,
      size.width * 0.41,
      size.height * 0.70,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(topPanel, const Radius.circular(12)),
      guide,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sidePanel, const Radius.circular(12)),
      guide,
    );
    _paintLabel(
      canvas,
      'BOVEN',
      Offset(topPanel.center.dx, topPanel.top + 18),
      12,
    );
    _paintLabel(
      canvas,
      'ZIJ',
      Offset(sidePanel.center.dx, sidePanel.top + 18),
      12,
    );
    canvas.drawLine(
      Offset(topPanel.left + 28, topPanel.center.dy),
      Offset(topPanel.right - 28, topPanel.center.dy),
      primary,
    );
    canvas.drawCircle(
      Offset(topPanel.left + 70, topPanel.center.dy),
      20,
      secondary,
    );
    canvas.drawCircle(
      Offset(topPanel.right - 70, topPanel.center.dy),
      20,
      secondary,
    );
    _paintDashedLine(
      canvas,
      Offset(topPanel.left + 20, topPanel.center.dy),
      Offset(topPanel.right - 20, topPanel.center.dy),
      guide,
    );
    final rifleY = sidePanel.center.dy - 18;
    canvas.drawLine(
      Offset(sidePanel.left + 28, rifleY),
      Offset(sidePanel.right - 28, rifleY),
      primary,
    );
    canvas.drawLine(
      Offset(sidePanel.left + 75, rifleY),
      Offset(sidePanel.left + 60, sidePanel.bottom - 45),
      secondary,
    );
    canvas.drawLine(
      Offset(sidePanel.right - 75, rifleY),
      Offset(sidePanel.right - 60, sidePanel.bottom - 45),
      secondary,
    );
    if (_showDeviation) {
      _paintDashedLine(
        canvas,
        Offset(topPanel.left + 28, topPanel.center.dy - 30),
        Offset(topPanel.right - 28, topPanel.center.dy + 25),
        deviation,
      );
      _paintDashedLine(
        canvas,
        Offset(sidePanel.left + 28, rifleY),
        Offset(sidePanel.right - 28, rifleY + 34),
        deviation,
      );
    }
  }

  void _paintContactMap(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final y = size.height * 0.48;
    canvas.drawLine(
      Offset(size.width * 0.14, y),
      Offset(size.width * 0.82, y),
      primary,
    );
    final stock = Path()
      ..moveTo(size.width * 0.55, y - 18)
      ..lineTo(size.width * 0.86, y - 12)
      ..lineTo(size.width * 0.76, y + 85)
      ..lineTo(size.width * 0.55, y + 25)
      ..close();
    canvas.drawPath(stock, primary);
    final contacts = [
      Offset(size.width * 0.27, y + 18),
      Offset(size.width * 0.63, y + 34),
      Offset(size.width * 0.77, y + 22),
      Offset(size.width * 0.70, y - 14),
      Offset(size.width * 0.57, y + 5),
    ];
    for (var index = 0; index < contacts.length; index++) {
      canvas.drawCircle(contacts[index], 11, index < 2 ? secondary : guide);
    }
    _paintLabel(canvas, 'steun', contacts[0].translate(0, 35), 11);
    _paintLabel(canvas, 'hand', contacts[1].translate(0, 35), 11);
    _paintLabel(canvas, 'schouder', contacts[2].translate(0, 35), 11);
    if (_showDeviation) {
      canvas.drawCircle(contacts[2], 32, deviation);
      _paintCross(canvas, contacts[2], deviation);
    }
  }

  void _paintRecoilReturn(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final y = size.height * 0.48;
    final positions = [0.25, 0.50, 0.75];
    const labels = ['START', 'TERUGLOOP', 'TERUGKEER'];
    for (var index = 0; index < positions.length; index++) {
      final x = size.width * positions[index];
      canvas.drawLine(
        Offset(x - 70, y),
        Offset(x + 70, y),
        index == 1 ? secondary : primary,
      );
      canvas.drawCircle(Offset(x - 45, y + 26), 15, guide);
      _paintLabel(canvas, labels[index], Offset(x, y + 82), 11);
      if (index > 0) {
        _paintArrow(
          canvas,
          Offset(size.width * positions[index - 1] + 82, y - 38),
          Offset(x - 82, y - 38),
          guide,
        );
      }
    }
    _paintDashedLine(
      canvas,
      Offset(size.width * 0.12, y),
      Offset(size.width * 0.88, y),
      guide,
    );
    if (_showDeviation) {
      _paintDashedLine(
        canvas,
        Offset(size.width * 0.67, y - 34),
        Offset(size.width * 0.84, y + 10),
        deviation,
      );
      _paintCross(canvas, Offset(size.width * 0.84, y + 10), deviation);
    }
  }

  void _paintSighterRecordMap(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final grid = Rect.fromLTWH(
      size.width * 0.30,
      size.height * 0.12,
      size.width * 0.56,
      size.height * 0.76,
    );
    for (var row = 0; row < 5; row++) {
      for (var column = 0; column < 5; column++) {
        final center = Offset(
          grid.left + (column + 0.5) * grid.width / 5,
          grid.top + (row + 0.5) * grid.height / 5,
        );
        canvas.drawCircle(
          center,
          math.min(grid.width / 13, grid.height / 13),
          guide,
        );
        _paintLabel(canvas, '${row * 5 + column + 1}', center, 9);
      }
    }
    final sighter = Rect.fromLTWH(
      size.width * 0.07,
      grid.top,
      size.width * 0.16,
      grid.height,
    );
    _paintDashedRect(canvas, sighter, secondary);
    for (var index = 0; index < 4; index++) {
      canvas.drawCircle(
        Offset(
          sighter.center.dx,
          sighter.top + (index + 0.7) * sighter.height / 4,
        ),
        17,
        secondary,
      );
    }
    _paintLabel(
      canvas,
      'PROEF',
      Offset(sighter.center.dx, sighter.bottom + 18),
      11,
    );
    _paintLabel(
      canvas,
      'RECORD 1–25',
      Offset(grid.center.dx, grid.bottom + 18),
      11,
    );
    if (_showDeviation) {
      _paintCross(
        canvas,
        Offset(grid.left + grid.width * 0.10, grid.top + grid.height * 0.10),
        deviation,
      );
      _paintLabel(
        canvas,
        'niet verwisselen',
        Offset(size.width * 0.18, size.height * 0.08),
        10,
        color: deviation.color,
      );
    }
  }

  void _paintFiveBlocks(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final blockWidth = size.width * 0.15;
    for (var block = 0; block < 5; block++) {
      final center = Offset(
        size.width * (0.12 + block * 0.19),
        size.height * 0.46,
      );
      final rect = Rect.fromCenter(
        center: center,
        width: blockWidth,
        height: size.height * 0.45,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        block.isEven ? primary : secondary,
      );
      for (var item = 0; item < 5; item++) {
        canvas.drawCircle(
          Offset(center.dx, rect.top + 34 + item * (rect.height - 68) / 4),
          8,
          guide,
        );
      }
      _paintLabel(
        canvas,
        'B${block + 1}',
        Offset(center.dx, rect.bottom + 22),
        12,
      );
      if (block < 4) {
        _paintArrow(
          canvas,
          Offset(rect.right + 4, center.dy),
          Offset(rect.right + size.width * 0.04, center.dy),
          guide,
        );
      }
    }
    if (_showDeviation) {
      _paintDashedRect(
        canvas,
        Rect.fromCenter(
          center: Offset(size.width * 0.50, size.height * 0.46),
          width: blockWidth,
          height: size.height * 0.45,
        ),
        deviation,
      );
      _paintLabel(
        canvas,
        'reset gemist',
        Offset(size.width * 0.50, size.height * 0.12),
        11,
        color: deviation.color,
      );
    }
  }

  void _paintConditionBlocks(
    Canvas canvas,
    Size size,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final left = size.width * 0.10;
    final right = size.width * 0.92;
    final y = size.height * 0.58;
    canvas.drawLine(Offset(left, y), Offset(right, y), guide);
    for (var block = 0; block < 5; block++) {
      final x = left + (block + 0.5) * (right - left) / 5;
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: (right - left) / 5 - 8,
        height: size.height * 0.28,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        block.isEven ? primary : secondary,
      );
      _paintLabel(canvas, 'B${block + 1}', Offset(x, rect.bottom - 18), 11);
      final direction = block.isEven ? 1.0 : -1.0;
      _paintArrow(
        canvas,
        Offset(x - 25 * direction, rect.top - 38),
        Offset(x + 25 * direction, rect.top - 38),
        block == 3 ? deviation : guide,
      );
      canvas.drawCircle(
        Offset(x, rect.center.dy - 18),
        7 + block * 1.5,
        block == 3 ? deviation : guide,
      );
    }
    _paintLabel(
      canvas,
      'tijd →',
      Offset(size.width * 0.50, size.height * 0.82),
      12,
    );
    if (_showDeviation) {
      _paintDashedLine(
        canvas,
        Offset(size.width * 0.66, size.height * 0.18),
        Offset(size.width * 0.66, size.height * 0.78),
        deviation,
      );
      _paintLabel(
        canvas,
        'omslag',
        Offset(size.width * 0.66, size.height * 0.12),
        11,
        color: deviation.color,
      );
    }
  }

  void _paintSafety(
    Canvas canvas,
    Size size,
    Offset center,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final shield = Path()
      ..moveTo(center.dx, size.height * 0.14)
      ..quadraticBezierTo(
        size.width * 0.72,
        size.height * 0.22,
        size.width * 0.72,
        size.height * 0.44,
      )
      ..quadraticBezierTo(
        size.width * 0.70,
        size.height * 0.70,
        center.dx,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.70,
        size.width * 0.28,
        size.height * 0.44,
      )
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.22,
        center.dx,
        size.height * 0.14,
      );
    canvas.drawPath(shield, primary);
    canvas.drawLine(
      Offset(size.width * 0.34, center.dy),
      Offset(size.width * 0.66, center.dy),
      secondary,
    );
    _paintArrow(
      canvas,
      Offset(size.width * 0.38, center.dy),
      Offset(size.width * 0.62, center.dy),
      secondary,
    );
    canvas.drawCircle(center.translate(0, size.height * 0.13), 22, guide);
    if (_showDeviation) {
      _paintDashedLine(
        canvas,
        Offset(size.width * 0.38, center.dy),
        Offset(size.width * 0.60, size.height * 0.36),
        deviation,
      );
      _paintCross(
        canvas,
        Offset(size.width * 0.62, size.height * 0.34),
        deviation,
      );
    }
  }

  void _paintStance(
    Canvas canvas,
    Size size,
    Offset center,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final head = Offset(size.width * 0.42, size.height * 0.28);
    canvas.drawCircle(head, size.shortestSide * 0.06, primary);
    canvas.drawLine(
      head.translate(0, size.height * 0.06),
      Offset(size.width * 0.43, size.height * 0.63),
      primary,
    );
    canvas.drawLine(
      Offset(size.width * 0.43, size.height * 0.42),
      Offset(size.width * 0.68, size.height * 0.37),
      secondary,
    );
    canvas.drawLine(
      Offset(size.width * 0.43, size.height * 0.62),
      Offset(size.width * 0.31, size.height * 0.82),
      primary,
    );
    canvas.drawLine(
      Offset(size.width * 0.43, size.height * 0.62),
      Offset(size.width * 0.56, size.height * 0.82),
      primary,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.84),
      Offset(size.width * 0.67, size.height * 0.84),
      guide,
    );
    _paintArrow(
      canvas,
      Offset(size.width * 0.48, size.height * 0.26),
      Offset(size.width * 0.84, size.height * 0.26),
      guide,
    );
    if (_showDeviation) {
      _paintDashedLine(
        canvas,
        head.translate(size.width * 0.08, 0),
        Offset(size.width * 0.52, size.height * 0.65),
        deviation,
      );
      _paintCross(
        canvas,
        Offset(size.width * 0.64, size.height * 0.78),
        deviation,
      );
    }
  }

  void _paintTrigger(
    Canvas canvas,
    Size size,
    Offset center,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, -size.height * 0.05),
        width: size.width * 0.36,
        height: size.height * 0.45,
      ),
      math.pi,
      math.pi,
      false,
      primary,
    );
    final finger = Path()
      ..moveTo(size.width * 0.23, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * 0.74,
        size.width * 0.70,
        size.height * 0.52,
      );
    canvas.drawPath(finger, secondary);
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.74),
      Offset(size.width * 0.80, size.height * 0.74),
      guide,
    );
    _paintArrow(
      canvas,
      Offset(size.width * 0.35, size.height * 0.82),
      Offset(size.width * 0.70, size.height * 0.82),
      primary,
    );
    if (_showDeviation) {
      _paintArrow(
        canvas,
        Offset(size.width * 0.43, size.height * 0.67),
        Offset(size.width * 0.69, size.height * 0.47),
        deviation,
      );
    }
  }

  void _paintBenchrest(
    Canvas canvas,
    Size size,
    Offset center,
    Paint primary,
    Paint secondary,
    Paint guide,
    Paint deviation,
  ) {
    final tableY = size.height * 0.74;
    canvas.drawLine(
      Offset(size.width * 0.10, tableY),
      Offset(size.width * 0.90, tableY),
      primary,
    );
    canvas.drawLine(
      Offset(size.width * 0.20, size.height * 0.39),
      Offset(size.width * 0.82, size.height * 0.39),
      secondary,
    );
    canvas.drawLine(
      Offset(size.width * 0.32, size.height * 0.39),
      Offset(size.width * 0.27, tableY),
      primary,
    );
    canvas.drawLine(
      Offset(size.width * 0.69, size.height * 0.39),
      Offset(size.width * 0.75, tableY),
      primary,
    );
    canvas.drawCircle(
      Offset(size.width * 0.20, size.height * 0.39),
      size.shortestSide * 0.035,
      secondary,
    );
    _paintArrow(
      canvas,
      Offset(size.width * 0.24, size.height * 0.28),
      Offset(size.width * 0.78, size.height * 0.28),
      guide,
    );
    if (_showDeviation) {
      _paintDashedLine(
        canvas,
        Offset(size.width * 0.20, size.height * 0.34),
        Offset(size.width * 0.82, size.height * 0.48),
        deviation,
      );
      _paintCross(
        canvas,
        Offset(size.width * 0.55, size.height * 0.47),
        deviation,
      );
    }
  }

  void _paintBull(
    Canvas canvas,
    Offset center,
    double radius,
    Paint ringPaint,
    Paint centerPaint,
  ) {
    for (final factor in const [1.0, 0.68, 0.36]) {
      canvas.drawCircle(center, radius * factor, ringPaint);
    }
    canvas.drawCircle(center, 5, centerPaint);
    canvas.drawLine(
      center.translate(-radius * 1.15, 0),
      center.translate(radius * 1.15, 0),
      ringPaint,
    );
    canvas.drawLine(
      center.translate(0, -radius * 1.15),
      center.translate(0, radius * 1.15),
      ringPaint,
    );
  }

  void _paintLabel(
    Canvas canvas,
    String label,
    Offset center,
    double fontSize, {
    Color? color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color ?? colorScheme.onSurface,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _paintCallout(Canvas canvas, Offset point, int number) {
    final fill = Paint()
      ..color = colorScheme.primaryContainer
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(point, 15, fill);
    canvas.drawCircle(point, 15, border);
    final painter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      point - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _paintArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const length = 13.0;
    canvas.drawLine(
      to,
      to.translate(
        -math.cos(angle - math.pi / 6) * length,
        -math.sin(angle - math.pi / 6) * length,
      ),
      paint,
    );
    canvas.drawLine(
      to,
      to.translate(
        -math.cos(angle + math.pi / 6) * length,
        -math.sin(angle + math.pi / 6) * length,
      ),
      paint,
    );
  }

  void _paintCross(Canvas canvas, Offset center, Paint paint) {
    const size = 13.0;
    canvas.drawLine(
      center.translate(-size, -size),
      center.translate(size, size),
      paint,
    );
    canvas.drawLine(
      center.translate(-size, size),
      center.translate(size, -size),
      paint,
    );
  }

  void _paintDashedRect(Canvas canvas, Rect rect, Paint paint) {
    _paintDashedLine(canvas, rect.topLeft, rect.topRight, paint);
    _paintDashedLine(canvas, rect.topRight, rect.bottomRight, paint);
    _paintDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint);
    _paintDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint);
  }

  void _paintDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 10, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 17;
      }
    }
  }

  void _paintDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);
    _paintDashedPath(canvas, path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrainingDiagramPainter oldDelegate) =>
      oldDelegate.spec != spec ||
      oldDelegate.view != view ||
      oldDelegate.mirrored != mirrored ||
      oldDelegate.colorScheme != colorScheme;
}
