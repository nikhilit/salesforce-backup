import { LightningElement, api } from 'lwc';
import handleRepeatCase from '@salesforce/apex/RepeatCaseController.handleRepeatCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RepeatCaseLwc extends LightningElement {
    @api recordId;
    internalComment = '';
    isLoading = false;

    handleCommentChange(event) {
        this.internalComment = event.target.value;
    }

    handleSubmit() {
        this.isLoading = true;
        handleRepeatCase({ currentCaseId: this.recordId, internalComment: this.internalComment })
            .then(result => {
                this.isLoading = false;
                this.showToast('Success', 'Repeat case action completed successfully.', 'success');
                this.resetForm(); // <-- Reset after submit
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', error.body && error.body.message ? error.body.message : 'An error occurred.', 'error');
            });
    }

    resetForm() {
        this.internalComment = '';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}