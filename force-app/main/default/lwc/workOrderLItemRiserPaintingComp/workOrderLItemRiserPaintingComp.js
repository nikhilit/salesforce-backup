import { LightningElement, api, wire,track } from 'lwc';
import getWorkOrderLineItems from '@salesforce/apex/WorkOrderLItemRiserPaintingContr.getWorkOrderLineItems';
import { NavigationMixin } from 'lightning/navigation';
export default class WorkOrderLItemRiserPaintingComp extends NavigationMixin(LightningElement) {
  
    @api recordId; // Work Order Id

    @track showCOWorkOrderLineItemPage = true;
    @api workOrderLineItemName='';
    @api workOrderLineItemId;
    
    
    workOrderLineItems = [];

    @track showEnterRiserDetails=false;
   // openModal=false;
    error;

    @wire(getWorkOrderLineItems, { workOrderId: '$recordId' })
    wiredItems({ data, error }) {
        if (data) {
            this.workOrderLineItems = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.workOrderLineItems = [];
        }
    }
    handleOpenModal(event){

     this.workOrderLineItemId = event.currentTarget.dataset.id; // Capture clicked Id
     console.log('workOrderLineItemName::',event.currentTarget.dataset.name);
    this.workOrderLineItemName=event.currentTarget.dataset.name;
        this.showEnterRiserDetails=true;
        this.showCOWorkOrderLineItemPage=false;
     // this.openModal=true;
    }
    handleCancel(){
      this.showEnterRiserDetails=false;
      this.showCOWorkOrderLineItemPage=true;
    }
    handleNavigate(event) {
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'WorkOrderLineItem',
                actionName: 'view'
            }
        });
    }
}