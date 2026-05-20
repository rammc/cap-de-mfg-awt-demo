# VerdantBot — Manufacturing Cloud Demo

> Field-Service-Erlebnis um einen fiktiven Rasenmähroboter, gebaut für die
> Agentforce World Tour Frankfurt 2026 Session *„How to fail Industry Cloud
> fast. Let's not."*

Drei UI-Erweiterungen über dem Manufacturing-Cloud-Standardprozess, ein
Agentforce-Nudge-Bubble als Klammer, ein versteckter Easter Egg für aufmerksame
Demo-Zuschauer — und ein Repo, das die meisten Komponenten so generisch hält,
dass sie in jeder anderen Demo wiederverwendet werden können.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                                                                         │
│   ┌─ WorkOrder ──────────────────┐    ┌─ Asset ──────────────────────┐  │
│   │                              │    │                              │  │
│   │  Service & Warranty Advisor  │    │  Connected Asset Dashboard   │  │
│   │  ┌────┐ ┌────┐ ┌────┐ ┌────┐ │    │  ┌──┐ ┌──┐ ┌──┐ ┌──┐         │  │
│   │  │ ✓  │ │ !  │ │ ✗  │ │ ⏰ │ │    │  │92│ │47│ │17│ │34│         │  │
│   │  └────┘ └────┘ └────┘ └────┘ │    │  └──┘ └──┘ └──┘ └──┘         │  │
│   │  [Basic]  [Plus]  [Premium]  │    │  ╭───── Telemetry ─────╮     │  │
│   │                              │    │  │      ╱╲      ╱╲     │     │  │
│   │  Product Upgrade Studio      │    │  │   ╱╲╱  ╲╱╲╱╲╱  ╲    │     │  │
│   │  [Battery] [C500★] [X800]    │    │  ╰─────────────────────╯     │  │
│   │                              │    │  Lawn-Map + Predictive +     │  │
│   │  AI Reasoning ▼              │    │  iPhone-Mirror               │  │
│   └──────────────────────────────┘    └──────────────────────────────┘  │
│                                                                         │
│                                       ┌─🟦─┐ ← Agentforce nudge         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Story

Ein Field-Service-Spezialist besucht **Familie Schmidt** in Berlin, deren
**VerdantBot C300** (Rasenmähroboter) seit ein paar Wochen Aussetzer hat.
Die WorkOrder ist offen, Akku-Health ist auf 78 %, das Grundstück ist auf
1.200 m² gewachsen — der aktuelle Vertrag deckt nur Software ab.

Die Demo zeigt drei Use Cases auf zwei Salesforce-Standard-Records:

1. **Service & Warranty (WorkOrder)** — Coverage-Gaps sichtbar machen,
   einen besseren Servicevertrag wählen, Tablet-Signatur direkt vor Ort.
2. **Upgrades (WorkOrder)** — drei Empfehlungen (Akku, größeres Modell, Pro)
   mit Fit-Score, Side-by-Side-Spec-Vergleich, Quote-an-Kunden-senden.
3. **Connected Asset (Asset)** — Telemetrie aus der Mobile App: 4 KPI,
   30-Tage-Verlauf, Lawn-Map, Predictive Maintenance — plus ein gespiegelter
   iPhone-Frame, der zeigt, was die Endkundin gleichzeitig sieht.

Cross-cutting: **Agentforce-Nudge-Bubble** mit kontextspezifischen
Vorschlägen, die per Lightning-Message-Service die jeweilige Ziel-Komponente
hervorhebt.

---

## Live-Org & Repo

| Was | Wo |
|---|---|
| Org | `https://cap-de-mfg-awt-demo-dev-ed.develop.my.salesforce.com` (Manufacturing Cloud Developer Edition, DEU90) |
| User | `christopher.ramm@cap-de-mfg-awt-demo.com` |
| Repo | <https://github.com/rammc/cap-de-mfg-awt-demo> |
| Demo-WO | `/lightning/r/WorkOrder/0WOWz000004EjDFOA0/view` |
| Demo-Asset | `/lightning/r/Asset/02iWz0000070dQLIAY/view` |

---

## Setup in 5 Befehlen

