# Phase 1 Implementation Prompt: VerdantBot Demo Setup

## Rolle & Ziel

Du bist Salesforce Platform Engineer und richtest in einer Manufacturing-Cloud Developer-Edition-Org das vollständige Grundsetup für eine UI-getriebene Demo ein. Die Demo erzählt die Story eines Field-Service-Einsatzes an einem Rasenmähroboter und wird in den folgenden Phasen 2–4 um drei LWC-basierte Tabs erweitert (Service & Warranty, Upgrades, Connected Asset).

**Diese Phase liefert kein UI-Verhalten**, sondern nur das Fundament: Datenmodell, Demo-Records, Custom Lightning Record Pages mit leeren Tab-Andockpunkten, List Views, Permission Set, Repo-Dokumentation.

## Org-Kontext (aus Discovery)

- **Org-Alias:** `christopher.ramm@cap-de-mfg-awt-demo.com` (im Folgenden `<alias>`)
- **Org-Typ:** Developer Edition – **nicht resetbar**. Idempotenz ist Pflicht.
- **API Version:** 66.0
- **Namespace:** keiner (Default-Namespace leer)
- **Repo:** `force-app/main/default/*` ist Greenfield
- **Bestehende Daten:** 17 GenWatt-Sample-Products, 2 Sample-Accounts (`sForce`, `Sample Account for Entitlements`) – nicht löschen, nur per List View ausblenden.

## Globale Regeln

### Naming
- **Custom Fields, Objects, Metadata Types, List Views, Permission Sets:** Prefix `VBOT_`
- **LWCs und Apex-Klassen:** kein Prefix (Default-Namespace ist leer, keine Kollisionen)
- **Demo-Daten:** im Namen / ProductCode mit `VBOT` oder `VBOT_` markiert, damit per Filter eindeutig auffindbar

### Idempotenz
- Vor jeder schreibenden Operation **prüfen, ob das Artefakt bereits existiert**.
- Metadata wird über `sf project deploy start` deployed – Salesforce upsert-Verhalten bei Metadata ist unkritisch.
- **Daten** werden über Apex Anonymous mit `upsert`-Pattern via External-ID-Felder eingespielt. Niemals blind `insert` für Demo-Records.
- Bei jedem Schritt ein klares Log in stdout: `[CREATE]`, `[SKIP-EXISTS]`, `[UPDATE]`.

### Field-API-Namens-Stolperfallen (aus Discovery)
- `WarrantyTerm`: Name-Feld heißt `WarrantyTermName`, Einheit heißt `WarrantyUnitOfTime` (nicht `WarrantyUnit`).
- Vor Daten-Seeding: kurz `sf sobject describe --sobject WarrantyTerm --target-org <alias>` checken, falls neue Felder eingeführt wurden.

---

## Schritt 1 – Repo-Skelett & Verzeichnisstruktur

Stelle sicher, dass die Standard-Source-Folder existieren und unter Git tracked sind:

```bash
mkdir -p force-app/main/default/{objects,layouts,flexipages,listViews,permissionsets,applications}
mkdir -p scripts/apex scripts/data
touch force-app/main/default/objects/.gitkeep
touch force-app/main/default/layouts/.gitkeep
touch force-app/main/default/flexipages/.gitkeep
touch force-app/main/default/permissionsets/.gitkeep
```

LWC- und classes-Ordner bleiben für Phase 2+ leer.

---

## Schritt 2 – Custom Fields auf Standardobjekten

Lege folgende Felder als XML-Metadata-Files an. Alle Felder sind im **Default-Namespace** und nutzen Prefix `VBOT_`.

### Asset
Pfad: `force-app/main/default/objects/Asset/fields/<FieldApiName>.field-meta.xml`

