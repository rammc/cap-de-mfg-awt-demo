import { LightningElement, api } from 'lwc';

export default class EmptyState extends LightningElement {
    @api icon = 'utility:info';
    @api title = '';
    @api message = '';
    @api ctaLabel;

    get hasCta() { return !!this.ctaLabel; }

    handleCta() {
        this.dispatchEvent(new CustomEvent('cta'));
    }
}