```bash
sf org login web --alias vbot
sf project deploy start --source-dir force-app --target-org vbot --test-level NoTestRun
sf org assign permset --name VBOT_Demo_Access --target-org vbot
sf apex run --file scripts/apex/seed-vbot-demo.apex --target-org vbot
sf org open --target-org vbot --path /lightning/r/WorkOrder/0WOWz000004EjDFOA0/view
```

Lightning Record Pages müssen einmal manuell als „Org Default" aktiviert
werden — Setup → Object Manager → **Work Order** / **Asset** → Lightning
Record Pages → `VBOT … Record Page` → **Activation** → Desktop + Phone.

---

## Architektur in einem Bild

```
                           ┌─────────────────────────────────────┐
   FlexiPage (WorkOrder)   │  warrantyAdvisorPanel               │
   ────────────────────    │  ├─ coverageGapVisualizer           │
                           │  ├─ contractOptionCard × 3          │
                           │  ├─ contractComparisonDrawer        │
                           │  ├─ eSignaturePreview               │
                           │  └─ contractConfirmationToast       │
                           ├─────────────────────────────────────┤
                           │  productUpgradeStudio               │
                           │  ├─ assetContextBanner              │
                           │  ├─ upgradeRecommendationGrid       │
                           │  │   └─ productUpgradeCard × 3      │
                           │  ├─ specDiffComparator              │
                           │  ├─ reasoningExplainer              │
                           │  └─ quoteCartFlyout                 │
                           ├─────────────────────────────────────┤
                           │  agentNudgeBubble  (LMS publisher)  │
                           └─────────────────────────────────────┘

                           ┌─────────────────────────────────────┐
   FlexiPage (Asset)       │  connectedAssetDashboard            │
   ────────────────────    │  ├─ headlessSyncIndicator           │
                           │  ├─ assetHealthHeader (4 KPI)       │
                           │  ├─ usageTimelineChart (SVG)        │
                           │  ├─ lawnHealthMap (SVG)             │
                           │  ├─ predictiveMaintenanceCard       │
                           │  └─ mobilePreviewMirror             │
                           ├─────────────────────────────────────┤
                           │  agentNudgeBubble                   │
                           └─────────────────────────────────────┘

                           ┌─────────────────────────────────────┐
   Cross-cutting           │  verdantBotEasterEgg (singleton)    │
                           │  vbotTabPlaceholder (legacy)        │
                           │  loadingSkeleton                    │
                           │  emptyState · errorState            │
                           │  demoResetAction (Quick Action)     │
                           └─────────────────────────────────────┘
```

---

## Komponenten-Katalog

Pro Komponente: **Zweck**, **API**, **Re-Use-Charakter**. „Re-Use" gliedert
sich in drei Stufen:

- 🟢 **Generisch** — domain-frei, direkt übernehmbar
- 🟡 **Mit kleinen Anpassungen** — Brand-Tokens und Labels tauschen
- 🔴 **Story-spezifisch** — eng an VerdantBot / Manufacturing-Demo gekoppelt

### Wrapper-LWCs (exposed auf FlexiPage)

#### `warrantyAdvisorPanel` 🔴

Service- & Warranty-Advisor für eine WorkOrder. `@api recordId`,
`@wire WarrantyAdvisorController.getAdvisorData`. Orchestriert 5
Sub-LWCs (Coverage, Cards, Drawer, Signature, Toast).

**Re-Use:** Story-spezifisch (Field-Service-Servicevertrag). Aber das
Orchestrierungs-Muster (`@wire` → Loading/Error/Data → Sub-LWCs → Modal/Drawer
Triggers) lässt sich 1:1 für ähnliche „Read-Apex → Side-Panel UX"-Workflows
übernehmen.

#### `productUpgradeStudio` 🔴

Up- / Cross-Sell-Studio auf der WorkOrder. Banner + 3 Cards + Reasoning.
Dispatcht `ShowToastEvent` beim „An Kunde senden" aus dem Cart.

**Re-Use:** Story-spezifisch. Wiederverwendbar als Pattern für jede
„Asset-Context → 3 Empfehlungen → Quote-Flyout"-UX.

#### `connectedAssetDashboard` 🔴

Telemetrie-Dashboard auf dem Asset. Layout 60/40 Desktop, einspaltig
< 1024 px. Polled keine Daten (alle Werte aus `@wire`-Cache).

**Re-Use:** Story-spezifisch. Das Grid-Layout-Pattern (Header → Chart →
Side-by-Side → Mobile-Mirror) ist generisch genug für jedes Connected-Product-
oder IoT-Dashboard.

