# Phase 4 Implementation Prompt: Connected Asset Dashboard (Headless 360)

## Rolle & Ziel

Du bist Salesforce LWC Engineer und baust den dritten und visuell anspruchsvollsten Use Case der VerdantBot-Demo: ein Connected-Asset-Dashboard auf der Asset-Recordpage, das Telemetriedaten aus der Mobile App visualisiert und damit den Headless-360-Ansatz für die Bühne sichtbar macht. Die Komponente zeigt dem Field Specialist Battery-Health, Operating-Hours, Mowed-Area, einen 30-Tage-Telemetrie-Verlauf, eine Lawn-Health-Map mit eingefärbten Zonen, eine Predictive-Maintenance-Empfehlung und – als visuelles Schlüssel-Element – einen Mobile-Preview-Mirror, der genau zeigt, was der Endkunde in der Mobile App sieht.

Die Komponente ersetzt den `vbotTabPlaceholder` mit `variant="connected-asset"` auf der `VBOT_Asset_Record_Page`. Datenquelle ist das `VBOT_Asset_Telemetry__c`-Objekt (30 Tagesdatensätze, in Phase 1 geseedet).

## Globale Regeln

- **Branding:** identische Capgemini-Tokens wie Phase 2 + 3. CSS-Variablen pro Bundle.
- **Konsistenz mit Phase 2 + 3:** Card-Shadow, Card-Radius (12px), Hover-Translation, Button-Styles **identisch**.
- **Daten-First:** Apex-Controller liest reale `VBOT_Asset_Telemetry__c`-Records, aggregiert sie zu Display-DTOs.
- **SVG statt Chart-Library:** Telemetrie-Chart und Lawn-Map werden als **handgebaute SVG** in der LWC gerendert. Kein Chart.js, kein Lightning Charts, keine Static Resources.
- **No Form Tags, A11y:** wie in Phase 2 + 3.
- **Mobile-friendly:** KPI-Tiles stacken bei `max-width: 1024px` (2×2), Chart und Lawn-Map bleiben full-width, Mobile-Preview-Mirror wird bei `max-width: 768px` unter den Chart gepusht.

## Komponenten-Architektur

```
connectedAssetDashboard (Wrapper, auf FlexiPage)
├── assetHealthHeader (4 KPI-Tiles, eine Reihe)
├── usageTimelineChart (SVG, 30-Tage-Verlauf, mit Range-Toggle)
├── lawnHealthMap (SVG, eingefärbte Zonen)
├── predictiveMaintenanceCard (Side-by-Side mit Lawn-Map möglich, oder unten)
├── headlessSyncIndicator (kleine Statusleiste, dauerhaft sichtbar)
└── mobilePreviewMirror (iPhone-Frame mit gespiegelten Daten)
```

**Layout:** zweispaltig auf Desktop:
- Links (60%): `assetHealthHeader` (full-width oben), darunter `usageTimelineChart`, darunter `lawnHealthMap` + `predictiveMaintenanceCard` Side-by-Side
- Rechts (40%): `mobilePreviewMirror` (sticky, scrollt mit, max-height 700px)
- Oben durchgängig: `headlessSyncIndicator` als schmale Bar

Bei `max-width: 1024px`: einspaltig, Mobile-Preview-Mirror nach unten.

## Komponente 1: `connectedAssetDashboard` (Wrapper)

**Pfad:** `force-app/main/default/lwc/connectedAssetDashboard/`

### Funktion

- Liest `recordId` der aktuellen Asset-Page via `@api recordId`
- Ruft Apex `AssetTelemetryController.getDashboardData(assetId, range)` auf
- `range` ist im Default-State auf `'30d'`, kann per `usageTimelineChart`-Event auf `'7d'` oder `'90d'` gewechselt werden
- Erhält DTO: Asset-Metadaten, KPI-Snapshot, Timeline-Punkte, Lawn-Zonen, Maintenance-Forecast, Mobile-Mirror-Payload
- Rendert: `headlessSyncIndicator` + zweispaltiges Grid mit allen Subkomponenten
- Loading-State, Error-State analog Phase 2 + 3

## Komponente 2: `assetHealthHeader`

**Pfad:** `force-app/main/default/lwc/assetHealthHeader/`

### Funktion

- `@api kpis` – Array von 4 Objekten
- Rendert 4 KPI-Tiles:
  - **Tile 1 – Battery Health:** Donut-SVG (handgebaut, 80×80px), Wert, Label, Trend
  - **Tile 2 – Operating Hours:** großes Numeral, Label
  - **Tile 3 – Mowed Area:** großes Numeral, Label, Wochen-Durchschnitt
  - **Tile 4 – Firmware:** Version, Status-Pill

### Donut-Implementation (handgebaut)

