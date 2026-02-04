import { LightningElement, api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class PdfPreviewModal extends LightningModal {
    @api previewUrl;

    handleClose() {
        this.close();
    }
}