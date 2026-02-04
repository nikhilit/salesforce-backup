import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import SUBJECT_FIELD from '@salesforce/schema/Case.Subject';

export default class CaseSubjectDisplay extends LightningElement {
    @api recordId; // This will be automatically passed in Lightning Record Page

    subject;

    @wire(getRecord, { recordId: '$recordId', fields: [SUBJECT_FIELD] })
    wiredCase({ error, data }) {
        if (data) {
            this.subject = data.fields.Subject.value;
        } else if (error) {
            console.error('Error fetching case:', error);
        }
    }
}