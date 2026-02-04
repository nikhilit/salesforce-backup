import { LightningElement, api } from 'lwc';
import QRCodeLib from '@salesforce/resourceUrl/asQrCode';
import { loadScript } from 'lightning/platformResourceLoader';
import asAgentIdentificationURL from "@salesforce/label/c.asAgentIdentificationURL";
import userId from '@salesforce/user/Id';

export default class AsAgentIdentification extends LightningElement {

   label = { asAgentIdentificationURL };
    
    inputText = this.label.asAgentIdentificationURL + userId;
    qrCodeInitialized = false;

    renderedCallback() {

        if (this.qrCodeInitialized) return;
        this.qrCodeInitialized = true;

        loadScript(this, QRCodeLib) 
            .then(() => {
                this.generateQRCode();
            })
            .catch(error => {
                console.error('Error loading QR code library', error);
            });
    }

    handleInput(event) {
        this.inputText = event.target.value;
        this.generateQRCode();
    }

    generateQRCode() {

        const qrContainer = this.template.querySelector('.qr-code-container');
        if (qrContainer) {
            qrContainer.innerHTML = ''; // Clear previous QR
            // eslint-disable-next-line no-undef
            new QRCode(qrContainer, {
                text: this.inputText,
                width: 200,
                height: 200
            });
        }
    }
}