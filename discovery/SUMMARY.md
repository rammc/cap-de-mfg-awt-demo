# Discovery Summary – Manufacturing Cloud Demo Org

_Generiert: 2026-05-19 · CLI: sf v2.134.6 · Modus: read-only_

## 1. Org-Eckdaten

| Schlüssel | Wert |
|---|---|
| Alias | `christopher.ramm@cap-de-mfg-awt-demo.com` |
| Org Id | `00DWz0000093KppMAE` |
| Name | Mfg cloud for AWT Demo org. |
| Instance URL | https://cap-de-mfg-awt-demo-dev-ed.develop.my.salesforce.com |
| Instance | DEU90 |
| API Version | 66.0 |
| Org-Typ | **Developer Edition** (kein Sandbox, kein Scratch, kein Trial) |
| Namespace | _kein_ |
| TrialExpirationDate | – |
| Metadata Types | 316 |

Quelle: `discovery/meta/org-display.json`, `discovery/meta/organization.json`, `discovery/meta/metadata-types.json`.

## 2. Manufacturing Cloud & FSL Status

**Permission Sets (25 Treffer):**

- **Field Service (FSL):** `sfdc_fieldservice` [sfdcInternalInt], `FieldServiceAdmin` [default], `FieldServiceDispatcher` [default], `FieldServiceServiceResource` [default], `FieldServiceAgentforceSchedulingSupervisorView`, `FieldServiceDocumentBuilderDispatcher/Mobile/Standard`, `FieldServiceMobileStandardPermSet` (alle `force` Namespace).
- **Manufacturing Cloud:** `ManufacturingFoundationUserPsl`, `ManufacturingAccountForecastPsl`, `ManufacturingAdvancedAccountForecastPsl`, `ManufacturingAdvAccForecastForCmtyPsl`, `ManufacturingAccountManagerTargetsPsl`, `ManufacturingAnalyticsAdmin/User`, `ManufacturingSalesAgreementsPsl`, `ManufacturingSalesAgreementsForCmtyPsl`, `ManufacturingSampleMgmtUserPsl`, `ManufacturingSampleMgmtForCmtyUserPsl`, `ManufacturingPartnerLeadMgmtPsl`, `ManufacturingPartnerPerformanceMgmtPsl`, `ManufacturingPartnerVisitMgmtPsl`, `ManufacturingProgramBasedBusinessPsl` (alle `force` Namespace).
- **Einstein:** `EinsteinForManufacturingPsl`.

**Standardobjekte (Soll ↔ Ist):**

| Erwartet | Vorhanden |
|---|---|
| WorkOrder | ✅ |
| WorkOrderLineItem | ✅ |
| Asset | ✅ |
| AssetRelationship | ✅ |
| ServiceContract | ✅ |
| ContractLineItem | ✅ |
| WarrantyTerm | ✅ |
| AssetWarranty | ✅ |
| ProductWarrantyTerm | ✅ |
| MaintenancePlan | ✅ |
| ProductRequiredEngagementChannelType | ❌ _(nicht in dieser Org)_ |

**Bewertung:** Org ist Manufacturing Cloud + Field Service ready. 10 von 11 erwarteten Standardobjekten verfügbar, alle nötigen Lizenz-Permission-Sets installiert. `ProductRequiredEngagementChannelType` (Channel-Type-Steuerung pro Produkt) fehlt – wahrscheinlich nicht für eine UI-getriebene Demo nötig.

Quellen: `discovery/meta/permission-sets.json`, `discovery/meta/standard-entities.json`.

## 3. Custom Fields auf relevanten Standardobjekten

| Objekt | Custom Fields | Anmerkung |
|---|---|---|
| WorkOrder | 4 | Alle 4 aus `FSL__` Managed Package |
| WorkOrderLineItem | 2 | Beide aus `FSL__` Managed Package |
| Asset | 0 | – |
| AssetRelationship | 0 | – |
| AssetWarranty | 0 | – |
| ServiceContract | 0 | – |
| ContractLineItem | 0 | – |
| WarrantyTerm | 0 | – |
| Product2 | 0 | – |
| Pricebook2 | 0 | – |
| PricebookEntry | 0 | – |
| Account | 7 | Standard Salesforce-Sample-Fields: `CustomerPriority__c`, `SLA__c`, `Active__c`, `NumberofLocations__c`, `UpsellOpportunity__c`, `SLASerialNumber__c`, `SLAExpirationDate__c` |
| Contact | 2 | `Level__c`, `Languages__c` |

**Risiken:**

