import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import workorderwithdrawallocation from '@salesforce/apex/AicWorkOrderClosureController.workorderwithdrawallocation';

export default class AicRubberHoseWithdrawAllocation extends LightningElement {
    @api reactiveValue = []; 
    @api selectedIds = [];
    @track isLoading = false;
    @track successMessage = '';
    @track errorMessage ='';
    @track cancelMessage='';

    connectedCallback() {
        if (this.reactiveValue?.length > 0) {
            this.selectedIds = this.reactiveValue;
            console.log('inside connectedcallback selected ids values:', JSON.stringify(this.selectedIds));
        }
    }

    handleCancel() {
        const box = this.template.querySelector('.confirm-box');
        if (box) {
            box.style.display = 'none';
        }
      this.cancelMessage = 'Withdraw Allocation Cancelled';
    }

    handleconfirmbox(){
        const box = this.template.querySelector('.confirm-box');
        if (box) {
            box.style.display = 'none';
        }
    }

    handleWithdraw() {
        this.isLoading = true;
        this.successMessage = '';
        this.errorMessage='';

        workorderwithdrawallocation({ reactiveValue: this.reactiveValue })
            .then(result => {
                this.isLoading = false;

                // 🔥 Toast
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: result,
                        variant: 'success'
                    })
                );

                // 🔥 UI Success Message
                this.successMessage = result;

                // Optionally hide confirmation box
                this.handleconfirmbox();
            })
            .catch(error => {
                this.isLoading = false;
                 this.handleconfirmbox();
                this.errorMessage='Something went Wrong,Please Contact Your Admin';

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body ? error.body.message : 'Unknown error',
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            });
    }
}