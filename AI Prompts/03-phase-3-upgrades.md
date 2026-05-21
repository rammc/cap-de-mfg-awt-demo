# Phase 3 Implementation Prompt: Up-/Cross-Sell LWCs

## Rolle & Ziel

Du bist Salesforce LWC Engineer und baust den zweiten echten Use Case der VerdantBot-Demo: einen Produkt-Upgrade-Studio, der auf derselben WorkOrder-Recordpage erscheint, **unter** dem Service-&-Warranty-Panel. Die Komponente zeigt dem Field Specialist drei Upgrade-Empfehlungen (Batterie-Upgrade, Modell-Upgrade Comfort+, Modell-Upgrade Pro) basierend auf Asset-Kontext und Nutzungsmustern, mit Reasoning-Erklärung und Quote-Cart-Flyout.

Die Komponente ersetzt den `vbotTabPlaceholder` mit `variant="upgrades"` auf der `VBOT_WorkOrder_Record_Page`. Geometrische Kontinuität zum Wireframe: Asset-Context-Banner oben, 3 Produkt-Karten in einer Reihe (mittlere mit Fit-Score-Badge), Reasoning-Card unten.

## Globale Regeln

- **Branding:** identische Capgemini-Tokens wie Phase 2. CSS-Variablen pro Bundle.
- **Konsistenz mit Phase 2:** Card-Shadow, Card-Radius (12px), Hover-Translation, Button-Styles, Modal/Drawer-Mechanik **müssen** mit Phase 2 identisch sein. Vor dem Bauen: einmal in den Phase-2-Bundles (insbesondere `contractOptionCard.css` und `contractComparisonDrawer.css`) nachsehen und die Werte übernehmen.
- **Mock-First:** Apex-Controller liest reale Felder von `Product2` und `Asset`, gibt aber fertig modellierte DTOs zurück. „Add to Quote" macht keinen echten Quote-Insert.
- **No Form Tags:** keine `<form>`-Elemente in LWCs.
- **A11y:** `lightning-button`, `role`/`aria-*` für Buttons und Modals.
- **Mobile-friendly:** Cards stacken bei `max-width: 768px`, Banner bleibt zweispaltig bis `max-width: 600px`.

## Komponenten-Architektur

```
productUpgradeStudio (Wrapper, auf FlexiPage)
├── assetContextBanner (Hero, eine Reihe)
├── upgradeRecommendationGrid
│   └── productUpgradeCard × 3 (Bundle, analog zur contractOptionCard-Architektur aus Phase 2)
├── specDiffComparator (Drawer, getriggert von „Vergleichen"-Button)
├── reasoningExplainer (Card, immer sichtbar unten)
└── quoteCartFlyout (Slide-in von rechts, getriggert von „Zu Quote hinzufügen")
```

## Komponente 1: `productUpgradeStudio` (Wrapper)

**Pfad:** `force-app/main/default/lwc/productUpgradeStudio/`

### Funktion

