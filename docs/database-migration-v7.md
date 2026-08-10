# Database schema 7: experimentele fotoscore

Schema 7 voegt duurzame conceptscans en provenance voor geassisteerde
handmatige scoring toe. De migratie herberekent geen bestaande score.

## Nieuwe gegevens

- `vision_scan_drafts` bewaart een onafgewerkte foto, kwaliteitsresultaat,
  registratie, kandidaten, review en engineversie.
- `vision_analyses` bewaart de definitieve analyse en review naast een gekoppelde
  reeks en scorefoto.
- `shot_impacts.placement_method` onderscheidt `manual`, `assistedAccepted` en
  `assistedEdited`.
- `shot_impacts.vision_analysis_id` verwijst optioneel naar de analysebron.
- `shot_impacts.positional_uncertainty_mm` bewaart optionele meetonzekerheid.

## Migratie 6 naar 7

1. Maak beide visiontabellen en hun indexen.
2. Voeg de drie impactkolommen toe.
3. Geef iedere bestaande impact `placementMethod = manual`.
4. Laat analyse-ID en positionele onzekerheid `null`.
5. Laat alle bestaande sessies, reeksen, foto's, impacts en scoreaggregaten
   numeriek ongewijzigd.
6. Voer `PRAGMA foreign_key_check` uit binnen de migratietransactie.
7. Rol de volledige upgrade terug wanneer een stap faalt.

## Invarianten

- Een conceptscan is zelfstandig en verwijst nog niet naar een sessie of reeks.
- Een definitieve visionanalyse hoort bij precies één reeks en scorefoto.
- Een analyse kan alleen provenance leveren; de score-engine blijft
  autoritatief.
- Verwijderen van een primaire foto behoudt bevestigde treffers en score, maar
  verwijdert de uitlijning en maakt fotoverwijzingen nullable volgens de
  bestaande mediaregels.
- Een mislukte koppeling laat het concept en de originele foto intact.

## Back-upmanifest 7

Manifest 7 bevat conceptscans, conceptscanfoto's, definitieve analyses,
reviewbeslissingen en impactprovenance. Afgeleide canonieke beelden, masks en
debugoverlays worden niet geback-upt.

Adapters voor manifest 1 tot en met 6 leveren lege visioncollecties en
`placementMethod = manual`. Restore valideert bestands-hashes, contractvelden,
relaties en vrije ruimte vóór vervanging. Een onbekende toekomstige
manifestversie wordt geweigerd. Herstel blijft volledig transactioneel.
