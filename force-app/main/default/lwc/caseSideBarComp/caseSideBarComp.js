import { LightningElement, api, wire, track } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getSidebarCaseDetails from '@salesforce/apex/CaseController.getSidebarCaseDetails';
import getAccountDetails from '@salesforce/apex/AccountDetailsController1.getAccountDetails';
import getRelatedLeadDetails from '@salesforce/apex/CaseController.getRelatedLeadDetails';

export default class CaseSidebar extends LightningElement {
    @api recordId;
    
    // Account related properties
    @track account = null;
    @track device = null;
    @track deviceAllocation = null;
    @track idnumber = null;
    @track servicecontract = null;
    @track minimumcharges =null;
    @track serviceContractNumber = null;

    // Lead related properties
    @track leadRecord = null;
    
    // Case related properties
    @track caseRecord;
    createdDate;
    closedDate;
    lastModifiedDate;
    category;
    previousStatus;
    department;
    
    @track isLoadingLead = false;
    @track warningMessage;
    
    // Platform event subscription
    channelName = '/event/DuplicateCaseEvent__e';
    subscription = {};
    
    connectedCallback() {
        this.registerErrorListener();
        this.subscribeToDuplicateEvents();
    }

    disconnectedCallback() {
        this.unsubscribeFromDuplicateEvents();
    }

    // Wire methods for data fetching
    @wire(getSidebarCaseDetails, { caseId: '$recordId' })
    wiredCase({ data, error }) {
        if (data) {
            this.caseRecord = data;
            this.createdDate = this.formatDateTime(data.CreatedDate);
            this.closedDate = data.ClosedDate ? this.formatDateTime(data.ClosedDate) : '—';
            this.lastModifiedDate = this.formatDateTime(data.LastModifiedDate);
            this.previousStatus = data.Previous_Status__c || '—';
            this.category = data.Category__c ? data.Category__c : '—';
            this.department = data.Department__c ? data.Department__c : '—';
            
            // Check if this case is marked as duplicate
            if (data.Is_Duplicate__c) {
                this.warningMessage = '⚠️ This case has been identified as a duplicate.';
            }
            
            if (data.Lead__c) {
                this.loadLeadDetails(data.Lead__c);
            }
        } else if (error) {
            console.error('Error fetching case:', error);
        }
    }

    @wire(getAccountDetails, { accrcaseId: '$recordId' })
    wiredAccountDetails({ error, data }) {
        if (data) {
            // Properly handle the account data structure
            this.account = data.account || null;
            this.device = data.device || null;
            this.deviceAllocation = data.deviceAllocation || null;
            this.idnumber = data.idnumber || null;
            this.servicecontract = data.servicecontract || null;
            this.minimumcharges = data.minimumcharges || null;
            this.serviceContractNumber = data.serviceContractNumber || null;
        } else if (error) {
            console.error('Error fetching account details:', error);
            this.account = null;
            this.device = null; 
        }
    }

    get displayNumber() {
        return this.caseRecord?.Docket_Number__c && this.caseRecord.Docket_Number__c.trim() !== ''
            ? this.caseRecord.Docket_Number__c
            : this.caseRecord?.CaseNumber;
    }

    get bpOrProspectNumber() {
        if (this.account?.BP_Number__c) {
            return this.account.BP_Number__c;
        } else if (this.caseRecord?.Lead__r?.Lead_No__c) {
            return this.caseRecord.Lead__r.Lead_No__c;
        }
        return '—';
    }

   get caNumber() {
        return this.serviceContractNumber?.Contract_Account_Number__c || 'N/A';
    }

    get applicationNumber() {
        return (this.idnumber && this.idnumber.ID_Number__c) ? this.idnumber.ID_Number__c : 'N/A';
    }

    get meterNumber() {
        return this.device?.meterNumber || 'N/A';
    }

    get lastMeterReading() {
        return (this.deviceAllocation && this.deviceAllocation.lastMeterReading) ? this.deviceAllocation.lastMeterReading : 'N/A';
    }

