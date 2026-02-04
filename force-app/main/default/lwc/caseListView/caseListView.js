import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCases from '@salesforce/apex/CaseListViewController.getCases';
import getListViewColumns from '@salesforce/apex/CaseListViewController.getListViewColumns';
import getPicklistValues from '@salesforce/apex/CaseListViewController.getPicklistValues';
import getDepartments from '@salesforce/apex/CaseListViewController.getDepartments';
import getAssignedToUsers from '@salesforce/apex/CaseListViewController.getAssignedToUsers';
import updateCases from '@salesforce/apex/CaseListViewController.updateCases';
import getPriorityOptions from '@salesforce/apex/CaseListViewController.getPriorityOptions';
import getOriginOptions from '@salesforce/apex/CaseListViewController.getOriginOptions';
import getCategoryOptions from '@salesforce/apex/CaseListViewController.getCategoryOptions';
import getStatusOptions from '@salesforce/apex/CaseListViewController.getStatusOptions';
import getCaseOwnerOptions from '@salesforce/apex/CaseListViewController.getCaseOwnerOptions';
import getUserProfileInfo from '@salesforce/apex/CaseListViewController.getUserProfileInfo';
import { NavigationMixin } from 'lightning/navigation';
import getJobStatus from '@salesforce/apex/CaseListViewController.getJobStatus';

export default class CaseListView extends NavigationMixin(LightningElement) {
    // Filters
    @track caseNumber = null;
    @track businessPartner = null;
    @track subject = null;
    @track departmentRespondedFrom = null;
    @track departmentRespondedTo = null;

    // Multi-select filters
    @track selectedDepartments = [];
    @track selectedCategories = [];
    @track selectedTypes = [];
    @track selectedSubTypes = [];
    @track selectedValues = [];
    @track selectedStatuses = [];
    @track selectedCaseOwners = [];
    @track selectedOrigins = [];
    @track selectedCaseSources = [];

    // Lists for filters
    @track departmentOptions = [];
    @track statusOptions = [];
    @track originOptions = [];
    @track categoryOptions = [];
    @track typeOptions = [];
    @track subTypeOptions = [];
    @track valueOptions = [];
    @track priorityOptions = [];
    @track caseSourceOptions = [];
    @track caseOwnerOptions = [];

    // Datatable
    @track cases = [];
    @track pagedData = [];
    @track pageSize = 100; // Default page size
    @track pageNumber = 1;
    @track totalSize = 0;
    @track totalPages = 1;
    @track isLoading = false;
    @track selectedCount = 0;
    @track columns = [];

    // Selection
    @track selectedCaseIds = [];
    @track pageSizeInput = ''; // Changed from selectNumberInput to pageSizeInput

    // Sidebar states
    @track showFilterSidebar = false;
    @track showAssignSidebar = false;

    // Assignment panel
    @track assignedTo;
    @track assignedToOptions = [];

    // Loading flags
    @track isAssignLoading = false;
    
    // Update form
    @track updateForm = {
        OwnerId: null,
        Status: null,
        Assigned_To__c: null,
        Department__c: null,
        Priority: null,
        Sub_Type__c: null,
        Origin: null,
        Category__c: null,
        Type__c: null,
        Comments: null,
        Outstanding_Payment_Cleared__c: false
    };

    @track selectedCaseNumber;
    @track selectedCaseOpenedDate;
    @track selectedCaseCreatedBy;
    @track selectedCaseDepartmentResponded;
    
    // Track current sort
    @track sortBy;
    @track sortDirection = 'asc';
    
    // Search
    @track searchKey = '';

    // User profile info
    @track userProfileInfo = {};

    // Department case counts - will track ALL cases across all pages
    @track departmentCaseCounts = [];
    
    // Track all cases loaded so far for department counts
    @track allCasesMap = new Map();

    connectedCallback() {
        this.loadUserProfileInfo();
    }
    
    loadUserProfileInfo() {
        getUserProfileInfo()
            .then(result => {
                this.userProfileInfo = result;
                
                // Load all options first, then apply profile filters
                Promise.all([
                    this.loadPicklistOptions(),
                    this.loadCaseOwnerOptions(),
                    this.loadAssignedToUsers()
                ]).then(() => {
                    this.applyProfileBasedFilters();
                    // Load cases after a short delay to ensure UI is ready
                    setTimeout(() => {
                        this.loadCases();
                    }, 500);
                });
            })
            .catch(error => {
                console.error('Error loading user profile:', error);
                // Load options even if profile fails
                Promise.all([
                    this.loadPicklistOptions(),
                    this.loadCaseOwnerOptions(),
                    this.loadAssignedToUsers()
                ]).then(() => {
                    this.loadCases();
                });
            });
    }

