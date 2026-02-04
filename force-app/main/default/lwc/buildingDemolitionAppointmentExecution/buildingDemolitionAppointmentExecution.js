import { LightningElement, api, track, wire} from 'lwc';
import updateWorkOrder from '@salesforce/apex/BuildingDemolitionExecutionController.updateWorkOrder';
//import savePhotoUploads from '@salesforce/apex/BuildingDemolitionExecutionController.savePhotoUploads';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getItemDescriptionOptions from '@salesforce/apex/RiserReplacementController.getItemDescriptionOptions';
import validateMeterApex from '@salesforce/apex/BuildingDemolitionExecutionController.validateMeterApex';
import saveMaterialDetails from '@salesforce/apex/BuildingDemolitionExecutionController.saveMaterialDetails';
import MP_ENDCAP from '@salesforce/schema/ServiceAppointment.MP_endcap__c';
import GI_REROUTING from '@salesforce/schema/ServiceAppointment.GI_rerouting__c';
import MP_REROUTING from '@salesforce/schema/ServiceAppointment.MP_rerouting__c';
import LP_REROUTING from '@salesforce/schema/ServiceAppointment.LP_rerouting__c';
import LP_ENDCAP from '@salesforce/schema/ServiceAppointment.LP_endcap__c';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { updateRecord, createRecord } from 'lightning/uiRecordApi';
import LOOP_STATUS from '@salesforce/schema/WorkOrder.Loop_Verification_Status__c';


export default class ContractorWorkExecution extends NavigationMixin(LightningElement) {

    @api recordId;
    @track workOrder = {};
   // @track photoUploadSlots = [];
    @track latitude;
    @track longitude;
  //  noOfPhotos = 10;
  //  imageUploadPage = true;
   // @track typeOfWork;
   // @track loopVerificationStatus;
    @track loopStatus = '';
    @track remarks;
    //@track meterNumber;
    @track meterReading;
    @track meterReadingDate;
    @track trenchVolume;
    @track pipelineLength;
   
    @track itemDescriptionOptions = [];
    @track enteredMeterNumber = '';

@track validatedMeter = false;
@track meterAttemptCount = 0;
@track showConfirmationPrompt = false;


  @track showPreviewModal = false;
@track previewUrl = '';
@track previewFileName = '';

    noOfPhotosMeterImageCapture = 3;
    noOfPhotosBuildingImage = 3;
    noOfPhotosEscnCopy = 3;
    noOfPhotosSiteCompletion = 3;
    noOfPhotosAutoCad = 3;

    @track photoUploadSlotsMeterImageCapture = [];
    @track photoUploadSlotsBuildingImage = [];
    @track photoUploadSlotsEscnCopy = [];
    @track photoUploadSlotsSiteCompletion = [];
    @track photoUploadSlotsAutoCad = [];

     get loopStatusOptions() {
    return [
        { label: 'Okay', value: 'Okay' },
        { label: 'Not Okay', value: 'Not Okay' }
    ];
}


     @track mpEndcap = false;
    @track giRerouting = false;
@track mpRerouting = false;
@track lpRerouting = false;
@track lpEndcap = false;

    @track serviceAppointmentId ;



    @track lineTypesSelected = [];
@track showMP = false;
@track showLP = false;

@track mpLineLength = 0;
@track lpLineLength = 0;
@track lineTypeLength = 0;
@track lineType = [];

lineTypeOptions = [
    { label: 'MP', value: 'MP' },
    { label: 'LP', value: 'LP' }
];

@track selectedLineTypesMap = {};
@track totalLineLength = 0;

    @track materialList = [{
        itemCode: '',
        itemDescription: '',
        unit: '',
        quantity: ''
    }];

    // workTypeOptions = [
    //     { label: 'MP ENDCAP', value: 'MP ENDCAP' },
    //     { label: 'LP ENDCAP', value: 'LP ENDCAP' },
    //     { label: 'LP REROUTING', value: 'LP REROUTING' },
    //     { label: 'MP REROUTING', value: 'MP REROUTING' },
    //     { label: 'GI REROUTING', value: 'GI REROUTING' }
    // ];

