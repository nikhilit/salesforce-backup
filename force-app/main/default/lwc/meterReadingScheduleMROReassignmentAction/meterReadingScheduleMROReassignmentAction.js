/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 02-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   07-10-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrentMRURecord from '@salesforce/apex/MRSMROReassignController.getCurrentMRURecord';
import getMRSRelatedWorkOrders from '@salesforce/apex/MRSMROReassignController.getMRSRelatedWorkOrders';
import getMRSRelatedWorkOrdersNoOffset from '@salesforce/apex/MRSMROReassignController.getMRSRelatedWorkOrdersNoOffset';
import updateWorkOrdersAgent from '@salesforce/apex/WorkOrderBulkApprovalController.updateWorkOrdersAgent';
import getCreatedSchedule from '@salesforce/apex/WorkOrderBulkApprovalController.getCreatedSchedule';
export default class MeterReadingScheduleMROReassignmentAction extends LightningElement {

    @track workOrderRecords = [];
    @track limitValue = 50;
    @track offset = 0;
    @track mRSRecord;
    @track isLoading = false;
    @track selectedRecords = [];
    allDataLoaded = false;
    _recordId;
    spinner = false;

    @track screens = {
        selectWorkOrders: true,
        selectReassignPage: false,
    }

    @api mrsDisabled = false;

    get disableLookup() {
        return !this.mrsDisabled;
    }

    @api
    set recordId(value) {
        this._recordId = value;
        this.init();
    }

    get recordId() {
        return this._recordId;
    }

    get recordCount() {
        // if (this.allDataLoaded) {
        return this.workOrderRecords.length; // exact count
        // } else {
        //     return `${this.workOrderRecords.length}+`; // show as "10+" etc.
        // }
    }

    get workOrderColumns() {
        return [
            {
                label: 'Work Order Number',
                fieldName: 'recordUrl',
                type: 'url',
                typeAttributes: {
                    label: { fieldName: 'WorkOrderNumber' },
                    target: '_blank'
                }
            },
            { label: 'Business Partner', fieldName: 'Customer_Full_Name__c', type: 'text' },
            { label: 'BP Number', fieldName: 'BP_Number__c', type: 'text' },
            { label: 'Building Name', fieldName: 'Building_Name__c', type: 'text' },
            // { label: 'Start Date', fieldName: 'Start_Date_Formula__c', type: 'text' },
            // { label: 'End Date', fieldName: 'End_Date__c', type: 'text' }
        ];
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
        var filter = '';
        if (this.resourceId) {
            filter += `Agent__c=\'${this.resourceId}\'`;
        }
        return filter;
    }

    get getShowTable() {
        return (this.workOrderRecords != null && this.workOrderRecords.length > 0);
    }

    connectedCallback() {
    }

