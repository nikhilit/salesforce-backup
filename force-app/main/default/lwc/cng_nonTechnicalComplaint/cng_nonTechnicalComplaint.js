import { LightningElement, track ,wire,api} from 'lwc';
import createComplaint from '@salesforce/apex/CNG_ProfileCardController.createComplaint';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Cng_nonTechnicalComplaint extends LightningElement {

    @track description;
    @track category;
    @track subCategory;
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

    categorySubCategoryMap = {
        'Washroom Related': [
            { label: 'Plumbing issues', value: 'Plumbing issues' },
            { label: 'No Water', value: 'No Water' },
            { label: 'Water Purifier Issues', value: 'Water Purifier Issues' },
            { label: 'Drinking Water Issues', value: 'Drinking Water Issues' },
            { label: 'Light non functional', value: 'Light non functional' },
            { label: 'Door latch broken', value: 'Door latch broken' }
        ],
        'Forecourt Related': [
            { label: 'Bollard Broken', value: 'Bollard Broken' },
            { label: 'Bollard Painting', value: 'Bollard Painting' },
            { label: 'Pedestal Damaged', value: 'Pedestal Damaged' },
            { label: 'Boundary Wall Broken', value: 'Boundary Wall Broken' },
            { label: 'Boundary Wall Painting', value: 'Boundary Wall Painting' }
        ],
        'Sales Office': [
            { label: 'AC Issue', value: 'AC Issue' },
            { label: 'Chair/Table Repair', value: 'Chair/Table Repair' },
            { label: 'Electrical Issue', value: 'Electrical Issue' }
        ]
    };

    get categoryOptions() {
        return [
            { label: 'Washroom Related', value: 'Washroom Related' },
            { label: 'Forecourt Related', value: 'Forecourt Related' },
            { label: 'Sales Office', value: 'Sales Office' }
        ];
    }

    get subCategoryOptions() {
        return this.category
            ? this.categorySubCategoryMap[this.category]
            : [];
    }

    get isSubCategoryDisabled() {
        return !this.category;
    }

    handleCategoryChange(event) {
        this.category = event.detail.value;
        this.subCategory = null;
    }

    handleSubCategoryChange(event) {
        this.subCategory = event.detail.value;
    }




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
        if (!this.description || !this.category || !this.subCategory || !this.uploadedFileId) {
            this.showToast('Error', 'All fields are mandatory', 'error');
            return;
        }

        createComplaint({
            subCategory: this.subCategory,
            category: this.category,
            description: this.description,
            uploadedFileId: this.uploadedFileId,
            stationId:this.recordId
        })
        .then(() => {
            this.showToast('Success', 'Complaint record created', 'success');
            window.location.reload();

        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

    resetForm() {
        this.description = null;
        this.category = null;
        this.subCategory = null;
        this.uploadedFileId = null;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}