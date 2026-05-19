import { LightningElement, api } from 'lwc';

const FEATURES = [
    { key: 'software',      label: 'Software & App-Support' },
    { key: 'battery',       label: 'Akku-Garantie' },
    { key: 'sensors',       label: 'Sensorik-Garantie' },
    { key: 'hardware',      label: 'Hardware-Austausch' },
    { key: 'response',      label: 'Reaktionszeit',    value: { Basic: '72h', Plus: '24h', Premium: '4h' } },
    { key: 'onsite',        label: 'On-Site-Service',  value: { Basic: '—',   Plus: 'Inklusive', Premium: 'Inklusive' } },
    { key: 'loaner',        label: 'Ersatzgerät',      value: { Basic: '—',   Plus: '—',         Premium: 'Inklusive' } },
    { key: 'inspection',    label: 'Jahresinspektion', value: { Basic: '—',   Plus: '1×/Jahr',   Premium: '2×/Jahr' } },
    { key: 'firmware',      label: 'Firmware-Updates', value: { Basic: 'Manuell', Plus: 'Automatisch', Premium: 'Beta-Access' } },
    { key: 'hotline',       label: 'Telefon-Hotline',  value: { Basic: 'Mo–Fr 9–17', Plus: 'Mo–Fr 8–20', Premium: '24/7' } }
];

const COVERAGE_KEYS = new Set(['software', 'battery', 'sensors', 'hardware']);

export default class ContractComparisonDrawer extends LightningElement {
    @api isOpen = false;
    @api contracts = [];
    _bound = false;

    get drawerClass() {
        return this.isOpen ? 'drawer drawer_open' : 'drawer';
    }

    get scrimClass() {
        return this.isOpen ? 'scrim scrim_open' : 'scrim';
    }

    get tierColumns() {
        return (this.contracts || []).map((c) => ({
            key: c.contractId,
            tier: c.tier,
            name: c.name,
            isRecommended: !!c.isRecommended,
            cls: c.isRecommended ? 'col col_recommended' : 'col',
            coverageByKey: this._coverageMap(c)
        }));
    }

    get featureRows() {
        const cols = this.tierColumns;
        return FEATURES.map((f) => ({
            key: f.key,
            label: f.label,
            cells: cols.map((col) => this._cellFor(f, col))
        }));
    }

    _coverageMap(contract) {
        const out = {};
        (contract.coverages || []).forEach((c) => { out[c.key] = c; });
        return out;
    }

    _cellFor(feature, col) {
        if (COVERAGE_KEYS.has(feature.key)) {
            const c = col.coverageByKey[feature.key];
            const covered = c && c.status === 'covered';
            return {
                key: `${col.key}-${feature.key}`,
                isIcon: true,
                iconName: covered ? 'utility:check' : 'utility:close',
                iconVariant: covered ? 'success' : 'error',
                text: covered ? 'Abgedeckt' : 'Nicht abgedeckt',
                cls: col.cls + ' cell ' + (covered ? 'cell_yes' : 'cell_no')
            };
        }
        const map = feature.value || {};
        const txt = map[col.tier] || '—';
        return {
            key: `${col.key}-${feature.key}`,
            isIcon: false,
            text: txt,
            cls: col.cls + ' cell'
        };
    }

    renderedCallback() {
        if (this.isOpen && !this._bound) {
            this._keydown = (e) => { if (e.key === 'Escape') this._dispatchClose(); };
            window.addEventListener('keydown', this._keydown);
            this._bound = true;
        } else if (!this.isOpen && this._bound) {
            window.removeEventListener('keydown', this._keydown);
            this._bound = false;
        }
    }

    disconnectedCallback() {
        if (this._bound) {
            window.removeEventListener('keydown', this._keydown);
            this._bound = false;
        }
    }

    handleClose() {
        this._dispatchClose();
    }

    handleScrim(event) {
        if (event.target === event.currentTarget) {
            this._dispatchClose();
        }
    }

    _dispatchClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}