   get miDate() {
    return (this.servicecontract && this.servicecontract.moveInDate)
        ? this.formatDate(this.servicecontract.moveInDate)
        : 'N/A';
}

get noDate() {
    if (this.servicecontract && this.servicecontract.moveOutDate) {
        const moveOutDate = new Date(this.servicecontract.moveOutDate);
        // Special date check (9999-12-31 or 4000-12-31)
        if (moveOutDate.getFullYear() === 9999) {
            return 'N/A';
        }
        return this.formatDate(this.servicecontract.moveOutDate);
    }
    return 'N/A';
}
    
    get drsName() {
        return this.leadRecord?.DRS__r?.Name || this.leadRecord?.DRS__c || '—';
    }

    get mrDate() {
        return this.deviceAllocation?.lastMeterDate ? this.formatDate(this.deviceAllocation.lastMeterDate) : 'N/A';
    }

    // Add getter for current status (similar to AccountBoxComponent)
    get currentStatus() {
    if (this.servicecontract && this.servicecontract.moveOutDate) {
        const moveOutDate = new Date(this.servicecontract.moveOutDate);
        const today = new Date();

        // Past date → Inactive
        if (moveOutDate < today) {
            return 'Inactive';
        }
        // Future date → Active
        return 'Active';
    }
    // If no moveOutDate → Active
    return 'Active';
}
    // Add getter for status badge class (similar to AccountBoxComponent)
    get badgeClass() {
        const status = this.currentStatus?.toLowerCase();
        if (status === 'active') {
            return 'slds-badge slds-theme_success';
        } else if (status === 'inactive') {
            return 'slds-badge slds-theme_error';
        } else {
            return 'slds-badge slds-theme_warning';
        }
    }
get totalCashAmountDisplay() {
    const value = this.account?.Security_Deposit__c;
    return value != null
        ? Math.abs(Number(value)).toLocaleString('en-IN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        })
        : '0.00';
}


    formatDate(dateValue) {
        if (!dateValue) return 'N/A';
        
        try {
            const date = new Date(dateValue);
            if (isNaN(date.getTime())) return 'N/A';
            
            return date.toLocaleDateString('en-IN', {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric'
            });
        } catch (error) {
            console.error('Error formatting date:', error, dateValue);
            return 'N/A';
        }
    }

    formatDateTime(dateStr) {
        if (!dateStr) return '—';
        const date = new Date(dateStr);
        return date.toLocaleString('en-GB', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            hour12: true
        });
    }

    loadLeadDetails(leadId) {
        this.isLoadingLead = true;
        getRelatedLeadDetails({ leadId: leadId })
            .then(result => {
                this.leadRecord = (result && Object.keys(result).length > 0) ? result : null;
                this.isLoadingLead = false;
            })
            .catch(error => {
                console.error('Error loading lead details:', error);
                this.isLoadingLead = false;
                this.leadRecord = null;
            });
    }

    get premiseId() {
        return (this.servicecontract && this.servicecontract.premiseId) 
            ? this.servicecontract.premiseId 
            : 'N/A';
    }
     get discReason() {
    return (this.minimumcharges?.Blocking_Reason__c && this.minimumcharges?.Blocking_Reason_Text__c)
        ? `${this.minimumcharges.Blocking_Reason__c} - ${this.minimumcharges.Blocking_Reason_Text__c}`
        : 'N/A';
}

    get streetAddress() {
        const street = this.account?.Street__c || '';
        const city = this.account?.City__c || '';
        const postalCode = this.account?.Postal_Code__c || '';
        
        return [street, city, postalCode].filter(part => part).join(', ');
    }

    subscribeToDuplicateEvents() {
        const messageCallback = (response) => {
            const payload = response.data.payload;
            if (payload.CaseId__c === this.recordId) {
                this.warningMessage = payload.Message__c;
            }
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
        });
    }

    unsubscribeFromDuplicateEvents() {
        unsubscribe(this.subscription, () => {
            console.log('Unsubscribed from duplicate case events');
        });
    }

    registerErrorListener() {
        onError(error => {
            console.error('Error with platform event subscription:', error);
        });
    }

    handleDismissWarning() {
        this.warningMessage = null;
    }
}