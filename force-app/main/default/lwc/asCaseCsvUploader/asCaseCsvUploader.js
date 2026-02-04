// asCaseCsvUploader.js
import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import xlsxLib from '@salesforce/resourceUrl/XLSX';
import { NavigationMixin } from 'lightning/navigation';

import getObjectList from '@salesforce/apex/AS_CaseCSVUploaderController.getObjectList';
import uploadCSVBatch from '@salesforce/apex/AS_CaseCSVUploaderController.uploadCSVBatch';
import uploadLargeCSVChunk from '@salesforce/apex/AS_CaseCSVUploaderController.uploadLargeCSVChunk';

export default class AsCaseCsvUploader extends NavigationMixin(LightningElement) {
    /* ====== API / reactive properties ====== */
    @api objectApiName;

    @track objectOptions = [];
    @track selectedObject;
    @track csvHeaders = [];
    @track csvPreview = [];
    @track failedRows = [];
    @track successRows = [];
    @track searchKeyword = '';
    @track filteredPreview = [];

    @track isParsing = false;
    @track isUploading = false;
    @track isReadyToUpload = false;
    @track showTable = false;
    uploadComplete = false;

    @track recordsUploaded = 0;
    @track totalRecords = 0;
    progressValue = 0;

    @track chunksCompleted = 0;
    @track totalChunks = 0;

    @track uploadedFileName = '';

    parsedCSV = [];
    // selectors / control flags
    isSelectorDisabled = false;
    isXlsxLoaded = false;

    /* ====== Apex / static resource loading ====== */
    connectedCallback() {
        // Load SheetJS (xlsx) static resource
        if (!this.isXlsxLoaded) {
            loadScript(this, xlsxLib)
                .then(() => {
                    // SheetJS exposes global XLSX
                    if (window && window.XLSX) {
                        this.isXlsxLoaded = true;
                        // console.log('XLSX loaded');
                    } else {
                        console.warn('SheetJS loaded but XLSX global not found.');
                        this.showToast('Warning', 'Excel parser loaded but XLSX not found.', 'warning');
                    }
                })
                .catch(error => {
                    console.error('Failed to load SheetJS library', error);
                    this.showToast('Error', 'Unable to load Excel parser. Excel files will not be parsed.', 'error');
                });
        }

        // Fetch object picklist
        getObjectList()
            .then((data) => {
                this.objectOptions = data;
            })
            .catch((err) => {
                const msg = err?.body?.message || JSON.stringify(err);
                this.showToast('Error', msg, 'error');
            });

        if (this.objectApiName) {
            this.selectedObject = this.objectApiName;
            this.isSelectorDisabled = true;
        }
    }

    /* ====== UI helpers ====== */
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

    handleObjectChange(event) {
        if (!this.isSelectorDisabled) {
            this.selectedObject = event.detail.value;
        }
    }

    /* ====== File input / drag & drop ====== */
    handleFileChange(event) {
        const file = event.target.files && event.target.files[0];
        if (file) {
            this.uploadedFileName = file.name;
            this.processFile(file);
            // reset input so same file can be reselected if needed
            event.target.value = null;
        }
    }

    handleDragOver(event) {
        event.preventDefault();
        const dropArea = this.template.querySelector('.drag-container');
        if (dropArea) dropArea.classList.add('drag-over');
    }

    handleDragLeave(event) {
        event.preventDefault();
        const dropArea = this.template.querySelector('.drag-container');
        if (dropArea) dropArea.classList.remove('drag-over');
    }

    handleDrop(event) {
        event.preventDefault();
        const dropArea = this.template.querySelector('.drag-container');
        if (dropArea) dropArea.classList.remove('drag-over');

        const file = event.dataTransfer.files && event.dataTransfer.files[0];
        if (file) {
            this.uploadedFileName = file.name;
            this.processFile(file);
        }
    }

