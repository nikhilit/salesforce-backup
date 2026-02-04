import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import WORKTYPE_NAME_FIELD from '@salesforce/schema/WorkOrder.WorkType.Name';
import { getRecord } from 'lightning/uiRecordApi';
import { getLocationService } from 'lightning/mobileCapabilities';
import FORM_FACTOR from '@salesforce/client/formFactor';

import getWorkOrderDetail from '@salesforce/apex/FollowUpAppointmentController.getWorkOrderDetail';
import asGoCollectFlowLabel from "@salesforce/label/c.AS_GoCollectFlowLabel";
import getPicklistValues from '@salesforce/apex/FollowUpAppointmentController.getPicklistValues';
import createFollowUp from '@salesforce/apex/FollowUpAppointmentController.createFollowUp';
import createFollowUpWithImages from '@salesforce/apex/FollowUpAppointmentController.createFollowUpWithImages';
import getFieldSenseFollowUpReasonsFromMetadata from '@salesforce/apex/FollowUpAppointmentController.getFieldSenseFollowUpReasonsFromMetadata';
import updateGeoLocation from '@salesforce/apex/FollowUpAppointmentController.updateGeoLocation';

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

    isDomestic = false;

    connectedCallback() {
        this.isLoading = true;
        this.registerOnlineListener();
        this.trySyncQueuedFollowUps();

        // getPicklistValues({ objectName: 'ServiceAppointment', fieldName: 'FollowUpRemarks__c' })
        // .then(result => { this.followUpOption = result; })
        // .catch(error => {
        //     this.isLoading = false;
        //     this.showToast('Error', error.body ? error.body.message : 'Unknown error', 'error');
        // });

        getWorkOrderDetail({ recId: this.recordId })
        .then(result => {
            const isCheckInDateAvailable = result.Check_In_Date_Time__c != null;
            const isWorkOrderCompleted = result.Status == 'Completed';
            const isCheckOutDateAvailable = result.Check_Out_Date_Time__c != null;
            const isFollowUp = result.Follow_up_Date__c != null;
            const isRandomVisit = result.Payment_Remark__c == 'Random Payment';
        
            if(isRandomVisit){
                this.showEnableMessage = true;
                this.message = 'Random visit case, this task is not allowed.';
            }

            if(this.isGoCollect){
                if (isCheckInDateAvailable && isWorkOrderCompleted && isCheckOutDateAvailable) {
                    this.showEnableMessage = true;
                    this.message = 'Task is already completed. Please refresh the WorkOrder page to continue.';
                } else if ((!isCheckInDateAvailable && !isFollowUp)) {
                    this.showEnableMessage = true;
                    this.message = 'Check-In is required. Please Check-In and refresh the WorkOrder page to continue.';
                } else if (isFollowUp) {
                    this.showEnableMessage = false;
                    this.showToast('Warning', 'This is already a Follow-Up task. If you still want to create another follow-up then continue else go back to Home screen.', 'warning');
                    if ((!isCheckInDateAvailable && isFollowUp)) {
                        this.showEnableMessage = true;
                        this.message = 'Check-In is required. Please Check-In and refresh the WorkOrder page to continue.';
                    } else {
                        this.showEnableMessage = false;
                    }
                }
            }
            
            this.isLoading = false;
        })
        .catch(error => {
            this.isLoading = false;
            this.showToast('Error', error.body ? error.body.message : 'Unknown error', 'error');
        });
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

    @wire(getFieldSenseFollowUpReasonsFromMetadata)
    wiredFollowUpMetadata({ error, data }) {
        if (data) {
            this.followUpMetadata = data;
            this.followUpOption = data.map(record => ({
                label: record.Label,
                value: record.Label
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load follow-up metadata', 'error');
        }
    }

    handleDateChange(event) { this.followUpDate = event.detail.value; }
    handleOtherRemarksChange(event) { this.otherFollowUpRemarks = event.detail.value; }

  

    handleRemarksChange(event) {
        this.followUpRemarks = event.detail.value;
        this.showOtherRemark = (this.followUpRemarks === 'Claim Paid' || this.followUpRemarks === 'Miscellaneous');
        const selectedValue = this.followUpRemarks?.toLowerCase();
        const selectedMetadata = this.followUpMetadata?.find(meta => meta.Label?.toLowerCase() === selectedValue);
        if (selectedMetadata) {
            const imageRequired = selectedMetadata.Image_Required__c;
            const imageCount = selectedMetadata.Image_count__c;
            this.isFollowUpRequired = selectedMetadata.Follow_Up_Required__c;
            if (imageRequired) {
                this.noOfPhotos = imageCount;
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
            this.doorLocked = false;
            this.noOfPhotos = 0;
            this.photoUploadSlots = [];
            this.imageOptional = false;
            this.isFollowUpRequired = false;
        }
    }

    /** Save Follow-up (offline + online hybrid) */
    async handleSave() {
        if (!this.followUpRemarks) {
            this.showToast('Error', 'Please enter the remarks.', 'error');
            return;
        }
        if (this.isFollowUpRequired && !this.followUpDate) {
            this.showToast('Error', 'Please enter follow-up date.', 'error');
            return;
        }

        if(!this.isGoCollect && FORM_FACTOR !== 'Large'){
            if (this.doorLocked) {
                const allFilesSelected = this.photoUploadSlots.length === this.noOfPhotos &&
                    this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

                if (this.doorLocked && !allFilesSelected && !this.imageOptional) {
                    this.showToast('Warning', 'Please capture the photos', 'warning');
                    return;
                }

                this.getMobileLocation();
            }
        }else{
            this.saveData();
        }
    }

    saveData(){
        
        let payload = {
            parentRecordId: this.recordId,
            followUpDate: this.followUpDate,
            followUpRemarks: this.followUpRemarks,
            otherRemark: this.otherFollowUpRemarks,
            hasImages: this.doorLocked,
            base64Images: []
        };

        if (this.doorLocked) {
            const allFilesSelected = this.photoUploadSlots.length === this.noOfPhotos &&
                this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

            const selectedMetadata = this.followUpMetadata.find(item => item.Label === this.followUpRemarks);

            const smsRequired = selectedMetadata?.SMS_requried__c || false;

            if (this.doorLocked && !allFilesSelected && !this.imageOptional) {
                this.showToast('Warning', 'Please capture the photos', 'warning');
                return;
            }

            payload.base64Images = this.photoUploadSlots.map(slot => slot.base64Data);
            payload.smsRequired = smsRequired; 
        }

        // Offline handling
        if (!navigator.onLine) {
            this.queueFollowUp(payload);
            this.showToast('Offline', 'Follow-up saved locally and will sync when online.', 'info');
            return;
        }else{
            this.saveFollowUpOnline(payload);
        }
    }

    async saveFollowUpOnline(payload) {
        
        const isWithImages = payload.hasImages;
        try {
            let result;
            if (isWithImages) {
                result = await createFollowUpWithImages(payload);
            } else {
                result = await createFollowUp(payload);
            }
            if (result?.success) {
                this.showToast('Success', result.message, 'success');
                if (result.message === 'Work Order updated.') {
                    //if (!this.isGoCollect) this.followUpScreen = false;
                    //else 
                    history.back();
                } else {
                    this.navigateToWorkOrderInFSL(this.recordId);
                }
            } else {
                this.showToast('Error', result?.message || 'Unknown error', 'error');
            }
        } catch (error) {
            console.error('Save online failed', error);
            this.showToast('Error', error.body?.message || 'Save failed', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /** =============== Offline Sync Management =============== */
    queueFollowUp(data) {
        try {
            let queue = JSON.parse(localStorage.getItem('FollowUpQueue') || '[]');
            queue.push(data);
            localStorage.setItem('FollowUpQueue', JSON.stringify(queue));
        } catch (e) {
            console.error('Queue save failed', e);
        }
    }

    async trySyncQueuedFollowUps() {
        if (!navigator.onLine) return;
        let queue = JSON.parse(localStorage.getItem('FollowUpQueue') || '[]');
        if (queue.length === 0) return;

        this.isLoading = true;
        let successCount = 0;
        let failedQueue = [];

        for (let record of queue) {
            try {
                await this.saveFollowUpOnline(record);
                successCount++;
            } catch (err) {
                console.warn('Sync failed for record', err);
                failedQueue.push(record);
            }
        }

        localStorage.setItem('FollowUpQueue', JSON.stringify(failedQueue));
        this.isLoading = false;
        if (successCount > 0)
            this.showToast('Info', `Synced ${successCount} pending follow-up(s).`, 'success');
    }

    registerOnlineListener() {
        window.addEventListener('online', () => {
            console.log('Connection restored — syncing offline follow-ups...');
            this.trySyncQueuedFollowUps();
        });
    }

    /** ========================================================== */

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    navigateToWorkOrderInFSL(workOrderId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: `com.salesforce.fieldservice://v1/sObject/${workOrderId}/overview` }
        });
    }

    // Image handling (unchanged)
    // async handleFile(event) {
    //     let newSlots = event.detail.steps;

    //     for (let i = 0; i < newSlots.length; i++) {
    //         let slot = newSlots[i];
    //         if (slot.base64Data) {
    //             try {
    //                 const fullBase64 = slot.base64Data.startsWith('data:image')
    //                     ? slot.base64Data
    //                     : `data:image/jpeg;base64,${slot.base64Data}`;
    //                 const blob = this.base64ToBlob(fullBase64);
    //                 const imageUrl = URL.createObjectURL(blob);
    //                 const compressedBlob = await this.compressImageFromURL(imageUrl);
    //                 const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
    //                 slot.base64Data = compressedBase64;
    //             } catch (error) {
    //                 console.error(`Compression failed for photo ${i + 1}:`, error);
    //             }
    //         }
    //     }
    //     this.photoUploadSlots = newSlots;
    // }

    handleFile(event) {
        //const index = event.target.dataset.index;
        const newSlots = event.detail.steps; 
        this.photoUploadSlots = newSlots;
    }

    setPhotoUploadSlots() {
        const count = this.noOfPhotos || 0;
        this.photoUploadSlots = Array.from({ length: count }, (_, i) => ({
            id: i + 1, index: i + 1, label: `Photo ${i + 1}`, name: `fileUploader${i + 1}`,
            fileName: '', uploaded: false, previewUrl: '', base64Data: ''
        }));
    }

    // async base64ToBlob(base64Data) {
    //     const byteString = atob(base64Data.split(',')[1]);
    //     const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];
    //     const ab = new ArrayBuffer(byteString.length);
    //     const ia = new Uint8Array(ab);
    //     for (let i = 0; i < byteString.length; i++) ia[i] = byteString.charCodeAt(i);
    //     return new Blob([ab], { type: mimeString });
    // }

    // async compressImageFromURL(imageUrl) {
    //     return new Promise((resolve, reject) => {
    //         const img = new Image(); img.crossOrigin = 'anonymous';
    //         img.onload = () => {
    //             const maxDim = 600; let { width, height } = img;
    //             const scale = Math.min(maxDim / width, maxDim / height, 1);
    //             width = Math.floor(width * scale); height = Math.floor(height * scale);
    //             const canvas = document.createElement('canvas');
    //             const ctx = canvas.getContext('2d', { willReadFrequently: true });
    //             canvas.width = width; canvas.height = height;
    //             ctx.fillStyle = '#ffffff'; ctx.fillRect(0, 0, width, height);
    //             ctx.drawImage(img, 0, 0, width, height);
    //             const compressedDataUrl = canvas.toDataURL('image/jpeg', 0.2);
    //             const byteString = atob(compressedDataUrl.split(',')[1]);
    //             const ab = new ArrayBuffer(byteString.length);
    //             const ia = new Uint8Array(ab);
    //             for (let i = 0; i < byteString.length; i++) ia[i] = byteString.charCodeAt(i);
    //             resolve(new Blob([ab], { type: 'image/jpeg' }));
    //         };
    //         img.onerror = () => reject(new Error('Image load failed'));
    //         img.src = imageUrl;
    //     });
    // }

    // async convertBlobToBase64(blob) {
    //     return new Promise((resolve, reject) => {
    //         const reader = new FileReader();
    //         reader.onload = () => resolve(reader.result.split(',')[1]);
    //         reader.onerror = reject;
    //         reader.readAsDataURL(blob);
    //     });
    // }

    handleCancel() { history.back(); }
    handleChildEvent(event) { this.openMainPage = true; }


    getMobileLocation() {

        this.isLoading = true;
        
        const locationService = getLocationService();

        if (!locationService || !locationService.isAvailable()) {
            this.showtoast('LocationService Not Available', 'Please use a GPS-enabled mobile device and ensure location is turned on.', 'error');
            return;
        }

        const options = {
            enableHighAccuracy: true
        };

        locationService.getCurrentPosition(options)
        .then(result => {
        
            this.lat = result.coords.latitude;
            this.long = result.coords.longitude;

            updateGeoLocation({ workOrderId: this.recordId, latitude: this.lat, longitude: this.long})
            .then(result => {
                this.saveData();
            })
            .catch(error => {
                this.showtoast('Error', error, 'Error');
            })

        }).catch(error => {
            console.error('Location error:', error);
            this.showtoast('Warning', 'Please enable your device location.', 'Warning');
        }).finally(() => {
            
        });
    }
}