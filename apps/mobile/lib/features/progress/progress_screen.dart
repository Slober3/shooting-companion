import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../widgets/compact_page_scaffold.dart';
import '../../widgets/responsive_metric_grid.dart';
import '../../widgets/safe_sheet_scaffold.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  _AnalysisFilters _filters = const _AnalysisFilters();

  @override
  Widget build(BuildContext context) {
    // A session update invalidates the FutureBuilder below without introducing
    // an app-wide analytics cache.
    ref.watch(sessionsProvider);
    final targets = ref.watch(targetProfilesProvider).valueOrNull ?? const [];
    final firearms = ref.watch(firearmsProvider).valueOrNull ?? const [];
    final ammoLots = ref.watch(ammoLotsProvider).valueOrNull ?? const [];

    return CompactPageScaffold(
      title: 'Analyse',
      actions: [
        Semantics(
          button: true,
          label: _filters.activeCount == 0
              ? 'Analysefilters'
              : 'Analysefilters, ${_filters.activeCount} actief',
          child: IconButton(
            tooltip: 'Filters',
            onPressed: () => _showFilters(
              targets: targets,
              firearms: firearms,
              ammoLots: ammoLots,
            ),
            icon: Badge(
              isLabelVisible: _filters.activeCount > 0,
              label: Text('${_filters.activeCount}'),
              child: const Icon(Icons.tune),
            ),
          ),
        ),
      ],
      body: FutureBuilder<List<SeriesRecord>>(
        future: ref.read(repositoryProvider).getConfirmedSeries(),
        builder: (context, snapshot) {
          final targetNames = {
            for (final target in targets)
              target.versionedId: target.displayName,
          };
          final allItems = snapshot.data ?? const <SeriesRecord>[];
          final items = _filters.apply(allItems);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sessionsProvider);
              await ref.read(sessionsProvider.future);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(),
                if (_filters.activeCount > 0) ...[
                  _ActiveFilterSummary(
                    filters: _filters,
                    targetNames: targetNames,
                    firearmNames: {
                      for (final firearm in firearms) firearm.id: firearm.name,
                    },
                    ammoNames: {
                      for (final ammo in ammoLots) ammo.id: ammo.displayName,
                    },
                    onClear: () =>
                        setState(() => _filters = const _AnalysisFilters()),
                  ),
                  const SizedBox(height: 12),
                ],
                if (snapshot.hasError)
                  _MessagePanel(
                    icon: Icons.error_outline,
                    message: 'Analyse laden mislukt: ${snapshot.error}',
                  )
                else if (allItems.isEmpty)
                  const _MessagePanel(
                    icon: Icons.insights_outlined,
                    message: 'Sla minstens één reeks op om je analyse te zien.',
                  )
                else if (items.isEmpty)
                  const _MessagePanel(
                    icon: Icons.filter_alt_off,
                    message: 'Geen reeksen passen bij deze filters.',
                  )
                else ...[
                  _Overview(items: items),
                  const SizedBox(height: 16),
                  _TrendCard(items: items),
                  const SizedBox(height: 16),
                  _Breakdown(items: items, targetNames: targetNames),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFilters({
    required List<TargetProfileRecord> targets,
    required List<FirearmRecord> firearms,
    required List<AmmoLotRecord> ammoLots,
  }) async {
    final allSeries = await ref.read(repositoryProvider).getConfirmedSeries();
    if (!mounted) return;
    final result = await showSafeModalSheet<_AnalysisFilters>(
      context: context,
      builder: (context) => _FilterSheet(
        initial: _filters,
        targets: targets,
        firearms: firearms,
        ammoLots: ammoLots,
        distances: allSeries.map((item) => item.distanceMeters).toSet().toList()
          ..sort(),
      ),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.items});

  final List<SeriesRecord> items;

  @override
  Widget build(BuildContext context) {
    final shots = items.fold(0, (sum, item) => sum + item.shotCount);
    final percentages = items.map(_percentage).toList();
    final average = percentages.reduce((a, b) => a + b) / items.length;
    final best = percentages.reduce(math.max);

    return ResponsiveMetricGrid(
      items: [
        MetricItem(
          label: 'Reeksen',
          value: '${items.length}',
          icon: Icons.layers_outlined,
        ),
        MetricItem(label: 'Schoten', value: '$shots', icon: Icons.adjust),
        MetricItem(
          label: 'Gemiddelde score',
          value: '${average.toStringAsFixed(1)}%',
          icon: Icons.show_chart,
        ),
        MetricItem(
          label: 'Beste score',
          value: '${best.toStringAsFixed(1)}%',
          icon: Icons.emoji_events_outlined,
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.items});

  final List<SeriesRecord> items;

  @override
  Widget build(BuildContext context) {
    final values = items.map(_percentage).toList();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scoretrend', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Percentage van de maximumscore per reeks'),
            const SizedBox(height: 16),
            Semantics(
              label:
                  'Scoretrend van ${values.first.toStringAsFixed(1)} tot ${values.last.toStringAsFixed(1)} procent',
              image: true,
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: _TrendPainter(values, Theme.of(context).colorScheme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.scheme);

  final List<double> values;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = scheme.outlineVariant;
    for (final percentage in [0.25, 0.5, 0.75, 1.0]) {
      final y = size.height * (1 - percentage);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final linePaint = Paint()
      ..color = scheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (values.length == 1) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height * (1 - values.first / 100)),
        5,
        linePaint..style = PaintingStyle.fill,
      );
      return;
    }
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = index / (values.length - 1) * size.width;
      final y = size.height * (1 - values[index].clamp(0, 100) / 100);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.scheme != scheme;
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.items, required this.targetNames});

  final List<SeriesRecord> items;
  final Map<String, String> targetNames;

  @override
  Widget build(BuildContext context) {
    final groups = <_ComparableGroup, List<SeriesRecord>>{};
    for (final item in items) {
      final key = _ComparableGroup(
        targetId: item.targetProfileVersionedId,
        distanceMeters: item.distanceMeters,
      );
      groups.putIfAbsent(key, () => []).add(item);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vergelijkbare reeksen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final entry in groups.entries)
              _BreakdownRow(
                title:
                    targetNames[entry.key.targetId] ??
                    _fallbackTargetName(entry.key.targetId),
                subtitle:
                    '${entry.key.distanceMeters.toStringAsFixed(_distanceDigits(entry.key.distanceMeters))} m · ${entry.value.length} ${entry.value.length == 1 ? 'reeks' : 'reeksen'}',
                percentage:
                    '${_groupPercentage(entry.value).toStringAsFixed(1)}%',
              ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.title,
    required this.subtitle,
    required this.percentage,
  });

  final String title;
  final String subtitle;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    final score = Text(
      percentage,
      style: Theme.of(context).textTheme.titleMedium,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                score,
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                score,
              ],
            ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
    child: Column(
      children: [
        Icon(icon, size: 40),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _ActiveFilterSummary extends StatelessWidget {
  const _ActiveFilterSummary({
    required this.filters,
    required this.targetNames,
    required this.firearmNames,
    required this.ammoNames,
    required this.onClear,
  });

  final _AnalysisFilters filters;
  final Map<String, String> targetNames;
  final Map<String, String> firearmNames;
  final Map<String, String> ammoNames;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (filters.period != _AnalysisPeriod.all)
        Chip(label: Text(filters.period.label)),
      if (filters.targetId case final id?)
        Chip(label: Text(targetNames[id] ?? _fallbackTargetName(id))),
      if (filters.distanceMeters case final distance?)
        Chip(
          label: Text(
            '${distance.toStringAsFixed(_distanceDigits(distance))} m',
          ),
        ),
      if (filters.firearmId case final id?)
        Chip(label: Text(firearmNames[id] ?? 'Onbekend wapen')),
      if (filters.ammoLotId case final id?)
        Chip(label: Text(ammoNames[id] ?? 'Onbekende munitie')),
      TextButton(onPressed: onClear, child: const Text('Wis filters')),
    ],
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.targets,
    required this.firearms,
    required this.ammoLots,
    required this.distances,
  });

  final _AnalysisFilters initial;
  final List<TargetProfileRecord> targets;
  final List<FirearmRecord> firearms;
  final List<AmmoLotRecord> ammoLots;
  final List<double> distances;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _AnalysisFilters filters;

  @override
  void initState() {
    super.initState();
    filters = widget.initial;
  }

  @override
  Widget build(BuildContext context) => SafeSheetScaffold(
    title: 'Analysefilters',
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context, filters),
        child: const Text('Filters toepassen'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, const _AnalysisFilters()),
        child: const Text('Alles wissen'),
      ),
    ],
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<_AnalysisPeriod>(
          initialValue: filters.period,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Periode'),
          items: [
            for (final period in _AnalysisPeriod.values)
              DropdownMenuItem(value: period, child: Text(period.label)),
          ],
          onChanged: (value) =>
              setState(() => filters = filters.copyWith(period: value)),
        ),
        const SizedBox(height: 12),
        _NullableDropdown<String>(
          label: 'Kaart',
          value: filters.targetId,
          items: {
            for (final target in widget.targets)
              target.versionedId: target.displayName,
          },
          onChanged: (value) => setState(
            () => filters = filters.copyWith(
              targetId: value,
              clearTarget: value == null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _NullableDropdown<double>(
          label: 'Afstand',
          value: filters.distanceMeters,
          items: {
            for (final distance in widget.distances)
              distance:
                  '${distance.toStringAsFixed(_distanceDigits(distance))} m',
          },
          onChanged: (value) => setState(
            () => filters = filters.copyWith(
              distanceMeters: value,
              clearDistance: value == null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _NullableDropdown<String>(
          label: 'Wapen',
          value: filters.firearmId,
          items: {
            for (final firearm in widget.firearms) firearm.id: firearm.name,
          },
          onChanged: (value) => setState(
            () => filters = filters.copyWith(
              firearmId: value,
              clearFirearm: value == null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _NullableDropdown<String>(
          label: 'Munitie',
          value: filters.ammoLotId,
          items: {
            for (final ammo in widget.ammoLots) ammo.id: ammo.displayName,
          },
          onChanged: (value) => setState(
            () => filters = filters.copyWith(
              ammoLotId: value,
              clearAmmo: value == null,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NullableDropdown<T> extends StatelessWidget {
  const _NullableDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      DropdownMenuItem<T>(value: null, child: const Text('Alle')),
      for (final entry in items.entries)
        DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
    ],
    onChanged: onChanged,
  );
}

enum _AnalysisPeriod {
  all('Alle datums'),
  last30Days('Laatste 30 dagen'),
  last90Days('Laatste 90 dagen'),
  lastYear('Laatste 12 maanden');

  const _AnalysisPeriod(this.label);
  final String label;
}

class _AnalysisFilters {
  const _AnalysisFilters({
    this.period = _AnalysisPeriod.all,
    this.targetId,
    this.distanceMeters,
    this.firearmId,
    this.ammoLotId,
  });

  final _AnalysisPeriod period;
  final String? targetId;
  final double? distanceMeters;
  final String? firearmId;
  final String? ammoLotId;

  int get activeCount =>
      (period == _AnalysisPeriod.all ? 0 : 1) +
      (targetId == null ? 0 : 1) +
      (distanceMeters == null ? 0 : 1) +
      (firearmId == null ? 0 : 1) +
      (ammoLotId == null ? 0 : 1);

  List<SeriesRecord> apply(List<SeriesRecord> items) {
    final cutoff = switch (period) {
      _AnalysisPeriod.all => null,
      _AnalysisPeriod.last30Days => DateTime.now().toUtc().subtract(
        const Duration(days: 30),
      ),
      _AnalysisPeriod.last90Days => DateTime.now().toUtc().subtract(
        const Duration(days: 90),
      ),
      _AnalysisPeriod.lastYear => DateTime.now().toUtc().subtract(
        const Duration(days: 365),
      ),
    };
    return items.where((item) {
      if (cutoff != null && item.createdAtUtc.isBefore(cutoff)) return false;
      if (targetId != null && item.targetProfileVersionedId != targetId) {
        return false;
      }
      if (distanceMeters != null &&
          (item.distanceMeters - distanceMeters!).abs() > 0.0001) {
        return false;
      }
      if (firearmId != null && item.firearmId != firearmId) return false;
      if (ammoLotId != null && item.ammoLotId != ammoLotId) return false;
      return true;
    }).toList();
  }

  _AnalysisFilters copyWith({
    _AnalysisPeriod? period,
    String? targetId,
    double? distanceMeters,
    String? firearmId,
    String? ammoLotId,
    bool clearTarget = false,
    bool clearDistance = false,
    bool clearFirearm = false,
    bool clearAmmo = false,
  }) => _AnalysisFilters(
    period: period ?? this.period,
    targetId: clearTarget ? null : targetId ?? this.targetId,
    distanceMeters: clearDistance
        ? null
        : distanceMeters ?? this.distanceMeters,
    firearmId: clearFirearm ? null : firearmId ?? this.firearmId,
    ammoLotId: clearAmmo ? null : ammoLotId ?? this.ammoLotId,
  );
}

class _ComparableGroup {
  const _ComparableGroup({
    required this.targetId,
    required this.distanceMeters,
  });

  final String targetId;
  final double distanceMeters;

  @override
  bool operator ==(Object other) =>
      other is _ComparableGroup &&
      other.targetId == targetId &&
      other.distanceMeters == distanceMeters;

  @override
  int get hashCode => Object.hash(targetId, distanceMeters);
}

double _percentage(SeriesRecord item) => item.maximumPossibleScore <= 0
    ? 0
    : item.totalScore / item.maximumPossibleScore * 100;

double _groupPercentage(List<SeriesRecord> items) {
  final total = items.fold(0, (sum, item) => sum + item.totalScore);
  final maximum = items.fold(0, (sum, item) => sum + item.maximumPossibleScore);
  return maximum <= 0 ? 0 : total / maximum * 100;
}

int _distanceDigits(double distance) =>
    distance == distance.roundToDouble() ? 0 : 1;

String _fallbackTargetName(String versionedId) {
  final profileId = versionedId.split('@').first;
  return profileId
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
