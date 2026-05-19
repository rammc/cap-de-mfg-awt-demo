import { LightningElement, api } from 'lwc';

function colorFor(score) {
    if (score >= 80) return { fill: '#3F9E54', opacity: 0.7, status: 'Optimal' };
    if (score >= 60) return { fill: '#F59E0B', opacity: 0.6, status: 'Belastet' };
    return { fill: '#D4351C', opacity: 0.6, status: 'Beschädigt' };
}

export default class LawnHealthMap extends LightningElement {
    @api zones = [];
    @api propertySizeSqm;

    get decoratedZones() {
        return (this.zones || []).map((z) => {
            const c = colorFor(z.healthScore);
            return {
                id: z.id,
                x: z.x,
                y: z.y,
                width: z.width,
                height: z.height,
                healthScore: z.healthScore,
                label: z.label || `Zone ${z.id}`,
                labelX: z.x + z.width / 2,
                labelY: z.y + z.height / 2 + 4,
                scoreY: z.y + z.height / 2 + 18,
                fill: c.fill,
                opacity: c.opacity,
                title: `${z.label || 'Zone ' + z.id} · ${c.status} (${z.healthScore})`
            };
        });
    }

    get zoneCount() {
        return (this.zones || []).length;
    }

    get sizeLabel() {
        return this.propertySizeSqm != null ? `${this.propertySizeSqm} m²` : '—';
    }

    get lastAnalyzed() {
        const d = new Date();
        return `${d.getDate()}.${d.getMonth() + 1}.${d.getFullYear()}`;
    }
}
