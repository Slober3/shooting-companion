import 'dart:math' as math;

import 'fingerprint.dart';
import 'models.dart';
import 'safety_policy.dart';

abstract final class CoachRuleIds {
  static const persistentBias = 'bias.persistent';
  static const centeredButWide = 'group.centered-wide';
  static const compactOffCenter = 'group.compact-off-center';
  static const improving = 'trend.improving';
  static const declining = 'trend.declining';
  static const plateau = 'trend.plateau';
  static const variability = 'consistency.variable';
  static const materialComparison = 'material.comparison';
  static const br50AreaPattern = 'br50.area-pattern';
  static const firstVersusLater = 'session.first-vs-later';
  static const reflectionCorrelation = 'reflection.correlation';
}

class CoachRuleEngine {
  const CoachRuleEngine();

  static const minimumPatternSeries = 3;
  static const minimumPatternHits = 30;
  static const strongEvidenceSeries = 5;
  static const strongEvidenceHits = 60;
  static const ruleVersion = 1;

  List<CoachInsight> evaluate(CoachAnalysisSnapshot snapshot) {
    final series =
        snapshot.series
            .where((sample) => sample.positionedHitCount > 0)
            .toList()
          ..sort(_compareChronologically);
    final hitCount = _hitCount(series);
    if (series.length < minimumPatternSeries || hitCount < minimumPatternHits) {
      return const [];
    }

    final insights = <CoachInsight>[
      ...?_persistentBias(snapshot, series),
      ...?_centeredButWide(snapshot, series),
      ...?_compactOffCenter(snapshot, series),
      ...?_trend(snapshot, series),
      ...?_variability(snapshot, series),
      ..._materialComparisons(snapshot, series),
      ...?_br50AreaPattern(snapshot, series),
      ...?_firstVersusLater(snapshot, series),
      ...?_reflectionCorrelation(snapshot, series),
    ];
    for (final insight in insights) {
      CoachSafetyPolicy.ensureSafe(insight);
    }
    insights.sort((first, second) {
      final byRule = first.ruleId.compareTo(second.ruleId);
      return byRule != 0
          ? byRule
          : first.fingerprint.compareTo(second.fingerprint);
    });
    return List.unmodifiable(insights);
  }

  List<CoachInsight>? _persistentBias(
    CoachAnalysisSnapshot snapshot,
    List<CoachSeriesObservation> series,
  ) {
    final x = _weightedMean(series, (sample) => sample.centroidXMm);
    final y = _weightedMean(series, (sample) => sample.centroidYMm);
    final offset = math.sqrt(x * x + y * y);
    if (offset < snapshot.thresholds.biasToleranceMm) return null;

    final horizontal = x.abs() >= y.abs();
    final signed = horizontal ? x : y;
    final consistent = series.where((sample) {
      final component = horizontal ? sample.centroidXMm : sample.centroidYMm;
      return component.sign == signed.sign &&
          component.abs() >= snapshot.thresholds.biasToleranceMm * 0.5;
    }).length;
    if (consistent / series.length < 0.67) return null;

    final direction = horizontal
        ? (x < 0 ? 'links' : 'rechts')
        : (y < 0 ? 'boven' : 'onder');
    return [
      _insight(
        snapshot: snapshot,
        samples: series,
        ruleId: CoachRuleIds.persistentBias,
        discriminator: direction,
        observation:
            'Het gemiddelde trefpunt lag over ${series.length} vergelijkbare '
            'reeksen ${_number(offset)} mm $direction van het richtpunt.',
        evidenceSummary:
            '$consistent van de ${series.length} reeksen wezen in dezelfde '
            'hoofdrichting; samen bevatten ze ${_hitCount(series)} '
            'positionele treffers.',
        metrics: {
          'centroid_x_mm': x,
          'centroid_y_mm': y,
          'offset_mm': offset,
          'direction_consistency': consistent / series.length,
        },
        explanations: const [
          CoachExplanation(
            title: 'Richtpunt of instelling',
            detail:
                'Het patroon kan samenhangen met de gekozen richtreferentie, '
                'het natuurlijk richtpunt of een instelling van het '
                'richtmiddel.',
          ),
          CoachExplanation(
            title: 'Uitvoering of omstandigheden',
            detail:
                'Houding, licht, steun en terugkerende uitvoering kunnen '
                'eveneens met deze richting samenhangen.',
          ),
        ],
        experiment: const CoachExperiment(
          title: 'Vergelijk twee identieke blokken',
          instructions:
              'Schiet twee vergelijkbare reeksen en wijzig in het tweede blok '
              'slechts één gekozen centrering- of richtreferentie.',
          controlledVariable: 'Centrering of richtreferentie',
        ),
        measurement: const CoachNextMeasurement(
          label: 'Groepscentrum',
          instructions:
              'Vergelijk de horizontale en verticale afwijking; controleer '
              'apart of de mean radius gelijk blijft.',
        ),
      ),
    ];
  }

