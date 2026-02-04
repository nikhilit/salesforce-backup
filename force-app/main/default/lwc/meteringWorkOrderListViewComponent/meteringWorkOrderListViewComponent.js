/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 27-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-10-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement, track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getDynamicColumns from '@salesforce/apex/MeteringWorkOrderListViewController.getDynamicColumns';
// import getWorkOrderList from '@salesforce/apex/MeteringWorkOrderListViewController.getWorkOrderList';
// import getWorkOrdersByBP from '@salesforce/apex/MeteringWorkOrderListViewController.getWorkOrdersByBP';
import getContentVersionsBase64 from '@salesforce/apex/MeteringWorkOrderListViewController.getContentVersionsBase64';
import getWorkOrdersDynamic from '@salesforce/apex/MeteringWorkOrderListViewController.getWorkOrdersDynamic';
import fieldPicklistValue from '@salesforce/apex/MeteringWorkOrderListViewController.fieldPicklistValue';
import getGroupMasterOptions from '@salesforce/apex/MeteringWorkOrderListViewController.getGroupMasterOptions';
import getGroupCodeOptions from '@salesforce/apex/MeteringWorkOrderListViewController.getGroupCodeOptions';
import getGroupMessageOptions from '@salesforce/apex/MeteringWorkOrderListViewController.getGroupMessageOptions';
import getWorkOrdersByFilters from '@salesforce/apex/MeteringWorkOrderListViewController.getWorkOrdersByFilters';
import getMRUCategoryOptions from '@salesforce/apex/MeteringWorkOrderListViewController.getMRUCategoryOptions';
import getareaOptions from '@salesforce/apex/MeteringWorkOrderListViewController.getareaOptions';
import getGAWiseOptions from '@salesforce/apex/MeteringWorkOrderListViewController.getGAWiseOptions';
import getLocationOptions from '@salesforce/apex/MeteringWorkOrderListViewController.getLocationOptions';
import executeBatchImageProcess from '@salesforce/apex/MeteringWorkOrderListViewController.executeBatchImageProcess';

import getS3PathByContentVersionId from '@salesforce/apex/MeteringWorkOrderListViewController.getS3PathByContentVersionId';

import saveUserColumnConfig from '@salesforce/apex/MeteringWorkOrderListViewController.saveUserColumnConfig';
import getUserColumnConfig from '@salesforce/apex/MeteringWorkOrderListViewController.getUserColumnConfig';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import WORK_ORDER_OBJECT from '@salesforce/schema/WorkOrder';
import APPROVAL_STATUS from '@salesforce/schema/WorkOrder.Approval_Status__c';

export default class MeteringWorkOrderListViewComponent extends LightningElement {

    @api hideHeader;
    @api listViewDeveloperName;
    @api limit = 5000;
    @api tableHeight = '40vh';
    @api lazyLoading;
    @api getImageButton;

    @track dataRecords = [];
    @track bpNumbers = '';
    @track isModalOpen = false;
    @track selectedImage = null;
    @track scriptsLoaded = false;
    @track spinner = false;
    @track filterCondition;
    likeState = true;
    @track showIllustration = true;   // show message initially
    @track showTable = false;         // hide table initially
    approvalStatusOptions=[];
    showColumnSelector = false;
    allColumns = [];
    fieldOptions = [];
    draftSelectedColumns = [];
    @track isBatchProcessing = false;

    excelJS;
    fileSaverLoaded = false;

    // Columns for datatable
    get columns() {
        return this.columnResult || [];
    }

    listViewName = '';

    connectedCallback() {
       // this.loadColumnsAndData();
        this.loadListViewConfig(); 
        this.init();
    }
    handleViewAll() {
    this.showIllustration = false;
    this.showTable = true;

    // Load data WITHOUT filters
    this.loadWorkOrderData();
}


    appointmentStatusOptions = [];
    groupMasterOptions = [];
    init() {
        this.getGroupMasterOptionsFunc();
        this.getMRUCategoryOptionsFunc();
        this.getareaOptionsFunc();
        this.getgawiseOptions();
        this.getLocationOptions();
        fieldPicklistValue({ objectName: 'WorkOrder', fieldName: 'Appointment_Status__c' })
            .then(result => {
                this.appointmentStatusOptions = result;
            })
            .catch(error => {
                console.error('Error fetching picklist values:', error);
            });
    }
    @wire(getObjectInfo, { objectApiName: WORK_ORDER_OBJECT })
    objectInfo;

