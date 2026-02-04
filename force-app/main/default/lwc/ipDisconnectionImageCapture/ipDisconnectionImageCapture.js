import { LightningElement, api, track } from 'lwc';
import saveIPDisconnectionDetails from '@salesforce/apex/TechnicianImageUploadController.saveIPDisconnectionDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TechnicianImageCapture extends LightningElement {
    @api recordId; // Work Order Id
    @track photoUploadSlots = [];
    @track load = false;
    @track saveDisabled = false;

    noOfPhotos = 4;

    connectedCallback() {
        this.imageUploadPage = true;
        this.setPhotoUploadSlots();
    }

    get isSaveDisabled() {
    return this.load || this.saveDisabled;
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

    handleFile(event) {
    this.photoUploadSlots = event.detail.steps.map(slot => ({
    ...slot,
    latitude: slot.latitude || null,
    longitude: slot.longitude || null,
    capturedTime: new Date().toISOString() // 🔄 match Apex field name
}));

}


    handleFinalSave() {
        console.log('Inside handle final save');

        const allFilesSelected = this.photoUploadSlots.length === 4 &&
            this.photoUploadSlots.every(slot => slot.fileName && slot.fileName.trim() !== '');
        console.log('allFilesSelected::', allFilesSelected);

        if (!allFilesSelected) {
            this.showToast('Warning', 'Please Capture all required photos.', 'warning');
            return;
        }

        this.load = true; // Show spinner
        this.saveDisabled = true; // Disable Save button

        saveIPDisconnectionDetails({ 
            recordId: this.recordId, 
            listFiles: this.photoUploadSlots 
        })
        .then(result => {      
            console.log('Result ::', result);
            this.showToast('Success', 'Record Updated Successfully.', 'success');

            // You can optionally hide the entire form or navigate away here
            this.load = false;
            this.saveDisabled = true; // keep button disabled permanently after success
            this.dispatchEvent(new CustomEvent('cancel'));
        })
        .catch(error => {
            this.load = false;
            this.saveDisabled = false; // re-enable button on failure
            console.log('Error ::', error);
            this.showToast('Error', 'Something went wrong. Please try again.', 'error');
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}