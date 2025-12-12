import { LightningElement, wire } from 'lwc';
import getContactList from '@salesforce/apex/ContactController.getContactList';

export default class ContactList extends LightningElement {

    contacts;
    @wire(getContactList) contacts;
    selectedContact;

    selectionHandler(event) {
        let selectedContactId = event.detail;

        // Accessing contacts data correctly
        this.selectedContact = this.contacts.data.find(
            (curritem) => curritem.Id === selectedContactId
        );
    }
}