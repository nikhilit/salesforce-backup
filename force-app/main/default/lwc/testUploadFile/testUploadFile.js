import { LightningElement, track } from 'lwc';
import uploadFile from '@salesforce/apex/OfflineFileUploaderController.uploadFile';

export default class TestUploadFile extends LightningElement {

    @track recordId = '';
    fileName;
    base64Data;
    mimeType;
    isUploading = false;
    message;

    handleRecordIdChange(event) {
        this.recordId = event.target.value;
    }

    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        this.fileName = file.name;
        this.mimeType = file.type; // e.g. application/pdf, image/png

        const reader = new FileReader();
        reader.onload = () => {
            const base64Marker = 'base64,';
            const dataStart = reader.result.indexOf(base64Marker) + base64Marker.length;
            this.base64Data = reader.result.substring(dataStart);

            // Optional offline caching:
            // localStorage.setItem('offlineFile',
            //   JSON.stringify({ recordId: this.recordId, fileName: this.fileName,
            //                   base64Data: this.base64Data, mimeType: this.mimeType }));
        };
        reader.readAsDataURL(file);
    }

    handleUpload() {
        if (!this.recordId || !this.base64Data) {
            this.message = 'Please select a file and enter a record Id.';
            return;
        }

        this.isUploading = true;
        this.message = '';

        uploadFile({
            recordId: this.recordId,
            fileName: this.fileName,
            base64Data: this.base64Data,
            mimeType: this.mimeType
        })
        .then(() => {
            this.message = '✅ File upload queued successfully!';
            this.isUploading = false;
        })
        .catch(error => {
            this.message = '❌ Error: ' + (error.body ? error.body.message : error);
            this.isUploading = false;
        });
    }
}