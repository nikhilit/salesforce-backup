import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import STATUS_FIELD from "@salesforce/schema/WorkOrder.Status";

import allowReceiptCancellation from '@salesforce/apex/PaymentCancelController.allowReceiptCancellation';

export default class AsPaymentCancel extends LightningElement {

    @api recordId;
    workOrderData;
    value;

    get options() {
        return [
            { label: 'Requested by customers', value: 'Requested by customers' },
            { label: 'Agreed to pay online', value: 'Agreed to pay online' },
        ];
    }
    
    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD] })
    workOrder;

    @wire(allowReceiptCancellation, { workOrderId: '$recordId' })
    allowCancelResult;

    get disableSubmit() {
        // If data is true → allow submission → disable = false
        // If data is false → disable = true
        return !(this.allowCancelResult?.data);
    }

    handleChange(event) {
        this.value = event.detail.value;
    }
    
}