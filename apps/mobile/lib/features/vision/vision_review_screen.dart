import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;
import 'package:shooting_companion_scoring/scoring.dart';
import 'package:shooting_companion_vision_api/vision_api.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/vision_scan_repository.dart';
import '../../widgets/app_action_dock.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/safe_sheet_scaffold.dart';
import '../photo/photo_canvas_models.dart';
import '../photo/photo_overlay_canvas.dart';
import '../scoring/transformable_scoring_viewport.dart';
import '../session/active_session_screen.dart';
import 'vision_candidate_geometry.dart';

class VisionReviewScreen extends ConsumerStatefulWidget {
  const VisionReviewScreen({required this.scanId, super.key});

  final String scanId;

  @override
  ConsumerState<VisionReviewScreen> createState() => _VisionReviewScreenState();
}

class _VisionReviewScreenState extends ConsumerState<VisionReviewScreen> {
  static const _uuid = Uuid();
  final _viewport = ScoringViewportController();
  final List<List<_ReviewEntry>> _undo = [];
  Timer? _autosave;
  List<_ReviewEntry> _entries = [];
  VisionScanDraftRecord? _draft;
  domain.TargetProfile? _target;
  geo.ManualPhotoAlignment? _alignment;
  String? _selectedId;
  ScoringTool _tool = ScoringTool.place;
  bool _precision = false;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _autosave?.cancel();
    _viewport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(visionScanDraftProvider(widget.scanId));
    return scan.when(
      data: (draft) {
        if (draft == null) {
          return const Scaffold(
            body: Center(child: Text('Deze conceptscan bestaat niet meer.')),
          );
        }
        _initializeOnce(draft);
        if (!_initialized || _alignment == null || _target == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildEditor(context);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Score controleren')),
        body: Center(child: Text('Review laden mislukt: $error')),
      ),
    );
  }

  void _initializeOnce(VisionScanDraftRecord draft) {
    if (_initialized) return;
    _initialized = true;
    _draft = draft;
    _target = domain.TargetProfile.fromJsonString(draft.targetProfileJson);
    final registration = VisionRegistrationResult.fromJson(
      (jsonDecode(draft.registrationJson!) as Map).cast<String, Object?>(),
    );
    final corners = registration.orderedSourceCornersNormalized;
    if (corners.length != 4) {
      _initialized = false;
      return;
    }
    final result = geo.ManualPhotoAlignment.build(
      corners: geo.NormalizedQuad.fromOrderedPoints(
        corners.map((point) => geo.NormalizedPoint(point.x, point.y)).toList(),
      ),
      cardWidthMm: _target!.physicalCardWidthMm,
      cardHeightMm: _target!.physicalCardHeightMm,
    );
    _alignment = result.alignment;
    if (_alignment == null) return;
    if (draft.reviewJson != null) {
      try {
        final map = (jsonDecode(draft.reviewJson!) as Map)
            .cast<String, Object?>();
        _entries = (map['entries'] as List<Object?>? ?? const [])
            .map(
              (item) =>
                  _ReviewEntry.fromJson((item! as Map).cast<String, Object?>()),
            )
            .toList();
        return;
      } catch (_) {
        // A damaged review is rebuilt from the immutable native candidates.
      }
    }
    final candidates = (jsonDecode(draft.candidatesJson!) as List)
        .map(
          (item) => VisionCandidateImpact.fromJson(
            (item as Map).cast<String, Object?>(),
          ),
        )
        .toList();
    _entries = [
      for (final candidate in candidates)
        _ReviewEntry.fromCandidate(widget.scanId, candidate),
    ];
  }

