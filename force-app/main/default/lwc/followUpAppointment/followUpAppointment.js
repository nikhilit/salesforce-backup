import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import WORKTYPE_NAME_FIELD from '@salesforce/schema/WorkOrder.WorkType.Name';
import { getRecord } from 'lightning/uiRecordApi';


import getWorkOrderDetail from '@salesforce/apex/FollowUpAppointmentController.getWorkOrderDetail';

import asGoCollectFlowLabel from "@salesforce/label/c.AS_GoCollectFlowLabel";
import getPicklistValues from '@salesforce/apex/FollowUpAppointmentController.getPicklistValues';
import createFollowUp from '@salesforce/apex/FollowUpAppointmentController.createFollowUp';
import createFollowUpWithImages from '@salesforce/apex/FollowUpAppointmentController.createFollowUpWithImages';
import getFollowUpReasonsFromMetadata from '@salesforce/apex/FollowUpAppointmentController.getFollowUpReasonsFromMetadata';

export default class FollowUpAppointment extends NavigationMixin(LightningElement) {
    @api recordId;
    followUpDate;
    followUpRemarks;
    @track isLoading = false;
    followUpOption = []; 
    showOtherRemark = false;
    otherFollowUpRemarks;
    @track photoUploadSlots = [];
    @track noOfPhotos;
    doorLocked = false;
    isGoCollect = false;
    isFollowUpRequired = false;

    label = { asGoCollectFlowLabel };

    followUpScreen = true;
    openMainPage = false;
    openDomesticHome = false;

    imageOptional = false;

    handleDateChange(event) {
        this.followUpDate = event.detail.value;
    }

    @wire(getRecord, { recordId: '$recordId', fields: WORKTYPE_NAME_FIELD })
    wiredWorkOrder({ error, data }) {
        if (data) {
            const workOrderType = data.fields.WorkType.displayValue;
            
            this.isGoCollect = this.label.asGoCollectFlowLabel.split(',').indexOf(workOrderType.toLowerCase()) !== -1;

        } else if (error) {
            console.error('Error fetching Work Order:', error);
        }
    }

    connectedCallback() {
        
        this.isLoading = true;

        getPicklistValues({ objectName: 'ServiceAppointment', fieldName: 'FollowUpRemarks__c' })
        .then(result => {
            this.followUpOption = result;
        })
        .catch(error => {
            this.isLoading = false;
            this.showToast('Error',error.body ? error.body.message : 'Unknown error','error');
        })
    
        getWorkOrderDetail({ recId: this.recordId })
        .then(result => {

            const isCheckInDateAvailable = result.Check_In_Date_Time__c != null;
            const isWorkOrderCompleted = result.Status == 'Completed';
            const isCheckOutDateAvailable = result.Check_Out_Date_Time__c != null;
            const isFollowUp = result.Follow_up_Date__c != null;
            
            if(isCheckInDateAvailable && isWorkOrderCompleted && isCheckOutDateAvailable){
                this.showEnableMessage = true;
                this.message = 'Task is already completed. Please refresh the WorkOrder page to continue.';
            }else if((!isCheckInDateAvailable && !isFollowUp)){
                this.showEnableMessage = true;
                this.message = 'Check-In is required. Please Check-In and refresh the WorkOrder page to continue.';
            }else if(isFollowUp){
                this.showEnableMessage = false;
                this.showToast('Warning','This is already a Follow-Up task. If you still want to create another follow-up then continue else go back to Home screen.','warning');
                if((!isCheckInDateAvailable && isFollowUp)){
                    this.showEnableMessage = true;
                    this.message = 'Check-In is required. Please Check-In and refresh the WorkOrder page to continue.';
                }else{
                    this.showEnableMessage = false;
                }
            }

            this.isLoading = false;
        })
        .catch(error => {
            this.isLoading = false;
            this.showToast('Error',error.body ? error.body.message : 'Unknown error','error');
        })
    }

