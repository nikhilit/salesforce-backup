import { LightningElement, api } from 'lwc';
import updateRemarks from '@salesforce/apex/AS_MassWorkOrderUpdater.updateRemarks';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AsUnallocateService extends LightningElement {

    @api reactiveValue = []; 
    @api selectedIds = [];
    remarks = '';

    unAllocated = false;

    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }

    connectedCallback() {
        if (this.reactiveValue?.length > 0) {
            this.selectedIds = this.reactiveValue;
        }
    }

    handleSubmit() {

        console.log('======this.remarks=====>', this.remarks);
        console.log('======this.selectedIds=====>', JSON.stringify(this.selectedIds) );

        if (!this.remarks) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter remarks before submitting.',
                    variant: 'error',
                })
            );
            return;
        }

        updateRemarks({ workOrderIds: this.selectedIds, remarks: this.remarks })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Remarks updated successfully!',
                    variant: 'success',
                })
            );

            this.unAllocated = true;
            this.selectedIds = [];
            this.reactiveValue = [];
            
        })
        .catch((error) => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating remarks',
                    message: error.body.message,
                    variant: 'error',
                })
            );
        });
    }

    handleCancel() {
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}