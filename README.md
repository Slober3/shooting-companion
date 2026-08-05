# Shooting Companion

Shooting Companion is een Android-first, volledig offline trainingsdagboek voor
precisieschutters. Sessies, reeksen, kaartfoto's, scores en analyses blijven op
het toestel. De app gebruikt geen account, advertenties, telemetrie of
internetpermission.

## Huidige status

Versie `0.5.0` behoudt de snelle puntplaatsing van 0.3 en voegt lokale,
verklaarbare analyse, optionele coaching en gestructureerde trainingstools toe:

- lokale bibliotheken voor wapens, kalibers, munitielots, standen en kaarten;
- bibliotheekitems bekijken, bewerken, dupliceren en veilig verwijderen;
- gebruikte bibliotheekitems archiveren en herstellen zonder historische
  sessies, filters of rapportnamen te verliezen;
- een sessie en score-editor openen met één tik;
- sessies en reeksen hervatten, aanpassen en zichtbaar verwijderen;
- atomair opgeslagen conceptreeksen met autosave;
- afzonderlijke modi voor plaatsen en bewerken, zodat een nabij punt nooit een
  nieuwe treffer onderschept;
- pinch-zoom, pan, zoomknoppen, precisiekruis, puntenlijst en echte undo;
- visueel plaatsen, verslepen en vermenigvuldigen van treffers en missers;
- versioned ISSF 2026-profielen voor 25 m Precision / 50 m Pistol en 25 m Rapid Fire;
- een ingebouwd WRABF BR50-profiel met 25 handmatig scorebare wedstrijdroosjes,
  proefroosjes, laagste-scorebeleid, X-count en straf voor extra schoten;
- scores en maximum op basis van het werkelijk geregistreerde schotaantal;
- handmatig scoren op een getekende kaart of een zelf uitgelijnde kaartfoto;
- meerdere sessie- en reeksfoto's met een onveranderlijk origineel;
- compacte Logboekfilters en één geaggregeerde SQLite-query zonder query per rij;
- groepsanalyse met centroid, bias, extreme spread, mean radius, R50/R90,
  spreidingsellips, MOA/millirad en target-aware BR50-normalisatie;
- één gedeelde groepsgrafiek met verklaarde 1-sigma-ellips, databasis, legenda
  en een zichtbare extreme-spreadlijn tussen het verst uit elkaar liggende paar;
- analyse per afzonderlijke reeks en per volledig standbezoek, plus een
  expliciete keuze van historische reeksen en vergelijkingen;
- aantikbare metriekkaarten met uitleg over berekening, interpretatie,
  databasis en beperkingen;
- reproduceerbare potential-scoreanalyse en voorzichtige subgroepsuggesties die
  nooit treffers of scores wijzigen;
- coachkaarten volgens `waarneming -> bewijs -> mogelijke verklaringen -> test`,
  met strikte minimumsteekproeven en lokale feedback;
- optionele vijfsecondenreflectie, persoonlijke doelen en volledig uit te
  schakelen coachmodus;
- een offline drillbibliotheek, A/B-experimentplanner en viziercalculator;
- een offline timer met par-, cadans- en externe invoermodus, reviewbare events,
  presets, lokale geschiedenis en optionele reekskoppeling;
- gestructureerde timerexports en compacte timerinformatie in het PDF-rapport;
- systeem/licht/donker met vier lokaal opgeslagen kleurpaletten;
- CSV, Unicode-PDF met ingebedde fonts en AES-256-GCM/Argon2id-back-up;
- migratie en back-upcompatibiliteit voor lokale gegevens uit versie 0.1;
- databaseschema 6 en back-upmanifest 6, met import van v1-v5-back-ups.

De akoestische live-firetimer zit als ontwikkelbasis in de broncode, maar is in
de stabiele `0.5.0+1`-build compile-time uitgeschakeld. Er is geen zichtbare
akoestische route en de release vraagt geen microfoontoegang. Publieke activatie
volgt pas na de volledige fysieke vergelijking met een referentietimer die in
[`docs/shot-timer.md`](docs/shot-timer.md) is vastgelegd. De geplande
analysehotfix `0.4.2` is niet afzonderlijk gepubliceerd; hij is in deze
`0.5.0`-release geïntegreerd.

