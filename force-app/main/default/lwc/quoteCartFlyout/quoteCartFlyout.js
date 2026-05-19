import { LightningElement, api } from 'lwc';

export default class QuoteCartFlyout extends LightningElement {
    @api isOpen = false;
    @api items = [];
    @api customer;
    _bound = false;

    get flyoutClass() { return this.isOpen ? 'flyout flyout_open' : 'flyout'; }
    get scrimClass() { return this.isOpen ? 'scrim scrim_open' : 'scrim'; }

    get isEmpty() { return !this.items || this.items.length === 0; }
    get itemCount() { return (this.items || []).length; }
    get subtotal() {
        const sum = (this.items || []).reduce((acc, it) => acc + Number(it.price || 0), 0);
        return `€${sum.toFixed(2).replace('.', ',')}`;
    }

    get rows() {
        return (this.items || []).map((it, idx) => ({
            key: it.productId || idx,
            productId: it.productId,
            name: it.name,
            price: `€${Number(it.price || 0).toFixed(2).replace('.', ',')}`,
            hasImage: !!it.heroImageUrl,
            heroImageUrl: it.heroImageUrl
        }));
    }

    renderedCallback() {
        if (this.isOpen && !this._bound) {
            this._keydown = (e) => { if (e.key === 'Escape') this._close(); };
            window.addEventListener('keydown', this._keydown);
            this._bound = true;
        } else if (!this.isOpen && this._bound) {
            window.removeEventListener('keydown', this._keydown);
            this._bound = false;
        }
    }
    disconnectedCallback() {
        if (this._bound) {
            window.removeEventListener('keydown', this._keydown);
            this._bound = false;
        }
    }

    handleScrim(event) {
        if (event.target === event.currentTarget) this._close();
    }
    handleClose() { this._close(); }
    handleRemove(event) {
        const productId = event.currentTarget.dataset.productId;
        this.dispatchEvent(new CustomEvent('removeitem', { detail: { productId } }));
    }
    handleSend() {
        if (this.isEmpty) return;
        this.dispatchEvent(new CustomEvent('sendquote', { detail: { items: this.items } }));
    }
    _close() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}
