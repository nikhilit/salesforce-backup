import { LightningElement,track,wire,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateWorkOrderApprovalStatus from '@salesforce/apex/AicWorkOrderClosureController.updateWorkOrderApprovalStatus';

export default class AicWorkorderClosureComp extends LightningElement {

// @track workorderStatusValue='';
@track appointmentStatusValue='';
@track remark='';

@track load=false;
@track showSaveButton=true;

 @api reactiveValue = []; 

  @api selectedIds = [];

@track onHoldReason='';

@track showMessage;

//@track showOnHoldField=false;

connectedCallback() {

     this.appointmentStatusValue = 'Completed';

     if (this.reactiveValue?.length > 0) {
            this.selectedIds = this.reactiveValue;
        console.log('inside connectedcallback selected ids values:', JSON.stringify(this.selectedIds));
        console.log('inside connectedcallback reactiveValue ids values:', JSON.stringify(this.reactiveValue));


        }
}

appointmentstatusoptions=[

{label:'Unattempted',value:'Unattempted'},
{label:'Completed',value:'Completed'},
{label:'Incomplete',value:'Incomplete'},
{label:'In Progress',value:'In Progress'}
];

// workorderstatusoptions = [
//     { label: 'New', value: 'New' },
//     { label: 'In Progress', value: 'In Progress' },
//     { label: 'On Hold', value: 'On Hold' },
//     { label: 'Completed', value: 'Completed' },
//     { label: 'Closed', value: 'Closed' },
//     { label: 'Cannot Complete', value: 'Cannot Complete' },
//     { label: 'Canceled', value: 'Canceled' },
//     { label: 'Customer Unavailable', value: 'Customer Unavailable' }
// ];


    handleAppointmentValueChange(event){

        console.log('handleApprovalValueChange ::', event.target.value);

        this.appointmentStatusValue = event.target.value;
    }

    // handleworkorderstatusValueChange(event){

    //     console.log('handleApprovalValueChange ::', event.target.value);

    //     this.workorderStatusValue = event.target.value;
    // }


    handleChangeRemark(event){
        console.log('handleChangeRemark ::', event.target.value);
        this.remark=event.target.value;
    }

handleSave(){

    console.log('inside handleSave method');
    this.load=true;
      if (!this.appointmentStatusValue  ||  !this.remark) {
                 this.showMessage='Please Enter All Required Fields';

            this.load=false;
            return;
        }
        if(this.appointmentStatusValue && this.remark ){
                          
               this.showMessage='';

        }

        updateWorkOrderApprovalStatus({ reactiveValue : this.reactiveValue, appointmentStatusValue : this.appointmentStatusValue,Remark : this.remark })

        .then( result => {

            console.log('Result ::', result);
            this.load=false;
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