| API Name | Type | Spezifika | Zweck |
|---|---|---|---|
| `VBOT_Property_Size_Sqm__c` | Number(7,0) | – | Grundstücksgröße in m², treibt Use Case 2 Reasoning |
| `VBOT_Battery_Health_Pct__c` | Percent(5,2) | – | aktueller Batteriezustand, für UC2 + UC3 |
| `VBOT_Firmware_Version__c` | Text(20) | – | für Connected Asset Header |
| `VBOT_Last_Sync__c` | DateTime | – | „Last sync from Mobile App"-Indikator |
| `VBOT_Mobile_App_Enabled__c` | Checkbox | default `true` | Headless-Indikator |

### WorkOrder
Pfad: `force-app/main/default/objects/WorkOrder/fields/<FieldApiName>.field-meta.xml`

| API Name | Type | Spezifika | Zweck |
|---|---|---|---|
| `VBOT_Demo_Scenario__c` | Text(40) | – | Demo-Identifikator, z. B. „BATTERY_REPLACEMENT_001" |
| `VBOT_Recommended_Action__c` | Picklist | Werte: `Battery Replacement`, `Model Upgrade`, `Software Upgrade`, `Service Contract Upgrade`, `None` | für spätere LWC-Logik |

### ServiceContract
Pfad: `force-app/main/default/objects/ServiceContract/fields/<FieldApiName>.field-meta.xml`

| API Name | Type | Spezifika | Zweck |
|---|---|---|---|
| `VBOT_Tier__c` | Picklist | Werte: `Basic`, `Plus`, `Premium` | Tier-Marker für UC1 |
| `VBOT_Monthly_Price__c` | Currency(8,2) | – | Pricing-Visualizer |
| `VBOT_Yearly_Price__c` | Currency(8,2) | – | Pricing-Visualizer |
| `VBOT_Covers_Hardware__c` | Checkbox | default `false` | Coverage-Gap-Visualizer |
| `VBOT_Covers_Software__c` | Checkbox | default `false` | Coverage-Gap-Visualizer |
| `VBOT_Covers_Battery__c` | Checkbox | default `false` | Coverage-Gap-Visualizer |
| `VBOT_Covers_Sensors__c` | Checkbox | default `false` | Coverage-Gap-Visualizer |
| `VBOT_Is_Template__c` | Checkbox | default `false` | markiert die nicht-zugewiesenen Vertragsvorlagen Plus/Premium |

### Product2
Pfad: `force-app/main/default/objects/Product2/fields/<FieldApiName>.field-meta.xml`

