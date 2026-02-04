import { LightningElement,track,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getWorkOrder from '@salesforce/apex/AddNoOfRisersContr.getWorkOrder';
import updateCODetails from '@salesforce/apex/AddNoOfRisersContr.updateCODetails';
import LightningAlert from 'lightning/alert';



export default class AddNoOfRisersComp extends LightningElement {

    @track risersNumber = '';

    @api recordId;

        @track load = false;


    @track noOfRisersAlreadyCreated='';
    @track existingandCurrentNoOfRisers='';

    connectedCallback() {

        console.log('add no of riser ::');
        
    this.getWorkOrder();

    }

    // handleBack(){

    //             this.dispatchEvent(new CustomEvent('cancel'));

    //   //this.handleCancel();

    //          }

     handleRiserChange(event) {

        this.risersNumber = parseInt(event.target.value, 10);

        this.existingandCurrentNoOfRisers =  Number(this.risersNumber) + Number(this.noOfRisersAlreadyCreated);


        console.log('existingandCurrentNoOfRisers', this.existingandCurrentNoOfRisers);
        if (this.existingandCurrentNoOfRisers >= 0 && this.existingandCurrentNoOfRisers <= 25) {

        }

        else {
       this.risersNumber = null;
        // this.showNextButton = false;
        // this.showMaintenanceDetail = false;

          LightningAlert.open({
            message: 'Please Enter Valid Number',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });

     // this.showtoast('Warning', 'Please Enter Valid Number.', 'warning');

        }
       // this.handleNextShowDetails();

    } 
    
     getWorkOrder(){

        getWorkOrder({recordId : this.recordId})

        .then( result => {

            console.log('Result getWorkOrder add riser ::', result);
          //  if(result.Number_of_Risers__c){


               this.noOfRisersAlreadyCreated = result;

               console.log('NoOfRisersAlreadyCreated::', this.noOfRisersAlreadyCreated);

          //  }
          
        })
        .catch(Error => {

            console.log('Error ::', Error);
        })
    }

     handleSave(){

        this.load=true;

          if ( this.risersNumber === null || this.risersNumber === undefined || this.risersNumber === '' ) {
         LightningAlert.open({
            message: 'Please Enter All Required Fields',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }); 
          //  this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
            this.load=false;
            return;
        }
         if ( this.existingandCurrentNoOfRisers > 25 ) {

             this.risersNumber = null;

            LightningAlert.open({
            message: 'Please Enter Valid Number',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
          //  this.showtoast('Warning', 'Please Enter Valid Number', 'Warning');
            this.load=false;
            return;
        }

        updateCODetails({recordId : this.recordId, riserNumber: this.risersNumber, noOfRisersAlreadyCreated : this.noOfRisersAlreadyCreated, existingandCurrentNoOfRisers : this.existingandCurrentNoOfRisers })
    
        .then(result => {

           LightningAlert.open({
            message: 'Details Saved Successfully',
            theme: 'success',   // red error dialog
            label: 'success'    // header text
        });
           //  this.showtoast('Success', 'Details Saved Successfully', 'success');
            console.log('Result savecodetails::', result);
             this.load=false;

          //   this.handleBack();

             this.handleCancel();
                     
          //  this.dispatchEvent(new CustomEvent ('cancel'));



        })
        .catch(Error => {

            console.log('Error savecodetails::', Error);
          this.load=false;

        })
    }


 handleCancel() {


       // this.accountView=false;
         setTimeout(() => {
            history.back();
        }, 1000);        
         console.log('inside handle cancel');
       
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