import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getAllAgencies from '@salesforce/apex/AS_AgencyAssignmentController.getAllAgencies';
import getAllAgents from '@salesforce/apex/AS_AgencyAssignmentController.getAllAgents';
import getAgentsByAgency from '@salesforce/apex/AS_AgencyAssignmentController.getAgentsByAgency';
import getAgenciesByAgent from '@salesforce/apex/AS_AgencyAssignmentController.getAgenciesByAgent';
import getWorkTypes from '@salesforce/apex/AS_AgencyAssignmentController.getWorkTypes';
import getFilteredWorkOrders from '@salesforce/apex/AS_AgencyAssignmentController.getFilteredWorkOrders';
import assignAgency from '@salesforce/apex/AS_AgencyAssignmentController.assignAgency';
import getSettings from '@salesforce/apex/AS_AgencyAssignmentController.getSettings';
import withdrawAllocations from '@salesforce/apex/AS_AgencyAssignmentController.withdrawAllocations';
import getGroupMasterOptions from '@salesforce/apex/MeteringWorkOrderListViewController.getGroupMasterOptions';
import getGroupMessageOptions from '@salesforce/apex/MeteringWorkOrderListViewController.getGroupMessageOptions';
import getGroupCodeOptions from '@salesforce/apex/MeteringWorkOrderListViewController.getGroupCodeOptions';




// Changes by Aliyaj
import dataTableColumns from "@salesforce/label/c.Data_Table_Columns";

export default class AsWorkOrderAssignment extends LightningElement {
    // Filters
    @track invoiceFrom;
    @track invoiceTo;
    @track fromHour;
    @track fromMin;
    @track toHour;
    @track toMin;
    @track meterNumber;
    @track bpNumber;
    @track caNumber;
    @track installationNumber;
    @track status;
    @track pinCode;
    @track selectedAgencyFilter;
    @track deviceNo;
    @track groupBy;
    @track message;
    @track mrNote
    @track portion
    @track activityType;
    @track selectedAgentFilter;
    @track allWorkOrders;

    // lists
    @track agencies = [];
    @track agents = [];
    @track workTypes = [];

    // datatable / pagination
    @track workOrders = [];
    @track pagedData = [];
    @track pageSize = 10;
    @track pageNumber = 1;
    @track totalSize = 0;
    @track totalPages = 1;
    @track isLoading = false;
    @track selectedWorkOrderIds = [];
    selectedCount = 0;

