import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import startProcessing from '@salesforce/apex/CSVBulkController.startProcessing';
import getStatus from '@salesforce/apex/CSVBulkController.getStatus';
import USER_ID from '@salesforce/user/Id';

export default class CsvBulkImporter extends LightningElement {
    @track uploadedFileId;
    @track processingId;
    @track progressPercent = 0;
    @track processedRows = 0;
    @track totalRows = 0;
    @track successCount = 0;
    @track failureCount = 0;
    @track errorMessage;

    // recordId = USER_ID; // ✅ attach to current user

    // handleUploadFinished(event) {
    //     console.log('Upload finished event triggered:', event.detail);
    //     const uploadedFiles = event.detail.files;

    //     console.log('=======uploadedFiles=====>>>',uploadedFiles);

    //     if (uploadedFiles && uploadedFiles.length > 0) {
    //         this.uploadedFileId = uploadedFiles[0].contentVersionId;
    //         console.log('File uploaded successfully, contentVersionId:', this.uploadedFileId);

    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: 'Upload Successful',
    //                 message: `File "${uploadedFiles[0].name}" uploaded successfully.`,
    //                 variant: 'success'
    //             })
    //         );

    //         this.errorMessage = null;
    //         this.processingId = null;
    //         this.progressPercent = 0;
    //     } else {
    //         console.error('Upload finished event triggered but no files found');
    //         this.errorMessage = 'No file uploaded. Please try again.';
    //     }
    // }

    // handleStartImport() {
    //     if (!this.uploadedFileId) {
    //         this.errorMessage = 'Please upload a CSV file first.';
    //         return;
    //     }

    //     console.log('Starting batch for ContentVersion:', this.uploadedFileId);

    //     startProcessing({ contentVersionId: this.uploadedFileId })
    //         .then(result => {
    //             console.log('Batch started. Status record ID:', result);
    //             this.processingId = result;
    //             this.errorMessage = null;
    //             this.pollStatus();
    //         })
    //         .catch(error => {
    //             console.error('Error starting batch:', error);
    //             this.errorMessage =
    //                 (error && error.body && error.body.message) ||
    //                 error.message ||
    //                 'Failed to start import.';
    //         });
    // }

    // pollStatus() {
    //     const poll = () => {
    //         if (!this.processingId) return;
    //         getStatus({ batchJobId: this.processingId })
    //             .then(s => {
    //                 if (s) {
    //                     this.totalRows = s.Total_Rows__c || 0;
    //                     this.processedRows = s.Processed_Rows__c || 0;
    //                     this.successCount = s.Success_Count__c || 0;
    //                     this.failureCount = s.Failure_Count__c || 0;
    //                     this.progressPercent = this.totalRows > 0
    //                         ? Math.round((this.processedRows / this.totalRows) * 100)
    //                         : 0;

    //                     console.log(`Progress: ${this.progressPercent}% (${this.processedRows}/${this.totalRows})`);

    //                     if (s.Status__c !== 'Completed' && s.Status__c !== 'Failed') {
    //                         setTimeout(poll, 2000);
    //                     } else if (s.Status__c === 'Failed') {
    //                         this.errorMessage = 'Processing failed. Check logs or error CSV.';
    //                     }
    //                 }
    //             })
    //             .catch(err => {
    //                 console.error('Error polling status:', err);
    //             });
    //     };
    //     poll();
    // }

    recordId = '001fs000000VA69AAG';

    handleUploadFinished(event) {
        console.log('Upload finished fired:', event.detail);
        const uploadedFiles = event.detail.files;
        if (uploadedFiles && uploadedFiles.length > 0) {
            this.contentVersionId = uploadedFiles[0].contentVersionId;
            this.fileUploaded = true;
            console.log('ContentVersionId:', this.contentVersionId);
        }
    }

    startProcessing() {
        if (!this.contentVersionId) {
            console.error('No ContentVersionId found.');
            return;
        }

        startProcessing({ contentVersionId: this.contentVersionId })
            .then(result => {
                console.log('Processing started:', result);
            })
            .catch(error => {
                console.error('Error starting process:', error);
            });
    }
}