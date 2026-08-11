import 'package:flutter/material.dart';

import '../../widgets/safe_sheet_scaffold.dart';
import 'analysis_evidence.dart';
import 'metric_definitions.dart';

Future<void> showMetricExplanationSheet({
  required BuildContext context,
  required MetricDefinition definition,
  String? currentValue,
  AnalysisEvidence? evidence,
  VoidCallback? onShowOnChart,
}) => showSafeModalSheet<void>(
  context: context,
  presentation: SafeSheetPresentation.adaptive,
  builder: (sheetContext) => MetricExplanationSheet(
    definition: definition,
    currentValue: currentValue,
    evidence: evidence,
    onShowOnChart: onShowOnChart == null
        ? null
        : () {
            Navigator.of(sheetContext).pop();
            onShowOnChart();
          },
  ),
);

/// Complete, readable explanation for one analysis metric.
///
/// This is intentionally a sheet instead of a tooltip: definitions, data scope
/// and limitations are task-relevant and must remain readable with large text.
class MetricExplanationSheet extends StatelessWidget {
  const MetricExplanationSheet({
    required this.definition,
    this.currentValue,
    this.evidence,
    this.onShowOnChart,
    super.key,
  });

  final MetricDefinition definition;
  final String? currentValue;
  final AnalysisEvidence? evidence;
  final VoidCallback? onShowOnChart;

  @override
  Widget build(BuildContext context) => SafeSheetScaffold(
    title: definition.label,
    actions: [
      if (onShowOnChart != null)
        FilledButton.icon(
          onPressed: onShowOnChart,
          icon: const Icon(Icons.center_focus_strong),
          label: const Text('Toon op kaart'),
        ),
    ],
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (currentValue case final value?) ...[
          _CurrentMeasurement(label: definition.label, value: value),
          const SizedBox(height: 16),
        ],
        if (evidence case final basis?) ...[
          EvidenceBasisPanel(evidence: basis),
          const SizedBox(height: 20),
        ],
        _ExplanationSection(
          title: 'Wat meet dit?',
          child: Text(definition.shortDescription),
        ),
        _ExplanationSection(
          title: 'Hoe wordt dit berekend?',
          child: Text(definition.calculation),
        ),
        _ExplanationSection(
          title: 'Hoe lees ik dit?',
          child: Text(definition.interpretation),
        ),
        _ExplanationSection(
          title: 'Benodigde gegevens',
          child: Text(definition.dataRequirement),
        ),
        _ExplanationSection(
          title: 'Beperkingen',
          isLast: true,
          child: Column(
            children: [
              for (final limitation in definition.limitations)
                _BulletPoint(text: limitation),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CurrentMeasurement extends StatelessWidget {
  const _CurrentMeasurement({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Huidige meting voor $label: $value',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deze meting',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplanationSection extends StatelessWidget {
  const _ExplanationSection({
    required this.title,
    required this.child,
    this.isLast = false,
  });

  final String title;
  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(child: Text('•')),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
