import { LightningElement, api } from 'lwc';

export default class HeadlessSyncIndicator extends LightningElement {
    @api syncStatus;

    get mobileLabel() {
        const ms = this.syncStatus?.lastMobileSyncMillis;
        return `Mobile App · synced ${this._formatAgo(ms)}`;
    }

    get portalLabel() {
        return 'Kundenportal · synced live';
    }

    get channelHints() {
        return [
            { key: 'mobile', icon: 'utility:phone_portrait', alt: 'Mobile App' },
            { key: 'portal', icon: 'utility:world', alt: 'Kundenportal' },
            { key: 'crm', icon: 'utility:desktop', alt: 'Service-Cloud Konsole' }
        ];
    }

    _formatAgo(ms) {
        if (!ms) return 'unbekannt';
        const diff = Math.max(0, Date.now() - Number(ms));
        const minutes = Math.floor(diff / 60000);
        if (minutes < 1) return 'vor wenigen Sekunden';
        if (minutes < 60) return `vor ${minutes} min`;
        const hours = Math.floor(minutes / 60);
        if (hours < 24) return `vor ${hours} h`;
        const days = Math.floor(hours / 24);
        return `vor ${days} T`;
    }
}
