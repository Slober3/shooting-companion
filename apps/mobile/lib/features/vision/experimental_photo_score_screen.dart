import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;
import 'package:shooting_companion_vision_api/vision_api.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/vision_scan_repository.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/app_action_dock.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/safe_sheet_scaffold.dart';
import '../photo/four_point_alignment_editor.dart';
import '../photo/ring_assisted_alignment_editor.dart';
import 'vision_candidate_geometry.dart';
import 'vision_review_screen.dart';

class ExperimentalPhotoScoreScreen extends ConsumerStatefulWidget {
  const ExperimentalPhotoScoreScreen({super.key});

  @override
  ConsumerState<ExperimentalPhotoScoreScreen> createState() =>
      _ExperimentalPhotoScoreScreenState();
}

class _ExperimentalPhotoScoreScreenState
    extends ConsumerState<ExperimentalPhotoScoreScreen> {
  final _picker = ImagePicker();
  final _storage = ImageStorageService();
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final capabilities = ref.watch(visionCapabilitiesProvider);
    final drafts = ref.watch(visionScanDraftsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Experimentele fotoscore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          const _ExperimentalHeader(),
          const SizedBox(height: 20),
          _CapabilityCard(capabilities: capabilities),
          const SizedBox(height: 20),
          Text(
            'Goede foto maken',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _PhotoTips(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Conceptscans',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              drafts.when(
                data: (items) => Badge(
                  isLabelVisible: items.isNotEmpty,
                  label: Text('${items.length}'),
                  child: const Icon(Icons.drafts_outlined),
                ),
                loading: () => const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, _) => const Icon(Icons.error_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          drafts.when(
            data: (items) => items.isEmpty
                ? const _EmptyDrafts()
                : Column(
                    children: [
                      for (final draft in items) ...[
                        _DraftCard(
                          draft: draft,
                          onContinue: () => _openDraft(draft.id),
                          onDelete: () => _deleteDraft(draft),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Conceptscans laden mislukt: $error'),
          ),
          const SizedBox(height: 16),
          const _PrivacyNote(),
        ],
      ),
      bottomNavigationBar: AppActionDock(
        actions: [
          FilledButton.icon(
            onPressed: _importing ? null : _newScan,
            icon: _importing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_a_photo_outlined),
            label: const Text('Nieuwe scan'),
          ),
        ],
      ),
    );
  }

  Future<void> _newScan() async {
    final source = await showSafeModalSheet<ImageSource>(
      context: context,
      presentation: SafeSheetPresentation.compact,
      builder: (sheetContext) => SafeSheetScaffold(
        title: 'Foto kiezen',
        contentSized: true,
        actions: const [],
        body: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              subtitle: const Text('Neem nu een kaartfoto'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerij'),
              subtitle: const Text('Gebruik een bestaande kaartfoto'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    if (source == ImageSource.camera && !await _confirmPhotoSafety()) return;
    final picked = await _picker.pickImage(source: source);
    if (picked == null || !mounted) return;
    setState(() => _importing = true);
    try {
      final stored = await _storage.importJpeg(picked.path);
      final id = await ref
          .read(visionScanRepositoryProvider)
          .createDraft(image: stored);
      if (!mounted) return;
      await _openDraft(id);
    } catch (error) {
      if (mounted) {
        AppMessenger.error(context, 'Foto importeren mislukt: $error');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<bool> _confirmPhotoSafety() async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Veilig fotograferen'),
          content: const Text(
            'Bevestig dat de baan veilig is en dat fotograferen volgens de '
            'regels van de schietstand is toegestaan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuleren'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ik bevestig dit'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _openDraft(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => VisionScanFlowScreen(scanId: id)),
    );
  }

  Future<void> _deleteDraft(VisionScanDraftRecord draft) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conceptscan verwijderen?'),
        content: const Text(
          'De lokale foto, kandidaten en niet-gekoppelde controlewijzigingen '
          'worden definitief verwijderd.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(visionScanRepositoryProvider).deleteDraft(draft.id);
      if (mounted) AppMessenger.success(context, 'Conceptscan verwijderd');
    } catch (error) {
      if (mounted) AppMessenger.error(context, 'Verwijderen mislukt: $error');
    }
  }
}

class VisionScanFlowScreen extends ConsumerStatefulWidget {
  const VisionScanFlowScreen({required this.scanId, super.key});

  final String scanId;

  @override
  ConsumerState<VisionScanFlowScreen> createState() =>
      _VisionScanFlowScreenState();
}

class _VisionScanFlowScreenState extends ConsumerState<VisionScanFlowScreen> {
  bool _running = false;
  bool _openedReview = false;

  @override
  void dispose() {
    unawaited(ref.read(visionAnalyzerProvider).cancel(widget.scanId));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(visionScanDraftProvider(widget.scanId));
    final currentDraft = draftAsync.valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Fotoscore')),
      body: draftAsync.when(
        data: (draft) {
          if (draft == null) {
            return const Center(
              child: Text('Deze conceptscan bestaat niet meer.'),
            );
          }
          if (draft.status == VisionScanDraftStatus.readyToLink.name &&
              !_openedReview) {
            _openReviewAfterFrame();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              const _StepIndicator(current: 2),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: draft.width / draft.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(draft.originalImagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Colors.black12,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _DraftStatusPanel(draft: draft),
              if (draft.qualityJson != null) ...[
                const SizedBox(height: 16),
                _QualityPanel(
                  quality: VisionQualityAssessment.fromJson(
                    (jsonDecode(draft.qualityJson!) as Map)
                        .cast<String, Object?>(),
                  ),
                  registration: _registration(draft),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'De detector doet alleen voorstellen. Controleer elk punt; '
                'overlappende gaten en missers blijven handmatig.',
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Scan laden mislukt: $error')),
      ),
      bottomNavigationBar: currentDraft == null
          ? null
          : _actionsFor(currentDraft),
    );
  }

  Widget _actionsFor(VisionScanDraftRecord draft) {
    final status = VisionScanDraftStatus.values.byName(draft.status);
    if (_running || status == VisionScanDraftStatus.analyzing) {
      return AppActionDock(
        leading: const Text('Lokale computer vision verwerkt de foto…'),
        actions: [
          OutlinedButton(
            onPressed: _cancelAnalysis,
            child: const Text('Annuleren'),
          ),
        ],
      );
    }
    if (status == VisionScanDraftStatus.reviewNeeded ||
        status == VisionScanDraftStatus.readyToLink) {
      final registered =
          _registration(draft)?.status == VisionRegistrationStatus.registered;
      return AppActionDock(
        actions: [
          OutlinedButton(
            onPressed: () => _manualAlignment(draft),
            child: const Text('Hoeken aanpassen'),
          ),
          FilledButton(
            onPressed: registered ? () => _openReview(draft) : null,
            child: const Text('Treffers controleren'),
          ),
        ],
      );
    }
    return AppActionDock(
      actions: [
        OutlinedButton(
          onPressed: () => _manualAlignment(draft),
          child: const Text('Handmatig uitlijnen'),
        ),
        FilledButton.icon(
          onPressed: _runAnalysis,
          icon: const Icon(Icons.auto_fix_high_outlined),
          label: Text(
            status == VisionScanDraftStatus.failed
                ? 'Opnieuw analyseren'
                : 'Analyseren',
          ),
        ),
      ],
    );
  }

  VisionRegistrationResult? _registration(VisionScanDraftRecord draft) {
    if (draft.registrationJson == null) return null;
    return VisionRegistrationResult.fromJson(
      (jsonDecode(draft.registrationJson!) as Map).cast<String, Object?>(),
    );
  }

  Future<void> _runAnalysis() async {
    if (_running) return;
    final draft = await ref
        .read(visionScanRepositoryProvider)
        .getDraft(widget.scanId);
    if (draft == null || !mounted) return;
    setState(() => _running = true);
    final repository = ref.read(visionScanRepositoryProvider);
    try {
      final capabilities = await ref
          .read(visionAnalyzerProvider)
          .capabilities();
      if (!capabilities.supportsCandidates) {
        throw StateError(
          'Deze appbuild bevat geen OpenCV-kandidaatdetector. '
          'Handmatig uitlijnen en scoren blijft beschikbaar.',
        );
      }
      await repository.markAnalyzing(widget.scanId);
      final result = await ref
          .read(visionAnalyzerProvider)
          .analyze(
            AnalyzeTargetRequest(
              jobId: widget.scanId,
              imagePath: draft.originalImagePath,
              targetProfileSnapshot: domain.TargetProfile.fromJsonString(
                draft.targetProfileJson,
              ),
              projectileDiameterMm: draft.projectileDiameterMm,
            ),
          );
      await repository.saveAnalysisResult(widget.scanId, result);
      if (mounted) {
        AppMessenger.info(
          context,
          '${result.candidateImpacts.length} mogelijke treffers gevonden',
        );
      }
    } on VisionAnalysisCancelled {
      await repository.saveAnalysisFailure(widget.scanId, 'analysis_cancelled');
    } catch (error) {
      await repository.saveAnalysisFailure(widget.scanId, error.toString());
      if (mounted) AppMessenger.error(context, 'Analyse mislukt: $error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _cancelAnalysis() async {
    await ref.read(visionAnalyzerProvider).cancel(widget.scanId);
  }

  Future<void> _manualAlignment(VisionScanDraftRecord draft) async {
    final target = domain.TargetProfile.fromJsonString(draft.targetProfileJson);
    final initialAlignment = _alignmentFromDraft(draft, target);
    final alignmentMode = await _chooseAlignmentMode(
      target,
      initialAlignment?.alignmentMode,
    );
    if (alignmentMode == null || !mounted) return;
    final ringRadiiMm =
        target.rings
            .map((ring) => ring.outerDiameterMm / 2)
            .where((radius) => radius > 0 && radius.isFinite)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    final alignment = await Navigator.of(context)
        .push<geo.ManualPhotoAlignment>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (routeContext) => Scaffold(
              appBar: AppBar(
                title: Text(
                  alignmentMode == geo.PhotoAlignmentMode.ringAssisted
                      ? 'Ringen uitlijnen'
                      : 'Kaart uitlijnen',
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: alignmentMode == geo.PhotoAlignmentMode.ringAssisted
                      ? RingAssistedAlignmentEditor(
                          imageProvider: FileImage(
                            File(draft.originalImagePath),
                          ),
                          imagePixelSize: Size(
                            draft.width.toDouble(),
                            draft.height.toDouble(),
                          ),
                          cardWidthMm: target.physicalCardWidthMm,
                          cardHeightMm: target.physicalCardHeightMm,
                          ringRadiiMm: ringRadiiMm,
                          initialAlignment:
                              initialAlignment?.alignmentMode == alignmentMode
                              ? initialAlignment
                              : null,
                          initialRotationQuarterTurns:
                              initialAlignment?.rotationQuarterTurns ??
                              draft.rotationQuarterTurns,
                          targetProfile: target,
                          onConfirmed: (value) =>
                              Navigator.pop(routeContext, value),
                        )
                      : FourPointAlignmentEditor(
                          imageProvider: FileImage(
                            File(draft.originalImagePath),
                          ),
                          imagePixelSize: Size(
                            draft.width.toDouble(),
                            draft.height.toDouble(),
                          ),
                          cardWidthMm: target.physicalCardWidthMm,
                          cardHeightMm: target.physicalCardHeightMm,
                          initialCorners:
                              initialAlignment?.alignmentMode == alignmentMode
                              ? initialAlignment?.corners
                              : null,
                          initialRotationQuarterTurns:
                              initialAlignment?.rotationQuarterTurns ??
                              draft.rotationQuarterTurns,
                          targetProfile: target,
                          onConfirmed: (value) =>
                              Navigator.pop(routeContext, value),
                        ),
                ),
              ),
            ),
          ),
        );
    if (alignment == null || !mounted) return;
    final quality = draft.qualityJson == null
        ? VisionQualityAssessment(
            status: VisionQualityStatus.review,
            widthPx: draft.width,
            heightPx: draft.height,
            issues: const [],
          )
        : VisionQualityAssessment.fromJson(
            (jsonDecode(draft.qualityJson!) as Map).cast<String, Object?>(),
          );
    final result = AnalyzeTargetResult(
      status: VisionAnalysisStatus.completed,
      engineVersion: draft.engineVersion ?? 'manual-registration-v2',
      provenance: VisionProvenance(
        backend: VisionBackend.geometryOnly,
        abiVersion: 2,
        engineVersion: draft.engineVersion ?? 'manual-registration-v2',
        capabilities: const ['manualRegistration'],
        algorithmVersions: {'registration': alignment.algorithmVersion},
        analyzedAtUtc: DateTime.now().toUtc(),
      ),
      registrationResult: VisionRegistrationResult(
        status: VisionRegistrationStatus.registered,
        orderedSourceCornersNormalized: alignment.corners.points
            .map((point) => VisionPoint(x: point.x, y: point.y))
            .toList(),
        sourceNormalizedToCardMmHomography: alignment.homographyMatrix,
        algorithmVersion: alignment.algorithmVersion,
      ),
      qualityAssessment: quality,
      candidateImpacts: reprojectVisionCandidates(
        candidates: draft.candidatesJson == null
            ? const []
            : (jsonDecode(draft.candidatesJson!) as List)
                  .map(
                    (item) => VisionCandidateImpact.fromJson(
                      (item as Map).cast<String, Object?>(),
                    ),
                  )
                  .toList(),
        alignment: alignment,
        target: target,
        projectileDiameterMm: draft.projectileDiameterMm,
      ),
      warnings: const [
        VisionWarning(
          code: VisionWarningCode.candidatesRequireReview,
          message:
              'De kaart werd handmatig uitgelijnd; controleer alle treffers.',
        ),
      ],
    );
    await ref
        .read(visionScanRepositoryProvider)
        .saveAnalysisResult(
          widget.scanId,
          result,
          confirmedAlignment: domain.StoredPhotoAlignment(
            imageId: widget.scanId,
            orderedCorners: alignment.corners.points
                .map((point) => domain.NormalizedPoint(x: point.x, y: point.y))
                .toList(growable: false),
            homographyMatrix: alignment.homographyMatrix,
            algorithmVersion: alignment.algorithmVersion,
            rotationQuarterTurns: alignment.rotationQuarterTurns,
            alignmentMode:
                alignment.alignmentMode == geo.PhotoAlignmentMode.fourCorners
                ? 'fullCard'
                : 'ringAssisted',
            anchorsJson: jsonEncode(
              alignment.anchors.map((anchor) => anchor.toJson()).toList(),
            ),
            reprojectionRmsMm: alignment.residuals.rmsMm,
            reprojectionMaxMm: alignment.residuals.maximumMm,
            planarityStatus: _alignmentPlanarityStatus(alignment),
            confirmedAtUtc: DateTime.now().toUtc(),
            updatedAtUtc: DateTime.now().toUtc(),
          ),
        );
  }

  geo.ManualPhotoAlignment? _alignmentFromDraft(
    VisionScanDraftRecord draft,
    domain.TargetProfile target,
  ) {
    final registration = _registration(draft);
    final corners = registration?.orderedSourceCornersNormalized;
    final matrix = registration?.sourceNormalizedToCardMmHomography;
    if (corners == null || corners.length != 4 || matrix == null) return null;
    try {
      final decodedAnchors = draft.anchorsJson == null
          ? null
          : jsonDecode(draft.anchorsJson!);
      return geo.ManualPhotoAlignment.fromJson({
        'schemaVersion': geo.photoAlignmentSchemaVersion,
        'algorithmVersion':
            draft.alignmentAlgorithmVersion ??
            registration?.algorithmVersion ??
            geo.manualHomographyV2AlgorithmVersion,
        'alignmentMode': draft.alignmentMode == 'fullCard'
            ? geo.PhotoAlignmentMode.fourCorners.name
            : draft.alignmentMode,
        'anchors': ?decodedAnchors,
        'cardWidthMm': target.physicalCardWidthMm,
        'cardHeightMm': target.physicalCardHeightMm,
        'corners': geo.NormalizedQuad.fromOrderedPoints(
          corners
              .map((point) => geo.NormalizedPoint(point.x, point.y))
              .toList(growable: false),
        ).toJson(),
        'homographyMatrix': matrix,
        'rotationQuarterTurns': draft.rotationQuarterTurns,
      });
    } on Object {
      return null;
    }
  }

  Future<geo.PhotoAlignmentMode?> _chooseAlignmentMode(
    domain.TargetProfile target,
    geo.PhotoAlignmentMode? currentMode,
  ) async {
    final supportsRingAssisted =
        target.targetKind == domain.TargetKind.concentricRings &&
        target.rings.map((ring) => ring.outerDiameterMm).toSet().length >= 2;
    if (!supportsRingAssisted) return geo.PhotoAlignmentMode.fourCorners;
    return showSafeModalSheet<geo.PhotoAlignmentMode>(
      context: context,
      presentation: SafeSheetPresentation.compact,
      builder: (sheetContext) => SafeSheetScaffold(
        title: 'Uitlijningsmethode',
        contentSized: true,
        actions: const [],
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.crop_free),
              title: const Text('Volledige kaart'),
              subtitle: const Text('Lijn de vier zichtbare kaarthoeken uit.'),
              trailing: currentMode == geo.PhotoAlignmentMode.fourCorners
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(
                sheetContext,
                geo.PhotoAlignmentMode.fourCorners,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.radio_button_checked),
              title: const Text('Alleen ringen zichtbaar'),
              subtitle: const Text(
                'Gebruik richtpunt en twee ringen als de hoeken zijn afgesneden.',
              ),
              trailing: currentMode == geo.PhotoAlignmentMode.ringAssisted
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(
                sheetContext,
                geo.PhotoAlignmentMode.ringAssisted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _alignmentPlanarityStatus(geo.ManualPhotoAlignment alignment) {
    final residuals = alignment.residuals;
    if (residuals.rmsMm <= 0.75 && residuals.maximumMm <= 1.5) {
      return 'accepted';
    }
    if (residuals.rmsMm <= 1.5 && residuals.maximumMm <= 3.0) {
      return 'manualReviewOnly';
    }
    return 'rejected';
  }

  void _openReviewAfterFrame() {
    _openedReview = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final draft = await ref
          .read(visionScanRepositoryProvider)
          .getDraft(widget.scanId);
      if (draft != null && mounted) await _openReview(draft);
    });
  }

  Future<void> _openReview(VisionScanDraftRecord draft) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VisionReviewScreen(scanId: draft.id),
      ),
    );
  }
}

class _ExperimentalHeader extends StatelessWidget {
  const _ExperimentalHeader();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Chip(
            avatar: Icon(Icons.science_outlined, size: 18),
            label: Text('Experimenteel'),
          ),
          const SizedBox(height: 8),
          Text(
            'Scorevoorstel uit een kaartfoto',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Ondersteund: ISSF 25 m Precision / 50 m Pistol · .22 LR'),
          const SizedBox(height: 8),
          const Text(
            'Alle verwerking gebeurt lokaal. Een voorstel wordt nooit zonder '
            'jouw controle als score bewaard.',
          ),
        ],
      ),
    ),
  );
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({required this.capabilities});

  final AsyncValue<VisionAnalyzerCapabilities> capabilities;

  @override
  Widget build(BuildContext context) => capabilities.when(
    data: (value) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        value.supportsCandidates
            ? Icons.check_circle_outline
            : Icons.warning_amber_rounded,
      ),
      title: Text(
        value.supportsCandidates
            ? 'Lokale detector beschikbaar'
            : 'Automatische detector niet beschikbaar in deze build',
      ),
      subtitle: Text(
        value.supportsCandidates
            ? '${value.engineVersion} · OpenCV lokaal'
            : value.unavailableReason ?? 'Handmatig scoren blijft beschikbaar.',
      ),
    ),
    loading: () => const LinearProgressIndicator(),
    error: (error, _) => Text('Visioncapaciteit controleren mislukt: $error'),
  );
}

class _PhotoTips extends StatelessWidget {
  const _PhotoTips();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Tip('Toon de volledige vierkante kaart met een kleine marge.'),
      _Tip('Fotografeer zo recht mogelijk, zonder reflectie of diepe schaduw.'),
      _Tip(
        'Gebruik een relatief schone kaart waarvan de ringen zichtbaar zijn.',
      ),
    ],
  );
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(Icons.check, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.onContinue,
    required this.onDelete,
  });

  final VisionScanDraftRecord draft;
  final VoidCallback onContinue;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = VisionScanDraftStatus.values.byName(draft.status);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onContinue,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(draft.originalImagePath),
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusLabel(status),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(_candidateSummary(draft)),
                    Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(draft.updatedAtUtc.toLocal()),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Conceptscanacties',
                onSelected: (value) =>
                    value == 'delete' ? onDelete() : onContinue(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'continue', child: Text('Verdergaan')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Concept verwijderen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _candidateSummary(VisionScanDraftRecord draft) {
    if (draft.candidatesJson == null) return 'Nog geen kandidaten';
    try {
      return '${(jsonDecode(draft.candidatesJson!) as List).length} kandidaten';
    } catch (_) {
      return 'Kandidaten controleren';
    }
  }

  static String _statusLabel(VisionScanDraftStatus status) => switch (status) {
    VisionScanDraftStatus.analysisNeeded => 'Analyse nodig',
    VisionScanDraftStatus.analyzing => 'Analyse bezig',
    VisionScanDraftStatus.reviewNeeded => 'Controle nodig',
    VisionScanDraftStatus.readyToLink => 'Klaar om te koppelen',
    VisionScanDraftStatus.failed => 'Opnieuw proberen',
  };
}

class _EmptyDrafts extends StatelessWidget {
  const _EmptyDrafts();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        'Nog geen conceptscans. Een geïmporteerde foto wordt hier direct veilig bewaard.',
      ),
    ),
  );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => const ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(Icons.phonelink_lock_outlined),
    title: Text('Volledig lokaal en offline'),
    subtitle: Text('Foto’s en analyseresultaten verlaten je telefoon niet.'),
  );
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final entry in const [
        (1, 'Foto'),
        (2, 'Uitlijning'),
        (3, 'Controleren'),
        (4, 'Koppelen'),
      ])
        Chip(
          avatar: CircleAvatar(child: Text('${entry.$1}')),
          label: Text(entry.$2),
          backgroundColor: entry.$1 == current
              ? Theme.of(context).colorScheme.secondaryContainer
              : null,
        ),
    ],
  );
}

