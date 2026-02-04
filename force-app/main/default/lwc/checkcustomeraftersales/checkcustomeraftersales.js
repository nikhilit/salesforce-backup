import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Parent Apex
import updateWorkOrder from '@salesforce/apex/CheckCustomerAfterSalesController.updateWorkOrder';
import checkWorkStepCheckin from '@salesforce/apex/CheckCustomerAfterSalesController.checkWorkStepCheckin';
import getWOrderWType from '@salesforce/apex/CheckCustomerAfterSalesController.getWOrderWType';

// Child Apex
import submitUnsuccessfulVisit from '@salesforce/apex/CheckCustomerAfterSalesController.submitUnsuccessfulVisit';

export default class Checkcustomeraftersales extends LightningElement {

    /* ------------------- COMMON ------------------- */
    @api recordId;
    @track load = false;

    /* ------------------- PARENT STATE ------------------- */
    @track showCustomerAvailability = true;
    @track customerAvailability = '';
    @track customerAvilable = false;
    @track showCheckBox = true;
    @track customerNotAvailableDetails = false;

    @track wOWorkType = '';
    @track showIPDEntry = false;
    @track showAfterSalesEntry = false;
    @track showMeterReplacementEntry = false;

    /* ------------------- CHILD STATE ------------------- */
    @track selectedReason = '';
    @track notes = '';
    @track selectedDateTime;
    @track showRemarks = false;
    @track showFollowUpDate = false;
    @track imageUploadPage = false;
    @track photoUploadSlots = [];

    @track showPreviewModal = false;
    @track previewUrl = '';
    @track previewFileName = '';
    @track isPreviewImage = false;
    @track isPreviewPdf = false;

    /* ------------------- OPTIONS ------------------- */
    get availabilityOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }

    reasonOptions = [
        { label: 'House Lock', value: 'House Lock' },
        { label: 'Customer Not Available', value: 'Customer Not Available' },
        { label: 'Customer Not Interested', value: 'Customer Not Interested' },
        { label: 'Customer Asked to Reschedule', value: 'Customer Asked to Reschedule' },
        { label: 'Customer Did Not Respond to Calls', value: 'Customer Did Not Respond to Calls' },
        { label: 'Wrong or Incomplete Address', value: 'Wrong or Incomplete Address' },
        { label: 'Access Not Provided by Security or Society', value: 'Access Not Provided by Security or Society' },
        { label: 'Customer Refused Work', value: 'Customer Refused Work' },
        { label: 'Documentation Not Ready', value: 'Documentation Not Ready' },
        { label: 'Payment Not Ready', value: 'Payment Not Ready' },
        { label: 'Meter Location Not Accessible', value: 'Meter Location Not Accessible' },
        { label: 'Safety Issue at Site', value: 'Safety Issue at Site' },
        { label: 'No Permission for Work from Society or Building', value: 'No Permission for Work from Society or Building' },
        { label: 'Others', value: 'Others' }
    ];

    remarkRequiredReasons = [
        'Others',
        'Customer Not Available',
        'Customer Not Interested',
        'Customer Asked to Reschedule',
        'Customer Did Not Respond to Calls',
        'Wrong or Incomplete Address',
        'Access Not Provided by Security or Society',
        'Customer Refused Work',
        'Documentation Not Ready',
        'Payment Not Ready',
        'Meter Location Not Accessible',
        'Safety Issue at Site',
        'No Permission for Work from Society or Building'
    ];

    /* ------------------- INIT ------------------- */
    connectedCallback() {
    if (!this.recordId) {
        console.warn('recordId not available yet');
        return;
    }
    this.init();
}

