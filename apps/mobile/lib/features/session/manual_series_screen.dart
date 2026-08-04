import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;
import 'package:shooting_companion_scoring/scoring.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/app_action_dock.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/safe_sheet_scaffold.dart';
import '../photo/photo.dart';
import '../scoring/target_canvas.dart';
import '../scoring/transformable_scoring_viewport.dart';
import 'series_settings_sheet.dart';
import 'series_reflection_sheet.dart';

class ManualSeriesScreen extends ConsumerStatefulWidget {
  const ManualSeriesScreen({
    required this.sessionId,
    this.seriesId,
    this.openPhotoPickerOnLoad = false,
    this.alignImageIdOnLoad,
    super.key,
  });

  final String sessionId;
  final String? seriesId;
  final bool openPhotoPickerOnLoad;
  final String? alignImageIdOnLoad;

  @override
  ConsumerState<ManualSeriesScreen> createState() => _ManualSeriesScreenState();
}

class _ManualSeriesScreenState extends ConsumerState<ManualSeriesScreen>
    with WidgetsBindingObserver {
  final _storage = ImageStorageService();
  final _picker = ImagePicker();
  final _viewportController = ScoringViewportController();

  String? _seriesId;
  SeriesRecord? _series;
  domain.TargetProfile? _target;
  String? _cartridgeId;
  String? _firearmId;
  String? _ammoLotId;
  String? _notes;
  double _distanceMeters = 25;
  double _projectileDiameterMm = 5.6;
  List<domain.ShotImpact> _impacts = [];
  List<ImageAssetRecord> _images = [];
  ImageAssetRecord? _primaryImage;
  geo.ManualPhotoAlignment? _alignment;
  String? _selectedImpactId;
  Object? _loadError;
  bool _loading = true;
  bool _saving = false;
  _AutosaveStatus _autosaveStatus = _AutosaveStatus.saved;
  bool _allowPop = false;
  bool _sessionActive = true;
  bool _photoSafetyAcknowledged = false;
  bool _openedInitialPhotoPicker = false;
  bool _openedInitialAlignment = false;
  Timer? _autosaveTimer;
  Future<void> _saveQueue = Future.value();
  ScoringTool _tool = ScoringTool.place;
  bool _precisionMode = false;
  final List<_EditorUndoEntry> _undoStack = [];
  _EditorUndoEntry? _dragStartEntry;
  bool _dragBecameInvalid = false;
  DateTime? _lastInvalidFeedbackAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autosaveTimer?.cancel();
    _viewportController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_flushSave());
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null || target == null || _series == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reeks')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('De reeks kon niet worden geopend.\n$_loadError'),
          ),
        ),
      );
    }

    final score = ScoreEngine.score(
      target: target,
      impacts: _impacts,
      projectileDiameterMm: _projectileDiameterMm,
    );
    final scoreById = {
      for (final shot in score.shots) shot.impact.id: shot.value,
    };
    final scoreText = target.targetKind == domain.TargetKind.multiBullConcentric
        ? '${score.total}/${score.maximumPossible} · ${score.innerTenCount} X · '
              '${score.scoredBullCount ?? 0}/${target.multiBullScoringPolicy!.recordBullCount} roosjes'
              '${score.penalty > 0 ? ' · −${score.penalty} straf' : ''}'
        : '${score.total}/${score.maximumPossible} · '
              '${score.innerTenCount} X · ${score.actualShotCount} schoten';
    final cartridges =
        ref.watch(cartridgesProvider).valueOrNull ?? const <CartridgeRecord>[];
    final cartridge = cartridges
        .where((item) => item.id == _cartridgeId)
        .firstOrNull;
    final isDraft = _series!.status == domain.SeriesStatus.draft.name;

    Widget settingsSummary({bool compact = false}) => _SettingsSummary(
      targetName: target.displayName,
      cartridgeName: cartridge?.name ?? 'Kaliber',
      distanceMeters: _distanceMeters,
      autosaveStatus: _autosaveStatus,
      onEdit: _openSettings,
      onRetry: () => unawaited(_persistSnapshot().catchError((_) {})),
      compact: compact,
    );
    Widget modeBar({bool compact = false}) => _ScoringModeBar(
      tool: _tool,
      precisionMode: _precisionMode,
      forceCompact: compact,
      onToolChanged: (tool) => setState(() {
        _tool = tool;
        if (tool == ScoringTool.place) _selectedImpactId = null;
      }),
      onPrecisionChanged: (value) => setState(() {
        _precisionMode = value;
        if (value) {
          _tool = ScoringTool.place;
          _selectedImpactId = null;
        }
      }),
      onPlaceAtCrosshair: _placeAtCrosshair,
    );
    Widget canvas() => DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: _buildCanvas(scoreById),
      ),
    );
    Widget canvasToolbar({bool vertical = false}) => _CanvasToolbar(
      canUndo: _impacts.isNotEmpty,
      canActuallyUndo: _undoStack.isNotEmpty,
      onMiss: _addMiss,
      onUndo: _undo,
      onPoints: () => _showPoints(score),
      onPhoto: _choosePhoto,
      vertical: vertical,
    );
    Widget selectedControls() => _SelectedImpactBar(
      impact: _selectedImpact!,
      index: _impacts.indexOf(_selectedImpact!) + 1,
      score: scoreById[_selectedImpact!.id] ?? 0,
      onDecrease: _decreaseMultiplicity,
      onIncrease: _increaseMultiplicity,
      onDelete: _deleteSelected,
    );
    Widget controls() => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        canvasToolbar(),
        const SizedBox(height: 6),
        SizedBox(
          height: 84,
          child: _selectedImpact == null
              ? const SizedBox.shrink()
              : selectedControls(),
        ),
      ],
    );

    return PopScope<Object?>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_saveBeforePop(result));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isDraft ? 'Nieuwe reeks' : 'Reeks bewerken'),
          actions: [
            PopupMenuButton<String>(
              enabled: !_saving,
              tooltip: 'Meer acties',
              onSelected: _handleMenuAction,
              itemBuilder: (_) => [
                if (_primaryImage != null)
                  const PopupMenuItem(
                    value: 'align',
                    child: Text('Uitlijning aanpassen'),
                  ),
                if (_impacts.isNotEmpty)
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('Alle punten wissen'),
                  ),
                if (isDraft && _sessionActive && score.actualShotCount > 0)
                  const PopupMenuItem(
                    value: 'save-complete',
                    child: Text('Bewaren en sessie beëindigen'),
                  ),
                if (isDraft)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Concept verwijderen'),
                  ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            AbsorbPointer(
              absorbing: _saving,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final landscape =
                          constraints.maxWidth > constraints.maxHeight;
                      if (landscape) {
                        final panelWidth = (constraints.maxWidth * 0.38)
                            .clamp(240.0, 320.0)
                            .toDouble();
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: canvas()),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: panelWidth,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    settingsSummary(),
                                    const SizedBox(height: 8),
                                    modeBar(),
                                    const SizedBox(height: 8),
                                    controls(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      final compactPortrait =
                          constraints.maxHeight < 560 ||
                          MediaQuery.textScalerOf(context).scale(1) >= 1.5;
                      return Column(
                        children: [
                          settingsSummary(compact: compactPortrait),
                          SizedBox(height: compactPortrait ? 4 : 8),
                          modeBar(compact: compactPortrait),
                          SizedBox(height: compactPortrait ? 4 : 8),
                          Expanded(
                            child: compactPortrait
                                ? Stack(
                                    children: [
                                      Positioned.fill(child: canvas()),
                                      Positioned(
                                        left: 5,
                                        top: 5,
                                        child: Material(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface
                                              .withValues(alpha: 0.94),
                                          elevation: 2,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: canvasToolbar(vertical: true),
                                        ),
                                      ),
                                      if (_selectedImpact != null)
                                        Positioned(
                                          left: 6,
                                          right: 6,
                                          bottom: 6,
                                          child: Material(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface
                                                .withValues(alpha: 0.94),
                                            elevation: 2,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: selectedControls(),
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : canvas(),
                          ),
                          if (!compactPortrait) ...[
                            const SizedBox(height: 8),
                            controls(),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_saving)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
        bottomNavigationBar: AbsorbPointer(
          absorbing: _saving,
          child: _SeriesBottomActionBar(
            scoreText: scoreText,
            saving: _saving,
            canSave: score.actualShotCount > 0 && !_saving,
            showNext: _sessionActive,
            onSave: () => _finish(saveNext: false),
            onSaveNext: () => _finish(saveNext: true),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas(Map<String, int> scoreById) {
    final image = _primaryImage;
    final alignment = _alignment;
    if (image != null && alignment != null && File(image.path).existsSync()) {
      return PhotoOverlayCanvas(
        imageProvider: FileImage(File(image.path)),
        imagePixelSize: Size(image.width.toDouble(), image.height.toDouble()),
        alignment: alignment,
        projectileDiameterMm: _projectileDiameterMm,
        tool: _tool,
        precisionMode: _precisionMode,
        viewportController: _viewportController,
        selectedImpactId: _selectedImpactId,
        impacts: [
          for (var index = 0; index < _impacts.length; index++)
            if (!_impacts[index].isMiss)
              PhotoCanvasImpact(
                id: _impacts[index].id,
                positionMm: geo.PhysicalPointMm(
                  _impacts[index].xMm,
                  _impacts[index].yMm,
                ),
                sequenceNumber: index + 1,
                scoreLabel: '${scoreById[_impacts[index].id] ?? 0}',
                multiplicity: _impacts[index].multiplicity,
                isPositionUncertain: _impacts[index].isPositionUncertain,
              ),
        ],
        onCanvasTap: (position) {
          final bull = _recordBullAt(
            position.physicalMm.x,
            position.physicalMm.y,
          );
          if (_target!.targetKind == domain.TargetKind.multiBullConcentric &&
              bull == null) {
            _handleInvalidPosition();
            return;
          }
          final impact = domain.ShotImpact(
            id: 'impact-${DateTime.now().microsecondsSinceEpoch}',
            xMm: position.physicalMm.x,
            yMm: position.physicalMm.y,
            sourceImageId: image.id,
            imageXNormalized: position.normalized.x,
            imageYNormalized: position.normalized.y,
            targetBullId: bull?.id,
          );
          _changeImpacts([..._impacts, impact], selectedId: impact.id);
        },
        onImpactMoved: (id, position) {
          final bull = _recordBullAt(
            position.physicalMm.x,
            position.physicalMm.y,
          );
          if (_target!.targetKind == domain.TargetKind.multiBullConcentric &&
              bull == null) {
            _handleInvalidPosition();
            return;
          }
          _changeImpacts(
            _impacts
                .map(
                  (impact) => impact.id == id
                      ? impact.copyWith(
                          xMm: position.physicalMm.x,
                          yMm: position.physicalMm.y,
                          sourceImageId: image.id,
                          imageXNormalized: position.normalized.x,
                          imageYNormalized: position.normalized.y,
                          targetBullId: bull?.id,
                        )
                      : impact,
                )
                .toList(),
            selectedId: id,
            recordUndo: _dragStartEntry == null,
            scheduleSave: _dragStartEntry == null,
          );
        },
        onImpactSelected: (id) => setState(() {
          _tool = ScoringTool.edit;
          _selectedImpactId = id;
        }),
        onImpactLongPressed: _selectImpactFromLongPress,
        onImpactMoveStart: _beginImpactMove,
        onImpactMoveEnd: _endImpactMove,
        onImpactMoveCancel: _cancelImpactMove,
        onInvalidPosition: _handleInvalidPosition,
      );
    }

    return TargetCanvas(
      target: _target!,
      impacts: _impacts,
      projectileDiameterMm: _projectileDiameterMm,
      scoreValues: scoreById,
      tool: _tool,
      precisionMode: _precisionMode,
      viewportController: _viewportController,
      selectedImpactId: _selectedImpactId,
      onImpactSelected: (id) => setState(() {
        _selectedImpactId = id;
      }),
      onImpactLongPressed: _selectImpactFromLongPress,
      onImpactMoveStart: _beginImpactMove,
      onImpactMoveEnd: _endImpactMove,
      onImpactMoveCancel: _cancelImpactMove,
      onInvalidPosition: _handleInvalidPosition,
      onChanged: (value) => _changeImpacts(
        _detachPhotoCoordinatesAfterTargetMove(value),
        recordUndo: _dragStartEntry == null,
        scheduleSave: _dragStartEntry == null,
      ),
    );
  }

  List<domain.ShotImpact> _detachPhotoCoordinatesAfterTargetMove(
    List<domain.ShotImpact> updated,
  ) {
    final previousById = {for (final impact in _impacts) impact.id: impact};
    return [
      for (final impact in updated)
        if (previousById[impact.id] case final previous?
            when previous.sourceImageId != null &&
                (previous.xMm != impact.xMm || previous.yMm != impact.yMm))
          impact.copyWith(clearSourceImage: true, clearImageCoordinates: true)
        else
          impact,
    ];
  }

  domain.ShotImpact? get _selectedImpact =>
      _impacts.where((impact) => impact.id == _selectedImpactId).firstOrNull;

  void _handleInvalidPosition() {
    if (_dragStartEntry != null) _dragBecameInvalid = true;
    final now = DateTime.now();
    if (_lastInvalidFeedbackAt != null &&
        now.difference(_lastInvalidFeedbackAt!) <
            const Duration(milliseconds: 800)) {
      return;
    }
    _lastInvalidFeedbackAt = now;
    unawaited(HapticFeedback.selectionClick());
    AppMessenger.warning(
      context,
      _target?.targetKind == domain.TargetKind.multiBullConcentric
          ? 'Kies een genummerd wedstrijdroosje; proefroosjes tellen niet mee.'
          : 'Buiten de uitgelijnde kaart — gebruik Misser / 0.',
    );
  }

  void _selectImpactFromLongPress(String id) {
    if (!_impacts.any((impact) => impact.id == id)) return;
    setState(() {
      _selectedImpactId = id;
      _tool = ScoringTool.edit;
      _precisionMode = false;
    });
  }

  void _placeAtCrosshair() {
    final normalized = _viewportController.viewportCenterNormalized;
    if (normalized == null) {
      _handleInvalidPosition();
      return;
    }
    final image = _primaryImage;
    final alignment = _alignment;
    late domain.ShotImpact impact;
    if (image != null && alignment != null && File(image.path).existsSync()) {
      final imagePoint = geo.NormalizedPoint(normalized.dx, normalized.dy);
      late final geo.PhysicalPointMm physical;
      try {
        physical = alignment.normalizedToPhysical(imagePoint);
      } on StateError {
        _handleInvalidPosition();
        return;
      }
      if (!physical.x.isFinite || !physical.y.isFinite) {
        _handleInvalidPosition();
        return;
      }
      final halfWidth = alignment.cardWidthMm / 2;
      final halfHeight = alignment.cardHeightMm / 2;
      const edgeToleranceMm = 1e-6;
      if (physical.x < -halfWidth - edgeToleranceMm ||
          physical.x > halfWidth + edgeToleranceMm ||
          physical.y < -halfHeight - edgeToleranceMm ||
          physical.y > halfHeight + edgeToleranceMm) {
        _handleInvalidPosition();
        return;
      }
      impact = domain.ShotImpact(
        id: 'impact-${DateTime.now().microsecondsSinceEpoch}',
        xMm: physical.x.clamp(-halfWidth, halfWidth).toDouble(),
        yMm: physical.y.clamp(-halfHeight, halfHeight).toDouble(),
        sourceImageId: image.id,
        imageXNormalized: normalized.dx,
        imageYNormalized: normalized.dy,
      );
    } else {
      final target = _target!;
      impact = domain.ShotImpact(
        id: 'impact-${DateTime.now().microsecondsSinceEpoch}',
        xMm: (normalized.dx - 0.5) * target.physicalCardWidthMm,
        yMm: (normalized.dy - 0.5) * target.physicalCardHeightMm,
      );
    }
    final bull = _recordBullAt(impact.xMm, impact.yMm);
    if (_target!.targetKind == domain.TargetKind.multiBullConcentric &&
        bull == null) {
      _handleInvalidPosition();
      return;
    }
    impact = impact.copyWith(targetBullId: bull?.id);
    _changeImpacts([..._impacts, impact], selectedId: impact.id);
  }

  domain.TargetBull? _recordBullAt(double xMm, double yMm) =>
      _target?.bullAt(xMm, yMm, recordOnly: true);

  Future<void> _showPoints(ScoreResult score) async {
    final scoreById = {
      for (final shot in score.shots) shot.impact.id: shot.value,
    };
    final multiBull =
        _target!.targetKind == domain.TargetKind.multiBullConcentric;
    final selectedId = await showSafeModalSheet<String>(
      context: context,
      builder: (sheetContext) => SafeSheetScaffold(
        title: multiBull ? 'Wedstrijdroosjes' : 'Punten en missers',
        body: multiBull
            ? Column(
                children: [
                  for (final bull in _target!.recordBulls)
                    _Br50BullTile(
                      bull: bull,
                      shots: score.shots
                          .where((shot) => shot.targetBullId == bull.id)
                          .toList(growable: false),
                      onSelect: (id) => Navigator.pop(sheetContext, id),
                      onAddMiss: () =>
                          Navigator.pop(sheetContext, 'miss:${bull.id}'),
                    ),
                ],
              )
            : _impacts.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Nog geen punten geregistreerd.')),
              )
            : Column(
                children: [
                  for (var index = 0; index < _impacts.length; index++)
                    ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text(
                        _impacts[index].isMiss
                            ? 'Misser · 0 punten'
                            : '${scoreById[_impacts[index].id] ?? 0} punten',
                      ),
                      subtitle: Text(
                        '×${_impacts[index].multiplicity}'
                        '${_impacts[index].isPositionUncertain ? ' · positie onzeker' : ''}',
                      ),
                      trailing: const Icon(Icons.edit_location_alt_outlined),
                      onTap: () =>
                          Navigator.pop(sheetContext, _impacts[index].id),
                    ),
                ],
              ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
    if (selectedId == null || !mounted) return;
    if (selectedId.startsWith('miss:')) {
      final bull = _target!.bullById(selectedId.substring(5));
      if (bull == null) return;
      final impact = domain.ShotImpact(
        id: 'impact-${DateTime.now().microsecondsSinceEpoch}',
        xMm: bull.centerXMm,
        yMm: bull.centerYMm,
        targetBullId: bull.id,
        isMiss: true,
        scoreDisposition: domain.ScoreDisposition.miss,
      );
      _changeImpacts([..._impacts, impact], selectedId: impact.id);
      return;
    }
    final impact = _impacts.where((item) => item.id == selectedId).firstOrNull;
    if (impact == null) return;
    setState(() {
      _selectedImpactId = selectedId;
      _tool = ScoringTool.edit;
      _precisionMode = false;
    });
    if (!impact.isMiss) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _viewportController.focusImpact(impact.id);
      });
    }
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'align':
        final image = _primaryImage;
        if (image != null) unawaited(_alignAsPrimary(image));
        return;
      case 'clear':
        unawaited(_clear());
        return;
      case 'save-complete':
        unawaited(_saveAndCompleteSession());
        return;
      case 'delete':
        unawaited(_deleteDraft());
        return;
    }
  }

  Future<void> _initialize() async {
    try {
      final repository = ref.read(repositoryProvider);
      final id =
          widget.seriesId ??
          await repository.createOrResumeDraftSeries(widget.sessionId);
      final detail = await repository.getSeriesDetail(id);
      final session = await repository.getSessionDetail(widget.sessionId);
      if (detail == null || session == null) {
        throw StateError('Sessie of reeks bestaat niet meer.');
      }
      final impacts = detail.impacts.map(_toDomainImpact).toList();
      final target = detail.target;
      final alignment = _decodeAlignment(detail.photoAlignment, target);
      final cartridges = await repository.watchCartridges().first;
      final resolvedCartridgeId =
          detail.series.cartridgeId ??
          cartridges
              .where(
                (item) =>
                    (item.projectileDiameterMm -
                            detail.series.projectileDiameterMm)
                        .abs() <
                    0.001,
              )
              .firstOrNull
              ?.id;
      if (!mounted) return;
      setState(() {
        _seriesId = id;
        _series = detail.series;
        _target = target;
        _cartridgeId = resolvedCartridgeId;
        _firearmId = detail.series.firearmId;
        _ammoLotId = detail.series.ammoLotId;
        _notes = detail.series.notes;
        _distanceMeters = detail.series.distanceMeters;
        _projectileDiameterMm = detail.series.projectileDiameterMm;
        _impacts = impacts;
        _images = detail.images;
        _primaryImage = detail.primaryImage;
        _alignment = alignment;
        _sessionActive =
            session.session.status == domain.SessionStatus.active.name;
        _photoSafetyAcknowledged =
            session.session.photoSafetyAcknowledgedAtUtc != null;
        _loading = false;
      });
      if (widget.openPhotoPickerOnLoad && !_openedInitialPhotoPicker) {
        _openedInitialPhotoPicker = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_choosePhoto());
        });
      } else if (widget.alignImageIdOnLoad != null &&
          !_openedInitialAlignment) {
        _openedInitialAlignment = true;
        final image = detail.images
            .where((item) => item.id == widget.alignImageIdOnLoad)
            .firstOrNull;
        if (image != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_alignAsPrimary(image));
          });
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  domain.ShotImpact _toDomainImpact(ImpactRecord record) => domain.ShotImpact(
    id: record.id,
    xMm: record.xMm,
    yMm: record.yMm,
    sourceImageId: record.sourceImageId,
    imageXNormalized: record.imageXNormalized,
    imageYNormalized: record.imageYNormalized,
    multiplicity: record.multiplicity,
    isMiss: record.isMiss,
    isPositionUncertain: record.isPositionUncertain,
    targetBullId: record.targetBullId,
    rawScoreValue: record.rawScoreValue,
    scoreDisposition: domain.ScoreDisposition.values.byName(
      record.scoreDisposition,
    ),
  );

  geo.ManualPhotoAlignment? _decodeAlignment(
    PhotoAlignmentRecord? record,
    domain.TargetProfile target,
  ) {
    if (record == null) return null;
    final corners = (jsonDecode(record.cornersJson) as List)
        .map(
          (value) => geo.NormalizedPoint(
            ((value as Map)['x'] as num).toDouble(),
            (value['y'] as num).toDouble(),
          ),
        )
        .toList();
    return geo.ManualPhotoAlignment.fromJson({
      'algorithmVersion': record.algorithmVersion,
      'cardWidthMm': target.physicalCardWidthMm,
      'cardHeightMm': target.physicalCardHeightMm,
      'corners': geo.NormalizedQuad.fromOrderedPoints(corners).toJson(),
      'homographyMatrix': (jsonDecode(record.matrixJson) as List)
          .cast<num>()
          .map((value) => value.toDouble())
          .toList(),
    });
  }

  void _changeImpacts(
    List<domain.ShotImpact> impacts, {
    String? selectedId,
    bool recordUndo = true,
    bool scheduleSave = true,
  }) {
    if (recordUndo) _pushUndo(_impacts, _selectedImpactId);
    setState(() {
      _impacts = impacts;
      _selectedImpactId = selectedId ?? _selectedImpactId;
      if (!_impacts.any((item) => item.id == _selectedImpactId)) {
        _selectedImpactId = null;
      }
    });
    if (scheduleSave) _scheduleAutosave();
  }

  void _pushUndo(List<domain.ShotImpact> snapshot, String? selectedImpactId) {
    _undoStack.add(
      _EditorUndoEntry(
        impacts: List<domain.ShotImpact>.from(snapshot),
        selectedImpactId: selectedImpactId,
      ),
    );
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _beginImpactMove(String id) {
    final hadPendingAutosave = _autosaveTimer?.isActive == true;
    _autosaveTimer?.cancel();
    if (hadPendingAutosave) {
      unawaited(_persistSnapshot().catchError((_) {}));
    }
    _dragStartEntry = _EditorUndoEntry(
      impacts: List<domain.ShotImpact>.from(_impacts),
      selectedImpactId: _selectedImpactId,
    );
    _dragBecameInvalid = false;
  }

  void _endImpactMove(String id) {
    final before = _dragStartEntry;
    _dragStartEntry = null;
    if (before == null) return;
    if (_dragBecameInvalid) {
      setState(() {
        _impacts = before.impacts;
        _selectedImpactId = before.selectedImpactId;
      });
      _dragBecameInvalid = false;
      _scheduleAutosave();
      return;
    }
    if (!_sameImpacts(before.impacts, _impacts)) {
      _undoStack.add(before);
      if (_undoStack.length > 50) _undoStack.removeAt(0);
      _scheduleAutosave();
    }
  }

  void _cancelImpactMove(String id) {
    final before = _dragStartEntry;
    _dragStartEntry = null;
    _dragBecameInvalid = false;
    if (before != null) {
      setState(() {
        _impacts = before.impacts;
        _selectedImpactId = before.selectedImpactId;
      });
      _scheduleAutosave();
    }
  }

  bool _sameImpacts(
    List<domain.ShotImpact> first,
    List<domain.ShotImpact> second,
  ) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      final a = first[index];
      final b = second[index];
      if (a.id != b.id ||
          a.xMm != b.xMm ||
          a.yMm != b.yMm ||
          a.sourceImageId != b.sourceImageId ||
          a.imageXNormalized != b.imageXNormalized ||
          a.imageYNormalized != b.imageYNormalized ||
          a.multiplicity != b.multiplicity ||
          a.isMiss != b.isMiss ||
          a.isPositionUncertain != b.isPositionUncertain ||
          a.targetBullId != b.targetBullId) {
        return false;
      }
    }
    return true;
  }

  Future<void> _addMiss() async {
    final target = _target!;
    domain.TargetBull? bull;
    if (target.targetKind == domain.TargetKind.multiBullConcentric) {
      final occupied = _impacts.map((impact) => impact.targetBullId).toSet();
      final suggested = target.recordBulls
          .where((candidate) => !occupied.contains(candidate.id))
          .firstOrNull;
      final selectedId = await showSafeModalSheet<String>(
        context: context,
        builder: (sheetContext) => SafeSheetScaffold(
          title: 'Misser aan roosje koppelen',
          body: Column(
            children: [
              for (final candidate in target.recordBulls)
                ListTile(
                  leading: CircleAvatar(child: Text(candidate.label)),
                  title: Text('Wedstrijdroosje ${candidate.label}'),
                  subtitle: occupied.contains(candidate.id)
                      ? const Text('Bevat al een registratie')
                      : candidate.id == suggested?.id
                      ? const Text('Eerstvolgende lege roosje')
                      : null,
                  trailing: candidate.id == suggested?.id
                      ? const Icon(Icons.arrow_forward)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, candidate.id),
                ),
            ],
          ),
          actions: const [],
        ),
      );
      if (selectedId == null || !mounted) return;
      bull = target.bullById(selectedId);
    }
    final impact = domain.ShotImpact(
      id: 'impact-${DateTime.now().microsecondsSinceEpoch}',
      xMm: bull?.centerXMm ?? 0,
      yMm: bull?.centerYMm ?? 0,
      isMiss: true,
      targetBullId: bull?.id,
      scoreDisposition: domain.ScoreDisposition.miss,
    );
    _changeImpacts([..._impacts, impact], selectedId: impact.id);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _viewportController.cancelInteraction();
    final previous = _undoStack.removeLast();
    setState(() {
      _impacts = previous.impacts;
      _selectedImpactId =
          _impacts.any((impact) => impact.id == previous.selectedImpactId)
          ? previous.selectedImpactId
          : null;
    });
    _scheduleAutosave();
  }

  Future<void> _clear() async {
    if (_impacts.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle punten wissen?'),
        content: Text('${_impacts.length} registraties worden verwijderd.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wissen'),
          ),
        ],
      ),
    );
    if (confirmed == true) _changeImpacts([]);
  }

  void _increaseMultiplicity() {
    final selected = _selectedImpact;
    if (selected == null) return;
    _changeImpacts(
      _impacts
          .map(
            (impact) => impact.id == selected.id
                ? impact.copyWith(multiplicity: impact.multiplicity + 1)
                : impact,
          )
          .toList(),
      selectedId: selected.id,
    );
  }

  void _decreaseMultiplicity() {
    final selected = _selectedImpact;
    if (selected == null || selected.multiplicity <= 1) return;
    _changeImpacts(
      _impacts
          .map(
            (impact) => impact.id == selected.id
                ? impact.copyWith(multiplicity: impact.multiplicity - 1)
                : impact,
          )
          .toList(),
      selectedId: selected.id,
    );
  }

  void _deleteSelected() {
    final selected = _selectedImpact;
    if (selected == null) return;
    _changeImpacts(
      _impacts.where((impact) => impact.id != selected.id).toList(),
    );
  }

  Future<void> _openSettings() async {
    final target = _target;
    final cartridgeId = _cartridgeId;
    if (target == null || cartridgeId == null) return;
    final result = await showSeriesSettingsSheet(
      context: context,
      initial: SeriesSettingsValues(
        target: target,
        cartridgeId: cartridgeId,
        distanceMeters: _distanceMeters,
        firearmId: _firearmId,
        ammoLotId: _ammoLotId,
        notes: _notes,
      ),
      targets:
          ref.read(targetProfilesProvider).valueOrNull ??
          const <TargetProfileRecord>[],
      cartridges:
          ref.read(cartridgesProvider).valueOrNull ?? const <CartridgeRecord>[],
      firearms:
          ref.read(firearmsProvider).valueOrNull ?? const <FirearmRecord>[],
      ammoLots:
          ref.read(ammoLotsProvider).valueOrNull ?? const <AmmoLotRecord>[],
    );
    if (result == null || !mounted) return;
    final cartridge = ref
        .read(cartridgesProvider)
        .valueOrNull
        ?.where((item) => item.id == result.cartridgeId)
        .firstOrNull;
    final targetChanged = result.target.versionedId != target.versionedId;
    setState(() {
      _target = result.target;
      _cartridgeId = result.cartridgeId;
      _distanceMeters = result.distanceMeters;
      _firearmId = result.firearmId;
      _ammoLotId = result.ammoLotId;
      _notes = result.notes;
      _projectileDiameterMm =
          cartridge?.projectileDiameterMm ?? _projectileDiameterMm;
      if (targetChanged) {
        _alignment = null;
        _impacts = _impacts
            .map(
              (impact) => impact.copyWith(
                clearSourceImage: true,
                clearImageCoordinates: true,
                clearTargetBull: true,
              ),
            )
            .toList();
      }
    });
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    if (mounted) setState(() => _autosaveStatus = _AutosaveStatus.changed);
    _autosaveTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_persistSnapshot().catchError((_) {}));
    });
  }

  Future<void> _persistSnapshot() {
    final id = _seriesId;
    final series = _series;
    final target = _target;
    if (id == null || series == null || target == null) return Future.value();
    final impacts = List<domain.ShotImpact>.from(_impacts);
    final distance = _distanceMeters;
    final diameter = _projectileDiameterMm;
    final cartridgeId = _cartridgeId;
    final firearmId = _firearmId;
    final ammoLotId = _ammoLotId;
    final notes = _notes;
    final repository = ref.read(repositoryProvider);
    Future<void> operation() async {
      if (mounted) setState(() => _autosaveStatus = _AutosaveStatus.saving);
      try {
        if (series.status == domain.SeriesStatus.draft.name) {
          await repository.saveSeriesDraft(
            seriesId: id,
            target: target,
            distanceMeters: distance,
            projectileDiameterMm: diameter,
            impacts: impacts,
            cartridgeId: cartridgeId,
            firearmId: firearmId,
            ammoLotId: ammoLotId,
            notes: notes,
          );
        } else {
          await repository.replaceConfirmedSeries(
            seriesId: id,
            target: target,
            distanceMeters: distance,
            projectileDiameterMm: diameter,
            impacts: impacts,
            cartridgeId: cartridgeId,
            firearmId: firearmId,
            ammoLotId: ammoLotId,
            notes: notes,
          );
        }
        if (mounted && _autosaveTimer?.isActive != true) {
          setState(() => _autosaveStatus = _AutosaveStatus.saved);
        }
      } catch (_) {
        if (mounted) setState(() => _autosaveStatus = _AutosaveStatus.failed);
        rethrow;
      }
    }

    _saveQueue = _saveQueue.then(
      (_) => operation(),
      onError: (_, _) => operation(),
    );
    return _saveQueue;
  }

  Future<void> _flushSave() async {
    _restoreActiveDragForPersistence();
    final hadPending = _autosaveTimer?.isActive == true;
    _autosaveTimer?.cancel();
    if (hadPending || _autosaveStatus != _AutosaveStatus.saved) {
      await _persistSnapshot();
    }
    await _saveQueue;
  }

  void _restoreActiveDragForPersistence() {
    _viewportController.cancelInteraction();
    final before = _dragStartEntry;
    if (before == null) return;
    _dragStartEntry = null;
    _dragBecameInvalid = false;
    if (mounted) {
      setState(() {
        _impacts = before.impacts;
        _selectedImpactId = before.selectedImpactId;
      });
    } else {
      _impacts = before.impacts;
      _selectedImpactId = before.selectedImpactId;
    }
  }

  Future<void> _finish({required bool saveNext}) async {
    if (_saving) return;
    if (!await _confirmIncompleteMultiBullIfNeeded()) return;
    setState(() => _saving = true);
    try {
      await _flushSave();
      final repository = ref.read(repositoryProvider);
      final wasDraft = _series!.status == domain.SeriesStatus.draft.name;
      if (wasDraft) await repository.confirmSeries(_seriesId!);
      if (!mounted) return;
      if (wasDraft) {
        await maybeShowSeriesReflectionPrompt(
          context: context,
          ref: ref,
          seriesId: _seriesId!,
        );
        if (!mounted) return;
      }
      if (saveNext && _sessionActive) {
        final next = await repository.createOrResumeDraftSeries(
          widget.sessionId,
        );
        if (!mounted) return;
        setState(() => _allowPop = true);
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                ManualSeriesScreen(sessionId: widget.sessionId, seriesId: next),
          ),
        );
      } else {
        setState(() => _allowPop = true);
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        AppMessenger.error(context, 'Bewaren mislukt: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAndCompleteSession() async {
    if (_saving || _series?.status != domain.SeriesStatus.draft.name) return;
    if (!await _confirmIncompleteMultiBullIfNeeded()) return;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reeks bewaren en sessie beëindigen?'),
        content: Text(
          'De huidige reeks met ${_impacts.fold<int>(0, (sum, impact) => sum + impact.multiplicity)} '
          'schoten wordt bewaard. Daarna wordt de sessie beëindigd.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bewaren en beëindigen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    _autosaveTimer?.cancel();
    try {
      await _saveQueue.catchError((_) {});
      await ref
          .read(repositoryProvider)
          .saveConfirmAndCompleteSeries(
            seriesId: _seriesId!,
            target: _target!,
            distanceMeters: _distanceMeters,
            projectileDiameterMm: _projectileDiameterMm,
            impacts: List<domain.ShotImpact>.from(_impacts),
            cartridgeId: _cartridgeId,
            firearmId: _firearmId,
            ammoLotId: _ammoLotId,
            notes: _notes,
          );
      if (!mounted) return;
      await maybeShowSeriesReflectionPrompt(
        context: context,
        ref: ref,
        seriesId: _seriesId!,
      );
      if (!mounted) return;
      setState(() {
        _allowPop = true;
        _sessionActive = false;
        _autosaveStatus = _AutosaveStatus.saved;
      });
      AppMessenger.success(context, 'Sessie beëindigd');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _autosaveStatus = _AutosaveStatus.failed);
        AppMessenger.error(context, 'Sessie beëindigen mislukt: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmIncompleteMultiBullIfNeeded() async {
    final target = _target;
    if (target == null ||
        target.targetKind != domain.TargetKind.multiBullConcentric) {
      return true;
    }
    final score = ScoreEngine.score(
      target: target,
      impacts: _impacts,
      projectileDiameterMm: _projectileDiameterMm,
    );
    final missing =
        target.multiBullScoringPolicy!.recordBullCount -
        (score.scoredBullCount ?? 0);
    if (missing <= 0) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Onvolledige BR50-reeks'),
        content: Text(
          'Er ${missing == 1 ? 'is' : 'zijn'} nog $missing leeg${missing == 1 ? '' : 'e'} '
          'wedstrijdroosje${missing == 1 ? '' : 's'}. Deze tellen als 0. '
          'Reeks toch bewaren?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Verder scoren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Toch bewaren'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _saveBeforePop(Object? result) async {
    if (_allowPop || _saving) return;
    setState(() => _saving = true);
    try {
      await _flushSave();
      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.of(context).pop(result);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteDraft() async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Concept verwijderen?'),
        content: const Text('Punten en gekoppelde reeksfoto’s verdwijnen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      _restoreActiveDragForPersistence();
      _autosaveTimer?.cancel();
      await _saveQueue.catchError((_) {});
      await ref.read(repositoryProvider).deleteSeries(_seriesId!);
      if (!mounted) return;
      setState(() => _allowPop = true);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        AppMessenger.error(context, 'Concept verwijderen mislukt: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _choosePhoto() async {
    final choice = await showSafeModalSheet<_PhotoChoice>(
      context: context,
      presentation: SafeSheetPresentation.compact,
      builder: (context) => const _PhotoChoiceSheet(),
    );
    if (choice == null || !mounted) return;
    if (choice.source == ImageSource.camera && !await _confirmPhotoSafety()) {
      return;
    }
    final picked = await _picker.pickImage(source: choice.source);
    if (picked == null || !mounted) return;

    StagedImage? staged;
    StoredImage? stored;
    String? attachedImageId;
    try {
      staged = await _storage.stageJpeg(picked.path);
      stored = await _storage.finalizeStagedImage(staged);
      final imageId = await ref
          .read(repositoryProvider)
          .attachImage(
            NewImageAsset(
              sessionId: widget.sessionId,
              seriesId: _seriesId,
              role: domain.ImageRole.attachment,
              path: stored.path,
              sha256: stored.sha256,
              width: stored.width,
              height: stored.height,
              sizeBytes: stored.sizeBytes,
            ),
          );
      attachedImageId = imageId;
      await _reloadMedia();
      if (choice.asScoringPhoto && mounted) {
        final record = _images
            .where((image) => image.id == imageId)
            .firstOrNull;
        if (record != null) await _alignAsPrimary(record);
      }
      if (mounted) _offerAddedPhotoCaption(imageId);
    } catch (error) {
      if (staged != null && stored == null) {
        await _storage.discardStagedImage(staged);
      }
      if (stored != null && attachedImageId == null) {
        await _storage.deleteStoredImage(stored.path);
      }
      if (mounted) {
        AppMessenger.error(context, 'Foto toevoegen mislukt: $error');
      }
    }
  }

  void _offerAddedPhotoCaption(String imageId) {
    AppMessenger.show(
      context,
      kind: AppNoticeKind.success,
      message: 'Foto toegevoegd',
      action: AppNoticeAction(
        label: 'Beschrijving',
        onPressed: () => unawaited(_editAddedPhotoCaption(imageId)),
      ),
    );
  }

  Future<void> _editAddedPhotoCaption(String imageId) async {
    final image = await ref.read(repositoryProvider).watchImage(imageId).first;
    if (!mounted || image == null) return;
    await editPhotoCaption(context: context, ref: ref, image: image);
  }

  Future<bool> _confirmPhotoSafety() async {
    if (_photoSafetyAcknowledged) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veilig fotograferen'),
        content: const Text(
          'Bevestig dat de baan veilig is en fotograferen volgens de '
          'standregels is toegestaan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ik bevestig dit'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    await ref.read(repositoryProvider).acknowledgePhotoSafety(widget.sessionId);
    _photoSafetyAcknowledged = true;
    return true;
  }

  Future<void> _alignAsPrimary(ImageAssetRecord image) async {
    if (_saving) return;
    if (!File(image.path).existsSync()) {
      AppMessenger.warning(context, 'Het originele fotobestand ontbreekt.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _flushSave();
      if (!mounted) return;
      final target = _target!;
      final isCurrentPrimary = image.id == _primaryImage?.id;
      final alignment = await Navigator.of(context)
          .push<geo.ManualPhotoAlignment>(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Foto uitlijnen')),
                body: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: FourPointAlignmentEditor(
                      imageProvider: FileImage(File(image.path)),
                      imagePixelSize: Size(
                        image.width.toDouble(),
                        image.height.toDouble(),
                      ),
                      cardWidthMm: target.physicalCardWidthMm,
                      cardHeightMm: target.physicalCardHeightMm,
                      initialCorners: isCurrentPrimary
                          ? _alignment?.corners
                          : null,
                      onConfirmed: (value) => Navigator.pop(context, value),
                      onUseAsAttachment: isCurrentPrimary
                          ? null
                          : () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
          );
      if (alignment == null || !mounted) return;
      final repository = ref.read(repositoryProvider);
      final realignedImpacts = [
        for (final impact in _impacts)
          if (impact.sourceImageId == image.id &&
              impact.imageXNormalized != null &&
              impact.imageYNormalized != null)
            _impactFromAlignment(impact, alignment)
          else
            impact,
      ];
      if (isCurrentPrimary &&
          _alignment != null &&
          !_sameImpacts(realignedImpacts, _impacts)) {
        final proceed = await _confirmRealignmentScoreChange(realignedImpacts);
        if (!proceed || !mounted) return;
      }
      final storedAlignment = domain.StoredPhotoAlignment(
        imageId: image.id,
        orderedCorners: alignment.corners.points
            .map((point) => domain.NormalizedPoint(x: point.x, y: point.y))
            .toList(),
        homographyMatrix: alignment.homographyMatrix,
        algorithmVersion: alignment.algorithmVersion,
        updatedAtUtc: DateTime.now().toUtc(),
      );
      await repository.realignSeriesPhoto(
        seriesId: _seriesId!,
        alignment: storedAlignment,
        target: target,
        projectileDiameterMm: _projectileDiameterMm,
        resultingImpacts: realignedImpacts,
      );
      if (!mounted) return;
      setState(() {
        _impacts = realignedImpacts;
        _autosaveStatus = _AutosaveStatus.saved;
      });
      await _reloadMedia();
    } catch (error) {
      if (mounted) {
        setState(() => _autosaveStatus = _AutosaveStatus.failed);
        AppMessenger.error(context, 'Uitlijning bewaren mislukt: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  domain.ShotImpact _impactFromAlignment(
    domain.ShotImpact impact,
    geo.ManualPhotoAlignment alignment,
  ) {
    final physical = alignment.normalizedToPhysical(
      geo.NormalizedPoint(impact.imageXNormalized!, impact.imageYNormalized!),
    );
    final halfWidth = alignment.cardWidthMm / 2;
    final halfHeight = alignment.cardHeightMm / 2;
    final xMm = physical.x.clamp(-halfWidth, halfWidth).toDouble();
    final yMm = physical.y.clamp(-halfHeight, halfHeight).toDouble();
    return impact.copyWith(
      xMm: xMm,
      yMm: yMm,
      targetBullId: _recordBullAt(xMm, yMm)?.id,
      clearTargetBull:
          _target?.targetKind == domain.TargetKind.multiBullConcentric &&
          _recordBullAt(xMm, yMm) == null,
    );
  }

  Future<bool> _confirmRealignmentScoreChange(
    List<domain.ShotImpact> realigned,
  ) async {
    final oldScore = ScoreEngine.score(
      target: _target!,
      impacts: _impacts,
      projectileDiameterMm: _projectileDiameterMm,
    );
    final newScore = ScoreEngine.score(
      target: _target!,
      impacts: realigned,
      projectileDiameterMm: _projectileDiameterMm,
    );
    final oldById = {
      for (final shot in oldScore.shots) shot.impact.id: shot.value,
    };
    final changedShots = [
      for (var index = 0; index < newScore.shots.length; index++)
        if (oldById[newScore.shots[index].impact.id] !=
            newScore.shots[index].value)
          (
            index: index + 1,
            before: oldById[newScore.shots[index].impact.id] ?? 0,
            after: newScore.shots[index].value,
          ),
    ];
    final changed = changedShots.length;
    final changeDetails = changedShots
        .map((item) => 'Punt ${item.index}: ${item.before} → ${item.after}')
        .join('\n');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nieuwe uitlijning controleren'),
        content: Text(
          'Score vóór uitlijnen: ${oldScore.total}/${oldScore.maximumPossible}\n'
          'Score na uitlijnen: ${newScore.total}/${newScore.maximumPossible}\n\n'
          '$changed ${changed == 1 ? 'ringwaarde verandert' : 'ringwaarden veranderen'}.'
          '${changeDetails.isEmpty ? '' : '\n\n$changeDetails'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Uitlijning bewaren'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _reloadMedia() async {
    final detail = await ref
        .read(repositoryProvider)
        .getSeriesDetail(_seriesId!);
    if (detail == null || !mounted) return;
    setState(() {
      _images = detail.images;
      _primaryImage = detail.primaryImage;
      _alignment = _decodeAlignment(detail.photoAlignment, _target!);
    });
  }
}

class _SettingsSummary extends StatelessWidget {
  const _SettingsSummary({
    required this.targetName,
    required this.cartridgeName,
    required this.distanceMeters,
    required this.autosaveStatus,
    required this.onEdit,
    required this.onRetry,
    this.compact = false,
  });

  final String targetName;
  final String cartridgeName;
  final double distanceMeters;
  final _AutosaveStatus autosaveStatus;
  final VoidCallback onEdit;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                targetName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '$cartridgeName · ${distanceMeters.toStringAsFixed(0)} m'
                ' · ${autosaveStatus.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (autosaveStatus == _AutosaveStatus.failed)
          IconButton(
            onPressed: onRetry,
            tooltip: 'Opnieuw proberen op te slaan',
            icon: const Icon(Icons.refresh),
          ),
        TextButton(onPressed: onEdit, child: const Text('Wijzig')),
      ],
    );
    return compact
        ? MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: content)
        : content;
  }
}

class _Br50BullTile extends StatelessWidget {
  const _Br50BullTile({
    required this.bull,
    required this.shots,
    required this.onSelect,
    required this.onAddMiss,
  });

  final domain.TargetBull bull;
  final List<ScoredImpact> shots;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddMiss;

  @override
  Widget build(BuildContext context) {
    if (shots.isEmpty) {
      return ListTile(
        leading: CircleAvatar(child: Text(bull.label)),
        title: const Text('Leeg · telt als 0'),
        trailing: IconButton(
          onPressed: onAddMiss,
          tooltip: 'Als misser registreren',
          icon: const Icon(Icons.add_circle_outline),
        ),
      );
    }
    final counted = shots
        .where(
          (shot) =>
              shot.disposition != domain.ScoreDisposition.duplicateNotCounted,
        )
        .firstOrNull;
    final selected = counted ?? shots.first;
    final totalShots = shots.fold<int>(
      0,
      (sum, shot) => sum + shot.impact.multiplicity,
    );
    return ExpansionTile(
      leading: CircleAvatar(child: Text(bull.label)),
      title: Text(
        selected.value == 0
            ? '0 · misser'
            : '${selected.value}${selected.isInnerTen ? ' X' : ''}',
      ),
      subtitle: totalShots > 1
          ? Text('$totalShots schoten · laagste telt')
          : null,
      children: [
        for (final shot in shots)
          ListTile(
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            title: Text(
              shot.impact.isMiss
                  ? 'Misser · 0'
                  : '${shot.value} punten${shot.isInnerTen ? ' · X' : ''}',
            ),
            subtitle:
                shot.disposition == domain.ScoreDisposition.duplicateNotCounted
                ? const Text('Telt niet · meerdere schoten')
                : const Text('Telt voor dit roosje'),
            trailing: const Icon(Icons.edit_location_alt_outlined),
            onTap: () => onSelect(shot.impact.id),
          ),
      ],
    );
  }
}

class _CanvasToolbar extends StatelessWidget {
  const _CanvasToolbar({
    required this.canUndo,
    required this.canActuallyUndo,
    required this.onMiss,
    required this.onUndo,
    required this.onPoints,
    required this.onPhoto,
    this.vertical = false,
  });

  final bool canUndo;
  final bool canActuallyUndo;
  final VoidCallback onMiss;
  final VoidCallback onUndo;
  final VoidCallback onPoints;
  final VoidCallback onPhoto;
  final bool vertical;

  @override
  Widget build(BuildContext context) => Flex(
    direction: vertical ? Axis.vertical : Axis.horizontal,
    mainAxisSize: vertical ? MainAxisSize.min : MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      IconButton.outlined(
        onPressed: onMiss,
        tooltip: 'Misser / 0 toevoegen',
        icon: const Icon(Icons.close),
      ),
      IconButton.outlined(
        onPressed: canActuallyUndo ? onUndo : null,
        tooltip: 'Laatste bewerking ongedaan maken',
        icon: const Icon(Icons.undo),
      ),
      IconButton.outlined(
        onPressed: canUndo ? onPoints : null,
        tooltip: 'Punten en missers',
        icon: const Icon(Icons.format_list_numbered),
      ),
      IconButton.outlined(
        onPressed: onPhoto,
        tooltip: 'Foto toevoegen',
        icon: const Icon(Icons.add_a_photo_outlined),
      ),
    ],
  );
}

class _ScoringModeBar extends StatelessWidget {
  const _ScoringModeBar({
    required this.tool,
    required this.precisionMode,
    required this.onToolChanged,
    required this.onPrecisionChanged,
    required this.onPlaceAtCrosshair,
    this.forceCompact = false,
  });

  final ScoringTool tool;
  final bool precisionMode;
  final ValueChanged<ScoringTool> onToolChanged;
  final ValueChanged<bool> onPrecisionChanged;
  final VoidCallback onPlaceAtCrosshair;
  final bool forceCompact;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          forceCompact ||
          constraints.maxWidth < 390 ||
          MediaQuery.textScalerOf(context).scale(1) >= 1.3;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<ScoringTool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ScoringTool.place,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: compact ? null : const Text('Plaatsen'),
                tooltip: 'Plaatsen: iedere tik maakt een nieuw punt',
              ),
              ButtonSegment(
                value: ScoringTool.edit,
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: compact ? null : const Text('Bewerken'),
                tooltip: 'Bewerken: selecteer of versleep een punt',
              ),
            ],
            selected: {tool},
            onSelectionChanged: (selection) => onToolChanged(selection.single),
          ),
          FilterChip(
            selected: precisionMode,
            avatar: const Icon(Icons.center_focus_strong, size: 18),
            label: const Text('Precisie'),
            onSelected: onPrecisionChanged,
          ),
          if (precisionMode)
            if (compact)
              IconButton.filledTonal(
                onPressed: onPlaceAtCrosshair,
                tooltip: 'Punt op het precisiekruis plaatsen',
                icon: const Icon(Icons.add_location_alt),
              )
            else
              FilledButton.tonalIcon(
                onPressed: onPlaceAtCrosshair,
                icon: const Icon(Icons.add),
                label: const Text('Punt plaatsen'),
              ),
        ],
      );
    },
  );
}

class _SelectedImpactBar extends StatelessWidget {
  const _SelectedImpactBar({
    required this.impact,
    required this.index,
    required this.score,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDelete,
  });

  final domain.ShotImpact impact;
  final int index;
  final int score;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${impact.isMiss ? 'Misser' : 'Treffer'}, multipliciteit ${impact.multiplicity}',
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 480 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.3;
        final label = impact.isMiss
            ? 'Punt $index · misser · ×${impact.multiplicity}'
            : 'Punt $index · $score punten · ×${impact.multiplicity}';
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              onPressed: impact.multiplicity > 1 ? onDecrease : null,
              tooltip: 'Eén schot minder',
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('×${impact.multiplicity}'),
            ),
            IconButton.outlined(
              onPressed: onIncrease,
              tooltip: 'Eén schot meer',
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: onDelete,
              tooltip: 'Punt verwijderen',
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        );
        if (compact) {
          return MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            ),
          );
        }
        return Row(
          children: [
            Expanded(child: Text(label)),
            actions,
          ],
        );
      },
    ),
  );
}

