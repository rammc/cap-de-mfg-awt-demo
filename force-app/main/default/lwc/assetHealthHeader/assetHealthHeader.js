import { LightningElement, api } from 'lwc';

const TREND_ICON = { up: 'utility:trending', down: 'utility:trending', flat: 'utility:right' };
const TREND_VARIANT = { up: 'success', down: 'error', flat: 'inverse' };
const DONUT_CIRCUMFERENCE = 226;

export default class AssetHealthHeader extends LightningElement {
    @api kpis = [];

    handleEasterTrigger() {
        try {
            window.dispatchEvent(new CustomEvent('verdantbotdriveby', {
                detail: { triggerSource: 'assetHealthHeader' }
            }));
        } catch (_) { /* ignore */ }
    }

    get tiles() {
        return (this.kpis || []).map((k) => {
            const isBattery = k.key === 'battery';
            const trend = k.trend || 'flat';
            const donutPercent = Math.min(Math.max(k.donutPercent ?? 0, 0), 100);
            const dashOffset = DONUT_CIRCUMFERENCE - (DONUT_CIRCUMFERENCE * donutPercent) / 100;
            return {
                key: k.key,
                label: k.label,
                value: k.value,
                unit: k.unit || '',
                trend,
                trendIcon: TREND_ICON[trend] || 'utility:right',
                trendVariant: TREND_VARIANT[trend] || 'inverse',
                showDonut: isBattery,
                donutDashOffset: dashOffset,
                donutText: `${k.value}${k.unit || ''}`,
                statusPill: k.key === 'firmware'
                    ? { label: 'Aktuell', cls: 'pill pill_ok' } : null,
                cls: 'tile tile_' + k.key
            };
        });
    }
}