class _DraftStatusPanel extends StatelessWidget {
  const _DraftStatusPanel({required this.draft});
  final VisionScanDraftRecord draft;

  @override
  Widget build(BuildContext context) {
    final status = VisionScanDraftStatus.values.byName(draft.status);
    final (icon, title, body) = switch (status) {
      VisionScanDraftStatus.analysisNeeded => (
        Icons.photo_outlined,
        'Foto opgeslagen',
        'Start lokale analyse of lijn de kaart handmatig uit.',
      ),
      VisionScanDraftStatus.analyzing => (
        Icons.hourglass_top,
        'Analyse bezig',
        'Kwaliteit, kaartgeometrie en mogelijke gaten worden gecontroleerd.',
      ),
      VisionScanDraftStatus.reviewNeeded => (
        Icons.fact_check_outlined,
        'Controle nodig',
        'Controleer de uitlijning en daarna ieder voorgesteld punt.',
      ),
      VisionScanDraftStatus.readyToLink => (
        Icons.link_outlined,
        'Klaar om te koppelen',
        'De gecontroleerde score kan aan een sessie worden gekoppeld.',
      ),
      VisionScanDraftStatus.failed => (
        Icons.warning_amber_rounded,
        'Analyse niet voltooid',
        draft.failureCode ??
            'Probeer opnieuw of gebruik handmatige uitlijning.',
      ),
    };
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(body),
      ),
    );
  }
}

