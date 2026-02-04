/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 04-08-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   22-07-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

import USER_ID from '@salesforce/user/Id';
import APPROVED_LIST_VIEW from '@salesforce/label/c.Work_Order_Approval_List_View_Api_Name';
import PROFILE_NAMES from '@salesforce/label/c.Work_Order_Approval_Profile_Access';
const FIELDS = ['User.Profile.Name'];

import updateWorkOrdersAgent from '@salesforce/apex/WorkOrderBulkApprovalController.updateWorkOrdersAgent';
import getCreatedSchedule from '@salesforce/apex/WorkOrderBulkApprovalController.getCreatedSchedule';

export default class WorkOrderBulkMeterReaderAssignment extends LightningElement {

    @api recordIds = [];
    load = false;
    showError = false;
    disableSubmit = false;
    // profileName;
    isProfileAllowed = false;

    connectedCallback() {
        this.init();
    }

    @wire(getRecord, { recordId: USER_ID, fields: FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            var profileName = data.fields.Profile.displayValue || data.fields.Profile.value.name;
            console.log('Profile Name: ' + profileName);
            const allowedProfiles = PROFILE_NAMES.split(';');
            this.isProfileAllowed = allowedProfiles.includes(profileName);
            if (!this.isProfileAllowed) {
                this.disableSubmit = true;
            }
        } else if (error) {
            console.error('Error fetching user profile:', error);
            this.disableSubmit = true;
        }
    }

    init() {
        console.log('Selected Record Ids:' + JSON.stringify(this.recordIds));
        if (this.recordIds && this.recordIds.length == 0) {
            this.showError = true;
            this.disableSubmit = true;
        }
    }

    get recordCounts() {
        return this.recordIds ? this.recordIds.length : 0;
    }

    get agencyFilter() {
        return 'IsActive=true AND Record_Type_Developer_Name__c=\'Metering\'';
    }

    get agentFilter() {
        var filter = 'Resource_Active__c=true AND Resource_Record_Type_Developer__c=\'MGL_Metering\'';
        if (this.agencyId) {
            filter += ` AND ServiceTerritoryId=\'${this.agencyId}\'`;
        }
        return filter;
    }

    get mrsFilter() {
        var filter = 'Status__c=\'Pending\'';
        if (this.resourceId) {
            filter += ` AND Agent__c=\'${this.resourceId}\'`;
        }
        return filter;
    }

    get errorMessage() {
        if (!this.agentId) {
            return 'Please select an agent.';
        } else if (this.scheduleRec && this.newSchedule) {
            return 'Please select date after ' + this.scheduleRec.endDate + '.';
        }
    }

    get disableMRS() {
        if (this.newSchedule) {
            return true;
        } else if (!this.newSchedule) {
            return false;
        } else if (!this.agencyId) {
            return true;
        }
        return false;
    }

    agencyId;
    agencyName = '';
    agentId;
    handleAgencyChange(event) {
        var agency = event.detail;
        if (agency) {
            this.agencyId = agency.Id;
            this.agencyName = agency.Name;
        } else {
            this.agencyId = null;
            this.agencyName = '';
            this.agentId = null;
            this.mrsId = null;
            this.mrsName = '';
            this.clearLookup('c-custom-lookup-component[data-field-name="agent"]');
            this.clearLookup('c-custom-lookup-component[data-field-name="schedule"]');
        }
        console.log('Agent filter: ' + this.agentFilter);
    }

    scheduleRec;
    handleAgentChange(event) {
        this.agentId = event.detail.Id;
        console.log('Agent Id: ' + this.agentId);
        this.scheduleRec = null;
        if (this.agentId) {
            this.getScheduleRec();
        }
        else {
            this.mrsId = null;
            this.mrsName = '';
            this.clearLookup('c-custom-lookup-component[data-field-name="schedule"]');
        }
    }

    mrsId;
    mrsName;
    handleMRSChange(event) {
        this.mrsId = event.detail.Id;
        console.log('MRS Id: ' + this.mrsId);
    }

