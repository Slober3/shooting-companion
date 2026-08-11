import 'package:shooting_companion_analysis/analysis.dart';

import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import 'analysis_adapter.dart';

/// The complete, immutable analysis state for one confirmed series.
class SeriesAnalysisContext {
  const SeriesAnalysisContext({required this.view});

  final AnalyzedSeriesView view;

  SessionRecord get session => view.source.session;
  SeriesRecord get series => view.source.series;
  ComparableCohortKey get strictCohortKey => _strictKey(view);
}

/// One exact target/distance/firearm/ammunition cohort inside a session.
class SessionCohortAnalysisContext {
  SessionCohortAnalysisContext({
    required this.key,
    required Iterable<SeriesAnalysisContext> series,
    required this.analysis,
  }) : series = List.unmodifiable(series);

  final ComparableCohortKey key;
  final List<SeriesAnalysisContext> series;
  final CohortAnalysis analysis;
}

/// Confirmed series in one session, kept separate by strict comparability.
class SessionAnalysisContext {
  SessionAnalysisContext({
    required this.session,
    required Iterable<SeriesAnalysisContext> series,
    required Iterable<SessionCohortAnalysisContext> cohorts,
  }) : series = List.unmodifiable(series),
       cohorts = List.unmodifiable(cohorts);

  final SessionRecord session;
  final List<SeriesAnalysisContext> series;
  final List<SessionCohortAnalysisContext> cohorts;
}

/// The selected series plus every confirmed series in its exact cohort.
class ComparableSeriesAnalysisContext {
  ComparableSeriesAnalysisContext({
    required this.selected,
    required Iterable<SeriesAnalysisContext> series,
    required this.analysis,
  }) : series = List.unmodifiable(series);

  final SeriesAnalysisContext selected;
  final List<SeriesAnalysisContext> series;
  final CohortAnalysis analysis;
}

/// Pure index over a repository dataset, shared by contextual analysis views.
class AnalysisContextCatalog {
  AnalysisContextCatalog._(this._seriesById, this._seriesBySessionId);

  factory AnalysisContextCatalog.fromDataset(
    Iterable<AnalysisSeriesData> source,
  ) {
    final analyzed = analyzeSeriesDataset(source).toList(growable: false)
      ..sort(_compareChronologically);
    final byId = <String, SeriesAnalysisContext>{};
    final bySession = <String, List<SeriesAnalysisContext>>{};
    for (final view in analyzed) {
      if (view.source.series.sessionId != view.source.session.id) {
        throw StateError(
          'Reeks ${view.source.series.id} hoort niet bij sessie '
          '${view.source.session.id}.',
        );
      }
      final context = SeriesAnalysisContext(view: view);
      if (byId[context.series.id] != null) {
        throw StateError(
          'Dubbele reeks in analysedataset: ${context.series.id}.',
        );
      }
      byId[context.series.id] = context;
      bySession.putIfAbsent(context.session.id, () => []).add(context);
    }
    return AnalysisContextCatalog._(
      Map.unmodifiable(byId),
      Map.unmodifiable({
        for (final entry in bySession.entries)
          entry.key: List<SeriesAnalysisContext>.unmodifiable(entry.value),
      }),
    );
  }

  final Map<String, SeriesAnalysisContext> _seriesById;
  final Map<String, List<SeriesAnalysisContext>> _seriesBySessionId;

  SeriesAnalysisContext? series(String seriesId) => _seriesById[seriesId];

  SessionAnalysisContext? session(String sessionId) {
    final series = _seriesBySessionId[sessionId];
    if (series == null || series.isEmpty) return null;
    final grouped = <ComparableCohortKey, List<SeriesAnalysisContext>>{};
    for (final item in series) {
      grouped.putIfAbsent(item.strictCohortKey, () => []).add(item);
    }
    final cohorts = <SessionCohortAnalysisContext>[];
    for (final entry in grouped.entries) {
      final items = entry.value..sort(_compareSeriesContexts);
      cohorts.add(
        SessionCohortAnalysisContext(
          key: entry.key,
          series: items,
          analysis: CohortAnalyzer.analyze(
            items.map((item) => cohortInputFromAnalyzed(item.view)),
            cohort: entry.key,
          ),
        ),
      );
    }
    cohorts.sort((first, second) {
      final firstSeries = first.series.first;
      final secondSeries = second.series.first;
      return _compareSeriesContexts(firstSeries, secondSeries);
    });
    return SessionAnalysisContext(
      session: series.first.session,
      series: series,
      cohorts: cohorts,
    );
  }

  ComparableSeriesAnalysisContext? comparableForSeries(String seriesId) {
    final selected = _seriesById[seriesId];
    if (selected == null) return null;
    final comparable =
        _seriesById.values
            .where((item) => item.strictCohortKey == selected.strictCohortKey)
            .toList(growable: false)
          ..sort(_compareSeriesContexts);
    return ComparableSeriesAnalysisContext(
      selected: selected,
      series: comparable,
      analysis: CohortAnalyzer.analyze(
        comparable.map((item) => cohortInputFromAnalyzed(item.view)),
        cohort: selected.strictCohortKey,
      ),
    );
  }
}

ComparableCohortKey _strictKey(AnalyzedSeriesView item) => ComparableCohortKey(
  targetProfileVersionedId: item.source.series.targetProfileVersionedId,
  distanceMeters: item.source.series.distanceMeters,
  projectileDiameterMm: item.source.series.projectileDiameterMm,
  cartridgeId: item.source.series.cartridgeId,
  firearmId: item.source.series.firearmId,
  ammoLotId: item.source.series.ammoLotId,
);

int _compareChronologically(
  AnalyzedSeriesView first,
  AnalyzedSeriesView second,
) {
  final bySession = first.source.session.startedAtUtc.compareTo(
    second.source.session.startedAtUtc,
  );
  if (bySession != 0) return bySession;
  final bySequence = first.source.series.sequenceNumber.compareTo(
    second.source.series.sequenceNumber,
  );
  return bySequence != 0
      ? bySequence
      : first.source.series.id.compareTo(second.source.series.id);
}

int _compareSeriesContexts(
  SeriesAnalysisContext first,
  SeriesAnalysisContext second,
) => _compareChronologically(first.view, second.view);
