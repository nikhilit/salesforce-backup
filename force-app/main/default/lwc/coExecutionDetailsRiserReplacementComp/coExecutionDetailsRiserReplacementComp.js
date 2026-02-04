import { LightningElement,api,track } from 'lwc';
import saveCODetails from '@salesforce/apex/COExecutionDetailsRiserReplacementContr.saveCODetails';
import getWorkOrder from '@salesforce/apex/COExecutionDetailsRiserReplacementContr.getWorkOrder';
import LightningAlert from 'lightning/alert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CoExecutionDetailsRiserReplacementComp extends LightningElement {


  @api recordId;
    @track load = false;

        @track isReadOnly=false;




    @track risersNumber = '';
    @track risersFloors ='';
     @track riserPickListValue;

      @track customerDetails='';

        @track instrumentTypeRange = '';
    @track calibrationCertificateNo = '';
    @track instrumentSerialNumber = '';  
    @track calibrationDueDate = null;
    @track calibrationDate = null;

    //@track showEnterCustomerDetails=false;


   // @track havingBPValue;



     @track showSaveButton=true;

      @track showWorkOrderLineItems=false;



          typeOfRiserOptions = [
        { label: 'Welded', value: 'Welded' },
        { label: 'Threaded', value: 'Threaded' }
    ];

     havingBPOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];


      connectedCallback() {
        
        this.getWorkOrder();

    }

    /* handleHavingBPChange(event) {

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

    } */

    getWorkOrder(){

        getWorkOrder({recordId : this.recordId})

        .then( result => {

            console.log('Result getWorkOrder ::', JSON.stringify(result));
            if(result.Number_of_Risers__c){

              //  this.showSaveButton = false;

                 this.isReadOnly=true;


                this.risersNumber=result.Number_of_Risers__c;
                
                this.risersFloors = result.Number_of_Floors__c;
              
                this.riserPickListValue = result.Type_of_Riser__c;

                  this.instrumentTypeRange = result.RM_Instrument_Type_Range__c;
                this.calibrationCertificateNo = result.RM_Calibration_Certificate_No__c;
                this.calibrationDate = result.RM_Calibration_Date__c;
                this.calibrationDueDate = result.RM_Calibration_Due_Date__c;
                this.instrumentSerialNumber = result.Instrument_Serial_Number__c;

        //          this.havingBPValue = result.Any_customer_using_gas_but_not_having_bp__c;
        //         if(this.havingBPValue=='Yes'){
        //             this.showEnterCustomerDetails=true;
				// this.customerDetails = result.Customer_Details_Using_Gas_Not_Having_BP__c;
        //         }


                this.showWorkOrderLineItems=true;         


            }
            if(result.Number_of_Risers__c ==''){

                this.showSaveButton=true;
            }
        })
        .catch(Error => {

            console.log('Error ::', Error);
        })
    }


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



     handleRiserChange(event) {

        this.risersNumber = parseInt(event.target.value, 10);


        if (this.risersNumber >= 0 && this.risersNumber <= 25) {

      //  this.noOfPhotos = this.risersNumber; 
      //  this.showBeforeImage=true;
       // this.setPhotoUploadSlots();
       // this.afterPaintingNoOfPhotos=this.risersNumber;

        }

        else {
       this.risersNumber = null;
       
      //this.showtoast('Warning', 'Please Enter Valid Number.', 'warning');
       LightningAlert.open({
            message: 'Please Enter Valid Number.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
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

     handleSave(){

       if(this.load){
            return;
        }

        this.load=true;

          if ( this.risersNumber === null || this.risersNumber === undefined || this.risersNumber === '' ||
             !this.risersFloors || !this.riserPickListValue || !this.instrumentTypeRange ||
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

       
        saveCODetails({recordId : this.recordId, riserNumber: this.risersNumber,risersFloors : this.risersFloors, riserPickListValue : this.riserPickListValue,
                          instrumentTypeRange : this.instrumentTypeRange, calibrationCertificateNo : this.calibrationCertificateNo,
        calibrationDate : this.calibrationDate, calibrationDueDate : this.calibrationDueDate, instrumentSerialNumber : this.instrumentSerialNumber  })
    
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