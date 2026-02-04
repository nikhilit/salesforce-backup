import { LightningElement, api, track, wire } from 'lwc';
import saveDisconnectionDetails from '@salesforce/apex/IPDisconnectionController.saveDisconnectionDetails';
//import saveIPDisconnectionDetails from '@salesforce/apex/IPDisconnectionController.saveIPDisconnectionDetails';
import saveMaterialDetails from '@salesforce/apex/IPDisconnectionController.saveMaterialDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getBPMeterNumber from '@salesforce/apex/IPDisconnectionController.getBPMeterNumber';

import LightningAlert from 'lightning/alert';


export default class DisconnectionForm extends NavigationMixin(LightningElement) {

    @api recordId;
    
    @track showMaterialScreen = false;
   
@track imageUploadRemark = true;
    @track showRemarksField = false;
@track showNextButton = false;

@track bpMeterNumber='';

@track photoUploadSlots = [];
    noOfPhotos = 4;

    @track load = false;
      @track fileName = '';
      
 
 
    selectedFile;


          @track meterMake='';

          handleMeterMakeChange(event){

this.meterMake=event.target.value;
}


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
   

@track finalRemarks = '';

@track finalRemarksOptions = [
    { label: 'Customer query resolved', value: 'Customer query resolved' },
    { label: 'Meter number found mismatch', value: 'Meter number found mismatch' },
    { label: 'Meter not available with customer', value: 'Meter not available with customer' },
    { label: 'Customer having billing-related query', value: 'Customer having billing-related query' },
    { label: 'New customer interested for name transfer', value: 'New customer interested for name transfer' },
    { label: 'Complaint attended – customer cancelled request', value: 'Complaint attended customer cancelled request' }
];
//Complaint attended – customer cancelled request
@track gasLeakageStatus = ''; // selected value

@track gasLeakageOptions = [
    { label: 'Yes', value: 'Yes' },
    { label: 'No', value: 'No' }
];
handleGasLeakageChange(event) {
    this.gasLeakageStatus = event.detail.value;
    console.log('Gas Leakage Status selected: ', this.gasLeakageStatus);
}


// @track meterMakeOptions = [
//     { label: 'AEM SA', value: 'AEM SA' },
//     { label: 'Elster', value: 'Elster' },
//     { label: 'Itron', value: 'Itron' },
//     { label: 'Raychem RPG', value: 'Raychem RPG' },
//     { label: 'Sensus', value: 'Sensus' },
//     { label: 'Hangzhou Beta', value: 'Hangzhou Beta' },
//     { label: 'Greenglobe', value: 'Greenglobe' },
//     { label: 'Genus Power', value: 'Genus Power' },
//     { label: 'Capital Innotech', value: 'Capital Innotech' },
//     { label: 'Pietro Fiorentini', value: 'Pietro Fiorentini' },
//     { label: 'Smartmeters Technologies', value: 'Smartmeters Technologies' }
// ];


/*@track finalRemarksOptions = [
    { label: 'House lock', value: 'House lock' },
    { label: 'Other', value: 'Other' },
    { label: 'Customer will call later', value: 'Customer will call later' },
    { label: 'CUSTOMER NOT ALLOWED', value: 'CUSTOMER NOT ALLOWED' },
    { label: 'FALSE COMPLAINT', value: 'FALSE COMPLAINT' },
    { label: 'Complaint closed after 15 days', value: 'Complaint closed after 15 days' },
    { label: 'Complaint attended customer cancelled request', value: 'Complaint attended customer cancelled request' },
    { label: 'Customer call not responding', value: 'Customer call not responding' },
    { label: 'Customer call not reachable', value: 'Customer call not reachable' },
    { label: 'New customer interested for name transfer', value: 'New customer interested for name transfer' },
    { label: 'Customer query resolved', value: 'Customer query resolved' },
    { label: 'Customer having billing related query', value: 'Customer having billing related query' },
    { label: 'Meter number found mismatch', value: 'Meter number found mismatch' },
    { label: 'Meter not available with customer', value: 'Meter not available with customer' },
    { label: 'Address not found', value: 'Address not found' }
]; */


    @track selectedDocumentType = '';

    @track meterMake = '';

    file;
    fileName = '';
    meterNumber = '';
    @track finalReading = '';
    
    @track isLoading = true;
    @track remarksText = '';
    

