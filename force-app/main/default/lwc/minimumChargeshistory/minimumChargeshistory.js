import { LightningElement, api, track } from 'lwc';
import getInstallationId from '@salesforce/apex/MinimunChargesHistory.getInstallationId';
import fetchInstallationData from '@salesforce/apex/MinimunChargesHistory.fetchInstallationData';

export default class InstallationDetails extends LightningElement {
    @api recordId; // Account Id
    @track installationData;
    @track error;

    connectedCallback() {
        this.fetchInstallation();
    }

    fetchInstallation() {
        getInstallationId({ accountId: this.recordId })
            .then(result => {
                console.log('Installation Id:', result);
                if (result) {
                    this.loadData(result);
                } else {
                    this.error = 'No installation found for this Account.';
                }
            })
            .catch(err => {
                this.error = err.body?.message || err.message;
                console.error('Error fetching installation:', err);
            });
    }

//     loadData(installationId) {
//     fetchInstallationData({ installationId })
//         .then(result => {
//             console.log('Installation Data:', JSON.stringify(result));
//             // result.sapData is an array
//             this.installationData = result.sapData;
//            // this.statsus=  result.sapData.s
//             this.error = undefined;
//         })
//         .catch(error => {
//             this.error = error.body?.message || error.message;
//             this.installationData = undefined;
//             console.error('Error fetching installation data:', error);
//         });
// }
loadData(installationId) {
    fetchInstallationData({ installationId })
        .then(result => {
            console.log('Installation Data:', JSON.stringify(result));

            // ✅ handle both data and message from Apex wrapper
            if (result.sapData && Array.isArray(result.sapData) && result.sapData.length > 0) {
                this.installationData = result.sapData;
                this.statusMessage = undefined;
            } 
            else if (result.statusMessage) {
                this.installationData = [];
                this.statusMessage = result.statusMessage;
            } 
            else {
                this.installationData = [];
                this.statusMessage = 'No Minimum Charge History Records Found.';
            }

            this.error = undefined;
        })
        .catch(error => {
            this.error = error.body?.message || error.message;
            this.installationData = [];
            console.error('Error fetching installation data:', error);
        });
}

get hasInstallationRecords() {
    return this.installationData && this.installationData.length > 0;
}
}