    connectedCallback() {
        console.log('connectedCallback invoked. RecordId:', this.recordId);
        
        const today = new Date();
    this.meterReadingDate = today.toISOString().split('T')[0];
      //  this.setPhotoUploadSlots();
       this.initSlots();
        this.showMaterialSection = true;

        // Fetch Item Description Options
        getItemDescriptionOptions()
            .then(result => {
                this.itemDescriptionOptions = result.map(value => ({ label: value, value }));
                console.log('Fetched item description options:', this.itemDescriptionOptions);
            })
            .catch(error => {
                console.error('Error fetching item description options:', error);
            });

        if (navigator.geolocation) {
            console.log('🌍 Getting Geolocation...');
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.latitude = position.coords.latitude;
                    this.longitude = position.coords.longitude;
                    console.log('📍 Location captured:', this.latitude, this.longitude);
                },
                (error) => {
                    console.error('❌ Geolocation error:', error);
                }
            );
        } else {
            console.warn('⚠ Geolocation not supported.');
        }
    }

     initSlots() {
        this.photoUploadSlotsMeterImageCapture = this.createSlots(this.noOfPhotosMeterImageCapture, 'Meter Image Capture');
        this.photoUploadSlotsBuildingImage = this.createSlots(this.noOfPhotosBuildingImage, 'Building Image');
        this.photoUploadSlotsEscnCopy = this.createSlots(this.noOfPhotosEscnCopy, 'Escn Copy');
        this.photoUploadSlotsSiteCompletion = this.createSlots(this.noOfPhotosSiteCompletion, 'Site Completion');
        this.photoUploadSlotsAutoCad = this.createSlots(this.noOfPhotosAutoCad, 'Auto Cad');
    }

      @wire(getRelatedListRecords, {
    parentRecordId: '$recordId',           // WorkOrder ID
    relatedListId: 'ServiceAppointments',  // Related list API name
    fields: ['ServiceAppointment.Id', 'ServiceAppointment.Status']
})
wiredSA({ data, error }) {
    if (data) {
        console.log('SA Related List → ', JSON.stringify(data.records));

        if (data.records.length > 0) {
            this.serviceAppointmentId = data.records[0].id;
            console.log('ServiceAppointmentId found:', this.serviceAppointmentId);
        } else {
            console.warn('⚠ No ServiceAppointments found for this Work Order');
        }

    } else if (error) {
        console.error('Error loading SA:', error);
    }
}



   async updateServiceAppointmentFields() {
    if (!this.serviceAppointmentId) return;

    const fields = {
        Id: this.serviceAppointmentId,    // ← CORRECT ONE
        [MP_ENDCAP.fieldApiName]: this.mpEndcap,
        [GI_REROUTING.fieldApiName]: this.giRerouting,
        [MP_REROUTING.fieldApiName]: this.mpRerouting,
        [LP_REROUTING.fieldApiName]: this.lpRerouting,
        [LP_ENDCAP.fieldApiName]: this.lpEndcap
    };

    return updateRecord({ fields });
}

handleMpEndcapChange(event) {
    this.mpEndcap = event.target.checked;
}

