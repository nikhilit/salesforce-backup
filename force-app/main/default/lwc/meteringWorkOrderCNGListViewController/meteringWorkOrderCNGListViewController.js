/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 10-11-2025
 * @last modified by  : Kartik Patkar Appstrail 
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   10-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from "lightning/navigation";
import CNG_PDF_Signature_File_Name from '@salesforce/label/c.CNG_PDF_Signature_File_Name';
import getCNGWorkOrderRecords from '@salesforce/apex/MeteringWorkOrderCNGListViewController.getCNGWorkOrderRecords';
import getColumnInfo from '@salesforce/apex/MeteringWorkOrderCNGListViewController.getColumnInfo';
import fieldPicklistValue from '@salesforce/apex/MeteringWorkOrderListViewController.fieldPicklistValue';
import getExcelData from '@salesforce/apex/MeteringWorkOrderCNGListViewController.getExcelData';
import getContentVersionsBase64 from '@salesforce/apex/MeteringWorkOrderListViewController.getContentVersionsBase64';
import getAccountOptions from '@salesforce/apex/MeteringWorkOrderCNGListViewController.getAccountOptions';
import getCNGWorkOrderFilterRecords from '@salesforce/apex/MeteringWorkOrderCNGListViewController.getCNGWorkOrderFilterRecords';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import WORK_ORDER_OBJECT from '@salesforce/schema/WorkOrder';
import APPROVAL_STATUS from '@salesforce/schema/WorkOrder.Approval_Status__c';
import saveUserColumnConfig from '@salesforce/apex/MeteringWorkOrderListViewController.saveUserColumnConfig';
import getUserColumnConfig from '@salesforce/apex/MeteringWorkOrderListViewController.getUserColumnConfig';


export default class MeteringWorkOrderCNGListViewController extends NavigationMixin(LightningElement) {

    @api metadataConfigApiName = 'CNG_Meter_Readings';
    @api limitRec = 5000;
    @api tableHeight = '43vh';
    @api hideHeader;
    @api lazyLoading;
    @track isBulkUploadBtnSelected = false;
    draftSelectedColumns = [];
    showColumnSelector = false;
    @track listViewLabel = 'CNG Metering Readings';
    likeState = true;
    fuelPoint;
    typeOfFuelSold;

    isExporting = false;
    spinner = false;
    metadataConfig;
    appointmentStatusOptions = [];
    showTable = false;

    columns = [];
    fuelPointOptions = [];
    typeOfFuelSoldOptions = [];
    salesOfficerName;
    omcOfficeName;
    salesOfficerNameOptions = [];
    omcOfficeNameOptions = [];

    accountFilter = {
        criteria: [
            {
                fieldPath: 'Category__c',
                operator: 'eq',
                value: 'CNG/LNG',
            }
        ]
    };

    connectedCallback() {
        this.init();
    }

    init() {
        this.getOptions();
        this.getColumnInfo();
        this.getAppointmentStatusPicklistValues();
        this.getFuelPointPicklistValues();        
        this.getTypeOfFuelSoldPicklistValues();   
    }

    zoneOptions = [];
    approvalStatusOptions = [];
    omcOptions = [];
    locationOptions = [];

