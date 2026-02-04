import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import getCurrentUserName from '@salesforce/apex/AgentAttendanceController.getCurrentUserName';
import getTodayAttendanceWithUserType from '@salesforce/apex/AgentAttendanceController.getTodayAttendanceWithUserType';
import getUserBlockAccessInfo from '@salesforce/apex/AgentAttendanceController.getUserBlockAccessInfo';
import handleAttendance from '@salesforce/apex/AgentAttendanceController.handleAttendance';
import getBreakReasons from '@salesforce/apex/AgentAttendanceController.getBreakReasons';
import createBreakRecord from '@salesforce/apex/AgentAttendanceController.createBreakRecord';
import getOngoingBreak from '@salesforce/apex/AgentAttendanceController.getOngoingBreak';
import endBreak from '@salesforce/apex/AgentAttendanceController.endBreak';
import getUserProfileName from '@salesforce/apex/AgentAttendanceController.getUserProfileName';
import triggerScheduledJob from '@salesforce/apex/AgentAttendanceController.triggerScheduledJob';

export default class QuickActionRTComponent extends LightningElement {    @track isLoading = true;
@track isBackOffice = false;
    @track quickActionData = [
        { actionName: 'Search Cases', description: 'Find and manage customer cases', iconName: 'standard:case', navigationTarget: 'Search_Cases' },
        { actionName: 'CIC0', description: 'Customer 360', iconName: 'standard:account', navigationTarget: 'CIC0' }
    ];

    @track userName = '';
    @track formattedDateTime = '';
    @track blockOptions = [];
    @track selectedBlock = '';
    @track typeOfWork = '';
    @track isFrontOffice = false;

    @track showCheckInButton = false;
    @track showCheckOutButton = false;
    @track checkInTime = '';
    @track checkOutTime = '';
    @track isBlockDisabled = false;

    @track breakReasons = [];
    @track selectedBreakReason = null;
    @track onBreak = false;
    @track showBreak = false;
    @track breakStartTime = null;
    @track breakRecordId = null;
    @track isBreakDisabled = false;

    @track subFunctionOptions = [];
    @track selectedSubFunction = '';
    @track isSubFunctionDisabled = false;

    connectedCallback() {
        this.initializeComponent();
    }

    async initializeComponent() {
        try {
            this.setFormattedDateTime();

        // 1. Get attendance record for today
        const attendanceResult = await getTodayAttendanceWithUserType();

        let initialSelectedSubFunction = '';
        if (attendanceResult && attendanceResult.record) {
            const record = attendanceResult.record;
            this.selectedBlock = this.addMGLPrefix(record.Block__c);
            initialSelectedSubFunction = record.Sub_Function__c ? String(record.Sub_Function__c) : '';
            this.isSubFunctionDisabled = !!record.Day_In_Timestamp__c;

            if (record.Day_In_Timestamp__c) {
                this.checkInTime = new Date(record.Day_In_Timestamp__c).toLocaleString();
                this.showCheckInButton = false;
                this.showCheckOutButton = !record.Day_Out_Timestamp__c;
                this.isBlockDisabled = true; // Only disable after check-in
                this.showBreak = !record.Day_Out_Timestamp__c;
            }

            if (record.Day_Out_Timestamp__c) {
                this.checkOutTime = new Date(record.Day_Out_Timestamp__c).toLocaleString();
                this.selectedSubFunction = record.Sub_Function__c || '';
                this.isSubFunctionDisabled = false;
                this.resetForNewDay();
            }
        } else {
            this.showCheckInButton = true;
            initialSelectedSubFunction = '';
            this.isSubFunctionDisabled = false;
            this.isBlockDisabled = false; // Ensure block is enabled for new check-in
        }
            // 2. Load user data (profile, blocks, etc.)
            await this.loadUserData();

            // 3. Load sub function options, injecting previously selected value if missing
            await this.fetchSubFunctionOptionsWithBackendValue(initialSelectedSubFunction);
            // Set the selected sub function after options are loaded
            this.selectedSubFunction = initialSelectedSubFunction;

            // 4. Load break reasons and initialize break state
            await Promise.all([
                this.fetchBreakReasons(),
                this.initializeBreakState()
            ]);

        } catch (error) {
            console.error('Initialization error:', error);
            this.showError('Initialization Error', this.getErrorMessage(error));
        } finally {
            this.isLoading = false;
        }
    }

