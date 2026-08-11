/// Stable identifiers for the descriptive metrics shown by the analysis UI.
enum AnalysisMetricId {
  groupCenter,
  meanRadius,
  extremeSpread,
  standardDeviationX,
  standardDeviationY,
  covarianceEllipse,
  empiricalR50,
  empiricalR90,
  moa,
  milliradians,
  scoreTrend,
  scoreConsistency,
  potentialScore,
  subgroupDetection,
}

/// Plain-language content used by every metric explanation surface.
///
/// Definitions deliberately describe what the stored impact positions can
/// support. They do not infer shooting technique or promise future results.
class MetricDefinition {
  const MetricDefinition({
    required this.id,
    required this.label,
    required this.shortDescription,
    required this.calculation,
    required this.interpretation,
    required this.limitations,
    required this.dataRequirement,
  });

  final AnalysisMetricId id;
  final String label;
  final String shortDescription;
  final String calculation;
  final String interpretation;
  final List<String> limitations;
  final String dataRequirement;
}

/// Single source of Dutch metric definitions and cautions.
abstract final class MetricDefinitions {
  static const groupCenter = MetricDefinition(
    id: AnalysisMetricId.groupCenter,
    label: 'Groepscentrum',
    shortDescription: 'Het gemiddelde trefpunt ten opzichte van het richtpunt.',
    calculation:
        'De app neemt het gemiddelde van alle geldige positionele treffers. '
        'Bij een BR50-kaart wordt iedere treffer eerst omgerekend ten opzichte '
        'van het centrum van het bijbehorende roosje.',
    interpretation:
        'De horizontale en verticale waarden tonen hoeveel millimeter de groep '
        'gemiddeld links, rechts, hoog of laag ligt. Een waarde dichter bij nul '
        'betekent dat de groep beter gecentreerd is.',
    limitations: [
      'Het groepscentrum zegt niets over de grootte of consistentie van de groep.',
      'Een verschoven groep bewijst niet dat het vizier verkeerd staat.',
      'Missers zonder positie worden niet in het gemiddelde opgenomen.',
    ],
    dataRequirement:
        'Vanaf één positionele treffer berekenbaar; meerdere vergelijkbare '
        'treffers zijn nodig voor een bruikbare patroonbeoordeling.',
  );

  static const meanRadius = MetricDefinition(
    id: AnalysisMetricId.meanRadius,
    label: 'Mean radius',
    shortDescription:
        'De gemiddelde afstand van iedere treffer tot het groepscentrum.',
    calculation:
        'Eerst wordt het groepscentrum berekend. Daarna wordt voor iedere '
        'positionele treffer de afstand tot dat centrum gemeten en worden die '
        'afstanden gemiddeld. Multipliciteit telt als meerdere treffers op '
        'dezelfde positie.',
    interpretation:
        'Een kleinere mean radius wijst op een compactere groep. De meting '
        'gebruikt alle positionele treffers en is daardoor doorgaans stabieler '
        'dan alleen de grootste afstand tussen twee treffers.',
    limitations: [
      'De waarde is bij een kleine steekproef gevoelig voor toeval.',
      'Een meervoudig gat met één geschatte positie maakt de spreiding benaderend.',
      'De waarde beschrijft het resultaat, niet de technische oorzaak ervan.',
    ],
    dataRequirement:
        'Vanaf drie positionele treffers voorlopig bruikbaar; vanaf tien '
        'treffers geschikt voor een volledige beschrijvende reeksanalyse.',
  );

  static const extremeSpread = MetricDefinition(
    id: AnalysisMetricId.extremeSpread,
    label: 'Extreme spreiding',
    shortDescription:
        'De grootste centrum-tot-centrumafstand tussen twee treffers.',
    calculation:
        'De app vergelijkt ieder paar geldige positionele treffers en bewaart '
        'de grootste afstand in millimeter.',
    interpretation:
        'Een kleinere waarde betekent dat de twee verst uit elkaar liggende '
        'treffers dichter bij elkaar liggen.',
    limitations: [
      'Eén verre treffer kan de volledige waarde bepalen.',
      'Groepen met meer schoten hebben meer kans op een grotere extreme spreiding.',
      'Vergelijk alleen reeksen met een vergelijkbaar aantal treffers.',
    ],
    dataRequirement:
        'Minstens twee positionele treffers; vijf of meer zijn wenselijk voor '
        'een betekenisvollere vergelijking.',
  );