    // Get picklist values for Approval_Status__c
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: APPROVAL_STATUS
    })
    picklistHandler({ data, error }) {
        if (data) {
            this.approvalStatusOptions = data.values;
        } else if (error) {
            console.error(error);
        }
    }@wire(getObjectInfo, { objectApiName: WORK_ORDER_OBJECT })
    objectInfo;

    // Get picklist values for Approval_Status__c
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: APPROVAL_STATUS
    })
    picklistHandler({ data, error }) {
        if (data) {
            this.approvalStatusOptions = data.values;
        } else if (error) {
            console.error(error);
        }
    }
    getGroupMasterOptionsFunc() {
        getGroupMasterOptions()
            .then(result => {
                this.groupMasterOptions = result;
            })
            .catch(error => {
                console.error('Error fetching Group Master options:', error);
            });
    }

    groupMasterValue;
    handleGroupMasterChange(event) {
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
        this.groupMessageValue = event.detail.value;
    }

    mruCategoryOptions = [];
    getMRUCategoryOptionsFunc() {
        getMRUCategoryOptions()
            .then(result => {
                console.log('MRU Category options:', JSON.stringify(result));
                this.mruCategoryOptions = result;
            })
            .catch(error => {
                console.error('Error fetching MRU Category options:', error);
            });
    }
    areaOptions = [];
    getareaOptionsFunc() {
        console.log('area options');
        getareaOptions()
            .then(result => {
                console.log('areaOptions options:', JSON.stringify(result));
                this.areaOptions = result;
            })
            .catch(error => {
                console.error('Error fetching areaOptions:', error);
            });
    }
    gawiseOptions = [];
    getgawiseOptions() {
        console.log('area options');
        getGAWiseOptions()
            .then(result => {
                console.log('gawiseOptions options:', JSON.stringify(result));
                this.gawiseOptions = result;
            })
            .catch(error => {
                console.error('Error fetching gawiseOptions:', error);
            });
    }
    locationOptions=[];
     getLocationOptions() {
        console.log('location options');
        getLocationOptions()
            .then(result => {
                console.log('getLocationOptions :', JSON.stringify(result));
                this.locationOptions = result;
            })
            .catch(error => {
                console.error('Error fetching getLocationOptions:', error);
            });
    }

    mruCategoryValue;
    handleMruCategoryChange(event) {
        this.mruCategoryValue = event.detail.value;
    }
    approvalStatus;
    handleapprovalStatusChange(event){
        this.approvalStatus = event.detail.value;
    }
    area;
    handleAreaChange(event){
         this.area = event.detail.value;
    }
    gaWiseValue;
    handleGAWiseChange(event){
         this.gaWiseValue = event.detail.value;
    }
    locationValue;
    handleLocationChange(event){
        this.locationValue = event.detail.value;
    }

    isApprovalBtnSelected = false;
    showApprovalBtn() {
        if (this.selectedRecords.length <= 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select at least one row.',
                    variant: 'error'
                })
            );
            return;
        }
        this.isApprovalBtnSelected = true;
        this.isButtonView = false;
    }
    columnResult = [];
    listViewLabel = '';
    objectAPIName = '';
    recordTypeDevName = '';
    imageFields = '';
    customerCategory = '';
//     async loadColumnsAndData() {
//     this.spinner = true;
//     try {
//         const config = await getDynamicColumns({ listViewName: this.listViewDeveloperName });
//         console.log('List View Config:', JSON.stringify(config));
//         console.log('🔵 listViewDeveloperName:', this.listViewDeveloperName);

//         // Assign metadata values
//         this.listViewLabel = config.listViewLabel;
//         this.objectApiName = config.objectApiName;
//         this.recordTypeDevName = config.recordTypeDevName;
//         this.imageFields = config.imageFields;
//         this.customerCategory = config.customerCategory;
//         this.filterCondition = JSON.parse(config.filters);

//         // Ensure columns is a proper array
//         const columnsArray = Array.isArray(config.columns) ? config.columns : Object.values(config.columns);

//         this.columnResult = columnsArray.filter(col => {
//             col.initialWidth = col.type === 'text' ? 150 : (col.type === 'number' ? 100 : (col.type === 'date' ? 120 : (col.type === 'html' ? 100 : 130)));
//             return col;
//         });

//         // 🔹 Store master column list (one-time)
//         this.allColumns = JSON.parse(JSON.stringify(this.columnResult));

//         // 🔹 Dual listbox options
//         this.fieldOptions = this.allColumns.map(col => ({
//             label: col.label,
//             value: col.fieldName
//         }));

//         // 🔹 Fetch saved user preferences
//         console.log('🔵 Fetching saved config for listView:', this.listViewDeveloperName);
//         const savedConfig = await getUserColumnConfig({ listViewName: this.listViewDeveloperName });
//         console.log('🔵 savedConfig result:', JSON.stringify(savedConfig));
        
//         // if (savedConfig && savedConfig.Selected_Fields__c) {
//         //     // User has saved preferences, use them
//         //     try {
//         //         const savedFields = JSON.parse(savedConfig.Selected_Fields__c);
//         //         console.log('🟢 Found saved fields:', JSON.stringify(savedFields));
//         //         this.draftSelectedColumns = savedFields;
                
