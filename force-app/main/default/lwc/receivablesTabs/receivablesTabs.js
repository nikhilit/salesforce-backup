import { LightningElement, api, track, wire } from 'lwc';
import getDownPayments from '@salesforce/apex/ReceivableController.getDownPayments';
import getReceivables from '@salesforce/apex/ReceivableController.getReceivables';
import getChronologies from '@salesforce/apex/ReceivableController.getChronologies';
import { CurrentPageReference } from 'lightning/navigation';

export default class ReceivablesTabs extends LightningElement {
   @api recordId; // This will work if component is on record page

    @track accountIdFromState;

    // @wire(CurrentPageReference)
    // getStateParameters(currentPageReference) {
    //     if (currentPageReference && currentPageReference.state) {
    //         this.accountIdFromState = currentPageReference.state.c__accountId;
    //         console.log('Received accountId from state:', this.accountIdFromState);
    //     }
    // }
    currentPageReference;
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
    }

    get recordId() {
        return this.currentPageReference?.state?.c__accountId;
    }

    get effectiveAccountId() {
        return this.recordId || this.accountIdFromState;
    }

   

    @track activeTab = 'receivables';
    @track downPaymentRows = [];
    @track error;

    // Store dynamic values for Totals tab
    businessPartnerName = '';
    contractAccountName = '';
    dueDate = '';

    // Use the effectiveAccountId for data wire
    @wire(getDownPayments, { accountId: '$effectiveAccountId' })
    wiredDownPayments({ error, data }) {
        console.log('Effective Account Id:', this.effectiveAccountId);
        if (data) {
            this.downPaymentRows = data.map(row => ({
                ...row,
                businessPartnerName: row.BP_Number__r ? row.BP_Number__r.Name : '',
                contractAccountName: row.Contract_Account__c ? row.Contract_Account__c : '',
                dueDate: row.Return_Date__c
            }));

            // Set Business Partner and Contract Account from the first record (if exists)
            if (this.downPaymentRows.length > 0) {
                this.businessPartnerName = this.downPaymentRows[0].businessPartnerName;
                this.contractAccountName = this.downPaymentRows[0].contractAccountName;
            }

            // Find the latest due date
            let dates = this.downPaymentRows
                .map(row => row.dueDate)
                .filter(date => date);
            if (dates.length > 0) {
                this.dueDate = dates.reduce((a, b) => (a > b ? a : b));
            } else {
                this.dueDate = '';
            }
        } else if (error) {
            this.error = error;
            this.downPaymentRows = [];
            this.businessPartnerName = '';
            this.contractAccountName = '';
            this.dueDate = '';
        }
    }

    get downPaymentsTotal() {
        return this.downPaymentRows.reduce((sum, row) => {
            const val = parseFloat(row.Cash_Amount__c) || 0;
            return sum + val;
        }, 0);
    }

    get downPaymentsTotalFormatted() {
        const total = this.downPaymentsTotal;
        return total ? total.toLocaleString('en-IN', { minimumFractionDigits: 2 }) : '0.00';
    }

    // Tab class getters
    get receivablesTabClass() {
        return this.activeTab === 'receivables' ? 'tab-item active' : 'tab-item';
    }
    get downPaymentsTabClass() {
        return this.activeTab === 'downPayments' ? 'tab-item active' : 'tab-item';
    }
    get totalsTabClass() {
        return this.activeTab === 'totals' ? 'tab-item active' : 'tab-item';
    }
    get chronologyTabClass() {
        return this.activeTab === 'chronology' ? 'tab-item active' : 'tab-item';
    }

    // Tab content visibility
    get isReceivablesTabActive() {
        return this.activeTab === 'receivables';
    }
    get isDownPaymentsTabActive() {
        return this.activeTab === 'downPayments';
    }
    get isTotalsTabActive() {
        return this.activeTab === 'totals';
    }
    get isChronologyTabActive() {
        return this.activeTab === 'chronology';
    }

    // Tab handlers
    selectReceivablesTab() {
        this.activeTab = 'receivables';
    }
    selectDownPaymentsTab() {
        this.activeTab = 'downPayments';
    }
    selectTotalsTab() {
        this.activeTab = 'totals';
    }
    selectChronologyTab() {
        this.activeTab = 'chronology';
    }
    @track receivableRows = [];
@track receivablesError;

@wire(getReceivables, { accountId: '$effectiveAccountId' })
wiredReceivables({ error, data }) {
    if (data) {
        this.receivableRows = data.map(row => ({
            ...row,
            businessPartnerName: row.Business_Partner__r ? row.Business_Partner__r.Name : '',
           contractAccountName: row.Contract_Account__c ? row.Contract_Account__c : '',
            dueDate: row.Net_Due_date__c
        }));
    } else if (error) {
        this.receivablesError = error;
        this.receivableRows = [];
    }
}

get receivablesTotal() {
    return this.receivableRows.reduce((sum, row) => {
        const val = parseFloat(row.Amount__c) || 0;
        return sum + val;
    }, 0);
}
get receivablesTotalFormatted() {
    const total = this.receivablesTotal;
    return total ? total.toLocaleString('en-IN', { minimumFractionDigits: 2 }) : '0.00';
}
@track chronologyRows = [];
@track chronologyError;

@wire(getChronologies, { accountId: '$effectiveAccountId' })
wiredChronologies({ error, data }) {
    if (data) {
        this.chronologyRows = data.map(row => ({
            ...row,
            // If you have formulas for Curr.bal. and CurrDwnPyt, map here
        }));
    } else if (error) {
        this.chronologyError = error;
        this.chronologyRows = [];
    }
}

get chronologyDebitTotal() {
    return this.chronologyRows.reduce((sum, row) => sum + (parseFloat(row.Debit_Amt__c) || 0), 0);
}
get chronologyCreditTotal() {
    return this.chronologyRows.reduce((sum, row) => sum + (parseFloat(row.Credit_Amt__c) || 0), 0);
}
get chronologyDownPymtTotal() {
    return this.chronologyRows.reduce((sum, row) => sum + (parseFloat(row.Down_Payment__c) || 0), 0);
}
get chronologyDebitTotalFormatted() {
    return this.chronologyDebitTotal.toLocaleString('en-IN', { minimumFractionDigits: 2 });
}
get chronologyCreditTotalFormatted() {
    return this.chronologyCreditTotal.toLocaleString('en-IN', { minimumFractionDigits: 2 });
}
get chronologyDownPymtTotalFormatted() {
    return this.chronologyDownPymtTotal.toLocaleString('en-IN', { minimumFractionDigits: 2 });
}


}