handleGiReroutingChange(e) { this.giRerouting = e.target.checked; }
handleMpReroutingChange(e) { this.mpRerouting = e.target.checked; }
handleLpReroutingChange(e) { this.lpRerouting = e.target.checked; }
handleLpEndcapChange(e) { this.lpEndcap = e.target.checked; }



      createSlots(count, label) {
        return Array.from({ length: count }, (_, i) => ({
            id: i + 1,
            index: i + 1,
            label,
            fileName: '',
            uploaded: false,
            base64Data: null,
            previewUrl: ''
        }));
    }

    async handleFileMeterImageCapture(e) { this.photoUploadSlotsMeterImageCapture = await this.processImageUpload(e.detail.steps); }
    async handleFileBuildingImage(e) { this.photoUploadSlotsBuildingImage = await this.processImageUpload(e.detail.steps); }
    async handleFileEscnCopy(e) { this.photoUploadSlotsEscnCopy = await this.processImageUpload(e.detail.steps); }
    async handleFileSiteCompletion(e) { this.photoUploadSlotsSiteCompletion = await this.processImageUpload(e.detail.steps); }
    async handleFileAutoCad(e) { this.photoUploadSlotsAutoCad = await this.processImageUpload(e.detail.steps); }

    async processImageUpload(newSlots) {
        for (let slot of newSlots) {
            if (!slot.base64Data) continue;

            const detectedMime = slot.base64Data.startsWith('data:')
                ? slot.base64Data.split(';')[0].replace('data:', '')
                : 'image/jpeg';

            const wrapper = slot.base64Data.startsWith('data:')
                ? slot.base64Data
                : `data:${detectedMime};base64,${slot.base64Data}`;

            slot.base64Data = wrapper;
            slot.uploaded = true;
        }
        return [...newSlots];
    }

    // loopStatusOptions = [
    //     { label: 'Okay', value: 'Okay' },
    //     { label: 'Not okay', value: 'Not okay' }
    // ];

     handleLoopStatusChange(event) {
    this.loopStatus = event.detail.value;
   }

    handleMeterInput(event) {
    this.enteredMeterNumber = event.target.value;
}

  async uploadAllPhotos() {
        const allSlots = [
            ...this.photoUploadSlotsMeterImageCapture,
            ...this.photoUploadSlotsBuildingImage,
            ...this.photoUploadSlotsEscnCopy,
            ...this.photoUploadSlotsSiteCompletion,
            ...this.photoUploadSlotsAutoCad
        ];

        const uploads = allSlots
            .filter(s => s.uploaded && s.base64Data)
            .map(s => this.uploadFileToRecord(s));

        await Promise.all(uploads);
        return true;
    }

    async uploadFileToRecord(slot) {
        let mime = 'image/jpeg';
        if (slot.base64Data.startsWith('data:')) {
            mime = slot.base64Data.substring(5, slot.base64Data.indexOf(';'));
        }

        const extension = mime === 'application/pdf' ? 'pdf' : 'jpg';
        const fileName = `${slot.label.replace(/\s/g, '')}_${Date.now()}.${extension}`;

        const base64Body = slot.base64Data.includes(',')
            ? slot.base64Data.split(',')[1]
            : slot.base64Data;

        const contentVersionRecord = {
            apiName: 'ContentVersion',
            fields: {
                Title: fileName,
                PathOnClient: fileName,
                VersionData: base64Body,
                FirstPublishLocationId: this.recordId
            }
        };

        return createRecord(contentVersionRecord);
    }

    async compressImage(base64String, maxWidth = 1024, quality = 0.6) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.onload = () => {
            // Calculate new dimensions
            const scale = maxWidth / img.width;
            const newWidth = img.width > maxWidth ? maxWidth : img.width;
            const newHeight = img.width > maxWidth ? img.height * scale : img.height;

            const canvas = document.createElement('canvas');
            canvas.width = newWidth;
            canvas.height = newHeight;

            const ctx = canvas.getContext('2d');
            ctx.drawImage(img, 0, 0, newWidth, newHeight);

            // Convert to compressed Base64
            const compressedBase64 = canvas.toDataURL('image/jpeg', quality);
            resolve(compressedBase64);
        };
        img.onerror = (e) => reject(e);
        img.src = base64String;
    });
}

async readFileAsBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();

        reader.onload = async () => {
            let base64 = reader.result;

            // If PDF, return as-is
            if (file.type === 'application/pdf') {
                return resolve(base64);
            }

            // ---- COMPRESS IMAGES HERE ----
            try {
                const compressed = await this.compressImage(base64, 1024, 0.6);
                resolve(compressed);
            } catch (err) {
                console.error('Compression failed, using original:', err);
                resolve(base64); // fallback
            }
        };

        reader.onerror = () => reject(reader.error);
        reader.readAsDataURL(file);
    });
}

    


    async processSelectedFiles(files, label) {
    if (!files || files.length === 0) {
        return;
    }

    let targetSlots;

    switch (label) {
        case 'Meter Image Capture':
            targetSlots = this.photoUploadSlotsMeterImageCapture;
            break;
        case 'Building Image':
            targetSlots = this.photoUploadSlotsBuildingImage;
            break;
        case 'Escn Copy':
            targetSlots = this.photoUploadSlotsEscnCopy;
            break;
        case 'Site Completion':
            targetSlots = this.photoUploadSlotsSiteCompletion;
            break;
        case 'Auto Cad':
            targetSlots = this.photoUploadSlotsAutoCad;
            break;
        default:
            return;
    }

 let emptySlots = targetSlots.filter(s => !s.uploaded);

    for (let file of files) {
        if (emptySlots.length === 0) break; // No slot remains

        let slot = emptySlots.shift(); // take first empty slot

        const base64 = await this.readFileAsBase64(file);

        slot.fileName = file.name;
        slot.base64Data = base64;
        slot.uploaded = true;
        slot.previewUrl = base64;
    }

    // Reassign tracked values so UI refreshes
    if (label === 'Meter Image Capture') this.photoUploadSlotsMeterImageCapture = [...targetSlots];
    if (label === 'Building Image') this.photoUploadSlotsBuildingImage = [...targetSlots];
    if (label === 'Escn Copy') this.photoUploadSlotsEscnCopy = [...targetSlots];
    if (label === 'Site Completion') this.photoUploadSlotsSiteCompletion = [...targetSlots];
    if (label === 'Auto Cad') this.photoUploadSlotsAutoCad = [...targetSlots];
}