    async getOptions() {
        try {
            this.zoneOptions = await getAccountOptions({ fieldApiName: 'Zone__c' });
            this.omcOptions = await getAccountOptions({ fieldApiName: 'Representative_Company__c' });
            this.locationOptions = await getAccountOptions({ fieldApiName: 'Location__c' });
            this.salesOfficerNameOptions = await getAccountOptions({ fieldApiName: 'Sales_Officer_Name__c' });      
            this.omcOfficeNameOptions = await getAccountOptions({ fieldApiName: 'OMC_Office_Name__c' });            
            console.log('Zone Options:', JSON.stringify(this.zoneOptions));
            console.log('OMC Options:', JSON.stringify(this.omcOptions));
            console.log('Location Options:', JSON.stringify(this.locationOptions));
            console.log('Sales Officer Name Options:', JSON.stringify(this.salesOfficerNameOptions)); 
            console.log('OMC Office Name Options:', JSON.stringify(this.omcOfficeNameOptions));   
        } catch (error) {
            console.error('Error fetching options:', error);
        }
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
    }
    fromDate;
    toDate;
    appointmentStatus;
    agency;
    agent;
    omc;
    zone;
    location;
    outlet;
    approvalstatus;
    bpNumbers;
    fuelPoint;
    typeOfFuelSold;
    salesOfficerName;
    omcOfficeName;
    handleInputChange(event) {
        const { name, value } = event.target;
        console.log('name--->', name, 'value--->', value);
        console.log('details::' + JSON.stringify(event.detail));
        if (name === 'fromDate') {
            this.fromDate = value || '';
        }
        else if (name === 'toDate') {
            this.toDate = value || '';
        }
        else if (name === 'appointmentStatus') {
            this.appointmentStatus = value || '';
        }
        else if (name === 'agency') {
            this.agency = event.detail.recordId || '';
        }
        else if (name === 'agent') {
            this.agent = event.detail.recordId || '';
        } else if (name === 'omc') {
            this.omc = value || '';
        } else if (name === 'zone') {
            this.zone = value || '';
        } else if (name === 'location') {
            this.location = value || '';
        }
        else if (name === 'account') {
            this.outlet = event.detail.recordId || '';
        } else if (name === 'Approval Status') {
            this.approvalstatus = value || '';
        } else if (name === 'bpNumber') {
            this.bpNumbers = value || '';
        }
        else if (name === 'fuelPoint') {              
            this.fuelPoint = value || '';
        } else if (name === 'typeOfFuelSold') {        
            this.typeOfFuelSold = value || '';
        }else if (name === 'salesOfficerName') {        
            this.salesOfficerName = value || '';
        } else if (name === 'omcOfficeName') {          
            this.omcOfficeName = value || '';
        }

    }

    handleViewAll(){
        this.spinner = true;
        this.getRecords();
    }

    getColumnInfo() {
        this.spinner = true;
        // this.isListLoading = true;
        getColumnInfo({ metadataConfigApiName: this.metadataConfigApiName })
            .then(result => {
                console.log('Column Info:', JSON.stringify(result));
                this.metadataConfig = result;
                this.columns = result.columns;
                this.listViewDeveloperName = result.listViewDeveloperName;
                this.allColumns = JSON.parse(JSON.stringify(this.columns));

        // 🔹 Dual listbox options
        this.fieldOptions = this.allColumns.map(col => ({
            label: col.label,
            value: col.fieldName
        }));
                // this.getRecords();
                // Process the result to set up columns as needed
                // ✅ APPLY SAVED USER CONFIG AFTER METADATA LOAD
        this.loadUserColumnPreference();

            })
            .catch(error => {
                this.spinner = false;
                this.isListLoading = false;
                console.error('Error fetching Column Info:', error);
                this.showToastMessage('Error', 'Failed to fetch Column Info.', 'error', 'dismissable');
            })
            .finally(() => {
                this.spinner = false;
            });
    }

    @track dataRecords = [];
    @track documentRecords;