    /* ====== File processing / routing ====== */
    processFile(file) {
        const validExtensions = ['.csv', '.xlsx', '.xls'];
        const parts = file.name.split('.');
        const fileExtension = parts.length > 1 ? `.${parts.pop().toLowerCase()}` : '';

        if (!validExtensions.includes(fileExtension)) {
            this.showToast('Invalid File', 'Please upload a valid .csv, .xlsx, or .xls file.', 'error');
            return;
        }

        this.isParsing = true;
        this.uploadedFileName = file.name;
        this.csvHeaders = [];
        this.parsedCSV = [];
        this.csvPreview = [];
        this.filteredPreview = [];
        this.isReadyToUpload = false;
        this.showTable = false;
        this.failedRows = [];
        this.successRows = [];
        this.progressValue = 0;

        if (fileExtension === '.csv') {
            this.processCSVFile(file);
        } else {
            // Excel file
            if (!this.isXlsxLoaded) {
                // try to load again or warn
                loadScript(this, xlsxLib)
                    .then(() => {
                        this.isXlsxLoaded = !!(window && window.XLSX);
                        if (!this.isXlsxLoaded) {
                            this.showToast('Error', 'Excel parser not available. Please upload CSV instead.', 'error');
                            this.isParsing = false;
                            return;
                        }
                        this.parseExcelFile(file);
                    })
                    .catch(error => {
                        console.error('Failed to load SheetJS dynamically', error);
                        this.showToast('Error', 'Unable to parse Excel file. Try CSV instead.', 'error');
                        this.isParsing = false;
                    });
            } else {
                this.parseExcelFile(file);
            }
        }
    }

    /* ====== CSV parsing (robust custom parser) ====== */
    processCSVFile(file) {
        const reader = new FileReader();
        reader.onload = () => {
            // Defer parsing to avoid blocking UI
            setTimeout(() => {
                this.parseCSV(reader.result);
            }, 0);
        };
        reader.onerror = (e) => {
            console.error('FileReader error', e);
            this.showToast('Error', 'Failed to read CSV file.', 'error');
            this.isParsing = false;
        };
        reader.readAsText(file);
    }

    parseCSV(csvText) {
        try {
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
                        current += '"';
                        i++;
                    } else if (char === '"') {
                        inQuotes = !inQuotes;
                    } else if (char === ',' && !inQuotes) {
                        row.push(current);
                        current = '';
                    } else if ((char === '\n' || char === '\r') && !inQuotes) {
                        // Push last cell and row
                        if (current !== '' || row.length > 0) row.push(current);
                        if (row.length > 0) rows.push(row);
                        row = [];
                        current = '';
                        if (char === '\r' && nextChar === '\n') i++;
                    } else {
                        current += char;
                    }
                }

                if (current !== '' || row.length > 0) {
                    row.push(current);
                    rows.push(row);
                }

                return rows;
            };

            const allRows = parse(csvText);

            if (!allRows || allRows.length === 0) {
                this.showToast('Error', 'No data found in the CSV file.', 'error');
                this.isParsing = false;
                return;
            }

            // Trim quotes and whitespace for headers
            this.csvHeaders = allRows[0].map(h => (h || '').toString().replace(/^"|"$/g, '').trim());

            // Validate required headers
            if (!this.validateCaseCSVHeaders(this.csvHeaders)) {
                this.isParsing = false;
                return;
            }

            // Build objects
            this.parsedCSV = allRows.slice(1).map(values => {
                const obj = {};
                this.csvHeaders.forEach((header, idx) => {
                    obj[header] = values[idx] ? values[idx].toString().replace(/^"|"$/g, '').trim() : '';
                });
                return obj;
            }).filter(r => Object.values(r).some(v => v !== ''));

            if (this.parsedCSV.length === 0) {
                this.showToast('No Data', 'No valid records found in the CSV file.', 'warning');
                this.isParsing = false;
                return;
            }

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

            this.showToast('Success', `Successfully parsed ${this.parsedCSV.length} records from CSV file.`, 'success');
        } catch (err) {
            console.error('CSV parse error', err);
            this.showToast('Error', 'Failed to parse CSV file.', 'error');
            this.isParsing = false;
        }
    }

