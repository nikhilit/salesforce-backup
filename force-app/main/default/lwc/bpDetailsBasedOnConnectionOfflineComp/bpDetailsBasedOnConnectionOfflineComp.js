import { LightningElement, api, wire,track } from 'lwc';
//import getBPDetails from '@salesforce/apex/BpDetailsBasedOnConnectionContr.getBPDetails';
import { NavigationMixin } from 'lightning/navigation';

import { getRecord, getFieldValue,getRecords  } from 'lightning/uiRecordApi';
import { getListUi } from 'lightning/uiListApi';

// Import the Work Order field you need to reference
import CONNECTION_FIELD from '@salesforce/schema/WorkOrder.Connection__c';

// Import Account object + fields to query related data
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import BP_NUMBER_FIELD from '@salesforce/schema/Account.BP_Number__c';
import CONNECTION_FIELD_ACC from '@salesforce/schema/Account.Connection__c';

export default class BpDetailsBasedOnConnectionOfflineComp extends NavigationMixin(LightningElement) {
  
    @api recordId; // Work Order Id

    @track showCOAccountPage = true;
   // @api accountBPNumber='';
    @api accountId;

    @track showBPPage=true;
    
    
    bpDetail = [];

    @track showEnterBPDetails=false;
   // openModal=false;
    error;

    connectedCallback() {
        
            console.log('record id workorder inside bp details query ::', this.recordId);

    }

     @wire(getRecord, { recordId: '$recordId', fields: [CONNECTION_FIELD] })
    workOrder;
    get connectionId() {
    return getFieldValue(this.workOrder.data, CONNECTION_FIELD);
}

 @wire(getListUi, {
    objectApiName: ACCOUNT_OBJECT,
    listViewApiName: 'AllAccounts' // your active list view
})
wiredAccounts({ data, error }) {
    console.log('bp records data::', JSON.stringify(data));

    if (data && data.records && Array.isArray(data.records.records)) {
        const connectionId = this.connectionId.trim();
        console.log('Filtering with connectionId:', connectionId);

        // ✅ Filter accounts whose related Connection__r id matches current connectionId
        const filtered = data.records.records.filter(rec => {
            const connId = rec.fields.Connection__r?.value?.id;
            console.log('Record:', rec.id, 'Connection__r id:', connId);
            return connId === connectionId;
        });

        // ✅ Map filtered records into bpDetail list
        this.bpDetail = filtered.map((rec, idx) => ({
            index: idx + 1,
            recordId: rec.id,
            bpNumber: rec.fields.BP_Number__c?.value || '',
            connectionName: rec.fields.Connection__r?.value?.fields?.Name?.value || '',
        }));

        this.error = undefined;
        console.log('Filtered BP details:', JSON.stringify(this.bpDetail));
    } else if (error) {
        this.error = error;
        this.bpDetail = [];
        console.error('Error fetching BP details:', JSON.stringify(error));
    }
}




    // @wire(getBPDetails, { workOrderId: '$recordId' })
    // bpDetails({ data, error }) {
    //     if (data) {
    //         this.bpDetail = data;
    //         this.error = undefined;
    //     } else if (error) {
    //         this.error = error;
    //         this.bpDetail = [];
    //     }
    // }
    handleOpenModal(event){

     this.accountId = event.currentTarget.dataset.id; // Capture clicked Id
     console.log('account name::',event.currentTarget.dataset.name);
          console.log('accountId::',event.currentTarget.dataset.id);

   // this.accountBPNumber=event.currentTarget.dataset.name;
       this.showEnterBPDetails=true;
        this.showBPPage=false;
     // this.openModal=true;
    }
    handleCancel(){
       this.showEnterBPDetails=false;
       this.showBPPage=true;
    //   this.showCOAccountPage=true;
    }
    handleNavigate(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'WorkOrderLineItem',
                actionName: 'view'
            }
        });
    }
}