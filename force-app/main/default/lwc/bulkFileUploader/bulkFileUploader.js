import { LightningElement, track, wire, api } from 'lwc';
import uploadFileToServer from '@salesforce/apex/AS_BulkFileUploadHandler.uploadFileToServer';
import pollJobProgress from '@salesforce/apex/AS_BulkJobMonitor.pollJobProgress';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { getPicklistValues } from "lightning/uiObjectInfoApi";
// import MODE_FIELD from "@salesforce/schema/BulkImportStatus__c.Mode__c";
// import Default_recordTypeId from "@salesforce/label/c.Default_recordTypeId";

export default class BulkFileUploader extends NavigationMixin(
    LightningElement
) {

    @api defaultModuleValue;
    get moduleLabel() {
        return this.defaultModuleValue || '—';
    }
    get cardTitle() {
        return `Bulk XLS Upload - ${this.moduleLabel}`;
    }
    // recordTypeId = Default_recordTypeId;
    // value = '';

    // _options = [];

    // @wire(getPicklistValues, {
    //     recordTypeId: "$recordTypeId",
    //     fieldApiName: MODE_FIELD
    // })
    // picklistResults({ error, data }) {
    //     if (data) {
    //         this._options = data.values.map(v => ({
    //             label: v.label,
    //             value: v.value
    //         }));

    //         if (!this.value) {
    //             this.value = 'Collect360';
    //         }
    //     } else {
    //         this._options = [];
    //         console.log('error:', JSON.stringify(error));
    //     }
    // }

    // get options() {
    //     return this._options;
    // }

    // handleChange(event) {
    //     this.value = event.detail.value;
    // }

    state = {
        isUploading: false,
        isProcessing: false,
        progressMessage: '',
        jobProgress: 0,
        jobMessage: '',
        bulkImportId: null,
        isComplete: false,
    };

    pollingInterval;

    handleUploadFinished(event) {
        const files = event.detail.files;

        if (!files || files.length === 0) {
            this.state = { ...this.state, progressMessage: 'No file uploaded' };
            return;
        }

        const contentDocumentId = files[0].documentId;
        const mode = this.defaultModuleValue;

        // Start upload
        this.state = {
            ...this.state,
            isUploading: true,
            progressMessage: 'Uploading file...'
        };

        uploadFileToServer({ contentDocumentId, mode })
            .then(result => {
                this.state = {
                    ...this.state,
                    bulkImportId: result?.bulkImportId,
                    isUploading: false,
                    isProcessing: true,
                    progressMessage: 'Processing file...'
                };

                this.startPolling();
            })
            .catch(error => {
                const errorMessage =
                    error?.body?.message ||
                    error?.message ||
                    'Unexpected error occurred. Please try again later.';
                const maxLength = 255;
                const trimmedMessage = errorMessage?.substring(0, maxLength);
                this.state = {
                    ...this.state,
                    isProcessing: false,
                    progressMessage: `Error: ${trimmedMessage}`
                };
            });
    }

    startPolling() {
        this.pollingInterval = setInterval(async () => {
            try {
                const result = await pollJobProgress({
                    bulkImportId: this.state.bulkImportId
                })

                // Update job progress + message
                this.state = {
                    ...this.state,
                    jobProgress: result.progress,
                    jobMessage: result.message
                };

                // Stop polling when job is finished
                const TERMINAL_STATUSES = ['JobComplete', 'Failed', 'Aborted', 'ERROR'];
                const isTerminal = TERMINAL_STATUSES.includes(result.status);
                // const isComplete = result.progress >= 100;

                if (isTerminal) {
                    clearInterval(this.pollingInterval);

                    this.state = {
                        ...this.state,
                        isProcessing: false,
                        isComplete: true,
                        progressMessage:
                            result.status === 'JobComplete'
                                ? '✅ Upload Complete!'
                                : `⚠️ Job ended with status: ${result.status}`
                    };
                }
            } catch (error) {
                clearInterval(this.pollingInterval);

                const errorMessage =
                    error?.body?.message ||
                    error?.message ||
                    'Unexpected error occurred. Please try again later.';

                const maxLength = 255;
                const trimmedMessage = errorMessage?.substring(0, maxLength);
                this.state = {
                    ...this.state,
                    isComplete: true,
                    isProcessing: false,
                    progressMessage: `Error: ${trimmedMessage}`
                };

            }
        }, 5000); // poll every 5s
    }

    resetState() {
        this.state = {
            isUploading: false,
            isProcessing: false,
            progressMessage: '',
            jobProgress: 0,
            jobMessage: '',
            bulkImportId: null,
        };
    }

    navigateToBulkImportStatusRecord() {
        const bulkImportId = this.state.bulkImportId;

        // Stop polling
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
            this.pollingInterval = null;
        }

        this.resetState();

        // navigation
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: bulkImportId,
                objectApiName: 'BulkImportStatus__c',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, '_blank');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

}