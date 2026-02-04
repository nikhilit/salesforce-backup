import { LightningElement, track, api } from 'lwc';
//import markCustomerUnavailable from '@salesforce/apex/MeterDetailsController.markCustomerUnavailable';
import savePhotoUploadsDomesticMeter from '@salesforce/apex/MeterDetailsController.savePhotoUploadsDomesticMeter';
import updateMeterStatus from '@salesforce/apex/MeterDetailsController.updateMeterStatus';
import uploadPhotosToWorkOrder from '@salesforce/apex/MeterDetailsController.uploadPhotosToWorkOrder';
import uploadPhotosToWorkOrderMeter from '@salesforce/apex/MeterDetailsController.uploadPhotosToWorkOrderMeter';
import uploadPhotosToGas from '@salesforce/apex/MeterDetailsController.uploadPhotosToGas';
import updateGasStatus from '@salesforce/apex/MeterDetailsController.updateGasStatus';
import getLastUnavailableVisitDate from '@salesforce/apex/MeterDetailsController.getLastUnavailableVisitDate';
//import markSiteDetailsAsCompleted from '@salesforce/apex/MeterDetailsController.markSiteDetailsAsCompleted';
import uploadCNAPhoto from '@salesforce/apex/MeterDetailsController.uploadCNAPhoto';
import checkWorkStep from '@salesforce/apex/MeterDetailsController.checkWorkStep';
import followUpDetails from '@salesforce/apex/MeterDetailsController.followUpDetails';
import LightningAlert from 'lightning/alert';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomerAvailability extends LightningElement {
    @track selectedOption;
    @track uploadedFileName;
    @track remarks = '';
    @api recordId;
    @track photoUploadSlots = [];
    @track photoUploadSlotsYes = [];

        @track photoUploadSlotsYesMeterInstallation = [];
        @track photoUploadSlotsYesBeforeMeterReading = [];
        @track photoUploadSlotsYesStoveBurning = [];
        @track photoUploadSlotsYesAfterMeterPhoto = [];


@track followUpValue = '';
@track showFollowUpDateSection=false;

    @track meterNumber = '';
    @track meterNumberGas = '';
    imageUploadPage = false;
    @track selectedReasons = [];
    @track showAvailabilitySelection = true;
    @track lastUnavailableDate;

    @track showCustomerYesSubmitButton=false;

    @track followUpCount='';

    @track meterMake='';

    @track showFollowUpConfirmed=false;

     @track meterMakeOptions = [
    { label: 'AEM SA', value: 'AEM SA' },
    { label: 'Elster', value: 'Elster' },
    { label: 'Itron', value: 'Itron' },
    { label: 'Raychem RPG', value: 'Raychem RPG' },
    { label: 'Sensus', value: 'Sensus' },
    { label: 'Hangzhou Beta', value: 'Hangzhou Beta' },
    { label: 'Greenglobe', value: 'Greenglobe' },
    { label: 'Genus Power', value: 'Genus Power' },
    { label: 'Capital Innotech', value: 'Capital Innotech' },
    { label: 'Pietro Fiorentini', value: 'Pietro Fiorentini' },
    { label: 'Smartmeters Technologies', value: 'Smartmeters Technologies' }
];

    noOfPhotos = 3;
  //  noOfPhotosYes = 4;
  noOfPhotosYesMeterInstallation =1;
  noOfPhotosYesBeforeMeterPhoto =1;
  noOfPhotosYesStoveBurningPhoto =1;
  noOfPhotosYesAfterMeterPhoto =1;
    noOfPhotosMeter = 3;
    noOfPhotosGas = 3;
    @track leakTestValue = '';
    @track gasLeakageCheckValue = '';
    @track closeCard = true;

     @track fileName = '';
      @track fileData='';

    @track isload = false;

    get gasLeakageOptions() {
    return [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];
}

get followUpDateOptions() {
    return [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];
}


handleMeterMakeChange(event) {
    this.meterMake = event.detail.value;
}

get reasonOptionsMeter() {
        return [
            { label: 'Permanent Disconnection', value: 'Permanent Disconnection' },
            { label: 'Miscellaneous', value: 'Miscellaneous' }
        ];
    }

    handleReasonChangeMeter(event) {
        this.selectedReasons = event.detail.value || [];

        this.showPermanentDisconnection = this.selectedReasons.includes('Permanent Disconnection');
        this.showMiscellaneous = this.selectedReasons.includes('Miscellaneous');
        if(this.showMiscellaneous){
        this.showPermanentDisconnection = true;
        }

    }

handleGasLeakageChange(event) {
    this.gasLeakageCheckValue = event.detail.value;
}

handleFollowUpDate(event) {
    this.followUpValue = event.detail.value;

    if(event.target.value =='Yes'){

        this.showFollowUpDateSection=true;
        this.remarks='';
        this.selectedDateTime='';
    }
    if(event.target.value =='No'){

        this.showFollowUpDateSection=false;
        this.selectedDateTime='';
       // this.showRemarks=true;
    }
    // else{

    //     this.showFollowUpDateSection=false;
    //    // this.showRemarks=false;
    // }
}

    @api 
    set imageList(value) {
        this.steps = value;
    }

     leakTestOptions = [
        { label: 'Ok', value: 'Ok'},
        { label: 'Not Ok', value: 'Not Ok'},
        { label: 'Na', value: 'Na'}
    ];

//     get leakTestOptions() {
//     return [
//         { label: 'Ok', value: 'Ok' },
//         { label: 'Not Ok', value: 'NNot Ok'},
//         { label: 'Na', value: 'Na' }
//     ];
// }

handleLeakTestChange(event) {
    console.log('event target value::', event.target.value);

    this.leakTestValue = event.detail.value;
}

    get imageList() {
        return this.steps;
    }

    @api disabled=false;
    @track steps = [];

     @track selectedDateTime ='';

     @track showSubmitButton=false;

  
    @track checkInDisabled = false;
    @track meterInfoSubmitted = false;
    //@track singleImageList = [];
    @track wrappedPhotoList = [];
    @track disableCheckOut = true; 
    @track isUploading = false;
    @track imagesSubmitted = false;
    @track isMeterAvailable = '';
@track isUsingGas = '';
@track reasonNoMeter = '';
@track reasonGasNotUsed = '';

@track showMeterUnavailableSection = false;
@track showGasUsageQuestion = false;
@track showGasNotUsedSection = false;

@track meterUnavailablePhotos = [];
@track gasNotUsedPhotos = [];

yesNoOptions = [
    { label: 'Yes', value: 'Yes' },
    { label: 'No', value: 'No' }
];


    availabilityOptions = [
        { label: 'No', value: 'No' },
        { label: 'CNA', value: 'CNA' },
        { label: 'Yes', value: 'Yes' }
    ];

    reasonOptions = [
        { label: 'House Lock', value: 'House Lock' },
        { label: 'Customer refused access', value: 'Customer refused access' },
        { label: 'Building Redevelopment', value: 'Building Redevelopment' },
        { label: 'Other', value: 'Other' }
    ];

   @track selectedReason = '';

   @track showCnaPhotoUpload=false;


    handleSelection(event) {
    this.selectedOption = event.detail.value;
    if(this.selectedOption =='CNA'){

    // this.showAvailabilitySelection = false; 
    this.showSubmitButton=false;
    //this.showCustomerYesSubmitButton=false;
    this.showCnaPhotoUpload=true;


    }
     if(this.selectedOption !='CNA'){

    // this.showAvailabilitySelection = false;
    this.showSubmitButton=true;
    this.showCnaPhotoUpload=false;
    //this.showCustomerYesSubmitButton=true;

    }

    //  if(this.selectedOption =='Yes'){

    //     console.log('inside yes selected');

    //  this.showCustomerYesSubmitButton=true;
    // this.showSubmitButton=false;
    // this.showCnaPhotoUpload=false;


    // }
    //  if(this.selectedOption !='Yes'){

    //  //this.showAvailabilitySelection = false; 
    //  this.showCustomerYesSubmitButton=false;f

    // }

    //   if(this.selectedOption =='No'){

    //  this.showAvailabilitySelection = false;
    //  this.showCustomerYesSubmitButton=false;
    // this.showSubmitButton=true;

    // }
    //  if(this.selectedOption !='No'){

    // // this.showAvailabilitySelection = false; 
    //  this.showCustomerYesSubmitButton=false;
    // this.showSubmitButton=false;

    // }





    this.showAvailabilitySelection = true; //need to change false
    // Possibly reset some other flags/data here as well
}

    get showRemarks() {
        return this.selectedReason === 'Other';
    }

     get showFollowUpConfirmedRemarks() {
        return this.followUpValue === 'No';
    }

    handleRemarks(event) {
        this.remarks = event.detail.value;
    }

    get showCnaDomestic() {
        return this.selectedOption === 'No';
    }

    get showCnaPhotoUpload() {
        return this.selectedOption === 'CNA';
    }

    get showDomesticMeterCheck() {
        return this.selectedOption === 'Yes';
    }

    get showMeterExecutionSection() {
    return this.isMeterAvailable === 'Yes' && this.isUsingGas === 'Yes';
}

       connectedCallback() {
    console.log('Record Id is:::', this.recordId); 
    
     this.checkWorkStep();

    this.setPhotoUploadSlots();
   // this.setPhotoUploadSlotsYes();
    this.setPhotoUploadSlotsYesMeterInstallation();
    this.setPhotoUploadSlotsYesBeforeMeterReading();
    this.setPhotoUploadSlotsYesStoveBurning();
    this.setPhotoUploadSlotsYesAfterMeterPhoto();

    this.fetchLastUnavailableDate();
    this.followUpDetails();
     
        this.setmeterUnavailablePhotos();
        this.setgasNotUsedPhotos();
    this.steps = [
        { id: 1, label: 'Meter Counter', uploaded: false },
        { id: 2, label: 'Before Meter', uploaded: false },
        { id: 3, label: 'After Meter', uploaded: false },
        { id: 4, label: 'House Lock', uploaded: false }
    ];
}


followUpDetails(){

    followUpDetails({recordId : this.recordId})
    .then(result => {

        console.log('Follow up result ::', result);
        this.followUpCount= result.length;
    })
    .catch(error => {

        console.log('errro ::', error);
    })
}


 checkWorkStep(){
    console.log('inside check work order step');
    checkWorkStep({recordId:this.recordId})
    .then( result => {

        console.log('Result :::', result);
        if(result !='Completed'){

              LightningAlert.open({
            message: 'Please Complete Check In Task',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
          //  this.showtoast('Warning', 'Please Complete Check In Task', 'warning');
             this.showCheckBox = false;

            this.handleCancel();
        }
    })
    .catch( error => {
        console.log('Error getting approval ::', error);
    })
  }



fetchLastUnavailableDate() {
    getLastUnavailableVisitDate({ workOrderId: this.recordId })
        .then(result => {
            this.lastUnavailableDate = result;
            console.log('🕓 Last unavailable visit date:', result);
        })
        .catch(error => {
            console.error('❌ Failed to fetch last unavailable visit date', error);
        });
}

// handleFollowUpDateChange(event) {
//     this.followUpDate = event.detail.value;
// }
 handleDateTimeChange(event) {
        this.selectedDateTime = event.target.value;
        console.log('Selected DateTime:', this.selectedDateTime);
    }

handleMeterAvailability(event) {
    this.isMeterAvailable = event.detail.value;
    this.showMeterUnavailableSection = (this.isMeterAvailable === 'No');
    this.showGasUsageQuestion = (this.isMeterAvailable === 'Yes');

    if (this.showMeterUnavailableSection) {
        this.meterUnavailablePhotos = [
            { id: 1, label: 'Photo 1', uploaded: false },
            { id: 2, label: 'Photo 2', uploaded: false },
            { id: 3, label: 'Photo 3', uploaded: false }
        ];

        this.isUsingGas = '';
        this.showGasNotUsedSection = false;
        this.reasonGasNotUsed = '';
        // this.gasNotUsedPhotos = [];
    }
}

handleGasUsage(event) {
    this.isUsingGas = event.detail.value;
    this.showGasNotUsedSection = (this.isUsingGas === 'No');
    this.showGasUsageQuestion = false;
}

handleReasonNoMeter(event) {
    this.reasonNoMeter = event.detail.value;
}


handleReasonGasNotUsed(event) {
    this.reasonGasNotUsed = event.detail.value;
}

getSingleImageList(photo) {
    return [photo];
}

handleMeterNumber(event) {

     console.log('event detail value::', event.detail.value);

    this.meterNumber = event.detail.value;
}

handleMeterNumberGas(event) {

    console.log('event detail value::', event.detail.value);
    this.meterNumberGas = event.detail.value;
}


// handleFileMeter(event) {
  
//     this.meterUnavailablePhotos = event.detail.steps;
//     console.log('Photo uploads:', JSON.stringify(this.meterUnavailablePhotos));

// }


// handleFileGas(event) {
//   this.gasNotUsedPhotos = event.detail.steps;
//     console.log('Photo uploads:', JSON.stringify(this.gasNotUsedPhotos));

    
// }


    setPhotoUploadSlots() {
    console.log('Inside method:', this.noOfPhotos);
    
    const customLabels = [
        'Photo 1', 'Photo 2', 'Photo 3'
    ];

    this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => {
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

// setPhotoUploadSlotsYes() {
//     console.log('Inside method:', this.noOfPhotosYes);
    
//     const customLabels = [
//         'Meter Installation Photo',
//         'Before Meter Photo',
//         'Stove Burning Photo',
//         'After Meter Photo'
//     ];

//     this.photoUploadSlotsYes = Array.from({ length: this.noOfPhotosYes }, (_, index) => {
//             const slotNum = index + 1;
//             return {
//                 id: slotNum,
//                 index: slotNum,
//                 label: customLabels[index] || `Photo ${slotNum}`,
//                 name: `fileUploader${slotNum}`,
//                 fileName: '',
//                 uploaded: false,
//                 previewUrl: '',
//                 showBeforeReading: index === 0, 
//                 showMiddleReading: index === 1, 
//                 showAfterReading: index === 2 
//             };
//         });
//         console.log('📸 Photo Upload Slots:', JSON.stringify(this.photoUploadSlotsYes));
// }

    setPhotoUploadSlotsYesMeterInstallation() {
     console.log('Inside method:', this.noOfPhotosYesMeterInstallation);
    
    this.photoUploadSlotsYesMeterInstallation = Array.from({ length: this.noOfPhotosYesMeterInstallation }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: 'Meter Installation Photo',
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: '',
               
            };
        });
        console.log('📸 Photo Upload Slots:', JSON.stringify(this.photoUploadSlotsYesMeterInstallation));
}


  setPhotoUploadSlotsYesBeforeMeterReading() {
     console.log('Inside method:', this.noOfPhotosYesBeforeMeterPhoto);
    
    this.photoUploadSlotsYesBeforeMeterReading = Array.from({ length: this.noOfPhotosYesBeforeMeterPhoto }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: 'Before Meter Photo',
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: '',
               
            };
        });
        console.log('📸 Photo Upload Slots:', JSON.stringify(this.photoUploadSlotsYesBeforeMeterReading));
}

setPhotoUploadSlotsYesStoveBurning() {
     console.log('Inside method:', this.noOfPhotosYesStoveBurningPhoto);
    
    this.photoUploadSlotsYesStoveBurning = Array.from({ length: this.noOfPhotosYesStoveBurningPhoto }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: 'Stove Burning Photo',
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: '',
               
            };
        });
        console.log('📸 Photo Upload Slots:', JSON.stringify(this.photoUploadSlotsYesStoveBurning));
}

