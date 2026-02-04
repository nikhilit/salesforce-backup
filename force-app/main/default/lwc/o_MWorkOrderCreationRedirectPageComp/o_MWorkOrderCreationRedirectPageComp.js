import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class O_MWorkOrderCreationRedirectPageComp extends NavigationMixin(LightningElement)  {

      @api reactiveValue=[]; 

       connectedCallback() {
        if (this.reactiveValue[0]) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.reactiveValue[0],
                    objectApiName: 'WorkOrder', 
                    actionName: 'view'
                }
            });
        }
    }


}