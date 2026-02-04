import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getCustomerProfile from '@salesforce/apex/CustomerProfileController.getCustomerProfile';

export default class CngCustomerProfile extends LightningElement {
    // @api recordId;
    // @track workOrderId = this.recordId;
    @track workOrderId
    @track profileData;
    @track isOffline = false;
    wiredResult;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            // this.workOrderId = currentPageReference.state?.recordId;
            this.workOrderId = currentPageReference.state?.c__recordId || currentPageReference.state?.recordId;
            console.log('Id:: ' + this.workOrderId);
        }
    }

    @wire(getCustomerProfile, { workOrderId: '$workOrderId' })
    wiredProfile(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            console.log("data found", JSON.stringify(data));
            this.profileData = data;
            localStorage.setItem('cachedProfile', JSON.stringify(data));
            this.isOffline = false;
        } else if (error) {
            console.log("error found", error);
            const cached = localStorage.getItem('cachedProfile');
            if (cached) {
                this.profileData = JSON.parse(cached);
                this.isOffline = true;
            }
        }
    }

    
    handleRefresh() {
        if (this.wiredResult) {
            refreshApex(this.wiredResult);
        }
    }

    connectedCallback() {
        this.handleRefresh();
    }
}