/* ====== Excel parsing (SheetJS) ====== */
parseExcelFile(file) {
    this.parseExcelFile = this.parseExcelFile.bind(this);

    try {
        const reader = new FileReader();

        reader.onload = (e) => {
            try {
                const arrayBuffer = e.target.result;
                const data = new Uint8Array(arrayBuffer);
                
                // Read workbook with date parsing enabled
                const workbook = window.XLSX.read(data, { 
                    type: 'array',
                    cellDates: true,  // This is key - tells SheetJS to parse dates as Date objects
                    cellText: true,
                    raw: true  // Keep raw values, we'll handle dates specially
                });

                if (!workbook || !workbook.SheetNames || workbook.SheetNames.length === 0) {
                    this.showToast('Error', 'No sheets found in Excel file.', 'error');
                    this.isParsing = false;
                    return;
                }

                const sheetName = workbook.SheetNames[0];
                const worksheet = workbook.Sheets[sheetName];
                
                // Convert to JSON with raw values to get Date objects
                const json = window.XLSX.utils.sheet_to_json(worksheet, { 
                    defval: '',
                    raw: true,  // Keep raw values including Date objects
                    dateNF: 'yyyy-mm-dd' // Tell SheetJS the date format we want
                });

                if (!json || json.length === 0) {
                    this.showToast('Error', 'No data found in Excel sheet.', 'error');
                    this.isParsing = false;
                    return;
                }

                this.csvHeaders = Object.keys(json[0]);

                if (!this.validateCaseCSVHeaders(this.csvHeaders)) {
                    this.isParsing = false;
                    return;
                }

                // Process rows with strict date validation
                this.parsedCSV = [];
                const dateValidationErrors = [];

                json.forEach((rowObj, index) => {
                    const normalized = {};
                    let hasData = false;
                    let rowHasError = false;

                    this.csvHeaders.forEach(h => {
                        let value = rowObj[h];
                        
                        // Handle different value types
                        if (value instanceof Date) {
                            // This is a proper Date object from Excel
                            // value = this.formatDateForSalesforce(value);
                            if (this.isTimeHeader(h)) {
                                value = this.formatTimeForSalesforce(value);
                            }
                            // 📅 DATE fields next
                            else if (this.isDateHeader(h)) {
                                value = this.formatDateForSalesforce(value);
                            }
                        } else if (value === null || value === undefined) {
                            value = '';
                        } else {
                            value = String(value).trim();
                        }
                        
                        // Validate date fields - only accept proper dates that were converted from Date objects
                        if (this.isDateHeader(h) && value !== '') {
                            // Check if the value came from a proper Date object or is in correct format
                            const isValidDate = this.isValidSalesforceDate(value);
                            if (!isValidDate) {
                                dateValidationErrors.push(`Row ${index + 2}: "${h}" has invalid date "${rowObj[h]}". Use proper date format only.`);
                                rowHasError = true;
                                value = ''; // Clear invalid date
                            }
                        }

                        if (this.isTimeHeader(h) && value !== '') {
                            if (!this.isValidSalesforceTime(value)) {
                                dateValidationErrors.push(
                                    `Row ${index + 2}: "${h}" has invalid time "${value}". Use HH:mm:ss`
                                );
                                rowHasError = true;
                                value = '';
                            }
                        }

                        
                        normalized[h] = value;
                        if (value !== '') hasData = true;
                    });

                    if (!rowHasError && hasData) {
                        this.parsedCSV.push(normalized);
                    }
                });

                // Show date validation errors
                if (dateValidationErrors.length > 0) {
                    const errorMessage = dateValidationErrors.slice(0, 5).join('\n');
                    if (dateValidationErrors.length > 5) {
                        errorMessage += `\n...and ${dateValidationErrors.length - 5} more errors`;
                    }
                    this.showToast('Date Format Errors', errorMessage, 'error');
                    
                    if (this.parsedCSV.length === 0) {
                        this.isParsing = false;
                        return;
                    }
                }

                if (this.parsedCSV.length === 0) {
                    this.showToast('No Data', 'No valid records found in the Excel file.', 'warning');
                    this.isParsing = false;
                    return;
                }

                this.csvPreview = this.parsedCSV;
                this.filteredPreview = this.parsedCSV;
                this.isReadyToUpload = true;
                this.showTable = true;
                this.isParsing = false;

                const successMsg = `Successfully parsed ${this.parsedCSV.length} rows from Excel file.`;
                if (dateValidationErrors.length > 0) {
                    this.showToast('Partial Success', `${successMsg} ${dateValidationErrors.length} rows had date format errors.`, 'warning');
                } else {
                    this.showToast('Success', successMsg, 'success');
                }

            } catch (innerErr) {
                console.error('Excel parse error', innerErr);
                this.showToast('Error', 'Failed to parse Excel file contents.', 'error');
                this.isParsing = false;
            }
        };

        reader.onerror = (e) => {
            console.error('FileReader error for Excel', e);
            this.showToast('Error', 'Failed to read Excel file.', 'error');
            this.isParsing = false;
        };

        reader.readAsArrayBuffer(file);
    } catch (err) {
        console.error('parseExcelFile error', err);
        this.showToast('Error', 'Unable to parse Excel file.', 'error');
        this.isParsing = false;
    }
}

