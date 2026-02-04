/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 25-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-05-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// IMPORTS APEX CLASS
import startWorkOrderBatch from '@salesforce/apex/MeteringWorkOrderAllocationHelper.startWorkOrderBatch';
export default class MeteringWorkOrderAllocationAction extends NavigationMixin(LightningElement) {

    load = true;

    connectedCallback() {
        this.init();
    }

    init() {
        this.load = true;
        startWorkOrderBatch()
            .then(result => {
                if(result != 'success') {
                    this.showToastMessage('Error', 'Something went wrong.', 'error');
                    return;
                }
                this.load = false;
            })
            .catch(error => {
                this.load = false;
                this.showToastMessage('Error', error.body.message, 'error');
            });
    }

    handleGoBack() {
        this.navigateToListView();
    }

    navigateToListView() {
        // this[NavigationMixin.Navigate]({
        //     type: 'standard__objectPage',
        //     attributes: {
        //         objectApiName: 'Meter_Reading_Order__c',
        //         actionName: 'list'
        //     },
        //     state: {
        //         filterName: 'All'
        //     }
        // });
        window.history.go(-1);
    }

    /**
     * This function creates a new ShowToastEvent, sets the title, message, variant, and mode, and then
     * dispatches the event
     * @param title - The title of the toast message.
     * @param message - The message you want to display in the toast.
     * @param variant - The type of toast message. Valid values are error, warning, success, and info.
     * @param mode - This is the mode of the toast. It can be either 'dismissable','pester' or 'sticky'.
     */
    showToastMessage(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}