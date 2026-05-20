import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { publish, MessageContext } from 'lightning/messageService';
import HIGHLIGHT_CHANNEL from '@salesforce/messageChannel/VBOT_HighlightChannel__c';

const PROMPTS = {
    warranty: [
        { id: 'coverage_gaps', label: 'Zeige mir Coverage-Lücken für dieses Asset', target: 'coverageGapVisualizer' },
        { id: 'best_tier', label: 'Welcher Vertragstier passt am besten?', target: 'contractOptionCard' },
        { id: 'warranty_end', label: 'Wann läuft die aktuelle Garantie ab?', target: 'coverageGapVisualizer' }
    ],
    upgrades: [
        { id: 'usage_based', label: 'Empfehle Upgrades basierend auf Nutzungsmustern', target: 'upgradeRecommendationGrid' },
        { id: 'customer_pref', label: 'Was würde der Kunde am ehesten kaufen?', target: 'reasoningExplainer' },
        { id: 'compare', label: 'Vergleiche Akku-Upgrade vs. Modell-Upgrade', target: 'reasoningExplainer' }
    ],
    telemetry: [
        { id: 'next_maintenance', label: 'Wann ist die nächste Wartung fällig?', target: 'predictiveMaintenanceCard' },
        { id: 'battery_decline', label: 'Warum sinkt die Akku-Leistung?', target: 'usageTimelineChart' },
        { id: 'firmware', label: 'Sollte ich ein Firmware-Update vorschlagen?', target: 'predictiveMaintenanceCard' }
    ]
};

const RESPONSES = {
    warranty: {
        coverage_gaps: 'Aktuell sind Akku, Hardware und Sensoren nicht abgedeckt. Software-Support endet in 90 Tagen. Ich empfehle VerdantCare Plus.',
        best_tier: 'Basierend auf Nutzungsintensität und Battery-Health-Verlauf passt VerdantCare Plus am besten – deckt alle aktuellen Risiken zu €9,99/Monat.',
        warranty_end: 'Die aktuelle Garantie (24M Hardware) endet am 15. März 2026 – in 90 Tagen.'
    },
    upgrades: {
        usage_based: 'Basierend auf 1.200 m² aktueller Mähfläche und steigender Tendenz empfehle ich das C500-Modell (Match-Score 86 %).',
        customer_pref: 'Familie Schmidt hat in der App häufig „Schwer erreichbare Zonen" als Issue gemeldet – das X800 mit GPS würde das lösen.',
        compare: 'Akku-Upgrade kostet €249, hebt aber nur die Laufzeit. Modell-Upgrade C500 kostet €1.999, erweitert Coverage UND erhöht Mähleistung.'
    },
    telemetry: {
        next_maintenance: 'Predictive-Maintenance: Akku-Tausch + Sensor-Kalibrierung in 6 Wochen. Confidence 82 %.',
        battery_decline: 'Akku-Health bei 78 %, lineare Degradation seit Tag 14. Voraussichtliche Ursache: Tiefentladungen während Regenphasen.',
        firmware: 'Firmware 3.4.1 ist aktuell, kein Update verfügbar. Nächste Major-Version 4.0 in Q3 2026 erwartet.'
    }
};

const CONTEXT_TITLE = {
    warranty: 'VerdantBot Service Agent',
    upgrades: 'VerdantBot Sales Agent',
    telemetry: 'VerdantBot Care Agent'
};

export default class AgentNudgeBubble extends LightningElement {
    @api recordId;
    @api context = 'auto';

    isOpen = false;
    showTyping = false;
    history = [];
    detectedContext;

    @wire(MessageContext) messageContext;

    @wire(getRecord, { recordId: '$recordId', layoutTypes: ['Compact'] })
    wiredRecord({ data, error }) {
        if (error || !data) return;
        const apiName = data.apiName;
        if (this.context === 'auto') {
            this.detectedContext = apiName === 'Asset' ? 'telemetry' : 'warranty';
        }
    }

    get resolvedContext() {
        if (this.context && this.context !== 'auto') return this.context;
        return this.detectedContext || 'warranty';
    }

    get bubbleClass() {
        return this.isOpen ? 'bubble bubble_open' : 'bubble';
    }
    get panelClass() {
        return this.isOpen ? 'panel panel_open' : 'panel';
    }
    get showBubble() {
        return !this.isOpen;
    }

    get agentTitle() {
        return CONTEXT_TITLE[this.resolvedContext] || 'VerdantBot Agent';
    }

    get prompts() {
        return PROMPTS[this.resolvedContext] || [];
    }

    get historyItems() {
        return this.history;
    }

    handleOpen() {
        if (!this.isOpen) {
            this.isOpen = true;
            if (this.history.length === 0) {
                this.history = [{
                    id: 'greet',
                    cls: 'msg msg_agent',
                    text: 'Hi Christopher, ich habe ein paar Vorschläge für diesen Kontext.'
                }];
            }
        }
    }

    handleClose() {
        this.isOpen = false;
    }

    handlePromptClick(event) {
        const id = event.currentTarget.dataset.id;
        const prompt = (this.prompts || []).find((p) => p.id === id);
        if (!prompt) return;

        this.history = [
            ...this.history,
            { id: 'u-' + Date.now(), cls: 'msg msg_user', text: prompt.label }
        ];
        this.showTyping = true;

        // Publish highlight ASAP so the wrapper can pre-arm the animation.
        publish(this.messageContext, HIGHLIGHT_CHANNEL, {
            target: prompt.target,
            context: this.resolvedContext
        });

        setTimeout(() => {
            this.showTyping = false;
            const answer = RESPONSES[this.resolvedContext]?.[id] || 'Hier ist meine Empfehlung …';
            this.history = [
                ...this.history,
                { id: 'a-' + Date.now(), cls: 'msg msg_agent', text: answer }
            ];
        }, 1500);
    }
}
