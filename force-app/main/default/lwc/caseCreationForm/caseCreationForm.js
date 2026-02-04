import { LightningElement, wire, track, api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getLatestAttendanceToday from '@salesforce/apex/CaseController.getLatestAttendanceToday';
import getTypeOfDocumentPicklistValues from '@salesforce/apex/CaseController.getTypeOfDocumentPicklistValues';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import getCaseWithNumber from '@salesforce/apex/CaseController.getCaseWithNumber';
import createCaseRecord from '@salesforce/apex/CaseController.createCaseRecord';
import getDepartmentAndSPOC from '@salesforce/apex/CaseController.getDepartmentAndSPOC';
import getDepartmentAndSPOCByType from '@salesforce/apex/CaseController.getDepartmentAndSPOCByType';
import getAccountInfo from '@salesforce/apex/CaseController.getAccountInfo';
import relateDocumentsToCase from '@salesforce/apex/CaseController.relateDocumentsToCase';
import isDuplicateCase from '@salesforce/apex/CaseController.isDuplicateCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchTAT from '@salesforce/apex/CaseController.fetchTAT';
import NEW_SALUTATION_FIELD from '@salesforce/schema/Case.New_Salutation__c';
import getOngoingBreak from '@salesforce/apex/AgentAttendanceController.getOngoingBreak';
import generateAndAttachLetterPDF from '@salesforce/apex/CaseController.generateAndAttachLetterPDF';
import getUserInfo from '@salesforce/apex/CaseController.getUserInfo';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
import { NavigationMixin } from 'lightning/navigation';
const FOCUS_CLASS = 'focus';
const ERROR_CLASS = 'error';
import getDocumentCategories from '@salesforce/apex/DocumentController.getDocumentCategories';
import getDocumentOptions from '@salesforce/apex/DocumentController.getDocumentOptions';
import { getRecord } from 'lightning/uiRecordApi';
import getPicklistValues from '@salesforce/apex/CasePicklistController.getPicklistValues';
import QRC_FOR_VALIDATION from '@salesforce/label/c.QRC_For_Validation';

const attachmentQrcSet = new Set(
    QRC_FOR_VALIDATION
        .split(/[\s,]+/)     // split on comma OR whitespace (spaces/newlines/tabs)
        .map(v => v.trim())
        .filter(v => v)      // remove empty entries
);
 
const FIELDS = [
    'Account.Name',
    'Account.Flat__c',
    'Account.Floor__c',
    'Account.Building_Name_Conn__c',
    'Account.District__c',
    'Account.Other_City__c',
    'Account.Street__c',
    'Account.Street_Line_2__c',
    'Account.Street_Line_3__c',
    'Account.Street_Line_4__c',
    'Account.Street_Line_5__c',
    'Account.City__c',
    'Account.Postal_Code__c',
    'Account.Phone',
    'Account.Secondary_Telephone__c',
    'Account.BP_Number__c',
    'Account.FirstName__c',     
    'Account.Middle_Name__c',   
    'Account.LastName__c', 
    'Account.Full_Name__c',
    'Account.Room__c',
    'Account.Person_Title__c',
    'Account.Supplement__c'
];
export default class CaseCreationForm extends NavigationMixin(LightningElement) {
    @track categoryOptions = [
        { label: 'Complaint', value: 'Complaint' },
         { label: 'Query', value: 'Query' },
        { label: 'Request', value: 'Request' },
       
       
    ];
    @track typeOptions = [];
    @track subTypeOptions = [];
    @track valueOptions = [];
@track userProfileName;
 
     @track hastype = false;
    @track hassubtype = false;
    @track hasValue1 = false;
     @track departmentOptions = [
    { label: 'Aftersales', value: 'Aftersales' },
    { label: 'BIS', value: 'BIS' },
    { label: 'Billing', value: 'Billing' },
    { label: 'CRM', value: 'CRM' },
    { label: 'Marketing', value: 'Marketing' },
    { label: 'Metering', value: 'Metering' },
    //{ label: 'O&M District Office', value: 'O&M District Office' },
    { label: 'O&M Support Online', value: 'O&M Support Online' },
    { label: 'Project', value: 'Project' }
];
validateContactNumber(contactNumber) {
    // Remove spaces, dashes, and parentheses
    contactNumber = contactNumber ? contactNumber.replace(/[\s\-()]/g, '') : '';

    // Define regex for a valid 10-digit Indian mobile number (starts with 6–9)
    const phoneRegex = /^[0-9]\d{9}$/;

    if (!contactNumber) {
        return { isValid: false, message: 'Contact number is required.' };
    } else if (!phoneRegex.test(contactNumber)) {
        return { isValid: false, message: 'Please enter a valid 10-digit mobile number.' };
    } else {
        return { isValid: true, message: '' };
    }
}
get requiresAttachmentForCurrentQrc() {
    const qrc = (this.qrcId || '').trim();   // qrcId is already set from Apex
    return qrc && attachmentQrcSet.has(qrc); // applies to ALL profiles
}
 

// fetchTypes() {
//     getPicklistValues({
//         department: this.form.Department__c,
//         category: this.selectedCategory,
//         type: ''
//     })
//     .then(result => {

//         const newTypes = [...new Set(result.map(r => r.Type__c).filter(t => t))]
//             .map(t => ({ label: t, value: t }))
//             .sort((a, b) => a.label.localeCompare(b.label)); // ✅ sort alphabetically

//         this.typeOptions = [...newTypes]; 
//         this.hastype = this.typeOptions.length > 0;

//     })
//     .catch(error => {
//         console.error('Error fetching Types:', error);
//     });
// }
fetchTypes() {
    getPicklistValues({
        department: this.form.Department__c,
        category: this.selectedCategory,
        type: ''
    })
    .then(result => {

        const newTypes = [...new Set(result.map(r => r.Type__c).filter(t => t))]
            .map(t => {
                // Custom label for "Name Transfer Processed"
                let label = t === 'Name Transfer Processed' ? 'Name Transfer Process' : t;
                return { label, value: t };
            })
            .sort((a, b) => a.label.localeCompare(b.label)); // ✅ sort alphabetically

        this.typeOptions = [...newTypes]; 
        this.hastype = this.typeOptions.length > 0;

        console.log('this.typeOptions', JSON.stringify(this.typeOptions));
    })
    .catch(error => {
        console.error('Error fetching Types:', error);
    });
}


fetchSubTypes() {
    getPicklistValues({ 
        department: this.form.Department__c, 
        category: this.selectedCategory, 
        type: this.form.Type__c 
    })
    .then(result => {
        this.subTypeOptions = [...new Set(result.map(r => r.Sub_Type__c).filter(s => s))]
            .map(s => ({ label: s, value: s }))
            .sort((a, b) => a.label.localeCompare(b.label)); // ✅ sort alphabetically

        this.hassubtype = this.subTypeOptions.length > 0;
    })
    .catch(error => {
        console.error('Error fetching SubTypes:', error);
    });
}

fetchValues() {
    getPicklistValues({ 
        department: this.form.Department__c, 
        category: this.selectedCategory, 
        type: this.form.Type__c
    })
    .then(result => {

        if (!this.form.Sub_Type__c) {
            this.valueOptions = [...new Set(result.map(r => r.Sub_Type__c).filter(s => s))]
                .map(s => ({ label: s, value: s }))
                .sort((a, b) => a.label.localeCompare(b.label)); // ✅ sort alphabetically
        } else {
            const filtered = result.filter(r => r.Sub_Type__c === this.form.Sub_Type__c);
            this.valueOptions = filtered
                .filter(r => r.Value_1__c != null && r.Value_1__c.trim() !== '')
                .map(r => ({ label: r.Value_1__c, value: r.Value_1__c }))
                .sort((a, b) => a.label.localeCompare(b.label)); // ✅ sort alphabetically
        }


        this.hasValue1 = this.valueOptions.length > 0;
    })
    .catch(error => {
        console.error('Error fetching Values:', error);
        this.valueOptions = [];
        this.hasValue1 = false;
    });
}

get isTransferTypeMandatory() {
    return this.form.Department__c === 'CRM' &&
           this.form.Category__c === 'Request' &&
           this.form.Type__c === 'Name Transfer Processed';
}

    @track showDuplicateConfirm = false;
    @track cachedValueMap;
    @track duplicateConfirmed = false;
    @track pendingSubmit = false;


    

    @track isCreateCasevalues = false;
    @track attendanceId;
    @track checkin = false;
    @track cases = [];
    @api recordId;
    account = {};
    accountdetail = {};
    templateSubject = 'Acknowlegement';
    @api objectApiName;
    @track userTypeOfWork = '';
    @track autoCreateWorkOrder = false;
     @track categories = [];
    @track selectedDocuments = [];
    renderedCallback() {
        if (!this._scrollListenerAdded) {
            window.addEventListener('scroll', this.handleScroll, true); // use capture phase
            this._scrollListenerAdded = true;
        }
    }
    handleScroll = () => {
        this.template.querySelectorAll('lightning-combobox').forEach(cb => cb.blur());
    }
     @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ data, error }) {
        if (data) {
            this.accountdetail = {
                Name: data.fields.Name.value,
                Flat__c: data.fields.Flat__c?.value,
                Floor__c: data.fields.Floor__c?.value,
                Building_Name_Conn__c: data.fields.Building_Name_Conn__c?.value,
                Street__c: data.fields.Street__c?.value,
                Street_Line_2__c: data.fields.Street_Line_2__c?.value,
                Street_Line_3__c: data.fields.Street_Line_3__c?.value,
                Street_Line_4__c: data.fields.Street_Line_4__c?.value,
                Street_Line_5__c: data.fields.Street_Line_5__c?.value,
                City__c: data.fields.City__c?.value,
                Postal_Code__c: data.fields.Postal_Code__c?.value,
                Phone: data.fields.Phone?.value,
                Secondary_Telephone__c: data.fields.Secondary_Telephone__c?.value,
                BP_Number__c: data.fields.BP_Number__c?.value,
                Full_Name__c : data.fields.Full_Name__c?.value,
                firstName: data.fields.FirstName__c?.value || '',
                middleName: data.fields.Middle_Name__c?.value || '',
                lastName: data.fields.LastName__c?.value || '',
                fullName: data.fields.Full_Name__c?.value || '',
                Room__c: data.fields.Room__c?.value,
                Person_Title__c: data.fields.Person_Title__c?.value,
                District__c: data.fields.District__c?.value,
                Supplement__c: data.fields.Supplement__c?.value,
                Other_City__c: data.fields.Other_City__c?.value
            };
             console.log('this.accountdetail ',JSON.stringify(this.accountdetail ));
        } else if (error) {
            console.error('Error loading account data', JSON.stringify(error));
        }
    }
handleBlur() {
    this.blurTimeout = setTimeout(() => {
        this.showOptions = false;
    }, 300);
}
applyFocus() {
    var optionBox = this.template.querySelector('.slds-dropdown');
    if (optionBox) {
        optionBox.focus();
    }
}
handleInputBlur(event) {
    var value = {
        value: this.inputValueTemp
    };
    const valueSelectedEvent = new CustomEvent('blur', {
        event,
        detail: value
    });
    this.dispatchEvent(valueSelectedEvent);
}
setFocus(on, event) {
    var element = this.template.activeElement;
    if (this.inputError) {
        element.parentNode.classList.add(ERROR_CLASS);
    } else {
        if (on) {
            element.parentNode.classList.add(FOCUS_CLASS);
        } else {
            let box = this.template.querySelector(".input-box");
            box.classList.remove(FOCUS_CLASS);
            this.template.querySelectorAll(".field").forEach(item => {
                if (item.value) {
                    box.classList.add(FOCUS_CLASS);
                } else {
                    box.classList.remove(FOCUS_CLASS);
                }
            });
        }
    }
}
  @wire(getDocumentCategories, { transferType:'$form.Transfer_Type__c' })
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

