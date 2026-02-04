import { LightningElement, wire, api } from 'lwc';
import getParentAccounts from '@salesforce/apex/AccountHelper.getParentAccounts';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_ID from '@salesforce/schema/Account.Id';
import ACCOUNT_SLA_TYPE from '@salesforce/schema/Account.SLA__c';
import ACCOUNT_PARENT from '@salesforce/schema/Account.ParentId';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import ACCOUNT_SLA_EXPIRY_DATE from '@salesforce/schema/Account.SLAExpirationDate__c';
import ACCOUNT_NO_OF_LOCATION from '@salesforce/schema/Account.NumberofLocations__c';
import ACCOUNT_DESCRIPTION from '@salesforce/schema/Account.Description';
import { createRecord, deleteRecord, getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const fieldsToLoad = [
    ACCOUNT_PARENT, 
    ACCOUNT_NAME, 
    ACCOUNT_SLA_EXPIRY_DATE, 
    ACCOUNT_NO_OF_LOCATION, 
    ACCOUNT_DESCRIPTION
];

export default class AccountDetails extends NavigationMixin(LightningElement) {
    parentOptions = [];
    selParentAcc = '';
    selNoOfLocations = '';
    selAccName = '';
    selSlaExpDate = '';
    selSlaType = '';
    selDescription = '';
    @api recordId = "";

    @wire(getRecord, {
        recordId: "$recordId",
        fields: fieldsToLoad
    }) wiredgetRecord_Function({ data, error }) {
        if (data) {
            this.selParentAcc = getFieldValue(data, ACCOUNT_PARENT); // Corrected field
            this.selSlaExpDate = getFieldValue(data, ACCOUNT_SLA_EXPIRY_DATE);
            this.selNoOfLocations = getFieldValue(data, ACCOUNT_NO_OF_LOCATION);
            this.selDescription = getFieldValue(data, ACCOUNT_DESCRIPTION);
            this.selAccName = getFieldValue(data, ACCOUNT_NAME);
            this.selSlaType = getFieldValue(data, ACCOUNT_SLA_TYPE);
        } else if (error) {
            console.log('Error while getting record', error);
        }
    }

    @wire(getParentAccounts)
    wired_getParentAccount({ data, error }) {
        this.parentOptions = [];
        if (data) {
            this.parentOptions = data.map((curritem) => ({
                label: curritem.Name,
                value: curritem.Id,
            }));
        } else if (error) {
            console.log('Error while getting Parent Records', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountObjectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$accountObjectInfo.data.defaultRecordTypeId',
        fieldApiName: ACCOUNT_SLA_TYPE,
    })
    slapicklist;

    handleChange(event) {
        const { name, value } = event.target;

        if (name === 'parentAcc') {
            this.selParentAcc = value;
        } else if (name === 'accName') {
            this.selAccName = value;
        } else if (name === 'slaExpDate') {
            this.selSlaExpDate = value;
        } else if (name === 'noOfLocations') {
            this.selNoOfLocations = value;
        } else if (name === 'description') {
            this.selDescription = value;
        } else if (name === 'slaType') { // Added SLA Type case
            this.selSlaType = value;
        }
    }

    saveRecord() {
        if (this.validateInput()) {
            const inputFields = {
                [ACCOUNT_NAME.fieldApiName]: this.selAccName,
                [ACCOUNT_PARENT.fieldApiName]: this.selParentAcc,
                [ACCOUNT_SLA_TYPE.fieldApiName]: this.selSlaType,
                [ACCOUNT_SLA_EXPIRY_DATE.fieldApiName]: this.selSlaExpDate,
                [ACCOUNT_NO_OF_LOCATION.fieldApiName]: this.selNoOfLocations,
                [ACCOUNT_DESCRIPTION.fieldApiName]: this.selDescription,
            };

            if (this.recordId) {
                inputFields[ACCOUNT_ID.fieldApiName] = this.recordId;
                const recordInput = { fields: inputFields };
                updateRecord(recordInput)
                    .then(() => {
                        this.showToast('Record Updated Successfully');
                        setTimeout(() => {
                            this.navigateToRecordPage(this.recordId);
                        }, 500);
                    })
                    .catch((error) => {
                        console.log('Error updating record', error);
                    });
            } else {
                const recordInput = {
                    apiName: ACCOUNT_OBJECT.objectApiName,
                    fields: inputFields,
                };
                createRecord(recordInput)
                    .then((result) => {
                        this.showToast('Record Created Successfully');
                        setTimeout(() => {
                            this.navigateToRecordPage(result.id);
                        }, 500);
                    })
                    .catch((error) => {
                        console.error('Error creating record', error);
                    });
            }
        } else {
            console.log('Inputs are not valid');
        }
    }

    validateInput() {
        const fields = Array.from(this.template.querySelectorAll('.validateMe'));
        return fields.every((field) => field.checkValidity());
    }

    navigateToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Account',
                actionName: 'view',
            },
        });
    }

    get formtitle() {
        return this.recordId ? 'Edit Account' : 'Create Account';
    }

    get isDeleteAvailable() {
        return !!this.recordId;
    }

    showToast(message) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: 'Record Deleted Successfully',
            variant: 'success',
        });
        this.dispatchEvent(event);
    }

    deleteHandler() {
        deleteRecord(this.recordId)
            .then(() => {
                console.log('Record Deleted Successfully')
            })
            .catch((error) => {
                console.log('Error deleting record', error);
            });
    }
}