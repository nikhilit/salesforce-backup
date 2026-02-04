import { LightningElement, api, track } from 'lwc';

import getBPBasedOnConnectionNumber from '@salesforce/apex/RiserReplacementController.getBPBasedOnConnectionNumber';
import updateAccounts from '@salesforce/apex/RiserReplacementController.updateAccounts';
import saveImage from '@salesforce/apex/RiserReplacementController.saveImage';


import saveGaugeCalibrationDetails from '@salesforce/apex/RiserReplacementController.saveGaugeCalibrationDetails';
import getServiceAppointmentId from '@salesforce/apex/RiserReplacementController.getServiceAppointmentId';
import saveCustomerDetails from '@salesforce/apex/RiserReplacementController.saveCustomerDetails';
import saveRiserTestingDetails from '@salesforce/apex/RiserReplacementController.saveRiserTestingDetails';
import saveMaterialDetails from '@salesforce/apex/RiserReplacementController.saveMaterialDetails';
import savePhotoUploadsReversal from '@salesforce/apex/RiserReplacementController.savePhotoUploadsReversal';
import savePhotoUploadsLPG from '@salesforce/apex/RiserReplacementController.savePhotoUploadsLPG';
import savePhotoUploadsMeter from '@salesforce/apex/RiserReplacementController.savePhotoUploadsMeter';

import getItemDescriptionOptions from '@salesforce/apex/RiserReplacementController.getItemDescriptionOptions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RiserReplacementForm extends LightningElement {
    @api recordId;
    @track isFormDisabled = false;
    @track floors;
    @track risers ='';
    @track riserDetailsList = [];
    @track showMetershiftedPhoto=false;
    @track meterReading;
@track meterNumber;
@track regulatorMake;
noOfPhotosMeter = 2;

   @track riserPickListValue;
      noOfPhotosLpg = 1;


      @track showBPData=false;


   @track lpgPhotoUploadSlots = []; 

    @track load=false;

    @track showRiserSaveBackNextButton=true;


    /* My photo code start */

   

     @track preInstallationPhotoUploadSlots=[];

        noOfPreInstallationPhotos = 1;

    @track giPipeFabricationPhotoUploadSlots=[];

        noOfGiPipeFabricationPhotos = 1;

        @track giPipeErectionPhotoUploadSlots=[];

        noOfGiPipeErectionPhotos = 1;

         @track lengthOfPipelineCommissionedPhotoUploadSlots=[];

        noOfPipelineCommissionedPhotos = 1;

          @track riserLengthPhotoUploadSlots=[];

        noOfRiserLengthPhotos = 1;

        /* end */