handleFilesInputChange(event) {
    const files = event.target.files;
    const label = event.target.dataset.label;

    this.processSelectedFiles(files, label);
}

triggerFileUpload(event) {
    const inputName = event.currentTarget.dataset.input;
    const fileInput = this.template.querySelector(`input[data-input="${inputName}"]`);

    if (fileInput) {
        fileInput.click();
    }
}

  get isPdfPreview() {
    return this.previewUrl?.startsWith('data:application/pdf');
   }

    get isImagePreview() {
    return !this.isPdfPreview;
   }

   handlePreview(event) {
    this.previewUrl = event.currentTarget.dataset.url;
    this.previewFileName = event.currentTarget.dataset.name;
    this.showPreviewModal = true;
}

closePreview() {
    this.showPreviewModal = false;
    this.previewUrl = '';
    this.previewFileName = '';
}


validateMeterNumber() {
    validateMeterApex({ workOrderId: this.recordId, meterNumber: this.enteredMeterNumber })
        .then(result => {
            if (result.isValid) {
                this.validatedMeter = true;
                this.meterAttemptCount = 0;
                this.showConfirmationPrompt = false;
                this.showToast('Success', 'Meter number validated successfully.', 'success');
            } else {
                this.meterAttemptCount += 1;

                if (this.meterAttemptCount === 1) {
                    this.showToast('Incorrect Meter Number', result.message, 'error');
                    this.enteredMeterNumber = '';
                } else if (this.meterAttemptCount === 2) {
                    this.showConfirmationPrompt = true;
                }
            }
        })
        .catch(error => {
            console.error(error);
            this.showToast('Error', error?.body?.message || 'Validation failed.', 'error');
        });
}



handleProceedWithEnteredMeterNumber(event) {
    const choice = event.target.dataset.choice;

    if (choice === 'yes') {
        this.validatedMeter = true;
        this.showConfirmationPrompt = false;
    } else {
        this.enteredMeterNumber = '';
        this.showConfirmationPrompt = false;
        this.meterAttemptCount = 0;
    }
}


getLineLength(lineType) {
    return this.selectedLineTypesMap[lineType] || 0;
}



// Called on checkbox change
handleLineTypeCheckboxChange(event) {
    const lineType = event.target.dataset.id;
    const isChecked = event.target.checked;

    this.lineTypeOptions = this.lineTypeOptions.map(line => {
        if (line.value === lineType) {
            return {
                ...line,
                showLengthInput: isChecked,
                length: isChecked ? 0 : undefined
            };
        }
        return line;
    });

    if (isChecked) {
        this.selectedLineTypesMap[lineType] = 0;
    } else {
        delete this.selectedLineTypesMap[lineType];
    }

    this.calculateTotalLength();
}


    // Handle length input change
  handleLengthChange(event) {
    const lineType = event.target.dataset.id;
    const length = parseFloat(event.target.value) || 0;
    this.selectedLineTypesMap[lineType] = length;

    this.lineTypeOptions = this.lineTypeOptions.map(line => {
        if (line.value === lineType) {
            return {
                ...line,
                length: length
            };
        }
        return line;
    });

    this.calculateTotalLength();
}


