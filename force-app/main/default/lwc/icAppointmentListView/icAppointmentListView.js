import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getFlatAppointments from '@salesforce/apex/IcDashboardController.getFlatAppointmentsByStatus';
import getWorkOrderIdFromSA from '@salesforce/apex/IcDashboardController.getWorkOrderIdFromSA';

import FORM_FACTOR from '@salesforce/client/formFactor';

export default class IcAppointmentListView extends NavigationMixin(LightningElement) {
    _selectedStatus;
    @api
    get selectedStatus() {
        return this._selectedStatus;
    }
    set selectedStatus(value) {
        this._selectedStatus = value;
        if (this.secondPage) {
            this.fetchAppointments();
        } 
    }
    @api selectedType;
    @api secondPage;
    @track error;
    @track appointmentsList = [];
    allAppointmentList = [];

    hasWorkType = false;
    workTypeList = [];
    allWorkType = [];
    workTypeSearchToggle = false;

    @track isLoading = true;
    @track hasAppointments = false;
    appointmentSearchToggle = false;
    
    connectedCallback() {
        this.fetchAppointments();
    }

    fetchAppointments() {

        // Start loading and clear previous data
        this.isLoading = true;
        this.error = undefined;

        getFlatAppointments({ status: this.selectedStatus, type: this.selectedType })
        .then((result) => {

            console.log('======getFlatAppointments=========>', JSON.stringify(result));

            if (result && result.length > 0) {
                this.workTypeList = result;
                this.allWorkType = result;
                this.hasWorkType = true;
            }else{
                this.hasWorkType = true;
            }
            
            this.isLoading = false;
        })
        .catch((error) => {
            console.error('Error fetching appointments:', error);
            this.error = error?.body?.message || error?.message || 'Unknown error occurred while fetching appointments.';
            this.isLoading = false;
        });
    }

    getAppointments(workType){

        if(this.allWorkType && workType){

            let appointments = this.allWorkType.filter(wrk => wrk.name === workType).map(wT => wT.appointments);
            appointments = appointments[0];

            this.appointmentsList = appointments.map(item => ({
                ...item,
                formattedSchedEndDate: item.SchedEndTime
                    ? new Date(item.SchedEndTime).toLocaleDateString('en-IN', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric'
                    })
                    : '',
                formattedDueAmount: item.DueAmount ? `₹${item.DueAmount}` : '₹0',
                label: item.appointmentType || '',
                accountName: item.accountName || '',
                // DetailAccountSummary: item.buildingStreet || ''
            }));

            this.allAppointmentList = JSON.parse(JSON.stringify(this.appointmentsList));

            this.hasAppointments = true;
            
            this.isLoading = false;

        }else {
            this.appointmentsList = [];
            this.allAppointmentList = [];
        }
    }

    handleWorkTypeClick(event){ 
        this.isLoading = true;
        this.hasWorkType = false;
        const workTypeName = event.currentTarget.dataset.name;
        this.getAppointments(workTypeName);
    }

    handleBackToAppointment(){
        this.hasWorkType = true;
        this.hasAppointments = false;
    }

    handleAppointmentClick(event) {

        this.isLoading = true;
        const serviceAppointmentId = event.currentTarget.dataset.id;

        getWorkOrderIdFromSA({ serviceAppointmentId })
        .then(workOrderId => {
            if (workOrderId) {
                this.navigateToWorkOrderInFSL(workOrderId);
            } else {
                this.showToast(
                    'Missing Work Order',
                    `No Work Order is associated with this Service Appointment.\nServiceAppointmentId: ${serviceAppointmentId}`,
                    'warning'
                );
                console.error('No Work Order ID returned from Apex.');
            }
        })
        .catch(error => {
            let errorMessage = 'An error occurred while fetching the Work Order.';
            if (error?.body?.message) {
                errorMessage = error.body.message;
            } else if (error?.message) {
                errorMessage = error.message;
            }
            this.showToast('Error', errorMessage, 'error');
            console.error('Error fetching Work Order ID:', error);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleAppointmentSearch(){
        this.appointmentSearchToggle = !this.appointmentSearchToggle;
    }

    handleWorkTypeSearch(){
        this.workTypeSearchToggle = !this.workTypeSearchToggle;
    }

    filterAppointmentSearch(event) {
        var value = event.detail.value;
        this.appointmentsList = [];
        if (value && value != '') {
            this.appointmentsList = this.allAppointmentList.filter(group => {
                const searchValue = value.toLowerCase();
                return (
                    (group.accountName && group.accountName.toLowerCase().includes(searchValue)) ||
                    (group.DetailAccountSummary && group.DetailAccountSummary.toLowerCase().includes(searchValue)) ||
                    (group.formattedDueAmount && group.formattedDueAmount.toString().toLowerCase().includes(searchValue))
                );
            });
        } else {
            this.appointmentsList = this.allAppointmentList;
        }
    }

    filterWorkTypeSearch(event) {
        var value = event.detail.value;
        this.workTypeList = [];
        if (value && value != '') {
            this.workTypeList = this.allWorkType.filter(group => {
                const searchValue = value.toLowerCase();
                return (group.name && group.name.toLowerCase().includes(searchValue));
            });
        } else {
            this.workTypeList = this.allWorkType;
        }
    }

    navigateToWorkOrderInFSL(workOrderId) {
        if (FORM_FACTOR === 'Large') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: workOrderId,
                    actionName: 'view',
                },
            });
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: `com.salesforce.fieldservice://v1/sObject/${workOrderId}/overview`
                }
            });
        }
    }

    handleBackToHome() {
        // Reset the state
        this.secondPage = false;
        this.openMainPage = true;

        // Clear appointments data so next time fetch gets fresh result
        this.appointmentsList = [];
        this.error = undefined;

        // Dispatch event to parent
        const event = new CustomEvent('childevent', {
            detail: {
                secondPage: this.secondPage,
                openMainPage: this.openMainPage
            }
        });
        this.dispatchEvent(event);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}