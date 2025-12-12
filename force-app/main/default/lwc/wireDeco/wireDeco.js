// import { LightningElement, wire } from 'lwc';
// import searchData from '@salesforce/apex/AccountHelper.searchData';

// export default class WireDeco extends LightningElement {
//     searchKey = '';
//     data = [];
//     currentPage = 1;
//     pageSize = 10;  // Set page size (items per page)
//     totalPages = 1;  // Default page count
//     pagedData = [];  // Data for the current page
//     debounceTimeout;
//     isPrevDisabled = true;  // Disable the previous button on the first page
//     isNextDisabled = false; // Disable the next button when on the last page
//     columns = [
//         {
//             label: 'Name',
//             fieldName: 'Name',
//         },
//     ];

//     @wire(searchData, { searchKey: '$searchKey' })
//     wiredData({ data, error }) {
//         if (data) {
//             this.data = data;
//             this.totalPages = Math.ceil(this.data.length / this.pageSize);
//             this.updatePagedData();
//         } else if (error) {
//             console.error('Error fetching data:', error);
//         }
//     }

//     handleSearch(event) {
//         this.searchKey = event.target.value;

//         // Debounce logic to avoid multiple API calls
//         clearTimeout(this.debounceTimeout);
//         this.debounceTimeout = setTimeout(() => {
//             this.updatePagedData();
//         }, 300);  // 300ms debounce time
//     }

//     updatePagedData() {
//         // Calculate the start and end indices based on currentPage and pageSize
//         const startIdx = (this.currentPage - 1) * this.pageSize;
//         const endIdx = this.currentPage * this.pageSize;

//         this.pagedData = this.data.slice(startIdx, endIdx);

//         // Update button disable states
//         this.isPrevDisabled = this.currentPage === 1;
//         this.isNextDisabled = this.currentPage === this.totalPages;
//     }

//     handlePrevPage() {
//         if (this.currentPage > 1) {
//             this.currentPage--;
//             this.updatePagedData();
//         }
//     }

//     handleNextPage() {
//         if (this.currentPage < this.totalPages) {
//             this.currentPage++;
//             this.updatePagedData();
//         }
//     }

//     handlePageChange(event) {
//         const pageNumber = parseInt(event.target.value, 10);
//         if (pageNumber >= 1 && pageNumber <= this.totalPages) {
//             this.currentPage = pageNumber;
//             this.updatePagedData();
//         }
//     }

//     exportSearchedAccounts() {
//         let selectedRows = this.template.querySelector("lightning-datatable").getSelectedRows();
//         let downloadRecords = selectedRows.length > 0 ? selectedRows : this.pagedData;

//         // Convert to CSV and trigger download
//         let csvFile = this.convertArrayToCsv(downloadRecords);
//         this.createLinkForDownload(csvFile);
//     }

//     // Convert array to CSV
//     convertArrayToCsv(records) {
//         if (records.length === 0) return '';
        
//         const csvHeader = Object.keys(records[0]).join(',');
//         const csvBody = records.map(record => Object.values(record).join(','));
        
//         return csvHeader + '\n' + csvBody.join('\n');
//     }

//     // Create download link for CSV
//     createLinkForDownload(csvFile) {
//         const downloadLink = document.createElement("a");
//         downloadLink.href = "data:text/csv;charset=utf-8," + encodeURI(csvFile);
//         downloadLink.target = "_blank";
//         downloadLink.download = "SearchedAccounts.csv";
//         downloadLink.click();
//     }
// }



import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import searchData from '@salesforce/apex/AccountHelper.searchData';
import getRelatedContacts from '@salesforce/apex/AccountHelper.getRelatedContacts';

export default class WireDeco extends NavigationMixin(LightningElement) {
    searchKey = '';
    data = [];
    currentPage = 1;
    pageSize = 10;
    totalPages = 1;
    pagedData = [];
    debounceTimeout;
    isPrevDisabled = true;
    isNextDisabled = false;
    isLoading = false;
    selectedRows = []; // Stores selected rows
    isModalOpen = false;
    contacts = [];
    selectedAccountId;

    columns = [
        { label: 'Name', fieldName: 'Name', sortable: true },
        { label: 'Industry', fieldName: 'Industry', sortable: true },
        {
            type: 'button',
            label: 'Contacts',
            typeAttributes: {
                label: 'View Contacts',
                name: 'view_contacts',
                variant: 'brand',
            },
        },
    ];