  static const standardDeviationX = MetricDefinition(
    id: AnalysisMetricId.standardDeviationX,
    label: 'Horizontale standaardafwijking',
    shortDescription:
        'Hoe sterk de treffers horizontaal rond het groepscentrum variëren.',
    calculation:
        'De sample-standaardafwijking wordt berekend over de horizontale '
        'millimeterposities van alle geldige positionele treffers.',
    interpretation:
        'Een kleinere waarde wijst op minder links-rechtsvariatie. Vergelijk de '
        'waarde met de verticale standaardafwijking om de dominante richting '
        'van de spreiding te beschrijven.',
    limitations: [
      'De maat is onstabiel bij weinig treffers.',
      'Ze verklaart niet waarom horizontale variatie ontstaat.',
      'Onzekere of geschatte posities kunnen de waarde beïnvloeden.',
    ],
    dataRequirement:
        'Minstens drie positionele treffers; vanaf tien treffers volledig tonen.',
  );

  static const standardDeviationY = MetricDefinition(
    id: AnalysisMetricId.standardDeviationY,
    label: 'Verticale standaardafwijking',
    shortDescription:
        'Hoe sterk de treffers verticaal rond het groepscentrum variëren.',
    calculation:
        'De sample-standaardafwijking wordt berekend over de verticale '
        'millimeterposities van alle geldige positionele treffers.',
    interpretation:
        'Een kleinere waarde wijst op minder hoog-laagvariatie. Vergelijk de '
        'waarde met de horizontale standaardafwijking om de dominante richting '
        'van de spreiding te beschrijven.',
    limitations: [
      'De maat is onstabiel bij weinig treffers.',
      'Ze verklaart niet waarom verticale variatie ontstaat.',
      'Onzekere of geschatte posities kunnen de waarde beïnvloeden.',
    ],
    dataRequirement:
        'Minstens drie positionele treffers; vanaf tien treffers volledig tonen.',
  );

  static const covarianceEllipse = MetricDefinition(
    id: AnalysisMetricId.covarianceEllipse,
    label: '1σ-spreidingsellips',
    shortDescription:
        'Een samenvatting van de richting en standaardspreiding van de groep.',
    calculation:
        'De app berekent de sample-covariantie van alle geldige positionele '
        'treffers. De eigenvector met de grootste variantie bepaalt de richting; '
        'de vierkantswortels van beide eigenwaarden bepalen de halve assen.',
    interpretation:
        'Een langgerekte ellips toont dat de groep in één richting sterker '
        'varieert. De hoek beschrijft die richting op het scherm.',
    limitations: [
      'De 1σ-ellips is geen buitenrand en hoeft niet alle treffers te bevatten.',
      'Treffers buiten de ellips tellen wel mee in alle groepsmaten.',
      'Een verre treffer kan richting en afmetingen sterk beïnvloeden.',
      'De ellips beschrijft het trefbeeld en verklaart geen technische oorzaak.',
    ],
    dataRequirement:
        'Minstens drie positionele treffers; bij een kleine steekproef is de '
        'vorm voorlopig.',
  );

  static const empiricalR50 = MetricDefinition(
    id: AnalysisMetricId.empiricalR50,
    label: 'Waargenomen R50',
    shortDescription:
        'De radius rond het groepscentrum waarbinnen 50% van de gemeten '
        'treffers ligt.',
    calculation:
        'De afstanden van alle positionele treffers tot het groepscentrum '
        'worden gesorteerd. De app neemt daaruit het waargenomen 50e percentiel.',
    interpretation:
        'Een kleinere R50 betekent dat de middelste helft van de gemeten '
        'treffers compacter ligt.',
    limitations: [
      'Dit is een empirische samenvatting van deze treffers, geen voorspelling.',
      'Bij weinig treffers kan één positie de percentielwaarde sterk veranderen.',
      'Vergelijk alleen voldoende grote, vergelijkbare reeksen.',
    ],
    dataRequirement:
        'Pas als volledige metric tonen vanaf tien positionele treffers.',
  );

