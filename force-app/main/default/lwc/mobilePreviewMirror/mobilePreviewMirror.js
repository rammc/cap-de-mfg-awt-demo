import { LightningElement, api } from 'lwc';

const DONUT_CIRCUMFERENCE = 339;

function colorFor(score) {
    if (score >= 80) return { fill: '#3F9E54', opacity: 0.75 };
    if (score >= 60) return { fill: '#F59E0B', opacity: 0.7 };
    return { fill: '#D4351C', opacity: 0.7 };
}

export default class MobilePreviewMirror extends LightningElement {
    @api mirrorData;

    get batteryPercent() {
        const v = Number(this.mirrorData?.batteryHealth ?? 0);
        return Math.round(v);
    }
    get batteryDashOffset() {
        const v = Math.min(Math.max(this.batteryPercent, 0), 100);
        return DONUT_CIRCUMFERENCE - (DONUT_CIRCUMFERENCE * v) / 100;
    }
    get batteryLabel() {
        return `${this.batteryPercent} %`;
    }
    get mowedTodayLabel() {
        const v = this.mirrorData?.mowedToday;
        return v != null ? `${v} m²` : '—';
    }
    get nextMowLabel() {
        return this.mirrorData?.nextMow || '—';
    }
    get contractName() {
        return this.mirrorData?.contractName || 'VerdantCare';
    }
    get contractDays() {
        return this.mirrorData?.contractExpiresInDays ?? 0;
    }
    get contractText() {
        return `${this.contractName} läuft in ${this.contractDays} Tagen ab`;
    }

    handleEasterTrigger() {
        try {
            window.dispatchEvent(new CustomEvent('verdantbotdriveby', {
                detail: { triggerSource: 'mobilePreviewMirror' }
            }));
        } catch (_) { /* ignore */ }
    }

    get zones() {
        return (this.mirrorData?.lawnZones || []).map((z) => {
            const c = colorFor(z.healthScore);
            return {
                id: z.id,
                x: z.x,
                y: z.y,
                width: z.width,
                height: z.height,
                fill: c.fill,
                opacity: c.opacity
            };
        });
    }
}
