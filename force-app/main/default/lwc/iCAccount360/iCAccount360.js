import { LightningElement, api, track } from 'lwc';
import getAccountInfoFromSA from '@salesforce/apex/iCAccount360Controller.getAccountInfoFromSA';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ICAccount360 extends LightningElement {
        @api recordId;
        @track account;
        @track serviceAppointment;
        @track error;
        @track accountView = true;
        @track workOrder;
        @track detailAccountSummary;
    
        connectedCallback() {
            if (this.recordId) {
                this.fetchAccountInfo();
            }
        }
    
        fetchAccountInfo() {
            getAccountInfoFromSA({ workOrderId: this.recordId })
                .then((data) => {
                    this.account = data.acc;
                    if (data.serviceAppointments && data.serviceAppointments.length > 0) {
                        this.serviceAppointment = data.serviceAppointments[0];
                    }
                    this.workOrder = data.workOrder;
                    this.detailAccountSummary = data.detailAccountSummary;
                    this.error = null;
                })
                .catch((error) => {
                    this.error = error;
                    this.account = null;
                    this.serviceAppointment = null;
                    this.detailAccountSummary = null;
                    this.workOrder = null;
                    console.error('Error fetching account and service appointment:', error);
                });
        }

        get getPaymentCollection(){
            return (this.workOrder.Amount_Received__c == null ? 'Unpaid' : 'Paid');
        }
    
        get formattedVisitDateTime() {
            if (this.serviceAppointment?.SchedEndTime) {
                const dt = new Date(this.serviceAppointment.SchedEndTime);
                const date = dt.toLocaleDateString('en-GB'); // DD/MM/YYYY
                const time = dt.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' }); // HH:MM
                return `${date}, ${time}`;
            }
            return '';
        }

        get formattedFollowUpDate() {
            if (this.workOrder?.Follow_up_Date__c) {
                const dt = new Date(this.workOrder.Follow_up_Date__c);
                const date = dt.toLocaleDateString('en-GB');
                return `${date}`;
            }
            return '';
        }

        get formattedBillDate() {
            if (this.workOrder?.Bill_Date__c) {
                const dt = new Date(this.workOrder.Bill_Date__c);
                const date = dt.toLocaleDateString('en-GB');
                return `${date}`;
            }
            return '';
        }
    
        handleTakeReading() {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Action Triggered',
                message: 'Collect Payment clicked',
                variant: 'info'
            }));
        }
    
        handleUpdateCustomer() {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Action Triggered',
                message: 'Update Customer clicked',
                variant: 'info'
            }));
        }

}