    @track plugFromValue = [];
    @track plugFromOptions = [
    { label: 'TEE', value: 'TEE' },
    { label: 'LIV', value: 'LIV' },
    { label: 'RIV', value: 'RIV' },
    { label: 'MCV', value: 'MCV' }
];


@track materialItems = [
    { name: 'meterBracket', label: 'Meter Bracket', value: '' },
    { name: 'meterRegulator', label: 'Meter Regulator', value: '' },
    { name: 'meterControlValve', label: 'Meter Control Valve', value: '' },
    { name: 'applianceValve', label: 'Appliance Valve', value: '' },
    { name: 'copperPipe12mm', label: 'Copper Pipe 12mm(In meter)', value: '' },
    { name: 'brDisconnectionUnion1', label: 'Br. Disconnection Union 1/2" x 12mm', value: '' },
    { name: 'brDisconnectionUnion2', label: 'Br. Disconnection Union 3/4" x 12mm', value: '' },
    { name: 'meterInletAdaptor', label: 'Meter Inlet Adaptor 3/4" x 3/4"', value: '' },
    { name: 'meterOutletAdaptor', label: 'Meter Outlet Adaptor 3/4" x 12mm', value: '' },
    { name: 'giPipe', label: 'GI Pipe', value: '' },
    { name: 'barrelNipple', label: 'Barrel Nipple', value: '' },
    { name: 'mlcPipeLength', label: 'MLC Pipe Length', value: '' },
    { name: 'anaconda', label: 'Anaconda', value: '' },
    { name: 'brFitting', label: 'Br. Fitting 1/2" x 1/2"', value: '' },
    { name: 'preSleevedGi', label: 'PRE-SLEEVED GI HOLE PIECE', value: '' }

];



    connectedCallback() {
 

    if (!this.recordId) return;

    this.isLoading = true;
    
    this.imageUploadPage = true;
        this.setPhotoUploadSlots();

        this.getBPMeterNumber();
    
}

getBPMeterNumber(){

    getBPMeterNumber({recordId : this.recordId})

    .then(result => {

        console.log('result:::', result);

        this.bpMeterNumber = result;

    })

    .catch(error => {

        console.log('Error ::', error);
    })
}


    handleInputChange(event) {

       
    const field = event.target.name;
    const value = event.target.value;
    this[field] = value;

    console.log('field change name::', field);
    console.log('value ::', value);

    this.showNextButton = true;

    if (field === 'finalRemarks') {
        //this.imageUploadRemark = (value === 'House lock');
        this.showRemarksField = (value === 'Other');
       
    }

    // if(field =='finalReading' && value > 99999){

    //     console.log('inside meter number greater then 5 digits');

    //  this.showToast('Warning', 'Meter Reading Can Not Be Greater Than 5 Digits', 'warning');

    // }

}

