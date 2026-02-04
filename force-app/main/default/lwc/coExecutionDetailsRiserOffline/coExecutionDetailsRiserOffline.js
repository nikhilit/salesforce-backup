import { LightningElement, api, track,wire } from 'lwc';

//import getWOrderWType from '@salesforce/apex/COExecutionDetailsRiserContr.getWOrderWType';
//import checkWorkStep from '@salesforce/apex/COExecutionDetailsRiserContr.checkWorkStep';
//import getApprovalStatus from '@salesforce/apex/COExecutionDetailsRiserContr.getApprovalStatus';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

//offline

import { getRecord } from 'lightning/uiRecordApi';
import WORKTYPE_NAME from '@salesforce/schema/WorkOrder.WorkType.Name';
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import DOCUMENT_OBJECT from '@salesforce/schema/Document__c';
import { getListUi } from 'lightning/uiListApi';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Username';
import { refreshApex } from "@salesforce/apex";

export default class CoExecutionDetailsRiserOffline extends NavigationMixin(LightningElement) {

    @api recordId;

          
     @track wOWorkType='';

    @track siteDocumentsStatus='';

    @track userName ='';


    @track riserReplacementForm=false;
    @track showMaintenanceEntry=false;
    @track riserPaintingCOExecution=false;



   
   


   // connectedCallback() {

       // this.getWOrderWType();

      //  this.checkWorkStep();
      //  this.getApprovalStatus();

        
        
  //  }

    //   getApprovalStatus(){
    // getApprovalStatus()
    // .then( result=> {
    //     console.log('result of approval status', JSON.stringify(result));
    //     if(result.Approval_Status_O_M__c !='Approved'){

    //     this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
    //     this.handleCancel();
    //    this.showMaintenanceEntry=false;
    //    this.riserReplacementForm=false;
    //    this.riserPaintingCOExecution=false;

        

    //     }

    // })
    // .catch(error => {

    //     console.log('Error ::',error);
    // })
    //  }

//      checkWorkStep(){
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

        const checkInStep = records.find(r => r.fields.Name.value === 'Upload Site Documents');

        this.siteDocumentsStatus = checkInStep ? checkInStep.fields.Status.value : 'Not Found';

        console.log('siteDocumentsStatus Status:', this.siteDocumentsStatus);

        if (this.siteDocumentsStatus !== 'Completed') {


                this.showtoast('Warning','Please Complete Upload Site Documents Task', 'warning');
        
               this.handleCancel();

        }

    }
       
}


    @wire(getRecord, { recordId: '$recordId', fields: [WORKTYPE_NAME] })
    wiredWorkOrder({ error, data }) {
        if (data) {
            this.wOWorkType = data.fields.WorkType?.value?.fields?.Name?.value || '';
            console.log('WorkType Name:', this.wOWorkType);
            this.checkWorkType();


        } else if (error) {
            console.error('Error fetching WorkType Name:', error);
        }
    }

    wiredUserResult; 

@wire(getRecord, { recordId: USER_ID, fields: [USER_NAME] })
wiredUser(result) {
    this.wiredUserResult = result; 
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


   

    // getWOrderWType(){
    //     getWOrderWType({recordId :this.recordId})
    //     .then( result => {
    //         console.log('Work Type Name ::', result);
    //     this.wOWorkType=result;
    //        this.checkWorkType();


    //     })
    //     .catch(error => {
    //         console.log('Error ::', error);
    //     })
    // }

    

    checkWorkType(){

        console.log('inside check work type');


    if(this.wOWorkType=='Riser Maintenance'){

          console.log('inside riser maintenance');


        this.showMaintenanceEntry=true;
       this.riserReplacementForm=false;
       this.riserPaintingCOExecution=false;
       
    
        }
       
        
        if(this.wOWorkType =='Riser Replacement'){

console.log('inside riser replacement');
            this.showMaintenanceEntry=false;
            this.riserReplacementForm=true;
            this.riserPaintingCOExecution=false;
             


        }

          if(this.wOWorkType =='Riser Painting'){

            console.log('inside riser painting');
            this.showMaintenanceEntry=false;
            this.riserReplacementForm=false;
            this.riserPaintingCOExecution=true;
            
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