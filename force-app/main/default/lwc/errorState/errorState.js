import { LightningElement, api } from 'lwc';

export default class ErrorState extends LightningElement {
    @api title = 'Daten konnten nicht geladen werden';
    @api message = 'Bitte erneut versuchen.';
    @api retryLabel = 'Erneut laden';

    handleRetry() {
        this.dispatchEvent(new CustomEvent('retry'));
    }
}
