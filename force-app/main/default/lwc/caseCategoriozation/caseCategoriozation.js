import { LightningElement, api, track, wire } from 'lwc';
import getSalutationPicklist from '@salesforce/apex/CasePicklistController.getSalutationPicklist';
import getPDReasonPicklist from '@salesforce/apex/CasePicklistController.getPDReasonPicklist';
import getPicklistValues from '@salesforce/apex/CasePicklistController.getPicklistValues';
import updateCaseRecord from '@salesforce/apex/CasePicklistController.updateCaseRecord';
import getCaseRecord from '@salesforce/apex/CasePicklistController.getCaseRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { RefreshEvent } from 'lightning/refresh';
import { getRecord } from 'lightning/uiRecordApi';


const DEFAULT_SHORTFALL_MONTHS = '6';

const CASE_FIELDS = [
    'Case.AccountId'
    // 'Case.Account.Full_Name__c'
];


export default class CaseCategorization extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isEditing = false;
    @track isEditable = true;
    @track isRemarksEditing = false;
    @track meterReading = '';
    @track fromDate = '';
    @track toDate = '';
    @track numberOfMonths = '';
    @track createdDate = '';

    @track newFirstName = '';
    @track newMiddleName = '';
    @track newLastName = '';
    @track accountdetail = {};
    @track amount = '';
    @track pdReason = '';
    @track newAddress = '';
    @track pdReasonOptions = [];

    @track transferType = '';
    @track nameTransferMode = '';
    @track isNewAddressEditing = false;
    originalNewAddress;

    // Static picklists
    @track departmentOptions = [
        { label: 'Aftersales', value: 'Aftersales' },
        { label: 'BIS', value: 'BIS' },
        { label: 'Billing', value: 'Billing' },
        { label: 'CRM', value: 'CRM' },
        { label: 'Marketing', value: 'Marketing' },
        { label: 'Metering', value: 'Metering' },
        { label: 'O&M District Office', value: 'O&M District Office' },
        { label: 'O&M Support Online', value: 'O&M Support Online' },
        { label: 'Project', value: 'Project' }
    ];

    @track categoryOptions = [
        { label: 'Complaint', value: 'Complaint' },
        { label: 'Query', value: 'Query' },
        { label: 'Request', value: 'Request' }
    ];

    // Dynamic picklists
    @track typeOptions = [];
    @track subTypeOptions = [];
    @track valueOptions = [];

    // Selected values
    @track selectedDepartment = '';
    @track selectedCategory = '';
    @track selectedType = '';
    @track selectedSubType = '';
    @track selectedValue = '';
    @track remarks = '';
    @track typevalue = '';
   // @track meterisSelected = false;
    // New fields for CRM Contact Details
    @track newEmailId = '';
    @track newContact = '';

    @track tatHours;
    @track tatMinutes;
    @track tatDays;
    @track newSalutation = '';

    @track salutationOptions = [];



    // Store the wired case record result for refreshing
    wiredCaseRecordResult;
    _lastAccountId;


    originalValues = {};

    // Conditional visibility getters - SAME LOGIC AS CASECREATIONFORM
    get showCustomerContactFields() {
        return this.selectedDepartment === 'CRM' && 
               this.selectedType === 'Customer Contact Details - Update';
    }
    // Add this getter for billing shortfall fields visibility
    get showBillingShortfallFields() {
        return this.selectedDepartment === 'Billing' &&
            this.selectedCategory === 'Request' &&
            this.selectedType === 'Minimum / Shortfall Charges';
    }

    get showNameCorrectionFields() {
        return this.selectedDepartment === 'CRM' &&
            this.selectedCategory==='Request'&&
            this.selectedType === 'Name Correction' &&
            this.selectedSubType === 'Name Correction';
    }

    get showAmountField() {
        return (
            this.selectedDepartment === 'CRM' &&
            this.selectedCategory === 'Query' &&
            this.selectedType === 'Redressal Processed'
        );
    }




        // Add this getter to check if billing shortfall fields should be required
    get areBillingShortfallFieldsRequired() {
            return this.showBillingShortfallFields;
    }

    get showNewEmailField() {
        return this.showCustomerContactFields && 
               (this.selectedSubType === 'Email Address' || 
                this.selectedSubType === 'Mobile No & Email Address');
    }
   get meterisSelected(){
     return this.selectedDepartment === 'Metering'; 
   }
     get meterisSelectedAMR() {
    return (
        this.selectedDepartment === 'Metering' &&
        (
            (this.selectedSubType && this.selectedSubType==='AMR Update')
        )
    );
}
 


    get showNewContactField() {
        return this.showCustomerContactFields && 
               (this.selectedSubType === 'Mobile No' || 
                this.selectedSubType === 'Mobile No & Email Address');
    }

    get rowClass() {
        return this.isEditingxf
            ? 'slds-grid slds-grid_align-spread slds-p-vertical_small'
            : 'slds-grid slds-grid_align-spread slds-p-vertical_small slds-border_bottom';
    }

    get showPDReason() {
        const subType = (this.selectedSubType || '').toLowerCase();
        return (
            this.selectedCategory === 'Request' &&
            this.selectedType === 'Permanent Disconnection & Refund Process' &&
            subType.includes('individual permanent disconnection')
        );
    }

    get showNewAddressField() {
        return this.showPDReason &&
            this.pdReason === 'Redevelopment of society';
    }


    // ✅ Validation logic - UPDATED TO INCLUDE NEW FIELDS
    get areAllFieldsValid() {
        const hasSubTypeOptions = this.subTypeOptions.length > 0;
        const hasValueOptions = this.valueOptions.length > 0;

        let isValid = (
            this.selectedDepartment &&
            this.selectedCategory &&
            this.selectedType &&
            (hasSubTypeOptions ? this.selectedSubType : true) &&
            (hasValueOptions ? this.selectedValue : true) &&
            this.selectedType !== '-'
        );

        // Additional validation for CRM Contact Update fields
        if (this.showCustomerContactFields) {
            if (this.showNewEmailField && (!this.newEmailId || this.newEmailId.trim() === '')) {
                isValid = false;
            }
            
            if (this.showNewContactField && (!this.newContact || this.newContact.trim() === '')) {
                isValid = false;
            }
        }
         // Additional validation for Billing Shortfall fields
        if (this.showBillingShortfallFields) {
            if (!this.meterReading || this.meterReading.trim() === '') {
                isValid = false;
            }
            if (!this.fromDate) {
                isValid = false;
            }
            if (!this.toDate) {
                isValid = false;
            }
            
            // Date validation: From Date should be before To Date
            if (this.fromDate && this.toDate) {
                const fromDateObj = new Date(this.fromDate);
                const toDateObj = new Date(this.toDate);
                if (fromDateObj > toDateObj) {
                    isValid = false;
                }
            }
        }

        if (this.showAmountField) {
            if (!this.amount || this.amount.trim() === '') {
                isValid = false;
            }
        }


        return isValid;
    }

    @wire(getSalutationPicklist)
    wiredSalutations({ data, error }) {
        if (data) {
            this.salutationOptions = data;
        } else if (error) {
            console.error('Error loading salutation picklist', error);
            this.salutationOptions = [];
        }
    }

    @wire(getPDReasonPicklist)
    wiredPDReasons({ data, error }) {
        if (data) {
            this.pdReasonOptions = data;
        } else if (error) {
            console.error('Error loading PD Reason picklist', error);
            this.pdReasonOptions = [];
        }
    }



    @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
    wiredCaseLDS({ data, error }) {
        if (data) {
            const newAccountId = data.fields.AccountId?.value;

            // Detect Business Partner change
            if (this._lastAccountId !== newAccountId) {
                this._lastAccountId = newAccountId;

                // Update account name immediately
                // this.accountdetail = {
                //     Full_Name__c:
                //         data.fields.Account?.value?.fields?.Full_Name__c?.value || ''
                // };

                // this.newFirstName = '';
                // this.newMiddleName = '';
                // this.newLastName = '';
                // this.newSalutation = '';


                // // 🔁 Refresh Apex-based data
                // if (this.wiredCaseRecordResult) {
                //     refreshApex(this.wiredCaseRecordResult);
                // }

                refreshApex(this.wiredCaseRecordResult);
            }
        } 
        // else if (error) {
        //     console.error('LDS error:', error);
        // }
    }



    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (!this.recordId && currentPageReference) {
            this.recordId = currentPageReference.state?.recordId
                || currentPageReference.state?.c__recordId;

            if (!this.recordId && window.location.pathname) {
                const regex = /\/Case\/([a-zA-Z0-9]{15,18})/;
                const match = window.location.pathname.match(regex);
                if (match) {
                    this.recordId = match[1];
                }
            }
        }
    }

    // Wire method to get case record
    @wire(getCaseRecord, { caseId: '$recordId' })
    wiredCaseRecord(result) {
        this.wiredCaseRecordResult = result;
        if (result.data) {

            this.accountdetail = {
                firstName: result.data.Account?.FirstName__c || '',
                middleName: result.data.Account?.Middle_Name__c || '',
                lastName: result.data.Account?.LastName__c || '',
                fullName: result.data.Account?.Full_Name__c || ''
            };

            //console.log('DEBUG accountdetail:', JSON.stringify(this.accountdetail));
            this.selectedDepartment = result.data.Department__c || '';
            this.selectedCategory = result.data.Category__c || '';
            this.selectedType = result.data.Type__c || '';
            this.typevalue = 
                result.data.Type__c === 'Name Transfer Processed' 
                    ? 'Name Transfer' 
                    : (result.data.Type__c || '');

            this.selectedSubType = result.data.Sub_Type__c || '';
            this.pdReason = result.data.PD_Reason__c || '';
            this.newAddress = result.data.New_Address__c || '';

            this.selectedValue = result.data.Value_1__c || '';
            this.remarks = result.data.Remarks__c || '';
            this.tatHours = result.data.TAT_in_hours__c || null;
            // Load billing shortfall fields
            this.meterReading = result.data.Meter_reading__c || '';
            this.fromDate = result.data.From_Date__c || '';
            this.toDate = result.data.To_Date__c || '';

            this.numberOfMonths = result.data.Number_of_Months__c || '';
            this.createdDate = result.data.CreatedDate;


            this.newEmailId = result.data.New_email_id__c || ''; 
            this.newContact = result.data.New_Contact__c || ''; 
            this.newSalutation = result.data.New_Salutation__c || '';
            this.amount = result.data.Amount__c || '';

            this.newFirstName  = result.data.New_First_Name__c  || '';
            this.newMiddleName = result.data.New_Middle_Name__c || '';
            this.newLastName   = result.data.New_Last_Name__c   || '';

            this.transferType = result.data.Transfer_Type__c || '';
            this.nameTransferMode = result.data.Name_Transfer_Mode__c || '';

            // Disable editing if case already has values
            if (result.data.Department__c || result.data.Category__c || result.data.Type__c) {
                this.isEditable = false;
            }

            // Fetch dependent picklists
            if (this.selectedCategory) this.fetchTypes();
            if (this.selectedType) this.fetchSubTypes();
            if (this.selectedSubType) this.fetchValues();

            if (this.showBillingShortfallFields) {
                this.initializeBillingShortfallDates();
            }

        } else if (result.error) {
            console.error('Error loading case record:', result.error);
        }
    }

    get showNameTransferDetails() {
        const type = (this.selectedType || '').toLowerCase();

        return (
            this.selectedDepartment === 'CRM' &&
            this.selectedCategory === 'Request' &&
            type.includes('name transfer')
        );
    }



    // Enables editing if allowed
    enableEdit() {
        if (!this.isEditable) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Cannot Edit',
                    message: 'This case has already been categorized. Please create a new case to make changes.',
                    variant: 'warning',
                })
            );
            return;
        }

        this.isEditing = true;
        this.originalValues = {
            department: this.selectedDepartment,
            category: this.selectedCategory,
            type: this.selectedType,
            subType: this.selectedSubType,
            pdReason: this.pdReason,
            newAddress: this.newAddress,
            value: this.selectedValue,
            remarks: this.remarks,
            newEmailId: this.newEmailId,
            newContact: this.newContact,
            newFirstName: this.newFirstName,
            newMiddleName: this.newMiddleName,
            newLastName: this.newLastName,
            meterReading: this.meterReading,
            fromDate: this.fromDate,
            toDate: this.toDate,
            numberOfMonths: this.numberOfMonths
        };
    }

    validateNameCorrectionChanges() {


        if (!this.showNameCorrectionFields && !this.showTitleErrorFields) {
            return { isValid: true, message: '' };
        }

        const fullName =
            (this.accountdetail?.fullName ||
            this.wiredCaseRecordResult?.data?.Account?.Full_Name__c ||
            '').trim();


        if (this.showTitleErrorFields) {
            if (!this.newSalutation) {
                return {
                    isValid: false,
                    message: 'New Salutation is mandatory for Title Error.'
                };
            }
            return { isValid: true, message: '' };
        }


        // Mandatory checks
        if (!this.newFirstName?.trim()) {
            return { isValid: false, message: 'New First Name is mandatory for Name Correction.' };
        }

        if (!this.newLastName?.trim()) {
            return { isValid: false, message: 'New Last Name is mandatory for Name Correction.' };
        }




        const currentFullName =
            this.wiredCaseRecordResult?.data?.Account?.Full_Name__c ||
            '';

        if (!currentFullName) {
            return { isValid: false, message: 'Current full name not found' };
        }

        // const currentParts = currentFullName.trim().split(/\s+/);
        // const currentFirst = currentParts[0] || '';
        // const currentMiddle = currentParts.length > 2 ? currentParts[1] : '';
        // const currentLast = currentParts.length > 1 ? currentParts[currentParts.length - 1] : '';



        const oldFirst  = (this.accountdetail.firstName || '').trim();
        const oldMiddle = (this.accountdetail.middleName || '').trim();
        const oldLast   = (this.accountdetail.lastName || '').trim();

        const newFirst  = this.newFirstName.trim();
        const newMiddle = (this.newMiddleName || '').trim();
        const newLast   = this.newLastName.trim();

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

        console.log(
            '📐 DISTANCES',
            JSON.stringify({ firstDiff, middleDiff, lastDiff, totalDiff })
        );

        return { isValid: true, message: '' };
    }


    enableRemarksEdit() {
        this.isRemarksEditing = true;
        this.originalRemarks = this.remarks;
    }

    enableNewAddressEdit() {
        this.isNewAddressEditing = true;
        this.originalNewAddress = this.newAddress;
    }

    handleCancelNewAddress() {
        this.isNewAddressEditing = false;
        this.newAddress = this.originalNewAddress;
    }


    calculateLevenshteinDistance(a = '', b = '') {
    const matrix = [];

    const aLen = a.length;
    const bLen = b.length;

    // Edge cases
    if (aLen === 0) return bLen;
    if (bLen === 0) return aLen;

    // Initialize matrix
    for (let i = 0; i <= bLen; i++) {
        matrix[i] = [i];
    }
    for (let j = 0; j <= aLen; j++) {
        matrix[0][j] = j;
    }

    // Populate matrix
    for (let i = 1; i <= bLen; i++) {
        for (let j = 1; j <= aLen; j++) {
            if (b.charAt(i - 1) === a.charAt(j - 1)) {
                matrix[i][j] = matrix[i - 1][j - 1];
            } else {
                matrix[i][j] = Math.min(
                    matrix[i - 1][j - 1] + 1, // substitution
                    matrix[i][j - 1] + 1,     // insertion
                    matrix[i - 1][j] + 1      // deletion
                );
            }
        }
    }

    return matrix[bLen][aLen];
}


    handleCancel() {
        this.isEditing = false;
        this.isRemarksEditing = false;
        this.isNewAddressEditing = false;
        this.selectedDepartment = this.originalValues.department;
        this.selectedCategory = this.originalValues.category;
        this.selectedType = this.originalValues.type;
        this.selectedSubType = this.originalValues.subType;
        this.pdReason = this.originalValues.pdReason;
        this.newAddress = this.originalValues.newAddress;
        this.selectedValue = this.originalValues.value;
        this.remarks = this.originalValues.remarks;
        this.newEmailId = this.originalValues.newEmailId;
        this.newContact = this.originalValues.newContact;
        this.meterReading = this.originalValues.meterReading;
        this.fromDate = this.originalValues.fromDate;
        this.toDate = this.originalValues.toDate;
        this.numberOfMonths = this.originalValues.numberOfMonths;
        this.newFirstName = this.originalValues.newFirstName;
        this.newMiddleName = this.originalValues.newMiddleName;
        this.newLastName = this.originalValues.newLastName;

    }

    handleNewFirstNameChange(event) {
        this.newFirstName = event.target.value;
    }

    handleNewMiddleNameChange(event) {
        this.newMiddleName = event.target.value;
    }

    handleNewLastNameChange(event) {
        this.newLastName = event.target.value;
    }

    handleNewSalutationChange(event) {
        this.newSalutation = event.detail.value;
    }

    handleAmountChange(event) {
        this.amount = event.target.value;
    }


    handlePDReasonChange(event) {
        this.pdReason = event.detail.value;
    }

    handleNewAddressChange(event) {
        this.newAddress = event.target.value;
    }


    handleCancelRemarks() {
        this.isRemarksEditing = false;
        this.remarks = this.originalRemarks;
    }

    handleDepartmentChange(event) {
        this.selectedDepartment = event.detail.value;
        this.selectedCategory = '';
        this.selectedType = '';
        this.selectedSubType = '';
        this.selectedValue = '';
        this.newEmailId = '';
        this.newContact = '';
        this.meterReading = '';
        this.fromDate = '';
        this.toDate = '';
        this.numberOfMonths = '';
        this.typeOptions = [];
        this.subTypeOptions = [];
        this.valueOptions = [];
    }

    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        this.selectedType = '';
        this.selectedSubType = '';
        this.selectedValue = '';
        this.newEmailId = '';
        this.newContact = '';
        this.meterReading = '';
        this.fromDate = '';
        this.toDate = '';
        this.numberOfMonths = '';
        this.typeOptions = [];
        this.subTypeOptions = [];
        this.valueOptions = [];
        this.fetchTypes();
    }

    handleTypeChange(event) {
        this.typevalue = 
            event.detail.value === 'Name Transfer Processed' 
                ? 'Name Transfer' 
                : event.detail.value;
        this.selectedType = event.detail.value;
        this.selectedSubType = '';
        this.selectedValue = '';
        this.newEmailId = '';
        this.newContact = '';
        this.subTypeOptions = [];
        this.valueOptions = [];
        if (this.selectedType) {
            this.fetchSubTypes();
        }
        if (this.showBillingShortfallFields) {
            this.initializeBillingShortfallDates();
        } else {
            // Moving away from Billing Shortfall: clear fields
            this.meterReading = '';
            this.fromDate = '';
            this.toDate = '';
            this.numberOfMonths = '';
        }

    }

    handleSubTypeChange(event) {
        this.selectedSubType = event.detail.value;
        this.selectedValue = '';
        this.newEmailId = '';
        this.newContact = '';
        // Clear billing shortfall fields when type changes away from Minimum/Shortfall Charges
        if (this.selectedType !== 'Minimum / Shortfall Charges') {
            this.meterReading = '';
            this.fromDate = '';
            this.toDate = '';
            this.numberOfMonths = '';
        }
        this.valueOptions = [];
        if (this.selectedSubType) {
            this.fetchValues();
        }
    }

    handleValueChange(event) {
        this.selectedValue = event.detail.value;
    }

    // Handle new field changes
    handleNewEmailChange(event) {
        this.newEmailId = event.target.value;
    }

    handleNewContactChange(event) {
        this.newContact = event.target.value;
    }

    fetchTypes() {
        if (!this.selectedDepartment || !this.selectedCategory) return;

        getPicklistValues({
            department: this.selectedDepartment,
            category: this.selectedCategory,
            type: '',
        })
        .then((result) => {
            const types = [...new Set(result.map((r) => r.Type__c).filter((t) => t))];

            this.typeOptions = types
                .map((t) => {
                    let label = t === 'Name Transfer Processed' ? 'Name Transfer' : t;
                    return { label, value: t };
                })
                .sort((a, b) => a.label.localeCompare(b.label));
        })
        .catch((error) => {
            console.error('Error fetching Types:', error);
            this.typeOptions = [];
        });
    }

    fetchSubTypes() {
        if (!this.selectedDepartment || !this.selectedCategory || !this.selectedType) return;
        getPicklistValues({
            department: this.selectedDepartment,
            category: this.selectedCategory,
            type: this.selectedType,
        })
            .then((result) => {
                const subTypes = [...new Set(result.map((r) => r.Sub_Type__c).filter((s) => s))];
                this.subTypeOptions = subTypes
                    .map((s) => ({ label: s, value: s }))
                    .sort((a, b) => a.label.localeCompare(b.label));
            })
            .catch((error) => {
                console.error('Error fetching SubTypes:', error);
                this.subTypeOptions = [];
            });
    }

    fetchValues() {
        if (!this.selectedDepartment || !this.selectedCategory || !this.selectedType || !this.selectedSubType) return;
        getPicklistValues({
            department: this.selectedDepartment,
            category: this.selectedCategory,
            type: this.selectedType,
        })
            .then((result) => {
                const filtered = result.filter((r) => r.Sub_Type__c === this.selectedSubType);
                this.valueOptions = filtered
                    .map((r) => ({ label: r.Value_1__c, value: r.Value_1__c }))
                    .filter((v) => v.value)
                    .sort((a, b) => a.label.localeCompare(b.label));

                if (filtered.length) {
                    this.tatHours = filtered[0].TAT_in_hours__c;
                    this.tatMinutes = this.tatHours * 60;
                    this.tatDays = (this.tatHours / 24).toFixed(2);
                }
            })
            .catch((error) => {
                console.error('Error fetching Values:', error);
                this.valueOptions = [];
            });
    }

    // Validation helper method
    validateContactNumber(contactNumber) {
        const phoneRegex = /^[0-9]{10}$/;
        return {
            isValid: phoneRegex.test(contactNumber),
            message: 'Please enter a valid 10-digit contact number'
        };
    }

    initializeBillingShortfallDates() {
        // Hardcode 6 months
        this.numberOfMonths = DEFAULT_SHORTFALL_MONTHS;

        // From Date = Created_Date__c (formula) if available, else today
        if (!this.fromDate) {
            if (this.createdDate) {
                const dt = new Date(this.createdDate);
                const year = dt.getFullYear();
                const month = String(dt.getMonth() + 1).padStart(2, '0');
                const day = String(dt.getDate()).padStart(2, '0');
                this.fromDate = `${year}-${month}-${day}`;   // Local formatted CreatedDate
            }
        }


        this.updateToDateBasedOnMonths();
    }


    updateToDateBasedOnMonths() {
        if (!this.fromDate) {
            this.toDate = '';
            return;
        }

        const monthsInt = parseInt(this.numberOfMonths || DEFAULT_SHORTFALL_MONTHS, 10);
        if (Number.isNaN(monthsInt) || monthsInt <= 0) {
            this.toDate = '';
            return;
        }

        const from = new Date(this.fromDate);
        if (isNaN(from.getTime())) {
            this.toDate = '';
            return;
        }

        const to = new Date(from);
        to.setMonth(to.getMonth() + monthsInt);

        const year = to.getFullYear();
        const month = String(to.getMonth() + 1).padStart(2, '0');
        const day = String(to.getDate()).padStart(2, '0');

        this.toDate = `${year}-${month}-${day}`;
    }

    async handleSaveNewAddress() {
        if (!this.newAddress || !this.newAddress.trim()) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Required',
                    message: 'New Address is required',
                    variant: 'error'
                })
            );
            return;
        }

        try {
            await updateCaseRecord({
                caseId: this.recordId,
                valueMap: {
                    New_Address__c: this.newAddress
                }

            });

            this.isNewAddressEditing = false;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'New Address updated successfully',
                    variant: 'success'
                })
            );

            await refreshApex(this.wiredCaseRecordResult);
        } catch (error) {
            this.showError(error);
        }
    }

    get isAnyInlineEditing() {
        return this.isNewAddressEditing || this.isRemarksEditing;
    }


    async handleSaveRemarks() {
        if (!this.remarks || !this.remarks.trim()) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Required',
                    message: 'Remarks is required',
                    variant: 'error'
                })
            );
            return;
        }

        try {
            await updateCaseRecord({
                caseId: this.recordId,
                remarks: this.remarks
            });

            this.isRemarksEditing = false;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Remarks updated successfully',
                    variant: 'success'
                })
            );

            await refreshApex(this.wiredCaseRecordResult);
        } catch (error) {
            this.showError(error);
        }
    }



    async handleSave() {
        if (!this.areAllFieldsValid) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Incomplete Selection',
                    message: 'Please select valid options for all fields',
                    variant: 'error',
                })
            );
            return;
        }

        if (!this.remarks || this.remarks.trim() === '') {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Required',
                    message: 'Remarks is Required',
                    variant: 'error',
                })
            );
            return;
        }

        // Additional validation for CRM Contact Update fields
        if (this.showCustomerContactFields) {
            // Email validation
            if (this.showNewEmailField && this.newEmailId) {
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(this.newEmailId)) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please enter a valid email address',
                            variant: 'error',
                        })
                    );
                    return;
                }
            }

            // Contact number validation
            if (this.showNewContactField && this.newContact) {
                const contactValidation = this.validateContactNumber(this.newContact);
                if (!contactValidation.isValid) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: contactValidation.message,
                            variant: 'error',
                        })
                    );
                    return;
                }
            }
        }

        // Additional validation for Billing Shortfall fields
        // if (this.showBillingShortfallFields) {
        //     if (this.fromDate && this.toDate) {
        //         const fromDateObj = new Date(this.fromDate);
        //         const toDateObj = new Date(this.toDate);
        //         if (fromDateObj > toDateObj) {
        //             this.dispatchEvent(
        //                 new ShowToastEvent({
        //                     title: 'Error',
        //                     message: 'From Date cannot be after To Date',
        //                     variant: 'error',
        //                 })
        //             );
        //             return;
        //         }
        //     }
        // }

        if (this.showPDReason && !this.pdReason) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Required',
                    message: 'Please select PD Reason',
                    variant: 'error'
                })
            );
            return;
        }

        if (this.showNewAddressField && (!this.newAddress || !this.newAddress.trim())) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Required',
                    message: 'Please enter New Address',
                    variant: 'error'
                })
            );
            return;
        }


        if (this.showBillingShortfallFields) {
            this.initializeBillingShortfallDates();
            if (!this.meterReading || this.meterReading.trim() === '') {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please enter Meter Reading for Minimum / Shortfall Charges',
                        variant: 'error',
                    })
                );
                return;
            }

            if (!this.fromDate) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select From Date for Minimum / Shortfall Charges',
                        variant: 'error',
                    })
                );
                return;
            }

            // const monthsStr = (this.numberOfMonths || '').trim();
            // if (!monthsStr) {
            //     this.dispatchEvent(
            //         new ShowToastEvent({
            //             title: 'Error',
            //             message: 'Please enter Number of Months for Minimum / Shortfall Charges',
            //             variant: 'error',
            //         })
            //     );
            //     return;
            // }

            // const monthsNum = Number(monthsStr);
            // if (
            //     Number.isNaN(monthsNum) ||
            //     !Number.isInteger(monthsNum) ||
            //     monthsNum <= 0
            // ) {
            //     this.dispatchEvent(
            //         new ShowToastEvent({
            //             title: 'Error',
            //             message: 'Number of Months must be a positive whole number',
            //             variant: 'error',
            //         })
            //     );
            //     return;
            // }

            if (!this.toDate) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'To Date could not be calculated. Please check From Date and Number of Months.',
                        variant: 'error',
                    })
                );
                return;
            }

            if (this.fromDate && this.toDate) {
                const fromDateObj = new Date(this.fromDate);
                const toDateObj = new Date(this.toDate);
                if (fromDateObj > toDateObj) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'From Date cannot be after To Date',
                            variant: 'error',
                        })
                    );
                    return;
                }
            }
        }


        const nameValidation = this.validateNameCorrectionChanges();
        if (!nameValidation.isValid) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid Name Correction',
                    message: nameValidation.message,
                    variant: 'error'
                })
            );
            return;
        }

        if (this.showTitleErrorFields && !this.newSalutation) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Required',
                    message: 'Please select New Salutation',
                    variant: 'error'
                })
            );
            return;
        }

        if (this.showAmountField) {
            const amountStr = (this.amount || '').trim();
            const numberRegex = /^\d+(\.\d+)?$/; // integer or decimal

            if (!amountStr) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Amount is required',
                        variant: 'error',
                    })
                );
                return;
            }

            if (!numberRegex.test(amountStr)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Amount must be a valid number (integer or decimal)',
                        variant: 'error',
                    })
                );
                return;
            }
        }



        const valueMap = {
            Value_1__c: this.selectedValue || '',
            PD_Reason__c: this.pdReason || '',
            New_Address__c: this.newAddress || ''
        };


        try {
            // Prepare parameters - only send date fields for Billing Shortfall cases
            const params = {
                caseId: this.recordId,
                department: this.selectedDepartment,
                category: this.selectedCategory,
                type: this.selectedType,
                subType: this.selectedSubType,
                value1: this.selectedValue,
                tatHours: this.tatHours,
                remarks: this.remarks,
                valueMap: valueMap,
                newEmailId: this.newEmailId,
                newContact: this.newContact,
                newFirstName:  this.newFirstName,
                newMiddleName: this.newMiddleName,
                newLastName: this.newLastName,
                newSalutation: this.newSalutation,
                amount: this.amount


            };

            // Only include meter reading and date fields for Billing Shortfall cases
            if (this.showBillingShortfallFields) {
                params.meterReading = this.meterReading;
                params.fromDate = this.fromDate || null; 
                params.toDate = this.toDate || null;    
                params.numberOfMonths = this.numberOfMonths || null;
            } else {
                // For non-Billing cases, explicitly set these to null
                params.meterReading = null;
                params.fromDate = null;
                params.toDate = null;
                params.numberOfMonths = null; 
            }

            await updateCaseRecord(params);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Case updated successfully!',
                    variant: 'success',
                })
            );

            this.isEditing = false;
            this.isEditable = false;
            this.isRemarksEditing = false;
            this.isNewAddressEditing = false;
            await refreshApex(this.wiredCaseRecordResult);
            this.dispatchEvent(new RefreshEvent());

        } catch (error) {
            let message = 'Something went wrong';

            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (error.body) {
                if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                    message = error.body.pageErrors.map(e => e.message).join(', ');
                } else if (error.body.fieldErrors) {
                    const fieldErrorMessages = [];
                    Object.values(error.body.fieldErrors).forEach(fieldErrArray => {
                        fieldErrArray.forEach(err => fieldErrorMessages.push(err.message));
                    });
                    if (fieldErrorMessages.length > 0) {
                        message = fieldErrorMessages.join(', ');
                    } else if (error.body.message) {
                        message = error.body.message;
                    }
                } else if (error.body.message) {
                    message = error.body.message;
                }
            } else if (error.message) {
                message = error.message;
            }

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating case',
                    message,
                    variant: 'error',
                    mode: 'sticky',
                })
            );

            console.error('Error saving case:', error);
        }
}

    // Disable logic getters
    get isCategoryDisabled() {
        return !this.categoryOptions || this.categoryOptions.length === 0;
    }
    get isTypeDisabled() {
        return !this.typeOptions || this.typeOptions.length === 0;
    }
    get isSubTypeDisabled() {
        return !this.subTypeOptions || this.subTypeOptions.length === 0;
    }
    get isValueDisabled() {
        return !this.valueOptions || this.valueOptions.length === 0;
    }

    get showTitleErrorFields() {
        return this.selectedDepartment === 'CRM' &&
            this.selectedCategory==='Request'&&
            this.selectedType === 'Name Correction' &&
            this.selectedSubType === 'Name Correction - Title Error';
    }

    get isNewSalutationRequired() {
        return this.showTitleErrorFields;
    }




    // Input handlers
    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }
    // Add these handler methods
    handleMeterReadingChange(event) {
        this.meterReading = event.target.value;
    }

    handleFromDateChange(event) {
        this.fromDate = event.target.value;
        this.updateToDateBasedOnMonths();   
    }

    handleNumberOfMonthsChange(event) {
        this.numberOfMonths = event.target.value;
        this.updateToDateBasedOnMonths();   
    }

    // handleToDateChange(event) {
    //     this.toDate = event.target.value;
    // }
}