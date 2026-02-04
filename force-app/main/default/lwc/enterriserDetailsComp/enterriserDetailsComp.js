import { LightningElement,track,api,wire } from 'lwc';
import getWOrderWType from '@salesforce/apex/COExecutionDetailsRiserContr.getWOrderWType';
import checkWorkStep from '@salesforce/apex/COExecutionDetailsRiserContr.checkWorkStep';


//fsl offline
import { getRecord } from 'lightning/uiRecordApi';
import WORKTYPE_NAME from '@salesforce/schema/WorkOrder.WorkType.Name';
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import DOCUMENT_OBJECT from '@salesforce/schema/Document__c';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Username';
import { getListUi } from 'lightning/uiListApi';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from "@salesforce/apex";


export default class EnterriserDetailsComp extends LightningElement {


@track riserPaintingRiserExecution =false;
@track riserReplacementRiserExecution =false;
@track showMaintenanceRiserExecution =false;

@track wOWorkType='';

@api recordId;

@track userName='';

@track coExecutionDetailStatus='';


//connectedCallback() {
    
       // this.getWOrderWType();
      //  this.checkWorkStep();

//}

    async connectedCallback() {
    
    console.log('WorkOrder Record Id::',this.recordId);
    if (this.wiredWorkOrderResult) {
        console.log('Refreshing WorkOrder wire for mobile...');
        try {
            await refreshApex(this.wiredWorkOrderResult);
            console.log('Wire refreshed');
        } catch (err) {
            console.error('Error refreshing wire:', err);
        }
    }

}





//  checkWorkStep(){
//     console.log('inside check work order step');
//     checkWorkStep({recordId:this.recordId})
//     .then( result => {

//         console.log('Result upload site status:::', result);
//         if(result !='Completed'){
//             console.log('inside new if');
//             this.showtoast('Warning', 'Please Complete Upload Site Document Task', 'warning');
//              this.handleCancel();

//         }

       
//     })
//     .catch( error => {
//         console.log('Error getting approval ::', error);
//     })
//   }

//  getWOrderWType(){
//         getWOrderWType({recordId :this.recordId})
//         .then( result => {
//             console.log('Work Type Name ::', result);
//         this.wOWorkType=result;
//            this.checkWorkType();


//         })
//         .catch(error => {
//             console.log('Error ::', error);
//         })
//     }


@wire(getRelatedListRecords, {
    parentRecordId: '$recordId',
    relatedListId: 'WorkSteps', 
    fields: ['WorkStep.Name', 'WorkStep.Status'],
    sortBy: ['CreatedDate DESC'],
    pageSize: 200
})

wiredWorkSteps({ data, error }) {
    if (data) {
        const records = data.records || [];
        console.log('WorkSteps:', records);

        const coExecutionDetail = records.find(r => r.fields.Name.value === 'CO Execution Detail');

        this.coExecutionDetailStatus = coExecutionDetail ? coExecutionDetail.fields.Status.value : 'Not Found';

        console.log('coExecutionDetailStatus:', this.coExecutionDetailStatus);

        if (this.coExecutionDetailStatus !== 'Completed') {


                this.showtoast('Warning','Please Complete CO Execution Detail Task', 'warning');
        
               this.handleCancel();

        }

    }
       
}

wiredUserResult; // store wire result reference

@wire(getRecord, { recordId: USER_ID, fields: [USER_NAME] })
wiredUser(result) {
    this.wiredUserResult = result; // store the full wire result for refresh
    const { data, error } = result;

    if (data) {
        this.userName = data.fields.Username.value;
        console.log('Current Username:', this.userName);
           if (this.wiredDocumentsResult) {
            refreshApex(this.wiredDocumentsResult);
        }
    } else if (error) {
        console.error(' Error fetching user:', error);
    }
}

wiredDocumentsResult;

@wire(getListUi, {
    objectApiName: DOCUMENT_OBJECT,
    listViewApiName: 'O_M_TBT_Documents',
    pageSize: 200
})
wiredDocuments(result) {
    this.wiredDocumentsResult = result;
    const { data, error } = result;

    if (data && this.userName) {
        const records = data.records.records;
        const match = records.find(
            rec => rec.fields.Submitted_Agent_Name__c.value === this.userName
        );

        if (match) {
        
            const apprStatus = match.fields.Approval_Status_O_M__c.value;

          

            if (apprStatus != 'Approved') {
             // this.showCheckBox = false;
              this.showtoast('Warning','Please Upload TBT Documents', 'warning');             
              this.handleCancel();
            }    
        }
        }
    
}



//  @wire(getRecord, { recordId: '$recordId', fields: [WORKTYPE_NAME] })
//     wiredWorkOrder({ error, data }) {
//         if (data) {
//             this.wOWorkType = data.fields.WorkType?.value?.fields?.Name?.value || '';
//             console.log('WorkType Name:', this.wOWorkType);
//             this.checkWorkType();


//         } else if (error) {
//             console.error('Error fetching WorkType Name:', error);
//         }
//     }


wiredWorkOrderResult; // store wire reference

@wire(getRecord, { recordId: '$recordId', fields: [WORKTYPE_NAME] })
wiredWorkOrder(result) {
    this.wiredWorkOrderResult = result; // store reference for refresh
    const { data, error } = result;

    if (data) {
        this.wOWorkType = data.fields.WorkType?.value?.fields?.Name?.value || '';
        console.log('WorkType Name:', this.wOWorkType);
        this.checkWorkType();
    } else if (error) {
        console.error('Error fetching WorkType Name:', error);
    }
}


     checkWorkType(){

        console.log('inside check work type');


         if(this.wOWorkType=='Riser Maintenance'){

          console.log('inside riser maintenance');


    //     this.showMaintenanceEntry=true;
    //    this.riserReplacementForm=false;
    //    this.riserPaintingCOExecution=false;

        this.riserPaintingRiserExecution =false;
        this.riserReplacementRiserExecution =false;
        this.showMaintenanceRiserExecution =true;
       
    
        }
       
        
        if(this.wOWorkType =='Riser Replacement'){

console.log('inside riser replacement');
            // this.showMaintenanceEntry=false;
            // this.riserReplacementForm=true;
            // this.riserPaintingCOExecution=false;

        this.riserPaintingRiserExecution =false;
        this.riserReplacementRiserExecution =true;
        this.showMaintenanceRiserExecution =false;
       
             


        }

          if(this.wOWorkType =='Riser Painting'){

            console.log('inside riser painting');
            // this.showMaintenanceEntry=false;
            // this.riserReplacementForm=false;
            // this.riserPaintingCOExecution=true;

        this.riserPaintingRiserExecution =true;
        this.riserReplacementRiserExecution =false;
        this.showMaintenanceRiserExecution =false;
       
            
        }


    }

    handleCloseFromChild(){

        console.log('inside handle close from child in parent');
        setTimeout(() => {
            history.back();
        }, 1000);        
         console.log('inside handle cancel');
    }

    handleCancel() {


       // this.accountView=false;
         setTimeout(() => {
            history.back();
        }, 1000);        
         console.log('inside handle cancel');
       
    }

     showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}