// For Name Transfer cases
    handleCategorySelect(event) {
        const categoryId = event.target.dataset.id;
        const isChecked = event.target.checked;

        this.categories = this.categories.map(category => {
            if (category.Id === categoryId) {
                return {
                    ...category,
                    checked: isChecked,
                    options: category.options.map(option => ({
                        ...option,
                        checked: isChecked
                    }))
                };
            }
            return category;
        });
        this.updateSelectedDocuments();
    }


   handleDocumentSelect(event) {
        const documentId = event.target.value;
        const isChecked = event.target.checked;

        this.categories = this.categories.map(category => {
            const updatedOptions = category.options.map(option => {
                if (option.Id === documentId) {
                    return { ...option, checked: isChecked };
                }
                return option;
            });
            
            return {
                ...category,
                options: updatedOptions,
                checked: updatedOptions.some(opt => opt.checked)
            };
        });
        this.updateSelectedDocuments();
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
    }
unsetFocusFalse(event) {
    this.handleInputBlur(event);  // Dispatch blur event to parent
    this.setFocus(false, event);  // Remove focus style
}
// Add this getter to control field visibility (OLD)
// get showBillingShortfallFields() {
//     return this.form.Department__c === 'Billing' &&
//            this.form.Type__c === 'Minimum / Shortfall Charges';
// }
// get areBillingShortfallFieldsRequired() {
//     return this.form.Department__c === 'Billing' && this.form.Category__c!='Query' && 
//            this.form.Type__c === 'Minimum / Shortfall Charges';
// }

get showBillingShortfallFields() {
    return this.form.Department__c === 'Billing' &&
           this.form.Category__c === 'Request' &&
           this.form.Type__c === 'Minimum / Shortfall Charges';
}

get areBillingShortfallFieldsRequired() {
    return this.showBillingShortfallFields;
}


setFocusTrue(event) {
    this.setFocus(true, event);
}

    disconnectedCallback() {
        this._scrollListenerAdded = false;
    }
    
    @track account = null;
    @track form = {
        //ParentId: '',
        Department__c:'',
        Category__c: '',
        Type__c: '',
        Sub_Type__c: '',
        Priority: '',
        Value_1__c: '',
        Value_2__c: '',
        Value_3__c: '',
        Value_4__c: '',
        Value_5__c: '',
        Value_6__c: '',
        Value_7__c: '',
        Value_8__c: '',
        New_First_Name__c: '',
        New_Middle_Name__c: '',
        New_Last_Name__c: '',
         New_Salutation__c: '', 
        remarks: '',
        Origin: '',
        Sub_Origin__c:'',
        Refund_Amount__c: null,
        Refund_Type__c: '',
        Request_Submission_Date__c: null,
        Account_Type__c: '',
        Bank_Name__c: '',
        Branch_Name__c: '',
        IFSC_Code__c: '',
        Account_Number__c: null,
        Account_Holder_Name__c: '',
         Send_SMS_to__c: '', 
        Ticket_Number__c:'',
        Mode_Of_Payment__c: '',
        Transfer_Type__c:'',
        Name_Transfer_Mode__c: '',
        Meter_reading__c:'',
        New_email_id__c: '',
        New_Contact__c: '',
        From_Date__c: '',
        Number_of_Months__c: '',
        To_Date__c: '',
        Call_Received_From__c: '',
        Amount__c: '',
        PD_Reason__c: '',
        New_Address__c: ''

    };
    @track picklistData = {};
    @track options = {};
    @track isLoading = true;
    @track department = '';
    @track beforedpt = '';
    @track spoc = '';
    @track tatDays = '';
    @track tatMinutes = '';
    @track appNumber = '';
    @track tat = '';
    @track qrcId = '';
    @track transfertypes = '';
    @track contactDirections = '';
    @track nameTransferModeOptions = '';
    defaultDescription = '';
    tatInHours = 0;
    get isRefundRelated() {
    const typeVal = this.form.Type__c ? this.form.Type__c.toLowerCase() : '';
    const subTypeVal = this.form.Sub_Type__c ? this.form.Sub_Type__c.toLowerCase() : '';
    const value1Val = this.form.Value_1__c ? this.form.Value_1__c.toLowerCase() : '';
    return (
        subTypeVal === 'excess amount (sd double payment)' ||
        typeVal === 'permanent disconnection & refund process' ||
        typeVal === 'cni-refund'||
        value1Val === 'institutional - td - refund'||
        subTypeVal==='refund excess gas charges paid'||
        subTypeVal==='security deposit refund'
    );
}

get showBankDetails() {
    return this.isRefundRelated && this.form.Mode_Of_Payment__c === 'Online';
}

 get isNameTransferRelated() {
     const isnametransfer = this.form.Type__c && this.form.Type__c.toLowerCase().includes('name transfer');
     return isnametransfer;
 }
    picklistFieldNames = [
        'Department__c', 'Category__c','Type__c', 'Sub_Type__c', 'Priority',
        'Value_1__c', 'Value_2__c', 'Value_3__c', 'Value_4__c',
        'Value_5__c', 'Value_6__c', 'Value_7__c', 'Value_8__c','Transfer_Type__c',
        'Refund_Type__c','Contact_Directions__c', 'Origin', 'Account_Type__c', 'Mode_Of_Payment__c','Sub_Origin__c','Name_Transfer_Mode__c','New_Salutation__c', 'PD_Reason__c'
    ];

    dependencies = [
        { controller: 'Department__c', dependent: 'Category__c' },
        { controller: 'Category__c', dependent: 'Type__c' },
        { controller: 'Type__c', dependent: 'Sub_Type__c' },
        { controller: 'Sub_Type__c', dependent: 'Value_1__c' },
        { controller: 'Value_1__c', dependent: 'Value_2__c' },
        { controller: 'Value_2__c', dependent: 'Value_3__c' },
        { controller: 'Value_3__c', dependent: 'Value_4__c' },
        { controller: 'Value_4__c', dependent: 'Value_5__c' },
        { controller: 'Value_5__c', dependent: 'Value_6__c' },
        { controller: 'Value_6__c', dependent: 'Value_7__c' },
        { controller: 'Value_7__c', dependent: 'Value_8__c' }
    ];
    caseColumns = [
        // {
        //     label: 'Case Number',
        //     fieldName: 'caseLink',
        //     type: 'url',
        //     typeAttributes: { label: { fieldName: 'CaseNumber' } }
        // },
         {
        label: 'Case Number',
        fieldName: 'caseLink',
        type: 'url',
        typeAttributes: { label: { fieldName: 'CaseNumberLabel' } } // use the new label
    },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Category', fieldName: 'Category__c', type: 'text' },
        { label: 'Created Date', fieldName: 'CreatedDateFormatted', type: 'text' },
    ];
    handleRowClick(event) {
        const row = event.detail.row;
        this.navigateToCasePage(row.Id);
    }
    handleCaseClick(event) {
        const caseId = event.target.dataset.id;
        this.navigateToCasePage(caseId);
    }

    navigateToCasePage(caseId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                objectApiName: 'Case', // Object name is 'Case' here
                actionName: 'view'
            }
        });
    }
   @wire(getAccountInfo, { recordId: '$recordId', objectType: '$objectApiName' })
    wiredAccountInfo({ data, error }) {
        this.isLoading = false;
        if (data) {
            if (this.objectApiName === 'Account') {
                this.account = data.account;
                this.appNumber = data.appNumber || '';
            } else if (this.objectApiName === 'Lead') {
                this.lead = data.lead;
            }
            
            this.cases = data.cases.map(c => {
    let createdDateFormatted = 'N/A';
    if (c.Created_Date_Old__c != null) {
        createdDateFormatted = this.formatDate(c.Created_Date_Old__c);
    }else if (c.Created_Date__c != null) {
        createdDateFormatted = this.formatDate(c.Created_Date__c);
    }

    return {
        ...c,
        OwnerName: c.Owner?.Name || 'N/A',
        CreatedDateFormatted: createdDateFormatted,
        caseLink: `/lightning/r/Case/${c.Id}/view`,
        CaseNumberLabel: c.Docket_Number__c && c.Docket_Number__c.trim() !== '' 
            ? c.Docket_Number__c 
            : c.CaseNumber
    };
});

            
            this.casesError = undefined;
        } else if (error) {
            this.account = null;
            this.lead = null;
            this.cases = [];
            this.casesError = 'Failed to load related cases.';
            console.error(error);
        }
    }
get filteredDepartmentOptions() {
    if (!this.picklistData.Department__c || !this.picklistData.Department__c.values) {
        return [];
    }
    
    return this.picklistData.Department__c.values
        .filter(v => {
            const lowerValue = v.value.toLowerCase();
            const shouldExclude = (lowerValue.includes('c&p') && lowerValue.includes('stores')) || 
                                lowerValue.includes('finance');
            return !shouldExclude;
        })
        .map(v => ({ label: v.label, value: v.value }));
}

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo;

    @wire(getPicklistValuesByRecordType, {
        objectApiName: CASE_OBJECT,
        recordTypeId: '$objectInfo.data.defaultRecordTypeId'
    })
    picklistValues({ data, error }) {
        if (data && data.picklistFieldValues) {
            this.picklistFieldNames.forEach(field => {
                if (data.picklistFieldValues[field]) {
                    this.picklistData[field] = data.picklistFieldValues[field];
                }
            });
            if (this.picklistData.Origin) {
                this.options.Origin = this.picklistData.Origin.values.map(v => ({ label: v.label, value: v.value }));
            }
             if (this.picklistData.Contact_Directions__c) {
                this.options.Contact_Directions__c = this.picklistData.Contact_Directions__c.values.map(v => ({ label: v.label, value: v.value }));
                this.contactDirections  = this.options.Contact_Directions__c;
            }
             if (this.picklistData.Sub_Origin__c) {
                this.options.Sub_Origin__c	 = this.picklistData.Sub_Origin__c	.values.map(v => ({ label: v.label, value: v.value }));
            }
             if (this.picklistData.Department__c) {
                this.options.Department__c = this.picklistData.Department__c.values.map(v => ({ label: v.label, value: v.value }));
            }
            if (this.picklistData.Priority) {
                this.options.Priority = this.picklistData.Priority.values.map(v => ({ label: v.label, value: v.value }));
            }
             if (this.picklistData.Transfer_Type__c) {
                this.options.Transfer_Type__c = this.picklistData.Transfer_Type__c.values.map(v => ({ label: v.label, value: v.value }));
                this.transfertypes  = this.options.Transfer_Type__c;
            }
             // Add New_Salutation__c options
        if (this.picklistData.New_Salutation__c) {
            this.options.New_Salutation__c = this.picklistData.New_Salutation__c.values.map(v => ({ 
                label: v.label, 
                value: v.value 
            }));
        }

        if (this.picklistData.PD_Reason__c) {
            this.options.PD_Reason__c =
                this.picklistData.PD_Reason__c.values.map(v => ({
                    label: v.label,
                    value: v.value
                }));
        }

            if (this.picklistData.Account_Type__c) {
                this.options.Account_Type__c = this.picklistData.Account_Type__c.values.map(v => ({ label: v.label, value: v.value }));
               


            }
 if (this.picklistData.Mode_Of_Payment__c) {
                    this.options.Mode_Of_Payment__c = this.picklistData.Mode_Of_Payment__c.values.map(v => ({ label: v.label, value: v.value }));
                }
    if (this.picklistData.Name_Transfer_Mode__c) {
    this.nameTransferModeOptions = this.picklistData.Name_Transfer_Mode__c.values.map(v => ({
        label: v.label,
        value: v.value
    }));
}

            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            this.showToast('Error', 'Failed to load picklist values', 'error');
        }
    }

updateShowBankDetails() {
    this.showBankDetails = this.isRefundRelated && this.form.Mode_Of_Payment__c === 'Online';
}

