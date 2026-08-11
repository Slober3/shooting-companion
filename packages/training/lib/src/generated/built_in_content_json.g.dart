// GENERATED CODE - DO NOT MODIFY BY HAND.
// Run: dart run tool/embed_content.dart

const builtInTechniquesJson = r'''{
  "schemaVersion": 2,
  "locale": "nl-BE",
  "lessons": [
    {
      "id": "safe-range-phone-routine",
      "version": 2,
      "title": "Veilige baanroutine en telefoongebruik",
      "shortPromise": "Maak appgebruik een afzonderlijke, veilige handeling in plaats van een afleiding aan de vuurlijn.",
      "category": "safety",
      "disciplines": ["universal"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 7,
      "prerequisites": [],
      "applicability": ["Voor iedere training waarbij de telefoon aan of nabij de vuurlijn wordt gebruikt.", "Lokale baanregels en bevelen van de baanverantwoordelijke gaan altijd voor."],
      "sections": [
        {"type":"overview","title":"Eén veilige scheiding","paragraphs":["Schieten en de app bedienen zijn twee afzonderlijke toestanden. De overgang gebeurt pas nadat het wapen volgens de baanregels veilig is gemaakt en de schutter de toestand zelf heeft gecontroleerd."],"steps":[],"sourceIds":["cmp-safety"]},
        {"type":"setup","title":"Vaste plaats voor de telefoon","paragraphs":["Leg de telefoon buiten de bewegingslijn van wapen en munitie, met het scherm leesbaar zonder over het wapen te reiken."],"steps":[],"sourceIds":["cmp-safety"]},
        {"type":"sequence","title":"Vaste overgang","paragraphs":[],"steps":["Volg het baanbevel en houd de monding in veilige richting.","Maak het wapen veilig zoals de baan voorschrijft en controleer kamer en magazijn.","Leg het wapen stabiel neer; raak daarna pas de telefoon aan.","Stop appgebruik onmiddellijk bij een nieuw baanbevel en hervat pas na een nieuwe veiligheidscontrole."],"sourceIds":["cmp-safety"]},
        {"type":"observe","title":"Controleerbare tekenen","paragraphs":["Je kunt zonder twijfel aanwijzen waar het veilige wapen ligt, waar de monding heen wijst en welke handeling eerst volgt bij een baanbevel."],"steps":[],"sourceIds":["cmp-safety"]},
        {"type":"abortOrReset","title":"Onderbreking betekent opnieuw controleren","paragraphs":["Na een onderbreking, vraag van een andere schutter of verplaatste uitrusting begin je opnieuw bij de wapentoestand. Vertrouw niet op je herinnering aan de vorige controle."],"steps":[],"sourceIds":["cmp-safety"]},
        {"type":"variation","title":"Baanregels verschillen","paragraphs":["Een veiligheidsvlag, open grendel, verwijderde magazijnhouder of afzonderlijke veilige tafel kan verplicht zijn. Gebruik de lokale procedure zonder ze door deze les te vervangen."],"steps":[],"sourceIds":["cmp-safety"]},
        {"type":"evidence","title":"Waarom deze les begrensd is","paragraphs":["De bron beschrijft algemene veilige wapenbehandeling. Ze bepaalt niet de concrete commando's of infrastructuur van jouw stand."],"steps":[],"sourceIds":["cmp-safety"]},
        {"type":"practice","title":"Oefen zonder tijdsdruk","paragraphs":[],"steps":["Doorloop de overgang één keer vóór de eerste reeks.","Spreek met een baanverantwoordelijke af waar de telefoon mag liggen.","Start daarna pas de gekoppelde veiligheidsstap in een drill."],"sourceIds":["cmp-safety"]},
        {"type":"limits","title":"Geen digitale handeling is dringend","paragraphs":["Een autosave, timer of melding is nooit een reden om een veiligheidsstap over te slaan. Laat desnoods de app wachten."],"steps":[],"sourceIds":["cmp-safety"]}
      ],
      "diagramIds": ["safe-phone-workflow"],
      "selfChecks": [{"prompt":"Kan ik de telefoon bereiken zonder over het wapen te reiken?","observableSuccess":"De telefoon heeft een vaste plaats en het wapen is aantoonbaar veilig vóór iedere bediening.","resetIf":"De telefoon of uitrusting is verplaatst, of een baanbevel onderbreekt de volgorde."}],
      "linkedDrillIds": ["pistol-blank-sight-picture@2", "br50-five-record-bulls@2"],
      "safetyCallouts": [{"title":"Baanregels eerst","instruction":"Volg altijd de baanverantwoordelijke; maak het wapen veilig vóór je de app bedient."}],
      "references": [{"id":"cmp-safety","title":"Safety","url":"https://thecmp.org/safety/","publisher":"Civilian Marksmanship Program","documentEdition":"webpagina, geraadpleegd 2026-08-10","locator":"secties ‘Rules for Safe Gun Handling’ en ‘The Goal: No Gun Accidents’"}],
      "review": {"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"CMP safety, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "reading-target-evidence",
      "version": 2,
      "title": "Wat een trefbeeld wel en niet kan aantonen",
      "shortPromise": "Lees positie en spreiding als metingen, zonder één technisch verhaal aan een groep op te leggen.",
      "category": "measurement",
      "disciplines": ["universal"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 9,
      "prerequisites": ["safe-range-phone-routine@2"],
      "applicability": ["Na een bevestigde reeks met voldoende positionele treffers.", "Voor vergelijking alleen wanneer kaart, afstand en relevante uitrusting gelijk zijn."],
      "sections": [
        {"type":"overview","title":"Beschrijving vóór verklaring","paragraphs":["Een kaart kan tonen waar de treffers liggen, hoe ruim ze verspreid zijn en hoe herhaalbaar reeksen zijn. Ze registreert niet rechtstreeks greepdruk, trekkerbeweging, visuele aandacht, wind of schotvolgorde."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"setup","title":"Maak de reeks vergelijkbaar","paragraphs":["Controleer kaartversie, afstand, wapen, munitie en werkelijk schotaantal voordat je twee resultaten naast elkaar zet."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"sequence","title":"Lees in drie stappen","paragraphs":[],"steps":["Benoem eerst het groepscentrum ten opzichte van het richtpunt.","Benoem daarna groepsgrootte en richting van de spreiding.","Noteer pas daarna mogelijke verklaringen als hypotheses die nog getest moeten worden."],"sourceIds":["issf-education"]},
        {"type":"observe","title":"Bruikbare observaties","paragraphs":["'Het groepscentrum ligt links' en 'de verticale spreiding is groter' zijn controleerbaar. 'Ik trok de trekker verkeerd' is zonder aanvullende waarneming geen conclusie uit de kaart."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"abortOrReset","title":"Stop bij slechte data","paragraphs":["Trek geen technische conclusie uit een onvolledige kaart, onbekende missers, gemengde reeksen of een uitlijning met waarschuwing. Herstel eerst de databasis."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"variation","title":"Score en groep beantwoorden iets anders","paragraphs":["Een compacte groep buiten het centrum kan laag scoren; een grotere maar gecentreerde groep kan meer punten halen. Bekijk daarom score, centrum en spreiding afzonderlijk."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"evidence","title":"Onderwijs, geen diagnosekaart","paragraphs":["ISSF-coachonderwijs combineert techniek, praktische opdrachten, zelfevaluatie en feedback. Dat ondersteunt een bredere beoordeling dan alleen de inslagpositie."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"practice","title":"Maak één neutrale samenvatting","paragraphs":[],"steps":["Open een recente reeks.","Schrijf één zin over centrum en één over spreiding.","Voeg hoogstens twee mogelijke verklaringen toe en koppel er een test aan."],"sourceIds":["issf-education"]},
        {"type":"limits","title":"Geen foutendiagnose uit kwadranten","paragraphs":["De app koppelt een kwadrant nooit rechtstreeks aan één technische fout. Dezelfde inslag kan door meerdere combinaties van materiaal, houding, waarneming en uitvoering ontstaan."],"steps":[],"sourceIds":["issf-education"]}
      ],
      "diagramIds": ["target-evidence-layers"],
      "selfChecks": [{"prompt":"Heb ik observatie en verklaring van elkaar gescheiden?","observableSuccess":"De observatie bevat alleen meetbare positie, spreiding of score; iedere verklaring staat als te testen mogelijkheid.","resetIf":"De reeks bevat gemengde omstandigheden, missers zonder context of onzekere foto-uitlijning."}],
      "linkedDrillIds": ["pistol-centre-vs-spread@2", "br50-five-block-card@2"],
      "safetyCallouts": [{"title":"Analyse pas na veilig afleggen","instruction":"Bekijk kaart of telefoon alleen wanneer de baanprocedure dit toestaat en het wapen veilig is."}],
      "references": [{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 7 en pp. 9-12: profiling, doelen, instructie, feedback, praktijkplanning en zelfevaluatie"}],
      "review": {"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF Education Reform Plan, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "one-variable-comparison",
      "version": 2,
      "title": "Eén variabele betrouwbaar vergelijken",
      "shortPromise": "Maak van een vermoeden een kleine, controleerbare proef zonder meerdere veranderingen door elkaar te halen.",
      "category": "measurement",
      "disciplines": ["universal"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 10,
      "prerequisites": ["reading-target-evidence@2"],
      "applicability": ["Voor materiaal-, houding- of routinevergelijkingen.", "Niet gebruiken om na één reeks een winnaar of oorzaak aan te wijzen."],
      "sections": [
        {"type":"overview","title":"Verander maar één ding","paragraphs":["Leg variant A en B vooraf vast. Kaart, afstand, wapen, schotaantal, rust en beoordelingsmethode blijven gelijk, behalve de ene gekozen variabele."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"setup","title":"Schrijf het contrast letterlijk op","paragraphs":["Gebruik concrete labels, bijvoorbeeld 'lot A / lot B' of 'steunmarkering zichtbaar / opnieuw opgebouwd'. Vermijd brede labels zoals 'oude / nieuwe techniek'."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"sequence","title":"Gebruik A-B-B-A","paragraphs":[],"steps":["Schiet een geldige reeks met A.","Schiet twee geldige reeksen met B.","Sluit af met A.","Vergelijk pas wanneer beide varianten voldoende positionele treffers hebben."],"sourceIds":["issf-education"]},
        {"type":"observe","title":"Meet dezelfde uitkomsten","paragraphs":["Kies vooraf één primaire metric, zoals mean radius, en hoogstens één secundaire, zoals groepscentrum. Voeg waargenomen omstandigheden apart toe."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"abortOrReset","title":"Ongeldige vergelijking","paragraphs":["Stop wanneer afstand, kaart, wind, steun, munitie of vermoeidheid buiten de gekozen variabele wezenlijk verandert. Markeer de run als onbetrouwbaar in plaats van de uitkomst passend te verklaren."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"variation","title":"Volgorde kan later wisselen","paragraphs":["Bij herhaling kan B-A-A-B een volgorde-effect helpen beoordelen. Meng de volgordes niet binnen één ongedocumenteerde activiteit."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"evidence","title":"Een vergelijking blijft beschrijvend","paragraphs":["Vier reeksen kunnen een praktisch signaal geven, maar bewijzen geen algemene superioriteit. De app toont daarom steekproefgrootte en onzekerheid."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"practice","title":"Ontwerp één proef","paragraphs":[],"steps":["Kies een variabele die je werkelijk kunt vasthouden.","Kies één meetwaarde.","Plan A-B-B-A met voldoende rust.","Leg vooraf vast wanneer de proef ongeldig is."],"sourceIds":["issf-education"]},
        {"type":"limits","title":"Geen automatische winnaar","paragraphs":["Een hoogste score in één reeks is geen betrouwbare materiaalkeuze. Herhaal de vergelijking op een andere sessie voordat je een praktische beslissing neemt."],"steps":[],"sourceIds":["issf-education"]}
      ],
      "diagramIds": ["abba-experiment"],
      "selfChecks": [{"prompt":"Kan ik de ene veranderde variabele in één zin benoemen?","observableSuccess":"Alle overige ingestelde voorwaarden zijn gelijk of als afwijking genoteerd.","resetIf":"Meer dan één materiaal-, techniek- of omgevingsvariabele verandert."}],
      "linkedDrillIds": ["br50-rebuild-rest@2", "pistol-three-baseline-groups@2"],
      "safetyCallouts": [{"title":"Wijzig materiaal alleen veilig","instruction":"Pas steun, vizier of materiaal uitsluitend aan wanneer het wapen volgens de baanprocedure veilig is."}],
      "references": [{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 7 en pp. 9-12: profiling, doelen, praktische opdrachten, dagboek en materiaaltests"}],
      "review": {"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF Education Reform Plan, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "pistol-natural-alignment",
      "version": 2,
      "title": "Eenhandige houding en natuurlijke uitlijning",
      "shortPromise": "Laat de opgebouwde houding naar het richtgebied terugkeren zonder de arm zijwaarts naar de kaart te sturen.",
      "category": "position",
      "disciplines": ["precisionPistol"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 12,
      "prerequisites": ["safe-range-phone-routine@2"],
      "applicability": ["ISSF-achtige eenhandige precisiehoudingen op 25 of 50 meter.", "Lichaamshoek en voetstand zijn individuele startwaarden, geen universele gradenmaat."],
      "sections": [
        {"type":"overview","title":"Richt de houding, niet alleen de arm","paragraphs":["De middenlijn of natuurlijke uitlijning is de richting waarin de opgebouwde positie zonder bewuste zijwaartse correctie terugkeert. Corrigeer die richting met de basis van de houding."],"steps":[],"sourceIds":["issf-education","cmp-pistol"]},
        {"type":"setup","title":"Veilige beginopstelling","paragraphs":["Neem op de erkende baan je normale schietpositie in met voldoende ruimte, stabiele voetplaatsing en een ontspannen niet-schietende arm volgens je coach- en baanprocedure."],"steps":[],"sourceIds":["issf-education","cmp-pistol"]},
        {"type":"sequence","title":"Vind de terugkeerrichting","paragraphs":[],"steps":["Bouw de houding zonder te schieten op.","Breng de arm naar het richtgebied en laat onnodige spanning los.","Observeer waar de uitlijning terugkomt.","Verplaats voeten en lichaamsbasis in kleine stappen; verdraai niet alleen schouder of pols."],"sourceIds":["issf-education"]},
        {"type":"observe","title":"Wat je zoekt","paragraphs":["Een bruikbare positie voelt niet perfect stil, maar komt na een normale opbouw in dezelfde zone terug zonder een blijvende zijwaartse duw."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"abortOrReset","title":"Opnieuw opbouwen","paragraphs":["Breek af wanneer de arm buiten de comfortabele bewegingszone komt, de voetplaatsing verschuift of de houding alleen met toenemende spanning blijft staan."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"variation","title":"Individuele geometrie","paragraphs":["Schoudermobiliteit, lichaamsbouw, griphoek en oogdominantie beïnvloeden de stand. Behoud het principe van herhaalbare terugkeer, niet één voorgeschreven silhouet."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"evidence","title":"Wat de bronnen ondersteunen","paragraphs":["ISSF-coachonderwijs behandelt been-, romp-, arm-, hand- en hoofdpositie samen met het vaststellen en corrigeren van de middenlijn. Het schrijft geen identieke lichaamshoek voor iedere schutter voor."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"practice","title":"Koppel aan een korte groep","paragraphs":[],"steps":["Controleer de terugkeerrichting drie keer zonder schot op de baan.","Schiet daarna één korte bevestigde reeks.","Noteer terugkeerzone en spierspanning vóór je het trefbeeld bekijkt."],"sourceIds":["cmp-pistol"]},
        {"type":"limits","title":"Geen oorzaak uit één zijdelingse treffer","paragraphs":["Een links of rechts liggende treffer bewijst geen fout in de voetstand. Gebruik meerdere opbouwen en groepen voordat je de houding gericht test."],"steps":[],"sourceIds":["issf-education"]}
      ],
      "diagramIds": ["pistol-natural-alignment-top"],
      "selfChecks": [{"prompt":"Komt mijn uitlijning na drie normale opbouwen in dezelfde zone terug?","observableSuccess":"De zone is herhaalbaar zonder de arm bewust zijwaarts te drukken.","resetIf":"Voeten, hoofdpositie of grip veranderen tussen de controles."}],
      "linkedDrillIds": ["pistol-three-baseline-groups@2"],
      "safetyCallouts": [{"title":"Controle zonder schot blijft baanwerk","instruction":"Voer droge positiecontroles alleen uit op een erkende baan, na toestemming, met een veilig gemaakt wapen en munitie fysiek gescheiden."}],
      "references": [{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 5, Pistol Course 1: stance, lichaamsas, arm- en hoofdlijn, nulpunt en correcties"},{"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"§§ Pistol Stance and Grip, Preparation for Firing Precision Pistol Shots en Firing Precision Pistol Shots, gedrukte pp. 18-24 (PDF pp. 23-29)"}],
      "review": {"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF/CMP, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "pistol-feet-body-arm",
      "version": 2,
      "title": "Voeten, lichaamsas en armrichting",
      "shortPromise": "Bouw één reproduceerbare keten van vloer tot richtlijn, zonder een geforceerde standaardhouding te kopiëren.",
      "category": "position",
      "disciplines": ["precisionPistol"],
      "levels": ["foundation"],
      "estimatedMinutes": 11,
      "prerequisites": ["pistol-natural-alignment@2"],
      "applicability": ["Staande eenhandige precisie.", "Aanpassingen gebeuren binnen pijnvrije mobiliteit en onder begeleiding wanneer nodig."],
      "sections": [
        {"type":"overview","title":"Een keten, geen losse onderdelen","paragraphs":["Voeten bepalen de basis; benen en romp dragen de houding; schouder en arm brengen het pistool in de richtlijn. Een verandering onderaan kan de natuurlijke richting bovenaan wijzigen."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"setup","title":"Markeer een startpositie","paragraphs":["Kies een comfortabele voetbreedte en noteer de stand met baanmarkeringen of een mentale referentie. Houd knieën vrij van geforceerde vergrendeling."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"sequence","title":"Van basis naar arm","paragraphs":[],"steps":["Plaats beide voeten volledig en stabiel.","Bouw romp en hoofd zonder zijwaarts trekken op.","Laat de schoudergordel laag en herhaalbaar.","Breng de arm in de natuurlijke lijn en controleer de terugkeer."],"sourceIds":["issf-education","cmp-pistol"]},
        {"type":"observe","title":"Herhaalbaarheid boven esthetiek","paragraphs":["Let op gelijke hoofdhoogte, gelijk steungevoel onder de voeten en dezelfde armrichting. Een positie hoeft er niet symmetrisch uit te zien om herhaalbaar te zijn."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"abortOrReset","title":"Pijn of toenemende spanning","paragraphs":["Stop de opbouw bij pijn, tinteling, verlies van balans of een houding die per herhaling verder wegdraait. Herbouw vanuit de voeten."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"variation","title":"Geen vaste hoek","paragraphs":["Voet- en romphoek verschillen door lichaamsbouw, mobiliteit, standruimte en grip. Verander in kleine stappen en beoordeel terugkeer, comfort en groep samen."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"evidence","title":"Disciplinegebonden opbouw","paragraphs":["Het ISSF-opleidingsplan behandelt been-, romp-, arm/hand- en hoofdpositie afzonderlijk én als praktisch opgebouwde houding. Het noemt biomechanische voor- en nadelen, geen universele mal."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"practice","title":"Drie identieke opbouwen","paragraphs":[],"steps":["Verlaat de positie volledig.","Bouw ze drie keer opnieuw op vanaf dezelfde referenties.","Noteer welke referentie telkens zichtbaar of voelbaar bleef.","Schiet pas daarna de gekoppelde groep."],"sourceIds":["issf-education"]},
        {"type":"limits","title":"Kaartbeeld is eindinformatie","paragraphs":["Een ruime groep kan samengaan met een comfortabele houding en omgekeerd. Combineer kaartdata met de waargenomen opbouw; wijzig niet alles na één resultaat."],"steps":[],"sourceIds":["issf-education"]}
      ],
      "diagramIds": ["pistol-stance-chain"],
      "selfChecks": [{"prompt":"Kan ik mijn voet-, hoofd- en armreferentie vóór ieder schot benoemen?","observableSuccess":"Drie heropbouwen geven dezelfde referenties zonder pijn of geforceerde correctie.","resetIf":"Eén referentie verschuift of de arm alleen met extra spanning in het richtgebied blijft."}],
      "linkedDrillIds": ["pistol-three-baseline-groups@2"],
      "safetyCallouts": [{"title":"Herbouwen na veilig afleggen","instruction":"Verlaat of wijzig de positie pas wanneer het wapen volgens de baanprocedure veilig is."}],
      "references": [{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 5, Pistol Course 1: benen, lichaam, arm/hand, hoofd en nulpunt"},{"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"§ Pistol Stance and Grip, gedrukte pp. 18-19 (PDF pp. 23-24)"}],
      "review": {"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF/CMP, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "pistol-grip-trigger-contact",
      "version": 2,
      "title": "Greep, pols en contact van de trekkervinger",
      "shortPromise": "Maak contactpunten controleerbaar zonder één greepdruk of vingervorm als universeel juist te verklaren.",
      "category": "shotExecution",
      "disciplines": ["precisionPistol"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 13,
      "prerequisites": ["pistol-feet-body-arm@2"],
      "applicability": ["Voor een veilig, passend precisiepistool met een correct afgestelde greep.", "Pas mechanische greepaanpassingen alleen toe volgens fabrikant, coach en baanregels."],
      "sections": [
        {"type":"overview","title":"Dezelfde verbinding opbouwen","paragraphs":["De greep verbindt hand, pols en pistool. Het doel is niet maximale kracht, maar een reproduceerbare plaatsing en een trekkervinger die druk kan opbouwen zonder zichtbaar zijwaarts contact met de greep."],"steps":[],"sourceIds":["issf-education","cmp-pistol"]},
        {"type":"setup","title":"Controleer passend materiaal","paragraphs":["Controleer dat de greep geen pijn, gevoelloosheid of onveilige toegang tot bediening veroorzaakt. De vinger bereikt de trekker zonder de handpositie telkens te verschuiven."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"sequence","title":"Plaats, sluit, controleer","paragraphs":[],"steps":["Plaats de hand telkens vanaf dezelfde referentie in de greep.","Sluit vingers en duim zonder de pols tijdens het richten opnieuw te vormen.","Plaats het gekozen vingerdeel op de trekker.","Bouw op de erkende baan gecontroleerd druk op en observeer of de vizierrelatie zijwaarts verandert."],"sourceIds":["cmp-pistol"]},
        {"type":"observe","title":"Waarneembare controle","paragraphs":["Let op dezelfde handhoogte, gelijke contactzones en een trekkervinger die vrij beweegt. Een kaart alleen vertelt niet welk contact veranderde."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"abortOrReset","title":"Hergrijp bewust","paragraphs":["Breek af bij pijn, verschuivende handpositie, onvrije trekkerbeweging of een pols die tijdens de opbouw blijft corrigeren. Maak het wapen veilig en herbouw."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"variation","title":"Druk en vingerplaatsing zijn individueel","paragraphs":["Handgrootte, trekkerafstand, greepgeometrie en trekkergewicht beïnvloeden de bruikbare contactplaats. Test één kleine wijziging tegelijk en behoud de veilige bediening."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"evidence","title":"Geen kwadrantdiagnose","paragraphs":["ISSF-onderwijs behandelt grip fitting en correctie als praktisch coachwerk. Een trefpunt links of rechts is onvoldoende om de trekkervinger als oorzaak vast te leggen."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"practice","title":"Contactcontrole op de baan","paragraphs":[],"steps":["Maak het wapen veilig volgens de baanregels.","Bouw de greep drie keer opnieuw op en benoem dezelfde contactreferenties.","Voer alleen na toestemming een droge of live korte oefening uit.","Noteer zichtbare vizierverandering, niet een veronderstelde oorzaak."],"sourceIds":["cmp-pistol"]},
        {"type":"limits","title":"Geen advies voor mechanische modificatie","paragraphs":["Deze les vervangt geen wapensmid, fabrikant of coach. Verwijder geen veiligheidsdelen en wijzig geen trekkermechanisme via de app."],"steps":[],"sourceIds":["issf-education"]}
      ],
      "diagramIds": ["pistol-grip-contact"],
      "selfChecks": [{"prompt":"Kan de trekkervinger bewegen zonder zichtbaar tegen de greep te duwen?","observableSuccess":"Handpositie en vizierrelatie blijven tijdens geleidelijke druk controleerbaar.","resetIf":"De hand verschuift, er ontstaat pijn of de bediening is niet vrij en veilig."}],
      "linkedDrillIds": ["pistol-blank-sight-picture@2", "pistol-repeatable-window@2"],
      "safetyCallouts": [{"title":"Geen mechanische aanpassing aan de vuurlijn","instruction":"Voer droge contactcontrole alleen uit op een erkende baan, na toestemming, met een veilig gemaakt wapen en munitie fysiek gescheiden. Volg fabrikant- en baanregels voordat greep of trekkerinstelling wordt aangepast."}],
      "references": [{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 5, Pistol Course 1: greeptechniek, correctie en aanpassen van de greep"},{"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"§§ Pistol Stance and Grip en Preparation for Firing Precision Pistol Shots, gedrukte pp. 18-22 (PDF pp. 23-27)"}],
      "review": {"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF/CMP, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "pistol-sight-alignment-picture",
      "version": 2,
      "title": "Vizieruitlijning tegenover richtbeeld",
      "shortPromise": "Scheid de geometrie van voor- en achtervizier van de plaats van dat geheel op de kaart.",
      "category": "aiming",
      "disciplines": ["precisionPistol"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 12,
      "prerequisites": ["pistol-grip-trigger-contact@2"],
      "applicability": ["Open vizieren op precisiepistolen.", "Het gekozen richtgebied kan centrum, sub-six of een andere herhaalbare hold zijn; de app schrijft geen universele hold voor."],
      "sections": [
        {"type":"overview","title":"Twee relaties","paragraphs":["Vizieruitlijning is de relatie tussen korrel en keep. Richtbeeld is de positie van dat uitgelijnde vizier ten opzichte van de kaart. Een kleine fout in de eerste relatie verandert de richting van het wapen."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"setup","title":"Kies één richtgebied","paragraphs":["Gebruik de hold die bij wapen, vizierinstelling, discipline en coaching hoort. Leg die keuze vóór de drill vast zodat je niet tijdens een reeks tussen centrum en onderkant wisselt."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"sequence","title":"Bouw van dichtbij naar buiten","paragraphs":[],"steps":["Plaats de korrel op gelijke hoogte in de keep.","Controleer gelijke lichtruimte links en rechts.","Houd de visuele aandacht op de korrel/vizierrelatie.","Laat het uitgelijnde geheel in het gekozen richtgebied bewegen zonder het stil te forceren."],"sourceIds":["cmp-pistol"]},
        {"type":"observe","title":"Wat scherp en wat stabiel moet zijn","paragraphs":["De vizierrelatie moet herkenbaar en herhaalbaar blijven. De kaart mag visueel minder scherp zijn; een bewegend richtbeeld is niet automatisch een fout."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"abortOrReset","title":"Breek af bij verloren relatie","paragraphs":["Wanneer je de korrel niet meer betrouwbaar in de keep ziet, de hoofdpositie verandert of je naar de kaart gaat jagen, laat je de uitvoering veilig zakken en bouw je opnieuw op."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"variation","title":"Hold en contrast verschillen","paragraphs":["Licht, zicht, keepbreedte en vizierinstelling beïnvloeden wat bruikbaar zichtbaar is. Behoud gelijke uitlijning; kies het richtgebied met coach en materiaalcontext."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"evidence","title":"Waarom blanco oefenen bestaat","paragraphs":["CMP beschrijft doelgerichte oefeningen waarbij score-informatie wordt verminderd om vizieruitlijning te isoleren. De app gebruikt dat principe alleen op de erkende baan."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"practice","title":"Blanco vlak op de baan","paragraphs":[],"steps":["Bevestig de veiligheidspoort voor de baan.","Gebruik een blanco vlak of keerzijde volgens de baanregels.","Voer de geplande droge of live fase uit zonder ringscore te zoeken.","Noteer of de vizierrelatie herkenbaar bleef."],"sourceIds":["cmp-pistol"]},
        {"type":"limits","title":"Geen oogheelkundig advies","paragraphs":["Onvoldoende zicht, pijn of aanhoudende dubbelbeelden vragen professionele beoordeling. De app kiest geen lens, filter of medische oplossing."],"steps":[],"sourceIds":["cmp-pistol"]}
      ],
      "diagramIds": ["pistol-sight-relationship"],
      "selfChecks": [{"prompt":"Kan ik de vizierrelatie benoemen zonder de ringscore te gebruiken?","observableSuccess":"Korrelhoogte en lichtruimte blijven herkenbaar terwijl het geheel normaal beweegt.","resetIf":"De aandacht springt naar het trefpunt, de hoofdpositie verandert of de korrelrelatie verdwijnt."}],
      "linkedDrillIds": ["pistol-blank-sight-picture@2"],
      "safetyCallouts": [{"title":"Droge oefening op de baan","instruction":"Een droge fase wordt uitsluitend op een erkende baan uitgevoerd, na toestemming, met een volledig gecontroleerd wapen en munitie fysiek gescheiden."}],
      "references": [{"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"§§ Preparation for Firing Precision Pistol Shots, Firing Precision Pistol Shots en Pistol Training, gedrukte pp. 20-27 (PDF pp. 25-32)"}],
      "review": {"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"CMP Junior Pistol Guide, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "pistol-visual-focus-movement",
      "version": 2,
      "title": "Visuele focus en een normale bewegingszone",
      "shortPromise": "Herken een bruikbaar bewegend richtbeeld zonder op een perfect stil moment te wachten.",
      "category": "aiming",
      "disciplines": ["precisionPistol"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 10,
      "prerequisites": ["pistol-sight-alignment-picture@2"],
      "applicability": ["Precisieschoten met open vizier.", "De grootte van de bewegingszone is persoonlijk en verandert met duur, herstel en omstandigheden."],
      "sections": [
        {"type":"overview","title":"Beweging is verwacht","paragraphs":["Een staand pistool beweegt. De oefentaak is de vizierrelatie binnen een herkenbare zone behouden en de uitvoering laten doorlopen, niet iedere beweging onderdrukken."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"setup","title":"Kies een korte observatie","paragraphs":["Gebruik een normale opbouw en bekijk enkele seconden hoe het uitgelijnde vizier beweegt. Schiet nog niet; probeer de beweging ook niet kleiner te duwen."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"sequence","title":"Herkennen en uitvoeren","paragraphs":[],"steps":["Vind de korrelrelatie.","Laat het richtbeeld het gekozen gebied naderen.","Herken de normale bewegingszone.","Start of behoud geleidelijke trekkerdruk zolang de vizierrelatie bruikbaar blijft."],"sourceIds":["cmp-pistol"]},
        {"type":"observe","title":"Zone, geen stil punt","paragraphs":["Observeer vorm, tempo en terugkeer van de beweging. Een kort moment door het centrum is niet automatisch beter dan een beheerst proces binnen de zone."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"abortOrReset","title":"Wanneer de zone uiteenvalt","paragraphs":["Breek af wanneer de beweging merkbaar groter blijft worden, visuele aandacht wegvalt of tijdsdruk leidt tot abrupt handelen."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"variation","title":"Vermoeidheid en licht","paragraphs":["De zone kan per serie veranderen door vermoeidheid, licht en herstel. Vergelijk alleen korte reeksen onder vergelijkbare omstandigheden."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"evidence","title":"Geen perfecte stilstand als norm","paragraphs":["CMP beschrijft een normale area of movement samen met progressieve trekkerdruk. Dat ondersteunt procescontrole, niet een vaste toegestane diameter voor iedere schutter."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"practice","title":"Drie observaties, drie schoten","paragraphs":[],"steps":["Observeer drie normale opbouwen op de baan.","Benoem de zone zonder te scoren.","Voer daarna drie schoten uit met dezelfde visuele opdracht.","Vergelijk procesnotitie en groep pas achteraf."],"sourceIds":["cmp-pistol"]},
        {"type":"limits","title":"Geen tremordiagnose","paragraphs":["De app meet geen spieractiviteit, blik of wapenbeweging. Een ruime groep is geen bewijs voor een specifieke visuele of lichamelijke oorzaak."],"steps":[],"sourceIds":["cmp-pistol"]}
      ],
      "diagramIds": ["pistol-movement-zone"],
      "selfChecks": [{"prompt":"Kan ik mijn normale bewegingszone herkennen zonder op een stil centrum te wachten?","observableSuccess":"De vizierrelatie blijft herkenbaar en de uitvoering kan zonder abrupte correctie doorlopen.","resetIf":"De zone blijft vergroten of de visuele relatie verdwijnt."}],
      "linkedDrillIds": ["pistol-blank-sight-picture@2", "pistol-repeatable-window@2"],
      "safetyCallouts": [{"title":"Afbreken is een veilige vaardigheid","instruction":"Verlaat een verslechterende opbouw volgens de veilige baanprocedure; forceer geen schot om de drill af te maken."}],
      "references": [{"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"§ Firing Precision Pistol Shots, gedrukte pp. 22-24 (PDF pp. 27-29)"}],
      "review": {"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"CMP Junior Pistol Guide, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "pistol-arm-lift-approach",
      "version": 2,
      "title": "Armheffing en gecontroleerde nadering",
      "shortPromise": "Maak de route naar het richtgebied herhaalbaar zonder één verplichte hefhoogte te kopiëren.",
      "category": "shotExecution",
      "disciplines": ["precisionPistol"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 10,
      "prerequisites": ["pistol-visual-focus-movement@2"],
      "applicability": ["Precisiepistool met een gecontroleerde hef- en daalbeweging.", "De hefhoogte wordt aangepast aan schutter, discipline, plafond, stand en coachplan."],
      "sections": [
        {"type":"overview","title":"Een herkenbare route","paragraphs":["De heffing brengt houding, vizier en ademritme samen. Een herhaalbare route is belangrijker dan exact dezelfde absolute hoogte voor iedere schutter."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"setup","title":"Vrije en veilige bewegingsbaan","paragraphs":["Controleer dat de monding binnen de toegestane veilige zone blijft en dat verlichting, plafond en baanregels de gekozen heffing toelaten."],"steps":[],"sourceIds":["cmp-safety","cmp-pistol"]},
        {"type":"sequence","title":"Heffen, vertragen, naderen","paragraphs":[],"steps":["Start uit dezelfde veilige gereedpositie.","Hef de arm vloeiend binnen de veilige baanzone.","Laat de beweging vertragen vóór het gekozen richtgebied.","Bouw vizierrelatie en trekkerdruk samen verder op."],"sourceIds":["cmp-pistol"]},
        {"type":"observe","title":"Referenties in de route","paragraphs":["Let op startpositie, hoogste praktische referentie, snelheid van naderen en het moment waarop de vizierrelatie herkenbaar wordt."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"abortOrReset","title":"Geen correctiejacht","paragraphs":["Breek af wanneer de route buiten de veilige zone komt, de schouder plots aanspant of je na overschrijden van het richtgebied terug moet jagen."],"steps":[],"sourceIds":["cmp-safety","cmp-pistol"]},
        {"type":"variation","title":"Hoogte is geen universele maat","paragraphs":["De CMP-gids beschrijft een gecoördineerde heffing, maar geeft ook ruimte voor variatie in de praktische hefhoogte. Kies met coach een route die veilig en herhaalbaar is."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"evidence","title":"Proceskoppeling","paragraphs":["De bron koppelt heffing, ademhaling, vizierverwerving en voorbereidende trekkerdruk. Ze bewijst niet dat één timing voor iedere precisiediscipline optimaal is."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"practice","title":"Vergelijk routes, niet hoogste schot","paragraphs":[],"steps":["Voer vijf veilige opbouwen zonder schot uit op de baan.","Kies twee zichtbare route-referenties.","Schiet een korte reeks met dezelfde route.","Beoordeel herhaalbaarheid vóór score."],"sourceIds":["cmp-pistol"]},
        {"type":"limits","title":"Niet geschikt voor snelvuurinstructie","paragraphs":["Deze les behandelt gecontroleerde precisieopbouw. Ze vervangt geen disciplinespecifieke timing voor rapid-fireonderdelen."],"steps":[],"sourceIds":["cmp-pistol"]}
      ],
      "diagramIds": ["pistol-lift-approach"],
      "selfChecks": [{"prompt":"Bereik ik het richtgebied via dezelfde veilige route?","observableSuccess":"Start, vertraging en nadering zijn herkenbaar zonder terugjagen of extra schouderspanning.","resetIf":"De route verandert, de veilige mondingszone wordt benaderd of de schouder aanspant."}],
      "linkedDrillIds": ["pistol-repeatable-window@2"],
      "safetyCallouts": [{"title":"Mondingszone blijft leidend","instruction":"De gekozen heffing moet altijd binnen baanregels en veilige mondingsrichting blijven."}],
      "references": [{"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"§§ Preparation for Firing Precision Pistol Shots en Firing Precision Pistol Shots, gedrukte pp. 20-24 (PDF pp. 25-29)"},{"id":"cmp-safety","title":"Safety","url":"https://thecmp.org/safety/","publisher":"Civilian Marksmanship Program","documentEdition":"webpagina, geraadpleegd 2026-08-10","locator":"secties ‘Rules for Safe Gun Handling’ en ‘The Goal: No Gun Accidents’"}],
      "review": {"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"CMP, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "pistol-breathing-window",
      "version": 2,
      "title": "Ademritme en comfortabel uitvoeringsvenster",
      "shortPromise": "Gebruik een herhaalbaar ademritme en breek af vóór een comfortabele pauze verandert in forceren.",
      "category": "shotExecution",
      "disciplines": ["precisionPistol"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 9,
      "prerequisites": ["pistol-arm-lift-approach@2"],
      "applicability": ["Langzame precisieopbouw zonder medische ademhalingsbeperking.", "Gebruik geen maximale ademstop en vraag medisch advies bij klachten."],
      "sections": [
        {"type":"overview","title":"Ademhaling ordent de opbouw","paragraphs":["Een korte comfortabele pauze kan een herkenbaar uitvoeringsvenster geven. Het doel is herhaalbaarheid, niet zo lang mogelijk de adem vasthouden."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"setup","title":"Begin normaal","paragraphs":["Start met een normaal, rustig ritme. Vermijd vooraf overdreven diep of snel ademen om een langere pauze te creëren."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"sequence","title":"Koppel aan de heffing","paragraphs":[],"steps":["Adem normaal vóór de opbouw.","Koppel de gekozen uitademing en heffing volgens je routine.","Gebruik alleen de comfortabele pauze voor de laatste uitvoering.","Adem opnieuw en reset wanneer het schot niet ontstaat."],"sourceIds":["cmp-pistol"]},
        {"type":"observe","title":"Comfort als grens","paragraphs":["Let op toenemende druk, spanning, zichtverandering en de neiging om het schot alsnog te forceren. Dat zijn signalen om af te breken, niet om langer vast te houden."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"abortOrReset","title":"Uitvoeringsvenster voorbij","paragraphs":["Laat het wapen veilig zakken zodra de comfortabele pauze voorbij is of de vizierrelatie duidelijk verslechtert. Heradem en begin de volledige routine opnieuw."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"variation","title":"Geen vaste seconden voor iedereen","paragraphs":["Fitheid, tempo en discipline verschillen. De app laat je een venster beschrijven, maar schrijft geen universele ademduur voor."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"evidence","title":"Gecoördineerde basis","paragraphs":["CMP behandelt ademhaling als onderdeel van een gecoördineerde armheffing en schotuitvoering. De bron is instructief en geen medische richtlijn."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"practice","title":"Drie vensters observeren","paragraphs":[],"steps":["Doorloop drie opbouwen zonder schot op de baan.","Benoem het moment waarop de pauze niet meer comfortabel voelt.","Schiet daarna een korte reeks en breek iedere te lange opbouw bewust af."],"sourceIds":["cmp-pistol"]},
        {"type":"limits","title":"Stop bij klachten","paragraphs":["Duizeligheid, benauwdheid of pijn zijn geen trainingssignaal. Stop onmiddellijk en volg passende medische of baanbegeleiding."],"steps":[],"sourceIds":["cmp-pistol"]}
      ],
      "diagramIds": ["pistol-breath-trigger-timeline"],
      "selfChecks": [{"prompt":"Kan ik mijn comfortabele venster herkennen vóór ik ga forceren?","observableSuccess":"Ik breek de opbouw zelfstandig af en hervat met normale ademhaling.","resetIf":"Ik verleng de ademstop om een schot alsnog af te dwingen."}],
      "linkedDrillIds": ["pistol-repeatable-window@2"],
      "safetyCallouts": [{"title":"Ademstop is geen prestatietest","instruction":"Forceer nooit een lange ademstop; stop bij klachten en maak het wapen veilig."}],
      "references": [{"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"§ Preparation for Firing Precision Pistol Shots, gedrukte pp. 20-22 (PDF pp. 25-27)"}],
      "review": {"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"CMP Junior Pistol Guide, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "pistol-progressive-trigger",
      "version": 2,
      "title": "Geleidelijke trekkerdruk tijdens beweging",
      "shortPromise": "Laat de druk gecontroleerd doorgroeien terwijl het richtbeeld normaal beweegt, zonder op een perfect moment te slaan.",
      "category": "shotExecution",
      "disciplines": ["precisionPistol"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 12,
      "prerequisites": ["pistol-grip-trigger-contact@2", "pistol-visual-focus-movement@2"],
      "applicability": ["Langzame precisie met een veilig en correct afgesteld trekkermechanisme.", "De exacte drukcurve verschilt per trekker, schutter en discipline."],
      "sections": [
        {"type":"overview","title":"Drukproces en richtbeeld lopen samen","paragraphs":["De uitvoering wacht niet op volmaakte stilstand. Druk wordt geleidelijk opgebouwd zolang vizierrelatie en bewegingszone bruikbaar blijven."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"setup","title":"Ken de veilige trekker","paragraphs":["Controleer met coach of fabrikant hoe eerste en tweede fase van jouw trekker aanvoelen. Wijzig geen mechanische instelling tijdens deze oefening."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"sequence","title":"Voorbereiden en doorzetten","paragraphs":[],"steps":["Plaats de trekkervinger herhaalbaar.","Neem voorbereidende druk op tijdens de gecontroleerde nadering wanneer dat bij het materiaal past.","Laat de druk rustig groeien binnen het uitvoeringsvenster.","Behoud visuele relatie en druk na het schot kort in de follow-through."],"sourceIds":["cmp-pistol"]},
        {"type":"observe","title":"Zie wat er werkelijk verandert","paragraphs":["Observeer of korrel en keep tijdens de druk zichtbaar van relatie veranderen. Noteer alleen die waarneming; een inslagrichting op zichzelf toont de trekkerbeweging niet."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"abortOrReset","title":"Druk veilig lossen","paragraphs":["Wanneer vizierrelatie of comfort wegvalt, stop je het schot volgens je aangeleerde veilige procedure. Houd de monding veilig en reset volledig; improviseer geen half afgebroken uitvoering."],"steps":[],"sourceIds":["cmp-safety","cmp-pistol"]},
        {"type":"variation","title":"Eén- en tweetrapstrekkers","paragraphs":["Het voelbare verloop kan sterk verschillen. Behoud de principes van voorspelbare vingerplaatsing, gecontroleerde richting en een veilige reset."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"evidence","title":"Geen universele timing","paragraphs":["CMP koppelt progressieve trekkerdruk aan een normale bewegingszone. De bron ondersteunt het proces, niet één vast milliseconden- of krachtprofiel."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"practice","title":"Blanco observatie en korte groep","paragraphs":[],"steps":["Bevestig de veiligheidspoort voor de baan.","Observeer eerst de vizierrelatie tijdens enkele toegestane droge uitvoeringen.","Schiet daarna drie tot vijf live schoten met dezelfde opdracht.","Vergelijk waarneming en groep zonder oorzaakclaim."],"sourceIds":["cmp-pistol"]},
        {"type":"limits","title":"Geen trekkerdiagnostiek zonder sensor","paragraphs":["De app registreert geen trekkerkracht of wapenspoor. Ze kan daarom geen precieze trekkerfout uit het trefbeeld afleiden."],"steps":[],"sourceIds":["cmp-pistol"]}
      ],
      "diagramIds": ["pistol-breath-trigger-timeline", "pistol-trigger-contact"],
      "selfChecks": [{"prompt":"Blijft de vizierrelatie herkenbaar terwijl de druk groeit?","observableSuccess":"De druk verloopt zonder zichtbare abrupte zijwaartse verandering en kan veilig worden afgebroken.","resetIf":"Ik wacht op stilstand, handel plots of kan de druk niet gecontroleerd lossen."}],
      "linkedDrillIds": ["pistol-blank-sight-picture@2", "pistol-repeatable-window@2"],
      "safetyCallouts": [{"title":"Alleen met veilig materiaal","instruction":"Gebruik alleen een correct werkend trekkermechanisme. Voer droge fasen uitsluitend op een erkende baan uit, na toestemming en met munitie fysiek gescheiden."}],
      "references": [{"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"§§ Preparation for Firing Precision Pistol Shots en Firing Precision Pistol Shots, gedrukte pp. 20-24 (PDF pp. 25-29)"},{"id":"cmp-safety","title":"Safety","url":"https://thecmp.org/safety/","publisher":"Civilian Marksmanship Program","documentEdition":"webpagina, geraadpleegd 2026-08-10","locator":"secties ‘Rules for Safe Gun Handling’ en ‘The Goal: No Gun Accidents’"}],
      "review": {"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"CMP, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "pistol-follow-through-reset",
      "version": 2,
      "title": "Follow-through, shot call, afbreken en resetten",
      "shortPromise": "Behoud de uitvoering kort na het schot en leg je waarneming vast vóór het trefbeeld je herinnering kleurt.",
      "category": "routine",
      "disciplines": ["precisionPistol"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 12,
      "prerequisites": ["pistol-progressive-trigger@2"],
      "applicability": ["Na ieder langzaam precisieschot.", "Een shot call is een waarneming van richting of kwaliteit, geen automatische oorzaakanalyse."],
      "sections": [
        {"type":"overview","title":"Het proces stopt niet bij de knal","paragraphs":["Behoud kort de veilige richting, vizierwaarneming en gecontroleerde handpositie. Geef daarna een eenvoudige call vóór je kaart of monitor bekijkt."],"steps":[],"sourceIds":["cmp-pistol","preshot-study"]},
        {"type":"setup","title":"Kies een eenvoudige call","paragraphs":["Gebruik bijvoorbeeld een 3×3-richting en kwaliteit 'helder / onzeker'. Vermijd lange technische verklaringen direct na het schot."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"sequence","title":"Schot, waarneming, reset","paragraphs":[],"steps":["Laat druk en visuele aandacht doorlopen terwijl het schot valt.","Observeer de laatste herkenbare vizierrelatie.","Maak een korte call.","Adem, ontspan en start de volgende volledige routine of breek veilig af."],"sourceIds":["cmp-pistol"]},
        {"type":"observe","title":"Call zonder achterafcorrectie","paragraphs":["Noteer wat je werkelijk zag, ook wanneer het niet overeenkomt met de treffer. Juist dat verschil is trainingsinformatie."],"steps":[],"sourceIds":["cmp-pistol"]},
        {"type":"abortOrReset","title":"Bewuste reset","paragraphs":["Na een onduidelijke uitvoering, baanonderbreking of emotionele reactie maak je het proces bewust af en begin je opnieuw. Schiet niet sneller om het vorige resultaat te herstellen."],"steps":[],"sourceIds":["preshot-study"]},
        {"type":"variation","title":"Routine blijft individueel","paragraphs":["Een korte routine kan andere woorden of fysieke cues gebruiken. Behoud alleen stappen die observeerbaar en veilig uitvoerbaar zijn."],"steps":[],"sourceIds":["preshot-study"]},
        {"type":"evidence","title":"Bescheiden bewijs","paragraphs":["Onderzoek naar preshot routines bij elite luchtpistoolschutters is een kleine casestudy. Het ondersteunt individuele, geoefende routines als mogelijkheid, niet één universeel script of garantie op betere scores."],"steps":[],"sourceIds":["preshot-study"]},
        {"type":"practice","title":"Call vijf schoten","paragraphs":[],"steps":["Kies vooraf je eenvoudige callformaat.","Voer vijf schoten uit zonder tussentijds kaartbeeld wanneer de stand dat toelaat.","Leg iedere call vast.","Vergelijk pas na de reeks, zonder verschillen als fout te verbergen."],"sourceIds":["cmp-pistol"]},
        {"type":"limits","title":"Geen schotvolgorde uit een kaart reconstrueren","paragraphs":["Zonder expliciete calls of elektronische/sensordata kent de app niet welk gat bij welk moment hoorde. Ze verzint die volgorde niet."],"steps":[],"sourceIds":["cmp-pistol"]}
      ],
      "diagramIds": ["pistol-abort-reset-tree"],
      "selfChecks": [{"prompt":"Kan ik mijn call geven vóór ik de uitslag zie?","observableSuccess":"De call is kort, observeerbaar en blijft ongewijzigd wanneer de treffer anders ligt.","resetIf":"Ik maak achteraf een verklaring passend bij de kaart of probeer het vorige schot snel te herstellen."}],
      "linkedDrillIds": ["pistol-cold-series@2", "pistol-match-block@2"],
      "safetyCallouts": [{"title":"Geen telefoongebruik tussen live schoten","instruction":"Calls worden alleen handsfree onthouden of pas vastgelegd nadat het wapen veilig is gemaakt."}],
      "references": [{"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"§ Firing Precision Pistol Shots, onderdeel 4 Follow-Through, gedrukte p. 24 (PDF p. 29)"},{"id":"preshot-study","title":"Preshot Routines to Improve Competition Performance: a case study","url":"https://doi.org/10.1123/cssep.2019-0039","publisher":"Case Studies in Sport and Exercise Psychology","documentEdition":"2020;4(1):52-57","locator":"Case study with elite pistol shooters"}],
      "review": {"evidenceStatus":"researchSupported","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"CMP en peer-reviewed case study, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "br50-rest-rules",
      "version": 2,
      "title": "Reglementaire voor- en achtersteun",
      "shortPromise": "Controleer eerst klasse- en kaartregels; bouw daarna pas een trainingsopstelling die je eerlijk kunt herhalen.",
      "category": "benchrest",
      "disciplines": ["br50"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 11,
      "prerequisites": ["safe-range-phone-routine@2"],
      "applicability": ["WRABF 50 m rimfire benchresttraining.", "Lokale en actuele wedstrijdregels bepalen welke steun en contactvorm zijn toegestaan."],
      "sections": [
        {"type":"overview","title":"Regels vóór techniek","paragraphs":["Een steunopstelling is alleen bruikbaar wanneer ze veilig, stabiel en toegestaan is voor de beoogde klasse. De app toont geen universele wedstrijdlegaliteit op basis van een foto."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"setup","title":"Controleer vijf zaken","paragraphs":["Controleer klasse, voorsteun, achtersteun, geweercontact en vrije veilige bediening. Leg ook vast of de oefening wedstrijdspecifiek of alleen technisch is."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"sequence","title":"Van reglement naar baan","paragraphs":[],"steps":["Lees de actuele regels en lokale aanvulling.","Laat onduidelijke uitrusting vooraf controleren.","Plaats steun en geweer zonder de mondingszone te verlaten.","Markeer alleen niet-permanente referenties die zijn toegestaan."],"sourceIds":["wrabf-rules","cmp-safety"]},
        {"type":"observe","title":"Controleerbare opstelling","paragraphs":["Je kunt vóór de eerste sighter benoemen waar voorsteun, achterzak, kolf en vizierlijn zich bevinden en welke delen tijdens de kaart niet worden gewijzigd."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"abortOrReset","title":"Stop bij verschuiving of twijfel","paragraphs":["Maak het geweer veilig wanneer steun of kolf verschuift, bediening wordt belemmerd of de reglementaire status onduidelijk is. Herbouw niet met een geladen wapen."],"steps":[],"sourceIds":["cmp-safety","wrabf-rules"]},
        {"type":"variation","title":"Klasse en materiaal verschillen","paragraphs":["Contactstrategie, steunconstructie en afstelling verschillen per klasse en materiaal. Deze les behandelt controlepunten, niet één verplichte technische stijl."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"evidence","title":"Wat WRABF hier bepaalt","paragraphs":["WRABF publiceert de discipline- en kaartregels. Die bron ondersteunt wedstrijdgrenzen en kaartprotocol, niet de claim dat één contactdruk de beste precisie geeft."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"practice","title":"Maak een setupkaart","paragraphs":[],"steps":["Noteer klasse en gebruikte steun.","Maak het geweer veilig en leg drie visuele referenties vast.","Herbouw de opstelling één keer vóór live fire.","Start daarna de vijf-bullsdrill."],"sourceIds":["wrabf-rules"]},
        {"type":"limits","title":"Geen wedstrijdkeuring","paragraphs":["De app is een trainingshulpmiddel en certificeert geen geweer, steun, tafel of wedstrijdkaart."],"steps":[],"sourceIds":["wrabf-rules"]}
      ],
      "diagramIds": ["br50-rest-overview"],
      "selfChecks": [{"prompt":"Kan ik de klasse, steunpunten en veilige bedieningsruimte benoemen?","observableSuccess":"Opstelling en referenties zijn vastgelegd en vooraf volgens actuele regels gecontroleerd.","resetIf":"Steun, kolf of reglementaire context verandert."}],
      "linkedDrillIds": ["br50-five-record-bulls@2"],
      "safetyCallouts": [{"title":"Herbouw alleen veilig","instruction":"Maak het geweer volledig veilig vóór je voorsteun, achterzak of contactpunten aanpast."}],
      "references": [{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"§§ B.8-B.10, pp. 14-16: voor- en achtersteun, vrije beweging en verbod op terugslagbeperking"},{"id":"cmp-safety","title":"Safety","url":"https://thecmp.org/safety/","publisher":"Civilian Marksmanship Program","documentEdition":"webpagina, geraadpleegd 2026-08-10","locator":"secties ‘Rules for Safe Gun Handling’ en ‘The Goal: No Gun Accidents’"}],
      "review": {"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"WRABF V4.4, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "br50-rest-axis",
      "version": 2,
      "title": "Voorsteun, achterzak en loopas uitlijnen",
      "shortPromise": "Bouw een rechte, vrije bewegingsroute zodat de opstelling na een schot controleerbaar kan terugkeren.",
      "category": "benchrest",
      "disciplines": ["br50"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 12,
      "prerequisites": ["br50-rest-rules@2"],
      "applicability": ["Voor een veilige, toegestane tweepuntssteun.", "Laat een coach controleren of jouw geweer en steun vrij en veilig kunnen bewegen."],
      "sections": [
        {"type":"overview","title":"Eén geometrische lijn","paragraphs":["Voorsteun, achterzak en geweer worden zo geplaatst dat de richtlijn zonder merkbare zijwaartse klem naar het gekozen bullcentrum wijst."],"steps":[],"sourceIds":["issf-education","wrabf-rules"]},
        {"type":"setup","title":"Begin met een veilig leeg systeem","paragraphs":["Maak het geweer veilig, centreer voorsteun en achterzak binnen hun bruikbare bereik en controleer vrije bediening en mondingsrichting."],"steps":[],"sourceIds":["cmp-safety"]},
        {"type":"sequence","title":"Lijn van doel naar kolf","paragraphs":[],"steps":["Kies het eerste bullcentrum.","Plaats de voorsteun zodat grove zijwaartse correctie minimaal is.","Breng de achterzak in dezelfde lijn.","Plaats het geweer en controleer of het zonder torsie naar het richtgebied terugkomt."],"sourceIds":["issf-education"]},
        {"type":"observe","title":"Vrije terugkeer","paragraphs":["Let op zijwaarts trekken, klemmen, scheve zakoren en een kolf die bij iedere plaatsing een andere baan volgt. Noteer referenties vóór live fire."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"abortOrReset","title":"Geen correctie onder spanning","paragraphs":["Stop wanneer het geweer niet vrij beweegt, een steuncontact onveilig wordt of grote zijdelingse druk nodig blijft. Maak veilig en plaats de hele steun opnieuw."],"steps":[],"sourceIds":["cmp-safety"]},
        {"type":"variation","title":"Opstelling hangt van materiaal af","paragraphs":["Kolfvorm, zak, voorsteun en klasse beïnvloeden de bruikbare lijn. Het diagram toont controlepunten, geen verplichte maatvoering."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"evidence","title":"Praktijkprincipe met begrenzing","paragraphs":["ISSF-coachonderwijs behandelt positieopbouw, middenlijn en correctie; WRABF bepaalt klassegrenzen. De precieze steunafstelling vraagt materiaal- en coachkennis."],"steps":[],"sourceIds":["issf-education","wrabf-rules"]},
        {"type":"practice","title":"Herbouw op drie referenties","paragraphs":[],"steps":["Leg één referentie bij voorsteun, één bij achterzak en één bij het gekozen bull vast.","Verwijder en herplaats het veilige geweer.","Controleer de terugkeer zonder schot.","Start pas daarna een korte live groep."],"sourceIds":["issf-education"]},
        {"type":"limits","title":"Geen voorspelling uit terugkeer alleen","paragraphs":["Een visueel goede terugkeer garandeert geen compacte groep. Munitie, wind, materiaal en uitvoering blijven afzonderlijke variabelen."],"steps":[],"sourceIds":["issf-education"]}
      ],
      "diagramIds": ["br50-rest-axis-top-side"],
      "selfChecks": [{"prompt":"Keert het veilige geweer zonder zijdelingse duw naar dezelfde zone terug?","observableSuccess":"De drie opstellingsreferenties blijven gelijk en de beweging voelt vrij.","resetIf":"Een steunpunt verschuift, klemt of een andere bullrij een grote zijwaartse kracht vraagt."}],
      "linkedDrillIds": ["br50-rebuild-rest@2"],
      "safetyCallouts": [{"title":"Handen aan steun betekent veilig geweer","instruction":"Verstel voorsteun of achterzak uitsluitend wanneer het geweer volgens de baanprocedure veilig is."}],
      "references": [{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 7 en pp. 9-12: individueel profiel, correctie, materiaaltest en praktijkplanning"},{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"§§ B.8-B.10, pp. 14-16: voor- en achtersteun, vrije beweging en verbod op terugslagbeperking"},{"id":"cmp-safety","title":"Safety","url":"https://thecmp.org/safety/","publisher":"Civilian Marksmanship Program","documentEdition":"webpagina, geraadpleegd 2026-08-10","locator":"secties ‘Rules for Safe Gun Handling’ en ‘The Goal: No Gun Accidents’"}],
      "review": {"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF/WRABF/CMP, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "br50-contact-rebuild",
      "version": 2,
      "title": "Herhaalbare contactstrategie en opstelling opnieuw bouwen",
      "shortPromise": "Leg jouw gekozen, toegestane contactpunten vast en test of je ze na een volledige heropbouw terugvindt.",
      "category": "benchrest",
      "disciplines": ["br50"],
      "levels": ["development"],
      "estimatedMinutes": 14,
      "prerequisites": ["br50-rest-axis@2", "one-variable-comparison@2"],
      "applicability": ["Na controle van klasse, steun en veilige bediening.", "Contactstrategieën verschillen; gebruik deze les om herhaalbaarheid te meten, niet om één stijl op te leggen."],
      "sections": [
        {"type":"overview","title":"Documenteer wat jij werkelijk doet","paragraphs":["Benoem waar hand, schouder, wang en kolf contact maken, welke punten bewust vrij blijven en welke steuninstellingen niet veranderen tijdens een kaart."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"setup","title":"Maak een setupsnapshot","paragraphs":["Leg klasse, steun, tafelhoogte, stoelpositie en drie materiaalreferenties vast. Gebruik geen detail dat niet veilig of toegestaan reproduceerbaar is."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"sequence","title":"Bouwen en herbouwen","paragraphs":[],"steps":["Bouw de opstelling volledig op en schiet twee korte geldige reeksen.","Maak het geweer veilig en verwijder het uit de steun.","Herbouw alleen met de vastgelegde referenties.","Schiet twee controlegroepen zonder andere variabele te wijzigen."],"sourceIds":["issf-education"]},
        {"type":"observe","title":"Meet meer dan score","paragraphs":["Vergelijk groepscentrum, mean radius en de zichtbare terugkeer. Noteer ook wanneer een contactreferentie niet reproduceerbaar bleek."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"abortOrReset","title":"Ongeldige herbouw","paragraphs":["Markeer de proef onbetrouwbaar wanneer munitie, doelafstand, wind, steunondergrond of contactstrategie tegelijk verandert."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"variation","title":"Free recoil en contactvormen","paragraphs":["Verschillende klassen, kolven en coaches gebruiken verschillende contactstrategieën. De app beoordeelt alleen of jouw vooraf gekozen strategie herhaalbaar is binnen de vastgelegde context."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"evidence","title":"Geen universele contactclaim","paragraphs":["WRABF ondersteunt de reglementaire context, maar publiceert hier geen bewijs dat één druk- of contactstrategie superieur is. De vergelijking blijft persoonlijk en praktijkgebaseerd."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"practice","title":"Gebruik de A-B-B-A-logica niet verkeerd","paragraphs":[],"steps":["Noem vóór de test exact wat 'opgebouwd' en 'herbouwd' betekent.","Behoud hetzelfde munitielot en kaartprotocol.","Gebruik de gekoppelde vier-reeksendrill.","Herhaal op een tweede sessie vóór een materiaalbesluit."],"sourceIds":["issf-education"]},
        {"type":"limits","title":"Geen oorzaakanalyse uit één cluster","paragraphs":["Een verschoven controlegroep kan samengaan met wind, munitie, steun of uitvoering. Ze bewijst niet dat één contactpunt de oorzaak was."],"steps":[],"sourceIds":["issf-education"]}
      ],
      "diagramIds": ["br50-contact-map", "abba-experiment"],
      "selfChecks": [{"prompt":"Kan ik mijn contactstrategie in concrete contact- en vrijzones beschrijven?","observableSuccess":"De herbouw gebruikt dezelfde referenties en verandert geen tweede variabele.","resetIf":"Een referentie niet reproduceerbaar is of omstandigheden wezenlijk veranderen."}],
      "linkedDrillIds": ["br50-rebuild-rest@2"],
      "safetyCallouts": [{"title":"Contact wijzigen met veilig geweer","instruction":"Verplaats geweer, steun, stoel of contactpunten alleen nadat het geweer veilig is gemaakt."}],
      "references": [{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"§§ B.1-B.10, pp. 7-16: klassen, uitrusting en steunregels"},{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 7 en pp. 9-12: feedback, materiaaltest, individuele doelen en praktijkplanning"}],
      "review": {"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"WRABF/ISSF, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "br50-recoil-return",
      "version": 2,
      "title": "Recoiltracking en terugkeer naar het richtgebied",
      "shortPromise": "Observeer waar het geweer na ieder schot terugkomt zonder een terugkeerpatroon als automatische foutdiagnose te gebruiken.",
      "category": "benchrest",
      "disciplines": ["br50"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 11,
      "prerequisites": ["br50-rest-axis@2"],
      "applicability": ["Live-fire BR50 met veilige en toegestane steunopstelling.", "De app meet geen dynamische recoiltrace; observaties worden door de gebruiker vastgelegd."],
      "sections": [
        {"type":"overview","title":"Terugkeer is procesinformatie","paragraphs":["Kijk na het schot waar het veilige geweer en vizierbeeld zich bevinden ten opzichte van het gekozen bull. Een consistente terugkeer kan helpen de opstelling te beoordelen, maar garandeert geen score."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"setup","title":"Kies één observatiereferentie","paragraphs":["Gebruik een bullrand, rasterrichting of vooraf getekende neutrale referentie. Noteer hoe contact en steun vóór de reeks zijn opgebouwd."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"sequence","title":"Schot en observatie","paragraphs":[],"steps":["Richt op het gekozen record- of oefenbull.","Voer het schot uit zonder contact tijdens de terugslag bewust te corrigeren.","Observeer de eerste stabiele terugkeerzone.","Maak het geweer veilig voordat steun of positie wordt aangepast."],"sourceIds":["cmp-safety"]},
        {"type":"observe","title":"Richting en herhaalbaarheid","paragraphs":["Noteer alleen terugkeer naar dezelfde zone, een herhaalde richting of een onduidelijke waarneming. Vermijd onmiddellijk materiaal te verstellen."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"abortOrReset","title":"Onveilige of plots veranderde baan","paragraphs":["Stop wanneer het geweer klemt, van de steun dreigt te lopen, bediening wordt geblokkeerd of het terugkeerpatroon abrupt verandert."],"steps":[],"sourceIds":["cmp-safety"]},
        {"type":"variation","title":"Kolf, steun en kaliber","paragraphs":["Recoilgedrag verschilt door materiaal en contactstrategie. Vergelijk alleen binnen dezelfde opstelling en gebruik geen .22-observatie als algemene norm voor andere systemen."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"evidence","title":"Geen sensordata","paragraphs":["De app heeft geen SCATT-achtige aimtrace of krachtsensor. Ze kan daarom richting en timing van terugslag niet automatisch reconstrueren."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"practice","title":"Vijf terugkeercalls","paragraphs":[],"steps":["Kies één referentie.","Schiet vijf recordbulls volgens dezelfde setup.","Geef na ieder schot alleen een terugkeerzonecall.","Vergelijk na veilig afleggen de calls met groeps- en scoredata."],"sourceIds":["issf-education"]},
        {"type":"limits","title":"Geen bewijs voor een contactfout","paragraphs":["Een afwijkende terugkeer kan meerdere oorzaken hebben. Bevestig eerst dat de observatie herhaalbaar is en test daarna één variabele."],"steps":[],"sourceIds":["issf-education"]}
      ],
      "diagramIds": ["br50-recoil-return"],
      "selfChecks": [{"prompt":"Kan ik de terugkeerzone benoemen zonder meteen iets te verstellen?","observableSuccess":"Vijf observaties gebruiken dezelfde referentie en blijven gescheiden van de score.","resetIf":"Steun, contact of observatiereferentie verandert."}],
      "linkedDrillIds": ["br50-five-record-bulls@2", "br50-rebuild-rest@2"],
      "safetyCallouts": [{"title":"Stop bij onvrije beweging","instruction":"Maak het geweer onmiddellijk veilig wanneer het klemt, steun verlaat of bediening wordt gehinderd."}],
      "references": [{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 7 en pp. 9-12: feedback, correctie, materiaaltest en trainingsplanning"},{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"§§ B.8-B.10, pp. 14-16: vrije steunbeweging en verbod op terugslagbeperking"},{"id":"cmp-safety","title":"Safety","url":"https://thecmp.org/safety/","publisher":"Civilian Marksmanship Program","documentEdition":"webpagina, geraadpleegd 2026-08-10","locator":"secties ‘Rules for Safe Gun Handling’ en ‘The Goal: No Gun Accidents’"}],
      "review": {"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF/WRABF/CMP, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "br50-sighters-record-bulls",
      "version": 2,
      "title": "Sighters, recordbulls, lege bulls en dubbelschoten",
      "shortPromise": "Voer het BR50-kaartprotocol bewust uit en herken beslissingen die de app niet uit een foto mag raden.",
      "category": "matchProcess",
      "disciplines": ["br50"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 13,
      "prerequisites": ["br50-rest-rules@2"],
      "applicability": ["WRABF BR50-kaarten met 25 recordbulls en zes sighters.", "Gebruik altijd de actuele officiële kaart en regels voor wedstrijdtraining."],
      "sections": [
        {"type":"overview","title":"Twee soorten bulls","paragraphs":["De officiële kaart heeft 25 tellende recordbulls en zes afzonderlijke sighters. Een sighter is oefeninformatie; een recordbull hoort bij de scorekaart."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"setup","title":"Ken de indeling vóór het eerste schot","paragraphs":["Controleer kaartoriëntatie, recordnummering en sighterzones. Gebruik de overlay of getekende kaart alleen als trainingshulp; de officiële papieren kaart blijft leidend."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"sequence","title":"Sighter naar record","paragraphs":[],"steps":["Gebruik sighters volgens het vooraf gekozen protocol.","Kies het eerste recordbull bewust.","Registreer ieder recordbull direct in je kaartvolgorde.","Controleer na ieder blok welke recordbulls nog leeg zijn."],"sourceIds":["wrabf-rules"]},
        {"type":"observe","title":"Leeg, misser of dubbel","paragraphs":["Een leeg recordbull, een schot buiten papier en meerdere gaten in één bull zijn verschillende gebeurtenissen. De gebruiker bevestigt deze toestand; beeldherkenning mag ze niet verzinnen."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"abortOrReset","title":"Stop bij verloren kaartpositie","paragraphs":["Wanneer je niet meer zeker weet welk bull aan de beurt is, maak je het geweer veilig en controleer je de kaartvolgorde. Een gok kan niet achteraf betrouwbaar worden gereconstrueerd."],"steps":[],"sourceIds":["cmp-safety","wrabf-rules"]},
        {"type":"variation","title":"Trainingsvolgorde versus wedstrijdprocedure","paragraphs":["Een vijf-bullsdrill kan een deel van de kaart gebruiken; een volledige repetitie volgt de gekozen wedstrijdvolgorde. Label de activiteit zodat resultaten niet worden gemengd."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"evidence","title":"Inward scoring en kaartopbouw","paragraphs":["WRABF vermeldt 25 scoring targets, zes sighters en inward scoring. De app gebruikt deze regels versiegebonden en presenteert zichzelf niet als wedstrijdcertificering."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"practice","title":"Doe een kaartwalkthrough","paragraphs":[],"steps":["Wijs zonder te schieten alle sighters aan.","Loop de gekozen volgorde van 25 recordbulls door.","Oefen de stop bij een verloren nummer.","Start daarna vijf recordbulls live fire."],"sourceIds":["wrabf-rules"]},
        {"type":"limits","title":"Foto kent geen schotgeschiedenis","paragraphs":["Eén achteraffoto kan oude gaten, nieuwe gaten, schotvolgorde en exact overlappende treffers niet betrouwbaar onderscheiden. De gebruiker blijft autoritatief."],"steps":[],"sourceIds":["wrabf-rules"]}
      ],
      "diagramIds": ["br50-sighter-record-map"],
      "selfChecks": [{"prompt":"Weet ik vóór ieder live schot welk recordbull of sighter actief is?","observableSuccess":"De gekozen kaartvolgorde is zichtbaar en lege of dubbele bulls worden bewust geregistreerd.","resetIf":"Het actieve bullnummer onzeker is of kaartoriëntatie verandert."}],
      "linkedDrillIds": ["br50-sighter-to-record@2", "br50-full-card-rehearsal@2"],
      "safetyCallouts": [{"title":"Controleer kaart alleen veilig","instruction":"Stop en maak het geweer veilig voordat je een verloren bullvolgorde op telefoon of kaart controleert."}],
      "references": [{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"§ scoring, p. 21 en Appendix E, p. 54: 25 recordbulls, sighters, inward scoring, dubbelschoten en strafpunten"},{"id":"cmp-safety","title":"Safety","url":"https://thecmp.org/safety/","publisher":"Civilian Marksmanship Program","documentEdition":"webpagina, geraadpleegd 2026-08-10","locator":"secties ‘Rules for Safe Gun Handling’ en ‘The Goal: No Gun Accidents’"}],
      "review": {"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"WRABF V4.4, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "br50-card-blocks-conditions",
      "version": 2,
      "title": "Kaart in blokken uitvoeren en omstandigheden registreren",
      "shortPromise": "Verdeel 25 recordbulls in zichtbare werkblokken zonder te doen alsof bullnummer gelijkstaat aan schotvolgorde.",
      "category": "matchProcess",
      "disciplines": ["br50"],
      "levels": ["foundation", "development"],
      "estimatedMinutes": 13,
      "prerequisites": ["br50-sighters-record-bulls@2", "reading-target-evidence@2"],
      "applicability": ["Volledige of gedeeltelijke BR50-kaarten.", "Omstandigheden worden handmatig en lokaal vastgelegd; de app gebruikt geen automatische weerclaim."],
      "sections": [
        {"type":"overview","title":"Vijf zichtbare blokken","paragraphs":["Groepeer de kaart in vijf blokken van vijf recordbulls. Dat maakt voortgang, rust en context zichtbaar zonder achteraf een onbekende individuele schotvolgorde te verzinnen."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"setup","title":"Kies blokvolgorde en context","paragraphs":["Leg vóór live fire de vijf blokken vast en noteer alleen omstandigheden die je daadwerkelijk kunt waarnemen, zoals lichtverandering, windindicatie of baanonderbreking."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"sequence","title":"Werk blok voor blok","paragraphs":[],"steps":["Gebruik sighters volgens je protocol.","Voltooi vijf recordbulls.","Maak het geweer veilig voor app- of kaartcontrole.","Noteer alleen een relevante verandering en start het volgende blok."],"sourceIds":["wrabf-rules","cmp-safety"]},
        {"type":"observe","title":"Zonepatronen zijn beschrijvend","paragraphs":["Vergelijk score, leeg/dubbelstatus en lokale impactpositie per blok. Een lager blok bewijst niet automatisch vermoeidheid of veranderde wind."],"steps":[],"sourceIds":["issf-education"]},
        {"type":"abortOrReset","title":"Onderbreking als contextgrens","paragraphs":["Na een baanonderbreking, steunverplaatsing of duidelijke conditieverandering begin je een nieuw contextblok. Voeg de data niet stil samen."],"steps":[],"sourceIds":["cmp-safety"]},
        {"type":"variation","title":"Rij, kolom of eigen volgorde","paragraphs":["De visuele blokken hoeven geen vaste rijvolgorde te volgen. Kies één vooraf herkenbare indeling en bewaar die als plansnapshot."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"evidence","title":"Bullpositie is geen tijdstip","paragraphs":["De kaartgeometrie kent bullnummers, maar zonder expliciet opgeslagen uitvoeringsvolgorde kent de analyse niet welk bull vroeg of laat werd geschoten."],"steps":[],"sourceIds":["wrabf-rules"]},
        {"type":"practice","title":"Vijf-bullsblok","paragraphs":[],"steps":["Kies één blok en markeer de vijf bulls.","Schiet ze volgens je vastgelegde volgorde.","Maak het geweer veilig.","Registreer toestand en één korte contextnotitie voordat je analyseert."],"sourceIds":["wrabf-rules"]},
        {"type":"limits","title":"Geen automatische winddiagnose","paragraphs":["Zonder gekalibreerde wind- of tracegegevens kan een zonepatroon meerdere verklaringen hebben. De app noemt omstandigheden als context, niet als bewezen oorzaak."],"steps":[],"sourceIds":["issf-education"]}
      ],
      "diagramIds": ["br50-five-blocks", "br50-condition-blocks"],
      "selfChecks": [{"prompt":"Zijn de vijf bulls en hun context vóór het blok vastgelegd?","observableSuccess":"Na het blok kan ik score, status en context tonen zonder een onbekende schotvolgorde in te vullen.","resetIf":"Volgorde, steun of omstandigheden wezenlijk wijzigen zonder nieuwe contextgrens."}],
      "linkedDrillIds": ["br50-five-block-card@2", "br50-cold-card@2", "br50-full-card-rehearsal@2"],
      "safetyCallouts": [{"title":"Context noteren na veilig maken","instruction":"Bedien de app uitsluitend tussen blokken nadat het geweer volgens de baanprocedure veilig is."}],
      "references": [{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"Appendix E, p. 54: recordbulls, sighters en kaartprotocol"},{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 7 en pp. 9-12: dagboek, omstandigheden, feedback, profiling en planning"},{"id":"cmp-safety","title":"Safety","url":"https://thecmp.org/safety/","publisher":"Civilian Marksmanship Program","documentEdition":"webpagina, geraadpleegd 2026-08-10","locator":"secties ‘Rules for Safe Gun Handling’ en ‘The Goal: No Gun Accidents’"}],
      "review": {"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"WRABF/ISSF/CMP, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    }
  ]
}
''';

