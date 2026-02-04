import { LightningElement,api,track,wire } from 'lwc';
//import saveCODetails from '@salesforce/apex/COExecutionDetailsRiserReplacementContr.saveCODetails';
//import getWorkOrder from '@salesforce/apex/COExecutionDetailsRiserReplacementContr.getWorkOrder';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//lds offline

import { getRecord } from 'lightning/uiRecordApi';
import {createRecord,updateRecord } from 'lightning/uiRecordApi';
import WORKORDER_LINE_ITEM_OBJECT from '@salesforce/schema/WorkOrderLineItem';
import RISER_NAME from '@salesforce/schema/WorkOrderLineItem.Riser_Name__c';
import WORKORDER_ID from '@salesforce/schema/WorkOrderLineItem.WorkOrderId';
import { getRelatedListRecords } from "lightning/uiRelatedListApi";

//import getWorkStepStatus from '@salesforce/apex/checkCustomerAvalibilityOfflineContr.getWorkStepStatus';
import WORKSTEP_OBJECT from '@salesforce/schema/WorkStep';
import ID_FIELD from '@salesforce/schema/WorkStep.Id';
import STATUS_FIELD from '@salesforce/schema/WorkStep.Status';
import NAME_FIELD from '@salesforce/schema/WorkStep.Name';
import PARENT_FIELD from '@salesforce/schema/WorkStep.ParentRecordId';
import { getFieldValue } from 'lightning/uiRecordApi';

import CustomerUsingGas_NotHavingBP from '@salesforce/schema/WorkOrder.Any_customer_using_gas_but_not_having_bp__c';
import CustomerDetails_NotHavingBP from '@salesforce/schema/WorkOrder.Customer_Details_Using_Gas_Not_Having_BP__c';


import NUMBER_OF_RISERS from '@salesforce/schema/WorkOrder.Number_of_Risers__c';
import FLOORS from '@salesforce/schema/WorkOrder.Number_of_Floors__c';
import RISER_TYPE from '@salesforce/schema/WorkOrder.Type_of_Riser__c';
import { refreshApex } from "@salesforce/apex";

export default class CoExecutionDetailsRiserReplacementOfflin extends LightningElement {


  @api recordId;
    @track load = false;

        @track isReadOnly=false;
        @track workStepId='';

@track havingBPValue;
  @track customerDetails='';

    @track showEnterCustomerDetails=false;


    @track risersNumber = '';
    @track risersFloors ='';
     @track riserPickListValue;

     @track showSaveButton=true;

      @track showWorkOrderLineItems=false;

havingBPOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

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

    }

    // getWorkOrder(){

    //     getWorkOrder({recordId : this.recordId})

    //     .then( result => {

    //         console.log('Result getWorkOrder ::', JSON.stringify(result));
    //         if(result.Number_of_Risers__c){

    //             this.showSaveButton = false;

    //              this.isReadOnly=true;


    //             this.risersNumber=result.Number_of_Risers__c;
                
    //             this.risersFloors = result.Number_of_Floors__c;
              
    //             this.riserPickListValue = result.Type_of_Riser__c;


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

       handleHavingBPChange(event) {

        console.log('handle having bp list value ::', event.target.value);
        this.havingBPValue = event.target.value;

        if(this.havingBPValue =='Yes'){

            this.showEnterCustomerDetails=true;

            }
            else{

              this.showEnterCustomerDetails=false;

            }

    }

     handleCustomerDetailChange(event) {

        console.log('handle customer detail change ::', event.target.value);
        this.customerDetails = event.target.value;

    }

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
            CustomerUsingGas_NotHavingBP,
            CustomerDetails_NotHavingBP,
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

             this.havingBPValue = data.fields.Any_customer_using_gas_but_not_having_bp__c.value;

                if(this.havingBPValue=='Yes'){
                    this.showEnterCustomerDetails=true;
				this.customerDetails = data.fields.Customer_Details_Using_Gas_Not_Having_BP__c.value;
                 
                }
           

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
      //  this.showBeforeImage=true;
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

    async handleSave(){

        this.load=true;

         try {

          if (!this.risersNumber  ||  !this.risersFloors || !this.riserPickListValue
          || !this.havingBPValue || (this.havingBPValue =='Yes' && !this.customerDetails)) {
            this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
            this.load=false;
            return;
        }

            const fields = {
                
                Id: this.recordId,
                Number_of_Risers__c: String(this.risersNumber),            
                Number_of_Floors__c : this.risersFloors,
                Type_of_Riser__c : this.riserPickListValue,
                Any_customer_using_gas_but_not_having_bp__c : this.havingBPValue,
				Customer_Details_Using_Gas_Not_Having_BP__c : this.customerDetails
               
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


     


    //  handleSave(){

    //     this.load=true;

    //       if (!this.risersNumber  ||  !this.risersFloors || !this.riserPickListValue) {
    //         this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
    //         this.load=false;
    //         return;
    //     }

       
    //     saveCODetails({recordId : this.recordId, riserNumber: this.risersNumber,risersFloors : this.risersFloors, riserPickListValue : this.riserPickListValue})
    
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


     showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}