  List<CoachInsight>? _centeredButWide(
    CoachAnalysisSnapshot snapshot,
    List<CoachSeriesObservation> series,
  ) {
    final x = _weightedMean(series, (sample) => sample.centroidXMm);
    final y = _weightedMean(series, (sample) => sample.centroidYMm);
    final offset = math.sqrt(x * x + y * y);
    final meanRadius = _weightedMean(series, (sample) => sample.meanRadiusMm);
    if (offset > snapshot.thresholds.biasToleranceMm ||
        meanRadius < snapshot.thresholds.wideMeanRadiusMm) {
      return null;
    }
    return [
      _insight(
        snapshot: snapshot,
        samples: series,
        ruleId: CoachRuleIds.centeredButWide,
        observation:
            'Het gezamenlijke trefpunt was goed gecentreerd, terwijl de '
            'gemiddelde mean radius ${_number(meanRadius)} mm bedroeg.',
        evidenceSummary:
            'De centrumafwijking was ${_number(offset)} mm over '
            '${series.length} reeksen en ${_hitCount(series)} positionele '
            'treffers.',
        metrics: {'offset_mm': offset, 'mean_radius_mm': meanRadius},
        explanations: const [
          CoachExplanation(
            title: 'Herhaalbaarheid',
            detail:
                'De brede verdeling kan samenhangen met wisselende '
                'richtbeelden, houding, steun of uitvoering.',
          ),
          CoachExplanation(
            title: 'Materiaal en omgeving',
            detail:
                'Munitie, licht, wind en de stabiliteit van het platform '
                'kunnen eveneens bijdragen aan de gemeten spreiding.',
          ),
        ],
        experiment: const CoachExperiment(
          title: 'Maak uitvoering zo constant mogelijk',
          instructions:
              'Schiet twee korte blokken met dezelfde instellingen en kies '
              'één uitvoeringsaspect dat in het tweede blok bewust constant '
              'wordt gehouden.',
          controlledVariable: 'Eén uitvoeringsaspect',
        ),
        measurement: const CoachNextMeasurement(
          label: 'Mean radius',
          instructions:
              'Vergelijk vooral mean radius en verticale/horizontale '
              'standaardafwijking; de score is hier secundair.',
        ),
      ),
    ];
  }

