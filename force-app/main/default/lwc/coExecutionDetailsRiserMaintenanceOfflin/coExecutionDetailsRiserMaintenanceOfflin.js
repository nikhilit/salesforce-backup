import { LightningElement,api,track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import saveCODetails from '@salesforce/apex/COExecutionDetailsRiserMaintenanceContr.saveCODetails';
//import getWorkOrder from '@salesforce/apex/COExecutionDetailsRiserMaintenanceContr.getWorkOrder';

//for offline

import {createRecord,updateRecord } from 'lightning/uiRecordApi';
import { getRecord } from 'lightning/uiRecordApi';

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


import { refreshApex } from "@salesforce/apex";
//import getWorkStepStatus from '@salesforce/apex/checkCustomerAvalibilityOfflineContr.getWorkStepStatus';


import NUMBER_OF_RISERS from '@salesforce/schema/WorkOrder.Number_of_Risers__c';
import SAMPLE_BP_1 from '@salesforce/schema/WorkOrder.Sample_BP_Number_1__c';
import SAMPLE_BP_2 from '@salesforce/schema/WorkOrder.Sample_BP_Number_2__c';
import INFO_BOARD from '@salesforce/schema/WorkOrder.Information_Board_available__c';
import FLOORS from '@salesforce/schema/WorkOrder.Number_of_Floors__c';
import RISER_TYPE from '@salesforce/schema/WorkOrder.Type_of_Riser__c';
import NEW_INFO_BOARD from '@salesforce/schema/WorkOrder.New_information_board_installed__c';
import INSTRUMENT_TYPE from '@salesforce/schema/WorkOrder.RM_Instrument_Type_Range__c';
import CERT_NO from '@salesforce/schema/WorkOrder.RM_Calibration_Certificate_No__c';
import CALIB_DATE from '@salesforce/schema/WorkOrder.RM_Calibration_Date__c';
import DUE_DATE from '@salesforce/schema/WorkOrder.RM_Calibration_Due_Date__c';
import SERIAL_NO from '@salesforce/schema/WorkOrder.Instrument_Serial_Number__c';


export default class CoExecutionDetailsRiserMaintenanceOfflin extends LightningElement {


  @api recordId;
    @track load = false;

    @track isReadOnly=false;

    @track workStepId='';




    @track risersNumber = '';
    @track risersFloors ='';
    @track sampleBP1 = '';
    @track sampleBP2 = '';
    @track boardAvailable='';
    @track newInformationBoardInstalled = '';
    @track instrumentTypeRange = '';
    @track calibrationCertificateNo = '';
    @track instrumentSerialNumber = '';

    @track calibrationDueDate = null;
    @track calibrationDate = null;

 @track riserPickListValue;


 @track showWorkOrderLineItems=false;

 @track showSaveButton=true;


 

    typeOfBoard = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];
      typeOfRiserOptions = [
        { label: 'Welded', value: 'Welded' },
        { label: 'Threaded', value: 'Threaded' }
    ];

   


    connectedCallback() {

       // this.getWorkStepStatus();

          if (this.wiredWorkOrderResult) {
                refreshApex(this.wiredWorkOrderResult);
            }
        
      //  this.getWorkOrder();
    }

    wiredWorkOrderResult; // store wire result reference

    @wire(getRecord, { recordId: '$recordId', fields: [ NUMBER_OF_RISERS,
            SAMPLE_BP_1,
            SAMPLE_BP_2,
            INFO_BOARD,
            FLOORS,
            RISER_TYPE,
            NEW_INFO_BOARD,
            INSTRUMENT_TYPE,
            CERT_NO,
            CALIB_DATE,
            DUE_DATE,
            SERIAL_NO,
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
            this.sampleBP1 = data.fields.Sample_BP_Number_1__c.value;
            this.sampleBP2 = data.fields.Sample_BP_Number_2__c.value;
            this.boardAvailable = data.fields.Information_Board_available__c.value;
            this.risersFloors = data.fields.Number_of_Floors__c.value;
            this.riserPickListValue = data.fields.Type_of_Riser__c.value;
            this.newInformationBoardInstalled = data.fields.New_information_board_installed__c.value;
            this.instrumentTypeRange = data.fields.RM_Instrument_Type_Range__c.value;
            this.calibrationCertificateNo = data.fields.RM_Calibration_Certificate_No__c.value;
            this.calibrationDate = data.fields.RM_Calibration_Date__c.value;
            this.calibrationDueDate = data.fields.RM_Calibration_Due_Date__c.value;
            this.instrumentSerialNumber = data.fields.Instrument_Serial_Number__c.value;
           
             this.showWorkOrderLineItems=true;

            if(this.boardAvailable=='No'){

            this.showNewInformationBoarInstalled=true;
        }
         if(this.boardAvailable!='No'){

            this.showNewInformationBoarInstalled=false;
        }                

         }
          if(data.fields.Number_of_Risers__c.value ==''){

                this.showSaveButton=true;
            }

    } else if (error) {
        console.error(' Error fetching user:', error);
    }
}

   /* getWorkOrder(){

        getWorkOrder({recordId : this.recordId})

        .then( result => {

            console.log('Result getWorkOrder ::', JSON.stringify(result));
            if(result.Number_of_Risers__c){

                this.showSaveButton = false;

                this.isReadOnly=true;

                this.risersNumber=result.Number_of_Risers__c;
                this.sampleBP1 = result.Sample_BP_Number_1__c;
                this.sampleBP2 = result.Sample_BP_Number_2__c;
                this.risersFloors = result.Number_of_Floors__c;
                this.boardAvailable = result.Information_Board_available__c;
                this.newInformationBoardInstalled = result.New_information_board_installed__c;
                this.riserPickListValue = result.Type_of_Riser__c;
                this.instrumentTypeRange = result.RM_Instrument_Type_Range__c;
                this.calibrationCertificateNo = result.RM_Calibration_Certificate_No__c;
                this.calibrationDate = result.RM_Calibration_Date__c;
                this.calibrationDueDate = result.RM_Calibration_Due_Date__c;
                this.instrumentSerialNumber = result.Instrument_Serial_Number__c;
 

                this.showWorkOrderLineItems=true;

            if(this.boardAvailable=='No'){

            this.showNewInformationBoarInstalled=true;
        }
         if(this.boardAvailable!='No'){

            this.showNewInformationBoarInstalled=false;
        }                


            }
            if(result.Number_of_Risers__c ==''){

                this.showSaveButton=true;
            }
        })
        .catch(Error => {

            console.log('Error ::', Error);
        })
    } */


    // handleCancel(){
    //   setTimeout(() => {
    //         history.back();
    //     }, 1000); 

    // }

    handleInstrumentType(event){

        console.log('instrumentTypeRange ::', event.target.value);

        this.instrumentTypeRange=event.target.value;
    }

    handleCalibrationCertificateNo(event){

     console.log('calibrationCertificateNo ::', event.target.value);

        this.calibrationCertificateNo=event.target.value;
    }

    handleCalibrationDate(event){
     console.log('calibrationDate ::', event.target.value);
    this.calibrationDate=event.target.value;

    }

    handleCalibrationDueDate(event){

     console.log('calibrationDueDate ::', event.target.value);

        this.calibrationDueDate=event.target.value;
    }

     handleInstrumentSerialNumber(event){

     console.log('instrumentSerialNumber ::', event.target.value);

        this.instrumentSerialNumber=event.target.value;
    }



      handlePicklistChange(event) {

        console.log('handle pick list value ::', event.target.value);
        this.riserPickListValue = event.target.value;

    }

     handleRiserChange(event) {

        this.risersNumber = parseInt(event.target.value, 10);


        if (this.risersNumber >= 1 && this.risersNumber <= 20) {

        // this.currentRiserView = 1;
        // this.initializeRiserData();
        // if(this.risersNumber){
        // this.showNextButton=true;
        // this.showMaintenanceDetail=false;
       // }

        }

        else {
       this.risersNumber = null;
        // this.showNextButton = false;
        // this.showMaintenanceDetail = false;
      this.showtoast('Warning', 'Please Enter Valid Number.', 'warning');

        }
       // this.handleNextShowDetails();

    }

    handleFloorChange(event){

        this.risersFloors=event.target.value;
        console.log('Inside handle Floor change ::', this.risersFloors);

    }

    handleBP1Change(event){

        this.sampleBP1 = event.target.value;
        console.log('Inside handlebp1change ::', this.sampleBP1);
    }

    handleBP2Change(event){

        this.sampleBP2=event.target.value;
        console.log('Inside handlebp2change :::', this.sampleBP2);
    }

    handleRemarkChange(event){

        this.afterImageRemark = event.target.value;
    }

    handleboardAvailableChange(event){

        this.boardAvailable = event.target.value;

        if(this.boardAvailable=='No'){

            this.showNewInformationBoarInstalled=true;
        }
         if(this.boardAvailable!='No'){

            this.showNewInformationBoarInstalled=false;
            this.newInformationBoarInstalled='';
        }
    }

     handleNewBoardInstalledChange(event){

        this.newInformationBoardInstalled = event.target.value;
    }

   /*  getWorkStepStatus(){

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



    async handleSave(){

        this.load=true;

        try {

          if (!this.risersNumber  || (!this.sampleBP1  && !this.sampleBP2) ||
           !this.boardAvailable || !this.risersFloors || !this.riserPickListValue || !this.instrumentTypeRange ||
           !this.calibrationCertificateNo || !this.calibrationDate || !this.calibrationDueDate || !this.instrumentSerialNumber ) {
            this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
            this.load=false;
            return;
        }


         const fields = {
                
                Id: this.recordId,
                Number_of_Risers__c: String(this.risersNumber),
                Sample_BP_Number_1__c: this.sampleBP1,
                Sample_BP_Number_2__c : this.sampleBP2,
                Information_Board_available__c : this.boardAvailable,
                Number_of_Floors__c : this.risersFloors,
                Type_of_Riser__c : this.riserPickListValue,
                New_information_board_installed__c : this.newInformationBoardInstalled,
                RM_Instrument_Type_Range__c : this.instrumentTypeRange,
                RM_Calibration_Certificate_No__c : this.calibrationCertificateNo,
                RM_Calibration_Date__c : this.calibrationDate,
                RM_Calibration_Due_Date__c : this.calibrationDueDate,
                Instrument_Serial_Number__c : this.instrumentSerialNumber
                
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
       // const riserCount = Number(this.risersNumber);

        console.log('risercount ::', riserCount);

        for (let i = 1; i <= riserCount; i++) {
            console.log('inside for loop');
            const fields = {};
            fields[RISER_NAME.fieldApiName] = `Riser ${i}`;
            fields[WORKORDER_ID.fieldApiName] = this.recordId;

            const recordInput = { apiName: WORKORDER_LINE_ITEM_OBJECT.objectApiName, fields };
            await createRecord(recordInput);

           // await new Promise(resolve => setTimeout(resolve, 200));


            console.log(`✅ Created WorkOrderLineItem: Riser ${i}`);
        }
    } catch (error) {
        console.error('⚠️ Error creating WorkOrderLineItems:', error);
    }
}



    /* handleSave(){

        this.load=true;

          if (!this.risersNumber  || (!this.sampleBP1  && !this.sampleBP2) ||
           !this.boardAvailable || !this.risersFloors || !this.riserPickListValue || !this.instrumentTypeRange ||
           !this.calibrationCertificateNo || !this.calibrationDate || !this.calibrationDueDate || !this.instrumentSerialNumber ) {
            this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
            this.load=false;
            return;
        }

        saveCODetails({recordId : this.recordId, riserNumber: this.risersNumber, sampleBP1: this.sampleBP1, 
        sampleBP2: this.sampleBP2, boardAvailable : this.boardAvailable,risersFloors : this.risersFloors, 
        riserPickListValue : this.riserPickListValue, newInformationBoardInstalled : this.newInformationBoardInstalled,
        instrumentTypeRange : this.instrumentTypeRange, calibrationCertificateNo : this.calibrationCertificateNo,
        calibrationDate : this.calibrationDate, calibrationDueDate : this.calibrationDueDate, instrumentSerialNumber : this.instrumentSerialNumber})
    
        .then(result => {

             this.showtoast('Success', 'Details Saved Successfully', 'success');
            console.log('Result savecodetails::', result);
             this.load=false;
            // this.handleCancel();
                     
            this.dispatchEvent(new CustomEvent ('cancel'));



        })
        .catch(Error => {

            console.log('Error savecodetails::', Error);
          this.load=false;

        })
    }

  */




     showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}