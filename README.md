# Shooting Companion

Shooting Companion is een Android-first, volledig offline trainingsdagboek voor
precisieschutters. Sessies, reeksen, kaartfoto's, scores en analyses blijven op
het toestel. De app gebruikt geen account, advertenties, telemetrie of
internetpermission.

## Huidige status

Versie `0.2.0` focust op een snelle, rustige en volledig handmatige workflow:

- lokale bibliotheken voor wapens, kalibers, munitielots, standen en kaarten;
- een sessie en score-editor openen met één tik;
- sessies en reeksen hervatten, aanpassen en zichtbaar verwijderen;
- atomair opgeslagen conceptreeksen met autosave;
- visueel plaatsen, verslepen en vermenigvuldigen van treffers en missers;
- versioned ISSF 2026-profielen voor 25 m Precision / 50 m Pistol en 25 m Rapid Fire;
- scores en maximum op basis van het werkelijk geregistreerde schotaantal;
- handmatig scoren op een getekende kaart of een zelf uitgelijnde kaartfoto;
- meerdere sessie- en reeksfoto's met een onveranderlijk origineel;
- compact logboek, scoretrend en vergelijkingen per kaart/afstand;
- CSV, PDF en AES-256-GCM/Argon2id-back-up en volledig herstel;
- migratie en back-upcompatibiliteit voor lokale gegevens uit versie 0.1.

Er is geen automatische trefferdetectie. De schutter duidt iedere treffer of
misser expliciet aan; de deterministische score-engine berekent daarna ringwaarde,
X-count, totaal en percentage. Daardoor blijft iedere score controleerbaar.

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

De app declareert alleen cameratoegang. Controleer voor een release:

```powershell
flutter build apk --release
& "$env:ANDROID_HOME/build-tools/36.0.0/aapt2.exe" dump permissions `
  build/app/outputs/flutter-apk/app-release.apk
```

De tweede opdracht mag `CAMERA` en Androids interne receiver-permission tonen,
maar geen `INTERNET`, audio-, opslag- of netwerkstatuspermission.

## Monorepo

- `apps/mobile` — Flutter Android-app en Drift-database.
- `packages/domain` — platformonafhankelijke domeintypen.
- `packages/scoring` — deterministische score- en spreidingsberekening.
- `packages/target_profiles` — officiële, versioned kaartdefinities.
- `packages/photo_geometry` — reproduceerbare vierpuntsuitlijning en homografie.
- `docs` — architectuur, scoreregels, back-up en releasebeleid.

## Belangrijke grens

Twee projectielen die exact door hetzelfde gat gaan zijn visueel niet automatisch
te onderscheiden. Geef daarom zelf de multipliciteit aan. Een schot buiten de
kaart wordt als `Misser / 0` geregistreerd.

## Licentie

MIT. Doelkaartafmetingen zijn vastgelegd als feitelijke geometrie uit het
[ISSF Rule Book 2026](https://backoffice.issf-sports.org/getfile.aspx?file=ISSF-Rule-Book-2026-Edition-2025-First-Print-12-2025-Effective-1-January-2026.pdf&inst=455&mod=docf&pane=1).
ISSF-beeldmateriaal of logo's worden niet meegeleverd.
