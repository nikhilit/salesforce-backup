import { LightningElement,track } from 'lwc';
import getContactDetails from '@salesforce/apex/CNG_ProfileCardController.getContactDetails';

export default class Cng_contacts extends LightningElement {
    data;
    error;
   
    connectedCallback(){
            getContactDetails()
                .then(result => {
                    this.data = result;
                    
        })
                .catch(error => {
                    this.error = error;
                    this.profile = undefined;
                    console.error(error);
                });
        }
}