const builtInDrillsJson = r'''{
  "schemaVersion": 2,
  "locale": "nl-BE",
  "drills": [
    {
      "id":"pistol-blank-sight-picture","version":2,"title":"Vizierbeeld op blanco vlak","shortPurpose":"Isoleer vizieruitlijning en geleidelijke trekkerdruk zonder dat ringscore je aandacht overneemt.","discipline":"precisionPistol","skillLevel":"foundation","mode":"rangeDryFire","estimatedDurationMinutes":15,"ammunitionBudget":0,"prerequisites":["pistol-sight-alignment-picture@2","pistol-progressive-trigger@2"],
      "setup":{"target":"Blanco, veilige richtzone of omgekeerde kaart volgens baanregels","distance":"Door baan en coach goedgekeurde positie","equipment":["Veilig precisiepistool","Par- of cadanstimer optioneel","Geen munitie in de droge oefenzone"],"dataBasis":"Vijf gecontroleerde uitvoeringen en één korte zelfevaluatie","safetyGate":"Erkende baan; toestemming; wapen, kamer en magazijn gecontroleerd; munitie fysiek gescheiden; veilige richting bevestigd."},
      "phases":[
        {"id":"safety","title":"Veiligheidspoort","instructions":["Laat de droge opstelling controleren volgens de lokale baanprocedure.","Bevestig dat munitie fysiek gescheiden is en de monding veilig blijft."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"safe-range-phone-routine@2"},
        {"id":"observe","title":"Drie opbouwen zonder trekkeractie","instructions":["Bouw korrelhoogte en gelijke lichtruimte op.","Observeer de normale beweging zonder die stil te duwen.","Laat veilig zakken en herhaal volledig."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":20,"linkedTechniqueId":"pistol-visual-focus-movement@2"},
        {"id":"execute","title":"Vijf droge uitvoeringen","instructions":["Start iedere uitvoering vanaf dezelfde veilige gereedpositie.","Laat vizierrelatie en geleidelijke trekkerdruk samen doorlopen.","Breek af zodra de vizierrelatie of comfortabele tijd wegvalt."],"completionKind":"timerActivity","seriesCount":null,"shotsPerSeries":null,"restSeconds":25,"linkedTechniqueId":"pistol-progressive-trigger@2"},
        {"id":"reflect","title":"Korte evaluatie","instructions":["Kies: vizierrelatie herkenbaar, wisselend of onvoldoende zichtbaar.","Noteer hoogstens één concrete observatie; maak geen foutdiagnose."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"pistol-sight-alignment-picture@2"}
      ],
      "measurements":[
        {"metric":"completion","direction":"complete","role":"primary","minimumSampleSize":4,"baselineEligible":false,"interpretation":"De vier geplande fasen zijn veilig en volledig doorlopen; geen scoredoel."},
        {"metric":"selfEvaluation","direction":"stabilize","role":"secondary","minimumSampleSize":1,"baselineEligible":false,"interpretation":"De zelfevaluatie beschrijft zichtbare relatie, niet de oorzaak van een afwijking."}
      ],
      "masteryRule":{"minimumValidExecutions":1,"requiredSuccesses":1,"evaluationWindow":1,"usesPersonalBaseline":false,"explanation":"Voltooid na één veilig uitgevoerde cyclus. Herhaalbaarheid wordt pas in live korte groepen beoordeeld."},
      "stopRules":["Stop onmiddellijk bij munitie in de droge zone, een baanbevel of twijfel over de wapentoestand.","Stop bij pijn, visuele klachten of een onveilige mondingsroute."],
      "reflectionPrompts":["Bleef korrelhoogte en lichtruimte herkenbaar tijdens de druk?","Op welk observeerbaar signaal brak je de uitvoering af?"],
      "progression":{"usableResult":"Ga naar drie basisgroepen en behoud dezelfde vizieropdracht.","insufficientData":"Herhaal alleen de ontbrekende veilige uitvoeringen; voeg geen scoredoel toe.","unreliableResult":"Laat de opstelling en veilige droge procedure opnieuw door baanverantwoordelijke of coach controleren.","nextDrillId":"pistol-three-baseline-groups@2"},
      "diagramIds":["pistol-sight-relationship","pistol-trigger-contact"],"techniqueReferences":["safe-range-phone-routine@2","pistol-sight-alignment-picture@2","pistol-visual-focus-movement@2","pistol-progressive-trigger@2"],
      "references":[{"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"§ Pistol Training, blanco-kaartoefening, gedrukte pp. 26-27 (PDF pp. 31-32)"},{"id":"cmp-safety","title":"Safety","url":"https://thecmp.org/safety/","publisher":"Civilian Marksmanship Program","documentEdition":"webpagina, geraadpleegd 2026-08-10","locator":"secties ‘Rules for Safe Gun Handling’ en ‘The Goal: No Gun Accidents’"}],
      "review":{"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"CMP, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id":"pistol-three-baseline-groups","version":2,"title":"Drie basisgroepen van vijf","shortPurpose":"Bouw een eerste persoonlijke groepsbaseline op zonder tijdens de reeks door score te worden gestuurd.","discipline":"precisionPistol","skillLevel":"foundation","mode":"liveFire","estimatedDurationMinutes":25,"ammunitionBudget":15,"prerequisites":["pistol-natural-alignment@2","pistol-sight-alignment-picture@2"],
      "setup":{"target":"ISSF 25 m Precision / 50 m Pistol","distance":"Dezelfde ingestelde afstand voor alle drie reeksen","equipment":["Hetzelfde pistool","Hetzelfde munitieprofiel of lot","Drie afzonderlijk bevestigde reeksen"],"dataBasis":"Vijftien positionele treffers verdeeld over drie reeksen van vijf","safetyGate":"Normale live-firebaanprocedure; app alleen bedienen nadat het pistool veilig is afgelegd."},
      "phases":[
        {"id":"prepare","title":"Eén uitvoeringsdoel","instructions":["Kies één observeerbare opdracht, bijvoorbeeld dezelfde vizierrelatie.","Leg kaart, afstand, pistool en munitie vast."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"pistol-sight-alignment-picture@2"},
        {"id":"groups","title":"Drie groepen","instructions":["Schiet vijf schoten zonder tussentijds de score te corrigeren.","Bevestig de reeks en neem minimaal zestig seconden rust.","Herhaal tot drie afzonderlijke geldige reeksen zijn gekoppeld."],"completionKind":"confirmedSeries","seriesCount":3,"shotsPerSeries":5,"restSeconds":60,"linkedTechniqueId":"pistol-natural-alignment@2"},
        {"id":"review","title":"Vergelijk beschrijvend","instructions":["Vergelijk mean radius en groepscentrum.","Noteer één waarneembaar verschil tussen de opbouwen.","Wijs geen oorzaak toe op basis van één treffer."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"reading-target-evidence@2"}
      ],
      "measurements":[
        {"metric":"meanRadiusMm","direction":"minimize","role":"primary","minimumSampleSize":15,"baselineEligible":true,"interpretation":"Gebruik de gezamenlijke en per-reeks mean radius; kleiner is alleen betekenisvol binnen dezelfde combinatie."},
        {"metric":"absoluteBiasMm","direction":"stabilize","role":"secondary","minimumSampleSize":15,"baselineEligible":true,"interpretation":"Groepscentrum beschrijft centrering maar stelt geen techniekdiagnose."}
      ],
      "masteryRule":{"minimumValidExecutions":3,"requiredSuccesses":2,"evaluationWindow":3,"usesPersonalBaseline":true,"explanation":"Na drie geldige uitvoeringen over minstens twee sessies ontstaat de baseline; daarna tellen twee bruikbare uitvoeringen in de laatste drie."},
      "stopRules":["Markeer de activiteit onbetrouwbaar wanneer kaart, afstand, pistool of munitie tussen groepen wijzigt.","Stop wanneer veilige bediening, zicht of lichamelijk comfort verslechtert."],
      "reflectionPrompts":["Welke opbouwreferentie bleef in alle drie reeksen gelijk?","Was het verschil vooral centrum, spreiding of beide?"],
      "progression":{"usableResult":"Gebruik de baseline in de drill voor het herhaalbare uitvoeringsvenster.","insufficientData":"Voeg alleen ontbrekende geldige reeksen toe binnen dezelfde combinatie.","unreliableResult":"Start later opnieuw met één vastgelegde kaart-, wapen- en munitiecombinatie.","nextDrillId":"pistol-repeatable-window@2"},
      "diagramIds":["target-evidence-layers","pistol-stance-chain"],"techniqueReferences":["pistol-natural-alignment@2","pistol-feet-body-arm@2","pistol-sight-alignment-picture@2","reading-target-evidence@2"],
      "references":[{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"pp. 9-12: practical assignments, diary, feedback and performance profiling"}],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF Education Reform Plan, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id":"pistol-repeatable-window","version":2,"title":"Herhaalbaar uitvoeringsvenster","shortPurpose":"Oefen armheffing, ademritme en geleidelijke trekkerdruk als één begrensd proces.","discipline":"precisionPistol","skillLevel":"development","mode":"mixedOnRange","estimatedDurationMinutes":30,"ammunitionBudget":15,"prerequisites":["pistol-arm-lift-approach@2","pistol-breathing-window@2","pistol-progressive-trigger@2"],
      "setup":{"target":"ISSF Precision-profiel","distance":"Normale trainingsafstand","equipment":["Precisiepistool","Parsignaal alleen als procesbegrenzing","Drie reeksen van vijf"],"dataBasis":"Drie bevestigde reeksen, drie reflecties en geregistreerde afbreekmomenten","safetyGate":"Droge voorbereiding uitsluitend op een erkende baan, na controle en met munitie fysiek gescheiden; fasen met schot volgen alle baancommando's."},
      "phases":[
        {"id":"rehearse","title":"Droge repetitie op de baan","instructions":["Doorloop drie veilige opbouwen zonder schot.","Benoem het comfortabele uitvoeringsvenster.","Breek minstens één bewust te lange opbouw veilig af."],"completionKind":"timerActivity","seriesCount":null,"shotsPerSeries":null,"restSeconds":30,"linkedTechniqueId":"pistol-breathing-window@2"},
        {"id":"live","title":"Drie korte reeksen","instructions":["Gebruik dezelfde hefroute en ademcue.","Voer vijf live schoten uit; forceer geen schot buiten het venster.","Bevestig iedere reeks en rust minimaal één minuut."],"completionKind":"confirmedSeries","seriesCount":3,"shotsPerSeries":5,"restSeconds":60,"linkedTechniqueId":"pistol-progressive-trigger@2"},
        {"id":"reflect","title":"Procescontrole","instructions":["Registreer per reeks goed, neutraal of moeilijk.","Noteer het aantal bewuste afbrekingen zonder die als fout te beoordelen."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"pistol-follow-through-reset@2"}
      ],
      "measurements":[
        {"metric":"consistency","direction":"stabilize","role":"primary","minimumSampleSize":3,"baselineEligible":true,"interpretation":"Vergelijk variatie in score en groepsmaten tussen drie gelijk opgebouwde reeksen."},
        {"metric":"selfEvaluation","direction":"stabilize","role":"secondary","minimumSampleSize":3,"baselineEligible":true,"interpretation":"Zelfevaluatie is context en geen automatische technische oorzaak."}
      ],
      "masteryRule":{"minimumValidExecutions":3,"requiredSuccesses":2,"evaluationWindow":3,"usesPersonalBaseline":true,"explanation":"Na baselinevorming geldt twee van de laatste drie geldige uitvoeringen zonder protocolwaarschuwing."},
      "stopRules":["Stop bij geforceerde ademstop, pijn of een onveilige mondingsroute.","Markeer onbetrouwbaar wanneer parsignaal de veilige uitvoering dwingt in plaats van begrenst."],
      "reflectionPrompts":["Op welk concreet signaal brak je af?","Bleef de uitvoering gelijk wanneer het richtbeeld groter bewoog?"],
      "progression":{"usableResult":"Ga naar centrum-versus-spreiding of een koude eerste reeks.","insufficientData":"Herhaal alleen tot drie geldige reeksen en reflecties beschikbaar zijn.","unreliableResult":"Verwijder het tijdsignaal en oefen eerst opnieuw zonder externe druk.","nextDrillId":"pistol-centre-vs-spread@2"},
      "diagramIds":["pistol-breath-trigger-timeline","pistol-abort-reset-tree"],"techniqueReferences":["pistol-arm-lift-approach@2","pistol-breathing-window@2","pistol-progressive-trigger@2","pistol-follow-through-reset@2"],
      "references":[{"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"§§ Preparation for Firing Precision Pistol Shots en Firing Precision Pistol Shots, gedrukte pp. 20-24 (PDF pp. 25-29)"}],
      "review":{"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"CMP Junior Pistol Guide, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id":"pistol-centre-vs-spread","version":2,"title":"Groepscentrum tegenover spreiding","shortPurpose":"Bepaal of de grootste scorekloof in deze training bij centrering, spreiding of beide ligt.","discipline":"precisionPistol","skillLevel":"development","mode":"analysisOnly","estimatedDurationMinutes":20,"ammunitionBudget":0,"prerequisites":["reading-target-evidence@2","pistol-three-baseline-groups@2"],
      "setup":{"target":"Drie of meer vergelijkbare bevestigde ISSF-reeksen","distance":"Exact dezelfde afstand","equipment":["Dezelfde targetprofielversie","Bij voorkeur hetzelfde pistool en munitieprofiel","Analyseweergave met groepscentrum en mean radius"],"dataBasis":"Minimaal vijftien positionele treffers en drie reeksen","safetyGate":"Analyse gebeurt pas nadat het wapen veilig is opgeborgen of afgelegd en de baanprocedure appgebruik toestaat."},
      "phases":[
        {"id":"select","title":"Selecteer vergelijkbare data","instructions":["Controleer targetversie, afstand en uitrusting.","Sluit geen verre treffers automatisch uit.","Lees waarschuwingen voor missers, multipliciteit en uitlijning."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"reading-target-evidence@2"},
        {"id":"compare","title":"Lees centrum en spreiding apart","instructions":["Benoem eerst de absolute bias.","Benoem daarna mean radius en extreme spread.","Gebruik potential score alleen als what-ifverschuiving, niet als vizieradvies."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"reading-target-evidence@2"},
        {"id":"experiment","title":"Plan één volgende test","instructions":["Kies centrering of spreiding als primaire vraag.","Koppel één passende live drill zonder materiaal en techniek tegelijk te wijzigen."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"one-variable-comparison@2"}
      ],
      "measurements":[
        {"metric":"absoluteBiasMm","direction":"minimize","role":"primary","minimumSampleSize":15,"baselineEligible":true,"interpretation":"Absolute bias beschrijft de afstand van groepscentrum tot richtpunt."},
        {"metric":"meanRadiusMm","direction":"minimize","role":"secondary","minimumSampleSize":15,"baselineEligible":true,"interpretation":"Mean radius beschrijft spreiding rond het berekende groepscentrum."}
      ],
      "masteryRule":{"minimumValidExecutions":1,"requiredSuccesses":1,"evaluationWindow":1,"usesPersonalBaseline":false,"explanation":"Voltooid wanneer de databasis geldig is en een volgende test met één variabele is vastgelegd."},
      "stopRules":["Stop bij gemengde targetversies, afstanden of onduidelijke foto-uitlijning.","Verwijder geen outlier alleen om een hypothese te laten passen."],
      "reflectionPrompts":["Welke meetwaarde beantwoordt de gekozen trainingsvraag?","Welke ene variabele verander je in de volgende test?"],
      "progression":{"usableResult":"Start de gekozen centreer- of spreidingsdrill met dezelfde combinatie.","insufficientData":"Verzamel eerst drie vergelijkbare reeksen met samen minstens vijftien positionele treffers.","unreliableResult":"Herstel profiel-, afstand- of uitlijningsdata vóór verdere interpretatie.","nextDrillId":"pistol-three-baseline-groups@2"},
      "diagramIds":["target-evidence-layers"],"techniqueReferences":["reading-target-evidence@2","one-variable-comparison@2"],
      "references":[{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"pp. 9-12: performance profiling, goals, feedback and diary"}],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF Education Reform Plan, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id":"pistol-cold-series","version":2,"title":"Koude eerste reeks","shortPurpose":"Bewaar de eerste geldige live reeks als aparte benchmark, zonder voorafgaande proefgroep.","discipline":"precisionPistol","skillLevel":"development","mode":"liveFire","estimatedDurationMinutes":15,"ammunitionBudget":5,"prerequisites":["pistol-follow-through-reset@2","pistol-three-baseline-groups@2"],
      "setup":{"target":"ISSF Precision-profiel","distance":"Vaste trainings- of wedstrijdafstand","equipment":["Normale wedstrijdachtige uitrusting","Exact vijf schoten","Geen voorafgaande live proefreeks in deze sessie"],"dataBasis":"Eén eerste bevestigde reeks plus directe reflectie","safetyGate":"Normale baancontrole en materiaalinspectie vóór de eerste live reeks; geen appbediening met onveilig pistool."},
      "phases":[
        {"id":"prepare","title":"Normale voorbereiding","instructions":["Gebruik je gewone veilige materiaal- en positiecontrole.","Voeg geen extra opwarmgroep toe voor de meting.","Kies één korte procescue."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"pistol-follow-through-reset@2"},
        {"id":"cold","title":"Eerste reeks","instructions":["Schiet exact vijf live schoten.","Geef per schot alleen een korte call wanneer dat veilig zonder telefoon kan.","Bevestig de reeks als eerste serie van de sessie."],"completionKind":"confirmedSeries","seriesCount":1,"shotsPerSeries":5,"restSeconds":null,"linkedTechniqueId":"pistol-follow-through-reset@2"},
        {"id":"reflect","title":"Directe context","instructions":["Kies goed, neutraal of moeilijk.","Noteer alleen voorbereiding, gevoel of baancontext die werkelijk aanwezig was."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"reading-target-evidence@2"}
      ],
      "measurements":[
        {"metric":"scorePercentage","direction":"stabilize","role":"primary","minimumSampleSize":1,"baselineEligible":true,"interpretation":"Vergelijk alleen met eerdere koude eerste reeksen van dezelfde combinatie."},
        {"metric":"meanRadiusMm","direction":"minimize","role":"secondary","minimumSampleSize":5,"baselineEligible":true,"interpretation":"Groepsgrootte blijft voorlopig bij vijf positionele treffers."}
      ],
      "masteryRule":{"minimumValidExecutions":3,"requiredSuccesses":2,"evaluationWindow":3,"usesPersonalBaseline":true,"explanation":"De persoonlijke koude baseline ontstaat na drie geldige sessies; daarna zijn twee van de laatste drie bruikbaar wanneer ze binnen de eigen band blijven."},
      "stopRules":["Ongeldig wanneer eerder in dezelfde sessie live werd geschoten.","Stop bij materiaal-, baan- of gezondheidsprobleem; een afgebroken sessie is geen mislukte benchmark."],
      "reflectionPrompts":["Was de normale voorbereiding volledig of aangepast?","Welk verschil met latere reeksen wil je alleen beschrijvend opvolgen?"],
      "progression":{"usableResult":"Bewaar de koude benchmark en vervolg met de geplande training.","insufficientData":"Herhaal op volgende sessies; voeg geen latere reeks als koude reeks toe.","unreliableResult":"Bewaar de context maar sluit de run uit de koude baseline uit.","nextDrillId":"pistol-match-block@2"},
      "diagramIds":["pistol-abort-reset-tree"],"techniqueReferences":["pistol-follow-through-reset@2","reading-target-evidence@2"],
      "references":[{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"pp. 9-12: diary, profiling and individual goals"}],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF Education Reform Plan, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id":"pistol-match-block","version":2,"title":"ISSF 25/50 m wedstrijdblok","shortPurpose":"Oefen een vooraf vastgelegde wedstrijdachtige reeksstructuur met protocol, herstel en nabespreking.","discipline":"precisionPistol","skillLevel":"development","mode":"matchSimulation","estimatedDurationMinutes":45,"ammunitionBudget":30,"prerequisites":["pistol-repeatable-window@2","pistol-cold-series@2"],
      "setup":{"target":"ISSF 25 m Precision / 50 m Pistol-profiel","distance":"Gekozen officiële of trainingsafstand, vast voor het blok","equipment":["Wedstrijdachtige pistool- en munitiecombinatie","Zes reeksen van vijf","Timer alleen volgens gekozen disciplineprotocol"],"dataBasis":"Zes bevestigde reeksen, totale score, groepsconsistentie en reflectie","safetyGate":"Baanregels, actuele disciplineprocedure en range commands hebben voorrang op de app."},
      "phases":[
        {"id":"brief","title":"Protocol vastleggen","instructions":["Kies afstand, timing en aantal reeksen vóór het eerste schot.","Controleer dat de gekozen structuur past bij je discipline en baan.","Leg één procesdoel vast."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"pistol-follow-through-reset@2"},
        {"id":"block-a","title":"Reeksen 1-3","instructions":["Schiet drie reeksen van vijf volgens hetzelfde protocol.","Bevestig iedere reeks afzonderlijk.","Gebruik alleen geplande rust; wijzig geen materiaal."],"completionKind":"confirmedSeries","seriesCount":3,"shotsPerSeries":5,"restSeconds":60,"linkedTechniqueId":"pistol-breathing-window@2"},
        {"id":"reset","title":"Geplande reset","instructions":["Maak het pistool veilig.","Herhaal alleen de vaste procescue en controleer materiaal zonder instelling te wijzigen."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":120,"linkedTechniqueId":"pistol-follow-through-reset@2"},
        {"id":"block-b","title":"Reeksen 4-6","instructions":["Schiet de laatste drie reeksen volgens hetzelfde protocol.","Bewaar iedere reeks afzonderlijk.","Forceer geen schot om de bloktijd te herstellen."],"completionKind":"confirmedSeries","seriesCount":3,"shotsPerSeries":5,"restSeconds":60,"linkedTechniqueId":"pistol-progressive-trigger@2"},
        {"id":"debrief","title":"Nabespreking","instructions":["Vergelijk beide blokken beschrijvend.","Noteer één processterkte en één volgende test.","Pas geen diagnosekaart toe op losse treffers."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"reading-target-evidence@2"}
      ],
      "measurements":[
        {"metric":"scorePercentage","direction":"maximize","role":"primary","minimumSampleSize":6,"baselineEligible":true,"interpretation":"Totale score en percentage worden alleen met hetzelfde blokprotocol vergeleken."},
        {"metric":"consistency","direction":"stabilize","role":"secondary","minimumSampleSize":6,"baselineEligible":true,"interpretation":"Vergelijk variatie tussen reeksen en blokken zonder reeksvolgorde als technische oorzaak te benoemen."}
      ],
      "masteryRule":{"minimumValidExecutions":3,"requiredSuccesses":2,"evaluationWindow":3,"usesPersonalBaseline":true,"explanation":"Na drie geldige volledige blokken bepalen twee stabiele uitvoeringen in de laatste drie de persoonlijke voortgang."},
      "stopRules":["Stop bij onveilige toestand, baanbevel of materiaalstoring.","Markeer onbetrouwbaar wanneer timing, afstand, kaart of uitrusting halverwege wijzigt."],
      "reflectionPrompts":["Bleef dezelfde procescue bruikbaar in beide blokken?","Waar verschilden score en consistentie zonder daar meteen een oorzaak aan te koppelen?"],
      "progression":{"usableResult":"Herhaal later hetzelfde protocol of bespreek de coachreflectie.","insufficientData":"Een onvolledig blok wordt bewaard maar niet in de volledige-blokbaseline opgenomen.","unreliableResult":"Gebruik de gekoppelde reeksen afzonderlijk en sluit de activiteit uit van wedstrijdblokvergelijking.","nextDrillId":null},
      "diagramIds":["pistol-breath-trigger-timeline","pistol-abort-reset-tree"],"techniqueReferences":["pistol-breathing-window@2","pistol-progressive-trigger@2","pistol-follow-through-reset@2","reading-target-evidence@2"],
      "references":[{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"pp. 9-12: competition preparation, profiling, feedback and goals"}],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF Education Reform Plan, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id":"br50-five-record-bulls","version":2,"title":"Vijf recordbulls","shortPurpose":"Oefen één schot per recordbull met bewuste kaartpositie, terugkeerobservatie en veilige controle.","discipline":"br50","skillLevel":"foundation","mode":"liveFire","estimatedDurationMinutes":20,"ammunitionBudget":5,"prerequisites":["br50-rest-rules@2","br50-recoil-return@2"],
      "setup":{"target":"WRABF BR50 trainingsweergave of officiële kaart","distance":"50 m","equipment":["Toegestane rimfire benchrestopstelling","Vijf vooraf gekozen recordbulls","Optionele sighters volgens protocol"],"dataBasis":"Vijf beoordeelde recordbulls en vijf terugkeerobservaties","safetyGate":"Geweer veilig bij iedere kaart- of appcontrole; actuele WRABF- en baanregels bevestigd."},
      "phases":[
        {"id":"map","title":"Vijf bulls vastleggen","instructions":["Wijs de vijf recordbulls en volgorde aan.","Controleer kaartoriëntatie en onderscheid met sighters.","Leg één terugkeerreferentie vast."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"br50-sighters-record-bulls@2"},
        {"id":"fire","title":"Eén schot per bull","instructions":["Schiet precies één gepland schot per recordbull.","Observeer de eerste stabiele terugkeerzone.","Verander steun of contact niet tijdens de vijf bulls."],"completionKind":"confirmedSeries","seriesCount":1,"shotsPerSeries":5,"restSeconds":null,"linkedTechniqueId":"br50-recoil-return@2"},
        {"id":"review","title":"Bullstatus controleren","instructions":["Controleer gevuld, leeg, misser of dubbel per bull.","Bevestig handmatig iedere afwijking.","Noteer terugkeer zonder automatische oorzaakclaim."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"reading-target-evidence@2"}
      ],
      "measurements":[
        {"metric":"filledBullCount","direction":"maximize","role":"primary","minimumSampleSize":5,"baselineEligible":false,"interpretation":"De protocolmeting vereist vijf bewust beoordeelde recordbulls; leeg telt zichtbaar als leeg of nul."},
        {"metric":"scorePercentage","direction":"maximize","role":"secondary","minimumSampleSize":1,"baselineEligible":true,"interpretation":"Score is secundair aan correcte kaartuitvoering en wordt alleen met dezelfde vijf-bullsopzet vergeleken."}
      ],
      "masteryRule":{"minimumValidExecutions":3,"requiredSuccesses":2,"evaluationWindow":3,"usesPersonalBaseline":true,"explanation":"Baseline na drie geldige uitvoeringen; voortgang vereist twee van de laatste drie met volledig protocol en zonder datakwaliteitswaarschuwing."},
      "stopRules":["Stop en maak het geweer veilig zodra het actieve bullnummer onzeker is.","Stop bij verschoven steun, onvrije recoilbeweging of baanonderbreking."],
      "reflectionPrompts":["Bleef de terugkeerreferentie gelijk over vijf bulls?","Was iedere afwijkende bullstatus bewust bevestigd?"],
      "progression":{"usableResult":"Ga naar een kaartblok van vijf met contextregistratie.","insufficientData":"Vul geen ontbrekende bull achteraf in; voer later een nieuwe vijf-bullsrun uit.","unreliableResult":"Bewaar de reeks los maar sluit haar uit van drillbaseline wanneer volgorde of setup onzeker was.","nextDrillId":"br50-five-block-card@2"},
      "diagramIds":["br50-sighter-record-map","br50-recoil-return"],"techniqueReferences":["br50-rest-rules@2","br50-recoil-return@2","br50-sighters-record-bulls@2"],
      "references":[{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"§ scoring, p. 21 en Appendix E, p. 54: 25 recordbulls, sighters, inward scoring, dubbelschoten en strafpunten"}],
      "review":{"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"WRABF V4.4, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id":"br50-five-block-card","version":2,"title":"Kaart in vijf zichtbare blokken","shortPurpose":"Voer 25 recordbulls uit als vijf controleerbare blokken zonder onbekende schotvolgorde te verzinnen.","discipline":"br50","skillLevel":"foundation","mode":"liveFire","estimatedDurationMinutes":45,"ammunitionBudget":25,"prerequisites":["br50-five-record-bulls@2","br50-card-blocks-conditions@2"],
      "setup":{"target":"Volledige WRABF BR50-kaart","distance":"50 m","equipment":["Vaste toegestane benchrestopstelling","Vijf vooraf gemarkeerde blokken van vijf recordbulls","Contextregistratie tussen blokken"],"dataBasis":"25 recordbulls, vijf bloksamenvattingen en één kaartreflectie","safetyGate":"Alle app- en kaartcontrole gebeurt tussen blokken met veilig gemaakt geweer."},
      "phases":[
        {"id":"plan","title":"Blokken en volgorde","instructions":["Kies vijf herkenbare blokken van vijf bulls.","Leg de volgorde en sighterprotocol vast.","Controleer setupreferenties."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"br50-card-blocks-conditions@2"},
        {"id":"blocks","title":"Vijf blokken","instructions":["Schiet één schot per gepland recordbull.","Maak het geweer na elk blok veilig.","Bevestig bullstatus en noteer alleen wezenlijk veranderde context."],"completionKind":"confirmedSeries","seriesCount":5,"shotsPerSeries":5,"restSeconds":60,"linkedTechniqueId":"br50-sighters-record-bulls@2"},
        {"id":"debrief","title":"Kaartoverzicht","instructions":["Controleer alle 25 recordbulls.","Vergelijk blokscore en lokale bullpositie beschrijvend.","Noem bullpositie niet automatisch vroeg of laat in de kaart."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"reading-target-evidence@2"}
      ],
      "measurements":[
        {"metric":"filledBullCount","direction":"maximize","role":"primary","minimumSampleSize":25,"baselineEligible":false,"interpretation":"Alle 25 recordbulls moeten bewust als treffer, nul, leeg of dubbel beoordeeld zijn."},
        {"metric":"consistency","direction":"stabilize","role":"secondary","minimumSampleSize":5,"baselineEligible":true,"interpretation":"Blokconsistentie wordt alleen binnen dezelfde vastgelegde blokindeling vergeleken."}
      ],
      "masteryRule":{"minimumValidExecutions":3,"requiredSuccesses":2,"evaluationWindow":3,"usesPersonalBaseline":true,"explanation":"Na drie volledige kaarten over minstens twee sessies geldt twee van de laatste drie protocollair volledige kaarten als voortgang."},
      "stopRules":["Stop bij verloren bullvolgorde en controleer pas na veilig maken.","Markeer de kaart onbetrouwbaar wanneer blokindeling, setup of context niet meer te reconstrueren is."],
      "reflectionPrompts":["Welk blok had de meest betrouwbare uitvoering, los van hoogste score?","Welke contextverandering is werkelijk waargenomen en niet uit de kaart afgeleid?"],
      "progression":{"usableResult":"Ga naar sighter-naar-record of de volledige kaartrepetitie.","insufficientData":"Een onvolledige kaart blijft bewaard maar vormt geen volledige kaartbaseline.","unreliableResult":"Gebruik geldige deelblokken afzonderlijk en sluit de kaart uit van blokvergelijking.","nextDrillId":"br50-sighter-to-record@2"},
      "diagramIds":["br50-five-blocks","br50-condition-blocks"],"techniqueReferences":["br50-sighters-record-bulls@2","br50-card-blocks-conditions@2","reading-target-evidence@2"],
      "references":[{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"Appendix E, p. 54: officiële kaart met 25 recordbulls, sighters en kaartprotocol"}],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"WRABF V4.4, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id":"br50-sighter-to-record","version":2,"title":"Van sighter naar recordbull","shortPurpose":"Maak de overgang van proefinformatie naar tellend bull bewust en herhaalbaar zonder een automatische windclaim.","discipline":"br50","skillLevel":"development","mode":"liveFire","estimatedDurationMinutes":30,"ammunitionBudget":18,"prerequisites":["br50-sighters-record-bulls@2","br50-five-record-bulls@2"],
      "setup":{"target":"WRABF BR50-kaart","distance":"50 m","equipment":["Toegestane benchrestopstelling","Vooraf gekozen sighter- en recordbulls","Drie cycli met telkens één gepland sighterschot en vijf recordbulls"],"dataBasis":"Drie bevestigde vijf-bullsreeksen met gekoppelde sightercontext","safetyGate":"Baan- en wedstrijdregels bepalen sightergebruik; appcontrole alleen met veilig geweer."},
      "phases":[
        {"id":"protocol","title":"Overgangscriterium","instructions":["Leg vooraf vast welke waarneembare sighterinformatie voldoende is om naar record te gaan.","Gebruik geen automatische voorspelling van wind of klikcorrectie."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"br50-sighters-record-bulls@2"},
        {"id":"cycles","title":"Drie cycli","instructions":["Gebruik per cyclus één gepland sighterschot volgens de actuele regels en je vastgelegde criterium.","Schiet daarna vijf geplande recordbulls.","Maak het geweer veilig en registreer alleen de overgangscontext."],"completionKind":"confirmedSeries","seriesCount":3,"shotsPerSeries":5,"restSeconds":90,"linkedTechniqueId":"br50-card-blocks-conditions@2"},
        {"id":"review","title":"Overgang vergelijken","instructions":["Vergelijk score en bullpositie tussen de drie cycli.","Benoem of het criterium uitvoerbaar was, niet of een sighter de score veroorzaakte."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"reading-target-evidence@2"}
      ],
      "measurements":[
        {"metric":"consistency","direction":"stabilize","role":"primary","minimumSampleSize":3,"baselineEligible":true,"interpretation":"Vergelijk de drie recordcycli binnen exact hetzelfde overgangsprotocol."},
        {"metric":"scorePercentage","direction":"maximize","role":"secondary","minimumSampleSize":3,"baselineEligible":true,"interpretation":"Score is secundair en bewijst geen sighter- of windoorzaak."}
      ],
      "masteryRule":{"minimumValidExecutions":3,"requiredSuccesses":2,"evaluationWindow":3,"usesPersonalBaseline":true,"explanation":"Na drie activiteiten over minstens twee sessies geldt twee van de laatste drie met uitvoerbaar criterium en geldige data."},
      "stopRules":["Stop wanneer de actieve bull of sighterstatus onzeker is.","Markeer onbetrouwbaar bij wezenlijk veranderde wind- of setupcontext tussen cycli."],
      "reflectionPrompts":["Was het overgangscriterium vooraf concreet genoeg om zonder gokken toe te passen?","Welke context werd werkelijk waargenomen?"],
      "progression":{"usableResult":"Gebruik hetzelfde criterium in een volledige kaartrepetitie.","insufficientData":"Voeg geen andere protocolvorm toe; verzamel drie gelijk opgebouwde cycli.","unreliableResult":"Vereenvoudig het criterium en herhaal later onder beter documenteerbare omstandigheden.","nextDrillId":"br50-full-card-rehearsal@2"},
      "diagramIds":["br50-sighter-record-map","br50-condition-blocks"],"techniqueReferences":["br50-sighters-record-bulls@2","br50-card-blocks-conditions@2","reading-target-evidence@2"],
      "references":[{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"§ scoring, p. 21 en Appendix E, p. 54: sighters, recordbulls en inward scoring"}],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"WRABF V4.4, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id":"br50-rebuild-rest","version":2,"title":"Steunopstelling opnieuw bouwen","shortPurpose":"Test of jouw vastgelegde opstelling na volledige veilige herbouw dezelfde groepskenmerken oplevert.","discipline":"br50","skillLevel":"development","mode":"liveFire","estimatedDurationMinutes":40,"ammunitionBudget":20,"prerequisites":["br50-rest-axis@2","br50-contact-rebuild@2","one-variable-comparison@2"],
      "setup":{"target":"Vier identieke BR50-deelreeksen of trainingsbullgroepen","distance":"50 m","equipment":["Hetzelfde geweer en munitielot","Vastgelegde voorsteun-, achterzak- en contactreferenties","A-B-B-A-volgorde: opgebouwd / herbouwd"],"dataBasis":"Vier bevestigde reeksen van vijf met exact één gekozen variabele","safetyGate":"Geweer volledig veilig en uit de steun vóór iedere herbouw; baanregels blijven leidend."},
      "phases":[
        {"id":"define","title":"A en B vastleggen","instructions":["Definieer A als oorspronkelijke opstelling en B als volledig herbouwd vanaf de referenties.","Behoud wapen, munitie, afstand en contactstrategie gelijk."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"one-variable-comparison@2"},
        {"id":"a1","title":"A — eerste groep","instructions":["Schiet vijf geplande recordbulls met de oorspronkelijke opstelling.","Bevestig de reeks zonder steunwijziging."],"completionKind":"confirmedSeries","seriesCount":1,"shotsPerSeries":5,"restSeconds":60,"linkedTechniqueId":"br50-contact-rebuild@2"},
        {"id":"b","title":"B — herbouw en twee groepen","instructions":["Maak het geweer veilig en verwijder het uit de steun.","Herbouw vanaf de vastgelegde referenties.","Schiet twee afzonderlijke groepen van vijf zonder verdere wijziging."],"completionKind":"confirmedSeries","seriesCount":2,"shotsPerSeries":5,"restSeconds":90,"linkedTechniqueId":"br50-rest-axis@2"},
        {"id":"a2","title":"A — controle","instructions":["Herstel de oorspronkelijke referenties na veilig maken.","Schiet de laatste groep van vijf."],"completionKind":"confirmedSeries","seriesCount":1,"shotsPerSeries":5,"restSeconds":90,"linkedTechniqueId":"br50-contact-rebuild@2"},
        {"id":"review","title":"Vergelijk zonder winnaarclaim","instructions":["Vergelijk groepscentrum en mean radius per variant.","Noem de proef voorlopig als de verschillen binnen normale sessievariatie vallen."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"reading-target-evidence@2"}
      ],
      "measurements":[
        {"metric":"meanRadiusMm","direction":"minimize","role":"primary","minimumSampleSize":20,"baselineEligible":false,"interpretation":"Vergelijk A en B beschrijvend; vier groepen zijn geen algemene materiaalkeuring."},
        {"metric":"absoluteBiasMm","direction":"stabilize","role":"secondary","minimumSampleSize":20,"baselineEligible":false,"interpretation":"Een verschoven centrum is een observatie die op een tweede sessie bevestigd moet worden."}
      ],
      "masteryRule":{"minimumValidExecutions":2,"requiredSuccesses":2,"evaluationWindow":2,"usesPersonalBaseline":false,"explanation":"Een praktisch signaal vereist twee volledige activiteiten op verschillende sessies met dezelfde A/B-definitie."},
      "stopRules":["Stop wanneer meer dan de herbouwvariabele wijzigt.","Stop bij onveilige steunbeweging, baanonderbreking of duidelijke conditieverandering."],
      "reflectionPrompts":["Waren alle drie opstellingsreferenties na herbouw werkelijk gelijk?","Is het waargenomen verschil groot genoeg om op een tweede sessie te testen?"],
      "progression":{"usableResult":"Herhaal dezelfde A-B-B-A-definitie op een tweede sessie.","insufficientData":"Vul geen ontbrekende variant aan met een andere sessie zonder nieuwe activiteit.","unreliableResult":"Verfijn de referenties en start de vergelijking volledig opnieuw.","nextDrillId":"br50-full-card-rehearsal@2"},
      "diagramIds":["br50-rest-axis-top-side","br50-contact-map","abba-experiment"],"techniqueReferences":["one-variable-comparison@2","br50-rest-axis@2","br50-contact-rebuild@2","reading-target-evidence@2"],
      "references":[{"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"pp. 7, 9-12: position correction, equipment testing and performance profiling"},{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"§§ B.1-B.10, pp. 7-16: klassen, uitrusting en steunregels"}],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"ISSF/WRABF, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id":"br50-cold-card","version":2,"title":"Koude BR50-kaart","shortPurpose":"Meet de eerste volledige BR50-kaart van een sessie als eigen benchmark zonder voorafgaande live kaart.","discipline":"br50","skillLevel":"development","mode":"liveFire","estimatedDurationMinutes":45,"ammunitionBudget":25,"prerequisites":["br50-five-block-card@2"],
      "setup":{"target":"Volledige WRABF BR50-kaart","distance":"50 m","equipment":["Normale wedstrijdachtige opstelling","Vaste vijf-blokkenindeling","Geen eerdere live kaart in dezelfde sessie"],"dataBasis":"Eén volledige 25-bullkaart, vijf blokken en directe reflectie","safetyGate":"Normale baan- en kaartprocedure; opstelling vooraf veilig gecontroleerd."},
      "phases":[
        {"id":"prepare","title":"Normale koude voorbereiding","instructions":["Bouw de opstelling volgens vaste referenties.","Leg sighterprotocol en vijf blokken vast.","Voeg geen live proefkaart toe."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"br50-contact-rebuild@2"},
        {"id":"card","title":"Eerste kaart","instructions":["Voer vijf blokken van vijf recordbulls uit.","Gebruik sighters alleen volgens protocol.","Bevestig ieder blok en controleer veilig de bullstatus."],"completionKind":"confirmedSeries","seriesCount":5,"shotsPerSeries":5,"restSeconds":60,"linkedTechniqueId":"br50-card-blocks-conditions@2"},
        {"id":"reflect","title":"Koude context","instructions":["Noteer voorbereiding, waargenomen omstandigheden en zelfevaluatie.","Vergelijk pas met eerdere koude kaarten van dezelfde combinatie."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"reading-target-evidence@2"}
      ],
      "measurements":[
        {"metric":"scorePercentage","direction":"stabilize","role":"primary","minimumSampleSize":5,"baselineEligible":true,"interpretation":"Alleen volledige koude kaarten van dezelfde combinatie vormen de baseline."},
        {"metric":"consistency","direction":"stabilize","role":"secondary","minimumSampleSize":5,"baselineEligible":true,"interpretation":"Blokvariatie is beschrijvend en bewijst geen vermoeidheids- of windoorzaak."}
      ],
      "masteryRule":{"minimumValidExecutions":3,"requiredSuccesses":2,"evaluationWindow":3,"usesPersonalBaseline":true,"explanation":"Na drie volledige koude kaarten op verschillende sessies geldt twee van de laatste drie binnen de persoonlijke band als stabiel."},
      "stopRules":["Ongeldig als eerder in de sessie een live BR50-kaart of groep is geschoten.","Stop bij verloren bullvolgorde, onveilige setup of baanonderbreking."],
      "reflectionPrompts":["Was de normale opstelling volledig opgebouwd vóór de eerste sighter?","Welk blokverschil is alleen geobserveerd en nog niet verklaard?"],
      "progression":{"usableResult":"Bewaar de koude kaart en vervolg met het sessieplan.","insufficientData":"Herhaal op volgende sessies; gebruik geen latere kaart als vervanging.","unreliableResult":"Behoud geldige reeksen maar sluit de activiteit uit van de koude-kaartbaseline.","nextDrillId":"br50-full-card-rehearsal@2"},
      "diagramIds":["br50-five-blocks","br50-condition-blocks"],"techniqueReferences":["br50-contact-rebuild@2","br50-card-blocks-conditions@2","reading-target-evidence@2"],
      "references":[{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"Appendix E, p. 54: officiële kaart, recordbulls en sighterprotocol"}],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"WRABF V4.4, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id":"br50-full-card-rehearsal","version":2,"title":"Volledige officiële kaartrepetitie","shortPurpose":"Doorloop een volledige wedstrijdachtige BR50-kaart met vooraf vastgelegd protocol en eerlijke nabespreking.","discipline":"br50","skillLevel":"development","mode":"matchSimulation","estimatedDurationMinutes":60,"ammunitionBudget":25,"prerequisites":["br50-five-block-card@2","br50-sighter-to-record@2","br50-rebuild-rest@2"],
      "setup":{"target":"Officiële WRABF BR50-kaart of neutrale geometrisch gelijke trainingsweergave","distance":"50 m","equipment":["Reglementair gecontroleerde opstelling","Vooraf vastgelegd sighterprotocol","Vijf kaartblokken en tijd-/rustplan"],"dataBasis":"25 recordbulls, sightercontext, vijf blokken, totale score en debrief","safetyGate":"Actuele WRABF- en baanregels bevestigd; app is geen wedstrijdcertificering en baancommando's hebben voorrang."},
      "phases":[
        {"id":"brief","title":"Wedstrijdachtige briefing","instructions":["Controleer klasse, kaart, afstand en opstelling.","Leg sighter-, blok- en rustprotocol vast.","Kies één procescue en stopcriterium."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"br50-rest-rules@2"},
        {"id":"card","title":"Volledige kaart","instructions":["Gebruik sighters volgens het vastgelegde protocol.","Schiet 25 recordbulls in vijf gekoppelde blokken.","Bevestig ieder blok; wijzig geen setup of materiaal zonder de activiteit onbetrouwbaar te markeren."],"completionKind":"confirmedSeries","seriesCount":5,"shotsPerSeries":5,"restSeconds":60,"linkedTechniqueId":"br50-card-blocks-conditions@2"},
        {"id":"verify","title":"Protocolcontrole","instructions":["Controleer alle bulls op treffer, leeg, nul of dubbel.","Bevestig missers en multipliciteit handmatig.","Controleer dat sighters niet als recordimpact zijn opgeslagen."],"completionKind":"acknowledged","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"br50-sighters-record-bulls@2"},
        {"id":"debrief","title":"Nabespreking","instructions":["Vergelijk kaartscore, blokconsistentie en context.","Benoem één sterk procesdeel en één volgende test.","Maak geen wind-, contact- of vermoeidheidsdiagnose uit bullpositie alleen."],"completionKind":"reflection","seriesCount":null,"shotsPerSeries":null,"restSeconds":null,"linkedTechniqueId":"reading-target-evidence@2"}
      ],
      "measurements":[
        {"metric":"scorePercentage","direction":"maximize","role":"primary","minimumSampleSize":5,"baselineEligible":true,"interpretation":"Volledige kaartscore wordt alleen met dezelfde protocol- en materiaalcombinatie vergeleken."},
        {"metric":"consistency","direction":"stabilize","role":"secondary","minimumSampleSize":5,"baselineEligible":true,"interpretation":"Blokconsistentie is beschrijvend; bullnummer is geen automatisch tijdstip."}
      ],
      "masteryRule":{"minimumValidExecutions":3,"requiredSuccesses":2,"evaluationWindow":3,"usesPersonalBaseline":true,"explanation":"Baseline na drie volledige kaarten over minstens twee sessies; voortgang bij twee van de laatste drie geldige kaarten binnen het persoonlijke doel."},
      "stopRules":["Stop bij onveilige toestand, verloren kaartpositie of onvrije steunbeweging.","Een onvolledige of protocolgewijzigde kaart wordt niet als volledige repetitie beoordeeld."],
      "reflectionPrompts":["Bleef hetzelfde sighter- en blokprotocol praktisch uitvoerbaar?","Welke volgende test verandert exact één variabele?"],
      "progression":{"usableResult":"Herhaal dezelfde repetitie later of bespreek de coachreflectie.","insufficientData":"Bewaar een onvolledige kaart als deelactiviteit, niet als volledige benchmark.","unreliableResult":"Gebruik geldige blokken afzonderlijk en herstel setup of protocol vóór een nieuwe volledige kaart.","nextDrillId":null},
      "diagramIds":["br50-sighter-record-map","br50-five-blocks","br50-condition-blocks"],"techniqueReferences":["br50-rest-rules@2","br50-sighters-record-bulls@2","br50-card-blocks-conditions@2","reading-target-evidence@2"],
      "references":[{"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"§ scoring, p. 21 en Appendix E, p. 54: A3-kaart, 25 recordbulls, sighters en inward scoring"}],
      "review":{"evidenceStatus":"officialGuidance","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"WRABF V4.4, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    }
  ]
}
''';