  Widget _buildEditor(BuildContext context) {
    final score = _score;
    final selected = _entryById(_selectedId);
    final included = _entries.where((entry) => entry.accepted).length;
    final suggestions = _entries.where((entry) => !entry.accepted).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score controleren'),
        actions: [
          IconButton(
            tooltip: 'Punten en suggesties',
            onPressed: _openPoints,
            icon: Badge(
              label: Text('${_entries.length}'),
              child: const Icon(Icons.format_list_numbered),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _StepIndicatorReview(),
                  const SizedBox(height: 8),
                  Text(
                    '${_entries.length} voorgestelde/ingevoerde punten · '
                    '$included opgenomen · $suggestions niet opgenomen',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (selected?.candidateId != null)
                    Text(
                      selected!.explanation,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  Text(
                    'Voorlopige score ${score.total}/${score.maximumPossible}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SegmentedButton<ScoringTool>(
                        segments: const [
                          ButtonSegment(
                            value: ScoringTool.place,
                            icon: Icon(Icons.add_location_alt_outlined),
                            label: Text('Plaatsen'),
                          ),
                          ButtonSegment(
                            value: ScoringTool.edit,
                            icon: Icon(Icons.edit_location_alt_outlined),
                            label: Text('Bewerken'),
                          ),
                        ],
                        selected: {_tool},
                        onSelectionChanged: (value) => setState(() {
                          _tool = value.single;
                          if (_tool == ScoringTool.place) _selectedId = null;
                        }),
                      ),
                      FilterChip(
                        selected: _precision,
                        avatar: const Icon(Icons.center_focus_strong, size: 18),
                        label: const Text('Precisie'),
                        onSelected: (value) =>
                            setState(() => _precision = value),
                      ),
                      if (_precision)
                        FilledButton.tonalIcon(
                          onPressed: _placeAtCrosshair,
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Punt plaatsen'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PhotoOverlayCanvas(
                    imageProvider: FileImage(File(_draft!.originalImagePath)),
                    imagePixelSize: Size(
                      _draft!.width.toDouble(),
                      _draft!.height.toDouble(),
                    ),
                    alignment: _alignment!,
                    impacts: _canvasImpacts(score),
                    projectileDiameterMm: _draft!.projectileDiameterMm,
                    tool: _tool,
                    precisionMode: _precision,
                    selectedImpactId: _selectedId,
                    viewportController: _viewport,
                    semanticsLabel:
                        'Experimenteel scorevoorstel met ${_entries.length} '
                        'punten en suggesties',
                    onCanvasTap: _addPoint,
                    onImpactSelected: (id) => setState(() => _selectedId = id),
                    onImpactLongPressed: (id) => setState(() {
                      _selectedId = id;
                      _tool = ScoringTool.edit;
                      _precision = false;
                    }),
                    onImpactMoved: _movePoint,
                    onInvalidPosition: () => AppMessenger.warning(
                      context,
                      'Buiten de uitgelijnde kaart — gebruik Misser / 0.',
                    ),
                  ),
                ),
              ),
            ),
            _editorTools(),
          ],
        ),
      ),
      bottomNavigationBar: AppActionDock(
        leading: Text(
          '${score.total}/${score.maximumPossible} · ${score.innerTenCount} X · '
          '${score.actualShotCount} schoten',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          OutlinedButton(
            onPressed: _saving ? null : _saveForLater,
            child: const Text('Later koppelen'),
          ),
          FilledButton(
            onPressed: _saving || score.actualShotCount == 0
                ? null
                : _confirmScore,
            child: const Text('Score klopt'),
          ),
        ],
      ),
    );
  }

  Widget _editorTools() {
    final selected = _entryById(_selectedId);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton.outlined(
                  tooltip: 'Misser / 0 toevoegen',
                  onPressed: _addMiss,
                  icon: const Icon(Icons.close),
                ),
                IconButton.outlined(
                  tooltip: 'Ongedaan maken',
                  onPressed: _undo.isEmpty ? null : _undoLast,
                  icon: const Icon(Icons.undo),
                ),
                IconButton.outlined(
                  tooltip: 'Punten en suggesties',
                  onPressed: _openPoints,
                  icon: const Icon(Icons.format_list_numbered),
                ),
              ],
            ),
            if (selected != null)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    selected.accepted
                        ? 'Punt ${_entries.indexOf(selected) + 1} · ×${selected.impact.multiplicity}'
                        : 'Suggestie · telt niet mee',
                  ),
                  if (!selected.accepted)
                    FilledButton.tonal(
                      onPressed: () => _setAccepted(selected.id, true),
                      child: const Text('Opnemen'),
                    )
                  else ...[
                    IconButton.outlined(
                      tooltip: 'Multipliciteit verlagen',
                      onPressed: selected.impact.multiplicity > 1
                          ? () => _changeMultiplicity(selected.id, -1)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text('×${selected.impact.multiplicity}'),
                    IconButton.outlined(
                      tooltip: 'Multipliciteit verhogen',
                      onPressed: () => _changeMultiplicity(selected.id, 1),
                      icon: const Icon(Icons.add),
                    ),
                    if (selected.candidateId != null)
                      TextButton(
                        onPressed: () => _setAccepted(selected.id, false),
                        child: const Text('Afwijzen'),
                      ),
                    IconButton.outlined(
                      tooltip: 'Punt verwijderen',
                      onPressed: () => _deleteEntry(selected.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  ScoreResult get _score => ScoreEngine.score(
    target: _target!,
    impacts: _entries
        .where((entry) => entry.accepted)
        .map((entry) => entry.impact),
    projectileDiameterMm: _draft!.projectileDiameterMm,
  );

  List<PhotoCanvasImpact> _canvasImpacts(ScoreResult score) {
    final labels = {
      for (final shot in score.shots) shot.impact.id: '${shot.value}',
    };
    var sequence = 0;
    return [
      for (final entry in _entries)
        if (!entry.impact.isMiss)
          PhotoCanvasImpact(
            id: entry.id,
            positionMm: geo.PhysicalPointMm(entry.impact.xMm, entry.impact.yMm),
            sequenceNumber: ++sequence,
            scoreLabel: entry.accepted ? labels[entry.id] : 'suggestie',
            multiplicity: entry.impact.multiplicity,
            isPositionUncertain: entry.impact.isPositionUncertain,
            style: !entry.accepted
                ? PhotoCanvasImpactStyle.suggestion
                : entry.needsReview
                ? PhotoCanvasImpactStyle.needsReview
                : PhotoCanvasImpactStyle.confirmed,
          ),
    ];
  }

  _ReviewEntry? _entryById(String? id) {
    if (id == null) return null;
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  void _mutate(void Function() operation) {
    _undo.add(_entries.map((entry) => entry.copy()).toList(growable: false));
    if (_undo.length > 50) _undo.removeAt(0);
    setState(operation);
    _scheduleAutosave();
  }

  void _addPoint(PhotoCanvasPosition position) {
    _mutate(() {
      final id = _uuid.v7();
      _entries.add(
        _ReviewEntry(
          id: id,
          accepted: true,
          needsReview: false,
          impact: domain.ShotImpact(
            id: id,
            xMm: position.physicalMm.x,
            yMm: position.physicalMm.y,
            imageXNormalized: position.normalized.x,
            imageYNormalized: position.normalized.y,
            placementMethod: domain.ImpactPlacementMethod.assistedEdited,
          ),
        ),
      );
      _selectedId = id;
    });
  }

  void _placeAtCrosshair() {
    final normalized = _viewport.viewportCenterNormalized;
    if (normalized == null) {
      AppMessenger.warning(
        context,
        'Plaats het precisiekruis binnen de kaart.',
      );
      return;
    }
    final point = geo.NormalizedPoint(normalized.dx, normalized.dy);
    final physical = _alignment!.normalizedToPhysical(point);
    _addPoint(PhotoCanvasPosition(normalized: point, physicalMm: physical));
  }

  void _movePoint(String id, PhotoCanvasPosition position) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    _mutate(() {
      final old = _entries[index];
      _entries[index] = old.copyWith(
        accepted: true,
        impact: old.impact.copyWith(
          xMm: position.physicalMm.x,
          yMm: position.physicalMm.y,
          imageXNormalized: position.normalized.x,
          imageYNormalized: position.normalized.y,
          placementMethod: domain.ImpactPlacementMethod.assistedEdited,
        ),
      );
    });
  }

  void _addMiss() {
    _mutate(() {
      final id = _uuid.v7();
      _entries.add(
        _ReviewEntry(
          id: id,
          accepted: true,
          needsReview: false,
          impact: domain.ShotImpact(
            id: id,
            xMm: 0,
            yMm: 0,
            isMiss: true,
            placementMethod: domain.ImpactPlacementMethod.assistedEdited,
          ),
        ),
      );
      _selectedId = id;
    });
  }

  void _setAccepted(String id, bool accepted) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    _mutate(
      () => _entries[index] = _entries[index].copyWith(accepted: accepted),
    );
  }

  void _changeMultiplicity(String id, int delta) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    final next = _entries[index].impact.multiplicity + delta;
    if (next < 1) return;
    _mutate(() {
      final old = _entries[index];
      _entries[index] = old.copyWith(
        impact: old.impact.copyWith(
          multiplicity: next,
          placementMethod: domain.ImpactPlacementMethod.assistedEdited,
        ),
      );
    });
  }

  void _deleteEntry(String id) {
    _mutate(() {
      _entries.removeWhere((entry) => entry.id == id);
      if (_selectedId == id) _selectedId = null;
    });
  }

  void _undoLast() {
    if (_undo.isEmpty) return;
    _viewport.cancelInteraction();
    setState(() {
      _entries = _undo.removeLast();
      if (_entryById(_selectedId) == null) _selectedId = null;
    });
    _scheduleAutosave();
  }

  Future<void> _openPoints() async {
    await showSafeModalSheet<void>(
      context: context,
      presentation: SafeSheetPresentation.adaptive,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeSheetScaffold(
          title: 'Punten en suggesties',
          actions: const [],
          body: Column(
            children: [
              if (_entries.isEmpty) const Text('Nog geen punten.'),
              for (var index = 0; index < _entries.length; index++)
                ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(
                    _entries[index].impact.isMiss
                        ? 'Misser · 0'
                        : _entries[index].accepted
                        ? 'Opgenomen · ×${_entries[index].impact.multiplicity}'
                        : 'Suggestie · telt niet mee',
                  ),
                  subtitle: Text(_entries[index].explanation),
                  trailing: _entries[index].accepted
                      ? const Icon(Icons.check_circle_outline)
                      : const Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    final entry = _entries[index];
                    Navigator.pop(sheetContext);
                    setState(() {
                      _selectedId = entry.id;
                      _tool = ScoringTool.edit;
                      _precision = false;
                    });
                    if (!entry.impact.isMiss) _viewport.focusImpact(entry.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleAutosave() {
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 300), () {
      unawaited(
        ref
            .read(visionScanRepositoryProvider)
            .saveReview(
              scanId: widget.scanId,
              review: _reviewJson,
              readyToLink: false,
            ),
      );
    });
  }

  Map<String, Object?> get _reviewJson => {
    'schemaVersion': 1,
    'entries': _entries.map((entry) => entry.toJson()).toList(),
    'updatedAtUtc': DateTime.now().toUtc().toIso8601String(),
  };

  Future<void> _saveForLater() async {
    _autosave?.cancel();
    setState(() => _saving = true);
    try {
      await ref
          .read(visionScanRepositoryProvider)
          .saveReview(
            scanId: widget.scanId,
            review: _reviewJson,
            readyToLink: true,
          );
      if (mounted) {
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.pop();
      }
    } catch (error) {
      if (mounted) {
        AppMessenger.error(context, 'Review bewaren mislukt: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmScore() async {
    final warnings = _entries
        .where((entry) => entry.accepted && entry.needsReview)
        .length;
    if (warnings > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Waarschuwingen gecontroleerd?'),
          content: Text(
            '$warnings opgenomen punt${warnings == 1 ? '' : 'en'} '
            'heeft middelmatige zekerheid of ligt dicht bij een scoringslijn.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Verder controleren'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ik heb ze gecontroleerd'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    await ref
        .read(visionScanRepositoryProvider)
        .saveReview(
          scanId: widget.scanId,
          review: _reviewJson,
          readyToLink: true,
        );
    if (!mounted) return;
    final selection = await _chooseDestination();
    if (selection == null || !mounted) return;
    if (selection.destination == null) {
      await _saveForLater();
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await ref
          .read(visionScanRepositoryProvider)
          .commitReviewedVisionScan(
            scanId: widget.scanId,
            destination: selection.destination!,
            confirmedImpacts: _entries
                .where((entry) => entry.accepted)
                .map((entry) => entry.impact)
                .toList(),
            review: _reviewJson,
            distanceMeters: selection.metadata.distanceMeters,
            firearmId: selection.metadata.firearmId,
            ammoLotId: selection.metadata.ammoLotId,
          );
      if (!mounted) return;
      AppMessenger.success(context, 'Fotoscore als reeks bewaard');
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ActiveSessionScreen(sessionId: result.sessionId),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (mounted) AppMessenger.error(context, 'Koppelen mislukt: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<_VisionDestinationSelection?> _chooseDestination() async {
    final active = await ref.read(activeSessionProvider.future);
    final metadata = await ref
        .read(visionScanRepositoryProvider)
        .suggestedSeriesMetadata();
    final firearms = (await ref.read(firearmsProvider.future))
        .where(
          (item) =>
              item.defaultCartridgeId == null ||
              item.defaultCartridgeId == 'cartridge-22-lr',
        )
        .toList(growable: false);
    final ammoLots = (await ref.read(ammoLotsProvider.future))
        .where((item) => item.cartridgeId == 'cartridge-22-lr')
        .toList(growable: false);
    var hasEmptyDraft = false;
    if (active != null) {
      final series = await ref.read(seriesProvider(active.id).future);
      for (final item in series.where(
        (item) => item.status == domain.SeriesStatus.draft.name,
      )) {
        final images = await ref.read(seriesImagesProvider(item.id).future);
        if (item.shotCount == 0 &&
            images.isEmpty &&
            (item.notes?.trim().isEmpty ?? true)) {
          hasEmptyDraft = true;
          break;
        }
      }
    }
    if (!mounted) return null;
    return showSafeModalSheet<_VisionDestinationSelection>(
      context: context,
      presentation: SafeSheetPresentation.compact,
      builder: (sheetContext) => _VisionDestinationSheet(
        initialMetadata: metadata,
        firearms: firearms,
        ammoLots: ammoLots,
        hasActiveSession: active != null,
        hasEmptyDraft: hasEmptyDraft,
      ),
    );
  }
}

class _VisionDestinationSelection {
  const _VisionDestinationSelection({
    required this.destination,
    required this.metadata,
  });

  final VisionScanDestination? destination;
  final VisionSeriesMetadata metadata;
}

class _VisionDestinationSheet extends StatefulWidget {
  const _VisionDestinationSheet({
    required this.initialMetadata,
    required this.firearms,
    required this.ammoLots,
    required this.hasActiveSession,
    required this.hasEmptyDraft,
  });

  final VisionSeriesMetadata initialMetadata;
  final List<FirearmRecord> firearms;
  final List<AmmoLotRecord> ammoLots;
  final bool hasActiveSession;
  final bool hasEmptyDraft;

  @override
  State<_VisionDestinationSheet> createState() =>
      _VisionDestinationSheetState();
}

class _VisionDestinationSheetState extends State<_VisionDestinationSheet> {
  late VisionSeriesMetadata _metadata = widget.initialMetadata;

  @override
  Widget build(BuildContext context) => SafeSheetScaffold(
    title: 'Reeks bewaren',
    contentSized: true,
    actions: const [],
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: Text(_metadataSummary)),
                TextButton(
                  onPressed: _editMetadata,
                  child: const Text('Wijzig'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.hasActiveSession)
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Nieuwe reeks in actieve sessie'),
            onTap: () =>
                _finish(VisionScanDestination.newSeriesInActiveSession),
          ),
        if (widget.hasActiveSession && widget.hasEmptyDraft)
          ListTile(
            leading: const Icon(Icons.edit_note_outlined),
            title: const Text('Actief leeg concept gebruiken'),
            onTap: () => _finish(VisionScanDestination.useEmptyActiveDraft),
          ),
        if (!widget.hasActiveSession)
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Nieuwe snelle sessie'),
            subtitle: const Text('Maakt de scan meteen de eerste reeks'),
            onTap: () => _finish(VisionScanDestination.newQuickSession),
          ),
        ListTile(
          leading: const Icon(Icons.schedule_outlined),
          title: const Text('Later koppelen'),
          onTap: () => Navigator.pop(
            context,
            _VisionDestinationSelection(destination: null, metadata: _metadata),
          ),
        ),
      ],
    ),
  );

  String get _metadataSummary {
    final firearm = widget.firearms
        .where((item) => item.id == _metadata.firearmId)
        .firstOrNull;
    final ammo = widget.ammoLots
        .where((item) => item.id == _metadata.ammoLotId)
        .firstOrNull;
    return [
      'ISSF Precision · .22 LR · ${_formatDistance(_metadata.distanceMeters)} m',
      if (firearm != null) firearm.name,
      if (ammo != null) ammo.displayName,
    ].join('\n');
  }

  Future<void> _editMetadata() async {
    final result = await showSafeModalSheet<VisionSeriesMetadata>(
      context: context,
      presentation: SafeSheetPresentation.adaptive,
      builder: (_) => _VisionMetadataSheet(
        initial: _metadata,
        firearms: widget.firearms,
        ammoLots: widget.ammoLots,
      ),
    );
    if (result != null && mounted) setState(() => _metadata = result);
  }

  void _finish(VisionScanDestination destination) => Navigator.pop(
    context,
    _VisionDestinationSelection(destination: destination, metadata: _metadata),
  );
}

class _VisionMetadataSheet extends StatefulWidget {
  const _VisionMetadataSheet({
    required this.initial,
    required this.firearms,
    required this.ammoLots,
  });

  final VisionSeriesMetadata initial;
  final List<FirearmRecord> firearms;
  final List<AmmoLotRecord> ammoLots;

  @override
  State<_VisionMetadataSheet> createState() => _VisionMetadataSheetState();
}

class _VisionMetadataSheetState extends State<_VisionMetadataSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _distance = TextEditingController(
    text: _formatDistance(widget.initial.distanceMeters),
  );
  late String? _firearmId = widget.initial.firearmId;
  late String? _ammoLotId = widget.initial.ammoLotId;

  @override
  void dispose() {
    _distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeSheetScaffold(
    title: 'Reeksgegevens',
    actions: [FilledButton(onPressed: _apply, child: const Text('Toepassen'))],
    body: Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _distance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Afstand',
              suffixText: 'm',
            ),
            validator: (value) {
              final parsed = _parseDistance(value);
              return parsed == null || parsed <= 0
                  ? 'Voer een geldige afstand in.'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          AppSelectField<String?>(
            label: 'Wapen',
            initialValue: _firearmId,
            options: [
              const AppSelectOption(value: null, label: 'Niet opgegeven'),
              for (final item in widget.firearms)
                AppSelectOption(value: item.id, label: item.name),
            ],
            onChanged: (value) => _firearmId = value,
          ),
          const SizedBox(height: 16),
          AppSelectField<String?>(
            label: 'Munitie',
            initialValue: _ammoLotId,
            options: [
              const AppSelectOption(value: null, label: 'Niet opgegeven'),
              for (final item in widget.ammoLots)
                AppSelectOption(value: item.id, label: item.displayName),
            ],
            onChanged: (value) => _ammoLotId = value,
          ),
        ],
      ),
    ),
  );

  void _apply() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(
      context,
      VisionSeriesMetadata(
        distanceMeters: _parseDistance(_distance.text)!,
        firearmId: _firearmId,
        ammoLotId: _ammoLotId,
      ),
    );
  }
}

double? _parseDistance(String? value) =>
    double.tryParse((value ?? '').trim().replaceAll(',', '.'));

String _formatDistance(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

class _ReviewEntry {
  const _ReviewEntry({
    required this.id,
    required this.impact,
    required this.accepted,
    required this.needsReview,
    this.candidateId,
    this.confidenceBand,
    this.reasons = const [],
  });

  factory _ReviewEntry.fromCandidate(
    String scanId,
    VisionCandidateImpact candidate,
  ) {
    final accepted = visionCandidateAcceptedByDefault(candidate);
    return _ReviewEntry(
      id: '$scanId-${candidate.id}',
      candidateId: candidate.id,
      accepted: accepted,
      needsReview:
          candidate.confidenceBand != VisionConfidenceBand.high ||
          candidate.nearScoringBoundary,
      confidenceBand: candidate.confidenceBand,
      reasons: candidate.reasons,
      impact: domain.ShotImpact(
        id: '$scanId-${candidate.id}',
        xMm: candidate.cardXMm,
        yMm: candidate.cardYMm,
        imageXNormalized: candidate.sourceImageXNormalized,
        imageYNormalized: candidate.sourceImageYNormalized,
        isPositionUncertain:
            candidate.confidenceBand != VisionConfidenceBand.high ||
            candidate.nearScoringBoundary,
        placementMethod: domain.ImpactPlacementMethod.assistedAccepted,
        positionalUncertaintyMm: candidate.boundaryUncertaintyMm,
      ),
    );
  }

  final String id;
  final String? candidateId;
  final domain.ShotImpact impact;
  final bool accepted;
  final bool needsReview;
  final VisionConfidenceBand? confidenceBand;
  final List<VisionCandidateReason> reasons;

  String get confidenceLabel => switch (confidenceBand) {
    VisionConfidenceBand.high => 'Hoge zekerheid',
    VisionConfidenceBand.medium => 'Middelmatige zekerheid',
    VisionConfidenceBand.low => 'Lage zekerheid',
    null =>
      impact.isMiss ? 'Handmatig toegevoegde misser' : 'Handmatig toegevoegd',
  };

  String get explanation {
    if (reasons.isEmpty) return confidenceLabel;
    final details = reasons.map(_reasonLabel).join(', ');
    return '$confidenceLabel · $details';
  }

  _ReviewEntry copy() => _ReviewEntry(
    id: id,
    candidateId: candidateId,
    impact: impact,
    accepted: accepted,
    needsReview: needsReview,
    confidenceBand: confidenceBand,
    reasons: reasons,
  );

  _ReviewEntry copyWith({domain.ShotImpact? impact, bool? accepted}) =>
      _ReviewEntry(
        id: id,
        candidateId: candidateId,
        impact: impact ?? this.impact,
        accepted: accepted ?? this.accepted,
        needsReview: needsReview,
        confidenceBand: confidenceBand,
        reasons: reasons,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'candidateId': candidateId,
    'accepted': accepted,
    'needsReview': needsReview,
    'confidenceBand': confidenceBand?.name,
    'reasons': reasons.map((reason) => reason.name).toList(),
    'impact': {
      'id': impact.id,
      'xMm': impact.xMm,
      'yMm': impact.yMm,
      'imageXNormalized': impact.imageXNormalized,
      'imageYNormalized': impact.imageYNormalized,
      'multiplicity': impact.multiplicity,
      'isMiss': impact.isMiss,
      'isPositionUncertain': impact.isPositionUncertain,
      'placementMethod': impact.placementMethod.name,
      'positionalUncertaintyMm': impact.positionalUncertaintyMm,
    },
  };

  factory _ReviewEntry.fromJson(Map<String, Object?> json) {
    final impact = (json['impact']! as Map).cast<String, Object?>();
    return _ReviewEntry(
      id: json['id']! as String,
      candidateId: json['candidateId'] as String?,
      accepted: json['accepted']! as bool,
      needsReview: json['needsReview']! as bool,
      confidenceBand: json['confidenceBand'] == null
          ? null
          : VisionConfidenceBand.values.byName(
              json['confidenceBand']! as String,
            ),
      reasons: (json['reasons'] as List<Object?>? ?? const [])
          .whereType<String>()
          .map(VisionCandidateReason.values.byName)
          .toList(growable: false),
      impact: domain.ShotImpact(
        id: impact['id']! as String,
        xMm: (impact['xMm']! as num).toDouble(),
        yMm: (impact['yMm']! as num).toDouble(),
        imageXNormalized: (impact['imageXNormalized'] as num?)?.toDouble(),
        imageYNormalized: (impact['imageYNormalized'] as num?)?.toDouble(),
        multiplicity: impact['multiplicity']! as int,
        isMiss: impact['isMiss']! as bool,
        isPositionUncertain: impact['isPositionUncertain']! as bool,
        placementMethod: domain.ImpactPlacementMethod.values.byName(
          impact['placementMethod']! as String,
        ),
        positionalUncertaintyMm: (impact['positionalUncertaintyMm'] as num?)
            ?.toDouble(),
      ),
    );
  }

  static String _reasonLabel(VisionCandidateReason reason) => switch (reason) {
    VisionCandidateReason.localContrast => 'lokale contrastafwijking',
    VisionCandidateReason.darkCore => 'donkere kern',
    VisionCandidateReason.fiberEdge => 'vezelrand',
    VisionCandidateReason.diameterMatchesProjectile =>
      'diameter past bij .22 LR',
    VisionCandidateReason.lowContrastBlackZone =>
      'laag contrast in zwarte zone',
    VisionCandidateReason.nearScoringLine => 'dicht bij scoringslijn',
    VisionCandidateReason.geometryUnverified => 'geometrie nog controleren',
  };
}

class _StepIndicatorReview extends StatelessWidget {
  const _StepIndicatorReview();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(Icons.looks_3_outlined, size: 20),
      SizedBox(width: 8),
      Text('Stap 3 van 4 · Controleren'),
    ],
  );
}
