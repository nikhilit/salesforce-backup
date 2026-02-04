import { LightningElement, api, wire, track } from 'lwc';
import getDocumentCategories from '@salesforce/apex/DocumentController.getDocumentCategories';
import getDocumentOptions from '@salesforce/apex/DocumentController.getDocumentOptions';
import relateDocumentsToCases from '@salesforce/apex/DocumentController.relateDocumentsToCases';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DocumentUploader extends LightningElement {
    @api transferType;
    @api recordId;
    @track categories = [];
    @track selectedDocuments = [];
    @track isLoading = true;
    @track error;

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
            console.error('Error loading document categories', error);
            this.error = error;
            this.showToast('Error', 'Failed to load document categories', 'error');
            this.isLoading = false;
        }
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
                        developerName: opt.DeveloperName
                    }));
                } catch (err) {
                    console.error(`Error loading options for category ${category.Name}`, err);
                    this.categories[index].options = [];
                }
            });
            
            await Promise.all(promises);
        } catch (error) {
            console.error('Error loading document options', error);
            this.error = error;
            this.showToast('Error', 'Failed to load document options', 'error');
        } finally {
            this.isLoading = false;
        }
    }

  handleCategorySelect(event) {
    const categoryId = event.target.dataset.id;
    const isChecked = event.target.checked;

    this.categories = this.categories.map(category => {
        if (category.Id === categoryId) {
            category.checked = isChecked;
            // Update all options (documents) under this category
            category.options = category.options.map(option => {
                return { ...option, checked: isChecked };
            });
        }
        return category;
    });

    this.updateSelectedDocuments(); // ✅ Emit selected docs
}


  handleDocumentSelect(event) {
    const documentId = event.target.value;
    const isChecked = event.target.checked;

    this.categories = this.categories.map(category => {
        let categoryModified = false;

        // Update the specific document inside this category
        category.options = category.options.map(option => {
            if (option.Id === documentId) {
                categoryModified = true;
                return { ...option, checked: isChecked };
            }
            return option;
        });

        // If document was updated, update the category's checked status
        if (categoryModified) {
            const allChecked = category.options.every(opt => opt.checked);
            const anyChecked = category.options.some(opt => opt.checked);
            category.checked = anyChecked; // At least one checked = true
        }

        return category;
    });

    this.updateSelectedDocuments(); // ✅ Emit selected docs
}


    updateParentCheckboxes() {
        this.categories = this.categories.map(category => {
            const allOptionsChecked = category.options.length > 0 && 
                                   category.options.every(option => option.checked);
            return {
                ...category,
                checked: allOptionsChecked
            };
        });
    }

    updateSelectedDocuments() {
        try {
            this.selectedDocuments = [];
            this.categories.forEach(category => {
                category.options.forEach(option => {
                    if (option.checked) {
                        this.selectedDocuments.push({
                            id: option.Id,
                            name: option.Option_Name__c,
                            developerName: option.DeveloperName,
                            parentName: category.Name,
                            isRequired: option.Is_Required__c
                        });
                    }
                });
            });
            
            this.dispatchEvent(new CustomEvent('documentsselected', {
                detail: this.selectedDocuments,
                bubbles: true,
                composed: true
            }));
        } catch (error) {
            console.error('Error in updateSelectedDocuments', error);
            this.error = error;
        }
    }

    @api
    getSelectedDocuments() {
        return this.selectedDocuments.map(doc => ({
            id: doc.id,
            name: doc.name,
            developerName: doc.developerName,
            parentName: doc.parentName,
            isRequired: doc.isRequired
        }));
    }

    @api
    validateRequiredDocuments() {
        const missingRequired = this.categories.some(category => 
            category.options.some(option => 
                option.Is_Required__c && !option.checked
            )
        );
        
        if (missingRequired) {
            this.showToast('Error', 'Please upload all required documents', 'error');
            return false;
        }
        return true;
    }
    getSelectedDocumentNames() {
    return this.selectedDocuments.map(doc => doc.name).join(', ');
}
@api
async uploadDocuments(documentIdToMetadata) {
    try {
        if (!this.validateRequiredDocuments()) {
            return { success: false, error: 'Missing required documents' };
        }

        const selectedDocumentNames = this.getSelectedDocumentNames();
        
        await relateDocumentsToCases({ 
            caseId: this.recordId, 
            documentIdToMetadata: documentIdToMetadata,
            selectedDocumentNames: selectedDocumentNames
        });
        
        this.showToast('Success', 'Documents uploaded successfully', 'success');
        return { success: true };
    } catch (error) {
        console.error('Error uploading documents', error);
        let errorMessage = 'Error uploading documents';
        if (error.body && error.body.message) {
            errorMessage = error.body.message;
        } else if (error.message) {
            errorMessage = error.message;
        }
        this.showToast('Error', errorMessage, 'error');
        return { success: false, error: errorMessage };
    }
}

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
    
}