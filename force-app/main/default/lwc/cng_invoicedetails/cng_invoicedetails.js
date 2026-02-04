import { LightningElement, api, wire } from 'lwc';
import getInvoiceDetails from '@salesforce/apex/CNG_ProfileCardController.getInvoiceDetails';

export default class Cng_invoicedetails extends LightningElement {
    @api recordId;
    invoice;

    @wire(getInvoiceDetails, { invoiceId: '$recordId' })
    wiredInvoice({ data, error }) {
        if (data) {
            this.invoice = data;
        } else if (error) {
            console.error(error);
        }
    }
}