import { LightningElement,api,track } from 'lwc';
//import saveServiReportData from '@salesforce/apex/RiserReplacementServiceReportContr.saveServiReportData';
import generateAndAttachPdf from '@salesforce/apex/RiserReplacementServiceReportContr.generateAndAttachPdf';
import LightningAlert from 'lightning/alert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';


export default class RiserReplacementServiceReportComp extends NavigationMixin(LightningElement) {


@api recordId;
@track oldMaterialUsed='';
@track isload=false;



 handleDownloadServiceReport(){

        this.isload=true;

        console.log('inside handle download service report');

             generateAndAttachPdf({worOrderId : this.recordId})
             .then(result => {

                console.log('Result ::', result);
              this.isload=false;

              if(result == 'Records Found'){

            //  this.showtoast('Success','Service Report Downloaded Successfully.','Success');
            //  this.dispatchEvent(new CustomEvent('cancel'));
                   LightningAlert.open({
            message: 'Service Report Downloaded Successfully.',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                this.dispatchEvent(new CustomEvent('cancel'));
         });

              }
              if(result == 'Records Not Found'){

                this.isload=false;
                // this.dispatchEvent(new CustomEvent('cancel'));

              }
             })
             .catch(error => {

                console.log('Error generating riser replacemnet report  ::', JSON.stringify(error));
             this.isload=false;


                });


    }



/* @track serviceReport = {

        instrumentTypeRange: '',
        calibrationDate: null,
        calibrationCertificateNo: '',
        calibrationDueDate: null
     
        
    };

   
     handleServiceReportDetails(event){

        const field = event.target.name;
        const value = event.target.value;

        if (field) {
            this.serviceReport[field] = value;
        }
    } */

    //  handleCancel() {


    //      setTimeout(() => {
    //         history.back();
    //     }, 1000);        
    //      console.log('inside handle cancel');
       
    // }

    /*

    handleSave(){

        // if(!this.serviceReport.calibrationDueDate || !this.serviceReport.calibrationCertificateNo || !this.serviceReport.calibrationDate || !this.serviceReport.instrumentTypeRange || this.oldMaterialUsed==''){

        //     //|| !this.serviceReport.mATERIALUSED
        //     console.log('inside if error');
        //    this.showtoast('Warning','Please enter required fields.','warning');
        //     return;
        //  }

     this.isload = true;

    //const jsonData = JSON.stringify(this.serviceReport);

  //  console.log('Json data :::', jsonData);
       // saveServiReportData({recordId : this.recordId, serviceReport : jsonData, oldMaterialUsed : this.oldMaterialUsed})
        saveServiReportData({recordId : this.recordId,oldMaterialUsed : this.oldMaterialUsed})

        .then( result => {
            console.log('Result ::', result);
              this.showtoast('Success','Record Updated Successfully.','Success');
       this.isload=false;
       this.handleCancel();
     // this.dispatchEvent(new CustomEvent('cancel'));
        // generateAndAttachPdf({worOrderId : this.recordId});



        })
        .catch(error => {
            this.isload=false;
            console.log('Error :', error);
        })
         
    }


handleRiserReplacement(event){

    this.oldMaterialUsed=event.target.value;
    console.log('old material user::', this.oldMaterialUsed);

} */

// handleSave(){

//     if(!this.oldMaterialUsed){

//       this.showtoast('Warning', 'Please Enter Old Material Details.', 'warning');
//       return;
//     }

//     this.isload=true;

//     updateWOMaterialUsed({recordId : this.recordId, oldMaterialUsed : this.oldMaterialUsed})
//     .then(result => {

//         console.log('Result ::', result);
//                 this.showtoast('Success', 'Record Updated Successfully', 'Success');

//         this.isload=false;
//       this.dispatchEvent(new CustomEvent('cancel'));
//          generateAndAttachPdf({worOrderId : this.recordId});
//     })
//     .catch(error =>{
//         this.isload=false;
//         console.log('Error::', error);
//     })
// }




showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }


}