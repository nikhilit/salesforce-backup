import { LightningElement, api, wire, track } from 'lwc';
import getAccountDetails from '@salesforce/apex/AccountDetailsController1.getAccountDetails';
import getOpenCaseCount from '@salesforce/apex/AccountDetailsController1.getOpenCaseCount';

// Import all SAP Apex methods
import fetchSAPData from '@salesforce/apex/MRResultCallout.fetchSAPData';
import fetchSAPDataChronologies from '@salesforce/apex/ReceivableController.fetchSAPDataChronologies';
import getDeviceNumber from '@salesforce/apex/MRResultCallout.getInstallationNumber';
import updateAccountBalances from '@salesforce/apex/ReceivableController.updateAccountBalances';

import { refreshApex } from '@salesforce/apex';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountBoxComponent extends LightningElement {
    @api recordId;

    // Existing properties
    account = {};
    deviceAllocation = {};
    idnumber = {};
    domId = {};
    servicecontract = {};
    serviceContractRec = {};
    serviceContractNumber = {};
    minimumcharges = {};
    device = {};

    // SAP Data Properties
    @track meterResultData = [];
    @track chronologyData = [];
    @track sapLoading = false;
    @track sapError;
    
    // For MR Result
    @track deviceNumber;
    @track statusMessage;
    
    // For Receivables
    @track lastAmountPaid = '0.00';
    @track lastPaymentDate = 'N/A';
    bpId;
    accountName = '';

    // Store the wire adapter results
    wiredAccountDetailsResult;

    // Track if data has been loaded to prevent multiple loads
    @track dataLoaded = false;
    previousRecordId = null;

    connectedCallback() {
        console.log('AccountBox connected with recordId:', this.recordId);
        this.previousRecordId = this.recordId;
        
        // Always load data when component connects
        if (this.recordId) {
            console.log('Loading data on initial connection');
        }
        
        // Check for session storage refresh
        const shouldRefresh = sessionStorage.getItem('refreshAccountData');
        const accountIdToRefresh = sessionStorage.getItem('accountIdToRefresh');
        
        if (shouldRefresh && accountIdToRefresh === this.recordId) {
            sessionStorage.removeItem('refreshAccountData');
            sessionStorage.removeItem('accountIdToRefresh');
            setTimeout(() => {
                this.refreshAllData();
            }, 1000);
        }
    }

    // Use CurrentPageReference to detect navigation
    @wire(CurrentPageReference)
    currentPageReference(pageRef) {
        if (pageRef && pageRef.attributes && pageRef.attributes.recordId) {
            const newRecordId = pageRef.attributes.recordId;
            console.log('Page reference changed, recordId:', newRecordId);
            
            // If recordId changed, reload data
            if (newRecordId && newRecordId !== this.previousRecordId) {
                console.log('Record ID changed from', this.previousRecordId, 'to', newRecordId);
                this.previousRecordId = newRecordId;
                this.dataLoaded = false;
            }
        }
    }

    // Wire for account details
    @wire(getAccountDetails, { accrcaseId: '$recordId' })
    wiredAccountDetails(result) {
        this.wiredAccountDetailsResult = result;

        const { data, error } = result;
        if (data) {
            console.log('Account data loaded for recordId:', this.recordId);
            this.account = data.account || {};
            this.deviceAllocation = data.deviceAllocation || {};
            this.idnumber = data.idnumber || {};
            this.domId = data.domId || {};
            this.servicecontract = data.servicecontract || {};
            this.serviceContractRec = data.serviceContractRec || {};
            this.serviceContractNumber = data.serviceContractNumber || {};
            this.lastamountpaid = data.lastamountpaid || {};
            this.minimumcharges = data.minimumcharges || {};
            this.device = data.device || {};
            
            // Once account data is loaded, fetch SAP data if we have BP number
            if (this.account.BP_Number__c) {
                this.bpId = this.account.BP_Number__c;
                this.accountName = this.account.Name || '';
                console.log('BP Number found:', this.bpId, 'Fetching SAP data...');
                this.fetchAllSAPData();
            } else {
                console.log('No BP Number found in account data');
                this.sapLoading = false;
            }
        } else if (error) {
            console.error('Error fetching account details:', error);
            this.sapLoading = false;
        }
    }

    // Fetch device number for MR Result
    fetchDeviceNumber() {
        if (!this.bpId) return Promise.resolve();
        
        return getDeviceNumber({ bpNumber: this.bpId })
            .then(result => {
                this.deviceNumber = result;
                console.log('Device Number fetched:', this.deviceNumber);
                return result;
            })
            .catch(error => {
                console.error('Error fetching device number:', error);
                throw error;
            });
    }

    // Fetch all SAP data
    fetchAllSAPData() {
        this.sapLoading = true;
        this.sapError = null;
        
        console.log('Starting to fetch all SAP data for BP:', this.bpId);
        
        // Fetch device number first, then all SAP data in sequence
        this.fetchDeviceNumber()
            .then(() => {
                console.log('Device number fetched, now fetching SAP data in parallel');
                // Fetch all SAP data in parallel after device number is available
                return Promise.all([
                    this.fetchMRResultData(),
                    this.fetchChronologyData()
                ]);
            })
            .then(() => {
                console.log('All SAP data fetched successfully');
                this.sapLoading = false;
            })
            .catch(error => {
                console.error('Error fetching SAP data:', error);
                this.sapError = error;
                this.sapLoading = false;
            });
    }

    // Fetch MR Result SAP Data
    fetchMRResultData() {
        if (!this.deviceNumber) {
            console.log('No device number available for MR Result');
            return Promise.resolve();
        }

        console.log('Fetching MR Result data for device:', this.deviceNumber);
        return fetchSAPData({ device: this.deviceNumber })
            .then(result => {
                console.log('MR Result SAP Data received:', result.sapData ? result.sapData.length : 0, 'records');
                this.statusMessage = result.statusMessage;
                this.meterResultData = result.sapData || [];
                
                // Format time for display
                this.meterResultData = this.meterResultData.map(row => ({
                    ...row,
                    formattedTime: this.formatTime(row.ACTUAL_MR_TIME)
                }));
            })
            .catch(error => {
                console.error('Error fetching MR Result from SAP:', error);
                throw error;
            });
    }

    // Fetch Chronology SAP Data
    fetchChronologyData() {
        if (!this.bpId) {
            console.log('No BP ID available for Chronology');
            return Promise.resolve();
        }

        console.log('Fetching Chronology data for BP:', this.bpId);
        return fetchSAPDataChronologies({ bpId: this.bpId })
            .then(result => {
                console.log('Chronology SAP Data received:', result.sapData ? result.sapData.length : 0, 'records');
                
                let sortedRows = (result.sapData || []).sort((a, b) => {
                    const dateA = a.NET_DATE ? new Date(a.NET_DATE) : new Date(0);
                    const dateB = b.NET_DATE ? new Date(b.NET_DATE) : new Date(0);
                    return dateA - dateB;
                });

                // Calculate running balance
                let runningBalance = 0;
                this.chronologyData = sortedRows.map(row => {
                    const debitVal = this.parseAmount(row.DEBIT);
                    const creditVal = this.parseAmount(row.CREDIT);
                    const dpVal = this.parseAmount(row.DOWN);

                    runningBalance += debitVal + creditVal;

                    return {
                        ...row,
                        businessPartnerName: this.accountName,
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

                // Extract last payment data
                this.extractLastPaymentData();
                
                // Update account balances
                this.updateAccountBalances();
            })
            .catch(error => {
                console.error('Error fetching chronology from SAP:', error);
                throw error;
            });
    }

    // Extract last payment data from chronology
    extractLastPaymentData() {
        let lastPaymentAmount = null;
        let lastPaymentRecord = null;

        for (let i = this.chronologyData.length - 1; i >= 0; i--) {
            if (this.chronologyData[i].HTEXT === 'Check Lot' || this.chronologyData[i].HTEXT === 'Payment Run') {
                lastPaymentAmount = this.chronologyData[i].Credit_Amt__raw || 0;
                lastPaymentRecord = this.chronologyData[i];
                break;
            }
        }

        this.lastAmountPaid = this.formatAmount(lastPaymentAmount || 0);

        if (lastPaymentRecord && lastPaymentRecord.BLDAT) {
            this.lastPaymentDate = this.formatDate(lastPaymentRecord.BLDAT);
        } else {
            this.lastPaymentDate = 'N/A';
        }

        console.log('Last payment extracted - Amount:', this.lastAmountPaid, 'Date:', this.lastPaymentDate);
    }

    // Update account balances in Salesforce
    updateAccountBalances() {
        const openingBalance = this.chronologyPastBalanceTotalFormatted.replace(/,/g, '');
        const due = this.chronologyBalanceTotalFormatted.replace(/,/g, '');
        const securityDeposit = this.chronologyDownPymtTotalFormatted.replace(/,/g, '');
        const lastAmountPaid = this.lastAmountPaid ? this.lastAmountPaid.replace(/,/g, '') : '0';
        const lastPaymentDate = this.lastPaymentDate !== 'N/A' ? this.lastPaymentDate : '';
        
        console.log('Updating account balances with SAP data');
        updateAccountBalances({
            bpNumber: this.bpId,
            openingBalance: openingBalance,
            due: due,
            securityDeposit: securityDeposit,
            lastAmountPaid: lastAmountPaid,
            lastPaymentDate: lastPaymentDate
        })
        .then(() => {
            console.log('Account balances updated successfully from SAP data');
            this.refreshAllData();
        })
        .catch(error => {
            console.error('Error updating account balances:', error);
        });
    }

    // Refresh all data including SAP
    refreshAllData() {
        console.log('Refreshing all data for recordId:', this.recordId);
        this.sapLoading = true;
        refreshApex(this.wiredAccountDetailsResult)
            .then(() => {
                console.log('Account details refreshed, now fetching SAP data');
            })
            .then(() => {
                console.log('All data refreshed successfully including SAP');
            })
            .catch(error => {
                console.error('Error refreshing data:', error);
                this.sapError = error;
                this.sapLoading = false;
            });
    }

    // ========== HELPER METHODS ==========
    
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

    formatTime(time) {
        if (!time) return '';
        const str = time.toString().padStart(4, '0');
        return `${str.substring(0,2)}:${str.substring(2,4)}`;
    }

    // ========== SAP DATA GETTERS ==========

    // MR Result Getters
    get latestMeterReading() {
        if (!this.meterResultData || this.meterResultData.length === 0) return 'N/A';
        const sorted = [...this.meterResultData].sort((a, b) => 
            new Date(this.parseDate(b.MR_DATE)) - new Date(this.parseDate(a.MR_DATE))
        );
        return sorted[0]?.MR_READING || 'N/A';
    }

    get latestMeterReadingDate() {
        if (!this.meterResultData || this.meterResultData.length === 0) return 'N/A';
        const sorted = [...this.meterResultData].sort((a, b) => 
            new Date(this.parseDate(b.MR_DATE)) - new Date(this.parseDate(a.MR_DATE))
        );
        return sorted[0]?.MR_DATE ? this.formatDate(sorted[0].MR_DATE) : 'N/A';
    }

    get latestMeterReadingTime() {
        if (!this.meterResultData || this.meterResultData.length === 0) return 'N/A';
        const sorted = [...this.meterResultData].sort((a, b) => 
            new Date(this.parseDate(b.MR_DATE)) - new Date(this.parseDate(a.MR_DATE))
        );
        return sorted[0]?.formattedTime || 'N/A';
    }

    get meterReadingType() {
        if (!this.meterResultData || this.meterResultData.length === 0) return 'N/A';
        const sorted = [...this.meterResultData].sort((a, b) => 
            new Date(this.parseDate(b.MR_DATE)) - new Date(this.parseDate(a.MR_DATE))
        );
        return sorted[0]?.MR_TYPE || 'N/A';
    }

    // Chronology Getters
    get sapChronologyTotalDebit() {
        if (!this.chronologyData || this.chronologyData.length === 0) return '0.00';
        const total = this.chronologyData.reduce((sum, item) => sum + (item.Debit_Amt__raw || 0), 0);
        return this.formatAmount(total);
    }

    get sapChronologyTotalCredit() {
        if (!this.chronologyData || this.chronologyData.length === 0) return '0.00';
        const total = this.chronologyData.reduce((sum, item) => sum + (item.Credit_Amt__raw || 0), 0);
        return this.formatAmount(total);
    }

    get sapChronologyBalance() {
        if (!this.chronologyData || this.chronologyData.length === 0) return '0.00';
        const last = this.chronologyData[this.chronologyData.length - 1];
        return this.formatAmount(last.Current_Balance__raw || 0);
    }

    get sapChronologyDownPayment() {
        if (!this.chronologyData || this.chronologyData.length === 0) return '0.00';
        const total = this.chronologyData.reduce((sum, item) => sum + (item.Down_Payment__raw || 0), 0);
        return this.formatAmount(total);
    }

    // Date parser for MR Result
    parseDate(dateString) {
        if (!dateString) return new Date();
        try {
            const parts = dateString.split('/');
            if (parts.length === 3) {
                return new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]));
            }
            return new Date(dateString);
        } catch (e) {
            console.error('Date parsing error:', e);
            return new Date();
        }
    }

    // Chronology Past/Future calculations (needed for updateAccountBalances)
    get today() {
        return new Date();
    }

    get todayStart() {
        return new Date(new Date().setHours(0, 0, 0, 0));
    }

    get pastChronologyRows() {
        return this.chronologyData.filter(
            row => row.NET_DATE && new Date(row.NET_DATE) < this.todayStart
        );
    }

    get chronologyPastBalanceTotalFormatted() {
        const past = this.pastChronologyRows || [];
        if (past.length === 0) {
            return this.formatAmount(0);
        }
        const lastPast = past[past.length - 1];
        return this.formatAmount(lastPast.Current_Balance__raw || 0);
    }

    get chronologyBalanceTotalFormatted() {
        if (!this.chronologyData || this.chronologyData.length === 0) {
            return this.formatAmount(0);
        }
        const last = this.chronologyData[this.chronologyData.length - 1];
        return this.formatAmount(last.Current_Balance__raw || 0);
    }

    get chronologyDownPymtTotalFormatted() {
        return this.formatAmount(this.chronologyData.reduce((s, r) => s + (r.Down_Payment__raw || 0), 0));
    }

    // ========== EXISTING GETTERS ==========

    // Open case count (existing)
    openCaseCount = 0;
    openCaseError;

    @wire(getOpenCaseCount, { accountId: '$recordId' })
    wiredOpenCaseCount({ error, data }) {
        if (data !== undefined) {
            this.openCaseCount = data;
        } else if (error) {
            console.error('Error fetching open case count:', error);
            this.openCaseError = error;
            this.openCaseCount = 0;
        }
    }

    get openCaseCountDisplay() {
        return this.openCaseCount || 0;
    }

    get accountNameDisplay() {
        return this.account.Name || 'N/A';
    }

    get caNumber() {
        return (this.serviceContractNumber && this.serviceContractNumber.Contract_Account_Number__c)
            ? this.serviceContractNumber.Contract_Account_Number__c
            : 'N/A';
    }

    get schBD() {
        return this.minimumcharges?.Sch_BD__c ? this.formatDate(this.minimumcharges.Sch_BD__c) : 'N/A';
    }

    get nachDebit() {
        const val = this.serviceContractRec?.Debit_Limit__c;
        if (val === null || val === undefined) {
            return ' N/A';
        }
        const num = Number(val);
        const status = num > 0 ? 'Active' : 'Inactive';
        if (num === 0) {
            return `${status}`;
        }
        return `${status} | ${num.toLocaleString('en-IN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        })}`;
    }

    get lastPaidDate() {
        return this.account.Last_Paid_Date__c || 'N/A';
    }

    get bpNumber() {
        return this.account.BP_Number__c || 'N/A';
    }

    get remarks() {
        return this.account.Remarks__c || '';
    }

    get customerType() {
        return this.account.Type_Desc__c || '';
    }

    get primaryPhone() {
        return this.account.Phone || 'N/A';
    }

    get isTD() {
        if (this.minimumcharges.Disconnection__c?.toLowerCase() === 'true') {
            return true;
        } else {
            return false;
        }
    }

    get emailId() {
        return this.account.Account_Email__c || 'N/A';
    }

    get totalCashAmountDisplay() {
        const val = Math.abs(this.account?.Security_Deposit__c || 0);
        return val.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    get openAmountFormatted() {
        const val = Math.abs(this.account?.Open__c || 0);
        return val.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    get dueAmountFormatted() {
        const val = Math.abs(this.account?.Due__c || 0);
        return val.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    get creditAmountFormatted() {
        const val = Math.abs(this.account?.Credit__c || 0);
        return val.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    get lastAmountPaid() {
        const val = Math.abs(this.account?.Last_Amount_Paid__c || 0);
        return val.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    get coNumber() {
        return this.account.Connection_Object__c || 'N/A';
    }

    get flatNumber() {
        return this.account.Room__c || 'N/A';
    }

    get buildingName() {
        return this.account.Building_Name_Conn__c || 'N/A';
    }

    get street() {
        const streets = [
            this.account.Street__c,
            this.account.Street_Line_2__c,
            this.account.Street_Line_3__c,
            this.account.Street_Line_4__c,
            this.account.Street_Line_5__c
        ].filter(s => s);
        return streets.length > 0 ? streets.join(', ') : 'N/A';
    }

    get vip() {
        return this.account.VIP_Customer__c || false;
    }

    get city() {
        return this.account.City__c || 'N/A';
    }

    get postalCode() {
        return this.account.Postal_Code__c || 'N/A';
    }

    get discReason() {
        return (this.minimumcharges?.Blocking_Reason__c && this.minimumcharges?.Blocking_Reason_Text__c)
            ? `${this.minimumcharges.Blocking_Reason__c} - ${this.minimumcharges.Blocking_Reason_Text__c}`
            : 'N/A';
    }
     get discDate() {
        return this.minimumcharges?.disc_date__c ? this.formatDate(this.minimumcharges.disc_date__c) : 'N/A';

    }
     get discPerson() {
              return this.minimumcharges?.disc_person__c ? this.minimumcharges.disc_person__c : 'N/A';

    }


    get formNumber() {
        return this.idnumber?.ID_Number__c || 'N/A';
    }

    get domNum() {
        return this.domId?.Type__c || 'N/A';
    }

    get domDesc() {
        return this.domId?.Payment_Scheme__c || 'N/A';
    }

    get miDate() {
        return (this.servicecontract && this.servicecontract.moveInDate)
            ? this.formatDate(this.servicecontract.moveInDate)
            : 'N/A';
    }

    get noDate() {
        if (this.servicecontract && this.servicecontract.moveOutDate) {
            const moveOutDate = new Date(this.servicecontract.moveOutDate);
            if (moveOutDate.getFullYear() === 9999) {
                return 'N/A';
            }
            return this.formatDate(this.servicecontract.moveOutDate);
        }
        return 'N/A';
    }

    get currentStatus() {
    if (this.isTD) {
        return 'Temp. Disconnection';
    }

    if (this.servicecontract) {
        if (this.servicecontract.moveOutDate) {
            const moveOutDate = new Date(this.servicecontract.moveOutDate);
            const today = new Date();

            return moveOutDate < today ? 'Inactive' : 'Active';
        } else {
            return 'Active';
        }
    } else {
        return 'Inactive';
    }
}


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

    get mrNumber() {
        return this.device?.deviceNumber || 'N/A';
    }

    get meterNumber() {
        return this.device?.meterNumber || 'N/A';
    }

    get meterReadingType() {
        return this.deviceAllocation?.latestMeterReadingType || 'N/A';
    }

    get personName(){
        return this.deviceAllocation?.mrPerson || 'N/A';
    }

    get lastMeterReading() {
        return this.deviceAllocation?.lastMeterReading || 'N/A';
    }

    get mrDate() {
        return this.deviceAllocation?.lastMeterDate ? this.formatDate(this.deviceAllocation.lastMeterDate) : 'N/A';
    }

    get minimumChargesObj() {
        if (this.minimumcharges && this.minimumcharges.Minimum_Charges__c == 'true' ) {
            const fromDate = this.minimumcharges.Charges_Valid_From__c
                ? this.formatDate(this.minimumcharges.Charges_Valid_From__c)
                : '';
            const toDate = this.minimumcharges.Charges_Valid_To__c
                ? this.formatDate(this.minimumcharges.Charges_Valid_To__c)
                : '';
            return `${fromDate}${fromDate && toDate ? ' - ' : ''}${toDate}`;
        }
        return 'N/A';
    }

    get lmcValue() {
        return this.account.LMC__c === 'X' ? 'Not Released' : 'Released';
    }

    get ebillValue() {
            return this.account?.EBill__c === 'X' ? 'Yes' : 'No';
    }


    // get ebillValue() {

    //     const ebill = this.account?.EBill__c;

    //     switch(ebill){
    //         case 'X':
    //             return 'Digital bill';
    //         case 'P':
    //             return 'Hard copy';
    //         case 'M':
    //             return 'Digital failure';
    //         case 'E':
    //             return 'Hard copy without charge';
    //         default:
    //             return 'No';
    //     }
    // }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}