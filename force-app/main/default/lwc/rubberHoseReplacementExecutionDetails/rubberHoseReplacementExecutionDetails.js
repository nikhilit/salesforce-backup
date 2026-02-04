import { LightningElement,api,track,wire } from 'lwc';
import getAccountInfoFromSA from '@salesforce/apex/RubberHoseReplacementExecutionDetaContr.getAccountInfoFromSA';
import updateServiceAppoinment from '@salesforce/apex/CheckInController.updateServiceAppoinment';
import { getLocationService } from 'lightning/mobileCapabilities';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getCheckInStatus from '@salesforce/apex/RubberHoseReplacementExecutionDetaContr.getCheckInStatus';
//import fieldPicklistValue from '@salesforce/apex/RubberHoseReplacementExecutionDetaContr.fieldPicklistValue';
import saveImage from '@salesforce/apex/RubberHoseReplacementExecutionDetaContr.saveImage';
import { getRecord } from 'lightning/uiRecordApi';
import WO_CASE_FIELD from '@salesforce/schema/WorkOrder.CaseId';

export default class RubberHoseReplacementExecutionDetails extends LightningElement {

 @api recordId;
//     account;
//     error;

//   @track accountView = true;

  @track load=false;

  @track showCheckBox=true;

  get availabilityOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }

            @track customerAvailability='';


           @track showNext=false;


      @track checkIn = true;;


  @track showRubberHose=false;

   @track lat;
   @track long;

   @track currentDateTime;

   @track ReasonForUnavailability=false;

   @track ishandleCaptureRiserDisabled=false;

   // @track reasonUnavailability = [];

     @track otherRemarkValue='';

     @track otherRemarkSelected = false;

     @track showChildWOStartEndDate=false;

     @track imageUploadPage=false;

         @track photoUploadSlots = [];
             noOfPhotos = 2;


        // @track rMCloserRemark ='';

          selectedDateTime;
      //selectedEndDateTime;
    @track reasonUnavailability = [];

//     reasonUnavailability = [
//   { label: 'Customer will call later', value: 'Customer will call later' },
//   { label: 'House locked', value: 'House locked' },
//   { label: 'CUSTOMER NOT ALLOWED', value: 'CUSTOMER NOT ALLOWED' },
//   { label: 'FALSE COMPLAINT', value: 'FALSE COMPLAINT' },
//   { label: 'Building Demolished', value: 'Building Demolished' },
//   { label: 'Customer call not responding', value: 'Customer call not responding' },
//   { label: 'Customer call not reachable', value: 'Customer call not reachable' },
//   { label: 'Address not found', value: 'Address not found' },
// //   { label: 'Customer Not Available', value: 'Customer Not Available' },
//   { label: 'Other', value: 'Other'}

// ];