### Sub-LWCs — Service & Warranty

#### `coverageGapVisualizer` 🟡

4-Tile-Status-Strip. `@api coverages = [{ key, label, status, expiresInDays }]`
mit Status `covered | partial | uncovered | expiring`. Animation: rote Tiles
pulsieren.

**Re-Use:** Mit Brand-Token + neuen Labels für **jedes** „4 KPIs mit
Ampel-Status"-Pattern. Beispiele: SLA-Coverage, Compliance-Checks,
Garantie-Status.

#### `contractOptionCard` 🟡

Card mit Tier-Badge, RECOMMENDED-Banner, Monatlich/Jährlich-Preis,
Coverage-Liste, zwei Buttons. Dispatcht `comparecontracts` und
`selectcontract` (bubbles, composed).

**Re-Use:** **Sehr** wiederverwendbar — jede Pricing-Card-UX. Tier-Farben
und CTA-Labels via Props.

#### `contractComparisonDrawer` 🟢

Slide-in-Drawer von rechts (CSS-Transition, kein `lightning-modal`).
ESC + Scrim-Click schließen. Side-by-Side-Tabelle mit Recommendation-Spalte-
Highlight.

**Re-Use:** Reines Layout-Pattern, völlig domain-frei. Tausche `features` +
`tabs` und du hast einen generischen Drawer für beliebige Vergleichs-Tabellen.

#### `eSignaturePreview` 🟢

Canvas-basiertes Signatur-Modal mit PointerEvents (funktioniert mit Maus,
Tablet-Stylus und Touch). „Bestätigen" ist disabled bis Strokes vorhanden.

**Re-Use:** **Sehr** wiederverwendbar — jede Demo, die eine Vor-Ort-Signatur
zeigen will. Kein Apex-Abhängigkeit, dispatched nur Events.

#### `contractConfirmationToast` 🟢

Vollflächiges Overlay mit animiertem SVG-Checkmark
(`stroke-dasharray`-Animation), Auto-Dismiss nach 4 s.

**Re-Use:** Generisch für jeden Success-Confirm-Flow. `contractName` →
generischer `title`-String, dann ist es ein Drop-in-Komponent.

### Sub-LWCs — Upgrades

#### `assetContextBanner` 🟡

3-Spalten-Hero: Bild + Asset-Meta + Context-Pills. Responsive (1-Spalter
< 768 px). Double-Click auf das Bild triggert das Easter Egg (siehe unten).

**Re-Use:** Generischer Hero-Banner für jede Asset-/Produkt-/Kundenkarte.

#### `productUpgradeCard` 🟡

Produkt-Card mit Tier-Badge, Fit-Score-Badge, Hero-Image (PNG/SVG-fähig),
Preis, Specs-Liste mit Diff-Icons, Value-Props in Italic, zwei CTAs.

**Re-Use:** Mit anderen Props sofort als generische
Produkt-Recommendation-Card nutzbar.

#### `upgradeRecommendationGrid` 🟢

Responsive 3-2-1-Grid-Wrapper. Bubbled `comparespecs` und `addtoquote` Events
nach oben.

**Re-Use:** Trivial generisch — jeder „Liste von Karten" Use Case.

#### `specDiffComparator` 🟢

Side-by-Side-Spec-Drawer mit Diff-Pfeilen (↑ grün, ↓ rot, sonst grau) und
optional Hero-Image-Row oben. ESC + Scrim-Click + „Schließen" + „Zu Quote
hinzufügen" als Footer.

**Re-Use:** Jeder Side-by-Side-Vergleich (Versions-Diff, Spec-Vergleich,
Variant-Comparison). Die Diff-Heuristik (`up`/`same`/`down`) ist erweiterbar.

#### `reasoningExplainer` 🟢

AI-Reasoning-Card mit Einstein-Icon, Bullets, „AI-generated"-Pill,
Confidence-Bar.

**Re-Use:** Universelles Pattern für „Erkläre meine Empfehlung". Brauchbar
auf jeder Prediction- / Recommendation-Surface.

#### `quoteCartFlyout` 🟢

Schmaler (380 px) Right-Slide-Cart. Items-Liste mit Remove-Icons, leerer
Zustand, Summary-Box, „Speichern" + „An Kunde senden" CTAs. Dispatcht
`removeitem` und `sendquote`.

