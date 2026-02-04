/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 17-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   08-07-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement, track, wire } from 'lwc';
import getS3URL from '@salesforce/apex/PreviewS3ImageController.getS3URL';
import { refreshApex } from '@salesforce/apex';
export default class PreviewS3ImageComponent extends LightningElement {

    @api recordId;
    @api objectApiName;
    @track imageUrl;

    connectedCallback() {
        this.init();
    }

    init(){
        // Invoke the Apex Method to get the S3 URL
        console.log('Record ID: ' + this.recordId);
        console.log('Object Name: ' + this.objectApiName);
        getS3URL({recordId: this.recordId,sObjectName:this.objectApiName})
            .then(result => {
                this.imageUrl = result;
            })
            .catch(error => {
                console.error('Error fetching S3 URL:', error);
                this.imageUrl = null; // Reset imageUrl on error
            });
    }

    handleRefresh() {
        this.init(); 
    }

}