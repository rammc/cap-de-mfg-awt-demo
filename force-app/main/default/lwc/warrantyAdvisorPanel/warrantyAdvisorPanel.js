import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAdvisorData from '@salesforce/apex/WarrantyAdvisorController.getAdvisorData';

export default class WarrantyAdvisorPanel extends LightningElement {
    @api recordId;
    billingCycle = 'monthly';
    comparisonOpen = false;
    signatureOpen = false;
    toastVisible = false;
    selectedContract;
    confirmedContractName = '';
    _wired;

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
}