Er is nog geen automatische trefferdetectie in de app. De schutter duidt iedere
treffer of misser expliciet aan; de deterministische score-engine berekent daarna
ringwaarde, X-count, totaal en percentage. De repository bevat wel afzonderlijke
visioncontracten, een fail-closed native onderzoeksbasis en een versleutelde,
privacyveilige `.scvision`-export. Die onderdelen maken geen score en krijgen pas
een gebruikersflow nadat de vastgelegde validatiedrempels zijn gehaald.

## Snel starten

Vereisten:

- Flutter 3.44.8 / Dart 3.12.2;
- Android Studio met Android SDK;
- Android 13 of hoger voor het toestel;
- Java 17.

```powershell
cd apps/mobile
flutter pub get
dart run build_runner build
flutter test
flutter run
```

De stabiele app declareert alleen cameratoegang. Microfoontoegang is in
`0.5.0+1` verboden in het release-APK. Controleer voor een release:

```powershell
flutter build apk --release
& "$env:ANDROID_HOME/build-tools/36.0.0/aapt2.exe" dump permissions `
  build/app/outputs/flutter-apk/app-release.apk
```

De tweede opdracht mag `CAMERA` en Androids interne receiver-permission tonen,
maar geen `RECORD_AUDIO`, `INTERNET`, opslag- of netwerkstatuspermission.

Interne akoestische validatie kan uitsluitend in een development/profile build:

```powershell
flutter run --dart-define=SC_ENABLE_ACOUSTIC_TIMER=true
```

De debug- en profile-manifests bevatten daarvoor microfoontoegang; het
release-manifest bewust niet. Dit opt-inpad is geen nauwkeurigheidsclaim en mag
niet als stabiele APK worden verspreid.

## Monorepo

- `apps/mobile` — Flutter Android-app en Drift-database.
- `packages/domain` — platformonafhankelijke domeintypen.
- `packages/scoring` — deterministische score- en spreidingsberekening.
- `packages/target_profiles` — officiële, versioned kaartdefinities.
- `packages/photo_geometry` — reproduceerbare vierpuntsuitlijning en homografie.
- `packages/analysis` — pure, afgeleide groeps- en cohortanalyse.
- `packages/coaching` — lokale, bewijsgebonden coachregels zonder generatief model.
- `packages/training` — versioned drills, experimentplanning en vizierberekening.
- `packages/shot_timer` — pure timerlogica, testklok en lokale Android-audio-engine.
- `packages/vision_api` — immutable onderzoekscontracten voor kandidaten.
- `packages/vision_research` — versleutelde, opgeschoonde onderzoeks-export.
- `native/vision_core` — C++/C-ABI/CLI-basis met optionele OpenCV-backend.
- `docs` — architectuur, scoreregels, back-up en releasebeleid.

## Belangrijke grens

Twee projectielen die exact door hetzelfde gat gaan zijn visueel niet automatisch
te onderscheiden. Geef daarom zelf de multipliciteit aan. Een schot buiten de
kaart wordt als `Misser / 0` geregistreerd.

## Licentie

De broncode is MIT. Ingebedde Noto Sans-fonts vallen onder de SIL Open Font
License 1.1; zie `THIRD_PARTY_NOTICES.md`. Doelkaartafmetingen zijn vastgelegd
als feitelijke geometrie uit het
[ISSF Rule Book 2026](https://backoffice.issf-sports.org/getfile.aspx?file=ISSF-Rule-Book-2026-Edition-2025-First-Print-12-2025-Effective-1-January-2026.pdf&inst=455&mod=docf&pane=1).
ISSF-beeldmateriaal of logo's worden niet meegeleverd. De BR50-weergave gebruikt
uitsluitend een neutrale geometrische trainingsrenderer op basis van de
[WRABF-regels](https://www.wrabf.com/WRABF%20Rules.htm) en
[doelkaartreferentie](https://www.wrabf.com/WRABF%20Targets.htm); er wordt geen
officiële printkaart, federatiestijl of verkopersafbeelding gebundeld.
