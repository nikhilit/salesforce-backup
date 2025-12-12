import { LightningElement } from 'lwc';
import getOpportunityData from '@salesforce/apex/OpportunityHelper.getOpportunityData';

export default class ImperativeDeno extends LightningElement {
    data;
    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Stage Name', fieldName: 'StageName' },
        { label: 'Close Date', fieldName: 'CloseDate' }
    ];

    handleClick(){
        getOpportunityData().then(data => {
            this.data = data;
        })
        .catch((error)=>{

            this.error = error;
        });
    }
}