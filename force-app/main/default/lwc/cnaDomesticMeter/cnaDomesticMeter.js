import { LightningElement, api, track, wire } from 'lwc';
import markCustomerUnavailable from '@salesforce/apex/VisitControllerDomesticMeter.markCustomerUnavailable';
import savePhotoUploadsDomesticMeter from '@salesforce/apex/VisitControllerDomesticMeter.savePhotoUploadsDomesticMeter';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

export default class CustomerUnavailable extends LightningElement {
    @api recordId;
    selectedReason = '';
    remarks = '';
    followUpDate = null;
    
    @track photoUploadSlots = [];
    imageUploadPage = false;
    noOfPhotos = 3;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId;
            console.log('📌 Record Id from URL:', this.recordId);
        }
    }


    reasonOptions = [
        { label: 'House Lock', value: 'House Lock' },
        { label: 'Customer refused access', value: 'Customer refused access' },
        { label: 'Locked premises', value: 'Locked premises' },
        { label: 'Other', value: 'Other' }
    ];



    connectedCallback() {
    console.log('Record Id is:::', this.recordId); 
    this.setPhotoUploadSlots();
}

handleFollowUpDateChange(event) {
    this.followUpDate = event.detail.value;
}



    async handleFile(event) {
        console.log('📥 inside handleFile');
        let newSlots = event.detail.steps;

        for (let i = 0; i < newSlots.length; i++) {
        let slot = newSlots[i];
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

        this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set');
    } 



    
    base64ToBlob(base64Data) {
        const byteString = atob(base64Data.split(',')[1]);
        const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];
        const ab = new ArrayBuffer(byteString.length);
        const ia = new Uint8Array(ab);
        for (let i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
        }
        return new Blob([ab], { type: mimeString });
    }

    compressImageFromURL(imageUrl) {
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

    convertBlobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    }

setPhotoUploadSlots() {
    const labelPrefix = this.selectedReason || 'Photo';

    this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => {
        return {
            id: index + 1,
            index: index + 1,
            label: this.noOfPhotos > 1 ? `${labelPrefix} ${index + 1}` : labelPrefix,
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: ''
        };
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

        if (this.selectedReason === 'House Lock') {
        this.imageUploadPage = true;
        
    }
       
    }

    handleRemarks(event) {
        this.remarks = event.detail.value;
    }



    handleSubmit() {
    if (!this.selectedReason) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'Please select a reason.',
            variant: 'error'
        }));
        return;
    }

    if (!this.followUpDate) {
    this.dispatchEvent(new ShowToastEvent({
        title: 'Error',
        message: 'Please select a follow-up visit date.',
        variant: 'error'
    }));
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

    console.log('📸 Sending photoUploadSlots:', JSON.stringify(this.photoUploadSlots));
    this.isLoading = true;

    // Step 1: Upload photos
    savePhotoUploadsDomesticMeter({
        recordId: this.recordId, 
        listFiles: this.photoUploadSlots
    })
    .then(uploadResult => {
        console.log('✅ Photo upload result:', uploadResult);
        if (uploadResult.includes('ERROR')) {
            throw new Error(uploadResult);
        }

        // Step 2: Submit reason, remarks, and follow-up date
        return markCustomerUnavailable({
    recordId: this.recordId, 
    reason: this.selectedReason,
    remarks: this.remarks,
    followUpDate: this.followUpDate
    
});

    })
    .then(() => {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Customer unavailability recorded and photos uploaded.',
            variant: 'success'
        }));
        this.showForm = false;
    })
    .catch(error => {
        console.error('❌ Error during submission:', error);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: this.getErrorMessage(error),
            variant: 'error'
        }));
    })
    .finally(() => {
        this.isLoading = false;
    });
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

}