**Re-Use:** Jedes Cart / Quote / Selected-Items Pattern.

### Sub-LWCs — Connected Asset

#### `headlessSyncIndicator` 🟢

Schmale Status-Bar mit zwei pulsierenden Dots und Channel-Icons.
Demo-Botschaft: „dieselben Daten in Mobile App + Portal + Konsole".

**Re-Use:** Jedes Multi-Channel / Multi-System Status-Display.

#### `assetHealthHeader` 🟡

4 KPI-Tiles, davon eines mit selbst gerendertem SVG-Donut. Brand-Color für
gefüllten Anteil, Cool-Grey für Rest.

**Re-Use:** Donut-Implementation ist generisch (zwei `<circle>` mit
`stroke-dasharray` + `stroke-dashoffset`). Tile-Inhalte via Props swappable.

#### `usageTimelineChart` 🟢

**Komplett handgebauter SVG-Linechart** ohne Chart-Library. Metric-Toggle,
Range-Toggle (7T/30T/90T), Hover-Tooltip, Polygon-Area-Fill unter der Line,
automatische Y-Achsen-Skalierung.

**Re-Use:** **Massiv** wiederverwendbar — jede Timeseries-Visualisierung in
LWC. Self-contained, kein Static Resource, kein NPM-Package. Beispiel-Use-
Cases: Sales-Pipeline-Velocity, Service-Backlog-Trend, App-Usage-Verlauf.

#### `lawnHealthMap` 🔴

SVG-Geo-Map mit eingefärbten Rechteck-Zonen (Health-Score → grün/amber/rot).
Pattern-Background-Grid.

**Re-Use:** Eng an die VerdantBot-Story (Rasen-Zonen). Aber als Pattern für
jede „Property als Zonen-Layout" Use Case (z. B. Lagerhalle, Plantage,
Hangar) übernehmbar — Zonen-Definitionen kommen aus Apex.

#### `predictiveMaintenanceCard` 🟢