class _QualityPanel extends StatelessWidget {
  const _QualityPanel({required this.quality, required this.registration});
  final VisionQualityAssessment quality;
  final VisionRegistrationResult? registration;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fotokwaliteit', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _QualityRow(
            label: 'Resolutie',
            good: quality.widthPx != null && quality.heightPx != null,
            value: '${quality.widthPx ?? '—'} × ${quality.heightPx ?? '—'} px',
          ),
          _QualityRow(
            label: 'Scherpte',
            good: quality.issues.every(
              (issue) => issue.code != VisionQualityIssueCode.blurred,
            ),
            value: quality.blurScore?.toStringAsFixed(1) ?? 'Niet gemeten',
          ),
          _QualityRow(
            label: 'Contrast',
            good: quality.issues.every(
              (issue) => issue.code != VisionQualityIssueCode.lowContrast,
            ),
            value: quality.contrastScore?.toStringAsFixed(1) ?? 'Niet gemeten',
          ),
          _QualityRow(
            label: 'Belichting',
            good: quality.issues.every(
              (issue) =>
                  issue.code != VisionQualityIssueCode.overexposed &&
                  issue.code != VisionQualityIssueCode.underexposed,
            ),
            value: _exposureLabel(quality),
          ),
          _QualityRow(
            label: 'Volledige kaart',
            good:
                registration?.status == VisionRegistrationStatus.registered &&
                quality.issues.every(
                  (issue) => issue.code != VisionQualityIssueCode.clippedTarget,
                ),
            value: registration?.status == VisionRegistrationStatus.registered
                ? 'Gevonden'
                : 'Controle nodig',
          ),
          _QualityRow(
            label: 'Perspectief',
            good:
                registration?.status == VisionRegistrationStatus.registered &&
                quality.issues.every(
                  (issue) =>
                      issue.code != VisionQualityIssueCode.extremePerspective,
                ),
            value: registration?.estimatedPerspectiveAngleDegrees == null
                ? 'Niet gemeten'
                : '${registration!.estimatedPerspectiveAngleDegrees!.toStringAsFixed(1)}°',
          ),
          _QualityRow(
            label: 'Scoringsringen',
            good: registration?.status == VisionRegistrationStatus.registered,
            value: registration?.status == VisionRegistrationStatus.registered
                ? 'Herkenbaar'
                : 'Handmatig controleren',
          ),
          for (final issue in quality.issues)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                issue.severity == VisionIssueSeverity.error
                    ? Icons.error_outline
                    : Icons.warning_amber_rounded,
              ),
              title: Text(issue.message),
            ),
        ],
      ),
    ),
  );

  static String _exposureLabel(VisionQualityAssessment quality) {
    final dark = quality.darkClippedFraction;
    final bright = quality.brightClippedFraction;
    if (dark == null || bright == null) return 'Niet gemeten';
    return '${(dark * 100).toStringAsFixed(1)}% donker · '
        '${(bright * 100).toStringAsFixed(1)}% licht';
  }
}

class _QualityRow extends StatelessWidget {
  const _QualityRow({
    required this.label,
    required this.good,
    required this.value,
  });
  final String label;
  final bool good;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(
          good ? Icons.check_circle_outline : Icons.warning_amber_rounded,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}