SVG-Donut mit `<circle>`-Elementen, `stroke-dasharray` und `stroke-dashoffset` berechnet aus `donutPercent`, `transform="rotate(-90 40 40)"`.

## Komponente 3: `usageTimelineChart`

**Pfad:** `force-app/main/default/lwc/usageTimelineChart/`

### Funktion

- `@api dataPoints` – Array von `{ date, batteryHealth, mowedArea, errorCount }`
- `@api selectedMetric` – `'batteryHealth' | 'mowedArea' | 'errorCount'`
- `@api range` – `'7d' | '30d' | '90d'`
- Rendert:
  - **Header-Row:** Heading + Toggle-Buttons + Range-Pills
  - **Chart-Area:** SVG `viewBox="0 0 800 240"` mit `<polyline>` für die Line, `<polygon>` für Area-Fill, `<circle>` für Data-Points
  - **Hover-Tooltip:** SLDS-Style-Tooltip mit Datum + Wert
  - **Footer-Trend:** „Durchschnitt: {avg}", „Trend: {trendDirection}"

### Events

- `metricchange`, `rangechange`

## Komponente 4: `lawnHealthMap`

**Pfad:** `force-app/main/default/lwc/lawnHealthMap/`

### Funktion

- `@api zones` – Array von `{ id, x, y, width, height, healthScore, label }`
- `@api propertySizeSqm`
- Rendert:
  - **Header-Row:** Heading + Legend
  - **Map-Area:** SVG `viewBox="0 0 400 240"` mit:
    - Grundstücks-Outline (rect mit grünem Border, hell-grüner Fill)
    - Zonen pro `healthScore`:
      - `>= 80`: dunkles Grün (#3F9E54, opacity 0.7)
      - `60-79`: Amber (#F59E0B, opacity 0.6)
      - `< 60`: Critical Red (#D4351C, opacity 0.6)
    - Zone-Label als `<text>`
  - **Footer:** „Grundstück: {propertySizeSqm} m² · {zoneCount} Zonen"

**Wichtig – Geometrie-Bridge zum Mobile-Mockup:** dieselbe SVG-Zonen-Definition wird später im Mobile-Mockup für Slide 10 verwendet. Koordinaten in einem klar dokumentierten Format ablegen.

## Komponente 5: `predictiveMaintenanceCard`

**Pfad:** `force-app/main/default/lwc/predictiveMaintenanceCard/`

### Funktion

- `@api forecast` – Objekt: `{ headline, predictedDate, daysUntil, reasoning, confidence, suggestedAction }`
- Rendert kompakte Card:
  - **Header:** Einstein-Icon + Headline + „AI-generated"-Pill
  - **Hero-Stat:** großer Text „In {daysUntil} Tagen"
  - **Predicted-Date-Row:** Kalender-Icon + Datum
  - **Reasoning-Bullets:** 2-3 Bullets
  - **Suggested-Action-Box:** Cool-Grey-Background-Card mit Empfehlung + Primary-Button „Termin vorschlagen"
  - **Confidence-Bar unten**

### Events

- `scheduleappointment`

## Komponente 6: `headlessSyncIndicator`

**Pfad:** `force-app/main/default/lwc/headlessSyncIndicator/`

### Funktion

- `@api syncStatus` – Objekt: `{ lastMobileSync, lastPortalSync, isLive }`
- Schmale Statusleiste:
  - Linker Block: animierter grüner Pulsing-Dot + Text „Mobile App: synced {timeAgo}"
  - Mittlerer Block: zweiter Dot + Text „Kundenportal: synced live"
  - Rechter Block: Channel-Icons (utility:phone_portrait, utility:globe, utility:desktop)

## Komponente 7: `mobilePreviewMirror`

**Pfad:** `force-app/main/default/lwc/mobilePreviewMirror/`

### Funktion

Dies ist das visuell wichtigste Element der Phase.

- `@api mirrorData` – `{ batteryHealth, mowedToday, nextMow, contractName, contractExpiresInDays, lawnZones }`
- Rendert vertikalen iPhone-Frame:
  - **Phone-Frame-SVG:** ca. 320×640px, schwarzer abgerundeter Rahmen, weißer Screen, Notch oben
  - **Status-Bar:** simulierte Time + Battery-Icon
  - **App-Inhalt:**
    - **App-Header:** „VerdantBot" Logo-Text + Robot-Icon
    - **Battery-Donut (groß):** identische SVG-Donut-Implementation wie `assetHealthHeader`
    - **Quick-Stats:** „Heute: {mowedToday} m²" + „Nächster Mähplan: {nextMow}"
    - **Lawn-Map (klein):** **dieselbe SVG-Zonen-Definition wie `lawnHealthMap`** (160×100px, ohne Header)
    - **Service-Reminder-Card:** Velocity Blue Background, „Dein VerdantCare {contractName} läuft in {contractExpiresInDays} Tagen ab"
    - **Chat-Bubble unten rechts:** kleiner Velocity-Blue-Kreis mit utility:chat-Icon, Notification-Badge

### Geometrie-Konsistenz

Die `lawn-zones`-Definition wird im Wrapper aus demselben Apex-DTO an `lawnHealthMap` UND `mobilePreviewMirror` weitergegeben.

## Apex Controller: `AssetTelemetryController`

**Pfad:** `force-app/main/default/classes/AssetTelemetryController.cls`

### Methoden

```apex
@AuraEnabled(cacheable=true)
public static DashboardDataDTO getDashboardData(Id assetId, String range) {
    // 1. Lade Asset mit VBOT_*-Feldern und Product2
    // 2. Lade VBOT_Asset_Telemetry__c-Records, sortiert nach Timestamp DESC
    //    range '7d' = 7 Records, '30d' = 30 Records, '90d' synthetisch aus 30 hochgerechnet
    // 3. Baue KPI-Snapshot aus jüngstem Record + Aggregaten
    // 4. Baue Timeline-Points (für SVG-Polyline)
    // 5. Baue Lawn-Zones STATISCH (4-5 Zonen mit Healthscore-Werten)
    // 6. Baue Maintenance-Forecast aus Battery-Health-Trend (linear regression)
    // 7. Baue Mobile-Mirror-Payload aus jüngstem KPI + ServiceContract-Lookup
}
```

### DTOs

`DashboardDataDTO`, `AssetMetaDTO`, `SyncStatusDTO`, `KpiTileDTO`, `TimelinePointDTO`, `LawnZoneDTO`, `MaintenanceForecastDTO`, `MobileMirrorDTO` – siehe Phase-4-Spec für Felddetails.

### Lawn-Zones-Definition (statisch im Controller)

```apex
private static List<LawnZoneDTO> buildLawnZones(Id assetId) {
    // 4 Zonen mit deterministischen Werten:
    // A (vorne links):    x=20,  y=20,  w=140, h=80,  health=85 (optimal)
    // B (vorne rechts):   x=180, y=20,  w=200, h=80,  health=72 (belastet)
    // C (hinten links):   x=20,  y=120, w=170, h=100, health=58 (beschädigt)
    // D (hinten rechts):  x=210, y=120, w=170, h=100, health=80 (optimal)
}
```

Diese Koordinaten sind **bewusst gewählt**, damit sie im Mobile-Mockup und in der Org-LWC identisch erscheinen.

### Test Class

`AssetTelemetryControllerTest.cls`: ≥75 % Coverage. Tests für Happy Path, Range-Variation, Edge Cases (kein Telemetry, assetId null).

## FlexiPage-Update

Ersetze den Placeholder mit `variant="connected-asset"` durch:

```xml
<componentInstance>
    <componentName>c:connectedAssetDashboard</componentName>
    <identifier>connectedAssetDashboardInstance</identifier>
</componentInstance>
```

## Permission Set Update

Erweitere `VBOT_Demo_Access`:
- Apex-Klasse-Zugriff: `AssetTelemetryController`
- Object-Permissions: `VBOT_Asset_Telemetry__c` read
- Field-Level-Security: alle `VBOT_*`-Felder

## Deployment

```bash
sf project deploy validate --source-dir force-app --target-org <alias>
sf project deploy start --source-dir force-app --target-org <alias>
sf apex run test --class-names AssetTelemetryControllerTest --target-org <alias> --result-format human
```

## Acceptance Criteria – Phase 4 ist fertig, wenn …

1. Deploy idempotent, Tests grün (≥75 % Coverage).
2. Demo-Asset-Page zeigt `connectedAssetDashboard` mit allen 6 Subkomponenten.
3. Range-Pill-Klick löst Apex-Re-Call aus, Chart aktualisiert sich.
4. „Termin vorschlagen" zeigt Success-Toast.
5. Hover über Chart-Point zeigt Tooltip.
6. **Visuelle Konsistenz mit Phase 2 + 3.**
7. **Geometrie-Bridge:** Lawn-Zonen in `lawnHealthMap` und `mobilePreviewMirror` haben identische Koordinaten.
8. Responsive (KPI-Tiles 2×2 bei < 1024px, Mobile-Mirror unter Chart bei < 768px).
9. Git: committet als `Phase 4: connectedAssetDashboard + 6 subcomponents + Apex controller`.

## Output am Ende

1. Deploy-Log
2. Test-Ergebnis
3. Liste aller neuen Dateien
4. Pro Acceptance-Criterion: ✅/⚠️/❌
5. Hinweis: drei Screenshots (Initial-State, Range-Switch, Lawn-Map + Mobile-Mirror Side-by-Side)
6. Hard-Reload-Reminder
7. **Dump der Lawn-Zones-Konstanten** aus dem Apex-Controller – für Mobile-Mockup Slide 10.
