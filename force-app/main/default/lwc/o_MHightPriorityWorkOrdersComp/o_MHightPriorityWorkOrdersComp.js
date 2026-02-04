import { LightningElement } from 'lwc';
  import { NavigationMixin } from 'lightning/navigation';

export default class O_MHightPriorityWorkOrdersComp extends NavigationMixin(LightningElement) {

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
                 filterName: 'High Priority WO'
            }
        });
    }
}