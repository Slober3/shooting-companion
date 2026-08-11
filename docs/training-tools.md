# Leren, oefenen en doelgericht trainen

Versie `0.8.0+1` vervangt de oude tekstlijsten en checkboxrunner door één
volledig offline leer- en trainingssysteem. De snelle handmatige scoreflow
blijft onafhankelijk: geen les, drill, reflectie of plannerstap wordt verplicht.

## Inhoud en scope

De eerste V2-catalogus bevat exact:

- 18 lessen: drie universele, negen voor ISSF 25/50 m precisiepistool en zes
  voor WRABF BR50;
- 12 drills: zes voor precisiepistool en zes voor BR50;
- vier vrije leerpaden: basis en herhaalbaarheid voor precisiepistool, plus
  basis en kaartuitvoering voor BR50.

`Meer > Trainingstools > Leren & oefenen` biedt Start, Leerpaden, Technieken,
Drills en Geschiedenis. Een leerpad ordent de inhoud, maar vergrendelt niets.
Zo kan een ervaren schutter rechtstreeks een referentieles of drill openen.

De gebundelde nl-BE-inhoud staat in
`packages/training/assets/content/v2`. Modellen, JSON-loader en contentlint
staan in `packages/training`; de app hoeft voor inhoud nooit een netwerk aan te
spreken. Iedere historische activiteit bewaart de gebruikte V2-snapshot, zodat
een latere redactionele wijziging een oud trainingsresultaat niet herschrijft.

Een gestart leerpad wordt als `learningPathV2` bewaard. Nieuwe activiteiten
bevatten naast de leerpadstructuur ook voor iedere stap de volledige,
versioned les- of drillsnapshot. Detail en geschiedenis lezen die opgeslagen
inhoud vóór de actuele catalogus. Vroege 0.8-ontwikkelrecords zonder deze
onderdeelsnapshots blijven alleen via een exact overeenkomende catalogusversie
bruikbaar; een gedeeltelijke of tegenstrijdige snapshot wordt afgekeurd.

## Lescontract

Iedere les bevat dezelfde controleerbare onderdelen:

1. leerdoel en toepassingsgebied;
2. veilige beginopstelling;
3. uitvoeringsvolgorde;
4. waarneembare controlepunten;
5. afbreek- en resetcriterium;
6. toegestane variaties en beperkingen;
7. wat de kaart wel en niet bewijst;
8. een direct gekoppelde drill;
9. concrete bronnen en eerlijke reviewstatus.

De detailweergave bouwt dit op in drie informatielagen: `In één minuut`, `Stap
voor stap` en `Waarom en bronnen`. Inhoud zonder schriftelijke coachreview wordt
zichtbaar aangeduid als `Coachreview open`; een praktijktest of bronverwijzing
wordt niet als coachhandtekening voorgesteld.

## Technische visualisaties

Alle platen worden lokaal met vectorprimitieven getekend. Er zijn geen
AI-afbeeldingen, gekopieerde federatietargets of decoratieve stockfoto's.
Platen ondersteunen zoom, pan, genummerde callouts, een voorbeeld/afwijking-
vergelijking en alleen waar technisch geldig links/rechts spiegelen.

Elke plaat heeft een volledige TalkBack-transcriptie. Lijnen, vormen, labels en
tekst dragen de betekenis samen; kleur is nooit het enige onderscheid. Bekende
diagram-ID's hebben een expliciete technische geometrie. Een onbekend ID valt
niet stil terug op een generieke illustratie.

## Drillcontract en echte voortgang

Iedere V2-drill definieert één primaire vaardigheid, setup, fasen, benodigde
reeksen of timeractiviteiten, rust, metingen, minimumsteekproef, stopregels,
reflectie en vervolgstap. Range dry fire is een afzonderlijke modus en kan pas
starten na de veiligheidspoort op een erkende baan.

De runner werkt als volgt:

