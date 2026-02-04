/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 29-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   03-07-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

import USER_ID from '@salesforce/user/Id';
import APPROVED_LIST_VIEW from '@salesforce/label/c.Work_Order_Approval_List_View_Api_Name';
import PROFILE_NAMES from '@salesforce/label/c.Work_Order_Approval_Profile_Access';
const FIELDS = ['User.Profile.Name'];

import updateWorkOrder from '@salesforce/apex/WorkOrderBulkApprovalController.updateWorkOrder';
import sendEmail from '@salesforce/apex/WorkOrderBulkApprovalController.sendEmail';
import getJobStatus from '@salesforce/apex/WorkOrderBulkApprovalController.getJobStatus';
export default class WorkOrderBulkApprovalComponent extends NavigationMixin(LightningElement) {

    @api recordIds = [];
    @api mode = 'approval';
    @api redirect;

    load = false;
    showError = false;
    disableSubmit = false;
    // profileName;
    isProfileAllowed = false;

    // Progress tracking
    showProgress = false;
    currentStep = 0;
    totalSteps = 4;
    currentStepName = '';
    jobKey = null;
    pollingInterval = null;

    connectedCallback() {
        console.log('[WO Approval] connectedCallback start');
        this.init();
        console.log('[WO Approval] connectedCallback done');
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
        console.log('[WO Approval] Selected Record Ids:', JSON.stringify(this.recordIds));
        if (this.recordIds && this.recordIds.length == 0) {
            this.showError = true;
            this.disableSubmit = true;
        }
    }

    get recordCounts() {
        return this.recordIds ? this.recordIds.length : 0;
    }

    get headerText() {
        return this.mode == 'approval' ? 'Work Orders Approvals' : 'Send Email';
    }

    get progressPercentage() {
        if (this.totalSteps === 0) return 0;
        return Math.round((this.currentStep / this.totalSteps) * 100);
    }

    get progressStyle() {
        return `width: ${this.progressPercentage}%`;
    }

    approvalSubmit() {
        console.log('[WO Approval] approvalSubmit start');
        this.showProgress = true;
        this.disableSubmit = true;
        this.currentStepName = 'Initializing...';
        this.currentStep = 0;
        this.totalSteps = 4;

        updateWorkOrder({
            workOrderList: this.recordIds,
            approvalStatus: 'Approved',
        })
            .then(result => {
                console.log('[WO Approval] updateWorkOrder result:', JSON.stringify(result));
                if (result && result !== 'error') {
                    // result is the jobKey
                    this.jobKey = result;
                    console.log('[WO Approval] Tracking jobKey:', this.jobKey);

                    // Start polling for progress
                    this.startPolling();
                } else {
                    this.showToastMessage('Error', 'Error while approving work order', 'error');
                    this.showProgress = false;
                    this.disableSubmit = false;
                }
            })
            .catch(error => {
                this.showProgress = false;
                this.disableSubmit = false;
                this.showToastMessage('Error', 'Unexpected error occurred', 'error');
                console.error('[WO Approval] Error updating work order:', JSON.stringify(error));
            });
    }

    startPolling() {
        console.log('[WO Approval] Starting polling every 2 seconds for jobKey:', this.jobKey);
        this.pollJobStatus(); // Immediate first poll
        this.pollingInterval = setInterval(() => {
            this.pollJobStatus();
        }, 2000);
    }
    
    pollJobStatus() {
        if (!this.jobKey) {
            console.warn('[WO Approval] ⚠️ jobKey is null/undefined, skipping poll');
            return;
        }
        
        console.log('[WO Approval] 🔄 Polling with jobKey:', this.jobKey);
        getJobStatus({ jobKey: this.jobKey })
            .then(status => {
                console.log('[WO Approval] getJobStatus response:', JSON.stringify(status));
                if (status) {
                    this.currentStep = status.currentStep;
                    this.totalSteps = status.totalSteps;
                    this.currentStepName = status.stepName;
                    console.log(`[WO Approval] ✅ Polled: ${this.currentStep}/${this.totalSteps} - ${this.currentStepName}`);
                    
                    if (status.isComplete) {
                        this.stopPolling();
                        this.showToastMessage('Success', 'Work orders approved and PDFs generated successfully', 'success');
                        setTimeout(() => this.handleBack(), 1500);
                    }
                } else {
                    console.log('[WO Approval] ℹ️ Status is null, waiting for Queueable to write cache...');
                }
            })
            .catch(error => {
                console.error('[WO Approval] Error polling:', JSON.stringify(error));
            });
    }
    
    stopPolling() {
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
            this.pollingInterval = null;
        }
    }
    
    disconnectedCallback() {
        this.stopPolling();
    }

    sendEmailSubmit() {
        console.log('sendEmailSubmit');
        this.load = true;
        this.disableSubmit = true;
        sendEmail({
            workOrderList: this.recordIds,
        })
            .then(result => {
                console.log('Success: ' + JSON.stringify(result));
                if (result == 'success') {
                    this.showToastMessage('Success', 'Email sent successfully', 'success');
                    this.handleBack();
                } else {
                    this.showToastMessage('Error', 'Error while sending email', 'error');
                }
                this.load = false;
                this.disableSubmit = false;
                this.disableSubmit = false;
            })
            .catch(error => {
                this.load = false;
                this.disableSubmit = false;
                this.showToastMessage('Error', 'Unexpected error occurred', 'error');
                console.error('Error sending email: ' + JSON.stringify(error));
            })
    }

    handleSubmit() {
        if (this.mode == 'approval') {
            this.approvalSubmit();
        } else if (this.mode == 'send_email') {
            this.sendEmailSubmit();
        }
    }

    handleBack() {
        this.navigateToAccountListView();
    }

    navigateToAccountListView() {
        console.log('APPROVED_LIST_VIEW:' + APPROVED_LIST_VIEW);
        // window.location.href = '/lightning/o/WorkOrder/list?filterName='+APPROVED_LIST_VIEW;
        // const previousUrl = document.referrer;
        // if (previousUrl) {
        //     window.location.href = previousUrl; // loads fresh, not cached } else { window.history.back(); // fallback }
        // }
        if (this.redirect) {
            const valueSelectedEvent = new CustomEvent("close", {});
            this.dispatchEvent(valueSelectedEvent);
        } else {
            window.history.go(-1);
        }
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