calculateTotalLength() {
    this.totalLineLength = Object.values(this.selectedLineTypesMap)
        .reduce((sum, val) => sum + (parseFloat(val) || 0), 0);
}




    handleChange(event) {
    const field = event.target.name;
    const value = event.detail?.value || event.target.value;

    this[field] = value;

    console.log(`🔧 Field Updated - ${field}:`, value);
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
            itemCode: '',
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


    // handleFile(event) {
    //     this.photoUploadSlots = event.detail.steps;
    //     console.log('📥 handleFile received photoUploadSlots:', JSON.stringify(this.photoUploadSlots));
    // }

    // setPhotoUploadSlots() {
    //     console.log('📸 setPhotoUploadSlots called');
    //     const customLabels = ['Meter Image', 'Current Image Of Building', 'Demolition Building', 'Issued Letters 1', 'Issued Letters 2', 'Issued Letters 3', 'ESCN Copy', 'Site Completion Photo With FRP Plate', 'AutoCAD Drawing', 'Completion Letter'];

    //     this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => {
    //         const slotNum = index + 1;
    //         return {
    //             id: slotNum,
    //             index: slotNum,
    //             label: customLabels[index] || `Photo ${slotNum}`,
    //             name: `fileUploader${slotNum}`,
    //             fileName: '',
    //             uploaded: false,
    //             previewUrl: '',
    //             latitude: this.latitude,
    //             longitude: this.longitude
    //         };
    //     });

    //     console.log('✅ Initialized photoUploadSlots:', JSON.stringify(this.photoUploadSlots));
    // }

    testData = [{
        itemDescription: 'test material',
        unit: '12',
        quantity: '80'
    }];


    submitWorkOrder() {

        if (!this.validatedMeter) {
        this.showToast('Validation Required', 'Please validate the meter number before submission.', 'warning');
        return;
    }
    this.uploadAllPhotos()
    this.updateServiceAppointmentFields()
    this.loopStatus ()
    console.log('🚀 Submitting work order...');

    console.log('📋 Data being submitted:', JSON.parse(JSON.stringify({
    recordId: this.recordId,
   // typeOfWork: this.typeOfWork,
   // loopVerificationStatus: this.loopVerificationStatus,
   [LOOP_STATUS.fieldApiName]: this.loopStatus,
    remarks: this.remarks,
    meterReading: this.meterReading,
    meterReadingDate: this.meterReadingDate,
    trenchVolume: this.trenchVolume,
    pipelineLength: this.pipelineLength,
    lineType: this.lineType
})));


    try {
        // 1. Update the Work Order
        updateWorkOrder({
    recordId: this.recordId,
   // typeOfWork: this.typeOfWork,
  //  loopVerificationStatus: this.loopVerificationStatus,
    remarks: this.remarks,
    [LOOP_STATUS.fieldApiName]: this.loopStatus,
    meterReading: parseFloat(this.meterReading),
    meterReadingDate: this.meterReadingDate,
    trenchVolume: parseFloat(this.trenchVolume),
    lineType: this.lineType,
    lineTypeLength: this.lineTypeLength

})
        console.log('✅ Work Order updated successfully');

        // 2. Save Material Details if section is visible and data exists
        if (this.showMaterialSection && this.materialList.length > 0) {
            console.log('📦 Saving material details...');
             saveMaterialDetails({
                workOrderId: this.recordId,
                materialList: this.materialList
            });
            console.log('✔ Material details saved.');
        }
            console.log('OUTPUT : photoupload is ::::', JSON.stringify(this.photoUploadSlots));
        // 3. Upload Photos
        //     savePhotoUploads({
        //     recordId: this.recordId,
        //     listFiles: this.photoUploadSlots
        // });

        // 4. Show Success Toast
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Work Order, materials, and photos updated successfully.',
            variant: 'success'
        }));

        // 5. Navigate to the record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'WorkOrder',
                actionName: 'view'
            }
        });

    } catch (error) {
        console.error('❌ submitWorkOrder error:', JSON.stringify(error));
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: error?.body?.message || JSON.stringify(error),
            variant: 'error'
        }));
    }
}

showToast(title, message, variant) {
    this.dispatchEvent(
        new ShowToastEvent({
            title,
            message,
            variant
        })
    );
}


}