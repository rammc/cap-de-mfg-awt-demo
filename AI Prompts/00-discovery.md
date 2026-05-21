# Discovery Prompt: Manufacturing Cloud Demo Org

## Rolle & Ziel

Du bist Salesforce DevOps Engineer und führst eine **read-only Discovery** auf einer Manufacturing-Cloud-Org durch. Ziel ist es, den aktuellen Stand der Org so zu dokumentieren, dass darauf eine UI/UX-getriebene Demo (Field Service + Service Contract + Up-Sell + Headless 360) aufbauen kann, ohne bestehende Konfiguration zu zerstören oder Namens-Kollisionen zu erzeugen.

**Wichtig: Diese Discovery darf keinerlei Änderungen an der Org vornehmen.** Keine `sf project deploy`, keine `sf data create/update/delete`, keine Apex-Skripte. Nur Lese-Operationen.

## Voraussetzungen

- `sf` CLI v2 ist installiert und der Org-Alias ist als `<alias>` zu verwenden – bitte vor Ausführung durch den tatsächlichen Alias ersetzen (z. B. `manu-demo`).
- Es existiert ein SFDX-Projekt im aktuellen Verzeichnis (`sfdx-project.json` vorhanden).
- Falls einer der Befehle fehlschlägt: Fehler protokollieren, Schritt überspringen, mit nächstem Befehl weitermachen. Keine Abbrüche.

## Vorgehen

Lege zunächst die Verzeichnisstruktur an:

```bash
mkdir -p discovery/{describe,layouts,flexipages,lwc,apex,data,meta}
```

Führe dann die folgenden Schritte aus und schreibe jeweils das Resultat in die angegebene Datei. Bei stdout-Ausgaben in eine Datei umleiten (`> discovery/.../file.json`).

### Schritt 1 – Org-Status & Edition

```bash
sf org display --target-org <alias> --json > discovery/meta/org-display.json
sf org list metadata-types --target-org <alias> --json > discovery/meta/metadata-types.json
```

Prüfe in `org-display.json`:
- `instanceUrl`, `apiVersion`, `edition` (sofern vorhanden)
- Notiere, ob es sich um Scratch / Sandbox / Trial / Production handelt

### Schritt 2 – Manufacturing-Cloud-Feature-Check

```bash
sf data query --query "SELECT DeveloperName, Label, NamespacePrefix FROM PermissionSet WHERE NamespacePrefix IN ('sf_industries','industries','FSL') OR DeveloperName LIKE '%Manufacturing%' OR DeveloperName LIKE '%FieldService%'" --target-org <alias> --json > discovery/meta/permission-sets.json

sf data query --query "SELECT DurableId, QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName IN ('ServiceContract','ContractLineItem','WarrantyTerm','AssetWarranty','ProductWarrantyTerm','WorkOrder','WorkOrderLineItem','Asset','AssetRelationship','MaintenancePlan','ProductRequiredEngagementChannelType')" --target-org <alias> --use-tooling-api --json > discovery/meta/standard-entities.json
```

Vermerk im späteren Summary, welche der erwarteten Objekte vorhanden sind und welche nicht.

### Schritt 3 – SObject Describes für relevante Objekte

Für jedes der folgenden Objekte einen vollen Describe ziehen. Falls ein Objekt in der Org nicht existiert (Fehlermeldung), das im Summary protokollieren und weitermachen.

```bash
for obj in WorkOrder WorkOrderLineItem Asset AssetRelationship ServiceContract ContractLineItem WarrantyTerm AssetWarranty Product2 Pricebook2 PricebookEntry Account Contact; do
  sf sobject describe --sobject "$obj" --target-org <alias> --json > "discovery/describe/${obj}.json" 2> "discovery/describe/${obj}.err" || echo "FAILED: $obj"
done
```

Filtere danach pro Objekt eine kompakte Liste der **Custom Fields** in eine Übersichtsdatei:

