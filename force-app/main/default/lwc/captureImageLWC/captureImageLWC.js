/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 12-12-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   10-12-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class CaptureImageLWC extends NavigationMixin(LightningElement) {
    @api recordId;

    get inputVariables() {
        console.log('recordId:' + this.recordId);
        if (!this.recordId) return [];
        return [
            {
                name: 'recordId',
                type: 'String',
                value: '0WOfs000001Mtn9GAC'
            }
        ];
    }

    startFlow() {
        var url = 'com.salesforce.fieldservice://v1/sObject/'+this.recordId+'/quickaction/Capture_Photo';
        // window.open(url, '_self');
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": url
            }
        });
    }
}