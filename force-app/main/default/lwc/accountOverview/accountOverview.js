import { LightningElement, api, track, wire } from 'lwc';
//import getDownPayments from '@salesforce/apex/ReceivableController.getDownPayments';
import getReceivables from '@salesforce/apex/ReceivableController.getReceivables';
import getChronologies from '@salesforce/apex/ReceivableController.getChronologies';

export default class ReceivablesTabs extends LightningElement {
    @api recordId;
    @track activeTab = 'receivables';

    // Down Payments
    //@track downPaymentRows = [];
    @track error;
    businessPartnerName = '';
    contractAccountName = '';
    dueDate = '';

    // Receivables
    @track receivableRows = [];
    @track receivablesError;

    // Chronologies
    @track chronologyRows = [];
    @track chronologyError;

    get effectiveAccountId() {
        return this.recordId;
    }

    // --- Helpers ---
    parseAmount(val) {
        if (val === null || val === undefined || val === '') {
            return 0;
        }
        let str = val.toString().trim();
        if (str.endsWith('-')) {
            str = '-' + str.slice(0, -1);
        }
        let num = parseFloat(str);
        return isNaN(num) ? 0 : num;
    }

   formatAmount(num) {
    const formatted = num.toLocaleString('en-IN', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });

    return formatted === '-0.00' ? '0.00' : formatted;
}


    // --- Down Payments Wire ---
   /* @wire(getDownPayments, { accountId: '$effectiveAccountId' })
    wiredDownPayments({ error, data }) {
        if (data) {
            this.downPaymentRows = data.map(row => {
                const cashVal = this.parseAmount(row.Cash_Amount__c);
                const reqVal = this.parseAmount(row.Req_Amount__c);
                return {
                    ...row,
                    businessPartnerName: row.BP_Number__r ? row.BP_Number__r.Name : '',
                    dueDate: row.Return_Date__c,
                    Cash_Amount__raw: cashVal,
                    Cash_Amount__c: this.formatAmount(cashVal),
                    Req_Amount__raw: reqVal,
                    Req_Amount__c: this.formatAmount(reqVal)
                };
            });

            if (this.downPaymentRows.length > 0) {
                this.businessPartnerName = this.downPaymentRows[0].businessPartnerName;
                this.contractAccountName = this.downPaymentRows[0].contractAccountName;
            }

            const dates = this.downPaymentRows
                .map(row => row.dueDate)
                .filter(date => date);
            this.dueDate = dates.length > 0 ? dates.reduce((a, b) => (a > b ? a : b)) : '';
        } else if (error) {
            this.error = error;
            this.downPaymentRows = [];
            this.businessPartnerName = '';
            this.contractAccountName = '';
            this.dueDate = '';
        }
    }*/

    // --- Receivables Wire ---
    @wire(getReceivables, { accountId: '$effectiveAccountId' })
    wiredReceivables({ error, data }) {
        if (data) {
            this.receivableRows = data.map(row => {
                const amtVal = this.parseAmount(row.Amount__c);
                return {
                    ...row,
                    businessPartnerName: row.Business_Partner__r ? row.Business_Partner__r.Name : '',
                    contractAccountName: row.Contract_Account__c ? row.Contract_Account__c : '',
                    dueDate: row.Net_Due_date__c,
                    Amount__raw: amtVal,
                    Amount__c: this.formatAmount(amtVal)
                };
            });
        } else if (error) {
            this.receivablesError = error;
            this.receivableRows = [];
        }
    }

    // --- Chronologies Wire ---
   @wire(getChronologies, { accountId: '$effectiveAccountId' })
    wiredChronologies({ error, data }) {
    if (data) {
        let runningBalance = 0; // start from 0
        this.chronologyRows = data.map(row => {
            const debitVal = this.parseAmount(row.Debit_Amt__c);
            const creditVal = this.parseAmount(row.Credit_Amt__c);
            const dpVal = this.parseAmount(row.Down_Payment__c);

            // update running balance
            runningBalance += creditVal; // add credit
            runningBalance += debitVal;  // subtract debit

            return {
                ...row,
                businessPartnerName: row.Business_Partner__r ? row.Business_Partner__r.Name : '',
                Debit_Amt__raw: debitVal,
                Debit_Amt__c: this.formatAmount(debitVal),
                Credit_Amt__raw: creditVal,
                Credit_Amt__c: this.formatAmount(creditVal),
                Down_Payment__raw: dpVal,
                Down_Payment__c: this.formatAmount(dpVal),
                Current_Balance__raw: runningBalance,
                Current_Balance__c: this.formatAmount(runningBalance) // formatted for display
            };
        });
    } else if (error) {
        this.chronologyError = error;
        this.chronologyRows = [];
    }
}
get chronologyPastDueDate() {
    const today = new Date().setHours(0, 0, 0, 0);
    const pastDates = this.chronologyRows
        .map(row => row.Net_Due_Date__c)
        .filter(d => d && new Date(d) < today)
        .sort((a, b) => new Date(b) - new Date(a)); // sort descending

    return pastDates.length > 0 ? pastDates[0] : null;
}

