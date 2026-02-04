import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveRHNotDoneDetails from '@salesforce/apex/RHNotDoneController.saveRHNotDoneDetails';
import savePhotoUploads from '@salesforce/apex/RHNotDoneController.savePhotoUploads';

export default class RhNotDoneForm extends LightningElement {
    @api recordId;
    @track reason = '';
    @track followUpDate;
    @track remarks = '';
    @track latitude;
    @track longitude;
    @track fileData;
    imageUploadPage = true;
    @track photoUploadSlots = [];
    noOfPhotos = 1;
    @track isLoading = false;  
    @track formDisabled = false;



    reasonOptions = [
        { label: 'House Locked', value: 'House Locked' },
        { label: 'Customer Not Allowing', value: 'Customer Not Allowing' },
        { label: 'Kitchen Under Renovation', value: 'Kitchen Under Renovation' },
        { label: 'Payment Defaulter / Disconnected', value: 'Payment Defaulter / Disconnected' },
        { label: 'Building Demolished', value: 'Building Demolished' },
        { label: 'Customer Using LPG', value: 'Customer Using LPG' },
        { label: 'Others', value: 'Others' }
    ];

    connectedCallback() {
        navigator.geolocation.getCurrentPosition(pos => {
            this.latitude = pos.coords.latitude;
            this.longitude = pos.coords.longitude;
        });

        this.setPhotoUploadSlots();
    }

    handleReasonChange(e) {
        this.reason = e.detail.value;
    }

    handleDateChange(e) {
        this.followUpDate = e.detail.value;
    }

    handleRemarksChange(e) {
        this.remarks = e.detail.value;
    }

    handleFile(event) {
        this.photoUploadSlots = event.detail.steps;
        console.log('handleFile this.photoUploadSlots::' + JSON.stringify(this.photoUploadSlots));
    }

    setPhotoUploadSlots() {
        console.log('Inside method:', this.noOfPhotos);
        //const customLabels = ['Before Photos'];
        this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                //label: customLabels[index] || `Photo ${slotNum}`, 
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: ''
            };
        });
        console.log('📸 Photo Upload Slots:', JSON.stringify(this.photoUploadSlots));
    }



    handleSubmit() {

    console.log('handleSubmit triggered');

    if (!this.reason || !this.followUpDate) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'Please fill all required fields.',
            variant: 'error'
        }));
        return;
    }

    this.isLoading = true; // Show spinner

    const payload = {
        reason: this.reason,
        followUpDate: this.followUpDate,
        remarks: this.remarks,
        latitude: this.latitude,
        longitude: this.longitude
    };

    saveRHNotDoneDetails({ recordId: this.recordId, payload: JSON.stringify(payload) })
        .then(() => {
            if (this.photoUploadSlots.length > 0) {
                const formattedPhotos = this.photoUploadSlots.map(slot => ({
                    label: slot.label || 'Photo',
                    fileName: slot.fileName,
                    base64Data: slot.previewUrl?.split(',')[1]
                }));
                return savePhotoUploads({
                    recordId: this.recordId,
                    listFiles: formattedPhotos
                });
            } else {
                return Promise.resolve();
            }
        })
        .then(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Details submitted successfully.',
                variant: 'success'
            }));
            this.formDisabled = true;
            this.isLoading=false;
        })
        .catch(error => {
            console.error('Apex error in handleSubmit:', JSON.stringify(error));
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error?.body?.message || error.message || 'Unknown error occurred',
                variant: 'error'
            }));
            this.isLoading=false;
        })
        .finally(() => {
            this.isLoading = false; // Hide spinner
        });
}



}