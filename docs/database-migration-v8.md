# Database- en back-upmigratie 8

Versie `0.8.0+1` gebruikt Drift-schema 8 en encrypted backupmanifest 8.
Historische scores worden tijdens deze migratie niet herberekend.

## Nieuwe alignmentvelden

`PhotoAlignments` en visionconcepten bewaren aanvullend:

- `rotationQuarterTurns` (0–3);
- stabiele `alignmentMode`-tekst;
- de volledige anchor-JSON voor reconstructie en audit;
- RMS- en maximumreprojectieresidu;
- planarity/quality-status;
- expliciet bevestigingstijdstip.

Een record uit schema 7 krijgt rotatie 0, modus `fullCard`, lege aanvullende
ankers en status `legacyUnverified`. De bestaande hoeken en homografiematrix
blijven intact. Schema-2 alignmentrecords controleren bij het laden opnieuw of
ankers, kaartmaten en matrix met elkaar overeenkomen.

## Migratiepad

De app ondersteunt ieder pad van schema 1 tot en met 7 naar schema 8. De
SchemaVerifier-test bouwt voor iedere vorige fixture de echte oude database op,
voert de productiemigratie uit en vergelijkt het resultaat met het geëxporteerde
schema 8. Een gevulde schema-7-fixture bewijst daarnaast behoud van sessies,
reeksen, impacts, foto’s, visionconcepten en legacy alignment.

Na migratie wordt `PRAGMA foreign_key_check` uitgevoerd. Iedere fout rolt de
volledige transactie terug.

## Back-upcompatibiliteit

Manifesten 1–7 worden stapsgewijs naar manifest 8 genormaliseerd. Voor restore
en vóór export gelden verplichte runtimevalidators voor targets, rings, bulls,
impact-ID’s, multipliciteit, eindige coördinaten, genormaliseerde fotoparen en
BR50-bullkoppelingen. Een toekomstige manifestversie of corrupte referentie
wordt geweigerd voordat de huidige database wordt vervangen.

De SCB1-container, Argon2id key derivation en AES-256-GCM encryptie veranderen
niet. Mediahashes en vrije ruimte worden zoals voorheen vóór vervanging
gecontroleerd.
