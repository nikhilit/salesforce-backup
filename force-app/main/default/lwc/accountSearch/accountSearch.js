<<<<<<< HEAD
import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import searchAccounts from '@salesforce/apex/AccountSearchController.searchAccounts';
import searchLeads from '@salesforce/apex/AccountSearchController.searchLeads';
import getLeadGAValues from '@salesforce/apex/AccountSearchController.getLeadGAValues';
import createLead from '@salesforce/apex/AccountSearchController.createLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrentUserAgentId from '@salesforce/apex/ClickToCallController.getCurrentUserAgentId';
import initiateCall from '@salesforce/apex/ClickToCallController.initiateCall';
import { CurrentPageReference } from 'lightning/navigation';
import getDRSList from '@salesforce/apex/AccountSearchController.getDRSList';
import getLeadTypeValues from '@salesforce/apex/AccountSearchController.getLeadTypeValues';
import getGAForDrs from '@salesforce/apex/AccountSearchController.getGAForDrs';
import updateAccountBalances from '@salesforce/apex/ReceivableController.updateAccountBalances';
import fetchSAPDataChronologies from '@salesforce/apex/ReceivableController.fetchSAPDataChronologies';
import fetchSAPData from '@salesforce/apex/MRResultCallout.fetchSAPData';
import getInstallationNumber from '@salesforce/apex/MRResultCallout.getInstallationNumber';
import MR_RESULT from '@salesforce/messageChannel/mrresult__c';
import { publish, MessageContext } from 'lightning/messageService';

export default class AccountSearch extends NavigationMixin(LightningElement) {

    @track noResults = false;
    @track showtable = false;
    @track firstName = '';
    @api recordId = '';
    @track city = '';
    @track postalCode = '';
    @track lastName = '';
    @track caNumber = '';
    @track bpNumber = '';
    @api teleNumber = '';
    @track buildingName = '';
    @track flat = '';
    @track floor = '';
    @track connection = '';
    @track email = '';
    @track registrationInfoName = '';
    @track streetname = '';
    @track invoicenumber = '';
    @track meternumber = '';
    @track accounts = [];
    @track isLoading = false;

    @track leadNoResults = false;
    @track leadShowTable = false;
    @track leads = [];
    @track leadFirstName = '';
    @track leadLastName = '';
    @track leadProspect = '';
    @track leadPhone = '';
    @track leadEmail = '';
    @track leadPostalCode = '';
    @track leadCity = '';
    @track leadStreet = '';

    @track leadType = '';
    @track typeOptions = [];
    @track drsOptions = [];
    @track selectedDrsId = null;
    @track buildingCode = '';
    @track street = '';
    @track street2 = '';
    @track street3 = '';
    @track street4 = '';
    @track street5 = '';
    @track othercity = '';
    @track district = '';
    @track country = '';
    @track timeZone = '';
    @track region = '';
    @track nameandNoofWings = '';
    @track potentialInEachWing = '';
    @track plotNo = '';
    @track totalNosOfFloor = '';
    @track selectedGA = '';
    @track gaOptions = [];

