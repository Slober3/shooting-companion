import 'package:flutter/material.dart';
import 'package:shooting_companion_analysis/analysis.dart';

/// User-facing strength of the available descriptive data.
///
/// These labels express the size and suitability of the data basis. They are
/// deliberately not probabilities and do not imply a causal conclusion.
enum AnalysisDataQuality {
  insufficient,
  provisional,
  smallSample,
  usable,
  stronger,
}

extension AnalysisDataQualityText on AnalysisDataQuality {
  String get label => switch (this) {
    AnalysisDataQuality.insufficient => 'Onvoldoende gegevens',
    AnalysisDataQuality.provisional => 'Voorlopig',
    AnalysisDataQuality.smallSample => 'Kleine steekproef',
    AnalysisDataQuality.usable => 'Bruikbaar patroon',
    AnalysisDataQuality.stronger => 'Sterker patroon',
  };

  String get explanation => switch (this) {
    AnalysisDataQuality.insufficient =>
      'Er zijn te weinig geschikte positiegegevens voor deze conclusie.',
    AnalysisDataQuality.provisional =>
      'De meting is beschrijvend, maar kan door extra treffers sterk veranderen.',
    AnalysisDataQuality.smallSample =>
      'De meting is bruikbaar als eerste aanwijzing, met een kleine steekproef.',
    AnalysisDataQuality.usable =>
      'Er zijn voldoende treffers voor een volledige beschrijvende reeksanalyse.',
    AnalysisDataQuality.stronger =>
      'Het patroon komt terug in meerdere vergelijkbare reeksen met voldoende treffers.',
  };
}

/// Visible scope and limitations behind a metric or coach observation.
class AnalysisEvidence {
  AnalysisEvidence({
    required this.quality,
    required this.actualShotCount,
    required this.positionedShotCount,
    this.seriesCount,
    Iterable<String> limitations = const [],
  }) : assert(actualShotCount >= 0),
       assert(positionedShotCount >= 0),
       assert(positionedShotCount <= actualShotCount),
       assert(seriesCount == null || seriesCount > 0),
       limitations = List.unmodifiable(limitations);

  factory AnalysisEvidence.fromReliability({
    required AnalysisReliability reliability,
    required int actualShotCount,
    required int positionedShotCount,
    int? seriesCount,
    Iterable<String> limitations = const [],
  }) => AnalysisEvidence(
    quality: switch (reliability) {
      AnalysisReliability.noPositionData ||
      AnalysisReliability.positionsOnly => AnalysisDataQuality.insufficient,
      AnalysisReliability.provisional => AnalysisDataQuality.provisional,
      AnalysisReliability.smallSample => AnalysisDataQuality.smallSample,
      AnalysisReliability.full => AnalysisDataQuality.usable,
    },
    actualShotCount: actualShotCount,
    positionedShotCount: positionedShotCount,
    seriesCount: seriesCount,
    limitations: limitations,
  );

  final AnalysisDataQuality quality;
  final int actualShotCount;
  final int positionedShotCount;
  final int? seriesCount;
  final List<String> limitations;

  int get shotsWithoutPosition => actualShotCount - positionedShotCount;

  String get countSummary {
    final parts = <String>[];
    if (seriesCount case final count?) {
      parts.add('$count ${count == 1 ? 'reeks' : 'reeksen'}');
    }
    if (actualShotCount == 0) {
      parts.add('geen geregistreerde schoten');
    } else {
      parts.add(
        '$positionedShotCount/$actualShotCount '
        '${actualShotCount == 1 ? 'schot' : 'schoten'} met positie',
      );
    }
    return parts.join(' · ');
  }

  String get semanticsSummary {
    final text = StringBuffer('${quality.label}. $countSummary.');
    if (shotsWithoutPosition > 0) {
      text.write(
        ' $shotsWithoutPosition '
        '${shotsWithoutPosition == 1 ? 'schot is' : 'schoten zijn'} '
        'niet in fysieke groepsmaten opgenomen.',
      );
    }
    if (limitations.isNotEmpty) text.write(' ${limitations.join(' ')}');
    return text.toString();
  }
}

/// Compact, non-colour-only representation of [AnalysisDataQuality].
class DataQualityBadge extends StatelessWidget {
  const DataQualityBadge({required this.quality, super.key});

  final AnalysisDataQuality quality;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (quality) {
      AnalysisDataQuality.insufficient => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.block_outlined,
      ),
      AnalysisDataQuality.provisional => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        Icons.hourglass_bottom_outlined,
      ),
      AnalysisDataQuality.smallSample => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.info_outline,
      ),
      AnalysisDataQuality.usable => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.analytics_outlined,
      ),
      AnalysisDataQuality.stronger => (
        colors.primary,
        colors.onPrimary,
        Icons.check_circle_outline,
      ),
    };

    return Semantics(
      label: 'Databasis: ${quality.label}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: foreground.withValues(alpha: .45)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  quality.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Always-visible explanation of the observations included in an analysis.
class EvidenceBasisPanel extends StatelessWidget {
  const EvidenceBasisPanel({
    required this.evidence,
    this.title = 'Databasis',
    super.key,
  });

  final AnalysisEvidence evidence;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$title. ${evidence.semanticsSummary}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              DataQualityBadge(quality: evidence.quality),
              const SizedBox(height: 8),
              Text(evidence.countSummary),
              if (evidence.shotsWithoutPosition > 0) ...[
                const SizedBox(height: 6),
                Text(
                  '${evidence.shotsWithoutPosition} '
                  '${evidence.shotsWithoutPosition == 1 ? 'schot telt' : 'schoten tellen'} '
                  'wel mee voor de score, maar niet voor fysieke groepsmaten.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              for (final limitation in evidence.limitations) ...[
                const SizedBox(height: 6),
                _EvidenceNote(text: limitation),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidenceNote extends StatelessWidget {
  const _EvidenceNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(Icons.info_outline, size: 16),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}
