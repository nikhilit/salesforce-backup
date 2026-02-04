import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class O_MIPDDMCAllWorkOrder extends NavigationMixin(LightningElement) {

@api selectedStatus;

    connectedCallback() {
        console.log('Work Order List Component loaded with status:', this.selectedStatus);
        this.handleRedirectToList();
    }

    handleRedirectToList() {
        // Determine which list view filter to use based on selected status
        let filterName = 'ipdDMCAllWorkorder'; // Default filter
        
        // You can customize the filter based on status if needed
        if (this.selectedStatus === 'Completed') {
            filterName = 'ipdDMCAllWorkorder'; // Create this list view in Salesforce
        }
        // Add more status mappings as needed
        
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'WorkOrder', 
                actionName: 'list'
            },
            state: {
                filterName: filterName
            }
        });
    }

    // Handle back navigation
    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }
}