    // columns
    columns = [
        { label: 'Work Order Number', fieldName: 'WorkOrderNumber' },
        { label: 'Contract Account', fieldName: 'Customer_CA_Number__c' },
        { label: 'Business Partner', fieldName: 'Account_BP_Number__c'},
        { label: 'BP Name', fieldName: 'Account_Name' },
        { label: 'Area Captured', fieldName: 'Area__c' },
        { label: 'Field Executive Name', fieldName: 'Agent_Name_Formula__c' },
        { label: 'Field Executive Code', fieldName: 'Agent_ID__c' },
        { label: 'Agency Name', fieldName: 'Agency_Name_Formula__c', type: 'text' },
        { label: 'Agency Code', fieldName: 'R_T_Agency__r_Agency_Code__c', type: 'text' },
        {
            label: 'Image 1',
            fieldName: 'ImageUrl1__c',
            type: 'image',
            typeAttributes: {
                value: { fieldName: 'ImageUrl1__c' }
            }
        },
        {
            label: 'Image 2',
            fieldName: 'ImageUrl2__c',
            type: 'image',
            typeAttributes: {
                value: { fieldName: 'ImageUrl2__c' }
            }
        },
        {
            label: 'Image 3',
            fieldName: 'ImageUrl3__c',
            type: 'image',
            typeAttributes: {
                value: { fieldName: 'ImageUrl3__c' }
            }
        },
        {
            label: 'Image 4',
            fieldName: 'ImageUrl4__c',
            type: 'image',
            typeAttributes: {
                value: { fieldName: 'ImageUrl4__c' }
            }
        },
        { label: 'GEO Location Latitude', fieldName: 'Check_In_Location__latitude__s' },
        { label: 'GEO Location Longitude', fieldName: 'Check_In_Location__longitude__s' },
        { label: 'Actual Visit Date', fieldName: 'actualVisitDate' },
        { label: 'Actual Visit Time', fieldName: 'actualVisitTime' },
        { label: 'Address', fieldName: 'Address' },
        { label: 'Date of First Attempt', fieldName: 'firstAttemptDate' },
        { label: 'Time of First Attempt', fieldName: 'firstAttemptTime' },
        { label: 'Date of Second Attempt', fieldName: 'secondAttemptDate' },
        { label: 'Time of Second Attempt', fieldName: 'secondAttemptTime' },
        { label: 'PreviousVisit Date', fieldName: 'previousVisitDate' },
        { label: 'Previous Visit Time', fieldName: 'previousVisitTime' },
        { label: 'Category of Activity', fieldName: 'WorkType_Name' },
        { label: 'Bill Date', fieldName: 'Bill_Date__c' },
        { label: 'Despatch Date', fieldName: 'despatchDate' },
        { label: 'Due Date', fieldName: 'Due_Date'},
        { label: 'Bill value', fieldName: 'Due_Amount__c' },
        { label: 'Outstanding Amount', fieldName: 'Outstanding_Amount__c' },
        { label: 'Payment Amount', fieldName: 'Amount_Received__c' },
        { label: 'Receipt Date', fieldName: 'Payment_Date__c' },
        { label: 'Cheque Number', fieldName: 'chequeNumber'},
        { label: 'Cheque Date', fieldName: 'chequeDate'},
        { label: 'Source of Payment', fieldName: 'Payment_Type__c' },
        { label: 'TEL NO', fieldName: 'Phone__c' },
        { label: 'Mobile No', fieldName: 'Old_Mobile_Number__c' },
        { label: 'Email', fieldName: 'Email_ID__c' },
        { label: 'Portion', fieldName: 'Billing_portion__c' },
        { label: 'MRU', fieldName: 'MRU__c' },
        { label: 'Meter No', fieldName: 'Meter_No_SR__c' },
        { label: 'Invoice No', fieldName: 'Invoice__c', type: 'text' },
        { label: 'Updated Mobile No', fieldName: 'New_Mobile_Number__c', type: 'text' },
        { label: 'Updated Email Id', fieldName: 'New_Email__c', type: 'text' },
        { label: 'Mode of Payment', fieldName: 'Payment_Mode__c' },
        { label: 'Allocation Start date', fieldName: 'AllocationStartDate' },
        { label: 'Allocation End Date', fieldName: 'AllocationEndDate' },
        { label: 'Disconnection Status', fieldName: 'DisconnectionStatus' },
        { label: 'No of Attempts', fieldName: 'Attempt_Count__c' },
        { label: 'Remarks Code', fieldName: 'RemarksCode' },
        { label: 'Remarks', fieldName: 'Remarks__c' },
        { label: 'Reallocation Date', fieldName: 'Follow_up_Date__c' },
        { label: 'Reallocation Period', fieldName: 'ReallocationPeriod' },
        { label: 'Bank Name', fieldName: 'bankName' },
        { label: 'GA', fieldName: 'GA_Wise__c' },

        //Child columns
        // {
        //     label: 'Payments',
        //     fieldName: 'Payment__c',
        //     type: 'child',
        //     typeAttributes: {
        //         value: { fieldName: 'Payments__r' },
        //         fieldLabel: 'Payments',
        //         apiName:'Payment__c'
        //     }
        // },
        // {
        //     label: 'Service Appointments',
        //     fieldName: 'ServiceAppointment',
        //     type: 'child',
        //     typeAttributes: {
        //         value: { fieldName: 'ServiceAppointments' },
        //         fieldLabel: 'Service Appointments',
        //         apiName:'ServiceAppointment'
        //     }
        // }  

    ];

    allColumns = [];
    selectedOption = [];
    columnOptions = [];
    settings;

    get tableContainerHeight() {
        return  'height:40vh;';
    }


    groupMasterOptions = [];
    init() {
        this.getGroupMasterOptionsFunc();
    }

    getGroupMasterOptionsFunc() {
        getGroupMasterOptions()
            .then(result => {
                this.groupMasterOptions = result;
                console.log('Options:',this.groupMasterOptions)
            })
            .catch(error => {
                console.error('Error fetching Group Master options:', error);
            });
    }

    groupMasterValue;
    handleGroupMasterChange(event) {
        this.handleFilterChange(event)
        this.groupMasterValue = event.detail.value;
        this.getGroupCodeOptionFunc();
    }

    groupCodeOptions = [];
    getGroupCodeOptionFunc() {
        if (this.groupMasterValue) {
            getGroupCodeOptions({ groupMasterId: this.groupMasterValue })
            .then(result => {
                this.groupCodeOptions = result;
            })
            .catch(error => {
                console.error('Error fetching Group Code options:', error);
            });
        }
    }

    groupCodeValue;
    handleGroupCodeChange(event) {
        this.handleFilterChange(event)
        this.groupCodeValue = event.detail.value;
        this.getGroupMessageOptionsFunc();
    }

    groupMessageOptions = [];
    getGroupMessageOptionsFunc() {
        if (this.groupCodeValue) {
            getGroupMessageOptions({ groupCodeId: this.groupCodeValue })
                .then(result => {
                    this.groupMessageOptions = result;
                })
                .catch(error => {
                    console.error('Error fetching Group Message options:', error);
                });
        }
    }

