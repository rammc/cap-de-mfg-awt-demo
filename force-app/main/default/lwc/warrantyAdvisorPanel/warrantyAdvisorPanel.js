import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import HIGHLIGHT_CHANNEL from '@salesforce/messageChannel/VBOT_HighlightChannel__c';
import getAdvisorData from '@salesforce/apex/WarrantyAdvisorController.getAdvisorData';

const HIGHLIGHT_DURATION_MS = 1500;
const HIGHLIGHT_TARGETS = new Set(['coverageGapVisualizer', 'contractOptionCard']);

export default class WarrantyAdvisorPanel extends LightningElement {
    @api recordId;
    billingCycle = 'monthly';
    comparisonOpen = false;
    signatureOpen = false;
    toastVisible = false;
    selectedContract;
    confirmedContractName = '';
    highlightTarget;
    _wired;
    _subscription;
    _highlightTimer;

    @wire(MessageContext) messageContext;

    @wire(getAdvisorData, { workOrderId: '$recordId' })
    wiredAdvisor(result) {
        this._wired = result;
    }

    get loading() {
        return !this._wired || (!this._wired.data && !this._wired.error);
    }
    get error() {
        return this._wired?.error;
    }
    get data() {
        return this._wired?.data;
    }
    get hasData() {
        return !!this.data && !this.error;
    }
    get headerTitle() {
        return this.data
            ? `Servicevertrag für ${this.data.assetName}`
            : 'Servicevertrag';
    }
    get headerSubtitle() {
        if (!this.data) return '';
        const cur = this.data.currentContract;
        return cur
            ? `Kunde ${this.data.accountName} · Aktiv: ${cur.name}`
            : `Kunde ${this.data.accountName} · kein aktiver Vertrag`;
    }

    get isMonthly() { return this.billingCycle === 'monthly'; }
    get isYearly() { return this.billingCycle === 'yearly'; }
    get monthlyBtnVariant() { return this.isMonthly ? 'brand' : 'neutral'; }
    get yearlyBtnVariant() { return this.isYearly ? 'brand' : 'neutral'; }

    get options() {
        return this.data?.options || [];
    }

    get customerName() {
        return this.data?.accountName || '';
    }

    handleSetMonthly() { this.billingCycle = 'monthly'; }
    handleSetYearly() { this.billingCycle = 'yearly'; }

    handleCompare() {
        this.comparisonOpen = true;
    }
    handleCloseCompare() {
        this.comparisonOpen = false;
    }

    handleSelect(event) {
        const id = event.detail?.contractId;
        const opt = this.options.find((o) => o.contractId === id);
        if (!opt) return;
        this.selectedContract = opt;
        this.signatureOpen = true;
    }

    handleCloseSignature() {
        this.signatureOpen = false;
        this.selectedContract = undefined;
    }

    handleSignatureComplete() {
        this.confirmedContractName = this.selectedContract?.name || '';
        this.signatureOpen = false;
        this.toastVisible = true;
    }

    handleToastDismiss() {
        this.toastVisible = false;
        this.selectedContract = undefined;
        if (this._wired) {
            refreshApex(this._wired);
        }
    }

    handleRetry() {
        if (this._wired) {
            refreshApex(this._wired);
        }
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
        if (this._highlightTimer) { clearTimeout(this._highlightTimer); }
    }
    _handleHighlight(message) {
        if (!message || !HIGHLIGHT_TARGETS.has(message.target)) return;
        this.highlightTarget = message.target;
        if (this._highlightTimer) clearTimeout(this._highlightTimer);
        this._highlightTimer = setTimeout(() => { this.highlightTarget = null; }, HIGHLIGHT_DURATION_MS);
    }
    get coverageClass() {
        return this.highlightTarget === 'coverageGapVisualizer' ? 'highlight-host is-highlighted' : 'highlight-host';
    }
    get cardsClass() {
        return this.highlightTarget === 'contractOptionCard' ? 'card-row is-highlighted' : 'card-row';
    }
}
