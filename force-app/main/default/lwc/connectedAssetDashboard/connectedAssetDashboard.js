import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDashboardData from '@salesforce/apex/AssetTelemetryController.getDashboardData';

export default class ConnectedAssetDashboard extends LightningElement {
    @api recordId;
    range = '30d';
    _wired;

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
}
