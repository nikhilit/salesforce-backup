import { LightningElement,api,track } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateWorkOrder from '@salesforce/apex/checkcustomerAvailablityMeterRep.updateWorkOrder';
import checkWorkStepCheckin from '@salesforce/apex/checkcustomerAvailablityMeterRep.checkWorkStepCheckin';
import getWOrderWType from '@salesforce/apex/checkcustomerAvailablityMeterRep.getWOrderWType';


export default class CheckCustomerAvailabilityMeterRep extends LightningElement {

@api recordId;

@track load=false;

@track showCustomerAvailability=true;

@track customerAvailability = '';

@track customerAvilable=false;

@track showCheckBox=true;

@track showIPDEntry=false;

@track showAfterSalesEntry=false;

@track showMeterReplacementEntry = false;

@track customerNotAvailableDetails=false;

     @track wOWorkType='';


connectedCallback() {
    
    this.checkWorkStepCheckin();
     this.getWOrderWType();

}



get availabilityOptions() {
    return [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];
}




 checkWorkStepCheckin(){
    console.log('inside check work order step');
    checkWorkStepCheckin({recordId:this.recordId})
    .then( result => {

        console.log('Result :::', result);
        if(result !='Completed'){
            this.showToast('Warning', 'Please Complete Check-in Task', 'warning');

            this.showCheckBox=false;
            this.showCustomerAvailability=false;
            this.customerNotAvailableDetails=false;

            this.handleCancel();  
                  }
    })
    .catch( error => {
        console.log('Error getting approval ::', error);
    })
  }


handleAvailabilityChange(event) {

    if (event.target.value == 'Yes') {

        this.customerAvailability = event.detail.value;
        this.customerAvilable=true;


        this.customerNotAvilable = false;
        this.customerNotAvilableRemark='';
        this.ReasonForUnavailability=false;

      
    }  if (event.target.value == 'No') {

        this.customerAvilable=false;
        this.customerAvailability = event.detail.value;
        this.showCheckBox=false;
        this.customerNotAvailableDetails=true;

       // this.ReasonForUnavailability=true;

      
    }
}


handleCusAvilSave(){

        this.load=true;

        updateWorkOrder({recordId : this.recordId, customerAvailability : this.customerAvailability})
        .then( result => {

            console.debug('Result ::', result);
             this.showtoast('Success', 'Details saved successfully!', 'success');

            this.load=false;
             this.handleCancel();

        })
        .catch(error => {
            console.error('Error:::', error);

            const message = 
                error?.body?.message ||
                error?.body?.pageErrors?.[0]?.message ||
                error?.body?.fieldErrors?.[0]?.message ||
                error?.message ||
                'Unknown error';

            this.showtoast('Error', message, 'error');
            this.load = false;
        })

    }

     getWOrderWType(){
        getWOrderWType({recordId :this.recordId})
        .then( result => {
            console.log('Work Type Name ::', result);
        this.wOWorkType=result;
           this.checkWorkType();


        })
        .catch(error => {
            console.log('Error ::', error);
        })
    }


    checkWorkType(){

        console.log('inside check work type');


    if(this.wOWorkType=='Individual Permanent Disconnection'){

          console.log('inside ipd');


        this.showIPDEntry=true;
       this.showAfterSalesEntry=false;
       
    
        }
       
        
        if(this.wOWorkType =='After Sales Service'){

        console.log('inside After Sales Service');
                this.showIPDEntry=false;
        this.showAfterSalesEntry=true;


        }

         
        if(this.wOWorkType =='Meter Replacement'){

        console.log('inside After Sales Service');
                this.showIPDEntry=false;
        this.showAfterSalesEntry=false;
        this.showMeterReplacementEntry = true;


        }

       


    }




 handleCancel() {
         setTimeout(() => {
            history.back();
        }, 1000); 
      
        
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