    groupMessageValue;
    handleGroupMessageChange(event) {
        this.handleFilterChange(event)
        this.groupMessageValue = event.detail.value;
    }

    

    handleColumns(event) {
        const selected = event.detail.value || [];
        console.log("selected:", selected);

        // Step 1: REMOVE columns not selected
        let newColumns = this.columns.filter(col =>
            selected.includes(col.fieldName)
        );

        // Step 2: ADD missing columns from settings (allColumns)
        selected.forEach(fieldName => {
            const alreadyExists = newColumns.some(c => c.fieldName === fieldName);

            if (!alreadyExists) {
                const settingColumn = this.allColumns.find(c => c.fieldName === fieldName);
                if (settingColumn) {
                    newColumns.push(settingColumn);
                }
            }
        });

        // Step 3: Optional — sort in the same order as allColumns
        newColumns = newColumns.sort(
            (a, b) =>
                this.allColumns.findIndex(c => c.fieldName === a.fieldName) -
                this.allColumns.findIndex(c => c.fieldName === b.fieldName)
        );

        this.columns = newColumns;
    }

    fetchSettings() {
        getSettings()
        .then(result => {
            this.settings = result|| [];

            // All possible columns (full definition for datatable)
            this.allColumns = this.columns.map(col => ({ ...col }));

            this.columnOptions = this.allColumns.map(col => ({
                label: col.label,
                value: col.fieldName,
            }));


            this.selectedOption = this.allColumns
 //               .filter(col => this.settings.some(s => s.value === col.fieldName))
                .map(col => col.label);

            this.columns = this.allColumns
            // .filter(col =>
            //     this.settings.some(s => s.value === col.fieldName)
            // );

        })
        .catch(error => {
            console.error('Error:', JSON.stringify(error));
        });
    }
    

    setColMaxWidth(){
        const WIDTH = 200;
        this.columns = this.columns.map(col => ({
            ...col,
            initialWidth: col.initialWidth ?? WIDTH
        }));
    }


    @track isModalOpen = false;
    handleImageClick(event) {
        this.selectedImage = event.detail.value;
        this.isModalOpen = true;        
    }

    handleCloseModal() {
        this.isModalOpen = false;
        this.selectedImage = null;
    }

    connectedCallback() {
        this.fetchSettings();
        this.loadInitialPicklists();
        this.loadWorkOrders();
        this.setColMaxWidth();
        this.init();
    }

    // assign panel values
    @track selectedAgencyForAssign;
    @track selectedAgentForAssign;
    @track selectedWorkTypeForAssign;
    @track startDateForAssign;
    @track endDateForAssign;

    // assign lists for assignment panel (mutual filtering)
    @track agentOptionsForAssign = [];
    @track agencyOptions = [];
    @track agentOptions = []; // for filters area
    @track workTypeOptions = [];

    statusOptions = [
        {label: 'Unattempted', value: 'Unattempted'},
        {label: 'Completed', value: 'Completed'},
        {label: 'Incomplete', value: 'Incomplete'},
        {label: 'In Progress', value: 'In Progress'}
    ];

    // loading/assigning flags
    @track isAssignLoading = false;

