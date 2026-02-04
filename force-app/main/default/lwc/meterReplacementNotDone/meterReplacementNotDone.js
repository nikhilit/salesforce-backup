import { LightningElement, api, track } from 'lwc';
import markCustomerUnavailable from '@salesforce/apex/MeterReplacementNotDoneController.markCustomerUnavailable';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import savePhotoUploads from '@salesforce/apex/MeterReplacementNotDoneController.savePhotoUploads';

export default class RhNotDoneForm extends LightningElement {
    @api recordId;
    @track reason;
    
    @track remarks;

    @track isLoading = false;
    @track isVisible = true;

    imageUploadPage = true;
    noOfPhotos = 1;
    @track photoUploadSlots = [];

    reasonOptions = [
        { label: 'House Locked', value: 'House Locked' },
        { label: 'Customer Not Allowing', value: 'Customer Not Allowing' },
        { label: 'Others', value: 'Others' }
    ];

    connectedCallback() {
        this.setPhotoUploadSlots();
        console.log('Work Order recordId:', this.recordId);
    }

    handleReasonChange(e) {
        this.reason = e.detail.value;
    }

    // handleDateChange(e) {
    //     this.followUpDate = e.detail.value;
    // }

    handleFile(event) {
        this.photoUploadSlots = event.detail.steps;
        console.log('handleFile this.photoUploadSlots::'+JSON.stringify(this.photoUploadSlots));
    }

    setPhotoUploadSlots() {
        console.log('Inside method:', this.noOfPhotos);
        const customLabels = ['Customer Not Available'];
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

    handleRemarksChange(e) {
        this.remarks = e.detail.value;
    }

    handleSubmit() {
    try {
        if (!this.reason) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please provide reason and follow-up date.',
                variant: 'error'
            }));
            return;
        }

        this.isLoading = true;

        // Validate image uploads
        const allUploaded = this.photoUploadSlots.every(slot => slot.uploaded && slot.base64Data);
        if (!allUploaded) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Please upload required images before submitting.',
                variant: 'error'
            }));
            this.isLoading = false;
            return;
        }

        console.log('Sending photoUploadSlots:', JSON.stringify(this.photoUploadSlots));


        savePhotoUploads({
            recordId: this.recordId,
            listFiles: this.photoUploadSlots
        })
        .then((uploadResult) => {
            console.log('Upload result:', uploadResult);
            if (uploadResult.includes('ERROR')) {
                throw new Error(uploadResult);
            }

            return markCustomerUnavailable({
                workOrderId: this.recordId,
                reason: this.reason,
                followUpDate: this.followUpDate,
                remarks: this.remarks
            });
        })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Customer marked as unavailable and photos uploaded.',
                variant: 'success'
            }));
            this.isVisible = false;
        })
        .catch((err) => {
            console.error('Caught error:', err);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: err?.body?.message || err?.message || 'Unknown error occurred',
                variant: 'error'
            }));
        })
        .finally(() => {
            this.isLoading = false;
        });
    } catch (e) {
        console.error('Outer try-catch error:', e);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: e.message || 'Unexpected error',
            variant: 'error'
        }));
    }
}

}