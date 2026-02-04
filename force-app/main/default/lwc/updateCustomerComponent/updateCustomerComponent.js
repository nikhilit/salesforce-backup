/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 19-05-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   07-05-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { RefreshEvent } from 'lightning/refresh';
import getAccountRec from '@salesforce/apex/UpdateCustomerController.getAccountRec';
export default class UpdateCustomerComponent extends NavigationMixin(LightningElement) {

    @api recordId; // Assuming you have a recordId to pass to the flow
    @api updateCustomer;
    actionSection = true;
    addressUpdate = false;
    meterNumberUpdate = false;
    contactUpdate = false;
    flowName;
    accountId;
    errorMessage = '';

    inputVariables = [];

    connectedCallback() {
        console.log('Record ID: ' + this.recordId);
        // this.init();
    }

    init() {
        getAccountRec({ recordId: this.recordId })
            .then(data => {
                console.log('Account ID: ' + JSON.stringify(data));
                if (data.AccountId) {
                    this.accountId = data.AccountId;
                    this.inputVariables = [
                        {
                            name: 'recordId',
                            type: 'String',
                            value: this.accountId
                        }
                    ];
                }
                //this.accountId = data;
            }).catch(error => {
                console.error('Error fetching account record: ', error);
            });
    }

    redirectToFlow(event) {
        this.actionSection = false;
        this.addressUpdate = false;
        this.meterNumberUpdate = false;
        this.contactUpdate = false;
        this.flowName = event.currentTarget.dataset.flow;
        let action = event.target.name;
        if(action=='addressUpdate'){
            this.addressUpdate=true;
        }else if(action=='meterNumberUpdate'){
            this.meterNumberUpdate=true;
        }else if(action=='contactUpdate'){
            this.contactUpdate=true;
        }
    }

    handleBack(){
        this.actionSection = true;
        this.addressUpdate = false;
        this.meterNumberUpdate = false;
        this.contactUpdate = false;
    }
}