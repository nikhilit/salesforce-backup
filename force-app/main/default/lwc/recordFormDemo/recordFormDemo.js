import { LightningElement, api } from 'lwc';

import Name_Field from '@salesforce/schema/Account.Name';
import Industry_Field from '@salesforce/schema/Account.Industry';
import Rating_Field from '@salesforce/schema/Account.Rating';
import Revenue_Field from '@salesforce/schema/Account.AnnualRevenue';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class RecordFormDemo extends LightningElement {
    @api recordId;
    @api objectApiName;

    fieldList=[Name_Field, Industry_Field, Rating_Field, Revenue_Field];


    showToast() {
        const event = new ShowToastEvent({
            title: 'Success',
            message:
                'Record Uodated Succesfully.',
            variant: 'success',
            mode: 'dismissable',
        });
        this.dispatchEvent(event);
    }

    navigateToRecordPage(event) {
        // Navigate to the Account home page

        let pageref = {
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                objectApiName: this.objectApiName,
                actionName: 'view',
            },
        };
        this[NavigationMixin.Navigate](pageref);
    }
    
}