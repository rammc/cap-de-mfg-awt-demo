import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import HIGHLIGHT_CHANNEL from '@salesforce/messageChannel/VBOT_HighlightChannel__c';
import getDashboardData from '@salesforce/apex/AssetTelemetryController.getDashboardData';

const HIGHLIGHT_DURATION_MS = 1500;
const HIGHLIGHT_TARGETS = new Set(['predictiveMaintenanceCard', 'usageTimelineChart']);

export default class ConnectedAssetDashboard extends LightningElement {
    @api recordId;
    range = '30d';
    highlightTarget;
    _wired;
    _subscription;
    _highlightTimer;

    @wire(MessageContext) messageContext;

    @wire(getDashboardData, { assetId: '$recordId', range: '$range' })
    wiredData(result) {
        this._wired = result;
    }

    get loading() {
        return !this._wired || (!this._wired.data && !this._wired.error);
    }
    get error() { return this._wired?.error; }
    get data() { return this._wired?.data; }
    get hasData() { return !!this.data && !this.error; }

    get syncStatus() { return this.data?.syncStatus; }
    get kpis() { return this.data?.kpis || []; }
    get timeline() { return this.data?.timeline || []; }
    get lawnZones() { return this.data?.lawnZones || []; }
    get forecast() { return this.data?.forecast; }
    get mobileMirror() { return this.data?.mobileMirror; }
    get propertySize() { return this.data?.asset?.propertySize; }

    get headerTitle() {
        return this.data ? `Connected Asset: ${this.data.asset.name}` : 'Connected Asset';
    }
    get headerSubtitle() {
        if (!this.data) return '';
        return `${this.data.asset.productName} · ${this.data.asset.propertySize ?? '—'} m²`;
    }

    handleRangeChange(event) {
        const range = event.detail?.range;
        if (range && range !== this.range) {
            this.range = range;
        }
    }

    handleScheduleAppointment() {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Service-Termin vorgeschlagen',
            message: `Vorschlag für ${this.forecast?.predictedDate || 'bald'} wurde an die Disposition gesendet.`,
            variant: 'success'
        }));
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
    get chartClass() {
        return this.highlightTarget === 'usageTimelineChart' ? 'highlight-host is-highlighted' : 'highlight-host';
    }
    get maintenanceClass() {
        return this.highlightTarget === 'predictiveMaintenanceCard' ? 'highlight-host is-highlighted' : 'highlight-host';
    }
}
