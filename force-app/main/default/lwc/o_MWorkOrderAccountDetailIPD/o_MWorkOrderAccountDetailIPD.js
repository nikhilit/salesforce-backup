import { LightningElement, api, wire, track } from 'lwc';
import getAccountInfoFromSA from '@salesforce/apex/O_MWorkOrderAccountInfoControllerIPD.getAccountInfoFromSA';
import fieldPicklistValue from '@salesforce/apex/O_MWorkOrderAccountInfoControllerIPD.fieldPicklistValue';
//import updateServiceAppointment from '@salesforce/apex/WorkOrderAccountInfoController.updateServiceAppointment';
import saveImage from '@salesforce/apex/O_MWorkOrderAccountInfoControllerIPD.saveImage';
import getWOrderWType from '@salesforce/apex/O_MWorkOrderAccountInfoControllerIPD.getWOrderWType';
import checkWorkStep from '@salesforce/apex/O_MWorkOrderAccountInfoControllerIPD.checkWorkStep';
import woApprovalStatus from '@salesforce/apex/O_MWorkOrderAccountInfoControllerIPD.woApprovalStatus';



// import getGroupDataForTodayAppointments from '@salesforce/apex/WorkOrderAccountInfoController.getGroupDataForTodayAppointments';
// // import searchGroupDetails from '@salesforce/apex/WorkOrderAccountInfoController.searchGroupDetails';
// // import searchGroupMessage from '@salesforce/apex/WorkOrderAccountInfoController.searchGroupMessage';
// import updateServiceAppointment from '@salesforce/apex/WorkOrderAccountInfoController.updateServiceAppointment';

// import getGroupMasterOptions from '@salesforce/apex/WorkOrderAccountInfoController.getGroupMasterOptions';
// import getGroupCodeOptions from '@salesforce/apex/WorkOrderAccountInfoController.getGroupCodeOptions';
// import getGroupMessageOptions from '@salesforce/apex/WorkOrderAccountInfoController.getGroupMessageOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';

export default class O_MWorkOrderAccountDetail extends NavigationMixin(LightningElement) {
    @api recordId;
    account;
    error;
//    @track reasonUnavailability = [];

     get availabilityOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }

    @track showCustomerAvailability = false;
