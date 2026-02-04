import { LightningElement, api, track, wire } from 'lwc';
import { updateRecord, createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import METER_NUMBER from '@salesforce/schema/WorkOrder.Meter_Number__c';
import METER_READING from '@salesforce/schema/WorkOrder.Meter_Reading__c';
import VOLUME from '@salesforce/schema/WorkOrder.Volume_of_Trench__c';
import MATERIAL from '@salesforce/schema/WorkOrder.Material_Utilised__c';
import LENGTH from '@salesforce/schema/WorkOrder.Length_of_Pipeline__c';
import LOOP_STATUS from '@salesforce/schema/WorkOrder.Loop_Verification_Status__c';
import TYPE_OF_LINE from '@salesforce/schema/WorkOrder.Type_Of_Line_Laid__c';
import MP_ENDCAP from '@salesforce/schema/ServiceAppointment.MP_endcap__c';
import GI_REROUTING from '@salesforce/schema/ServiceAppointment.GI_rerouting__c';
import MP_REROUTING from '@salesforce/schema/ServiceAppointment.MP_rerouting__c';
import LP_REROUTING from '@salesforce/schema/ServiceAppointment.LP_rerouting__c';
import LP_ENDCAP from '@salesforce/schema/ServiceAppointment.LP_endcap__c';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_FIELD from '@salesforce/schema/WorkOrder.AccountId';
import ACCOUNT_METER from '@salesforce/schema/Account.Meter_Number__c';
import METER_READING_DATE from '@salesforce/schema/WorkOrder.Meter_Reading_Date__c';
import DISCREPANCY_FLAG from '@salesforce/schema/WorkOrder.Discrepancy_Flag__c';


//import getItemDescriptionOptions from '@salesforce/apex/RiserReplacementController.getItemDescriptionOptions';
//import saveMaterialDetails from '@salesforce/apex/BuildingDemolitionExecutionController.saveMaterialDetails';

import MATERIAL_OBJECT from '@salesforce/schema/Material_Consumption__c';

import ITEM_CODE_FIELD from '@salesforce/schema/Material_Consumption__c.Item_Code__c';
import ITEM_DESC_FIELD from '@salesforce/schema/Material_Consumption__c.Item_description__c';
import UNIT_FIELD from '@salesforce/schema/Material_Consumption__c.Unit__c';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';











import ID_FIELD from '@salesforce/schema/WorkStep.Id';
import STATUS_FIELD from '@salesforce/schema/WorkStep.Status';

import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class Datacapturebd extends NavigationMixin(LightningElement) {
    @api recordId;
    @track accountId;
    @track accountMeterNumber;
    @track meterReadingDate = '';
    @track typeOfLine = []; // instead of string
@track mpLength = '';
@track lpLength = '';


//materialconsumption
@track itemCodeOptions = [];
@track itemDescriptionOptions = [];
@track unitOptions = [];


    @track workStepId = '';

    @track meterNumber = '';
    @track meterReading = '';
    @track volumeOfTrench = '';
    @track materialUtilised = '';
    @track lengthOfPipeline = '';
    @track loopStatus = '';
   // @track typeOfLine = '';
    @track mpEndcap = false;
    @track giRerouting = false;
@track mpRerouting = false;
@track lpRerouting = false;
@track lpEndcap = false;

    @track serviceAppointmentId ;


    @track showPreviewModal = false;
@track previewUrl = '';
@track previewFileName = '';

    noOfPhotosMeterImageCapture = 3;
    noOfPhotosBuildingImage = 3;
    noOfPhotosEscnCopy = 3;
    noOfPhotosSiteCompletion = 3;
    noOfPhotosAutoCad = 3;
    noOfPhotosLetterIssued = 3;
    noOfPhotosCompletionLetter = 3;
    


    @track photoUploadSlotsMeterImageCapture = [];
    @track photoUploadSlotsBuildingImage = [];
    @track photoUploadSlotsEscnCopy = [];
    @track photoUploadSlotsSiteCompletion = [];
    @track photoUploadSlotsAutoCad = [];
    @track photoUploadSlotsLetterIssued = [];
    @track photoUploadSlotsCompletionLetter = [];


 @track itemDescriptionOptions = [];
    @track materialList = [{
    itemCode: '',
    itemDescription: '',
    unit: '',
    quantity: ''
}];


    get loopStatusOptions() {
    return [
        { label: 'Okay', value: 'Okay' },
        { label: 'Not Okay', value: 'Not Okay' }
    ];
}

get typeOfLineOptions() {
    return [
        { label: 'MP', value: 'MP' },
        { label: 'LP', value: 'LP' }
    ];
}



    connectedCallback() {
        this.initSlots();
    //     getItemDescriptionOptions()
    // .then(result => {
    //     this.itemDescriptionOptions = result.map(v => ({ label: v, value: v }));
    // })
    // .catch(error => console.error(error));

    }

    initSlots() {
        this.photoUploadSlotsMeterImageCapture = this.createSlots(this.noOfPhotosMeterImageCapture, 'Meter Image Capture');
        this.photoUploadSlotsBuildingImage = this.createSlots(this.noOfPhotosBuildingImage, 'Building Image');
        this.photoUploadSlotsEscnCopy = this.createSlots(this.noOfPhotosEscnCopy, 'Escn Copy');
        this.photoUploadSlotsSiteCompletion = this.createSlots(this.noOfPhotosSiteCompletion, 'Site Completion');
        this.photoUploadSlotsAutoCad = this.createSlots(this.noOfPhotosAutoCad, 'Auto Cad');
        this.photoUploadSlotsLetterIssued = this.createSlots(this.noOfPhotosLetterIssued, 'Letter Issued');
        this.photoUploadSlotsCompletionLetter = this.createSlots(this.noOfPhotosCompletionLetter, 'Completion Letter');
        

    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkSteps',
        fields: ['WorkStep.Id', 'WorkStep.Name', 'WorkStep.Status']
    })
    wiredWorkStep({ data, error }) {
        if (data) {
            const step = data.records.find(r => r.fields.Name.value === 'Data Capture Detail');
            if (step) {
                this.workStepId = step.id;
            }
        }
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


//materialconsumption
@wire(getObjectInfo, { objectApiName: MATERIAL_OBJECT })
materialObjectInfo;

@wire(getPicklistValues, {
    recordTypeId: '$materialObjectInfo.data.defaultRecordTypeId',
    fieldApiName: ITEM_CODE_FIELD
})
wiredItemCode({ data }) {
    if (data) {
        this.itemCodeOptions = data.values;
    }
}

@wire(getPicklistValues, {
    recordTypeId: '$materialObjectInfo.data.defaultRecordTypeId',
    fieldApiName: ITEM_DESC_FIELD
})
wiredItemDesc({ data }) {
    if (data) {
        this.itemDescriptionOptions = data.values;
    }
}

@wire(getPicklistValues, {
    recordTypeId: '$materialObjectInfo.data.defaultRecordTypeId',
    fieldApiName: UNIT_FIELD
})
wiredUnit({ data }) {
    if (data) {
        this.unitOptions = data.values;
    }
}


//materialconsumption






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

@wire(getRecord, {
    recordId: '$recordId',
    fields: [ACCOUNT_FIELD]
})
wiredWO({ data, error }) {
    if (data) {
        this.accountId = data.fields.AccountId.value;
    }
}

@wire(getRecord, {
    recordId: '$accountId',
    fields: [ACCOUNT_METER]
})
wiredAccount({ data, error }) {
    if (data) {
        this.accountMeterNumber = data.fields.Meter_Number__c.value;
        console.log('Account Meter Number → ', this.accountMeterNumber);
    }
}

get today() {
    return new Date().toISOString().split('T')[0];
}


handleMeterReadingDateChange(event) {
    this.meterReadingDate = event.detail.value;

    const today = new Date().setHours(0,0,0,0);
    const selected = new Date(this.meterReadingDate).setHours(0,0,0,0);

    if (selected < today) {
        this.showToast('Past date not allowed. Please select today or future date.', 'warning');
        this.meterReadingDate = '';
    }
}

handleTypeOfLineChange(event) {
    this.typeOfLine = event.detail.value;

    // Reset lengths if un-selected later
    if (!this.typeOfLine.includes('MP')) this.mpLength = '';
    if (!this.typeOfLine.includes('LP')) this.lpLength = '';

    this.updateTotalLength();
}

handleMpLengthChange(event) {
    this.mpLength = event.target.value;
    this.updateTotalLength();
}

handleLpLengthChange(event) {
    this.lpLength = event.target.value;
    this.updateTotalLength();
}

updateTotalLength() {
    let sum = 0;

    if (this.mpLength) sum += parseFloat(this.mpLength);
    if (this.lpLength) sum += parseFloat(this.lpLength);

    this.lengthOfPipeline = sum ? sum.toString() : '';
}

get showMpLength() {
    return this.typeOfLine.includes('MP');
}

get showLpLength() {
    return this.typeOfLine.includes('LP');
}


handleMaterialChange(event) {
    const index = event.target.dataset.index;
    const field = event.target.name;
    const value = event.detail.value || event.target.value;

    this.materialList[index][field] = value;
}

addMaterialRow() {
    this.materialList.push({
        itemCode: '',
        itemDescription: '',
        unit: '',
        quantity: ''
    });
}

removeMaterialRow(event) {
    const index = event.target.dataset.index;
    if (this.materialList.length > 1) {
        this.materialList.splice(index, 1);
    }
}




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
    async handleFileLetterIssued(e) { this.photoUploadSlotsLetterIssued = await this.processImageUpload(e.detail.steps); }
    async handleFileCompletionLetter(e) { this.photoUploadSlotsCompletionLetter = await this.processImageUpload(e.detail.steps); }


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

    handleLoopStatusChange(event) {
    this.loopStatus = event.detail.value;
   }

//    handleTypeOfLineChange(event) {
//     this.typeOfLine = event.detail.value;
// }

handleMpEndcapChange(event) {
    this.mpEndcap = event.target.checked;
}

handleGiReroutingChange(e) { this.giRerouting = e.target.checked; }
handleMpReroutingChange(e) { this.mpRerouting = e.target.checked; }
handleLpReroutingChange(e) { this.lpRerouting = e.target.checked; }
handleLpEndcapChange(e) { this.lpEndcap = e.target.checked; }





    handleMeterNumberChange(e) {
        
         this.meterNumber = e.detail.value;    
     }
    handleMeterReadingChange(e) { this.meterReading = e.detail.value; }
    handleVolumeOfTrench(e) { this.volumeOfTrench = e.detail.value; }
    handleLengthOfPipeline(e) { this.lengthOfPipeline = e.detail.value;}
    handleMaterialUtilised(e) { this.materialUtilised = e.detail.value;}

    validateMeterNumber() {
    if (!this.meterNumber) {
        this.showToast('Please enter Meter Number before validating', 'warning');
        return;
    }

    if (!this.accountMeterNumber) {
        this.showToast('Unable to verify Meter Number. Account data not loaded yet.', 'error');
        return;
    }

    if (this.meterNumber === this.accountMeterNumber) {
        this.showToast('Meter Number is correct', 'success');
    } else {
        this.showToast(
            'Meter Number not matching with BP, You can still proceed.',
            'warning'
        );
    }
}

//materialconsumption
async saveMaterialConsumption() {
    const records = this.materialList.map(mat => ({
        apiName: 'Material_Consumption__c',
        fields: {
            Work_Order__c: this.recordId,
            Item_Code__c: mat.itemCode,
            Item_description__c: mat.itemDescription,
            Unit__c: mat.unit,
            Quantity__c: mat.quantity
        }
    }));

    const promises = records.map(r => createRecord(r));
    await Promise.all(promises);
}
//materialconsumption

    handleSubmit() {

         let discrepancyFlagValue = false;

        if (this.accountMeterNumber && this.meterNumber !== this.accountMeterNumber) {
             discrepancyFlagValue = true;
        this.showToast('Meter Number mismatch with Account data!', 'error');
        
    }
        this.updateWorkOrderFields(discrepancyFlagValue)
            .then(() => this.updateServiceAppointmentFields())
            .then(() => this.saveMaterialConsumption()) 
            .then(() => this.uploadAllPhotos())
            .then(() => this.updateWorkStepDataCapture())
            .then(() => {
                this.showToast('Saved successfully', 'success');
               // this.navigateToRecord();
                this.handleCancel();
            })
            .catch(err => this.showToast(this.getError(err), 'error'));

//         saveMaterialDetails({ 
//     workOrderId: this.recordId, 
//     materialList: this.materialList 
// });

    }

    updateWorkOrderFields(discrepancyFlagValue = false) {
        const fields = {
            Id: this.recordId,
            [METER_NUMBER.fieldApiName]: this.meterNumber,
            [METER_READING.fieldApiName]: this.meterReading,
            [VOLUME.fieldApiName]: this.volumeOfTrench,
            [MATERIAL.fieldApiName]: this.materialUtilised,
            [LENGTH.fieldApiName]: this.lengthOfPipeline,
            [LOOP_STATUS.fieldApiName]: this.loopStatus,
            [METER_READING_DATE.fieldApiName]: this.meterReadingDate,
            [TYPE_OF_LINE.fieldApiName]: this.typeOfLine.join(';'),
             [DISCREPANCY_FLAG.fieldApiName]: discrepancyFlagValue 

 
        };
        return updateRecord({ fields });
    }

     handleDelete(event) {
    const label = event.currentTarget.dataset.label;
    const index = event.currentTarget.dataset.index;

    let list;
    switch (label) {
        case 'Meter Image Capture': list = [...this.photoUploadSlotsMeterImageCapture]; break;
        case 'Building Image': list = [...this.photoUploadSlotsBuildingImage]; break;
        case 'Escn Copy': list = [...this.photoUploadSlotsEscnCopy]; break;
        case 'Site Completion': list = [...this.photoUploadSlotsSiteCompletion]; break;
        case 'Auto Cad': list = [...this.photoUploadSlotsAutoCad]; break;
        case 'Letter Issued': list = [...this.photoUploadSlotsLetterIssued]; break;
        case 'Completion Letter': list = [...this.photoUploadSlotsCompletionLetter]; break;
       
    }

    list[index - 1].uploaded = false;
    list[index - 1].fileName = '';
    list[index - 1].previewUrl = '';
    list[index - 1].base64Data = null;

    if (label === 'Meter Image Capture') this.photoUploadSlotsMeterImageCapture = list;
    if (label === 'Building Image') this.photoUploadSlotsBuildingImage = list;
    if (label === 'Escn Copy') this.photoUploadSlotsEscnCopy = list;
    if (label === 'Site Completion') this.photoUploadSlotsSiteCompletion = list;
    if (label === 'Auto Cad') this.photoUploadSlotsAutoCad = list;
    if (label === 'Letter Issued') this.photoUploadSlotsLetterIssued = list;
    if (label === 'Completion Letter') this.photoUploadSlotsCompletionLetter = list;

   

}

    async uploadAllPhotos() {
        const allSlots = [
            ...this.photoUploadSlotsMeterImageCapture,
            ...this.photoUploadSlotsBuildingImage,
            ...this.photoUploadSlotsEscnCopy,
            ...this.photoUploadSlotsSiteCompletion,
            ...this.photoUploadSlotsAutoCad,
            ...this.photoUploadSlotsLetterIssued,
            ...this.photoUploadSlotsCompletionLetter

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
        case 'Letter Issued':
            targetSlots = this.photoUploadSlotsLetterIssued;
            break;  
        case 'Completion Letter':
            targetSlots = this.photoUploadSlotsCompletionLetter;
            break;        
        default:
            return;
    }

    // let slotIndex = 0;

    // for (let file of files) {
    //     if (slotIndex >= targetSlots.length) break;

    //     const base64 = await this.readFileAsBase64(file);

    //     targetSlots[slotIndex].fileName = file.name;
    //     targetSlots[slotIndex].base64Data = base64;
    //     targetSlots[slotIndex].uploaded = true;
    //     targetSlots[slotIndex].previewUrl = base64;

    //     slotIndex++;
    // }

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
    if (label === 'Letter Issued') this.photoUploadSlotsLetterIssued = [...targetSlots];
    if (label === 'Completion Letter') this.photoUploadSlotsCompletionLetter = [...targetSlots];


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


    async updateWorkStepDataCapture() {
        if (!this.workStepId) return;

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.workStepId;
        fields[STATUS_FIELD.fieldApiName] = 'Completed';

        return updateRecord({ fields });
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


    navigateToRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'WorkOrder',
                actionName: 'view'
            }
        });
    }

    handleCancel() {
         setTimeout(() => {
            history.back();
        }, 1000); 
      
        
      }


    getError(err) {
        return err?.body?.message || err.message || JSON.stringify(err);
    }

    showToast(msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title: msg, variant }));
    }
}