/* ====== Date Validation Methods ====== */
isDateHeader(header) {
    const dateHeaders = ['Planned_Start_date__c', 'Planned_End_Date__c'];
    return dateHeaders.some(dateHeader => 
        header.toLowerCase() === dateHeader.toLowerCase()
    );
}

isValidSalesforceDate(dateString) {
    // Only accept YYYY-MM-DD format
    const regex = /^\d{4}-\d{2}-\d{2}$/;
    if (!regex.test(dateString)) {
        return false;
    }

    // Validate it's a real date
    const parts = dateString.split('-');
    const year = parseInt(parts[0], 10);
    const month = parseInt(parts[1], 10);
    const day = parseInt(parts[2], 10);

    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;

    const date = new Date(year, month - 1, day);
    return date.getFullYear() === year && 
           date.getMonth() === month - 1 && 
           date.getDate() === day;
}

formatDateForSalesforce(date) {
    // Format JavaScript Date object as YYYY-MM-DD
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}
/* ====== Date Helper Methods ====== */
// isDateHeader(header) {
//     const dateHeaders = ['Planned_Start_date__c', 'Planned_End_Date__c', 'Date', 'Start_Date', 'End_Date'];
//     return dateHeaders.some(dateHeader => 
//         header.toLowerCase().includes(dateHeader.toLowerCase())
//     );
// }

excelSerialToDate(serial) {
    // Excel date serial number to JavaScript Date conversion
    // Excel's epoch is January 1, 1900
    const excelEpoch = new Date(1900, 0, 1);
    // Adjust for Excel's leap year bug (it considers 1900 a leap year)
    const days = serial - (serial > 60 ? 2 : 1);
    return new Date(excelEpoch.getTime() + days * 24 * 60 * 60 * 1000);
}

// formatDateForSalesforce(date) {
//     // Format date as YYYY-MM-DD for Salesforce
//     const year = date.getFullYear();
//     const month = String(date.getMonth() + 1).padStart(2, '0');
//     const day = String(date.getDate()).padStart(2, '0');
//     return `${year}-${month}-${day}`;
// }

isTimeHeader(header) {
    const timeHeaders = [
        'Planned_Start_Time__c',
        'Planned_End_Time__c'
    ];
    return timeHeaders.some(h => header.toLowerCase() === h.toLowerCase());
}