@track currentRiserDetail = null;
@track isFirstRiser = true;
@track isLastRiser = false;

 handlePicklistChange(event) {

         console.log('handle pick list value ::', event.target.value);
         this.riserPickListValue = event.target.value;

         if(this.riserPickListValue =='Yes'){

            this.showMetershiftedPhoto = true;
         }

     }

       typeOfRiserOptions = [
        { label: 'Welded', value: 'Welded' },
        { label: 'Threaded', value: 'Threaded' }
    ];

     numberofLeakagesOptions = [
    { label: '1', value: '1' },
    { label: '2', value: '2' },
    { label: '3', value: '3' },
    { label: '4', value: '4' },
    { label: '5', value: '5' },
    { label: '6', value: '6' },
    { label: '7', value: '7' },
    { label: '8', value: '8' },
    { label: '9', value: '9' },
    { label: '10', value: '10' }
];


    @track materialList = [{
        itemCode: '',
        itemDescription: '',
        unit: '',
        quantity: ''
    }];

    @track photoBPMap = {};

    @track itemDescriptionOptions = [
  { label: 'Appliance Valve 1/4" with Nozzle 6.4 mm', value: 'Appliance Valve 1/4" with Nozzle 6.4 mm' },
  { label: 'Brass adap 3/4" x 3/4" - flex corr pipe', value: 'Brass adap 3/4" x 3/4" - flex corr pipe' },
  { label: 'Brass Adaptor 1/4" M x 12 mm', value: 'Brass Adaptor 1/4" M x 12 mm' },
  { label: 'Brass Disconn Union 1/2" x 12 mm (St)', value: 'Brass Disconn Union 1/2" x 12 mm (St)' },
  { label: 'Brass Disconn Union 3/4" x 12 mm (St)', value: 'Brass Disconn Union 3/4" x 12 mm (St)' },
  { label: 'Copper Coupler (Straight) 12 mm', value: 'Copper Coupler (Straight) 12 mm' },
  { label: 'Copper Elbow 12 mm', value: 'Copper Elbow 12 mm' },
  { label: 'Copper Equal Tee (Straight) 12 mm', value: 'Copper Equal Tee (Straight) 12 mm' },
  { label: 'Copper Tube 12 mm OD x 0.6 mm', value: 'Copper Tube 12 mm OD x 0.6 mm' },
  { label: 'Crimping Fitting 1" x 32 mm (LP)', value: 'Crimping Fitting 1" x 32 mm (LP)' },
  { label: 'Crimping Fitting 1/2" x 20 mm (LP)', value: 'Crimping Fitting 1/2" x 20 mm (LP)' },
  { label: 'Crimping Fitting 3/4"x 32 mm (LP)', value: 'Crimping Fitting 3/4"x 32 mm (LP)' },
  { label: 'ERW Pipe (Med Cl) - GI & PC - 1" NB', value: 'ERW Pipe (Med Cl) - GI & PC - 1" NB' },
  { label: 'ERW Pipe (Med Cl) - GI & PC - 1/2" NB', value: 'ERW Pipe (Med Cl) - GI & PC - 1/2" NB' },
  { label: 'ERW Pipe (Med Cl) - GI & PC - 3/4" NB', value: 'ERW Pipe (Med Cl) - GI & PC - 3/4" NB' },
  { label: 'GI Elbow 90 deg 1" F/F', value: 'GI Elbow 90 deg 1" F/F' },
  { label: 'GI Elbow 90 deg 1" F/F (PC)', value: 'GI Elbow 90 deg 1" F/F (PC)' },
  { label: 'GI Elbow 90 deg 1/2" F/F (PC)', value: 'GI Elbow 90 deg 1/2" F/F (PC)' },
  { label: 'GI Elbow 90 deg 1/2" M/F (PC)', value: 'GI Elbow 90 deg 1/2" M/F (PC)' },
  { label: 'GI Elbow 90 deg 3/4" F/F', value: 'GI Elbow 90 deg 3/4" F/F' },
  { label: 'GI Equal Tee 1/2" (PC)', value: 'GI Equal Tee 1/2" (PC)' },
  { label: 'GI Nipple 1/2" x 2" (PC)', value: 'GI Nipple 1/2" x 2" (PC)' },
  { label: 'GI Nipple 1/2" x 4" (PC)', value: 'GI Nipple 1/2" x 4" (PC)' },
  { label: 'GI Nipple 1/2" x 6" (PC)', value: 'GI Nipple 1/2" x 6" (PC)' },
  { label: 'GI Nipple 3/4" x 2" (PC)', value: 'GI Nipple 3/4" x 2" (PC)' },
  { label: 'GI Nipple 3/4" x 4" (PC)', value: 'GI Nipple 3/4" x 4" (PC)' },
  { label: 'GI Nipple 3/4" x 6" (PC)', value: 'GI Nipple 3/4" x 6" (PC)' },
  { label: 'GI Plug 1" (PC)', value: 'GI Plug 1" (PC)' },
  { label: 'GI Reducing Tee 3/4" x 1/2" (PC)', value: 'GI Reducing Tee 3/4" x 1/2" (PC)' },
  { label: 'GI Saddle 1" (PC)', value: 'GI Saddle 1" (PC)' },
  { label: 'GI Saddle 1/2" (PC)', value: 'GI Saddle 1/2" (PC)' },
  { label: 'GI Saddle 3/4" (PC)', value: 'GI Saddle 3/4" (PC)' },
  { label: 'GI Socket 1"(PC)', value: 'GI Socket 1"(PC)' },
  { label: 'GI Socket 1/2"(PC)', value: 'GI Socket 1/2"(PC)' },
  { label: 'GI Socket 3/4"(PC)', value: 'GI Socket 3/4"(PC)' },
  { label: 'GI Union 1" (PC)', value: 'GI Union 1" (PC)' },
  { label: 'GI Union 1/2" (PC)', value: 'GI Union 1/2" (PC)' },
  { label: 'GI Union 3/4" (PC)', value: 'GI Union 3/4" (PC)' },
  { label: 'Meter Bracket-Diap GM G1.6(Qmax 2.5scmh)', value: 'Meter Bracket-Diap GM G1.6(Qmax 2.5scmh)' },
  { label: 'Meter Control Valve 1/2"', value: 'Meter Control Valve 1/2"' },
  { label: 'Meter Inlet Union 3/4 F x 3/4"', value: 'Meter Inlet Union 3/4 F x 3/4"' },
  { label: 'Meter Outlet Union 3/4" x 12 mm', value: 'Meter Outlet Union 3/4" x 12 mm' },
  { label: 'Meter Regulator 3/4"', value: 'Meter Regulator 3/4"' },
  { label: 'Riser Isolation Valve 1"', value: 'Riser Isolation Valve 1"' },
  { label: 'Riser Isolation Valve 1/2"', value: 'Riser Isolation Valve 1/2"' },
  { label: 'Riser Isolation Valve 3/4"', value: 'Riser Isolation Valve 3/4"' },
  { label: 'GI FORGE ELBOW 90 DEG 1/2" F/F', value: 'GI FORGE ELBOW 90 DEG 1/2" F/F' },
  { label: 'GI FORGE ELBOW 90 DEG 3/4" F/F', value: 'GI FORGE ELBOW 90 DEG 3/4" F/F' },
  { label: 'GI FORGE ELBOW 90 DEG 1" F/F', value: 'GI FORGE ELBOW 90 DEG 1" F/F' },
  { label: 'GI FORGE ELBOW 90 DEG 1 1/2" F/F', value: 'GI FORGE ELBOW 90 DEG 1 1/2" F/F' },
  { label: 'GI FORGE ELBOW 90 DEG 2" F/F', value: 'GI FORGE ELBOW 90 DEG 2" F/F' },
  { label: 'GI FORGE ELBOW 90 DEG 1/2" M/F', value: 'GI FORGE ELBOW 90 DEG 1/2" M/F' },
  { label: 'GI FORGE COUPLER 1/2"', value: 'GI FORGE COUPLER 1/2"' },
  { label: 'GI FORGE COUPLER 3/4"', value: 'GI FORGE COUPLER 3/4"' },
  { label: 'GI FORGE COUPLER 1"', value: 'GI FORGE COUPLER 1"' },
  { label: 'GI FORGE COUPLER 1 1/2"', value: 'GI FORGE COUPLER 1 1/2"' },
  { label: 'GI FORGE HEX NIPPLE 3/4"', value: 'GI FORGE HEX NIPPLE 3/4"' },
  { label: 'GI FORGE HEX NIPPLE 1"', value: 'GI FORGE HEX NIPPLE 1"' },
  { label: 'GI FORGE COUPLER 2"', value: 'GI FORGE COUPLER 2"' },
  { label: 'GI FORGE EQUAL TEE 1/2"', value: 'GI FORGE EQUAL TEE 1/2"' },
  { label: 'GI FORGE EQUAL TEE 3/4"', value: 'GI FORGE EQUAL TEE 3/4"' },
  { label: 'GI FORGE EQUAL TEE 1"', value: 'GI FORGE EQUAL TEE 1"' },
  { label: 'GI FORGE EQUAL TEE 1 1/2"', value: 'GI FORGE EQUAL TEE 1 1/2"' },
  { label: 'GI FORGE EQUAL TEE 2"', value: 'GI FORGE EQUAL TEE 2"' },
  { label: 'GI FORGE REDUCING TEE 3/4" X 1/2"', value: 'GI FORGE REDUCING TEE 3/4" X 1/2"' },
  { label: 'GI FORGE REDUCING TEE 1" X 3/4"', value: 'GI FORGE REDUCING TEE 1" X 3/4"' },
  { label: 'GI FORGE REDUCING TEE 1" X 1/2"', value: 'GI FORGE REDUCING TEE 1" X 1/2"' },
  { label: 'GI FORGE REDUCING TEE 1 1/2" X 1/2"', value: 'GI FORGE REDUCING TEE 1 1/2" X 1/2"' },
  { label: 'GI FORGE REDUCING TEE 1 1/2" X 3/4"', value: 'GI FORGE REDUCING TEE 1 1/2" X 3/4"' },
  { label: 'GI FORGE REDUCING TEE 1 1/2" X 1"', value: 'GI FORGE REDUCING TEE 1 1/2" X 1"' },
  { label: 'GI FORGE REDUCER 3/4" X 1/2"', value: 'GI FORGE REDUCER 3/4" X 1/2"' },
  { label: 'GI FORGE REDUCER 1" X 1/2"', value: 'GI FORGE REDUCER 1" X 1/2"' },
  { label: 'GI FORGE REDUCER 1" X 3/4"', value: 'GI FORGE REDUCER 1" X 3/4"' },
  { label: 'GI FORGE REDUCER 1 1/2" X 1"', value: 'GI FORGE REDUCER 1 1/2" X 1"' },
  { label: 'GI FORGE REDUCER 2" X 1 1/2"', value: 'GI FORGE REDUCER 2" X 1 1/2"' },
  { label: 'GI FORGE UNION 1"', value: 'GI FORGE UNION 1"' },
  { label: 'GI FORGE UNION 3/4"', value: 'GI FORGE UNION 3/4"' },
  { label: 'GI FORGE UNION 1/2"', value: 'GI FORGE UNION 1/2"' },
  { label: 'GI FORGE PLUG 1/2"', value: 'GI FORGE PLUG 1/2"' },
  { label: 'GI FORGE PLUG 3/4"', value: 'GI FORGE PLUG 3/4"' },
  { label: 'GI FORGE PLUG 1"', value: 'GI FORGE PLUG 1"' }
];

    // Initial site form data

    @track riserTypes = [];
    imageUploadPage = true;
    @track photoUploadSlots = [];
    @track currentRiserIndex = 1;
    @track totalRisers = '';

    @track showLeakLocationsFields=false;


     @track photoBPUploadSlots=[];
    noOfBPPhotos = 1;

    @track showAccRecordUpdaveSave = false;

    @track showPressureGaugeInputScreen=false;


