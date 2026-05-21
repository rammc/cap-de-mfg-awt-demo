# Phase 5 Implementation Prompt: Cross-Cutting Polish

## Rolle & Ziel

Du bist Salesforce LWC Engineer und führst den finalen Polish-Pass über die VerdantBot-Demo durch. Drei Streams: (A) `agentNudgeBubble` als cross-cutting Agentforce-Visualisierung, (B) Konsistenz-Pass über alle bestehenden LWCs (Phase 2 + 3 + 4), (C) Demo-Härtung mit Edge-Cases und Reset-Mechanik.

**Keine neuen Use Cases, keine neuen Controller-Endpoints.** Das Ziel ist „aus einem Guss" – die Demo soll wirken, als wäre sie als Einheit konzipiert worden, nicht in drei separaten Phasen.

## Globale Regeln

- **Branding:** Capgemini-Tokens wie zuvor. Stream B führt ein zentrales `cgTokens`-Static-Resource ein, das alle bestehenden LWCs nutzen sollen.
- **Konsistenz schlägt Innovation:** wenn ein Style-Wert in Phase 2/3/4 etabliert ist, übernehmen, nicht neu erfinden.
- **A11y und Mobile-Responsive:** wie zuvor.

---

## Stream A – `agentNudgeBubble` (Agentforce-Visualisierung)

### Ziel

Eine kleine, persistente Chat-Bubble unten rechts auf allen drei Tabs (WO Service & Warranty, WO Upgrades, Asset Connected Asset). Im Closed-State zeigt sie nur ein Agentforce-Icon. Im Open-State öffnet sie ein Mini-Chat-Window mit 2–3 vordefinierten Prompts pro Kontext. Beim Klick auf einen Prompt zeigt sie eine simulierte Agent-Antwort und triggert ein visuelles Highlight in der jeweiligen LWC.

### Komponente: `agentNudgeBubble`

**Pfad:** `force-app/main/default/lwc/agentNudgeBubble/`

#### Funktion

- `@api context` – `'warranty' | 'upgrades' | 'telemetry' | 'auto'`, Default `'auto'`
- `@api recordId` – aktuelle Record-Id
- Zwei States:
  - **Closed:** runder Floating-Button (56×56px) unten rechts, fixed position, Velocity-Blue, weißes Agentforce-Icon, pulsierende Animation
  - **Open:** Chat-Panel (380×480px) öffnet sich animiert von unten rechts (Slide + Fade, 250ms)
- **Closed-Notification-Badge:** roter Kreis mit „1" rechts oben

#### Chat-Panel-Inhalt (Open-State)

- **Header:** „VerdantBot Service Agent" + Status-Pill „Online" + Close-Button
- **Begrüßungs-Message-Bubble:** „Hi Christopher, ich habe ein paar Vorschläge für diesen Kontext."
- **Prompt-Suggestion-Chips (3 Stück, vertikal):**
  - Kontext `warranty`: „Zeige mir Coverage-Lücken", „Welcher Vertragstier passt?", „Wann läuft die Garantie ab?"
  - Kontext `upgrades`: „Empfehle Upgrades", „Was würde der Kunde kaufen?", „Vergleiche Akku vs. Modell"
  - Kontext `telemetry`: „Wann ist nächste Wartung?", „Warum sinkt die Akku-Leistung?", „Firmware-Update?"
- **Bei Klick auf einen Chip:** User-Message → Typing-Indicator → Agent-Antwort → `highlightcomponent`-Event
- **Footer:** Input-Feld „Frage stellen…" (dekorativ, disabled), „Powered by Agentforce"

#### Auto-Context-Detection

Wenn `context='auto'`: Default basierend auf Record-Type (WorkOrder → `warranty`, Asset → `telemetry`).

#### Vordefinierte Agent-Antworten (im JS hartcodiert)

```javascript
const AGENT_RESPONSES = {
    warranty: {
        'coverage_gaps': 'Aktuell sind Akku, Hardware und Sensoren nicht abgedeckt. Software-Support endet in 90 Tagen. Ich empfehle VerdantCare Plus.',
        // ... weitere
    },
    upgrades: { /* ... */ },
    telemetry: { /* ... */ }
};
```

#### Events

- `highlightcomponent`: `{ detail: { target } }`

---

## Stream B – Konsistenz-Pass

### B.1 – Zentrales `cgTokens` Static Resource

**Pfad:** `force-app/main/default/staticresources/cgTokens.css`

```css
:root {
    /* Brand Colors */
    --cg-vibrant-blue: #0070AD;
    --cg-velocity-blue: #12ABDB;
    --cg-deep-purple: #2B1A47;
    --cg-charcoal: #1F2A37;
    --cg-grey-100: #F4F5F7;
    --cg-grey-200: #E5E7EB;
    --cg-grey-300: #D1D5DB;
    --cg-critical-red: #D4351C;
    --cg-amber: #F59E0B;
    --cg-success-green: #3F9E54;

    /* Geometry */
    --cg-radius: 12px;
    --cg-radius-sm: 8px;
    --cg-radius-pill: 999px;

    /* Spacing, Shadows, Transitions, Typography */
    /* ... */
}
```

