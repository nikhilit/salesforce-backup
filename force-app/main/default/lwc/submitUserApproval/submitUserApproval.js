import { LightningElement, api, track } from 'lwc';
import uploadFile from '@salesforce/apex/OfflineFileUploaderController.uploadFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OfflineFileUploader extends LightningElement {
    @api recordId;
    @track uploadMessage = '';
    fileData;

    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) {
            return;
        }

        const reader = new FileReader();
        reader.onload = () => {
            const base64 = reader.result.split(',')[1];
            this.fileData = {
                filename: file.name,
                base64: base64,
                mimeType: file.type
            };
        };
        reader.readAsDataURL(file);
    }

    handleUpload() {
        if (!this.fileData) {
            this.showToast('Error', 'Please select a file first.', 'error');
            return;
        }

        uploadFile({
            recordId: this.recordId,
            fileName: this.fileData.filename,
            base64Data: this.fileData.base64,
            mimeType: this.fileData.mimeType
        })
        .then(() => {
            this.uploadMessage = 'File uploaded successfully.';
            this.showToast('Success', 'File uploaded successfully.', 'success');
            this.fileData = null;
        })
        .catch(error => {
            this.uploadMessage = 'Error: ' + error.body.message;
            this.showToast('Error', error.body.message, 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}