```text
Voorbereiden
-> veiligheid en setup bevestigen
-> drillactiviteit als concept bewaren
-> bestaande actieve sessie gebruiken of expliciet een nieuwe maken

Uitvoeren
-> actuele fase tonen
-> gewone score-editor of timer openen
-> alleen een werkelijk bevestigde reeks koppelen
-> runner hervatten bij dezelfde fase

Evalueren
-> autoritatieve score-, groeps-, timer- en reflectiedata lezen
-> datakwaliteit en baseline tonen
-> gerichte reflectie bewaren
-> drill voltooien of onderbreken
```

Een scherm sluiten, conceptreeks achterlaten of dubbel tikken maakt geen
voortgang. Concept- en onderbroken activiteiten zijn hervatbaar. Activiteit,
snapshot en gekoppelde bevestigde reeksen blijven transactioneel en idempotent.

## Persoonlijke baseline

Een resultaat is alleen vergelijkbaar bij dezelfde targetprofielversie,
afstand, discipline en, wanneer ingesteld, hetzelfde wapen. Een drill kan
munitie als vaste variabele eisen. De eerste drie geldige uitvoeringen over
minstens twee sessies bouwen de baseline op. Daarna gebruikt de app de mediaan
van maximaal vijf recente geldige uitvoeringen.

Tot die minimumdata bestaat toont de app `Baseline wordt opgebouwd`, niet een
verzonnen succes- of faaloordeel. Standaard is doorgang gebaseerd op twee
bruikbare uitvoeringen binnen de laatste drie. Drills kunnen zelf definiëren of
hoger, lager of stabieler beter is. Datakwaliteitswaarschuwingen blokkeren een
stellige vergelijking.

## Deterministische trainingsplanner

De planner vraagt discipline, focus, 30/45/60 minuten en munitiebudget, plus
optioneel wapen en munitieprofiel. De uitvoer is deterministisch en bestaat uit
veiligheid/setup, een korte relevante les, één of twee passende drills,
rust/review en een afsluitende reflectie. Tijd en munitie worden nooit boven het
gevraagde budget gepland.

Een plan en leerpad gebruiken de bestaande generieke `TrainingActivities` en
`TrainingActivitySeriesLinks` met kinds `trainingPlan`, `guidedDrillV2` en
`learningPathV2`. Daarom blijven databaseschema en encrypted back-upmanifest
versie 8. Back-ups bewaren definitieversie, gegenereerde stappen, actuele stap,
gekoppelde reeksen, metrics, leerpadinhoud en voltooiingsstatus.

## Veiligheids- en bewijsgrens

- De baanverantwoordelijke en lokale regels gaan altijd voor.
- De telefoon wordt pas bediend nadat het wapen volgens de baanprocedure veilig
  is gemaakt en de gebruiker die toestand opnieuw heeft gecontroleerd.
- Dry fire wordt in deze catalogus alleen als range dry fire aangeboden.
- Een trefbeeld beschrijft positie en spreiding, maar bewijst niet op zichzelf
  een oorzaak in greep, trekker, houding, aandacht of omstandigheden.
- BR50-contact- en steunstrategieën worden als te testen variaties beschreven,
  niet als één universeel recept.
- De experimentele OpenCV-fotoscore is geen invoerbron voor lessen, drills,
  baselines of plannen en krijgt in 0.8 geen nieuwe nauwkeurigheidsclaim.

## Redactionele bronnen

- [ISSF Education Reform Plan](https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1): disciplinegebonden leerinhoud, theorie plus praktijk, zelfevaluatie, doelen, planning en feedback.
- [CMP Guide to Junior Pistol Shooting](https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf): veilige baanprocedure en de gecoördineerde basis van houding, greep, vizier, armbeweging, ademhaling, trekkerdruk en follow-through.
- [CMP Safety](https://thecmp.org/safety/): veilige wapenhandeling; de app vervangt geen lokale baancommando's.
- [WRABF Rules](https://www.wrabf.com/WRABF%20Rules.htm): officiële discipline-, kaart- en protocolgrenzen voor BR50, niet een universele techniekhandleiding.

Brononderbouwde inhoud kan met `Coachreview open` worden geleverd. Alleen een
schriftelijk vastgelegde, disciplinespecifieke review mag de status naar
`reviewed` veranderen; een inhoudelijke wijziging maakt altijd een nieuwe
contentversie.
