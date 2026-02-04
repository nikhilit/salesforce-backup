import { LightningElement, api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';

//import getWorkOrderDetails from '@salesforce/apex/DMCReportContr.getWorkOrderDetails';
//import saveMeterCheckingData from '@salesforce/apex/DomesticMeterCheckingContr.saveMeterCheckingData';
import generateAndAttachPdf from '@salesforce/apex/DomesticMeterCheckingContr.generateAndAttachPdf';


export default class DomesticMeterChecking extends NavigationMixin(LightningElement) {
    @api recordId;
   @track materialUsed = '';
    @track materialRecovered ='';
    @track actionTaken='';


    @track load = false;

   // connectedCallback() {
     //   this.fetchWorkOrderDetails();
  //  }

    // fetchWorkOrderDetails() {
    //     this.load = true;
    //     getWorkOrderDetails({ workOrderId: this.recordId })
    //         .then(result => {
    //             this.workOrderNumber = result.WorkOrderNumber;
    //             this.load = false;
    //         })
    //         .catch(error => {
    //             console.error('Error fetching work order details', error);
    //             this.showToast('Error', error.body?.message || 'Failed to load work order details', 'error');
    //             this.load = false;
    //         });
    // }

    handleMaterialUsedChange(event) {
        this.materialUsed = event.target.value;
    }

    handleRemarkChange(event){

        this.actionTaken = event.target.value;
    }

      handleMaterialRecoveredChange(event){

        this.materialRecovered = event.target.value;
    }



   handleSaveReport() {


    console.log('inside handle save report');

    console.log('record id ::', this.recordId);

        this.load = true;

            generateAndAttachPdf({ workOrderId: this.recordId })
            .then(result => {

                console.log('Result :::', result);

                //     this.load = false;

                //  this.showtoast('Success', 'Service Report Downloaded Successfully.', 'success');

                //        this.dispatchEvent(new CustomEvent('cancel'));
                   LightningAlert.open({
            message: 'Service Report Downloaded Successfully.',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                 this.load=false;
                 this.dispatchEvent(new CustomEvent('cancel'));
         });


            })
            .catch(error => {

                this.load = false;
                console.log('error ::', error);


            })

   }

    // if (!this.materialUsed.trim()) {
    //     this.showToast('Error', 'Please enter Material Used before downloading', 'error');
    //     return;
    // }

   /* if(!this.materialUsed || !this.materialRecovered || !this.actionTaken){

       this.showtoast('Warning', 'Please Enter All Required Fields ', 'warning');

        this.load=false;
        return;
    } */


   /* saveMeterCheckingData({ workOrderId: this.recordId, materialUsed: this.materialUsed, materialRecovered : this.materialRecovered, actionTaken : this.actionTaken })
        .then(result => {

            console.log('result after savemeterchecking data', result);

            this.load=false;
               this.showtoast('Success', 'Details Saved Successfully.', 'success');

               this.dispatchEvent(new CustomEvent('cancel'));


              generateAndAttachPdf({ worOrderId: this.recordId });


        //     if (result === 'Success') {
        //         generateAndAttachPdf({ workOrderId: this.recordId })
        //             .then((res) => {
        //                 if (res === 'Success') {
        //                     this.showtoast('Success', 'Details Saved Successfully.', 'success');
        //                     this.load=false;
        //                   //  this.materialUsed = ''; // ✅ Clear the input field
        //                 } else {
        //                  //   this.showToast('Error', 'Failed to generate PDF.', 'error');
        //                 }
        //                 this.load = false;
        //                 this.dispatchEvent(new CustomEvent('cancel'));

        //             })
        //             .catch(error => {
        //                 console.error('Error generating PDF:', error);
        //             //    this.showToast('Error', 'Failed to generate PDF.', 'error');
        //                 this.load = false;
        //             });
        //     } else {
        //       //  this.showtoast('Error', 'Failed to save material used.', 'error');
        //         this.load = false;
        //     }
         })
        .catch(error => {
            console.error('Error saving data:', error);
         //   this.showtoast('Error', 'Something went wrong while saving.', 'error');
            this.load = false;
        });
} */


  /*  get isPreviewDisabled() {
        return !this.materialUsed.trim();
    } */

  showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}