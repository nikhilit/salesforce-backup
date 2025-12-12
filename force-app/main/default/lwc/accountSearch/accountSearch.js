import { LightningElement, track } from 'lwc';

export default class AccountSearch extends LightningElement {
    @track searchText = '';
    searchAccountContactHander(event) {
        this.searchText = event.detail;
    }
}