import { LightningElement, api, track } from 'lwc';
import getComplaints from '@salesforce/apex/CNG_ProfileCardController.getRecords';
import { NavigationMixin } from 'lightning/navigation';

export default class Cng_technicalComplaints extends NavigationMixin(LightningElement) {
    @api recordId;          // Record ID passed from community page
    @api filter = '';  
    @api listName;     // Optional filter string
    @api objectApiName;     // Object API name passed from page
    @track records = [];    // Dynamic records
    @track columns = [];    // Columns config for table

    sortDirection = 'desc'; // default
    sortedField;            // field being sorted

    // Configure fields for your object here dynamically
    // For example, if objectApiName = 'Complaint__c'
    fieldConfigsByList = {
    'Technical Complaint': [
        { label: 'Notification', fieldName: 'Name' },
        { label: 'Created Date', fieldName: 'CreatedDate' },
        { label: 'Category', fieldName: 'Category__c' },
        { label: 'Sub-Category', fieldName: 'Sub_Category__c' },
        { label: 'Reported By', fieldName: 'CreatedByName' },
        { label: 'Closed Date', fieldName: 'Closed_Date__c' },
        { label: 'Status', fieldName: 'Status__c' }
    ],

    'Non Technical Complaint': [
        { label: 'Category', fieldName: 'Category__c' ,type: 'url',
        urlField: 'recordUrl'},
        { label: 'Sub-Category', fieldName: 'Sub_Category__c' },
        { label: 'Complaint Description', fieldName: 'Complaint_Description__c' },
        { label: 'Status', fieldName: 'Status__c' }
    ],

    'Retail Outlet Compliance': [
        { label: 'Document Name', fieldName: 'Document_Name__c',type: 'url',
        urlField: 'recordUrl' },
        { label: 'Created On', fieldName: 'CreatedDate' },
        { label: 'Start Date', fieldName: 'Start_Date__c' },
        { label: 'Expiry Date', fieldName: 'Expiry_Date__c' },
        { label: 'Status', fieldName: 'Status__c' },
    ],
    'STC Card':[
        { label: 'STC Number', fieldName: 'STC_Number__c',type: 'url',
        urlField: 'recordUrl'  },
        { label: 'Name', fieldName: 'STC_Name__c' },
        { label: 'Start Date', fieldName: 'Start_Date__c' },
        { label: 'Expiry Date', fieldName: 'Expiry_Date__c' },
        { label: 'Status', fieldName: 'Status__c' }
    ]
};

    connectedCallback() {
    // Pick fields based on listName
    this.columns =
        this.fieldConfigsByList[this.listName] ||
        this.fieldConfigsByList.Default;

    // Default sort = first column
    if (this.columns.length) {
        this.sortedField = this.columns[0].fieldName;
    }

    this.loadData();
}


   async loadData() {
    if (!this.objectApiName || !this.recordId) return;

    try {
        const result = await getComplaints({
            objectApiName: this.objectApiName,
            recordId: this.recordId,
            filter: this.filter,
            listName: this.listName
        });

        const recordPromises = result.map(async row => {
            let mapped = {
                Id: row.Id
            };

            // Map fields
            this.columns.forEach(col => {
                mapped[col.fieldName] = row[col.fieldName] || '';
            });

            // Generate community-safe URL
            mapped.recordUrl = await this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    objectApiName: this.objectApiName,
                    actionName: 'view'
                }
            });

            return mapped;
        });

        // ✅ Assign ONCE
        this.records = await Promise.all(recordPromises);

        // Default sort
        if (this.sortedField) {
            this.sort(this.sortedField, false);
        }

    } catch (error) {
        console.error('Error fetching records', error);
    }
}


    handleRefresh() {
        this.loadData();
    }

    /* ---------- Sorting ---------- */
    handleSort(event) {
        const field = event.currentTarget.dataset.field;
        this.sort(field);
    }

    sort(field, toggleDirection = true) {
        if (toggleDirection) {
            this.sortDirection =
                this.sortedField === field && this.sortDirection === 'asc'
                    ? 'desc'
                    : 'asc';
        }
        this.sortedField = field;

        this.records = [...this.records].sort((a, b) => {
            let valA = a[field] || '';
            let valB = b[field] || '';

            // Convert dates if the field contains 'Date'
            if (field.includes('Date')) {
                valA = new Date(valA).getTime() || 0;
                valB = new Date(valB).getTime() || 0;
            }

            return this.sortDirection === 'asc'
                ? valA > valB ? 1 : -1
                : valA < valB ? 1 : -1;
        });
    }
   get columnsWithClass() {
    return this.columns.map(col => ({
        ...col,
        isUrl: col.type === 'url',
        sortClass:
            this.sortedField === col.fieldName
                ? `sort-icon ${this.sortDirection}`
                : ''
    }));
}


}