import { LightningElement,api,track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//import getWorkOrder from '@salesforce/apex/COExecutionDetailsRiserPaintingContr.getWorkOrder';
import saveCODetails from '@salesforce/apex/COExecutionDetailsRiserPaintingContr.saveCODetails';


//lds offline

import { getRecord } from 'lightning/uiRecordApi';
import {createRecord,updateRecord } from 'lightning/uiRecordApi';
import WORKORDER_LINE_ITEM_OBJECT from '@salesforce/schema/WorkOrderLineItem';
import RISER_NAME from '@salesforce/schema/WorkOrderLineItem.Riser_Name__c';
import WORKORDER_ID from '@salesforce/schema/WorkOrderLineItem.WorkOrderId';

import WORKSTEP_OBJECT from '@salesforce/schema/WorkStep';
import ID_FIELD from '@salesforce/schema/WorkStep.Id';
import STATUS_FIELD from '@salesforce/schema/WorkStep.Status';
import NAME_FIELD from '@salesforce/schema/WorkStep.Name';
import PARENT_FIELD from '@salesforce/schema/WorkStep.ParentRecordId';
import { getFieldValue } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from "lightning/uiRelatedListApi";


//import getWorkStepStatus from '@salesforce/apex/checkCustomerAvalibilityOfflineContr.getWorkStepStatus';



import NUMBER_OF_RISERS from '@salesforce/schema/WorkOrder.Number_of_Risers__c';
import FLOORS from '@salesforce/schema/WorkOrder.Number_of_Floors__c';
import RISER_TYPE from '@salesforce/schema/WorkOrder.Type_of_Riser__c';
import Length_ApprocahRiser from '@salesforce/schema/WorkOrder.Length_Of_Approcah_Riser__c';

import { refreshApex } from "@salesforce/apex";


export default class CoExecutionDetailsRiserPaintingOffline extends LightningElement {

    @api recordId;
    @track load = false;

        @track workStepId='';


        @track isReadOnly=false;




    @track risersNumber = '';
    @track risersFloors ='';
    @track riserPickListValue;
    @track approcahRiserLength='';

     @track showWorkOrderLineItems=false;


    //@track showBeforeImage=false;

    //   @track photoUploadSlots=[];
    //     noOfPhotos;

        
    // @track afterPaintingPhotoUploadSlots=[];
    //     afterPaintingNoOfPhotos;  

     @track showSaveButton=true;


       typeOfRiserOptions = [
        { label: 'Welded', value: 'Welded' },
        { label: 'Threaded', value: 'Threaded' }
    ];


      connectedCallback() {

              //  this.getWorkStepStatus();


         if (this.wiredWorkOrderResult) {
                refreshApex(this.wiredWorkOrderResult);
            }
        
       // this.getWorkOrder();
       // this.setAfterPaintingPhotoUploadSlots();

    }

    // getWorkOrder(){

    //     getWorkOrder({recordId : this.recordId})

    //     .then( result => {

    //         console.log('Result getWorkOrder ::', JSON.stringify(result));
    //         if(result.Number_of_Risers__c){

    //             this.showSaveButton = false;

    //             this.isReadOnly=true;


    //             this.risersNumber=result.Number_of_Risers__c;
                
    //             this.risersFloors = result.Number_of_Floors__c;
              
    //             this.riserPickListValue = result.Type_of_Riser__c;

    //             this.approcahRiserLength= result.Length_Of_Approcah_Riser__c;

    //             this.showWorkOrderLineItems=true;         


    //         }
    //         if(result.Number_of_Risers__c ==''){

    //             this.showSaveButton=true;
    //         }
    //     })
    //     .catch(Error => {

    //         console.log('Error ::', Error);
    //     })
    // }


    /* getWorkStepStatus(){

        getWorkStepStatus({workOrderId : this.recordId, name:'CO Execution Detail'})

        .then( result => {

            console.log('WorkStep Id Result:: ', result);
            this.workStepId = result;
        })
        .catch(error => {

                console.log('Error getting workstep id::', error);
        })
       } */

        @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkSteps', // Related List API name on WorkOrder
        fields: ['WorkStep.Id', 'WorkStep.Name']
    })
    wiredWorkSteps({ data, error }) {
        if (data) {
            console.log('Related WorkSteps:', data);
            // Filter by Name
            const ws = data.records.find(r => r.fields.Name.value === 'CO Execution Detail');
            if (ws) {

                this.workStepId = ws.id;
                console.log('Selected WorkStep Id for CO Execution Detail task:', this.workStepId);
            }
        } else if (error) {
            console.error('Error fetching related WorkSteps:', error);
        }
    }

       async updateWorkStepStatus() {
        try {
            // Prepare field map
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.workStepId;
            fields[STATUS_FIELD.fieldApiName] = 'Completed'; 

            const recordInput = { fields };

            await updateRecord(recordInput);

          //  this.showToast('Success', 'WorkStep updated to Completed', 'success');
           // console.log('✅ WorkStep updated successfully');
        } catch (error) {
           // console.error('⚠️ Error updating WorkStep:', error);
          //  this.showToast('Error', error.body?.message || error.message, 'error');
        }
    }



      wiredWorkOrderResult; // store wire result reference

    @wire(getRecord, { recordId: '$recordId', fields: [ NUMBER_OF_RISERS,
            RISER_TYPE,
            FLOORS,
            Length_ApprocahRiser
             ] })
    wiredWorkOrder(result) {
    this.wiredWorkOrderResult  = result; 
    const { data, error } = result;

    if (data) {

        console.log('inside data found using wire::', JSON.stringify(data));
         if(data.fields.Number_of_Risers__c.value){

                this.showSaveButton = false;

                this.isReadOnly=true;

         
            this.risersNumber = data.fields.Number_of_Risers__c.value;
            this.risersFloors = data.fields.Number_of_Floors__c.value;
            this.riserPickListValue = data.fields.Type_of_Riser__c.value;
            this.approcahRiserLength = data.fields.Length_Of_Approcah_Riser__c.value;


             this.showWorkOrderLineItems=true;

                     

         }
          if(data.fields.Number_of_Risers__c.value ==''){

                this.showSaveButton=true;
            }

    } else if (error) {
        console.error(' Error fetching user:', error);
    }
}



  handleRiserChange(event) {

        this.risersNumber = parseInt(event.target.value, 10);


        if (this.risersNumber >= 1 && this.risersNumber <= 20) {

      //  this.noOfPhotos = this.risersNumber; 
        this.showBeforeImage=true;
       // this.setPhotoUploadSlots();
       // this.afterPaintingNoOfPhotos=this.risersNumber;

        }

        else {
       this.risersNumber = null;
       
      this.showtoast('Warning', 'Please Enter Valid Number.', 'warning');

        }

    }

    handleFloorChange(event){

        this.risersFloors=event.target.value;
        console.log('Inside handle Floor change ::', this.risersFloors);

    }

      handlePicklistChange(event) {

        console.log('handle pick list value ::', event.target.value);
        this.riserPickListValue = event.target.value;

    }

 handleLengthChange(event) {

        console.log('handle length change value ::', event.target.value);
        this.approcahRiserLength = event.target.value;

    }

    //  handleSave(){

    //     this.load=true;

    //       if (!this.risersNumber  ||  !this.risersFloors || !this.riserPickListValue || !this.approcahRiserLength ) {
    //         this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
    //         this.load=false;
    //         return;
    //     }

    //     saveCODetails({recordId : this.recordId, riserNumber: this.risersNumber,risersFloors : this.risersFloors, riserPickListValue : this.riserPickListValue, approcahRiserLength : this.approcahRiserLength})
    
    //     .then(result => {

    //          this.showtoast('Success', 'Details Saved Successfully', 'success');
    //         console.log('Result savecodetails::', result);
    //          this.load=false;
    //         // this.handleCancel();
    //         this.dispatchEvent(new CustomEvent ('cancel'));



    //     })
    //     .catch(Error => {

    //         console.log('Error savecodetails::', Error);
    //       this.load=false;

    //     })
    // }


     async handleSave(){

        this.load=true;

         try {

          if (!this.risersNumber  ||  !this.risersFloors || !this.riserPickListValue || !this.approcahRiserLength) {
            this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
            this.load=false;
            return;
        }

            const fields = {
                
                Id: this.recordId,
                Number_of_Risers__c: String(this.risersNumber),            
                Number_of_Floors__c : this.risersFloors,
                Type_of_Riser__c : this.riserPickListValue,
                Length_Of_Approcah_Riser__c : this.approcahRiserLength,

            };

            await updateRecord({ fields });

            await this.createWorkOrderLineItems();

            await this.updateWorkStepStatus();

             this.showtoast('Success', 'Details Saved Successfully', 'success');
             this.load=false;
                     
            this.dispatchEvent(new CustomEvent ('cancel'));



        }
        catch(error){

            console.log('Error updating workorder ::', error);
            this.load=false;

        }

    }

    async createWorkOrderLineItems() {
    try {

        console.log('inside createWorkOrderLineItems::', this.recordId);

        const riserCount = parseInt(this.risersNumber, 10);

        console.log('risercount ::', riserCount);



        for (let i = 1; i <= riserCount; i++) {
            console.log('inside for loop');
            const fields = {};
            fields[RISER_NAME.fieldApiName] = `Riser ${i}`;
            fields[WORKORDER_ID.fieldApiName] = this.recordId;

            const recordInput = { apiName: WORKORDER_LINE_ITEM_OBJECT.objectApiName, fields };
           
            await createRecord(recordInput);

            console.log(`Created WorkOrderLineItem: Riser ${i}`);
        }

    } catch (error) {
        console.error('Error creating WorkOrderLineItems:', error);
    }
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