 handleFinalReadingChange(event) {

         const value = event.target.value;
    console.log('event detail value::', value);

    // Regex: up to 5 digits before decimal, optional decimal with up to 3 digits
        const regex = /^\d{1,5}(\.\d{0,3})?$/;

    if (regex.test(value)) {
        this.finalReading = value;
    } else {
        this.finalReading = '';
         LightningAlert.open({
            message: 'Please enter valid Final Reading (max 5 digits before decimal and 3 after).',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
       // this.showToast('Warning', 'Please enter valid Final Reading (max 5 digits before decimal and 3 after).', 'warning');
    }

 }


handlePlugFromChange(event) {
    this.plugFromValue = event.detail.value;
    console.log('Plug From Value (Array):', JSON.parse(JSON.stringify(this.plugFromValue)));

}

goToNextPage() {

    if(this.meterNumber ==''){

             LightningAlert.open({
            message: 'Please enter meter number',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
            // this.showToast('Warning', 'Please enter meter  number.', 'warning');
                return;

            }
            if(this.finalReading ==''){

                LightningAlert.open({
            message: 'Please enter final reading',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
          //   this.showToast('Warning', 'Please enter final reading.', 'warning');
                return;

            }

    //   const allFilesSelected = this.photoUploadSlots.length === 4 &&
    //             this.photoUploadSlots.every(slot => slot.fileName && slot.fileName.trim() !== '');
            
        const allFilesSelected =
             this.photoUploadSlots
        .filter(slot => slot.label !== 'PNG service note')
        .every(slot => slot.fileName && slot.fileName.trim() !== '');

            if (!allFilesSelected) {
                LightningAlert.open({
            message: 'Please capture all required photos',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
             //   this.showToast('Warning', 'Please capture all required photos.', 'warning');
                return;
            }
            
    this.showMaterialScreen = true;
    console.log('INSIDE NEXT PAGE::: ',);
}

handleBack() {
    this.showMaterialScreen = false;
}


handleMaterialChange(event) {
    const name = event.target.dataset.name;
    const value = event.target.value;

    this.materialItems = this.materialItems.map(item => {
        return item.name === name ? { ...item, value } : item;
    });
}






    setPhotoUploadSlots() {
        console.log('Inside method:', this.noOfPhotos);  
        const customLabels = [
            'Old installation photo',
            'Meter counter photo',  
            'Outside LIV/RIV plug photo',
            'PNG service note'
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

    

//     handleFile(event) {
//     this.photoUploadSlots = event.detail.steps.map(slot => ({
//     ...slot,
//     latitude: slot.latitude || null,
//     longitude: slot.longitude || null,
//     capturedTime: new Date().toISOString() 
// }));

// }

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




async handleSubmit() {

    this.load=true;

    //   const allFilesSelected = this.photoUploadSlots.length === 4 &&
    //             this.photoUploadSlots.every(slot => slot.fileName && slot.fileName.trim() !== '');
                const allFilesSelected =
             this.photoUploadSlots
        .filter(slot => slot.label !== 'PNG service note')
        .every(slot => slot.fileName && slot.fileName.trim() !== '');
            if (!allFilesSelected) {

                LightningAlert.open({
            message: 'Please capture all required photos',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
            //    this.showToast('Warning', 'Please capture all required photos.', 'warning');
                this.load=false;
                return;
            }


    this.showMaterialScreen = true;
    console.log('INSIDE NEXT PAGE::: ',);
    const materialData = {};
    this.materialItems.forEach(item => {
        materialData[item.name] = item.value;
    });
    materialData.workOrderId = this.recordId;

    saveMaterialDetails({ materialMap: materialData })
        .then(() => {



          //  const reading = parseFloat(this.finalReading);
            // if (isNaN(reading) || this.finalReading === '' || this.finalReading === null) {
            //     this.showToast('Validation Error', 'Please enter a valid Final Reading (numbers only).', 'error');
            //     this.load=false;
            //     return;
            // }

            // 3. Validate Meter Number
            // const meterNum = parseFloat(this.meterNumber);
            // if (isNaN(meterNum) || this.meterNumber === '' || this.meterNumber === null) {
            //     this.showToast('Validation Error', 'Please enter a valid numeric Meter Number.', 'error');
            //     this.load=false;
            //     return;
            // }

            const plugValue = Array.isArray(this.plugFromValue) ? this.plugFromValue.join(';') : '';

              var imagesList = [];
                this.photoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                var temp = this.uploadFile(imagesList);

            return saveDisconnectionDetails({
                workOrderId: this.recordId,
                meterNumber: this.meterNumber,
                finalReading: this.finalReading,
                plugFromValue: plugValue,
                finalRemarks: this.finalRemarks,
                remarksText: this.remarksText || '',
                meterMake: this.meterMake,
                gasLeakageStatus: this.gasLeakageStatus,
                listFiles: imagesList 

            });
        })
        .then(() => {
            console.log('✅ saveDisconnectionDetails success');

        //     LightningAlert.open({
        //     message: 'Details Saved Successfully',
        //     theme: 'success',   // red error dialog
        //     label: 'Success'    // header text
        // });

        //     //  this.showToast('Success', 'Details Saved Successfully.', 'success');

        //         //commenting for alret 
        //        this.dispatchEvent(new CustomEvent('cancel'));
        LightningAlert.open({
    message: 'Details Saved Successfully',
    theme: 'success',
    label: 'Success'
}).then(() => {
    // This runs ONLY after user clicks OK
    this.dispatchEvent(new CustomEvent('cancel'));
    this.load = false;
});

            // this.load = false;

           

            
        })
        
        .catch(error => {
            console.error('❌ Error during submission:', error);
          
            this.load = false;
        })
       

    
}



    showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
    }));
}
handleMeterMakeChange(event) {
    this.meterMake = event.detail.value;
}

}