@wire(getRecord, { recordId: '$recordId', fields: [WO_CASE_FIELD] })
wiredWorkOrder({ error, data }) {
    if (data) {
        const caseId = data.fields.CaseId.value;

        if (caseId) {
            console.log('This Work Order with Case:', caseId);
               this.reasonUnavailability = [
  { label: 'Customer will call later', value: 'Customer will call later' },
  { label: 'House locked', value: 'House locked' },
  { label: 'CUSTOMER NOT ALLOWED', value: 'CUSTOMER NOT ALLOWED' },
  { label: 'FALSE COMPLAINT', value: 'FALSE COMPLAINT' },
  { label: 'Building Demolished', value: 'Building Demolished' },
  { label: 'Customer call not responding', value: 'Customer call not responding' },
  { label: 'Customer call not reachable', value: 'Customer call not reachable' },
  { label: 'Address not found', value: 'Address not found' },
//   { label: 'Customer Not Available', value: 'Customer Not Available' },
  { label: 'Other', value: 'Other'}

];

        } else {

                this.reasonUnavailability = [
  { label: 'House locked', value: 'House locked' },
  { label: 'CUSTOMER NOT ALLOWED', value: 'CUSTOMER NOT ALLOWED' },
  { label: 'FALSE COMPLAINT', value: 'FALSE COMPLAINT' },
  { label: 'Building Demolished', value: 'Building Demolished' },
//   { label: 'Customer Not Available', value: 'Customer Not Available' },
  { label: 'Other', value: 'Other'}

];
            console.log('This Work Order without Case');
        }
    }
    if (error) {
        console.log('Error fetching work order:', error);
    }
}




    //   @track objectName='WorkOrder';
    //   @track fieldName='Reason_for_Unavailability__c';

          @track unavailability;


    //   fieldPicklistValue(){
    //     fieldPicklistValue({objectName:this.objectName, fieldName:this.fieldName})
    //     .then( result => {
    //         console.log('Rsult of picklist ::', result);
    //         this.reasonUnavailability=result;
    //         })
    //     .catch(error => {
    //             console.error('Error loading picklist values:', error);
    //         });
    // }


   connectedCallback() {


       // this.handleGetLocation();
        this.getCheckInStatus();
       // this.fieldPicklistValue();

    
     // this.getMobileLocation();

   }


   handleDateTimeChange(event) {
        this.selectedDateTime = event.target.value;
        console.log('Selected DateTime:', this.selectedDateTime);
    }

    // handleEndDateTimeChange(event) {
    //     this.selectedEndDateTime = event.target.value;
    //     console.log('Selected End DateTime:', this.selectedEndDateTime);
    // }




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


      handleAvailabilityChange(event) {
        if(event.target.value == 'Yes'){

            this.showCheckBox=false;
        this.customerAvailability = event.target.value;
        // this.customerAvilable=true;
        // this.customerNotAvilable = false;
        // this.customerNotAvilableRemark='';
        this.showRubberHose=true;
        this.ReasonForUnavailability=false;
            this.showNext=false;



        }
        if(event.target.value == 'No'){

         this.showCheckBox=false;

        this.customerAvailability = event.target.value;
            this.ReasonForUnavailability=true;
            this.showNext=true;
            this.showRubberHose=false;

           //  this.fieldPicklistValue();


        }
      }

      handleImageCapturePage() {

     if(!this.otherRemarkValue && this.otherRemarkSelected){

  this.showtoast('Warning', 'Remark is required.', 'warning');

    return;
    }

      if(!this.selectedDateTime && this.showChildWOStartEndDate){

  this.showtoast('Warning', 'Please Enter Start Date.', 'warning');

    return;
    }
       
       // this.formSecondPage = false;
        this.setPhotoUploadSlots();
        this.imageUploadPage = true;
        this.showNext=false;
        console.log('show next ::'+ this.showNext);
    }

    //  handleRMCloserRemark(event){

    //     this.rMCloserRemark = event.target.value;
    // }


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


    // handleCaptureRiser() {
    //    // this.showCheckBox = true;
    //    // this.accountView = false;
    //    // this.showRubberHose=true;
    //     this.handleCheckInCheckOut();
    // }

     handleGetLocation() {
        if (FORM_FACTOR === 'Large') {
            this.getBrowserLocation();
        } else {
            this.getMobileLocation();
        }
    }

    handleCancel() {

        this.handleCheckInCheckOut();
        if (FORM_FACTOR === 'Large') {
            const closeQA = new CustomEvent('close');
            this.dispatchEvent(closeQA);
        } else {
             
           setTimeout(() => {
            history.back();
        }, 1000); 
      
        }
    }



     handleCheckInCheckOut() {

        console.log('inside handle check in out method');
        this.load = true;

        console.log('Latitude handleCheckIn: ' + this.lat);
        console.log('Longitude handleCheckIn: ' + this.long);
        this.currentDateTime = new Date().toISOString();
        // Get current DateTime
        console.log('time: ' + this.currentDateTime);


        updateServiceAppoinment({ recordId: this.recordId, lat: this.lat, lon: this.long, checkIn : this.checkIn, currentDateTime : this.currentDateTime })
            .then(result => {
                this.load = false;
                console.log('inside success result');
                 console.log('result:::>>', result);

                if (result == 'Check In Successfully') {
                    console.log('inside check in success');
                   // this.checkIn=false;

                   // this.showRubberHose=true;
                  //  this.accountView = false;


                  //  this.showtoast('Success', 'Check In Successfully', 'success');
                }
                else if (result == 'Check Out Successfully') {
                    console.log('inside check out successfully');
           
                 // this.handleCancel();


                    //  this.showRubberHose=true;
                    // this.accountView = false;
                 //   this.showtoast('Success', 'Check Out Successfully', 'success');
                }
                //  else if (result === 'TOO_FAR_FROM_LOCATION') {
                //      console.log('inside to far from location');
                //     this.showtoast('Warning', 'TOO FAR FROM LOCATION', 'Warning');
                //     return;
                // }
                
            })
            .catch(error => {
                this.load = false;

                // this.dispatchEvent(customEvent);
                this.showtoast('Error', error, 'Error');
              //  this.handleCancel();
                console.log('inside catch');
                console.log('error::' + JSON.stringify(error));
            })

    }


 getBrowserLocation() {

        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    var latitude = position.coords.latitude;
                    var longitude = position.coords.longitude;
                    this.lat = latitude;
                    this.long = longitude;
                    this.lstMarkers = [
                        {
                            location: {
                                Latitude: latitude,
                                Longitude: longitude
                            },
                            title: "Your Current Location"
                        }
                    ];
                    this.zoomlevel = "10";

                    if(this.CheckInLocation == '' || this.CheckINDateTime == ''){
                       this.handleCheckInCheckOut();
                    }

                },
                (error) => {
                    this.showtoast('Warning', 'Please enable your device location', 'warning');
                    // this.checkIn = false;
                    // this.checkOut = false;
                this.showCheckBox=false;

                     this.handleCancel();
                }
            );
        } else {
            this.showtoast('Warning', 'Geolocation is not supported by this browser', 'warning');
            // this.checkIn = false;
            // this.checkOut = false;

        }


    }








 getMobileLocation() {
        const locationService = getLocationService();

        if (!locationService || !locationService.isAvailable()) {
            this.showtoast('LocationService Not Available', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
         //   this.checkIn = false;
         //   this.checkOut = false;
         //   this.showMap = true;

         this.ishandleCaptureRiserDisabled=true;



            return;
        }

        const options = {
            enableHighAccuracy: true
        };

        locationService.getCurrentPosition(options)
            .then(result => {
                console.log('Location result:', result);

                this.lat = result.coords.latitude;
                this.long = result.coords.longitude;

                this.lstMarkers = [{
                    location: {
                        Latitude: this.lat,
                        Longitude: this.long
                    },
                    title: "Your Current Location"
                }];
                this.zoomlevel = "15";

                  if(this.CheckInLocation == '' || this.CheckINDateTime == ''){
                       this.handleCheckInCheckOut();
                    }



            })
            .catch(error => {
                console.error('Location error:', error);
                this.showtoast('Warning', 'Please enable your device location.', 'Warning');
              //  this.checkIn = false;
              //  this.checkOut = false;

                this.handleCancel();
                this.showCheckBox=false;
                  this.ishandleCaptureRiserDisabled=true;


            })
            .finally(() => {
                // this.requestInProgress = false;
            });


    }


    // @track reasonUnavailability = [];


    //   @track objectName='WorkOrder';
    //   @track fieldName='Reason_for_Unavailability__c';

    //       @track unavailability;


    //   fieldPicklistValue(){
    //     fieldPicklistValue({objectName:this.objectName, fieldName:this.fieldName})
    //     .then( result => {
    //         console.log('Rsult of picklist ::', result);
    //         this.reasonUnavailability=result;
    //         })
    //     .catch(error => {
    //             console.error('Error loading picklist values:', error);
    //         });
    // }

      handlereasonForUnavailability(event) {

        console.log('event detail value ::', event.detail.value);
        console.log('event detail value ::', event.target.value);

        this.unavailability = event.detail.value;

        console.log('Reson unavilability ::', this.unavailability);

        if(this.unavailability =='Other'){

            console.log('reason other inside::', this.unavailability);

            this.otherRemarkSelected=true;

           console.log('reason other inside::', this.otherRemarkSelected);

           this.showChildWOStartEndDate=false;

           // this.showEnterCustomerNameFlatNumber=false;
        }
          if(this.unavailability !='Other'){


           // this.otherRemarkSelected=false;
             this.showChildWOStartEndDate=false;

           // this.showEnterCustomerNameFlatNumber=false;
        }
         

        if(event.target.value=='House locked'){

           // this.showEnterCustomerNameFlatNumber=true;
            this.otherRemarkSelected=false;
            this.showChildWOStartEndDate=true;
        }
         if(event.target.value!='House locked'){

           // this.showEnterCustomerNameFlatNumber=true;
            this.otherRemarkSelected=false;
            this.showChildWOStartEndDate=false;
        }
    }

    handleOtherRemark(event){

        this.otherRemarkValue = event.target.value;
    }



    getCheckInStatus() {
        console.log('recordId:::' + this.recordId);
        getCheckInStatus({ recordId: this.recordId })
            .then(result => {
                console.log('inside success' + JSON.stringify(result));
              
            this.CheckOutLocation = result.Check_Out_Lat_Long__c ? String(result.Check_Out_Lat_Long__c) : '';
            this.CheckInLocation = result.Check_In_Lat_Long__c ? String(result.Check_In_Lat_Long__c) : '';
             this.CheckINDateTime = result.O_MCheckInTimestamp__c	 ? result.O_MCheckInTimestamp__c : '';
             this.CheckOutDateTime = result.O_MCheckOutTimestamp__c	 ? result.O_MCheckOutTimestamp__c : '';
            
                // if(this.CheckOutLocation != '' && this.CheckInLocation != '' && this.CheckOutDateTime != '' && this.CheckINDateTime != ''){
                //     this.checkOut = false;
                //     this.checkIn = false;
                //     this.showEnableMessage = true;
                //     this.showMap = false;
                //     this.handleCancel();
                //      this.showtoast('warning','Already Checked In','warning');
                // }

                 if((this.CheckInLocation != '' || this.CheckINDateTime != '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')) {
                    this.checkIn = false;
                    this.checkOut = true;
                }
                else if((this.CheckOutLocation != '' || this.CheckOutDateTime != '') && (this.CheckInLocation == '' || this.CheckINDateTime == '')){ 
                    this.checkIn = true;
                    this.checkOut = false;
                }
                // else if((this.CheckInLocation != '' || this.CheckINDateTime != '') && (this.CheckOutLocation == '' || this.CheckOutDateTime == '')){
                //     this.checkIn = true;
                //     this.checkOut = false;
                // }
                this.handleGetLocation();

            })
            .catch(error => {
                // this.dispatchEvent(customEvent);
                this.showtoast('Error', error, 'Error');
              //  this.handleCancel();
                console.log('inside catch');
                console.log('error::' + JSON.stringify(error));
            })

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

    this.getCheckInStatus();
       // const workStepName = 'Letters/Notices';
        const allFilesSelected = this.photoUploadSlots.length === 2 &&
            this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.load = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
            this.showtoast('Warning', 'Please Capture 2 photos.', 'warning');
            return;
        }

        // if(!this.rMCloserRemark){

        //  this.showtoast('Warning', 'Please Enter Closer Remark.', 'warning');
        // return;
        // }

         if(!this.otherRemarkValue && this.otherRemarkSelected){

  this.showtoast('Warning', 'Please Enter Remark.', 'warning');

    return;
    }

         if(!this.selectedDateTime && this.showChildWOStartEndDate){

  this.showtoast('Warning', 'Please Enter Start Date.', 'warning');

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
           // rMCloserRemark : this.rMCloserRemark,
            selectedDateTime : this.selectedDateTime
          //  selectedEndDateTime : this.selectedEndDateTime
           
        })
        .then((result) => {
            this.showtoast('Success', 'Details saved successfully!', 'success');
            this.load = false;

           // this.handleCheckInCheckOut();

            //this.handleCancel();
             setTimeout(() => {
            history.back();
        }, 1000);
         //  history.back();

         //   this.dispatchEvent(new CustomEvent('cancel'));
        })
        .catch(error => {
            this.load = false;
            //console.error('❌ Save error:', JSON.stringify(error, null, 2));
            const message = error?.body?.message || error?.message || 'Unknown error occurred';
            this.showtoast('Error', message, 'error');
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









      showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }



}