initializeBillingShortfallDefaults() {
    // Only act when the Billing Shortfall combo is active
    if (!this.areBillingShortfallFieldsRequired) {
        return;
    }

    // 1. From Date = "today" (this will match Case Created_Date__c formula)
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    const fromStr = `${yyyy}-${mm}-${dd}`; // lightning-input date format

    // 2. Hard-code Number of Months = 6 (TEXT field)
    const monthsStr = '6';

    // 3. Put them on the form
    this.form = {
        ...this.form,
        From_Date__c: fromStr,
        Number_of_Months__c: monthsStr
    };

    // 4. Recalculate To_Date__c
    this.updateToDateBasedOnMonths();
}

    showTicketNumber=false;
    @track transfervalue = '';
    @track showBankDetails=false;
    @track typeValue = '';
    @track isMetering = false;
    @track isMeteringAMR = false;
    handleChange(event) {
    const field = event.target.name;
    const value = event.target.inputValue;

    // this.clearValues(field);
    if (['Department__c', 'Category__c', 'Type__c', 'Sub_Type__c'].includes(field)) {
        this.clearValues(field);
    }

    if (field === 'Department__c' || field === 'Category__c' || 
        field === 'Type__c' || field === 'Sub_Type__c') {
        if (!this.showNameCorrectionFields) {
            this.form.New_First_Name__c = '';
            this.form.New_Middle_Name__c = '';
            this.form.New_Last_Name__c = '';
        }
    }

    // Reset PD fields when parent selection changes
    if (
        field === 'Department__c' ||
        field === 'Category__c' ||
        field === 'Type__c' ||
        field === 'Sub_Type__c'
    ) {
        this.form.PD_Reason__c = '';
        this.form.New_Address__c = '';
    }

    // If PD Reason changes away from Redevelopment → clear New Address
    if (field === 'PD_Reason__c' && value !== 'Redevelopment of society') {
        this.form.New_Address__c = '';
    }

      if (field === 'Sub_Type__c' && value === 'Name Correction - Title Error') {
        // Now just use the options that are already loaded
        this.salutationOptions = this.options.New_Salutation__c || [];
    } else if (field === 'Department__c' || field === 'Category__c' || field === 'Type__c') {
        // Clear salutation options if any of these fields change
        this.salutationOptions = [];
        this.form.New_Salutation__c = '';
    }

    if (
        field === 'Department__c' ||
        field === 'Category__c' ||
        field === 'Type__c'
    ) {
        if (!this.showAmountField) {
            this.form.Amount__c = '';
        }
    }


    if ((field === 'Department__c' && value !== 'Billing') || 
        (field === 'Category__c' && value !== 'Request') ||
        (field === 'Type__c' && value !== 'Minimum/Shortfall Charges')) {
        this.form.Meter_reading__c = '';
        this.form.From_Date__c = '';
        this.form.Number_of_Months__c = '';
        this.form.To_Date__c = '';
    }

    if (field === 'Department__c') {
    this.isMetering = (value === 'Metering');
}
     this.isMeteringAMR = (
        this.form.Department__c === 'Metering' &&
        this.form.Sub_Type__c === 'AMR Update'
    );

    if(field == 'Category__c'){
        this.selectedCategory = value;
        this.fetchTypes();
    }

    this.form = {
        ...this.form,
        [field]: value
    };
     if (field === 'Mode_Of_Payment__c' && this.isRefundRelated) {
        if (value === 'Online') {
            const today = new Date().toISOString().split('T')[0];
            this.form.Request_Submission_Date__c = today;
        } else {
            this.form.Request_Submission_Date__c = null;
        }
    }
        if (['Type__c', 'Category__c', 'Sub_Type__c'].includes(field)) {
        this.fetchTatAndPrepareRemarks(); // Trigger TAT + Remarks update
    }
   
    // this.clearBelow(field);
    if (['Department__c', 'Category__c', 'Type__c', 'Sub_Type__c'].includes(field)) {
        this.clearBelow(field);
    }


    const dependency = this.dependencies.find(dep => dep.controller === field);
    /*if (dependency) {
        this.setDependentOptions(field, dependency.dependent, value);
    }*/
   
     if (field === 'Type__c') {
        this.form.Type__c = value;
        this.typeValue = (value === 'Name Transfer Processed') ? 'Name Transfer Process' : value;
        this.fetchSubTypes();
        this.determineDepartmentByType();
    }

    if (field === 'Sub_Type__c') {
        this.form.Sub_Type__c = value;
        this.fetchValues();
        this.determineDepartment();
    }
    if (field === 'Value_1__c') {
        this.determineDepartment();
    }
    if (field === 'Transfer_Type__c'){
        this.transfervalue = value;
        this.loadDocTypeOptions();
    }
     if (field === 'Type__c' || field === 'Mode_Of_Payment__c') {
        this.updateShowBankDetails();
    }

    if ( field === 'Type__c' &&
    !(value && (value.toLowerCase().includes('refund') || value.toLowerCase().includes('cni-refund')))) {
        this.form.Refund_Amount__c = null;
        this.form.Request_Submission_Date__c = '';
        this.form.Account_Number__c = null;
        this.form.IFSC_Code__c = '';
        this.form.Branch_Name__c = '';
        this.form.Bank_Name__c = '';
        this.form.Account_Type__c = '';
        this.form.Mode_Of_Payment__c = '';
    }
if (
    field === 'Origin' &&        value &&
        (
            value.toLowerCase() === 'social media' ||
            value.toLowerCase() === 'nch cases' ||
            value.toLowerCase() === 'mopng/e-seva/pg'
        )
) {
    this.showTicketNumber = true;
} else {
    this.showTicketNumber = false;
    this.ticketNumber = '';
}

if (this.areBillingShortfallFieldsRequired) {
        this.initializeBillingShortfallDefaults();
    }

}

    handleFormChange(event) {
        const { name = '', inputValue = '' } = event.detail || {};

        if (!name) {
            console.error('Received change event without field name!');
            return;
        }
        this.form = {
            ...this.form,
            [name]: inputValue
        };
    }

    updateToDateBasedOnMonths() {
        const fromStr = this.form.From_Date__c;
        const monthsStr = this.form.Number_of_Months__c;

        const months = parseInt(monthsStr, 10);

        // If missing / invalid inputs → clear To_Date__c
        if (!fromStr || isNaN(months) || months <= 0) {
            this.form = {
                ...this.form,
                To_Date__c: ''
            };
            return;
        }

        const from = new Date(fromStr);
        if (isNaN(from.getTime())) {
            this.form = {
                ...this.form,
                To_Date__c: ''
            };
            return;
        }

        // Add N months and subtract 1 day → inclusive range
        const end = new Date(from);
        end.setMonth(end.getMonth() + months);
        end.setDate(end.getDate());

        const yyyy = end.getFullYear();
        const mm = String(end.getMonth() + 1).padStart(2, '0');
        const dd = String(end.getDate()).padStart(2, '0');

        const toDateStr = `${yyyy}-${mm}-${dd}`; // lightning-input date format

        this.form = {
            ...this.form,
            To_Date__c: toDateStr
        };
    }

    handleFieldChange(event) {
        // Log the entire event detail for debugging
        console.log('Event detail:', event.detail);
        console.log('Event target dataset:', event.target.dataset);

        // Support both event structures
        const fieldName = event.detail.name || event.target.dataset.name;
        const fieldValue = event.detail.inputValue || event.detail.value;

        // Log what will be set
        console.log(`Updating form: ${fieldName} = ${fieldValue}`);

        this.form = {
            ...this.form,
            [fieldName]: fieldValue
        };

        // Auto-calc To_Date__c for Billing Shortfall
        if (['From_Date__c', 'Number_of_Months__c'].includes(fieldName) &&
            this.areBillingShortfallFieldsRequired) {
            this.updateToDateBasedOnMonths();
        }
         

    }
    determineDepartment() {
    if (!this.form.Category__c|| !this.form.Type__c || !this.form.Sub_Type__c || ! this.form.Department__c) {
        // console.log('gekodjbwrong');
        this.resetDepartmentFields();
        return;
    }
    
    getDepartmentAndSPOC({
       department: this.form.Department__c,
        category: this.form.Category__c,
        type: this.form.Type__c,
        subType: this.form.Sub_Type__c,
        value1: this.form.Value_1__c,
        recordId: this.recordId,
        objectType: this.objectApiName
    })
    .then(result => {  
       // console.log('results',JSON.stringify(result));      
        // Ensure we have valid results before updating
        if (result) {
            console.log('results',JSON.stringify(result));
            this.beforedpt = result.beforeapprovaldpt || '';
            this.department = result.beforeapprovaldpt || result.department || '';
            this.spoc = result.spoc;
            this.spocId = result.spocId;
            const tatHours = Number(result.tat) || 0;
            this.tat = tatHours;
            this.tatDays = tatHours ? Math.floor(tatHours / 24) : '';
            this.tatMinutes = tatHours ? Math.round(tatHours * 60) : '';
            
            this.qrcId = result.qrcId || '';
            
            // Force UI update for both Account and Lead
            this.requestUpdate();
            
            if (this.spocId && 
                this.form.Category__c !== 'Query' && 
                this.form.Type__c !== 'Name Transfer Processed') {
                this.autoCreateWorkOrder = true;
            }
        } else {
            console.warn('Empty result from getDepartmentAndSPOC');
            this.resetDepartmentFields();
        }
    })
    .catch(error => {
        console.error('Error determining department:', JSON.stringify(error));
        this.resetDepartmentFields();
        this.showToast('Error', 'Failed to load department information', 'error');
    });
}




determineDepartmentByType() {

    getDepartmentAndSPOCByType({
       department:this.form.Department__c,
        category: this.form.Category__c,
        type: this.form.Type__c,
        recordId: this.recordId,
        objectType: this.objectApiName
    })
    .then(result => {
        
        if (result) {
            this.department = result.beforeapprovaldpt || result.department || '';
            this.spoc = result.spoc;
            
            const tatHours = Number(result.tat) || 0;
            this.tat = tatHours;
            this.tatDays = tatHours ? Math.floor(tatHours / 24) : '';
            this.tatMinutes = tatHours ? Math.round(tatHours * 60) : '';
            
            this.spocId = result.spocId || '';
            this.qrcId = result.qrcId || '';
            
            // Force UI update
            this.requestUpdate();
            
            if (this.spocId && 
                this.form.Category__c !== 'Query' && 
                this.form.Type__c !== 'Name Transfer Processed') {
                this.autoCreateWorkOrder = true;
            }
        } else {
            console.warn('Empty result from getDepartmentAndSPOCByType');
            this.resetDepartmentFields();
        }
    })
    .catch(error => {
        console.error('Error determining department by type:', JSON.stringify(error));
        this.resetDepartmentFields();
        this.showToast('Error', 'Failed to load department information', 'error');
    });
}

// Add this method to force UI updates
requestUpdate() {
    // This forces Lightning to recognize property changes
    this.department = this.department;
    this.spoc = this.spoc;
    this.tatDays = this.tatDays;
    this.tatMinutes = this.tatMinutes;
}

resetDepartmentFields() {
    this.department = '';
    this.spoc = '';
    this.spocId = '';
    this.tat = '';
    this.tatDays = '';
    this.tatMinutes = '';
    this.qrcId = '';
    this.beforedpt = '';
    this.autoCreateWorkOrder = false;
    
    // Force UI update when resetting
    this.requestUpdate();
}
    convertTat() {
        const tatHours = this.tat;
        const tatDayss = Math.floor(tatHours / 24);
        const tatMinutess = Math.round(tatHours * 60);

        return { tatDayss, tatMinutess };
    }


    handleTatConversion() {
        const { tatDayss, tatMinutess } = this.convertTat();
        this.tatDays = tatDayss;
        this.tatMinutes = tatMinutess;
    }

    handlePriorityChange(event) {
        this.form.Priority = event.detail.value;
    }
async fetchTatAndPrepareRemarks() {
    const { Category__c, Type__c, Sub_Type__c } = this.form;

    // ✅ Sub-Type is OPTIONAL now
    if (!Category__c || !Type__c) {
        console.warn('❌ Cannot calculate TAT — Category or Type missing.');
        this.tatInHours = 0;
        this.prepareDefaultRemarks(); // Still show benchmark with no TAT
        return;
    }

    try {
        const tat = await fetchTAT({
            category: Category__c,
            type: Type__c,
            subType: Sub_Type__c || '' // Provide empty string if null
        });

        this.tatInHours = tat || 0; // Use 0 if null
        this.prepareDefaultRemarks();
    } catch (error) {
        console.error('TAT fetch error:', error);
        this.tatInHours = 0;
        this.prepareDefaultRemarks(); // Still populate Description
    }
}

