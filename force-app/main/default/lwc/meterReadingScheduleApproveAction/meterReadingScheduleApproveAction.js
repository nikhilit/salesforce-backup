/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 25-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   27-06-2025   Kartik Patkar, Appstrail   Initial Version
**/
import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';

// IMPORTS APEX CLASS
import startWorkOrderBatch from '@salesforce/apex/MeteringWorkOrderAllocationHelper.startWorkOrderApprovalBatch';
export default class MeterReadingScheduleApproveAction extends LightningElement {

    load = true;
    @api set recordId(value) {
        this.mrsId = value;
        this.init();
    }
    mrsId;

    get recordId() {
        return this.mrsId;
    }

    // connectedCallback() {
    //     this.init();
    // }

    init() {
        this.load = true;
        startWorkOrderBatch({ mrsId: this.mrsId })
            .then(result => {
                if (result != 'success') {
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
        this.dispatchEvent(new RefreshEvent());
        this.dispatchEvent(new CloseActionScreenEvent());
        // this.navigateToListView();
    }

    // navigateToListView() {
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__objectPage',
    //         attributes: {
    //             objectApiName: 'Meter_Reading_Order__c',
    //             actionName: 'list'
    //         },
    //         state: {
    //             filterName: 'All'
    //         }
    //     });
    // }

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