isValidSalesforceTime(timeString) {
    // HH:mm:ss
    const regex = /^([01]\d|2[0-3]):[0-5]\d:[0-5]\d$/;
    return regex.test(timeString);
}

    /* ====== Header validation ====== */
    validateCaseCSVHeaders(headers) {
        const requiredHeaders = ["Docket_Number__c"];
        const missing = requiredHeaders.filter(r => !headers.some(h => (h || '').toString().trim().toLowerCase() === r.toLowerCase()));
        if (missing.length > 0) {
            this.showToast('Missing Required Column', `The following required column is missing: ${missing.join(', ')}. Required column: Docket_Number__c. Optional columns: Standard_Remarks__c, Planned_Start_date__c, Planned_End_Date__c, Planned_Start_Time__c, Planned_End_Time__c, Status`, 'error');
            return false;
        }
        return true;
    }

    /* ====== Datatable helpers ====== */
    get previewColumns() {
        return this.csvHeaders
            .filter(header => header !== 'Id')
            .map(header => ({ label: header, fieldName: header }));
    }

    get previewTableData() {
        const data = this.filteredPreview?.slice(0, 1000) || [];
        return data.map(row => {
            const filteredRow = {};
            Object.keys(row).forEach(k => {
                if (k !== 'Id') filteredRow[k] = row[k];
            });
            return filteredRow;
        });
    }

    formatTimeForSalesforce(date) {
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const seconds = String(date.getSeconds()).padStart(2, '0');
        return `${hours}:${minutes}:${seconds}`;
    }


    /* ====== Search ====== */
    handleSearch(event) {
        this.searchKeyword = event.target.value ? event.target.value.toLowerCase() : '';
        if (!this.searchKeyword) {
            this.filteredPreview = this.csvPreview;
            return;
        }
        this.filteredPreview = this.csvPreview.filter(row => {
            return Object.values(row).some(v => (v || '').toString().toLowerCase().includes(this.searchKeyword));
        });
    }

    get totalRowCount() {
        return this.csvPreview?.length || 0;
    }

    get filteredRowCount() {
        return this.filteredPreview?.length || 0;
    }

    /* ====== Upload logic (batch + chunked async) ====== */
    async handleUpload() {
        if (!this.validateCaseCSVHeaders(this.csvHeaders)) return;

        const total = this.parsedCSV.length;
        this.progressValue = 0;
        this.successRows = [];
        this.failedRows = [];
        this.isUploading = true;
        this.recordsUploaded = 0;
        this.totalRecords = total;
        this.chunksCompleted = 0;
        this.totalChunks = 0;

        let BATCH_SIZE = 50;

        try {
            if (total > 5000) {
                // Use background chunk uploads (uploadLargeCSVChunk)
                const MAX_CHUNKS = 24;
                BATCH_SIZE = Math.ceil(total / MAX_CHUNKS);
                this.totalChunks = Math.ceil(total / BATCH_SIZE);
                const uploadPromises = [];

                for (let i = 0; i < total; i += BATCH_SIZE) {
                    const chunk = this.parsedCSV.slice(i, i + BATCH_SIZE);
                    const uploadPromise = uploadLargeCSVChunk({
                        records: chunk,
                        objectName: this.selectedObject
                    })
                    .then(() => {
                        this.recordsUploaded += chunk.length;
                        this.progressValue = Math.floor((this.recordsUploaded / total) * 100);
                        this.chunksCompleted++;
                        // no per-chunk successRows available (background)
                        if (this.chunksCompleted === this.totalChunks) {
                            this.isUploading = false;
                            this.uploadComplete = true;
                            this.showToast('Upload Complete', `Background upload completed for ${total} records.`, 'success');
                        }
                    })
                    .catch(error => {
                        console.error('Chunk upload failed:', error);
                        const failedChunk = chunk.map(row => ({ ...row, Error: error?.body?.message || 'Background upload failed' }));
                        this.failedRows = [...this.failedRows, ...failedChunk];
                        this.chunksCompleted++;
                        this.recordsUploaded += chunk.length;
                        this.progressValue = Math.floor((this.recordsUploaded / total) * 100);
                        if (this.chunksCompleted === this.totalChunks) {
                            this.isUploading = false;
                            this.uploadComplete = true;
                            const successCount = total - this.failedRows.length;
                            this.showToast('Upload Complete', `Upload finished. Success: ${successCount}, Failed: ${this.failedRows.length}`, 'warning');
                        }
                    });

                    uploadPromises.push(uploadPromise);
                }

                // Fire-and-inform; still track promises
                Promise.allSettled(uploadPromises).then(() => {
                    // console.log('All chunk uploads settled');
                });

                this.showToast('Upload Started', `Background upload started for ${total} records across ${this.totalChunks} chunks.`, 'info');

            } else {
                // synchronous-ish batch upload using uploadCSVBatch
                let uploaded = 0;
                while (uploaded < total) {
                    const chunk = this.parsedCSV.slice(uploaded, uploaded + BATCH_SIZE);
                    try {
                        const res = await uploadCSVBatch({
                            objectName: this.selectedObject,
                            csvRecords: chunk
                        });

                        if (res.errors?.length) {
                            this.failedRows.push(...res.errors);
                        }

                        if (res.successes?.length) {
                            this.successRows.push(...res.successes);
                        }
                    } catch (err) {
                        const msg = err?.body?.message || JSON.stringify(err);
                        this.failedRows.push(...chunk.map(row => ({ ...row, Error: msg })));
                    }

                    uploaded += chunk.length;
                    this.recordsUploaded = uploaded;
                    this.progressValue = Math.floor((uploaded / total) * 100);
                }

                this.isUploading = false;
                this.uploadComplete = true;
                this.recordsUploaded = 0;
                this.totalRecords = 0;

                // Update preview with successRows (filter out Id)
                this.csvPreview = this.successRows.map(r => {
                    const obj = {};
                    Object.keys(r).forEach(k => {
                        if (k !== 'Id') obj[k] = r[k];
                    });
                    return obj;
                });
                this.filteredPreview = this.csvPreview;
                this.searchKeyword = '';

                const message = `Upload complete. Success: ${total - this.failedRows.length}, Failed: ${this.failedRows.length}`;
                this.showToast('Upload Complete', message, 'success');
            }
        } catch (finalErr) {
            console.error('Upload error', finalErr);
            this.showToast('Error', 'An unexpected error occurred during upload.', 'error');
            this.isUploading = false;
        }
    }

    /* ====== Downloads ====== */
    downloadSuccess() {
        if (this.parsedCSV.length > 200) {
            this.showToast('Not Available', 'Upload Successful! Success file download is not available for bulk (asynchronous) uploads.', 'info');
            return;
        }

        if (!this.successRows.length) {
            this.showToast('No Data', 'There are no success records to download.', 'warning');
            return;
        }

        const headers = this.csvHeaders.filter(h => h !== 'Id');
        let csv = headers.join(',') + '\n';
        this.successRows.forEach(row => {
            const line = headers.map(h => `"${(row[h] || '').toString().replace(/"/g, '""')}"`).join(',');
            csv += line + '\n';
        });
        this.downloadCSV(csv, 'success.csv');
    }

    downloadErrors() {
        const headers = [...this.csvHeaders.filter(h => h !== 'Id'), 'Error'];
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

    downloadCSV(csvContent, fileName) {
        try {
            const blob = new Blob([csvContent], { type: 'text/plain' });
            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = fileName;
            link.style.display = 'none';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            setTimeout(() => {
                URL.revokeObjectURL(link.href);
            }, 100);
        } catch (error) {
            console.error('Blob creation/download error:', error);
            try {
                const dataUrl = 'data:text/plain;charset=utf-8,' + encodeURIComponent(csvContent);
                const link = document.createElement('a');
                link.href = dataUrl;
                link.download = fileName;
                link.style.display = 'none';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            } catch (fallbackError) {
                this.showToast('Download Error', 'Unable to generate download file. Try copying data manually.', 'error');
                console.error('Fallback download error:', fallbackError);
            }
        }
    }

    /* ====== Utility / UI getters ====== */
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    handleReset() {
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
        this.chunksCompleted = 0;
        this.totalChunks = 0;

        const fileInput = this.template.querySelector('lightning-input[type="file"]');
        if (fileInput) fileInput.value = null;

        const dropArea = this.template.querySelector('.drag-container');
        if (dropArea) dropArea.classList.remove('drag-over');

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