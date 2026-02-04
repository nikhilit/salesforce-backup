import { LightningElement, api } from 'lwc';
import generateAndAttachPDF from '@salesforce/apex/WorkOrderPDFController.generateAndAttachPDF';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GeneratePDF extends LightningElement {
    @api recordIds;

    connectedCallback() {
        if (this.recordIds && this.recordIds.length > 0) {
            generateAndAttachPDF({ workOrderIds: this.recordIds })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'PDFs generated and attached to selected Work Orders.',
                            variant: 'success',
                        })
                    );
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error generating PDFs',
                            message: error.body.message,
                            variant: 'error',
                        })
                    );
                });
        }
    }
}