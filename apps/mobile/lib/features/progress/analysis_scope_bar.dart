import 'package:flutter/material.dart';

import 'analysis_evidence.dart';

/// Compact description of the comparable records currently being analysed.
class AnalysisScope {
  AnalysisScope({required Iterable<String> dimensions})
    : dimensions = List.unmodifiable(
        dimensions
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty),
      );

  final List<String> dimensions;

  String get label => dimensions.isEmpty
      ? 'Geen vergelijkingsscope ingesteld'
      : dimensions.join(' · ');
}

/// Always-visible cohort scope and data quality summary.
///
/// If [onPressed] is provided, the complete surface opens the exact filters or
/// cohort details. Critical scope and quality information remain visible before
/// that interaction.
class AnalysisScopeBar extends StatelessWidget {
  const AnalysisScopeBar({
    required this.scope,
    required this.evidence,
    this.onPressed,
    this.title = 'Vergelijkbare gegevens',
    super.key,
  });

  final AnalysisScope scope;
  final AnalysisEvidence evidence;
  final VoidCallback? onPressed;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.filter_alt_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(scope.label, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                DataQualityBadge(quality: evidence.quality),
                const SizedBox(height: 6),
                Text(evidence.countSummary, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (onPressed != null) ...[
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      container: true,
      button: onPressed != null,
      label:
          '$title. ${scope.label}. ${evidence.semanticsSummary}'
          '${onPressed == null ? '' : ' Open details.'}',
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: onPressed == null
            ? content
            : InkWell(onTap: onPressed, child: content),
      ),
    );
  }
}
