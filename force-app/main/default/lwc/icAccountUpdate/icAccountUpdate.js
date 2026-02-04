import { LightningElement, api, wire } from 'lwc';
//import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//const WORKORDER_FIELDS = ['WorkOrder.AccountId'];
export default class IcAccountUpdate extends LightningElement {

    @api recordId;
    @api objectApiName;
    accountId;
 
    validatePhoneNumber(inputElement) {
        const regex = /^\d{10}$/;
        return !regex.test(inputElement);
    }

    validateEmail(inputElement) {
        const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        return !emailRegex.test(inputElement);
    }
    
    @api
    submitForm() {
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        let isValid = true;
        // inputFields.forEach(field => {
        //     if(field.fieldName === 'Phone' || field.fieldName === 'Secondary_Telephone__c'){
        //         if(field.value && this.validatePhoneNumber(field.value)){
        //             this.dispatchEvent(
        //                 new ShowToastEvent({
        //                     title: 'Error',
        //                     message: 'Phone and Secondary Phone must contain exactly 10 digits only.',
        //                     variant: 'error',
        //                 })
        //             );
        //             isValid = false;
        //         }
        //     }

        //     if(field.fieldName === 'Email_Id__c'){
        //         if(field.value && this.validateEmail(field.value)){
        //             this.dispatchEvent(
        //                 new ShowToastEvent({
        //                     title: 'Error',
        //                     message: 'Please enter valid email id.',
        //                     variant: 'error',
        //                 })
        //             );
        //             isValid = false;
        //         }
        //     }
        //     console.log('Field API Name:', field.fieldName);
        //     console.log('Field Value:', field.value);
        // });

        if(isValid){
            this.template.querySelector('lightning-record-edit-form').submit();
        }
    }

    // @wire(getRecord, { recordId: '$recordId', fields: WORKORDER_FIELDS })
    // wiredWorkOrder({ error, data }) {
    //     if (data) {
    //         this.accountId = data.fields.AccountId?.value;
    //     } else if (error) {
    //         console.error('Error fetching WorkOrder:', error);
    //     }
    // } 

    handleSuccess() {
        console.log('Contact details updated successfully');
        this.dispatchEvent(new CustomEvent('childsaved'));
    }

    handleError(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error updating Account',
                message: event.detail.message,
                variant: 'error',
            })
        );
    }
}