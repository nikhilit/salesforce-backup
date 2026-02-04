import { LightningElement, wire } from 'lwc';
import getAccountData from '@salesforce/apex/AccountHelper.getAccountData'; 
const columns = [
    { label: 'Account Name ', fieldName: 'Name' },
    { label: 'Account Industry', fieldName: 'Industry'},
    { label: 'Account Rating', fieldName: 'Rating' },
];

export default class WireDecoratorProperty extends LightningElement {
    columns = columns;
    accounts; // Store account records
    filteredAccounts; // Store filtered account records

    // Fetch all accounts when the component is initialized
    @wire(getAccountData, { ratingFilter: null }) // Initially fetch all accounts
    accountsHandler({ data, error }) {
        if (data) { 
            // console.table("Data--------------------------->",data);
            this.accounts = data;
            this.filteredAccounts = data; // Initially, all accounts are displayed
        } else if (error) {
            console.error('Error:', error);
        }

    }

    

    // Handle button clicks
    handleHotButtonClick() {
        this.filterAccounts('Hot'); // Filter to show only hot rated accounts
    }

    handleWarmButtonClick() {
        this.filterAccounts('Warm'); // Filter to show only warm rated accounts
    }

    handleColdButtonClick() {
        this.filterAccounts('Cold'); // Filter to show only cold rated accounts
    }

    // Filter accounts based on rating
    filterAccounts(rating) {
        if (this.accounts) {
            this.filteredAccounts = this.accounts.filter(account => account.Rating === rating);
        }
    }
}