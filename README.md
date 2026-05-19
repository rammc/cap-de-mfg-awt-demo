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

## Bekannte Phase-1-Abweichungen von der Spec

- **FlexiPages ohne Tabset:** Die Tabset-Struktur (`flexipage:tabset` mit JSON-encoded
  Tabs) ist über reine Metadata-API in dieser Org-Edition nicht zuverlässig
  deploybar. Wir liefern stattdessen 1-Column-Pages mit gestapelten Komponenten:
  Highlights-Panel + LWC-Placeholder(s). Tabs werden in Phase 2 nachgereicht,
  sobald ein echter LWC eingebaut wird (via UI Builder, dann re-retrieve).
- **List Views nur teilweise deployed:** `VBOT_Customers` (Account) und
  `VBOT_Assets` (Asset) sind deployed; `VBOT_Products`, `VBOT_Service_Contracts`
  und `VBOT_Work_Orders` mussten herausgenommen werden, weil die SF-ListView-XML
  in dieser Org-Edition die Filter-Field-Tokens (`PRODUCT2.PRODUCTCODE`,
  `SERVICE_CONTRACT.NAME`, `WORK_ORDER.VBOT_DEMO_SCENARIO__C`) nicht resolved
  hat. Workaround: List Views bei Bedarf in der UI anlegen und retrieve.
- **Sidebar-Komponenten weggelassen:** `runtime_sales_activities:activitiesPanel`
  und `runtime_chatter:feedContainer` sind in der Developer Edition nicht
  verfügbar – Sidebar bleibt leer; das Page-Template zeigt den Standard-Inhalt.
- **`Record Details`-Komponente:** `flexipage:recordDetailComponent` und
  `flexipage:relatedListContainer` waren in der Org nicht über XML-Deploy
  ansprechbar. Record-Felder werden über das Highlights-Panel im Header
  sichtbar gemacht; Related Lists werden in Phase 2 (per UI) ergänzt.

## Phase-Status

- [x] Phase 1: Setup, Datenmodell, Demo-Daten, Permission Set, Placeholder-Pages
- [ ] Phase 2: LWCs Service & Warranty + Tabset im FlexiPage XML
- [ ] Phase 3: LWCs Upgrades
- [ ] Phase 4: LWCs Connected Asset + Mobile-Mockup
- [ ] Phase 5: Polish, Backup-Screenshots, Demo-Skript
