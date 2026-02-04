import { LightningElement, track, wire } from 'lwc';
import getRecords from '@salesforce/apex/DynamicListViewController.getRecords';
import getFieldList from '@salesforce/apex/DynamicListViewController.getFieldList';
import getUserColumnPreference from '@salesforce/apex/DynamicListViewController.getUserColumnPreference';
import saveUserColumnPreference from '@salesforce/apex/DynamicListViewController.saveUserColumnPreference';
import updateRecordApex from '@salesforce/apex/DynamicListViewController.updateRecord';
import getRecordDetailsApex from '@salesforce/apex/DynamicListViewController.getRecordDetails';
import getAnalyticsApex from '@salesforce/apex/DynamicListViewController.getAnalytics';
import importWorkOrdersApex from '@salesforce/apex/DynamicListViewController.importWorkOrdersApex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';


export default class DynamicListView extends LightningElement {

    objectName = 'WorkOrder';
    showColumnSelector = false;
    selectedRows = [];
    searchTimeout;
    searchKey = '';
    lastPage = null;

    @track records = [];
    @track columns = [];
    @track fieldOptions = [];
    @track selectedColumns = [];
    @track draftSelectedColumns = [];
    @track error;
    @track isLoading = false;
    
    sortBy;
    sortDirection = 'asc';
    previousColumns = [];
    draggedColumn;
    lastSavedColumns = [];

    pageNumber = 1;
    hasMore = false;

    
    /* ========== ADD THESE PROPERTIES TO YOUR CLASS ========== */

    showImportExportModal = false;
    isImportTab = true;
    isExportTab = false;

    importFileSelected = false;
    importPreviewHeaders = [];
    importPreviewRows = [];
    totalImportRows = 0;
    importedCSVData = [];

    exportRecordCount = 0;
    selectedExportType = 'all';
    includeIds = true;
    noSelectedRows = false;

    showFilterPanel = false;
    hasActiveFilters = false;
    filterOperator = 'AND';
    filterOperatorOptions = [
        { label: 'AND', value: 'AND' },
        { label: 'OR', value: 'OR' }
    ];
    filters = [];
    filterFieldOptions = [];

    defaultColumns = [
        'WorkOrderNumber',
        'Status',
        'Priority',
        'Subject',
        'OwnerId',
        'CreatedDate'
    ];

    pageSizeOptions = [
        { label: '10', value: 10 },
        { label: '20', value: 20 },
        { label: '50', value: 50 },
        { label: '100', value: 100 },
        { label: '1000', value: 1000}
    ];

    connectedCallback() {
        this.init();
    }

    async init() {
        try {
            this.isLoading = true;
            console.log('🚀 INIT START');
            const initStart = performance.now();

            // ✅ PARALLEL APEX CALLS
            const [fields, saved] = await Promise.all([
                getFieldList({ objectName: this.objectName }),
                getUserColumnPreference({ objectApiName: this.objectName })
            ]);

            console.log('✅ Metadata loaded in', (performance.now() - initStart).toFixed(0), 'ms');

            // Build field options
            this.fieldOptions = fields
                .filter(f => !f.apiName.includes('.'))
                .map(f => ({ label: f.label, value: f.apiName }));

            // Determine columns
            const available = this.fieldOptions.map(f => f.value);
            let finalCols = this.defaultColumns.filter(f => available.includes(f));

            if (saved && saved.trim()) {
                const savedCols = saved.split(',').map(s => s.trim()).filter(s => s);
                const valid = savedCols.filter(f => available.includes(f));
                if (valid.length > 0) {
                    finalCols = valid;
                }
            }

            // Set columns
            this.selectedColumns = [...finalCols];
            this.draftSelectedColumns = [...finalCols];
            this.lastSavedColumns = [...finalCols];

            this.buildColumns();
            console.log('✅ INIT COMPLETE in', (performance.now() - initStart).toFixed(0), 'ms');

        } catch (err) {
            console.error('❌ INIT ERROR:', err);
            this.handleError(err);
        } finally {
            this.isLoading = false;
            // ✅ Reduce initial page size for faster first load
            this.pageSize = 10;
            this.loadData();
        }
    }

