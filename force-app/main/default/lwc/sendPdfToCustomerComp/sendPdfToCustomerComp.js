import { LightningElement,wire,api,track } from 'lwc';
import getBillingsByAccount from '@salesforce/apex/SendPdfToCunstomerController.getBillingsByAccount';
import savePdfFiles from '@salesforce/apex/SendPdfToCunstomerController.savePdfFiles';
import getPreferencePicklistValues from '@salesforce/apex/SendPdfToCunstomerController.getPreferencePicklistValues';
import getAccountInfoFromSA from '@salesforce/apex/RTVisitExecutionController.getAccountInfoFromSA';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_FIELD from '@salesforce/schema/WorkOrder.AccountId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SendPdfToCustomerComp extends LightningElement {
// fetch Billings using AccountId
@api recordId;
error;
@track WorkOrder;
billings=[];
@track accountId;
@track accountPhone='';
@track account;
@track ifChecked=false;
@track isLoading=false;
connectedCallback() {
this.fetchAccountInfo();
this.fetchPreferences();
}
@wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_FIELD] })
wiredWorkOrderAccount({ error, data }) {
if (data) {
    this.accountId = data.fields.AccountId.value;
    
} else if (error) {
    console.error('Error fetching AccountId from Work Order:', error);
}
}
@wire(getBillingsByAccount, {accountId: '$accountId'})
wiredBillings({ data, error }) {
if (data) {
    this.billings = data;
    console.log('dataPdf::'+JSON.stringify(data));
    this.error = undefined;
} else if (error) {
    console.log('error::'+JSON.stringify(error));
    this.error = error;
    this.billings = undefined;
}
}

fetchAccountInfo() {
    getAccountInfoFromSA({ workOrderId: this.recordId })
        .then((data) => {

            console.log('========data=======>', JSON.stringify(data));
            
            this.account = data.acc;
            this.accountPhone=this.account.Phone;
            console.log('accountPhone::'+this.accountPhone);
            this.accountDetails = true;
            if (data.serviceAppointments && data.serviceAppointments.length > 0) {
                this.serviceAppointment = data.serviceAppointments[0];
            }
            this.workOrder = data.workOrder;
            console.log('orkOrder::'+JSON.stringify(this.workOrder));
            //this.billing = data.billing;
            
            this.error = null;
        })
    .catch(error => {
        this.showToast('Error', error?.body?.message || 'Failed to get account details.', 'error');
    });
}
printDocNum=[];
handleCheckBoxChange(event) {
    const value = event.currentTarget.dataset.printdoc;

    if (event.target.checked) {
        if (!this.printDocNum.includes(value)) {
            this.printDocNum.push(value);
        }
    } else {
        this.printDocNum = this.printDocNum.filter(item => item !== value);
    }

    console.log('Selected Doc Numbers:', this.printDocNum);
    if(this.printDocNum.length>0){
        this.ifChecked=true;
    }
    else{
        this.ifChecked=false;
    }
}
@track preferenceOptions = [];
    selectedPreference = '';

    fetchPreferences() {
        getPreferencePicklistValues()
            .then(result => {
                this.preferenceOptions = result.map(value => ({
                    label: value,
                    value: value
                }));
            })
            .catch(error => {
                console.error('Error fetching picklist values:', error);
            });
    }

    handleChange(event) {
        this.selectedPreference = event.detail.value;
        console.log('Selected Preference: ', this.selectedPreference);
    }
handlePhoneChange(event){
    this.accountPhone=event.target.value;
}
getPdfList() {
    if(this.accountPhone==''){
        this.showToast('Warning', 'Please Enter Phone Number!', 'wraning');
        return;
    }
    if(this.selectedPreference==''){
        this.showToast('Warning', 'Please Select Preference!', 'wraning');
        return;
    }
    this.isLoading = true;
    console.log('this.printDocNum::'+this.printDocNum);
    savePdfFiles({ billPrintNumbers: this.printDocNum,phoneNumber:this.accountPhone,accountName:this.account.Name,preference:this.selectedPreference,workOrderId:this.recordId })
        .then((publicUrls) => {
            this.isLoading = false;
            if (publicUrls=='Success') {
                this.showToast('Success','PDF sent to customer', 'success');
                console.log('PDF URLs:', publicUrls); 
            } else {
                this.showToast('Error','PDF didn not send to customer', 'error');
            }
        })
        .catch((err) => {
            this.isLoading = false;
            console.log('error::'+JSON.stringify(err));
            const errorMsg = err.body?.message || err.message || 'Unknown error';
            this.showToast('Error fetching PDFs: ' + errorMsg, 'error');
        });
}
showToast(title, message, variant) {
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant, // 'success', 'error', 'warning', 'info'
        mode: 'dismissable' // can be 'dismissable', 'pester', or 'sticky'
    });
    this.dispatchEvent(evt);
}
}