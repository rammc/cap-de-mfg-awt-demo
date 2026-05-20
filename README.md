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
2. Deploy Metadata: `sf project deploy start --source-dir force-app --target-org <alias> --test-level NoTestRun`
3. Assign Permission Set: `sf org assign permset --name VBOT_Demo_Access --target-org <alias>`
4. Seed Daten: `sf apex run --file scripts/apex/seed-vbot-demo.apex --target-org <alias>`
5. Lightning Record Pages aktivieren (manuell, siehe unten).

## Lightning Record Pages aktivieren (manuell)

Salesforce erlaubt die „Org Default"-Aktivierung nicht über die Metadata-API.

1. Setup → Object Manager → **Work Order** → Lightning Record Pages →
   `VBOT Work Order Record Page` → **Activation** → „Org Default" → Desktop + Phone → Save
2. Setup → Object Manager → **Asset** → Lightning Record Pages →
   `VBOT Asset Record Page` → **Activation** → „Org Default" → Desktop + Phone → Save

Dauer: < 2 Minuten.

## Demo zurücksetzen

`scripts/apex/reset-vbot-demo.apex` löscht alle VBOT-Daten in korrekter Reihenfolge
(Telemetry → WO Line Items → WO → Service Contracts → Asset → WarrantyTerms →
PricebookEntries → Products → Contact → Account). Metadata bleibt unangetastet.

```bash
sf apex run --file scripts/apex/reset-vbot-demo.apex --target-org <alias>
```

## Stand nach Phase 1.5

- **vbotTabPlaceholder** rendert drei unterscheidbare Wireframe-Varianten (Service &
  Warranty mit Coverage-Tiles + 3 Contract-Cards · Upgrades mit Asset-Banner + 3
  Produkt-Cards + Reasoning-Block · Connected Asset mit 4 KPI-Donuts + Line-Chart
  + Lawn-Map). Shimmer-Animation, Capgemini-Brand-Farben über CSS-Variablen.
  Variant wird per `tabLabel` auto-erkannt oder explizit gesetzt.
- **WorkOrder Record Page** rendert Highlights-Panel + 2 Placeholder
  (Service & Warranty + Upgrades) gestapelt; **Asset Record Page** Highlights +
  Connected Asset Placeholder.
- **Alle 5 ListViews** sind deployed: `VBOT_Customers` (Account),
  `VBOT_Assets` (Asset), `VBOT_Products` (Product2), `VBOT_Service_Contracts`
  (ServiceContract), `VBOT_Work_Orders` (WorkOrder).

## Bekannte Abweichungen von der Spec (Phase 1 & 1.5)

- **FlexiPage-Tabsets verschoben:** `flexipage:tabset` mit JSON-tabs-Property
  ließ sich in dieser Developer Edition nicht deployen — Fehler
  „facet … defined but not actually used", egal ob Tab-Content-Regionen als
  `Region` oder `Facet` definiert sind und unabhängig von der `flexipage:record*`
  Detail-Komponente (`recordDetailComponent`, `recordDetailPanel`,
  `recordFullSizeForm`, `recordHighlightsAndDetails` — alle „couldn't retrieve
  the design time component information"). Lösung Phase 1.5: 1-Column-Page mit
  polishen Placeholder-Wireframes, Highlights-Panel zeigt die wichtigen
  Record-Felder. Tabset-Bau bleibt für eine spätere Phase im UI Builder.
- **ListView-Filter via Standard-Feld nicht möglich:** Nur Custom-Fields
  (`VBOT_*__c`) und die Tokens `ACCOUNT.NAME` / `ASSET.NAME` resolven in dieser
  Edition als Filter-Field. Product2 + ServiceContract ListViews nutzen darum
  Custom-Field-Filter (`VBOT_Tier_Label__c not equal ""` bzw. `VBOT_Tier__c not
  equal ""`) – semantisch identisch zum Spec-Filter „nur VBOT-Records".
- **ListView columns weggelassen:** Keine Variante (`NAME`, `Name`,
  `Product2.Name`, `PRODUCT.NAME`, `PRODUCT2.NAME`) deployt – ListView fällt auf
  Org-Default-Spalten zurück. Anpassung via UI ist trivial und persistiert beim
  nächsten Retrieve.
- **Sidebar-Komponenten:** `runtime_sales_activities:activitiesPanel` und
  `runtime_chatter:feedContainer` sind in der Developer Edition nicht
  deploybar. Sidebar bleibt leer.

## Demo-Run

Vor jedem Live-Run: **[`docs/DEMO_CHECKLIST.md`](docs/DEMO_CHECKLIST.md)** abarbeiten. Backup-Strategie für Org-Ausfälle: **[`docs/backup-screenshots.md`](docs/backup-screenshots.md)**.

Quick-Reset während der Vorbereitung: Quick-Action **VBOT Demo Reset** auf der Demo-WorkOrder (oder `scripts/apex/reset-vbot-demo.apex` + `scripts/apex/seed-vbot-demo.apex` in Kombi).

## Phase-Status

- [x] Phase 1: Setup, Datenmodell, Demo-Daten, Permission Set, Placeholder-Pages
- [x] Phase 1.5: Polished Wireframe-Placeholder, 5/5 ListViews
- [x] Phase 2: Service & Warranty LWCs (warrantyAdvisorPanel + 5 Subs + Apex)
- [x] Phase 3: Upgrades LWCs (productUpgradeStudio + 6 Subs + Apex)
- [x] Phase 4: Connected Asset LWCs (connectedAssetDashboard + 6 Subs + Apex)
- [x] Phase 5: agentNudgeBubble + LMS-Highlight + shared States + Demo-Reset