prepareDefaultRemarks() {
    let benchmarkDate = '';

    if (this.tatInHours > 0) {
        const now = new Date();
        const futureDate = new Date(now.getTime() + this.tatInHours * 60 * 60 * 1000);

        const day = String(futureDate.getDate()).padStart(2, '0');
        const month = String(futureDate.getMonth() + 1).padStart(2, '0');
        const year = futureDate.getFullYear();

        benchmarkDate = `${day}/${month}/${year}`;
    }


// const remarks = [
//     benchmarkDate ? `ETA - ${benchmarkDate}` : null,
//     this.form.Category__c || '',
//      this.form.Type__c || '' 
// ].filter(Boolean).join(' ').trim();
const typeValue =
    this.form.Type__c === 'Name Transfer Processed'
        ? 'Name Transfer Process'
        : this.form.Type__c;

const remarks = [
    benchmarkDate ? `ETA - ${benchmarkDate}` : null,
    this.form.Category__c || '',
    typeValue || ''
].filter(Boolean).join(' ').trim();


    this.defaultDescription = remarks;
    this.form.Remarks__c = remarks;

    // ✅ Force DOM update manually for <textarea>
    setTimeout(() => {
        const textarea = this.template.querySelector('[data-id="desc"]');
        if (textarea) {
            textarea.value = this.form.Remarks__c;
            console.log('📝 Updated <textarea> manually to:', textarea.value);
        } else {
            console.warn('⚠️ <textarea> not found');
        }
    }, 0);
}



    handleDescChange(event) {
       const value = event.target.value;
    this.form.Remarks__c = value;

    this.remarksModified = (this.form.Remarks__c !== this.defaultDescription);
    
    }
    handleDocDescChange(event){
        this.docdescription = event.target.value;
    }

    setDependentOptions(controllerField, dependentField, controllerValue) {

        const dependentMeta = this.picklistData[dependentField];
        console.log('dependentMeta', dependentMeta);
        console.log('this.picklistData', JSON.stringify(this.picklistData));
        if (!dependentMeta) {
            console.warn(`Dependent metadata not found for ${dependentField}`);
            return;
        }

        const controllerKey = dependentMeta.controllerValues[controllerValue];

        // If controllerKey is undefined, no match found, exit safely
        if (controllerKey === undefined) {
            console.warn(`No controller key found for value: ${controllerValue}`);
            this.options[dependentField] = [];
            return;
        }

        const options = dependentMeta.values
            .filter(opt => opt.validFor.includes(controllerKey))
            .map(opt => ({ label: opt.label, value: opt.value }));

        console.log(`Setting dependent options for ${dependentField}:`, JSON.stringify(options));

        // Use spread operator to trigger reactivity
        this.options = {
            ...this.options,
            [dependentField]: options
        };
    }

   clearBelow(controllerField) {
    let startClearing = false;
    const protectedFields = ['Priority', 'Origin', 'Account_Type__c', 'Sub_Origin__c', 
                           'Mode_Of_Payment__c','Contact_Directions__c','New_Salutation__c', 'PD_Reason__c'];

    for (const f of this.picklistFieldNames) {
        if (f === controllerField) {
            startClearing = true;
            continue; 
        }

        if (startClearing && !protectedFields.includes(f)) {
            this.form[f] = '';
            this.options[f] = [];
        }
    }
}

    // Add this method to your component
    isValueFieldRequired(fieldName) {
        // Only check Value_X__c fields
        if (fieldName.startsWith('Value_') && fieldName.endsWith('__c')) {
            return this.options[fieldName]?.length > 0;
        }
        return false;
    }
    // @track isLoading = true;
    @track message = 'Assigning to Department';

    @track value = false;
get showNameTransferMode() {
    return this.form.Type__c === 'Name Transfer Processed';
}
get showCustomerContactFields() {
    return this.form.Department__c === 'CRM' && this.form.Category__c!='Query' &&
           this.form.Type__c === 'Customer Contact Details - Update';
}

get showNewEmailField() {
    return this.showCustomerContactFields && 
           (this.form.Sub_Type__c === 'Email Address' || 
            this.form.Sub_Type__c === 'Mobile No & Email Address');
}

get showNewContactField() {
    return this.showCustomerContactFields && 
           (this.form.Sub_Type__c === 'Mobile No' || 
            this.form.Sub_Type__c === 'Mobile No & Email Address');
}
getIsChecked(optionValue) {
    return this.selectedDocTypes.includes(optionValue);
}

// Add this method to validate name character changes (middle name is optional)
validateNameCorrectionChanges() {
    if (!this.showNameCorrectionFields) {
        return { isValid: true, message: '' };
    }

    const oldFirst  = (this.accountdetail.firstName || '').trim();
    const oldMiddle = (this.accountdetail.middleName || '').trim();
    const oldLast   = (this.accountdetail.lastName || '').trim();

    if (!oldFirst && !oldLast) {
        return {
            isValid: false,
            message: 'Account full name not found. Please tag an account before name correction.'
        };
    }

    const newFirst  = (this.form.New_First_Name__c || '').trim();
    const newMiddle = (this.form.New_Middle_Name__c || '').trim();
    const newLast   = (this.form.New_Last_Name__c || '').trim();

    const firstDiff = this.calculateLevenshteinDistance(
        oldFirst.toLowerCase(),
        newFirst.toLowerCase()
    );

    const middleDiff =
        oldMiddle.toLowerCase() !== newMiddle.toLowerCase()
            ? this.calculateLevenshteinDistance(
                oldMiddle.toLowerCase(),
                newMiddle.toLowerCase()
            )
            : 0;

    const lastDiff = this.calculateLevenshteinDistance(
        oldLast.toLowerCase(),
        newLast.toLowerCase()
    );

    const totalDiff = firstDiff + middleDiff + lastDiff;

    console.log('🔍 NAME COMPARISON DEBUG', {
        oldFirst, oldMiddle, oldLast,
        newFirst, newMiddle, newLast,
        firstDiff, middleDiff, lastDiff,
        totalDiff
    });

    if (totalDiff == 0) {
        return {
            isValid: false,
            message: 'No changes detected. Make changes first.'
        };
    }

    if (totalDiff > 2) {
        return {
            isValid: false,
            message: 'More than 2 character changes detected in name correction.'
        };
    }

    const onlyCaseChanged =
        totalDiff === 0 &&
        (
            oldFirst !== newFirst ||
            oldMiddle !== newMiddle ||
            oldLast !== newLast
        );

    if (onlyCaseChanged) {
        return {
            isValid: false,
            message: 'Only case changes are not allowed.'
        };
    }

    return { isValid: true, message: '' };

    // Get the current full name from account
    // const currentFullName = this.accountdetail?.Full_Name__c || '';
    // if (!currentFullName) {
    //     return { isValid: false, message: 'Current full name not found' };
    // }

    // // Get new name fields (middle name is optional)
    // const newFirstName = (this.form.New_First_Name__c || '').trim();
    // const newMiddleName = (this.form.New_Middle_Name__c || '').trim();
    // const newLastName = (this.form.New_Last_Name__c || '').trim();

    // // Split current name into parts
    // const currentParts = currentFullName.trim().split(/\s+/);
    
    // // Determine which parts are being compared
    // let currentFirst = currentParts[0] || '';
    // let currentMiddle = currentParts.length > 2 ? currentParts[1] : '';
    // let currentLast = currentParts.length > 1 ? currentParts[currentParts.length - 1] : '';

    // Calculate character differences for each part individually
    // let totalCharacterDifference = 0;
    // let messages = [];

    // // Helper function to compare strings ignoring spaces
    // const compareIgnoringSpaces = (str1, str2) => {
    //     // Remove all spaces from both strings before comparison
    //     const cleanStr1 = str1.replace(/\s+/g, '');
    //     const cleanStr2 = str2.replace(/\s+/g, '');
        
    //     return this.calculateLevenshteinDistance(
    //         cleanStr1.toLowerCase(),
    //         cleanStr2.toLowerCase()
    //     );
    // };

    // // Helper function to count only non-space characters
    // const countNonSpaceCharacters = (str) => {
    //     return str.replace(/\s+/g, '').length;
    // };

    // // Compare first name (ignoring spaces)
    // const firstNameDiff = compareIgnoringSpaces(currentFirst, newFirstName);
    // if (firstNameDiff > 0) {
    //     totalCharacterDifference += firstNameDiff;
    //     messages.push(`First name: ${firstNameDiff} change(s)`);
    // }

    // // Compare last name (ignoring spaces)
    // const lastNameDiff = compareIgnoringSpaces(currentLast, newLastName);
    // if (lastNameDiff > 0) {
    //     totalCharacterDifference += lastNameDiff;
    //     messages.push(`Last name: ${lastNameDiff} change(s)`);
    // }

    // // Handle middle name (optional)
    // if (currentMiddle && newMiddleName) {
    //     // Both have middle names, compare them (ignoring spaces)
    //     const middleNameDiff = compareIgnoringSpaces(currentMiddle, newMiddleName);
    //     if (middleNameDiff > 0) {
    //         totalCharacterDifference += middleNameDiff;
    //         messages.push(`Middle name: ${middleNameDiff} change(s)`);
    //     }
    // } else if (currentMiddle && !newMiddleName) {
    //     // Middle name removed - this is allowed (not counted as character changes)
    //     messages.push('Middle name removed');
    // } else if (!currentMiddle && newMiddleName) {
    //     // Middle name added - count only non-space characters
    //     const charCount = countNonSpaceCharacters(newMiddleName);
    //     if (charCount > 0) {
    //         totalCharacterDifference += charCount;
    //         messages.push(`Middle name added: ${charCount} character(s)`);
    //     }
    // }

    // Allow up to 2 character changes across all name parts
    // if (totalCharacterDifference > 2) {
    //     return { 
    //         isValid: false, 
    //         message: `More than 2 character changes detected (total: ${totalCharacterDifference} changes). Breakdown: ${messages.join(', ')}. Please verify the name correction.` 
    //     };
    // }

    // // Check if the change is meaningful (not just case change)
    // // We need to compare the cleaned strings (without spaces) for case checking
    // const cleanedCurrentFirst = currentFirst.replace(/\s+/g, '');
    // const cleanedNewFirst = newFirstName.replace(/\s+/g, '');
    // const cleanedCurrentLast = currentLast.replace(/\s+/g, '');
    // const cleanedNewLast = newLastName.replace(/\s+/g, '');
    
    // const onlyCaseChanged = (firstNameDiff === 0 && cleanedCurrentFirst !== cleanedNewFirst) || 
    //                       (lastNameDiff === 0 && cleanedCurrentLast !== cleanedNewLast);
    
    // if (onlyCaseChanged && totalCharacterDifference === 0) {
    //     // Only case changed, no actual character difference
    //     return { 
    //         isValid: false, 
    //         message: 'Only case changes detected. Please verify the name correction.' 
    //     };
    // }

    // return { isValid: true, message: '' };
}

// Levenshtein distance algorithm to calculate character differences
calculateLevenshteinDistance(str1, str2) {
    const matrix = [];

    // Initialize matrix
    for (let i = 0; i <= str1.length; i++) {
        matrix[i] = [i];
    }
    for (let j = 0; j <= str2.length; j++) {
        matrix[0][j] = j;
    }

    // Fill matrix
    for (let i = 1; i <= str1.length; i++) {
        for (let j = 1; j <= str2.length; j++) {
            const cost = str1.charAt(i - 1) === str2.charAt(j - 1) ? 0 : 1;
            matrix[i][j] = Math.min(
                matrix[i - 1][j] + 1,      // deletion
                matrix[i][j - 1] + 1,      // insertion
                matrix[i - 1][j - 1] + cost // substitution
            );
        }
    }

    return matrix[str1.length][str2.length];
}

