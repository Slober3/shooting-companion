import 'package:flutter/material.dart';

/// One structured, non-visual representation of a chart value.
class AccessibleChartDataRow {
  const AccessibleChartDataRow({
    required this.label,
    required this.value,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;

  String get semanticLabel => [
    '$label: $value',
    if (detail case final text? when text.trim().isNotEmpty) text,
  ].join('. ');
}

/// Accessible chrome for a custom-painted or otherwise visual chart.
///
/// The visible [summary] conveys the primary relationship without requiring
/// colour or visual inspection. [dataRows] expose the underlying values in a
/// responsive structure that remains usable at large text scales.
class AccessibleChartFrame extends StatefulWidget {
  const AccessibleChartFrame({
    required this.title,
    required this.summary,
    required this.chart,
    required this.dataRows,
    this.legend,
    this.chartSemanticLabel,
    this.initiallyShowData = false,
    super.key,
  });

  final String title;
  final String summary;
  final Widget chart;
  final List<AccessibleChartDataRow> dataRows;
  final Widget? legend;
  final String? chartSemanticLabel;
  final bool initiallyShowData;

  @override
  State<AccessibleChartFrame> createState() => _AccessibleChartFrameState();
}

class _AccessibleChartFrameState extends State<AccessibleChartFrame> {
  late bool _showData;

  @override
  void initState() {
    super.initState();
    _showData = widget.initiallyShowData;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(widget.summary, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Semantics(
              container: true,
              image: true,
              label:
                  widget.chartSemanticLabel ??
                  '${widget.title}. ${widget.summary}',
              child: ExcludeSemantics(child: widget.chart),
            ),
            if (widget.legend case final legend?) ...[
              const SizedBox(height: 12),
              legend,
            ],
            if (widget.dataRows.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              Semantics(
                button: true,
                label:
                    'Gegevens en uitleg, '
                    '${_showData ? 'uitgevouwen' : 'ingevouwen'}',
                excludeSemantics: true,
                child: TextButton.icon(
                  key: const ValueKey('accessible-chart-data-toggle'),
                  onPressed: () => setState(() => _showData = !_showData),
                  icon: AnimatedRotation(
                    turns: _showData ? .5 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(Icons.expand_more),
                  ),
                  label: const Text('Gegevens en uitleg'),
                ),
              ),
              if (_showData)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < widget.dataRows.length;
                        index++
                      )
                        _AccessibleDataRow(
                          row: widget.dataRows[index],
                          showDivider: index != widget.dataRows.length - 1,
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccessibleDataRow extends StatelessWidget {
  const _AccessibleDataRow({required this.row, required this.showDivider});

  final AccessibleChartDataRow row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: row.semanticLabel,
      excludeSemantics: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  row.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(row.value),
                if (row.detail case final detail?) ...[
                  const SizedBox(height: 4),
                  Text(detail, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1),
        ],
      ),
    );
  }
}
