import { LightningElement, api } from 'lwc';
import processCase from '@salesforce/apex/CaseActionController.processCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class CaseActionButton extends LightningElement {
    @api recordId;
    remarks = '';
    isLoading = false;

    @api invoke() {
        // Automatically open UI; or do nothing if using modal
    }

    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }

    handleSubmit() {
        // Prevent multiple submissions
        if (this.isLoading) {
            return;
        }

        if (!this.recordId) {
            this.showToast('Error', 'No Case Id found.', 'error');
            return;
        }

        // Set loading state and disable button
        this.isLoading = true;
        const submitButton = this.template.querySelector('lightning-button');
        if (submitButton) {
            submitButton.disabled = true;
            submitButton.label = 'Processing...';
        }

        processCase({ caseId: this.recordId, remarks: this.remarks })
            .then(() => {
                getRecordNotifyChange([{recordId: this.recordId}]);
                this.showToast('Success', 'Case updated.', 'success');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.showToast('Error', this.reduceError(error), 'error');
            })
            .finally(() => {
                // Reset loading state
                this.isLoading = false;
                
                // Re-enable button
                const button = this.template.querySelector('lightning-button');
                if (button) {
                    button.disabled = false;
                    button.label = 'Submit';
                }
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    reduceError(error) {
        if (Array.isArray(error.body)) {
            return error.body.map(e => e.message).join(', ');
        } else if (typeof error.body?.message === 'string') {
            return error.body.message;
        }
        return 'Unknown error';
    }
}