    // Load ALL cases for department counts (with large page size)
    loadAllCasesForDepartmentCounts() {
        const params = {
            pageSize: 10000, // Large number to get all matching cases
            pageNumber: 1,
            searchKey: this.searchKey || null,
            departmentRespondedFrom: this.departmentRespondedFrom || null,
            departmentRespondedTo: this.departmentRespondedTo || null,
            defaultFRL: this.userProfileInfo.defaultFRL || null
        };
        params.noCache = Date.now();
        // Apply all filters
        if (this.caseNumber) params.caseNumber = this.caseNumber;
        if (this.businessPartner) params.businessPartner = this.businessPartner;
        if (this.subject) params.subject = this.subject;

        if (this.selectedStatuses && this.selectedStatuses.length > 0) {
            params.status = JSON.stringify([...this.selectedStatuses]);
        }
        
        if (this.selectedOrigins && this.selectedOrigins.length > 0) {
            params.origin = JSON.stringify([...this.selectedOrigins]);
        }
        
        if (this.selectedCategories && this.selectedCategories.length > 0) {
            params.category = JSON.stringify([...this.selectedCategories]);
        }
        
        if (this.selectedTypes && this.selectedTypes.length > 0) {
            params.type = JSON.stringify([...this.selectedTypes]);
        }
        
        if (this.selectedSubTypes && this.selectedSubTypes.length > 0) {
            params.subType = JSON.stringify([...this.selectedSubTypes]);
        }
        
        if (this.selectedValues && this.selectedValues.length > 0) {
            params.value = JSON.stringify([...this.selectedValues]);
        }
        
        if (this.selectedCaseSources && this.selectedCaseSources.length > 0) {
            params.caseSource = JSON.stringify([...this.selectedCaseSources]);
        }
        
        if (this.selectedDepartments && this.selectedDepartments.length > 0) {
            params.department = JSON.stringify([...this.selectedDepartments]);
        }
        
        if (this.selectedCaseOwners && this.selectedCaseOwners.length > 0) {
            params.caseOwner = JSON.stringify([...this.selectedCaseOwners]);
        }

        getCases(params)
        .then(result => {
            const allCases = result.records || [];
            this.calculateDepartmentCountsFromAllData(allCases);
        })
        .catch(error => {
            console.error('Error loading all cases for department counts:', error);
            this.departmentCaseCounts = [];
        });
    }

    // Calculate department counts from ALL matching cases
    calculateDepartmentCountsFromAllData(allCases) {
        if (!allCases || allCases.length === 0) {
            this.departmentCaseCounts = [];
            return;
        }

        // Create a map to count cases per department across ALL data
        const departmentCountMap = new Map();
        
        allCases.forEach(caseRec => {
            const department = caseRec.Department__c || 'Unassigned';
            const currentCount = departmentCountMap.get(department) || 0;
            departmentCountMap.set(department, currentCount + 1);
        });

        // Convert map to array of objects
        this.departmentCaseCounts = Array.from(departmentCountMap.entries()).map(([departmentName, caseCount]) => ({
            departmentName,
            caseCount
        })).sort((a, b) => a.departmentName.localeCompare(b.departmentName));
    }

    // Computed property for total cases across all departments in ALL data
    get totalAllDepartmentCases() {
        if (!this.departmentCaseCounts || this.departmentCaseCounts.length === 0) {
            return 0;
        }
        return this.departmentCaseCounts.reduce((total, dept) => total + (dept.caseCount || 0), 0);
    }

    applyProfileBasedFilters() {
        // Apply default status for Call Center users
        if (this.userProfileInfo.isCallCenter && this.userProfileInfo.defaultStatus) {
            this.selectedStatuses = [...this.userProfileInfo.defaultStatus];
        }
        
        // FIXED: Apply CRM Queue ONLY for Call Center Team Leads
        const isTeamLead = this.userProfileInfo.isCallCenterTL || 
                          (this.userProfileInfo.profileName && 
                           this.userProfileInfo.profileName.toLowerCase().includes('teamlead'));
        
        if (isTeamLead) {
            this.selectedCaseOwners = ['CRM Queue'];
        }
        
        // Apply default origin for Back Office users
        if (this.userProfileInfo.defaultOrigin) {
            this.selectedOrigins = [...this.userProfileInfo.defaultOrigin];
        }
        
        // Force UI refresh
        this.refreshMultiSelectComponents();
    }

