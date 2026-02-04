import { LightningElement, api, track, wire} from 'lwc';
import getUnsuccessfulReasons from '@salesforce/apex/TPEController.getUnsuccessfulReasons';
import savePhotoUploads from '@salesforce/apex/TPEController.savePhotoUploads';
import markAsUnsuccessful from '@salesforce/apex/TPEController.markAsUnsuccessful';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UnsuccessfulVisit extends LightningElement {
    @api recordId;
    @track reasonOptions = [];
    @track photoUploadSlots = [];
    @track isVisible = true;

    selectedReason = '';
    otherDetails = '';
    showOther = false;
    imageUploadPage = true;
    noOfPhotos = 1;
    isLoading = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId || currentPageReference.attributes.recordId;
            console.log('✅ recordId from URL:', this.recordId);
        }
    }

    connectedCallback() {
        getUnsuccessfulReasons()
            .then(data => {
                this.reasonOptions = data.map(reason => ({ label: reason, value: reason }));
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load reasons: ' + this.getErrorMessage(error), 'error');
            });

        this.setPhotoUploadSlots();
    }

    handleFile(event) {
    this.photoUploadSlots = event.detail.steps;
    console.log('handleFile photoUploadSlots:', JSON.stringify(this.photoUploadSlots));
}


    setPhotoUploadSlots() {
    const customLabels = ['Customer Not Available'];
    this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => {
        return {
            id: index + 1,
            index: index + 1,
            label: customLabels[index] || `Photo ${index + 1}`,
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: ''
        };
    });
}


    handleReasonChange(e) {
        this.selectedReason = e.detail.value;
        this.showOther = this.selectedReason === 'Other';
    }

    handleDetailsChange(e) {
        this.otherDetails = e.detail.value;
    }

    handleSubmit() {
    if (!this.selectedReason) {
        this.showToast('Error', 'Please select a reason.', 'error');
        return;
    }

    const allUploaded = this.photoUploadSlots.every(slot => slot.uploaded && slot.base64Data);
    if (!allUploaded) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'Please upload required images before submitting.',
            variant: 'error'
        }));
        return;
    }
      console.log('recordId being passed:', this.recordId);
    console.log('Sending photoUploadSlots:', JSON.stringify(this.photoUploadSlots));
    this.isLoading = true;

    // Step 1: Save Photos
    savePhotoUploads({
        recordId: this.recordId,
        listFiles: this.photoUploadSlots
    })
    .then((uploadResult) => {
        console.log('Upload result:', uploadResult);
        if (uploadResult.includes('ERROR')) {
            throw new Error(uploadResult);
        }

        // Replace with correct method and parameters
        return markAsUnsuccessful({
    workOrderId: this.recordId, 
    reason: this.selectedReason,
    reasonDetails: this.selectedReason === 'Other' ? this.otherDetails : ''
});

    })
    .then(() => {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Customer marked as unavailable and photos uploaded.',
            variant: 'success'
        }));
        this.isVisible = false;
         this.dispatchEvent(new CustomEvent('cancel'));

    })
    .catch((err) => {
        console.error('Caught error:', err);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: this.getErrorMessage(err),
            variant: 'error'
        }));
    })
    .finally(() => {
        this.isLoading = false;
    });
}

    

    // showToast(title, msg, variant) {
    //     this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    // }

    getErrorMessage(error) {
        try {
            if (error?.body?.message) return error.body.message;
            if (error?.message) return error.message;
            return JSON.stringify(error);
        } catch (e) {
            return 'Unknown error occurred';
        }
    }
}