    minDate;
    maxDate;
    resourceId;
    getScheduleRec() {
        getCreatedSchedule({ memberId: this.agentId })
            .then(result => {
                console.log('Schedule: ' + JSON.stringify(result));
                this.scheduleRec = result;
                if (this.scheduleRec) {
                    this.agencyId = this.scheduleRec.agencyId;
                    this.resourceId = this.scheduleRec.agentId;
                    this.agencyName = this.scheduleRec.agencyName;
                    this.minDate = this.scheduleRec.fromDate;
                    // this.maxDate = new Date(this.scheduleRec.endDate);
                }
            })
            .catch(error => {
                console.log('Error getting schedule: ' + JSON.stringify(error));
            })
    }

    newSchedule = false;
    handleNewSchedule(event) {
        this.newSchedule = !this.newSchedule;
        if (this.newSchedule) {
            this.mrsId = null;
            this.clearLookup('c-custom-lookup-component[data-field-name="schedule"]');
        }
    }

    clearLookup(selector) {
        var dom = this.template.querySelector(selector);
        if (dom) {
            dom.handleRemovePill();
        }
    }

    startDate;
    endDate
    handleFieldChange(event) {
        var name = event.currentTarget.dataset.fieldName;
        switch (name) {
            case 'startDate':
                this.startDate = event.detail.value;
                break;
            case 'endDate':
                this.endDate = event.detail.value;
                break;
        }
    }

    saveErrorMessage = null;
    validateSave() {
        if (!this.agentId) {
            this.saveErrorMessage = 'Please select an agent.';
            // this.showToastMessage('Error', 'Please select an agent.', 'error');
            return true;
        } else if (!this.newSchedule && !this.mrsId) {
            this.saveErrorMessage = 'Please select a schedule.';
            // this.showToastMessage('Error', 'Please select a schedule.', 'error');
            return true;
        } else if (this.newSchedule && !this.startDate) {
            this.saveErrorMessage = 'Please select a start date.';
            // this.showToastMessage('Error', 'Please select a start date.', 'error');
            return true;
        } else if (this.newSchedule && !this.endDate) {
            this.saveErrorMessage = 'Please select an end date.';
            // this.showToastMessage('Error', 'Please select an end date.', 'error');
            return true;
        } else if (this.newSchedule && this.endDate < this.startDate) {
            this.saveErrorMessage = 'End date should be greater than start date.';
            // this.showToastMessage('Error', 'End date should be greater than start date.', 'error');
            return true;
        }
        this.saveErrorMessage = null;
        return false;
    }

    handleCloseMessage() {
        this.saveErrorMessage = null;
    }

    handleSubmit() {
        this.load = true;
        this.disableSubmit = true;
        if (this.validateSave()) {
            this.load = false;
            this.disableSubmit = false;
            return;
        }
        updateWorkOrdersAgent({
            workOrderList: this.recordIds,
            agentId: this.agentId,
            agencyId: this.agencyId,
            startDate: this.startDate,
            endDate: this.endDate,
            mrsId: this.mrsId,
            newSchedule: this.newSchedule
        })
            .then(result => {
                console.log('Success: ' + JSON.stringify(result));
                if (result == 'success') {
                    // this.showToastMessage('Success', 'Work order approved successfully', 'success');
                    this.handleBack();
                } else {
                    // this.showToastMessage('Error', 'Error while approving work order', 'error');
                }
                this.load = false;
                this.disableSubmit = false;
            })
            .catch(error => {
                this.load = false;
                this.disableSubmit = false;
                // this.showToastMessage('Error', 'Unexpected error occurred', 'error');
                console.error('Error updating work order: ' + JSON.stringify(error));
            });
    }

    handleBack() {
        this.navigateToAccountListView();
    }

    navigateToAccountListView() {
        // window.location.href = '/lightning/o/WorkOrder/list?filterName='+APPROVED_LIST_VIEW;
        window.history.back();
    }

    /**
     * This function creates a new ShowToastEvent, sets the title, message, variant, and mode, and then
     * dispatches the event
     * @param title - The title of the toast message.
     * @param message - The message you want to display in the toast.
     * @param variant - The type of toast message. Valid values are error, warning, success, and info.
     * @param mode - This is the mode of the toast. It can be either 'dismissable','pester' or 'sticky'.
     */
    showToastMessage(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}