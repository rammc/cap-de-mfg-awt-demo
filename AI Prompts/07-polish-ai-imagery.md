# Polish Prompt: AI-Generated Product Imagery Integration

## Rolle & Ziel

Du bist Salesforce Platform Engineer und integrierst von Christopher generierte AI-Renderings der vier VerdantBot-Modelle (E150, C300, C500, X800) als Static Resources in die Demo-Org. Die SVG-Illustrationen für Akku (`vbot_bat_plus`) und Software (`vbot_lawn_ai`) bleiben erhalten – nur die vier Roboter werden auf Foto-Renderings umgestellt, weil diese visuell überzeugender wirken als die Vektor-Variante.

Zusätzlich passt du die LWCs an, sodass die Foto-Renderings (typischerweise quadratisch, oft mit weißem Hintergrund) in allen Container-Größen sauber aussehen.

## Input von Christopher

- **Ordnerpfad mit den AI-Renderings:** `<image_folder_path>` (z. B. `~/Downloads/vbot_renders/`)
- **Erwartete Dateien im Ordner (Naming Schema):**
  - `vbot_e150.png` (oder `.jpg`)
  - `vbot_c300.png`
  - `vbot_c500.png`
  - `vbot_x800.png`
- **Falls die Dateinamen abweichen:** zeige eine Mapping-Liste an Christopher und frage nach Bestätigung.

## Globale Regeln

- **Idempotent:** zweiter Lauf darf keine Duplikate erzeugen.
- **5MB-Limit pro Static Resource.** Falls eine Datei darüber liegt, komprimieren via ImageMagick.
- **Format:** PNG bevorzugt, JPG akzeptabel.
- **Naming-Konvention der Static Resources:** identisch zum bestehenden Pattern (`vbot_e150`, `vbot_c300`, `vbot_c500`, `vbot_x800`).
- **SVGs der vier Roboter:** behalten als Backup-Files im Repo, **aber nicht als Static Resources deployen**. Verschiebe sie zu `docs/svg-fallbacks/`.

## Schritt 1 – Image Inventory & Validation

```bash
ls -la <image_folder_path>
file <image_folder_path>/*.png <image_folder_path>/*.jpg 2>/dev/null
identify <image_folder_path>/vbot_*.png
```

Pro Datei prüfen:
- Format: PNG oder JPG
- Dimensionen: mindestens 800×800px
- Dateigröße: unter 5MB

**Falls eine Datei zu groß ist:**

```bash
convert input.png -strip -resize 1024x1024\> -quality 88 output.png
```

**Falls Dateinamen nicht dem Schema entsprechen:** Liste aller Bilder zeigen und Mapping abfragen.

## Schritt 2 – Static Resources anlegen / aktualisieren

Für jedes Bild ein Static-Resource-Bundle in `force-app/main/default/staticresources/` anlegen.

**Beispiel für `vbot_c300`:**

`force-app/main/default/staticresources/vbot_c300.png` (Binary)

`force-app/main/default/staticresources/vbot_c300.resource-meta.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<StaticResource xmlns="http://soap.sforce.com/2006/04/metadata">
    <cacheControl>Public</cacheControl>
    <contentType>image/png</contentType>
    <description>VerdantBot C300 product image (AI-generated)</description>
</StaticResource>
```

Bei JPG: `<contentType>image/jpeg</contentType>` und Dateiendung `.jpg`.

**Idempotenz-Check:**
- Vergleiche Hash der bestehenden Datei mit der neuen
- Wenn identisch → `[SKIP-EXISTS]`
- Wenn unterschiedlich → überschreiben + `[UPDATE]`

**SVGs der vier Roboter verschieben:**

```bash
mkdir -p docs/svg-fallbacks
mv force-app/main/default/staticresources/vbot_e150.svg* docs/svg-fallbacks/ 2>/dev/null || true
# analog für c300, c500, x800
```

**Die SVGs für `vbot_bat_plus` und `vbot_lawn_ai` bleiben unverändert als Static Resources.**

## Schritt 3 – Apex-Seed-Skript aktualisieren

Im `scripts/apex/seed-vbot-demo.apex` den Product2-Seed-Block erweitern:

```apex
Map<String, String> imageMap = new Map<String, String>{
    'VBOT_E150'      => '/resource/vbot_e150',
    'VBOT_C300'      => '/resource/vbot_c300',
    'VBOT_C500'      => '/resource/vbot_c500',
    'VBOT_X800'      => '/resource/vbot_x800',
    'VBOT_BAT_PLUS'  => '/resource/vbot_bat_plus',
    'VBOT_LAWN_AI'   => '/resource/vbot_lawn_ai'
};

List<Product2> productsToUpdate = new List<Product2>();
for (Product2 p : [SELECT Id, ProductCode, VBOT_Hero_Image_Url__c FROM Product2 WHERE ProductCode LIKE 'VBOT_%']) {
    String expectedUrl = imageMap.get(p.ProductCode);
    if (expectedUrl != null && p.VBOT_Hero_Image_Url__c != expectedUrl) {
        p.VBOT_Hero_Image_Url__c = expectedUrl;
        productsToUpdate.add(p);
    }
}
if (!productsToUpdate.isEmpty()) {
    update productsToUpdate;
    System.debug('[UPDATE] Product images: ' + productsToUpdate.size() + ' records');
} else {
    System.debug('[SKIP-EXISTS] Product images already set');
}
```