    @wire(getListViewColumns)
wiredColumns({ error, data }) {
    if (data) {
        const filteredColumns = data.filter(col => col.label !== 'Docket Number' && col.label !== 'Priority');
        this.columns = [
            {
                label: 'Case Number',
                type: 'button',
                typeAttributes: {
                    label: { fieldName: 'Docket_Number__c' },
                    name: 'view_case',
                    variant: 'base'
                },
                cellAttributes: {
                    alignment: 'left'
                }
            },
            ...filteredColumns.map(col => ({
                label: col.label,
                fieldName: col.fieldName,
                type: col.type,
                sortable: true
            })),
            {
                label: 'Case Source',
                fieldName: 'Case_Source__c',
                type: 'text',
                sortable: true
            },
            // ADD Department Responded On column
            {
                label: 'Department Responded On',
                fieldName: 'Department_Responded_On__c',
                type: 'date',
                sortable: true,
                typeAttributes: {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric'
                }
            },
            // ADD Outgoing Calls Count column
            {
                label: 'Outgoing Calls Count',
                fieldName: 'Outgoing_Calls_Count__c',
                type: 'number',
                sortable: true,
                cellAttributes: {
                    alignment: 'center'
                }
            }
        ];
    }
}
    loadPicklistOptions() {
        return new Promise((resolve) => {
            // Initialize all options with empty arrays first
            this.departmentOptions = [];
            this.statusOptions = [];
            this.originOptions = [];
            this.categoryOptions = [];
            this.typeOptions = [];
            this.subTypeOptions = [];
            this.valueOptions = [];
            this.priorityOptions = [];
            this.caseSourceOptions = [
                { label: 'Salesforce', value: 'Salesforce' },
                { label: 'SAP', value: 'SAP' }
            ];

            const promises = [];

            // Load departments
            promises.push(
                getDepartments()
                    .then(result => {
                        const uniqueDepartments = this.removeDuplicateOmSupport(result);
                        this.departmentOptions = uniqueDepartments.map(dept => ({
                            label: dept,
                            value: dept
                        }));
                    })
                    .catch(error => {
                        console.error('Error loading departments:', error);
                        this.departmentOptions = [];
                    })
            );

            // Load status options
            promises.push(
                getStatusOptions()
                    .then(result => {
                        this.statusOptions = result.map(option => ({
                            label: option.label,
                            value: option.value
                        }));
                    })
                    .catch(error => {
                        this.statusOptions = [];
                    })
            );

            // Load origin options
            promises.push(
                getOriginOptions()
                    .then(result => {
                        this.originOptions = result.map(option => ({
                            label: option.label,
                            value: option.value
                        }));
                    })
                    .catch(error => {
                        this.originOptions = [];
                    })
            );

            // Load category options
            promises.push(
                getCategoryOptions()
                    .then(result => {
                        this.categoryOptions = result
                            .filter(option => option.label !== 'Others' && option.label !== 'Query')
                            .map(option => ({
                                label: option.label,
                                value: option.value
                            }));
                    })
                    .catch(error => {
                        this.categoryOptions = [];
                    })
            );

            // Load priority options
            promises.push(
                getPriorityOptions()
                    .then(result => {
                        this.priorityOptions = result.map(option => ({
                            label: option.label,
                            value: option.value
                        }));
                    })
                    .catch(error => {
                        this.priorityOptions = [];
                    })
            );

            Promise.all(promises).then(() => resolve());
        });
    }

    loadCaseOwnerOptions() {
        return new Promise((resolve) => {
            getCaseOwnerOptions()
                .then(result => {
                    this.caseOwnerOptions = result.map(option => ({
                        label: option.label,
                        value: option.value
                    }));
                    
                    // After case owner options are loaded, ensure CRM Queue exists for Team Leads
                    const isTeamLead = this.userProfileInfo.isCallCenterTL || 
                                      (this.userProfileInfo.profileName && 
                                       this.userProfileInfo.profileName.toLowerCase().includes('teamlead'));
                    
                    if (isTeamLead) {
                        const crmQueueExists = this.caseOwnerOptions.some(option => 
                            option.value === 'CRM Queue' || option.label === 'CRM Queue'
                        );
                        
                        if (!crmQueueExists) {
                            // Add CRM Queue to options if it doesn't exist
                            this.caseOwnerOptions.unshift({
                                label: 'CRM Queue',
                                value: 'CRM Queue'
                            });
                        }
                    }
                    
                    resolve();
                })
                .catch(error => {
                    console.error('Error loading case owners:', error);
                    this.caseOwnerOptions = [];
                    resolve();
                });
        });
    }