    buildColumns() {
        this.columns = this.selectedColumns.map(f => {
            if (f === 'WorkOrderNumber') {
                return {
                    label: this.getLabel(f),
                    fieldName: 'WorkOrderLink',
                    type: 'url',
                    sortable: true,
                    typeAttributes: {
                        label: { fieldName: 'WorkOrderNumber' },
                        target: '_blank'
                    }
                };
            }

            return {
                label: this.getLabel(f),
                fieldName: f,
                type: 'text',
                sortable: true
            };
        });
    }

    getLabel(api) {
        const f = this.fieldOptions.find(x => x.value === api);
        return f ? f.label : api;
    }

    get filterButtonVariant() {
        return this.hasActiveFilters ? 'brand' : 'base';
    }

    get isFilterDisabled() {
        return this.filters.length === 0;
    }

    getRecordUrl(recordId) {
        return '/' + recordId;
    }

    toggleColumnSelector() {
        this.showColumnSelector = !this.showColumnSelector;
    }

    loadData() {
        if (this.isLoading) {
            console.warn('⚠️ Already loading');
            return;
        }

        if (!this.selectedColumns || this.selectedColumns.length === 0) {
            this.error = 'No columns selected';
            return;
        }

        this.isLoading = true;
        this.error = undefined;

        const fieldsToFetch = ['Id', ...this.selectedColumns];
        const loadStart = performance.now();

        console.log('🔥 LOAD START - Page', this.pageNumber, 'Size', this.pageSize);

        getRecords({
            objectName: this.objectName,
            fieldNames: fieldsToFetch,
            pageSize: this.pageSize,
            pageNumber: this.pageNumber,
            searchKey: this.searchKey,
            sortBy: this.sortBy,
            sortDirection: this.sortDirection
        })
        .then(res => {
            const loadTime = performance.now() - loadStart;
            console.log('⏱️ Apex response in', loadTime.toFixed(0), 'ms');
            
            if (res.error) {
                throw new Error(res.error);
            }

            this.hasMore = res.hasMore;
            // ✅ Capture last page when data ends
            if (!res.hasMore) {
                this.lastPage = this.pageNumber;
            }


            if (!res.records || res.records.length === 0) {
                console.log('⚠️ No records found');
                this.records = [];
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'No Results',
                        message: 'No WorkOrder records found',
                        variant: 'info'
                    })
                );
                return;
            }

            // ✅ Map records
            this.records = res.records.map(r => ({
                ...r,
                WorkOrderLink: '/' + r.Id
            }));

