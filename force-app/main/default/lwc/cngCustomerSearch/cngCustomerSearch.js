import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchCngCustomers from '@salesforce/apex/CngCustomerController.searchCngCustomers';

export default class CngCustomerSearch extends LightningElement {
    @track location = '';
    @track outlet = '';
    @track company = '';
    @track zone = '';
    @track workOrders = [];
    @track noResults = false;
    @track showSearch = true;
    @track selectedWorkOrder = null;
    @track isLoading;

    handleInputChange(event) {
        const field = event.target.dataset.id;
        this[field] = event.target.value;
    }

    searchCustomers() {
        this.isLoading = true;
        this.selectedWorkOrder = null;
        searchCngCustomers({
            location: this.location,
            outlet: this.outlet,
            company: this.company,
            zone: this.zone
        })
            .then((result) => {
                this.workOrders = result;
                this.showSearch = true;
                this.noResults = result.length === 0;
            })
            .catch((error) => {
                console.error('Error fetching work orders', error);
                this.showToast('Error fetching record', JSON.stringify(error), 'error');
                // this.showToast('Error fetching record', error.body, 'error');
                this.noResults = true;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleResultClick(event) {
        const workOrderId = event.currentTarget.dataset.id;
        this.selectedWorkOrder = this.workOrders.find(w => w.Id === workOrderId);
        this.showSearch = false; 
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}