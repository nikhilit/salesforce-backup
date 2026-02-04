import { LightningElement, api, track } from 'lwc';

import getWOrderWType from '@salesforce/apex/COExecutionDetailsRiserContr.getWOrderWType';
import checkWorkStep from '@salesforce/apex/COExecutionDetailsRiserContr.checkWorkStep';
import getApprovalStatus from '@salesforce/apex/COExecutionDetailsRiserContr.getApprovalStatus';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';

export default class CoExecutionDetailsRiser extends NavigationMixin(LightningElement) {

    @api recordId;

          
     @track wOWorkType='';



    @track riserReplacementForm=false;
    @track showMaintenanceEntry=false;
    @track riserPaintingCOExecution=false;



   
   


    connectedCallback() {

        this.getWOrderWType();
     //   this.checkWorkStep();
     //   this.getApprovalStatus();
        
        
    }

    
   /*  tbt document from document__c object
    getApprovalStatus(){
    getApprovalStatus()
    .then( result=> {
        console.log('result of approval status', JSON.stringify(result));
        if(result.Approval_Status_O_M__c !='Approved'){

            //need to uncomment this part
        // this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
        // this.handleCancel();
       this.showMaintenanceEntry=false;
       this.riserReplacementForm=false;
       this.riserPaintingCOExecution=false;

        

        }

    })
    .catch(error => {

        console.log('Error ::',error);
    })
     } */

     getApprovalStatus(){
    getApprovalStatus()
    .then( result=> {
        console.log('result of approval status', JSON.stringify(result));
        if(result.Approval_Status__c !='Approved'){

        //     //need to uncomment this part
        //  this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
        //  this.handleCancel();
         LightningAlert.open({
            message: 'Please Upload TBT Documents.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
               this.handleCancel();
         });
       this.showMaintenanceEntry=false;
       this.riserReplacementForm=false;
       this.riserPaintingCOExecution=false;

        

        }

    })
    .catch(error => {

        console.log('Error ::',error);
    })
     }

    
 checkWorkStep(){
    console.log('inside check work order step');
    checkWorkStep({recordId:this.recordId})
    .then( result => {

        console.log('Result upload site status:::', result);
        if(result !='Completed'){
            console.log('inside new if');
            //need to uncomment this part
        //    this.showtoast('Warning', 'Please Complete Upload Site Document Task', 'warning');
        //      this.handleCancel();
          LightningAlert.open({
            message: 'Please Complete Upload Site Document Task',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
                 this.handleCancel();
         });
        }

       
    })
    .catch( error => {
        console.log('Error getting approval ::', error);
    })
  } 
   

    getWOrderWType(){
        getWOrderWType({recordId :this.recordId})
        .then( result => {
            console.log('Work Type Name ::', result);
        this.wOWorkType=result;
           this.checkWorkType();


        })
        .catch(error => {
            console.log('Error ::', error);
        })
    }

    

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