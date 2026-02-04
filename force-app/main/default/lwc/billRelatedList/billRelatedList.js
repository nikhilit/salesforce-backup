import { LightningElement, api, wire } from 'lwc';
import fetchSAPData from '@salesforce/apex/BillsCallout.fetchlastsixbills';
import { NavigationMixin } from 'lightning/navigation';
import getPdfFromAPI from '@salesforce/apex/BillsCallout.getPdfFromAPI';

export default class BillingTable extends NavigationMixin(LightningElement) {
    @api recordId;
    bpId
    billings;
    error;
    isLoading = false;

    sortBy = 'BUDAT';
    sortDirection = 'desc';

   @wire(fetchSAPData, { accountId: '$recordId' })
wiredBillings({ data, error }) {
    if (data) {
        console.log('inside data');

        // Clone before sorting to avoid mutating the proxy
        const clonedData = JSON.parse(JSON.stringify(data.sapData || []));

        // Sort by BUDAT (latest first)
        const sortedData = clonedData.sort((a, b) => {
            const dateA = new Date(a.BUDAT.replace(/-/g, '/')); 
            const dateB = new Date(b.BUDAT.replace(/-/g, '/')); 
            return dateB - dateA; // latest first
        });

        // Pick only the latest 6 entries
        this.billings = sortedData.slice(0, 6);

        this.error = undefined;
    } else if (error) {
        this.error = error.body?.message || error.message;
        this.billings = undefined;
        console.log('inside error', this.error);
    }
}



    handleSort(event) {
        const field = event.currentTarget.dataset.field;
        this.sortDirection =
            this.sortBy === field && this.sortDirection === 'asc'
                ? 'desc'
                : 'asc';
        this.sortBy = field;

        this.sortData();
    }

    sortData() {
        if (!this.sortBy) return;
        const isAsc = this.sortDirection === 'asc';
        this.billings = [...this.billings].sort((a, b) => {
            let valA = a[this.sortBy] || '';
            let valB = b[this.sortBy] || '';
            return isAsc ? valA.localeCompare(valB) : valB.localeCompare(valA);
        });
    }

    // Reactive icon for current sorted column
    get sortIcon() {
        return this.sortDirection === 'asc'
            ? 'utility:arrowup'
            : 'utility:arrowdown';
    }

    // Show icon only for the sorted column
    get isSortedByPrintDoc() { return this.sortBy === 'OPBEL'; }
    get isSortedByBillingDoc() { return this.sortBy === 'BELNR'; }
    get isSortedByDocDate() { return this.sortBy === 'BLDAT'; }
    get isSortedByPostingDate() { return this.sortBy === 'BUDAT'; }
    get isSortedByBillFrom() { return this.sortBy === 'BEGABRPE'; }
    get isSortedByBillTo() { return this.sortBy === 'ENDABRPE'; }
    get isSortedByDueAmount() { return this.sortBy === 'TOTAL_AMNT'; }
    get isSortedByDueDate() { return this.sortBy === 'FAEDN'; }

    // Navigate to Billing record
    navigateToBilling(event) {
        const billingId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: billingId,
                objectApiName: 'Billing__c',
                actionName: 'view'
            }
        });
    }

    // Get PDF logic
    getPdf(event) {
        const printDocNum = event.currentTarget.dataset.printdoc;
        this.isLoading = true;
        getPdfFromAPI({ billPrintNumber: printDocNum })
            .then((base64Pdf) => {
                this.isLoading = false;
                if (base64Pdf) {
                    const byteCharacters = atob(base64Pdf);
                    const byteNumbers = new Array(byteCharacters.length);
                    for (let i = 0; i < byteCharacters.length; i++) {
                        byteNumbers[i] = byteCharacters.charCodeAt(i);
                    }
                    const byteArray = new Uint8Array(byteNumbers);
                    const blob = new Blob([byteArray], { type: 'application/pdf' });
                    const blobUrl = URL.createObjectURL(blob);
                    window.open(blobUrl, '_blank');
                } else {
                    this.error = 'No PDF data returned';
                }
            })
            .catch((err) => {
                this.isLoading = false;
                this.error = 'Error fetching PDF: ' + err.body?.message;
            });
    }
}