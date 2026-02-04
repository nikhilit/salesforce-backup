import { LightningElement, api, track } from 'lwc';
import updateWorkOrderApprovalStatus
    from '@salesforce/apex/AICApprovalAfsContr.updateWorkOrderApprovalStatus';

export default class AicApprovalAfsComp extends LightningElement {

    @api reactiveValue = [];
    @api selectedIds = [];

    @track approvalStatusValue = '';
    @track remark = '';
    @track load = false;
    @track showSaveButton = true;
    @track showMessage = '';


    connectedCallback() {
     if (this.reactiveValue?.length > 0) {
            this.selectedIds = this.reactiveValue;
        console.log('inside connectedcallback selected ids values:', JSON.stringify(this.selectedIds));
        console.log('inside connectedcallback reactiveValue ids values:', JSON.stringify(this.reactiveValue));


        }
}


    approvalStatusValueOption = [
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' }
    ];

    handleApprovalValueChange(event) {

        console.log('handleApprovalValueChange ::', event.target.value);
        this.approvalStatusValue = event.target.value;
    }

    handleChangeRemark(event) {
        console.log('handleChangeRemark ::', event.target.value);
        this.remark = event.target.value;
    }

    handleSave() {

        console.log('inside handleSave method');
        this.load = true;

        if (!this.approvalStatusValue || !this.remark) {
            this.showMessage = 'Please enter all required fields';
            this.load = false;
            return;
        }

        this.showMessage = '';

        updateWorkOrderApprovalStatus({
            reactiveValue: this.reactiveValue,
            approvalStatusValue: this.approvalStatusValue,
            remark: this.remark
        })
        .then(() => {
            this.load = false;
            this.showSaveButton = false;
            this.showMessage = 'Details saved successfully';
        })
        .catch(error => {
            console.error(error);
            this.load = false;
        });
    }
}