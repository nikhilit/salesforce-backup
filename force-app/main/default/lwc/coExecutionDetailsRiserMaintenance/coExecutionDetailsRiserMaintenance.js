import { LightningElement,api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveCODetails from '@salesforce/apex/COExecutionDetailsRiserMaintenanceContr.saveCODetails';
import getWorkOrder from '@salesforce/apex/COExecutionDetailsRiserMaintenanceContr.getWorkOrder';
import getServiceAppointment from '@salesforce/apex/COExecutionDetailsRiserMaintenanceContr.getServiceAppointment';
import LightningAlert from 'lightning/alert';
export default class CoExecutionDetailsRiserMaintenance extends LightningElement {


  @api recordId;
    @track load = false;

    @track isReadOnly=false;



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

 //@track showAddRiserComp=false;

 @track showSaveButton=true;

 @track isanycopperleakagefound='';
@track copperLeakageFoundNotificationNo='';

@track isanycrimpguardleakagefound='';
@track crimpLeakageFoundNotificationNo='';

@track isanySRleakagefound='';
@track srLeakageFountNotificationNo='';

@track anyOneYes=false;

@track showCopperLeakageFound=false;
@track showCrimpGuardleakageFound=false;
@track showSRLeakageFound=false;




    typeOfBoard = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];
      typeOfRiserOptions = [
        { label: 'Welded', value: 'Welded' },
        { label: 'Threaded', value: 'Threaded' }
    ];
   
   valvesReplacedOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    connectedCallback() {
        
        this.getWorkOrder();
        this.getServiceAppointment();
    }

   


    handleCopperLeakageFoundChange(event){

        this.isanycopperleakagefound = event.target.value;

        if(event.target.value=='Yes'){

            this.showCopperLeakageFound=true;
        }
        else{

            this.showCopperLeakageFound=false;
            this.copperLeakageFoundNotificationNo='';
        }

    }

    handleCopperLeakNotificationNumberChange(event){

        this.copperLeakageFoundNotificationNo=event.target.value;
    }

    handleCrimpGuardLeakageFoundChange(event){

           this.isanycrimpguardleakagefound = event.target.value;

        if(event.target.value=='Yes'){

            this.showCrimpGuardleakageFound=true;
        }
          else{

            this.showCrimpGuardleakageFound=false;
            this.crimpLeakageFoundNotificationNo='';


        }
    }

handleCrimpLeakFoundNotificationChange(event){

 this.crimpLeakageFoundNotificationNo=event.target.value;

}

handleSRLeakageFoundChange(event){

       this.isanySRleakagefound = event.target.value;

        if(event.target.value=='Yes'){

            this.showSRLeakageFound=true;
        }
        else{

            this.showSRLeakageFound=false;
            this.srLeakageFountNotificationNo='';

        }
}

handleSrLeakageNotificationChange(event){

     this.srLeakageFountNotificationNo=event.target.value;

}



    getWorkOrder(){

        getWorkOrder({recordId : this.recordId})

        .then( result => {

            console.log('Result getWorkOrder ::', JSON.stringify(result));
            if(result.Number_of_Risers__c){

               // this.showSaveButton = false;

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
    }

     getServiceAppointment(){

        getServiceAppointment({recordId : this.recordId})

        .then( result => {

         
            console.log('Result getserviceappointment ::', JSON.stringify(result));

                 this.isanycopperleakagefound = result.Is_Any_Copper_Leakage_Found__c;

                 this.isanycrimpguardleakagefound = result.Is_Any_Crimp_Guard_Leakage_Found__c;

                 this.isanySRleakagefound = result.Is_Any_SR_Leakage_Found__c;

             if(result.Is_Any_Copper_Leakage_Found__c =='Yes'){   

                this.showCopperLeakageFound=true;
                 this.copperLeakageFoundNotificationNo = result.CopperLeakageFoundNotificationNo__c;
                //  this.crimpLeakageFoundNotificationNo = result.CrimpLeakageFoundNotificationNo__c;
                //  this.srLeakageFountNotificationNo = result.SRLeakageFountNotificationNo__c;

             }

             if(result.Is_Any_Crimp_Guard_Leakage_Found__c =='Yes'){

                this.showCrimpGuardleakageFound=true;
                  this.crimpLeakageFoundNotificationNo = result.CrimpLeakageFoundNotificationNo__c;

             }

             if(result.Is_Any_SR_Leakage_Found__c=='Yes'){


                this.showSRLeakageFound=true;
             this.srLeakageFountNotificationNo = result.SRLeakageFountNotificationNo__c;


             }




          
        })
        .catch(Error => {

            console.log('Error ::', Error);
        })
    }

// handleAddRiserCancel(){

//     this.showAddRiserComp=false;
//     this.showWorkOrderLineItems=true;
//     this.getWorkOrder();

//     this.dispatchEvent(new CustomEvent ('cancel'));


// }

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


        if (this.risersNumber >= 0 && this.risersNumber <= 25) {

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
     // this.showtoast('Warning', 'Please Enter Valid Number.', 'warning');
     LightningAlert.open({
            message: 'Please Enter Valid Number.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
        }
       // this.handleNextShowDetails();

    }

    // handleShowAddRiser(){

    //     this.showAddRiserComp=true;
    //     this.showWorkOrderLineItems=false;
    // }

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


     handleSave(){
        
        if(this.load){
            return;
        }

        this.load=true;

          if ( this.risersNumber === null || this.risersNumber === undefined || this.risersNumber === '' ||
             (!this.sampleBP1  && !this.sampleBP2) ||
           !this.boardAvailable || !this.risersFloors || !this.riserPickListValue || !this.instrumentTypeRange ||
           !this.calibrationCertificateNo || !this.calibrationDate || !this.calibrationDueDate || !this.instrumentSerialNumber ) {
            // this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
            // this.load=false;
             LightningAlert.open({
            message: 'Please Enter All Required Fields',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
                    this.load=false;
         });
            return;
        }

        saveCODetails({recordId : this.recordId, riserNumber: this.risersNumber, sampleBP1: this.sampleBP1, 
        sampleBP2: this.sampleBP2, boardAvailable : this.boardAvailable,risersFloors : this.risersFloors, 
        riserPickListValue : this.riserPickListValue, newInformationBoardInstalled : this.newInformationBoardInstalled,
        instrumentTypeRange : this.instrumentTypeRange, calibrationCertificateNo : this.calibrationCertificateNo,
        calibrationDate : this.calibrationDate, calibrationDueDate : this.calibrationDueDate, instrumentSerialNumber : this.instrumentSerialNumber,
        isanycopperleakagefound : this.isanycopperleakagefound, copperLeakageFoundNotificationNo: this.copperLeakageFoundNotificationNo, isanycrimpguardleakagefound : this.isanycrimpguardleakagefound,
        crimpLeakageFoundNotificationNo : this.crimpLeakageFoundNotificationNo, isanySRleakagefound : this.isanySRleakagefound, srLeakageFountNotificationNo : this.srLeakageFountNotificationNo })
    
        .then(result => {

            //  this.showtoast('Success', 'Details Saved Successfully', 'success');
            // console.log('Result savecodetails::', result);
            //  this.load=false;
            // // this.handleCancel();
                     
            // this.dispatchEvent(new CustomEvent ('cancel'));
             LightningAlert.open({
            message: 'Details Saved Successfully',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                    this.load=false;
                    this.dispatchEvent(new CustomEvent ('cancel'));
         });


        })
        .catch(Error => {

            console.log('Error savecodetails::', Error);
          this.load=false;

        })
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