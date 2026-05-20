# Pre-Demo Checklist

## 30 Minuten vor Start

- [ ] Demo-Reset auf der Demo-WO ausführen
      ```
      sf apex run --file scripts/apex/reset-vbot-demo.apex --target-org christopher.ramm@cap-de-mfg-awt-demo.com
      sf apex run --file scripts/apex/seed-vbot-demo.apex --target-org christopher.ramm@cap-de-mfg-awt-demo.com
      ```
      Alternativ Quick-Action **VBOT Demo Reset** auf der WorkOrder.
- [ ] Browser-Cache leeren (⌘⇧R auf WO-Page)
- [ ] Test-Klick durch alle Use Cases:
      Service & Warranty → „Vergleichen" Drawer → „Auswählen" Signature →
      Upgrade-Studio → „Vergleichen" Spec-Drawer → „Zu Quote hinzufügen" Flyout →
      Asset → Connected Asset Dashboard → Chart-Range 7T → „Termin vorschlagen" Toast
- [ ] Backup-Screenshot-Tab in zweitem Browser-Window vorbereiten
      (siehe `docs/backup-screenshots.md`)
- [ ] Mobile Hotspot als Wifi-Backup einschalten
- [ ] Org-Login auffrischen: `sf org open --target-org christopher.ramm@cap-de-mfg-awt-demo.com`

## 5 Minuten vor Start

- [ ] WO-Page + Asset-Page einmal angeklickt (Cache-Warm-up)
- [ ] Agent-Bubble einmal getriggert (Klick auf einen Prompt) → Highlight-Animation sichtbar
- [ ] Wasser griffbereit

## Notfall — Org reagiert nicht

1. F5 / ⌘R auf der Record-Page
2. `sf org open` neu aufrufen
3. Backup-Screenshots im Vor-Tab — Story trotzdem zu Ende erzählen
4. Falls Apex-Fehler: Quick-Action **VBOT Demo Reset** → bei Erfolg weiter, sonst seed-Skript erneut

## Direkt-Links

```bash
# WorkOrder (Service & Warranty + Upgrades)
sf org open --target-org christopher.ramm@cap-de-mfg-awt-demo.com \
  --path /lightning/r/WorkOrder/0WOWz000004EjDFOA0/view

# Asset (Connected Asset)
sf org open --target-org christopher.ramm@cap-de-mfg-awt-demo.com \
  --path /lightning/r/Asset/02iWz0000070dQLIAY/view
```
