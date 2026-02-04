import { LightningElement,api,track } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateWorkOrder from '@salesforce/apex/checkCustomerAvalibilityIPDContr.updateWorkOrder';
import checkWorkStepCheckin from '@salesforce/apex/checkCustomerAvalibilityIPDContr.checkWorkStepCheckin';
import getWOrderWType from '@salesforce/apex/checkCustomerAvalibilityIPDContr.getWOrderWType';
import getApprovalStatus from '@salesforce/apex/checkCustomerAvalibilityIPDContr.getApprovalStatus';


export default class CheckCustomerAvalibilityIPDComp extends LightningElement {

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
    
     this.getApprovalStatus();
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

    getApprovalStatus(){
    getApprovalStatus()
    .then( result=> {
        console.log('result of approval status', JSON.stringify(result));
       /* if(result.documentRecordDetail.Approval_Status_O_M__c !='Approved'
         && (result.profileName !='Domestic Meter Checking Field Agent' ||
          result.profileName !='O&M Field Agent DOMESTIC METER CHECKING' || result.profileName !='O&M Supervisor DOMESTIC METER CHECKING'
          || result.profileName !='Rubber Hose Field Agent' || result.profileName !='O&M Rubber Hose Supervisor' || result.profileName !='O&M Rubber Hose Field Agent')){

        this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
        this.handleCancel();
        this.checkOut = false;
        this.checkIn = false;
        

        } */

          console.log('result of approval status', JSON.stringify(result));

        if(result.profileName =='Domestic Meter Checking Field Agent' ||
          result.profileName =='O&M Field Agent DOMESTIC METER CHECKING' || result.profileName =='O&M Supervisor DOMESTIC METER CHECKING'
          || result.profileName =='Rubber Hose Field Agent' || result.profileName =='O&M Rubber Hose Supervisor' || result.profileName =='O&M Rubber Hose Field Agent'){

            console.log('inside profile matched:');
       
          }
       else if(result.documentRecordDetail.Approval_Status__c !='Approved' &&
        
       (result.profileName ='O&M Field Agent Riser Activity' ||
          result.profileName =='O&M Field Agent IPD' || result.profileName =='O&M Supervisor IPD' ||   result.profileName == 'Field Agent(O&M)- AfterSalesService'))
        {

            console.log('inside 2nd if condition');
         
        this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
        console.log('inside if condition');
        this.handleCancel();
        this.checkOut = false;
        this.checkIn = false;
        

        }

    })
    .catch(error => {

        console.log('Error ::',error);
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

            console.debug('Error:::', error);
            this.load=false;
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