//         //         // Filter columnResult to only show saved columns
//         //         this.columnResult = this.allColumns.filter(col =>
//         //             savedFields.includes(col.fieldName)
//         //         );
//         //         console.log('🟢 Applied saved columns, now showing:', this.columnResult.length);
//         if (savedConfig && savedConfig.Selected_Fields__c) {
//     // User has saved preferences, use them
//     try {
//         const savedFields = JSON.parse(savedConfig.Selected_Fields__c);
//         console.log('🟢 Found saved fields:', JSON.stringify(savedFields));
//         this.draftSelectedColumns = savedFields;
        
//         // ✅ KEY CHANGE: Reorder allColumns based on saved order
//         this.columnResult = savedFields
//             .map(fieldName => this.allColumns.find(col => col.fieldName === fieldName))
//             .filter(col => col != null);  // Remove any null entries
        
//         console.log('🟢 Applied saved columns in saved order, now showing:', this.columnResult.length);
//             } catch (parseError) {
//                 console.error('🔴 Error parsing saved fields:', parseError);
//                 this.draftSelectedColumns = this.columnResult.map(col => col.fieldName);
//             }
//         } else {
//             console.log('🟡 No saved config found, using all columns');
//             this.draftSelectedColumns = this.columnResult.map(col => col.fieldName);
//         }

//         // Extract field API names for fetching data
//         const fieldApiNames = this.columnResult.map(col => col.originalApi);

//         // Fetch data
//         let records = await getWorkOrdersDynamic({
//             recordTypeDevName: 'MGL_Metering',
//             fieldJson: JSON.stringify(fieldApiNames.reduce((acc, f) => { acc[f] = f; return acc; }, {})),
//             objectApiName: this.objectApiName,
//             customerCategory: this.customerCategory,
//             limitRec: this.limit
//         });

//         this.dataRecords = JSON.parse(JSON.stringify(records));
//         this.totalRecords = this.dataRecords.length;
//         this.totalPages = Math.ceil(this.totalRecords / this.pageSize);

//         // Load initial batch
//         this.page = 1;
//         this.loadData();