async handleSubmit() {
    this.isLoading = true;
    try {
        // 1. Check attendance
        const attendanceResult = await getLatestAttendanceToday();
        if (!attendanceResult || attendanceResult.Day_Out_Timestamp__c) {
            this.showToast('Error', 'Please do Check-In', 'error');
            this.isLoading = false;
            return;
        }
        this.attendanceId = attendanceResult.Id;

        // 2. Check for ongoing break
        const breakResult = await getOngoingBreak();
        if (breakResult) {
            this.showToast('Error', 'You cannot create a Case during an active break.', 'error');
            this.isLoading = false;
            return;
        }

        // 3. Validate always-required fields
       if (
    !this.form.Department__c ||
    !this.form.Category__c ||
    !this.form.Origin ||
    !this.form.Type__c ||
    !this.form.Priority ||
    !this.form.Contact_Directions__c ||
    (this.options.Sub_Type__c.length > 0 && !this.form.Sub_Type__c) ||
    (this.isMeteringAMR && !this.form.Meter_reading__c)
 
) {
    this.showToast('Error', 'Please fill all required fields', 'error');
    this.isLoading = false;
    return;
}


        // PD Reason mandatory
        if (this.showPDReason && !this.form.PD_Reason__c) {
            this.showToast('Error', 'Please select PD Reason', 'error');
            this.isLoading = false;
            return;
        }
        // Transfer Type mandatory for CRM → Request → Name Transfer Process
if (
    this.form.Department__c === 'CRM' &&
    this.form.Category__c === 'Request' &&
    this.form.Type__c === 'Name Transfer Processed' &&
    !this.form.Transfer_Type__c
) {
    this.showToast(
        'Error',
        'Please select Transfer Type',
        'error'
    );
    this.isLoading = false;
    return;
}

if (
    this.form.Department__c === 'CRM' &&
    this.form.Category__c === 'Request' &&
    this.form.Type__c === 'Name Transfer Processed' &&
    !this.form.Name_Transfer_Mode__c
) {
    this.showToast(
        'Error',
        'Please select Name Transfer Mode',
        'error'
    );
    this.isLoading = false;
    return;
}
        // New Address mandatory ONLY for Redevelopment
        if (
            this.showNewAddressField &&
            (!this.form.New_Address__c || !this.form.New_Address__c.trim())
        ) {
            this.showToast('Error', 'Please enter New Address', 'error');
            this.isLoading = false;
            return;
        }


        // Add this validation after the CRM contact update validation 
        if (this.showNameCorrectionFields) {
            if (!this.form.New_First_Name__c || this.form.New_First_Name__c.trim() === '') {
                this.showToast('Error', 'Please enter New First Name', 'error');
                this.isLoading = false;
                return;
            }
            
            if (!this.form.New_Last_Name__c || this.form.New_Last_Name__c.trim() === '') {
                this.showToast('Error', 'Please enter New Last Name', 'error');
                this.isLoading = false;
                return;
            }
            const nameValidation = this.validateNameCorrectionChanges();
            if (!nameValidation.isValid) {
                this.showToast('Error', nameValidation.message, 'error');
                this.isLoading = false;
                return;
            }
           
        }
         if (this.showNewSalutationField && (!this.form.New_Salutation__c || this.form.New_Salutation__c.trim() === '')) {
                this.showToast('Error', 'Please enter New Salutation', 'error');
                this.isLoading = false;
                return;
            }

        // 3.4 – validate "Call Received From" when Origin = Telephone (API '1')
       if (
    this.form.Origin === '1' || 
    this.form.Origin === '12' || 
    this.form.Origin === '13' || 
    this.form.Origin === '14' || 
    this.form.Origin === '15' || 
    this.form.Origin === '20' || 
    this.form.Origin === '21'
) {
    const val = (this.form.Call_Received_From__c || '').trim();

    // ✅ Throw error if blank
    if (!val) {
        this.showToast('Error', 'Call Received From cannot be blank', 'error');
        this.isLoading = false;
        return;
    }

    // ✅ Validate number if not blank
    const contactValidation = this.validateContactNumber(val);
    if (!contactValidation.isValid) {
        this.showToast('Error', contactValidation.message, 'error');
        this.isLoading = false;
        return;
    }
}


        // 3.5 Validate Billing Shortfall fields when applicable
        if (this.areBillingShortfallFieldsRequired) {
            if (!this.form.Meter_reading__c || this.form.Meter_reading__c.trim() === '') {
                this.showToast('Error', 'Please enter Meter Reading for Minimum / Shortfall Charges', 'error');
                this.isLoading = false;
                return;
            }

            // From / Months / To should already be auto-set
            if (!this.form.From_Date__c) {
                this.showToast('Error', 'From Date could not be set. Please contact your administrator.', 'error');
                this.isLoading = false;
                return;
            }

            if (!this.form.To_Date__c) {
                this.showToast(
                    'Error',
                    'To Date could not be calculated. Please contact your administrator.',
                    'error'
                );
                this.isLoading = false;
                return;
            }
        }


            
        
        // 4. Validate CRM Contact Update fields based on Sub Type
        if (this.showCustomerContactFields) {
            if (this.showNewEmailField && (!this.form.New_email_id__c || this.form.New_email_id__c.trim() === '')) {
                this.showToast('Error', 'Please enter New Email ID', 'error');
                this.isLoading = false;
                return;
            }
            
            if (this.showNewContactField && (!this.form.New_Contact__c || this.form.New_Contact__c.trim() === '')) {
                this.showToast('Error', 'Please enter New Contact', 'error');
                this.isLoading = false;
                return;
            }
            
            // Additional validation for email format
            if (this.showNewEmailField && this.form.New_email_id__c) {
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(this.form.New_email_id__c)) {
                    this.showToast('Error', 'Please enter a valid email address', 'error');
                    this.isLoading = false;
                    return;
                }
            }
            
            // Additional validation for contact number format (10 digits)
            if (this.showNewContactField && this.form.New_Contact__c) {
                const contactValidation = this.validateContactNumber(this.form.New_Contact__c);
                if (!contactValidation.isValid) {
                    this.showToast('Error', contactValidation.message, 'error');
                    this.isLoading = false;
                    return;
                }
            }
        }

        // 4. Custom validation for Refund Related-Request
        if (this.isRefundRelated && this.form.Mode_Of_Payment__c === 'Online') {
            console.log('Inside 852',JSON.stringify(this.uploadedDocuments));
            const hasCheque = (this.uploadedDocuments || []).some(doc =>
                doc.docType && doc.docType.trim().toLowerCase() === 'cheque'
            );
            if (!hasCheque) {
                this.showToast('Error', 'Please Upload the related Cheque document', 'error');
                this.isLoading = false;
                return;
            }
        }
         // 4.5 Validate if document types selected but not uploaded
if (!this.validateDocuments()) {
    this.isLoading=false;
            return;
        }

        // 5. Prepare valueMap for duplicate check
        const valueMap = {};
        for (let i = 1; i <= 8; i++) {
            const value = this.form[`Value_${i}__c`];
            if (value) valueMap[`Value${i}`] = value;
        }

        if (this.form.Amount__c) {
            valueMap.Amount__c = this.form.Amount__c;
        }
        valueMap['Meter_reading__c'] = this.form.Meter_reading__c; 
        valueMap['Call_Received_From__c'] = this.form.Call_Received_From__c;

        valueMap['From_Date__c']         = this.form.From_Date__c || '';
        valueMap['Number_of_Months__c']  = this.form.Number_of_Months__c || '';
        valueMap['To_Date__c']           = this.form.To_Date__c || '';
        // ✅ ADD PD Reason & New Address to valueMap
        if (this.form.PD_Reason__c) {
            valueMap.PD_Reason__c = this.form.PD_Reason__c;
        }

        if (this.form.New_Address__c) {
            valueMap.New_Address__c = this.form.New_Address__c;
        }

        console.log('✅ FINAL valueMap:', JSON.stringify(valueMap));


       console.log('valueMap',JSON.stringify(valueMap));

        // 6. Duplicate Case Check
        const isDuplicate = await isDuplicateCase({
            recordId: this.recordId,
            objectType: this.objectApiName,
            category: this.form.Category__c,
            type: this.form.Type__c,
            subType: this.form.Sub_Type__c,
            department: this.department,
            valueMap: valueMap
        });

        // DUPLICATE FOUND & NOT YET CONFIRMED
        if (isDuplicate && !this.duplicateConfirmed) {
            this.showDuplicateConfirm = true;
            this.isLoading = false;
            this.pendingSubmit = true;
            return;
        }


        // 7. Fallback for Remarks/Description
        if (!this.form.Remarks__c || this.form.Remarks__c.trim() === '') {
            this.form.Remarks__c = this.defaultDescription;
        }
        const smsAndAdditionalFields = {
            'sendSmsTo': this.form.Send_SMS_to__c, // The actual SMS value
            'contactedBy': this.form.Contacted_By__c,
            'relationshipToOwner': this.form.Relationship_to_the_owner__c,
            'newEmailId': this.form.New_email_id__c,
             'newContact': this.form.New_Contact__c,
             'fromDate': this.form.From_Date__c,
             'toDate': this.form.To_Date__c,
            'newFirstName': this.form.New_First_Name__c,
            'newMiddleName': this.form.New_Middle_Name__c,
            'newLastName': this.form.New_Last_Name__c,
            'newSalutation':this.form.New_Salutation__c
        };
        // Validation For Required Attachments based on Department, Category, Type
        
        // For non–Name Transfer: use checkbox doc types (Others / Cheque / ID Proof)
       try {
        
console.log('Uploaded Documents:', {
    uploadedDocuments: this.uploadedDocuments,
    uploadedCount: Array.isArray(this.uploadedDocuments) ? this.uploadedDocuments.length : 'NOT ARRAY'
});
 
    // Normalizer
    const norm = v =>
        (v === undefined || v === null) ? '' : String(v).trim().toLowerCase();
 
    const dept = norm(this.form?.Department__c);
    const cat  = norm(this.form?.Category__c);
    const type = norm(this.form?.Type__c);
 
    // // Rule A: QRC-based (for everyone)
    // let requiresQrcAttachment = this.requiresAttachmentForCurrentQrc;

    // // Billing / Request / Customer Contact Details - Update combo
    // const isBillingContactUpdate =
    //     dept === 'crm' &&
    //     cat === 'request' &&
    //     (type === 'customer contact details - update' || type === 'name correction') ;
 
    // // // Rule B: Billing / Request / CCDU (FrontOffice only)
    // const requiresBillingAttachment =
    //     this.isFrontOfficeProfile && isBillingContactUpdate;

    // // CRM / Request / Customer Contact Details - Update
    // // const isCustomerContactUpdate =
    // //     dept === 'crm' &&
    // //     cat === 'request' &&
    // //     (type === 'customer contact details - update' || type === 'name correction');

    // // Rule B1: Front Office → always required (existing behavior)
    // const requiresFrontOfficeAttachment =
    //     this.isFrontOfficeProfile && isBillingContactUpdate;

    // // Rule B2: Back Office → required ONLY when Origin is Letter
    // const requiresBackOfficeAttachment =
    //     this.isBackOfficeProfile &&
    //     isBillingContactUpdate &&
    //     this.isLetterOrigin;

    // // Final rule for this scenario
    // // const requiresBillingAttachment =
    // //     requiresFrontOfficeAttachment || requiresBackOfficeAttachment;

 
    // // ❗ If it is Billing/Request/CCDU and user is NOT FrontOffice,
    // //    ignore the QRC-based rule (i.e. no attachment required from label)
    // if (isBillingContactUpdate && !this.isFrontOfficeProfile) {
    //     requiresQrcAttachment = false;
    // }
 
    // // Final decision → if ANY rule says yes, attachments are mandatory
    // const requiresAttachment = requiresQrcAttachment || requiresBillingAttachment;

    // Rule A: QRC-based
    let requiresQrcAttachment = this.requiresAttachmentForCurrentQrc;

    // Rule B: Billing / Request / CCDU
    const isBillingContactUpdate =
        dept === 'crm' &&
        cat === 'request' &&
        (type === 'customer contact details - update' || type === 'name correction');

    // Rule B1: Front Office → always required
    const requiresFrontOfficeAttachment =
        this.isFrontOfficeProfile && isBillingContactUpdate;

    // Rule B2: Back Office → required ONLY when Origin is Letter
    const requiresBackOfficeAttachment =
        this.isBackOfficeProfile &&
        isBillingContactUpdate &&
        this.isLetterOrigin;

    // ❗ Ignore QRC rule for non-FrontOffice in this scenario
    if (isBillingContactUpdate && !this.isFrontOfficeProfile) {
        requiresQrcAttachment = false;
    }

    // ✅ FINAL DECISION (THIS WAS WRONG BEFORE)
    const requiresAttachment =
        requiresQrcAttachment ||
        requiresFrontOfficeAttachment ||
        requiresBackOfficeAttachment;

 
    if (requiresAttachment) {

        // Check uploaded files
        // const hasUploadedFiles =
        //     Array.isArray(this.uploadedDocuments) &&
        //     this.uploadedDocuments.length > 0;
        const hasUploadedFiles = this.hasUserUploadedDocuments();

 
        // For non–Name Transfer: use checkbox doc types (Others / Cheque / ID Proof)
        const hasNonNameTransferDocTypes =
            Array.isArray(this.selectedDocTypes) &&
            this.selectedDocTypes.length > 0;
 
        // For Name Transfer: use selectedDocuments (category/options)
        // let hasNameTransferDocTypes = false;
        // if (Array.isArray(this.selectedDocuments)) {
        //     hasNameTransferDocTypes = this.selectedDocuments.length > 0;
        // } else if (this.selectedDocuments && typeof this.selectedDocuments === 'object') {
        //     hasNameTransferDocTypes = Object.keys(this.selectedDocuments).length > 0;
        // }
        const hasNameTransferDocTypes =
            Array.isArray(this.selectedDocuments) &&
            this.selectedDocuments.length > 0;

 
        const hasSelectedDocTypes = this.isNameTransferRelated
            ? hasNameTransferDocTypes
            : hasNonNameTransferDocTypes;
 
        // Enforce: BOTH doc-type + file are required
        if (!hasSelectedDocTypes) {
            this.showToast(
                'Error',
                'Please select at least one document type (Others / Cheque / ID Proof).',
                'error'
            );
            this.isLoading = false;
            return;
        }
 
        if (!hasUploadedFiles) {
            this.showToast(
                'Error',
                'Please upload at least one document for the selected document type(s).',
                'error'
            );
            this.isLoading = false;
            return;
        }
    }
 
} catch (err) {
    console.error('Attachment validation error:', err);
}

if(this.qrcId==''){
    this.showToast(
                'Error',
                'No matching QRC\'s found. Please check if you have filled all values',
                'error'
            );
}

        if (this.showAmountField) {
            const amount = (this.form.Amount__c || '').trim();

            if (!amount) {
                this.showToast('Error', 'Please enter Amount', 'error');
                this.isLoading = false;
                return;
            }

            const amountRegex = /^\d+(\.\d{1,2})?$/;
            if (!amountRegex.test(amount)) {
                this.showToast(
                    'Error',
                    'Amount must be a valid number (integer or decimal), 2 Decimal places',
                    'error'
                );
                this.isLoading = false;
                return;
            }

            // ✅ store normalized value back
            this.form.Amount__c = amount;
        }

 
        // 8. Create Case Record
        const caseRecord = await createCaseRecord({
            recordId: this.recordId,
            objectType: this.objectApiName,
            category: this.form.Category__c,
            type:this.form.Type__c,
            subType: this.form.Sub_Type__c,
            description: this.form.Remarks__c,
            priority: this.form.Priority,
            valueMap: valueMap,
            department: this.department,
            spocId: this.spocId,
            tat: this.tat,
            tatDays: this.tatDays,
            tatMinutes: this.tatMinutes,
            refundAmount: this.form.Refund_Amount__c,
            origin: this.form.Origin,
            subOrigin: this.form.Sub_Origin__c,
            requestSubmissionDate: this.form.Request_Submission_Date__c || null,
            accountType: this.form.Account_Type__c,
            bankName: this.form.Bank_Name__c,
            branchName: this.form.Branch_Name__c,
            ifscCode: this.form.IFSC_Code__c,
            accountNumber: this.form.Account_Number__c || null,
            accountHolderName: this.form.Account_Holder_Name__c,
            ticketNumber: this.form.Ticket_Number__c,
            qrcprocess: this.qrcId,
            attendancetrack: this.attendanceId,
            sendSmsTo: JSON.stringify(smsAndAdditionalFields),
            modeOfPayment: this.form.Mode_Of_Payment__c,
            createCheckbox: this.autoCreateWorkOrder,
            transfertypevalue: this.form.Transfer_Type__c,
            nameTransferMode: this.form.Name_Transfer_Mode__c,
           contactdirection: this.form.Contact_Directions__c,
           meterreading: this.form.Meter_reading__c

        });
        this.createdCaseId = caseRecord.Id;
      const caseNumber = await this.fetchCaseNumber(this.createdCaseId);
this.createdCase = { ...caseRecord, CaseNumber: caseNumber };

this.duplicateConfirmed = false;
this.pendingSubmit = false;


        // 9. Relate documents to case
  // In handleSubmit(), update the document metadata creation:
const documentIdToMetadata = {};
(this.uploadedDocuments || []).forEach(doc => {
    if (doc.documentId) {
        documentIdToMetadata[doc.documentId] = {
            docType: this.isNameTransferRelated 
                ? doc.docTypes?.join(', ') || '' 
                : doc.docType || '',
            description: doc.description || ''
        };
    }
});

if (Object.keys(documentIdToMetadata).length > 0) {
    await relateDocumentsToCase({
        caseId: this.createdCaseId,
        documentIdToMetadata: documentIdToMetadata
    });
}
//         if (this.form.Origin && this.form.Origin.toLowerCase().includes('letter')) {
//    try {
//      const acc = this.accountdetail || {};
//     const cs = this.createdCase || {}; // <-- get the Case object

//     const streetLines1 = [
//     acc.Street__c,
//     acc.Street_Line_3__c   
//     ].filter(line => line && line.trim()).join(', ').trim();

//     const streetLines2 = [
//     acc.Street_Line_4__c,
//     acc.Street_Line_5__c
//     ].filter(line => line && line.trim()).join(', ').trim();
//     // Get today's date
// let today = new Date();

// // Format as dd.MM.yyyy
// let day = String(today.getDate()).padStart(2, '0');
// let month = String(today.getMonth() + 1).padStart(2, '0'); // Months are 0-based
// let year = today.getFullYear();

// let dateValue = `${day}.${month}.${year}`;

// let months = today.getMonth() + 1; // JS months are 0-based
// let fy = '';

// if (months >= 4) { // April to December
//     fy = year + '-' + String(year + 1).slice(-2);
// } else { // January to March
//     fy = (year - 1) + '-' + String(year).slice(-2);
// }

//  const letterBody = `
//  <table style="width: 100%; margin-top: 10px;">
//     <tr>
//        <td style="text-align: left;">
//     <strong>Ref No: MGL/CRM/${cs.CaseNumber}/${fy}</strong>
// </td>

//         <td style="text-align: right;"><strong>Date: ${dateValue}</strong></td>
//     </tr>
// </table>
// <div style="margin-top: 8px; line-height: 1.4;">
//     To,<br/>
//     <strong>${acc.Person_Title__c || ''} ${acc.Full_Name__c || 'Customer'}</strong><br/>
//     ${acc.Room__c ? `Flat No: ${acc.Room__c}` : ''} 
//     ${acc.Room__c && acc.Floor__c ? ', ' : ''}${acc.Floor__c ? `Floor No: ${acc.Floor__c}` : ''} 
//     ${(acc.Room__c || acc.Floor__c) && acc.Supplement__c ? ', ' : ''}${acc.Supplement__c ? `Wing: ${acc.Supplement__c},<br/>` : acc.Room__c || acc.Floor__c ? '<br/>' : ''}
    
//     ${acc.Building_Name_Conn__c ? `Building: ${acc.Building_Name_Conn__c},<br/>` : ''}
//     ${streetLines1 ? `${streetLines1},<br/>` : ''}
//     ${streetLines2 ? `${streetLines2},<br/>` : ''}
//     ${acc.Other_City__c || acc.District__c || acc.City__c || acc.Postal_Code__c
//     ? `${acc.Other_City__c ? acc.Other_City__c + ', ' : ''}${acc.District__c ? acc.District__c + ', ' : ''}${acc.City__c ? acc.City__c + ' - ' : ''}${acc.Postal_Code__c || ''}<br/>`
//     : '<br/>'}

//     <div style="margin-top: 10px;">
//         Tel: ${acc.Secondary_Telephone__c || '0'} <br/>
//         Mob: ${acc.Phone || '0'}
//     </div>

//     <div style="margin-top: 10px;">
//         <strong>Sub: ${this.form.Type__c || 'Acknowledgement'}</strong>
//     </div>

//     <div style="margin-top: 10px;">
//         ${acc.BP_Number__c ? `<strong>Business Partner Number (BP): ${acc.BP_Number__c}</strong><br/>` : ''}
//         ${cs.CaseNumber ? `<strong>Case / Docket Number: ${cs.CaseNumber}</strong>` : ''}
//     </div>
//     <div style="margin-top: 25px;">
//                 Dear Sir/Madam,<br/>
//                  <div style="margin-top: 10px;">
//               Thank you for giving us an opportunity to serve you and we acknowledge your letter received by us on ${dateValue}.</div>
//                  <div style="margin-top: 10px;">
//                 Our team will review your concern with due care and update the status to you suitably. However in order to track the status of your service request, we hereby assign the Docket No.${cs.CaseNumber} and request you to kindly quote this docket number in case of any further correspondence with respect to this specific matter.</div>
// </div>
// </div>
// `;




//     await generateAndAttachLetterPDF({
//         caseId: this.createdCaseId,
//         objectType: this.objectApiName,
//         templateBody: letterBody
//     });
// } catch (error) {
//     console.error('Error generating letter PDF:', error);
//     this.showToast('Error', 'Failed to generate letter PDF', 'error');
// }
//         }
const letterOriginApiNames = ['2', '8', '9', '17', '22', '23'];

if (this.form.Origin && letterOriginApiNames.includes(this.form.Origin)) {
    console.log('entered id');
    console.log(' this.createdCase', JSON.stringify(this.createdCase));
    try {
        let isAccount = this.objectApiName === 'Account';
        let isLead = this.objectApiName === 'Lead';
        
        let templateBody = '';
        const cs = this.createdCase || {};

        // Get today's date
        let today = new Date();
        let day = String(today.getDate()).padStart(2, '0');
        let month = String(today.getMonth() + 1).padStart(2, '0');
        let year = today.getFullYear();
        let dateValue = `${day}.${month}.${year}`;

        let months = today.getMonth() + 1;
        let fy = '';
        if (months >= 4) {
            fy = year + '-' + String(year + 1).slice(-2);
        } else {
            fy = (year - 1) + '-' + String(year).slice(-2);
        }

        if (isAccount) {
            const acc = this.accountdetail || {};
            
            templateBody = `
            <table style="width: 100%; margin-top: 10px;">
                <tr>
                    <td style="text-align: left;">
                        <strong>Ref No: MGL/CRM/${cs.CaseNumber}/${fy}</strong>
                    </td>
                    <td style="text-align: right;"><strong>Date: ${dateValue}</strong></td>
                </tr>
            </table>
            <div style="margin-top: 8px; line-height: 1.4;">
                To,<br/>
                <strong>${acc.Person_Title__c || ''} ${acc.Full_Name__c || 'Customer'}</strong><br/>
                ${acc.Room__c ? `Flat No: ${acc.Room__c}` : ''} 
                ${acc.Room__c && acc.Floor__c ? ', ' : ''}${acc.Floor__c ? `Floor No: ${acc.Floor__c}` : ''} 
                ${(acc.Room__c || acc.Floor__c) && acc.Supplement__c ? ', ' : ''}${acc.Supplement__c ? `Wing: ${acc.Supplement__c},<br/>` : acc.Room__c || acc.Floor__c ? '<br/>' : ''}
                
                ${acc.Building_Name_Conn__c ? `Building: ${acc.Building_Name_Conn__c},<br/>` : ''}
                ${acc.Street__c ? `${acc.Street__c},<br/>` : ''}
                ${acc.Street_Line_3__c ? `${acc.Street_Line_3__c},<br/>` : ''}
                ${acc.Street_Line_4__c ? `${acc.Street_Line_4__c},<br/>` : ''}
                ${acc.Street_Line_5__c ? `${acc.Street_Line_5__c},<br/>` : ''}
                ${acc.Other_City__c || acc.District__c || acc.City__c || acc.Postal_Code__c
                ? `${acc.Other_City__c ? acc.Other_City__c + ', ' : ''}${acc.District__c ? acc.District__c + ', ' : ''}${acc.City__c ? acc.City__c + ' - ' : ''}${acc.Postal_Code__c || ''}<br/>`
                : '<br/>'}

                <div style="margin-top: 10px;">
                    Tel: ${acc.Secondary_Telephone__c || '0'} <br/>
                    Mob: ${acc.Phone || '0'}
                </div>

                <div style="margin-top: 10px;">
                    <strong>Sub: ${this.form.Type__c || 'Acknowledgement'}</strong>
                </div>

                <div style="margin-top: 10px;">
                    ${acc.BP_Number__c ? `<strong>Business Partner Number (BP): ${acc.BP_Number__c}</strong><br/>` : ''}
                    ${cs.CaseNumber ? `<strong>Case / Docket Number: ${cs.CaseNumber}</strong>` : ''}
                </div>
                <div style="margin-top: 25px;">
                    Dear Sir/Madam,<br/>
                    <div style="margin-top: 10px;">
                        Thank you for giving us an opportunity to serve you and we acknowledge your letter received by us on ${dateValue}.</div>
                    <div style="margin-top: 10px;">
                        Our team will review your concern with due care and update the status to you suitably. However in order to track the status of your service request, we hereby assign the Docket No.${cs.CaseNumber} and request you to kindly quote this docket number in case of any further correspondence with respect to this specific matter.</div>
                </div>
            </div>
            `;

        } else if (isLead) {
            const lead = this.lead || {};
            
            templateBody = `
            <table style="width: 100%; margin-top: 10px;">
                <tr>
                    <td style="text-align: left;">
                        <strong>Ref No: MGL/CRM/${cs.CaseNumber}/${fy}</strong>
                    </td>
                    <td style="text-align: right;"><strong>Date: ${dateValue}</strong></td>
                </tr>
            </table>
            <div style="margin-top: 8px; line-height: 1.4;">
                To,<br/>
                <strong>${lead.Name || 'Customer'}</strong><br/>
                ${lead.Flat__c ? `Flat No: ${lead.Flat__c}` : ''} 
                ${lead.Flat__c && lead.Floor__c ? ', ' : ''}${lead.Floor__c ? `Floor No: ${lead.Floor__c},<br/>` : ''}
                ${lead.Building_Name__c ? `Building: ${lead.Building_Name__c},<br/>` : ''}
                                
                ${lead.Street__c && lead.Street_Line_3__c ? `${lead.Street__c}, ${lead.Street_Line_3__c},<br/>` : ''}
                ${lead.Street__c && !lead.Street_Line_3__c ? `${lead.Street__c},<br/>` : ''}
                ${!lead.Street__c && lead.Street_Line_3__c ? `${lead.Street_Line_3__c},<br/>` : ''}
                ${lead.Street_Line_4__c ? `${lead.Street_Line_4__c},<br/>` : ''}
                ${lead.Street_Line_5__c ? `${lead.Street_Line_5__c},<br/>` : ''}
                ${lead.Other_City__c || lead.District__c || lead.City__c || lead.Postal_Code__c
                ? `${lead.Other_City__c ? lead.Other_City__c + ', ' : ''}${lead.District__c ? lead.District__c + ', ' : ''}${lead.City__c ? lead.City__c + ' - ' : ''}${lead.Postal_Code__c || ''}<br/>`
                : '<br/>'}

                <div style="margin-top: 10px;">
                    Tel: ${lead.Phone || '0'} <br/>
                    Mob: ${lead.MobilePhone || '0'}
                </div>

                <div style="margin-top: 10px;">
                    <strong>Sub: ${this.form.Type__c || 'Acknowledgement'}</strong>
                </div>

               <div style="margin-top: 10px;">
    ${lead.Lead_No__c ? `<div><strong>Prospect Number: ${lead.Lead_No__c}</strong></div>` : ''}
    ${cs.CaseNumber ? `<div><strong>Case / Docket Number: ${cs.CaseNumber}</strong></div>` : ''}
</div>

                <div style="margin-top: 25px;">
                    Dear Sir/Madam,<br/>
                    <div style="margin-top: 10px;">
                        Thank you for giving us an opportunity to serve you and we acknowledge your letter received by us on ${dateValue}.</div>
                    <div style="margin-top: 10px;">
                        Our team will review your concern with due care and update the status to you suitably. However in order to track the status of your service request, we hereby assign the Docket No.${cs.CaseNumber} and request you to kindly quote this docket number in case of any further correspondence with respect to this specific matter.</div>
                </div>
            </div>
            `;
        }

        await generateAndAttachLetterPDF({
            caseId: this.createdCaseId,
            objectType: this.objectApiName,
            templateBody: templateBody
        });
        
    } catch (error) {
        console.error('Error generating letter PDF:', error);
        this.showToast('Error', 'Failed to generate letter PDF', 'error');
    }
}
        // 11. Final actions
        this.resetForm();
        this.isLoading = false;
        this.dispatchEvent(new RefreshEvent());
        this.dispatchEvent(new CloseActionScreenEvent());

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.createdCaseId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });

        this.showToast('Success', 'Case created successfully!', 'success');
    } catch (error) {
        this.isLoading = false;
        let message = 'An error occurred while creating the case';
        if (error && error.body && error.body.message) {
            message = error.body.message;
            const customValidationMatch = message.match(/FIELD_CUSTOM_VALIDATION_EXCEPTION, (.+?): \[/);
            if (customValidationMatch && customValidationMatch[1]) {
                message = customValidationMatch[1];
            }
        } else if (error && error.message) {
            message = error.message;
        }
        this.showToast('Error', message, 'error');
    }
}

