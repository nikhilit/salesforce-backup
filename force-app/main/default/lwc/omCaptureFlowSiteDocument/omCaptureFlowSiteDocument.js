import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class OmCaptureFlowSiteDocument extends NavigationMixin(LightningElement) {
    @api recordId;

    connectedCallback() {
        
    this.startFlow();

    }

    // get inputVariables() {
    //     console.log('recordId:' + this.recordId);

    //     if (!this.recordId) return [];
    //     return [
    //         {
    //             name: 'recordId',
    //             type: 'String',
    //             value: '0WOfs000001Mtn9GAC'
    //         }
    //     ];
    // }

    startFlow() {
        var url = 'com.salesforce.fieldservice://v1/sObject/'+this.recordId+'/quickaction/Upload_site_documentflow';
        // window.open(url, '_self');
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": url
            }
        });
    }
}