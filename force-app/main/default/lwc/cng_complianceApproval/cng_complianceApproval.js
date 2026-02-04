import { LightningElement, api } from 'lwc';
import updateStatus from '@salesforce/apex/CNG_ProfileCardController.updateStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';

export default class ApprovalButtons extends LightningElement {
    @api recordId;

    handleApprove() {
        this.updateRecordStatus('Approved');
    }

    handleReject() {
        this.updateRecordStatus('Rejected');
    }

    updateRecordStatus(statusValue) {
        updateStatus({
            recordId: this.recordId,
            statusValue: statusValue
        })
        .then(() => {
            this.showToast('Success', `Status updated to ${statusValue}`, 'success');
                this.dispatchEvent(new RefreshEvent());

        })
        .catch(error => {
            this.showToast(
                'Error',
                error.body?.message || 'Failed to update status',
                'error'
            );
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