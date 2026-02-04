import { LightningElement, api, track } from 'lwc';
import getContactDetails from '@salesforce/apex/CNG_ProfileCardController.getContactDetails';

export default class PortalQuickActionComponent extends LightningElement {
    @api childRecordId;
    @track data;
    isLoaded = false;

    connectedCallback() {
        console.log('connectedCallback childRecordId:', this.childRecordId);

        if (this.childRecordId) {
            this.loadData();
        }
    }

    loadData() {
        console.log('Calling Apex with recordId:', this.childRecordId);

        getContactDetails({ recordId: this.childRecordId })
            .then(result => {
                this.data = result;
                console.log('Apex result:', JSON.stringify(result));
            })
            .catch(error => {
                console.error('Apex error:', JSON.stringify(error));
            });
    }
}