            console.log('✅ Data ready:', this.records.length, 'records in', (performance.now() - loadStart).toFixed(0), 'ms');

        })
        .catch(err => {
            console.error('❌ LOAD ERROR:', err);
            this.handleError(err);
        })
        .finally(() => {
            this.isLoading = false;
        });
    }

    handleSearch(event) {
        this.searchKey = event.target.value.trim();
        this.pageNumber = 1;
        this.lastPage = null;

        
        // ✅ Increase debounce to 500ms for heavy searches
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            console.log('🔍 Search:', this.searchKey);
            this.loadData();
        }, 500);
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value, 10);
        this.pageNumber = 1;
        this.lastPage = null;
        console.log('📄 Page size:', this.pageSize);
        this.loadData();
    }

    exportToCSV() {
        // ✅ Check if records are selected
        if (this.selectedRows && this.selectedRows.length > 0) {
            // Export SELECTED records only
            this.exportRecords(this.selectedRows, this.selectedRows.length);
        } else {
            // Export ALL current page records
            this.exportRecords(this.records, this.records.length);
        }
    }

    exportRecords(recordsToExport, recordCount) {
        if (!recordsToExport || recordsToExport.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Data',
                    message: 'No records to export',
                    variant: 'warning'
                })
            );
            return;
        }

        // Build CSV
        let csv = this.selectedColumns.join(',') + '\n';
        recordsToExport.forEach(r => {
            csv += this.selectedColumns.map(c => `"${r[c] || ''}"`).join(',') + '\n';
        });

        // Download
        const link = document.createElement('a');
        link.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
        link.download = 'WorkOrders.csv';
        link.click();

        // Show toast message
        const message = this.selectedRows && this.selectedRows.length > 0 
            ? `Downloaded ${recordCount} selected records`
            : `Downloaded ${recordCount} records`;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Export Successful',
                message,
                variant: 'success'
            })
        );
    }

    

    resetToDefault() {
        this.previousColumns = [...this.lastSavedColumns];
        this.selectedColumns = [...this.defaultColumns];
        this.draftSelectedColumns = [...this.defaultColumns];

        this.buildColumns();
        this.pageNumber = 1;
        this.totalRecords = 0;
        this.lastPage = null;
        this.loadData();

        saveUserColumnPreference({
            objectApiName: this.objectName,
            selectedFields: this.defaultColumns.join(',')
        });
    }

    undoReset() {
        if (!this.previousColumns.length) return;

        this.selectedColumns = [...this.previousColumns];
        this.draftSelectedColumns = [...this.previousColumns];
        this.lastSavedColumns = [...this.previousColumns];

        this.buildColumns();
        this.pageNumber = 1;
        this.loadData();

        saveUserColumnPreference({
            objectApiName: this.objectName,
            selectedFields: this.selectedColumns.join(',')
        });

        this.previousColumns = [];
    }

    get canUndoReset() {
        return this.previousColumns.length > 0;
    }

    handleDragStart(e) {
        this.draggedColumn = e.target.dataset.id;
    }

    allowDrop(e) {
        e.preventDefault();
    }

    handleDrop(e) {
        const target = e.target.dataset.id;
        if (!target || target === this.draggedColumn) return;

        const cols = [...this.draftSelectedColumns];
        cols.splice(cols.indexOf(this.draggedColumn), 1);
        cols.splice(cols.indexOf(target), 0, this.draggedColumn);
        this.draftSelectedColumns = cols;
    }

    handleDraftColumnChange(e) {
        this.draftSelectedColumns = e.detail.value;
    }

    handleApply() {
        if (this.isLoading) {
            console.warn('⚠️ Loading in progress');
            return;
        }

        const columnsChanged = 
            JSON.stringify(this.selectedColumns) !== 
            JSON.stringify(this.draftSelectedColumns);

        this.selectedColumns = [...this.draftSelectedColumns];
        this.lastSavedColumns = [...this.selectedColumns];
        this.pageNumber = 1;
        this.lastPage = null;

        this.buildColumns();

        if (columnsChanged) {
            this.loadData();
        }

        saveUserColumnPreference({
            objectApiName: this.objectName,
            selectedFields: this.selectedColumns.join(',')
        });

        this.showColumnSelector = false;
    }

    handleCancel() {
        this.draftSelectedColumns = [...this.selectedColumns];
        this.showColumnSelector = false;
    }

    previousPage() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.loadData();
        }
    }

    nextPage() {
        if (this.records.length >= this.pageSize) {
            this.pageNumber++;
            this.loadData();
        }
    }

    handleError(error) {
        console.error('🔴 ERROR:', error);

        let message = 'Something went wrong';
        if (error?.body?.message) {
            message = error.body.message;
        } else if (typeof error === 'string') {
            message = error;
        }

        this.error = message;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error'
            })
        );
    }

    handleSort(event) {
        let field = event.detail.fieldName;

        if (field === 'WorkOrderLink') {
            field = 'WorkOrderNumber';
        }

        this.sortBy = field;
        this.sortDirection = event.detail.sortDirection;
        this.pageNumber = 1;
        this.loadData();
    }

    handleFilterOperatorChange(event) {
        this.filterOperator = event.detail.value;
    }

    handleFilterChange(event) {
        const filterId = event.currentTarget.dataset.id;
        const fieldName = event.currentTarget.name;
        const value = event.detail.value;
        
        const filter = this.filters.find(f => f.id === filterId);
        if (filter) {
            filter[fieldName] = value;
        }
    }

    get disableNextBtn() {
        return this.records.length < this.pageSize || this.isLoading;
    }

    get disablePreviousBtn() {
        return this.pageNumber === 1 || this.isLoading;
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    exportSelectedCSV() {
        if (!this.selectedRows.length) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No rows selected',
                    message: 'Please select at least one record',
                    variant: 'warning'
                })
            );
            return;
        }

        let csv = this.selectedColumns.join(',') + '\n';
        this.selectedRows.forEach(r => {
            csv += this.selectedColumns
                .map(c => `"${r[c] || ''}"`)
                .join(',') + '\n';
        });

        const link = document.createElement('a');
        link.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
        link.download = 'Selected_WorkOrders.csv';
        link.click();
    }
    /* ---------- PAGINATION ---------- */
    get totalPages() {
    // If last page is known, always show it
    if (this.lastPage) {
        return this.lastPage;
    }

    // Otherwise, estimate progressively
    return this.hasMore
        ? this.pageNumber + 1
        : this.pageNumber;
}



    get disablePreviousBtn() {
    return this.pageNumber === 1 || this.isLoading;
}


    get disableNextBtn() {
    return !this.hasMore || this.isLoading;
}

    // ========== MODAL TOGGLE ==========
