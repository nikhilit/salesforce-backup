import { LightningElement, api, track, wire } from 'lwc';
import { updateRecord, createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import WORKORDER_OUTSTANDING from '@salesforce/schema/WorkOrder.Outstanding_Amount__c';
import WORKORDER_REMARKS from '@salesforce/schema/WorkOrder.Remarks__c';


import ID_FIELD from '@salesforce/schema/WorkStep.Id';
import STATUS_FIELD from '@salesforce/schema/WorkStep.Status';
import IF_BILL_PAID from '@salesforce/schema/ServiceAppointment.If_bill_paid__c';
import BILL_PAID_TEXT from '@salesforce/schema/ServiceAppointment.Bill_Paid__c';
import TYPE_OF_WORK from '@salesforce/schema/WorkOrder.Type_Of_Work__c';


import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getListUi } from 'lightning/uiListApi';
import SERVICE_APPOINTMENT_OBJECT from '@salesforce/schema/ServiceAppointment';
// import SA_ID_FIELD from '@salesforce/schema/ServiceAppointment.Id';
import { getRecord } from 'lightning/uiRecordApi';


import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class MeterExecution extends NavigationMixin(LightningElement) {
    @api recordId;

    @track workStepId = '';

   @track billPaid = '';
   @track billPaidText = '';

    @track billPaidOptions = [];
    @track outstandingAmount = '';
    @track typeSelection = '';
    @track reasonOtherRemark = '';
    @track reasonOptions = [];
    @track showReasonPicklist = false;
    @track serviceAppointmentId ;

    
    @track showPreviewModal = false;
@track previewUrl = '';
@track previewFileName = '';

    noOfPhotosBeforeWork = 3;
    noOfPhotosAfterWork = 3;
    noOfPhotosMeterWork = 3;
    noOfPhotosAddPhotos = 3;
   

    @track photoUploadSlotsBeforeWork = [];
    @track photoUploadSlotsAfterWork = [];
    @track photoUploadSlotsMeterWork = [];
    @track photoUploadSlotsAddPhotos = [];

    

  /* Type / Reason lists (as requested) */
    typeOptions = [
        { label: 'Disconnection', value: 'Disconnection' },
        { label: 'Reconnection', value: 'Reconnection' }
    ];

    disconnectionReasons = [
        'Visited and disconnection done',
        'On-the-spot bill paid',
        'Already bill paid',
        'Society not allowed',
        'Customer not allowed',
        'Technically disconnection not possible',
        'Disconnection not possible- Line inside duct',
        'Disconnection not possible -Line inside Grill',
        'WAH not possible- Metal sheet',
        'WAH not possible- No permanent structure',
        'WAH not possible- Solar panel on terrace',
        'WAH not possible-Personal terrace on top floor and flat is lock',
        'Disconnection not possible-Building in Dilapidated condition',
        'Disconnection not possible-Scaffolding',
        'Disconnection not possible-Honey comb available',
        'Disconnection not possible-no space for cutting',
        'Disconnection not possible-riser covered by net',
        'Disconnection not possible-RIV not accessible',
        'Payment done but not reflecting in system',
        'Connection already disconnected earlier',
        'Address issue',
        'Building already demolished',
        'Not to disconnect – Amount less than 6000',
        'On Hold as per R&T mail',
        'Resolved as per R&T',
        'Bill paid to collection person',
        'Meter number and BP number mismatch',
        'No connection found',
        'Not allowed – Even after final letter',
        'RTP / WIP',
        'Terrace key not available / WIP',
        'Society taken time / WIP'
    ];

    reconnectionReasons = [
        'Reconnection done',
        'House found locked',
        'Customer not reachable / did not respond to calls',
        'Customer will call later',
        'Customer cancelled the request',
        'Already reconnected',
        'Address not found',
        'Installation unsafe for reconnection',
        'AFS work required'
    ];

   

    connectedCallback() {
        this.initSlots();
        // this.loadBillPaidPicklist();
    }

    initSlots() {
        this.photoUploadSlotsBeforeWork = this.createSlots(this.noOfPhotosBeforeWork, 'Before Work');
        this.photoUploadSlotsAfterWork = this.createSlots(this.noOfPhotosAfterWork, 'After Work');
        this.photoUploadSlotsMeterWork = this.createSlots(this.noOfPhotosMeterWork, 'Meter Counter');
        this.photoUploadSlotsAddPhotos = this.createSlots(this.noOfPhotosAddPhotos, 'Add Photos');
       
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkSteps',
        fields: ['WorkStep.Id', 'WorkStep.Name', 'WorkStep.Status']
    })
    wiredWorkStep({ data, error }) {
        if (data) {
            const step = data.records.find(r => r.fields.Name.value === 'Data Capture');
            if (step) {
                this.workStepId = step.id;
            }
        }
    }

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: IF_BILL_PAID })
wiredBillPaid({ data, error }) {
    if (data) {
        this.billPaidOptions = data.values.map(v => ({
            label: v.label,
            value: v.value
        }));
    } else if (error) {
        console.warn('Bill Paid picklist load failed', error);
    }
}

