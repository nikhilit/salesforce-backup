import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Name_Field from '@salesforce/schema/Account.Name';
import Industry_Field from '@salesforce/schema/Account.Industry';
import Rating_Field from '@salesforce/schema/Account.Rating';
import Revenue_Field from '@salesforce/schema/Account.AnnualRevenue';
import { NavigationMixin } from 'lightning/navigation';


export default class RecordEditFormDemo extends LightningElement {
    @api recordId;
    @api objectApiName;

    fieldList = {
        name: Name_Field,
        industry: Industry_Field,
        rating: Rating_Field,
        revenue: Revenue_Field
    };

    handleSuccessAndNavigate(event) {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Record Created successfully',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);

        this.navigateToRecordPage(event);
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