@track showRisersCorrectNext=false;


    noOfPhotos = 1;

    get riserTypeOptions() {
        return [
            { label: 'Threaded', value: 'Threaded' },
            { label: 'Welded', value: 'Welded' }
        ];
    }

     get meterShiftedOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }



    @track serviceAppointmentId;
    @track forms = [];


    @track copperPipeLength = '';
    @track gIpipelinelength = '';
     @track giPipeFabricationlength = '';

    @track testPressure = '';
    @track stabilizationTime = '';
    @track testingTime = '';
    @track testingStatus = '';
    @track leakageObserved = '';
    @track lengthRectified = '';
    @track showNewRiserTesting = false;  
    @track newRiser = true;

    @track meterImageUploadSlots = [];

    @track accRecordList =[];
    @track userInputMap ={};

     connectionOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    @track serviceReport = {

        instrumentTypeRange: '',
        calibrationDate: null,
        calibrationCertificateNo: '',
        calibrationDueDate: null
     
        
    };

     handleServiceReportDetails(event){

        const field = event.target.name;
        const value = event.target.value;

        if (field) {
            this.serviceReport[field] = value;
        }
    }


    handleInstrumentSave(){

        if(!this.serviceReport.calibrationDueDate || !this.serviceReport.calibrationCertificateNo || !this.serviceReport.calibrationDate || !this.serviceReport.instrumentTypeRange || this.oldMaterialUsed==''){

            //|| !this.serviceReport.mATERIALUSED
            console.log('inside if error');
           this.showtoast('Warning','Please enter required fields.','warning');
            return;
         }

     this.isload = true;

    const jsonData = JSON.stringify(this.serviceReport);

    console.log('Json data :::', jsonData);
        saveServiReportData({recordId : this.recordId, serviceReport : jsonData})
        .then( result => {
            console.log('Result ::', result);
           //   this.showtoast('Success','Record Updated Successfully.','Success');
       this.isload=false;
      // this.handleCancel();
     // this.dispatchEvent(new CustomEvent('cancel'));
      //   generateAndAttachPdf({worOrderId : this.recordId});



        })
        .catch(error => {
            this.isload=false;
            console.log('Error :', error);
        })
         
    }


    @track instrumentType;
    @track certificateNo;
    @track calibrationDate;
    @track calibrationDueDate;
    @track showCalibrationDetails = true;

    connectedCallback() {
        console.log('Work Order recordId:', this.recordId);

         this.setPreInstallationPhotoUploadSlots();
         this.setGiPipeFabricationPhotoUploadSlots();
         this.setGiPipeErectionPhotoUploadSlots();
         this.setLengthOfPipelineCommissionedPhotoUploadSlots();
         this.setRiserLengthPhotoUploadSlots();


        this.getBPBasedOnConnectionNumber();
        this.setBPPhotoUploadSlots();

            this.setreversalPhotoUploadSlots();
                this.setlpgPhotoUploadSlots();
                    this.setmeterImageUploadSlots();




        // Reset view states
        this.showFormPage = true;
        this.showMaterialSection = true;

        // Pre-fetch Service Appointment Id
        if (this.recordId) {
            getServiceAppointmentId({ workOrderId: this.recordId })
                .then(result => {
                    this.serviceAppointmentId = result;
                    console.log('Fetched Service Appointment ID:', result);
                })
                .catch(error => {
                    console.error('Error fetching service appointment ID:', error);
                });
        }

        

        // Fetch Item Description Options
        // getItemDescriptionOptions()
        //     .then(result => {
        //         this.itemDescriptionOptions = result.map(value => ({ label: value, value }));
        //         console.log('Fetched item description options:', this.itemDescriptionOptions);
        //     })
        //     .catch(error => {
        //         console.error('Error fetching item description options:', error);
        //     });
    }


    /* handle Checkbox change */


        @track showGiPipeFabricationLength=false;

        @track showGiPipeErection=false;

        @track showNoOfLeakages = false;

        @track showRiserTestingAndCommissioning = false;

        @track showRiserLength=false;

        @track showCrimpsReplacedQuantity = false;

        @track showClampReplacedQuantity=false;

        @track showLateralReplacementDone =false;

         @track gIpipefabrication=false;
         @track gIPipeErection=false;

         @track riserTesting=false;
         @track riserTestingandCommissioning=false;
         @track oldRiserRemoved=false;
         @track clampReplacement=false;
         @track lateralReplacement=false;

         @track crimpGuardReplacement=false;

         @track riserPainting=false;

         @track showRiserPaintingRequired = false;

        handleCheckBoxChange(event){

            console.log('check box change label::', event.target.label);

            const label = event.target.label;

            const value =  event.target.checked;


         if(label=='Riser Painting' && value==true){

                this.riserPainting=value;

            this.showRiserPaintingRequired=true;
            }
             if(label=='Riser Painting' && value==false){


                this.riserPainting=value;

            this.showRiserPaintingRequired=false;
            this.riserDetailsList[0].riserPainting='';
             this.riserDetailsList[0].riserPaintedLength='';
             this.riserPaintingYesShowSaveButton-false;

           // this.giPipeFabricationPhotoUploadSlots = [];
            }


            if(label=='Riser Fabrication' && value==true){

                this.gIpipefabrication=value;

            this.showGiPipeFabricationLength=true;
            }
             if(label=='Riser Fabrication' && value==false){


                this.gIpipefabrication=value;

            this.showGiPipeFabricationLength=false;
            this.riserDetailsList[0].giPipeFabricationlength='';
           // this.giPipeFabricationPhotoUploadSlots = [];
            }


             if(label=='Riser Erection' && value==true){

                    this.gIPipeErection=value;
            this.showGiPipeErection=true;
            }
             if(label=='Riser Erection' && value==false){

                this.gIPipeErection=value;

            this.showGiPipeErection=false;
            this.riserDetailsList[0].gipipeerectionlength='';
           // this.giPipeFabricationPhotoUploadSlots = [];
            }


             if(label=='Riser Testing' && value==true){

                this.riserTesting=value;
            this.showNoOfLeakages=true;
            }
             if(label=='Riser Testing' && value==false){

                this.riserTesting=value;

            this.showNoOfLeakages=false;
            this.showLeakLocationsFields=false;

           this.riserDetailsList[0].leakLocation1='';
          this.riserDetailsList[0].leakLocation2='';
          this.riserDetailsList[0].lengthofRiserTested='';

           // this.giPipeFabricationPhotoUploadSlots = [];
            }

             if(label=='Riser Testing and Commissioning' && value==true){

                this.riserTestingandCommissioning=value;
            this.showRiserTestingAndCommissioning=true;
            }
             if(label=='Riser Testing and Commissioning' && value==false){

                this.riserTestingandCommissioning=value;

            this.showRiserTestingAndCommissioning=false;
            this.riserDetailsList[0].lengthofRiserCommissioned='';
           // this.giPipeFabricationPhotoUploadSlots = [];
            }

            if(label=='Old Riser Removed' && value==true){

                this.oldRiserRemoved=value;
            this.showRiserLength=true;
            }
             if(label=='Old Riser Removed' && value==false){

              this.oldRiserRemoved=value;

            this.showRiserLength=false;
            this.riserDetailsList[0].riserLength='';
           // this.giPipeFabricationPhotoUploadSlots = [];
            }

              if(label=='Clamp Replacement' && value==true){

                this.clampReplacement=value;
            this.showClampReplacedQuantity=true;
            }
             if(label=='Clamp Replacement' && value==false){

              this.clampReplacement=value;

            this.showClampReplacedQuantity=false;
            this.riserDetailsList[0].numberofClampstobeReplaced='';
           // this.giPipeFabricationPhotoUploadSlots = [];
            }

            if(label=='Crimp Guard Replacement' && value==true){

                this.crimpGuardReplacement=value;
            this.showCrimpsReplacedQuantity=true;
            }
             if(label=='Crimp Guard Replacement' && value==false){

              this.clampReplacement=value;

            this.showCrimpsReplacedQuantity=false;
            this.riserDetailsList[0].numberofCrimpGuardstobeReplaced='';
           // this.giPipeFabricationPhotoUploadSlots = [];
            }

               if(label=='Lateral Replacement' && value==true){

                this.lateralReplacement=value;
            this.showLateralReplacementDone=true;
            }
             if(label=='Lateral Replacement' && value==false){
                this.lateralReplacement=value;

            this.showLateralReplacementDone=false;
            this.riserDetailsList[0].numberOfLateralReplacementsDone='';
           // this.giPipeFabricationPhotoUploadSlots = [];
            }

        }

    /* end */


    getBPBasedOnConnectionNumber(){

        getBPBasedOnConnectionNumber({recordId : this.recordId})
          .then(data => {
                this.accRecordList = data;

                this.showAccRecordUpdaveSave = this.accRecordList && this.accRecordList.length > 0;
                console.log('showaccountrecordupdatesave::', this.showAccRecordUpdaveSave);

            })
            .catch(error => {
                console.log('Error ::', error);
                this.accRecordList = [];
            })
    }

    handleInputChange(event) {
        const accId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.detail.value;

        if (!this.userInputMap[accId]) {
            this.userInputMap[accId] = {Id: accId };
        }

        this.userInputMap[accId][field] = value;
        console.log('Updated Input:', JSON.stringify(this.userInputMap));
    }

     handleSave() {

        this.load=true;

        console.log('inside handle save');
        const updatedList = Object.values(this.userInputMap);
        
        console.log('updated list ::', updatedList);
        if (updatedList.length === 0) {
           this.showToast('Warning', 'Please Enter Input', 'warning');
           this.load=false;
            return;

        }


        console.log('before update accounts ::');

        updateAccounts({ updatedData: updatedList, recordId : this.recordId })
            .then(() => {
                console.log('inside success result');
                this.showToast('Success','Records Updated Successfully','Success');
                this.load=false;
                this.handleBPFinalSave();
               this.dispatchEvent(new CustomEvent('cancel'));

               // this.userInputMap = {}; // Clear input map
            })
            .catch(error => {
                 //   console.log('Error update account details::', error);
            });
    }


    /* My photo upload slots */

     setPreInstallationPhotoUploadSlots() {

            this.preInstallationPhotoUploadSlots = Array.from({ length: this.noOfPreInstallationPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Pre Installation' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));


    }

      setGiPipeFabricationPhotoUploadSlots() {

            this.giPipeFabricationPhotoUploadSlots = Array.from({ length: this.noOfGiPipeFabricationPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Riser Fabrication' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));

    }

     setGiPipeErectionPhotoUploadSlots() {

            this.giPipeErectionPhotoUploadSlots = Array.from({ length: this.noOfGiPipeErectionPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Riser Erection' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));

     }

     setLengthOfPipelineCommissionedPhotoUploadSlots() {

            this.lengthOfPipelineCommissionedPhotoUploadSlots = Array.from({ length: this.noOfPipelineCommissionedPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Pipeline Commissioned' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));

     }

     setRiserLengthPhotoUploadSlots() {

            this.riserLengthPhotoUploadSlots = Array.from({ length: this.noOfRiserLengthPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Post Replacement Picture' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));

     }




    /*  end */


    /* my handle file change */

      async handlePreInstallationPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.preInstallationPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < preInstallationPhotoUploadSlots.length; i++) {
        let slot = preInstallationPhotoUploadSlots[i];
            console.log(`🔄 Processing Photo ${i + 1}`);

            if (slot.base64Data) {
                try {
                    // Add prefix if missing
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;

                    // 🔍 Original size in MB
                    const originalBytes = atob(fullBase64.split(',')[1]).length;
                    const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

                    // Convert to blob and compress
                    const blob = this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);

                    // Convert compressed Blob back to base64
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    const compressedBytes = atob(compressedBase64).length;
                    const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

                    // Store compressed result
                    slot.base64Data = compressedBase64;

                } catch (error) {
                //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);

                // Only show toast if compressed base64 is not usable
                if (!slot.base64Data || slot.base64Data.length < 100) {
                console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
                } else {
                    console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
                }
            }


            } else {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
            }
        }


       // this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set');
    } 


    async handleGiPipeFabricationPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.giPipeFabricationPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < giPipeFabricationPhotoUploadSlots.length; i++) {
        let slot = giPipeFabricationPhotoUploadSlots[i];
            console.log(`🔄 Processing Photo ${i + 1}`);

            if (slot.base64Data) {
                try {
                    // Add prefix if missing
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;

                    // 🔍 Original size in MB
                    const originalBytes = atob(fullBase64.split(',')[1]).length;
                    const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

                    // Convert to blob and compress
                    const blob = this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);

                    // Convert compressed Blob back to base64
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    const compressedBytes = atob(compressedBase64).length;
                    const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

                    // Store compressed result
                    slot.base64Data = compressedBase64;

                } catch (error) {
                //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);

                // Only show toast if compressed base64 is not usable
                if (!slot.base64Data || slot.base64Data.length < 100) {
                console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
                } else {
                    console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
                }
            }


            } else {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
            }
        }


       // this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set');
    } 


     async handleGiPipeErectionPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.giPipeErectionPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < giPipeErectionPhotoUploadSlots.length; i++) {
        let slot = giPipeErectionPhotoUploadSlots[i];
            console.log(`🔄 Processing Photo ${i + 1}`);

            if (slot.base64Data) {
                try {
                    // Add prefix if missing
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;

                    // 🔍 Original size in MB
                    const originalBytes = atob(fullBase64.split(',')[1]).length;
                    const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

                    // Convert to blob and compress
                    const blob = this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);

                    // Convert compressed Blob back to base64
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    const compressedBytes = atob(compressedBase64).length;
                    const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

                    // Store compressed result
                    slot.base64Data = compressedBase64;

                } catch (error) {
                //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);

                // Only show toast if compressed base64 is not usable
                if (!slot.base64Data || slot.base64Data.length < 100) {
                console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
                } else {
                    console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
                }
            }


            } else {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
            }
        }


       // this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set');
    } 

     async handlelengthOfPipelineCommissionedPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.lengthOfPipelineCommissionedPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < lengthOfPipelineCommissionedPhotoUploadSlots.length; i++) {
        let slot = lengthOfPipelineCommissionedPhotoUploadSlots[i];
            console.log(`🔄 Processing Photo ${i + 1}`);

            if (slot.base64Data) {
                try {
                    // Add prefix if missing
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;

                    // 🔍 Original size in MB
                    const originalBytes = atob(fullBase64.split(',')[1]).length;
                    const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

                    // Convert to blob and compress
                    const blob = this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);

                    // Convert compressed Blob back to base64
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    const compressedBytes = atob(compressedBase64).length;
                    const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

                    // Store compressed result
                    slot.base64Data = compressedBase64;

                } catch (error) {
                //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);

                // Only show toast if compressed base64 is not usable
                if (!slot.base64Data || slot.base64Data.length < 100) {
                console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
                } else {
                    console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
                }
            }


            } else {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
            }
        }


       // this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set');
    } 


      async handleRiserLengthPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.riserLengthPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < riserLengthPhotoUploadSlots.length; i++) {
        let slot = riserLengthPhotoUploadSlots[i];
            console.log(`🔄 Processing Photo ${i + 1}`);

            if (slot.base64Data) {
                try {
                    // Add prefix if missing
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;

                    // 🔍 Original size in MB
                    const originalBytes = atob(fullBase64.split(',')[1]).length;
                    const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

                    // Convert to blob and compress
                    const blob = this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);

                    // Convert compressed Blob back to base64
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    const compressedBytes = atob(compressedBase64).length;
                    const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

                    // Store compressed result
                    slot.base64Data = compressedBase64;

                } catch (error) {
                //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);

                // Only show toast if compressed base64 is not usable
                if (!slot.base64Data || slot.base64Data.length < 100) {
                console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
                } else {
                    console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
                }
            }


            } else {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
            }
        }


       // this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set');
    } 






    /* end */

     setBPPhotoUploadSlots() {
        this.photoBPUploadSlots = Array.from({ length: this.noOfBPPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label: `Photo ${index + 1}`,
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }

    updateCurrentRiserFlags() {
    this.currentRiserDetail = this.riserDetailsList[this.currentRiserIndex - 1] || null;
    this.isFirstRiser = this.currentRiserIndex === 1;
    this.isLastRiser = this.currentRiserIndex === this.totalRisers;
}


    handleMaterialChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        console.log(`Material Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        this.materialList[index][field] = value;
    }

    addMaterialRow() {
        console.log('Adding new material row');
        this.materialList.push({
            // itemCode: '',
            itemDescription: '',
            unit: '',
            quantity: ''
        });
    }

    removeMaterialRow(event) {
        const index = event.target.dataset.index;
        console.log(`Removing material row at index: ${index}`);
        if (this.materialList.length > 1) {
            this.materialList.splice(index, 1);
        }
    }

    handleToggleCalibrationDetails(event) {
        this.showCalibrationDetails = event.target.checked;
        console.log('Toggled Calibration Details:', this.showCalibrationDetails);
    }


    statusOptions = [
        { label: 'Okay', value: 'Okay' },
        { label: 'Not Okay', value: 'Not Okay' }
    ];

     riserPaintingOptions = [
        //  { label: 'None', value: 'None' },
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    handleChange(event) {
        const field = event.target.name;
        let value = event.detail.value || event.target.value;

        // Convert number fields to actual numbers
        if (event.target.type === 'number') {
            value = parseFloat(value);
        }

        console.log(`handleChange called: field = ${field}, value = ${value}`);
        this[field] = value;

        if (field === 'calibrationDueDate') {
            this.showMaterialSection = !!value;
            console.log('showMaterialSection toggled:', this.showMaterialSection);
        }
    }


handleShowRiserData(){

    this.showNewRiserTesting=true;
    this.newRiser=false;
}


    // handleToggleNewRiserTesting(event) {
    //     this.showNewRiserTesting = event.target.checked;
    //     console.log('Toggled New Riser Testing Section:', this.showNewRiserTesting);
    // }



    handleFloors(event) {
        this.floors = event.detail.value;
        console.log('Number of Floors:', this.floors);
    }

    handleRisers(event) {

   // this.risers = parseInt(event.target.value, 10) || 0;
    this.risers = parseInt(event.target.value, 10);
    this.riserTypes = [];
    this.riserDetailsList = [];

   

        //   if (this.risers >= 1 && this.riser <= 9) {




    for (let i = 0; i < this.risers; i++) {
        this.riserDetailsList.push({
            key: `riser-${i}`,
            label: `Riser ${i + 1}`,
           // riserType: '',
            copperPipeLength: '',
            giPipeFabricationlength : '',
            gIpipelinelength : '',
            meterShiftedPickListValue : '',
            gipipeerectionlength : '',
            numberofleakage : '',
            leakagelocations : [],
            lengthofRiserCommissioned : '',
            riserLength : '',
            riserPainting : '',
           // quantityOfCrimpsReplaced :'',
            leakLocation1 : '',
            leakLocation2 : '',
            numberofClampstobeReplaced : '',
            numberofCrimpGuardstobeReplaced : '',
            lengthofRiserTested : '',
            riserPaintedLength : ''
           

          //  testPressure: '',
          //  stabilizationTime: '',
          //  testingTime: '',
           // testingStatus: '',
           // leakageObserved: '',
           // lengthRectified: ''
        });
    }

      this.totalRisers = this.risers;
    this.currentRiserIndex = 1;
    this.updateCurrentRiserFlags();

       //   }

    //      else {

    //          this.risers = '';
    //     this.showNewRiserTesting = false;
    //    this.showToast('Warning', 'Please Enter Valid Number.', 'warning');
    //       }
    

    



  
}

@track riserPaintingYesShowSaveButton=false;

@track showRisePaintingNoFields=true;

handleRiserDetailChange(event) {
    const index = parseInt(event.target.dataset.index, 10) - 1;
    const field = event.target.name;
    const value = event.detail.value || event.target.value;
        const fieldLabel = event.target.label;



        if(fieldLabel =='Riser Painting' && value=='Yes'){

            this.riserPaintingYesShowSaveButton=true;
            this.showRisePaintingNoFields=false;
            this.showRiserSaveBackNextButton=false;
        }

          if(fieldLabel =='Riser Painting' && value=='No'){

            this.riserPaintingYesShowSaveButton=false;
            this.showRisePaintingNoFields=true;
            this.showRiserSaveBackNextButton=true;

        }


        if (field  === 'numberofleakage' && value !='') {

            this.showLeakLocationsFields=true;

        }

   /*  if (field  === 'numberofleakage') {



            console.log('inside field name number of leakage');

             if (this.riserDetailsList[index]) {
        this.riserDetailsList[index].numberofleakage = value;

        console.log('number of leakage observed::', this.riserDetailsList[index].numberofleakage);

        // Generate leakage locations for that riser
        this.riserDetailsList[index].leakagelocations = Array.from(
            { length: value },
            (_, i) => ({
                index: i + 1,
                value: '',
                label: `Leakage location ${i + 1}`
            })
        );

        // Force reactivity
        this.riserDetailsList = [...this.riserDetailsList];
    }

        //     this.riserDetailsList.numberofleakage = value;

        //     console.log('number of leakage observed::', this.riserDetailsList.numberofleakage);



        //   //  this.numberOfLeakages = parseInt(value, 10);
        //     this.riserDetailsList.leakagelocations = Array.from({ length: value }, (_, i) => ({
        //         index: i + 1,
        //         value: '',
        //         label: `Leakage location ${i + 1}` 
        //     }));

        //          this.riserDetailsList.leakagelocations = [...this.riserDetailsList.leakagelocations];
        }

         if (fieldLabel .startsWith('Leakage location')) {
            console.log('inside leak location field change');
        //     const index = parseInt(fieldLabel.replace('Leakage location', ''), 10) - 1;
        //    this.rubberHose.leakagelocations[index].value = value;

        //       this.rubberHose.leakagelocations = [...this.rubberHose.leakagelocations];
        
    const locIndex = parseInt(fieldLabel.replace('Leakage location', ''), 10) - 1;

    if (this.riserDetailsList[index] && this.riserDetailsList[index].leakagelocations) {
        this.riserDetailsList[index].leakagelocations[locIndex].value = value;

        // Force reactivity
        this.riserDetailsList = [...this.riserDetailsList];
    }

        } */

    if (this.riserDetailsList[index]) {
        this.riserDetailsList[index][field] = value;
        console.log(`Updated riserDetailsList[${index}][${field}] = ${value}`);
    }

    this.updateCurrentRiserFlags(); // update UI state
}

handleNext() {

this.setPreInstallationPhotoUploadSlots();
this.setGiPipeFabricationPhotoUploadSlots();
this.setGiPipeErectionPhotoUploadSlots();
this.setLengthOfPipelineCommissionedPhotoUploadSlots();
this.setRiserLengthPhotoUploadSlots();

this.gIPipeErection=false;
this.gIpipefabrication=false;
this.riserTesting=false;
this.riserTestingandCommissioning=false;
this.oldRiserRemoved=false;
this.clampReplacement=false;
this.clampReplacement = false;
this.lateralReplacement=false;
this.riserPainting=false;

this.showRiserPaintingRequired=false;

this.serviceReport=[];

this.showNoOfLeakages=false;
this.riserDetailsList[0].numberofleakage='';
this.riserDetailsList[0].leakLocation1='';
this.riserDetailsList[0].leakLocation2='';
this.riserDetailsList[0].riserPainting=null;
this.riserDetailsList[0].lengthofRiserTested='';
this.riserDetailsList[0].riserPaintedLength='';



this.materialList = [];

  this.showGiPipeFabricationLength=false;
  this.riserDetailsList[0].giPipeFabricationlength='';

 this.showGiPipeErection=false;
 this.riserDetailsList[0].gipipeerectionlength='';

 this.showRiserTestingAndCommissioning=false;
this.riserDetailsList[0].lengthofRiserCommissioned='';

this.riserDetailsList[0].riserLength='';

 this.showCrimpsReplacedQuantity=false;
 this.riserDetailsList[0].numberofClampstobeReplaced='';

  this.showLateralReplacementDone=false;
this.riserDetailsList[0].numberOfLateralReplacementsDone='';


    
        if (this.currentRiserIndex < this.totalRisers) {
        this.currentRiserIndex += 1;
        this.updateCurrentRiserFlags();
    }
}

handleBack() {
    if (this.currentRiserIndex > 1) {
        this.currentRiserIndex -= 1;
        this.updateCurrentRiserFlags();
    }
}   

  @track materialList = [{
        itemDescription: '',
        quantity: ''
    }];


  addMaterialRow() {
        console.log('Adding new material row');
        this.materialList.push({
            itemDescription: '',
            quantity: ''
        });
    }

      removeMaterialRow(event) {
        const index = event.target.dataset.index;
        console.log(`Removing material row at index: ${index}`);
        if (this.materialList.length > 1) {
            this.materialList.splice(index, 1);
        }
    }

     handleMaterialChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        console.log(`Material Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        this.materialList[index][field] = value;
    }

    handleShowBpScreen(){

         this.showBPData=true;
         this.showPressureGaugeInputScreen=false;
        if(this.accRecordList && !this.accRecordList >0){

           this.dispatchEvent(new CustomEvent('cancel'));
            }
    }


   

    // handleFile(event) {
    //     this.photoUploadSlots = event.detail.steps;
    //     console.log('Uploaded Photo Steps:', JSON.stringify(this.photoUploadSlots));
    // }

    testData = [{
        itemDescription: 'test material',
        unit: '12',
        quantity: '80'
    }];
    // console.log('testData---'+ JSON.stringify(testData));

    handleRiserPaintingSubmit(){

           this.showToast('Success', 'Details saved Successfully.', 'success');

             this.dispatchEvent(new CustomEvent('cancel'));



    }

    handleBackToRiserDetails(){

        this.showNewRiserTesting = true;
            this.newRiser = true;
            this.showFormPage=true;
            this.showBPData=false;
    }

    handleSubmit() {
    console.log('Starting handleSubmit');

    if (!this.floors || !this.risers) {
        this.showToast('Warning', 'Please enter Number of Floors and Risers.', 'warning');
        return;
    }



     this.showNewRiserTesting = false;
            this.newRiser = false;
            this.showFormPage=false;
            this.showBPData=true;
         //   this.showPressureGaugeInputScreen = true;

         //   this.showToast('Success', 'Riser details saved.', 'success');


    if (this.showNewRiserTesting) {
        saveRiserTestingDetails({
            workOrderId: this.recordId,
            riserDataList: this.riserDetailsList,
            // instrumentType: this.instrumentType,
            // certificateNo: this.certificateNo,
            // calibrationDate: this.calibrationDate,
            // calibrationDueDate: this.calibrationDueDate,
            noOfFloors: this.floors,
            noOfRisers: this.risers,
          //  meterReading: this.meterReading,
           // meterNumber: this.meterNumber,
         //   regulatorMake: this.regulatorMake,
            riserPickListValue : this.riserPickListValue
        })
        .then(() => {
            this.showToast('Success', 'Riser details saved.', 'success');
        //     this.showNewRiserTesting = false;
        //     this.newRiser = false;
        //     this.showFormPage=false;
        //    // this.showBPData=true;
        //     this.showPressureGaugeInputScreen = true;
        //     if(this.accRecordList && !this.accRecordList >0){

        //    this.dispatchEvent(new CustomEvent('cancel'));
        //     }
        })
        .catch((error) => {
            console.error('Error saving riser details:', error);
           // this.showToast('Error', error?.body?.message || 'Failed to save riser details.', 'error');
        });
     } // else {
    //     this.showToast('Info', 'New Riser Testing not selected.', 'info');
    // }
}

// handleFinalSubmit() {
//     console.log('Final Submission Started');

//     const promises = [];

//     // Save Gauge Calibration Details
//     if (this.showCalibrationDetails) {
//         promises.push(
//             saveGaugeCalibrationDetails({
//                 workOrderId: this.recordId,
//                 instrumentType: this.instrumentType,
//                 certificateNo: this.certificateNo,
//                 calibrationDate: this.calibrationDate,
//                 calibrationDueDate: this.calibrationDueDate
//             }).then(() => {
//                 console.log('✔ Calibration details saved.');
//                  this.dispatchEvent(new CustomEvent('cancel'));

//             }).catch(error => {
//                 throw new Error('Calibration Save Error: ' + (error?.body?.message || error.message));
//             })
//         );
//     }

//     // Save Material Details
//     if (this.showMaterialSection && this.materialList.length > 0) {
//         promises.push(
//             saveMaterialDetails({
//                 workOrderId: this.recordId,
//                 materialList: this.materialList
//             }).then(() => {
//                 console.log('✔ Material details saved.');
//             }).catch(error => {
//                 throw new Error('Material Save Error: ' + (error?.body?.message || error.message));
//             })
//         );
//     }

//     Promise.all(promises)
//         .then(() => {
//             this.showToast('Success', 'All details saved successfully.', 'success');
//             this.isFormDisabled = true;
//          this.dispatchEvent(new CustomEvent('cancel'));

//         })
//         .catch((error) => {
//             console.error('❌ Final Submit Error:', error);
//             this.showToast('Error', error.message, 'error');
//         });
// }

showToast(title, message, variant) {
    this.dispatchEvent(
        new ShowToastEvent({
            title,
            message,
            variant
        })
    );
}


setreversalPhotoUploadSlots() {
    console.log('Inside method:', this.noOfPhotos);
        const customLabels = ['Riser Fabrication', 'After Reversal'];
        this.reversalPhotoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: customLabels[index] || `Photo ${slotNum}`, 
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: ''
            };
        });
        console.log('Photo Upload Slots:', JSON.stringify(this.photoUploadSlots));
}