    removeDuplicateOmSupport(departments) {
        const seen = new Set();
        const uniqueDepartments = [];
        let omSupportOnlineFound = false;

        departments.forEach(dept => {
            const normalized = dept.toLowerCase().replace(/\s+/g, ' ').trim();
            const isOmSupport = normalized.includes('o&m') && normalized.includes('support');
            
            if (isOmSupport) {
                if (!omSupportOnlineFound && (normalized.includes('online') || dept === 'O&M Support Online')) {
                    uniqueDepartments.push(dept);
                    seen.add(normalized);
                    omSupportOnlineFound = true;
                }
            } else {
                if (!seen.has(normalized)) {
                    seen.add(normalized);
                    uniqueDepartments.push(dept);
                }
            }
        });

        return uniqueDepartments.sort();
    }

    loadAssignedToUsers() {
        return new Promise((resolve) => {
            getAssignedToUsers()
                .then(result => {
                    this.assignedToOptions = result.map(user => ({
                        label: user.Name,
                        value: user.Id
                    }));
                    resolve();
                })
                .catch(error => {
                    this.assignedToOptions = [];
                    resolve();
                });
        });
    }

    initializeUpdateForm() {
        const defaultForm = {
            OwnerId: null,
            Status: null,
            Assigned_To__c: null,
            Department__c: null,
            Priority: null,
            Sub_Type__c: null,
            Origin: null,
            Category__c: null,
            Type__c: null,
            Comments: null,
            Outstanding_Payment_Cleared__c: false
        };

        // Auto-fill Status for Call Center users
        if (this.isCallCenterUser) {
            defaultForm.Status = 'Actioned by Department';
        }

        return defaultForm;
    }

    loadCases() {
        this.isLoading = true;
         if (this.pageSizeInput) {
        this.pageSize = parseInt(this.pageSizeInput, 10);
    }
        const params = {
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            searchKey: this.searchKey || null,
            departmentRespondedFrom: this.departmentRespondedFrom || null,
            departmentRespondedTo: this.departmentRespondedTo || null,
            defaultFRL: this.userProfileInfo.defaultFRL || null
        };
        params.noCache = Date.now();

        if (this.caseNumber) params.caseNumber = this.caseNumber;
        if (this.businessPartner) params.businessPartner = this.businessPartner;
        if (this.subject) params.subject = this.subject;

        // Handle multi-select filters
        if (this.selectedStatuses && this.selectedStatuses.length > 0) {
            params.status = JSON.stringify([...this.selectedStatuses]);
        } else {
            params.status = null;
        }
        
        if (this.selectedOrigins && this.selectedOrigins.length > 0) {
            params.origin = JSON.stringify([...this.selectedOrigins]);
        } else {
            params.origin = null;
        }
        
        if (this.selectedCategories && this.selectedCategories.length > 0) {
            params.category = JSON.stringify([...this.selectedCategories]);
        } else {
            params.category = null;
        }
        
        if (this.selectedTypes && this.selectedTypes.length > 0) {
            params.type = JSON.stringify([...this.selectedTypes]);
        } else {
            params.type = null;
        }
        
        if (this.selectedSubTypes && this.selectedSubTypes.length > 0) {
            params.subType = JSON.stringify([...this.selectedSubTypes]);
        } else {
            params.subType = null;
        }
        
        if (this.selectedValues && this.selectedValues.length > 0) {
            params.value = JSON.stringify([...this.selectedValues]);
        } else {
            params.value = null;
        }
        
        if (this.selectedCaseSources && this.selectedCaseSources.length > 0) {
            params.caseSource = JSON.stringify([...this.selectedCaseSources]);
        } else {
            params.caseSource = null;
        }
        
        if (this.selectedDepartments && this.selectedDepartments.length > 0) {
            params.department = JSON.stringify([...this.selectedDepartments]);
        } else {
            params.department = null;
        }
        
        // Handle Case Owner filter
        if (this.selectedCaseOwners && this.selectedCaseOwners.length > 0) {
            params.caseOwner = JSON.stringify([...this.selectedCaseOwners]);
        } else {
            params.caseOwner = null;
        }
// Load current page FIRST, THEN load department counts (no parallel calls)
this.loadCurrentPageData(params)
    .then(() => {
        return this.loadAllCasesForDepartmentCounts();
    })
    .then(() => {
        this.isLoading = false;
    })
    .catch(error => {
        console.error('Error loading data:', error);
        this.isLoading = false;
    });

    }