class _SeriesBottomActionBar extends StatelessWidget {
  const _SeriesBottomActionBar({
    required this.scoreText,
    required this.saving,
    required this.canSave,
    required this.showNext,
    required this.onSave,
    required this.onSaveNext,
  });

  final String scoreText;
  final bool saving;
  final bool canSave;
  final bool showNext;
  final VoidCallback onSave;
  final VoidCallback onSaveNext;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.3,
    child: AppActionDock(
      leading: Text(
        scoreText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      actions: [
        FilledButton(
          onPressed: canSave ? onSave : null,
          child: Text(saving ? 'Bewaren…' : 'Bewaren'),
        ),
        if (showNext)
          Semantics(
            label: 'Bewaren en volgende reeks',
            button: true,
            child: OutlinedButton(
              onPressed: canSave ? onSaveNext : null,
              child: const Text('Volgende'),
            ),
          ),
      ],
    ),
  );
}

class _EditorUndoEntry {
  const _EditorUndoEntry({
    required this.impacts,
    required this.selectedImpactId,
  });

  final List<domain.ShotImpact> impacts;
  final String? selectedImpactId;
}

class _PhotoChoice {
  const _PhotoChoice({required this.source, required this.asScoringPhoto});

  final ImageSource source;
  final bool asScoringPhoto;
}