    // @track pageNumber = 1;
    // @track totalPages = 1;

    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber === this.totalPages;
    }

    get isPrevDisabled() {
        return this.isLoading || this.pageNumber <= 1;
    }

    get isNextDisabled() {
        return this.isLoading || this.pageNumber >= this.totalPages || this.totalPages === 0;
    }


    handlePrevPage() {
        if (this.isLoading) return;        
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.loadWorkOrders();
        }
    }

    handleNextPage() {
        if (this.isLoading) return;    
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.loadWorkOrders();
        }
    }

    // --------- initial data
    loadInitialPicklists() {
        getAllAgencies()
        .then(data => {
            this.agencies = data;
            this.agencyOptions = data.map(a => ({ label: a.Name, value: a.Id }));
        })
        .catch(err => console.error(err));

        getAllAgents()
        .then(data => {
            this.agents = data;
            this.agentOptions = data.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }));
        })
        .catch(err => console.error(err));

        getWorkTypes()
        .then(data => {
            this.workTypes = data;
            this.workTypeOptions = data.map(w => ({ label: w.Name, value: w.Id }));
        })
        .catch(err => console.error(err));
    }

    // --------- filters handlers

    hours = [...Array(24).keys()];    // 0 - 23
    minutes = [...Array(60).keys()]; // 0 - 59



    handleFilterChange(e) {
        const name = e.target.dataset.name;
        if (name === 'invoiceFrom') this.invoiceFrom = e.target.value;
        if (name === 'invoiceTo') this.invoiceTo = e.target.value;
        if (name === 'fromHour' ) this.fromHour = e.target.value;
        if (name === 'fromMin' ) this.fromMin = e.target.value;
        if (name === 'toHour' ) this.toHour = e.target.value;
        if (name === 'toMin' ) this.toMin = e.target.value;
        if (name === 'meterNumber') this.meterNumber = e.target.value;
        if (name === 'bpNumber') this.bpNumber = e.target.value;
        if (name === 'caNumber') this.caNumber = e.target.value;
        if (name === 'installationNumber') this.installationNumber = e.target.value;
        if (name === 'status') this.status = e.target.value;
        if (name === 'agency') {
            this.selectedAgencyFilter = e.target.value;
            // load agent options for that agency in filter area
            if (this.selectedAgencyFilter) {
                getAgentsByAgency({ agencyId: this.selectedAgencyFilter })
                    .then(res => {
                        this.agentOptions = res.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }));
                    })
                    .catch(err => console.error(err));
            } else {
                // reload full agents
                getAllAgents().then(res => this.agentOptions = res.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }))).catch(err=>console.error(err));
            }
        }
        if (name === 'deviceNo') this.deviceNo = e.target.value;
        if (name === 'portion') this.portion = e.target.value;
        if (name === 'activityType') this.activityType = e.target.value;
        if (name === 'agent') {
            this.selectedAgentFilter = e.target.value;
            // load agencies for filter if agent selected
            if (this.selectedAgentFilter) {
                getAgenciesByAgent({ agentServiceResourceId: this.selectedAgentFilter }).then(res => {
                    this.agencyOptions = res.map(a => ({ label: a.Name, value: a.Id }));
                }).catch(err => console.error(err));
            } else {
                getAllAgencies().then(res => this.agencyOptions = res.map(a => ({ label: a.Name, value: a.Id }))).catch(err => console.error(err));
            }
        }

        if (name === 'groupBy') this.groupBy = e.target.value;
        if (name === 'mrNote') this.mrNote = e.target.value;
        if (name === 'message') this.message = e.target.value;
    }

    applyFilters() {
        this.pageNumber = 1;
        this.loadWorkOrders();
    }

    clearFilters() {
        this.invoiceFrom = null;
        this.invoiceTo = null;
        this.fromHour = null;
        this.fromMin = null;
        this.toHour = null;
        this.toMin = null;
         this.template.querySelectorAll('select').forEach(select => {
            select.value = '';
        });
        this.meterNumber = null;
        this.bpNumber = null;
        this.caNumber = null;
        this.installationNumber = null;
        this.status = null;
        this.pinCode = null;
        this.selectedAgencyFilter = null;
        this.deviceNo = null;
        this.groupBy = null;
        this.groupMasterValue = null;
        this.mrNote = null;
        this.groupCodeValue = null;
        this.message = null;
        this.groupMessageValue = null;
        this.groupCodeOptions = null;
        this.groupMessageOptions = null;
        this.portion = null;
        this.activityType = null;
        this.selectedAgentFilter = null;
        // reload picklists
        this.loadInitialPicklists();
        this.pageNumber = 1;
        this.loadWorkOrders();
    }

    // --------- load paged workorders
    loadWorkOrders() {
        this.isLoading = true;
        getFilteredWorkOrders({
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            invoiceFrom: this.invoiceFrom?.split('T')[0],
            invoiceTo: this.invoiceTo?.split('T')[0],
            fromHour: this.fromHour,
            fromMin: this.fromMin,
            toHour: this.toHour,
            toMin: this.toMin,
            meterNumber : this.meterNumber,
            bpNumber : this.bpNumber,
            caNumber : this.caNumber,
            installationNumber:this.installationNumber,
            status: this.status,
            status: this.status,
            pinCode: this.pinCode,
            agencyId: this.selectedAgencyFilter,
            deviceNo:this.deviceNo,
            groupBy:this.groupBy,
            mrNote:this.mrNote,
            message:this.message,
            portion:this.portion,
            agentServiceResourceId: this.selectedAgentFilter,
            activityType: this.activityType
        })
        .then(result => {
            console.log('=======WO=======>', result);

            this.workOrders = result.records.map(row => {

                const saList = row.ServiceAppointments || [];

                let actualVisitDate = '-';
                let actualVisitTime = '-';

                if (row.Check_In_Date_Time__c) {
                    const actualDt = new Date(row.Check_In_Date_Time__c);

                    actualVisitDate = actualDt.toLocaleDateString('en-IN');
                    actualVisitTime = actualDt.toLocaleTimeString('en-IN', {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    });
                }

                

                let firstAttemptDate = '-';
                let firstAttemptTime = '-';
                let secondAttemptDate = '-';
                let secondAttemptTime = '-';

                let previousVisitDate = '-';
                let previousVisitTime = '-';

                if (saList.length >= 1 && saList[0].Check_In_Timestamp__c) {
                    const dt1 = new Date(saList[0].Check_In_Timestamp__c);
                    firstAttemptDate = dt1.toLocaleDateString('en-IN');
                    firstAttemptTime = dt1.toLocaleTimeString('en-IN', {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    });

                    // default previous = first attempt
                    previousVisitDate = firstAttemptDate;
                    previousVisitTime = firstAttemptTime;
                }

                if (saList.length >= 2 && saList[1].Check_In_Timestamp__c) {
                    const dt2 = new Date(saList[1].Check_In_Timestamp__c);
                    secondAttemptDate = dt2.toLocaleDateString('en-IN');
                    secondAttemptTime = dt2.toLocaleTimeString('en-IN', {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    });

                    // overwrite previous = second attempt
                    previousVisitDate = secondAttemptDate;
                    previousVisitTime = secondAttemptTime;
                }

                const paymentsList = row.Payments__r || [];

                let chequeNumber = '-';
                let chequeDate = '-';
                let bankName = '-';

                if (paymentsList.length === 1) {
                    const payment = paymentsList[0];

                    chequeNumber = payment.Cheque_Number__c || '';
                    bankName = payment.Bank_Name__c || '';

                    if (payment.Cheque_Date__c) {
                        const chequeDt = new Date(payment.Cheque_Date__c);
                        chequeDate = chequeDt.toLocaleDateString('en-IN');
                    }
                }

                return {
                    ...row,
                    Account_BP_Number__c: row.Account?.BP_Number__c || '-',
                    WorkType_Name: row.WorkType?.Name || '—',
                    Account_Name: row.Account?.Name || '-',
                    R_T_Agency__r_Agency_Code__c: row.R_T_Agency__r?.Agency_Code__c || '-',
                    Due_Date: row.EndDate ? new Date(row.EndDate).toLocaleDateString('en-IN') : '-',
                    AllocationStartDate: row.StartDate ? new Date(row.StartDate).toLocaleDateString('en-IN') : '-',
                    AllocationEndDate: row.EndDate ? new Date(row.EndDate).toLocaleDateString('en-IN') : '-',

                    actualVisitDate,
                    actualVisitTime,

                    // Attempts
                    firstAttemptDate,
                    firstAttemptTime,
                    secondAttemptDate,
                    secondAttemptTime,

                    // ✅ Previous Visit
                    previousVisitDate,
                    previousVisitTime,

                    chequeNumber,
                    bankName,
                    chequeDate,

                    Payments__r: row.Payments__r || [],
                    ServiceAppointments: saList
                };
            });

            this.totalSize = result.totalSize || 0;
            this.totalPages = Math.ceil(this.totalSize / this.pageSize) || 1;
            this.pagedData = this.workOrders;
            this.selectedWorkOrderIds = [];
        })
        .catch(error => {
            console.error('Failed to load workorders', error);
            this.showToast('Error', 'Failed to load workorders', 'error');
        })
        .finally(() => this.isLoading = false);
    }

    // --------- Load all workorders without pagination for CSV/Excel export
    async loadAllWorkOrders() {
        try {
            const result = await getFilteredWorkOrders({
                pageSize: this.totalSize,
                pageNumber: 1,
                invoiceFrom: this.invoiceFrom?.split('T')[0],
                invoiceTo: this.invoiceTo?.split('T')[0],
                fromHour: this.fromHour,
                fromMin: this.fromMin,
                toHour: this.toHour,
                toMin: this.toMin,
                meterNumber: this.meterNumber,
                bpNumber: this.bpNumber,
                caNumber: this.caNumber,
                installationNumber: this.installationNumber,
                status: this.status,
                pinCode: this.pinCode,
                agencyId: this.selectedAgencyFilter,
                deviceNo: this.deviceNo,
                groupBy: this.groupBy,
                mrNote: this.mrNote,
                message: this.message,
                portion: this.portion,
                agentServiceResourceId: this.selectedAgentFilter,
                activityType: this.activityType
            });

            this.allWorkOrders = result.records.map(row => {

                /* ---------------- Service Appointments ---------------- */
                const saList = row.ServiceAppointments || [];

                let firstAttemptDate = '';
                let firstAttemptTime = '';
                let secondAttemptDate = '';
                let secondAttemptTime = '';
                let previousVisitDate = '';
                let previousVisitTime = '';

                if (saList.length >= 1 && saList[0].Check_In_Timestamp__c) {
                    const dt1 = new Date(saList[0].Check_In_Timestamp__c);
                    firstAttemptDate = dt1.toLocaleDateString('en-IN');
                    firstAttemptTime = dt1.toLocaleTimeString('en-IN', {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    });

                    previousVisitDate = firstAttemptDate;
                    previousVisitTime = firstAttemptTime;
                }

                if (saList.length >= 2 && saList[1].Check_In_Timestamp__c) {
                    const dt2 = new Date(saList[1].Check_In_Timestamp__c);
                    secondAttemptDate = dt2.toLocaleDateString('en-IN');
                    secondAttemptTime = dt2.toLocaleTimeString('en-IN', {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    });

                    previousVisitDate = secondAttemptDate;
                    previousVisitTime = secondAttemptTime;
                }

                /* ---------------- Actual Visit ---------------- */
                let actualVisitDate = '';
                let actualVisitTime = '';

                if (row.Check_In_Date_Time__c) {
                    const actualDt = new Date(row.Check_In_Date_Time__c);
                    actualVisitDate = actualDt.toLocaleDateString('en-IN');
                    actualVisitTime = actualDt.toLocaleTimeString('en-IN', {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    });
                }

                /* ---------------- Payments ---------------- */
                const paymentsList = row.Payments__r || [];

                let chequeNumber = '';
                let chequeDate = '';
                let bankName = '';

                if (paymentsList.length === 1) {
                    const payment = paymentsList[0];
                    chequeNumber = payment.Cheque_Number__c || '';
                    bankName = payment.Bank_Name__c || '';

                    if (payment.Cheque_Date__c) {
                        chequeDate = new Date(payment.Cheque_Date__c)
                            .toLocaleDateString('en-IN');
                    }
                }

                /* ---------------- Return flattened row ---------------- */
                return {
                    ...row,
                    Account_BP_Number__c: row.Account?.BP_Number__c || '-',
                    WorkType_Name: row.WorkType?.Name || '—',
                    Account_Name: row.Account?.Name || '-',
                    R_T_Agency__r_Agency_Code__c: row.R_T_Agency__r?.Agency_Code__c || '-',
                    Due_Date: row.EndDate ? new Date(row.EndDate).toLocaleDateString('en-IN') : '-',

                    actualVisitDate,
                    actualVisitTime,

                    firstAttemptDate,
                    firstAttemptTime,
                    secondAttemptDate,
                    secondAttemptTime,
                    previousVisitDate,
                    previousVisitTime,

                    chequeNumber,
                    chequeDate,
                    bankName
                };
            });

            return this.allWorkOrders;

        } catch (error) {
            console.error('Failed to load workorders', error);
            this.showToast('Error', 'Failed to load workorders', 'error');
            throw error;
        }
    }



    // row selection
    handleRowSelection(event) {
         const selectedRows = event.detail.selectedRows;
         this.selectedWorkOrderIds = selectedRows.map(r => r.Id);
         this.selectedCount = selectedRows.length;        
    }

    // --------- Assignment panel - mutual filtering & handlers
    handleAgencyAssignChange(e) {
        this.selectedAgencyForAssign = e.detail.value;

        console.log('===========this.selectedAgencyForAssign==========>', JSON.stringify(this.selectedAgencyForAssign));

        //fetch agents for this agency to show in assign agent dropdown
        if (this.selectedAgencyForAssign) {
            getAgentsByAgency({ agencyId: this.selectedAgencyForAssign })
                .then(res => {
                    this.agentOptionsForAssign = res.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }));
                    // If currently selected agent is not in list, clear it
                    const ids = this.agentOptionsForAssign.map(x => x.value);
                    if (!ids.includes(this.selectedAgentForAssign)) this.selectedAgentForAssign = null;
                })
                .catch(err => console.error(err));
        } else {
            // reload all agents
            getAllAgents().then(res => this.agentOptionsForAssign = res.map(a => ({ label: a.ServiceResource.RelatedRecord.Name, value: a.ServiceResourceId }))).catch(err=>console.error(err));
        }
    }

    handleAgentAssignChange(e) {
        this.selectedAgentForAssign = e.detail.value;
        // fetch agencies for selected agent
        if (this.selectedAgentForAssign) {
            getAgenciesByAgent({ agentServiceResourceId: this.selectedAgentForAssign })
                .then(res => {
                    this.agencyOptions = res.map(a => ({ label: a.Name, value: a.Id }));

                    console.log('===========this.agencyOptions==========>', JSON.stringify(this.agencyOptions));
                    if(this.agencyOptions){
                        this.selectedAgencyForAssign = this.agencyOptions[0].value;
                    }

                    // If currently selected agency is not in list, clear it
                    const ids = this.agencyOptions.map(x => x.value);
                    if (!ids.includes(this.selectedAgencyForAssign)) this.selectedAgencyForAssign = null;
                })
                .catch(err => console.error(err));
        } else {
            getAllAgencies().then(res => this.agencyOptions = res.map(a => ({ label: a.Name, value: a.Id }))).catch(err=>console.error(err));
        }
    }

    handleWorkTypeChange(e) {
        this.selectedWorkTypeForAssign = e.detail.value;
    }
    handleStartDateChange(e) {
        this.startDateForAssign = e.target.value;
    }
    handleEndDateChange(e) {
        this.endDateForAssign = e.target.value;
    }

    // reset assign panel
    handleResetAssign() {
        this.selectedAgencyForAssign = null;
        this.selectedAgentForAssign = null;
        this.selectedWorkTypeForAssign = null;
        this.startDateForAssign = null;
        this.endDateForAssign = null;
        this.loadInitialPicklists();
    }

    // assign button state
    // get isAssignDisabled() {
    //     const allFields = this.selectedAgencyForAssign && this.selectedAgentForAssign && this.selectedWorkTypeForAssign && this.startDateForAssign && this.endDateForAssign && (this.selectedWorkOrderIds && this.selectedWorkOrderIds.length > 0);
    //     if (!allFields) return true;
    //     // check date validity
    //     // startDateForAssign and endDateForAssign are strings 'YYYY-MM-DD'
    //     return (this.startDateForAssign > this.endDateForAssign);
    // }
    get isAssignDisabled() {
        const allFieldsFilled = this.selectedAgencyForAssign 
            && this.selectedAgentForAssign 
            // && this.selectedWorkTypeForAssign 
            && this.startDateForAssign 
            && this.endDateForAssign 
            && (this.selectedWorkOrderIds && this.selectedWorkOrderIds.length > 0);            

        if (!allFieldsFilled) return true;

        return new Date(this.startDateForAssign) > new Date(this.endDateForAssign);
    }


    // assign action
    handleAssign() {
        if (this.isAssignDisabled) {
            if (this.startDateForAssign && this.endDateForAssign && this.startDateForAssign > this.endDateForAssign) {
                this.showToast('Error', 'End Date cannot be earlier than Start Date', 'error');
            } else {
                this.showToast('Error', 'Please fill all required fields and select Work Orders.', 'error');
            }
            return;
        }

        console.log('=======this.selectedWorkOrderIds=======>', JSON.stringify(this.selectedWorkOrderIds) );
        console.log('=======this.selectedAgencyForAssign=======>', JSON.stringify(this.selectedAgencyForAssign) );
        console.log('=======this.selectedAgentForAssign=======>', JSON.stringify(this.selectedAgentForAssign) );
        console.log('=======this.selectedWorkTypeForAssign=======>', JSON.stringify(this.selectedWorkTypeForAssign) );
        console.log('=======this.startDateForAssign=======>', JSON.stringify(this.startDateForAssign) );
        console.log('=======this.endDateForAssign=======>', JSON.stringify(this.endDateForAssign) );

        this.isAssignLoading = true;
        //Call Apex
        assignAgency({
            workOrderIds: this.selectedWorkOrderIds,
            agencyId: this.selectedAgencyForAssign,
            agentId: this.selectedAgentForAssign,
            workTypeId: this.selectedWorkTypeForAssign,
            startDate: this.startDateForAssign,
            endDate: this.endDateForAssign
        })
        .then(()=> {
            this.showToast('Success', 'Assigned successfully', 'success');
            // reload table (page)
            this.loadWorkOrders();
            // reset assign panel if desired
            // this.handleResetAssign();
        })
        .catch(error => {
            console.error('Assign failed', error);
            const msg = (error?.body?.message) ? error.body.message : 'Assignment failed';
            this.showToast('Error', msg, 'error');
        })
        .finally(()=> {
            this.isAssignLoading = false;
        });
    }

    // utilities
    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }

    // helper to compute pagedData if needed (server already returns paged, but keep for safety)
    // get pagedData() {
    //     return this.workOrders;
    // }

    // computed totalPages
    // get totalPages() {
    //     return Math.max(1, Math.ceil((this.totalSize || 0) / this.pageSize));
    // }