handleDuplicateCancel() {
    this.showDuplicateConfirm = false;
    this.duplicateConfirmed = false;
    this.pendingSubmit = false;
}

handleDuplicateYes() {
    this.showDuplicateConfirm = false;
    this.duplicateConfirmed = true;

    if (this.pendingSubmit) {
        this.pendingSubmit = false;
        this.handleSubmit(); // retry creation
    }
}



    resetForm() {
        this.showDuplicateConfirm = false;
this.duplicateConfirmed = false;
this.pendingSubmit = false;

        // Reset the form object with a new reference to ensure reactivity
        this.template.querySelectorAll('[data-id="desc"]').forEach(item => {
    item.value = '';
});
        this.form = {
            Department__c:'',
            Category__c: '',
            Type__c: '',
            Sub_Type__c: '',
            Priority: '',
            Value_1__c: '',
            Value_2__c: '',
            Value_3__c: '',
            Value_4__c: '',
            Value_5__c: '',
            Value_6__c: '',
            Value_7__c: '',
            Value_8__c: '',
            Origin: '',
            New_First_Name__c: '',
            New_Middle_Name__c: '',
            New_Last_Name__c: '',
            Meter_reading__c: '',
            New_Salutation__c: '', 
            From_Date__c: '',
            Number_of_Months__c: '',
            To_Date__c: '',
            Sub_Origin__c:'',
            Refund_Amount__c: null,
            Refund_Type__c: '',
            Request_Submission_Date__c: null,
            Account_Type__c: '',
            Bank_Name__c: '',
            Branch_Name__c: '',
            IFSC_Code__c: '',
            Account_Number__c: null,
            Account_Holder_Name__c: '' ,
            Ticket_Number__c:'' ,
            Mode_Of_Payment__c:'',
            Contact_Directions__c:'',
            Send_SMS_to__c: '',
            Contacted_By__c: '',
            Relationship_to_the_owner__c: '',
            New_email_id__c: '',
            New_Contact__c: '',
            Call_Received_From__c: '',
            Amount__c: '',
            PD_Reason__c: '',
            New_Address__c: ''

            };
         // Reset document related states
    this.uploadedDocuments = [];
    this.selectedDocType = '';
    this.selectedDocuments = [];
    this.docdescription = '';
    this.salutationOptions = [];
    
    // Reset document checkboxes
    this.docTypeOptions = this.docTypeOptions.map(option => ({
        ...option,
        checked: false
    }));
    
    // Reset categories and document selections
    this.categories = this.categories.map(category => ({
        ...category,
        checked: false,
        options: category.options.map(option => ({
            ...option,
            checked: false
        }))
    }));
        this.tat = '';
        this.tatDays = '';
        this.tatMinutes = '';
        this.department = '';
        this.spoc = '';
        this.qrcId = '';
        this.autoCreateWorkOrder=false;
        this.picklistFieldNames.forEach(f => {
            if (f !== 'Department__c'&&f !== 'Category__c' && f !== 'Priority' && f !== 'Account_Type__c' && f !== 'Origin' && f!=='Sub_Origin__c' &&f!=='Mode_Of_Payment__c') {
                this.options[f] = [];
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    // Getter Methods for disabling fields
   get isTypeDisabled() {
        return !this.typeOptions || this.typeOptions.length === 0;
    }
    get isCategoryDisabled(){
         return !this.categoryOptions || this.categoryOptions.length === 0;
    }
    get isSubTypeDisabled() {
        return !this.subTypeOptions || this.subTypeOptions.length === 0;
    }
    get isValue1Disabled() {
        return !this.valueOptions || this.valueOptions.length === 0;
    }
    get showValue2() {
        return this.form.Value_1__c && this.options.Value_2__c && this.options.Value_2__c.length > 0;
    }
    get showValue3() {
        return this.form.Value_2__c && this.options.Value_3__c && this.options.Value_3__c.length > 0;
    }
    get showValue4() {
        return this.form.Value_3__c && this.options.Value_4__c && this.options.Value_4__c.length > 0;
    }
    get showValue5() {
        return this.form.Value_4__c && this.options.Value_5__c && this.options.Value_5__c.length > 0;
    }
    get showValue6() {
        return this.form.Value_5__c && this.options.Value_6__c && this.options.Value_6__c.length > 0;
    }
    get showValue7() {
        return this.form.Value_6__c && this.options.Value_7__c && this.options.Value_7__c.length > 0;
    }
    get showValue8() {
        return this.form.Value_7__c && this.options.Value_8__c && this.options.Value_8__c.length > 0;
    }
     get isAccount() {
        return this.objectApiName === 'Account';
    }

    get isLead() {
        return this.objectApiName === 'Lead';
    }

    get accountName() {
        return this.account?.Name || this.lead?.Name || '';
    }

    get accountPhone() {
        return this.account?.Phone || this.lead?.Phone || '';
    }

    get accountEmail() {
        return this.account?.Account_Email__c || this.lead?.Email || '';
    }

    get accountAddress() {
        if (this.account) {
            return `${this.account.Street__c || ''}, ${this.account.City__c || ''}, ${this.account.Postal_Code__c || ''}`;
        } else if (this.lead) {
            return `${this.lead.Street__c || ''}, ${this.lead.City__c || ''}, ${this.lead.Postal_Code__c || ''}`;
        }
        return '';
    }

    get hasCases() {
        return this.cases && this.cases.length > 0;
    }

    get showCallReceivedFrom() {
        // if Origin picklist API value for Telephone is '1'
        return this.form.Origin === '1'|| this.form.Origin==='15'|| this.form.Origin==='21'|| this.form.Origin==='20'|| this.form.Origin==='14'|| this.form.Origin==='12'|| this.form.Origin==='13';
    }

    



    
    clearValues(value){
    if(value == 'Department__c'){
        this.form.Category__c = '';
        this.form.Type__c = '';
        this.form.Sub_Type__c = '';
        this.form.Value_1__c = '';
        this.form.Mode_Of_Payment__c = '';
        this.form.New_email_id__c = '';
        this.form.New_Contact__c = '';
        this.form.Meter_reading__c='';
        this.form.From_Date__c = '';
        this.form.New_Salutation__c = ''; 
        this.form.Number_of_Months__c = '';
        this.form.To_Date__c = '';
    }

    if(value == 'Category__c'){
        this.form.Type__c = '';
        this.form.Sub_Type__c = '';
        this.form.Value_1__c = '';
        this.form.Mode_Of_Payment__c = '';
        this.form.New_email_id__c = '';
        this.form.New_Contact__c = ''
        this.form.Meter_reading__c='';
        this.form.New_Salutation__c = ''; 
        this.form.From_Date__c = '';
        this.form.Number_of_Months__c = '';
        this.form.To_Date__c = '';
    }
     if(value == 'Type__c'){
        this.form.Sub_Type__c = '';
        this.form.Value_1__c = '';
        this.form.Mode_Of_Payment__c = '';
        this.form.New_email_id__c = '';
        this.form.New_Contact__c = '';
        this.form.Meter_reading__c='';
        this.form.New_Salutation__c = ''; 
        this.form.From_Date__c = '';
        this.form.Number_of_Months__c = '';
        this.form.To_Date__c = '';
    }
     if(value == 'Sub_Type__c'){
        this.form.Value_1__c = '';
        this.form.Mode_Of_Payment__c = '';
        this.form.New_email_id__c = '';
        this.form.New_Contact__c = '';
        this.form.Meter_reading__c='';
        this.form.From_Date__c = '';
        this.form.New_Salutation__c = ''; 
        this.form.Number_of_Months__c = '';
        this.form.To_Date__c = '';
    }
}

    get relativeDateDisplay() {
        return this.caseRecord?.relativeDate ? this.caseRecord.relativeDate : 'NA';
    }
    getRelativeTime(date) {
        const now = new Date();
        const diff = Math.floor((now - date) / 1000); // seconds

        const rtf = new Intl.RelativeTimeFormat('en', { numeric: 'auto' });

        if (diff < 60) return rtf.format(-diff, 'second');
        if (diff < 3600) return rtf.format(-Math.floor(diff / 60), 'minute');
        if (diff < 86400) return rtf.format(-Math.floor(diff / 3600), 'hour');
        if (diff < 604800) return rtf.format(-Math.floor(diff / 86400), 'day');

        return date.toLocaleDateString();
    }
    formatDate(isoDate) {
        const date = new Date(isoDate);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    }
    handleCaseClick(event) {
        // Get the case Id from the clicked div's data-id attribute
        const caseId = event.currentTarget.dataset.id;

        console.log('Clicked case Id:', caseId);
        if (!caseId) {
            console.error('Case ID not found!');
            return;
        }

        // Navigate to the Case record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }
    // JS file
    get connectionName() {
        return this.account && this.account.Premise__r && this.account.Premise__r.Connection_Name__c
            ? this.account.Premise__r.Connection_Name__c
            : '';
    }

    @track form = { ParentId: null };
    @track resultMessage = '';

    handleParentCaseChange(event) {
        // event.detail.Id contains the selected record Id
        this.form.ParentId = event.detail.Id;
    }


    get isCheckboxDisabled() {
        return !this.form.ParentId;
    }

    @track docTypeOptions = [];
    @track selectedDocType = '';
    @track docdescription = '';
    @track uploadedDocuments = [];

    acceptedFormats = ['.pdf', '.docx', '.jpg', '.png'];
     get isVisible() {
        return this.recordId && ['Account', 'Lead'].includes(this.objectApiName);
    }

 connectedCallback() {
     console.log('connectedCallback executed');
        console.log('recordId:', this.recordId);
        console.log('objectApiName:', this.objectApiName);
    this.loadDocTypeOptions();
    this.fetchAttendance();

    if (!this.form.Remarks__c || this.form.Remarks__c.trim() === '') {
const benchmark = this.form.Benchmark__c;
const category = this.form.Category__c || '';

this.defaultDescription = [
    benchmark ? `ETA - ${benchmark}` : null,
    category
].filter(Boolean).join(' ').trim();
        this.form.Remarks__c = this.defaultDescription;
        
        setTimeout(() => {
            const textarea = this.template.querySelector('[data-id="desc"]');
            if (textarea) {
                textarea.value = this.form.Remarks__c;
            }
        }, 0);
    }
     if (this.objectApiName !== 'Account' && this.objectApiName !== 'Lead') {
            console.error('Component only works on Account and Lead records');
            return;
        }
    this.fetchUserTypeOfWork();
}
// Add this method to fetch user info
fetchUserTypeOfWork() {
    getUserInfo()
        .then(result => {
            this.userTypeOfWork = result.Type_Of_Work__c || '';
 
            // 👇 read nested relationship field Profile.Name
            this.userProfileName =
                (result.Profile && result.Profile.Name)
                    ? result.Profile.Name
                    : '';
 
            // console.log('USER DEBUG', JSON.stringify(result), 'userProfileName=', this.userProfileName);
        })
        .catch(error => {
            console.error('Error fetching user info:', error);
        });
}
get isFrontOfficeProfile() {
    const name = (this.userProfileName || '').trim().toLowerCase();
    // return name === 'crm frontoffice agent';
    // return name.startsWith('crm front');
    return name.startsWith('crm frontoffice') || name.startsWith('crm front office');
}
get isBackOfficeProfile() {
    const name = (this.userProfileName || '').trim().toLowerCase();
    return name.includes('crm back');
}
get isLetterOrigin() {
    const letterOriginApiNames = ['2', '8', '9', '17', '22', '23'];
    return this.form.Origin && letterOriginApiNames.includes(this.form.Origin);
}

hasUserUploadedDocuments() {
    if (!this.uploadedDocuments) {
        return false;
    }

    // Case 1: uploadedDocuments is an array
    if (Array.isArray(this.uploadedDocuments)) {
        return this.uploadedDocuments.length > 0;
    }

    // Case 2: uploadedDocuments is an object (Proxy/Object)
    if (typeof this.uploadedDocuments === 'object') {
        return Object.keys(this.uploadedDocuments).length > 0;
    }

    return false;
}



// Add this getter
get isSubOriginDisabled() {
    return this.userTypeOfWork === 'Front Office';
}


    fetchAttendance() {
        getLatestAttendanceToday()
            .then(record => {
                if (record) {
                    if (record.Day_Out_Timestamp__c) {
                        this.showToast('You cannot create a Case after Check-Out');
                        this.attendanceId = null;
                        this.checkin = false;
                    } else {
                        this.attendanceId = record.Id;
                        this.checkin = true;
                        console.log('Today’s Attendance ID:', this.attendanceId);
                    }
                } else {
                    this.attendanceId = null;
                    this.checkin = false;
                    this.showCheckInToast();
                }
            })
            .catch(error => {
                console.error('Error fetching attendance:', error);
                this.showToast('Please do Check-In');
            });
    }


    showCheckInToast() {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Missing Check-In',
            message: 'Please check-in first.',
            variant: 'warning',
        }));
    }

    showErrorToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
        }));
    }
  loadDocTypeOptions() {
        getTypeOfDocumentPicklistValues({ transferType: this.transfervalue })
            .then(result => {
                this.docTypeOptions = result.map(option => ({
                    label: option.label,
                    value: option.value,
                    checked: false
                }));
                console.log('Loaded document type options:', this.docTypeOptions);
            })
            .catch(error => {
                console.error('Error loading document options:', error);
                this.showToast('Error', 'Failed to load document types', 'error');
            });
    }

    handleDocTypeChange(event) {
        this.selectedDocType = event.target.inputValue;
    }

    @track selectedDocuments = [];

 
    // File Upload Handling
    handleFileUploadFinished(event) {
    const uploadedFiles = event.detail.files;
    if (uploadedFiles.length === 0) return;

    // Get document types based on case type
    const docTypes = this.isNameTransferRelated 
        ? this.selectedDocuments.map(doc => doc.name) 
        : this.selectedDocTypes;

    // if (docTypes.length === 0) {
    //     this.showToast('Error', 'Please select document types before uploading', 'error');
    //     return;
    // }

    // Create new document entries
    const newDocuments = uploadedFiles.map(file => ({
        documentId: file.documentId,
        fileName: file.name,
        docType: docTypes.join(', '), // Store all selected types
        docTypes: [...docTypes], // Keep as array for validation
        description: this.docdescription || '',
        previewUrl: `/lightning/r/ContentDocument/${file.documentId}/view`
    }));

    this.uploadedDocuments = [...this.uploadedDocuments, ...newDocuments];
    this.docdescription = '';
    this.showToast('Success', `${uploadedFiles.length} file(s) uploaded successfully`, 'success');
}