class _PhotoChoiceSheet extends StatelessWidget {
  const _PhotoChoiceSheet();

  @override
  Widget build(BuildContext context) => SafeSheetScaffold(
    title: 'Foto toevoegen',
    contentSized: true,
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.camera_alt_outlined),
          title: const Text('Scorefoto maken'),
          subtitle: const Text('Foto uitlijnen en punten erop plaatsen'),
          onTap: () => Navigator.pop(
            context,
            const _PhotoChoice(
              source: ImageSource.camera,
              asScoringPhoto: true,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Scorefoto uit galerij'),
          onTap: () => Navigator.pop(
            context,
            const _PhotoChoice(
              source: ImageSource.gallery,
              asScoringPhoto: true,
            ),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.attach_file),
          title: const Text('Gewone foto toevoegen'),
          onTap: () => Navigator.pop(
            context,
            const _PhotoChoice(
              source: ImageSource.gallery,
              asScoringPhoto: false,
            ),
          ),
        ),
      ],
    ),
    actions: const [],
  );
}

enum _AutosaveStatus { saved, changed, saving, failed }

extension on _AutosaveStatus {
  String get label => switch (this) {
    _AutosaveStatus.saved => 'Opgeslagen',
    _AutosaveStatus.changed => 'Gewijzigd',
    _AutosaveStatus.saving => 'Opslaan…',
    _AutosaveStatus.failed => 'Opslaan mislukt — opnieuw proberen',
  };
}
