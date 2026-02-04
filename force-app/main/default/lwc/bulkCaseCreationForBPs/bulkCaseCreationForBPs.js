import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import XLSX from '@salesforce/resourceUrl/XLSX';

import insertCases from '@salesforce/apex/BulkCaseCreationForBPs.insertCases';

const MAX_PREVIEW_ROWS = 1000;
const PAGE_SIZE = 100;

export default class BulkCaseCreationForBPs extends LightningElement {
    @track fileName;
    @track parsedRows = [];

    @track isProcessing = false;
    @track readyToUpload = false;
    // @track isCompleted = false;
    // @track uploadResult;

    // pagination
    currentPage = 1;

    isXlsxLoaded = false;

    /* ===================== lifecycle ===================== */
    connectedCallback() {
        loadScript(this, XLSX)
            .then(() => (this.isXlsxLoaded = true))
            .catch(() => {
                this.showToast('Error', 'Failed to load Excel parser', 'error');
            });
    }

    /* ===================== getters ===================== */
    get totalRows() {
        return this.parsedRows.length;
    }

    get totalPages() {
        return Math.ceil(this.previewSource.length / PAGE_SIZE);
    }

    get hasNext() {
        return this.currentPage < this.totalPages;
    }

    get hasPrev() {
        return this.currentPage > 1;
    }

    get previewStart() {
        return this.previewSource.length
            ? (this.currentPage - 1) * PAGE_SIZE + 1
            : 0;
    }

    get previewEnd() {
        const end = this.currentPage * PAGE_SIZE;
        return end > this.previewSource.length
            ? this.previewSource.length
            : end;
    }

    get isPreviewLimited() {
        return this.parsedRows.length > MAX_PREVIEW_ROWS;
    }

    get previewSource() {
        return this.parsedRows.slice(0, MAX_PREVIEW_ROWS);
    }

    get previewData() {
        const start = (this.currentPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        return this.previewSource.slice(start, end);
    }

    get disablePrev() {
        return !this.hasPrev;
    }

    get disableNext() {
        return !this.hasNext;
    }

    get disableUpload() {
        return this.isProcessing || !this.parsedRows.length;
    }

    // get createdCaseColumns() {
    //     return [
    //         {
    //             label: 'Case Number',
    //             fieldName: 'url',
    //             type: 'url',
    //             typeAttributes: {
    //                 label: { fieldName: 'CaseNumber' },
    //                 target: '_blank'
    //             }
    //         },
    //         { label: 'Department', fieldName: 'Department__c' },
    //         { label: 'Category', fieldName: 'CategoryLabel' },
    //         { label: 'Type', fieldName: 'Type__c' },
    //         { label: 'Sub Type', fieldName: 'Sub_Type__c' },
    //         { label: 'Origin', fieldName: 'OriginLabel' },
    //         { label: 'Priority', fieldName: 'PriorityLabel' }
    //     ];
    // }



    get previewColumns() {
        return [
            { label: 'BP Number', fieldName: 'BP_Number__c' },
            { label: 'Department', fieldName: 'Department__c' },
            { label: 'Category', fieldName: 'Category__c' },
            { label: 'Type', fieldName: 'Type__c' },
            { label: 'Sub Type', fieldName: 'Sub_Type__c' },
            { label: 'Origin', fieldName: 'Origin' },
            { label: 'Priority', fieldName: 'Priority' }
        ];
    }

    // get createdCasesWithUrl() {
    //     if (!this.uploadResult?.createdCases) return [];

    //     return this.uploadResult.createdCases.map(c => ({
    //         ...c,
    //         url: `/lightning/r/Case/${c.Id}/view`
    //     }));
    // }

    get disableUpload() {
        return this.isProcessing || !this.parsedRows.length || this.isCompleted;
    }

    get totalPages() {
        return Math.max(
            1,
            Math.ceil(this.previewSource.length / PAGE_SIZE)
        );
    }



    // downloadSuccess() {
    //     if (!this.createdCasesWithUrl.length) {
    //         this.showToast('No Data', 'No success records to download', 'warning');
    //         return;
    //     }

    //     const headers = [
    //         'CaseNumber',
    //         'Id',
    //         'Department__c',
    //         'CategoryLabel',
    //         'Type__c',
    //         'Sub_Type__c',
    //         'OriginLabel',
    //         'PriorityLabel'
    //     ];

    //     let csv = headers.join(',') + '\n';

    //     this.createdCasesWithUrl.forEach(row => {
    //         csv += headers
    //             .map(h => `"${(row[h] || '').toString().replace(/"/g, '""')}"`)
    //             .join(',') + '\n';
    //     });

    //     this.downloadCSV(csv, 'success_cases.csv');
    // }


    // downloadFailed() {
    //     const rows = this.uploadResult?.failedRows || [];
    //     if (!rows.length) {
    //         this.showToast('No Data', 'No failed records to download', 'warning');
    //         return;
    //     }

    //     const headers = Object.keys(rows[0]);
    //     let csv = headers.join(',') + '\n';

    //     rows.forEach(row => {
    //         csv += headers
    //             .map(h => `"${(row[h] || '').toString().replace(/"/g, '""')}"`)
    //             .join(',') + '\n';
    //     });

    //     this.downloadCSV(csv, 'failed_cases.csv');
    // }



    // downloadCSV(csvContent, fileName) {
    //     try {
    //         const blob = new Blob([csvContent], { type: 'text/plain;charset=utf-8;' });
    //         const link = document.createElement('a');
    //         link.href = URL.createObjectURL(blob);
    //         link.download = fileName;
    //         link.style.display = 'none';

    //         document.body.appendChild(link);
    //         link.click();
    //         document.body.removeChild(link);

    //         setTimeout(() => {
    //             URL.revokeObjectURL(link.href);
    //         }, 100);
    //     } catch (error) {
    //         console.error('Blob download failed, using fallback', error);

    //         // 🔁 FALLBACK (critical)
    //         try {
    //             const dataUrl =
    //                 'data:text/plain;charset=utf-8,' +
    //                 encodeURIComponent(csvContent);

    //             const link = document.createElement('a');
    //             link.href = dataUrl;
    //             link.download = fileName;
    //             link.style.display = 'none';

    //             document.body.appendChild(link);
    //             link.click();
    //             document.body.removeChild(link);
    //         } catch (fallbackError) {
    //             console.error('Fallback download failed', fallbackError);
    //             this.showToast(
    //                 'Download Error',
    //                 'Unable to generate download file.',
    //                 'error'
    //             );
    //         }
    //     }
    // }






    /* ===================== pagination ===================== */
    handleNext() {
        if (this.hasNext) this.currentPage += 1;
    }

    handlePrev() {
        if (this.hasPrev) this.currentPage -= 1;
    }

    /* ===================== file handling ===================== */
    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        this.fileName = file.name;
        this.isProcessing = true;
        this.currentPage = 1;

        const ext = file.name.split('.').pop().toLowerCase();
        ext === 'csv' ? this.readCsvFile(file) : this.readExcelFile(file);
    }