AI-Forecast-Card mit Hero-Stat („in *n* Tagen"), Datum, Reasoning-Bullets,
Suggested-Action-Box mit Primary-CTA, Confidence-Bar.

**Re-Use:** Universelle „Predicted Event"-Karte. Brauchbar für jede
Predictive-Use-Case in Service, Sales, Health, Risk.

#### `mobilePreviewMirror` 🟡

CSS-iPhone-Frame (kein PNG/SVG) mit Notch, Statusbar und vollem
App-Mockup-Inhalt: Battery-Donut, Quick-Stats, mini Lawn-Map (selbe Zonen
wie die große), Reminder-Banner, Chat-Bubble mit Notification-Badge.

**Re-Use:** Jede Demo, die einen Endkunden-Mobile-View braucht. Frame ist
generisch, der Inhalt wird über Props gefüttert.

### Cross-cutting LWCs

#### `agentNudgeBubble` 🟢

Floating Chat-Bubble (`position: fixed; bottom: 24px; right: 24px`).
**Closed**: pulsierender Button mit Notification-Badge. **Open**:
380 × 480 Chat-Panel mit kontextspezifischen Prompts, Typing-Indicator,
simulierte Agent-Antworten. Publisht **Lightning Message Service**
(`VBOT_HighlightChannel`) — Schwester-Komponenten subscriben.

**Re-Use:** Generisches Agentforce-Marketing-Pattern. Tausche `PROMPTS`-Konstante
und Antworten, und es ist ein Drop-in für jede Custom-Demo.

#### `vbotTabPlaceholder` 🟢

Wireframe-Placeholder mit 4 Varianten (`service-warranty`, `upgrades`,
`connected-asset`, `generic`). Shimmer-Animation. Wird in dieser Demo nicht
mehr aktiv genutzt — bleibt im Repo als Pattern.

**Re-Use:** Tooling-Wert während des Demo-Aufbaus: „die Page steht schon,
die LWCs kommen". Jede Phase-by-Phase Demo profitiert.

#### `loadingSkeleton`, `emptyState`, `errorState` 🟢

Drei kleine, hochgradig wiederverwendbare State-Karten.
`<c-loading-skeleton variant="kpi-row">`, `<c-empty-state>`, `<c-error-state>`.

**Re-Use:** Trivial generisch. Pflicht-Bausteine für jede Apex-Wrapper-LWC.

#### `demoResetAction` 🟢

Quick-Action-LWC. Confirmation-Dialog → Apex-Aufruf → Toast →
`CloseActionScreenEvent`. Funktioniert auf jeder Record-Page mit
`lightning__RecordAction` Target.

**Re-Use:** Universelles Pattern für jeden „Reset / Action mit Bestätigung"
Quick-Action-Flow.

#### `verdantBotEasterEgg` 🟡

Floating Singleton mit 4-Phasen-Animation (entrance → mid-spin → exit →
cleanup), eingebettet in alle drei Wrapper. Lauscht auf
`window.verdantbotdriveby` Custom-Events, prüft Cooldown, respektiert
`prefers-reduced-motion`.

**Re-Use:** Animation-Pattern (CSS keyframes + JS-Phase-Timer +
window-Event-Listener) ist generisch — VerdantBot-spezifisch nur die SVG
und der Toast-Text. Für andere Demos: Roboter-SVG tauschen, Toast-Text
ändern, fertig.

### Apex-Controller

Vier Controller, alle `with sharing`, alle `@AuraEnabled(cacheable=true)`
außer `DemoResetController`.

#### `WarrantyAdvisorController` 🟡

DTO-Aggregator: lädt WorkOrder → Account → Service-Contracts (active +
templates) → baut `AdvisorDataDTO` mit Coverage-Status, Aktivem Vertrag und
3 Tier-Optionen. Coverage-Heuristik (covered/partial/uncovered/expiring) im
Controller.

**Re-Use:** Pattern für „Read-Apex-DTO mit konstruierten Status-Feldern"
generell anwendbar.

#### `ProductUpgradeController` 🔴

Liest WorkOrder + Asset, sucht 3 Upgrade-Kandidaten aus statischen Codes
(VBOT_BAT_PLUS, VBOT_C500, VBOT_X800). Reasoning-Bullets aus Asset-Kontext
(Property-Wachstum, Akku-Wear, Asset-Alter).

**Re-Use:** Story-spezifisch durch die hartcodierten Codes. Das Reasoning-
Pattern (DTO-Bullets, Confidence-Score) ist generisch.

#### `AssetTelemetryController` 🟡

Aggregiert `VBOT_Asset_Telemetry__c`-Records zu KPIs + Timeline + Forecast +
Mobile-Mirror-Payload. **Linear Regression** auf Battery-Health-Verlauf für
Predictive Maintenance (n-Punkte → slope/intercept → days-until-target).
Lawn-Zones sind statisch im Controller (4 Rechteck-Zonen mit fixen
Koordinaten — bewusst geteilt zwischen `lawnHealthMap` und
`mobilePreviewMirror`).

**Re-Use:** Linear-Regression-Trick und Timeline-Aggregation sind generisch
und gut für jede Custom-Object-Timeseries-Aggregation.

#### `DemoResetController` 🟢

Idempotenter State-Reset für die Demo. Pattern: Try / Catch / Savepoint /
Rollback. Aufgerufen aus `demoResetAction`-LWC.

**Re-Use:** Bauplan für jede Demo-Reset-Funktion.

### Static Resources

- `cgTokens` — zentrale Brand-Token CSS-Variablen (Vibrant Blue, Velocity
  Blue, Deep Purple, Charcoal, Greys, Shadows, Radii, Spacings)
- `vbot_e150`, `vbot_c300`, `vbot_c500`, `vbot_x800`, `vbot_bat_plus` —
  AI-Renderings (Gemini Nano Banana 2, 1024×1024 PNG)
- `vbot_lawn_ai` — handgezeichnete SVG

### Message Channel

#### `VBOT_HighlightChannel` 🟢

Lightning Message Service Channel mit zwei Feldern (`target`, `context`).
Wrapper-LWCs subscriben und pulsieren ihre Ziel-Sub-LWC für 1,5 s, wenn der
Agent-Nudge auf einen Prompt klickt.

**Re-Use:** **Sehr** wiederverwendbar als Pattern für jede „Cross-LWC-
Highlight" oder „guided tour" Coordination zwischen Schwester-Komponenten
auf einer FlexiPage.

### Quick Action

#### `VBOT_Reset_Demo` (auf WorkOrder)

`LightningWebComponent` Quick Action vom Typ `ScreenAction` → öffnet
`demoResetAction`. Muss manuell auf das Work-Order Layout gelegt werden
(Object Manager → Page Layouts → Mobile & Lightning Actions).

---

## Datenmodell

Greenfield-Custom-Fields, alle mit `VBOT_`-Prefix, kein Namespace.

| Object | Custom Fields |
|---|---|
| `Asset` | `VBOT_Property_Size_Sqm__c`, `VBOT_Battery_Health_Pct__c`, `VBOT_Firmware_Version__c`, `VBOT_Last_Sync__c`, `VBOT_Mobile_App_Enabled__c` |
| `WorkOrder` | `VBOT_Demo_Scenario__c`, `VBOT_Recommended_Action__c` |
| `ServiceContract` | `VBOT_Tier__c`, `VBOT_Monthly_Price__c`, `VBOT_Yearly_Price__c`, `VBOT_Covers_Hardware/Software/Battery/Sensors__c`, `VBOT_Is_Template__c` |
| `Product2` | `VBOT_Max_Area_Sqm__c`, `VBOT_Battery_Capacity_Wh__c`, `VBOT_Has_GPS__c`, `VBOT_Has_Lawn_AI__c`, `VBOT_Hero_Image_Url__c`, `VBOT_Tier_Label__c` |
| `VBOT_Asset_Telemetry__c` (Custom Object) | 9 Felder (Master-Detail zu Asset, Timestamp, Battery, Mowed-Area, Operating-Hours, Error-Count, Firmware, Lawn-Health-Score, External-Id) |

Permission Set `VBOT_Demo_Access` bündelt alle Object- und Field-Permissions
plus `classAccesses` für die 4 Apex-Controller.

---

## Demo-Run

Schritt-für-Schritt: **[`docs/DEMO_CHECKLIST.md`](docs/DEMO_CHECKLIST.md)**.
Backup für Org-Ausfälle: **[`docs/backup-screenshots.md`](docs/backup-screenshots.md)**.

**Quick Reset** während der Vorbereitung:

- Quick-Action **VBOT Demo Reset** auf der Demo-WorkOrder *(idempotent —
  setzt WO-Status, Recommended-Action, letzte 7 Telemetry-Rows und Basic-
  Vertragslaufzeit zurück)*, **oder**
- Volle Re-Seed:
  ```bash
  sf apex run --file scripts/apex/reset-vbot-demo.apex --target-org vbot
  sf apex run --file scripts/apex/seed-vbot-demo.apex --target-org vbot
  ```

---

## Product Imagery

Produktbilder liegen als Static Resources unter
`force-app/main/default/staticresources/`:

- `vbot_e150`, `vbot_c300`, `vbot_c500`, `vbot_x800`, `vbot_bat_plus` (PNG,
  AI-generiert via Gemini Nano Banana 2, 1024×1024)
- `vbot_lawn_ai` (SVG, handgezeichnet)

Die `VBOT_Hero_Image_Url__c`-Felder werden vom Seed-Skript auf
`/resource/<name>` gesetzt — idempotent, bei wiederholtem Lauf
`[SKIP-EXISTS]`.

---

## Easter Egg

Doppelklick auf eines der drei versteckten Trigger-Elemente:

- Produktbild im **Asset-Context-Banner** (Upgrades-Tab)
- **Battery-Donut** in den KPI-Tiles (Asset-Page)
- **iPhone-Frame** im Mobile-Mirror (Asset-Page)

…lässt einen kleinen SVG-VerdantBot diagonal über den Bildschirm fahren,
hinterlässt eine kurz aufleuchtende grüne Mähbahn, dreht sich in der Mitte
und fährt rechts oben aus dem Viewport. Cooldown 8 Sekunden, drei verschiedene
Toast-Stufen, `prefers-reduced-motion`-aware. Klick auf den Roboter während
der Drehung schaltet einen geheimen Gruß frei.

Implementation: `verdantBotEasterEgg` Singleton-LWC, eingebettet am Ende
jedes Wrapper-Templates.

---

## Bekannte Limitierungen

- **FlexiPage-Tabsets** ließen sich in dieser Developer Edition nicht via
  Metadata API deployen (Salesforce rejected `flexipage:tabset` und alle
  `flexipage:record*` Detail-Komponenten). Die Demo nutzt darum 1-Column
  Record Pages mit gestapelten Komponenten.
- **ListView-Filter** nehmen in dieser Edition nur Custom-Fields oder die
  speziellen Tokens `ACCOUNT.NAME` / `ASSET.NAME` — die drei betroffenen
  ListViews nutzen darum Custom-Field-Filter.
- **Backup-Screenshots** liegen nicht im Repo (Binärdaten würden den Diff
  aufblähen) — sondern werden manuell auf dem Demo-Laptop vorbereitet.
- **Quick-Action-Sichtbarkeit** auf der Work Order Layout muss manuell im
  Object Manager hinzugefügt werden.
- **Lokale `:host { --cg-* }`-Definitionen** wurden bewusst beibehalten,
  auch nachdem `cgTokens` als Static Resource zur zentralen Quelle wurde —
  schützt gegen Race-Conditions beim ersten Page-Load.

Vollständige Stolperfallen-Liste in [`CLAUDE.md`](CLAUDE.md).

---

## Tech-Stack

| Layer | Was |
|---|---|
| Datenmodell | 5 Custom Fields × 4 Standard-Objekte + 1 Custom Object + Permission Set |
| Apex | 4 Controller (`WarrantyAdvisor`, `ProductUpgrade`, `AssetTelemetry`, `DemoReset`) + Test-Klassen, Coverage 91–99 % |
| LWC | 26 Bundles (4 Wrapper, 17 Sub, 5 Cross-cutting) |
| Cross-cutting | 1 Lightning Message Channel, 1 Static Resource (CSS-Tokens), 6 Product-Image Static Resources |
| Tooling | SFDX, sf CLI v2, Husky + Prettier + ESLint + Jest (Phase-1-Template-Stand) |

---

## Phase-Historie

Vier vollwertige Implementation-Phasen + Polish-Phasen, jede als atomarer
Commit im Repo nachvollziehbar:

| Phase | Inhalt | Commit-Range |
|---|---|---|
| 1 | Datenmodell, Demo-Daten, Permission Set, Placeholder-Pages | initial → `eaa1c15` |
| 1.5 | Polished Wireframe-Placeholder, 5/5 ListViews | `d2be89d` |
| 2 | Service & Warranty (Wrapper + 5 Subs + `WarrantyAdvisorController`) | `cab61f8` |
| 3 | Upgrades (Wrapper + 6 Subs + `ProductUpgradeController`) | `5ec6223` |
| 4 | Connected Asset Dashboard (Wrapper + 6 Subs + `AssetTelemetryController`) | `a98f284` |
| 5 | Agent Nudge Bubble + LMS + Demo Reset + DEMO_CHECKLIST | `43aa746` |
| Easter Egg | VerdantBot Drive-By | `ef869cd` |
| Imagery Polish | AI-Renderings als Static Resources, LWC-Anpassungen | `b84bcc0` |

---

## Reuse-Reminder

Wenn du Komponenten in eine andere Demo / einen anderen Mandanten ziehst:

1. **Brand-Tokens** zentral in `cgTokens.css` ändern, **oder** lokal pro
   Bundle in den `:host`-Blöcken — beide Stellen funktionieren parallel.
2. **Apex-Controller** sind `with sharing` und lesen ausschließlich
   Standard-Objekte + Custom-Fields. Bei Übernahme: VBOT-Felder durch eigene
   Felder ersetzen.
3. **LMS-Channel** muss separat deployed werden (`messageChannels/`-Ordner).
4. **Lightning Message Service** funktioniert ausschließlich
   FlexiPage-intern — über Apps hinweg nicht ohne weiteres.
5. **Permission Set** komplett übernehmen oder die `classAccesses` und
   `fieldPermissions` selektiv in einen bestehenden PermSet überführen.

---

## Credits

Built by **Christopher Ramm** (GitHub [@rammc](https://github.com/rammc)),
Capgemini, für die Agentforce World Tour Frankfurt 2026.

LWC-Architektur, Apex-Layer und Polish in Co-Authorship mit
**Claude Opus 4.7 (1M context)** via Claude Code.

Brand-Visualisierungen: **Gemini Nano Banana 2**.

---

## License

Demo-Code unter MIT-Lizenz. Brand-Assets (Capgemini-Tokens, Logos) sowie die
AI-Renderings unterliegen den jeweiligen Nutzungsbedingungen.
