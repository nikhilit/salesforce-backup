import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCasesByPhone from '@salesforce/apex/CaseSearchController.getCasesByPhone';
import searchCases from '@salesforce/apex/CaseSearchController.searchCases';
import createLead from '@salesforce/apex/AccountSearchController.createLead';
import getCurrentUserAgentId from '@salesforce/apex/ClickToCallController.getCurrentUserAgentId';
import initiateCall from '@salesforce/apex/ClickToCallController.initiateCall';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

export default class CaseSearchComponent extends NavigationMixin(LightningElement) {
    @track noResults = false;
    @track showtable = false;

    @track firstName = '';
    @track lastName = '';
    @track caNumber = '';
    @track bpNumber = '';
    @track teleNumber = '';
    @track connection = '';
    @track email = '';
    @track caseNumber = '';
    @track isLoading=false;

    @api recordId = '';
    @track phoneNumber1 = '';
    @track cases = [];
    @track error;
    agentId;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            this.teleNumber = currentPageReference.state?.c__teleNumber || '';
            console.log('teleNumber from URL:', this.teleNumber);
            if (this.teleNumber) {
                this.searchCasesHandler(); // auto-search
            }
        }
    }

    @wire(getCurrentUserAgentId)
    wiredAgentId({ error, data }) {
        if (data) {
            this.agentId = data;
        } else if (error) {
            console.error('Error fetching agent ID', error);
        }
    }
     get displayNumber() {
        // Trim in case Docket_Number__c has spaces
        return this.cases.Docket_Number__c && this.cases.Docket_Number__c.trim() !== ''
            ? this.cases.Docket_Number__c
            : this.cases.CaseNumber; // or Case_Number__c if that's your API
    }

    handleClickToCall(event) {
        event.stopPropagation();
        const phone = event.currentTarget.dataset.phone;
        this.phoneNumber1 = phone;
        this.redirectToAccount();
        initiateCall({ agentId: this.agentId, phoneNumber: phone })
            .then(result => {
                this.showToast(result, '', 'success');
            })
            .catch(err => {
                this.showToast('Click-to-Call Failed', err.body?.message || 'Unknown error', 'error');
            });
    }

    handleInputChange(event) {
        const { name, value } = event.target;
        this[name] = value;
    }

    handleKeyUp(event) {
        if (event.key === 'Enter') {
            this.searchCasesHandler();
        }
    }

    handleSearchClick() {
        this.searchCasesHandler();
    }

    searchCasesHandler() {
        this.isLoading=true;
        this.error = null;
        this.cases = [];

        searchCases({
            firstName: this.firstName,
            lastName: this.lastName,
            caNumber: this.caNumber,
            bpNumber: this.bpNumber,
            teleNumber: this.teleNumber,
            connection: this.connection,
            email: this.email,
            caseNumber: this.caseNumber
        })
            .then(result => {
                this.cases = result.map(c => ({
                    ...c,
                     societyName: c.Account?.Society_Name__c || '',
                    formattedDate: new Date(c.CreatedDate).toLocaleDateString('en-IN')
                }));

                this.noResults = this.cases.length === 0;
                this.showtable = !this.noResults;
                this.isLoading=false;
                console.log('cases retrieved:', JSON.stringify(this.cases));
            })
            .catch(error => {
                this.error = error;
                this.isLoading=false;
                this.noResults = true;
                console.error('Error retrieving cases:', JSON.stringify(error));
            });
    }

    handleRecordClick(event) {
        event.stopPropagation();
        const recordId = event.currentTarget.dataset.key;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    get hascases() {
        return this.cases && this.cases.length > 0;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    handleClearClick() {
        this.firstName = '';
        this.lastName = '';
        this.caNumber = '';
        this.bpNumber = '';
        this.teleNumber = '';
        this.connection = '';
        this.email = '';
        this.caseNumber = '';
        this.noResults = false;
        this.showtable = false;
    }

    redirectToAccount() {
        getCasesByPhone({ phoneNumber: this.phoneNumber1 })
            .then(cases => {
                if (cases && cases.length > 0 && cases[0].Account && cases[0].Account.Id) {
                    this.navigateToAccountRecord(cases[0].Account.Id);
                } else {
                    console.warn('No matching Account found for phone.');
                }
            })
            .catch(error => {
                console.error('Error fetching Account by phone:', JSON.stringify(error));
            });
    }

    navigateToAccountRecord(accountId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }
}