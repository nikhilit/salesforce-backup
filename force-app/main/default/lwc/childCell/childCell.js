import { LightningElement,api } from 'lwc';
import getChildFields from '@salesforce/apex/AS_AgencyAssignmentController.getChildFields';

const ALL_COLUMNS = [
        { label: 'Date of First Attempt', fieldName: 'firstAttemptDate',sourceField: 'Check_In_Time__c' },
        { label: 'Time of First Attempt', fieldName: 'firstAttemptTime',sourceField: 'Check_In_Time__c' },
        { label: 'Date of Second Attempt', fieldName: 'secondAttemptDate',sourceField: 'Check_In_Time__c' },
        { label: 'Time of Second Attempt', fieldName: 'secondAttemptTime',sourceField: 'Check_In_Time__c' },
        { label: 'Previous Visit Date', fieldName: 'previousAttemptDate',sourceField: 'Check_In_Time__c' },
        { label: 'Previous Visit Time', fieldName: 'previousAttemptTime',sourceField: 'Check_In_Time__c' },

        { label: 'Receipt Date', fieldName: 'Payment_Date__c',sourceField: 'Payment_Date__c' },
        { label: 'Cheque Number', fieldName: 'Cheque_Number__c',sourceField: 'Cheque_Number__c' },
        { label: 'Cheque Date', fieldName: 'Cheque_Date__c',sourceField: 'Cheque_Date__c' },
        { label: 'Bank Name', fieldName: 'Bank_Name__c',sourceField: 'Bank_Name__c' }
    ];

export default class ChildCell extends LightningElement {
    @api value;
    @api fieldLabel;
    @api fieldApiName;

    columns = [];
    tableData = [];
    isModalOpen = false;

    get hasRecords() {
        return Array.isArray(this.value) && this.value.length > 0;
    }

     handleOpenModal(event) {
        event.preventDefault();

        getChildFields({ objectApiName: this.fieldApiName })
            .then(fieldApis => {
                this.prepareColumns(fieldApis);
                this.prepareData(fieldApis);
                this.isModalOpen = true;
            })
            .catch(error => {
                console.error('Error fetching child fields', error);
            });
    }

    handleCloseModal() {
        this.isModalOpen = false;
    }


     prepareColumns(fieldApis) {
        this.columns = ALL_COLUMNS.filter(col =>
            fieldApis.includes(col.sourceField)
        );
    }

    prepareData(fieldApis) {
        this.tableData = this.value.map(row => {
            const flattened = { ...row };
            if (fieldApis.includes('Check_In_Time__c')) {
                flattened.firstAttemptDate = row.Check_In_Time__c;
                flattened.firstAttemptTime = row.Check_In_Time__c;
                flattened.secondAttemptDate = row.Check_In_Time__c;
                flattened.secondAttemptTime = row.Check_In_Time__c;
                flattened.previousAttemptDate = row.Check_In_Time__c;
                flattened.previousAttemptTime = row.Check_In_Time__c;
            }
            return flattened;
        });
    }
}