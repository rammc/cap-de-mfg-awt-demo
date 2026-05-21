# Easter Egg Implementation Prompt: VerdantBot Drive-By

## Rolle & Ziel

Du baust ein verstecktes Easter Egg in die VerdantBot-Demo: zwei schnelle Klicks auf ein Produkt-Element → ein kleiner SVG-Rasenmähroboter fährt animiert über den Bildschirm, hinterlässt eine kurz sichtbare „gemähte Bahn" und verschwindet. Reines Frontend, keine Backend-Logik, kein Audio.

Das Easter Egg ist eine versteckte Belohnung für aufmerksame Demo-Zuschauer und Insider-Konferenzgäste.

## Globale Regeln

- **Branding:** VerdantBot-Stil + Capgemini-Tokens (`cgTokens` Static Resource aus Phase 5). Robot-Body: Vibrant Blue Hauptkörper, Velocity Blue Akzent, weiße Highlights.
- **Performance:** GPU-beschleunigte CSS-Transforms, keine JS-Animation-Loops. Ziel: konstante 60fps.
- **Kein Audio.**
- **A11y-aware:** `prefers-reduced-motion` Media Query respektieren – wenn User reduzierte Bewegung wählt, zeigt das Easter Egg eine kurze statische Toast-Notification.

## Komponenten-Architektur

```
verdantBotEasterEgg (singletonartig, lazy-mounted)
├── verdantBotMowerSvg (SVG-Definition, inline in der LWC)
├── mowing-trail (CSS-Layer)
└── easterEggTriggerMixin (JS-Helper)
```

Drei Bestandteile:

1. **Die Easter-Egg-LWC selbst**
2. **Trigger-Hooks in bestehenden LWCs** – Double-Click-Listener auf 2-3 wohldefinierte Stellen
3. **Custom Event Bus** – `verdantbotdriveby` Event bubbles bis zur Easter-Egg-LWC

---

## Komponente 1: `verdantBotEasterEgg`

**Pfad:** `force-app/main/default/lwc/verdantBotEasterEgg/`

### Funktion

- Statisch in den drei Wrapper-LWCs eingebettet
- Position: `position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; pointer-events: none; z-index: 9999`
- Default-State: unsichtbar
- Lauscht auf custom Event `verdantbotdriveby`
- Bei Empfang:
  1. Prüft Cooldown (8 Sekunden via localStorage)
  2. Prüft `prefers-reduced-motion` – falls true: SLDS-Toast statt Animation
  3. Andernfalls: rendert Roboter und startet Animation
  4. Inkrementiert `vbot_easter_total_finds`
  5. Bei `total_finds >= 3`: Toast „🌱 Du hast den VerdantBot {n} mal entdeckt!"

### Animation-Phasen

Gesamtdauer: 4.5 Sekunden:

| Phase | Dauer | Was passiert |
|---|---|---|
| **Entrance** | 0–800ms | Roboter startet links unten außerhalb, fährt diagonal in die Bildschirmmitte |
| **Mid-Spin** | 800–1.800ms | 360°-Drehung in der Mitte, plus zwei „Wackler" (Yaw ±10°) |
| **Exit** | 1.800–3.500ms | Fährt diagonal nach rechts oben aus dem Viewport |
| **Cleanup** | 3.500–4.500ms | Mowing-Trail verblasst |

### Mowing-Trail

- **Implementation:** SVG-Path mit `stroke-dasharray` und `stroke-dashoffset` animiert
- **Farbe:** `var(--cg-success-green)` mit `opacity: 0.35`
- **Strichbreite:** 24px
- **Verblassen:** während Cleanup-Phase opacity 0.35 → 0 über 1 Sekunde
- **Bonus:** kleine `<circle>`-Elemente in Velocity Blue an 3-4 Stellen (Gras-Flocken)

### Roboter-SVG-Definition

Inline in `verdantBotEasterEgg.html` als 80×60px SVG (Top-Down):
- Body (ellipse, Vibrant Blue)
- Highlight (top-left, Velocity Blue)
- Sensor strip (rect, Velocity Blue)
- Two LED eyes (white circles)
- VerdantBot "V" logo (white path)
- Side wheels (charcoal rects)
- Antenna mit rotem Dot

### Bonus-Detail: klickbarer Roboter

Während der Mid-Spin-Phase ist der Roboter klickbar:
- Stoppt Spin
- Zeigt 1 Sekunde Sprechblase „Hallo, Christopher! 🌱"
- Fährt dann normal weiter