setPhotoUploadSlotsYesAfterMeterPhoto() {
     console.log('Inside method:', this.noOfPhotosYesAfterMeterPhoto);
    
    this.photoUploadSlotsYesAfterMeterPhoto = Array.from({ length: this.noOfPhotosYesAfterMeterPhoto }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: 'After Meter Photo',
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: '',
               
            };
        });
        console.log('📸 Photo Upload Slots:', JSON.stringify(this.photoUploadSlotsYesAfterMeterPhoto));
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




 async handleFileYesMeterInstallation(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.photoUploadSlotsYesMeterInstallation =event.detail.steps;

        for (let i = 0; i < photoUploadSlotsYesMeterInstallation.length; i++) {
        let slot = photoUploadSlotsYesMeterInstallation[i];
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

    async handleFileYesBeforeMeterReading(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.photoUploadSlotsYesBeforeMeterReading =event.detail.steps;

        for (let i = 0; i < photoUploadSlotsYesBeforeMeterReading.length; i++) {
        let slot = photoUploadSlotsYesBeforeMeterReading[i];
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

     async handleFileYesStoveBurning(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.photoUploadSlotsYesStoveBurning =event.detail.steps;

        for (let i = 0; i < photoUploadSlotsYesStoveBurning.length; i++) {
        let slot = photoUploadSlotsYesStoveBurning[i];
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

    async handleFileYesAfterMeterReading(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.photoUploadSlotsYesAfterMeterPhoto =event.detail.steps;

        for (let i = 0; i < photoUploadSlotsYesAfterMeterPhoto.length; i++) {
        let slot = photoUploadSlotsYesAfterMeterPhoto[i];
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


     async handleFileYes(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.photoUploadSlotsYes =event.detail.steps;

        for (let i = 0; i < photoUploadSlotsYes.length; i++) {
        let slot = photoUploadSlotsYes[i];
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



  /*  async handleFileYes(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.photoUploadSlotsYes =event.detail.steps;

        for (let i = 0; i < photoUploadSlotsYes.length; i++) {
        let slot = photoUploadSlotsYes[i];
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
    } */


    async handleFileMeter(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.meterUnavailablePhotos =event.detail.steps;

        for (let i = 0; i < meterUnavailablePhotos.length; i++) {
        let slot = meterUnavailablePhotos[i];
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

async handleFileGas(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.gasNotUsedPhotos =event.detail.steps;

        for (let i = 0; i < gasNotUsedPhotos.length; i++) {
        let slot = gasNotUsedPhotos[i];
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

   


setmeterUnavailablePhotos() {
    console.log('Inside method:', this.noOfPhotosMeter);
    
    const customLabelsMeter = [
        'Photo 1',
        'Photo 2',
        'Photo 3'
    ];

    this.meterUnavailablePhotos = Array.from({ length: this.noOfPhotosMeter }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: customLabelsMeter[index] || `Photo ${slotNum}`,
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: ''
            };
        });
        console.log('📸 Photo Upload Slots:', JSON.stringify(this.meterUnavailablePhotos));
}

setgasNotUsedPhotos() {
    console.log('Inside method:', this.noOfPhotosGas);
    
    const customLabelsGas = [
        'Meter Photo',
        'Meter Installation Photo',
        'Rubber Tube Disconnected photo'
    ];

    this.gasNotUsedPhotos = Array.from({ length: this.noOfPhotosGas }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: customLabelsGas[index] || `Photo ${slotNum}`,
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: ''
            };
        });
        console.log('📸 Photo Upload Slots:', JSON.stringify(this.gasNotUsedPhotos));
}


    removeImage(event) {
        console.log('removeImage');
        const stepId = Number(event.target.dataset.id);
        this.steps = this.steps.map(step => {
            if (step.id === stepId) {
                return { ...step, uploaded: false, previewUrl: '' };
            }
            return step;
        });
        this.handleReturn();
    }

    handleReturn() {
        const valueSelectedEvent = new CustomEvent("change", {
            detail: { steps: this.steps },
        });
        this.dispatchEvent(valueSelectedEvent);

    }

    @track meterStatus = '';
   @track meterReading = '';
   @track beforeMeterReading = '';
   @track afterMeterReading = '';
    @track reason = '';
    //imageType = '';
   @track isRunning = false;
   @track isNotRunning = false;

    statusOptions = [
    { label: 'Gas Not Used', value: 'Gas Not Used' },
    { label: 'Ok', value: 'Ok' },
    { label: 'Not Ok', value: 'Not Ok' }
    // { label: 'Yes', value: 'Yes' },
    // { label: 'No', value: 'No' }
];


    imageOptions = [
        { label: 'Meter Counter', value: 'Meter Counter' },
        { label: 'Before Meter', value: 'Before Meter' },
        { label: 'After Meter', value: 'After Meter' },
        { label: 'House Lock', value: 'House Lock' }
    ];

    handleStatusChange(event) {

     console.log('event detail value::', event.detail.value);

        this.meterStatus = event.detail.value;
        this.isRunning = this.meterStatus === 'Ok';
        this.isNotRunning = this.meterStatus === 'Not Ok';
    }

    handleReading(event) {
        this.meterReading = event.detail.value;
    }

    handleBeforeReading(event) {

         const value = event.target.value;
    console.log('event detail value::', value);

    // Regex: up to 5 digits before decimal, optional decimal with up to 3 digits
        const regex = /^\d{1,5}(\.\d{0,3})?$/;

    if (regex.test(value)) {
        this.beforeMeterReading = value;
    } else {
        this.beforeMeterReading = null;
             LightningAlert.open({
            message: 'Please enter valid Meter Reading (max 5 digits before decimal and 3 after).',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
     //   this.showtoast('Warning', 'Please enter valid Meter Reading (max 5 digits before decimal and 3 after).', 'warning');
    }

    //  console.log('event detail value::', event.detail.value);

    //    // this.beforeMeterReading = event.detail.value;

    //      this.beforeMeterReading = parseInt(event.target.value, 10);


    //     if (this.beforeMeterReading >= 1 && this.beforeMeterReading <= 99999) {

        
    //     }

    //     else {
    //    this.beforeMeterReading = null;
        
    //   this.showtoast('Warning', 'Please Enter Valid Meter Reading.', 'warning');

    //     }
    }

    handleAfterReading(event) {

              const value = event.target.value;
    console.log('event detail value::', value);

    // Regex: up to 5 digits before decimal, optional decimal with up to 3 digits
        const regex = /^\d{1,5}(\.\d{0,3})?$/;

    if (regex.test(value)) {
        this.afterMeterReading = value;
    } else {
        this.afterMeterReading = null;
             LightningAlert.open({
            message: 'Please enter valid Meter Reading (max 5 digits before decimal and 3 after).',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
      //  this.showtoast('Warning', 'Please enter valid Meter Reading (max 5 digits before decimal and 3 after).', 'warning');
    }

    //  console.log('event detail value::', event.detail.value);

    //    // this.afterMeterReading = event.detail.value;

    //    this.afterMeterReading = parseInt(event.target.value, 10);


    //     if (this.afterMeterReading >= 1 && this.afterMeterReading <= 99999) {

        
    //     }

    //     else {
    //    this.afterMeterReading = null;
        
    //   this.showtoast('Warning', 'Please Enter Valid Meter Reading.', 'warning');

    //     }
    }

    handleReason(event) {
        this.reason = event.detail.value;
    }

    handleImageStepsChange(event) {
    this.steps = event.detail.steps;
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



    get showRemarks() {
        return this.selectedReason === 'Other';
    }

    get showFollowUp() {
        return this.selectedReason === 'House Lock';
    }

    handleReasonChange(event) {
    this.selectedReason = event.detail.value;

    if(this.selectedReason === 'House Lock'){
        console.log('inside if house lock');
        this.showFollowUpConfirmed=true;
        this.imageUploadPage = true;
 //this.showFollowUpConfirmedRemarks=false;
        this.showFollowUpDateSection=false;  
       this.remarks='';
       this.selectedDateTime='';
       this.followUpValue='';
       this.photoUploadSlots = [];
        this.setPhotoUploadSlots();

    //     this.photoUploadSlots = this.photoUploadSlots.map(slot => ({
    //     ...slot,
    //     fileName: '',
    //     base64Data: ''
    // }));

    }
     else if (this.selectedReason === 'Building Redevelopment') {

        console.log('inside if not house lock and not building redevelopment');

        this.imageUploadPage = true;
        this.showFollowUpConfirmed= false;
        this.selectedDateTime='';
        this.followUpValue='';
         this.showFollowUpDateSection=false;  
         this.remarks='';
        this.photoUploadSlots = [];
        this.setPhotoUploadSlots();


    //      this.photoUploadSlots = this.photoUploadSlots.map(slot => ({
    //     ...slot,
    //     fileName: '',
    //     base64Data: ''
    // }));

     }
    else{
                console.log('inside if not house lock and not building redevelopment 2');
        this.imageUploadPage = false;
         this.showFollowUpConfirmed= false;
           this.selectedDateTime='';
        this.followUpValue='';
         this.showFollowUpDateSection=false;  
       this.remarks='';
              this.photoUploadSlots = [];
        this.setPhotoUploadSlots();

    //  this.photoUploadSlots = this.photoUploadSlots.map(slot => ({
    //     ...slot,
    //     fileName: '',
    //     base64Data: ''
    // }));

        // this.showFollowUpConfirmed= false;
        // this.remarks='';
        // this.selectedDateTime='';
        // this.followUpValue='';
        // this.showFollowUpConfirmedRemarks=false;
        // this.showFollowUpDateSection=false;

    }
   
    // if (this.selectedReason === 'House Lock' || this.selectedReason === 'Building Redevelopment') {
    //     this.imageUploadPage = true;
    //  }
    //  else {
    //     this.imageUploadPage = false;
    //   //  this.showFollowUpConfirmed=false;

    // }
}


    handleRemarks(event) {
        this.remarks = event.detail.value;
    }

    async handleFinalAnyEncroachedSave() {
       // const workStepName = 'Letters/Notices';
        const allFilesSelected = this.showAnyEncroachedPhotoUploadSlots.length === 1 &&
            this.showAnyEncroachedPhotoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.isload = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
           // this.showtoast('Warning', 'Please Capture 1 photos.', 'warning');
            return;
        }
      

        
        this.isload = true;

         var imagesList = [];
                this.showAnyEncroachedPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                var temp = this.uploadFile(imagesList);

        saveImageAnyEncroached({
            listFiles: imagesList,
            recordId: this.recordId,
          
           
        })
        .then((result) => {
          //  this.showtoast('Success', 'Images saved successfully!', 'success');
            this.isload = false;
           
           // history.back();

         //   this.dispatchEvent(new CustomEvent('cancel'));
        })
        .catch(error => {
            this.isload = false;
            //console.error('❌ Save error:', JSON.stringify(error, null, 2));
            const message = error?.body?.message || error?.message || 'Unknown error occurred';
               LightningAlert.open({
            message: 'error',
            theme: 'error',   // red error dialog
            label: 'Error'    // header text
        });
           // this.showtoast('Error', message, 'error');
        });
    }


     handleCancel() {

 setTimeout(() => {
            history.back();
        }, 1000);   

     }     



    handleSubmit() {

        console.log('inside handle submit');

 console.log('meternumber::', this.meterNumberGas);
          console.log('meterreading::', this.meterReading);

if(this.selectedOption == 'No'){

            this.isload=true;


    console.log('selectedOption::', this.selectedOption);
    if (!this.selectedReason) {
        // this.dispatchEvent(new ShowToastEvent({
        //     title: 'Error',
        //     message: 'Please select a reason.',
        //     variant: 'error'
        // }));
                   LightningAlert.open({
            message: 'Please select a reason.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
                //    this.showtoast('Warning', 'Please select a reason.', 'warning');

         this.isload=false;

        return;
    }

    if (this.selectedReason === 'House Lock' && this.followUpValue =='') {
   

         LightningAlert.open({
            message: 'Is follow up date confirmed with user required',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
             
             //   this.showtoast('Warning', 'Please select a follow-up visit date', 'warning');

     this.isload=false;

    return;
}

    if (this.selectedReason === 'House Lock' && !this.selectedDateTime && this.followUpValue =='Yes') {
   

         LightningAlert.open({
            message: 'Please select a follow-up visit date',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
             
             //   this.showtoast('Warning', 'Please select a follow-up visit date', 'warning');

     this.isload=false;

    return;
}
  if (this.selectedReason === 'House Lock' && !this.remarks && this.followUpValue =='No') {
   

         LightningAlert.open({
            message: 'Please Enter Remark',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
             
             //   this.showtoast('Warning', 'Please select a follow-up visit date', 'warning');

     this.isload=false;

    return;
}
// Call Apex to mark "Site Details" as completed
    // markSiteDetailsAsCompleted({ workOrderId: this.workOrderId })
    //     .then(() => {
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: 'Success',
    //             message: 'Site Details step marked as completed.',
    //             variant: 'success'
    //         }));
    //     })
    //     .catch(error => {
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: 'Error',
    //             message: error.body.message,
    //             variant: 'error'
    //         }));
    //     });

    console.log('this.photoUploadSlots.length ::', this.photoUploadSlots.length);

    //   const allFilesSelected = this.photoUploadSlots.length === 3 &&
    //         this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

    const allFilesSelected =
    this.photoUploadSlots.length === 3 &&
     this.photoUploadSlots.some(
        slot => slot.fileName && slot.base64Data
    );

        if (!allFilesSelected && (this.selectedReason =='House Lock' || this.selectedReason=='Building Redevelopment')) {
            this.isload = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
                LightningAlert.open({
            message: 'Please Capture 1 photo.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
         //   this.showtoast('Warning', 'Please Capture 3 photos.', 'warning');


            return;
        }
      

        

         var imagesList = [];
                this.photoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                var temp = this.uploadFile(imagesList);

                console.log('selectedReason::', this.selectedReason);

                let dateTimeValue = this.selectedDateTime
    ? new Date(this.selectedDateTime).toISOString()
    : null;

        savePhotoUploadsDomesticMeter({

             recordId: this.recordId,
             listFiles: imagesList ,
              reason: this.selectedReason,
              remarks: this.remarks || '',
             selectedDateTime: dateTimeValue,

          // selectedDateTime: this.selectedDateTime || null,
           selectedOption : this.selectedOption || '',
           followUpValue : this.followUpValue

                    
        })

        .then(result => {

            console.log('Result upload save photo domestic meter::', result);


             LightningAlert.open({
            message: 'Details Saved Successfully',
            theme: 'success',   // red error dialog
            label: 'success'    // header text
        }).then(() => {
                       
      this.isload=false;
       this.handleCancel();
         });
        
             // this.showtoast('Success', 'Details Saved Successfully.', 'success');

               //  this.handleCancel();

           //  this.isload=false;


        })
        

   
    .catch(error => {
        console.error('❌ Error during submission:', error);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: this.getErrorMessage(error),
            variant: 'error'
        }));
         this.isload=false;

    })
   
    
} else {

   console.log('Inside else submit meter info onclick:::');

//    this.isUploading = true;
//     this.saveDisabled = true;

    this.isload=true;

       

    const shouldUpdateMeterStatus = this.isMeterAvailable === 'Yes' && this.isUsingGas === 'Yes';
    const shouldUploadUnavailablePhotos = this.isMeterAvailable === 'No';
    const shouldUploadGasNotUsedPhotos = this.isMeterAvailable === 'Yes' && this.isUsingGas === 'No';

    console.log('shouldUpdateMeterStatus ::', shouldUpdateMeterStatus);
    console.log('shouldUploadUnavailablePhotos ::', shouldUploadUnavailablePhotos);
    console.log('shouldUploadGasNotUsedPhotos ::', shouldUploadGasNotUsedPhotos);


    let updateMeterPromise = Promise.resolve();

    if (shouldUpdateMeterStatus) {
      //  this.isload=true;
        console.log('inside shouldUpdateMeterStatus ture');
        //  const allFilesSelected = this.photoUploadSlotsYes.length === 4 &&
        //     this.photoUploadSlotsYes.every(slot => slot.fileName && slot.base64Data);

        // if (!allFilesSelected) {
        //  //   this.isload = false;
        //     //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
        //     this.showtoast('Warning', 'Please Capture 4 photos.', 'warning');

        //          this.isload=false;

        //     return;
        // }

          const allFilesSelectedMeterInstallation = this.photoUploadSlotsYesMeterInstallation.length === 1 &&
            this.photoUploadSlotsYesMeterInstallation.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelectedMeterInstallation) {
         //   this.isload = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
         
              LightningAlert.open({
            message: 'Please Capture Meter Installation photo.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
          //  this.showtoast('Warning', 'Please Capture Meter Installation photo.', 'warning');

                 this.isload=false;

            return;
        }

        const allFilesSelectedBeforeMeterReading = this.photoUploadSlotsYesBeforeMeterReading.length === 1 &&
            this.photoUploadSlotsYesBeforeMeterReading.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelectedBeforeMeterReading) {
         //   this.isload = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
          
                LightningAlert.open({
            message: 'Please Capture Before Meter Reading Photo.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
          //  this.showtoast('Warning', 'Please Capture Before Meter Reading Photo.', 'warning');

                 this.isload=false;

            return;
        }

        const allFilesSelectedStoveBurning = this.photoUploadSlotsYesStoveBurning.length === 1 &&
            this.photoUploadSlotsYesStoveBurning.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelectedStoveBurning) {
         //   this.isload = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
           
                LightningAlert.open({
            message: 'Please Capture Stove Burning Photo.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
          //  this.showtoast('Warning', 'Please Capture Stove Burning Photo.', 'warning');

                 this.isload=false;

            return;
        }

         const allFilesSelectedAfterMeterReading = this.photoUploadSlotsYesAfterMeterPhoto.length === 1 &&
            this.photoUploadSlotsYesAfterMeterPhoto.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelectedAfterMeterReading) {
         //   this.isload = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
         
          LightningAlert.open({
            message: 'Please Capture After Meter Reading Photo.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
           // this.showtoast('Warning', 'Please Capture After Meter Reading Photo.', 'warning');

                 this.isload=false;

            return;
        }


       

        if(!this.beforeMeterReading || !this.afterMeterReading){

           
            LightningAlert.open({
            message: 'Please Enter Before And After Meter Reading.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
           //  this.showtoast('Warning', 'Please Enter Before And After Meter Reading.', 'warning');

                 this.isload=false;

            return;


        }
        updateMeterPromise = updateMeterStatus({
            recordId: this.recordId,
            status: this.meterStatus,
            //reading: this.meterReading,
            beforeReading: this.beforeMeterReading,
            afterReading: this.afterMeterReading,
            reason: this.reason,
            meterNumber: this.meterNumber,
            isMeterAvailable: this.isMeterAvailable,
            isUsingGas: this.isUsingGas,
            gasLeakageCheckValue: this.gasLeakageCheckValue,
            leakTestValue : this.leakTestValue,
            meterMake : this.meterMake
        }).then(() => {

            console.log('inside then reuslt of shouldUpdateMeterStatus');
            this.meterInfoSubmitted = true;
           //  this.isload=false;

        });
    }

    if (shouldUploadGasNotUsedPhotos) {

      //  this.isload=true;

        console.log('inside shouldUploadGasNotUsedPhotos ture');

         const allFilesSelected = this.gasNotUsedPhotos.length === 3 &&
            this.gasNotUsedPhotos.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.isload = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
          
             LightningAlert.open({
            message: 'Please Capture 3 photos',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
          //  this.showtoast('Warning', 'Please Capture 3 photos.', 'warning');

                 this.isload=false;

            return;
        }

       


        updateMeterPromise = updateGasStatus({
            recordId: this.recordId,
            meterNumber: this.meterNumberGas,
            reading: this.meterReading,
            reasonGasNotUsed: this.reasonGasNotUsed
        }).then(() => {
            this.meterInfoSubmitted = true;
             this.isload=false;

        });
    }

    

    updateMeterPromise
        .then(() => {

         //   this.isload=true;
            console.log('✅ uploadPhotosToWorkOrder done');
            if (shouldUpdateMeterStatus) {

             console.log('inside shouldUpdateMeterStatus inside updatemeterpromise');

            console.log('photoUploadSlotsYesMeterInstallation ::', this.photoUploadSlotsYesMeterInstallation);
      
            console.log('photoUploadSlotsYesBeforeMeterReading ::', this.photoUploadSlotsYesBeforeMeterReading);
            console.log('photoUploadSlotsYesStoveBurning ::', this.photoUploadSlotsYesStoveBurning);
            console.log('photoUploadSlotsYesAfterMeterPhoto ::', this.photoUploadSlotsYesAfterMeterPhoto);

        

         var imageListYes = [];
                // this.photoUploadSlotsYes.forEach(item => {
                //     imageListYes.push({
                //         base64Data: item.base64Data,
                //         fileName: item.fileName,
                //         label: item.label
                //     })
                // })

                this.photoUploadSlotsYesMeterInstallation.forEach(item => {
                    imageListYes.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                 this.photoUploadSlotsYesBeforeMeterReading.forEach(item => {
                    imageListYes.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                 this.photoUploadSlotsYesStoveBurning.forEach(item => {
                    imageListYes.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                 this.photoUploadSlotsYesAfterMeterPhoto.forEach(item => {
                    imageListYes.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

              //  system.debug('uploadimageyes ::', JSON.stringify(imageListYes));


                var temp = this.uploadFile(imageListYes);

                return uploadPhotosToWorkOrder({
                    recordId: this.recordId,
                    listFiles: imageListYes
                });
            }  
            return Promise.resolve();
        })


        .then(() => {
         //   this.isload=true;
            if (shouldUploadUnavailablePhotos) {

                 const allFilesSelected = this.meterUnavailablePhotos.length === 3 &&
            this.meterUnavailablePhotos.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.isload = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
            LightningAlert.open({
            message: 'Please Capture 3 photos.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
         //   this.showtoast('Warning', 'Please Capture 3 photos.', 'warning');

                 this.isload=false;

        return Promise.reject(new Error('❌ Please upload at least 3 images.'));
        }

           

    
          

                console.log('✅ uploadPhotosToWorkOrderMeter done');
                return uploadPhotosToWorkOrderMeter({
                    recordId: this.recordId,
                    listFiles: this.meterUnavailablePhotos,
                    customerAvailableOrNot : this.selectedOption || '',
                    isMeterAvailable : this.isMeterAvailable || '',
                     meterNotAvailableSelectedReasons : this.selectedReasons || '',
                    miscellaneousRemark : this.reasonNoMeter || ''
                });
            }
            return Promise.resolve();
        })
        .then(() => {

           // this.isload=true;

            if (shouldUploadGasNotUsedPhotos) {
                console.log('✅ updateGasStatus done');

      var imageListGasNotUsed = [];
                this.gasNotUsedPhotos.forEach(item => {
                    imageListGasNotUsed.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                var temp = this.uploadFile(imageListGasNotUsed);

                return uploadPhotosToWorkOrder({
                    recordId: this.recordId,
                    listFiles: imageListGasNotUsed
                });


                
            }
            return Promise.resolve();
        })
        .then(() => {
          
          //  this.isload=true;

              LightningAlert.open({
            message: 'Details Saved Successfully',
            theme: 'success',   // red error dialog
            label: 'success'    // header text
        }).then(() => {
                       
      this.isload=false;
       this.handleCancel();
         });

             //   this.showtoast('Success', 'Details Saved Successfully.', 'success');

              

                   // this.isload=false;


                 //  this.handleCancel();


           
        })
        .catch(error => {
            this.isload=false;
            console.error('Upload failed:', JSON.stringify(error, null, 2));
            // this.dispatchEvent(new ShowToastEvent({
            //     title: 'Error',
            //     message: error?.body?.message || error?.message || 'Upload failed.',
            //     variant: 'error'
            // }));
        })
       

}

}

getErrorMessage(error) {
        try {
            if (error?.body?.message) return error.body.message;
            if (error?.message) return error.message;
            return JSON.stringify(error);
        } catch (e) {
            return 'Unknown error occurred';
        }
    }

      uploadFile(imagesList) {

    }

      handleFileChange(event) {
        console.log('handle file change::');
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name;
            this.selectedFile = file;
            console.log('File Name::: ' + this.fileName);
            const reader = new FileReader();
 
            reader.onload = () => {
                this.fileData = reader.result.split(',')[1];
                console.log('File data :: '+ this.fileData);
            this.handleUpload();
 
            };
 
            reader.onerror = (error) => {
                console.log('Error reading file:', error);
            };
 
            reader.readAsDataURL(file);
 
 
        }
    }
 
    handleUpload() {
       
        console.log('handle upload :::: ');
        if (this.fileData && this.fileName) {
            console.log('File  name ::: ' + this.fileName);
           // console.log('File file data ::: ' + this.fileName);
 
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64Data = reader.result.split(',')[1];
                this.selectedFileData = base64Data;
                console.log('base64data ::: '+ base64Data);
                console.log('upload file ::: '+ this.fileName);
             // this.uploadFile(this.fileName, base64Data);
 
 
            };
            reader.readAsDataURL(this.selectedFile);
        }
        else if(this.fileName == ''){

             LightningAlert.open({
            message: 'Please select a file to upload.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
 
          //  this.showtoast('Warning', 'Please select a file to upload.', 'warning');
 
        }
    }
 
     handleCNAUploadFile() {

        this.isload=true;
 
       // this.isLoading = true;
        console.log('inside upload file::: ');
       
       
        uploadCNAPhoto({
            fileName: this.fileName,
            base64Data: this.selectedFileData,
            recordId : this.recordId
           
        })
            .then(result => {
                console.log('result sucess');

               LightningAlert.open({
            message: 'Image Uploaded Successfully',
            theme: 'success',   // red error dialog
            label: 'success'    // header text
        }).then(() => {
        
      this.isload=false;
       this.handleCancel();
         });
         
             //  this.showtoast('Success', 'Image Uploaded Successfully.', 'Success');

            //     this.isload=false;
            //    this.handleCancel();

                   // this.showSubmit = true;
 
            })
            .catch(error =>{
 
                this.isload=false;
              console.log('Error', error);
            })
     }

//      handleCustomerYesSubmit(){

//          this.isload=true;

//          console.log('inside handle customer yes submit');

//     const shouldUpdateMeterStatus = this.isMeterAvailable === 'Yes' && this.isUsingGas === 'Yes';
//     const shouldUploadUnavailablePhotos = this.isMeterAvailable === 'No';
//     const shouldUploadGasNotUsedPhotos = this.isMeterAvailable === 'Yes' && this.isUsingGas === 'No';

//     console.log('shouldUpdateMeterStatus::', shouldUpdateMeterStatus);
//     console.log('shouldUploadUnavailablePhotos::', shouldUploadUnavailablePhotos);
//     console.log('shouldUploadGasNotUsedPhotos::', shouldUploadGasNotUsedPhotos);


//     let updateMeterPromise = Promise.resolve();

//     if (shouldUpdateMeterStatus) {
//         console.log('inside shouldUpdateMeterStatus true::');
//         updateMeterPromise = updateMeterStatus({
//             recordId: this.recordId,
//             status: this.meterStatus,
//             //reading: this.meterReading,
//             beforeReading: this.beforeMeterReading,
//             afterReading: this.afterMeterReading,
//             reason: this.reason,
//             meterNumber: this.meterNumber,
//             isMeterAvailable: this.isMeterAvailable,
//             isUsingGas: this.isUsingGas,
//             gasLeakageCheckValue: this.gasLeakageCheckValue
//         }).then(() => {
//             this.meterInfoSubmitted = true;
//              this.isload=false;

//         });
//     }

//     if (shouldUploadGasNotUsedPhotos) {
//         updateMeterPromise = updateGasStatus({
//             recordId: this.recordId,
//             meterNumber: this.meterNumber,
//             reading: this.meterReading,
//             reasonGasNotUsed: this.reasonGasNotUsed
//         }).then(() => {
//             this.meterInfoSubmitted = true;
//              this.isload=false;

//         });
//     }

//     updateMeterPromise
//         .then(() => {
//             console.log('✅ uploadPhotosToWorkOrder done');
//             if (shouldUpdateMeterStatus) {
//                 return uploadPhotosToWorkOrder({
//                     recordId: this.recordId,
//                     listFiles: this.photoUploadSlots
//                 });
//             }  
//             return Promise.resolve();
//         })
//         .then(() => {
//             if (shouldUploadUnavailablePhotos) {
//                 console.log('✅ uploadPhotosToWorkOrderMeter done');
//                 return uploadPhotosToWorkOrderMeter({
//                     recordId: this.recordId,
//                     listFiles: this.meterUnavailablePhotos
//                 });
//             }
//             return Promise.resolve();
//         })
//         .then(() => {
//             if (shouldUploadGasNotUsedPhotos) {
//                 console.log('✅ updateGasStatus done');
//                 return uploadPhotosToGas({
//                     recordId: this.recordId,
//                     listFiles: this.gasNotUsedPhotos
//                 });
//             }
//             return Promise.resolve();
//         })
//         .then(() => {
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Success',
//                 message: 'All applicable data saved successfully.',
//                 variant: 'success'
//             }));

//             // setTimeout(() => {
//             //     this[NavigationMixin.Navigate]({
//             //         type: 'standard__recordPage',
//             //         attributes: {
//             //             recordId: this.recordId,
//             //             objectApiName: 'WorkOrder',
//             //             actionName: 'view'
//             //         }
//             //     });
//             // }, 300);

//             this.handleCancel();
            
//             // this.disableCheckOut = false;
//             // this.imagesSubmitted = true;
//             // this.closeCard = false;
//         })
//         .catch(error => {
//             console.error('Upload failed:', JSON.stringify(error, null, 2));
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Error',
//                 message: error?.body?.message || error?.message || 'Upload failed.',
//                 variant: 'error'
//             }));
//         })
//         .finally(() => {
//              this.isload=false;
//             });

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