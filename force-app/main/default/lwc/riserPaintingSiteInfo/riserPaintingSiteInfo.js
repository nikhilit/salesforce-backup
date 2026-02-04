import { LightningElement, api, track } from 'lwc';
//import saveSiteDetails from '@salesforce/apex/InitialSiteDetailsController.saveSiteDetails';
import getForms from '@salesforce/apex/RiserPaintingFormController.getForms';
import saveForms from '@salesforce/apex/RiserPaintingFormController.saveForms';
import getServiceAppointmentId from '@salesforce/apex/RiserPaintingFormController.getServiceAppointmentId';
import setupRiserForms from '@salesforce/apex/RiserPaintingFormController.setupRiserForms';
import savePhotoUploads from '@salesforce/apex/RiserPaintingFormController.savePhotoUploads';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';


export default class CombinedRiserLogger extends LightningElement {
    @api recordId;

    
    showFormPage = false;

    // Initial site form data
    @track floors;
    @track risers;
    @track riserTypes = [];
    imageUploadPage = true;
    @track photoUploadSlots = [];
    @track currentRiserIndex = 1;
    @track totalRisers = 1;
    @track isSubmitting = false;
@track isFinished = false;
@track formDisabled = false;



    noOfPhotos = 1;

    typeOptions = [
        { label: 'Welded', value: 'Welded' },
        { label: 'Threaded', value: 'Threaded' }
    ];

    
    @track serviceAppointmentId;
    @track forms = [];

    connectedCallback() {
        this.setPhotoUploadSlots();
        console.log('Work Order recordId:', this.recordId);
    }

    handleFloors(event) {
        this.floors = event.detail.value;
    }

    handleRisers(event) {
        this.risers = parseInt(event.target.value, 10) || 0;
        this.riserTypes = [];

        for (let i = 0; i < this.risers; i++) {
            this.riserTypes.push({
                key: i,
                type: '',
                label: `Riser ${i + 1} Type`
            });
        }
    }

