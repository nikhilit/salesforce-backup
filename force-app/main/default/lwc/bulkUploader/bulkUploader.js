import { LightningElement, api, track } from 'lwc';
import startBulkInsert from '@salesforce/apex/BulkCsvUploadController.startBulkInsert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BulkCsvUploader extends LightningElement {

    @api recordId;              // can be any record if needed; for File Upload context
    @track jobMessage;
    @track isLoading = false;
    targetObject = '';

    handleObjectChange(event){
        this.targetObject = event.target.value;
    }

    async handleUploadFinished(event){
        if(!this.targetObject){
            this.showToast('Error','Please enter the Target Object API Name first','error');
            return;
        }

        const uploadedFiles = event.detail.files;
        if(!uploadedFiles || uploadedFiles.length === 0){
            this.showToast('Error','No file uploaded.','error');
            return;
        }

        const contentDocumentId = uploadedFiles[0].documentId;

        this.isLoading = true;
        try {
            const result = await startBulkInsert({
                contentDocumentId: contentDocumentId,
                targetObjectApiName: this.targetObject
            });
            this.jobMessage = result;
            this.showToast('Success','Bulk insert job created successfully','success');
        } catch (error) {
            this.showToast('Error', error.body ? error.body.message : error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant){
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}