    setFormattedDateTime() {
        this.formattedDateTime = new Date().toLocaleString();
        setInterval(() => {
            this.formattedDateTime = new Date().toLocaleString();
        }, 60000);
    }

    async loadUserData() {
        try {
            const [name, profileName, blockInfo] = await Promise.all([
                getCurrentUserName(),
                getUserProfileName(),
                getUserBlockAccessInfo()
            ]);

            this.userName = name;
            const isCRMAdmin = profileName === 'CRM Admin';

            this.typeOfWork = blockInfo.typeOfWork;
            this.isFrontOffice = this.typeOfWork === 'Front Office' && !isCRMAdmin;

            this.blockOptions = blockInfo.blockOptions.map(block => ({
                label: this.addMGLPrefix(block),
                value: block
            }));

            if (isCRMAdmin) {
                this.selectedBlock = 'Bandra Nodal Office';
                this.isBlockDisabled = true;
            } else if (blockInfo.defaultBlock) {
                this.selectedBlock = this.addMGLPrefix(blockInfo.defaultBlock);
                this.isBlockDisabled = !this.isFrontOffice;
            }

        } catch (error) {
            console.error('Error loading user data:', error);
            throw error;
        }
    }

    fetchSubFunctionOptionsWithBackendValue(forcedValue) {
    let options = [];

    if (this.typeOfWork === 'Front Office') {
        options = [
            { label: 'Support cell - Name transfer/Refund Management', value: 'Support cell - Name transfer/Refund Management' },
             { label: 'Escalation Cell', value: 'Escalation Cell' },
            { label: 'Walk-in', value: 'Walk-in' }
        ];
    } else if (this.typeOfWork === 'Back Office') {
        options = [
            { label: 'Email', value: 'Email' },
            { label: 'Live Chat', value: 'Live Chat' },
             { label: 'letter', value: 'letter' },
              { label: 'MGL Connect', value: 'MGL Connect' },
               { label: 'FRL', value: 'FRL' },
        ];
        this.isBackOffice = true;
    }else if (this.typeOfWork === 'Call Center') {
        options = [
            { label: 'Inbound', value: 'Inbound' },
            { label: 'Outbound', value: 'Outbound' }
        ];
    }

    // Inject forced value if it’s missing (e.g., restored from DB but not in the static list)
    if (forcedValue && !options.some(opt => opt.value === forcedValue)) {
        options.unshift({ label: forcedValue, value: forcedValue });
    }

    this.subFunctionOptions = [...options];
}
async handleRefreshMIS() {
    this.isLoading = true;
    try {
        await triggerScheduledJob();
        this.showSuccess('MIS refresh job has been triggered.');
    } catch (error) {
        this.showError('Failed to trigger MIS job', this.getErrorMessage(error));
    } finally {
        this.isLoading = false;
    }
}

    async fetchBreakReasons() {
        try {
            const data = await getBreakReasons();
            if (data && Array.isArray(data)) {
                this.breakReasons = data.map(reason => ({
                    label: String(reason),
                    value: String(reason)
                }));
            }
        } catch (error) {
            console.error('Error fetching break reasons:', error);
            throw error;
        }
    }

    async initializeBreakState() {
        try {
            const result = await getOngoingBreak();
            if (result && result.Id) {
                this.onBreak = true;
                this.selectedBreakReason = String(result.Break_Codes__c);
                this.breakStartTime = new Date(result.Break_Start_Time__c);
                this.breakRecordId = result.Id;
                this.isBreakDisabled = true;
            }
        } catch (error) {
            console.error('Error initializing break state:', error);
            throw error;
        }
    }

    resetForNewDay() {
    this.showCheckInButton = true;
    this.showCheckOutButton = false;
    this.showBreak = false;
      this.isBlockDisabled = false; // Re-enable block for new day
    this.isSubFunctionDisabled = false;

    if (this.isFrontOffice) {
        this.selectedBlock = '';
    } else if (this.typeOfWork === 'Back Office') {
        this.selectedBlock = 'MGL Back Office';
    } else if (this.typeOfWork === 'Call Center') {
        this.selectedBlock = 'MGL Call Center';
    }
}


    handleBlockChange(event) {
        this.selectedBlock = event.detail.value;
    }

    handleSubFunctionChange(event) {
        this.selectedSubFunction = event.detail.value;
    }