const builtInLearningPathsJson = r'''{
  "schemaVersion": 2,
  "locale": "nl-BE",
  "learningPaths": [
    {
      "id": "precision-pistol-foundations",
      "version": 2,
      "title": "Precisiepistool — basis",
      "shortDescription": "Bouw een veilige, observeerbare basis op en verzamel drie echte groepen zonder een technisch probleem uit één treffer af te leiden.",
      "discipline": "precisionPistol",
      "estimatedMinutes": 138,
      "entries": [
        {"id":"safety","kind":"lesson","versionedContentId":"safe-range-phone-routine@2","prerequisiteEntryIds":[]},
        {"id":"stance","kind":"lesson","versionedContentId":"pistol-natural-alignment@2","prerequisiteEntryIds":["safety"]},
        {"id":"body","kind":"lesson","versionedContentId":"pistol-feet-body-arm@2","prerequisiteEntryIds":["stance"]},
        {"id":"grip","kind":"lesson","versionedContentId":"pistol-grip-trigger-contact@2","prerequisiteEntryIds":["body"]},
        {"id":"sights","kind":"lesson","versionedContentId":"pistol-sight-alignment-picture@2","prerequisiteEntryIds":["grip"]},
        {"id":"movement","kind":"lesson","versionedContentId":"pistol-visual-focus-movement@2","prerequisiteEntryIds":["sights"]},
        {"id":"trigger","kind":"lesson","versionedContentId":"pistol-progressive-trigger@2","prerequisiteEntryIds":["movement"]},
        {"id":"blank","kind":"drill","versionedContentId":"pistol-blank-sight-picture@2","prerequisiteEntryIds":["trigger"]},
        {"id":"evidence","kind":"lesson","versionedContentId":"reading-target-evidence@2","prerequisiteEntryIds":["blank"]},
        {"id":"baseline","kind":"drill","versionedContentId":"pistol-three-baseline-groups@2","prerequisiteEntryIds":["evidence"]}
      ],
      "references": [
        {"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"gedrukte pp. 18-27 (PDF pp. 23-32): houding, voorbereiding, precisieschot en doelgerichte oefeningen"},
        {"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 5 en pp. 7, 9-12: pistol foundations, profiling, feedback en praktijkplanning"}
      ],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"CMP en ISSF, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "precision-pistol-repeatability",
      "version": 2,
      "title": "Precisiepistool — herhaalbaarheid",
      "shortDescription": "Verbind lift, ademvenster, vizierrelatie, trekkerdruk en reset tot een herhaalbare routine die met echte reeksen wordt beoordeeld.",
      "discipline": "precisionPistol",
      "estimatedMinutes": 269,
      "entries": [
        {"id":"safety","kind":"lesson","versionedContentId":"safe-range-phone-routine@2","prerequisiteEntryIds":[]},
        {"id":"stance","kind":"lesson","versionedContentId":"pistol-natural-alignment@2","prerequisiteEntryIds":["safety"]},
        {"id":"body","kind":"lesson","versionedContentId":"pistol-feet-body-arm@2","prerequisiteEntryIds":["stance"]},
        {"id":"grip","kind":"lesson","versionedContentId":"pistol-grip-trigger-contact@2","prerequisiteEntryIds":["body"]},
        {"id":"sights","kind":"lesson","versionedContentId":"pistol-sight-alignment-picture@2","prerequisiteEntryIds":["grip"]},
        {"id":"movement","kind":"lesson","versionedContentId":"pistol-visual-focus-movement@2","prerequisiteEntryIds":["sights"]},
        {"id":"lift","kind":"lesson","versionedContentId":"pistol-arm-lift-approach@2","prerequisiteEntryIds":["movement"]},
        {"id":"breath","kind":"lesson","versionedContentId":"pistol-breathing-window@2","prerequisiteEntryIds":["lift"]},
        {"id":"trigger","kind":"lesson","versionedContentId":"pistol-progressive-trigger@2","prerequisiteEntryIds":["breath"]},
        {"id":"reset","kind":"lesson","versionedContentId":"pistol-follow-through-reset@2","prerequisiteEntryIds":["trigger"]},
        {"id":"window","kind":"drill","versionedContentId":"pistol-repeatable-window@2","prerequisiteEntryIds":["reset"]},
        {"id":"evidence","kind":"lesson","versionedContentId":"reading-target-evidence@2","prerequisiteEntryIds":["window"]},
        {"id":"compare","kind":"lesson","versionedContentId":"one-variable-comparison@2","prerequisiteEntryIds":["evidence"]},
        {"id":"baseline","kind":"drill","versionedContentId":"pistol-three-baseline-groups@2","prerequisiteEntryIds":["compare"]},
        {"id":"centre-spread","kind":"drill","versionedContentId":"pistol-centre-vs-spread@2","prerequisiteEntryIds":["baseline"]},
        {"id":"cold","kind":"drill","versionedContentId":"pistol-cold-series@2","prerequisiteEntryIds":["centre-spread"]},
        {"id":"match","kind":"drill","versionedContentId":"pistol-match-block@2","prerequisiteEntryIds":["cold"]}
      ],
      "references": [
        {"id":"cmp-pistol","title":"The CMP Guide to Junior Pistol Shooting","url":"https://thecmp.org/wp-content/uploads/2026/05/JrPistolGuide.pdf","publisher":"Civilian Marksmanship Program","documentEdition":"uitgave 2016","locator":"gedrukte pp. 20-27 (PDF pp. 25-32): lift, ademhaling, vizierfocus, progressieve trekkerdruk, follow-through en oefeningen"},
        {"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 9 en p. 11: verticale benadering, sighting, trigger, follow-through, dagboek en trainingsplanning"}
      ],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"CMP en ISSF, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "br50-foundations",
      "version": 2,
      "title": "BR50 — basis",
      "shortDescription": "Leer de reglementaire grenzen, bouw een herhaalbare steunopstelling en controleer je terugkeer zonder één contactstrategie als universeel voor te stellen.",
      "discipline": "br50",
      "estimatedMinutes": 154,
      "entries": [
        {"id":"safety","kind":"lesson","versionedContentId":"safe-range-phone-routine@2","prerequisiteEntryIds":[]},
        {"id":"evidence","kind":"lesson","versionedContentId":"reading-target-evidence@2","prerequisiteEntryIds":["safety"]},
        {"id":"compare","kind":"lesson","versionedContentId":"one-variable-comparison@2","prerequisiteEntryIds":["evidence"]},
        {"id":"rules","kind":"lesson","versionedContentId":"br50-rest-rules@2","prerequisiteEntryIds":["safety"]},
        {"id":"axis","kind":"lesson","versionedContentId":"br50-rest-axis@2","prerequisiteEntryIds":["rules"]},
        {"id":"contact","kind":"lesson","versionedContentId":"br50-contact-rebuild@2","prerequisiteEntryIds":["axis","compare"]},
        {"id":"recoil","kind":"lesson","versionedContentId":"br50-recoil-return@2","prerequisiteEntryIds":["contact"]},
        {"id":"rebuild","kind":"drill","versionedContentId":"br50-rebuild-rest@2","prerequisiteEntryIds":["recoil"]},
        {"id":"bulls","kind":"drill","versionedContentId":"br50-five-record-bulls@2","prerequisiteEntryIds":["rebuild"]}
      ],
      "references": [
        {"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"§§ B.1-B.10, pp. 7-16 en Appendix E, p. 54: klassen, steunregels, kaart en recordbulls"},
        {"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"pp. 7, 9-12: individuele doelen, materiaaltest, feedback en trainingsplanning"}
      ],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"WRABF V4.4 en ISSF, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    },
    {
      "id": "br50-card-execution",
      "version": 2,
      "title": "BR50 — kaartuitvoering",
      "shortDescription": "Gebruik sighters en vijf zichtbare kaartblokken om een volledige BR50-kaart protocollair, controleerbaar en zonder verzonnen schotvolgorde uit te voeren.",
      "discipline": "br50",
      "estimatedMinutes": 345,
      "entries": [
        {"id":"safety","kind":"lesson","versionedContentId":"safe-range-phone-routine@2","prerequisiteEntryIds":[]},
        {"id":"evidence","kind":"lesson","versionedContentId":"reading-target-evidence@2","prerequisiteEntryIds":["safety"]},
        {"id":"compare","kind":"lesson","versionedContentId":"one-variable-comparison@2","prerequisiteEntryIds":["evidence"]},
        {"id":"rules","kind":"lesson","versionedContentId":"br50-rest-rules@2","prerequisiteEntryIds":["safety"]},
        {"id":"axis","kind":"lesson","versionedContentId":"br50-rest-axis@2","prerequisiteEntryIds":["rules"]},
        {"id":"contact","kind":"lesson","versionedContentId":"br50-contact-rebuild@2","prerequisiteEntryIds":["axis","compare"]},
        {"id":"recoil","kind":"lesson","versionedContentId":"br50-recoil-return@2","prerequisiteEntryIds":["axis"]},
        {"id":"protocol","kind":"lesson","versionedContentId":"br50-sighters-record-bulls@2","prerequisiteEntryIds":["rules"]},
        {"id":"blocks","kind":"lesson","versionedContentId":"br50-card-blocks-conditions@2","prerequisiteEntryIds":["protocol","evidence"]},
        {"id":"five-bulls","kind":"drill","versionedContentId":"br50-five-record-bulls@2","prerequisiteEntryIds":["recoil"]},
        {"id":"rebuild","kind":"drill","versionedContentId":"br50-rebuild-rest@2","prerequisiteEntryIds":["contact"]},
        {"id":"sighter-record","kind":"drill","versionedContentId":"br50-sighter-to-record@2","prerequisiteEntryIds":["blocks","five-bulls"]},
        {"id":"five-block","kind":"drill","versionedContentId":"br50-five-block-card@2","prerequisiteEntryIds":["sighter-record"]},
        {"id":"cold","kind":"drill","versionedContentId":"br50-cold-card@2","prerequisiteEntryIds":["five-block"]},
        {"id":"full","kind":"drill","versionedContentId":"br50-full-card-rehearsal@2","prerequisiteEntryIds":["cold","rebuild"]}
      ],
      "references": [
        {"id":"wrabf-rules","title":"WRABF Rules","url":"https://www.wrabf.com/documents/WRABF%20Rules%202023-2027%20V4.4.pdf","publisher":"World Rimfire and Air Rifle Benchrest Federation","documentEdition":"Rules 2023-2027 V4.4, herzien 2026-05-05","locator":"§ scoring, p. 21 en Appendix E, p. 54: A3-kaart, 25 recordbulls, sighters, inward scoring en kaartprotocol"},
        {"id":"issf-education","title":"ISSF Education Reform Plan","url":"https://backoffice.issf-sports.org/getfile.aspx?file=ISSF+EDUCATION+REFORM+PLAN.pdf&inst=439&mod=docf&pane=1","publisher":"International Shooting Sport Federation","documentEdition":"Education Reform Plan","locator":"p. 7 en p. 11: doelen, feedback, planning en trainingsdagboek"}
      ],
      "review":{"evidenceStatus":"practiceBased","coachReviewStatus":"pending","reviewerRole":null,"reviewedAtUtc":null,"sourceEdition":"WRABF V4.4 en ISSF, gecontroleerd 2026-08-10","lastSourceCheckUtc":"2026-08-10T00:00:00.000Z"}
    }
  ]
}
''';
