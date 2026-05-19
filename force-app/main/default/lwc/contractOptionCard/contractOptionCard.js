import { LightningElement, api } from 'lwc';

const TIER_BADGE_CLASS = {
    Basic: 'tier-badge tier-badge_basic',
    Plus: 'tier-badge tier-badge_plus',
    Premium: 'tier-badge tier-badge_premium'
};

const COVERAGE_LABELS = {
    software: 'Software & App',
    battery: 'Akku',
    hardware: 'Hardware',
    sensors: 'Sensorik'
};

export default class ContractOptionCard extends LightningElement {
    @api contract;
    @api billingCycle = 'monthly';

    get cardClass() {
        return this.contract?.isRecommended
            ? 'card card_highlight'
            : 'card';
    }

    get tierBadgeClass() {
        return TIER_BADGE_CLASS[this.contract?.tier] || 'tier-badge';
    }

    get showRecommendedBadge() {
        return !!this.contract?.isRecommended;
    }

    get priceLabel() {
        if (!this.contract) return '';
        const value = this.billingCycle === 'yearly'
            ? this.contract.yearlyPrice
            : this.contract.monthlyPrice;
        const suffix = this.billingCycle === 'yearly' ? '/Jahr' : '/Monat';
        return `€${Number(value || 0).toFixed(2).replace('.', ',')}${suffix}`;
    }

    get cycleLabel() {
        return this.billingCycle === 'yearly' ? 'Jährlich' : 'Monatlich';
    }

    get coverageRows() {
        return (this.contract?.coverages || []).map((c) => ({
            key: c.key,
            label: COVERAGE_LABELS[c.key] || c.label || c.key,
            covered: c.status === 'covered',
            iconName: c.status === 'covered' ? 'utility:check' : 'utility:close',
            iconVariant: c.status === 'covered' ? 'success' : 'error',
            cls: c.status === 'covered' ? 'row row_covered' : 'row row_uncovered'
        }));
    }

    handleCompare() {
        this.dispatchEvent(new CustomEvent('comparecontracts', {
            bubbles: true,
            composed: true,
            detail: { contractId: this.contract?.contractId }
        }));
    }

    handleSelect() {
        this.dispatchEvent(new CustomEvent('selectcontract', {
            bubbles: true,
            composed: true,
            detail: {
                contractId: this.contract?.contractId,
                billingCycle: this.billingCycle
            }
        }));
    }
}
