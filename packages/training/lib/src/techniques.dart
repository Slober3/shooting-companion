enum TechniqueCategory {
  safety,
  position,
  aiming,
  shotExecution,
  mentalRoutine,
  benchrest,
}

enum TechniqueIllustration {
  safetyTriangle,
  naturalAlignment,
  sightAlignment,
  triggerPressure,
  breathingCycle,
  followThrough,
  standingBalance,
  benchrestSupport,
  shotRoutine,
}

enum TechniqueReviewStatus { evidenceInformed, coachReviewRequired }

class TechniqueSource {
  const TechniqueSource({required this.title, required this.url});

  final String title;
  final String url;

  Map<String, Object?> toJson() => {'title': title, 'url': url};

  factory TechniqueSource.fromJson(Map<String, Object?> json) =>
      TechniqueSource(
        title: _requiredTechniqueText(json['title']! as String, 'title'),
        url: _validatedUrl(json['url']! as String),
      );
}

class TechniqueTopic {
  factory TechniqueTopic({
    required String id,
    required int version,
    required String title,
    required String summary,
    required TechniqueCategory category,
    required TechniqueIllustration illustration,
    required Iterable<String> keyPoints,
    required Iterable<String> commonPitfalls,
    required Iterable<String> practiceSteps,
    required String safetyNote,
    required Iterable<TechniqueSource> sources,
    TechniqueReviewStatus reviewStatus =
        TechniqueReviewStatus.coachReviewRequired,
  }) {
    if (version < 1) throw ArgumentError.value(version, 'version');
    final normalizedSources = List<TechniqueSource>.unmodifiable(sources);
    if (normalizedSources.isEmpty) {
      throw ArgumentError('Een techniekonderwerp vereist minstens één bron.');
    }
    return TechniqueTopic._(
      id: _requiredTechniqueText(id, 'id'),
      version: version,
      title: _requiredTechniqueText(title, 'title'),
      summary: _requiredTechniqueText(summary, 'summary'),
      category: category,
      illustration: illustration,
      keyPoints: _normalizedList(keyPoints, 'keyPoints'),
      commonPitfalls: _normalizedList(commonPitfalls, 'commonPitfalls'),
      practiceSteps: _normalizedList(practiceSteps, 'practiceSteps'),
      safetyNote: _requiredTechniqueText(safetyNote, 'safetyNote'),
      sources: normalizedSources,
      reviewStatus: reviewStatus,
    );
  }

  const TechniqueTopic._({
    required this.id,
    required this.version,
    required this.title,
    required this.summary,
    required this.category,
    required this.illustration,
    required this.keyPoints,
    required this.commonPitfalls,
    required this.practiceSteps,
    required this.safetyNote,
    required this.sources,
    required this.reviewStatus,
  });

  final String id;
  final int version;
  final String title;
  final String summary;
  final TechniqueCategory category;
  final TechniqueIllustration illustration;
  final List<String> keyPoints;
  final List<String> commonPitfalls;
  final List<String> practiceSteps;
  final String safetyNote;
  final List<TechniqueSource> sources;
  final TechniqueReviewStatus reviewStatus;

  String get versionedId => '$id@$version';

  Map<String, Object?> toJson() => {
    'id': id,
    'version': version,
    'title': title,
    'summary': summary,
    'category': category.name,
    'illustration': illustration.name,
    'keyPoints': keyPoints,
    'commonPitfalls': commonPitfalls,
    'practiceSteps': practiceSteps,
    'safetyNote': safetyNote,
    'sources': sources.map((source) => source.toJson()).toList(),
    'reviewStatus': reviewStatus.name,
  };

  factory TechniqueTopic.fromJson(Map<String, Object?> json) => TechniqueTopic(
    id: json['id']! as String,
    version: json['version']! as int,
    title: json['title']! as String,
    summary: json['summary']! as String,
    category: TechniqueCategory.values.byName(json['category']! as String),
    illustration: TechniqueIllustration.values.byName(
      json['illustration']! as String,
    ),
    keyPoints: (json['keyPoints']! as List<Object?>).cast<String>(),
    commonPitfalls: (json['commonPitfalls']! as List<Object?>).cast<String>(),
    practiceSteps: (json['practiceSteps']! as List<Object?>).cast<String>(),
    safetyNote: json['safetyNote']! as String,
    sources: (json['sources']! as List<Object?>).map(
      (source) =>
          TechniqueSource.fromJson((source! as Map).cast<String, Object?>()),
    ),
    reviewStatus: TechniqueReviewStatus.values.byName(
      json['reviewStatus']! as String,
    ),
  );
}