    @wire(getFollowUpReasonsFromMetadata)
    wiredFollowUpMetadata({ error, data }) {
        if (data) {
            this.followUpMetadata = data;

            // Map to options
            this.reasonOptions = data.map(record => ({
                label: record.Label,
                value: record.Label // use Label as value
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load follow-up metadata', 'error');
        }
    }

    get statusOptions() {
        return this.followUpOption;
    }

    handleRemarksChange(event) {
        this.followUpRemarks = event.detail.value;
        this.showOtherRemark = (this.followUpRemarks.toLowerCase() === 'other');
        const selectedValue = this.followUpRemarks?.toLowerCase();
        console.log('Selected value:', selectedValue);

        const selectedMetadata = this.followUpMetadata?.find(
            meta => meta.Label?.toLowerCase() === selectedValue
        );
        console.log('Matched metadata:', JSON.stringify(selectedMetadata));

        if (selectedMetadata) {
            const imageRequired = selectedMetadata.Image_Required__c;
            const imageCount = selectedMetadata.Image_count__c;
            const smsRequired = selectedMetadata.SMS_requried__c;

            this.isFollowUpRequired = selectedMetadata.Follow_Up_Required__c;

            console.log('Image required:', imageRequired, 'Image count:', imageCount);

            if (imageRequired) {
                this.noOfPhotos = imageCount;
                console.log('Setting photo upload slots with count:', this.noOfPhotos);
                this.imageOptional = selectedMetadata.Image_Optional__c;
                this.setPhotoUploadSlots();
                this.doorLocked = true;
            } else {
                this.doorLocked = false;
                this.noOfPhotos = 0;
                this.imageOptional = false;
                this.photoUploadSlots = [];
            }
        } else {
            console.warn('No matching metadata found.');
            this.doorLocked = false;
            this.noOfPhotos = 0;
            this.photoUploadSlots = [];
            this.imageOptional = false;
            this.isFollowUpRequired = false;
        }

        console.log('Final doorLocked:', this.doorLocked);
    }



    handleOtherRemarksChange(event) {
        this.otherFollowUpRemarks = event.detail.value;
    }

    handleSave() {  
        console.log('Inside save');

        //if (!this.followUpDate || !this.followUpRemarks) {
        if (!this.followUpRemarks) {
            //this.showToast('Error', 'Please enter date and remarks.', 'error');
            this.showToast('Error', 'Please enter the remarks.', 'error');
            return;
        }

        if(this.isFollowUpRequired && !this.followUpDate){
            this.showToast('Error', 'Please enter follow-up date.', 'error');
            return;
        }

        // if (this.followUpRemarks == 'Other' && !this.otherFollowUpRemarks) {
        //     this.showToast('Error', 'Please enter other remark details.', 'error');
        //     return;
        // }

        if(this.doorLocked){
            const allFilesSelected = this.photoUploadSlots.length === this.noOfPhotos &&
                this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);
            const selectedMetadata = this.followUpMetadata.find(
              item => item.Label === this.followUpRemarks
            );

            const smsRequired = selectedMetadata?.SMS_requried__c || false;


            if (this.doorLocked && !allFilesSelected && !this.imageOptional) {
                this.showToast('Warning', 'Please capture the photos', 'warning');
                return;    
            }

            this.isLoading = true;

            const base64ImagesToSend = this.doorLocked
                ? this.photoUploadSlots.map(slot => slot.base64Data)
                : [];

            
            createFollowUpWithImages({
                parentRecordId: this.recordId,
                followUpDate: this.followUpDate,
                followUpRemarks: this.followUpRemarks,
                otherRemark: this.otherFollowUpRemarks,
                smsRequired: smsRequired,
                base64Images: base64ImagesToSend
            })
            .then(result => {
                
                
                if (result.success) {

                    if(result.message == 'Work Order updated.'){
                        this.showToast(
                            result.success ? 'Success' : 'Error',
                            result.message,
                            result.success ? 'success' : 'error'
                        );

                        if(!this.isGoCollect){
                            this.followUpScreen = false;
                        }else{
                            history.back();
                        }
                    }else{
                        this.navigateToWorkOrderInFSL(this.recordId);
                    }
                } 

                this.isLoading = false;
            })
            .catch(error => {
                console.error(' Apex call failed:', error);

                this.showToast(
                    'Error',
                    error.body?.message || 'Unknown error',
                    'error'
                );
                this.isLoading = false;
            });

        }else{

            this.isLoading = true;
            createFollowUp({ 
                parentRecordId: this.recordId, 
                followUpDate: this.followUpDate, 
                followUpRemarks: this.followUpRemarks,
                otherRemarks: this.otherFollowUpRemarks
            })
            .then(result => {
                if (result.success) {

                    if(result.message == 'Work Order updated.'){
                        this.showToast(
                            result.success ? 'Success' : 'Error',
                            result.message,
                            result.success ? 'success' : 'error'
                        );

                        if(!this.isGoCollect){
                            this.followUpScreen = false;
                        }else{
                            history.back();
                        }

                        this.isLoading = false;
                    }else{
                        this.navigateToWorkOrderInFSL(this.recordId);
                    }   
                }
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    error.body ? error.body.message : 'Unknown error',
                    'error'
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    navigateToWorkOrderInFSL(workOrderId) {
        //history.back();
        //window.close();
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `com.salesforce.fieldservice://v1/sObject/${workOrderId}/overview`
            }
        });
    }

    async handleFile(event) {
        
        let newSlots = event.detail.steps;

        for (let i = 0; i < newSlots.length; i++) {
        let slot = newSlots[i];
            
            if (slot.base64Data) {
                try {
                    // Add prefix if missing
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;

                    // 🔍 Original size in MB
                    const originalBytes = atob(fullBase64.split(',')[1]).length;
                    const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
                    
                    // Convert to blob and compress
                    const blob = this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);

                    // Convert compressed Blob back to base64
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    const compressedBytes = atob(compressedBase64).length;
                    const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
                    console.log(` Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

                    // Store compressed result
                    slot.base64Data = compressedBase64;

                } catch (error) {
                //console.error(` Compression failed for Photo ${i + 1}:`, error);

                // Only show toast if compressed base64 is not usable
                if (!slot.base64Data || slot.base64Data.length < 100) {
                    console.error(` Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
                } else {
                    console.warn(` Compression threw error but base64 still present for Photo ${i + 1}`);
                }
            }


            } else {
                console.warn(` Skipped Photo ${i + 1}: base64Data missing.`);
            }
        }

        this.photoUploadSlots = newSlots;
        console.log('Final photoUploadSlots set');
    }

    setPhotoUploadSlots() {
        const count = this.noOfPhotos || 0;
        console.log('setPhotoUploadSlots called with count:', count);

        this.photoUploadSlots = Array.from({ length: count }, (_, index) => {
            const slot = {
                id: index + 1,
                index: index + 1,
                label: `Photo ${index + 1}`,
                name: `fileUploader${index + 1}`,
                fileName: '',
                uploaded: false,
                previewUrl: '',
                base64Data: ''
            };
            console.log('Created slot:', slot);
            return slot;
        });

        console.log('Final photoUploadSlots:', this.photoUploadSlots);
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
            img.crossOrigin = 'anonymous';

            img.onload = () => {
                try {
                    const maxDim = 600; // smaller = smaller file
                    let { width, height } = img;

                    const scale = Math.min(maxDim / width, maxDim / height, 1);
                    width = Math.floor(width * scale);
                    height = Math.floor(height * scale);

                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d', { willReadFrequently: true });
                    canvas.width = width;
                    canvas.height = height;

                    // Fill white background (remove transparency)
                    ctx.fillStyle = '#ffffff';
                    ctx.fillRect(0, 0, width, height);
                    ctx.drawImage(img, 0, 0, width, height);

                    // 🔥 Use toDataURL (works in all browsers)
                    const compressedDataUrl = canvas.toDataURL('image/jpeg', 0.2); // 0.2 = strong compression

                    // Convert to Blob manually
                    const byteString = atob(compressedDataUrl.split(',')[1]);
                    const ab = new ArrayBuffer(byteString.length);
                    const ia = new Uint8Array(ab);
                    for (let i = 0; i < byteString.length; i++) {
                        ia[i] = byteString.charCodeAt(i);
                    }
                    const blob = new Blob([ab], { type: 'image/jpeg' });

                    console.log(
                        `✅ Compressed image → ${(blob.size / (1024 * 1024)).toFixed(2)} MB`
                    );
                    resolve(blob);
                } catch (err) {
                    reject(err);
                }
            };

            img.onerror = () => reject(new Error('Failed to load image'));
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

    handleCancel() {
        history.back();
    }

    handleChildEvent(event) {
        this.openMainPage = true;
    }
}