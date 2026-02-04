import { LightningElement, track } from 'lwc';
import generateCommissionReport from '@salesforce/apex/AS_CommissionReportController.generateCommissionReport';

export default class AsCommissionReport extends LightningElement {
    @track startDate = '';
    @track endDate = '';
    @track batchLot = '';
    @track error = '';
    @track info = '';
    uploadedFileBase64 = ''; // NEW: store base64 of uploaded file

    handleStartDateChange(event) { this.startDate = event.target.value; }
    handleEndDateChange(event) { this.endDate = event.target.value; }
    handleBatchLotChange(event) { this.batchLot = event.target.value; }

    // NEW: Handle file input change
    handleFileChange(event) {
        this.error = '';
        const file = event.target.files[0];
        if (!file) {
            this.uploadedFileBase64 = '';
            return;
        }

        const reader = new FileReader();
        reader.onload = () => {
            const base64 = reader.result.split(',')[1]; // remove the prefix "data:*/*;base64,"
            this.uploadedFileBase64 = base64;
        };
        reader.onerror = () => {
            this.error = 'Error reading file.';
            this.uploadedFileBase64 = '';
        };
        reader.readAsDataURL(file);
    }

    validateInputs() {
        this.error = '';
        if ((!this.startDate || !this.endDate) && !this.batchLot && !this.uploadedFileBase64) {
            this.error = 'Provide either Start Date & End Date OR Batch Lot No. OR upload BP file.';
            return false;
        }
        if (this.startDate && this.endDate) {
            const sd = new Date(this.startDate);
            const ed = new Date(this.endDate);
            if (ed < sd) {
                this.error = 'End Date must be same or after Start Date.';
                return false;
            }
        }
        return true;
    }

    onGenerate() {
        this.error = '';
        this.info = '';
        if (!this.validateInputs()) return;

        const sd = this.startDate ? this.startDate : null;
        const ed = this.endDate ? this.endDate : null;
        const batch = this.batchLot ? this.batchLot.trim() : null;
        const fileContent = this.uploadedFileBase64 ? this.uploadedFileBase64 : null;

        generateCommissionReport({ startDate: sd, endDate: ed, batchLot: batch, fileContent: fileContent })
            .then(result => {
                if (!result || !result.base64Data) {
                    this.error = 'No file returned.';
                    return;
                }
                const fileName = result.fileName || 'Commission_Report.xls';
                const base64 = result.base64Data;
                const linkSource = 'data:application/vnd.ms-excel;base64,' + base64;
                const downloadLink = document.createElement('a');
                downloadLink.href = linkSource;
                downloadLink.download = fileName;
                document.body.appendChild(downloadLink);
                downloadLink.click();
                downloadLink.remove();
                this.info = 'Report generated: ' + fileName;
            })
            .catch(err => {
                console.error('Error generating commission report', err);
                this.error = (err && err.body && err.body.message) ? err.body.message : 'Error generating report. Check logs.';
            });
    }
}