// Method to export filtered work orders as CSV file

    async exportWorkOrdersAsCSV() {
        try {
            console.log('🔵 CSV Export started');
            
            // ✅ Get FILTERED records
            const records = await this.loadAllWorkOrders();
            const recordsToExport = JSON.parse(JSON.stringify(records));
            console.log('🔵 Total filtered records to export:', recordsToExport.length);
            
            if (recordsToExport.length === 0) {
                this.showToast('Warning', 'No records to export', 'warning');
                return;
            }
            
            // Build CSV Header
            const headers = this.columns
            .filter(col => col.type !== 'child')
            .map(col => col.label);

            const headerRow = headers.map(h => this.escapeCSV(h)).join(',');
            
            console.log('🔵 CSV Headers:', headerRow);
            
            // Build CSV Rows
            const csvRows = [headerRow];
            
            for (const record of recordsToExport) {
                const row = [];
                
                for (const col of this.columns) {

                    if (col.type === 'child') {
                        continue;
                    }

                    let cellValue = record[col.fieldName] ?? '';
                    
                    // ✅ Handle image columns
                    if (col.type === 'image') {
                        cellValue = cellValue ;
                    }
                    
                    // ✅ Format the value for CSV
                    cellValue = this.formatCSVValue(cellValue);
                    row.push(this.escapeCSV(cellValue));
                }
                
                csvRows.push(row.join(','));
            }

            // Combine all rows
            const csvContent = csvRows.join('\n');
            console.log('🔵 CSV content created, total rows:', csvRows.length);
            
            // Generate timestamp for filename
            const now = new Date();
            const year = now.getFullYear();
            const month = String(now.getMonth() + 1).padStart(2, '0');
            const day = String(now.getDate()).padStart(2, '0');
            const timestamp = `${year}-${month}-${day}`;
            
            //Create blob and download
            const blob = new Blob([csvContent], { type: 'text/plain' });
            const link = document.createElement('a');
            const url = URL.createObjectURL(blob);
            
            link.href = url;
            link.download = `WorkOrders_${timestamp}.csv`;
            link.style.visibility = 'hidden';
            
            document.body.appendChild(link);
            link.click();
            
            setTimeout(() => {
                document.body.removeChild(link);
                URL.revokeObjectURL(url);
            }, 100);
            
            console.log('🟢 CSV exported successfully');
            this.showToast('Success', `CSV exported successfully (${recordsToExport.length} records)`, 'success');

        }catch{
            console.error(`Error fetching images for column ${columnFieldName}:`, err);
        }
            
    }