    selectedMRSId;
    selectedMRSName;
    init() {
        getCurrentMRURecord({ recordId: this._recordId })
            .then(data => {
                this.mRSRecord = data;
                if (this.mRSRecord) {
                    this.selectedMRSId = this.mRSRecord.Id;
                    this.selectedMRSName = this.mRSRecord.MRS_Custom_Name__c;
                    this.loadData();
                }
            })
            .catch(error => {
                console.error('Error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    originalData = [];
    loadData() {
        // 🚫 Stop if already loading or all data loaded
        if (this.isLoading || this.allDataLoaded) {
            return;
        }

        this.isLoading = true;
        this.workOrderRecords = [];
        getMRSRelatedWorkOrdersNoOffset({ mrsId: this.selectedMRSId })
            .then(data => {
                if (data && data.length > 0) {
                    const newData = data.map(record => ({
                        ...record,
                        recordUrl: '/' + record.Id,
                        accountName: record.Account.Name,
                    }));
                    this.workOrderRecords = [...this.workOrderRecords, ...newData];
                    this.originalData = JSON.parse(JSON.stringify([...this.originalData, ...newData]));
                    this.offset += this.limitValue;
                    this.generateBuildingDropdown();

                    // ✅ If fewer than limit returned → no more data left
                    if (data.length < this.limitValue) {
                        this.allDataLoaded = true;
                    }
                } else {
                    this.allDataLoaded = true;
                }
            })
            .catch(error => {
                console.error('Error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    buildingOptions = [];
    generateBuildingDropdown() {
        if (!this.originalData || this.originalData.length === 0) {
            return [];
        }

        // Step 1: Count records by building
        const countMap = {};

        this.originalData.forEach(record => {
            let name = record.Building_Name__c;

            // Normalize blank building name → Others
            if (!name || name.trim() === '') {
                name = 'Others';
            }

            if (!countMap[name]) {
                countMap[name] = 0;
            }
            countMap[name] += 1;
        });

        // Step 2: Convert map → dropdown options
        const options = Object.keys(countMap).map(name => {
            return {
                label: `${name} (${countMap[name]})`,
                value: name
            };
        });

        // (Optional) Sort alphabetically, keeping Others at bottom
        this.buildingOptions = options.sort((a, b) => {
            if (a.value === 'Others') return 1;
            if (b.value === 'Others') return -1;
            return a.value.localeCompare(b.value);
        });
    }

    handleBuildingFilter(event) {
        const selectedValues = event.detail.value; // <-- array

        if (selectedValues && selectedValues.length > 0) {
            this.workOrderRecords = this.originalData.filter(record => {

                const buildingName = record.Building_Name__c && record.Building_Name__c.trim() !== ''
                    ? record.Building_Name__c
                    : 'Others';

                // selectedValues is array → use includes()
                return selectedValues.includes(buildingName);
            });
        } else {
            this.workOrderRecords = [...this.originalData];
        }
    }

    handleSearch(event) {
        const searchTerm = event.target.value ? event.target.value.toLowerCase() : '';

        if (!searchTerm) {
            this.workOrderRecords = [...this.originalData]; // reset if search is empty
            return;
        }

        this.workOrderRecords = this.originalData.filter(record => {
            return (
                (record.WorkOrderNumber || '').toLowerCase().includes(searchTerm) ||
                (record.Customer_Full_Name__c || '').toLowerCase().includes(searchTerm) ||
                (record.BP_Number__c || '').toLowerCase().includes(searchTerm) ||
                (record.Building_Name__c || '').toLowerCase().includes(searchTerm) ||
                (record.Start_Date_Formula__c || '').toLowerCase().includes(searchTerm) ||
                (record.End_Date__c || '').toLowerCase().includes(searchTerm) ||
                (record.accountName || '').toLowerCase().includes(searchTerm)
            );
        });
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

    handleScroll(event) {
        if (this.allDataLoaded || this.isLoading) {
            return; // 🚫 Prevent extra calls once data is exhausted
        }

        const { scrollTop, scrollHeight, offsetHeight } = event.target;
        if (Math.ceil(scrollTop) >= scrollHeight - offsetHeight) {
            this.loadData();
        }
    }

    getSelectedName(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedRecords = selectedRows;
    }

    get selectedMRORecCount() {
        return 'Selected Records: ' + this.selectedRecords.length;
    }

    handleNext() {
        if (this.selectedRecords != null && this.selectedRecords.length == 0) {
            this.showToastMessage('Error', 'Please select at least one record', 'error', 'dismissable');
            this.spinner = false;
            return;
        }
        this.screens.selectWorkOrders = false;
        this.screens.selectReassignPage = true;
    }

    handleBack() {
        this.screens.selectWorkOrders = true;
        this.screens.selectReassignPage = false;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
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
            // this.saveErrorMessage = 'Please select an agent.';
            this.showToastMessage('Error', 'Please select an agent.', 'error');
            return true;
        } else if (!this.newSchedule && !this.mrsId) {
            // this.saveErrorMessage = 'Please select a schedule.';
            this.showToastMessage('Error', 'Please select a schedule.', 'error');
            return true;
        } else if (this.newSchedule && !this.startDate) {
            // this.saveErrorMessage = 'Please select a start date.';
            this.showToastMessage('Error', 'Please select a start date.', 'error');
            return true;
        } else if (this.newSchedule && !this.endDate) {
            // this.saveErrorMessage = 'Please select an end date.';
            this.showToastMessage('Error', 'Please select an end date.', 'error');
            return true;
        } else if (this.newSchedule && this.endDate < this.startDate) {
            // this.saveErrorMessage = 'End date should be greater than start date.';
            this.showToastMessage('Error', 'End date should be greater than start date.', 'error');
            return true;
        }
        this.saveErrorMessage = null;
        return false;
    }

    handleCloseMessage() {
        this.saveErrorMessage = null;
    }

    disableSubmit = false;
    handleSubmit() {
        this.spinner = true;
        this.disableSubmit = true;
        if (this.validateSave()) {
            this.spinner = false;
            this.disableSubmit = false;
            return;
        }
        updateWorkOrdersAgent({
            workOrderList: this.selectedRecords,
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
                    this.showToastMessage('Success', 'Work order approved successfully', 'success');
                    this.handleCancel();
                } else {
                    this.showToastMessage('Error', 'Error while approving work order', 'error');
                }
                this.spinner = false;
                this.disableSubmit = false;
            })
            .catch(error => {
                this.spinner = false;
                this.disableSubmit = false;
                this.showToastMessage('Error', 'Unexpected error occurred', 'error');
                console.error('Error updating work order: ' + JSON.stringify(error));
            });
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