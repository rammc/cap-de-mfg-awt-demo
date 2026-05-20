import { LightningElement, api } from 'lwc';

export default class LoadingSkeleton extends LightningElement {
    @api variant = 'card';

    get isBanner() { return this.variant === 'banner'; }
    get isKpiRow() { return this.variant === 'kpi-row'; }
    get isChart() { return this.variant === 'chart'; }
    get isCard() { return !this.isBanner && !this.isKpiRow && !this.isChart; }
}