### Trigger-Statistik (localStorage)

- `vbot_easter_total_finds`: Integer
- `vbot_easter_last_trigger`: Timestamp
- `vbot_easter_robot_clicked`: Integer

Bei `total_finds === 1`: erster Toast
Bei `total_finds === 3`: spezieller Toast
Bei `robot_clicked >= 1`: geheimer Toast

---

## Trigger-Hooks in bestehenden LWCs

Drei Stellen für Double-Click:

### Hook 1: `assetContextBanner` (Phase 3)

- Wrap Produktbild in `<div ondblclick={handleDoubleClick}>`
- Title-Attribut „Klick mich zweimal"

### Hook 2: `assetHealthHeader` (Phase 4)

- Battery-Donut als Trigger-Element

### Hook 3: `mobilePreviewMirror` (Phase 4)

- iPhone-Frame als Trigger-Element

### Event-Handler (in jeder Trigger-LWC)

```javascript
handleDoubleClick() {
    this.dispatchEvent(new CustomEvent('verdantbotdriveby', {
        bubbles: true,
        composed: true,
        detail: { triggerSource: 'assetContextBanner' }
    }));
}
```

---

## Integration in Wrapper-LWCs

Jeder Wrapper (`warrantyAdvisorPanel`, `productUpgradeStudio`, `connectedAssetDashboard`) bekommt am Ende seines Templates:

```html
<c-verdant-bot-easter-egg></c-verdant-bot-easter-egg>
```

Da `position: fixed` ist, ist die Platzierung im DOM irrelevant.

---

## CSS-Highlights

### Robot-Body-Schwung

```css
@keyframes vbot-yaw-sway {
    0%, 100% { transform: rotate(0deg); }
    50% { transform: rotate(2deg); }
}
.vbot-mower-svg { animation: vbot-yaw-sway 1.2s ease-in-out infinite; }
```

### Mid-Spin

```css
@keyframes vbot-mid-spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}
```

### Container-Pfad

```css
.vbot-mower-container {
    position: fixed;
    width: 80px;
    height: 60px;
    will-change: transform;
}
.vbot-mower-container.is-entrance { animation: vbot-entrance 800ms ease-out forwards; }
.vbot-mower-container.is-mid-spin { animation: vbot-mid-spin 1000ms ease-in-out forwards; }
.vbot-mower-container.is-exit { animation: vbot-exit 1700ms ease-in forwards; }
```

### Reduced-Motion-Fallback

```css
@media (prefers-reduced-motion: reduce) {
    .vbot-mower-container,
    .vbot-mower-svg,
    .vbot-trail {
        animation: none !important;
        display: none;
    }
}
```

---

## Acceptance Criteria – Easter Egg ist fertig, wenn …

1. Double-Click (innerhalb 400ms) auf eines der drei Trigger-Elemente löst Animation aus
2. Animation läuft in 4 Phasen ab, Gesamtdauer 4.5s
3. Roboter-SVG ist VerdantBot-gebrandet (Vibrant Blue + Velocity Blue + roter Antennen-Dot)
4. Mowing-Trail erscheint und verblasst nach 3.5s
5. Cooldown von 8 Sekunden funktioniert
6. Erstes Triggern zeigt Toast „🌱 Du hast den VerdantBot gefunden!"
7. Drittes Triggern zeigt speziellen Toast
8. `prefers-reduced-motion: reduce` ersetzt Animation durch SLDS-Toast
9. Animation läuft konstant 60fps
10. Roboter während Mid-Spin klickbar, zeigt Sprechblase
11. Git: committet als `Easter egg: VerdantBot drive-by`

## Output am Ende

1. Deploy-Log
2. Pro Acceptance-Criterion: ✅/⚠️/❌
3. Screen-Recording (5 Sekunden, GIF oder MP4) für Bühnen-Trockenlauf
4. Hinweis: „Doppelklick auf Produktbild im Banner, Battery-Donut, oder iPhone-Frame. Cooldown 8 Sekunden."

## Hinweis zur Demo-Verwendung

- Reihenfolge: **nach** Phase 5 bauen (braucht `cgTokens`)
- Stage-Strategie: ein einziges Mal in der Session, gegen Ende, kurz vor Wrap-up-Slide
- Idealer Moment: nach der Asset-Page, Doppelklick auf iPhone-Mirror, kurzer Schmunzel-Moment