abstract final class BuiltInTechniques {
  static const _safety =
      'Pas dit alleen toe op een erkende baan en volg altijd de aanwijzingen '
      'van de baanverantwoordelijke. Bij dry fire: controleer wapen, kamer, '
      'magazijn en veilige richting volgens de lokale regels.';
  static const _issfAcademy = TechniqueSource(
    title: 'ISSF Academy',
    url: 'https://www.issf-sports.org/academy',
  );
  static const _cmpFundamentals = TechniqueSource(
    title: 'CMP Fundamentals of Rifle Marksmanship',
    url:
        'https://thecmp.org/wp-content/uploads/2023/12/TheFundamentalsOfRifleMarksmanship.pdf',
  );
  static const _nraPrinciples = TechniqueSource(
    title: 'NRA Principles of Marksmanship',
    url:
        'https://online.nra.org.uk/images/uploaded/Module%201%20-%20Pre-reading.pdf',
  );
  static const _issfFocus = TechniqueSource(
    title: 'ISSF: building focus shot by shot',
    url: 'https://www.issf-sports.org/news/4961',
  );
  static const _issfTremor = TechniqueSource(
    title: 'ISSF: postural tremor and shooting performance',
    url: 'https://www.issf-sports.org/news/3756',
  );
  static const _cmpSafety = TechniqueSource(
    title: 'CMP Safe Gun Handling',
    url: 'https://thecmp.org/wp-content/uploads/2026/01/marksmanship.pdf',
  );

  static final safetyRoutine = TechniqueTopic(
    id: 'safe-range-routine',
    version: 1,
    title: 'Veilige baanroutine',
    summary:
        'Een vaste controle vóór, tijdens en na de reeks voorkomt dat '
        'trainingsdruk de basisregels verdringt.',
    category: TechniqueCategory.safety,
    illustration: TechniqueIllustration.safetyTriangle,
    keyPoints: const [
      'Veilige mondingsrichting blijft continu behouden.',
      'Vinger blijft buiten de trekkerbeugel tot vuren is toegestaan.',
      'Na de reeks: actie open, ontladen en toestand zichtbaar controleren.',
    ],
    commonPitfalls: const [
      'Materiaal aanpassen zonder de toestand opnieuw te controleren.',
      'De telefoon bedienen terwijl het wapen nog niet veilig is afgelegd.',
    ],
    practiceSteps: const [
      'Spreek je vaste controlevolgorde hardop of in gedachten uit.',
      'Leg het wapen veilig af vóór je de app of kaart bedient.',
      'Herhaal de controle na iedere onderbreking.',
    ],
    safetyNote: _safety,
    sources: const [_cmpSafety],
    reviewStatus: TechniqueReviewStatus.evidenceInformed,
  );

  static final naturalAlignment = TechniqueTopic(
    id: 'natural-point-of-aim',
    version: 1,
    title: 'Natuurlijke uitlijning',
    summary:
        'Laat houding en steun het wapen naar het richtpunt brengen zonder '
        'blijvende zijdelingse spierspanning.',
    category: TechniqueCategory.position,
    illustration: TechniqueIllustration.naturalAlignment,
    keyPoints: const [
      'Bouw eerst een comfortabele, herhaalbare houding.',
      'Controleer waar de uitlijning natuurlijk terugkomt.',
      'Corrigeer de hele houding of steun, niet alleen armen of romp.',
    ],
    commonPitfalls: const [
      'Het richtpunt vasthouden met continue spierspanning.',
      'Een oncomfortabele houding toch proberen te behouden.',
    ],
    practiceSteps: const [
      'Maak het wapen veilig volgens de baanregels.',
      'Neem de houding aan, ontspan kort en controleer de terugkeerpositie.',
      'Verplaats voeten, stoel of steun en herhaal de controle.',
    ],
    safetyNote: _safety,
    sources: const [_nraPrinciples, _cmpFundamentals],
  );