- Auf `Account` existieren bereits semantisch ähnlich klingende Felder (`SLA__c`, `UpsellOpportunity__c`). Wenn die Demo eigene SLA-/Upsell-Konzepte einführt, droht **semantische** Verwirrung (kein technischer Konflikt). Empfehlung: eigene Felder mit Demo-Prefix anlegen (z. B. `WT_SLA_Tier__c`).
- Alle `FSL__`-Felder sind Managed-Package-Eigentum → für eigene Erweiterungen unangetastet lassen, mit eigenem Prefix arbeiten.

Volldetail: `discovery/describe/_custom-fields-summary.md` und `discovery/describe/<Object>.json`.

## 4. Page Layouts & Lightning Record Pages

**WorkOrder Layouts (4):**

- `WorkOrder-Work Order Layout` (Standard)
- `WorkOrder-System Administrator Work Order Layout`
- `WorkOrder-Field Service Technician Work Order Layout`
- `WorkOrder-Field Service Dispatcher Work Order Layout`

**Asset Layouts (1):**

- `Asset-Asset Layout` (Standard)

**FlexiPages (10 retrieved):** Alle 10 sind **Utility-Bars für Standard-Apps** (`Field_Service_Console_UtilityBar1`, `IndustriesEcm_UtilityBar`, `LightningSales/Service`-UtilityBars, etc.). **Keine** Custom Lightning Record Page für `WorkOrder` oder `Asset` (`_relevant-flexipages.txt` ist leer).

**Andockstellen für neue Tabs (Service & Warranty / Upgrades / Connected Asset):**

- Da keine Custom-Record-Pages existieren, lässt sich für WorkOrder & Asset jeweils eine eigene Lightning Record Page anlegen, ohne mit Bestehendem zu kollidieren. Wir bauen Greenfield über `<Object>-Record-Page` (FlexiPage) + `lightningCommunities__RecordPage` als Target und docken die LWC-Tabs in `<tabset>` an.
- Salesforce-managed Default-Record-Pages werden über die Metadata API nicht ausgeliefert – nicht ungewöhnlich. Wenn nötig, in der UI prüfen, ob die Org bereits eine aktive Custom Page hat, die nicht extrahiert wurde (unwahrscheinlich, da keine im Retrieve erschien).

Quellen: `discovery/layouts/`, `discovery/flexipages/`.

## 5. Existierende Demo-Daten

| Objekt | Count | Highlights |
|---|---|---|
| Product2 | **17** | Klassisches Salesforce-Sample-Set: GenWatt Diesel/Propane/Gasoline (`GC1020`…`GC5060`), Installation Services (`IN70*`), SLA Bronze/Silver/Gold/Platinum (`SL90*`) |
| Asset | 0 | – |
| WorkOrder | 0 | – |
| ServiceContract | 0 | – |
| WarrantyTerm | 0 | – |
| Account | 2 | `sForce` (San Francisco), `Sample Account for Entitlements` |

**Konflikte mit geplanten Demo-Daten:** Keine Namens-Kollisionen erkennbar – die GenWatt-Generatoren passen thematisch nicht zur geplanten Manufacturing/Lawn-Care/VerdantBot-Demo.

**Empfehlung:** GenWatt-Sample-Daten **stehen lassen, aber im Demo-Flow ignorieren**. Eigene Demo-Daten mit Prefix (z. B. `WT_` oder branded Modellnamen) seeden, damit sie eindeutig identifizierbar sind und bei Bedarf gezielt wieder gelöscht werden können.

Quellen: `discovery/data/*.json`.

## 6. LWC- und Apex-Konflikte

| Suchraum | Treffer | Default-Namespace |
|---|---|---|
| LightningComponentBundle | 533 total | **0** |
| ApexClass (Namespace = NULL) | 26 | 26 |

**LWC-Verteilung:** 422 × `omnistudio`, 111 × `FSL` (alles Managed Package). Im **default**-Namespace existiert **kein einziges** Bundle.

**Apex-Klassen im default-Namespace (26):** Ausschließlich auto-generated Communities-Controller (`ChangePasswordController`, `CommunitiesLanding/Login/SelfReg…`, etc.).

**Kollisions-Check gegen geplante Liste:**

- Geplante LWCs (21 Namen): `warrantyAdvisorPanel`, `coverageGapVisualizer`, `contractOptionCard`, `contractComparisonDrawer`, `eSignaturePreview`, `contractConfirmationToast`, `productUpgradeStudio`, `assetContextBanner`, `upgradeRecommendationGrid`, `specDiffComparator`, `reasoningExplainer`, `quoteCartFlyout`, `connectedAssetDashboard`, `assetHealthHeader`, `usageTimelineChart`, `lawnHealthMap`, `predictiveMaintenanceCard`, `headlessSyncIndicator`, `mobilePreviewMirror`, `agentNudgeBubble`, `cgTokens` → **0 Kollisionen**.
- Geplante Apex-Klassen (6 Namen): `WarrantyAdvisorController`, `ProductUpgradeController`, `AssetTelemetryController`, `WarrantyAdvisorMockDataProvider`, `ProductUpgradeMockDataProvider`, `AssetTelemetryMockDataProvider` → **0 Kollisionen**.