#### Integration

In den drei Wrapper-Components (`warrantyAdvisorPanel`, `productUpgradeStudio`, `connectedAssetDashboard`):

```javascript
import { loadStyle } from 'lightning/platformResourceLoader';
import CG_TOKENS from '@salesforce/resourceUrl/cgTokens';

connectedCallback() {
    loadStyle(this, CG_TOKENS);
}
```

### B.2 – CSS-Variable-Deduplizierung

Alle LWC-Bundles aus Phase 2, 3, 4 durchgehen und:
1. Entferne lokale `:host { --cg-* }` Definitionen
2. Behalte die Verwendung von `var(--cg-*)` in CSS-Regeln
3. Wo hartcodierte Werte existieren: durch CSS-Variablen ersetzen

### B.3 – Loading-Skeleton-Vereinheitlichung

Mini-Komponente `loadingSkeleton`:
- `@api variant` – `'card' | 'banner' | 'kpi-row' | 'chart'`
- Wird in allen drei Wrappern statt Inline-Skeleton-Logik verwendet

### B.4 – Empty-State und Error-State

`emptyState` und `errorState` Komponenten für graceful Fehlerbehandlung in allen drei Wrappern.

### B.5 – Highlight-Animation für `highlightcomponent`-Events

Wenn `agentNudgeBubble` ein `highlightcomponent`-Event dispatcht, fängt der Wrapper das und triggert eine Border-Glow-Animation (Pulse 1.5s) auf der Zielkomponente.

---

## Stream C – Demo-Härtung

### C.1 – Edge-Case-Handling in Apex-Controllern

1. **Null-Safe DTO-Aufbau:** WO ohne Asset → `assetMissing: true`, Wrapper rendert `emptyState`
2. **Fallback-Reasoning:** `VBOT_Property_Size_Sqm__c` NULL → generische Bullets
3. **Empty-Telemetry-Fallback:** keine Records → Default-KPIs
4. **Try-Catch um Top-Level-Aufrufe:** `AuraHandledException` mit klarer Message

### C.2 – Demo-Reset als Quick-Action

`demoResetAction` LWC + `DemoResetController` Apex:
- Confirmation-Dialog
- Setzt WO-Status zurück
- Löscht und re-seedet letzte 7 Telemetry-Records
- Setzt ServiceContract-Status zurück
- Idempotent

### C.3 – Backup-Screenshots als Static Resources

Sechs PNGs als Static Resources:
- `vbot_backup_warranty`, `vbot_backup_warranty_modal`
- `vbot_backup_upgrades`, `vbot_backup_upgrades_drawer`
- `vbot_backup_telemetry`, `vbot_backup_mobile_mirror`

Plus `docs/backup-screenshots.md` mit Verwendungsanleitung.

### C.4 – Pre-Demo-Checkliste

`docs/DEMO_CHECKLIST.md` mit Schritten für 30 min vor Start, 5 min vor Start, Notfall.

---

## Deployment

```bash
sf project deploy validate --source-dir force-app --target-org <alias>
sf project deploy start --source-dir force-app --target-org <alias>
sf apex run test --class-names DemoResetControllerTest --target-org <alias> --result-format human
```

## Acceptance Criteria – Phase 5 ist fertig, wenn …

### Stream A – Agentforce

1. `agentNudgeBubble` auf allen drei Tab-Positionen sichtbar
2. Closed-State zeigt pulsierende Bubble mit Notification-Badge
3. Open-State zeigt Chat-Panel mit 3 kontextspezifischen Prompts
4. Klick auf Prompt → Typing → Agent-Antwort → Highlight-Event
5. Highlight-Animation triggert in Ziel-LWC
6. Auto-Context-Detection funktioniert

### Stream B – Konsistenz

7. `cgTokens` Static Resource deployed und geladen
8. Lokale `:host { --cg-* }` aus allen Bundles entfernt
9. `loadingSkeleton` in allen drei Wrappern
10. `emptyState` und `errorState` verfügbar und getestet
11. Visueller Side-by-Side-Test: identischer Look über alle Phasen

### Stream C – Demo-Härtung

12. Edge-Cases in allen drei Controllern abgedeckt
13. `demoResetAction` Quick-Action verfügbar und funktional
14. 6 Backup-Screenshots als Static Resources
15. `docs/DEMO_CHECKLIST.md` committet

### Allgemein

16. Deploy idempotent, alle bestehenden Tests grün
17. Git: committet als `Phase 5: agent bubble, consistency pass, demo hardening`
18. README ergänzt um „Demo-Run"-Abschnitt

## Output am Ende

1. Deploy-Log
2. Test-Ergebnis
3. Liste aller geänderten/neu erzeugten Dateien
4. Pro Acceptance-Criterion: ✅/⚠️/❌
5. Hinweis: vier Screenshots (Bubble closed/open, Highlight-Animation, Reset-Action, Backup-Screenshot)
6. Bestätigung, dass Phase 2 + 3 + 4 visuell unverändert wirken
