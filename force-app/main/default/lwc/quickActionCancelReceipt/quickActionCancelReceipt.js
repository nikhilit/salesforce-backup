import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";

export default class QuickActionCancelReceipt extends NavigationMixin(LightningElement) {

    // _recordId;
    // @api set recordId(value) {
    //     this._recordId = value;
    // }
    wireRecordId;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference ', currentPageReference);
            //it gets executed before the connected callback and avilable to use
            this.wireRecordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        this.dispatchEvent(new CloseActionScreenEvent());
        // this.navigateToVFPage();
    }

    // //Navigate to visualforce page
    navigateToVFPage() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: '/apex/receipt?id=' + this.wireRecordId
            }
        }).then(vfURL => {
        window.open(vfURL);
        });
    }
}