    recordType = 'Customer';
    registrationStatus = 'Registered';

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.teleNumber = currentPageReference.state?.c__teleNumber || '';
            if (this.teleNumber) {
                this.searchAccountsHandler();
            }
        }
    }
    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.loadDRSOptions();
        this.loadLeadTypeOptions();
        this.country = 'IN';
        this.loadGAOptions(); 
        this.timeZone = 'INDIA';
    }
     // Add this method to load GA picklist values
    loadGAOptions() {
        getLeadGAValues()
            .then(result => {
                this.gaOptions = result.map(value => ({ 
                    label: value, 
                    value: value 
                }));
            })
            .catch(error => {
                console.error('Error loading GA values:', error);
            });
    }

    // Add this handler
    handleGAChange(event) {
        this.selectedGA = event.detail.value;
    }

    get isCustomer() {
        return this.recordType === 'Customer';
    }

    get isProspect() {
        return this.recordType === 'Prospect';
    }

    get isRegistered() {
        return this.registrationStatus === 'Registered';
    }

    get isUnregistered() {
        return this.registrationStatus === 'Unregistered';
    }

    loadDRSOptions() {
        getDRSList()
            .then(result => {
                this.drsOptions = result.map(item => ({
                    label: item.Name,
                    value: item.Id
                }));
            })
            .catch(error => {
                console.error('Error loading DRS options', error);
            });
    }

    loadLeadTypeOptions() {
        getLeadTypeValues()
            .then(result => {
                this.typeOptions = result.map(value => ({ label: value, value: value }));
            })
            .catch(error => {
                console.error('Error loading lead types:', error);
            });
    }

    handleRecordTypeChange(event) {
        this.recordType = event.target.value;
        this.resetAllSearches();
    }

    handleRegistrationChange(event) {
        this.registrationStatus = event.target.value;
        this.resetAllSearches();
    }

    resetAllSearches() {
        this.accounts = [];
        this.leads = [];
        this.showtable = false;
        this.leadShowTable = false;
        this.noResults = false;
        this.leadNoResults = false;
    }

    handleInputChange(event) {
        const { name, value } = event.target;
        this[name] = value;
    }
    handleLeadInputChange(event) {
        const field = event.target.name;
        const value = event.detail?.value ?? event.target.value;
        this[field] = value;
        console.log('this[field]', this[field]);

    }
    handleLead1InputChange(event) {
        const field = event.target.name;
        const value = event.target.value;

        // Update the property directly using the field name (converted for consistency)
        if (field === 'Name & No of Wings') {
            this.nameandNoofWings = value;
        } else if (field === 'Potential In Each Wing') {
            this.potentialInEachWing = value;
        } else if (field === 'Total Nos Of Floor') {
            this.totalNosOfFloor = value;
        } else if (field === 'Plot No') {
            this.plotNo = value;
        }
    }
    handleKeyUp(event) {
        if (event.key === 'Enter') {
            this.isLoading = true;
            if (this.isCustomer && this.isRegistered) {
                this.searchAccountsHandler();
            } else if (this.isProspect) {
                this.searchLeadsHandler();
            }
        }
    }

    handleSearchClick() {
        //  this.isLoading=true;
        this.searchAccountsHandler();
    }

    searchAccountsHandler() {
        searchAccounts({
            firstName: this.firstName,
            lastName: this.lastName,
            caNumber: this.caNumber,
            bpNumber: this.bpNumber,
            teleNumber: this.teleNumber,
            postalCode: this.postalCode,
            city: this.city,
            registrationInfoName: this.registrationInfoName,
            buildingName: this.buildingName,
            streetname: this.streetname,
            connection: this.connection,
            email: this.email,
            meternumber: this.meternumber,
            invoicenumber: this.invoicenumber
        })
            .then(result => {
                this.accounts = result.map(wrapper => {
                    const acc = wrapper.account;
                    const caNumber = wrapper.caNumber || ''; // Get CA number from wrapper

                    let appNumber = '';
                    if (acc.Identification_Numbers__r && acc.Identification_Numbers__r.length > 0) {
                        const latest = acc.Identification_Numbers__r[0];
                        if (latest?.ID_Number__c) {
                            appNumber = latest.ID_Number__c;
                        }
                    }
                    let moveInDate = '';
                    let moveOutDate = '';
                    if (acc.Move_In_Outs__r && acc.Move_In_Outs__r.length > 0) {
                        const latest = acc.Move_In_Outs__r[0];
                        moveInDate = latest?.Move_In_Date__c || '';
                        moveOutDate = latest?.Move_Out_Date__c || '';
                    }
                    const conn = acc.Connection__r || {};

                    const accountStreet = [
                        acc.Street__c,
                        acc.Street_Line_2__c,
                        acc.Street_Line_3__c,
                        acc.Street_Line_4__c,
                        acc.Street_Line_5__c
                    ].filter(Boolean).join(', ');

                    const connectionStreet = [
                        conn.Street__c,
                        conn.Street_2__c,
                        conn.Street_3__c,
                        conn.Street_4__c,
                        conn.Street_5__c
                    ].filter(Boolean).join(', ');

                    return {
                        ...acc, // Spread all account properties
                        caNumber: caNumber, // Add CA number from wrapper
                        connectionName: acc.Connection_Object__c || '',
                        buildingName: acc.Building_Name_Conn__c || '',
                        applicationNumber: appNumber,

                        projectArea: conn.Project_Area__c || '',
                        connectionStatus: conn.Status__c || '',
                        marketingBPStatus: acc.Status__c || '',
                        searchTerm1: conn.Search_Term__c || '',
                        moveInDate: moveInDate || '',
                        moveOutDate: (moveOutDate && moveOutDate !== '9999-12-31')
                            ? moveOutDate
                            : 'N/A',
                        streetAccount: acc.Street__c || '',
                        street2Account: acc.Street_Line_2__c || '',
                        street3Account: acc.Street_Line_3__c || '',
                        street4Account: acc.Street_Line_4__c || '',
                        street5Account: acc.Street_Line_5__c || '',

                        buildingNameConn: conn.Building_Name__c || '',
                        streetConn: conn.Street__c || '',
                        street2Conn: conn.Street_2__c || '',
                        street3Conn: conn.Street_3__c || '',
                        street4Conn: conn.Street_4__c || '',
                        street5Conn: conn.Street_5__c || '',

                        fullAccountStreet: accountStreet,
                        fullConnectionStreet: connectionStreet,

                        regionName: conn.Region_Name__c || '',
                        region: conn.Region__c || '',
                        country: conn.Country__c || '',
                        countryCode: conn.Country_Code__c || '',
                        cityConnection: conn.City__c || '',

                        primaryPhone: acc.Phone || '',
                        secondaryPhone: acc.Secondary_Telephone__c || ''
                    };
                });

                this.noResults = this.accounts.length === 0;
                this.showtable = this.accounts.length > 0;
                this.isLoading = false;
                //  this.isLoadingOnEnter = false;
            })
            .catch(error => {
                this.isLoading = false;
                // this.isLoadingOnEnter = false;
                this.noResults = true;
                console.error('Error retrieving accounts:', error);
                this.showToast('Error', 'Error retrieving accounts: ' + error.body?.message, 'error');
            });
    }

    handleLeadSearchClick() {
        this.searchLeadsHandler();
    }

    searchLeadsHandler() {
        this.isLoading = true;
        this.isLoadingOnEnter = true;
        searchLeads({
            firstName: this.leadFirstName,
            lastName: this.leadLastName,
            leadProspect: this.leadProspect,
            phone: this.leadPhone,
            email: this.leadEmail,
            postalCode: this.leadPostalCode,
            city: this.leadCity,
            street: this.leadStreet
        })
            .then(result => {
                this.leads = result.map(lead => ({
                    ...lead,
                    fullStreet: [
                        lead.Street__c,
                        lead.Street_Line_2__c,
                        lead.Street_Line_3__c,
                        lead.Street_Line_4__c,
                        lead.Street_Line_5__c
                    ].filter(Boolean).join(', ')
                }));

                this.leadNoResults = this.leads.length === 0;
                this.leadShowTable = this.leads.length > 0;
                this.isLoading = false;
                //  this.isLoadingOnEnter = false;
            })
            .catch(error => {
                this.isLoading = false;
                // this.isLoadingOnEnter = false;
                this.leadNoResults = true;
                console.error('Error retrieving leads:', error);
                this.showToast('Error', 'Error retrieving leads: ' + error.body?.message, 'error');
            });
    }

    handleDrsSelect(event) {
        this.selectedDrsId = event.detail.value;

        if (this.selectedDrsId) {
            getGAForDrs({ drsId: this.selectedDrsId })
                .then(result => {
                    this.region = result || '';
                })
                .catch(error => {
                    console.error('Error fetching GA for DRS:', error);
                    this.region = '';
                });
        } else {
            this.region = '';
        }
    }

    handleChange(event) {
        this.leadType = event.detail.value;
    }

    handleCreateLead() {
        if (!this.selectedGA) {
            this.showToast('Error', 'GA is required', 'error');
            return;
        }
        if (!this.leadFirstName || !this.leadLastName) {
            this.showToast('Error', 'First Name and Last Name are required', 'error');
            return;
        }

        if (!this.leadPhone) {
            this.showToast('Error', 'Phone Number is required', 'error');
            return;
        }

        if (!this.street) {
            this.showToast('Error', 'Street (Address) is required', 'error');
            return;
        }

        if (!this.postalCode) {
            this.showToast('Error', 'Postal Code is required', 'error');
            return;
        }

        // if (!this.leadEmail) {
        //     this.showToast('Error', 'Email is required', 'error');
        //     return;
        // }

        if (!this.selectedDrsId) {
            this.showToast('Error', 'DRS is required', 'error');
            return;
        }

        if (!this.leadType) {
            this.showToast('Error', 'Lead Type is required', 'error');
            return;
        }
        if (!this.buildingName) {
            this.showToast('Error', 'Building Name is required', 'error');
            return;
        }

        if (!this.buildingCode) {
            this.showToast('Error', 'Building Code is required', 'error');
            return;
        }

        if (!this.street2) {
            this.showToast('Error', 'Street 2 is required', 'error');
            return;
        }

        if (!this.city) {
            this.showToast('Error', 'City is required', 'error');
            return;
        }

        if (!this.flat) {
            this.showToast('Error', 'Flat is required', 'error');
            return;
        }

        if (!this.region) {
            this.showToast('Error', 'Region is required', 'error');
            return;
        }

        if (!this.district) {
            this.showToast('Error', 'District is required', 'error');
            return;
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        const phoneRegex = /^[0-9]{10}$/;

        if (this.leadPhone && !phoneRegex.test(this.leadPhone)) {
            this.showToast('Error', 'Please enter a valid 10-digit phone number', 'error');
            return;
        }

        if (this.leadEmail && !emailRegex.test(this.leadEmail)) {
            this.showToast('Error', 'Please enter a valid email address', 'error');
            return;
        }
        this.isLoading = true;
        createLead({
            firstName: this.leadFirstName,
            lastName: this.leadLastName,
            phone: this.leadPhone,
            email: this.leadEmail,
            drsId: this.selectedDrsId,
            leadType: this.leadType,
            floor: this.floor,
            buildingName: this.buildingName,
            buildingCode: this.buildingCode,
            street: this.street,
            street2: this.street2,
            street3: this.street3,
            street4: this.street4,
            street5: this.street5,
            flat: this.flat,
            city: this.city,
            othercity: this.othercity,
            district: this.district,
            postalCode: this.postalCode,
            country: this.country,
            timeZone: this.timeZone,
            region: this.region,
            nameandNoofWings: this.nameandNoofWings,
            potentialInEachWing: this.potentialInEachWing,
            totalNosOfFloor: this.totalNosOfFloor,
            plotNo: this.plotNo,
            gaValue: this.selectedGA
        })
            .then(result => {
                this.showToast('Success', 'Lead created successfully', 'success');
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'Lead',
                        actionName: 'view'
                    }
                });
                this.resetLeadForm();
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Error creating lead: ' + error.body?.message, 'error');
            });
    }

    resetLeadForm() {
        this.leadFirstName = '';
        this.leadLastName = '';
        this.leadPhone = '';
        this.leadEmail = '';
        this.selectedDrsId = null;
        this.leadType = '';
        this.floor = '';
        this.buildingName = '';
        this.buildingCode = '';
        this.street = '';
        this.street2 = '';
        this.street3 = '';
        this.street4 = '';
        this.street5 = '';
        this.flat = '';
        this.city = '';
        this.selectedGA = '';
        this.othercity = '';
        this.district = '';
        this.postalCode = '';
        this.region = '';
        this.nameandNoofWings = '';
        this.potentialInEachWing = '';
        this.plotNo = '';
        this.totalNosOfFloor = '';
    }

    handleClearClick() {
        this.firstName = '';
        this.lastName = '';
        this.caNumber = '';
        this.bpNumber = '';
        this.teleNumber = '';
        this.postalCode = '';
        this.city = '';
        this.registrationInfoName = '';
        this.buildingName = '';
        this.streetname = '';
        this.email = '';
        this.connection = '';
        this.meternumber = '';
        this.invoicenumber = '';
        this.showtable = false;
        this.noResults = false;
    }

    handleLeadClearClick() {
        this.leadFirstName = '';
        this.leadLastName = '';
        this.leadProspect = '';
        this.leadPhone = '';
        this.leadEmail = '';
        this.leadPostalCode = '';
        this.leadCity = '';
        this.leadStreet = '';
        this.leadShowTable = false;
        this.leadNoResults = false;
    }

    handleRecordClick(event) {
        const recordId = event.currentTarget.dataset.key;
        const bpNumber = event.currentTarget.dataset.bp;

        if (!bpNumber) return;
        // First get the Installation Id using BP Number
        getInstallationNumber({ bpNumber: bpNumber })
            .then(installationId => {
                if (installationId) {
                    // Now call fetchSAPData with the Installation Id
                    return fetchSAPData({ device: installationId });
                } else {
                    console.warn('No installation found for BP:', bpNumber);
                    return null;
                }
            })
            .then(result => {
                if (result) {
                    console.log('SAP Data refreshed:', result);
                }
            })
            .catch(error => {
                console.error('Error refreshing SAP for BP:', bpNumber, error);
            })

        // Update Account Balances in the background
        this.updateAccountBalancesBackground(bpNumber, recordId);
    }

    async updateAccountBalancesBackground(bpNumber, recordId) {
        // Use the exact same helper functions as in Receivables
        const parseAmount = (val) => {
            if (val === null || val === undefined || val === '') {
                return 0;
            }
            let str = val.toString().trim();
            if (str.endsWith('-')) {
                str = '-' + str.slice(0, -1);
            }
            let num = parseFloat(str);
            return isNaN(num) ? 0 : num;
        };

        const formatAmount = (num) => {
            const formatted = num.toLocaleString('en-IN', {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            });
            return formatted === '-0.00' ? '0.00' : formatted;
        };

        const formatDate = (dateValue) => {
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
        };

        try {
            // Fetch data
            const [chronologyResult] = await Promise.all([
                fetchSAPDataChronologies({ bpId: bpNumber })
            ]);

            // Calculate chronology data (same as Receivables component)
            let sortedRows = (chronologyResult.sapData || []).sort((a, b) => {
                const dateA = a.NET_DATE ? new Date(a.NET_DATE) : new Date(0);
                const dateB = b.NET_DATE ? new Date(b.NET_DATE) : new Date(0);
                return dateA - dateB; // ascending order
            });

            let runningBalance = 0;
            const chronologyRows = sortedRows.map(row => {
                const debitVal = parseAmount(row.DEBIT);
                const creditVal = parseAmount(row.CREDIT);
                const dpVal = parseAmount(row.DOWN);

                // update running balance (SAP already provides signed values)
                runningBalance += debitVal + creditVal;

                return {
                    ...row,
                    Debit_Amt__raw: debitVal,
                    Credit_Amt__raw: creditVal,
                    Down_Payment__raw: dpVal,
                    Current_Balance__raw: runningBalance
                };
            });

            // EXTRACT LAST AMOUNT PAID (Both Check Lot AND Payment Run)
            let lastPaymentAmount = null;
            let lastPaymentDate = null;
            for (let i = chronologyRows.length - 1; i >= 0; i--) {
                if (chronologyRows[i].HTEXT === 'Check Lot' || chronologyRows[i].HTEXT === 'Payment Run') {
                    lastPaymentAmount = chronologyRows[i].Credit_Amt__raw || 0;
                    lastPaymentDate = formatDate(chronologyRows[i].BLDAT);
                    break;
                }
            }

            // Calculate past chronology rows (same as Receivables component)
            const todayStart = new Date(new Date().setHours(0, 0, 0, 0));
            const pastChronologyRows = chronologyRows.filter(
                row => row.NET_DATE && new Date(row.NET_DATE) < todayStart
            );

            // Get the exact same values as Receivables component
            const chronologyPastBalanceTotal = pastChronologyRows.length > 0
                ? pastChronologyRows[pastChronologyRows.length - 1].Current_Balance__raw || 0
                : 0;

            const chronologyBalanceTotal = chronologyRows.length > 0
                ? chronologyRows[chronologyRows.length - 1].Current_Balance__raw || 0
                : 0;

            const chronologyDownPymtTotal = chronologyRows.reduce((s, r) => s + (r.Down_Payment__raw || 0), 0);
            const lastAmountPaidVal = lastPaymentAmount || 0;

            // Format values exactly like Receivables component
            const openingBalance = formatAmount(chronologyPastBalanceTotal).replace(/,/g, '');
            const due = formatAmount(chronologyBalanceTotal).replace(/,/g, '');
            const securityDeposit = formatAmount(chronologyDownPymtTotal).replace(/,/g, '');
            const lastAmountPaid = formatAmount(lastAmountPaidVal).replace(/,/g, '');
            const lastPaymentDateFormatted = lastPaymentDate !== 'N/A' ? lastPaymentDate : '';

            updateAccountBalances({
                bpNumber,
                openingBalance: openingBalance,
                due: due,
                securityDeposit: securityDeposit,
                lastAmountPaid: lastAmountPaid,
                lastPaymentDate: lastPaymentDateFormatted  // Add this parameter
            });

            publish(this.messageContext, MR_RESULT, {
                message: 'MR data refreshed',
                bpnumber: recordId
            });

            console.log('✅ LMS Publish executed');

            console.log('Account balances updated for BP:', bpNumber, 'with last payment date:', lastPaymentDate);

        } catch (error) {
            let message = error?.body?.message || error?.message || JSON.stringify(error);
            console.error('Error updating account balances:', message);
        }finally{
            // Navigate to the Account page
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            });
        };
    }

    handleLeadRecordClick(event) {
        const recordId = event.currentTarget.dataset.key;
        this.navigateToRecord(recordId, 'Lead');
    }

    navigateToRecord(recordId, objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'view'
            }
        });
    }

    agentId;

    @wire(getCurrentUserAgentId)
    wiredAgentId({ error, data }) {
        if (data) {
            this.agentId = data;
        } else if (error) {
            console.error('Error fetching agent ID', error);
        }
    }

    handleClickToCall(event) {
        event.stopPropagation();
        const phone = event.currentTarget.dataset.phone;
        const accountId = event.currentTarget.dataset.id;

        if (accountId) {
            this.navigateToRecord(accountId, 'Account');
        }

        this.initiateCallHelper(phone);
    }

    handleLeadClickToCall(event) {
        event.stopPropagation();
        const phone = event.currentTarget.dataset.phone;
        const leadId = event.currentTarget.dataset.id;

        if (leadId) {
            this.navigateToRecord(leadId, 'Lead');
        }

        this.initiateCallHelper(phone);
    }

    initiateCallHelper(phone) {
        initiateCall({ agentId: this.agentId, phoneNumber: phone })
            .then(() => {
                this.showToast('Success', 'Call initiated', 'success');
            })
            .catch(() => {
                this.showToast('Error', 'Error initiating call', 'error');
            });
    }

    get hasAccounts() {
        return this.accounts && this.accounts.length > 0;
    }

    get hasLeads() {
        return this.leads && this.leads.length > 0;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
=======
import { LightningElement, track } from 'lwc';

export default class AccountSearch extends LightningElement {
    @track searchText = '';
    searchAccountContactHander(event) {
        this.searchText = event.detail;
>>>>>>> e604021b64f33882bfed07c2bfed265ad53326cf
    }
}