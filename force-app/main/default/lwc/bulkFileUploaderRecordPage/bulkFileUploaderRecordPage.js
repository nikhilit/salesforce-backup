import { LightningElement, track, wire, api } from 'lwc';
import pollJobProgress from '@salesforce/apex/AS_BulkJobMonitor.pollJobProgress';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import BATCH_JOB_ID from '@salesforce/schema/BulkImportStatus__c.BatchJobId__c';
import STATUS_FIELD from '@salesforce/schema/BulkImportStatus__c.Status__c';
import ERROR_FIELD from '@salesforce/schema/BulkImportStatus__c.Error__c';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent } from 'lightning/refresh';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BulkFileUploaderRecordPage extends NavigationMixin(
    LightningElement
) {

    @api recordId;

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

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD, ERROR_FIELD, BATCH_JOB_ID] })
    wiredRecord(response) {
        this.wiredBulkImport = response; // store the wire reference

        const { data, error } = response;

        if (data) {
            this.bulkImportData = data;
            const status = data.fields.Status__c.value;
            const errorMsg = data.fields.Error__c.value;

            this.state = { ...this.state, bulkImportId: data.id };

            if (status === 'JobComplete') {
                this.state = {
                    ...this.state,
                    isComplete: true,
                    jobMessage: 'File processing completed.'
                };
            } else if (status === 'In Progress' || status === 'Uploaded') {
                this.state = {
                    ...this.state,
                    isProcessing: true,
                    progressMessage: 'Processing file...'
                };
                this.startPolling();
            } else if (status === 'Failed') {
                this.state = {
                    ...this.state,
                    jobMessage: errorMsg
                };
            }
        }

        if (error) {
            console.error('Record load error', error);
        }
    }

    startPolling() {
        this.pollingInterval = setInterval(async () => {
            try {
                const result = await pollJobProgress({
                    bulkImportId: this.state.bulkImportId
                });

                this.state = {
                    ...this.state,
                    jobProgress: result.progress,
                    jobMessage: result.message
                };

                const TERMINAL_STATUSES = ['JobComplete', 'Failed', 'Aborted', 'ERROR'];
                const isTerminal = TERMINAL_STATUSES.includes(result.status);
                // const isComplete = result.progress >= 100;

                if (isTerminal) {
                    clearInterval(this.pollingInterval);

                    this.state = {
                        ...this.state,
                        isProcessing: false,
                        progressMessage:
                            result.status === 'JobComplete'
                                ? '✅ Upload Complete!'
                                : `⚠️ Job ended with status: ${result.status}`
                    };

                    // ✅ refresh once when done
                    this.dispatchEvent(new RefreshEvent());
                    refreshApex(this.wiredBulkImport);
                }

            } catch (error) {
                clearInterval(this.pollingInterval);

                const errorMessage =
                    error?.body?.message ||
                    error?.message ||
                    'Unexpected error occurred. Please try again later.';

                this.state = {
                    ...this.state,
                    isProcessing: false,
                    progressMessage: `Error: ${errorMessage}`
                };

                // ✅ refresh once on error
                this.dispatchEvent(new RefreshEvent());
                refreshApex(this.wiredBulkImport);
            }
        }, 5000);
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

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

}