@track customerAvailability = '';
@track individualDisconnection = false;
@track cnaIPDisconnection = false;


     @track accountView = true;

     @track wOWorkType='';

     @track dueDate;


      @track otherRemark=false;
     @track otherRemarkValue='';
     @track rMCloserRemark ='';




    @track showCheckBox=false;
    @track showCaptureRiserDetails=false;
    @track showRubberHose=false;
    @track meterReplacement=false;
    @track riserReplacementForm=false;

    @track customerAvailability='';
    @track showMaintenanceEntry=false;
    @track riserPaintingSiteInfo=false;
    @track buildingDemolitionAppointmentExecution=false;
    @track afterSalesAppointmentExecution=false;

    @track rMReasonForUnavailability=false;
    @track rHRReasonForUnavailability=false;
    @track mRReasonForUnavailability=false;
    @track rRReasonForUnavailability=false;
    @track rPReasonForUnavailability=false;

    @track domesticMeterChecking=false;
    @track cnaDomesticMeter=false;

    @track unavailability;
    @track reasonUnavailability=[];
    @track objectName='WorkOrder';
    @track fieldName='Reason_for_Unavailability__c';
    @track showImageUpload=false;
    @track photoUploadSlots = [];
    @track imageUploadPage = false;
    noOfPhotos = 2;
    @track load=false;
    @track showNext=false;


    @track ishandleCaptureRiserDisabled=false;
    connectedCallback() {
        this.checkWorkStep();
        this.fieldPicklistValue();
        this.getWOrderWType();
        this.woApprovalStatus();
        
    }

     checkWorkStep(){
    console.log('inside check work order step');
    checkWorkStep({recordId:this.recordId})
    .then( result => {

        console.log('Result upload site status:::', result);
        if(result !='Completed'){
            console.log('inside new if');
             LightningAlert.open({
            message: 'Please Complete Upload Site Document Task',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
         //   this.showtoast('Warning', 'Please Complete Upload Site Document Task', 'warning');
            this.ishandleCaptureRiserDisabled=true;
        }
    })
    .catch( error => {
        console.log('Error getting approval ::', error);
    })
  }

    fieldPicklistValue(){
        fieldPicklistValue({objectName:this.objectName, fieldName:this.fieldName})
        .then( result => {
            console.log('Rsult of picklist ::', result);
            this.reasonUnavailability=result;
            })
        .catch(error => {
                console.error('Error loading picklist values:', error);
            });
    }

    getWOrderWType(){
        getWOrderWType({recordId :this.recordId})
        .then( result => {
            console.log('Result ::', result);
        this.wOWorkType=result;

        })
        .catch(error => {
            console.log('Error ::', error);
        })
    }

     woApprovalStatus(){
        woApprovalStatus({recordId :this.recordId})
        .then( result => {
            console.log('Result ::', result);

        if(result !='Approved'){
      // this.ishandleCaptureRiserDisabled=true;
        }
        if(result =='Approved'){

        //    this.ishandleCaptureRiserDisabled=false;
        }
        })
        .catch(error => {
            console.log('Error ::', error);
        })
    }
    //Account 360 view 
    @wire(getAccountInfoFromSA, { workOrderId: '$recordId' })
    wiredAccountInfo({ error, data }) {
        if (data) {
            console.log('Account data received:', data);
            this.account = data.acc;
            this.error = undefined;

let dateStr = data.acc.RH_Due_Date__c; 

let dateObj = new Date(dateStr);

let day = String(dateObj.getDate()).padStart(2, '0');
let month = String(dateObj.getMonth() + 1).padStart(2, '0'); 
let year = dateObj.getFullYear();

    this.dueDate = `${day}-${month}-${year}`;



        } else if (error) {
            console.error('Error fetching account:', error);
            this.account = undefined;
            this.error = error;
        }
    }

    // handleCaptureRiser() {
    //     //this.showCaptureRiserDetails=true;
    //     this.individualDisconnection=true;
    //     this.showCheckBox = true;
    //     // this.formFirstPage = true;
    //     // this.formSecondPage = false;
    //     // this.imageUploadPage = false;
    //     this.accountView = false;
    //     this.checkWorkType();
    // }

    handleCaptureRiser() {
   // this.showCustomerAvailability = true;
    this.accountView = false;
    this.individualDisconnection = true;
   // this.cnaIPDisconnection = false;
}

handleAvailabilityChange(event) {
    this.customerAvailability = event.detail.value;

    if (this.customerAvailability === 'Yes') {
        console.log('OUTPUT : INSIDE YES');
        this.showCaptureRiserDetails = true;
        this.individualDisconnection = true;
        this.showCustomerAvailability = false;
        this.cnaIPDisconnection = false;
    } else if (this.customerAvailability === 'No') {
        console.log('OUTPUT : INSIDE NO');
        this.showCaptureRiserDetails = true;
        this.individualDisconnection = false;
        this.cnaIPDisconnection = true;
        this.showCustomerAvailability = false;
    }
}

get availabilityOptions() {
    return [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];
}


    checkWorkType(){

    if(this.wOWorkType=='Riser Maintenance'){

        this.showMaintenanceEntry=true;
        this.showRubberHose=false;
       this.meterReplacement=false;
       this.riserReplacementForm=false;
       this.riserPaintingSiteInfo=false;
        this.individualDisconnection=false;
        this.domesticMeterChecking=false;
        this.buildingDemolitionAppointmentExecution=false;
        this.afterSalesAppointmentExecution=false;


    //      this.rMReasonForUnavailability=false;
    //     this.rHRReasonForUnavailability=false;
    //    this.mRReasonForUnavailability=false;
    //    this.rRReasonForUnavailability=false;
    //    this.rPReasonForUnavailability=false;
    //    this.cnaIPDisconnection=false;
    //    this.cnaDomesticMeter=false;

        }
        if(this.wOWorkType=='Rubber Hose Replacement'){


            this.showRubberHose =true;
            this.showMaintenanceEntry=false;
           this.meterReplacement=false;
           this.riserReplacementForm=false;
           this.riserPaintingSiteInfo=false;
           this.individualDisconnection=false;
           this.domesticMeterChecking=false;
          this.buildingDemolitionAppointmentExecution=false;
           this.afterSalesAppointmentExecution=false;




    //          this.rMReasonForUnavailability=false;
    //     this.rHRReasonForUnavailability=false;
    //    this.mRReasonForUnavailability=false;
    //    this.rRReasonForUnavailability=false;
    //    this.rPReasonForUnavailability=false;
    //     this.cnaIPDisconnection=false;
    //     this.cnaDomesticMeter=false;



        }
          if(this.wOWorkType=='Meter Replacement'){


            this.showRubberHose =false;
            this.showMaintenanceEntry=false;
            this.meterReplacement=true;
            this.riserReplacementForm=false;
            this.riserPaintingSiteInfo=false;
            this.individualDisconnection=false;
            this.domesticMeterChecking=false;
            this.buildingDemolitionAppointmentExecution=false;
            this.afterSalesAppointmentExecution=false;
 


    //           this.rMReasonForUnavailability=false;
    //     this.rHRReasonForUnavailability=false;
    //    this.mRReasonForUnavailability=false;
    //    this.rRReasonForUnavailability=false;
    //    this.rPReasonForUnavailability=false;
    //    this.cnaIPDisconnection=false;
    //      this.cnaDomesticMeter=false;


        }
        if(this.wOWorkType =='Riser Replacement'){


            this.showRubberHose =false;
            this.showMaintenanceEntry=false;
            this.meterReplacement=false;
            this.riserReplacementForm=true;
            this.riserPaintingSiteInfo=false;
             this.individualDisconnection=false;
            this.domesticMeterChecking=false;
            this.buildingDemolitionAppointmentExecution=false;
            this.afterSalesAppointmentExecution=false;


    //           this.rMReasonForUnavailability=false;
    //     this.rHRReasonForUnavailability=false;
    //    this.mRReasonForUnavailability=false;
    //    this.rRReasonForUnavailability=false;
    //    this.rPReasonForUnavailability=false;
    //   this.cnaIPDisconnection=false;
    //          this.cnaDomesticMeter=false;



        }

          if(this.wOWorkType =='Riser Painting'){


            this.showRubberHose =false;
            this.showMaintenanceEntry=false;
            this.meterReplacement=false;
            this.riserReplacementForm=false;
            this.riserPaintingSiteInfo=true;
             this.individualDisconnection=false;
            this.domesticMeterChecking=false;
             this.buildingDemolitionAppointmentExecution=false;
            this.afterSalesAppointmentExecution=false;


    //           this.rMReasonForUnavailability=false;
    //     this.rHRReasonForUnavailability=false;
    //    this.mRReasonForUnavailability=false;
    //    this.rRReasonForUnavailability=false;
    //    this.rPReasonForUnavailability=false;
    //    this.cnaIPDisconnection=false;
    //    this.cnaDomesticMeter=false;




        }


    }

    

   /*  handleAvailabilityChange(event) {
        if(event.target.value == 'Yes'){

            this.showCheckBox=false;
        this.customerAvailability = event.target.value;

        if(this.wOWorkType=='Riser Maintenance'){
           this.showCheckBox=false;

        this.showMaintenanceEntry=true;
        this.showRubberHose=false;
       this.meterReplacement=false;
       this.riserReplacementForm=false;
       this.riserPaintingSiteInfo=false;
        this.individualDisconnection=false;
        this.domesticMeterChecking=false;
        this.buildingDemolitionAppointmentExecution=false;
        this.afterSalesAppointmentExecution=false;


         this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
       this.cnaIPDisconnection=false;
       this.cnaDomesticMeter=false;

        }
        if(this.wOWorkType=='Rubber Hose Replacement'){

            this.showCheckBox=false;

            this.showRubberHose =true;
            this.showMaintenanceEntry=false;
           this.meterReplacement=false;
           this.riserReplacementForm=false;
           this.riserPaintingSiteInfo=false;
           this.individualDisconnection=false;
           this.domesticMeterChecking=false;
          this.buildingDemolitionAppointmentExecution=false;
           this.afterSalesAppointmentExecution=false;




             this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
        this.cnaIPDisconnection=false;
        this.cnaDomesticMeter=false;



        }
          if(this.wOWorkType=='Meter Replacement'){

           this.showCheckBox=false;

            this.showRubberHose =false;
            this.showMaintenanceEntry=false;
            this.meterReplacement=true;
            this.riserReplacementForm=false;
            this.riserPaintingSiteInfo=false;
            this.individualDisconnection=false;
            this.domesticMeterChecking=false;
            this.buildingDemolitionAppointmentExecution=false;
            this.afterSalesAppointmentExecution=false;
 


              this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
       this.cnaIPDisconnection=false;
         this.cnaDomesticMeter=false;


        }
        if(this.wOWorkType =='Riser Replacement'){

              this.showCheckBox=false;

            this.showRubberHose =false;
            this.showMaintenanceEntry=false;
            this.meterReplacement=false;
            this.riserReplacementForm=true;
            this.riserPaintingSiteInfo=false;
             this.individualDisconnection=false;
            this.domesticMeterChecking=false;
            this.buildingDemolitionAppointmentExecution=false;
            this.afterSalesAppointmentExecution=false;


              this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
      this.cnaIPDisconnection=false;
             this.cnaDomesticMeter=false;



        }

          if(this.wOWorkType =='Riser Painting'){

                this.showCheckBox=false;

            this.showRubberHose =false;
            this.showMaintenanceEntry=false;
            this.meterReplacement=false;
            this.riserReplacementForm=false;
            this.riserPaintingSiteInfo=true;
             this.individualDisconnection=false;
            this.domesticMeterChecking=false;
             this.buildingDemolitionAppointmentExecution=false;
            this.afterSalesAppointmentExecution=false;


              this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
       this.cnaIPDisconnection=false;
       this.cnaDomesticMeter=false;




        }
         if(this.wOWorkType =='Individual Permanent Disconnection'){

                this.showCheckBox=false;

            this.showRubberHose =false;
            this.showMaintenanceEntry=false;
            this.meterReplacement=false;
            this.riserReplacementForm=false;
            this.riserPaintingSiteInfo=false;
             this.individualDisconnection=true;
             this.domesticMeterChecking=false;
             this.buildingDemolitionAppointmentExecution=false;
            this.afterSalesAppointmentExecution=false;
  


              this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
        this.cnaIPDisconnection=false;
        this.cnaDomesticMeter=false;




        }

          if(this.wOWorkType =='Domestic Meter Checking'){

                this.showCheckBox=false;

            this.showRubberHose =false;
            this.showMaintenanceEntry=false;
            this.meterReplacement=false;
            this.riserReplacementForm=false;
            this.riserPaintingSiteInfo=false;
             this.individualDisconnection=false;
             this.domesticMeterChecking=true;
            this.buildingDemolitionAppointmentExecution=false;
            this.afterSalesAppointmentExecution=false;



              this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
        this.cnaIPDisconnection=false;
        this.cnaDomesticMeter=false;




        }

          if(this.wOWorkType =='Building Demolition'){

                this.showCheckBox=false;

            this.showRubberHose =false;
            this.showMaintenanceEntry=false;
            this.meterReplacement=false;
            this.riserReplacementForm=false;
            this.riserPaintingSiteInfo=false;
             this.individualDisconnection=false;
             this.domesticMeterChecking=false;
            this.buildingDemolitionAppointmentExecution=true;
           this.afterSalesAppointmentExecution=false;
 


              this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
        this.cnaIPDisconnection=false;
        this.cnaDomesticMeter=false;




        }

          if(this.wOWorkType =='After sales Service'){

                this.showCheckBox=false;

            this.showRubberHose =false;
            this.showMaintenanceEntry=false;
            this.meterReplacement=false;
            this.riserReplacementForm=false;
            this.riserPaintingSiteInfo=false;
             this.individualDisconnection=false;
             this.domesticMeterChecking=false;
            this.buildingDemolitionAppointmentExecution=false;
           this.afterSalesAppointmentExecution=true;
 


              this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
        this.cnaIPDisconnection=false;
        this.cnaDomesticMeter=false;




        }

       


        this.rMReasonForUnavailability=false;
       // this.showCheckBox=true;
       // this.showNext=true;

         this.showCheckBox=false;



        console.log('inside yes click');
        }
         if(event.target.value == 'No'){


        this.customerAvailability = event.target.value;
                   this.showCheckBox=false;


        if(this.wOWorkType=='Riser Maintenance'){

         this.showCheckBox=false;

        this.rMReasonForUnavailability=true;
        this.showMaintenanceEntry=false;
        this.showRubberHose=false;
        this.meterReplacement=false;
        this.riserReplacementForm=false;
        this.riserPaintingSiteInfo=false;
        this.individualDisconnection=false;
         this.showCheckBox=true;
        this.showNext=true;
        this.fieldPicklistValue();

        }

         if(this.wOWorkType=='Rubber Hose Replacement'){

              this.showCheckBox=false;

        this.showMaintenanceEntry=false;
        this.showRubberHose=false;
        this.meterReplacement=false;
        this.riserReplacementForm=false;
        this.riserPaintingSiteInfo=false;
         this.domesticMeterChecking=false;


        this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=true;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
     this.cnaIPDisconnection=false;
        this.cnaDomesticMeter=false;


       

        }

         if(this.wOWorkType=='Meter Replacement'){

           this.showCheckBox=false;

        this.showMaintenanceEntry=false;
        this.showRubberHose=false;
        this.meterReplacement=false;
        this.riserReplacementForm=false;
        this.riserPaintingSiteInfo=false;
         this.domesticMeterChecking=false;


        this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=true;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
       this.cnaIPDisconnection=false;
             this.cnaDomesticMeter=false;


        }

         if(this.wOWorkType=='Riser Replacement'){

           this.showCheckBox=false;

        this.showMaintenanceEntry=false;
        this.showRubberHose=false;
        this.meterReplacement=false;
        this.riserReplacementForm=false;
        this.riserPaintingSiteInfo=false;
         this.domesticMeterChecking=false;


        this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=true;
       this.rPReasonForUnavailability=false;
       this.cnaIPDisconnection=false;
        this.cnaDomesticMeter=false;


        }

         if(this.wOWorkType=='Riser Painting'){

         this.showCheckBox=false;

        this.showMaintenanceEntry=false;
        this.showRubberHose=false;
        this.meterReplacement=false;
        this.riserReplacementForm=false;
        this.riserPaintingSiteInfo=false;
         this.domesticMeterChecking=false;


        this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=true;
       this.cnaIPDisconnection=false;
        this.cnaDomesticMeter=false;


        }

           if(this.wOWorkType=='Individual Permanent Disconnection'){

         this.showCheckBox=false;

        this.showMaintenanceEntry=false;
        this.showRubberHose=false;
        this.meterReplacement=false;
        this.riserReplacementForm=false;
        this.riserPaintingSiteInfo=false;
        this.domesticMeterChecking=false;


        this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
       this.cnaIPDisconnection=true;
         this.cnaDomesticMeter=false;


        }

            if(this.wOWorkType=='Domestic Meter Checking'){

         this.showCheckBox=false;

        this.showMaintenanceEntry=false;
        this.showRubberHose=false;
        this.meterReplacement=false;
        this.riserReplacementForm=false;
        this.riserPaintingSiteInfo=false;
        this.domesticMeterChecking=false;


        this.rMReasonForUnavailability=false;
        this.rHRReasonForUnavailability=false;
       this.mRReasonForUnavailability=false;
       this.rRReasonForUnavailability=false;
       this.rPReasonForUnavailability=false;
       this.cnaIPDisconnection=false;
         this.cnaDomesticMeter=true;


        }


       this.showCheckBox=false;
     

        }
    }

    */

    //  handlereasonForUnavailability(event) {
    //     console.log('event detail value ::', event.detail.value);
    //     console.log('event detail value ::', event.target.value);

    //     this.unavailability = event.detail.value;
    // }

    handlereasonForUnavailability(event) {
        console.log('event detail value ::', event.detail.value);
        console.log('event detail value ::', event.target.value);

        this.unavailability = event.detail.value;

        if(this.unavailability =='Other'){

            this.otherRemark=true;
        }
    }

    handleOtherRemark(event){

        this.otherRemarkValue = event.target.value;
    }

    handleRMCloserRemark(event){

        this.rMCloserRemark = event.target.value;
    }

    // handleNext(){

    //     this.showImageUpload=true;
    // }

/* old handlefile
     handleFile(event) {
        this.photoUploadSlots = event.detail.steps;
        console.log('handleFile this.photoUploadSlots::'+JSON.stringify(this.photoUploadSlots));
    }

    */

 handleImageCapturePage() {

     if(!this.otherRemarkValue && this.otherRemark){

         LightningAlert.open({
            message: 'Remark is required.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });

        // this.showtoast('Warning', 'Remark is required.', 'warning');

    return;
    }
       
       // this.formSecondPage = false;
        this.setPhotoUploadSlots();
        this.imageUploadPage = true;
        this.showNext=false;
        console.log('show next ::'+ this.showNext);
    }

    async handleFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.photoUploadSlots =event.detail.steps;

        for (let i = 0; i < photoUploadSlots.length; i++) {
        let slot = photoUploadSlots[i];
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



    
   async handleFinalSave() {
       // const workStepName = 'Letters/Notices';
        const allFilesSelected = this.photoUploadSlots.length === 2 &&
            this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.load = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
          LightningAlert.open({
            message: 'Please Capture 2 photos',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
           // this.showtoast('Warning', 'Please Capture 2 photos.', 'warning');
            return;
        }

        if(!this.rMCloserRemark){

             LightningAlert.open({
            message: 'Please Enter Closer Remark',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
      //   this.showtoast('Warning', 'Please Enter Closer Remark.', 'warning');
        return;
        }

         if(!this.otherRemarkValue && this.otherRemark){

             LightningAlert.open({
            message: 'Please Enter Remark',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
         //this.showtoast('Warning', 'Please Enter Remark.', 'warning');

    return;
    }

        this.load = true;

         var imagesList = [];
                this.photoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                var temp = this.uploadFile(imagesList);

        saveImage({
            listFiles: imagesList,
            recordId: this.recordId,
            reasonUnavailability : this.unavailability,
            otherRemarkValue : this.otherRemarkValue,
            rMCloserRemark : this.rMCloserRemark
           
        })
        .then((result) => {
             LightningAlert.open({
            message: 'Images saved successfully',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        });
          //  this.showtoast('Success', 'Images saved successfully!', 'success');
            this.load = false;
        // commenting as discused with customer they will click on cancel button
        //      setTimeout(() => {
        //     history.back();
        // }, 1000);
        // commenting as discused with customer they will click on cancel button


           // history.back();

         //   this.dispatchEvent(new CustomEvent('cancel'));
        })
        .catch(error => {
            this.load = false;
            //console.error('❌ Save error:', JSON.stringify(error, null, 2));
            const message = error?.body?.message || error?.message || 'Unknown error occurred';
          //  this.showtoast('Error', message, 'error');
        });
    }

     uploadFile(imagesList) {

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
                    const maxWidth = 1600;
                    const maxHeight = 1600;
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

     setPhotoUploadSlots() {
        this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => ({
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

/*old setphotouploadslots
     setPhotoUploadSlots() {
        console.log('Inside method:', this.noOfPhotos);
        this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: `Photo ${slotNum}`,
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: ''
            };
        });
        console.log('📸 Photo Upload Slots:', JSON.stringify(this.photoUploadSlots));
    }


 old handlefinalsave
   handleFinalSave() {
        this.load = true;
        console.log(' Starting handleSavePhotos...');
        console.log('Reason for unavailability :::', this.unavailability);
         console.log(' Base 64 ...', JSON.stringify(this.photoUploadSlots));

         saveImage({listFiles:this.photoUploadSlots,recordId:this.recordId,reasonUnavailability : this.unavailability})
        .then((result) => {

            console.log('Result ::', result);
           // this.showNext=false;
             this.load = false;
            
         this.showtoast('Success', 'Images and data saved successfully!', 'Success');
          this.handleCancel();          

        })                
            .catch(error => {
                this.load = false;
                console.error('Error updating work order:', error);
                this.error = error;
            });
    } */

    handleCloseFromChild(){

        console.log('inside handle close from child in parent');
        //this.showCaptureRiserDetails=false;
        this.individualDisconnection=false;
        setTimeout(() => {
            history.back();
        }, 1000);        
         console.log('inside handle cancel');
    }

    handleCancel() {

        //this.showCaptureRiserDetails=false;
        this.individualDisconnection=false;
        this.showRubberHose=false;

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