| API Name | Type | Spezifika | Zweck |
|---|---|---|---|
| `VBOT_Max_Area_Sqm__c` | Number(7,0) | – | Reasoning für Up-Sell |
| `VBOT_Battery_Capacity_Wh__c` | Number(6,0) | – | Spec-Diff-Comparator |
| `VBOT_Has_GPS__c` | Checkbox | default `false` | Spec-Diff |
| `VBOT_Has_Lawn_AI__c` | Checkbox | default `false` | Spec-Diff |
| `VBOT_Hero_Image_Url__c` | URL(255) | – | Produkt-Hero-Image im Recommendation-Grid |
| `VBOT_Tier_Label__c` | Text(20) | – | Anzeige-Tier („Entry", „Comfort", „Pro") |

### Custom Object: `VBOT_Asset_Telemetry__c`

Pfad: `force-app/main/default/objects/VBOT_Asset_Telemetry__c/VBOT_Asset_Telemetry__c.object-meta.xml`

- **Label:** Asset Telemetry · **Plural:** Asset Telemetry Records
- **Name-Feld:** AutoNumber, Display Format `TEL-{0000}`
- **Sharing:** ControlledByParent
- **Deployment Status:** Deployed

**Felder:**
| API Name | Type | Spezifika |
|---|---|---|
| `VBOT_Asset__c` | Master-Detail to Asset | required, ReparentableMasterDetail false |
| `VBOT_Timestamp__c` | DateTime | required |
| `VBOT_Battery_Health_Pct__c` | Percent(5,2) | – |
| `VBOT_Mowed_Area_Sqm__c` | Number(6,0) | – |
| `VBOT_Operating_Hours__c` | Number(5,1) | – |
| `VBOT_Error_Count__c` | Number(3,0) | – |
| `VBOT_Firmware_Version__c` | Text(20) | – |
| `VBOT_Lawn_Health_Score__c` | Number(3,0) | 0-100, treibt Lawn-Health-Map |
| `VBOT_External_Id__c` | Text(40), ExternalId, Unique | für Upsert beim Daten-Seeding |

---

## Schritt 3 – List Views (GenWatt-Daten ausblenden)

Lege folgende List Views an, alle als „Visible to all users".

**Product2:** `force-app/main/default/objects/Product2/listViews/VBOT_Products.listView-meta.xml`
- Filter: `ProductCode STARTS WITH "VBOT"`
- Columns: `Name`, `ProductCode`, `VBOT_Tier_Label__c`, `VBOT_Max_Area_Sqm__c`, `IsActive`

**Asset:** `force-app/main/default/objects/Asset/listViews/VBOT_Assets.listView-meta.xml`
- Filter: `Product2.Name STARTS WITH "VBOT"`
- Columns: `Name`, `SerialNumber`, `Account.Name`, `InstallDate`, `VBOT_Battery_Health_Pct__c`

**Account:** `force-app/main/default/objects/Account/listViews/VBOT_Customers.listView-meta.xml`
- Filter: `Name STARTS WITH "VBOT"`
- Columns: `Name`, `BillingCity`, `Phone`

**WorkOrder:** `force-app/main/default/objects/WorkOrder/listViews/VBOT_Work_Orders.listView-meta.xml`
- Filter: `VBOT_Demo_Scenario__c NOT EQUAL TO ""`
- Columns: `WorkOrderNumber`, `Subject`, `Asset.Name`, `Account.Name`, `Status`

**ServiceContract:** `force-app/main/default/objects/ServiceContract/listViews/VBOT_Service_Contracts.listView-meta.xml`
- Filter: `Name STARTS WITH "VBOT"`
- Columns: `Name`, `ContractNumber`, `VBOT_Tier__c`, `Account.Name`, `StartDate`, `EndDate`

---

## Schritt 4 – Custom Lightning Record Pages

Zwei FlexiPages mit jeweils einem `tabset`, drei bzw. zwei Tabs. Die LWC-Tabs sind in dieser Phase **leer** (nur Placeholder-Komponente). In Phase 2–4 ersetzen wir den Placeholder durch echte LWCs.

### Placeholder-LWC `vbotTabPlaceholder`

Pfad: `force-app/main/default/lwc/vbotTabPlaceholder/`

- `vbotTabPlaceholder.js-meta.xml` – Targets: `lightning__RecordPage`, mit Target-Config-Property `tabLabel` (String).
- `vbotTabPlaceholder.js` – exposes `@api tabLabel`
- `vbotTabPlaceholder.html` – zeigt eine schlichte Box mit „⚙ Coming in Phase X – {tabLabel}" und einem dezenten SLDS-Spinner-Icon.
- `vbotTabPlaceholder.css` – minimal, nur Padding/Center.

Das ist die einzige LWC dieser Phase. Sie wird in Phase 2–4 nicht ersetzt, sondern in den FlexiPages durch die jeweilige Komponente überschrieben.

### FlexiPage WorkOrder

Pfad: `force-app/main/default/flexipages/VBOT_WorkOrder_Record_Page.flexipage-meta.xml`

- **Type:** RecordPage
- **MasterLabel:** VBOT Work Order Record Page
- **SObject:** WorkOrder
- **Template:** `flexipage:recordHomeTemplateDesktop`
- **Regions:**
  - `header` → Highlights Panel + Path (Status)
  - `main` → Tabset mit drei Tabs:
    - Tab 1 „Details" → Record-Details + Related Lists (Asset, Account, Work Order Line Items)
    - Tab 2 „Service & Warranty" → `vbotTabPlaceholder` mit `tabLabel = "Service & Warranty"`
    - Tab 3 „Upgrades" → `vbotTabPlaceholder` mit `tabLabel = "Upgrades"`
  - `sidebar` → Activity + Chatter

### FlexiPage Asset

Pfad: `force-app/main/default/flexipages/VBOT_Asset_Record_Page.flexipage-meta.xml`

- **Type:** RecordPage
- **MasterLabel:** VBOT Asset Record Page
- **SObject:** Asset
- **Template:** `flexipage:recordHomeTemplateDesktop`
- **Regions:**
  - `header` → Highlights Panel
  - `main` → Tabset mit zwei Tabs:
    - Tab 1 „Details" → Record-Details + Related Lists (Work Orders, Asset Warranties, Asset Telemetry)
    - Tab 2 „Connected Asset" → `vbotTabPlaceholder` mit `tabLabel = "Connected Asset"`
  - `sidebar` → Activity + Chatter

**Wichtig:** Aktivierung als „Org Default" **nicht im Metadata**, sondern in Schritt 8 manuell via UI – siehe dort.

---

## Schritt 5 – Permission Set `VBOT_Demo_Access`

Pfad: `force-app/main/default/permissionsets/VBOT_Demo_Access.permissionset-meta.xml`

- **Label:** VBOT Demo Access
- **Description:** „Grants full access to all VerdantBot demo custom objects, fields and pages."

**Inhalt:**
- `objectPermissions` für `VBOT_Asset_Telemetry__c`: alleCreate/Read/Edit/Delete/ViewAll/ModifyAll
- `fieldPermissions` für alle in Schritt 2 angelegten Custom Fields: read + edit
- `pageAccesses` (Visualforce): keine
- `flexiPageAccesses`: keine (FlexiPage-Zugriff geht über Object/Record-Permission)

Optional ergänzend: `recordTypeVisibilities` falls Record Types eingeführt werden – in Phase 1 nicht der Fall.

---

## Schritt 6 – Deployment

Vor dem Deploy ein Trockenlauf:

```bash
sf project deploy validate --source-dir force-app --target-org <alias> --json > deploy-validate.json
```

Wenn Validate sauber durchläuft:

```bash
sf project deploy start --source-dir force-app --target-org <alias> --json > deploy-start.json
```

Wenn der Deploy Fehler wirft:
- Fehler aus `deploy-start.json` lesen
- Wenn „duplicate value" / „already exists" → idempotent ignorieren, weitermachen.
- Wenn echte Fehler (fehlende Felder, syntaktische XML-Probleme) → fixen und erneut validate-deploy.

**Assigne das Permission Set an den eigenen User:**

```bash
sf org assign permset --name VBOT_Demo_Access --target-org <alias>
```

---

## Schritt 7 – Demo-Daten via Apex Anonymous

**Warum Apex Anonymous statt SF CLI Tree Files:** Tree Files können keine External-ID-basierten Upserts mit Lookup-Auflösung über mehrere Schritte sauber idempotent halten. Apex Anonymous gibt uns volle Kontrolle über Existenz-Checks und Reihenfolge.

Erstelle Datei `scripts/apex/seed-vbot-demo.apex` mit folgender Logik. **Jeder Block ist idempotent** und nutzt entweder External-ID-Upsert oder SOQL-Existenz-Check.

### Datenmodell (Reihenfolge zwingend)

1. **Account** „VBOT Familie Schmidt"
   - Match-Key: `Name = 'VBOT Familie Schmidt'`
   - Felder: BillingCity Berlin, BillingCountry DE, Phone (Demo), Type „Customer"
2. **Contact** „Anna Schmidt"
   - Match-Key: `Email = 'anna.schmidt@example.vbot'` (Demo-E-Mail)
   - Account-Lookup auf den eben erstellten/gefundenen Account
3. **Pricebook2** Standard auslesen (nicht erstellen)
   - SOQL: `SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1`
4. **Product2** × 6
   - Match-Key: `ProductCode`
   - Liste mit allen Spezifika:
     | Name | ProductCode | TierLabel | MaxAreaSqm | BatteryWh | GPS | LawnAI |
     |---|---|---|---|---|---|---|
     | VerdantBot E150 | VBOT_E150 | Entry | 500 | 60 | false | false |
     | VerdantBot C300 | VBOT_C300 | Comfort | 1000 | 90 | false | false |
     | VerdantBot C500 | VBOT_C500 | Comfort+ | 1500 | 110 | false | false |
     | VerdantBot X800 | VBOT_X800 | Pro | 3000 | 150 | true | true |
     | VerdantBot High-Capacity Battery Pack | VBOT_BAT_PLUS | Accessory | – | 130 | false | false |
     | VerdantBot Lawn-AI Subscription | VBOT_LAWN_AI | Software | – | – | false | true |
   - Setze `VBOT_Hero_Image_Url__c` provisorisch leer (kommt in Phase 4 mit Mobile-Mockup-Assets).
5. **PricebookEntry** × 6 auf Standard Pricebook
   - Match-Key: `Product2Id + Pricebook2Id`
   - UnitPrice (Beispielwerte):
     | ProductCode | UnitPrice EUR |
     |---|---|
     | VBOT_E150 | 899 |
     | VBOT_C300 | 1499 |
     | VBOT_C500 | 1999 |
     | VBOT_X800 | 2999 |
     | VBOT_BAT_PLUS | 249 |
     | VBOT_LAWN_AI | 49 |
6. **WarrantyTerm** × 2
   - Match-Key: `WarrantyTermName`
   - Records:
     - `VBOT 12M Software-Only`, WarrantyDuration 12, WarrantyUnitOfTime „Months"
     - `VBOT 24M Hardware Limited`, WarrantyDuration 24, WarrantyUnitOfTime „Months"
   - Hinweis: Felder vor dem Insert via describe verifizieren, falls API-Naming abweicht.
7. **Asset** „VerdantBot C300 #SN-2024-04711"
   - Match-Key: `SerialNumber = 'SN-2024-04711'`
   - Verknüpfungen: AccountId, ContactId, Product2Id (= C300)
   - Felder: InstallDate = TODAY - 420 Tage, Status „Installed", `VBOT_Property_Size_Sqm__c` = 1200, `VBOT_Battery_Health_Pct__c` = 78, `VBOT_Firmware_Version__c` = „3.4.1", `VBOT_Last_Sync__c` = NOW - 4 minutes, `VBOT_Mobile_App_Enabled__c` = true
8. **ServiceContract** × 3
   - Match-Key: `Name`
   - Records:
     - `VBOT VerdantCare Basic` – `VBOT_Tier__c = Basic`, monthly 4.99, yearly 49, Covers_Software true, andere false, AccountId = Schmidt, StartDate = InstallDate, EndDate = InstallDate + 12 Monate, Status „Active", `VBOT_Is_Template__c` = false
     - `VBOT VerdantCare Plus (Template)` – `VBOT_Tier__c = Plus`, monthly 9.99, yearly 99, Covers_Software + Covers_Battery + Covers_Sensors true, Covers_Hardware true, AccountId = Schmidt, StartDate = TODAY, EndDate = TODAY + 365 Tage, Status „Draft", `VBOT_Is_Template__c` = true
     - `VBOT VerdantCare Premium (Template)` – `VBOT_Tier__c = Premium`, monthly 14.99, yearly 149, alle Covers_* true, AccountId = Schmidt, StartDate = TODAY, EndDate = TODAY + 365 Tage, Status „Draft", `VBOT_Is_Template__c` = true
9. **WorkOrder** „WO Battery Replacement"
   - Match-Key: `VBOT_Demo_Scenario__c = 'BATTERY_REPLACEMENT_001'`
   - Felder: Subject „Lawn Mower not working – battery suspected", Status „In Progress", Priority „High", AssetId = C300-Asset, AccountId = Schmidt, ContactId = Anna, Description „Customer reports unit shuts down after 8 minutes of operation. Trunk inventory carries replacement battery.", `VBOT_Recommended_Action__c` = „Battery Replacement"
10. **WorkOrderLineItem** „Battery Pack OEM"
    - Match-Key: `WorkOrderId + Product2Id` (composite, da kein nativer External-Key – check via SOQL vor Insert)
    - Product2 = VBOT_BAT_PLUS, Quantity 1, UnitPrice 249, Status „In Progress"
11. **VBOT_Asset_Telemetry__c** × 30 (täglich, letzte 30 Tage)
    - Match-Key: `VBOT_External_Id__c = 'TEL-{assetId}-{yyyyMMdd}'`
    - Synthetische Daten:
      - `VBOT_Battery_Health_Pct__c` linear von 92 % (vor 30 Tagen) auf 78 % (heute)
      - `VBOT_Mowed_Area_Sqm__c` zufällig zwischen 180 und 360 pro Tag
      - `VBOT_Operating_Hours__c` zufällig zwischen 1.2 und 2.8 pro Tag, kumuliert
      - `VBOT_Error_Count__c` meist 0, 3 zufällige Tage mit 1–2 Fehlern
      - `VBOT_Firmware_Version__c` = „3.4.1"
      - `VBOT_Lawn_Health_Score__c` zufällig zwischen 68 und 84
    - **Reproduzierbarkeit:** Verwende einen Seed-basierten Pseudo-Random (z. B. Hash aus Datum) – damit die Daten bei wiederholtem Lauf identisch sind.

### Apex-Skript-Struktur

Strukturiere `seed-vbot-demo.apex` in nummerierte Blöcke, jeden mit:

```apex
System.debug('--- Block N: <Name> ---');
// 1. Existenz-Check via SOQL
// 2. Wenn vorhanden → System.debug('[SKIP-EXISTS] ...'); ID merken
// 3. Wenn nicht vorhanden → insert/upsert; System.debug('[CREATE] ...');
// 4. ID in lokale Variable für Folgeschritte
```

### Ausführung

```bash
sf apex run --file scripts/apex/seed-vbot-demo.apex --target-org <alias>
```

Bei wiederholter Ausführung muss der Output ausschließlich `[SKIP-EXISTS]` enthalten (außer bei Asset Telemetry: dort werden täglich neue Records erzeugt, falls Datumsgrenzen sich verschieben – das ist gewollt).

---

## Schritt 8 – Lightning App Builder: Record Pages aktivieren

Salesforce erlaubt nicht, FlexiPages programmatisch als „Org Default" zu aktivieren ohne dass sie vorher in der UI gesehen wurden. Daher:

**Anweisungen, die du in der Org-UI ausführst (nicht automatisierbar, aber im README dokumentieren):**

1. Setup → Object Manager → **Work Order** → Lightning Record Pages → `VBOT Work Order Record Page` → **Activation**
   - „Activate" → „Org Default" → „Desktop and phone" → Save
2. Setup → Object Manager → **Asset** → Lightning Record Pages → `VBOT Asset Record Page` → **Activation**
   - „Activate" → „Org Default" → „Desktop and phone" → Save

Dauer: < 2 Minuten. Macht aus dem Greenfield-Setup eine wirklich nutzbare Demo-Oberfläche.

---

## Schritt 9 – Repo-Dokumentation

### README.md (Repo-Wurzel)

Erstelle / aktualisiere `README.md` mit:

```markdown
# VerdantBot Manufacturing Cloud Demo

Demo-Org für die Agentforce World Tour Frankfurt 2026 Session
„How to fail Industry Cloud fast. Let's not."

## Story

Field Service an einem Rasenmähroboter (VerdantBot C300). Drei UI-Erweiterungen
oberhalb des Manufacturing-Cloud-Standardprozesses:

1. Service & Warranty – Servicevertragsverlängerung beim Vor-Ort-Termin
2. Upgrades – Up-/Cross-Sell-Empfehlungen auf Basis Asset + Nutzung
3. Connected Asset – Telemetrie aus Mobile App, Headless-360-Botschaft

## Naming-Konvention

- Custom Fields, Objects, Metadata, List Views, Permission Sets: Prefix `VBOT_`
- LWCs und Apex-Klassen: kein Prefix (Default-Namespace, keine Kollisionen)
- Demo-Daten: Name oder ProductCode beginnt mit `VBOT`

## Setup

1. Auth in Org: `sf org login web --alias <alias>`
2. Deploy Metadata: `sf project deploy start --source-dir force-app --target-org <alias>`
3. Assign Permission Set: `sf org assign permset --name VBOT_Demo_Access --target-org <alias>`
4. Seed Daten: `sf apex run --file scripts/apex/seed-vbot-demo.apex --target-org <alias>`
5. Lightning Record Pages aktivieren (manuell, siehe Setup-Doku unten).

## Demo zurücksetzen

`scripts/apex/reset-vbot-demo.apex` löscht alle VBOT-Daten in korrekter Reihenfolge
(Telemetry → WO Line Items → WO → Service Contracts → Asset → Contact → Account).
Metadata bleibt unangetastet.

## Phase-Status

- [x] Phase 1: Setup, Datenmodell, Demo-Daten, leere Record Pages
- [ ] Phase 2: LWCs Service & Warranty
- [ ] Phase 3: LWCs Upgrades
- [ ] Phase 4: LWCs Connected Asset + Mobile-Mockup
- [ ] Phase 5: Polish, Backup-Screenshots, Demo-Skript
```

### CLAUDE.md (Repo-Wurzel)

Erstelle `CLAUDE.md` als Claude-Code-Kontextfile:

```markdown
# Claude Code Kontext – VerdantBot Demo

## Org

Manufacturing Cloud Developer Edition, **nicht resetbar**. Alle Operationen
müssen idempotent sein.

## Konventionen

- Custom Metadata Prefix: `VBOT_`
- LWCs und Apex: kein Namespace-Prefix
- Standard-Objekte werden NICHT verändert außer durch eindeutig benannte
  Custom Fields mit `VBOT_`-Prefix.
- FSL-Managed-Package-Felder (`FSL__`) sind tabu.

## Sample-Daten in der Org (ignorieren)

- 17 GenWatt-Sample-Products (ProductCodes `GC*`, `IN*`, `SL*`)
- 2 Sample-Accounts: `sForce`, `Sample Account for Entitlements`
- Account hat 7 Custom-Sample-Felder (`SLA__c`, `UpsellOpportunity__c`, etc.) –
  nicht überschreiben, nicht für eigene Logik nutzen.

## Discovery-Snapshot

`discovery/SUMMARY.md` enthält den Org-Stand vor Phase 1. Bei jedem späteren
Retrieve gegen diesen Snapshot diffen, um Drift zu erkennen.

## Phase-Plan

- Phase 1 (DONE): Setup, Datenmodell, Demo-Daten
- Phase 2: LWCs `warrantyAdvisorPanel` + 5 Subkomponenten + `WarrantyAdvisorController`
- Phase 3: LWCs `productUpgradeStudio` + 5 Subkomponenten + `ProductUpgradeController`
- Phase 4: LWCs `connectedAssetDashboard` + 6 Subkomponenten + `AssetTelemetryController`
- Phase 5: `agentNudgeBubble` (cross-cutting), Polish, Mobile-Mockup-Slide
```

### Reset-Skript

Erstelle `scripts/apex/reset-vbot-demo.apex` als Inverse zum Seed-Skript. Löscht in Reihenfolge:
1. `VBOT_Asset_Telemetry__c` aller Demo-Assets
2. WorkOrderLineItems der Demo-WO
3. WorkOrder mit `VBOT_Demo_Scenario__c != null`
4. ServiceContracts mit `Name LIKE 'VBOT %'`
5. Asset mit `SerialNumber = 'SN-2024-04711'`
6. WarrantyTerms mit `WarrantyTermName LIKE 'VBOT %'`
7. PricebookEntries auf VBOT-Products (auf Standard Pricebook)
8. Products mit `ProductCode LIKE 'VBOT%'`
9. Contact mit Email `anna.schmidt@example.vbot`
10. Account mit `Name = 'VBOT Familie Schmidt'`

Auch dieses Skript ist idempotent (jeder Block: SOQL → wenn Records vorhanden, löschen, sonst `[SKIP-EMPTY]`).

---

## Acceptance Criteria – Phase 1 ist fertig, wenn …

1. **`sf project deploy start --source-dir force-app --target-org <alias>` läuft ohne Fehler durch** und ist beim zweiten Aufruf idempotent (no-op / „Same"-Status).
2. **Apex Seed-Skript läuft beim ersten Aufruf mit ausschließlich `[CREATE]`-Logs** und beim zweiten Aufruf mit ausschließlich `[SKIP-EXISTS]`-Logs (Asset Telemetry ausgenommen).
3. **Setup → Object Manager → Asset** zeigt Custom Object `VBOT_Asset_Telemetry__c` plus 5 neue Custom Fields auf Asset.
4. **App Launcher → Service oder Field Service Console**: Wechsel auf das WorkOrder-Tab zeigt die Demo-Work-Order. Aufruf zeigt die drei Tabs (Details / Service & Warranty / Upgrades). Tab 2 und 3 zeigen den Placeholder.
5. **Aufruf des Demo-Assets** zeigt Tabs Details + Connected Asset, letzterer mit Placeholder.
6. **List Views** „VBOT Products", „VBOT Assets", „VBOT Customers", „VBOT Work Orders", „VBOT Service Contracts" zeigen jeweils ausschließlich die Demo-Records.
7. **README.md, CLAUDE.md und das Reset-Skript sind im Repo committet.**
8. **Git-Status:** sauberer working tree; Commit-Message-Vorschlag „Phase 1: VBOT demo foundation (data model, seed, record pages, perm set)".

---

## Bekannte Stolperfallen

- **WarrantyTerm-Felder:** `WarrantyTermName` (nicht `Name`), `WarrantyUnitOfTime` (nicht `WarrantyUnit`). Falls Seed-Skript bei WarrantyTerm-Insert mit „No such column" abbricht: kurz `sf sobject describe --sobject WarrantyTerm --target-org <alias>` checken und Skript anpassen.
- **Master-Detail auf Asset:** Asset ist als Master-Objekt für Custom Master-Detail-Beziehungen erlaubt. Falls die Org diese Konfiguration aus historischen Gründen blockiert, Fallback auf Lookup mit `Required = true` und kaskadierender Lösch-Logik im Apex.
- **FlexiPage „Org Default"-Aktivierung:** Metadata-API kann FlexiPage-Aktivierung nicht zuverlässig setzen → manuell via UI (Schritt 8). Im README dokumentiert.
- **WorkOrder-Highlights-Panel:** Asset und Account sollen im Highlights Panel sichtbar sein. Falls die Compact Layouts der Standard-WO-Page das nicht zeigen, in Phase 2 (vor LWC-Einbau) Compact Layout „Work Order Compact Layout" anpassen.

## Output am Ende der Ausführung

1. Zeige den Inhalt des Deploy-Logs (nur Zusammenfassung: Komponenten erfolgreich / fehlgeschlagen).
2. Zeige die letzten 30 Zeilen des Apex-Seed-Logs.
3. Liste alle erzeugten Dateien unter `force-app/` und `scripts/`.
4. Bestätige explizit pro Acceptance-Criterion-Punkt: ✅ oder ❌ + Begründung.
