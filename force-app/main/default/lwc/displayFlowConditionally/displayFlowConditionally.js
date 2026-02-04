import { LightningElement, wire, api } from 'lwc';
import ACCOUNT_RATING from '@salesforce/schema/Account.Rating';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';

export default class DisplayFlowConditionally extends LightningElement {

    @api recordId;
    accountRating;

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [ACCOUNT_RATING]
    })
    getRecordOutput({ data, error }) {
        if (data) {
            this.accountRating = getFieldValue(data, ACCOUNT_RATING);
        } else if (error) {
            // Handle the error if needed
        }
    }

    get isAccountRatingHot() {
        return this.accountRating === 'Hot';
    }

    get isAccountRatingWarm() {
        return this.accountRating === 'Warm';
    }

    get isAccountRatingCold() {
        return this.accountRating === 'Cold';
    }

    get inputvariable() {
        return [{ name: "inputRating", type: "String", value: this.accountRating }];
    }
}