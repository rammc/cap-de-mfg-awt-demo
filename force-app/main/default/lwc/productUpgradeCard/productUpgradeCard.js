import { LightningElement, api } from 'lwc';

const TIER_BADGE_CLASS = {
    Accessory: 'tier-badge tier-badge_accessory',
    'Comfort+': 'tier-badge tier-badge_comfort',
    Pro: 'tier-badge tier-badge_pro'
};

export default class ProductUpgradeCard extends LightningElement {
    @api option;

    get cardClass() {
        return this.option?.isRecommended ? 'card card_highlight' : 'card';
    }
    get tierBadgeClass() {
        return TIER_BADGE_CLASS[this.option?.tier] || 'tier-badge';
    }
    get hasImage() {
        return !!this.option?.heroImageUrl;
    }
    get priceLabel() {
        const v = this.option?.price;
        return v != null ? `€${Number(v).toFixed(2).replace('.', ',')}` : '—';
    }
    get fitBadgeText() {
        const f = this.option?.fitScore;
        return f != null ? `${f} % Fit` : '';
    }
    get specRows() {
        return (this.option?.specs || []).map((s) => ({
            key: s.label,
            label: s.label,
            value: s.value,
            iconName: s.diff === 'up' ? 'utility:add' : 'utility:check',
            iconVariant: s.diff === 'up' ? 'success' : 'inverse',
            cls: s.diff === 'up' ? 'spec spec_up' : 'spec'
        }));
    }
    get valueProps() {
        return (this.option?.valueProps || []).map((t, idx) => ({ key: idx, text: t }));
    }

    handleCompare() {
        this.dispatchEvent(new CustomEvent('comparespecs', {
            bubbles: true,
            composed: true,
            detail: { productId: this.option?.productId }
        }));
    }
    handleAddToQuote() {
        this.dispatchEvent(new CustomEvent('addtoquote', {
            bubbles: true,
            composed: true,
            detail: { option: this.option }
        }));
    }
}
