# Claude Code Kontext – VerdantBot Demo

## Org

Manufacturing Cloud **Developer Edition**, **nicht resetbar**. Alle Operationen
müssen idempotent sein. Org-Alias: `christopher.ramm@cap-de-mfg-awt-demo.com`.

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

## Deploy-Stolperfallen (aus Phase 1)

- **Master-Detail-Field:** Kein `<required>true</required>` setzen — Salesforce
  rejecte „Can not specify 'required' for a CustomField of type MasterDetail".
- **PermissionSet-Dependencies:** FieldPermissions auf required Felder
  (`VBOT_Timestamp__c`) dürfen nicht ins PermSet. `VBOT_Asset_Telemetry__c.Read`
  zieht `Asset.Read` nach sich, das wiederum `Account.Read`.
- **FlexiPage-Komponenten in dieser Edition NICHT verfügbar:**
  `flexipage:recordDetailComponent`, `flexipage:relatedListContainer`,
  `runtime_sales_activities:activitiesPanel`, `runtime_chatter:feedContainer`.
  Nutzbar bestätigt: `force:highlightsPanel`, eigene `c:*` Custom LWCs.
- **FlexiPage Tabset:** XML-Variante mit JSON-encoded Tabs ist fragil.
  In Phase 2 über UI bauen und retrieven.
- **FlexiPage `mode>Replace</mode>`:** Nur in nested Regions erlaubt;
  in Top-Level Regions (header/main/sidebar) **weglassen**.
- **ListView Filter-Tokens:** API-Name, `OBJECT.FIELD`, `OBJECT_NAME` — alle
  unzuverlässig in dieser Edition. Nur `ACCOUNT.NAME` und `ASSET.NAME`
  haben sich als deploybar erwiesen.
- **`ServiceContract.Status`:** Read-only, wird aus StartDate/EndDate berechnet.
  Im Insert nicht setzen.
- **`WarrantyTerm.EffectiveStartDate`:** Picklist (Werte „Install Date",
  „Manufacture Date", „Purchase Date"), KEIN Date-Feld.
- **`WorkOrderLineItem.Product2Id`:** Nicht direkt setzen — Salesforce
  setzt es über `PricebookEntryId`.
- **Deploy:** Immer mit `--test-level NoTestRun`, sonst läuft Salesforce die
  Coverage-Tests auf bestehenden Communities-Apex-Klassen (74 % < 75 %).

## Phase-Plan

- Phase 1 (DONE): Setup, Datenmodell, Demo-Daten, Placeholder-Record-Pages
- Phase 2: LWCs `warrantyAdvisorPanel` + 5 Subkomponenten + `WarrantyAdvisorController`
- Phase 3: LWCs `productUpgradeStudio` + 5 Subkomponenten + `ProductUpgradeController`
- Phase 4: LWCs `connectedAssetDashboard` + 6 Subkomponenten + `AssetTelemetryController`
- Phase 5: `agentNudgeBubble` (cross-cutting), Polish, Mobile-Mockup-Slide

## Demo-Daten (Stand Phase 1)

- Account: `VBOT Familie Schmidt` (Berlin)
- Contact: `Anna Schmidt` (anna.schmidt@example.vbot)
- Asset: `VerdantBot C300 #SN-2024-04711`, installiert vor 420 Tagen,
  Battery 78 %, Firmware 3.4.1
- 6 Produkte: `VBOT_E150 / C300 / C500 / X800 / BAT_PLUS / LAWN_AI`
- 3 ServiceContracts: Basic (active), Plus + Premium (Templates)
- 1 WorkOrder mit Scenario `BATTERY_REPLACEMENT_001`
- 30 Telemetry-Records (deterministisch via hashCode-Pseudo-Seed)
