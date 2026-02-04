import { LightningElement, wire } from 'lwc';
import getDealerDetails from '@salesforce/apex/CNG_ProfileCardController.currentDistributorDetails';

export default class Cng_stationswitcher extends LightningElement {

    distributorName;
    error;

    // 🔹 Get current dealer & selected station details
    @wire(getDealerDetails)
    wiredDealerDetails({ error, data }) {
        if (data) {
            this.distributorName = data;
        } else if (error) {
            console.error('Dealer Details Error:', error);
        }
    }
}