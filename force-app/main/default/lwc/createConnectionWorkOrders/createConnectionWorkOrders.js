import { LightningElement, api, track } from 'lwc';
import getAccountsFromConnections
    from '@salesforce/apex/CreateConnectionWorkOrdersController.getAccountsFromConnections';
import createWorkOrders
    from '@salesforce/apex/CreateConnectionWorkOrdersController.createWorkOrders';

export default class CreateConnectionWorkOrders extends LightningElement {

   // @api connectionIds = [];
    _connectionIds = [];
    @api
    set connectionIds(value) {
        console.log('👶 Child received connectionIds:', value);

        this._connectionIds = value;

        if (value && value.length > 0) {
            this.isLoading = true;
            this.loadAccounts(); 
        }
    }

    get connectionIds() {
        return this._connectionIds;
    }
    @track accounts = [];
    @track isLoading = false;
    @track message;
    selectedAccountIds = new Set();


    // accountId → { startDate, endDate }
    dateMap = {};

     connectedCallback() {
        this.loadAccounts();
     }

    

handleRowSelection(event) {
    const accId = event.target.dataset.id;

    if (event.target.checked) {
        this.selectedAccountIds.add(accId);
    } else {
        this.selectedAccountIds.delete(accId);
    }

    console.log('Selected Accounts:', Array.from(this.selectedAccountIds));
}


    

    loadAccounts() {
    this.isLoading = true;
    getAccountsFromConnections({ connectionIds: this.connectionIds })
        .then(result => {
            this.accounts = result.map((acc, index) => {
                return {
                    ...acc,
                    rowIndex: index + 1 
                };
            });
            this.isLoading = false;
        })
        .catch(err => {
            this.isLoading = false;
            console.error(err);
        });
}


    //  ONE handler for both fields
    handleDateChange(event) {
        const accId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.detail.value;

        console.log('Date change:', accId, field, value);

        if (!this.dateMap[accId]) {
            this.dateMap[accId] = {};
        }

        // Convert to ISO so Apex Datetime never becomes NULL
        this.dateMap[accId][field] = new Date(value).toISOString();

        console.log('dateMap:', JSON.stringify(this.dateMap));
    }

    
    handleCreateWO() {
    let payload = [];

    this.accounts.forEach(acc => {
        if (!this.selectedAccountIds.has(acc.Id)) {
            return; // ❌ Skip unselected accounts
        }

        const dates = this.dateMap[acc.Id];
        if (dates?.startDate && dates?.endDate) {
            payload.push({
                accountId: acc.Id,
                startDate: dates.startDate,
                endDate: dates.endDate,
                caseId: dates.caseId
            });
        }
    });

    console.log('Payload to Apex:', JSON.stringify(payload));

    if (!payload.length) {
        this.message = 'Please select Accounts and enter Start & End Date';
        return;
    }

    this.isLoading = true;

    createWorkOrders({
        connectionIds: this.connectionIds,
        accountDateWrappers: payload
    })
    .then(res => {
        this.isLoading = false;
        this.message = res;
    })
    .catch(err => {
        this.isLoading = false;
        this.message = err.body?.message || err.message;
    });
}

// Case record picker filter
filter = {
    criteria: [
        {
            fieldPath: 'Department__c',
            operator: 'eq',
            value: 'AFTER SALES'
        },
        {
            fieldPath: 'Sub_Type__c',
            operator: 'eq',
            value: 'Bldg. Demolition - Perm Disconnection & Refund Processing.'
        }
    ]
};

//case
handleCaseChange(event) {
    const accId = event.target.dataset.id;
    const caseId = event.detail.recordId;

    if (!this.dateMap[accId]) {
        this.dateMap[accId] = {};
    }

    this.dateMap[accId].caseId = caseId;

    console.log('Case tagged:', accId, caseId);
}
//case
get showNoAccountsMessage() {
    return (
        !this.isLoading &&
        this.accounts &&
        this.accounts.length === 0 &&
        this.connectionIds &&
        this.connectionIds.length > 0
    );
}


handleBack() {
    this.dispatchEvent(new CustomEvent('back'));
}


}