    contactColumns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Email', fieldName: 'Email' },
        { label: 'Phone', fieldName: 'Phone' },
        {
            type: 'button',
            label: 'View',
            typeAttributes: {
                label: 'View',
                name: 'view_contact',
                variant: 'brand',
            },
        },
    ];

    @wire(searchData, { searchKey: '$searchKey' })
    wiredData({ data, error }) {
        this.isLoading = true;
        if (data) {
            this.data = data;
            this.totalPages = Math.ceil(this.data.length / this.pageSize);
            this.updatePagedData();
        } else if (error) {
            console.error('Error fetching data:', error);
            this.showToast('Error', error.body.message, 'error');
        }
        this.isLoading = false;
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
        clearTimeout(this.debounceTimeout);
        this.debounceTimeout = setTimeout(() => {
            this.updatePagedData();
        }, 300);
    }

    updatePagedData() {
        const startIdx = (this.currentPage - 1) * this.pageSize;
        const endIdx = this.currentPage * this.pageSize;
        this.pagedData = this.data.slice(startIdx, endIdx);
        this.isPrevDisabled = this.currentPage === 1;
        this.isNextDisabled = this.currentPage === this.totalPages;
    }

    handlePrevPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePagedData();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePagedData();
        }
    }

    handlePageChange(event) {
        const pageNumber = parseInt(event.target.value, 10);
        if (pageNumber >= 1 && pageNumber <= this.totalPages) {
            this.currentPage = pageNumber;
            this.updatePagedData();
        } else {
            this.showToast('Error', 'Invalid page number.', 'error');
        }
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortData(fieldName, sortDirection);
    }

    sortData(fieldName, sortDirection) {
        const sortedData = [...this.data].sort((a, b) => {
            const valueA = a[fieldName] || '';
            const valueB = b[fieldName] || '';
            return sortDirection === 'asc'
                ? valueA.localeCompare(valueB)
                : valueB.localeCompare(valueA);
        });
        this.data = sortedData;
        this.updatePagedData();
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        if (action.name === 'view_contacts') {
            this.selectedAccountId = row.Id;
            this.fetchContacts();
        }
    }

    handleRowSelection(event) {
        // Capture the selected rows
        this.selectedRows = event.detail.selectedRows;
        console.log('Selected Rows:', this.selectedRows);
    }

    fetchContacts() {
        this.isLoading = true;
        getRelatedContacts({ accountId: this.selectedAccountId })
            .then((data) => {
                this.contacts = data;
                this.isModalOpen = true;
            })
            .catch((error) => {
                console.error('Error fetching contacts:', error);
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleContactAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        if (action.name === 'view_contact') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    actionName: 'view',
                },
            });
        }
    }

    closeModal() {
        this.isModalOpen = false;
    }

    exportSelectedAsCsv() {
        let recordsToExport = [];

        // Check if any rows are selected
        if (this.selectedRows.length > 0) {
            recordsToExport = this.selectedRows; // Export selected rows
        } else {
            recordsToExport = this.pagedData; // Export all rows on the current page
        }

        // Check if there is data to export
        if (recordsToExport.length === 0) {
            this.showToast('Error', 'No data to export.', 'error');
            return;
        }

        // Convert the data to CSV and trigger download
        const csvFile = this.convertArrayToCsv(recordsToExport);
        this.createLinkForDownload(csvFile, 'Accounts.csv');
    }

    exportAllAsJson() {
        if (this.data.length === 0) {
            this.showToast('Error', 'No data to export.', 'error');
            return;
        }
        const jsonFile = JSON.stringify(this.data, null, 2);
        this.createLinkForDownload(jsonFile, 'AllAccounts.json', 'application/json');
    }

    convertArrayToCsv(records) {
        if (records.length === 0) return '';
        const csvHeader = Object.keys(records[0]).join(',');
        const csvBody = records.map(record => Object.values(record).join(','));
        return csvHeader + '\n' + csvBody.join('\n');
    }

    createLinkForDownload(data, fileName, mimeType = 'text/csv') {
        const downloadLink = document.createElement("a");
        downloadLink.href = `data:${mimeType};charset=utf-8,${encodeURI(data)}`;
        downloadLink.target = "_blank";
        downloadLink.download = fileName;
        downloadLink.click();
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}