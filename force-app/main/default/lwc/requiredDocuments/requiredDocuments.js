import { LightningElement, api, track, wire } from 'lwc';
import getFilesForCase from '@salesforce/apex/CaseFileController.getFilesForCase';
import updateFiles from '@salesforce/apex/CaseFileController.updateFileFields';
import { RefreshEvent } from 'lightning/refresh';
import { getRecord } from 'lightning/uiRecordApi';
import getTypeOfDocumentOptions from '@salesforce/apex/CaseFileController.getTypeOfDocumentOptions';
import getStatusOptions from '@salesforce/apex/CaseFileController.getStatusOptions';
import getReasonOptions from '@salesforce/apex/CaseFileController.getReasonOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getDocumentOptions from '@salesforce/apex/DocumentController.getDocumentOptions';
import getDocumentCategories from '@salesforce/apex/DocumentController.getDocumentCategories';
import approveCase from '@salesforce/apex/CaseFileController.approveCase';
import validateCaseForApproval from '@salesforce/apex/CaseFileController.validateCaseForApproval';

const FIELDS = [
    'Case.Transfer_Type__c', 
    'Case.Name_Transfer_Request_Status__c',
    'Case.Reason_For_Name_Transfer_Rejection__c'
];

export default class RequiredDocuments extends LightningElement {
    @api recordId;
    