- Liest `recordId` der aktuellen WorkOrder via `@api recordId`
- Ruft Apex `ProductUpgradeController.getUpgradeData(workOrderId)` auf
- Erhält DTO: Asset-Kontext (Modell, Property-Size, Battery-Health, Install-Date), 3 Upgrade-Optionen, Reasoning-Bullets, aktuelles Produkt
- Rendert: Header („Upgrade-Empfehlungen für {Asset.Name}") + `assetContextBanner` + `upgradeRecommendationGrid` + `reasoningExplainer`
- Handlet Events:
  - `comparespecs` von Card → öffnet `specDiffComparator` mit ausgewählter Upgrade-Option
  - `addtoquote` von Card → öffnet `quoteCartFlyout`
  - Flyout dispatcht `sendquote` → Erfolgs-Toast via `ShowToastEvent`
- Loading-State, Error-State analog Phase 2

## Komponente 2: `assetContextBanner`

**Pfad:** `force-app/main/default/lwc/assetContextBanner/`

### Funktion

- `@api asset` – Objekt: `{ name, productName, productImageUrl, installedMonthsAgo, propertySize, batteryHealthPct, firmwareVersion }`
- Rendert eine breite Banner-Card:
  - **Linker Bereich (30%):** Produkt-Bild (über `<img>` mit `productImageUrl`; falls leer: SLDS-Default-Icon `utility:product` in Velocity Blue, 80×80px in einem Cool-Grey-Quadrat mit Border-Radius 8px)
  - **Mittlerer Bereich (40%):** Asset-Name (groß, Deep Purple), darunter Produkt-Name (Charcoal), darunter Install-Datum als sekundäre Info
  - **Rechter Bereich (30%):** 3 Pills horizontal: „Grundstück: {propertySize} m²", „Akku: {batteryHealthPct}%", „Firmware: {firmwareVersion}"
- Bei `max-width: 768px`: Banner wird einspaltig
- Bei `max-width: 600px`: Pills stacken vertikal

## Komponente 3: `upgradeRecommendationGrid`

**Pfad:** `force-app/main/default/lwc/upgradeRecommendationGrid/`

### Funktion

- `@api options` – Array von 3 ProductUpgradeOptionDTOs
- Rendert 3 `productUpgradeCard` in einer Reihe (Grid)
- Bei `max-width: 1024px`: 2 Spalten
- Bei `max-width: 768px`: 1 Spalte
- Bubble-Events von Karten weiterleiten (`comparespecs`, `addtoquote`)

## Komponente 4: `productUpgradeCard`

**Pfad:** `force-app/main/default/lwc/productUpgradeCard/`

### Funktion

- `@api option` – ProductUpgradeOptionDTO mit `productId, productCode, name, tier, heroImageUrl, price, fitScore, isRecommended, specs, valueProps, ctaLabel`
- Rendert Karte:
  - **Header:** Tier-Badge (oben links, farblich nach Tier)
  - **Recommended-Badge:** „86 % Fit" oben rechts, nur wenn `isRecommended`
  - **Hero-Image-Area:** 100px hoch, Cool-Grey-Background, zentriertes Produktbild oder Fallback-Icon
  - **Produkt-Name:** Bold, Deep Purple, 1.125rem
  - **Preis:** Groß (1.5rem), Charcoal, „€{price}" – Einmalpreis ohne Toggle (Unterschied zu Phase 2)
  - **Specs-Liste:** 3-4 Zeilen mit Icons
  - **Value-Props:** 2-3 Bullet-Points in Italic
  - **Footer-CTAs:** „Vergleichen" (Sekundär) + „Zu Quote hinzufügen" (Primär)
- Hover: 2px Translate-Up, Shadow leicht erhöht
- Recommended-Card hat 2px Vibrant-Blue-Border

### Events

- `comparespecs` (bubbles, composed): `{ detail: { productId } }`
- `addtoquote`: `{ detail: { option } }` (komplettes Option-Objekt)

## Komponente 5: `specDiffComparator`

**Pfad:** `force-app/main/default/lwc/specDiffComparator/`

### Funktion

- `@api isOpen`, `@api currentProduct`, `@api selectedUpgrade`
- Slide-in von rechts, **identisch zur `contractComparisonDrawer`-Mechanik aus Phase 2**
- Inhalt:
  - **Header:** „Vergleich: {currentProduct.name} vs. {selectedUpgrade.name}"
  - **Body:** Side-by-Side-Tabelle, 2 Spalten (Charcoal-Background links, Vibrant-Blue-5%-Background rechts)
  - **Spec-Zeilen (8-10):** Mähleistung, Akku-Kapazität, Akku-Laufzeit, GPS, Lawn-AI, Hangneigung, Lärmpegel, Garantie, Preis
  - **Diff-Visualisierung:** grünes „+" bei Verbesserung, grau bei identisch, Critical Red bei Verschlechterung
  - **Footer:** „Schließen" + „Zu Quote hinzufügen"

## Komponente 6: `reasoningExplainer`

**Pfad:** `force-app/main/default/lwc/reasoningExplainer/`

### Funktion

- `@api reasoning` – Objekt: `{ headline, bullets: [{ icon, text }], confidence }`
- Rendert eine schmale, breite Card unter dem Grid:
  - **Header-Row:** Einstein-Icon + Headline („Warum diese Empfehlungen?") + „AI-generated"-Pill rechts
  - **Bullet-Liste (3-4 Items):** Icon + Bullet-Text
  - **Confidence-Indicator unten:** Horizontale Bar (80% gefüllt mit Vibrant Blue), Label „Confidence: 86 %"
- Background: weißer Card-Background mit Cool-Grey-Akzent links (4px Vibrant-Blue-Border-Left)

## Komponente 7: `quoteCartFlyout`

**Pfad:** `force-app/main/default/lwc/quoteCartFlyout/`

### Funktion

- `@api isOpen`, `@api items`, `@api customer`
- Slide-in von rechts (380px breit)
- Inhalt:
  - **Header:** „Quote-Vorschau" + Close-Button
  - **Customer-Info:** Account + Contact (Cool-Grey-Background-Pill)
  - **Items-Liste:** Pro Item: Mini-Hero-Image (40×40px) + Name + Preis + „Entfernen"-Icon
  - **Summary-Box unten:** Anzahl Items, Zwischensumme, „inkl. MwSt."
  - **Footer-CTAs:** „Speichern" (Sekundär) + „An Kunde senden" (Primär, dispatcht `sendquote`)

## Apex Controller: `ProductUpgradeController`

**Pfad:** `force-app/main/default/classes/ProductUpgradeController.cls`

### Methoden

```apex
@AuraEnabled(cacheable=true)
public static UpgradeStudioDataDTO getUpgradeData(Id workOrderId) {
    // 1. Lade WorkOrder mit Asset + Account
    // 2. Lade Asset mit Product2 + VBOT_Property_Size_Sqm__c + VBOT_Battery_Health_Pct__c + InstallDate + VBOT_Firmware_Version__c
    // 3. Lade alle Product2 mit ProductCode LIKE 'VBOT_%' und ProductCode != current Product
    // 4. Wähle 3 Upgrade-Optionen basierend auf Asset-Kontext:
    //    - BAT_PLUS (Batterie-Upgrade) - immer relevant bei Battery_Health < 85 %
    //    - C500 (kleines Modell-Upgrade) - relevant bei Property_Size > Current.Max_Area
    //    - X800 (großes Modell-Upgrade) - der Top-Pick wenn Property_Size > 1.000 m²
    // 5. Mittlere Option (C500) als isRecommended = true mit fitScore = 86
    // 6. Reasoning-Bullets aus Asset-Daten ableiten
}
```

### DTOs

`UpgradeStudioDataDTO`, `AssetContextDTO`, `ProductContextDTO`, `ProductUpgradeOptionDTO`, `SpecRowDTO`, `ReasoningDTO`, `ReasoningBulletDTO` – siehe Phase-3-Spec für detaillierte Felder.

### Test Class

`ProductUpgradeControllerTest.cls`: ≥75 % Coverage, Tests für Happy Path + Edge Cases (Property_Size NULL, WO ohne Asset).

## FlexiPage-Update

Ersetze den Placeholder mit `variant="upgrades"` durch:

```xml
<componentInstance>
    <componentName>c:productUpgradeStudio</componentName>
    <identifier>productUpgradeStudioInstance</identifier>
</componentInstance>
```

## Permission Set Update

Erweitere `VBOT_Demo_Access`:
- Apex-Klasse-Zugriff: `ProductUpgradeController`
- Object-Permissions: `Product2` read, `Pricebook2` read, `PricebookEntry` read

## Hero-Images

In Phase 3 **ohne echte Static Resources** lassen. Fallback-Icons reichen. Wenn Bilder beigesteuert werden, kommen sie als separater Polish-Schritt rein.

## Deployment

```bash
sf project deploy validate --source-dir force-app --target-org <alias>
sf project deploy start --source-dir force-app --target-org <alias>
sf apex run test --class-names ProductUpgradeControllerTest --target-org <alias> --result-format human
```

## Acceptance Criteria – Phase 3 ist fertig, wenn …

1. Deploy idempotent, Tests grün (≥75 % Coverage).
2. Demo-WorkOrder zeigt unter dem `warrantyAdvisorPanel` das `productUpgradeStudio` mit Banner, 3 Cards (mittlere recommended), Reasoning-Card.
3. Klick auf „Vergleichen" öffnet `specDiffComparator` mit Side-by-Side-Tabelle.
4. Klick auf „Zu Quote hinzufügen" öffnet `quoteCartFlyout`.
5. Klick auf „An Kunde senden" zeigt Success-Toast und schließt Flyout.
6. Alle Komponenten responsive.
7. **Visuelle Konsistenz mit Phase 2:** Card-Shadow, Border-Radius, Hover-Translate, Drawer-Transition identisch.
8. Git: committet als `Phase 3: productUpgradeStudio + 6 subcomponents + Apex controller`.

## Output am Ende

1. Deploy-Log
2. Test-Ergebnis
3. Liste aller neuen Dateien
4. Pro Acceptance-Criterion: ✅/⚠️/❌
5. Hinweis: zwei Screenshots der finalen UI
6. Hard-Reload-Reminder: ⌘⇧R
