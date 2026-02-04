/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 13-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   13-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MeteringAppointmentListViewComponent extends NavigationMixin(LightningElement) {

      // backing variable
    _appointmentsList = [];

    appointmentSearchToggle = false;

    @api
    get appointmentsList() {
        return this._appointmentsList;
    }
    set appointmentsList(value) {
        this._appointmentsList = value || [];

        // DEBUG: show how many records arrived & first id
        const len = this._appointmentsList.length;
        const firstId = len > 0 ? this._appointmentsList[0].id : 'none';

        // this.dispatchEvent(
        //     new ShowToastEvent({
        //         title: 'DEBUG: Child appointmentsList',
        //         message: `Length: ${len}, first id: ${firstId}`,
        //         variant: 'info'
        //     })
        // );
    }

    get hasAppointments() {
        return this._appointmentsList && this._appointmentsList.length > 0;
    }

    connectedCallback() {
        // this.dispatchEvent(
        //     new ShowToastEvent({
        //         title: 'DEBUG: Child connectedCallback',
        //         message: 'Child component mounted successfully',
        //         variant: 'info'
        //     })
        // );
    }


    filterAppointmentSearch(event) {
        var value = event.detail.value;
        this.appointmentsList = [];
        if (value && value != '') {
            this.appointmentsList = this.appointmentsListMain.filter(group => {
                const searchValue = value.toLowerCase();
                return (
                    (group.accountName && group.accountName.toLowerCase().includes(searchValue)) ||
                    (group.DetailAccountSummary && group.DetailAccountSummary.toLowerCase().includes(searchValue)) ||
                    (group.customerContactNo && String(group.customerContactNo).toLowerCase().includes(searchValue)) ||
                    (group.phone && String(group.phone).toLowerCase().includes(searchValue)) ||
                    (group.personHomePhone && String(group.personHomePhone).toLowerCase().includes(searchValue)) ||
                    (group.secondaryTelephone && String(group.secondaryTelephone).toLowerCase().includes(searchValue)) ||
                    (group.secondaryPhone && String(group.secondaryPhone).toLowerCase().includes(searchValue)) ||
                    (group.meterNumber && String(group.meterNumber).toLowerCase().includes(searchValue))
                );
            });
        } else {
            this.appointmentsList = this.appointmentsListMain;
        }
    }

    handleAppointmentClick(event) {
        const workOrderId = event.currentTarget.dataset.id;

        if (FORM_FACTOR == 'Large') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { 
                    recordId: workOrderId, 
                    actionName: 'view' 
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

}