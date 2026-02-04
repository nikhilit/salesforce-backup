import { LightningElement, api, track } from 'lwc';
import getFilteredAccounts from '@salesforce/apex/CreateDemolitionWorkOrdersController.getFilteredAccounts';
import createSelectedWOs from '@salesforce/apex/CreateDemolitionWorkOrdersController.createSelectedWOs';

export default class CreateDemolitionWorkOrders extends LightningElement {

    // @api caseId;
   // @api caseIds = [];
    @api recordIds;  // Salesforce automatically passes selected Case Ids from List View
   @api caseIdsFromFlow; // Passed from flow




    @track accounts = [];

    @track columns = [
        { label: 'BP Number', fieldName: 'BP_Number__c' },
        { label: 'Full Name', fieldName: 'Full_Name__c' },
        { label: 'Move Out Date', fieldName: 'Move_Out_Date__c', type: 'date' },
        { label: 'Active', fieldName: 'sharinpix__Active__c' },
        { label: 'Connection', fieldName: 'Connection_Object__c' }
    ];

    @track isLoading = false;
    @track message;

    connectedCallback() {
        this.loadAccounts();
        console.log('Create Demolition');
        
    }

    renderedCallback() {
    console.log('Rendered - Checking IDs');
    console.log('recordIds:', JSON.stringify(this.recordIds));
    console.log('caseIdsFromFlow:', JSON.stringify(this.caseIdsFromFlow));
    console.log('caseIdsToProcess:', JSON.stringify(this.caseIdsToProcess));
}


    get caseIdsToProcess() {
    if (this.caseIdsFromFlow && this.caseIdsFromFlow.length > 0) {
        return this.caseIdsFromFlow;
    }

    if (this.recordIds && this.recordIds.length > 0) {
        return this.recordIds;
    }

    return [];
}



    // Load accounts using method 1
    loadAccounts() {
        this.isLoading = true;

      //  getFilteredAccounts({ caseIds: [this.caseId] })
    //  getFilteredAccounts({ caseIds: this.caseIds })
    getFilteredAccounts({ caseIds: this.caseIdsToProcess })
            .then(result => {
                this.accounts = result;
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error loading accounts:', error);
                this.message = 'Error loading accounts.';
            });
    }

    // Create WOs for selected accounts using method 2
    handleCreateWO() {
        const table = this.template.querySelector('lightning-datatable');
        const selected = table.getSelectedRows();

        if (!selected.length) {
            this.message = 'Please select at least one Account.';
            return;
        }

        let selectedAccountIds = selected.map(row => row.Id);

        this.isLoading = true;

        // createSelectedWOs({
        //     caseId: this.caseId,
        //     selectedAccountIds: selectedAccountIds
        // })
        createSelectedWOs({
    caseIds: this.caseIdsToProcess,
    selectedAccountIds: selectedAccountIds
    })

        .then(result => {
            this.isLoading = false;
            this.message = result;   // result = 'Success' or error string
        })
        .catch(error => {
    this.isLoading = false;
    console.error('Create WO Error:', error);

    let msg = 'Unknown error';

    if (error && error.body && error.body.message) {
        msg = error.body.message;
    } else if (error && error.message) {
        msg = error.message;
    }

    this.message = 'Error: ' + msg;
});

    }
}