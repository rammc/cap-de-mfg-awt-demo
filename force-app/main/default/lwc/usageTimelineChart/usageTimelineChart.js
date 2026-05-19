import { LightningElement, api } from 'lwc';

const CHART_W = 800;
const CHART_H = 240;
const PAD_L = 50;
const PAD_R = 20;
const PAD_T = 20;
const PAD_B = 32;

const METRIC_META = {
    batteryHealth: { label: 'Akku', unit: '%', minOverride: 0, maxOverride: 100 },
    mowedArea: { label: 'Fläche', unit: 'm²' },
    errorCount: { label: 'Fehler', unit: '' }
};

const MONTH_LABELS = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];

export default class UsageTimelineChart extends LightningElement {
    @api points = [];
    @api range = '30d';
    selectedMetric = 'batteryHealth';
    hoveredIdx = -1;

    get viewBox() {
        return `0 0 ${CHART_W} ${CHART_H}`;
    }

    get metricLabel() {
        return METRIC_META[this.selectedMetric]?.label || '';
    }

    get rangePills() {
        return ['7d', '30d', '90d'].map((r) => ({
            key: r,
            label: r === '7d' ? '7T' : r === '30d' ? '30T' : '90T',
            variant: r === this.range ? 'brand' : 'neutral',
            value: r
        }));
    }

    get metricButtons() {
        return ['batteryHealth', 'mowedArea', 'errorCount'].map((m) => ({
            key: m,
            label: METRIC_META[m].label,
            variant: m === this.selectedMetric ? 'brand' : 'neutral',
            value: m
        }));
    }

    get series() {
        const values = (this.points || []).map((p) => Number(p[this.selectedMetric] ?? 0));
        const meta = METRIC_META[this.selectedMetric];
        let min = meta.minOverride ?? Math.min(...values, 0);
        let max = meta.maxOverride ?? Math.max(...values, 1);
        if (max - min < 1) max = min + 1;
        const n = values.length;
        const stepX = n > 1 ? (CHART_W - PAD_L - PAD_R) / (n - 1) : 0;
        const scaleY = (CHART_H - PAD_T - PAD_B) / (max - min);

        return values.map((v, i) => {
            const x = PAD_L + i * stepX;
            const y = CHART_H - PAD_B - (v - min) * scaleY;
            const dp = this.points[i];
            return {
                x: x.toFixed(1),
                y: y.toFixed(1),
                value: v,
                index: i,
                date: dp?.dateValue,
                tooltipText: `${this._formatDate(dp?.dateValue)} · ${this._formatValue(v)}`
            };
        });
    }

    get polylinePoints() {
        return this.series.map((p) => `${p.x},${p.y}`).join(' ');
    }

    get polygonPoints() {
        const s = this.series;
        if (!s.length) return '';
        const baseline = (CHART_H - PAD_B).toFixed(1);
        const line = s.map((p) => `${p.x},${p.y}`).join(' ');
        return `${s[0].x},${baseline} ${line} ${s[s.length - 1].x},${baseline}`;
    }

    get yAxisLines() {
        const meta = METRIC_META[this.selectedMetric];
        const values = (this.points || []).map((p) => Number(p[this.selectedMetric] ?? 0));
        const min = meta.minOverride ?? Math.min(...values, 0);
        const max = meta.maxOverride ?? Math.max(...values, 1);
        const ticks = [0, 0.25, 0.5, 0.75, 1];
        return ticks.map((t) => {
            const val = min + (max - min) * (1 - t);
            const y = PAD_T + t * (CHART_H - PAD_T - PAD_B);
            return {
                key: t,
                y: y.toFixed(1),
                xStart: PAD_L,
                xEnd: CHART_W - PAD_R,
                label: this._formatTickLabel(val)
            };
        });
    }

    get xAxisLabels() {
        const s = this.series;
        if (!s.length) return [];
        const step = Math.max(1, Math.floor(s.length / 5));
        const out = [];
        for (let i = 0; i < s.length; i += step) {
            out.push({
                key: i,
                x: s[i].x,
                y: (CHART_H - PAD_B + 16).toFixed(1),
                label: this._formatDateShort(s[i].date)
            });
        }
        return out;
    }

    get average() {
        const values = (this.points || []).map((p) => Number(p[this.selectedMetric] ?? 0));
        if (!values.length) return '—';
        const sum = values.reduce((a, b) => a + b, 0);
        return this._formatValue(sum / values.length);
    }

    get trendDirection() {
        const values = (this.points || []).map((p) => Number(p[this.selectedMetric] ?? 0));
        if (values.length < 2) return 'flat';
        const first = values[0];
        const last = values[values.length - 1];
        if (last > first * 1.02) return 'up';
        if (last < first * 0.98) return 'down';
        return 'flat';
    }

    get trendIcon() {
        return this.trendDirection === 'flat' ? 'utility:right' : 'utility:trending';
    }
    get trendVariant() {
        if (this.trendDirection === 'up') return 'success';
        if (this.trendDirection === 'down') return 'error';
        return 'inverse';
    }

    get tooltip() {
        if (this.hoveredIdx < 0 || this.hoveredIdx >= this.series.length) return null;
        const p = this.series[this.hoveredIdx];
        const offsetX = Number(p.x) > CHART_W - 160 ? -130 : 10;
        return {
            x: (Number(p.x) + offsetX).toFixed(1),
            y: (Number(p.y) - 40).toFixed(1),
            text: p.tooltipText
        };
    }

    handleMetricClick(event) {
        const metric = event.currentTarget.dataset.metric;
        if (metric && metric !== this.selectedMetric) {
            this.selectedMetric = metric;
            this.dispatchEvent(new CustomEvent('metricchange', { detail: { metric } }));
        }
    }

    handleRangeClick(event) {
        const range = event.currentTarget.dataset.range;
        if (range && range !== this.range) {
            this.dispatchEvent(new CustomEvent('rangechange', {
                bubbles: true, composed: true,
                detail: { range }
            }));
        }
    }

    handlePointEnter(event) {
        this.hoveredIdx = Number(event.currentTarget.dataset.idx);
    }
    handlePointLeave() {
        this.hoveredIdx = -1;
    }

    _formatValue(v) {
        const meta = METRIC_META[this.selectedMetric];
        const n = Number(v).toFixed(meta.unit === '%' ? 1 : 0);
        return meta.unit ? `${n} ${meta.unit}` : n;
    }
    _formatTickLabel(v) {
        const meta = METRIC_META[this.selectedMetric];
        const n = Math.round(Number(v));
        return meta.unit === '%' ? `${n} %` : meta.unit ? `${n}` : `${n}`;
    }
    _formatDate(d) {
        if (!d) return '';
        const date = d instanceof Date ? d : new Date(d);
        if (Number.isNaN(date.getTime())) return '';
        return `${date.getDate()}. ${MONTH_LABELS[date.getMonth()]} ${date.getFullYear()}`;
    }
    _formatDateShort(d) {
        if (!d) return '';
        const date = d instanceof Date ? d : new Date(d);
        if (Number.isNaN(date.getTime())) return '';
        return `${date.getDate()}. ${MONTH_LABELS[date.getMonth()]}`;
    }
}
