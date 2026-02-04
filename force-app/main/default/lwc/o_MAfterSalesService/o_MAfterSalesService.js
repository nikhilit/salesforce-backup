import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class O_MAfterSalesService extends NavigationMixin(LightningElement)  {

    connectedCallback() {
        this.handleRedirectToList();
    }

     handleRedirectToList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'WorkOrder', 
                actionName: 'list'
            },
            state: {
                 filterName: 'After_Sales_Servicemyworkorder'
            }
        });
    }

}