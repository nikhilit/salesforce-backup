import { LightningElement, api, track, wire } from 'lwc';
import fetchSAPDataChronologies from '@salesforce/apex/ReceivableController.fetchSAPDataChronologies';
import fetchSAPDataReceivables from '@salesforce/apex/ReceivableController.fetchSAPDataReceivables';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateAccountBalances from '@salesforce/apex/ReceivableController.updateAccountBalances';
const FIELDS = ['Account.BP_Number__c', 'Account.Name'];
import { publish, MessageContext } from 'lightning/messageService';
import MR_RESULT from '@salesforce/messageChannel/mrresult__c';

export default class ReceivablesTabs extends LightningElement {
    @api recordId;
    @track activeTab = 'receivables';

    // Down Payments
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

    @track lastAmountPaid = '0.00';
    @track lastPaymentDate = 'N/A';

    get effectiveAccountId() {
        return this.recordId;
    }
    @wire(MessageContext)
messageContext;


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

    isLoading = false;

    // --- Receivables Wire ---
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.isLoading = true;
            this.bpId = data.fields.BP_Number__c.value;
            this.name = data.fields.Name.value;
            console.log('bpId', this.bpId, 'Account Name', this.name);
            this.callSAP();
        } else if (error) {
            this.error = error.body?.message || error.message;
            console.error('Error fetching Account:', error);
        }
    }

    callSAP() {
        if (!this.bpId) {
            this.showToast('Missing Info', 'Please ensure.', 'warning');
            return;
        }

        this.error = undefined;

        fetchSAPDataReceivables({ bpId: this.bpId })
        .then(result => {
            this.receivableRows = result.sapData
                .map(row => {
                    const amtVal = this.parseAmount(row.AMOUNT);
                    return {
                        ...row,
                        businessPartnerName: this.name || '',
                        Amount__raw: amtVal,
                        Amount__c: this.formatAmount(amtVal)
                    };
                })
                .sort((a, b) => {
                    const dateA = a.NET_DATE ? new Date(a.NET_DATE) : new Date(0);
                    const dateB = b.NET_DATE ? new Date(b.NET_DATE) : new Date(0);
                    return dateA - dateB;
                });
        })
        .catch(error => {
            this.error = error.body?.message || error.message;
            console.log(this.error);
        })
        .finally(() => {
            this.isLoading = false;
        });

        fetchSAPDataChronologies({ bpId: this.bpId })
        .then(result => {
            this.statusMessage = result.statusMessage;

            // Step 1: sort first
            let sortedRows = (result.sapData || []).sort((a, b) => {
                const dateA = a.NET_DATE ? new Date(a.NET_DATE) : new Date(0);
                const dateB = b.NET_DATE ? new Date(b.NET_DATE) : new Date(0);
                return dateA - dateB;
            });

            // Step 2: now calculate running balance
            let runningBalance = 0;
            this.chronologyRows = sortedRows.map(row => {
                const debitVal = this.parseAmount(row.DEBIT);
                const creditVal = this.parseAmount(row.CREDIT);
                const dpVal = this.parseAmount(row.DOWN);

                runningBalance += debitVal + creditVal;

                return {
                    ...row,
                    businessPartnerName: this.name || '',
                    Debit_Amt__raw: debitVal,
                    Debit_Amt__c: this.formatAmount(debitVal),
                    Credit_Amt__raw: creditVal,
                    Credit_Amt__c: this.formatAmount(creditVal),
                    Down_Payment__raw: dpVal,
                    Down_Payment__c: this.formatAmount(dpVal),
                    Current_Balance__raw: runningBalance,
                    Current_Balance__c: this.formatAmount(runningBalance)
                };
            });

            // EXTRACT LAST PAYMENT DATA (Both Check Lot AND Payment Run) - SINGLE LOOP
            let lastPaymentAmount = null;
            let lastPaymentRecord = null;

            for (let i = this.chronologyRows.length - 1; i >= 0; i--) {
                if (this.chronologyRows[i].HTEXT === 'Check Lot' || this.chronologyRows[i].HTEXT === 'Payment Run') {
                    lastPaymentAmount = this.chronologyRows[i].Credit_Amt__raw || 0;
                    lastPaymentRecord = this.chronologyRows[i];
                    break;
                }
            }

            this.lastAmountPaid = this.formatAmount(lastPaymentAmount || 0);

            if (lastPaymentRecord && lastPaymentRecord.BLDAT) {
                this.lastPaymentDate = this.formatDate(lastPaymentRecord.BLDAT);
            } else {
                this.lastPaymentDate = 'N/A';
            }

            console.log('Last payment date extracted:', this.lastPaymentDate);
            this.updateAccount();
        })
        .catch(error => {
            this.error = error.body?.message || error.message;
            console.log(this.error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    updateAccount() {
        const openingBalance = this.chronologyPastBalanceTotalFormatted.replace(/,/g, '');
        const due = this.chronologyBalanceTotalFormatted.replace(/,/g, '');
        const securityDeposit = this.chronologyDownPymtTotalFormatted.replace(/,/g, '');
        const lastAmountPaid = this.lastAmountPaid ? this.lastAmountPaid.replace(/,/g, '') : '0';
        const lastPaymentDate = this.lastPaymentDate !== 'N/A' ? this.lastPaymentDate : '';
        
        updateAccountBalances({
            bpNumber: this.bpId,
            openingBalance: openingBalance,
            due: due,
            securityDeposit: securityDeposit,
            lastAmountPaid: lastAmountPaid,
            lastPaymentDate: lastPaymentDate
        })
        .then(() => {
            console.log('Account balances updated successfully with last payment date:', this.lastPaymentDate);
             publish(this.messageContext, MR_RESULT, {
    message: 'MR data refreshed',
    bpnumber: this.recordId
});
        })
        .catch(error => {
            console.error('Error updating account:', error);
            this.showToast('Error', error.body?.message || error.message, 'error');
        });
    }

    today = new Date();
    todayStart = new Date(new Date().setHours(0, 0, 0, 0));
    
    get chronologyAsOnPastRows() {
        if (!this.chronologyPastDueDate) {
            return [];
        }
        const cutoff = new Date(this.chronologyPastDueDate).setHours(0, 0, 0, 0);
        return this.chronologyRows.filter(row => {
            return row.NET_DATE && new Date(row.NET_DATE) <= cutoff;
        });
    }
    
    get chronologyPastDueDate() {
        const today = new Date().setHours(0, 0, 0, 0);
        const pastDates = this.chronologyRows
            .map(row => row.NET_DATE)
            .filter(d => d && new Date(d) < today)
            .sort((a, b) => new Date(b) - new Date(a));
        return pastDates.length > 0 ? pastDates[0] : null;
    }

    get todayFormatted() {
        return this.today.toLocaleDateString('en-GB', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        });
    }
    
    get pastChronologyRows() {
        return this.chronologyRows.filter(
            row => row.NET_DATE && new Date(row.NET_DATE) < this.todayStart
        );
    }
    
    get futureChronologyRows() {
        return this.chronologyRows.filter(
            row => row.NET_DATE && new Date(row.NET_DATE) > this.todayStart
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
    
    get chronologyTabClass() {
        return this.activeTab === 'chronology' ? 'tab-item active' : 'tab-item';
    }

    get isReceivablesTabActive() { return this.activeTab === 'receivables'; }
    get isChronologyTabActive() { return this.activeTab === 'chronology'; }

    // --- Tab Click Handlers ---
    selectReceivablesTab() { this.activeTab = 'receivables'; }
    selectChronologyTab() { this.activeTab = 'chronology'; }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}