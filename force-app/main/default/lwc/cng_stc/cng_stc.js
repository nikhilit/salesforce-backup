import { LightningElement, track,api} from 'lwc';
import saveCompliance from '@salesforce/apex/CNG_ProfileCardController.saveSTCompliance';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Cng_roComplianceForm extends LightningElement {

    @track stcName;
    @track stcNumber;
    @track startDate;
    @track expiryDate;
    @api recordId;
@track isModalOpen = false;
openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        this.resetForm();
    }
    handleChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    uploadedFileId;

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;

        if (uploadedFiles.length > 0) {
            this.uploadedFileId = uploadedFiles[0].documentId;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'File uploaded successfully',
                    variant: 'success'
                })
            );
        }
    }
    handleSubmit() {
        if (!this.stcName || !this.startDate || !this.expiryDate || !this.uploadedFileId || !this.stcNumber) {
            this.showToast('Error', 'All fields are mandatory', 'error');
            return;
        }

        saveCompliance({
            stcName: this.stcName,
            stcNumber: this.stcNumber,
            startDate: this.startDate,
            expiryDate: this.expiryDate,
            uploadedFileId: this.uploadedFileId,
            stationId:this.recordId
        })
        .then(() => {
            this.showToast('Success', 'Compliance record created', 'success');
            window.location.reload();
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

    resetForm() {
        this.stcNumber = null;
        this.stcName=null;
        this.startDate = null;
        this.expiryDate = null;
        this.uploadedFileId=null;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}