   loadCurrentPageData(params) {
    return getCases(params)
    .then(result => {
        this.cases = result.records || [];
        this.totalSize = result.totalSize;
        this.totalPages = Math.ceil(this.totalSize / this.pageSize) || 1;
        
        this.pagedData = this.cases.map(caseRec => {
            return {
                Id: caseRec.Id,
                Docket_Number__c: caseRec.Docket_Number__c,
                'Account.Name': caseRec.Account ? caseRec.Account.Name : '',
                Subject: caseRec.Subject,
                Status: caseRec.Status,
                Origin: caseRec.Origin,
                Category__c: caseRec.Category__c,
                Type__c: caseRec.Type__c,
                Sub_Type__c: caseRec.Sub_Type__c,
                Value_1__c: caseRec.Value_1__c,
                CRM_Assigned_date__c: caseRec.CRM_Assigned_date__c,
                CreatedDate: caseRec.CreatedDate,
                'Owner.Name': caseRec.Owner ? caseRec.Owner.Name : '',
                'Assigned_To__r.Name': caseRec.Assigned_To__r ? caseRec.Assigned_To__r.Name : '',
                Reopen_Count__c: caseRec.Reopen_Count__c,
                Department__c: caseRec.Department__c,
                Outstanding_Payment_Cleared__c: caseRec.Outstanding_Payment_Cleared__c || false,
                Comments: caseRec.Comments,
                'CreatedBy.Name': caseRec.CreatedBy ? caseRec.CreatedBy.Name : '',
                Case_Source__c: caseRec.Case_Source__c,
                FRL__c: caseRec.FRL__c || false,
                Department_Responded_On__c: caseRec.Department_Responded_On__c,
                Outgoing_Calls_Count__c: caseRec.Outgoing_Calls_Count__c,
                _originalCase: caseRec
            };
        });
        
        this.selectedCaseIds = [];
        this.selectedCount = 0;
    })
    .catch(error => {
        console.error('Error loading cases:', error);
        this.showToast('Error', 'Failed to load cases: ' + (error.body?.message || error.message), 'error');
        throw error;
    });
}

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        switch (action.name) {
            case 'view_case':
                this.navigateToCase(row.Id);
                break;
        }
    }

    navigateToCase(caseId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }

    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.pagedData));
        let keyValue = (a) => a[fieldname] || '';
        parseData.sort((a, b) => {
            let valA = keyValue(a);
            let valB = keyValue(b);
            let result = 0;
            if (valA > valB) result = 1;
            else if (valA < valB) result = -1;
            return direction === 'asc' ? result : -result;
        });
        this.pagedData = parseData;
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
        this.pageNumber = 1;
        this.loadCases();
    }

    // Method to handle page size input change
    handlePageSizeChange(event) {
        const inputValue = event.target.value;
        
        // Only allow numbers
        if (inputValue === '' || /^\d+$/.test(inputValue)) {
            this.pageSizeInput = inputValue;
            
            if (inputValue === '') {
                // If input is empty, reset to default page size
                this.pageSize = 100;
                this.pageNumber = 1;
                this.loadCases();
            } else {
                const newPageSize = parseInt(inputValue, 10);
                if (newPageSize > 0) {
                    this.pageSize = newPageSize;
                    this.pageNumber = 1;
                    this.loadCases();
                }
            }
        }
    }

    loadDependentPicklistValues() {
        if (!this.selectedDepartments || this.selectedDepartments.length === 0) {
            this.categoryOptions = [];
            this.typeOptions = [];
            this.subTypeOptions = [];
            this.valueOptions = [];
            return;
        }
        
        // Create arrays to collect all unique values
        const allCategories = new Set();
        const allTypes = new Set();
        const allSubTypes = new Set();
        const allValues = new Set();
        
        // Create promises for each department
        const promises = this.selectedDepartments.map(dept => {
            return getPicklistValues({
                department: dept,
                category: null,
                type: null
            })
            .then(result => {
                if (result && result.length > 0) {
                    result.forEach(item => {
                        if (item.Category__c) allCategories.add(item.Category__c);
                        if (item.Type__c) allTypes.add(item.Type__c);
                        if (item.Sub_Type__c) allSubTypes.add(item.Sub_Type__c);
                        if (item.Value_1__c) allValues.add(item.Value_1__c);
                    });
                }
            })
            .catch(error => {
                console.error(`Error loading picklists for department ${dept}:`, error);
            });
        });
        
        // Wait for all promises to complete
        Promise.all(promises)
        .then(() => {
            this.typeOptions = Array.from(allTypes)
                .sort()
                .map(type => ({ label: type, value: type }));
                
            this.subTypeOptions = Array.from(allSubTypes)
                .sort()
                .map(subType => ({ label: subType, value: subType }));
                
            this.valueOptions = Array.from(allValues)
                .sort()
                .map(value => ({ label: value, value: value }));
            
        })
        .catch(error => {
            console.error('Error loading combined picklists:', error);
            this.categoryOptions = [];
            this.typeOptions = [];
            this.subTypeOptions = [];
            this.valueOptions = [];
        });
    }

    handleMultiSelectChange(event) {
        const selectedValues = event.detail.selectedValues;
        const label = event.target.label;
        
        switch(label) {
            case 'Department':
                this.selectedDepartments = selectedValues;
                this.loadDependentPicklistValues();
                break;
            case 'Category':
                this.selectedCategories = selectedValues;
                break;
            case 'Type':
                this.selectedTypes = selectedValues;
                break;
            case 'Sub Type':
                this.selectedSubTypes = selectedValues;
                break;
            case 'Value':
                this.selectedValues = selectedValues;
                break;
            case 'Status':
                this.selectedStatuses = selectedValues;
                break;
            case 'Origin':
                this.selectedOrigins = selectedValues;
                break;
            case 'Case Source':
                this.selectedCaseSources = selectedValues;
                break;
            case 'Case Owner':
                this.selectedCaseOwners = selectedValues;
                break;
            default:
                // Do nothing
        }
    }

    applyFilters() {
        if (this.departmentRespondedFrom && this.departmentRespondedTo) {
            const from = new Date(this.departmentRespondedFrom);
            const to = new Date(this.departmentRespondedTo);
            
            if (from > to) {
                this.showToast('Error', 'From Date cannot be greater than To Date. Please correct the dates.', 'error');
                return;
            }
        }
        this.pageNumber = 1;
        this.loadCases();
        this.closeFilterSidebar();
    }

    clearFilters() {
        this.caseNumber = null;
        this.businessPartner = null;
        this.subject = null;
        this.selectedCategories = [];
        this.selectedTypes = [];
        this.selectedSubTypes = [];
        this.selectedValues = [];
        this.selectedCaseSources = [];
        this.selectedDepartments = [];
        this.selectedOrigins = [];
        this.searchKey = '';
        this.departmentRespondedFrom = null;
        this.departmentRespondedTo = null;
        
        // DO NOT clear Case Owner and Status - reapply defaults instead
        this.selectedCaseOwners = [];
        this.selectedStatuses = [];
        
        // Re-apply profile-based defaults after clearing
        this.applyProfileBasedFilters();
        
        // Clear multi-select dropdowns UI (except Case Owner and Status)
        const dropdowns = this.template.querySelectorAll('c-multi-select-combo-picklist');
        dropdowns.forEach(dropdown => {
            const label = dropdown.label;
            if (label !== 'Case Owner' && label !== 'Status') {
                dropdown.clearSelection();
            }
        });
        
        // Clear dependent picklist options
        this.categoryOptions = [];
        this.typeOptions = [];
        this.subTypeOptions = [];
        this.valueOptions = [];
        
        this.pageNumber = 1;
        this.loadCases();
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedCaseIds = selectedRows.map(r => r.Id);
        this.selectedCount = selectedRows.length;
    }

    handlePrevPage() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.loadCases();
        }
    }

    handleNextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.loadCases();
        }
    }

    get isPrevDisabled() {
        return this.isLoading || this.pageNumber <= 1;
    }

    get isNextDisabled() {
        return this.isLoading || this.pageNumber >= this.totalPages || this.totalPages === 0;
    }

    toggleFilterSidebar() {
        this.showFilterSidebar = !this.showFilterSidebar;
        if (this.showAssignSidebar) {
            this.showAssignSidebar = false;
        }
        
        // When opening the filter sidebar, ensure the multi-select components reflect current selections
        if (this.showFilterSidebar) {
            setTimeout(() => {
                this.refreshMultiSelectComponents();
            }, 300);
        }
    }

    closeFilterSidebar() {
        this.showFilterSidebar = false;
    }

    get filterSidebarClass() {
        const baseClass = 'cart-sidebar';
        const openClass = this.showFilterSidebar ? ' open' : '';
        return baseClass + openClass;
    }

    refreshMultiSelectComponents() {
        const multiSelects = this.template.querySelectorAll('c-multi-select-combo-picklist');
        
        multiSelects.forEach(component => {
            // Force update of selected values for each component
            if (component.label === 'Case Owner') {
                component.selectedValues = [...this.selectedCaseOwners];
            }
            if (component.label === 'Status') {
                component.selectedValues = [...this.selectedStatuses];
            }
            if (component.label === 'Origin') {
                component.selectedValues = [...this.selectedOrigins];
            }
        });
    }

    getSelectedValuesForLabel(label) {
        switch(label) {
            case 'Case Owner': return this.selectedCaseOwners;
            case 'Status': return this.selectedStatuses;
            case 'Origin': return this.selectedOrigins;
            case 'Department': return this.selectedDepartments;
            case 'Category': return this.selectedCategories;
            case 'Type': return this.selectedTypes;
            case 'Sub Type': return this.selectedSubTypes;
            case 'Value': return this.selectedValues;
            case 'Case Source': return this.selectedCaseSources;
            default: return [];
        }
    }

    toggleAssignSidebar() {
        if (this.selectedCaseIds.length === 0) {
            this.showToast('Error', 'Please select at least one case', 'error');
            return;
        }
        
        if (this.selectedCaseIds.length === 1) {
            const selectedCase = this.findSelectedCase();
            if (selectedCase) {
                this.openUpdateModal(selectedCase);
            } else {
                this.showToast('Error', 'Could not find selected case data', 'error');
            }
        } else {
            this.updateForm = this.initializeUpdateForm();
            this.checkSelectedCasesStatus();
            this.showAssignSidebar = true;
        }
        
        if (this.showFilterSidebar) {
            this.showFilterSidebar = false;
        }
    }

    checkSelectedCasesStatus() {
        if (this.selectedCaseIds.length <= 1) return;
        
        const selectedCases = this.cases.filter(caseRec => 
            this.selectedCaseIds.includes(caseRec.Id)
        );
        
        if (selectedCases.length === 0) return;
        
        const statuses = [...new Set(selectedCases.map(caseRec => caseRec.Status))];
        
        if (statuses.length === 1) {
            this.updateForm.Status = statuses[0];
        }
    }

    findSelectedCase() {
        if (this.selectedCaseIds.length !== 1) return null;
        
        const selectedId = this.selectedCaseIds[0];
        
        let foundCase = this.pagedData.find(caseRec => caseRec.Id === selectedId);
        if (foundCase && foundCase._originalCase) {
            return foundCase._originalCase;
        }
        
        foundCase = this.cases.find(caseRec => caseRec.Id === selectedId);
        return foundCase || null;
    }

    openUpdateModal(caseRecord) {
        this.selectedCaseNumber = caseRecord.Docket_Number__c;
        this.selectedCaseOpenedDate = this.formatDate(caseRecord.CreatedDate);
        this.selectedCaseCreatedBy = caseRecord.CreatedBy ? caseRecord.CreatedBy.Name : '';
        this.selectedCaseDepartmentResponded = this.formatDate(caseRecord.Department_Responded_On__c);

        this.updateForm = {
            OwnerId: caseRecord.OwnerId || null,
            Status: this.isCallCenterUser ? 'Actioned by Department' : (caseRecord.Status || null),
            Assigned_To__c: caseRecord.Assigned_To__c || null,
            Department__c: caseRecord.Department__c || null,
            Priority: caseRecord.Priority || null,
            Sub_Type__c: caseRecord.Sub_Type__c || null,
            Origin: caseRecord.Origin || null,
            Category__c: caseRecord.Category__c || null,
            Type__c: caseRecord.Type__c || null,
            Comments: caseRecord.Comments || null,
            Outstanding_Payment_Cleared__c: caseRecord.Outstanding_Payment_Cleared__c || false
        };

        this.showAssignSidebar = true;
    }

    closeAssignSidebar() {
        this.showAssignSidebar = false;
    }
    jobId;
    handleUpdateFieldChange(event) {
        const fieldName = event.target.dataset.name;
        const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        this.updateForm[fieldName] = value;
    }

    startPolling() {
        this.pollingInterval = setInterval(() => {
            console.log('Checking status for jobId → ' + this.jobId);

            getJobStatus({ jobId: this.jobId })
                .then(res => {
                    if (res && res.Status__c) {
                        
                        clearInterval(this.pollingInterval);
                        if (res.Status__c === 'Success') {
    this.showToast('Success', res.Message__c, 'success');
  setTimeout(() => {
    this.pageNumber = 1;
    this.loadCases();
if (this.pageSizeInput) {
    this.pageSize = parseInt(this.pageSizeInput, 10);
}

    this.loadAllCasesForDepartmentCounts();
}, 2000); 
    this.closeAssignSidebar();
    this.resetUpdatePanel();
    this.isAssignLoading = false;
} else {
    this.showToast('Error', res.Message__c, 'error');
    this.isAssignLoading = false;
}
                    }
                })
                .catch(error => {
                    console.error('Polling error: ', error);
                });

        }, 5000);
    }

    handleUpdateCase() {
    if (this.selectedCaseIds.length === 0) {
        this.showToast('Error', 'Please select at least one case', 'error');
        return;
    }

    if (!this.updateForm.Status) {
        this.showToast('Error', 'Status is required', 'error');
        return;
    }
    if (!this.updateForm.Comments) {
        this.showToast('Error', 'Case Comments are required', 'error');
        return;
    }
    
    this.isAssignLoading = true;
    
    updateCases({ 
        fieldValues: this.updateForm, 
        caseIds: this.selectedCaseIds 
    })
    .then(jobId => {
        this.jobId = jobId; // ✔ Store jobId 
        this.startPolling();
    
    })
    .catch(error => {
        console.error('Error updating cases:', error);
        this.showToast('Error', error.body?.message || 'Update failed. Please try again.', 'error');
        this.isAssignLoading = false;
    });
}

    resetUpdatePanel() {
        this.updateForm = this.initializeUpdateForm();
        this.selectedCaseNumber = null;
        this.selectedCaseOpenedDate = null;
        this.selectedCaseCreatedBy = null;
        this.selectedCaseDepartmentResponded = null;
    }

    handleDepartmentRespondedFromChange(event) {
        const fromDate = event.target.value;
        this.departmentRespondedFrom = fromDate;
        
        if (fromDate && this.departmentRespondedTo) {
            this.validateDateRange(fromDate, this.departmentRespondedTo);
        }
    }

    handleDepartmentRespondedToChange(event) {
        const toDate = event.target.value;
        this.departmentRespondedTo = toDate;
        
        if (this.departmentRespondedFrom && toDate) {
            this.validateDateRange(this.departmentRespondedFrom, toDate);
        }
    }

    validateDateRange(fromDate, toDate) {
        const from = new Date(fromDate);
        const to = new Date(toDate);
        
        if (from > to) {
            this.showToast('Error', 'From Date cannot be greater than To Date', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
    }

    get showNoCasesMessage() {
        return !this.isLoading && this.pagedData.length === 0;
    }

    get isCallCenterUser() {
        return this.userProfileInfo.isCallCenter || false;
    }

    get isCallCenterTL() {
        return this.userProfileInfo.isCallCenterTL || false;
    }

    get showStatusFilter() {
        const profileName = this.userProfileInfo.profileName || '';
        const isCallCenter = profileName.toLowerCase().includes('call') && profileName.toLowerCase().includes('center');
        const isBackOffice = profileName.toLowerCase().includes('back') && profileName.toLowerCase().includes('office');
        return !isCallCenter && !isBackOffice;
    }

    get showOriginFilter() {
        const profileName = this.userProfileInfo.profileName || '';
        const isBackOffice = profileName.toLowerCase().includes('back') && profileName.toLowerCase().includes('office');
        return !isBackOffice;
    }
    
    get departmentCount() {
        return this.departmentCaseCounts?.length || 0;
    }

    get isDepartmentListEmpty() {
        return this.departmentCaseCounts?.length === 0;
    }
}