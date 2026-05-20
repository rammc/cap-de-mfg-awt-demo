import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import resetWorkOrderDemo from '@salesforce/apex/DemoResetController.resetWorkOrderDemo';

export default class DemoResetAction extends LightningElement {
    @api recordId;
    busy = false;

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleConfirm() {
        this.busy = true;
        try {
            const message = await resetWorkOrderDemo({ workOrderId: this.recordId });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Demo zurückgesetzt',
                message: message || 'Status, Telemetry und Vertrag sind wieder im Initial-Zustand.',
                variant: 'success'
            }));
        } catch (err) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Reset fehlgeschlagen',
                message: err?.body?.message || err?.message || 'Unbekannter Fehler.',
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.busy = false;
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }
}
