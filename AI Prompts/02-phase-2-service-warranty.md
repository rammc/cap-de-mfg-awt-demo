# Phase 2 Implementation Prompt: Service & Warranty LWCs

## Rolle & Ziel

Du bist Salesforce LWC Engineer und baust den ersten echten Use Case der VerdantBot-Demo: einen Service-Vertrag-Advisor, der auf der WorkOrder-Recordpage erscheint. Die Komponente erlaubt einem Field Specialist, Coverage-Gaps am Asset zu sehen, zwischen drei Servicevertrags-Tiers zu wählen und den Upgrade-Flow zu simulieren – alles mit Mock-Daten aus den `VBOT_*`-Feldern auf `ServiceContract`.

Die Komponente ersetzt den `vbotTabPlaceholder` mit `variant="service-warranty"` auf der `VBOT_WorkOrder_Record_Page`. Die Geometrie (4 Coverage-Tiles + 3 Cards) ist absichtlich identisch zum Wireframe.

## Globale Regeln

- **Branding:** Capgemini-Tokens (Vibrant Blue `#0070AD`, Velocity Blue `#12ABDB`, Deep Purple `#2B1A47`, Charcoal `#1F2A37`, Cool Grey `#E5E7EB`/`#F4F5F7`) – CSS-Variablen pro Bundle.
- **Mock-First:** Apex-Controller liest die `VBOT_*`-Felder von `ServiceContract`, aber gibt fertig modellierte DTOs zurück. Keine echten Schreiboperationen – „Confirm Upgrade" macht nur einen Toast.
- **No Form Tags:** keine `<form>`-Elemente in LWCs.
- **A11y:** alle interaktiven Elemente mit `lightning-button` oder `role`/`aria-*`-Attributen.
- **Mobile-friendly:** SLDS-Grid + Flex-Layouts, Cards stacken bei `max-width: 768px`.

## Komponenten-Architektur

```
warrantyAdvisorPanel (Wrapper, auf FlexiPage)
├── coverageGapVisualizer (4 Tiles, eine Reihe)
├── contractOptionCard × 3 (Basic, Plus, Premium)
├── contractComparisonDrawer (Modal/Drawer, getriggert von „Compare"-Button)
├── eSignaturePreview (Modal, getriggert von „Sign on Tablet"-Button auf Card)
└── contractConfirmationToast (Overlay, nach Signature-Bestätigung)
```

## Komponente 1: `warrantyAdvisorPanel` (Wrapper)

**Pfad:** `force-app/main/default/lwc/warrantyAdvisorPanel/`

### Funktion