    @track nameTransferRejectionReason = '';
    @track nameTransferStatus = '';
    @track isNameTransferRejectionReasonRequired = false;
    @track nameTransferStatusOptions = [
        { label: 'None', value: '' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    @track typeOptions = [];
    @track transferType = '';
    @track statusOptions = [];
    @track reasonOptions = [];
    @track categories = [];
    
    channelName = '/event/CaseFileUploadEvent__e';
    subscription = null;

    // File related properties
    @track files = [];
    @track showSaveButton = false;
    @track isModalOpen = false;
    @track previewUrl = '';
    @track selectedStatus = '';
    @track selectedType = '';
    @track selectedRemarks = '';
    @track currentdocId = '';
    @track activeFileId = '';
    @track previewTitle = '';
    @track selectReason = '';

    // Approval related properties
    @track isApproving = false;
    @track validationError = '';
    @track rotationAngle = 0;

    // Getter for showing validation error
    get showValidationError() {
        return this.validationError !== '';
    }

    // Getter for showing rejection reason field
    get showNameTransferRejectionReason() {
        return this.nameTransferStatus === 'Rejected';
    }

    // Getter for character count
    get rejectionReasonCharacterCount() {
        return this.nameTransferRejectionReason ? this.nameTransferRejectionReason.length : 0;
    }

    // Getter for showing reason field in file modal
    get showReason() {
        return this.selectedStatus === 'Rejected';
    }

    // get iframeStyle() {
    //     return `transform: rotate(${this.rotationAngle}deg); transform-origin: center center;transition: transform 0.2s ease-in-out;`;
    // }



    get containerStyle() {
        return `
            width: 100%;
            height: 500px;
            overflow: hidden; /* Fix: Hides content that spills out, preventing scrollbars */
            position: relative; /* Fix: Ensures absolute positioning of iframe works relative to this box */
            background-color: #f3f3f3;
            border: 1px solid #dddbda;
            border-radius: 4px;
            display: flex;
            justify-content: center;
            align-items: center;
        `;
    }

    get iframeStyle() {
        // Base styles for the iframe
        let style = `
            border: none;
            transition: transform 0.3s ease-in-out, width 0.3s, height 0.3s;
            transform-origin: center center;
            transform: rotate(${this.rotationAngle}deg);
        `;

        // When rotated 90 or 270 degrees
        if (this.rotationAngle % 180 !== 0) {
            return style + `
                width: 500px; 
                height: 100%;
                /* Optional: Scale down slightly if content is cut off */
                /* transform: rotate(${this.rotationAngle}deg) scale(0.9); */ 
            `;
        }
        
        // Standard (0 or 180 degrees)
        return style + `
            width: 100%;
            height: 100%;
        `;
    }
    
    handleRotateLeft() {
        this.rotationAngle = (this.rotationAngle - 90 + 360) % 360;
    }

    handleRotateRight() {
        this.rotationAngle = (this.rotationAngle + 90) % 360;
    }

    resetRotation() {
        this.rotationAngle = 0;
    }



    connectedCallback() {
        console.log('connectedCallback');
        this.loadFiles(); 
        this.fetchStatusOptions();
        this.fetchReasonOptions();
        this.registerErrorListener();
        this.subscribeToFileUploadEvent(); 
    }

    @wire(getDocumentCategories, { transferType: '$transferType' })
    wiredCategories({ error, data }) {
        if (data) {
            this.categories = data.map(category => ({
                ...category,
                checked: false,
                options: []
            }));
            this.error = undefined;
            this.loadAllOptions();
        } else if (error) {
            this.handleError('Error loading document categories', error);
        }
    }

    handleCategorySelect(event) {
        const categoryId = event.target.dataset.id;
        const isChecked = event.target.checked;

        this.categories = this.categories.map(category => {
            if (category.Id === categoryId) {
                category.checked = isChecked;
                category.options = category.options.map(option => {
                    return { ...option, checked: isChecked };
                });
            }
            return category;
        });
    }

    handleDocumentSelect(event) {
        const documentId = event.target.value;
        const isChecked = event.target.checked;

        this.categories = this.categories.map(category => {
            let categoryModified = false;

            category.options = category.options.map(option => {
                if (option.Id === documentId) {
                    categoryModified = true;
                    return { ...option, checked: isChecked };
                }
                return option;
            });

            if (categoryModified) {
                const anyChecked = category.options.some(opt => opt.checked);
                category.checked = anyChecked;
            }

            return category;
        });
    }

    async loadAllOptions() {
        try {
            const promises = this.categories.map(async (category, index) => {
                try {
                    const options = await getDocumentOptions({ 
                        categoryDeveloperName: category.DeveloperName,
                        transferType: this.transferType 
                    });
                    this.categories[index].options = options.map(opt => ({
                        ...opt,
                        checked: false,
                        parentCategory: category.Name,
                        developerName: opt.DeveloperName,
                        isRequired: opt.Is_Required__c || false
                    }));
                } catch (err) {
                    console.error(`Error loading options for ${category.Name}`, err);
                    this.categories[index].options = [];
                }
            });

            await Promise.all(promises);
        } catch (error) {
            this.handleError('Error loading document options', error);
        } finally {
            this.isLoading = false;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCase({ data, error }) {
        if (data) {
            const newTransferType = data.fields.Transfer_Type__c?.value;
            const newNameTransferStatus = data.fields.Name_Transfer_Request_Status__c?.value;
            const newRejectionReason = data.fields.Reason_For_Name_Transfer_Rejection__c?.value;
            
            console.log('Transfer_Type__c changed to:', newTransferType);
            console.log('Name_Transfer_Request_Status__c changed to:', newNameTransferStatus);
            console.log('Reason_For_Name_Transfer_Rejection__c changed to:', newRejectionReason);

            if (this.transferType !== newTransferType) {
                this.transferType = newTransferType;
                this.fetchTypeOptions();
            }
            
            if (this.nameTransferStatus !== newNameTransferStatus) {
                this.nameTransferStatus = newNameTransferStatus;
                this.isNameTransferRejectionReasonRequired = (this.nameTransferStatus === 'Rejected');
            }
            
            if (this.nameTransferRejectionReason !== newRejectionReason) {
                this.nameTransferRejectionReason = newRejectionReason || '';
            }
        } else if (error) {
            console.error('Error in getRecord wire:', error);
        }
    }

    // SIMPLE APPROVAL HANDLER
    handleNameTransferStatusChange(event) {
        const newStatus = event.detail.value;
        this.nameTransferStatus = newStatus;
        this.isNameTransferRejectionReasonRequired = (newStatus === 'Rejected');
        
        // Clear any previous validation errors
        this.validationError = '';
        
        // If user selects "Approved", validate and approve
        if (newStatus === 'Approved') {
            this.handleApproveCase();
        }
    }

    // SIMPLE APPROVAL METHOD
    handleApproveCase() {
        this.isApproving = true;
        this.validationError = '';
        
        approveCase({ caseId: this.recordId })
            .then(result => {
                if (result === 'SUCCESS') {
                    //this.showToast('Success', 'Case approved successfully!', 'success');
                    this.nameTransferStatus = 'Approved';
                    this.isNameTransferRejectionReasonRequired = false;
                    this.nameTransferRejectionReason = '';
                    this.refreshRecordData();
                } else {
                    // Show validation error
                    this.validationError = result;
                    this.showToast('Error', result, 'error');
                    // Reset status since approval failed
                    this.nameTransferStatus = '';
                }
            })
            .catch(error => {
                this.validationError = error.body?.message || error.message;
                this.showToast('Error', this.validationError, 'error');
                // Reset status since approval failed
                this.nameTransferStatus = '';
            })
            .finally(() => {
                this.isApproving = false;
            });
    }

    // Method to refresh record data after approval
    refreshRecordData() {
        this.dispatchEvent(new CustomEvent('recordupdated'));
        this.loadFiles();
    }

    handleNameTransferRejectionReasonChange(event) {
        this.nameTransferRejectionReason = event.detail.value;
    }

    saveNameTransferStatus() {
        if (!this.recordId) return;

        // Validation: If status is Rejected, reason is mandatory
        if (this.nameTransferStatus === 'Rejected' && 
            (!this.nameTransferRejectionReason || this.nameTransferRejectionReason.trim() === '')) {
            this.showToast('Error', 'Please enter reason for name transfer rejection', 'error');
            
            const textarea = this.template.querySelector('lightning-textarea');
            if (textarea) {
                textarea.focus();
            }
            return;
        }

        const fields = {};
        fields['Id'] = this.recordId;
        fields['Name_Transfer_Request_Status__c'] = this.nameTransferStatus;
        
        if (this.nameTransferStatus === 'Rejected') {
            fields['Reason_For_Name_Transfer_Rejection__c'] = this.nameTransferRejectionReason;
        } else {
            fields['Reason_For_Name_Transfer_Rejection__c'] = '';
        }

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.showToast('Success', 'Name Transfer Status updated successfully', 'success');
                console.log('Name Transfer Status updated to:', this.nameTransferStatus);
            })
            .catch(error => {
                console.error('Error updating name transfer status:', error);
                this.showToast('Error', 'Failed to update Name Transfer Status', 'error');
            });
    }

    // ... rest of your existing methods (fetchTypeOptions, fetchStatusOptions, fetchReasonOptions, etc.)
    fetchTypeOptions() {
        getTypeOfDocumentOptions()
            .then(result => {
                const labelToIdMap = {
                    'purchase agreement': 1,
                    'noc': 2,
                    'transfer form': 3,
                    'transfer charge': 4,
                    'letter from mortgager': 5,
                    'gift deed': 6,
                    'builder letter': 7,
                    'rent receipt': 8,
                    'noc from landlord': 9,
                    'noc from legal heirs': 10,
                    'death certificate': 11,
                    'letter from employer to the applicant': 12,
                    'marriage certificate /gazzate certificate/ affidavit': 13,
                    'noc from society': 14
                };

                const transferDocumentMap = {
                    'Mortgaged Transfer': [2, 5, 3, 4],
                    'Sale of Flat Transfer': [1, 2, 3, 4, 15],
                    'Gift Deed Transfer': [2, 3, 4, 6, 10],
                    'Builder Transfer': [2, 3, 4, 8],
                    'Pagadi/Rental/Leased Transfer': [2, 3, 4, 8, 9],
                    'Death of Registered Consumer': [2, 3, 4, 10, 11],
                    'Instituational /Others Transfer': [3, 4, 2]
                };
                
                let filteredLabels = [];

                if (!this.transferType) {
                    filteredLabels = result;
                } else {
                    const allowedIds = transferDocumentMap[this.transferType] || [];
                    filteredLabels = result.filter(label => {
                        const docId = labelToIdMap[label?.trim()?.toLowerCase()];
                        return allowedIds.includes(docId);
                    });
                }

                this.typeOptions = filteredLabels.map(item => ({ label: item, value: item }));
                console.log('🔄 Refreshed document types:', this.typeOptions);
            })
            .catch(error => {
                console.error('Error fetching document types:', error);
            });
    }

    fetchStatusOptions() {
        getStatusOptions()
            .then(result => {
                this.statusOptions = result.map(item => ({ label: item, value: item }));
            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching Status__c options:', error);
            });
    }

    fetchReasonOptions() {
        getReasonOptions()
            .then(result => {
                this.reasonOptions = result.map(item => ({ label: item, value: item }));
            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching Reason_for_Rejection__c options:', error);
            });
    }

    disconnectedCallback() {
        this.unsubscribeFromFileUploadEvent();
    }

    subscribeToFileUploadEvent() {
        const messageCallback = (response) => {
            const payload = response.data.payload;
            console.log('Received upload event:', JSON.stringify(payload));
            
            if (!payload.CaseId__c || payload.CaseId__c === this.recordId) {
                console.log('Refreshing files...');
                this.loadFiles();
                
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Document Update',
                    message: `File ${payload.DocumentTitle__c || ''} was processed`,
                    variant: 'success'
                }));
                
                try {
                    this.dispatchEvent(new RefreshEvent());
                } catch (e) {
                    console.warn('force:refreshView not available in this context.');
                }
            }
        };