/**
 * Helper methods for CSV export
 */
    // Format value for CSV export
    formatCSVValue(value) {
        if (value === null || value === undefined) {
            return '';
        }
        
        if (typeof value === 'object') {
            return JSON.stringify(value);
        }
        
        if (typeof value === 'string' && value.includes('<')) {
            return value.replace(/<[^>]*>/g, '');
        }
        
        return value;
    }

    // Escape special characters in CSV values
    escapeCSV(value) {
        if (value === null || value === undefined) {
            return '';
        }
        const stringValue = String(value); 
        if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
            return '"' + stringValue.replace(/"/g, '""') + '"';
        }
        return stringValue;
    }

// Method to export filtered work orders as Excel file
    async exportWorkOrdersAsExcel(){

        const records = await this.loadAllWorkOrders();
        const recordsToExport = JSON.parse(JSON.stringify(records));

        if (recordsToExport.length === 0) {
            this.showToast('Warning', 'No records to export', 'warning');
            return;
        }
        const recordsSnapshot = JSON.parse(JSON.stringify(recordsToExport));
        try {
            const excelColumns = this.columns.filter(col => col.type !== 'child');

            // ✅ STEP 2 — Build table HTML
            let doc = '<table>';
            doc += '<colgroup>';
            excelColumns.forEach(() => {
                doc += '<col style="width:120px"/>';
            });
            doc += '</colgroup>';

            doc += `<style>
                table, th, td {
                    border:1px solid black;
                    border-collapse:collapse;
                    text-align:center;
                    vertical-align:middle;
                }
                img {
                    object-fit:contain;
                }
            </style>`;

            doc += '<tr>';
            excelColumns.forEach(col => (doc += `<th>${col.label}</th>`));
            doc += '</tr>';

            // ✅ STEP 3 — Add Records
            for (const record of recordsSnapshot) {
                doc += '<tr>';

                for (const col of excelColumns) {
                    let cellValue = record[col.fieldName] ?? '';

                    // 🔹 Always treat as text
                    if (typeof cellValue === 'string') {
                        cellValue = this.extractImageUrl(cellValue);
                    }

                    doc += `<td>${cellValue}</td>`;
                }

                doc += '</tr>';
            }

            doc += '</table>';
            const element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
            const downloadElement = document.createElement('a');
            downloadElement.href = element;
            downloadElement.download = 'WorkOrders.xls';
            document.body.appendChild(downloadElement);
            downloadElement.click();
            document.body.removeChild(downloadElement);
            this.showToast('Success', 'Excel Generated successfully', 'success');

        } catch (error) {
            console.error('Export error:', error);
        }
    }

/**
 * Helper methods for Excel export
 */
    //Extract URL from Image field
    extractImageUrl(imgFieldValue) {
        if (!imgFieldValue) return '';
        const imgTagMatch = imgFieldValue.match(/<img[^>]*src="([^"]+)"[^>]*>/);
        let url = imgTagMatch ? imgTagMatch[1] : imgFieldValue;
        return url || '';
    }

    get disableWithdrawal() {
    return !this.selectedWorkOrderIds || this.selectedWorkOrderIds.length === 0;
}


    handleWithdrawal() {
        this.isLoading = true;
        withdrawAllocations({ workOrderIds: this.selectedWorkOrderIds })
        .then(() => {
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: "Allocation Withdrawn",
                    variant: 'success',
                })
            );

            this.handleResetAssign();
            this.clearFilters();
            this.selectedCount = 0;
            this.selectedWorkOrderIds = [];  
        })
        .catch((error) => {
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message || 'An unexpected error occurred',
                    variant: 'error',
                })
            );
        });
    }

}