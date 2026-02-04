import { LightningElement, track, api } from 'lwc';
import createWorkOrders from '@salesforce/apex/WorkOrderCreatorController.createWorkOrders';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class WorkOrderFlowLauncher extends LightningElement {
    @track workOrderId;
    @track error;

    // This makes it available to the Flow
    @api reactiveValue=[];

    connectedCallback() {
        console.log('Flow input reactiveValue:', this.reactiveValue);
        this.createWorkOrderAutomatically();
    }

    createWorkOrderAutomatically() {
    console.log('Calling Apex with reactiveValue:', this.reactiveValue);

    createWorkOrders({ reactiveValue: this.reactiveValue }) 
        .then(result => {
            this.workOrderId = result;
            this.showToast('Success', `Work Order Created: ${result}`, 'success');
        })
        .catch(error => {
            this.error = error.body?.message || 'Failed to create Work Order';
            this.showToast('Error', this.error, 'error');
        });
}


    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}