import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import ID_FIELD from '@salesforce/schema/Attendance__c.Id';
import DAY_OUT_TS from '@salesforce/schema/Attendance__c.Day_Out_Timestamp__c';
import DAY_OUT_LAT from '@salesforce/schema/Attendance__c.Day_Out_Lat__c';
import DAY_OUT_LON from '@salesforce/schema/Attendance__c.Day_Out_Long__c';

export default class ResetDayOutAction extends LightningElement {
    @api recordId;

    @api invoke() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[DAY_OUT_TS.fieldApiName] = null;
        fields[DAY_OUT_LAT.fieldApiName] = null;
        fields[DAY_OUT_LON.fieldApiName] = null;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Day-Out has been reset.',
                        variant: 'success'
                    })
                );

                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'Error resetting Day-Out',
                        variant: 'error'
                    })
                );

                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }
}