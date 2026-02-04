import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
 
import getObjectList from '@salesforce/apex/UpdateRemarksController.getObjectList';
import uploadCSVBatch from '@salesforce/apex/UpdateRemarksController.uploadCSVBatch';
import uploadLargeCSVChunk from '@salesforce/apex/UpdateRemarksController.uploadLargeCSVChunk';
 
export default class UpdateReamrks extends NavigationMixin(LightningElement) {
  
    @api objectApiName;
    isSelectorDisabled = false;
    @track objectOptions = [];
    @track selectedObject;
    @track externalId = '';
    @track csvHeaders = [];
    @track csvPreview = [];
    @track failedRows = [];
    @track successRows = [];
    parsedCSV = [];
    @track searchKeyword = '';
    @track filteredPreview = []; 
    @track supportedFields = [];

    isReadyToUpload = false;
    @track showTable = false;
    @track isUploading = false;
    @track isParsing = false;
    uploadComplete = false;
    @track recordsUploaded = 0;
    @track totalRecords = 0;
    progressValue = 0;

    @track chunksCompleted = 0;
    @track totalChunks = 0;


    handleBackClick() {
        if (this.objectApiName) {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.objectApiName,
                    actionName: 'list'
                }
            });
        }
    }

    connectedCallback() {

        getObjectList().then((data) => {
            this.objectOptions = data;
        }).catch((err) => {
            this.showToast('Error', err.body.message, 'error');
        });

        if (this.objectApiName) {
            this.selectedObject = this.objectApiName;
            this.isSelectorDisabled = true;
        }
    }

    handleObjectChange(event) {
        if (!this.isSelectorDisabled) {
            this.selectedObject = event.detail.value;
        }
    }

    handleExternalIdChange(e) {
        this.externalId = e.target.value;
    }

    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            this.uploadedFileName = file.name;
            this.processFile(file);
        }
    }

    handleDragOver(event) {
        event.preventDefault();
        const dropArea = this.template.querySelector('.drag-container');
        dropArea.classList.add('drag-over');
    }

    handleDragLeave(event) {
        event.preventDefault();
        const dropArea = this.template.querySelector('.drag-container');
        dropArea.classList.remove('drag-over');
    }

    handleDrop(event) {
        event.preventDefault();
        const dropArea = this.template.querySelector('.drag-container');
        dropArea.classList.remove('drag-over');

        this.isParsing = true;

        const file = event.dataTransfer.files[0];
        if (file) {
            this.forwardFileToLightningInput(file);
        }
    }

    forwardFileToLightningInput(file) {
        // Manually call the existing file processing logic
        this.processFile(file);

        // Optional: reset the lightning-input to avoid confusion
        const fileInput = this.template.querySelector('lightning-input[type="file"]');
        if (fileInput) {
            fileInput.value = null; // allow re-uploading same file if needed
        }

        this.uploadedFileName = file.name;
    }

    processFile(file) {
        if (!file.name.endsWith('.csv')) {
            this.showToast('Invalid File', 'Please upload a valid .csv file.', 'error');
            return;
        }

        this.isParsing = true;
        this.uploadedFileName = file.name;

        const reader = new FileReader();
        reader.onload = () => {
            setTimeout(() => {
                this.parseCSV(reader.result);
            }, 0);
        };
        reader.readAsText(file);
    }

    parseCSV(csvText) {

        const MAX_ROWS = 100000;

        const parse = (text) => {
            const rows = [];
            let row = [];
            let current = '';
            let inQuotes = false;

            for (let i = 0; i < text.length; i++) {
                const char = text[i];
                const nextChar = text[i + 1];

                if (char === '"' && inQuotes && nextChar === '"') {
                    current += '"'; // escaped quote
                    i++; // skip next quote
                } else if (char === '"') {
                    inQuotes = !inQuotes;
                } else if (char === ',' && !inQuotes) {
                    row.push(current);
                    current = '';
                } else if ((char === '\n' || char === '\r') && !inQuotes) {
                    if (current || row.length > 0) row.push(current);
                    if (row.length > 0) rows.push(row);
                    row = [];
                    current = '';
                    if (char === '\r' && nextChar === '\n') i++; // handle CRLF
                } else {
                    current += char;
                }
            }

            if (current || row.length > 0) {
                row.push(current);
                rows.push(row);
            }

            return rows;
        };

        const allRows = parse(csvText);
        this.csvHeaders = allRows[0].map(h => h.replace(/^"|"$/g, '').trim());

        this.parsedCSV = allRows.slice(1).map((values) => {
            const row = {};
            this.csvHeaders.forEach((header, i) => {
                row[header] = values[i] ? values[i].replace(/^"|"$/g, '').trim() : '';
            });
            return row;
        });

        if (this.parsedCSV.length > MAX_ROWS) {
            this.showToast('Limit Exceeded', `Only the first ${MAX_ROWS} records will be processed.`, 'warning');
            this.parsedCSV = this.parsedCSV.slice(0, MAX_ROWS);
        }

        this.csvPreview = this.parsedCSV;
        this.filteredPreview = this.parsedCSV;

        this.failedRows = [];
        this.progressValue = 0;
        this.isReadyToUpload = true;
        this.showTable = true;
        this.isParsing = false;

    }

    get previewColumns() {
        return this.csvHeaders.map(header => ({
            label: header,
            fieldName: header
        }));
    }

    async handleUpload(){

        if (this.selectedObject === 'WorkOrder') {
            if (!this.validateWorkOrderCSVHeaders(this.csvHeaders)) {
                return;
            }
        }

        const total = this.parsedCSV.length;

        this.progressValue = 0;
        this.successRows = [];
        this.failedRows = [];
        this.isUploading = true;
        this.recordsUploaded = 0;
        this.totalRecords = total;
        this.supportedFields = [];


        let BATCH_SIZE = 500;
        
        if (total > 200) {

            const MAX_CHUNKS = 24;
            BATCH_SIZE = Math.ceil(total / MAX_CHUNKS);    

            this.chunksCompleted = 0;
            this.totalChunks = Math.ceil(total / BATCH_SIZE);

            
            for (let i = 0; i < total; i += BATCH_SIZE) {
                const chunk = this.parsedCSV.slice(i, i + BATCH_SIZE);

                uploadLargeCSVChunk({
                    records: chunk,
                    objectName: this.selectedObject,
                    externalIdField: this.externalId
                }).then(() => {

                    this.recordsUploaded += chunk.length;
                    this.progressValue = Math.floor((this.recordsUploaded / total) * 100);
                    this.chunksCompleted++;

                    if (this.chunksCompleted === this.totalChunks) {
                        this.isUploading = false;
                        this.uploadComplete = true;
                        this.showToast('Upload Complete', `Background upload completed.`, 'success');
                    }
                    
                }).catch(err => {

                    this.failedRows.push(...chunk.map(row => ({
                        ...row,
                        Error: err?.body?.message || 'Background upload failed.'
                    })));
 
                });
            }

            //this.isUploading = false;
            this.showToast('Upload Started', `Background upload started for ${total} records.`, 'info');

        } else {

            // Existing small-file upload logic (inline batch upload)
            let uploaded = 0;
            while (uploaded < total) {
                const chunk = this.parsedCSV.slice(uploaded, uploaded + BATCH_SIZE);
                try {
                    const res = await uploadCSVBatch({
                        objectName: this.selectedObject,
                        csvRecords: chunk
                        //externalIdField: this.externalId
                    });

                    if (res.errors?.length) {
                        this.failedRows.push(...res.errors);
                    }

                    if (res.successes?.length) {
                        this.successRows.push(...res.successes);
                    }

                    if (res.supportedFields) {
                        this.supportedFields = res.supportedFields;
                    }

                } catch (err) {
                    this.failedRows.push(...chunk.map(row => ({ ...row, Error: err.body.message })));
                }

                uploaded += chunk.length;
                this.recordsUploaded = uploaded;
                this.progressValue = Math.floor((uploaded / total) * 100);
            }

            this.isUploading = false;
            this.uploadComplete = true;
            this.recordsUploaded = 0;
            this.totalRecords = 0;

            if (!this.csvHeaders.includes('Id')) {
                this.csvHeaders = [...this.csvHeaders, 'Id'];
            }

            if(this.selectedObject === 'WorkOrder'){
                const extraFields = Object.values(this.supportedFields);

                // Merge unique new fields into csvHeaders
                extraFields.forEach(f => {
                    if (!this.csvHeaders.includes(f)) {
                        this.csvHeaders.push(f);
                    }
                });
                
                this.csvPreview = this.parsedCSV.map((row, idx) => {
                    const updatedRow = this.successRows[idx] || {};
                    return { ...row, ...updatedRow };
                });

                this.filteredPreview = this.csvPreview;
            }else{
                this.csvPreview = this.successRows;
                this.filteredPreview = this.successRows;
            }

            this.searchKeyword = '';

            const message = `Upload complete. Success: ${total - this.failedRows.length}, Failed: ${this.failedRows.length}`;
            this.showToast('Upload Complete', message, 'success');
        }
    }

    validateWorkOrderCSVHeaders(headers) {
        
        const requiredHeaders = ["BP Number", "WorkType Name"];

        const missingHeaders = requiredHeaders.filter(
            h => !headers.some(col => col.trim().toLowerCase() === h.toLowerCase())
        );

        if (missingHeaders.length > 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Missing Required Columns',
                    message: `The following required column(s) are missing: ${missingHeaders.join(", ")}`,
                    variant: 'error'
                })
            );
            return false;
        }
        return true;
    }

    downloadSuccess() {
        if (this.parsedCSV.length > 200) {
            this.showToast('Not Available', 'Upload Successful! Success file download is not available for bulk (asynchronous) uploads.', 'info');
            return;
        }

        if (!this.successRows.length) {
            this.showToast('No Data', 'There are no success records to download.', 'warning');
            return;
        }

        const headers = this.csvHeaders;
        let csv = headers.join(',') + '\n';

        this.successRows.forEach(row => {
            const line = headers.map(h => `"${(row[h] || '').replace(/"/g, '""')}"`).join(',');
            csv += line + '\n';
        });

        this.downloadCSV(csv, 'success.csv');
    }

    downloadErrors() {
        const headers = [...this.csvHeaders, 'Error'];
        let csvContent = headers.join(',') + '\n';

        this.failedRows.forEach(row => {
            const line = headers.map(h => {
                const cell = row[h] ? row[h].toString().replace(/"/g, '""') : '';
                return `"${cell}"`;
            }).join(',');
            csvContent += line + '\n';
        });

        this.downloadCSV(csvContent, 'failed.csv');
    }

    downloadCSV(csvContent, fileName){
         // Fallback-safe blob creation
        try {
            const blob = new Blob([csvContent], { type: 'text/plain' });

            // Create temporary anchor element
            const link = document.createElement('a');
            link.href = window.URL.createObjectURL(blob);
            link.download = fileName;

            // Append, click, and clean up
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            window.URL.revokeObjectURL(link.href);
        } catch (error) {
            this.showToast('Download Error', 'Unable to generate CSV file. Try copying data manually.', 'error');
            console.error('Blob creation/download error:', error);
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleSearch(event) {
        this.searchKeyword = event.target.value.toLowerCase();

        if (!this.searchKeyword) {
            this.filteredPreview = this.csvPreview;
            return;
        }

        this.filteredPreview = this.csvPreview.filter(row => {
            return Object.values(row).some(value =>
                (value || '').toString().toLowerCase().includes(this.searchKeyword)
            );
        });
    }


    get totalRowCount() {
        return this.csvPreview?.length || 0;
    }

    get filteredRowCount() {
        return this.filteredPreview?.length || 0;
    }

    handleReset() {
        this.externalId = '';
        this.csvHeaders = [];
        this.csvPreview = [];
        this.parsedCSV = [];
        this.failedRows = [];
        this.successRows = [];
        this.progressValue = 0;
        this.isReadyToUpload = false;
        this.showTable = false;
        this.isParsing = false;
        this.uploadedFileName = '';
        this.searchKeyword = '';
        this.filteredPreview = [];
        this.uploadComplete = false;

        // Clear file input value
        const fileInput = this.template.querySelector('lightning-input[type="file"]');
        if (fileInput) {
            fileInput.value = null;
        }

        // Remove drag highlight class (just in case)
        const dropArea = this.template.querySelector('.drag-container');
        if (dropArea) {
            dropArea.classList.remove('drag-over');
        }

        this.showToast('Reset', 'Form has been cleared.', 'info');
    }

    get isTableDisabled() {
        return this.csvPreview?.length > 1000;
    }

    get isSearchDisabled() {
        return this.parsedCSV?.length > 1000;
    }

    get tableDisabledClass() {
        return this.isTableDisabled ? 'datatable-disabled' : '';
    }

    get previewTableData() {
        // Limit datatable rows to 5000 even if more are loaded
        return this.filteredPreview?.slice(0, 1000) || [];
    }

    get isSuccessDownloadDisabled() {
        return this.parsedCSV.length > 5000 || this.successRows.length === 0;
    }

    get disableControls() {
        return this.isUploading || this.isParsing;
    }

    get isUploadDisabled() {
        return this.isUploading || this.isParsing || this.uploadComplete;
    }

    get uploadButtonLabel() {
        return this.uploadComplete ? 'Uploaded' : 'Upload';
    }
}