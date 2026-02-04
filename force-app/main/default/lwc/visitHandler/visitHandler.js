import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord, getRecordUi, getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import Comments from '@salesforce/schema/WorkOrder.Comments__c';
import Follow_up_Date from '@salesforce/schema/WorkOrder.Follow_Up_Appointment_Date__c';
import Follow_up_Remarks from '@salesforce/schema/WorkOrder.Follow_up_Remarks__c';
import Reason_for_Unavailability from '@salesforce/schema/WorkOrder.Reason_for_Unavailability__c';

import updateVisitInfo from '@salesforce/apex/WorkOrderVisitController.updateVisitInfo';
import uploadImage from '@salesforce/apex/WorkOrderVisitController.uploadImage';

import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';

const FIELDS = [
    Comments,
    Reason_for_Unavailability,
    Follow_up_Date,
    Follow_up_Remarks,
]
export default class VisitHandler extends NavigationMixin(LightningElement) {
    @api recordId;

    @track selectedReason = '';
    @track showComments = false;
    @track comments = '';
    @track followUpDate = '';
    @track followUpRemarks = '';
    wiredResult;

    @track images = [];
    acceptedFormats = ['image/jpeg', 'image/png', 'image/jpg'];

    reasonOptions = [
        { label: 'Customer Not Available', value: 'Customer Not Available' },
        { label: 'Access Denied', value: 'Access Denied' },
        { label: 'Equipment Malfunction', value: 'Equipment Malfunction' },
        { label: 'Premises Locked', value: 'Premises Locked' },
        { label: 'Other', value: 'Other' }
    ];

    handleReasonChange(event) {
        this.selectedReason = event.detail.value;
        this.showComments = this.selectedReason === 'Other';
    }

    handleCommentsChange(event) {
        this.comments = event.detail.value;
    }

    handleRemarkChange(event) {
        this.followUpRemarks = event.detail.value;
    }
    
    handleFollowUpChange(event) {
        this.followUpDate = event.detail.value;
    }

    handleImageUpload(event) {
        const files = event.target.files;
        if (files.length === 0 || !this.recordId) return;

        Array.from(files).forEach(file => {
            // if (!acceptedFormats.includes(file.type)) {
            //     this.showToast('Unsupported Format', `${file.name} is not a supported image type.`, 'error');
            //     return;
            // }
            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];

                uploadImage({ fileName: file.name, base64Data: base64, recordId: this.recordId })
                    .then(() => {
                        const newImage = {
                            fileName: file.name,
                            previewUrl: reader.result
                        };
                        this.images = [...this.images, newImage];

                        this.showToast('Success', `${file.name} uploaded`, 'success');
                    })
                    .catch(error => {
                        console.error('Upload failed:', error);
                        this.showToast('Error', `Failed to upload ${file.name}`, 'error');
                    });
            };
            reader.readAsDataURL(file);
        });
    }

    removeImage(event) {
        const index = Number(event.target.dataset.index);
        this.images = this.images.filter((_, i) => i !== index);
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.selectedReason = data.fields.Reason_for_Unavailability__c.value;
            this.comments = data.fields.Comments__c.value;           
            this.followUpDate = data.fields.Follow_Up_Appointment_Date__c.value;    
            this.followUpRemarks = data.fields.Follow_up_Remarks__c.value;  
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
            console.error('Wire error:', JSON.stringify(error, null, 2));
        }
    }

    handleSave() {
        this.storeLocally({ 
            workOrderId: this.recordId,
            comments: this.comments,
            followUpDate: this.followUpDate,
            followUpRemarks: this.followUpRemarks,
            reason: this.selectedReason });
        
        updateVisitInfo({
            workOrderId: this.recordId,
            comments: this.comments,
            followUpDate: this.followUpDate,
            followUpRemarks: this.followUpRemarks,
            reason: this.selectedReason
        }).then(() => {
            this.showToast('Success', 'Visit info recorded.', 'success');
                // this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                console.error(error);
            }).finally(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    storeLocally(dataObj) {
        try {
            if (typeof localStorage !== 'undefined') {
                const localData = JSON.parse(localStorage.getItem('saCheckinData')) || {};
                localData[this.recordId] = {
                    ...localData[this.recordId],
                    ...dataObj
                };
                localStorage.setItem('saCheckinData', JSON.stringify(localData));
            }
        } catch (e) {
            console.warn('localStorage not available in this environment', e);
        }
    }
    
    getStoredValue(key) {
        try {
            const localData = JSON.parse(localStorage.getItem('saCheckinData')) || {};
            const saData = localData[this.recordId] || {};
            return saData[key];
        } catch (e) {
            console.warn('localStorage not available in this environment', e);
            return null;
        }
    }

    handleRefresh() {
        if (this.wiredResult) {
            refreshApex(this.wiredResult);
        }
    }

    connectedCallback() {
        this.handleRefresh();
        this.recordId = this.getStoredValue('workOrderId') || this.recordId,
        this.comments = this.getStoredValue('comments') || this.comments,
        this.followUpDate = this.getStoredValue('followUpDate') || this.followUpDate,
        this.followUpRemarks = this.getStoredValue('followUpRemarks') || this.followUpRemarks,
        this.selectedReason = this.getStoredValue('selectedReason') || this.selectedReason
        
        this.showComments = this.selectedReason === 'Other';
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}