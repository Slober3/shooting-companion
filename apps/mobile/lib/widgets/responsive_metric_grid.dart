import 'package:flutter/material.dart';

class MetricItem {
  const MetricItem({
    required this.label,
    required this.value,
    this.icon,
    this.onTap,
    this.helpSemanticLabel,
  });

  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Full accessible action label when the visible metric opens an explanation.
  final String? helpSemanticLabel;
}

/// A non-scrolling metric grid that keeps each label and value together.
///
/// Phone layouts use two columns. Wide layouts use four, while a large text
/// scale automatically returns to two to prevent cramped values.
class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({required this.items, super.key});

  final List<MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final columns = textScale >= 1.8
            ? 1
            : constraints.maxWidth >= 680 && textScale < 1.5
            ? 4
            : 2;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _MetricTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item});

  final MetricItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.icon case final icon?) ...[
            Icon(icon, size: 20),
            const SizedBox(height: 8),
          ],
          Text(
            item.value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(item.label, style: theme.textTheme.bodySmall),
              ),
              if (item.onTap != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: item.helpSemanticLabel ?? 'Leg ${item.label} uit',
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Semantics(
      button: item.onTap != null,
      label: item.onTap == null
          ? '${item.label}: ${item.value}'
          : '${item.label}: ${item.value}. '
                '${item.helpSemanticLabel ?? 'Open uitleg'}',
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: item.onTap == null
            ? content
            : InkWell(onTap: item.onTap, child: content),
      ),
    );
  }
}
