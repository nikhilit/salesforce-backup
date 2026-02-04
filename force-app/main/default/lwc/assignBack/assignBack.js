import { LightningElement, api,track } from 'lwc';
import assignWorkOrderBackToPreviousSpoc from '@salesforce/apex/CaseReassignmentController.reassignCaseToPreviousSpoc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AssignBack extends LightningElement {
    @api recordId; 
    @track remarks = '';
    message;
    error;

    handleRemarksChange(event) {
        console.log('this',this.remarks);
        this.remarks = event.target.value;
    }

    handleAssignBack() {
        console.log('recordId',this.recordId);
        assignWorkOrderBackToPreviousSpoc({ caseId: this.recordId, remarks: this.remarks })
            .then(() => {
                this.message = 'Successfully reassigned.';
                this.showToast('Success', this.message, 'success');
                this.closeModal(); // ✅ close modal
            })
            .catch(error => {
                this.error = error.body?.message || error.message;
                this.showToast('Error', this.error, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}