  static const empiricalR90 = MetricDefinition(
    id: AnalysisMetricId.empiricalR90,
    label: 'Waargenomen R90',
    shortDescription:
        'De radius rond het groepscentrum waarbinnen 90% van de gemeten '
        'treffers ligt.',
    calculation:
        'De afstanden van alle positionele treffers tot het groepscentrum '
        'worden gesorteerd. De app neemt daaruit het waargenomen 90e percentiel.',
    interpretation:
        'Een kleinere R90 betekent dat bijna alle gemeten treffers dichter bij '
        'het groepscentrum liggen.',
    limitations: [
      'Dit is een empirische samenvatting van deze treffers, geen voorspelling.',
      'R90 is gevoelig voor de buitenste treffers en voor een kleine steekproef.',
      'Een misser zonder positie kan niet in deze radius worden opgenomen.',
    ],
    dataRequirement:
        'Pas als volledige metric tonen vanaf tien positionele treffers.',
  );

  static const moa = MetricDefinition(
    id: AnalysisMetricId.moa,
    label: 'Spreiding in MOA',
    shortDescription:
        'De extreme spreiding omgerekend naar een hoek in minutes of angle.',
    calculation:
        'De gemeten extreme spreiding en de geregistreerde afstand worden '
        'omgerekend naar een hoekmaat. Daardoor kunnen afstanden in theorie '
        'beter worden vergeleken.',
    interpretation:
        'Een kleinere MOA-waarde betekent een kleinere hoekspreiding.',
    limitations: [
      'De uitkomst is alleen correct wanneer afstand en kaartgeometrie kloppen.',
      'Dezelfde beperkingen als extreme spreiding blijven gelden.',
      'Verschillende kaarten en omstandigheden worden niet automatisch vergelijkbaar.',
    ],
    dataRequirement:
        'Minstens twee positionele treffers en een geldige afstand groter dan nul.',
  );

  static const milliradians = MetricDefinition(
    id: AnalysisMetricId.milliradians,
    label: 'Spreiding in millirad',
    shortDescription:
        'De extreme spreiding omgerekend naar een hoek in milliradialen.',
    calculation:
        'De gemeten extreme spreiding wordt gedeeld door de geregistreerde '
        'afstand en als milliradiaal weergegeven.',
    interpretation:
        'Een kleinere milliradwaarde betekent een kleinere hoekspreiding.',
    limitations: [
      'De uitkomst is alleen correct wanneer afstand en kaartgeometrie kloppen.',
      'Dezelfde beperkingen als extreme spreiding blijven gelden.',
      'Het is een spreidingsmaat en geen automatische viziercorrectie.',
    ],
    dataRequirement:
        'Minstens twee positionele treffers en een geldige afstand groter dan nul.',
  );

  static const scoreTrend = MetricDefinition(
    id: AnalysisMetricId.scoreTrend,
    label: 'Scoretrend',
    shortDescription:
        'De gemiddelde verandering in scorepercentage van reeks naar reeks.',
    calculation:
        'De app zet vergelijkbare reeksen in chronologische volgorde en past '
        'een rechte trendlijn toe op het scorepercentage. De getoonde waarde '
        'is de helling in procentpunten per reeks.',
    interpretation:
        'Een positieve waarde beschrijft een stijgende score in deze selectie; '
        'een negatieve waarde een dalende. Een waarde rond nul wijst op weinig '
        'lineaire verandering.',
    limitations: [
      'Een trend is geen voorspelling van een volgende training.',
      'Eén uitzonderlijke reeks kan een kleine selectie sterk beïnvloeden.',
      'Alleen exact vergelijkbare kaart-, afstand- en materiaalcontexten worden samengevoegd.',
    ],
    dataRequirement:
        'Minstens twee vergelijkbare reeksen; drie reeksen en dertig '
        'positionele treffers zijn wenselijk voor een voorzichtig patroon.',
  );