    handleBreakReasonChange(event) {
        this.selectedBreakReason = event.detail.value;
    }

    async handleCheckIn() {
    // First validate all required fields
    if (!this.selectedSubFunction) {
        this.showToast('Error', 'Please select a sub-function before checking in', 'error');
        return;
    }

    // Additional validation for Front Office users
    if (this.isFrontOffice && !this.selectedBlock) {
        this.showToast('Error', 'Please select a location before checking in', 'error');
        return;
    }

    this.isLoading = true;
    try {
        await handleAttendance({
            actionType: 'Check-In',
            block: this.removeMGLPrefix(this.selectedBlock),
            timestamp: new Date().toISOString(),
            subFunction: this.selectedSubFunction
        });

        this.checkInTime = new Date().toLocaleString();
        this.showCheckInButton = false;
        this.showCheckOutButton = true;
        this.isBlockDisabled = true; // Now disable the block after successful check-in
        this.isSubFunctionDisabled = true;
        this.showBreak = true;
        this.showSuccess('Checked in successfully');
    } catch (error) {
        // Improved error message handling
        const errorMsg = this.getErrorMessage(error);
        const userFriendlyMsg = errorMsg.includes('Location is required') ? 
            'Please select a valid location before checking in' : 
            'Check-in failed. Please try again or contact support.';
        
        this.showError('Check-in Failed', userFriendlyMsg);
    } finally {
        this.isLoading = false;
    }
}

    async handleCheckOut() {
        this.isLoading = true;
        try {
            await handleAttendance({
                actionType: 'Check-Out',
                block: this.removeMGLPrefix(this.selectedBlock),
                timestamp: new Date().toISOString()
            });
            this.checkOutTime = new Date().toLocaleString();
            this.resetForNewDay();
            this.resetBreakState();
            this.selectedSubFunction = ''; // <<< force-clear UI
            this.showSuccess('Checked out successfully');
        } catch (error) {
            this.showError('Check-out failed', this.getErrorMessage(error));
        } finally {
            this.isLoading = false;
        }
    }

    async handleStartBreak() {
        if (!this.selectedBreakReason) {
            this.showToast('Error', 'Please select a break reason', 'error');
            return;
        }

        this.isLoading = true;
        try {
            const result = await createBreakRecord({ reason: this.selectedBreakReason });
            if (!result) throw new Error('No break record ID returned');
            this.onBreak = true;
            this.isBreakDisabled = true;
            this.breakRecordId = result;
            this.breakStartTime = new Date();
            this.showSuccess('Break started successfully');
        } catch (error) {
            this.showError('Failed to start break', this.getErrorMessage(error));
            this.resetBreakState();
        } finally {
            this.isLoading = false;
        }
    }

    async handleEndBreak() {
        if (!this.breakRecordId) {
            this.showToast('Error', 'No active break to end', 'error');
            return;
        }

        this.isLoading = true;
        try {
            await endBreak({ breakId: this.breakRecordId });
            this.resetBreakState();
            this.showSuccess('Break ended successfully');
        } catch (error) {
            this.showError('Failed to end break', this.getErrorMessage(error));
        } finally {
            this.isLoading = false;
        }
    }

    resetBreakState() {
        this.onBreak = false;
        this.selectedBreakReason = null;
        this.breakStartTime = null;
        this.breakRecordId = null;
        this.isBreakDisabled = false;
    }

    addMGLPrefix(value) {
        const prefixes = { 'Back Office': 'MGL Back Office', 'Call Center': 'MGL Call Center' };
        return prefixes[value] || value;
    }

    removeMGLPrefix(value) {
        const mappings = { 'MGL Back Office': 'Back Office', 'MGL Call Center': 'Call Center' };
        return mappings[value] || value;
    }

    getErrorMessage(error) {
        if (error?.body?.message) return error.body.message;
        return error?.message || 'An unexpected error occurred';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    showSuccess(message) {
        this.showToast('Success', message, 'success');
    }

    showError(title, message) {
        this.showToast(title, message || 'An error occurred', 'error');
    }

    handleActionClick(event) {
        const actionName = event.currentTarget.dataset.name;
        const action = this.quickActionData.find(a => a.actionName === actionName);
        if (action) {
            this[NavigationMixin.Navigate]({
                type: 'standard__navItemPage',
                attributes: { apiName: action.navigationTarget }
            });
        }
    }
}