init() {
    this.checkWorkStep();
    this.fetchWorkType();
}


    checkWorkStep() {
        checkWorkStepCheckin({ recordId: this.recordId })
            .then(res => {
                if (res !== 'Completed') {
                    this.showToast('Warning', 'Please Complete Check-in Task', 'warning');
                    this.showCheckBox = false;
                    this.showCustomerAvailability = false;
                    this.customerNotAvailableDetails = false;
                    this.handleCancel();
                }
            });
    }

    fetchWorkType() {
        getWOrderWType({ recordId: this.recordId })
            .then(res => {
                this.wOWorkType = res;
            });
    }

    /* ------------------- CUSTOMER AVAILABILITY ------------------- */
    handleAvailabilityChange(event) {
        this.customerAvailability = event.detail.value;

        if (this.customerAvailability === 'Yes') {
            this.customerAvilable = true;
            this.customerNotAvailableDetails = false;
            
           this.handleCusAvilSave();
        } else {
            this.customerAvilable = false;
            this.showCheckBox = false;
            this.customerNotAvailableDetails = true;
            this.showAfterSalesEntry = true; // After Sales logic stays same
        }
    }

    handleCusAvilSave() {
        this.load = true;
        updateWorkOrder({
            recordId: this.recordId,
            customerAvailability: this.customerAvailability
        })
        .then(() => {
            this.showToast('Success', 'Details saved successfully!', 'success');
            //this.handleCancel();
        })
        .finally(() => this.load = false);
    }

    /* ------------------- UNSUCCESSFUL VISIT ------------------- */
    handleReasonChange(event) {
        this.selectedReason = event.detail.value;
        this.showRemarks = this.remarkRequiredReasons.includes(this.selectedReason);
        this.imageUploadPage = true;
        this.showFollowUpDate = (this.selectedReason === 'House Lock');
    }

    handleNotesChange(event) {
        this.notes = event.target.value;
    }

    handleDateTimeChange(event) {
        const selected = new Date(event.target.value);
        const today = new Date();
        today.setHours(0,0,0,0);

        if (selected < today) {
            this.showToast('Warning', 'Please Select Correct Date', 'warning');
            this.selectedDateTime = null;
            event.target.value = '';
        } else {
            this.selectedDateTime = event.target.value;
        }
    }

    /* ------------------- FILE UPLOAD ------------------- */
    triggerFileUpload() {
        this.template.querySelector('input[type="file"]').click();
    }

    // async handleFilesInputChange(event) {
    //     const files = [...event.target.files];
    //     for (let file of files) {
    //         const base64 = await this.convertToBase64(file);
    //         this.photoUploadSlots = [
    //             ...this.photoUploadSlots,
    //             {
                    
    //                 fileName: file.name,
    //                 base64Data: base64,
    //                 previewUrl: URL.createObjectURL(file)
    //             }
    //         ];
    //     }
    // }

    async handleFilesInputChange(event) {
    const files = [...event.target.files];

    if (!this.selectedReason) {
        this.showToast('Warning', 'Please select Reason before uploading photo.', 'warning');
        return;
    }

    for (let file of files) {

        const base64 = await this.convertToBase64(file);

        // Extract extension
        const extension = file.name.includes('.')
            ? file.name.substring(file.name.lastIndexOf('.'))
            : '';

        // Safe reason name (remove special characters)
        const safeReason = this.selectedReason.replace(/[^a-zA-Z0-9 ]/g, '').replace(/\s+/g, '_');

        // Timestamp for uniqueness
        const now = new Date();
        const timestamp =
            now.getFullYear().toString() +
            String(now.getMonth() + 1).padStart(2, '0') +
            String(now.getDate()).padStart(2, '0') + '_' +
            String(now.getHours()).padStart(2, '0') +
            String(now.getMinutes()).padStart(2, '0') +
            String(now.getSeconds()).padStart(2, '0');

        // Final filename
        //const finalFileName = `${safeReason}_${timestamp}${extension}`;
        const finalFileName = `${safeReason}${extension}`;

        this.photoUploadSlots = [
            ...this.photoUploadSlots,
            {
                fileName: finalFileName,
                base64Data: base64,
                previewUrl: URL.createObjectURL(file)
            }
        ];
    }

    // Reset file input so same file can be reselected
    event.target.value = null;
}


    convertToBase64(file) {
        return new Promise(resolve => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.readAsDataURL(file);
        });
    }


    /* ------------------- PREVIEW ------------------- */
handlePreview(event) {
    const index = event.currentTarget.dataset.index;
    const file = this.photoUploadSlots[index];

    this.previewUrl = file.previewUrl;
    this.previewFileName = file.fileName;

    const lowerName = file.fileName.toLowerCase();
    this.isPreviewImage = lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg') || lowerName.endsWith('.png');
    this.isPreviewPdf = lowerName.endsWith('.pdf');

    this.showPreviewModal = true;
}

closePreview() {
    this.showPreviewModal = false;
    this.previewUrl = '';
    this.previewFileName = '';
    this.isPreviewImage = false;
    this.isPreviewPdf = false;
}

/* ------------------- DELETE ------------------- */
handleDelete(event) {
    const index = event.currentTarget.dataset.index;

    this.photoUploadSlots = this.photoUploadSlots.filter(
        (item, i) => i !== Number(index)
    );
}


    /* ------------------- SUBMIT ------------------- */
    handleSubmit() {
        this.load = true;

        if (!this.selectedReason) {
            this.showToast('Warning', 'Please Select Reason.', 'warning');
            this.load = false;
            return;
        }

        if (this.showFollowUpDate && !this.selectedDateTime) {
            this.showToast('Warning', 'Please Select Follow-up Date.', 'warning');
            this.load = false;
            return;
        }

        if (this.showRemarks && !this.notes) {
            this.showToast('Warning', 'Please Enter Remark.', 'warning');
            this.load = false;
            return;
        }

        if (!this.photoUploadSlots.length) {
            this.showToast('Warning', 'Please capture at least one photo.', 'warning');
            this.load = false;
            return;
        }

        submitUnsuccessfulVisit({
            workOrderId: this.recordId,
            reason: this.selectedReason,
            notes: this.notes,
            followUpDate: this.selectedDateTime,
            listFiles: this.photoUploadSlots
        })
        .then(() => {
            this.showToast('Success', 'Details Saved Successfully.', 'success');
            this.handleCancel();
        })
        .finally(() => this.load = false);
    }

    handleCancel() {
        setTimeout(() => history.back(), 1000);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}