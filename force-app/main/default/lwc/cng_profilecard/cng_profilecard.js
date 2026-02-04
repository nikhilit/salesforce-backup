import { LightningElement,track,api } from 'lwc';
import getAccountDetails from '@salesforce/apex/CNG_ProfileCardController.getAccountDetails';

export default class Cng_profilecard extends LightningElement {
    profile;
    leftCompressors = [];
    rightCompressors = [];
    error;
    @track searchKey = '';
    @track stations = [];
    @track showDropdown = false;
    @api recordId;
  get billingAddress() {
    const parts = [
        this.profile?.BillingStreet,
        this.profile?.BillingCity,
        this.profile?.BillingState,
        this.profile?.BillingPostalCode,
        this.profile?.BillingCountry
    ];

    return parts.filter(part => part && part.trim()).join(', ');
}


    connectedCallback(){

        this.leftCompressors = [];
        this.rightCompressors = [];

        getAccountDetails({ stationId: this.recordId })
            .then(result => {
                this.profile = result;

                const compressors = result?.Compressors__r;

                // 🔴 SAFETY CHECK
                if (!compressors || compressors.length === 0) {
                    console.warn('No compressors found');
                    return;
                }

                compressors.forEach((comp, index) => {
                    const compWithIndex = {
                        ...comp,
                        displayIndex: index + 1
                    };

                    if (index % 2 === 0) {
                        this.leftCompressors = [...this.leftCompressors, compWithIndex];
                    } else {
                        this.rightCompressors = [...this.rightCompressors, compWithIndex];
                    }
                });

                console.log('Left:', JSON.stringify(this.leftCompressors));
                console.log('Right:', JSON.stringify(this.rightCompressors));
            })
            .catch(error => {
                this.error = error;
                this.profile = undefined;
                console.error(error);
            });
          
    }
}