# Experimentele fotoscore

## Productgrens

Versie 0.6 bevat een volledig lokale, experimentele fotoscore voor één
ondersteunde combinatie:

- ISSF 25 m Precision / 50 m Pistol;
- .22 LR;
- één achteraffoto van een relatief schone kaart;
- expliciete controle en correctie door de gebruiker.

De native detector maakt alleen voorstellen. Een `VisionCandidateImpact` is
nooit een bevestigde `ShotImpact`. Alleen de bestaande Dart-score-engine
berekent ringwaarden en totalen nadat de gebruiker de zichtbare selectie heeft
bevestigd. Een update van een detector herberekent nooit historische scores.

De app gebruikt geen ML, OCR, internet, modeldownload, telemetrie of on-device
training. Exact overlappende schoten, missers buiten het papier en het
onderscheid tussen oude en nieuwe gaten blijven handmatige beslissingen.

## Architectuur

```text
image_picker en interne opslag
        |
        v
packages/vision_api          schema-v2 contracten
        |
        v
packages/vision_ffi          isolate, cancellation en C-binding
        |
        v
stabiele C ABI v2            create/run/cancel/destroy job
        |
        v
native/vision_core           C++17 en OpenCV 4.13.0
        |
        v
VisionScanDraft              duurzaam concept en review
        |
        v
handmatige review-editor     enige bevestigingsgrens
        |
        v
Dart-score-engine            autoritatieve score
```

OpenCV wordt bij Android-builds uit de officiële, vastgezette 4.13.0 SDK
statisch in `libshooting_companion_vision.so` gelinkt. Alleen `core`, `imgproc`
en `imgcodecs` worden gebruikt. Release bouwt voor `arm64-v8a`; debug ondersteunt
ook `x86_64`. Wanneer de native library of de OpenCV-capability ontbreekt, stopt
de analyse eerlijk met een begrijpelijke melding. De geometry-only backend mag
nooit automatische kandidaten voorstellen.

## Contract en coördinaten

Visioncontract v2 gebruikt ondubbelzinnige coördinaten:

- `sourceImageXNormalized` en `sourceImageYNormalized` verwijzen naar de
  originele, EXIF-vrije foto;
- `cardXMm` en `cardYMm` verwijzen naar fysieke millimeters op het kaartvlak;
- `orderedSourceCornersNormalized` bewaart de vier bronhoeken;
- `sourceNormalizedToCardMmHomography` maakt de omzetting reproduceerbaar.

Bij handmatige heruitlijning worden kandidaten opnieuw vanuit hun originele
fotocoördinaten naar millimeters geprojecteerd. Hun scoregrenswaarschuwing wordt
eveneens opnieuw berekend. Zoom en pan wijzigen nooit deze brongegevens.

Iedere analyse bewaart provenance:

- contractschema, C-ABI en engineversie;
- backend en capabilities;
- algoritmeversies voor kwaliteit, registratie en detectie;
- kwaliteitsmetingen, registratie en waarschuwingen;
- vertrouwen, redenen en positionele onzekerheid per kandidaat;
- alle reviewbeslissingen.

## Native jobmodel

De ABI biedt `createJob`, `runJob`, `cancelJob` en `destroyJob`. De pipeline
controleert annulering tussen kwaliteitscontrole, registratie, perspective
warp en kandidatendetectie. Bij navigeren uit de flow worden late resultaten
genegeerd, tijdelijke gegevens opgeruimd en geen gedeeltelijke analyse
opgeslagen.

Resultaatstrings hebben expliciet C-ABI-eigenaarschap. De FFI-adapter verstuurt
alleen serializeerbare waarden over de isolategrens en reconstrueert de
Dart-contracten aan de ontvangende kant.

## Beeldverwerking

De klassieke pipeline voert uit:

1. resolutie-, scherpte-, contrast- en belichtingscontrole;
2. zoeken naar papiercontour, vierhoek en scoringsringen;
3. profielcontrole en homografie;
4. canonieke warp met vaste pixels per millimeter;
5. profielgebaseerd masker voor gedrukte ringlijnen;
6. onafhankelijke signalen voor donkere kern, vezelrand, lokaal contrast,
   morfologie, vorm en bekende .22-diameter;
7. confidenceclassificatie met controleerbare redenen.

Hoge en middelmatige kandidaten worden aanvankelijk opgenomen maar blijven
zichtbaar gemarkeerd. Lage kandidaten zijn standaard niet opgenomen. Kandidaten
bij een scoringslijn krijgen altijd een grenswaarschuwing. De detector maakt
geen kunstmatige gaten om een verwacht aantal te bereiken.

## Concepten en transactioneel koppelen

Een originele scan wordt onmiddellijk duurzaam en EXIF-vrij opgeslagen. Een
concept bewaart foto, profiel, kwaliteit, registratie, kandidaten en review.
Appsluiting of analysefout verliest dit concept niet.

`commitReviewedVisionScan` valideert doel, kaliber en bestemming en schrijft in
één transactie de sessie/reeks, scorefoto, uitlijning, analyse, review,
bevestigde impacts en scoreaggregaten. Bij een fout blijven conceptscan, foto en
bestaande sessies intact. Bevestigde impacts registreren of zij ongewijzigd of
bewerkt uit een voorstel kwamen.

## Build

Zet voor een Android-build:

```powershell
$env:OPENCV_ANDROID_SDK = 'C:\pad\naar\OpenCV-android-sdk'
flutter build apk --release --target-platform android-arm64
```

De SDK-versie is 4.13.0. De verwachte SHA-256 van het officiële Android-archief
is:

```text
edfda20fdf65d0bd45391d168ec5261dd30b600b00279c4d910d7f1c3e020f0f
```

CI downloadt dit archief, controleert de hash, bouwt de APK en verifieert dat de
native arm64-library aanwezig is. De app downloadt OpenCV nooit tijdens gebruik.

De geometry-only C++-tests blijven afzonderlijk bestaan om contract- en
homografielogica te testen zonder OpenCV. Zij zijn geen bewijs van
detectienauwkeurigheid.

## Privacy en auteursrecht

- Geen persoonlijke kaartfoto's, exports of back-ups worden gecommit.
- Foto's staan alleen in interne appopslag en worden niet geüpload.
- EXIF en GPS worden bij import verwijderd.
- Afgeleide masks en tijdelijke warps zijn geen autoritatieve data en gaan niet
  in de back-up.
- De app bevat geen doelkaartfoto; zij gebruikt declaratieve ISSF-geometrie.

## Validatie en eerlijke claim

De technische integratie maakt de detector nog niet bewezen betrouwbaar. Voor
publieke activering zijn minimaal 100 onafhankelijke foto's, 500 geannoteerde
.22-gaten en drie Androidtoestellen nodig. De experimentele ondergrenzen zijn:

- registratie minstens 95% op door kwaliteitscontrole geaccepteerde foto's;
- mediane positionele fout maximaal 1,5 mm;
- precisie minstens 90% en recall minstens 85% voor geïsoleerde gaten;
- geen lage kandidaat die stil meetelt;
- P95 maximaal acht seconden op het primaire Samsungtoestel.

Tot die set is verzameld en gemeten, blijft de UI `Experimenteel` tonen, worden
geen nauwkeurigheidsclaims gemaakt en blijft handmatige scoring de betrouwbaarste
route. Synthetische fixtures bewijzen regressies en geometrie, maar vervangen
geen echte validatiefoto's.

Buiten de eerste scope vallen BR50, andere kaartprofielen en kalibers, ML, OCR,
voor/na-vergelijking, wedstrijdcertificering en automatische reconstructie van
exact overlappende schoten.