- Liest `recordId` der aktuellen WorkOrder via `@api recordId`
- Ruft Apex `WarrantyAdvisorController.getAdvisorData(workOrderId)` auf
- Erhält DTO: aktuelles Asset, aktiver ServiceContract, Coverage-Status, 3 Vertragsoptionen
- Rendert: Header („Servicevertrag für {Asset.Name}") + `coverageGapVisualizer` + 3 `contractOptionCard` Instanzen
- Handlet Events:
  - `comparecontracts` von Card → öffnet `contractComparisonDrawer`
  - `selectcontract` von Card → öffnet `eSignaturePreview`
  - `signaturecomplete` vom Signature-Modal → zeigt `contractConfirmationToast` + setzt State auf „upgraded"
- Loading-State während Apex-Call: zeigt eine kompakte Skeleton-Variante (3 graue Cards, ohne Shimmer-Distraktion).
- Error-State: SLDS-Inline-Error-Message mit Retry-Button.

## Komponente 2: `coverageGapVisualizer`

**Pfad:** `force-app/main/default/lwc/coverageGapVisualizer/`

### Funktion

- `@api coverages` – Array von 4 Objekten: `{ key, label, status, expiresInDays }` mit `status` ∈ `covered | partial | uncovered | expiring`
- Rendert 4 Tiles in einer Reihe (Grid, bei < 768px 2×2)
- Pro Tile: Icon (utility:check, utility:warning, utility:close, utility:clock), Label, Status-Text
- Farben pro Status:
  - `covered`: Velocity Blue Border, hellgrauer Background, Check-Icon
  - `partial`: Amber `#F59E0B`, Warning-Icon
  - `uncovered`: Critical Red `#D4351C`, Close-Icon, **stark hervorgehoben** (Pulsieren-Animation)
  - `expiring`: Charcoal, Clock-Icon, Sub-Text „in {n} Tagen"
- Hover: Tile hebt sich leicht (subtle Shadow + 2px Translation).

## Komponente 3: `contractOptionCard`

**Pfad:** `force-app/main/default/lwc/contractOptionCard/`

### Funktion

- `@api contract` – Objekt: `{ id, tier, name, monthlyPrice, yearlyPrice, isRecommended, coverages, ctaLabel }`
- `@api billingCycle` – `"monthly" | "yearly"` (vom Wrapper getoggled)
- Rendert eine Karte mit:
  - Tier-Badge (oben, farblich nach Tier: Basic = Grau, Plus = Vibrant Blue, Premium = Deep Purple)
  - „RECOMMENDED"-Badge oben rechts (nur wenn `isRecommended`)
  - Tier-Name (z. B. „VerdantCare Plus") als Heading
  - Großer Preis (z. B. „€9,99/Monat" oder „€99/Jahr") mit Toggle-Switch zwischen Monthly/Yearly
  - Coverage-Liste (4 Bullets mit Check/Cross-Icons, korrespondierend zum coverageGapVisualizer)
  - Zwei CTAs unten: „Vergleichen" (Sekundär-Button, dispatcht `comparecontracts`) + „Auswählen" (Primär-Button, dispatcht `selectcontract`)
- Hover: Card hebt sich leicht (Translate + Shadow).
- Recommended-Card hat einen 2px-Vibrant-Blue-Border.

### Events

- `comparecontracts` (bubbles, composed): `{ detail: { contractId } }`
- `selectcontract`: `{ detail: { contractId, billingCycle } }`

## Komponente 4: `contractComparisonDrawer`

**Pfad:** `force-app/main/default/lwc/contractComparisonDrawer/`

### Funktion

- `@api isOpen` – steuert Modal-Visibility
- `@api contracts` – Array der 3 Vertragsoptionen
- Slide-in von rechts (LWC nutzt CSS-Transitions, kein lightning-modal aus Performance-Gründen)
- Rendert Tabelle mit Spalten: Feature | Basic | Plus | Premium
  - Header-Row: Feature-Name
  - Body-Rows: Coverage-Items (8–10 Zeilen: Software-Support, Battery-Coverage, Sensor-Coverage, Hardware-Replacement, Response-Time, On-Site-Service, Replacement-Equipment, Annual-Inspection, Firmware-Updates, etc.)
  - Cells: Check (Velocity Blue), Cross (grau), oder Text-Value (z. B. „24h", „Yes (1×/Jahr)")
- „Close"-Button oben rechts, ESC-Key schließt ebenfalls
- Highlight-Spalte: Recommended-Vertrag hat einen leichten Velocity-Blue-Background

## Komponente 5: `eSignaturePreview`

**Pfad:** `force-app/main/default/lwc/eSignaturePreview/`

### Funktion

- `@api isOpen`, `@api contract` (gewählter Vertrag), `@api customer` (Account-Name)
- Modal-Style (zentriert, Overlay-Background mit Opacity)
- Inhalt:
  - Heading: „Servicevertrag-Upgrade bestätigen"
  - Zusammenfassung: „{customer} - {contract.name} - €{contract.price}/{cycle}"
  - Canvas-Element (`<canvas width="500" height="200">`) für Signatur (PointerEvents-basiert, einfacher Pen-Stroke)
  - Buttons unten: „Abbrechen" + „Bestätigen & Signieren" (letzterer disabled, bis Canvas Strokes hat)
- Beim „Bestätigen": dispatcht `signaturecomplete` Event
- Reset-Button neben Canvas (kleiner Link „Signatur löschen")

### Implementation-Hinweis

- Canvas-Logik: `@track strokes = []`, PointerDown/Move/Up Handler, `quadraticCurveTo` für smooth Lines.
- Touch-Events sind PointerEvents äquivalent (kein extra Code nötig auf iPad).

## Komponente 6: `contractConfirmationToast`

**Pfad:** `force-app/main/default/lwc/contractConfirmationToast/`

### Funktion

- `@api isVisible`, `@api contractName`
- Vollflächiges Overlay (semi-transparent), zentriert ein großer Success-Card
- Card-Inhalt:
  - Animiertes Check-Icon (SVG mit CSS-stroke-dasharray-Animation, 600ms)
  - Heading: „Servicevertrag erfolgreich aktualisiert!"
  - Subtext: „{contractName} ist ab sofort aktiv. Kunde erhält Bestätigung per E-Mail."
  - Single CTA: „Weiter"
- Auto-Dismiss nach 4 Sekunden (setTimeout in `connectedCallback`, cleared in `disconnectedCallback`)

## Apex Controller: `WarrantyAdvisorController`

**Pfad:** `force-app/main/default/classes/WarrantyAdvisorController.cls`

### Methoden

```apex
@AuraEnabled(cacheable=true)
public static AdvisorDataDTO getAdvisorData(Id workOrderId) {
    // 1. Lade WorkOrder mit Asset (AssetId) und Account
    // 2. Lade aktiven ServiceContract des Assets
    // 3. Lade die 3 Template-Verträge (VBOT_Is_Template__c = true) auf demselben Account
    // 4. Baue Coverage-Status aus aktivem SC's VBOT_Covers_* Feldern
    // 5. Baue ContractOptionDTOs mit Preisen, Coverages und Tiers aus VBOT_Tier__c
    // 6. Markiere den mittleren (VBOT_Tier__c = 'Plus') als isRecommended = true
}
```

### DTOs

```apex
public class AdvisorDataDTO {
    @AuraEnabled public String assetName;
    @AuraEnabled public String accountName;
    @AuraEnabled public CurrentContractDTO currentContract;
    @AuraEnabled public List<CoverageItemDTO> coverages;
    @AuraEnabled public List<ContractOptionDTO> options;
}

public class CoverageItemDTO {
    @AuraEnabled public String key;       // 'software' | 'battery' | 'hardware' | 'sensors'
    @AuraEnabled public String label;
    @AuraEnabled public String status;    // 'covered' | 'partial' | 'uncovered' | 'expiring'
    @AuraEnabled public Integer expiresInDays;
}

public class ContractOptionDTO {
    @AuraEnabled public Id contractId;
    @AuraEnabled public String tier;
    @AuraEnabled public String name;
    @AuraEnabled public Decimal monthlyPrice;
    @AuraEnabled public Decimal yearlyPrice;
    @AuraEnabled public Boolean isRecommended;
    @AuraEnabled public List<CoverageItemDTO> coverages;
    @AuraEnabled public String ctaLabel;
}

public class CurrentContractDTO {
    @AuraEnabled public String name;
    @AuraEnabled public String tier;
    @AuraEnabled public Date endDate;
}
```

### Test Class

`WarrantyAdvisorControllerTest.cls`: 75 % Coverage minimum, setUp mit Test-Daten (Account + Asset + WO + 1 aktiver SC + 2 Template SCs), Tests für Happy Path + Error Cases.

## FlexiPage-Update

Ersetze den Placeholder auf der Service-&-Warranty-Position der `VBOT_WorkOrder_Record_Page` durch die neue Komponente `c:warrantyAdvisorPanel`:

```xml
<componentInstance>
    <componentName>c:warrantyAdvisorPanel</componentName>
    <identifier>warrantyAdvisorInstance</identifier>
</componentInstance>
```

## Permission Set Update

Erweitere `VBOT_Demo_Access`:

- Apex-Klasse-Zugriff: `WarrantyAdvisorController`
- Object-Permissions: `ServiceContract` read, `Asset` read, `WorkOrder` read

## Deployment

```bash
sf project deploy validate --source-dir force-app --target-org <alias>
sf project deploy start --source-dir force-app --target-org <alias>
sf apex run test --class-names WarrantyAdvisorControllerTest --target-org <alias> --result-format human
```

## Acceptance Criteria – Phase 2 ist fertig, wenn …

1. Deploy idempotent, Tests grün (>= 75 % Coverage auf `WarrantyAdvisorController`).
2. Öffnen der Demo-WorkOrder zeigt `warrantyAdvisorPanel` mit:
   - Coverage-Visualizer: 4 Tiles, davon mindestens 1 rot („Battery: Not covered") und 1 amber/expiring
   - 3 Contract-Option-Cards, mittlere mit „RECOMMENDED"-Badge und 2px Vibrant-Blue-Border
   - Monthly/Yearly Toggle funktioniert
3. Klick auf „Vergleichen" öffnet Comparison-Drawer mit 3-Spalten-Tabelle.
4. Klick auf „Auswählen" öffnet eSignature-Modal; Bestätigen-Button ist disabled bis Canvas-Strokes da sind.
5. Nach Bestätigung: Confirmation-Toast erscheint mit animiertem Check-Icon, dismisst nach 4s.
6. Alle Komponenten responsive (Cards stacken bei < 768px).
7. Git: committet als `Phase 2: warrantyAdvisorPanel + 5 subcomponents + Apex controller`.

## Output am Ende

1. Deploy-Log-Zusammenfassung
2. Test-Ergebnis (Coverage + Pass/Fail)
3. Liste aller neu erzeugten Dateien
4. Pro Acceptance-Criterion: ✅/⚠️/❌
5. Hinweis: zwei Screenshots der finalen UI (Initial-State + Modal/Drawer geöffnet) für Verifizierung.