  static final standingBalance = TechniqueTopic(
    id: 'standing-balance',
    version: 1,
    title: 'Balans in staande houding',
    summary:
        'Zoek een stabiele zone waarin het lichaam kan bewegen zonder '
        'krampachtig tegen iedere kleine beweging te vechten.',
    category: TechniqueCategory.position,
    illustration: TechniqueIllustration.standingBalance,
    keyPoints: const [
      'Gewicht en steun blijven voorspelbaar verdeeld.',
      'Hoofd- en oogpositie worden herhaalbaar opgebouwd.',
      'Een normale bewegingzone is informatie, geen fout op zichzelf.',
    ],
    commonPitfalls: const [
      'De adem onnodig lang vasthouden om beweging te forceren.',
      'Spanning verhogen zodra het richtbeeld beweegt.',
    ],
    practiceSteps: const [
      'Observeer eerst alleen de bewegingzone zonder af te drukken.',
      'Herhaal drie opbouwen en vergelijk waar het richtbeeld terugkeert.',
      'Stop wanneer vermoeidheid de houding duidelijk verandert.',
    ],
    safetyNote: _safety,
    sources: const [_issfTremor, _issfAcademy],
  );

  static final sightAlignment = TechniqueTopic(
    id: 'sight-alignment-picture',
    version: 1,
    title: 'Vizierlijn en richtbeeld',
    summary:
        'Scheid de relatie tussen voor- en achtervizier van de plaats van dat '
        'uitgelijnde beeld ten opzichte van de kaart.',
    category: TechniqueCategory.aiming,
    illustration: TechniqueIllustration.sightAlignment,
    keyPoints: const [
      'Werk met dezelfde hoofd- en oogpositie.',
      'Beoordeel vizieruitlijning en kaartpositie als aparte controles.',
      'Gebruik een reproduceerbaar richtgebied, niet één perfect stil moment.',
    ],
    commonPitfalls: const [
      'Visuele aandacht voortdurend tussen vizier en kaart laten springen.',
      'Een slecht uitgelijnd vizier compenseren door op de kaart te sturen.',
    ],
    practiceSteps: const [
      'Oefen de vizierrelatie eerst zonder scoredoel.',
      'Bouw daarna hetzelfde beeld op tegen een eenvoudige kaart.',
      'Noteer alleen wat je werkelijk zag, niet wat de treffer suggereert.',
    ],
    safetyNote: _safety,
    sources: const [_nraPrinciples, _cmpFundamentals],
  );

  static final triggerControl = TechniqueTopic(
    id: 'controlled-trigger-pressure',
    version: 1,
    title: 'Gecontroleerde trekkerdruk',
    summary:
        'Bouw druk op zonder de uitlijning bewust te verstoren en behoud '
        'de uitvoering wanneer het schot valt.',
    category: TechniqueCategory.shotExecution,
    illustration: TechniqueIllustration.triggerPressure,
    keyPoints: const [
      'Druk wordt beheerst en in een reproduceerbare richting opgebouwd.',
      'Richtbeeld en drukproces lopen samen door.',
      'Beoordeel na de reeks patroon en uitvoering, niet één losse treffer.',
    ],
    commonPitfalls: const [
      'Wachten op een perfect beeld en dan abrupt handelen.',
      'Een technisch probleem diagnosticeren uit één trefpunt.',
    ],
    practiceSteps: const [
      'Oefen alleen wanneer dry fire door materiaal en baanregels is toegestaan.',
      'Gebruik een korte reeks met één uitvoeringsdoel.',
      'Vergelijk zelfevaluatie met groepspatroon, zonder causaliteit te claimen.',
    ],
    safetyNote: _safety,
    sources: const [_cmpFundamentals, _nraPrinciples],
  );

  static final breathing = TechniqueTopic(
    id: 'breathing-shot-window',
    version: 1,
    title: 'Ademritme en schotvenster',
    summary:
        'Gebruik een comfortabel ademritme om de opbouw voorspelbaar te '
        'maken; forceer geen lange ademstop.',
    category: TechniqueCategory.shotExecution,
    illustration: TechniqueIllustration.breathingCycle,
    keyPoints: const [
      'Start de reeks met een normaal, reproduceerbaar ritme.',
      'Kies een comfortabel moment in plaats van een maximale ademstop.',
      'Breek de opbouw af wanneer spanning of tijdsdruk oploopt.',
    ],
    commonPitfalls: const [
      'Steeds langer vasthouden omdat het richtbeeld niet perfect is.',
      'Een vast schema gebruiken dat niet past bij je actuele toestand.',
    ],
    practiceSteps: const [
      'Observeer drie ademcycli zonder schot.',
      'Kies daarna een kort, comfortabel uitvoeringsvenster.',
      'Vergelijk consistentie, niet alleen hoogste score.',
    ],
    safetyNote: _safety,
    sources: const [_issfTremor, _issfFocus],
  );

