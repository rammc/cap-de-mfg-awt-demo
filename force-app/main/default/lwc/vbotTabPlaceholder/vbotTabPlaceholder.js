import { LightningElement, api } from 'lwc';

const VARIANT_LABELS = {
    'service-warranty': 'Service & Warranty',
    upgrades: 'Upgrades',
    'connected-asset': 'Connected Asset',
    generic: 'Coming soon'
};

export default class VbotTabPlaceholder extends LightningElement {
    @api tabLabel = 'Coming soon';
    @api variant = 'auto';
    @api phaseLabel = 'Phase 2';

    get resolvedVariant() {
        if (this.variant && this.variant !== 'auto') {
            return this.variant;
        }
        const label = (this.tabLabel || '').toLowerCase();
        if (label.includes('service') || label.includes('warranty')) return 'service-warranty';
        if (label.includes('upgrade') || label.includes('sales')) return 'upgrades';
        if (label.includes('connected') || label.includes('asset') || label.includes('telemetry')) return 'connected-asset';
        return 'generic';
    }

    get displayLabel() {
        if (this.tabLabel && this.tabLabel !== 'Coming soon') {
            return this.tabLabel;
        }
        return VARIANT_LABELS[this.resolvedVariant] || 'Coming soon';
    }

    get isServiceWarranty() {
        return this.resolvedVariant === 'service-warranty';
    }
    get isUpgrades() {
        return this.resolvedVariant === 'upgrades';
    }
    get isConnectedAsset() {
        return this.resolvedVariant === 'connected-asset';
    }
    get isGeneric() {
        return this.resolvedVariant === 'generic';
    }
}