Quellen: `discovery/lwc/_bundles.json`, `discovery/lwc/_bundle-names.txt`, `discovery/apex/_classes.json`, `discovery/apex/_class-names.txt`.

## 7. Repo-Setup

- **Package Directories:** `force-app` (default)
- **Source API Version:** `66.0` (passt zur Org)
- **Namespace:** leer
- **Login URL:** `https://login.salesforce.com`
- **Toolchain:** husky pre-commit Hook, eslint, prettier, jest – Standard SFDX-Template
- **Repo-Wurzel:** `~/cap-de-mfg-awt-demo/` (Git-tracked auf `rammc/cap-de-mfg-awt-demo`, private)
- **Auffälligkeiten:** `force-app/main/default/*` ist **leer** (alle Standard-Unterordner existieren, aber keine Metadata-Dateien). Erwartet für Greenfield.

Quelle: `discovery/meta/sfdx-project.json`, `discovery/meta/repo-root.txt`, `discovery/meta/repo-tree.txt`.

## 8. Risiken & Empfehlungen für Phase 1

**Top-3-Risiken:**

1. **Developer Edition, nicht Sandbox/Scratch** → keine "Reset"-Möglichkeit. Jede Veränderung ist relativ persistent. Vorsicht beim Seeden/Löschen von Demo-Daten; ggf. einzeln rückbaubar machen.
2. **Salesforce-Sample-Demo-Daten (GenWatt + Account-Custom-Fields) vorhanden** → können bei Live-Demos sichtbar werden, wenn nicht über List-Views/Filter ausgeblendet. Semantische Reibung zwischen `Account.SLA__c` (Sample) und einem etwaigen demo-eigenen SLA-Konzept.
3. **Keine Custom Lightning Record Pages und keine eigenen Custom-Objekte** → Greenfield-Vorteil, aber: alle UI-Andockpunkte für die geplante Demo müssen wir selbst anlegen. Kein bestehendes Custom-Tab-Setup übernehmbar.

**Top-3-Empfehlungen vor Phase-1-Setup:**

1. **Naming-Konvention festlegen** (z. B. `WT_` als Prefix für alle Custom Fields / Custom Objects; gehäuselos für LWCs aber Anti-Kollisions-Pattern). Vor dem ersten Deploy in CLAUDE.md / README dokumentieren.
2. **Demo-User & Permission-Set-Strategie:** `ManufacturingFoundationUserPsl` + `FieldServiceAdmin` + ggf. eigenes `WT_Demo_PermSet` als Wrapper. Nicht direkt am User Profile arbeiten.
3. **Discovery-Snapshot ins Repo committen** (`discovery/` ist bereits da) – dient als Baseline für Diff bei jedem späteren Retrieve, damit unbeabsichtigte Org-Drifts sichtbar werden.

**Offene Fragen an Christopher:**

- Soll die geplante Demo (Field Service + Service Contract + Up-Sell + Headless 360) auf einem **Lawn-Care/VerdantBot**-Narrativ basieren (Schritt 6 deutet `lawnHealthMap` an) oder breiter Manufacturing?
- Welcher **Prefix** für Custom-Metadata: `cg_` (Capgemini), `WT_` (Working Title), `VB_` (VerdantBot) oder anderes?
- Sollen die GenWatt-Sample-Products **gelöscht** oder mittels Record-Type/Family **ausgeblendet** werden?
- Soll die `force-app`-Skeleton-Struktur mit `.gitkeep` versehen werden, damit die Ordnerhierarchie schon committet ist, bevor Inhalte rein kommen?

## Bekannte Fehler (während der Discovery aufgetreten)

| Schritt | Befehl/Query | Problem | Auflösung |
|---|---|---|---|
| 2 | `PermissionSet` SOQL aus Spec | `DeveloperName` existiert nicht auf `PermissionSet` (heißt `Name`) | Re-run mit `Name` → 25 Treffer |
| 5 | `WarrantyTerm` SOQL aus Spec | `Name` (→ `WarrantyTermName`) und `WarrantyUnit` (→ `WarrantyUnitOfTime`) existieren nicht | Re-run mit korrekten API-Namen → 0 Records |

Beide Fehler sind Spec-Bugs (falsche Feldnamen), nicht Org-Probleme. Empfehlung: Spec-Vorlage entsprechend nachziehen.
