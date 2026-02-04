import { LightningElement, track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import getPhoneByRecordId from '@salesforce/apex/ClickToCallController.getPhoneByRecordId';
import getCurrentUserAgentId from '@salesforce/apex/ClickToCallController.getCurrentUserAgentId';
import getAccountsByPhone from '@salesforce/apex/ClickToCallController.getAccountsByPhone';
import initiateCall from '@salesforce/apex/ClickToCallController.initiateCall';

export default class PhoneUtility extends NavigationMixin(LightningElement) {
    @track phoneNumber1;
    phoneNumber = '';
    agentId = '';
    dialKeysTop = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
     recordId;

    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.attributes && pageRef.attributes.recordId) {
            this.recordId = pageRef.attributes.recordId;

            getPhoneByRecordId({ recordId: this.recordId })
                .then(result => {
                    if (result) {
                        this.phoneNumber = result;
                        console.log('Phone fetched:', this.phoneNumber);
                    } else {
                        this.phoneNumber = '';
                    }
                })
                .catch(error => {
                    console.error('Error fetching phone:', error);
                    this.phoneNumber = '';
                    this.showToast('Error', 'Failed to fetch phone number.', 'error');
                });
        } 
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    connectedCallback() {
        getCurrentUserAgentId()
            .then(result => {
                this.agentId = result;
            })
            .catch(() => {
                this.showToast('Error', 'Unable to fetch Agent Id', 'error');
            });
    }

    handleDialClick(event) {
        this.phoneNumber += event.target.innerText;
    }

    handleBackspaceClick() {
        this.phoneNumber = this.phoneNumber.slice(0, -1);
    }
  handlePhoneInput(event) {
    const input = event.target.value.replace(/\D/g, '');
    this.phoneNumber = input.slice(0, 10);
}
 

    handleCallClick() {
        const digitsOnly = this.phoneNumber.replace(/\D/g, '');
        this.phoneNumber1 = digitsOnly;
        
        if (digitsOnly.length !== 10) {
            this.showToast('Invalid Number', 'Please enter exactly 10 digits', 'error');
            return;
        }

        // First initiate the call
        initiateCall({ agentId: this.agentId, phoneNumber: digitsOnly })
            .then(result => {
                this.showToast('Call Initiated', result, 'success');
                // Then handle account navigation
                this.handleAccountNavigation();
            })
            .catch(error => {
                this.showToast('Call Failed', error.body.message, 'error');
            });
    }

    handleAccountNavigation() {
        getAccountsByPhone({ phoneNumber: this.phoneNumber1 })
            .then(accounts => {
                if (!accounts || accounts.length === 0) {
                    this.showToast('No Account Found', 'No account matches this phone number', 'info');
                } else if (accounts.length === 1) {
                    this.navigateToAccountRecord(accounts[0].Id);
                } else {
                    this.navigateToAccountList();
                }
            })
            .catch(error => {
                console.error('Error fetching Account:', JSON.stringify(error));
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

    navigateToAccountList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/lightning/n/CIC0?c__teleNumber=${encodeURIComponent(this.phoneNumber1)}`
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}