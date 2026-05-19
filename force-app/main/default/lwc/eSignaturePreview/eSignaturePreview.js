import { LightningElement, api } from 'lwc';

export default class ESignaturePreview extends LightningElement {
    @api isOpen = false;
    @api contract;
    @api customer;
    @api billingCycle = 'monthly';

    hasStrokes = false;
    _drawing = false;
    _ctx;
    _lastX = 0;
    _lastY = 0;

    get rootClass() {
        return this.isOpen ? 'overlay overlay_open' : 'overlay';
    }

    get summary() {
        if (!this.contract) return '';
        const cycle = this.billingCycle === 'yearly' ? '/Jahr' : '/Monat';
        const price = this.billingCycle === 'yearly'
            ? this.contract.yearlyPrice
            : this.contract.monthlyPrice;
        return `${this.customer || 'Kunde'} · ${this.contract.name} · €${Number(price || 0).toFixed(2).replace('.', ',')}${cycle}`;
    }

    get confirmDisabled() {
        return !this.hasStrokes;
    }

    renderedCallback() {
        if (!this.isOpen) {
            this.hasStrokes = false;
            this._ctx = null;
            return;
        }
        const canvas = this.template.querySelector('canvas');
        if (canvas && !this._ctx) {
            const ratio = window.devicePixelRatio || 1;
            const rect = canvas.getBoundingClientRect();
            canvas.width = rect.width * ratio;
            canvas.height = rect.height * ratio;
            const ctx = canvas.getContext('2d');
            ctx.scale(ratio, ratio);
            ctx.lineCap = 'round';
            ctx.lineJoin = 'round';
            ctx.lineWidth = 2;
            ctx.strokeStyle = '#1F2A37';
            this._ctx = ctx;
        }
    }

    handlePointerDown(event) {
        if (!this._ctx) return;
        this._drawing = true;
        const { x, y } = this._pointer(event);
        this._lastX = x;
        this._lastY = y;
        this._ctx.beginPath();
        this._ctx.moveTo(x, y);
    }

    handlePointerMove(event) {
        if (!this._drawing || !this._ctx) return;
        event.preventDefault();
        const { x, y } = this._pointer(event);
        const midX = (this._lastX + x) / 2;
        const midY = (this._lastY + y) / 2;
        this._ctx.quadraticCurveTo(this._lastX, this._lastY, midX, midY);
        this._ctx.stroke();
        this._lastX = x;
        this._lastY = y;
        if (!this.hasStrokes) {
            this.hasStrokes = true;
        }
    }

    handlePointerUp() {
        this._drawing = false;
    }

    _pointer(event) {
        const canvas = event.currentTarget;
        const rect = canvas.getBoundingClientRect();
        return {
            x: event.clientX - rect.left,
            y: event.clientY - rect.top
        };
    }

    handleClear() {
        if (!this._ctx) return;
        const canvas = this.template.querySelector('canvas');
        this._ctx.clearRect(0, 0, canvas.width, canvas.height);
        this.hasStrokes = false;
    }

    handleScrim(event) {
        if (event.target === event.currentTarget) {
            this.handleCancel();
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleConfirm() {
        if (this.confirmDisabled) return;
        this.dispatchEvent(new CustomEvent('signaturecomplete', {
            detail: { contractId: this.contract?.contractId }
        }));
    }
}
