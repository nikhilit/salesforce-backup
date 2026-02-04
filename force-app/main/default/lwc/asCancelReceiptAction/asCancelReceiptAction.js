import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
import LightningConfirm from 'lightning/confirm';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import WORKORDER_OBJECT from "@salesforce/schema/WorkOrder";
import CANCEL_REASON_FIELD from "@salesforce/schema/WorkOrder.Cancel_Reason__c";
import cancelReceiptMethod from '@salesforce/apex/PaymentCancelController.cancelReceiptMethod';
import checkValidity from '@salesforce/apex/PaymentCancelController.checkValidity';

export default class AsCancelReceiptAction extends LightningElement {
    _recordId;

    @api set recordId(value) {
        this._recordId = value;

        this.toggle();
        this.loadValidity();
        // do your thing right here with this.recordId / value
    }

    get recordId() {
        return this._recordId;
    }

    @api objectApiName;
    @api isLoaded = false;
    value;
    @track formData = {};

    @wire(getObjectInfo, { objectApiName: WORKORDER_OBJECT })
    objectInfo;

    get recordTypeId() {
        const rtis = this.objectInfo?.data?.recordTypeInfos;
        return Object.keys(rtis).find((rti) => rtis[rti].name === "MGL R&T");
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: CANCEL_REASON_FIELD })
    picklistOptions;

    get options() {
        return this.picklistOptions?.data?.values;
    }

    loadValidity() {
        this.isLoaded = false;

        checkValidity({ recordId: this.recordId })
            .then(result => {
                this.isValid = Boolean(result);   // ✔ FORCE boolean
                console.log('isValid (bool): ', this.isValid);
            })
            .catch(error => {
                console.error('Error checking validity:', error);
                this.isValid = false;
            })
            .finally(() => {
                this.isLoaded = true;
            });
    }

    get disableSubmit() {
        // Block submit if component still loading
        if (!this.isLoaded) return true;
        // Block submit if cancel reason not selected
        if (!this.formData.cancelReason) return true;

        if (!this.isValid) return true;

        return false;
    }

    toggle() {
        this.isLoaded = !this.isLoaded;
    }

    handleChange(event) {
        this.formData[event.target.name] = event.target.value;
        console.log('data: ', JSON.stringify(this.formData));
    }

    async handleSubmit() {
        this.toggle();

        const result = await LightningConfirm.open({
            message: 'Are you sure you want to cancel this receipt?',
            variant: 'headerless',
        });

        if (!result) {
            this.toggle();  // hide loader
            return;         // stop here → do NOT call Apex
        }

        cancelReceiptMethod({ formData: this.formData, recordId: this.recordId })
            .then(() => {
                this.showToast('Success', 'Receipt cancelled successfully', 'success');
                this.toggle();
                this.dispatchEvent(new RefreshEvent());
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.toggle();
                let errorMessage =
                    error?.message ||
                    error?.body?.message ||
                    error?.body?.errorMessage ||
                    'Unexpected error occurred. Please contact your administrator.';

                this.showToast('Error', errorMessage, 'error');
            })
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

}