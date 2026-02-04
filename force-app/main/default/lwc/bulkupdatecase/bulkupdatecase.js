import { LightningElement, api, wire } from 'lwc';
import getCases from '@salesforce/apex/AgentAttendanceController.getCases';

export default class Bulkupdatecase extends LightningElement {
    @api recordId=[];
    caseData = {};
    isSingleRecord = false;

    @wire(getCases, { caseIds: '$recordId' })
    wiredCases({ error, data }) {
        console.log('$recordId',JSON.stringify(this.recordId));
        if (data) {
            this.isSingleRecord = data.length === 1;
            if (this.isSingleRecord) {
                const record = data[0];
                this.caseData = {
                    CaseNumber: record.CaseNumber,
                    CreatedDate: record.CreatedDate,
                    CreatedByName: record.CreatedBy?.Name
                };
            } else {
                this.caseData = {};
            }
        } else if (error) {
            console.error('Error fetching cases', error);
        }
    }
}