//     } catch (error) {
//         console.error('Error loading columns or data:', JSON.stringify(error));
//         this.showToastMessage('Error', 'Unable to load list view configuration or data. Apply a filter and search.', 'error');
//     } finally {
//         this.spinner = false;
//     }
// }
async loadListViewConfig() {
    this.spinner = true;
    try {
        const config = await getDynamicColumns({
            listViewName: this.listViewDeveloperName
        });

        console.log('List View Config:', JSON.stringify(config));

        // 🔹 Metadata
        this.listViewLabel = config.listViewLabel;
        this.objectApiName = config.objectApiName;
        this.recordTypeDevName = config.recordTypeDevName;
        this.imageFields = config.imageFields;
        this.customerCategory = config.customerCategory;

        // 🔹 FILTER VISIBILITY CONFIG
        this.filterCondition = JSON.parse(config.filters);

        // 🔹 Columns
        const columnsArray = Array.isArray(config.columns)
            ? config.columns
            : Object.values(config.columns);

        this.columnResult = columnsArray.map(col => {
            col.initialWidth =
                col.type === 'text' ? 150 :
                col.type === 'number' ? 100 :
                col.type === 'date' ? 120 :
                col.type === 'html' ? 100 : 130;
            return col;
        });

        // 🔹 Store master list
        this.allColumns = JSON.parse(JSON.stringify(this.columnResult));

        // 🔹 Dual listbox options
        this.fieldOptions = this.allColumns.map(col => ({
            label: col.label,
            value: col.fieldName
        }));

        // 🔹 User column preferences
        const savedConfig = await getUserColumnConfig({
            listViewName: this.listViewDeveloperName
        });

        if (savedConfig?.Selected_Fields__c) {
            try {
                const savedFields = JSON.parse(savedConfig.Selected_Fields__c);
                this.draftSelectedColumns = savedFields;

                // Preserve saved order
                this.columnResult = savedFields
                    .map(f => this.allColumns.find(c => c.fieldName === f))
                    .filter(Boolean);
            } catch {
                this.draftSelectedColumns = this.columnResult.map(c => c.fieldName);
            }
        } else {
            this.draftSelectedColumns = this.columnResult.map(c => c.fieldName);
        }

    } catch (error) {
        console.error('Error loading list view config:', error);
        this.showToastMessage(
            'Error',
            'Unable to load filter configuration',
            'error'
        );
    } finally {
        this.spinner = false;
    }
}
async loadWorkOrderData() {
    this.spinner = true;
    try {
        const fieldApiNames = this.columnResult.map(col => col.originalApi);

        const records = await getWorkOrdersDynamic({
            recordTypeDevName: 'MGL_Metering',
            fieldJson: JSON.stringify(
                fieldApiNames.reduce((acc, f) => {
                    acc[f] = f;
                    return acc;
                }, {})
            ),
            objectApiName: this.objectApiName,
            customerCategory: this.customerCategory,
            limitRec: this.limit
        });

        this.dataRecords = JSON.parse(JSON.stringify(records));
        this.totalRecords = this.dataRecords.length;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);

        this.page = 1;
        this.showIllustration = false;
        this.showTable = true;

        this.loadData();

    } catch (error) {
        console.error('Error loading work orders:', error);
        this.showToastMessage(
            'Error',
            'Unable to load work orders',
            'error'
        );
    } finally {
        this.spinner = false;
    }
}


    @track paginatedData = [];    // Records for current page
    @track page = 1;              // Current page
    @track pageSize = 20;         // Records per page
    @track totalPages = 0;        // Calculated from dataRecords
    @track totalRecords = 0;
    @track tableKey = 0;

    //Get records for current page

    loadData(){
        if(!this.lazyLoading){
            this.setPaginatedData();
        }else{
            this.setLazyLoadingData();
        }
    }

    setPaginatedData() {
        const start = (this.page - 1) * this.pageSize;
        const end = this.page * this.pageSize;
        this.paginatedData = this.dataRecords.slice(start, end);
        this.paginatedData = this.paginatedData.map(record => {
            if (this.imageFields) {
                this.imageFields.split(',').forEach(field => {
                    record[field] = this.extractImageUrl(record[field]);
                });
            }
            return record;
        });

        // Recompute visibleSelectedRecords for the current page (normalize as strings)
        const pageIds = this.paginatedData.map(r => String(r.Id));
        this.visibleSelectedRecords = this.selectedRecords
            .map(id => String(id))
            .filter(id => pageIds.includes(id));

        console.log('paginatedData', JSON.stringify(this.paginatedData));
        this.tableKey++;
    }

    setLazyLoadingData() {
        this.spinner = true;
        // Calculate how many records must be visible now
        const end = this.page * this.pageSize;

        // Slice from the big dataset
        let lazySlice = this.dataRecords.slice(0, end);

        // Process images
        lazySlice = lazySlice.map(record => {
            if (this.imageFields) {
                this.imageFields.split(',').forEach(field => {
                    record[field] = this.extractImageUrl(record[field]);
                });
            }
            return record;
        });

        // Update displayed list
        this.paginatedData = lazySlice;

        // Track selected rows visible on screen
        const visibleIds = this.paginatedData.map(r => String(r.Id));
        this.visibleSelectedRecords = this.selectedRecords
            .map(id => String(id))
            .filter(id => visibleIds.includes(id));

        // Refresh UI
        this.tableKey++;

        console.log('Lazy loaded data:', JSON.stringify(this.paginatedData));
        this.spinner = false;
    }

    handleLoadNext() {
        console.log('Scroll event:');
        if (this.page < this.totalPages) {
            this.page++;
            this.setPaginatedData();
        }
    }

    // Handle next/previous buttons
    handleNext() {
        if (this.page < this.totalPages) {
            this.page++;
            this.setPaginatedData();
        }
    }

    handlePrev() {
        if (this.page > 1) {
            this.page--;
            this.setPaginatedData();
        }
    }

    get isPrevDisabled() {
        return this.page <= 1;
    }

    get isNextDisabled() {
        return this.page >= this.totalPages;
    }

    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    // Used to sort the 'Age' column
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.paginatedData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.paginatedData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    toggleFilterSection() {
        this.likeState = !this.likeState;
    }

    get tableContainerHeight() {
        return !this.likeState ? 'height:68vh;' : 'height:' + this.tableHeight + ';';
    }

    // loadWorkOrders() {
    //     getWorkOrderList()
    //         .then(result => {
    //             this.dataRecords = result.map(record => {
    //                 record.Images1__c = this.extractImageUrl(record.Images1__c);
    //                 return record;
    //             });
    //             console.log('Work Orders loaded:' + JSON.stringify(this.dataRecords));
    //         })
    //         .catch(error => console.error('Error fetching Work Order List:', error));
    // }

    caNumbers;
    fromDate;
    toDate;
    meterNumber;
    appointmentStatus;
    agency;
    agent;
    handleInputChange(event) {
        const { name, value } = event.target;
        console.log('name--->', name, 'value--->', value);
        console.log('details::' + JSON.stringify(event.detail));
        if (name === 'bpNumber') {
            this.bpNumbers = value || '';
        }
        else if (name === 'caNumber') {
            this.caNumbers = value || '';
        }
        else if (name === 'fromDate') {
            this.fromDate = value || '';
        }
        else if (name === 'toDate') {
            this.toDate = value || '';
        }
        else if (name === 'meterNumber') {
            this.meterNumber = value || '';
        }
        else if (name === 'appointmentStatus') {
            this.appointmentStatus = value || '';
        }
        else if (name === 'agency') {
            this.agency = event.detail.recordId || '';
        }
        else if (name === 'agent') {
            this.agent = event.detail.recordId || '';
        }

    }

    handleSearch() {
        console.log('area',this.area);
        console.log('gaWiseValue',this.gaWiseValue);
        console.log('approvalStatus',this.approvalStatus);
        console.log('mruCategoryValue',this.mruCategoryValue);
        const bpList = (this.bpNumbers || '')
            .split(/[\s,;\n]+/)
            .map(bp => bp.trim())
            .filter(bp => bp.length > 0);

        const caList = (this.caNumbers || '')
            .split(/[\s,;\n]+/)
            .map(bp => bp.trim())
            .filter(bp => bp.length > 0);

        // if (bpList.length === 0) {
        //     this.showToast('No BP Numbers', 'Please enter at least one BP Number.', 'info');
        //     return;
        // }

        // if (bpList.length === 0) {
        //     this.showToast('No BP Numbers', 'Please enter at least one BP Number.', 'info');
        //     return;
        // }
        const fieldApiNames = this.columns.map(col => col.originalApi ?? col.fieldName);

        const parameter = {
            bpNumbers: bpList,
            caNumbers: caList,
            fromDate: this.fromDate,
            toDate: this.toDate,
            agency: this.agency,
            agent: this.agent,
            groupMasterId: this.groupMasterValue,
            groupCodeId: this.groupCodeValue,
            groupMessageId: this.groupMessageValue,
            appointmentStatus: this.appointmentStatus,
            meterNumber: this.meterNumber,
            mruCategoryValue: this.mruCategoryValue,
            recordTypeDevName: 'MGL_Metering',
            fieldJson: JSON.stringify(
                fieldApiNames.reduce((acc, f) => { acc[f] = f; return acc; }, {})
            ),
            objectApiName: this.objectApiName,
            customerCategory: this.customerCategory,
            limitRec: this.limit,
            approvalStatus:this.approvalStatus,
            area : this.area,
            gaWiseValue:this.gaWiseValue,
            locationValue:this.locationValue
        };


        console.log('Parameter --->', JSON.stringify(parameter));
        getWorkOrdersByFilters(parameter)
            // .then(result => {
            //     console.log('Work Orders fetched:' + JSON.stringify(result));
            //     this.dataRecords = JSON.parse(JSON.stringify(result));
            //     this.totalRecords = result.length;
            //     this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
            //     this.setPaginatedData();
            // })
           .then(result => {
    this.dataRecords = JSON.parse(JSON.stringify(result));
    this.totalRecords = result.length;
    this.totalPages = Math.ceil(this.totalRecords / this.pageSize);

    this.showIllustration = false;
    this.showTable = true;

    this.page = 1;
    this.loadData();
})


            .catch(error => console.log('Error fetching Work Orders:' + JSON.stringify(error)));
    }

    handleClear() {
        this.bpNumbers = '';
        this.caNumbers = '';
        this.fromDate = null;
        this.toDate = null;
        this.meterNumber = '';
        this.appointmentStatus = '';
        this.mruCategoryValue = '';
        this.agency = '';
        this.agent = '';
        this.groupMasterValue = '';
        this.groupCodeValue = '';
        this.groupMessageValue = '';
        const inputs = this.template.querySelectorAll('lightning-input, lightning-textarea', 'lightning-input');
        inputs.forEach(input => input.value = '');
        const lookips = this.template.querySelectorAll('lightning-record-picker');
        lookips.forEach(lookup => lookup.clearSelection());
       // this.loadColumnsAndData();
        //this.loadWorkOrders();
         this.loadWorkOrderData();
         this.loadListViewConfig(); 
        this.area ='';
        this.gaWiseValue='';
        this.approvalStatus='';
    }

    handleImageClick(event) {
        this.selectedImage = event.detail.value;
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
        this.selectedImage = null;
    }

    extractImageUrl(imgFieldValue) {
        if (!imgFieldValue) return '';
        const imgTagMatch = imgFieldValue.match(/<img[^>]*src="([^"]+)"[^>]*>/);
        let url = imgTagMatch ? imgTagMatch[1] : imgFieldValue;
        return url || '';
    }

    extractContentVersionId(imgFieldValue) {
        if (!imgFieldValue) return null;
        let url = this.extractImageUrl(imgFieldValue);
        const idMatch = url.match(/\/([a-zA-Z0-9]{15,18})(?:$|\/|\?)/);
        return idMatch ? idMatch[1] : null;
    }

    @track currentProgress = 0;
    @track totalItems = 0;
    @track isExporting = false;
    @track isExportCancelled = false;
    @track progressWidth = 'width:0%';

    progressWidthUpdate() {
        console.log('currentProgress:', this.currentProgress, 'totalItems:', this.totalItems);
        if (this.totalItems === 0) this.progressWidth = 'width:0%';
        const percent = Math.min((this.currentProgress / this.totalItems) * 100, 100);
        this.progressWidth = `width:${percent}%`;
    }

    async exportWorkOrdersAsExcel() {
        const recordsSnapshot = JSON.parse(JSON.stringify(this.dataRecords));

        this.isExporting = true;
        this.isExportCancelled = false;
        // this.totalItems = recordsSnapshot.length;
        // this.currentProgress = 0;
        // await this.refreshUI();
        // this.progressWidthUpdate();

        try {
            // ✅ STEP 1 — Build column → imageBase64Map structure
            const imageColumns = this.columns.filter(
                col => col.type === 'html' || col.fieldName.includes('Image')
            );

            const allBase64 = {};

            // ✅ Total columns to process
            this.totalItems = imageColumns.length;
            this.currentProgress = 0;
            this.progressWidthUpdate();

            const totalImageColumns = imageColumns.length;

            for (let index = 0; index < totalImageColumns; index++) {
                if (this.isExportCancelled) throw new Error('Export cancelled by user');

                const col = imageColumns[index];

                // Fetch base64 data for this column
                allBase64[col.fieldName] = await this.fetchImagesForColumn(col.fieldName, recordsSnapshot);

                // ✅ Calculate and update progress for this stage
                this.currentProgress++;
                this.progressWidthUpdate();

            }

            // ✅ STEP 2 — Build table HTML
            let doc = '<table>';
            doc += '<colgroup>';
            this.columns.forEach(() => {
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
            this.columns.forEach(col => (doc += `<th>${col.label}</th>`));
            doc += '</tr>';

            // ✅ STEP 3 — Add Records
            for (const record of recordsSnapshot) {
                if (this.isExportCancelled) throw new Error('Export cancelled by user');

                doc += '<tr style="height:90px;">';

                for (const col of this.columns) {
                    let cellValue = record[col.fieldName] ?? '';

                    if (col.type === 'html' || col.fieldName.includes('Image')) {
                        const id = this.extractContentVersionId(cellValue);
                        const base64 = id ? allBase64[col.fieldName][id] : null;

                        cellValue = base64
                            ? `<img src="data:image/png;base64,${base64}" width="100" height="90" />`
                            : '';
                    }

                    doc += `<td>${cellValue}</td>`;
                }

                doc += '</tr>';
                // // ✅ Allow UI updates & stop button response
                // if (this.currentProgress % 1 === 0) {
                //     await this.refreshUI();
                // }
            }

            // ✅ STEP 4 — Download File
            if (!this.isExportCancelled) {
                doc += '</table>';
                const element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
                const downloadElement = document.createElement('a');
                downloadElement.href = element;
                downloadElement.download = 'WorkOrders.xls';
                document.body.appendChild(downloadElement);
                downloadElement.click();
                document.body.removeChild(downloadElement);
                this.showToastMessage('Success', 'Excel Generated successfully', 'success');
            }

        } catch (error) {
            if (error.message === 'Export cancelled by user') {
                this.showToastMessage('Stopped', 'Excel generation stopped by user.', 'error');
            } else {
                console.error('Export error:', error);
                this.showToastMessage('Error', 'Error Generating Excel', 'error');
            }
        } finally {
            this.isExporting = false;
            this.isExportCancelled = false;
            // await this.refreshUI();
        }
    }

    async fetchImagesForColumn(columnFieldName, records) {
        const ids = records
            .map(r => this.extractContentVersionId(r[columnFieldName]))
            .filter(id => id);

        const base64Map = {};
        const batchSize = 3;

        for (let i = 0; i < ids.length; i += batchSize) {
            if (this.isExportCancelled) throw new Error('Export cancelled by user');

            const batch = ids.slice(i, i + batchSize);
            try {
                const base64List = await getContentVersionsBase64({
                    contentVersionIds: batch,
                    maxIds: batch.length
                });

                batch.forEach((id, idx) => {
                    base64Map[id] = base64List[idx];
                });


                // ✅ Allow progress updates and Stop responsiveness
                // await this.refreshUI();

            } catch (err) {
                console.error(`Error fetching images for column ${columnFieldName}:`, err);
            }
        }

        return base64Map;
    }




    async exportWorkOrdersAsCSV() {
    try {
        console.log('🔵 CSV Export started');
        
        // ✅ Get FILTERED + SORTED records
        const recordsToExport = JSON.parse(JSON.stringify(this.dataRecords));
        console.log('🔵 Total filtered records to export:', recordsToExport.length);
        
        if (recordsToExport.length === 0) {
            this.showToastMessage('Warning', 'No records to export', 'warning');
            return;
        }
        
        // ✅ STEP 1: Identify image columns
        const imageColumns = this.columns.filter(
            col => col.type === 'html' || col.fieldName.includes('Image')
        );
        console.log('🔵 Image columns:', imageColumns.map(c => c.fieldName));
        
        // ✅ STEP 2: Extract ALL ContentVersionIds from ALL records
        const allContentVersionIds = new Set();
        const recordImageDebug = [];
        
        for (const record of recordsToExport) {
            for (const col of imageColumns) {
                const cellValue = record[col.fieldName] || '';
                console.log('🔵 Raw cell value for', col.fieldName, ':', cellValue.substring(0, 100));
                
                const contentVersionId = this.extractContentVersionId(cellValue);
                
                if (contentVersionId) {
                    allContentVersionIds.add(contentVersionId);
                    recordImageDebug.push({
                        woId: record.Id,
                        column: col.fieldName,
                        cvId: contentVersionId,
                        rawValue: cellValue.substring(0, 100)
                    });
                    console.log('🔵 Found CV ID:', contentVersionId, 'in', col.fieldName, 'for WO:', record.Id);
                } else {
                    console.log('🟡 NO CV ID found in', col.fieldName, 'for WO:', record.Id);
                }
            }
        }
        
        console.log('🔵 Total unique ContentVersionIds:', allContentVersionIds.size);
        console.log('🔵 CV IDs:', Array.from(allContentVersionIds));
        console.log('🔵 Debug info:', JSON.stringify(recordImageDebug));
        
        // ✅ STEP 3: Fetch S3 paths for all ContentVersionIds
        let cvToS3Map = {}; // Map<ContentVersionId, S3Path>
        
        if (allContentVersionIds.size > 0) {
            try {
                const cvIdArray = Array.from(allContentVersionIds);
                cvToS3Map = await getS3PathByContentVersionId({ 
                    contentVersionIds: cvIdArray
                });
                console.log('🟢 CV to S3 mapping fetched:', JSON.stringify(cvToS3Map));
            } catch (error) {
                console.error('🔴 Error fetching S3 paths:', error);
                this.showToastMessage('Warning', 'Could not fetch all image paths', 'warning');
            }
        }
        
        // ✅ STEP 4: Build CSV Header
        const headers = this.columns.map(col => {
            // If it's an image column, use "Image" as header
            if (col.type === 'html' || col.fieldName.includes('Image')) {
                return 'Image';
            }
            return col.label;
        });
        const headerRow = headers.map(h => this.escapeCSV(h)).join(',');
        
        console.log('🔵 CSV Headers:', headerRow);
        
        // ✅ STEP 5: Build CSV Rows
        const csvRows = [headerRow];
        
        for (const record of recordsToExport) {
            const row = [];
            
            for (const col of this.columns) {
                let cellValue = record[col.fieldName] ?? '';
                
                // ✅ Handle image columns - extract CV ID and get S3 path
                if (col.type === 'html' || col.fieldName.includes('Image')) {
                    const contentVersionId = this.extractContentVersionId(cellValue);
                    
                    console.log('🔵 Processing image:', col.fieldName, 'CV ID:', contentVersionId);
                    
                    // Look up the S3 path for this ContentVersionId
                    if (contentVersionId && cvToS3Map[contentVersionId]) {
                        cellValue = cvToS3Map[contentVersionId];
                        console.log('🟢 Found S3 path:', cellValue);
                    } else {
                        cellValue = '';
                        console.log('🟡 No S3 path found for CV:', contentVersionId);
                    }
                }
                
                // ✅ Format the value for CSV
                cellValue = this.formatCSVValue(cellValue);
                row.push(this.escapeCSV(cellValue));
            }
            
            csvRows.push(row.join(','));
        }
        
        // ✅ STEP 6: Combine all rows
        const csvContent = csvRows.join('\n');
        console.log('🔵 CSV content created, total rows:', csvRows.length);
        
        // ✅ STEP 7: Generate timestamp for filename
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const timestamp = `${year}-${month}-${day}`;
        
        // ✅ STEP 8: Create blob and download
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
        this.showToastMessage('Success', `CSV exported successfully (${recordsToExport.length} records)`, 'success');
        
    } catch (error) {
        console.error('🔴 CSV Export Error:', error);
        this.showToastMessage('Error', 'Failed to export CSV: ' + error.message, 'error');
    }
}

/**
 * Escape special characters in CSV values
 */
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

/**
 * Format value for CSV export
 */
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



    handleStopExport() {
        if (this.isExporting) {
            this.isExportCancelled = true;
            this.showToastMessage('Info', 'Stopping export...', 'info');
        } else {
            this.showToastMessage('Info', 'No export process is currently running.', 'info');
        }
    }

    @track selectedRecords = [];
    @track visibleSelectedRecords = [];
    refresh = true;
    handleSelectRecords(event) {
        const action = event.detail.config.action;
        const value = event.detail.config.value;

        switch (action) {
            case 'selectAllRows':
                // Add all IDs from current page to global selectedRecords
                this.paginatedData.forEach(rec => {
                    const idStr = String(rec.Id);
                    if (!this.selectedRecords.map(String).includes(idStr)) {
                        this.selectedRecords.push(rec.Id);
                    }
                });
                break;

            case 'deselectAllRows':
                // Remove all IDs of current page from global selectedRecords
                const pageIdsSet = new Set(this.paginatedData.map(r => String(r.Id)));
                this.selectedRecords = this.selectedRecords.filter(id => !pageIdsSet.has(String(id)));
                break;

            case 'rowSelect':
                if (!this.selectedRecords.map(String).includes(String(value))) {
                    this.selectedRecords.push(value);
                    console.log(JSON.stringify(this.selectedRecords),'selectedRecords')
                }
                break;

            case 'rowDeselect':
                this.selectedRecords = this.selectedRecords.filter(id => String(id) !== String(value));
                break;

            default:
                break;
        }

        // Recompute visibleSelectedRecords for the current page
        const pageIds = this.paginatedData.map(r => String(r.Id));
        this.visibleSelectedRecords = this.selectedRecords
            .map(id => String(id))
            .filter(id => pageIds.includes(id));

        // Force datatable to re-render so it reflects the updated selection
        this.tableKey++;

        console.log('Selected Records (global):', JSON.stringify(this.selectedRecords));
        console.log('Visible Selected Records (on page):', JSON.stringify(this.visibleSelectedRecords));
    }
     handleClose(){
       this.isApprovalBtnSelected = false;
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
    toggleColumnSelector() {
    this.showColumnSelector = !this.showColumnSelector;

    // Reset draft when opening - preserve the current order
    if (this.showColumnSelector) {
        // ✅ Initialize draftSelectedColumns with current columnResult order
        this.draftSelectedColumns = this.columnResult.map(col => col.fieldName);
        console.log('🔵 Modal opened with current order:', JSON.stringify(this.draftSelectedColumns));
    }
}

handleDraftColumnChange(event) {
    // ✅ This event fires when user reorders using arrows
    this.draftSelectedColumns = event.detail.value;
    console.log('🔵 Columns reordered:', JSON.stringify(this.draftSelectedColumns));
}

async handleApply() {
    console.log('🔵 handleApply() called');
    console.log('🔵 draftSelectedColumns (in order):', JSON.stringify(this.draftSelectedColumns));
    console.log('🔵 listViewDeveloperName:', this.listViewDeveloperName);
    
    // ✅ KEY CHANGE: Reorder columnResult based on draftSelectedColumns order
    this.columnResult = this.draftSelectedColumns
        .map(fieldName => this.allColumns.find(col => col.fieldName === fieldName))
        .filter(col => col != null);

    console.log('🔵 columnResult after reordering:', this.columnResult.map(c => c.fieldName));

    // 🔹 Save to Salesforce
    try {
        console.log('🔵 About to call saveUserColumnConfig with:', {
            listViewName: this.listViewDeveloperName,
            selectedFieldsLength: this.draftSelectedColumns.length,
            order: this.draftSelectedColumns
        });
        
        const result = await saveUserColumnConfig({
            listViewName: this.listViewDeveloperName,
            selectedFields: JSON.stringify(this.draftSelectedColumns)
        });
        
        console.log('🟢 Column config saved with order:', JSON.stringify(result));
        this.showToastMessage('Success', 'Column preferences and order saved successfully', 'success');
    } catch (error) {
        console.error('🔴 Error saving column config:', JSON.stringify(error));
        this.showToastMessage('Error', 'Failed to save column preferences: ' + error.body?.message, 'error');
    }

    this.showColumnSelector = false;
    this.tableKey++;
}



handleCancel() {
    // Revert draft to current visible columns
    this.draftSelectedColumns = this.columnResult.map(col => col.fieldName);
    this.showColumnSelector = false;
}

async handleGetImage() {
    if (this.isBatchProcessing) {
        this.showToastMessage(
            'Info',
            'Batch process is already running...',
            'info'
        );
        return;
    }

    this.isBatchProcessing = true;
    try {
        console.log('🔵 Initiating WorkOrderImageBatch...');
        
        // Call the apex method to execute the batch
        const result = await executeBatchImageProcess();
        
        console.log('🟢 Batch execution result:', JSON.stringify(result));
        this.showToastMessage(
            'Success',
            'Image batch process started. JobId: ' + result,
            'success'
        );
    } catch (error) {
        console.error('🔴 Error executing batch:', error);
        this.showToastMessage(
            'Error',
            'Failed to execute batch process: ' + (error.body?.message || error.message),
            'error'
        );
    } finally {
        this.isBatchProcessing = false;
    }
}

}