import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const STORAGE_LAST = 'vbot_easter_last_trigger';
const STORAGE_TOTAL = 'vbot_easter_total_finds';
const STORAGE_CLICK = 'vbot_easter_robot_clicked';
const COOLDOWN_MS = 8000;

export default class VerdantBotEasterEgg extends LightningElement {
    isActive = false;
    phase = '';
    showSpeech = false;
    clicked = false;
    _boundHandler;
    _phaseTimers = [];
    _reducedMotion = false;

    connectedCallback() {
        this._boundHandler = (event) => this._handleDriveBy(event);
        window.addEventListener('verdantbotdriveby', this._boundHandler);
        try {
            this._reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        } catch (_) {
            this._reducedMotion = false;
        }
    }

    disconnectedCallback() {
        if (this._boundHandler) {
            window.removeEventListener('verdantbotdriveby', this._boundHandler);
            this._boundHandler = null;
        }
        this._clearTimers();
    }

    get containerClass() {
        let cls = 'vbot-mower-container';
        if (this.phase) cls += ` is-${this.phase}`;
        if (this.clicked) cls += ' is-paused';
        return cls;
    }

    get trailClass() {
        return this.phase === 'cleanup' ? 'vbot-trail vbot-trail_fading' : 'vbot-trail';
    }

    _handleDriveBy() {
        if (this.isActive) return;

        const now = Date.now();
        const last = Number(this._read(STORAGE_LAST) || 0);
        if (now - last < COOLDOWN_MS) {
            return;
        }
        this._write(STORAGE_LAST, String(now));

        const total = Number(this._read(STORAGE_TOTAL) || 0) + 1;
        this._write(STORAGE_TOTAL, String(total));

        if (this._reducedMotion) {
            this.dispatchEvent(new ShowToastEvent({
                title: '🌱 Easter Egg gefunden',
                message: 'Du hast den VerdantBot entdeckt.',
                variant: 'success'
            }));
            return;
        }

        if (total === 1) {
            this.dispatchEvent(new ShowToastEvent({
                title: '🌱 Du hast den VerdantBot gefunden!',
                message: 'Klick ihn mitten in der Drehung an für einen geheimen Gruß.',
                variant: 'success'
            }));
        } else if (total === 3) {
            this.dispatchEvent(new ShowToastEvent({
                title: '🌱 Du hast den VerdantBot dreimal entdeckt!',
                message: 'Erzähl es weiter.',
                variant: 'success'
            }));
        }

        this._playAnimation();
    }

    _playAnimation() {
        this._clearTimers();
        this.isActive = true;
        this.clicked = false;
        this.showSpeech = false;
        this.phase = 'entrance';

        this._phaseTimers.push(setTimeout(() => { this.phase = 'mid-spin'; }, 800));
        this._phaseTimers.push(setTimeout(() => {
            if (!this.clicked) this.phase = 'exit';
        }, 1800));
        this._phaseTimers.push(setTimeout(() => { this.phase = 'cleanup'; }, 3500));
        this._phaseTimers.push(setTimeout(() => {
            this.isActive = false;
            this.phase = '';
            this.showSpeech = false;
            this.clicked = false;
        }, 4500));
    }

    handleRobotClick() {
        if (this.phase !== 'mid-spin' || this.clicked) return;
        this.clicked = true;
        this.showSpeech = true;

        const clicked = Number(this._read(STORAGE_CLICK) || 0) + 1;
        this._write(STORAGE_CLICK, String(clicked));
        if (clicked === 1) {
            this.dispatchEvent(new ShowToastEvent({
                title: '🌱 Geheimer Doppel-Easter-Egg-Klick freigeschaltet!',
                message: 'Du hast den VerdantBot mitten im Spin erwischt.',
                variant: 'success'
            }));
        }

        this._clearTimers();
        this._phaseTimers.push(setTimeout(() => {
            this.showSpeech = false;
            this.phase = 'exit';
        }, 1000));
        this._phaseTimers.push(setTimeout(() => { this.phase = 'cleanup'; }, 2700));
        this._phaseTimers.push(setTimeout(() => {
            this.isActive = false;
            this.phase = '';
            this.clicked = false;
        }, 3700));
    }

    _clearTimers() {
        this._phaseTimers.forEach((t) => clearTimeout(t));
        this._phaseTimers = [];
    }

    _read(key) {
        try {
            return window.localStorage.getItem(key);
        } catch (_) {
            return null;
        }
    }
    _write(key, value) {
        try {
            window.localStorage.setItem(key, value);
        } catch (_) {
            /* ignore quota / privacy mode */
        }
    }
}
