import { LightningElement, api, wire, track } from 'lwc';
import fetchSAPData from '@salesforce/apex/BillsCallout.fetchSAPData';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPdfFromAPI from '@salesforce/apex/BillsCallout.getPdfFromAPI';

const BP_FIELD = 'Account.BP_Number__c';

export default class getBills extends LightningElement {
    @api recordId;
    bpId;
    @track fromDate;
    @track toDate;
    isLoading = false;
    statusMessage;
    error;
    isLoading = false;
    sapData=[];

    @wire(getRecord, { recordId: '$recordId', fields: [BP_FIELD] })
    wiredAccount({ error, data }) {
        if (data) {
            this.bpId = data.fields.BP_Number__c.value;
        } else if (error) {
            this.error = error.body?.message || error.message;
            console.error('Error fetching Account:', error);
        }
    }
getPdf(event) {
        const printDocNum = event.currentTarget.dataset.printdoc; // Get from data attribute
        this.isLoading = true;
        
        getPdfFromAPI({ billPrintNumber: printDocNum })
            .then((base64Pdf) => {
                this.isLoading = false;
                if (base64Pdf) {
                    const byteCharacters = atob(base64Pdf);
                    const byteNumbers = new Array(byteCharacters.length);
                    for (let i = 0; i < byteCharacters.length; i++) {
                        byteNumbers[i] = byteCharacters.charCodeAt(i);
                    }
                    const byteArray = new Uint8Array(byteNumbers);
                    const blob = new Blob([byteArray], { type: 'application/pdf' });
                    const blobUrl = URL.createObjectURL(blob);
                    window.open(blobUrl, '_blank'); // Open PDF in a new tab
                } else {
                    this.error = 'No PDF data returned';
                }
            })
            .catch((err) => {
                this.isLoading = false;
                this.error = 'Error fetching PDF: ' + err.body?.message;
            });
    }
    handleFromDateChange(event) {
        this.fromDate = event.target.value;
    }

    handleToDateChange(event) {
        this.toDate = event.target.value;
    }

    callSAP() {
    if (!this.bpId || !this.fromDate || !this.toDate) {
        this.showToast('Missing Info', 'Please ensure From Date, and To Date are filled.', 'warning');
        return;
    }

    const formattedFrom = this.fromDate.replace(/-/g, '');
    const formattedTo = this.toDate.replace(/-/g, '');

    this.isLoading = true;
    this.error = undefined;

    fetchSAPData({ bpId: this.bpId, fromDate: formattedFrom, toDate: formattedTo })
        .then(result => {
            this.statusMessage = result.salesforceStatus;

            // Sort sapData by BUDATE
            this.sapData = (result.sapData || []).sort((a, b) => {
                const dateA = new Date(a.BUDAT.replace(/-/g, '/')); 
                const dateB = new Date(b.BUDAT.replace(/-/g, '/')); 
                return dateB - dateA; // ascending (earliest first)
            });

            this.showToast('Success', 'Data fetched successfully.', 'success');
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


    handleRefresh() {
        this.callSAP();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}