toggleImportExportModal() {
    this.showImportExportModal = !this.showImportExportModal;
    
    if (this.showImportExportModal) {
        this.isImportTab = true;
        this.isExportTab = false;
        this.resetImportForm();
    }
}

switchToImportTab() {
    this.isImportTab = true;
    this.isExportTab = false;
}

switchToExportTab() {
    this.isImportTab = false;
    this.isExportTab = true;
    this.updateExportStats();
}

/* ========== ADD THESE GETTERS TO YOUR CLASS ========== */

get importTabClass() {
    return this.isImportTab ? 'tab-btn active' : 'tab-btn';
}

get exportTabClass() {
    return this.isExportTab ? 'tab-btn active' : 'tab-btn';
}

get selectedRowCount() {
    return this.selectedRows ? this.selectedRows.length : 0;
}

get selectedColumnsCount() {
    return this.selectedColumns ? this.selectedColumns.length : 0;
}

    // ========== IMPORT FUNCTIONS ==========

    handleFileSelect(event) {
        const file = event.target.files[0];
        
        if (!file) {
            console.log('❌ No file selected');
            return;
        }

        if (!file.name.endsWith('.csv')) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid File',
                    message: 'Please upload a CSV file',
                    variant: 'error'
                })
            );
            return;
        }

        console.log('📁 File selected:', file.name, 'Size:', (file.size / 1024).toFixed(2), 'KB');

        // Read CSV file
        const reader = new FileReader();
        reader.onload = (e) => {
            const csvContent = e.target.result;
            this.parseCSV(csvContent);
        };
        reader.readAsText(file);
    }

    parseCSV(csvContent) {
        try {
            const lines = csvContent.trim().split('\n');
            
            if (lines.length < 2) {
                throw new Error('CSV file must contain header and at least one data row');
            }

            // Parse headers
            this.importPreviewHeaders = lines[0].split(',').map(h => h.trim());
            console.log('📋 Headers:', this.importPreviewHeaders);

            // Parse data rows
            this.importedCSVData = [];
            this.importPreviewRows = [];

            for (let i = 1; i < lines.length; i++) {
                const values = lines[i].split(',').map(v => v.trim());
                
                if (values.filter(v => v).length === 0) continue; // Skip empty rows

                const rowData = {};
                this.importPreviewHeaders.forEach((header, index) => {
                    rowData[header] = values[index] || '';
                });

                this.importedCSVData.push(rowData);

                // Add to preview (first 5 rows)
                if (i <= 5) {
                    this.importPreviewRows.push({
                        id: i,
                        data: values.map((v, idx) => ({
                            id: idx,
                            value: v
                        }))
                    });
                }
            }

            this.totalImportRows = this.importedCSVData.length;
            this.importFileSelected = true;

            console.log('✅ CSV Parsed:', this.totalImportRows, 'rows');

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'File Loaded',
                    message: `${this.totalImportRows} rows ready to import`,
                    variant: 'success'
                })
            );

        } catch (error) {
            console.error('❌ CSV Parse Error:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'File Error',
                    message: 'Error parsing CSV: ' + error.message,
                    variant: 'error'
                })
            );
        }
    }

    confirmImport() {
        if (this.importedCSVData.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Data',
                    message: 'No records to import',
                    variant: 'warning'
                })
            );
            return;
        }

        // Show confirmation
        if (confirm(`Import ${this.importedCSVData.length} records? This will create/update records in Salesforce.`)) {
            this.executeImport();
        }
    }

    async executeImport() {
        this.isLoading = true;

        try {
            console.log('📤 Starting import of', this.importedCSVData.length, 'records');

            // Call Apex to import data
            const result = await importWorkOrdersApex({
                csvData: JSON.stringify(this.importedCSVData),
                objectName: this.objectName
            });

            console.log('✅ Import Result:', result);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Import Successful',
                    message: `Created: ${result.created} | Updated: ${result.updated} | Failed: ${result.failed}`,
                    variant: 'success'
                })
            );

            // Refresh list
            this.pageNumber = 1;
            this.loadData();

            // Close modal
            this.toggleImportExportModal();

        } catch (error) {
            console.error('❌ Import Error:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Import Failed',
                    message: error.message,
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }

    resetImportForm() {
        this.importFileSelected = false;
        this.importPreviewHeaders = [];
        this.importPreviewRows = [];
        this.totalImportRows = 0;
        this.importedCSVData = [];
        
        const fileInput = document.querySelector('#fileInput');
        if (fileInput) {
            fileInput.value = '';
        }
    }

    // ========== EXPORT FUNCTIONS ==========

    handleExportTypeChange(event) {
        this.selectedExportType = event.target.value;
        this.updateExportStats();
    }

    handleIncludeIdsChange(event) {
        this.includeIds = event.target.checked;
    }

    updateExportStats() {
        this.noSelectedRows = !this.selectedRows || this.selectedRows.length === 0;

        if (this.selectedExportType === 'selected' && this.selectedRows && this.selectedRows.length > 0) {
            this.exportRecordCount = this.selectedRows.length;
        } else {
            this.exportRecordCount = this.records.length;
        }
    }

    exportAsCSV() {
        const recordsToExport = this.selectedExportType === 'selected' && this.selectedRows 
            ? this.selectedRows 
            : this.records;

        this.downloadCSVFile(recordsToExport, 'WorkOrders.csv');
    }

    exportAsExcel() {
        const recordsToExport = this.selectedExportType === 'selected' && this.selectedRows 
            ? this.selectedRows 
            : this.records;

        this.downloadExcelFile(recordsToExport, 'WorkOrders.csv');
    }

    exportAsPDF() {
        const recordsToExport = this.selectedExportType === 'selected' && this.selectedRows 
            ? this.selectedRows 
            : this.records;

        this.openPDFPage(recordsToExport, recordsToExport.length);
    }

    downloadCSVFile(recordsToExport, fileName) {
        let csv = '';

        // Add headers
        if (this.includeIds) {
            csv += 'Id,';
        }
        csv += this.selectedColumns.join(',') + '\n';

        // Add data
        recordsToExport.forEach(record => {
            if (this.includeIds) {
                csv += `"${record.Id}",`;
            }
            csv += this.selectedColumns.map(col => `"${record[col] || ''}"`).join(',') + '\n';
        });

        const link = document.createElement('a');
        link.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
        link.download = fileName;
        link.click();

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Export Successful',
                message: `Exported ${recordsToExport.length} records`,
                variant: 'success'
            })
        );

        this.toggleImportExportModal();
    }

    downloadExcelFile(recordsToExport, fileName) {
        const link = document.createElement('a');
        link.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(this.buildCSVContent(recordsToExport));
        link.download = fileName.replace('.csv', '.xlsx');
        link.click();

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Export Successful',
                message: `Exported ${recordsToExport.length} records`,
                variant: 'success'
            })
        );

        this.toggleImportExportModal();
    }

    buildCSVContent(recordsToExport) {
        let csv = '';

        if (this.includeIds) {
            csv += 'Id,';
        }
        csv += this.selectedColumns.join(',') + '\n';

        recordsToExport.forEach(record => {
            if (this.includeIds) {
                csv += `"${record.Id}",`;
            }
            csv += this.selectedColumns.map(col => `"${record[col] || ''}"`).join(',') + '\n';
        });

        return csv;
    }

            /* ========== REPLACE YOUR exportAsExcel() FUNCTION ========== */

        exportAsExcel() {
            const recordsToExport = this.selectedExportType === 'selected' && this.selectedRows 
                ? this.selectedRows 
                : this.records;

            this.downloadExcelFile(recordsToExport, 'WorkOrders.xls');
        }

        downloadExcelFile(recordsToExport, fileName) {
            try {
                console.log('📊 Starting Excel export with', recordsToExport.length, 'records');

                // ✅ Build HTML table (like the working example)
                let doc = '<table>';
                
                // Add column widths
                doc += '<colgroup>';
                if (this.includeIds) {
                    doc += '<col style="width:120px"/>';
                }
                this.selectedColumns.forEach(() => {
                    doc += '<col style="width:150px"/>';
                });
                doc += '</colgroup>';

                // ✅ Add styling for professional look
                doc += `<style>
                    table, th, td {
                        border: 1px solid #000000;
                        border-collapse: collapse;
                        text-align: left;
                        vertical-align: middle;
                    }
                    th {
                        background-color: #0070D2;
                        color: white;
                        font-weight: bold;
                        padding: 10px;
                        font-size: 12px;
                    }
                    td {
                        padding: 8px;
                        font-size: 11px;
                    }
                    tr:nth-child(even) {
                        background-color: #F5F5F5;
                    }
                    tr:nth-child(odd) {
                        background-color: #FFFFFF;
                    }
                </style>`;

                // ✅ Add header row
                doc += '<tr>';
                
                if (this.includeIds) {
                    doc += '<th>ID</th>';
                }
                
                this.selectedColumns.forEach(col => {
                    const label = this.getLabel(col);
                    doc += `<th>${this.escapeHtml(label)}</th>`;
                });
                
                doc += '</tr>';

                // ✅ Add data rows
                recordsToExport.forEach(record => {
                    doc += '<tr style="height: 25px;">';

                    if (this.includeIds) {
                        doc += `<td>${record.Id || ''}</td>`;
                    }

                    this.selectedColumns.forEach(col => {
                        const cellValue = record[col] || '';
                        doc += `<td>${this.escapeHtml(String(cellValue).substring(0, 500))}</td>`;
                    });

                    doc += '</tr>';
                });

                doc += '</table>';

                // ✅ Download using data URI (same as working example)
                const element = 'data:application/vnd.ms-excel;charset=utf-8,' + encodeURIComponent(doc);
                const downloadElement = document.createElement('a');
                downloadElement.href = element;
                downloadElement.download = fileName;
                document.body.appendChild(downloadElement);
                downloadElement.click();
                document.body.removeChild(downloadElement);

                console.log('✅ Excel export completed');

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Export Successful',
                        message: `Exported ${recordsToExport.length} records to Excel`,
                        variant: 'success'
                    })
                );

                this.toggleImportExportModal();

            } catch (error) {
                console.error('❌ Excel export error:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Export Failed',
                        message: 'Error exporting to Excel: ' + error.message,
                        variant: 'error'
                    })
                );
            }
        }

        // ✅ Helper function to escape HTML
        escapeHtml(text) {
            if (!text) return '';
            const map = {
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&#039;'
            };
            return String(text).replace(/[&<>"']/g, m => map[m]);
        }

    
}