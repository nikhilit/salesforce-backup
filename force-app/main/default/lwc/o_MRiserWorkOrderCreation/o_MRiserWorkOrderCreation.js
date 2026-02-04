import { LightningElement } from 'lwc';
    import { NavigationMixin } from 'lightning/navigation';

export default class O_MRiserWorkOrderCreation extends NavigationMixin(LightningElement)  {

    connectedCallback() {
        this.handleRedirectToList();
    }

     handleRedirectToList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Connection__c', 
                actionName: 'list'
            },
            state: {
                 filterName: 'RiserConnections'
            }
        });
    }

}