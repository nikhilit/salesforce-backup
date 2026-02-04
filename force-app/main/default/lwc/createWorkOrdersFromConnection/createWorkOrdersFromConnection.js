import { LightningElement, api, track } from 'lwc';

export default class CreateWorkOrdersFromConnection extends LightningElement {
    @api connectionIds = [];

    @track showChild = false;

    connectedCallback() {
        console.log('Connection IDs received:', this.connectionIds);
        this.showChild = true; // always show child for now
    }
}