// JS function to calculate benchmark estimate
getEstimatedBenchmarkDate(tatInHours) {
    const now = new Date();
    const estimatedTime = now.getTime() + (tatInHours * 60 * 60 * 1000); // Convert hours to ms
    return new Date(estimatedTime);
}
// Tracked properties
@track docTypeOptions = [];
@track selectedDocTypes = [];

// For non-Name Transfer cases
   handleCheckboxChange(event) {
    const value = event.target.value;
    const isChecked = event.target.checked;

    this.docTypeOptions = this.docTypeOptions.map(option => {
        if (option.value === value) {
            return { ...option, checked: isChecked };
        }
        return option;
    });

    // Handle "None" selection
    if (value === 'None' && isChecked) {
        this.docTypeOptions = this.docTypeOptions.map(option => {
            if (option.value !== 'None') {
                return { ...option, checked: false };
            }
            return option;
        });
    }

    // If any other option is selected, uncheck "None"
    if (value !== 'None' && isChecked) {
        this.docTypeOptions = this.docTypeOptions.map(option => {
            if (option.value === 'None') {
                return { ...option, checked: false };
            }
            return option;
        });
    }

    this.selectedDocTypes = this.docTypeOptions
        .filter(option => option.checked && option.value !== 'None')
        .map(option => option.value);
}

