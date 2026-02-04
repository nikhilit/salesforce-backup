import { LightningElement, api, track } from 'lwc';
import getAgenciesByAgent from '@salesforce/apex/AgencyFetcherForRT.getAgenciesByAgent';
import assignAgency from '@salesforce/apex/AgencyFetcherForRT.assignAgency';
import getAllAgencies from '@salesforce/apex/AgencyFetcherForRT.getAllAgencies';
import getAllAgents from '@salesforce/apex/AgencyFetcherForRT.getAllAgents';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class AgencySelectorForRT extends LightningElement {
    @api reactiveValue = [];
    @api selectedIds = [];

    @track agencies = [];
    @track agents = [];
    @track workTypes = [];

    selectedAgencyId;
    selectedAgentId;
    selectedWorkTypeId;
    startDate;
    endDate;

    isAssigned = false;
    isLoading = false;


    connectedCallback() {
        if (this.reactiveValue?.length > 0) {
            this.selectedIds = this.reactiveValue;
        }
        //this.fetchWorkTypes();
        this.fetchInitialAgenciesAndAgents();
    }

    get agencyOptions() {
        return this.agencies.map(a => ({
            label: a.Name,
            value: a.Id
        }));
    }

    get agentOptions() {
        return this.agents.map(a => ({
            label: a.ServiceResource.RelatedRecord.Name,
            value: a.ServiceResourceId
        }));
    }

    get workTypeOptions() {
        return this.workTypes.map(wt => ({
            label: wt.Name,
            value: wt.Id
        }));
    }

    get isAssignDisabled() {
        // Check if all required fields are filled
        const hasAllFields =
            this.selectedAgencyId &&
            this.selectedAgentId &&
            //this.selectedWorkTypeId &&
            this.startDate &&
            this.endDate;

        // Check date validity
        const isDateValid = this.startDate <= this.endDate;

        return !(hasAllFields && isDateValid);
    }

    handleAgencyChange(event) {
        this.selectedAgencyId = event.detail.value;
    
        // getAgentsByAgency({ agencyId: this.selectedAgencyId })
        // .then(data => {
        //     this.agents = data;

        //     const agentIds = data.map(a => a.Id);
        //     if (!agentIds.includes(this.selectedAgentId)) {
        //         this.selectedAgentId = null;
        //     }
        // })
        // .catch(error => {
        //     console.error('Error loading agents:', error);
        // });
    }

    handleAgentChange(event) {
        this.selectedAgentId = event.detail.value;

        getAgenciesByAgent({ agentId: this.selectedAgentId })
        .then(data => {
            this.agencies = data;

            const agencyIds = data.map(a => a.Id);
            if (!agencyIds.includes(this.selectedAgencyId)) {
                this.selectedAgencyId = null;
            }
        })
        .catch(error => {
            console.error('Error loading agencies:', error);
        });
    }

    handleWorkTypeChange(event) {
        this.selectedWorkTypeId = event.detail.value;
    }

    handleStartDateChange(event) {
        this.startDate = event.detail.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.detail.value;
    }

    handleReset() {
        this.selectedAgencyId = null;
        this.selectedAgentId = null;
        this.selectedWorkTypeId = null;
        this.startDate = null;
        this.endDate = null;
        this.agents = [];
        this.agencies = [];

        this.fetchInitialAgenciesAndAgents();
    }

    handleAssign() {
        console.log('handleAssign::');
        if (this.isAssignDisabled) {
            this.showToast('Error', 'Please fill in all required fields.', 'error');
            return;
        }

        this.isLoading = true;

        assignAgency({
            workOrderIds: this.selectedIds,
            agencyId: this.selectedAgencyId,
            agentId: this.selectedAgentId,
            //workTypeId: this.selectedWorkTypeId,
            startDate: this.startDate,
            endDate: this.endDate
        })
        .then(() => {
            this.isAssigned = true;
            console.log('sucess::');
            this.showToast('Success', 'Assigned successfully!', 'success');
        })
        .catch(error => {
            console.log('error::'+JSON.stringify(error));
            this.showToast('Error', error.body?.message || 'Assignment failed.', 'error');
        })
        .finally(() => {
            this.isLoading = false; 
        });
    }

    fetchInitialAgenciesAndAgents() {
        getAllAgencies()
            .then(data => {
                this.agencies = data;
            })
            .catch(error => {
                console.error('Error loading agencies:', error);
            });

        getAllAgents()
            .then(data => {
                this.agents = data;
            })
            .catch(error => {
                console.error('Error loading agents:', error);
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}