get chronologyAsOnPastRows() {
    if (!this.chronologyPastDueDate) {
        return [];
    }
    const cutoff = new Date(this.chronologyPastDueDate).setHours(0, 0, 0, 0);
    return this.chronologyRows.filter(row => {
        return row.Net_Due_Date__c && new Date(row.Net_Due_Date__c) <= cutoff;
    });
}
today = new Date(); // used for formatting
todayStart = new Date(new Date().setHours(0, 0, 0, 0));
get todayFormatted() {
        return this.today.toLocaleDateString('en-GB', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        });
    }
   get pastChronologyRows() {
    return this.chronologyRows.filter(
        row => row.Net_Due_Date__c && new Date(row.Net_Due_Date__c) < this.todayStart
    );
}
get futureChronologyRows() {
    return this.chronologyRows.filter(
        row => row.Net_Due_Date__c && new Date(row.Net_Due_Date__c) > this.todayStart
    );
}

    get chronologyDebitTotalFormatted() {
    return this.formatAmount(this.chronologyRows.reduce((s, r) => s + (r.Debit_Amt__raw || 0), 0));
}
get chronologyCreditTotalFormatted() {
    return this.formatAmount(this.chronologyRows.reduce((s, r) => s + (r.Credit_Amt__raw || 0), 0));
}
get chronologyBalanceTotalFormatted() {
    if (!this.chronologyRows || this.chronologyRows.length === 0) {
        return this.formatAmount(0);
    }
    const last = this.chronologyRows[this.chronologyRows.length - 1];
    return this.formatAmount(last.Current_Balance__raw || 0);
}

get chronologyDownPymtTotalFormatted() {
    return this.formatAmount(this.chronologyRows.reduce((s, r) => s + (r.Down_Payment__raw || 0), 0));
}

// Past totals
get chronologyPastDebitTotalFormatted() {
    return this.formatAmount(this.pastChronologyRows.reduce((s, r) => s + (r.Debit_Amt__raw || 0), 0));
}
get chronologyPastCreditTotalFormatted() {
    return this.formatAmount(this.pastChronologyRows.reduce((s, r) => s + (r.Credit_Amt__raw || 0), 0));
}
get chronologyPastBalanceTotalFormatted() {
    const past = this.pastChronologyRows || [];
    if (past.length === 0) {
        return this.formatAmount(0);
    }
    const lastPast = past[past.length - 1];
    return this.formatAmount(lastPast.Current_Balance__raw || 0);
}
get chronologyPastDownPymtTotalFormatted() {
    return this.formatAmount(this.pastChronologyRows.reduce((s, r) => s + (r.Down_Payment__raw || 0), 0));
}

    // --- Totals ---
   /* get downPaymentsTotal() {
        return this.downPaymentRows.reduce((sum, row) => sum + (row.Cash_Amount__raw || 0), 0);
    }
    get downPaymentsTotalFormatted() {
        return this.formatAmount(this.downPaymentsTotal);
    }*/

    get receivablesTotal() {
        return this.receivableRows.reduce((sum, row) => sum + (row.Amount__raw || 0), 0);
    }
    get receivablesTotalFormatted() {
        return this.formatAmount(this.receivablesTotal);
    }

    // --- Tab Styling and Visibility ---
    get receivablesTabClass() {
        return this.activeTab === 'receivables' ? 'tab-item active' : 'tab-item';
    }
   /* get downPaymentsTabClass() {
        return this.activeTab === 'downPayments' ? 'tab-item active' : 'tab-item';
    }
    get totalsTabClass() {
        return this.activeTab === 'totals' ? 'tab-item active' : 'tab-item';
    }*/
    get chronologyTabClass() {
        return this.activeTab === 'chronology' ? 'tab-item active' : 'tab-item';
    }

    get isReceivablesTabActive() { return this.activeTab === 'receivables'; }
    //get isDownPaymentsTabActive() { return this.activeTab === 'downPayments'; }
   // get isTotalsTabActive() { return this.activeTab === 'totals'; }
    get isChronologyTabActive() { return this.activeTab === 'chronology'; }

    // --- Tab Click Handlers ---
    selectReceivablesTab() { this.activeTab = 'receivables'; }
    //selectDownPaymentsTab() { this.activeTab = 'downPayments'; }
   // selectTotalsTab() { this.activeTab = 'totals'; }
    selectChronologyTab() { this.activeTab = 'chronology'; }
}