        subscribe(this.channelName, -1, messageCallback)
            .then(response => {
                console.log('Subscribed to channel:', response);
                this.subscription = response;
            })
            .catch(error => {
                console.error('Subscription error:', error);
            });

        onError(error => {
            console.error('EMP API error:', error);
        });
    }

    unsubscribeFromFileUploadEvent() {
        if (this.subscription) {
            unsubscribe(this.subscription, () => {
                console.log('Unsubscribed from platform event');
            });
        }
    }

    registerErrorListener() {
        onError(error => {
            console.error('Platform event error:', error);
        });
    }

    loadFiles() {
        const baseUrl = window.location.origin;
        console.log('baseUrl', baseUrl);
        console.log('Inside loadFiles');

        getFilesForCase({ caseId: this.recordId })
            .then(result => {
                this.files = result.map(file => {
                    const isApproved = file.status === 'Verified'; 
                    const isPending = file.status === 'Not Verified';
                    const isRejected = file.status === 'Rejected';
                    
                    return {
                        ...file,
                        fileUrl: `${baseUrl}/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=${file.contentVersionId}`,
                        isEditing: false,
                        isApproved: isApproved,
                        isPending: isPending,
                        isRejected: isRejected
                    };
                });

                console.log('this.files', JSON.stringify(this.files));
            })
            .catch(error => {
                this.showToast('Error', 'Failed to load files.', 'error');
                console.error(error);
            });
    }

    enableEdit(event) {
        const id = event.target.dataset.id;
        this.files = this.files.map(file => {
            if (file.contentVersionId === id) {
                return { ...file, isEditing: true };
            }
            return file;
        });
        this.showSaveButton = true;
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
    }

    handleReasonChange(event) {
        this.selectReason = event.detail.value;
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
    }

    handleRemarksChange(event) {
        this.selectedRemarks = event.detail.value;
    }

    handleSave() {
        if (!this.activeFileId) {
            this.showToast('Error', 'No file selected.', 'error');
            return;
        }

        if (
            this.selectedStatus &&
            this.selectedStatus.toLowerCase() === 'rejected' &&
            (!this.selectReason || this.selectReason.trim() === '')
        ) {
            this.showToast('Error', 'Please select a reason for rejection.', 'error');
            return;
        }

        const selectedItems = this.categories.flatMap(category => {
            console.log('🔍 Category:', category);

            const hasDocs = Array.isArray(category.options) && category.options.length > 0;

            if (!hasDocs) {
                console.log('📂 No documents under category:', category.Name);
                return [category.Name];
            }

            const checkedDocs = category.options.filter(option => option.checked);

            if (checkedDocs.length > 0) {
                return checkedDocs.map(doc => doc.Name || doc.Option_Name__c || doc.DeveloperName);
            }

            return [];
        });

        const selectedNamesCSV = selectedItems.join(', ');
        console.log('✅ Final CSV:', selectedNamesCSV);

        updateFiles({
            contentVersionId: this.activeFileId,
            status: this.selectedStatus,
            reason: this.selectReason,
            docType: this.selectedType,
            comment: this.selectedRemarks,
            selectedNamesCSV: selectedNamesCSV
        })
            .then(() => {
                this.previewUrl = null;
                this.loadFiles();
                this.showToast('Success', 'Record updated successfully.', 'success');
                this.dispatchEvent(new RefreshEvent());
            })
            .catch(error => {
                console.error('❌ Error updating fields:', error);
                this.showToast('Error', 'Failed to update file.', 'error');
            });
    }

    handleTitleClick(event) {
        this.loadFiles();

        const fileId = event.currentTarget.dataset.id;
        const fileUrl = event.currentTarget.dataset.url;
        this.currentdocId = fileId;

        const file = this.files.find(f => f.contentVersionId === fileId);
        if (file) {
            this.activeFileId = fileId;
            this.previewUrl = fileUrl;
            this.previewTitle = file.title;

            this.selectedStatus = file.status || '';
            this.selectedType = file.typeofdoc || '';
            this.selectedRemarks = file.remarks || '';
            this.selectReason = file.reason || '';
            this.rotationAngle = 0;

            // Auto-select document checkboxes
            const selectedNames = (file.selectedDocs || '').split(',').map(name => name.trim().toLowerCase());

            this.categories = this.categories.map(category => {
                let anyChecked = false;

                category.options = category.options.map(option => {
                    const isSelected = selectedNames.includes(
                        (option.Option_Name__c || option.Name || option.DeveloperName || '').toLowerCase()
                    );
                    if (isSelected) {
                        anyChecked = true;
                    }
                    return {
                        ...option,
                        checked: isSelected
                    };
                });

                return {
                    ...category,
                    checked: anyChecked
                };
            });

            console.log('✅ Restored selected documents:', selectedNames);
        } else {
            console.error('File not found in list for ID:', fileId);
        }
    }

    handleCloseModal() {
        this.isModalOpen = false;
        this.previewUrl = null;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ 
            title, 
            message, 
            variant 
        }));
    }

    handleError(title, error) {
        console.error(title, error);
        this.showToast('Error', title + ': ' + (error.body?.message || error.message), 'error');
    }
}