handleDocumentsSelected(event) {
    this.selectedDocuments = event.detail || [];
}
async fetchCaseNumber(caseId) {
    if (!caseId) {
        console.error('No Case ID provided');
        return null;
    }

    try {
        const result = await getCaseWithNumber({ caseId });
        console.log('Fetched Case Number:', result.CaseNumber);
        // Optionally update local state
        this.createdCase = { ...this.createdCase, CaseNumber: result.CaseNumber };
        return result.CaseNumber;

    } catch (error) {
        console.error('Error fetching Case Number:', error);
        this.showToast('Error', 'Unable to fetch Case Number', 'error');
        return null;
    }
}


validateDocuments() {
    // For non-name transfer cases
    if (!this.isNameTransferRelated) {
        // Get all checked document types
        const checkedTypes = this.docTypeOptions
            .filter(option => option.checked && option.value !== 'None');
        
        // Only throw error if at least one checkbox is checked AND no documents are uploaded
        if (checkedTypes.length > 0 && this.uploadedDocuments.length === 0) {
            this.showToast('Error', 'Please upload documents for the selected types', 'error');
            return false;
        }
        return true;
    }

    // For name transfer cases
    const hasSelectedDocuments = this.selectedDocuments.length > 0;
    const hasUploadedDocuments = this.uploadedDocuments.length > 0;

    if (hasSelectedDocuments && !hasUploadedDocuments) {
        this.showToast('Error', 'Please upload documents for the selected types', 'error');
        return false;
    }

    return true;
}
handleDiscardFile(event) {
    const documentId = event.currentTarget.dataset.id;

    this.uploadedDocuments = this.uploadedDocuments.filter(doc => doc.documentId !== documentId);

    this.showToast('Info', 'Document discarded.', 'info');
}
// Replace your existing getter at line 2405 with this:
get showNameCorrectionFields() {
    return this.form.Department__c === 'CRM' && 
           this.form.Category__c==='Request'&&
           this.form.Type__c === 'Name Correction' &&
           this.form.Sub_Type__c === 'Name Correction' 
}
// Add this getter method to your JavaScript class
get showNewSalutationField() {
          return this.form.Department__c === 'CRM' && 
          this.form.Category__c==='Request'&&
          this.form.Type__c === 'Name Correction' &&
          this.form.Sub_Type__c === 'Name Correction - Title Error';
}

get showAmountField() {
    return this.form.Department__c === 'CRM' &&
           this.form.Category__c === 'Query' &&
           this.form.Type__c === 'Redressal Processed';
}

get isAmountRequired() {
    return (
        this.form.Department__c === 'CRM' &&
        this.form.Category__c === 'Query' &&
        this.form.Type__c === 'Redressal Processed'
    );
}

get showPDReason() {
        const dept = this.form.Department__c;
        const cat  = this.form.Category__c;
        const type = this.form.Type__c;
        const sub  = (this.form.Sub_Type__c || '').toLowerCase();

        const isPD =
            dept === 'Aftersales' &&
            cat === 'Request' &&
            type === 'Permanent Disconnection & Refund Process' &&
            sub.includes('individual permanent disconnection');

        console.log('🧪 PD CHECK', {
            dept,
            cat,
            type,
            sub,
            result: isPD
        });

        return isPD;
    }

    get showNewAddressField() {
        const showPD = this.showPDReason;
        const reason = this.form.PD_Reason__c;

        const show =
            showPD &&
            reason === 'Redevelopment of society';

        return show;
    }





fetchSalutationPicklistValues() {
    // The salutation options are already available in this.options.New_Salutation__c
    // from the wire service above
    
    // If you want to store them separately, you can do:
    this.salutationOptions = this.options.New_Salutation__c || [];
    
}
}