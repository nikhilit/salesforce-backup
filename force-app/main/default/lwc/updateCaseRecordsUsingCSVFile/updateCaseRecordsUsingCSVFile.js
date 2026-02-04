import { LightningElement, track } from 'lwc';
import processCSV from '@salesforce/apex/UpdateCaseRecordsUsingCSVContr.processCSV';

export default class UpdateCaseRecordsUsingCSVFile extends LightningElement {
    @track showSpinner = false;

    async handleUploadFinished(event) {
        this.showSpinner = true;

        const uploadedFile = event.detail.files[0];
        const fileId = uploadedFile.documentId;

        try {
            const result = await processCSV({ contentDocumentId: fileId });

            this.showSpinner = false;
            alert(result);

        } catch (error) {
            this.showSpinner = false;
            console.error(error);
            alert('Error: ' + error.body.message);
        }
    }
}