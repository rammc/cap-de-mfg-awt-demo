import { LightningElement, api } from 'lwc';

const MONTH = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

export default class PredictiveMaintenanceCard extends LightningElement {
    @api forecast;

    get headline() {
        return this.forecast?.headline || 'Predictive Maintenance';
    }
    get daysUntil() {
        return this.forecast?.daysUntil ?? 0;
    }
    get predictedDateLabel() {
        const d = this.forecast?.predictedDate;
        if (!d) return '—';
        const date = d instanceof Date ? d : new Date(d);
        if (Number.isNaN(date.getTime())) return '—';
        return `${date.getDate()}. ${MONTH[date.getMonth()]} ${date.getFullYear()}`;
    }
    get reasoning() {
        return (this.forecast?.reasoning || []).map((t, idx) => ({ key: idx, text: t }));
    }
    get suggestedAction() {
        return this.forecast?.suggestedAction || '';
    }
    get confidence() {
        return this.forecast?.confidence ?? 0;
    }
    get confidenceLabel() {
        return `Confidence: ${this.confidence} %`;
    }
    get barStyle() {
        return `width: ${Math.min(Math.max(this.confidence, 0), 100)}%;`;
    }

    handleSchedule() {
        this.dispatchEvent(new CustomEvent('scheduleappointment', {
            bubbles: true,
            composed: true,
            detail: { predictedDate: this.forecast?.predictedDate }
        }));
    }
}