    getRecords() {
        const token = this.createNewRequestToken();
        this.currentRequestToken = token;
        // this.isListLoading = true;

        this.spinner = true;
        console.log('Fetching CNG Work Order Records with Metadata Config:', JSON.stringify(this.metadataConfig));
        getCNGWorkOrderRecords({ metadataConfig: this.metadataConfig, limitRec: this.limitRec })
            .then(result => {
                if (this.currentRequestToken !== token) return;
                // if (this.lazyLoading) {
                this.processDataLazyLoading(result);
                // } else {
                //     this.processData(result);
                // }
                // this.processData(result);
                //this.paginatedData=result;
                console.log('this,paginatedData', JSON.stringify(result));
            })
            .catch(error => {
                this.spinner = false;
                console.error('Error fetching CNG Work Order Records:', JSON.stringify(error));
                this.showToastMessage('Error', 'Failed to fetch CNG Work Order Records.', 'error', 'dismissable');
            })
            .finally(() => {
                if (this.currentRequestToken === token) {
                    this.isListLoading = false;
                }
            });
    }
    selectedParentIds = [];     // Stores parent record.Id for selected rows
    selectedCaseIds = [];       // If you also want selected child row Ids
    selectedCount = 0;
    handleRowSelection(event) {
        // rows selected inside the datatable
        const selectedRows = event.detail.selectedRows;
        console.log('selectedRows', JSON.stringify(selectedRows));

        // get parent record Id from the attribute
        const parentRecordId = event.currentTarget.dataset.id;
        console.log('parentRecordId', JSON.stringify(parentRecordId));
        if (!selectedRows || selectedRows.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select at least one row.',
                    variant: 'error'
                })
            );
            return;
        }

        // if selected, store the parent record Id in a list
        if (!this.selectedParentIds) {
            this.selectedParentIds = [];
        }

        if (!this.selectedParentIds.includes(parentRecordId)) {
            this.selectedParentIds.push(parentRecordId);
        }

        console.log('Selected Parent IDs:', JSON.stringify(this.selectedParentIds));
    }


    showBulkUploadPdfBtn() {
        if (this.selectedParentIds.length <= 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select at least one row.',
                    variant: 'error'
                })
            );
            return;
        }
        this.isBulkUploadBtnSelected = true;
    }

    isApprovalBtnSelected = false;
    showApprovalBtn() {
        if (this.selectedParentIds.length <= 0) {
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

    isSendEmailBtnSelected = false;
    showSendEmailBtn() {
        if (this.selectedParentIds.length <= 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select at least one row.',
                    variant: 'error'
                })
            );
            return;
        }
        this.isSendEmailBtnSelected = true;
        this.isButtonView = false;
    }

    handleClose() {
        this.isSendEmailBtnSelected = false;
        this.isApprovalBtnSelected = false;
        this.isBulkUploadBtnSelected = false;
    }

    handleSearch() {
        const token = this.createNewRequestToken();
        this.currentRequestToken = token;

        // this.isListLoading = true;
        this.spinner = true;
        const bpList = (this.bpNumbers || '')
            .split(/[\s,;\n]+/)
            .map(bp => bp.trim())
            .filter(bp => bp.length > 0);
        const parameter = {
            fromDate: this.fromDate,
            toDate: this.toDate,
            agency: this.agency,
            agent: this.agent,
            appointmentStatus: this.appointmentStatus,
            omc: this.omc,
            zone: this.zone,
            location: this.location,
            outlet: this.outlet,
            metadataConfig: this.metadataConfig,
            limitRec: this.limitRec,
            approvalstatus: this.approvalstatus,
            bpNumbers: bpList,
            fuelPoint: this.fuelPoint,            
            typeOfFuelSold: this.typeOfFuelSold,
            salesOfficerName: this.salesOfficerName,    
            omcOfficeName: this.omcOfficeName          
        };


        console.log('Parameter --->', JSON.stringify(parameter));
        getCNGWorkOrderFilterRecords(parameter)
            .then(result => {
                if (this.currentRequestToken !== token) return;
                console.log('filtred results' + JSON.stringify(result));
                this.processDataLazyLoading(result);
                this.scrollToTop();
            })
            .catch(error => {
                this.spinner = false;
                console.log('Error fetching Work Orders:' + JSON.stringify(error))
            })
            .finally(() => {
                if (this.currentRequestToken === token) {
                    this.isListLoading = false;
                }
            });
    }

    handleClear() {
        this.fromDate = null;
        this.toDate = null;
        this.appointmentStatus = '';
        this.agency = '';
        this.agent = '';
        this.omc = '';
        this.zone = '';
        this.location = '';
        this.outlet = '';
        this.fuelPoint = '';            
        this.typeOfFuelSold = '';         
        this.salesOfficerName = '';        
        this.omcOfficeName = '';            
        const inputs = this.template.querySelectorAll('lightning-input, lightning-textarea', 'lightning-input');
        inputs.forEach(input => input.value = '');
        const lookips = this.template.querySelectorAll('lightning-record-picker');
        lookips.forEach(lookup => lookup.clearSelection());
        this.showTable = false;
        this.dataRecords = [];
        this.fullDataRecords = [];

        // this.getRecords();

        // this.loadWorkOrders();
    }

    processData(result) {
        var recordList = result.records;
        this.documentRecords = result.contentDocMap;
        console.log('Document Records:', JSON.stringify(this.documentRecords));
        this.dataRecords = recordList.filter(item => {
            item.expanded = false;
            if (item.Dispenser_Points__r) {
                item.Dispenser_Points__r.forEach(dispenserPoint => {
                    dispenserPoint.fromDate = dispenserPoint.WorkOrderID__r.From_Date__c;
                });
            }
            return item;
        });
        console.log('Filtered CNG Work Order Records:', JSON.stringify(this.dataRecords));
        this.dataRecords = this.mapOriginalApiToFieldNameNested(this.columns, this.dataRecords);
        console.log('Mapped CNG Work Order Records:', JSON.stringify(this.dataRecords));
        this.dataRecords.forEach(item => {
            item.expanded = false;
            item.jointPDF = true;
            item.liveReadingPDF = true;
            if (this.documentRecords && this.documentRecords.length > 0) {
                for (let i = 0; i < this.documentRecords.length; i++) {
                    let doc = this.documentRecords[i];
                    if (doc.LinkedEntityId == item.Id && doc.ContentDocumentId) {
                        if (doc.ContentDocument.Title.includes('_JT_') && item.jointPDF) {
                            item.jointPDF = false;
                        }
                        if (doc.ContentDocument.Title.includes('Live_Update_') && item.liveReadingPDF) {
                            item.liveReadingPDF = false;
                        }
                    }
                }
            }
        });
        this.totalRecords = this.dataRecords.length;
        // this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // this.setPaginatedData();
        // console.log('CNG Work Order Records:', JSON.stringify(this.dataRecords));
        this.spinner = false;
    }

    @track paginatedData = [];    // Records for current page
    @track page = 1;              // Current page
    @track pageSize = 20;         // Records per page
    @track totalPages = 0;        // Calculated from dataRecords
    @track totalRecords = 0;

    fullDataRecords = [];   // backup of full data
    currentIndex = 0;

    @track isListLoading = false;       // spinner only for list section
    currentRequestToken = null;  
    createNewRequestToken() {
        return Symbol();
    }

    processDataLazyLoading(result) {
        // FULL dataset returned from Apex
        var recordList = result.records;
        this.documentRecords = result.contentDocMap;

        this.fullDataRecords = [];
        this.currentIndex = 0;

        /** ------------------------------
         *  ⭐ STORE FULL LIST IN BACKUP ⭐
         * ----------------------------- */
        var varFullDataRecords = recordList.filter(item => {
            item.expanded = false;
            if (item.Dispenser_Points__r) {
                item.Dispenser_Points__r.forEach(dispenserPoint => {
                    dispenserPoint.fromDate = dispenserPoint.WorkOrderID__r.From_Date__c;
                });
            }
            return item;
        });
        console.log('Filtered CNG Work Order Records:', JSON.stringify(varFullDataRecords));
        varFullDataRecords = this.mapOriginalApiToFieldNameNested(this.columns, varFullDataRecords);
        // console.log('Mapped CNG Work Order Records:', JSON.stringify(this.dataRecords));
        varFullDataRecords.forEach(item => {
            item.expanded = false;
            item.jointPDF = true;
            item.liveReadingPDF = true;
            if (this.documentRecords && this.documentRecords.length > 0) {
                for (let i = 0; i < this.documentRecords.length; i++) {
                    let doc = this.documentRecords[i];
                    if (doc.LinkedEntityId == item.Id && doc.ContentDocumentId) {
                        if (doc.ContentDocument.Title.includes('_JT_') && item.jointPDF) {
                            item.jointPDF = false;
                        }
                        if (doc.ContentDocument.Title.includes('Live_Update_') && item.liveReadingPDF) {
                            item.liveReadingPDF = false;
                        }
                    }
                }
            }
        });

        // this.fullDataRecords = recordList.map(item => {
        //     item.expanded = false;
        //     return item;
        // });

        this.fullDataRecords = varFullDataRecords;
        console.log('Full Data Records:', JSON.stringify(this.fullDataRecords));

        /** ------------------------------------------------------------
         * ⭐ SHOW ONLY FIRST 20 RECORDS IN THE UI (LAZY LOADING START) ⭐
         * ------------------------------------------------------------ */
        this.currentIndex = this.pageSize;
        this.dataRecords = JSON.parse(JSON.stringify(this.fullDataRecords.slice(0, this.pageSize)));

        console.log('Initial Lazy Loaded Records:', JSON.stringify(this.dataRecords));

        this.totalRecords = this.fullDataRecords.length;
        this.spinner = false;
        this.showTable = true;
    }

    get visibleRecordCountLabel() {
        const loaded = this.dataRecords?.length || 0;
        const total = this.fullDataRecords?.length || 0;

        // 0 records case
        if (loaded === 0) {
            return 'Showing 0 records';
        }

        // If total is less than pageSize (e.g., only 15 in entire dataset)
        if (total <= this.pageSize) {
            return `Showing ${total} records`;
        }

        // If user has not loaded all yet (lazy loading ongoing)
        if (loaded < total) {
            return `Showing ${loaded}+ records`;
        }

        // All records loaded
        return `Showing ${total} records`;
    }

    scrollToTop() {
        const container = this.template.querySelector('.table-container');
        if (container) {
            container.scrollTop = 0;
        }
    }

    /** ----------------------------------------------------------------
     *   ⭐ ADD LAZY LOADING DURING SCROLL — LOAD NEXT 20 RECORDS ⭐
     * ---------------------------------------------------------------- */
    handleScroll(event) {
        // if (!this.lazyLoading) return;
        const el = event.target;

        // Has user scrolled near bottom?
        if (Math.ceil(el.scrollTop) >= (Number(el.scrollHeight) - Number(el.offsetHeight))) {
            this.loadMoreData();
        }
    }

    loadMoreData() {
        // if (!this.lazyLoading) return;
        this.spinner = true;
        // this.isListLoading = true;

        // Stop if currently loading (prevents duplicate scroll calls)
        if (this.isLoadingMore) return;
        this.isLoadingMore = true;

        // Stop if all records are loaded
        if (this.currentIndex >= this.fullDataRecords.length) {
            console.log('⛔ No more records to load');
            this.isLoadingMore = false;
            this.isListLoading = false;
            this.spinner = false;
            return;
        }

        if (this.currentIndex >= this.fullDataRecords.length) return;

        const nextIndex = this.currentIndex + this.pageSize; // FIX HERE ✔

        const nextChunk = JSON.parse(JSON.stringify(
            this.fullDataRecords.slice(this.currentIndex, nextIndex)
        ));

        this.dataRecords = [...this.dataRecords, ...nextChunk];

        this.currentIndex = nextIndex;

        console.log('Lazy Loaded More Records:', this.currentIndex);
        this.isListLoading = false;
        this.spinner = false;

        // Allow next scroll load
        setTimeout(() => {
            this.isLoadingMore = false;
            this.isListLoading = false;
            this.spinner = false;
        }, 200);
    }

    // Get records for current page
    setPaginatedData() {
        const start = (this.page - 1) * this.pageSize;
        const end = this.page * this.pageSize;
        this.paginatedData = this.dataRecords.slice(start, end);
        console.log('Paginated Data:', JSON.stringify(this.paginatedData));
        // this.paginatedData = this.paginatedData.map(record => {
        //     // if (this.imageFields) {
        //     //     this.imageFields.split(',').forEach(field => {
        //     //         record[field] = this.extractImageUrl(record[field]);
        //     //     });
        //     // }
        //     return record;
        // });
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
        const recordId = event.currentTarget.dataset.id;
        console.log('Sorting recordId:', recordId);
        const { fieldName: sortedBy, sortDirection } = event.detail;
        console.log('Sorting by:', sortedBy, 'Direction:', sortDirection);
        // const cloneData = [...this.paginatedData];

        // cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        // console.log('Before Sort:', JSON.stringify(cloneData));
        this.paginatedData.forEach(item => {
            if (item.Id == recordId && item.Dispenser_Point__r) {
                item.Dispenser_Point__r.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
            }
        });
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    handleOnselect(event) {
        var selectedMenu = event.detail.value;
        var recordId = event.currentTarget.dataset.id;
        switch (selectedMenu) {
            case 'MenuItemOne':
                // Handle Photos action
                console.log('Photos selected for recordId:', recordId);
                this.handleOpenModal(recordId);
                break;
            case 'MenuItemTwo':
                // Handle Joint Ticket PDF action
                console.log('Joint Ticket PDF selected for recordId:', recordId);
                if (this.documentRecords) {
                    for (let i = 0; i < this.documentRecords.length; i++) {
                        let doc = this.documentRecords[i];
                        if (doc.LinkedEntityId === recordId && doc.ContentDocumentId) {
                            if (doc.ContentDocument.Title.includes('_JT_')) {
                                this.navigateToFiles(doc.ContentDocumentId);
                                break;
                            }
                        }
                    }
                }
                break;
            case 'MenuItemThree':
                // Handle Live Reading PDF action
                console.log('Live Reading PDF selected for recordId:', recordId);
                if (this.documentRecords) {
                    for (let i = 0; i < this.documentRecords.length; i++) {
                        let doc = this.documentRecords[i];
                        if (doc.LinkedEntityId === recordId && doc.ContentDocumentId) {
                            if (doc.ContentDocument.Title.includes('Live_Update_')) {
                                this.navigateToFiles(doc.ContentDocumentId);
                                break;
                            }
                        }
                    }
                }
                break;
            default:
                console.log('Unknown menu item selected:', selectedMenu);
        }
    }

    navigateToFiles(contentId) {
        this[NavigationMixin.Navigate]({
            type: "standard__namedPage",
            attributes: {
                pageName: "filePreview",
            },
            state: {
                recordIds: contentId
            },
        });
    }

    signatureURL;
    selfieURL;
    isModalOpen = false;
    handleOpenModal(record) {
        this.documentRecords.forEach(doc => {
            if (doc.LinkedEntityId === record && doc.ContentDocumentId) {
                if (doc.ContentDocument.Title.includes('Signature') || doc.ContentDocument.Title.includes(CNG_PDF_Signature_File_Name)) {
                    this.signatureURL = '/sfc/servlet.shepherd/version/download/' + doc.ContentDocument.LatestPublishedVersionId;
                }
                if (doc.ContentDocument.Title.includes('Selfie')) {
                    this.selfieURL = '/sfc/servlet.shepherd/version/download/' + doc.ContentDocument.LatestPublishedVersionId;
                }
            }
        });
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.signatureURL = null;
        this.selfieURL = null;
        this.isModalOpen = false;
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

    toggleSection(event) {
        const recordId = event.currentTarget.dataset.id;
        this.dataRecords = this.dataRecords.map(item => {
            if (item.Id === recordId) {
                console.log('Toggling section for recordId:', recordId);
                console.log('Current expanded state:', JSON.stringify(item));
                item.expanded = !item.expanded;
            }
            return item;
        });
    }

    toggleFilterSection() {
        this.likeState = !this.likeState;
    }

    get tableContainerHeight() {
        return !this.likeState ? 'height:63vh;' : 'height:' + this.tableHeight + ';'+'align-content: center;';
    }
    toggleColumnSelector() {
        this.showColumnSelector = !this.showColumnSelector;
        if (this.showColumnSelector) {
            this.draftSelectedColumns = this.columns.map(col => col.fieldName);
         }
    }

    handleDraftColumnChange(event) {
        this.draftSelectedColumns = event.detail.value;
    }

    async handleApply() {
        console.log('listViewDeveloperName',this.listViewDeveloperName);
    this.columns = this.draftSelectedColumns
        .map(fieldName => this.allColumns.find(col => col.fieldName === fieldName))
        .filter(col => col != null);
    try {
        console.log('About to call saveUserColumnConfig with:', {
            listViewName: this.listViewDeveloperName,
            selectedFieldsLength: this.draftSelectedColumns.length,
            order: this.draftSelectedColumns
        });
        
        const result = await saveUserColumnConfig({
            listViewName: this.listViewDeveloperName,
            selectedFields: JSON.stringify(this.draftSelectedColumns)
        });
            this.showToastMessage('Success', 'Column preferences and order saved successfully', 'success');
    } catch (error) {
        console.error('Error saving column config:', JSON.stringify(error));
        this.showToastMessage('Error', 'Failed to save column preferences: ' + error.body?.message, 'error');
    }

    this.showColumnSelector = false;
    this.tableKey++;
    }



    handleCancel() {
    // Revert draft to current visible columns
        this.draftSelectedColumns = this.columns.map(col => col.fieldName);
        this.showColumnSelector = false;
    }
    /**
     * Map columns.originalApi -> columns.fieldName across parent and child records
     * Keeps child arrays nested but replaces field keys in child objects.
     *
     * @param {Array} columns - array of { fieldName, originalApi, ... }
     * @param {Array} data - array of parent records (may contain child arrays)
     * @returns {Array} transformed data (non-mutating)
     */
    mapOriginalApiToFieldNameNested(columns, data) {
        const cloned = JSON.parse(JSON.stringify(data || []));

        const getByPath = (obj, path) => {
            if (!obj || !path) return undefined;
            return path.split('.').reduce((acc, p) => (acc == null ? undefined : acc[p]), obj);
        };

        const setKey = (obj, key, value) => {
            obj[key] = value;
        };

        const toSingularChildKey = (key) => key.replace(/s(?=__r$)/, '');

        const out = cloned.map(parent => {
            const parentMapped = {};

            // Map parent-level fields from columns
            columns.forEach(col => {
                const parentValue = getByPath(parent, col.originalApi);
                if (parentValue !== undefined) {
                    setKey(parentMapped, col.fieldName, parentValue);
                }
            });

            // Preserve important parent-level details
            if (parent.WorkOrderNumber !== undefined) parentMapped.WorkOrderNumber = parent.WorkOrderNumber;
            if (parent.AccountId !== undefined) parentMapped.AccountId = parent.AccountId;
            if (parent.Account && parent.Account.Name !== undefined && !parentMapped.Account_Name__c) {
                parentMapped.AccountName = parent.Account.Name;
                parentMapped.Account_Name__c = parent.Account.Name;
                parentMapped.Account_Location__c = parent.Account.Location__c;
                parentMapped.Account_Representative_Company__c = parent.Account.Representative_Company__c;
            }
            if (parent.From_Date__c) parentMapped.From_Date__c = parent.From_Date__c;
            if (parent.To_Date__c) parentMapped.To_Date__c = parent.To_Date__c;

            // Detect relationship arrays (child records)
            const childKeys = Object.keys(parent).filter(k =>
                Array.isArray(parent[k]) && parent[k].length > 0 && typeof parent[k][0] === 'object'
            );

            childKeys.forEach(childKey => {
                const childArray = parent[childKey];
                const newChildKey = toSingularChildKey(childKey);

                const mappedChildren = childArray.map(child => {
                    const mappedChild = {};

                    columns.forEach(col => {
                        const val = getByPath(child, col.originalApi);
                        if (val !== undefined) {
                            setKey(mappedChild, col.fieldName, val);
                        }
                    });

                    // Keep child Id for tracking
                    if (child.Id !== undefined) mappedChild.Id = child.Id;

                    // Flatten WorkOrderID__r.* fields dynamically (no need to specify in columns)
                    if (child.WorkOrderID__r) {
                        Object.entries(child.WorkOrderID__r).forEach(([key, val]) => {
                            mappedChild[`WorkOrderID__r_${key}`] = val;
                        });
                    }

                    // Copy direct fields from child
                    [
                        'Point_Number__c', 'Opening_Reading_Value__c', 'Closing_Reading_Value__c',
                        'Difference_Of_Open_and_Close_Reading__c', 'Metering_Agency__c',
                        'Meter_Reader__c', 'Calibration_Qty__c', 'Jumping_Qty__c',
                        'Other_Qty__c', 'Live_Reading__c'
                    ].forEach(f => {
                        if (child[f] !== undefined) mappedChild[f] = child[f];
                    });

                    return mappedChild;
                });

                parentMapped[newChildKey] = mappedChildren;
            });

            // ✅ Keep the parent’s original Id, not the child Id
            if (parent.Id !== undefined) parentMapped.Id = parent.Id;

            return parentMapped;
        });

        return out;
    }

    /**
     * @description
     * Recursively flattens nested Salesforce-style JSON data into a single-level map.
     * Nested relationship fields (e.g. WorkOrderID__r.Account.Name)
     * become flattened keys like "WorkOrderID__r.Account.Name".
     *
     * @param {Array|Object} data - Input object or array of records
     * @returns {Array} flattened array of objects
     */
    flattenSalesforceData(data) {
        // Handle if input is a single object instead of an array
        const records = Array.isArray(data) ? data : [data];

        const flattenObject = (obj, parentKey = '', res = {}) => {
            for (const key in obj) {
                if (!Object.prototype.hasOwnProperty.call(obj, key)) continue;

                const value = obj[key];
                const newKey = parentKey ? `${parentKey}.${key}` : key;

                if (value && typeof value === 'object' && !Array.isArray(value)) {
                    // Recursive flatten for nested objects
                    flattenObject(value, newKey, res);
                } else {
                    res[newKey] = value;
                }
            }
            return res;
        };

        return records.map(record => flattenObject(record));
    }


    async exportWorkOrdersAsExcel() {
        this.isExporting = true;
        this.isExportCancelled = false;

        try {
            // ✅ STEP 1 — Get data from Apex
            const parameter = {
                fromDate: this.fromDate,
                toDate: this.toDate,
                agency: this.agency,
                agent: this.agent,
                appointmentStatus: this.appointmentStatus,
                omc: this.omc,
                zone: this.zone,
                location: this.location,
                outlet: this.outlet,
                metadataConfig: this.metadataConfig,
                limitRec: this.limitRec,
                fuelPoint: this.fuelPoint,              
                typeOfFuelSold: this.typeOfFuelSold,     
                salesOfficerName: this.salesOfficerName,      
                omcOfficeName: this.omcOfficeName             
            };
            const apexResponse = await getExcelData(parameter);

            // Apex returns { query: 'SOQL...', records: [ ... ] }
            const recordsSnapshot = this.flattenSalesforceData(apexResponse.records) || [];
            console.log('Excel Export - Records Snapshot:', JSON.stringify(recordsSnapshot));
            console.log('this.metadataConfig:', this.metadataConfig);

            // Parse metadata config fields
            const excelFields = JSON.parse(this.metadataConfig.excelFields);
            const imageFieldsRaw = this.metadataConfig.imageFields;
            const imageFields = typeof imageFieldsRaw === 'string'
                ? imageFieldsRaw.split(',').map(i => i.trim()).filter(Boolean)
                : imageFieldsRaw; // handle array type too

            console.log('Excel Export - Excel Fields:', JSON.stringify(excelFields));
            console.log('Excel Export - Image Fields:', JSON.stringify(imageFields));

            this.isExporting = true;
            this.isExportCancelled = false;

            // ✅ STEP 2 — Prepare progress state
            this.totalItems = imageFields.length;
            this.currentProgress = 0;
            this.progressWidthUpdate();

            const allBase64 = {};

            // ✅ STEP 3 — Fetch image base64 per column
            for (const fieldName of imageFields) {
                if (this.isExportCancelled) throw new Error('Export cancelled by user');

                allBase64[fieldName] = await this.fetchImagesForColumn(fieldName, recordsSnapshot);

                this.currentProgress++;
                this.progressWidthUpdate();
            }

            // ✅ STEP 4 — Build table HTML for Excel
            let doc = '<table border="1">';
            doc += '<colgroup>';
            Object.keys(excelFields).forEach(() => {
                doc += '<col style="width:120px"/>';
            });
            doc += '</colgroup>';

            doc += `<style>
            table, th, td {
                border: 1px solid black;
                border-collapse: collapse;
                text-align: center;
                vertical-align: middle;
                font-family: Arial;
                font-size: 12px;
            }
            th {
                background-color: #f2f2f2;
                font-weight: bold;
            }
            img {
                object-fit: contain;
            }
        </style>`;

            // ✅ Header Row
            doc += '<tr>';
            Object.values(excelFields).forEach(label => {
                doc += `<th>${label}</th>`;
            });
            doc += '</tr>';

            // ✅ STEP 5 — Table Body
            for (const record of recordsSnapshot) {
                if (this.isExportCancelled) throw new Error('Export cancelled by user');

                doc += '<tr style="height:90px;">';

                for (const [apiName, label] of Object.entries(excelFields)) {
                    let cellValue = record[apiName] ?? '';

                    // ✅ Handle image fields
                    if (imageFields.includes(apiName)) {
                        const id = this.extractContentVersionId(cellValue);
                        const base64 = id ? allBase64[apiName]?.[id] : null;

                        cellValue = base64
                            ? `<img src="data:image/png;base64,${base64}" width="100" height="90" />`
                            : '';
                    }

                    doc += `<td>${cellValue}</td>`;
                }

                doc += '</tr>';
            }

            // ✅ STEP 6 — Download Excel file
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

    handleStopExport() {
        if (this.isExporting) {
            this.isExportCancelled = true;
            this.showToastMessage('Info', 'Stopping export...', 'info');
        } else {
            this.showToastMessage('Info', 'No export process is currently running.', 'info');
        }
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

    getAppointmentStatusPicklistValues() {
        fieldPicklistValue({ objectName: 'WorkOrder', fieldName: 'Appointment_Status__c' })
            .then(result => {
                this.appointmentStatusOptions = result;
            })
            .catch(error => {
                console.error('Error fetching picklist values:', error);
            });
    }
    getFuelPointPicklistValues() {
    fieldPicklistValue({ objectName: 'Account', fieldName: 'Fuel_Point__c' })
        .then(result => {
            this.fuelPointOptions = result;
            console.log('Fuel Point Options:', JSON.stringify(this.fuelPointOptions));
        })
        .catch(error => {
            console.error('Error fetching Fuel Point picklist values:', error);
        });
    }

        getTypeOfFuelSoldPicklistValues() {
            fieldPicklistValue({ objectName: 'Account', fieldName: 'Type_of_Fuel_Sold__c' })
                .then(result => {
                    this.typeOfFuelSoldOptions = result;
                    console.log('Type of Fuel Sold Options:', JSON.stringify(this.typeOfFuelSoldOptions));
                })
                .catch(error => {
                    console.error('Error fetching Type of Fuel Sold picklist values:', error);
                });
        }

    handleCloseModel() {
        this.isBulkUploadBtnSelected = false;
    }
    // 🔹 Load saved column order & visibility for logged-in user
async loadUserColumnPreference() {
    try {
        const config = await getUserColumnConfig({
            listViewName: this.listViewDeveloperName
        });

        if (config && config.Selected_Fields__c) {
            const savedFields = JSON.parse(config.Selected_Fields__c);

            // 🔹 Apply saved order & visibility
            this.columns = savedFields
                .map(fieldName =>
                    this.allColumns.find(col => col.fieldName === fieldName)
                )
                .filter(col => col);

            console.log('✅ User column preference applied:', savedFields);
        }
    } catch (error) {
        console.error('❌ Error loading user column config:', error);
    }
}


}