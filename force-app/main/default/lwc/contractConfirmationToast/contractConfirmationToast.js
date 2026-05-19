import { LightningElement, api } from 'lwc';

export default class ContractConfirmationToast extends LightningElement {
    @api isVisible = false;
    @api contractName = '';
    _timer;

    get rootClass() {
        return this.isVisible ? 'overlay overlay_visible' : 'overlay';
    }

    get subtext() {
        return `${this.contractName || 'Vertrag'} ist ab sofort aktiv. Kunde erhält Bestätigung per E-Mail.`;
    }

    renderedCallback() {
        if (this.isVisible && !this._timer) {
            this._timer = setTimeout(() => this._dismiss(), 4000);
        } else if (!this.isVisible && this._timer) {
            clearTimeout(this._timer);
            this._timer = null;
        }
    }

    disconnectedCallback() {
        if (this._timer) {
            clearTimeout(this._timer);
            this._timer = null;
        }
    }

    handleDismiss() {
        this._dismiss();
    }

    _dismiss() {
        if (this._timer) {
            clearTimeout(this._timer);
            this._timer = null;
        }
        this.dispatchEvent(new CustomEvent('dismiss'));
    }
}