  static const scoreConsistency = MetricDefinition(
    id: AnalysisMetricId.scoreConsistency,
    label: 'Scorevariatie',
    shortDescription:
        'Hoe sterk de scorepercentages tussen de geselecteerde reeksen variëren.',
    calculation:
        'De app berekent de standaardafwijking van de scorepercentages van '
        'de geselecteerde, exact vergelijkbare reeksen.',
    interpretation:
        'Een kleinere waarde betekent dat de reeksscores dichter bij elkaar '
        'lagen. Een grotere waarde beschrijft meer wisselvalligheid.',
    limitations: [
      'Scorevariatie combineert centrering, spreiding en eventuele missers.',
      'Een kleine selectie levert een onstabiele waarde.',
      'De waarde verklaart niet waardoor verschillen tussen reeksen ontstonden.',
    ],
    dataRequirement:
        'Minstens twee vergelijkbare reeksen; vijf of meer geven een '
        'bruikbaardere vergelijking.',
  );

  static const potentialScore = MetricDefinition(
    id: AnalysisMetricId.potentialScore,
    label: 'Potentiële score',
    shortDescription:
        'Een what-ifscore wanneer exact hetzelfde trefbeeld als geheel optimaal '
        'op de kaart wordt verschoven.',
    calculation:
        'De score-engine herberekent dezelfde treffers op verschillende '
        'verschuivingen. De beste geldige totaalscore en de kleinste bijbehorende '
        'verplaatsing worden gerapporteerd.',
    interpretation:
        'Het verschil met de huidige score helpt onderscheiden hoeveel winst in '
        'de centrering zit en hoeveel scorekloof door de spreiding overblijft.',
    limitations: [
      'Dit is een reproduceerbare what-ifanalyse, geen voorspelling of garantie.',
      'De uitkomst is geen vizieradvies zonder een bevestigd vizierprofiel.',
      'Missers zonder positie kunnen niet betrouwbaar worden verschoven.',
    ],
    dataRequirement:
        'Een geldige doelkaartsnapshot en voldoende positionele treffers om de '
        'groep zinvol te beschrijven.',
  );

  static const subgroupDetection = MetricDefinition(
    id: AnalysisMetricId.subgroupDetection,
    label: 'Mogelijke deelgroepen',
    shortDescription:
        'Een statistische suggestie dat de geplaatste treffers mogelijk meer '
        'dan één ruimtelijke groep vormen.',
    calculation:
        'De app onderzoekt twee of drie kandidaatgroepen en toont alleen een '
        'suggestie wanneer scheiding en stabiliteit vooraf ingestelde drempels '
        'halen.',
    interpretation:
        'Gebruik de suggestie als aanleiding om het patroon te bekijken of in '
        'een volgende training één variabele te testen.',
    limitations: [
      'Een voorgestelde deelgroep is geen bewezen flyer of technische diagnose.',
      'Geen enkele treffer wordt automatisch verwijderd of uitgesloten.',
      'De officiële score en opgeslagen treffers veranderen nooit.',
    ],
    dataRequirement:
        'Minstens tien positionele treffers; de suggestie verschijnt alleen bij '
        'voldoende scheiding en stabiliteit.',
  );

  static const values = <MetricDefinition>[
    groupCenter,
    meanRadius,
    extremeSpread,
    standardDeviationX,
    standardDeviationY,
    covarianceEllipse,
    empiricalR50,
    empiricalR90,
    moa,
    milliradians,
    scoreTrend,
    scoreConsistency,
    potentialScore,
    subgroupDetection,
  ];

  static MetricDefinition forId(AnalysisMetricId id) =>
      values.firstWhere((definition) => definition.id == id);
}
