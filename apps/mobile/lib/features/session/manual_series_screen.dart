import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;
import 'package:shooting_companion_scoring/scoring.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/safe_bottom_action_bar.dart';
import '../photo/photo.dart';
import '../scoring/target_canvas.dart';
import 'series_settings_sheet.dart';

class ManualSeriesScreen extends ConsumerStatefulWidget {
  const ManualSeriesScreen({
    required this.sessionId,
    this.seriesId,
    this.openPhotoPickerOnLoad = false,
    super.key,
  });

  final String sessionId;
  final String? seriesId;
  final bool openPhotoPickerOnLoad;

  @override
  ConsumerState<ManualSeriesScreen> createState() => _ManualSeriesScreenState();
}

class _ManualSeriesScreenState extends ConsumerState<ManualSeriesScreen>
    with WidgetsBindingObserver {
  final _storage = ImageStorageService();
  final _picker = ImagePicker();

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
  bool _saved = true;
  bool _allowPop = false;
  bool _sessionActive = true;
  bool _photoSafetyAcknowledged = false;
  bool _openedInitialPhotoPicker = false;
  Timer? _autosaveTimer;
  Future<void> _saveQueue = Future.value();

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
    final cartridges =
        ref.watch(cartridgesProvider).valueOrNull ?? const <CartridgeRecord>[];
    final cartridge = cartridges
        .where((item) => item.id == _cartridgeId)
        .firstOrNull;
    final isDraft = _series!.status == domain.SeriesStatus.draft.name;

    return PopScope<Object?>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_saveBeforePop(result));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isDraft ? 'Nieuwe reeks' : 'Reeks bewerken'),
          actions: [
            if (isDraft)
              PopupMenuButton<String>(
                tooltip: 'Meer acties',
                onSelected: (value) {
                  if (value == 'delete') unawaited(_deleteDraft());
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_outline),
                      title: Text('Concept verwijderen'),
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                _SettingsSummary(
                  targetName: target.displayName,
                  cartridgeName: cartridge?.name ?? 'Kaliber',
                  distanceMeters: _distanceMeters,
                  saved: _saved,
                  onEdit: _openSettings,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: _buildCanvas(scoreById),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _CanvasToolbar(
                  canUndo: _impacts.isNotEmpty,
                  onMiss: _addMiss,
                  onUndo: _undo,
                  onClear: _clear,
                  onPhoto: _choosePhoto,
                ),
                if (_selectedImpact != null) ...[
                  const SizedBox(height: 6),
                  _SelectedImpactBar(
                    impact: _selectedImpact!,
                    onDecrease: _decreaseMultiplicity,
                    onIncrease: _increaseMultiplicity,
                    onDelete: _deleteSelected,
                  ),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeBottomActionBar(
          leading: Text(
            '${score.total}/${score.maximumPossible} · '
            '${score.innerTenCount} X · ${score.actualShotCount} schoten',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          actions: [
            FilledButton(
              onPressed: score.actualShotCount == 0 || _saving
                  ? null
                  : () => _finish(saveNext: false),
              child: Text(_saving ? 'Bewaren…' : 'Bewaren'),
            ),
            if (_sessionActive)
              OutlinedButton(
                onPressed: score.actualShotCount == 0 || _saving
                    ? null
                    : () => _finish(saveNext: true),
                child: const Text('Bewaren + volgende'),
              ),
          ],
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
          final impact = domain.ShotImpact(
            id: 'impact-${DateTime.now().microsecondsSinceEpoch}',
            xMm: position.physicalMm.x,
            yMm: position.physicalMm.y,
            sourceImageId: image.id,
            imageXNormalized: position.normalized.x,
            imageYNormalized: position.normalized.y,
          );
          _changeImpacts([..._impacts, impact], selectedId: impact.id);
        },
        onImpactMoved: (id, position) {
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
                        )
                      : impact,
                )
                .toList(),
            selectedId: id,
          );
        },
        onImpactSelected: (id) => setState(() => _selectedImpactId = id),
      );
    }

    return TargetCanvas(
      target: _target!,
      impacts: _impacts,
      projectileDiameterMm: _projectileDiameterMm,
      scoreValues: scoreById,
      selectedImpactId: _selectedImpactId,
      onImpactSelected: (id) => setState(() => _selectedImpactId = id),
      onChanged: (value) => _changeImpacts(value),
    );
  }

  domain.ShotImpact? get _selectedImpact =>
      _impacts.where((impact) => impact.id == _selectedImpactId).firstOrNull;

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

  void _changeImpacts(List<domain.ShotImpact> impacts, {String? selectedId}) {
    setState(() {
      _impacts = impacts;
      _selectedImpactId = selectedId ?? _selectedImpactId;
      if (!_impacts.any((item) => item.id == _selectedImpactId)) {
        _selectedImpactId = null;
      }
    });
    _scheduleAutosave();
  }

  void _addMiss() {
    final impact = domain.ShotImpact(
      id: 'impact-${DateTime.now().microsecondsSinceEpoch}',
      xMm: 0,
      yMm: 0,
      isMiss: true,
    );
    _changeImpacts([..._impacts, impact], selectedId: impact.id);
  }

  void _undo() {
    if (_impacts.isEmpty) return;
    _changeImpacts(_impacts.sublist(0, _impacts.length - 1));
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
              ),
            )
            .toList();
      }
    });
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    setState(() => _saved = false);
    _autosaveTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_persistSnapshot());
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
        setState(() => _saved = true);
      }
    }

    _saveQueue = _saveQueue.then(
      (_) => operation(),
      onError: (_, _) => operation(),
    );
    return _saveQueue;
  }

  Future<void> _flushSave() async {
    final hadPending = _autosaveTimer?.isActive == true;
    _autosaveTimer?.cancel();
    if (hadPending || !_saved) await _persistSnapshot();
    await _saveQueue;
  }

  Future<void> _finish({required bool saveNext}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _flushSave();
      final repository = ref.read(repositoryProvider);
      final wasDraft = _series!.status == domain.SeriesStatus.draft.name;
      if (wasDraft) await repository.confirmSeries(_seriesId!);
      if (!mounted) return;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bewaren mislukt: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
    if (confirmed != true) return;
    _autosaveTimer?.cancel();
    await _saveQueue;
    await ref.read(repositoryProvider).deleteSeries(_seriesId!);
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.of(context).pop(true);
  }

  Future<void> _choosePhoto() async {
    final choice = await showModalBottomSheet<_PhotoChoice>(
      context: context,
      useSafeArea: true,
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
    } catch (error) {
      if (staged != null && stored == null) {
        await _storage.discardStagedImage(staged);
      }
      if (stored != null && attachedImageId == null) {
        await _storage.deleteStoredImage(stored.path);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto toevoegen mislukt: $error')),
        );
      }
    }
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
    final target = _target!;
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
                    onConfirmed: (value) => Navigator.pop(context, value),
                    onUseAsAttachment: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        );
    if (alignment == null || !mounted) return;
    final repository = ref.read(repositoryProvider);
    await repository.setPrimaryScoringImage(image.id);
    await repository.savePhotoAlignment(
      domain.StoredPhotoAlignment(
        imageId: image.id,
        orderedCorners: alignment.corners.points
            .map((point) => domain.NormalizedPoint(x: point.x, y: point.y))
            .toList(),
        homographyMatrix: alignment.homographyMatrix,
        algorithmVersion: alignment.algorithmVersion,
        updatedAtUtc: DateTime.now().toUtc(),
      ),
    );
    await _reloadMedia();
    _scheduleAutosave();
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
    required this.saved,
    required this.onEdit,
  });

  final String targetName;
  final String cartridgeName;
  final double distanceMeters;
  final bool saved;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Row(
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
              '${saved ? ' · Opgeslagen' : ' · Bewaren…'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      TextButton(onPressed: onEdit, child: const Text('Wijzig')),
    ],
  );
}