handleReversalFile(event) {
    const rawFiles = event.detail.steps;
    console.log('Raw reversal uploads:', JSON.stringify(rawFiles));

    // Deduplicate using label + fileName as unique key
    const uniqueFiles = [];
    const seenKeys = new Set();

    for (const file of rawFiles) {
        const key = `${file.label}::${file.fileName}`;
        if (!seenKeys.has(key)) {
            uniqueFiles.push({
                fileName: file.fileName,
                label: file.label,
                name: file.name,
                base64Data: file.previewUrl?.split(',')[1]
            });
            seenKeys.add(key);
        } else {
            console.log('Duplicate skipped:', key);
        }
    }

    console.log('Unique reversal uploads:', JSON.stringify(uniqueFiles));

    // Now call Apex method with deduplicated list
    savePhotoUploadsReversal({
        recordId: this.recordId,
        listFiles: uniqueFiles
    })
    .then(result => {
        console.log('Reversal photos saved successfully:', result);
        // this.dispatchEvent(new ShowToastEvent({
        //     title: 'Success',
        //     message: 'Reversal photos uploaded.',
        //     variant: 'success'
        // }));
    })
    .catch(error => {
        console.error('Error uploading reversal photos:', error);
        // this.dispatchEvent(new ShowToastEvent({
        //     title: 'Error',
        //     message: 'Failed to upload reversal photos.',
        //     variant: 'error'
        // }));
    });
}


