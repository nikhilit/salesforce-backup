import { LightningElement, wire } from 'lwc';

import getAccountData from '@salesforce/apex/AccountHelper.getAccountData'; 
const columns = [
    { label: 'Account Name ', fieldName: 'Name' },
    { label: 'Account Industry', fieldName: 'Industry'},
    { label: 'Account Rating', fieldName: 'Rating' },
];

export default class Wiredemo extends LightningElement {
    columns = columns;
    @wire(getAccountData) accounts;

}