  List<CoachInsight>? _compactOffCenter(
    CoachAnalysisSnapshot snapshot,
    List<CoachSeriesObservation> series,
  ) {
    final x = _weightedMean(series, (sample) => sample.centroidXMm);
    final y = _weightedMean(series, (sample) => sample.centroidYMm);
    final offset = math.sqrt(x * x + y * y);
    final meanRadius = _weightedMean(series, (sample) => sample.meanRadiusMm);
    if (offset < snapshot.thresholds.biasToleranceMm ||
        meanRadius > snapshot.thresholds.compactMeanRadiusMm) {
      return null;
    }
    final direction = x.abs() >= y.abs()
        ? (x < 0 ? 'links' : 'rechts')
        : (y < 0 ? 'boven' : 'onder');
    return [
      _insight(
        snapshot: snapshot,
        samples: series,
        ruleId: CoachRuleIds.compactOffCenter,
        discriminator: direction,
        observation:
            'De groep was compact maar lag gemiddeld ${_number(offset)} mm '
            '$direction van het richtpunt.',
        evidenceSummary:
            'De mean radius was ${_number(meanRadius)} mm over '
            '${series.length} reeksen en ${_hitCount(series)} treffers.',
        metrics: {'offset_mm': offset, 'mean_radius_mm': meanRadius},
        explanations: const [
          CoachExplanation(
            title: 'Constante richtreferentie',
            detail:
                'Een herhaalbare maar verschoven richtreferentie of '
                'richtmiddelinstelling kan bij dit beeld passen.',
          ),
          CoachExplanation(
            title: 'Constante positie',
            detail:
                'Een terugkerende houding, steun of lichtsituatie kan eveneens '
                'met de verschuiving samenhangen.',
          ),
        ],
        experiment: const CoachExperiment(
          title: 'Test alleen de centrering',
          instructions:
              'Behoud dezelfde uitvoering en vergelijk een controlegroep met '
              'één kleine, vooraf genoteerde wijziging van de centrering.',
          controlledVariable: 'Centrering',
        ),
        measurement: const CoachNextMeasurement(
          label: 'Centrum én groepsgrootte',
          instructions:
              'Controleer of het centrum dichter bij het richtpunt komt zonder '
              'dat de mean radius groter wordt.',
        ),
      ),
    ];
  }

  List<CoachInsight>? _trend(
    CoachAnalysisSnapshot snapshot,
    List<CoachSeriesObservation> series,
  ) {
    if (!_isStrong(series.length, _hitCount(series))) return null;
    final window = math.max(2, series.length ~/ 3);
    final early = series.take(window).toList();
    final late = series.skip(series.length - window).toList();
    final earlyMean = _weightedMean(early, (sample) => sample.meanRadiusMm);
    final lateMean = _weightedMean(late, (sample) => sample.meanRadiusMm);
    if (earlyMean <= 0) return null;
    final change = (lateMean - earlyMean) / earlyMean;

    late String ruleId;
    late String observation;
    late List<CoachExplanation> explanations;
    late CoachExperiment experiment;
    if (change <= -snapshot.thresholds.trendChangeFraction) {
      ruleId = CoachRuleIds.improving;
      observation =
          'De meest recente reeksen hadden een ${_percent(-change)} kleinere '
          'mean radius dan de vroegste reeksen in deze selectie.';
      explanations = const [
        CoachExplanation(
          title: 'Ontwikkeling of gewenning',
          detail:
              'Het verschil kan passen bij een stabielere uitvoering of '
              'gewenning aan materiaal en omstandigheden.',
        ),
        CoachExplanation(
          title: 'Selectie en omstandigheden',
          detail:
              'Een verschil in dagvorm, licht, steun of geselecteerde sessies '
              'kan ook bijdragen.',
        ),
      ];
      experiment = const CoachExperiment(
        title: 'Herhaal de huidige aanpak',
        instructions:
            'Herhaal dezelfde trainingsopzet in minstens twee nieuwe reeksen '
            'zonder tegelijk andere materiaalkeuzes te wijzigen.',
        controlledVariable: 'Trainingsopzet',
      );
    } else if (change >= snapshot.thresholds.trendChangeFraction) {
      ruleId = CoachRuleIds.declining;
      observation =
          'De meest recente reeksen hadden een ${_percent(change)} grotere '
          'mean radius dan de vroegste reeksen in deze selectie.';
      explanations = const [
        CoachExplanation(
          title: 'Veranderde omstandigheden',
          detail:
              'Licht, steun, tempo, materiaal of trainingscontext kunnen met '
              'het verschil samenhangen.',
        ),
        CoachExplanation(
          title: 'Normale variatie',
          detail:
              'Een beperkt aantal mindere reeksen kan de recente meting '
              'tijdelijk beïnvloeden.',
        ),
      ];
      experiment = const CoachExperiment(
        title: 'Herhaal een vaste referentietraining',
        instructions:
            'Gebruik dezelfde kaart, afstand, materiaalkeuze en vaste '
            'trainingsopzet voor twee controlegroepen.',
        controlledVariable: 'Trainingscontext',
      );
    } else if (change.abs() <= snapshot.thresholds.plateauBandFraction) {
      ruleId = CoachRuleIds.plateau;
      observation =
          'De mean radius bleef stabiel: het verschil tussen vroege en '
          'recente reeksen was ${_percent(change.abs())}.';
      explanations = const [
        CoachExplanation(
          title: 'Stabiel niveau',
          detail:
              'De huidige aanpak kan een reproduceerbaar prestatieniveau '
              'opleveren.',
        ),
        CoachExplanation(
          title: 'Te weinig veranderde prikkel',
          detail:
              'Vergelijkbare trainingen kunnen weinig informatie geven over '
              'welke enkele aanpassing nog verschil maakt.',
        ),
      ];
      experiment = const CoachExperiment(
        title: 'Test één gerichte variabele',
        instructions:
            'Behoud de referentieopzet en wijzig in een tweede blok exact één '
            'vooraf gekozen aspect.',
        controlledVariable: 'Eén gekozen trainingsvariabele',
      );
    } else {
      return null;
    }

    return [
      _insight(
        snapshot: snapshot,
        samples: series,
        ruleId: ruleId,
        observation: observation,
        evidenceSummary:
            'De eerste $window reeksen maten gemiddeld '
            '${_number(earlyMean)} mm en de laatste $window '
            '${_number(lateMean)} mm mean radius.',
        metrics: {
          'early_mean_radius_mm': earlyMean,
          'late_mean_radius_mm': lateMean,
          'relative_change': change,
        },
        explanations: explanations,
        experiment: experiment,
        measurement: const CoachNextMeasurement(
          label: 'Trend in mean radius',
          instructions:
              'Meet opnieuw met dezelfde cohortfilters en beoordeel ook de '
              'consistentie tussen de nieuwe reeksen.',
        ),
      ),
    ];
  }