class _CanvasToolbar extends StatelessWidget {
  const _CanvasToolbar({
    required this.canUndo,
    required this.onMiss,
    required this.onUndo,
    required this.onClear,
    required this.onPhoto,
  });

  final bool canUndo;
  final VoidCallback onMiss;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        OutlinedButton.icon(
          onPressed: onMiss,
          icon: const Icon(Icons.close),
          label: const Text('Misser / 0'),
        ),
        const SizedBox(width: 6),
        IconButton.outlined(
          onPressed: canUndo ? onUndo : null,
          tooltip: 'Ongedaan maken',
          icon: const Icon(Icons.undo),
        ),
        const SizedBox(width: 6),
        IconButton.outlined(
          onPressed: canUndo ? onClear : null,
          tooltip: 'Alle punten wissen',
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: onPhoto,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Foto'),
        ),
      ],
    ),
  );
}

class _SelectedImpactBar extends StatelessWidget {
  const _SelectedImpactBar({
    required this.impact,
    required this.onDecrease,
    required this.onIncrease,
    required this.onDelete,
  });

  final domain.ShotImpact impact;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${impact.isMiss ? 'Misser' : 'Treffer'}, multipliciteit ${impact.multiplicity}',
    child: Row(
      children: [
        Expanded(
          child: Text(
            impact.isMiss ? 'Misser geselecteerd' : 'Punt geselecteerd',
          ),
        ),
        IconButton(
          onPressed: impact.multiplicity > 1 ? onDecrease : null,
          tooltip: 'Eén schot minder',
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('× ${impact.multiplicity}'),
        IconButton(
          onPressed: onIncrease,
          tooltip: 'Eén schot meer',
          icon: const Icon(Icons.add_circle_outline),
        ),
        IconButton(
          onPressed: onDelete,
          tooltip: 'Punt verwijderen',
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
  );
}

class _PhotoChoice {
  const _PhotoChoice({required this.source, required this.asScoringPhoto});

  final ImageSource source;
  final bool asScoringPhoto;
}

class _PhotoChoiceSheet extends StatelessWidget {
  const _PhotoChoiceSheet();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
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
  );
}
