import { LightningElement,track,wire,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import updateWorkOrderApprovalStatus from '@salesforce/apex/ContractorApprovalContr.updateWorkOrderApprovalStatus';


export default class ContractorApprovalComp extends LightningElement {


@track approvalStatusValue='';

@track load=false;

@track showSaveButton=true;

 @api reactiveValue = []; 

  @api selectedIds = [];

@track remark='';

@track showMessage;

@track showOnHoldField=false;

connectedCallback() {
     if (this.reactiveValue?.length > 0) {
            this.selectedIds = this.reactiveValue;
        console.log('inside connectedcallback selected ids values:', JSON.stringify(this.selectedIds));
        console.log('inside connectedcallback reactiveValue ids values:', JSON.stringify(this.reactiveValue));


        }
}


approvalStatusValueOption = [
        { label: 'Approved', value: 'Approved' },
        { label: 'Rejected', value: 'Rejected' },
        // { label: 'On Hold', value: 'On Hold' },

    ];

    handleApprovalValueChange(event){

        console.log('handleApprovalValueChange ::', event.target.value);

        this.approvalStatusValue = event.target.value;

        if(this.approvalStatusValue=='On Hold'){

            this.showOnHoldField=true;
        }
         if(this.approvalStatusValue !='On Hold'){

            this.showOnHoldField=false;
        }
    }

    handleChangeRemark(event){

        console.log('handleChangeRemark::', event.target.value);

        this.remark=event.target.value;
    }

handleSave(){

    console.log('inside handleSave method');

    this.load=true;

      if (!this.approvalStatusValue  || !this.remark) {
          //  this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
                 this.showMessage='Please Enter All Required Fields';

            this.load=false;
            return;
        }
        if(this.approvalStatusValue  && this.remark){
                          
               this.showMessage='';

        }

        updateWorkOrderApprovalStatus({ reactiveValue : this.reactiveValue, approvalStatusValue : this.approvalStatusValue, Remark : this.remark })

        .then( result => {

            console.log('Result ::', result);

            this.load=false;
            // this.showtoast('Success', 'Details Saved Successfully', 'Success');
            this.showSaveButton=false;
            this.showMessage='Details Saved Successfully';

        })
        .catch(error => {

            console.log('error ::', error);
            this.load=false;
        })
}

   showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
}