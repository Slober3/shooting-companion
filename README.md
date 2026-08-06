# Shooting Companion

Shooting Companion is een Android-first, volledig offline trainingsdagboek voor
precisieschutters. Sessies, reeksen, kaartfoto's, scores en analyses blijven op
het toestel. De app gebruikt geen account, advertenties, telemetrie of
internetpermission.

## Huidige status

Versie `0.6.0` behoudt de snelle puntplaatsing van 0.3 en voegt lokale,
verklaarbare analyse, optionele coaching, trainingstools en een afzonderlijke
experimentele fotoscoreflow toe:

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
- een begeleide akoestische live-firetimer plus par-, cadans- en externe
  invoermodus, reviewbare events, lokale geschiedenis en reekskoppeling;
- gestructureerde timerexports en compacte timerinformatie in het PDF-rapport;
- `Meer > Experimentele fotoscore` voor één schone ISSF Precision-kaart met
  .22 LR, met lokale kwaliteitscontrole, automatische kaartregistratie,
  klassieke OpenCV-gatkandidaten en verplichte menselijke review;
- hervatbare conceptscans, handmatige vierpuntsfallback en transactionele
  koppeling aan een actieve of nieuwe snelle sessie;
- candidate-provenance, onzekerheid en reviewbeslissingen in schema/back-up 7;
- systeem/licht/donker met vier lokaal opgeslagen kleurpaletten;
- CSV, Unicode-PDF met ingebedde fonts en AES-256-GCM/Argon2id-back-up;
- migratie en back-upcompatibiliteit voor lokale gegevens uit versie 0.1;
- databaseschema 7 en back-upmanifest 7, met import van v1-v6-back-ups.

De live-firetimer vraagt microfoontoegang pas nadat de gebruiker de begeleide
toestelcontrole start. Audio wordt tijdens de zichtbare run in het geheugen
verwerkt; alleen gecontroleerde eventtijden worden opgeslagen. De meting is een
trainingshulpmiddel, geen gecertificeerde wedstrijdtimer. De fysieke
validatiematrix en grenzen staan in
[`docs/shot-timer.md`](docs/shot-timer.md).

De fotoscore is nadrukkelijk een experiment en geen automatische eindscore. Hoge
en middelmatige kandidaten zijn slechts voorstellen; lage kandidaten tellen
standaard niet mee. De gebruiker bevestigt, verplaatst, verwijdert of voegt
punten toe voordat de bestaande deterministische Dart-score-engine ringwaarde,
X-count, totaal en percentage berekent. Handmatige scoring blijft altijd
beschikbaar. De huidige detector heeft nog geen validatieset van voldoende
omvang om een betrouwbaarheidsclaim te rechtvaardigen.

## Snel starten

Vereisten:

- Flutter 3.44.8 / Dart 3.12.2;
- Android Studio met Android SDK;
- Android 13 of hoger voor het toestel;
- Java 17.
- de vastgezette OpenCV 4.13.0 Android SDK voor een vision-enabled APK.

```powershell
cd apps/mobile
flutter pub get
dart run build_runner build
flutter test
flutter run
```

De app declareert camera- en microfoontoegang. Microfoontoegang wordt pas in de
begeleide live-firetimer gevraagd en de audiostroom wordt uitsluitend tijdens
de zichtbare run in het geheugen verwerkt.

De officiële OpenCV-SDK kan reproduceerbaar worden klaargezet met:

```powershell
$env:OPENCV_ANDROID_SDK = & .\tools\setup_opencv_android.ps1
cd apps/mobile
flutter build apk --release --target-platform android-arm64
```

Het script controleert SHA-256
`edfda20fdf65d0bd45391d168ec5261dd30b600b00279c4d910d7f1c3e020f0f`
voordat de SDK wordt gebruikt. Zonder een OpenCV-capabele native library faalt
de detector gesloten en blijft handmatig uitlijnen/scoren beschikbaar.

Controleer voor een release ook de verpakte Android-permissies:

```powershell
flutter build apk --release
& "$env:ANDROID_HOME/build-tools/36.0.0/aapt2.exe" dump permissions `
  build/app/outputs/flutter-apk/app-release.apk
```

De tweede opdracht moet `CAMERA` en `RECORD_AUDIO` tonen en mag Androids interne
receiver- en vibratiepermission tonen. `INTERNET`, opslag-, locatie- en
netwerkstatuspermissions blijven verboden. De timer is een controleerbaar
trainingshulpmiddel en geen gecertificeerde wedstrijdtimer.

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
- `packages/vision_ffi` — annuleerbare Flutter-FFI-adapter en Androidbuildhook.
- `packages/vision_research` — versleutelde, opgeschoonde onderzoeks-export.
- `native/vision_core` — C++17, C-ABI v2 en klassieke OpenCV-pipeline.
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
OpenCV 4.13.0 wordt onder Apache License 2.0 gebruikt; versie, bron en checksum
staan in `THIRD_PARTY_NOTICES.md` en `docs/vision-foundation.md`.
