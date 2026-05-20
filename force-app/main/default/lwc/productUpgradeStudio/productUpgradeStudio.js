import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import HIGHLIGHT_CHANNEL from '@salesforce/messageChannel/VBOT_HighlightChannel__c';
import getUpgradeData from '@salesforce/apex/ProductUpgradeController.getUpgradeData';

const HIGHLIGHT_DURATION_MS = 1500;
const HIGHLIGHT_TARGETS = new Set(['reasoningExplainer', 'upgradeRecommendationGrid']);

export default class ProductUpgradeStudio extends LightningElement {
    @api recordId;
    diffOpen = false;
    cartOpen = false;
    selectedUpgrade;
    cartItems = [];
    highlightTarget;
    _wired;
    _subscription;
    _highlightTimer;

    @wire(MessageContext) messageContext;

    @wire(getUpgradeData, { workOrderId: '$recordId' })
    wiredUpgrade(result) {
        this._wired = result;
    }

    get loading() {
        return !this._wired || (!this._wired.data && !this._wired.error);
    }
    get error() { return this._wired?.error; }
    get data() { return this._wired?.data; }
    get hasData() { return !!this.data && !this.error; }

    get headerTitle() {
        return this.data ? `Upgrade-Empfehlungen für ${this.data.asset.name}` : 'Upgrade-Empfehlungen';
    }
    get headerSubtitle() {
        if (!this.data) return '';
        return `${this.data.accountName} · ${this.data.contactName}`;
    }
    get customerLabel() {
        if (!this.data) return '';
        return [this.data.accountName, this.data.contactName].filter(Boolean).join(' · ');
    }
    get currentProduct() {
        return this.data?.currentProduct;
    }

    handleCompare(event) {
        const id = event.detail?.productId;
        this.selectedUpgrade = (this.data?.options || []).find((o) => o.productId === id);
        if (this.selectedUpgrade) {
            this.diffOpen = true;
        }
    }
    handleCloseDiff() {
        this.diffOpen = false;
    }

    handleAddToQuote(event) {
        const opt = event.detail?.option;
        if (!opt) return;
        if (!this.cartItems.some((it) => it.productId === opt.productId)) {
            this.cartItems = [...this.cartItems, opt];
        }
        this.diffOpen = false;
        this.cartOpen = true;
    }
    handleCloseCart() {
        this.cartOpen = false;
    }
    handleRemoveItem(event) {
        const pid = event.detail?.productId;
        this.cartItems = this.cartItems.filter((it) => it.productId !== pid);
    }
    handleSendQuote() {
        this.cartOpen = false;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Quote gesendet',
            message: `${this.cartItems.length} Position(en) wurden an ${this.data?.accountName || 'den Kunden'} versendet.`,
            variant: 'success'
        }));
        this.cartItems = [];
    }
    handleRetry() {
        if (this._wired) refreshApex(this._wired);
    }

    connectedCallback() {
        if (!this._subscription && this.messageContext) {
            this._subscription = subscribe(this.messageContext, HIGHLIGHT_CHANNEL, (msg) => this._handleHighlight(msg));
        }
    }
    renderedCallback() {
        if (!this._subscription && this.messageContext) {
            this._subscription = subscribe(this.messageContext, HIGHLIGHT_CHANNEL, (msg) => this._handleHighlight(msg));
        }
    }
    disconnectedCallback() {
        if (this._subscription) {
            unsubscribe(this._subscription);
            this._subscription = null;
        }
        if (this._highlightTimer) clearTimeout(this._highlightTimer);
    }
    _handleHighlight(message) {
        if (!message || !HIGHLIGHT_TARGETS.has(message.target)) return;
        this.highlightTarget = message.target;
        if (this._highlightTimer) clearTimeout(this._highlightTimer);
        this._highlightTimer = setTimeout(() => { this.highlightTarget = null; }, HIGHLIGHT_DURATION_MS);
    }
    get gridClass() {
        return this.highlightTarget === 'upgradeRecommendationGrid' ? 'highlight-host is-highlighted' : 'highlight-host';
    }
    get reasoningClass() {
        return this.highlightTarget === 'reasoningExplainer' ? 'highlight-host is-highlighted' : 'highlight-host';
    }
}
