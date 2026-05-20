# Backup-Screenshots für die Demo

Sechs PNGs als Fallback, falls die Live-Org während der Demo nicht reagiert. Liegen **nicht** als Static Resources im Repo (Binär-Files würden den Diff aufblähen) – stattdessen separat auf dem Demo-Laptop und in einem zweiten Browser-Tab vorbereitet.

## Aufnahme-Workflow

1. WO-Page öffnen, **Demo-Reset** durchführen (Quick-Action oder seed-Skript).
2. Pro Screenshot: ⌘⇧4 (macOS) oder Snipping-Tool (Windows), in einen Ordner `~/Desktop/vbot-backup/` ablegen.
3. Im Backup-Browser-Tab als lokale `file://`-Vorschau öffnen, damit sie als Notfall sofort sichtbar sind.

## Die 6 Aufnahmen

| # | Datei | Inhalt | Triggered-Aktion |
|---|---|---|---|
| 1 | `vbot_backup_warranty.png` | `warrantyAdvisorPanel` Initial-State | WO-Page öffnen |
| 2 | `vbot_backup_warranty_modal.png` | `contractComparisonDrawer` geöffnet | „Vergleichen" auf Plus-Card |
| 3 | `vbot_backup_upgrades.png` | `productUpgradeStudio` Initial-State | runterscrollen auf WO |
| 4 | `vbot_backup_upgrades_drawer.png` | `specDiffComparator` geöffnet | „Vergleichen" auf C500-Card |
| 5 | `vbot_backup_telemetry.png` | `connectedAssetDashboard` Initial-State | Asset-Page öffnen |
| 6 | `vbot_backup_mobile_mirror.png` | `mobilePreviewMirror` Nahaufnahme | rechte Seite des Dashboards zoomen |

## Notfall-Story

Wenn die Org hängt: das Backup-Tab statt der Org zeigen, **die gleiche Geschichte erzählen**, dabei jeden Screenshot in der oben beschriebenen Reihenfolge wechseln. Keine Erklärung „wir sind offline" — nur weiterreden.
