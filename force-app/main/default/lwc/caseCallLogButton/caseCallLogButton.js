import { LightningElement, api, wire } from 'lwc';
import updateRemarksAndCount from '@salesforce/apex/CaseUpdateController.updateRemarksAndCount';
import getCaseData from '@salesforce/apex/CaseUpdateController.getCaseData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class CaseCallLogButton extends LightningElement {
    @api recordId;
    remarks = '';
    caseData = {};
    isSaveDisabled = false;
    isLoading = true;
    hasError = false;
    errorMessage = '';
    wiredCaseDataResult;

    /** AUTO-FIX: Get recordId if opened from App Builder */
    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        if (!this.recordId && pageRef?.attributes?.recordId) {
            this.recordId = pageRef.attributes.recordId;
        }
    }

    // Wire service for case data with refresh capability
    @wire(getCaseData, { caseId: '$recordId' })
    wiredCaseData(result) {
        this.wiredCaseDataResult = result;
        if (result.data) {
            this.caseData = result.data.caseRecord;
            this.isSaveDisabled = result.data.isSaveDisabled;
            this.isLoading = false;
            this.hasError = false;
        } else if (result.error) {
            this.handleError(result.error);
        }
    }

    get isSaveButtonDisabled() {
        return this.isLoading || !this.remarks.trim();
    }

    connectedCallback() {
        setTimeout(() => {
            if (!this.recordId) {
                this.handleError('No record ID detected. Use this component on a Case record or as a Case Quick Action.');
                return;
            }
        }, 200);
    }

    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }

    async handleSaveClick() {
        if (!this.remarks.trim()) {
            this.showToast('Missing Comments', 'Please enter comments before saving.', 'error');
            return;
        }

        this.isLoading = true;

        try {
            await updateRemarksAndCount({
                caseId: this.recordId,
                remarks: this.remarks
            });
            
            this.showToast('Success', 'Comments saved successfully', 'success');
            
            // Refresh the data from server to ensure consistency
            await refreshApex(this.wiredCaseDataResult);
            
            // Update local state immediately
            this.updateLocalCaseData();
            
            // Notify other components about record change
            getRecordNotifyChange([{ recordId: this.recordId }]);

            // Clear the remarks
            this.remarks = '';

            // Close after delay
            setTimeout(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            }, 1200);

        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    // Update local caseData with the new remarks for immediate UI update
    updateLocalCaseData() {
        if (!this.wiredCaseDataResult?.data) return;
        
        const currentUser = 'Current User';
        const currentTime = new Date().toLocaleString();
        
        // Update the wired result data directly
        const updatedData = {...this.wiredCaseDataResult.data};
        const updatedCaseRecord = {...updatedData.caseRecord};
        
        // Determine which call slot to update
        if (!updatedCaseRecord.Outbound_Call_1_Remarks__c || updatedCaseRecord.Outbound_Call_1_Remarks__c === '--') {
            updatedCaseRecord.Outbound_Call_1_Done_By__c = currentUser;
            updatedCaseRecord.Outbound_Call_1_Done_Time__c = currentTime;
            updatedCaseRecord.Outbound_Call_1_Remarks__c = this.remarks;
            updatedCaseRecord.Outgoing_Calls_Count__c = (updatedCaseRecord.Outgoing_Calls_Count__c || 0) + 1;
        } else if (!updatedCaseRecord.Outbound_Call_2_Remarks__c || updatedCaseRecord.Outbound_Call_2_Remarks__c === '--') {
            updatedCaseRecord.Outbound_Call_2_Done_By__c = currentUser;
            updatedCaseRecord.Outbound_Call_2_Done_Time__c = currentTime;
            updatedCaseRecord.Outbound_Call_2_Remarks__c = this.remarks;
            updatedCaseRecord.Outgoing_Calls_Count__c = (updatedCaseRecord.Outgoing_Calls_Count__c || 0) + 1;
        } else if (!updatedCaseRecord.Outbound_Call_3_Remarks__c || updatedCaseRecord.Outbound_Call_3_Remarks__c === '--') {
            updatedCaseRecord.Outbound_Call_3_Done_By__c = currentUser;
            updatedCaseRecord.Outbound_Call_3_Done_Time__c = currentTime;
            updatedCaseRecord.Outbound_Call_3_Remarks__c = this.remarks;
            updatedCaseRecord.Outgoing_Calls_Count__c = (updatedCaseRecord.Outgoing_Calls_Count__c || 0) + 1;
            // Disable save after 3rd call
            updatedData.isSaveDisabled = true;
        }
        
        updatedData.caseRecord = updatedCaseRecord;
        this.wiredCaseDataResult.data = updatedData;
        
        // Update reactive properties
        this.caseData = updatedCaseRecord;
        this.isSaveDisabled = updatedData.isSaveDisabled;
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleError(error) {
        let msg = error?.body?.message || error?.message || 'Unexpected error occurred';
        this.hasError = true;
        this.errorMessage = msg;
        this.isLoading = false;

        this.showToast('Error', msg, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    // Getters
    get showContent() { return !this.isLoading && !this.hasError; }
    get showError() { return this.hasError; }

    get call1DoneBy() { return this.caseData?.Outbound_Call_1_Done_By__c || '--'; }
    get call1DoneTime() { return this.caseData?.Outbound_Call_1_Done_Time__c || '--'; }
    get call1Remarks() { return this.caseData?.Outbound_Call_1_Remarks__c || '--'; }

    get call2DoneBy() { return this.caseData?.Outbound_Call_2_Done_By__c || '--'; }
    get call2DoneTime() { return this.caseData?.Outbound_Call_2_Done_Time__c || '--'; }
    get call2Remarks() { return this.caseData?.Outbound_Call_2_Remarks__c || '--'; }

    get call3DoneBy() { return this.caseData?.Outbound_Call_3_Done_By__c || '--'; }
    get call3DoneTime() { return this.caseData?.Outbound_Call_3_Done_Time__c || '--'; }
    get call3Remarks() { return this.caseData?.Outbound_Call_3_Remarks__c || '--'; }

    get outgoingCallsCount() { return this.caseData?.Outgoing_Calls_Count__c || 0; }
}