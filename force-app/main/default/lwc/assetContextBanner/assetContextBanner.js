import { LightningElement, api } from 'lwc';

export default class AssetContextBanner extends LightningElement {
    @api asset;

    get hasImage() {
        return !!this.asset?.productImageUrl;
    }

    get installedText() {
        const m = this.asset?.installedMonthsAgo;
        if (m == null) return '';
        if (m < 1) return 'In diesem Monat installiert';
        return `Installiert vor ${m} Monaten`;
    }

    get propertyPill() {
        return this.asset?.propertySize != null
            ? `Grundstück: ${this.asset.propertySize} m²`
            : 'Grundstück: unbekannt';
    }

    get batteryPill() {
        const pct = this.asset?.batteryHealthPct;
        return pct != null
            ? `Akku: ${Math.round(pct)} %`
            : 'Akku: —';
    }

    get firmwarePill() {
        return this.asset?.firmwareVersion
            ? `Firmware: ${this.asset.firmwareVersion}`
            : 'Firmware: —';
    }
}
