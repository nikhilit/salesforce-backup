import { LightningElement,api, wire,track } from 'lwc';
import getAccounts from '@salesforce/apex/AccountHelper.getAccounts';

import { publish, MessageContext } from 'lightning/messageService';
import viewAccountContactsChannel from '@salesforce/messageChannel/viewAccountContactsChannel__c';


const COLUMNS = [
    { label: 'Id', fieldName: 'Id' },
    { label: 'Name', fieldName: 'Name'},
    { label: 'Actions', type:'button', typeAttributes:{
        label:'View Contacts',
        name:'View Contacts',
        title:'View Contacts',
        value:'View_Contacts',
    }},
];

export default class AccountSearchResult extends LightningElement {
    @api searchText='';
    columns=COLUMNS;
    @track accountsList = [];

    @wire(MessageContext)
    messageContext;


    @wire(getAccounts, { searchText: '$searchText' })
    wiredAccounts({ error, data }) {
        if (data) {
            console.log('Fetched Accounts:', data);
            this.accountsList = data;
        } else if (error) {
            console.error('Error:', error);
        }
    }

    rowActionHandler(event){
        if(event.detail.action.value=='View_Contacts'){
            const payload = { accountId: event.detail.row.Id,accountName: event.detail.row.Name };

            publish(this.messageContext, viewAccountContactsChannel, payload);
        }
    }

}