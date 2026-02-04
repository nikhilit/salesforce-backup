import { LightningElement, api, wire } from 'lwc';
import fetchSAPData from '@salesforce/apex/ChangeHistoryCallout.fetchSAPData';
import { getRecord } from 'lightning/uiRecordApi';

const BP_FIELD = 'Account.BP_Number__c';

export default class SapDataViewer extends LightningElement {
    @api recordId;
    bpId;
    sapData = [];
    statusMessage;
    error;
    isLoading = false;

    @wire(getRecord, { recordId: '$recordId', fields: [BP_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            this.bpId = data.fields.BP_Number__c.value;
            this.callSAP();
        } else if (error) {
            this.error = error.body?.message || error.message;
            console.error('Error fetching Account:', error);
        }
    }

    callSAP() {
        this.isLoading = true;
        this.error = undefined;
        fetchSAPData({ bpId: this.bpId })
            .then(result => {
                this.statusMessage = result.statusMessage;
                //this.sapData = result.sapData;
                  if (result.sapData) {
                    this.sapData = this.sortSapData(result.sapData);
                } else {
                    this.sapData = [];
                }
            })
            .catch(error => {
                this.error = error.body?.message || error.message;
                console.error('SAP Callout Error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    sortSapData(data) {
        // Create a new array with a slice to avoid modifying the original array
        return data.slice().sort((a, b) => {
            // Combine date and time for a single, reliable sort key
            const aDateTime = a.UDATE + a.UTIME;
            const bDateTime = b.UDATE + b.UTIME;

            if (aDateTime > bDateTime) {
                return -1; // b comes before a for descending order
            }
            if (aDateTime < bDateTime) {
                return 1; // a comes before b for descending order
            }
            return 0; // The items are equal
        });
    }

    handleRefresh() {
        this.callSAP();
    }
}