// @wire(getRecord, { recordId: '$recordId', fields: [SA_ID] })
// wiredWO({ data, error }) {
//     if (data) {
//         this.serviceAppointmentId = data.fields.ServiceAppointmentId.value;
//     }
// }
@wire(getRecord, { recordId: '$recordId', fields: [TYPE_OF_WORK] })
wiredWorkOrder({data, error}) {
    if (data) {
        this.typeSelection = data.fields.Type_Of_Work__c.value;
        console.log('Fetched Type Of Work:', this.typeSelection);

        // Auto set reason options based on Type
        if (this.typeSelection === 'Disconnection') {
            this.reasonOptions = this.disconnectionReasons.map(r => ({ label: r, value: r }));
        } else if (this.typeSelection === 'Reconnection') {
            this.reasonOptions = this.reconnectionReasons.map(r => ({ label: r, value: r }));
        }

        this.showReasonPicklist = true;
    }
    if (error) {
        console.error('Error fetching Type_Of_Work__c:', error);
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

async updateServiceAppointment() {
    if (!this.serviceAppointmentId) return;

    const fields = {};
    fields['Id'] = this.serviceAppointmentId;
    fields[IF_BILL_PAID.fieldApiName] = this.billPaid;
    fields[BILL_PAID_TEXT.fieldApiName] = this.billPaidText;

    return updateRecord({ fields });
}


//  async loadBillPaidPicklist() {
//         try {
//             const res = await getBillPaidPicklistValues();
//             this.billPaidOptions = res.map(v => ({ label: v, value: v }));
//         } catch (e) {
//             console.warn('Could not load If Bill Paid picklist (offline?)', e);
//             this.billPaidOptions = []; // fallback empty
//         }
//     }

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

    async handleFileBeforeWork(e) { this.photoUploadSlotsBeforeWork = await this.processImageUpload(e.detail.steps); }
    async handleFileAfterWork(e) { this.photoUploadSlotsAfterWork = await this.processImageUpload(e.detail.steps); }
    async handleFileMeterWork(e) { this.photoUploadSlotsMeterWork = await this.processImageUpload(e.detail.steps); }
    async handleFileAddPhotos(e) { this.photoUploadSlotsAddPhotos = await this.processImageUpload(e.detail.steps); }
   

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

    handleBillPaidTextChange(e) {
    this.billPaidText = e.target.value;
}

     handleBillPaidChange(e) { this.billPaid = e.detail.value; }
    handleOutstandingAmountChange(e) { this.outstandingAmount = e.detail.value; }

    // handleTypeChange(e) {
    //     this.typeSelection = e.detail.value;
    //     this.showReasonPicklist = true;
    //     if (this.typeSelection === 'Disconnection') {
    //         this.reasonOptions = this.disconnectionReasons.map(r => ({ label: r, value: r }));
    //     } else {
    //         this.reasonOptions = this.reconnectionReasons.map(r => ({ label: r, value: r }));
    //     }
    //     this.reasonOtherRemark = '';
    // }

    handleReasonPicklistChange(e) {
        this.reasonOtherRemark = e.detail.value;
    }


    async handleSubmit() {
        try {
            // 1) Update WorkOrder fields (Outstanding + Remarks)
            await this.updateWorkOrderFields();

            await this.updateServiceAppointment();


            // 3) Upload files via createRecord(ContentVersion) — these are queued when offline
            await this.uploadAllPhotos();

            // 4) Update WorkStep status to Completed (if available)
            await this.updateWorkStepDataCapture();

            this.showToast('Saved successfully', 'success');
            this.handleCancel();

            // navigate back or close as you prefer
            // history.back();
        } catch (err) {
            console.error('Submit failed', err);
            this.showToast(this.getError(err), 'error');
        }
    }


   async updateWorkOrderFields() {
        const fields = {};
        fields['Id'] = this.recordId;
        if (this.outstandingAmount !== '') fields[WORKORDER_OUTSTANDING.fieldApiName] = this.outstandingAmount;
        if (this.reasonOtherRemark) fields[WORKORDER_REMARKS.fieldApiName] = this.reasonOtherRemark;

        const recordInput = { fields };
        return updateRecord(recordInput);
    }

    handleDelete(event) {
    const label = event.currentTarget.dataset.label;
    const index = event.currentTarget.dataset.index;

    let list;
    switch (label) {
        case 'Before Work': list = [...this.photoUploadSlotsBeforeWork]; break;
        case 'After Work': list = [...this.photoUploadSlotsAfterWork]; break;
        case 'Meter Counter': list = [...this.photoUploadSlotsMeterWork]; break;
        case 'Add Photos': list = [...this.photoUploadSlotsAddPhotos]; break;
    }

    list[index - 1].uploaded = false;
    list[index - 1].fileName = '';
    list[index - 1].previewUrl = '';
    list[index - 1].base64Data = null;

    if (label === 'Before Work') this.photoUploadSlotsBeforeWork = list;
    if (label === 'After Work') this.photoUploadSlotsAfterWork = list;
    if (label === 'Meter Counter') this.photoUploadSlotsMeterWork = list;
    if (label === 'Add Photos') this.photoUploadSlotsAddPhotos = list;
}


    async uploadAllPhotos() {
        const allSlots = [
            ...this.photoUploadSlotsBeforeWork,
            ...this.photoUploadSlotsAfterWork,
             ...this.photoUploadSlotsAddPhotos,
            ...this.photoUploadSlotsMeterWork,
           
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
        case 'Before Work':
            targetSlots = this.photoUploadSlotsBeforeWork;
            break;
        case 'After Work':
            targetSlots = this.photoUploadSlotsAfterWork;
            break;
        case 'Add Photos':
            targetSlots = this.photoUploadSlotsAddPhotos;
            break;   
        case 'Meter Counter':
            targetSlots = this.photoUploadSlotsMeterWork;
            break;
        default:
            return;
    }

    // LIMIT: Only 1 photo for these specific sections
    const singleUploadSections = ['Before Work', 'After Work', 'Meter Counter'];
    if (singleUploadSections.includes(label)) {
        if (files.length > 1) {
            this.showToast('Only 1 photo allowed', 'warning');
            return;
        }
        // If one already uploaded → replace it
        targetSlots.forEach(s => {
            s.uploaded = false;
            s.fileName = '';
            s.previewUrl = '';
            s.base64Data = null;
        });
    }

    let slotIndex = 0;

    for (let file of files) {
        if (slotIndex >= targetSlots.length) break;

        const base64 = await this.readFileAsBase64(file);

        targetSlots[slotIndex].fileName = file.name;
        targetSlots[slotIndex].base64Data = base64;
        targetSlots[slotIndex].uploaded = true;
        targetSlots[slotIndex].previewUrl = base64;

        slotIndex++;
    }

    // Reassign tracked values so UI refreshes
    if (label === 'Before Work') this.photoUploadSlotsBeforeWork = [...targetSlots];
    if (label === 'After Work') this.photoUploadSlotsAfterWork = [...targetSlots];
    if (label === 'Meter Counter') this.photoUploadSlotsMeterWork = [...targetSlots];
    if (label === 'Add Photos') this.photoUploadSlotsAddPhotos = [...targetSlots];
 
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