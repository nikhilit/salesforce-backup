import { LightningElement, api, track } from 'lwc';
import getListViewData from '@salesforce/apex/GenericListViewControllerNew.getListViewData';

export default class GenericListViewNew extends LightningElement {
    @api objectApiName = 'WorkOrder';   // configurable in App Builder
    @track columns = [];
    @track data = [];
    @track allData = [];
    @track searchKey = '';

    pageSize = 10;
    pageNumber = 0;

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        getListViewData({ objectApiName: this.objectApiName })
            .then(result => {
                this.columns = result.columns;
                this.allData = result.records;
                this.data = this.allData.slice(0, this.pageSize);
                this.pageNumber = 0;
            })
            .catch(error => {
                console.error('Error loading data: ', error);
            });
    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        if (this.searchKey) {
            const filtered = this.allData.filter(row =>
                Object.values(row).some(val =>
                    String(val).toLowerCase().includes(this.searchKey)
                )
            );
            this.data = filtered.slice(0, this.pageSize);
            this.pageNumber = 0;
        } else {
            this.data = this.allData.slice(0, this.pageSize);
            this.pageNumber = 0;
        }
    }

    handleNext() {
        const start = (this.pageNumber + 1) * this.pageSize;
        if (start < this.allData.length) {
            this.pageNumber++;
            this.data = this.allData.slice(start, start + this.pageSize);
        }
    }

    handlePrev() {
        if (this.pageNumber > 0) {
            this.pageNumber--;
            const start = this.pageNumber * this.pageSize;
            this.data = this.allData.slice(start, start + this.pageSize);
        }
    }

    // ✅ Disable buttons correctly (instead of === in HTML)
    get isPrevDisabled() {
        return this.pageNumber === 0;
    }

    get isNextDisabled() {
        return (this.pageNumber + 1) * this.pageSize >= this.allData.length;
    }

    handleAction(event) {
        const action = event.target.dataset.action;
        // Placeholder: Replace with your logic
        alert(`Action clicked: ${action}`);
    }
}