    handleRiserType(event) {
    const index = event.target.dataset.index;
    this.riserTypes[index].type = event.detail.value;

    const allSelected = this.riserTypes.every(r => r.type);

    if (allSelected && this.floors && this.risers) {
        this.initiateFormSetup(); // renamed from handleSubmit
    }
}



//     handleFile(event) {
//     this.photoUploadSlots = event.detail.steps;
//     console.log('Photo uploads:', JSON.stringify(this.photoUploadSlots));

//     // Upload photos and then show form page
//     savePhotoUploads({
//         recordId: this.recordId,
//         listFiles: this.photoUploadSlots
//     }).then(() => {
//         this.imageUploadPage = false; 
//         this.showFormPage = true;     
//     }).catch(error => {
//         console.error('Upload failed:', error);
//     });
// }

async handleFile(event) {
    console.log('📥 inside handleFile');
    let newSlots = event.detail.steps;

    for (let i = 0; i < newSlots.length; i++) {
        let slot = newSlots[i];
        console.log(`🔄 Processing Photo ${i + 1}`);

        if (slot.base64Data) {
            try {
                const fullBase64 = slot.base64Data.startsWith('data:image')
                    ? slot.base64Data
                    : `data:image/jpeg;base64,${slot.base64Data}`;

                const originalBytes = atob(fullBase64.split(',')[1]).length;
                const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
                console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

                const blob = this.base64ToBlob(fullBase64);
                const imageUrl = URL.createObjectURL(blob);
                const compressedBlob = await this.compressImageFromURL(imageUrl);

                const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                const compressedBytes = atob(compressedBase64).length;
                const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
                console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

                slot.base64Data = compressedBase64;

            } catch (error) {
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
    console.log('✅ Final photoUploadSlots set:', JSON.stringify(this.photoUploadSlots));

    // ⬇️ Upload compressed photos and show form page
    try {
        await savePhotoUploads({
            recordId: this.recordId,
            listFiles: this.photoUploadSlots
        });

        this.imageUploadPage = false;
        this.showFormPage = true;
        console.log('📤 Photo upload successful. Showing form page.');
    } catch (error) {
        console.error('❌ Photo upload failed:', error);
        this.showtoast('Error', 'Photo upload failed. Please try again.', 'error');
    }
}



    setPhotoUploadSlots() {
        console.log('Inside method:', this.noOfPhotos);
        const customLabels = ['Before Photos'];
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

    initiateFormSetup() {
    if (!this.floors || !this.risers || this.riserTypes.some(r => !r.type)) {
        alert('Please complete all fields.');
        return;
    }

    setupRiserForms({ workOrderId: this.recordId, totalRisers: this.risers })
        .then(() => {
            return getServiceAppointmentId({ workOrderId: this.recordId });
        })
        .then(saId => {
            this.serviceAppointmentId = saId;
            this.totalRisers = this.risers;
            this.currentRiserIndex = 1;

            return getForms({ appointmentId: saId, riserIndex: this.currentRiserIndex });
        })
        .then(data => {
            this.forms = data.map(f => {
                const rawType = f.Form_Master__r.Data_Type__c?.toLowerCase();
                return {
                    Id: f.Id,
                    label: f.Form_Master__r.Question_Label__c,
                    response: f.Response__c,
                    dataType: rawType,
                    dataTypeIsText: rawType === 'text' || rawType === 'number' || rawType === 'measurement',
                    dataTypeIsBoolean: rawType === 'boolean' || rawType === 'yes/no',
                    isChecked: f.Response__c === 'true'
                };
            });
        })
        .catch(error => {
            console.error('Error setting up forms:', error);
        });
}


//     async handleSubmit() {
//     if (!this.floors || !this.risers || this.riserTypes.some(r => !r.type)) {
//         alert('Please fill all required fields.');
//         return;
//     }

//     try {
//         const result = await setupRiserForms({ workOrderId: this.recordId, totalRisers: this.risers });

//         if (result === 'AlreadyExists') {
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Info',
//                 message: 'Forms already exist. Loading existing forms...',
//                 variant: 'info'
//             }));
//         } else if (result === 'Created') {
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Success',
//                 message: 'Riser forms created successfully.',
//                 variant: 'success'
//             }));
//         } else if (result === 'InvalidRiserCount') {
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Error',
//                 message: 'Invalid number of risers. Please check the input.',
//                 variant: 'error'
//             }));
//             return;
//         }

//         const saId = await getServiceAppointmentId({ workOrderId: this.recordId });

//         if (!saId) {
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Error',
//                 message: 'No Service Appointment found for this Work Order.',
//                 variant: 'error'
//             }));
//             return;
//         }

//         this.serviceAppointmentId = saId;
//         this.totalRisers = this.risers;
//         this.currentRiserIndex = 1;

//         await this.loadForms(saId, this.currentRiserIndex);
//         this.showFormPage = true;

//     } catch (error) {
//         console.error('Error saving:', error);
//         const message = error?.body?.message || error?.message || 'Unknown error occurred';

//         this.dispatchEvent(new ShowToastEvent({
//             title: 'Error',
//             message: message,
//             variant: 'error'
//         }));
//     }
// }



    // Modified to use riserIndex
    async loadForms(appointmentId, riserIndex) {
    try {
        const data = await getForms({ appointmentId, riserIndex });
        console.log(`Returned ${data.length} forms for riser ${riserIndex}`);

        if (!data || data.length === 0) {
            console.warn('No forms returned for current riser index:', riserIndex);
        }

        this.forms = data.map(f => {
            const rawType = f.Form_Master__r.Data_Type__c?.toLowerCase();
            return {
                Id: f.Id,
                label: f.Form_Master__r.Question_Label__c,
                response: f.Response__c,
                dataType: rawType,
                dataTypeIsText: rawType === 'text' || rawType === 'number' || rawType === 'measurement',
                dataTypeIsBoolean: rawType === 'boolean' || rawType === 'yes/no',
                isChecked: f.Response__c === 'true'
            };
        });
    } catch (error) {
        console.error('Error fetching forms:', error);
    }
}


    handleChange(event) {
        const id = event.target.dataset.id;
        const value = event.target.type === 'checkbox'
            ? event.target.checked.toString()
            : event.detail.value;
        const form = this.forms.find(f => f.Id === id);
        form.response = value;
    }

    get isLastRiser() {
        return this.currentRiserIndex === this.totalRisers;
    }

    get riserButtonLabel() {
    return this.isLastRiser ? 'Finish' : 'Next Riser';
}


    get currentRiserLabel() {
        return `Riser ${this.currentRiserIndex}`;
    }

    async handleSave() {
    const formsToSave = this.forms.map(f => ({
        Id: f.Id,
        Response__c: f.response,
        Riser_Index__c: this.currentRiserIndex
    }));

    try {
        await saveForms({ forms: formsToSave });

        if (!this.isLastRiser) {
            this.currentRiserIndex += 1;

            const data = await getForms({
                appointmentId: this.serviceAppointmentId,
                riserIndex: this.currentRiserIndex
            });

            this.forms = data.map(f => {
                const rawType = f.Form_Master__r.Data_Type__c?.toLowerCase();
                return {
                    Id: f.Id,
                    label: f.Form_Master__r.Question_Label__c,
                    response: f.Response__c,
                    dataType: rawType,
                    dataTypeIsText: rawType === 'text' || rawType === 'number' || rawType === 'measurement',
                    dataTypeIsBoolean: rawType === 'boolean' || rawType === 'yes/no',
                    isChecked: f.Response__c === 'true'
                };
            });

            this.showFormPage = true;

        } else {
            // ✅ Final riser reached — show final success toast only (skip re-upload)
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'All riser data and photos submitted successfully.',
                variant: 'success'
            }));

            this.dispatchEvent(new CustomEvent('cancel'));

            this.formDisabled = true;

            // Optional: auto-close screen
            setTimeout(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            }, 1500);
        }

    } catch (error) {
        console.error('Error saving form responses or loading next:', error);
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'Failed to save or load next riser form',
            variant: 'error'
        }));
    }
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


    get hasForms() {
        return this.forms && this.forms.length > 0;
    }

    

}