```bash
for f in discovery/describe/*.json; do
  obj=$(basename "$f" .json)
  echo "## $obj" >> discovery/describe/_custom-fields-summary.md
  jq -r '.result.fields[] | select(.custom == true) | "- \(.name) (\(.type)) – \(.label)"' "$f" >> discovery/describe/_custom-fields-summary.md 2>/dev/null || echo "- (no jq or no custom fields)" >> discovery/describe/_custom-fields-summary.md
  echo "" >> discovery/describe/_custom-fields-summary.md
done
```

### Schritt 4 – Layouts & Lightning Record Pages auf WorkOrder und Asset

```bash
sf project retrieve start --metadata "Layout:WorkOrder-*" --target-org <alias> --output-dir discovery/layouts --json > discovery/layouts/_retrieve-workorder-layouts.json
sf project retrieve start --metadata "Layout:Asset-*" --target-org <alias> --output-dir discovery/layouts --json > discovery/layouts/_retrieve-asset-layouts.json
sf project retrieve start --metadata "FlexiPage" --target-org <alias> --output-dir discovery/flexipages --json > discovery/flexipages/_retrieve-flexipages.json
```

Nach dem Retrieve: liste alle gefundenen FlexiPages und filtere die, die WorkOrder oder Asset betreffen:

```bash
find discovery/flexipages -name "*.flexipage-meta.xml" | while read f; do
  if grep -qE "(WorkOrder|Asset)" "$f"; then
    echo "$f" >> discovery/flexipages/_relevant-flexipages.txt
  fi
done
```

### Schritt 5 – Konflikt-Check: bestehende Demo-Daten

```bash
sf data query --query "SELECT Id, Name, ProductCode, Family FROM Product2 ORDER BY CreatedDate DESC LIMIT 50" --target-org <alias> --json > discovery/data/products.json
sf data query --query "SELECT Id, Name, AccountId, Account.Name, Product2Id, Product2.Name, SerialNumber, InstallDate FROM Asset ORDER BY CreatedDate DESC LIMIT 50" --target-org <alias> --json > discovery/data/assets.json
sf data query --query "SELECT Id, WorkOrderNumber, Subject, Status, AssetId, AccountId FROM WorkOrder ORDER BY CreatedDate DESC LIMIT 50" --target-org <alias> --json > discovery/data/workorders.json
sf data query --query "SELECT Id, Name, ContractNumber, AccountId, StartDate, EndDate, Status FROM ServiceContract ORDER BY CreatedDate DESC LIMIT 50" --target-org <alias> --json > discovery/data/servicecontracts.json
sf data query --query "SELECT Id, Name, WarrantyDuration, WarrantyUnit FROM WarrantyTerm ORDER BY CreatedDate DESC LIMIT 50" --target-org <alias> --json > discovery/data/warrantyterms.json
sf data query --query "SELECT Id, Name, BillingCity FROM Account WHERE Type = 'Customer' OR Type = NULL ORDER BY CreatedDate DESC LIMIT 30" --target-org <alias> --json > discovery/data/accounts.json
```

### Schritt 6 – Konflikt-Check: bestehende LWCs & Apex-Klassen

```bash
sf data query --query "SELECT Id, DeveloperName, MasterLabel, NamespacePrefix FROM LightningComponentBundle ORDER BY DeveloperName" --target-org <alias> --use-tooling-api --json > discovery/lwc/_bundles.json

sf data query --query "SELECT Id, Name, NamespacePrefix, Status FROM ApexClass WHERE NamespacePrefix = NULL ORDER BY Name" --target-org <alias> --use-tooling-api --json > discovery/apex/_classes.json
```

Erstelle daraus zwei kompakte Listen:

```bash
jq -r '.result.records[] | "- \(.DeveloperName) [\(.NamespacePrefix // "default")]"' discovery/lwc/_bundles.json > discovery/lwc/_bundle-names.txt 2>/dev/null
jq -r '.result.records[] | "- \(.Name)"' discovery/apex/_classes.json > discovery/apex/_class-names.txt 2>/dev/null
```