setlpgPhotoUploadSlots() {
    console.log('Inside method:', this.noOfPhotosLpg);
        const customLabels = ['Meter shifted Image'];
        this.lpgPhotoUploadSlots = Array.from({ length: this.noOfPhotosLpg }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: customLabels[index] || `Photo ${slotNum}`, 
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: ''
            };
        });
        console.log('📸 Photo Upload Slots:', JSON.stringify(this.photoUploadSlots));
}

handleFile(event) {
    this.lpgPhotoUploadSlots = event.detail.steps;
    console.log('Photo uploads:', JSON.stringify(this.lpgPhotoUploadSlots));

    // Upload photos and then show form page
    savePhotoUploadsLPG({
        recordId: this.recordId,
        listFiles: this.lpgPhotoUploadSlots
    }).then(() => {
         
        //this.showRemarksAfterUploadOrMCV = true;     
    }).catch(error => {
        console.error('Upload failed:', error);
    })
}



setmeterImageUploadSlots() {
    console.log('Inside method:', this.noOfPhotosMeter);
        const customLabels = ['pre installation', 'post installation'];
        this.meterImageUploadSlots = Array.from({ length: this.noOfPhotosMeter }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: customLabels[index] || `Photo ${slotNum}`, 
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: ''
            };
        });
        console.log('Photo Upload Slots:', JSON.stringify(this.photoUploadSlots));
}