  List<CoachInsight>? _variability(
    CoachAnalysisSnapshot snapshot,
    List<CoachSeriesObservation> series,
  ) {
    final values = series.map((sample) => sample.meanRadiusMm).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean <= 0) return null;
    final variance =
        values
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        (values.length - 1);
    final coefficient = math.sqrt(variance) / mean;
    if (coefficient < snapshot.thresholds.variabilityCoefficient) return null;
    return [
      _insight(
        snapshot: snapshot,
        samples: series,
        ruleId: CoachRuleIds.variability,
        observation:
            'De groepsgrootte wisselde duidelijk tussen vergelijkbare '
            'reeksen.',
        evidenceSummary:
            'De variatiecoëfficiënt van de mean radius was '
            '${_percent(coefficient)} over ${series.length} reeksen.',
        metrics: {
          'mean_radius_mm': mean,
          'coefficient_of_variation': coefficient,
        },
        explanations: const [
          CoachExplanation(
            title: 'Wisselende uitvoering',
            detail:
                'Tempo, houding, steun of richtbeeld kunnen per reeks anders '
                'zijn geweest.',
          ),
          CoachExplanation(
            title: 'Wisselende context',
            detail:
                'Licht, wind, materiaal of een kleine steekproef kunnen '
                'eveneens bijdragen aan de spreiding tussen reeksen.',
          ),
        ],
        experiment: const CoachExperiment(
          title: 'Gebruik een vaste referentieroutine',
          instructions:
              'Leg voor drie volgende reeksen dezelfde korte voorbereiding, '
              'materiaalkeuze en het tempo vast.',
          controlledVariable: 'Voorbereidingsroutine',
        ),
        measurement: const CoachNextMeasurement(
          label: 'Consistentie tussen reeksen',
          instructions:
              'Vergelijk de variatiecoëfficiënt en de afzonderlijke mean '
              'radius van elke reeks.',
        ),
      ),
    ];
  }

  List<CoachInsight> _materialComparisons(
    CoachAnalysisSnapshot snapshot,
    List<CoachSeriesObservation> series,
  ) => [
    ...?_materialComparison(snapshot, series, CoachMaterialKind.ammoLot),
    ...?_materialComparison(snapshot, series, CoachMaterialKind.firearm),
  ];

  List<CoachInsight>? _materialComparison(
    CoachAnalysisSnapshot snapshot,
    List<CoachSeriesObservation> series,
    CoachMaterialKind kind,
  ) {
    final groups = <String, List<CoachSeriesObservation>>{};
    for (final sample in series) {
      final id = kind == CoachMaterialKind.ammoLot
          ? sample.ammoLotId
          : sample.firearmId;
      if (id != null) (groups[id] ??= []).add(sample);
    }
    final eligible = groups.entries
        .where(
          (entry) => entry.value.length >= 5 && _hitCount(entry.value) >= 50,
        )
        .toList();
    if (eligible.length < 2) return null;
    eligible.sort((first, second) {
      final firstMean = _weightedMean(
        first.value,
        (sample) => sample.meanRadiusMm,
      );
      final secondMean = _weightedMean(
        second.value,
        (sample) => sample.meanRadiusMm,
      );
      final byMean = firstMean.compareTo(secondMean);
      return byMean != 0 ? byMean : first.key.compareTo(second.key);
    });
    final compact = eligible.first;
    final wide = eligible.last;
    final compactMean = _weightedMean(
      compact.value,
      (sample) => sample.meanRadiusMm,
    );
    final wideMean = _weightedMean(wide.value, (sample) => sample.meanRadiusMm);
    if (wideMean <= 0) return null;
    final difference = (wideMean - compactMean) / wideMean;
    if (difference < snapshot.thresholds.materialDifferenceFraction) {
      return null;
    }
    final compactName = _materialName(snapshot, kind, compact.key);
    final wideName = _materialName(snapshot, kind, wide.key);
    final compared = [...compact.value, ...wide.value];
    final kindLabel = kind == CoachMaterialKind.ammoLot
        ? 'munitieprofielen'
        : 'wapens';
    return [
      _insight(
        snapshot: snapshot,
        samples: compared,
        ruleId: CoachRuleIds.materialComparison,
        discriminator: '${kind.name}|${compact.key}|${wide.key}',
        strength: CoachEvidenceStrength.strong,
        observation:
            'Bij $compactName was de gemiddelde mean radius in deze gegevens '
            '${_percent(difference)} kleiner dan bij $wideName.',
        evidenceSummary:
            'De vergelijking omvat ${compact.value.length} en '
            '${wide.value.length} reeksen met minimaal 50 positionele '
            'treffers per variant.',
        metrics: {
          'compact_mean_radius_mm': compactMean,
          'wide_mean_radius_mm': wideMean,
          'relative_difference': difference,
        },
        explanations: [
          CoachExplanation(
            title: 'Meetbaar verschil in deze selectie',
            detail:
                'De twee $kindLabel hadden in de geselecteerde reeksen een '
                'andere gemiddelde groepsgrootte.',
          ),
          const CoachExplanation(
            title: 'Volgorde en omstandigheden',
            detail:
                'Schietvolgorde, dagvorm, licht, steun en andere gekoppelde '
                'keuzes kunnen een deel van het verschil verklaren.',
          ),
        ],
        experiment: CoachExperiment(
          title: 'Voer een afwisselende A/B-test uit',
          instructions:
              'Schiet $compactName en $wideName in een A-B-B-A-volgorde met '
              'dezelfde kaart, afstand en overige instellingen.',
          controlledVariable: kind == CoachMaterialKind.ammoLot
              ? 'Munitieprofiel'
              : 'Wapen',
        ),
        measurement: const CoachNextMeasurement(
          label: 'Mean radius en groepscentrum per variant',
          instructions:
              'Vergelijk beide varianten pas opnieuw nadat ze evenveel '
              'controlegroepen hebben.',
        ),
      ),
    ];
  }

  List<CoachInsight>? _br50AreaPattern(
    CoachAnalysisSnapshot snapshot,
    List<CoachSeriesObservation> series,
  ) {
    final areas = <String, _AreaAggregate>{};
    final usedSamples = <CoachSeriesObservation>[];
    for (final sample in series) {
      if (sample.br50Areas.isEmpty) continue;
      usedSamples.add(sample);
      for (final area in sample.br50Areas) {
        (areas[area.areaId] ??= _AreaAggregate(area.label)).add(area);
      }
    }
    final eligible = areas.entries
        .where((entry) => entry.value.bullCount >= 15)
        .toList();
    if (eligible.length < 2) return null;
    eligible.sort((first, second) {
      final byScore = first.value.averageScore.compareTo(
        second.value.averageScore,
      );
      return byScore != 0 ? byScore : first.key.compareTo(second.key);
    });
    final lowest = eligible.first;
    var otherScoreTotal = 0.0;
    var otherBullCount = 0;
    for (final entry in eligible.skip(1)) {
      otherScoreTotal += entry.value.scoreTotal;
      otherBullCount += entry.value.bullCount;
    }
    final otherAverage = otherScoreTotal / otherBullCount;
    final gap = otherAverage - lowest.value.averageScore;
    if (gap < snapshot.thresholds.br50AreaGapPoints) return null;
    return [
      _insight(
        snapshot: snapshot,
        samples: usedSamples,
        ruleId: CoachRuleIds.br50AreaPattern,
        discriminator: lowest.key,
        observation:
            'In kaartzone ${lowest.value.label} lag de gemiddelde score '
            '${_number(gap)} punt per roos lager dan in de andere gemeten '
            'zones.',
        evidenceSummary:
            'De zone bevatte ${lowest.value.bullCount} gescoorde roosjes over '
            '${usedSamples.length} reeksen.',
        metrics: {
          'area_average_score': lowest.value.averageScore,
          'other_areas_average_score': otherAverage,
          'score_gap': gap,
        },
        explanations: const [
          CoachExplanation(
            title: 'Kaartpositie en zicht',
            detail:
                'Kijkhoek, steun, licht of de positie op de kaart kunnen met '
                'het zoneverschil samenhangen.',
          ),
          CoachExplanation(
            title: 'Spreiding en steekproef',
            detail:
                'De verdeling van moeilijke treffers en normale variatie '
                'kunnen eveneens een zoneverschil geven.',
          ),
        ],
        experiment: CoachExperiment(
          title: 'Controleer dezelfde kaartzone bewust',
          instructions:
              'Gebruik in een volgende BR50-reeks dezelfde opstelling en '
              'controleer vóór kaartzone ${lowest.value.label} expliciet één '
              'vaste kijk- en steunreferentie.',
          controlledVariable: 'Kijk- en steunreferentie per kaartzone',
        ),
        measurement: CoachNextMeasurement(
          label: 'Score en lokale afwijking in ${lowest.value.label}',
          instructions:
              'Vergelijk de zone opnieuw met de overige zones zonder '
              'bullnummer als schotvolgorde te interpreteren.',
        ),
      ),
    ];
  }

  List<CoachInsight>? _firstVersusLater(
    CoachAnalysisSnapshot snapshot,
    List<CoachSeriesObservation> series,
  ) {
    final sessions = <String, List<CoachSeriesObservation>>{};
    for (final sample in series) {
      (sessions[sample.sessionId] ??= []).add(sample);
    }
    final first = <CoachSeriesObservation>[];
    final later = <CoachSeriesObservation>[];
    var pairedSessions = 0;
    for (final samples in sessions.values) {
      samples.sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
      final firstSamples = samples.where(
        (sample) => sample.sequenceNumber == 1,
      );
      final laterSamples = samples.where((sample) => sample.sequenceNumber > 1);
      if (firstSamples.isEmpty || laterSamples.isEmpty) continue;
      pairedSessions++;
      first.add(firstSamples.first);
      later.addAll(laterSamples);
    }
    final compared = [...first, ...later];
    if (pairedSessions < 3 || _hitCount(compared) < minimumPatternHits) {
      return null;
    }
    final firstMean = _weightedMean(first, (sample) => sample.meanRadiusMm);
    final laterMean = _weightedMean(later, (sample) => sample.meanRadiusMm);
    final baseline = math.max(firstMean, laterMean);
    if (baseline <= 0) return null;
    final difference = (firstMean - laterMean) / baseline;
    if (difference.abs() < snapshot.thresholds.firstSeriesDifferenceFraction) {
      return null;
    }
    final description = difference > 0
        ? '${_percent(difference.abs())} ruimer'
        : '${_percent(difference.abs())} compacter';
    return [
      _insight(
        snapshot: snapshot,
        samples: compared,
        ruleId: CoachRuleIds.firstVersusLater,
        discriminator: difference.sign.toString(),
        observation:
            'De eerste reeks van een sessie was gemiddeld $description dan '
            'de latere reeksen.',
        evidenceSummary:
            'De vergelijking gebruikt $pairedSessions sessies: eerste '
            'reeksen maten ${_number(firstMean)} mm en latere reeksen '
            '${_number(laterMean)} mm mean radius.',
        metrics: {
          'first_series_mean_radius_mm': firstMean,
          'later_series_mean_radius_mm': laterMean,
          'relative_difference': difference,
        },
        explanations: const [
          CoachExplanation(
            title: 'Begincontext',
            detail:
                'Opwarming, controle van materiaal of de eerste gewenning aan '
                'de omstandigheden kunnen met het patroon samenhangen.',
          ),
          CoachExplanation(
            title: 'Latere context',
            detail:
                'Tempo, concentratie, veranderend licht of normale variatie '
                'kunnen het verschil eveneens beïnvloeden.',
          ),
        ],
        experiment: const CoachExperiment(
          title: 'Gebruik een vaste openingsroutine',
          instructions:
              'Voer bij drie sessies dezelfde korte voorbereiding uit en '
              'verander verder niets aan de eerste reeks.',
          controlledVariable: 'Openingsroutine',
        ),
        measurement: const CoachNextMeasurement(
          label: 'Eerste versus latere mean radius',
          instructions:
              'Vergelijk per sessie de eerste reeks met het gemiddelde van de '
              'latere reeksen.',
        ),
      ),
    ];
  }

  List<CoachInsight>? _reflectionCorrelation(
    CoachAnalysisSnapshot snapshot,
    List<CoachSeriesObservation> series,
  ) {
    final good = series
        .where(
          (sample) => sample.perceivedQuality == CoachPerceivedQuality.good,
        )
        .toList();
    final difficult = series
        .where(
          (sample) =>
              sample.perceivedQuality == CoachPerceivedQuality.difficult,
        )
        .toList();
    if (good.length < 3 ||
        difficult.length < 3 ||
        _hitCount(good) < 15 ||
        _hitCount(difficult) < 15) {
      return null;
    }
    final goodMean = _weightedMean(good, (sample) => sample.meanRadiusMm);
    final difficultMean = _weightedMean(
      difficult,
      (sample) => sample.meanRadiusMm,
    );
    final baseline = math.max(goodMean, difficultMean);
    if (baseline <= 0) return null;
    final difference = (difficultMean - goodMean) / baseline;
    if (difference.abs() < snapshot.thresholds.reflectionDifferenceFraction) {
      return null;
    }
    final relation = difference > 0 ? 'ruimer' : 'compacter';
    final compared = [...good, ...difficult];
    return [
      _insight(
        snapshot: snapshot,
        samples: compared,
        ruleId: CoachRuleIds.reflectionCorrelation,
        discriminator: difference.sign.toString(),
        observation:
            'Als ‘Moeilijk’ beoordeelde reeksen waren gemiddeld '
            '${_percent(difference.abs())} $relation dan als ‘Goed’ '
            'beoordeelde reeksen.',
        evidenceSummary:
            'De vergelijking gebruikt ${good.length} als goed en '
            '${difficult.length} als moeilijk beoordeelde reeksen.',
        metrics: {
          'good_mean_radius_mm': goodMean,
          'difficult_mean_radius_mm': difficultMean,
          'relative_difference': difference,
        },
        explanations: const [
          CoachExplanation(
            title: 'Zelfevaluatie sluit mogelijk aan',
            detail:
                'De eigen beoordeling kan een werkelijk verschil in '
                'herhaalbaarheid of omstandigheden hebben weerspiegeld.',
          ),
          CoachExplanation(
            title: 'Verwachting en toeval',
            detail:
                'Verwachting, achterafbeoordeling en normale variatie kunnen '
                'de samenhang eveneens beïnvloeden.',
          ),
        ],
        experiment: const CoachExperiment(
          title: 'Noteer de beoordeling vóór de score',
          instructions:
              'Registreer bij volgende reeksen direct na het schieten de '
              'beleving en bekijk pas daarna de gemeten score en groep.',
          controlledVariable: 'Moment van zelfevaluatie',
        ),
        measurement: const CoachNextMeasurement(
          label: 'Zelfevaluatie tegenover mean radius',
          instructions:
              'Vergelijk de categorieën opnieuw zonder de samenhang als '
              'oorzaak te interpreteren.',
        ),
      ),
    ];
  }

  CoachInsight _insight({
    required CoachAnalysisSnapshot snapshot,
    required List<CoachSeriesObservation> samples,
    required String ruleId,
    required String observation,
    required String evidenceSummary,
    required Map<String, double> metrics,
    required List<CoachExplanation> explanations,
    required CoachExperiment experiment,
    required CoachNextMeasurement measurement,
    String discriminator = '',
    CoachEvidenceStrength? strength,
  }) {
    final hitCount = _hitCount(samples);
    final resolvedStrength = strength ?? _strength(samples.length, hitCount);
    final warnings = <String>[
      if (resolvedStrength == CoachEvidenceStrength.moderate)
        'Voorlopig patroon: minder dan 5 reeksen of 60 positionele treffers.',
      if (samples.any((sample) => sample.hasApproximatePositions))
        'Een deel van de posities is benaderend; interpreteer '
            'spreidingsmaten voorzichtig.',
    ];
    return CoachInsight(
      fingerprint: CoachFingerprint.create(
        ruleId: ruleId,
        ruleVersion: ruleVersion,
        cohort: snapshot.cohort,
        evidenceKeys: samples.map((sample) => sample.fingerprintKey),
        discriminator: discriminator,
      ),
      ruleId: ruleId,
      ruleVersion: ruleVersion,
      observation: observation,
      evidence: CoachEvidence(
        summary: evidenceSummary,
        seriesCount: samples.map((sample) => sample.seriesId).toSet().length,
        positionedHitCount: hitCount,
        metrics: metrics,
      ),
      evidenceStrength: resolvedStrength,
      possibleExplanations: explanations,
      proposedExperiment: experiment,
      nextMeasurement: measurement,
      cohortReference: snapshot.cohort,
      warnings: warnings,
    );
  }

  String _materialName(
    CoachAnalysisSnapshot snapshot,
    CoachMaterialKind kind,
    String id,
  ) {
    for (final label in snapshot.materialLabels) {
      if (label.kind == kind && label.id == id) return label.displayName;
    }
    return kind == CoachMaterialKind.ammoLot
        ? 'munitieprofiel $id'
        : 'wapen $id';
  }

  static int _compareChronologically(
    CoachSeriesObservation first,
    CoachSeriesObservation second,
  ) {
    final byTime = first.occurredAtUtc.compareTo(second.occurredAtUtc);
    return byTime != 0 ? byTime : first.seriesId.compareTo(second.seriesId);
  }

  static int _hitCount(Iterable<CoachSeriesObservation> samples) =>
      samples.fold(0, (sum, sample) => sum + sample.positionedHitCount);

  static double _weightedMean(
    Iterable<CoachSeriesObservation> samples,
    double Function(CoachSeriesObservation sample) value,
  ) {
    var total = 0.0;
    var weight = 0;
    for (final sample in samples) {
      total += value(sample) * sample.positionedHitCount;
      weight += sample.positionedHitCount;
    }
    return weight == 0 ? 0 : total / weight;
  }

  static CoachEvidenceStrength _strength(int seriesCount, int hitCount) =>
      _isStrong(seriesCount, hitCount)
      ? CoachEvidenceStrength.strong
      : CoachEvidenceStrength.moderate;

  static bool _isStrong(int seriesCount, int hitCount) =>
      seriesCount >= strongEvidenceSeries && hitCount >= strongEvidenceHits;

  static String _number(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');

  static String _percent(double fraction) =>
      '${(fraction * 100).toStringAsFixed(0)}%';
}

class _AreaAggregate {
  _AreaAggregate(this.label);

  final String label;
  var bullCount = 0;
  var scoreTotal = 0.0;

  double get averageScore => scoreTotal / bullCount;

  void add(CoachAreaObservation observation) {
    bullCount += observation.scoredBullCount;
    scoreTotal += observation.averageScore * observation.scoredBullCount;
  }
}