Prüfe gegen diese geplante Namensliste und protokolliere Kollisionen:

```
Geplante LWC-Bundles:
- warrantyAdvisorPanel, coverageGapVisualizer, contractOptionCard, contractComparisonDrawer, eSignaturePreview, contractConfirmationToast
- productUpgradeStudio, assetContextBanner, upgradeRecommendationGrid, specDiffComparator, reasoningExplainer, quoteCartFlyout
- connectedAssetDashboard, assetHealthHeader, usageTimelineChart, lawnHealthMap, predictiveMaintenanceCard, headlessSyncIndicator, mobilePreviewMirror
- agentNudgeBubble
- cgTokens (Static Resource oder Hilfs-Bundle)

Geplante Apex-Klassen:
- WarrantyAdvisorController, ProductUpgradeController, AssetTelemetryController
- WarrantyAdvisorMockDataProvider, ProductUpgradeMockDataProvider, AssetTelemetryMockDataProvider
```

### Schritt 7 – Repo-Struktur

```bash
cat sfdx-project.json > discovery/meta/sfdx-project.json
ls -la > discovery/meta/repo-root.txt
find . -maxdepth 3 -type d -not -path "./node_modules*" -not -path "./.git*" > discovery/meta/repo-tree.txt
```

## Deliverable: Discovery-Summary

Erzeuge am Ende eine Datei `discovery/SUMMARY.md` mit folgender Struktur:

```markdown
# Discovery Summary – Manufacturing Cloud Demo Org

## 1. Org-Eckdaten
- Alias / Instance URL / API Version
- Org-Typ: Scratch / Sandbox / Trial / Production
- Edition

## 2. Manufacturing Cloud & FSL Status
- Permission Sets gefunden: [Liste]
- Standardobjekte verfügbar: [Tabelle aus Schritt 2]
- Bewertung: ist die Org bereit für die geplante Demo?

## 3. Custom Fields auf relevanten Standardobjekten
- Pro Objekt: Liste der bereits existierenden Custom Fields
- Risiken: wo könnten Konflikte mit unserer Demo entstehen?

## 4. Page Layouts & Lightning Record Pages
- WorkOrder: gefundene Layouts + aktive FlexiPage(s)
- Asset: gefundene Layouts + aktive FlexiPage(s)
- Andockstellen für neue Tabs „Service & Warranty", „Upgrades", „Connected Asset"

## 5. Existierende Demo-Daten
- Wieviele Products / Assets / WorkOrders / ServiceContracts existieren?
- Konflikte mit geplanten VerdantBot-Daten? (Namens-Kollisionen?)
- Empfehlung: Daten löschen, in Ruhe lassen, oder mit Prefix arbeiten?

## 6. LWC- und Apex-Konflikte
- Existieren Bundles mit denselben Namen wie unsere geplanten LWCs? [Liste]
- Existieren Apex-Klassen mit denselben Namen? [Liste]
- Wo müssen wir umbenennen?

## 7. Repo-Setup
- Package Directory(s)
- API Version im sfdx-project.json
- Auffälligkeiten in der Repo-Struktur

## 8. Risiken & Empfehlungen für Phase 1
- Top-3-Risiken
- Top-3-Empfehlungen, bevor wir mit dem Setup starten
- Offene Fragen an Christopher
```

## Abschluss

Wenn `discovery/SUMMARY.md` fertig ist:

1. Zeige mir den Inhalt von `SUMMARY.md` als Output.
2. Liste alle erzeugten Dateien unter `discovery/` mit Größenangabe.
3. Wenn Befehle fehlgeschlagen sind: liste die Fehler am Ende des Summary unter „Bekannte Fehler".

**Nicht** die Custom-Fields-Summary, FlexiPage-XMLs oder andere große Files in den Chat dumpen – nur Pfade nennen, ich pulle sie selektiv nach.
