// import { LightningElement, api, track } from 'lwc';
// import getFilteredAccounts from '@salesforce/apex/CreateDemolitionWorkOrdersController.getFilteredAccounts';
// import createSelectedWOs from '@salesforce/apex/CreateDemolitionWorkOrdersController.createSelectedWOs';

// export default class CreateDemolitionsWorkOrders extends LightningElement {

//     // @api caseId;
//    // @api caseIds = [];
//   //  @api recordIds;  // Salesforce automatically passes selected Case Ids from List View
//  @api reactiveValue = [];
//   @api selectedIds = [];


//     @track accounts = [];

//     @track columns = [
//         { label: 'BP Number', fieldName: 'BP_Number__c' },
//         { label: 'Full Name', fieldName: 'Full_Name__c' },
//         { label: 'Move Out Date', fieldName: 'Move_Out_Date__c', type: 'date' },
//         { label: 'Active', fieldName: 'sharinpix__Active__c' },
//         { label: 'Connection', fieldName: 'Connection_Object__c' }
//     ];

//     @track isLoading = false;
//     @track message;

//     connectedCallback() {
       
//         console.log('Create Demolition');
//          console.log('Received Case Ids:', this.reactiveValue);
//          if (this.reactiveValue?.length > 0) {
//             this.selectedIds = this.reactiveValue;
//         console.log('inside connectedcallback selected ids values:', JSON.stringify(this.selectedIds));
//         console.log('inside connectedcallback reactiveValue ids values:', JSON.stringify(this.reactiveValue));
//         this.loadAccounts();


//         }
//     }

//     // Load accounts using method 1
//     loadAccounts() {
//         this.isLoading = true;

//       //  getFilteredAccounts({ caseIds: [this.caseId] })
//       getFilteredAccounts({ caseIds: this.reactiveValue })
//             .then(result => {
//                 this.accounts = result;
//                 console.log('Accounts ::', this.accounts);
//                 this.isLoading = false;
//             })
//             .catch(error => {
//                 this.isLoading = false;
//                 console.error('Error loading accounts:', error);
//                 this.message = 'Error loading accounts.';
//             });
//     }

//     // Create WOs for selected accounts using method 2
//     handleCreateWO() {
//         const table = this.template.querySelector('lightning-datatable');
//         const selected = table.getSelectedRows();

//         if (!selected.length) {
//             this.message = 'Please select at least one Account.';
//             return;
//         }

//         let selectedAccountIds = selected.map(row => row.Id);

//         this.isLoading = true;

//         // createSelectedWOs({
//         //     caseId: this.caseId,
//         //     selectedAccountIds: selectedAccountIds
//         // })
//         createSelectedWOs({
//     caseIds: this.reactiveValue,
//     selectedAccountIds: selectedAccountIds
//     })

//         .then(result => {
//             this.isLoading = false;
//             this.message = result;   // result = 'Success' or error string
//         })
//         .catch(error => {
//     this.isLoading = false;
//     console.error('Create WO Error:', error);

//     let msg = 'Unknown error';

//     if (error && error.body && error.body.message) {
//         msg = error.body.message;
//     } else if (error && error.message) {
//         msg = error.message;
//     }

//     this.message = 'Error: ' + msg;
// });

//     }
// }


import { LightningElement, api, track } from 'lwc';
import getFilteredAccounts
    from '@salesforce/apex/CreateDemolitionWorkOrdersController.getFilteredAccounts';
import createSelectedWOs
    from '@salesforce/apex/CreateDemolitionWorkOrdersController.createSelectedWOs';

export default class CreateDemolitionsWorkOrders extends LightningElement {

    @api reactiveValue = []; // Case Ids
    @track accounts = [];
    @track isLoading = false;
    @track message;

    selectedAccountIds = new Set();
    dateMap = {}; // accountId → { startDate, endDate }

    connectedCallback() {
        if (this.reactiveValue?.length) {
            this.loadAccounts();
        }
    }

    loadAccounts() {
        this.isLoading = true;

        getFilteredAccounts({ caseIds: this.reactiveValue })
            .then(result => {
                this.accounts = result.map((acc, index) => ({
                    ...acc,
                    rowIndex: index + 1
                }));
                this.isLoading = false;
            })
            .catch(err => {
                this.isLoading = false;
                console.error(err);
                this.message = 'Error loading accounts';
            });
    }

    handleRowSelection(event) {
        const accId = event.target.dataset.id;
        event.target.checked
            ? this.selectedAccountIds.add(accId)
            : this.selectedAccountIds.delete(accId);
    }

    handleDateChange(event) {
        const accId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.detail.value;

        if (!this.dateMap[accId]) {
            this.dateMap[accId] = {};
        }

        this.dateMap[accId][field] = new Date(value).toISOString();
    }

    handleCreateWO() {
        let payload = [];

        this.accounts.forEach(acc => {
            if (!this.selectedAccountIds.has(acc.Id)) return;

            const dates = this.dateMap[acc.Id];
            if (dates?.startDate && dates?.endDate) {
                payload.push({
                    accountId: acc.Id,
                    startDate: dates.startDate,
                    endDate: dates.endDate
                });
            }
        });

        if (!payload.length) {
            this.message = 'Please select Accounts and enter Start & End Date';
            return;
        }

        this.isLoading = true;

        createSelectedWOs({
            caseIds: this.reactiveValue,
            accountDateWrappers: payload
        })
        .then(res => {
            this.isLoading = false;
            this.message = res;
        })
        .catch(err => {
            this.isLoading = false;
            console.error(err);
            this.message = err.body?.message || err.message;
        });
    }
}