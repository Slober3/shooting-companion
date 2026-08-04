import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;
import 'package:shooting_companion_photo_geometry/photo_geometry.dart' as geo;

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/safe_bottom_action_bar.dart';
import '../photo/photo.dart';
import '../scoring/target_canvas.dart';
import '../scoring/transformable_scoring_viewport.dart';
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
          : SafeBottomActionBar(
              actions: [
                FilledButton.icon(
                  onPressed: () =>
                      _edit(context, detail.valueOrNull!.series.sessionId),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Bewerken'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _edit(
                    context,
                    detail.valueOrNull!.series.sessionId,
                    addPhoto: true,
                  ),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Foto toevoegen'),
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

class _SeriesDetailBody extends StatelessWidget {
  const _SeriesDetailBody({required this.detail});

  final SeriesDetail detail;

  @override
  Widget build(BuildContext context) {
    final series = detail.series;
    final target = detail.target;
    final scoreValues = {
      for (final impact in detail.impacts) impact.id: impact.scoreValue,
    };
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        128 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        AspectRatio(
          aspectRatio: 1,
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
        Text('Instellingen', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.track_changes),
          title: Text(target.displayName),
          subtitle: Text(
            '${series.distanceMeters.toStringAsFixed(0)} m · '
            'projectiel ${series.projectileDiameterMm.toStringAsFixed(2)} mm',
          ),
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
                  : '${entry.$2.scoreValue} punten'
                        '${entry.$2.isInnerTen ? ' · X' : ''}',
            ),
            subtitle: Text(
              entry.$2.multiplicity > 1
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
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final image = detail.images[index];
                return _PhotoThumb(
                  image: image,
                  primary: image.id == detail.primaryImage?.id,
                  onTap: () => _openPhoto(context, image),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _openPhoto(BuildContext context, ImageAssetRecord image) {
    if (image.id == detail.primaryImage?.id && detail.photoAlignment != null) {
      final alignment = _decodeAlignment(detail);
      if (alignment != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PhotoOverlayViewer(
              imageProvider: FileImage(File(image.path)),
              imagePixelSize: Size(
                image.width.toDouble(),
                image.height.toDouble(),
              ),
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
            ),
          ),
        );
        return;
      }
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _PlainPhotoViewer(image: image)));
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

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.image,
    required this.primary,
    required this.onTap,
  });

  final ImageAssetRecord image;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: primary ? 'Primaire scorefoto' : 'Foto',
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(image.path),
              width: 92,
              height: 92,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.square(
                dimension: 92,
                child: ColoredBox(
                  color: Colors.black12,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
          if (primary)
            const Positioned(
              left: 4,
              top: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Scorefoto',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _PlainPhotoViewer extends StatelessWidget {
  const _PlainPhotoViewer({required this.image});

  final ImageAssetRecord image;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(image.caption ?? 'Foto')),
    body: SafeArea(
      top: false,
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 6,
        child: Center(child: Image.file(File(image.path))),
      ),
    ),
  );
}
