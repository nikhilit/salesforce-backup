import { LightningElement, api, wire, track } from 'lwc';
import fetchSAPData from '@salesforce/apex/SecurityDepositLwcHandler.fetchSAPData';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const BP_FIELD = 'Account.BP_Number__c';

export default class GetSecurityDeposit extends LightningElement {
    @api recordId;
    bpId;
    @track fromDate;
    @track toDate;
    isLoading = false;
    statusMessage;
    error;
    isLoading = false;
    sapData=[];
    @track totalCashAmount = '0.00';
    @track totalRequestAmount = '0.00';

    @wire(getRecord, { recordId: '$recordId', fields: [BP_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            this.bpId = data.fields.BP_Number__c.value;
            console.log('bpId',this.bpId);
            this.callSAP();
        } else if (error) {
            this.error = error.body?.message || error.message;
            console.error('Error fetching Account:', error);
        }
    }


callSAP() {
        if (!this.bpId) {
            this.showToast('Missing Info', 'Please provide BP Id.', 'warning');
            return;
        }

        this.isLoading = true;
        this.error = undefined;

        fetchSAPData({ bpId: this.bpId })
            .then(result => {
                this.sapData = result.sapData || [];
                 this.sapData = (result.sapData || []).map(row => ({
                ...row,
                // normalize NON_CASH to true/false
                NON_CASH: row.NON_CASH === true || row.NON_CASH === 'true' || row.NON_CASH === 'X'
            }));
this.sapData.sort((a, b) => {
            const dateA = new Date(a.SEC_START);
            const dateB = new Date(b.SEC_START);
            return dateA - dateB; // descending
        });
                // Calculate totals
                this.totalRequestAmount = this.sapData
                    .reduce((sum, row) => sum + (row.REQUEST || 0), 0);

                this.totalCashAmount = this.sapData
                    .reduce((sum, row) => sum + (row.PAID || 0), 0);

                this.showToast('Success', 'SAP Data fetched successfully', 'success');
            })
            .catch(error => {
                this.error = error.body?.message || error.message;
                console.error('SAP Callout Error:', error);
                this.showToast('Error', this.error, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }


    handleRefresh() {
        this.callSAP();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}