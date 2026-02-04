import { LightningElement, track ,wire,api} from 'lwc';
import saveCompliance from '@salesforce/apex/CNG_ProfileCardController.saveCompliance';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import DOCUMENT_NAME_FIELD from '@salesforce/schema/Compliance__c.Document_Name__c';
import COMPLIANCE_OBJECT from '@salesforce/schema/Compliance__c';

export default class Cng_roComplianceForm extends LightningElement {

    @track documentName;
    @track startDate;
    @track expiryDate;
    @api recordId;

    documentOptions = [
    ];
    @track isModalOpen = false;
openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        this.resetForm();
    }
recordTypeId;

    // 1️⃣ Get Object Info
    @wire(getObjectInfo, { objectApiName: COMPLIANCE_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.error(error);
        }
    }

    // 2️⃣ Get Picklist Values
    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: DOCUMENT_NAME_FIELD
    })
    wiredPicklist({ data, error }) {
        if (data) {
            this.documentOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error(error);
        }
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
        if (!this.documentName || !this.startDate || !this.expiryDate || !this.uploadedFileId) {
            this.showToast('Error', 'All fields are mandatory', 'error');
            return;
        }

        saveCompliance({
            documentName: this.documentName,
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
        this.documentName = null;
        this.startDate = null;
        this.expiryDate = null;
        this.uploadedFileId = null;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}