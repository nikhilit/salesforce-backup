import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import PAYMENT_MODE_FIELD from "@salesforce/schema/WorkOrder.Payment_Mode__c";

export default class ViewReceiptQuickAction extends NavigationMixin(LightningElement) {
    _recordId;
    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(recordId) {
        if (recordId !== this._recordId) {
            this._recordId = recordId;
        }
    }

    isExecuting = false;

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [PAYMENT_MODE_FIELD],
    })
    workorder;

    get paymentMode() {
        return getFieldValue(this.workorder.data, PAYMENT_MODE_FIELD);
    }

    @api invoke() {
        if (this.isExecuting) {
            return;
        }
        console.log('recordId: ' + this.recordId);
        console.log('paymentMode: ' + this.paymentMode);

        let urlappend = this.recordId
        if (this.paymentMode === 'Cheque')
            urlappend = this.recordId + '&mode=cheque';

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/apex/receipt?id=' + urlappend
            }
        }).then(vfURL => {
            window.open(vfURL);
        });
    }
}