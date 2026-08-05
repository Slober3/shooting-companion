import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/app_action_dock.dart';
import '../../widgets/app_notice.dart';
import 'analysis_adapter.dart';

Future<String?> showAnalysisSeriesPicker(
  BuildContext context,
  List<AnalyzedSeriesView> items,
) => Navigator.of(context).push<String>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _AnalysisSeriesPickerScreen(items: items),
  ),
);

Future<Set<String>?> showAnalysisComparisonPicker(
  BuildContext context, {
  required List<AnalyzedSeriesView> items,
  required Set<String> selectedIds,
  required String requiredSeriesId,
}) => Navigator.of(context).push<Set<String>>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _AnalysisSeriesPickerScreen(
      items: items,
      initialSelection: selectedIds,
      requiredSeriesId: requiredSeriesId,
    ),
  ),
);

class _AnalysisSeriesPickerScreen extends StatefulWidget {
  const _AnalysisSeriesPickerScreen({
    required this.items,
    this.initialSelection,
    this.requiredSeriesId,
  });

  final List<AnalyzedSeriesView> items;
  final Set<String>? initialSelection;
  final String? requiredSeriesId;

  bool get isMultiSelect => initialSelection != null;

  @override
  State<_AnalysisSeriesPickerScreen> createState() =>
      _AnalysisSeriesPickerScreenState();
}

class _AnalysisSeriesPickerScreenState
    extends State<_AnalysisSeriesPickerScreen> {
  late final TextEditingController _searchController;
  late Set<String> _selection;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selection = {...?widget.initialSelection};
    if (widget.requiredSeriesId case final requiredSeriesId?) {
      _selection.add(requiredSeriesId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final visible = widget.items
        .where((item) {
          if (normalized.isEmpty) return true;
          final source = item.source;
          final haystack = [
            item.target.displayName,
            source.cartridge?.name ?? '',
            source.firearm?.name ?? '',
            source.ammoLot?.displayName ?? '',
            'reeks ${source.series.sequenceNumber}',
            source.series.distanceMeters.toString(),
            DateFormat(
              'd MMMM yyyy',
              'nl_BE',
            ).format(source.session.startedAtUtc.toLocal()),
          ].join(' ').toLowerCase();
          return haystack.contains(normalized);
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isMultiSelect ? 'Reeksen vergelijken' : 'Kies een reeks',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Zoeken',
                hintText: 'Datum, kaart, wapen of munitie',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          if (widget.isMultiSelect)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_selection.length}/5 geselecteerd. De bronreeks blijft altijd geselecteerd.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('Geen passende reeksen gevonden.'))
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      4,
                      8,
                      24 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      final series = item.source.series;
                      final date = DateFormat(
                        'd MMM yyyy · HH:mm',
                        'nl_BE',
                      ).format(item.source.session.startedAtUtc.toLocal());
                      final subtitle = [
                        item.target.displayName,
                        '${series.distanceMeters.toStringAsFixed(series.distanceMeters == series.distanceMeters.roundToDouble() ? 0 : 1)} m',
                        if (item.source.cartridge != null)
                          item.source.cartridge!.name,
                        if (item.source.firearm != null)
                          item.source.firearm!.name,
                        if (item.source.ammoLot != null)
                          item.source.ammoLot!.displayName,
                        '${item.analysis.positionedShotCount} positionele treffers',
                        if (item.analysis.positionedShotCount >= 3)
                          '${item.analysis.metrics.meanRadiusMm.toStringAsFixed(1)} mm gemiddelde radius'
                        else if (item.analysis.positionedShotCount == 0)
                          'geen positionele groepsanalyse'
                        else
                          'alleen posities; nog geen groepsmaten',
                      ].join(' · ');
                      if (!widget.isMultiSelect) {
                        return ListTile(
                          title: Text('$date · Reeks ${series.sequenceNumber}'),
                          subtitle: Text(subtitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, series.id),
                        );
                      }
                      final required = series.id == widget.requiredSeriesId;
                      return CheckboxListTile(
                        value: _selection.contains(series.id),
                        title: Text('$date · Reeks ${series.sequenceNumber}'),
                        subtitle: Text(
                          '$subtitle${required ? '\nBronreeks' : ''}',
                        ),
                        secondary: required
                            ? const Icon(Icons.push_pin_outlined)
                            : null,
                        onChanged: required
                            ? null
                            : (value) => _toggle(series.id, value ?? false),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: widget.isMultiSelect
          ? AppActionDock(
              actions: [
                FilledButton.icon(
                  onPressed: _selection.isEmpty
                      ? null
                      : () => Navigator.pop(context, _selection),
                  icon: const Icon(Icons.check),
                  label: const Text('Vergelijking toepassen'),
                ),
              ],
            )
          : null,
    );
  }

  void _toggle(String seriesId, bool selected) {
    final next = {..._selection};
    if (selected) {
      if (next.length >= 5) {
        AppMessenger.info(context, 'Selecteer maximaal vijf reeksen.');
        return;
      }
      next.add(seriesId);
    } else {
      next.remove(seriesId);
    }
    setState(() => _selection = next);
  }
}
