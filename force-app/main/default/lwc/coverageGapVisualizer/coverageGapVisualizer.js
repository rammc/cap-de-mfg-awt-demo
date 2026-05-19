import { LightningElement, api } from 'lwc';

const STATUS_META = {
    covered: { icon: 'utility:check', text: 'Abgedeckt', cls: 'tile tile_covered' },
    partial: { icon: 'utility:warning', text: 'Eingeschränkt', cls: 'tile tile_partial' },
    uncovered: { icon: 'utility:close', text: 'Nicht abgedeckt', cls: 'tile tile_uncovered' },
    expiring: { icon: 'utility:clock', text: 'Läuft bald aus', cls: 'tile tile_expiring' }
};

export default class CoverageGapVisualizer extends LightningElement {
    @api coverages = [];

    get tiles() {
        return (this.coverages || []).map((c) => {
            const meta = STATUS_META[c.status] || STATUS_META.uncovered;
            const subText = c.status === 'expiring' && c.expiresInDays
                ? `in ${c.expiresInDays} Tagen`
                : meta.text;
            return {
                key: c.key,
                label: c.label,
                iconName: meta.icon,
                subText,
                cls: meta.cls
            };
        });
    }
}