## Schritt 4 – LWC-Anpassungen für Foto-Renderings

Foto-Renderings unterscheiden sich von SVGs:
- **Hintergrund:** typischerweise weiß
- **Aspect Ratio:** quadratisch (1:1)

Vier LWCs verwenden die Hero-Images:

### 4.1 – `productUpgradeCard`

In `productUpgradeCard.css`:

```css
.vbot-product-image {
    width: 100%;
    height: 120px;
    background: white;
    border-radius: 8px;
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 8px;
    box-sizing: border-box;
}
.vbot-product-image img {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
}
```

In `productUpgradeCard.html`:

```html
<div class="vbot-product-image">
    <template if:true={option.heroImageUrl}>
        <img src={option.heroImageUrl} alt={option.name}/>
    </template>
    <template if:false={option.heroImageUrl}>
        <lightning-icon icon-name="utility:product" size="large"></lightning-icon>
    </template>
</div>
```

### 4.2 – `assetContextBanner`

```css
.vbot-banner-image {
    width: 100px;
    height: 100px;
    background: white;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    overflow: hidden;
    box-shadow: 0 1px 3px rgba(31, 42, 55, 0.08);
}
.vbot-banner-image img {
    max-width: 90%;
    max-height: 90%;
    object-fit: contain;
}
```

### 4.3 – `quoteCartFlyout`

```css
.vbot-cart-item-image {
    width: 56px;
    height: 56px;
    background: var(--cg-grey-100);
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    overflow: hidden;
}
.vbot-cart-item-image img {
    max-width: 90%;
    max-height: 90%;
    object-fit: contain;
}
```

### 4.4 – `specDiffComparator`

```css
.vbot-diff-product-image {
    width: 140px;
    height: 140px;
    background: white;
    border-radius: 12px;
    margin: 0 auto 16px;
    display: flex;
    align-items: center;
    justify-content: center;
    overflow: hidden;
    box-shadow: 0 2px 6px rgba(31, 42, 55, 0.08);
}
.vbot-diff-product-image img {
    max-width: 90%;
    max-height: 90%;
    object-fit: contain;
}
```

## Schritt 5 – Deployment & Verifikation

```bash
sf project deploy validate --source-dir force-app --target-org <alias>
sf project deploy start --source-dir force-app --target-org <alias>
sf apex run --file scripts/apex/seed-vbot-demo.apex --target-org <alias>
```

Nach Deploy:
1. Demo-WO öffnen mit Hard-Reload (⌘⇧R)
2. Zum `productUpgradeStudio` scrollen
3. „Vergleichen" klicken → Hero-Images im Spec-Diff
4. „Zu Quote hinzufügen" → Thumbnail im Cart
5. Asset-Page → `assetContextBanner` mit Bild

## Schritt 6 – Repo-Doku update

In `README.md`:

```markdown
## Product Imagery

Produktbilder der vier VerdantBot-Modelle sind AI-generiert (Gemini Nano Banana 2)
und liegen als Static Resources in `force-app/main/default/staticresources/`:
- `vbot_e150`, `vbot_c300`, `vbot_c500`, `vbot_x800` (PNG/JPG)
- `vbot_bat_plus`, `vbot_lawn_ai` (SVG, handgezeichnet)

SVG-Fallbacks der vier Roboter liegen in `docs/svg-fallbacks/` als Backup.
```

In `CLAUDE.md`:

```markdown
## Product Imagery

- Vier Roboter-Modelle: AI-Renderings (PNG/JPG)
- Akku + Software: handgezeichnete SVGs (transparent)
- Bei Änderungen: Static Resources tauschen, Apex-Seed re-run, Browser hard-reload
```

## Acceptance Criteria

1. Vier neue Static Resources angelegt
2. Jede Resource < 5MB, contentType korrekt
3. SVG-Files der vier Roboter nach `docs/svg-fallbacks/` verschoben
4. `vbot_bat_plus.svg` und `vbot_lawn_ai.svg` unverändert
5. Apex-Seed: `VBOT_Hero_Image_Url__c` auf allen 6 Produkten korrekt gesetzt
6. Vier LWCs CSS-angepasst
7. Visuelle Verifikation: Demo-WO und Demo-Asset zeigen neue Bilder
8. Idempotent: zweiter Run produziert `[SKIP-EXISTS]`
9. Git: committet als `Polish: AI-generated product imagery`

## Output am Ende

1. Liste aller verarbeiteten Bilder (Original-Pfad, Zielpfad, Dateigröße, Dimensionen)
2. Deploy-Log
3. Apex-Seed-Log
4. Pro Acceptance-Criterion: ✅/⚠️/❌
5. Hinweis: vier Screenshots der LWC-Stellen für visuelle Verifikation
