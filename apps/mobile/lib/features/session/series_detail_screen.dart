import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_analysis/analysis.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_action_dock.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../photo/photo.dart';
import '../progress/analysis_adapter.dart';
import '../progress/group_analysis_widgets.dart';
import '../progress/series_analysis_screen.dart';
import '../scoring/target_canvas.dart';
import '../scoring/transformable_scoring_viewport.dart';
import '../training_tools/shot_timer_flow.dart';
import '../training_tools/timer_history_screen.dart';
import 'manual_series_screen.dart';

class SeriesDetailScreen extends ConsumerWidget {
  const SeriesDetailScreen({required this.seriesId, super.key});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(seriesDetailProvider(seriesId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reeksdetail'),
        actions: [
          if (detail.valueOrNull != null)
            IconButton(
              tooltip: 'Timer voor deze reeks starten',
              onPressed: () => launchShotTimerFlow(
                context: context,
                ref: ref,
                sessionId: detail.valueOrNull!.series.sessionId,
                seriesId: seriesId,
              ),
              icon: const Icon(Icons.timer_outlined),
            ),
          PopupMenuButton<String>(
            tooltip: 'Reeksacties',
            onSelected: (value) {
              if (value == 'delete') unawaited(_delete(context, ref));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline),
                  title: Text('Reeks verwijderen'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: detail.when(
        data: (value) => value == null
            ? const Center(child: Text('Deze reeks bestaat niet meer.'))
            : _SeriesDetailBody(detail: value),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Laden mislukt: $error')),
      ),
      bottomNavigationBar: detail.valueOrNull == null
          ? null
          : AppActionDock(
              actions: [
                FilledButton.icon(
                  onPressed: () =>
                      _edit(context, detail.valueOrNull!.series.sessionId),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Bewerken'),
                ),
                Semantics(
                  button: true,
                  label: 'Foto toevoegen aan deze reeks',
                  child: ExcludeSemantics(
                    child: OutlinedButton.icon(
                      onPressed: () => _edit(
                        context,
                        detail.valueOrNull!.series.sessionId,
                        addPhoto: true,
                      ),
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Foto', maxLines: 1),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    String sessionId, {
    bool addPhoto = false,
  }) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ManualSeriesScreen(
        sessionId: sessionId,
        seriesId: seriesId,
        openPhotoPickerOnLoad: addPhoto,
      ),
    ),
  );

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final detail = ref.read(seriesDetailProvider(seriesId)).valueOrNull;
    if (detail == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reeks verwijderen?'),
        content: Text(
          'Reeks ${detail.series.sequenceNumber}, ${detail.series.shotCount} '
          'schoten en ${detail.images.length} foto’s worden verwijderd.',
        ),
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
    await ref.read(repositoryProvider).deleteSeries(seriesId);
    if (context.mounted) Navigator.pop(context, true);
  }
}

class _SeriesDetailBody extends ConsumerWidget {
  const _SeriesDetailBody({required this.detail});

  final SeriesDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = detail.series;
    final target = detail.target;
    final scoreValues = {
      for (final impact in detail.impacts) impact.id: impact.rawScoreValue,
    };
    final analysis = GroupAnalyzer.analyze(
      seriesId: series.id,
      impacts: detail.impacts.map(impactRecordToDomain).toList(growable: false),
      targetProfile: target,
      distanceMeters: series.distanceMeters,
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        128 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        AspectRatio(
          aspectRatio: target.physicalCardWidthMm / target.physicalCardHeightMm,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _TargetPreview(detail: detail, scoreValues: scoreValues),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ResponsiveMetricGrid(
          items: [
            MetricItem(
              label: 'Score',
              value: '${series.totalScore}/${series.maximumPossibleScore}',
            ),
            MetricItem(
              label: 'Percentage',
              value: series.maximumPossibleScore == 0
                  ? '0%'
                  : '${(series.totalScore / series.maximumPossibleScore * 100).toStringAsFixed(1)}%',
            ),
            MetricItem(label: 'Schoten', value: '${series.shotCount}'),
            MetricItem(label: 'X', value: '${series.innerTenCount}'),
          ],
        ),
        const SizedBox(height: 20),
        GroupAnalysisSummaryCard(
          analysis: analysis,
          onOpenAnalysis: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SeriesAnalysisScreen(seriesId: series.id),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SeriesTimerActivities(seriesId: series.id),
        const SizedBox(height: 20),
        Text('Instellingen', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.track_changes),
          title: Text(target.displayName),
          subtitle: Text(
            '${series.distanceMeters.toStringAsFixed(0)} m · '
            '${detail.cartridge?.name ?? 'projectiel ${series.projectileDiameterMm.toStringAsFixed(2)} mm'}',
          ),
        ),
        if (detail.firearm != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.sports_martial_arts_outlined),
            title: const Text('Wapen'),
            subtitle: Text(detail.firearm!.name),
          ),
        if (detail.ammoLot != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Munitieprofiel'),
            subtitle: Text(detail.ammoLot!.displayName),
          ),
        if (series.notes != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notes_outlined),
            title: const Text('Notitie'),
            subtitle: Text(series.notes!),
          ),
        const SizedBox(height: 12),
        Text('Punten', style: Theme.of(context).textTheme.titleMedium),
        ...detail.impacts.indexed.map(
          (entry) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text('${entry.$1 + 1}')),
            title: Text(
              entry.$2.isMiss
                  ? 'Misser · 0 punten'
                  : '${entry.$2.rawScoreValue} punten'
                        '${entry.$2.isInnerTen ? ' · X' : ''}',
            ),
            subtitle: Text(
              entry.$2.scoreDisposition ==
                      domain.ScoreDisposition.duplicateNotCounted.name
                  ? 'Telt niet · meerdere schoten op hetzelfde roosje'
                  : entry.$2.multiplicity > 1
                  ? 'Telt als ${entry.$2.multiplicity} schoten · positie onzeker'
                  : entry.$2.isBoundaryUncertain
                  ? 'Dicht bij een scoringslijn'
                  : '${entry.$2.xMm.toStringAsFixed(1)}, '
                        '${entry.$2.yMm.toStringAsFixed(1)} mm',
            ),
          ),
        ),
        if (detail.images.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Foto’s', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 98 + MediaQuery.textScalerOf(context).scale(38),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final image = detail.images[index];
                final primary = image.id == detail.primaryImage?.id;
                return PhotoThumbnailTile(
                  image: image,
                  badgeLabel: primary ? 'Scorefoto' : 'Reeksfoto',
                  onTap: () => _openPhoto(context, image),
                  onLongPress: () => unawaited(
                    _showPhotoActions(context, ref, image, primary),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _openPhoto(BuildContext context, ImageAssetRecord image) {
    final isPrimary = image.id == detail.primaryImage?.id;
    PhotoViewerOverlayData? overlayData;
    if (image.id == detail.primaryImage?.id && detail.photoAlignment != null) {
      final alignment = _decodeAlignment(detail);
      if (alignment != null) {
        overlayData = PhotoViewerOverlayData(
          alignment: alignment,
          projectileDiameterMm: detail.series.projectileDiameterMm,
          impacts: [
            for (var index = 0; index < detail.impacts.length; index++)
              if (!detail.impacts[index].isMiss)
                PhotoCanvasImpact(
                  id: detail.impacts[index].id,
                  positionMm: geo.PhysicalPointMm(
                    detail.impacts[index].xMm,
                    detail.impacts[index].yMm,
                  ),
                  sequenceNumber: index + 1,
                  scoreLabel: '${detail.impacts[index].scoreValue}',
                  multiplicity: detail.impacts[index].multiplicity,
                  isPositionUncertain:
                      detail.impacts[index].isPositionUncertain,
                ),
          ],
        );
      }
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(
          imageId: image.id,
          sourceLabel: isPrimary ? 'Scorefoto' : 'Reeksfoto',
          overlayData: overlayData,
          onMakePrimary: isPrimary
              ? null
              : () => _openAlignment(context, image),
          onAdjustAlignment: isPrimary && detail.photoAlignment != null
              ? () => _openAlignment(context, image)
              : null,
        ),
      ),
    );
  }

  Future<void> _showPhotoActions(
    BuildContext context,
    WidgetRef ref,
    ImageAssetRecord image,
    bool primary,
  ) async {
    final action = await showPhotoActionsSheet(
      context: context,
      image: image,
      canMakePrimary: !primary,
      canAdjustAlignment: primary && detail.photoAlignment != null,
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case PhotoAction.view:
        _openPhoto(context, image);
        return;
      case PhotoAction.resetView:
        return;
      case PhotoAction.editCaption:
        await editPhotoCaption(context: context, ref: ref, image: image);
        return;
      case PhotoAction.makePrimary:
      case PhotoAction.adjustAlignment:
        await _openAlignment(context, image);
        return;
      case PhotoAction.delete:
        await deletePhotoWithConfirmation(
          context: context,
          ref: ref,
          image: image,
          sourceLabel: primary ? 'Scorefoto' : 'Reeksfoto',
        );
        return;
    }
  }

  Future<void> _openAlignment(BuildContext context, ImageAssetRecord image) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ManualSeriesScreen(
            sessionId: detail.series.sessionId,
            seriesId: detail.series.id,
            alignImageIdOnLoad: image.id,
          ),
        ),
      );
}

class _SeriesTimerActivities extends ConsumerWidget {
  const _SeriesTimerActivities({required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(seriesTrainingActivitiesProvider(seriesId));
    return activities.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Text(
                  'Timerresultaten',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final activity in items)
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(_timerActivityLabel(activity.kind)),
                  subtitle: Text(_timerActivitySummary(activity.summaryJson)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) =>
                          TimerActivityDetailScreen(activityId: activity.id),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

String _timerActivityLabel(String kind) => switch (kind) {
  'acousticLiveFire' => 'Akoestische shot timer',
  'par' => 'Par timer',
  'cadence' => 'Cadanstrainer',
  'externalManual' => 'Extern gemeten',
  _ => 'Trainingstimer',
};

String _timerActivitySummary(String summaryJson) {
  try {
    final summary = (jsonDecode(summaryJson) as Map).cast<String, Object?>();
    final isExternalSummaryOnly =
        summary['externalTimingCompleteness'] == 'summaryOnly';
    final shots = (summary['countedShotCount'] as num?)?.toInt();
    final total = (summary['totalTimeMicros'] as num?)?.toInt();
    final parts = <String>[
      if (shots != null) '$shots schoten',
      if (isExternalSummaryOnly) 'Splits niet ingevoerd',
      if (total != null)
        '${(total / 1000000).toStringAsFixed(2).replaceAll('.', ',')} s',
    ];
    return parts.isEmpty ? 'Timerresultaat' : parts.join(' · ');
  } catch (_) {
    return 'Timerresultaat';
  }
}

class _TargetPreview extends StatelessWidget {
  const _TargetPreview({required this.detail, required this.scoreValues});

  final SeriesDetail detail;
  final Map<String, int> scoreValues;

  @override
  Widget build(BuildContext context) {
    final image = detail.primaryImage;
    final alignment = _decodeAlignment(detail);
    if (image != null && alignment != null && File(image.path).existsSync()) {
      return PhotoOverlayCanvas(
        imageProvider: FileImage(File(image.path)),
        imagePixelSize: Size(image.width.toDouble(), image.height.toDouble()),
        alignment: alignment,
        projectileDiameterMm: detail.series.projectileDiameterMm,
        accessMode: CanvasAccessMode.readOnly,
        impacts: [
          for (var index = 0; index < detail.impacts.length; index++)
            if (!detail.impacts[index].isMiss)
              PhotoCanvasImpact(
                id: detail.impacts[index].id,
                positionMm: geo.PhysicalPointMm(
                  detail.impacts[index].xMm,
                  detail.impacts[index].yMm,
                ),
                sequenceNumber: index + 1,
                scoreLabel: '${detail.impacts[index].scoreValue}',
                multiplicity: detail.impacts[index].multiplicity,
                isPositionUncertain: detail.impacts[index].isPositionUncertain,
              ),
        ],
      );
    }
    return TargetCanvas(
      target: detail.target,
      impacts: detail.impacts
          .map(
            (impact) => domain.ShotImpact(
              id: impact.id,
              xMm: impact.xMm,
              yMm: impact.yMm,
              multiplicity: impact.multiplicity,
              isMiss: impact.isMiss,
              isPositionUncertain: impact.isPositionUncertain,
              targetBullId: impact.targetBullId,
              rawScoreValue: impact.rawScoreValue,
              scoreDisposition: domain.ScoreDisposition.values.byName(
                impact.scoreDisposition,
              ),
            ),
          )
          .toList(),
      projectileDiameterMm: detail.series.projectileDiameterMm,
      scoreValues: scoreValues,
    );
  }
}

geo.ManualPhotoAlignment? _decodeAlignment(SeriesDetail detail) {
  final record = detail.photoAlignment;
  if (record == null) return null;
  try {
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
      'cardWidthMm': detail.target.physicalCardWidthMm,
      'cardHeightMm': detail.target.physicalCardHeightMm,
      'corners': geo.NormalizedQuad.fromOrderedPoints(corners).toJson(),
      'homographyMatrix': (jsonDecode(record.matrixJson) as List)
          .cast<num>()
          .map((value) => value.toDouble())
          .toList(),
    });
  } catch (_) {
    return null;
  }
}
