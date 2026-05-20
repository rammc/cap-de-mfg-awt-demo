import { LightningElement, api } from 'lwc';

const FALLBACK_SPECS = [
    'Max. Mähleistung',
    'Akku-Kapazität',
    'Akku-Laufzeit',
    'GPS-Navigation',
    'Lawn-AI Software',
    'Maximale Hangneigung',
    'Lärmpegel',
    'Garantie inklusive',
    'Preis'
];

const FALLBACK_VALUES = {
    'Max. Mähleistung':       { current: '1.000 m²', upgrade: '1.500 m²' },
    'Akku-Kapazität':         { current: '90 Wh',    upgrade: '110 Wh' },
    'Akku-Laufzeit':          { current: '70 min',   upgrade: '95 min' },
    'GPS-Navigation':         { current: 'Nein',     upgrade: 'Nein' },
    'Lawn-AI Software':       { current: 'Nein',     upgrade: 'Nein' },
    'Maximale Hangneigung':   { current: '35 %',     upgrade: '40 %' },
    'Lärmpegel':              { current: '58 dB',    upgrade: '60 dB' },
    'Garantie inklusive':     { current: '12 Monate', upgrade: '24 Monate' },
    'Preis':                  { current: '€1.499,00', upgrade: '€1.999,00' }
};

export default class SpecDiffComparator extends LightningElement {
    @api isOpen = false;
    @api currentProduct;
    @api selectedUpgrade;
    _bound = false;

    get drawerClass() { return this.isOpen ? 'drawer drawer_open' : 'drawer'; }
    get scrimClass() { return this.isOpen ? 'scrim scrim_open' : 'scrim'; }

    get headerText() {
        const cur = this.currentProduct?.name || 'Aktuelles Modell';
        const up = this.selectedUpgrade?.name || 'Upgrade';
        return `${cur} vs. ${up}`;
    }

    get currentImage() { return this.currentProduct?.heroImageUrl; }
    get upgradeImage() { return this.selectedUpgrade?.heroImageUrl; }
    get hasImages() { return !!(this.currentImage || this.upgradeImage); }
    get currentName() { return this.currentProduct?.name || 'Aktuell'; }
    get upgradeName() { return this.selectedUpgrade?.name || 'Upgrade'; }

    get rows() {
        const curSpecs = this._mapSpecs(this.currentProduct?.specs);
        const upSpecs = this._mapSpecs(this.selectedUpgrade?.specs);
        return FALLBACK_SPECS.map((label) => {
            const cur = curSpecs[label]
                ?? FALLBACK_VALUES[label]?.current
                ?? '—';
            const upValue = upSpecs[label]
                ?? FALLBACK_VALUES[label]?.upgrade
                ?? '—';
            const diff = this._diffFromUpgrade(label) || this._inferDiff(cur, upValue);
            return {
                key: label,
                label,
                current: cur,
                upgrade: upValue,
                diffCls: 'diff diff_' + diff,
                diffPrefix: diff === 'up' ? '↑' : diff === 'down' ? '↓' : ''
            };
        });
    }

    _mapSpecs(arr) {
        const out = {};
        (arr || []).forEach((s) => { out[s.label] = s.value; });
        return out;
    }

    _diffFromUpgrade(label) {
        const match = (this.selectedUpgrade?.specs || []).find((s) => s.label === label);
        return match?.diff;
    }

    _inferDiff(current, upgrade) {
        if (current === upgrade) return 'same';
        const a = this._numericish(current);
        const b = this._numericish(upgrade);
        if (a != null && b != null) {
            if (b > a) return 'up';
            if (b < a) return 'down';
        }
        return 'same';
    }

    _numericish(value) {
        if (value == null) return null;
        const n = parseFloat(String(value).replace(/\./g, '').replace(',', '.').replace(/[^\d.-]/g, ''));
        return Number.isFinite(n) ? n : null;
    }

    renderedCallback() {
        if (this.isOpen && !this._bound) {
            this._keydown = (e) => { if (e.key === 'Escape') this._close(); };
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

    handleScrim(event) {
        if (event.target === event.currentTarget) this._close();
    }
    handleClose() { this._close(); }
    handleAddToQuote() {
        this.dispatchEvent(new CustomEvent('addtoquote', {
            detail: { option: this.selectedUpgrade }
        }));
        this._close();
    }
    _close() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}
