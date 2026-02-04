import { LightningElement,track,api } from 'lwc';
//import saveServiReportData from '@salesforce/apex/RiserMaintenenceServiceReportContr.saveServiReportData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateAndAttachPdf from '@salesforce/apex/RiserMaintenenceServiceReportContr.generateAndAttachPdf';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';

export default class RiserMaintenenceServiceReportComp extends NavigationMixin(LightningElement) {


    @api recordId;
    @track isload=false;
    @track contentDocumId='';
    @track previewButtonDisabled=true;


 /* @track serviceReport = {

        instrumentTypeRange: '',
        calibrationDate: null,
        calibrationCertificateNo: '',
        calibrationDueDate: null,
        //mATERIALUSED: '',
        comments : ''
        
    };

   
    handleServiceReportDetails(event){

        const field = event.target.name;
        const value = event.target.value;

        if (field) {
            this.serviceReport[field] = value;
        }
    } */

     handleCancel() {


         setTimeout(() => {
            history.back();
        }, 1000);        
         console.log('inside handle cancel');
       
    }


    handleDownloadServiceReport(){

        this.isload=true;

        console.log('inside handle download service report');

             generateAndAttachPdf({worOrderId : this.recordId})
             .then(result => {

                console.log('Result ::', result);
              //this.isload=false;
             //this.showtoast('Success','Service Report Downloaded Successfully.','Success');
                //this.dispatchEvent(new CustomEvent('cancel'));
                   LightningAlert.open({
            message: 'Service Report Downloaded Successfully.',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                 this.load=false;
                 this.dispatchEvent(new CustomEvent('cancel'));
         });
             })
             .catch(Error => {

                console.log('Error ::', Error.body.message);
             this.isload=false;


                })


    }




   /* handleSave(){

        if(!this.serviceReport.comments  || !this.serviceReport.calibrationDueDate || !this.serviceReport.calibrationCertificateNo || !this.serviceReport.calibrationDate || !this.serviceReport.instrumentTypeRange){

            //|| !this.serviceReport.mATERIALUSED
            console.log('inside if error');
           this.showtoast('Warning','Please enter required fields.','warning');
            return;
         }

     this.isload = true;

    const jsonData = JSON.stringify(this.serviceReport);

    console.log('Json data :::', jsonData);
        saveServiReportData({recordId : this.recordId, serviceReport : jsonData})
        .then( result => {
            console.log('Result ::', result);
              this.showtoast('Success','Record Updated Successfully.','Success');
       this.isload=false;
      this.dispatchEvent(new CustomEvent('cancel'));
         generateAndAttachPdf({worOrderId : this.recordId});



        })
        .catch(error => {
            this.isload=false;
            console.log('Error :', error);
        })
         
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