handleMeterFileUpload(event) {
   const rawFiles = event.detail.steps;
    console.log('Raw reversal uploads:', JSON.stringify(rawFiles));

    // Deduplicate using label + fileName as unique key
    const uniqueFiles = [];
    const seenKeys = new Set();

    for (const file of rawFiles) {
        const key = `${file.label}::${file.fileName}`;
        if (!seenKeys.has(key)) {
            uniqueFiles.push({
                fileName: file.fileName,
                label: file.label,
                name: file.name,
                base64Data: file.previewUrl?.split(',')[1]
            });
            seenKeys.add(key);
        } else {
            console.log('Duplicate skipped:', key);
        }
    }

    console.log('Unique reversal uploads:', JSON.stringify(uniqueFiles));

    // Now call Apex method with deduplicated list
    savePhotoUploadsMeter({
        recordId: this.recordId,
        listFiles: uniqueFiles
    })
    .then(result => {
        console.log('Reversal photos saved successfully:', result);
        // this.dispatchEvent(new ShowToastEvent({
        //     title: 'Success',
        //     message: 'Reversal photos uploaded.',
        //     variant: 'success'
        // }));
       // this.showMeterReplacedSection = true;
    })
    .catch(error => {
        console.error('Error uploading reversal photos:', error);
    //     this.dispatchEvent(new ShowToastEvent({
    //         title: 'Error',
    //         message: 'Failed to upload reversal photos.',
    //         variant: 'error'
    //     }));
     });
}





 async handleBPFile(event) {
        console.log('📥 inside handleFile');
        //let newSlots = event.detail.steps;

           // const accId = event.target.dataset.id; 

        this.photoBPUploadSlots =event.detail.steps;
        for (let i = 0; i < photoBPUploadSlots.length; i++) {
        let slot = photoBPUploadSlots[i];
            console.log(`🔄 Processing Photo ${i + 1}`);

            if (slot.base64Data) {
                try {
                    // Add prefix if missing
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;

                    // 🔍 Original size in MB
                    const originalBytes = atob(fullBase64.split(',')[1]).length;
                    const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

                    // Convert to blob and compress
                    const blob = this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);

                    // Convert compressed Blob back to base64
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    const compressedBytes = atob(compressedBase64).length;
                    const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

                    // Store compressed result
                    slot.base64Data = compressedBase64;

                } catch (error) {
                //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);

                // Only show toast if compressed base64 is not usable
                if (!slot.base64Data || slot.base64Data.length < 100) {
                console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
                } else {
                    console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
                }
            }


            } else {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
            }
        }

            this.photoBPMap[accId] = photoBPUploadSlots;
           // this.userInputMap[accId]['imageDetails']=photoBPUploadSlots;
        console.log('✅ Final photoUploadSlots set');
    } 


      async base64ToBlob(base64Data) {
        const byteString = atob(base64Data.split(',')[1]);
        const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];
        const ab = new ArrayBuffer(byteString.length);
        const ia = new Uint8Array(ab);
        for (let i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
        }
        return new Blob([ab], { type: mimeString });
    }

  async compressImageFromURL(imageUrl) {
        return new Promise((resolve, reject) => {
            const img = new Image();

            img.onload = () => {
                try {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');
                    const maxWidth = 2400;
                    const maxHeight = 2400;
                    let width = img.width;
                    let height = img.height;

                    const ratio = Math.min(maxWidth / width, maxHeight / height);
                    width *= ratio;
                    height *= ratio;

                    canvas.width = width;
                    canvas.height = height;
                    ctx.drawImage(img, 0, 0, width, height);

                        try {
                            canvas.toBlob(
                                (blob) => {
                                    if (blob) {
                                        resolve(blob);
                                    } else {
                                        console.warn('⚠️ toBlob returned null. Possibly tainted canvas or unsupported format.');
                                        reject(new Error('Canvas compression failed. Blob was null.'));
                                    }
                                },
                                'image/jpeg',
                                9.1
                            );
                        } catch (err) {
                            console.error('❌ Error during canvas.toBlob execution:', err);
                            reject(new Error('Exception during canvas.toBlob: ' + err.message));
                        }
                } catch (error) {
                    reject(new Error('Error during image compression: ' + error.message));
                }
            };

            img.onerror = () => {
                reject(new Error('Error loading image.'));
            };

            img.crossOrigin = 'anonymous';
            img.src = imageUrl;
        });
    }

   async convertBlobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    }



    
    async handleBPFinalSave() {
       // const workStepName = 'Letters/Notices';
        // const allFilesSelected = this.photoUploadSlots.length === 6 &&
        //     this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        // if (!allFilesSelected) {
        //     this.load = false;
        //     //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
        //     this.showtoast('Warning', 'Please Capture 6 photos.', 'warning');
        //     return;
        // }

        // if(!this.afterImageRemark){

        //  this.showtoast('Warning', 'Please Enter Remark.', 'warning');
        //  return;
 
        // }

       

        this.load = true;

        //     let promises = [];


          var imagesList = [];
                this.photoBPUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                var temp = this.uploadFile(imagesList);


        saveImage({
            listFiles: imagesList,
            recordId: this.accRecordList[0].Id,
          //  afterImageRemark : this.afterImageRemark
           
        })
        .then((result) => {
          //  this.showToast('Success', 'Records Updated Successfully!', 'success');
            this.load = false;
           // history.back();
            this.dispatchEvent(new CustomEvent('cancel'));
        })
        .catch(error => {
            this.load = false;
            //console.error('❌ Save error:', JSON.stringify(error, null, 2));
            const message = error?.body?.message || error?.message || 'Unknown error occurred';
            this.showToast('Error', message, 'error');
        });

    //      let promises = [];

    // for (const accId in this.photoBPMap) {
    //     const imagesList = this.photoBPMap[accId];

    //     if (imagesList && imagesList.length > 0) {
    //         const uploadPromise = saveImage({
    //             listFiles: imagesList,
    //             recordId: accId  // ✅ Save as attachment to this Account
    //         });

    //         promises.push(uploadPromise);
    //     }
    // }

    // try {
    //     await Promise.all(promises);
    //     this.showtoast('Success', 'Images saved for all accounts.', 'success');
    // } catch (error) {
    //     const message = error?.body?.message || error?.message || 'Unknown error occurred';
    //     this.showtoast('Error', message, 'error');
    // } finally {
    //     this.load = false;
    //     this.dispatchEvent(new CustomEvent('cancel'));
    // }
    }

 
    
    
    uploadFile(imagesList) {

    }


}