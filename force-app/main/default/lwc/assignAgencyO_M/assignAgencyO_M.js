// agencySelectorForOM.js
import { LightningElement, api, track, wire } from 'lwc';
import getOMAgencies from '@salesforce/apex/AgencyFetcherForOM.getOMAgencies';
import assignOMAgency from '@salesforce/apex/AgencyFetcherForOM.assignOMAgency';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AgencySelectorForOM extends LightningElement {
    @api reactiveValue = []; 
    @track selectedIds = [];
    @track agencies = [];
    @track selectedAgencyId;
    @track isAssigned = false;
    error;
    ids = [];  // Holds selected work order IDs


    connectedCallback() {
        if (this.reactiveValue?.length > 0) {
            this.selectedIds = this.reactiveValue;
        }
    }

    @wire(getOMAgencies)
wiredAgencies({ error, data }) {
    if (data) {
        console.log('✅ Data from Apex:', data);  // ADD THIS
        this.agencies = data;
    } else if (error) {
        console.error('❌ Error loading agencies:', error); // ADD THIS
        this.error = 'Failed to load agencies';
    }
}

handleRowSelection(event) {
    const selectedRows = event.detail.selectedRows;
    this.ids = selectedRows.map(row => row.Id);  // Store only the Ids
    console.log('🟢 Selected Work Order IDs:', JSON.stringify(this.ids));
}


    handleChange(event) {
        this.selectedAgencyId = event.detail.value;
    }

    get agencyOptions() {
        return this.agencies.map(a => ({
            label: a.Name,
            value: a.Id
        }));
    }
handleAssign() {
    // Use selected from table if available, else fallback to reactiveValue
    const workOrderIdsToUse = (this.ids.length > 0) ? this.ids : this.reactiveValue;

    console.log('⚙️ Assign clicked. SelectedAgencyId:', this.selectedAgencyId);
    console.log('⚙️ Work Orders to Assign:', JSON.stringify(workOrderIdsToUse));

    if (!this.selectedAgencyId || workOrderIdsToUse.length === 0) {
        this.showToast('Error', 'Please select an agency and at least one Work Order.', 'error');
        return;
    }

    assignOMAgency({
        reactiveValue: workOrderIdsToUse,
        agencyId: this.selectedAgencyId
    })
    .then(() => {
        this.isAssigned = true;
        this.showToast('Success', 'Agency assigned successfully!', 'success');
    })
    .catch(error => {
        console.error('❌ Error assigning agency:', error);
        this.showToast('Error', error.body?.message || 'Failed to assign agency.', 'error');
    });
}





    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}