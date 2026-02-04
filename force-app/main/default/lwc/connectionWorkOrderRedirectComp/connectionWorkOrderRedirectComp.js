import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ConnectionWorkOrderRedirectComp extends NavigationMixin (LightningElement) {



      @api reactiveValue=''; 

       connectedCallback() {
        if (this.reactiveValue) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.reactiveValue,
                    objectApiName: 'WorkOrder', 
                    actionName: 'view'
                }
            });
        }
    }


}