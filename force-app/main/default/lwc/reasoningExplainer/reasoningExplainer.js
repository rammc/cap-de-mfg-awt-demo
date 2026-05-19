import { LightningElement, api } from 'lwc';

export default class ReasoningExplainer extends LightningElement {
    @api reasoning;

    get headline() {
        return this.reasoning?.headline || 'Warum diese Empfehlungen?';
    }
    get bullets() {
        return (this.reasoning?.bullets || []).map((b, idx) => ({
            key: idx,
            icon: b.icon || 'utility:info',
            text: b.text
        }));
    }
    get confidence() {
        return this.reasoning?.confidence ?? 0;
    }
    get confidenceLabel() {
        return `Confidence: ${this.confidence} %`;
    }
    get barStyle() {
        return `width: ${Math.min(Math.max(this.confidence, 0), 100)}%;`;
    }
}