    readCsvFile(file) {
        const reader = new FileReader();
        reader.onload = () => {
            try {
                const text = reader.result;
                const delimiter = text.includes('\t') ? '\t' : ',';
                const rows = text.split(/\r?\n/).filter(r => r.trim());

                const headers = rows[0].split(delimiter).map(h => h.trim());
                const data = rows.slice(1).map((line, index) => {
                    const values = line.split(delimiter);
                    const obj = { __rowKey: index + 1 };
                    headers.forEach((h, i) => (obj[h] = values[i]?.trim() || ''));
                    return obj;
                });


                this.parsedRows = data.filter(row => {
                    // Must have BP Number at minimum
                    return row.BP_Number__c &&
                        row.BP_Number__c.toString().trim().length > 0;
                });


                this.readyToUpload = true;
                this.isProcessing = false;

                this.showToast(
                    'Success',
                    `${this.parsedRows.length} records loaded`,
                    'success'
                );

            } catch (e) {
                this.failParse();
            }
        };
        reader.readAsText(file);
    }

    readExcelFile(file) {
        if (!this.isXlsxLoaded) {
            this.showToast('Error', 'Excel parser still loading', 'error');
            this.isProcessing = false;
            return;
        }

        const reader = new FileReader();
        reader.onload = e => {
            try {
                const wb = XLSX.read(new Uint8Array(e.target.result), { type: 'array' });
                const sheet = wb.Sheets[wb.SheetNames[0]];
                const json = XLSX.utils.sheet_to_json(sheet, { defval: '' });

                this.parsedRows = json
                    .filter(row =>
                        Object.values(row).some(
                            v => v && v.toString().trim().length > 0
                        )
                    )
                    .map((r, i) => ({ ...r, __rowKey: i + 1 }));

                this.readyToUpload = true;
            } catch {
                this.failParse();
            }
            this.isProcessing = false;
        };
        reader.readAsArrayBuffer(file);
    }

    failParse() {
        this.isProcessing = false;
        this.showToast('Error', 'Failed to parse file', 'error');
    }

    /* ===================== upload ===================== */
    async handleUpload() {
    this.isProcessing = true;

    try {
        const jobId = await insertCases({ rows: this.parsedRows });

        this.showToast(
            'Upload Started',
            `Cases are being created in background (Job Id: ${jobId})`,
            'success'
        );


        console.log('Batch Job Id:', jobId);

        // Reset UI
        this.parsedRows = [];
        this.fileName = null;
        this.readyToUpload = false;

    } catch (e) {
        console.error(e);
        this.showToast(
            'Error',
            e.body?.message || 'Failed to start batch job',
            'error'
        );
    } finally {
        this.isProcessing = false;
    }
}



    handleReset() {
        this.fileName = null;
        this.parsedRows = [];
        this.readyToUpload = false;
        this.isCompleted = false;
        this.uploadResult = null;
        this.currentPage = 1;
    }

    /* ===================== toast ===================== */
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}