  static final followThrough = TechniqueTopic(
    id: 'follow-through-shot-call',
    version: 1,
    title: 'Follow-through en schotbeeld',
    summary:
        'Laat positie, visuele aandacht en controle kort doorlopen en leg '
        'vast wat je waarnam vóór je de kaart beoordeelt.',
    category: TechniqueCategory.shotExecution,
    illustration: TechniqueIllustration.followThrough,
    keyPoints: const [
      'De uitvoering stopt niet abrupt bij het schot.',
      'Noteer de waargenomen richting zonder de uitslag te kennen.',
      'Gebruik meerdere reeksen om patronen te beoordelen.',
    ],
    commonPitfalls: const [
      'Onmiddellijk naar de kaart of monitor kijken.',
      'Een verklaring achteraf aanpassen aan de treffer.',
    ],
    practiceSteps: const [
      'Houd de veilige richting en positie kort aan.',
      'Markeer de waargenomen richting of kwaliteit.',
      'Vergelijk pas na de reeks met de werkelijke groep.',
    ],
    safetyNote: _safety,
    sources: const [_cmpFundamentals, _nraPrinciples],
  );

  static final benchrestSupport = TechniqueTopic(
    id: 'benchrest-repeatable-support',
    version: 1,
    title: 'Herhaalbare benchreststeun',
    summary:
        'Bouw voor- en achtersteun zo op dat plaatsing, contact en terugkeer '
        'van reeks tot reeks vergelijkbaar blijven.',
    category: TechniqueCategory.benchrest,
    illustration: TechniqueIllustration.benchrestSupport,
    keyPoints: const [
      'Steun en kaart blijven vóór de reeks stabiel opgesteld.',
      'Contactpunten en schouderdruk worden niet tussen schoten gewijzigd.',
      'Verander in een vergelijking slechts één materiaalvariabele.',
    ],
    commonPitfalls: const [
      'De steun na ieder schot anders belasten.',
      'Tegelijk munitie, steun en vizier wijzigen.',
    ],
    practiceSteps: const [
      'Leg steunpositie en contactpunten vooraf vast.',
      'Schiet korte vergelijkbare reeksen met dezelfde opbouw.',
      'Gebruik een A/B-experiment voor één gecontroleerde wijziging.',
    ],
    safetyNote: _safety,
    sources: const [_cmpFundamentals, _issfAcademy],
  );

  static final shotRoutine = TechniqueTopic(
    id: 'repeatable-shot-routine',
    version: 1,
    title: 'Herhaalbare schotroutine',
    summary:
        'Een korte vaste volgorde maakt afwijkingen zichtbaar zonder dat de '
        'routine een rigide wedstrijdritueel hoeft te worden.',
    category: TechniqueCategory.mentalRoutine,
    illustration: TechniqueIllustration.shotRoutine,
    keyPoints: const [
      'Gebruik enkele duidelijke controlepunten.',
      'Reset bewust na een afgebroken opbouw.',
      'Pas de routine aan wanneer omstandigheden veranderen.',
    ],
    commonPitfalls: const [
      'Doorgaan omdat de routine al gestart is.',
      'Een lange checklist belangrijker maken dan de actuele waarneming.',
    ],
    practiceSteps: const [
      'Schrijf drie tot vijf korte stappen op.',
      'Gebruik dezelfde volgorde voor één training.',
      'Evalueer achteraf welke stap bruikbaar bewijs opleverde.',
    ],
    safetyNote: _safety,
    sources: const [_issfFocus, _cmpFundamentals],
  );

  static final List<TechniqueTopic> all = List.unmodifiable([
    safetyRoutine,
    naturalAlignment,
    standingBalance,
    sightAlignment,
    triggerControl,
    breathing,
    followThrough,
    benchrestSupport,
    shotRoutine,
  ]);
}

List<String> _normalizedList(Iterable<String> values, String field) {
  final normalized = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  if (normalized.isEmpty) throw ArgumentError('$field mag niet leeg zijn.');
  return List<String>.unmodifiable(normalized);
}

String _requiredTechniqueText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

String _validatedUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    throw ArgumentError.value(
      value,
      'url',
      'Alleen HTTPS-bronnen zijn geldig.',
    );
  }
  return uri.toString();
}
