import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
//import getWorkOrderDetails from '@salesforce/apex/IPDReportContr.getWorkOrderDetails';
import generateAndAttachPdf from '@salesforce/apex/IPDMeterCheckingContr.generateAndAttachPdf';
import getCreatedServiceReportDetail from '@salesforce/apex/IPDMeterCheckingContr.getCreatedServiceReportDetail';
import LightningAlert from 'lightning/alert';

export default class IpdMeterChecking extends NavigationMixin(LightningElement) {
    @api recordId;
    @track load = false;

    @track serviceReportDownloaded=false;
  //  workOrderNumber = '';

    connectedCallback() {
      //  this.getCreatedServiceReportDetail();
    }

    /*fetchWorkOrderDetails() {
        this.load = true;
        getWorkOrderDetails({ workOrderId: this.recordId })
            .then(result => {
                this.workOrderNumber = result.WorkOrderNumber;
                this.load = false;
            })
            .catch(error => {
                console.error('Error fetching work order details', error);
                this.showToast('Error', error.body?.message || 'Failed to load work order details', 'error');
                this.load = false;
            });
    } */


    // getCreatedServiceReportDetail(){

    //     getCreatedServiceReportDetail({recordId : this.recordId})
    //     .then(result => {

    //         console.log('Result of getCreateServiceReportDetail::', result);

    //             if(result =='EXISTS'){

    //               this.serviceReportDownloaded = true;
    //             }
    //             else {

    //             this.serviceReportDownloaded = false;
  
    //             }
    //     })
    //     .catch(error => {

    //         console.log('Error ::', error);
    //     })
    // }

    async handleDownloadPDF() {

        // if(this.serviceReportDownloaded==true){

        //      this.showToast('Warning', 'Service Report Already Downloaded Successfully', 'warning');
        //      return;

        // }
        this.load = true;

         const result = await getCreatedServiceReportDetail({ recordId: this.recordId });
           console.log('Check if report exists:', result);

        if(result === 'EXISTS') {
            //this.showToast('Warning', 'Service Report Already Downloaded Successfully', 'warning');
            //this.load = false;
               LightningAlert.open({
            message: 'Service Report Already Downloaded Successfully',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
                 this.load=false;
         });
            return;
        }
        
        generateAndAttachPdf({ worOrderId: this.recordId})
            .then(result => {

                console.log('result ::', result);
                // this.load=false;
                //     this.showToast('Success', 'Service Report Downloaded Successfully', 'success');
                //   this.dispatchEvent(new CustomEvent('cancel'));

                   LightningAlert.open({
            message: 'Service Report Already Downloaded Successfully',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                 this.load=false;
                  this.dispatchEvent(new CustomEvent('cancel'));
         });

                    // Close the modal or refresh the page as needed
                  //  this.dispatchEvent(new CustomEvent('close'));
                    // Refresh the parent component to show the new attachment
                  //  this.dispatchEvent(new CustomEvent('refresh'));
               
            })
            .catch(error => {

                this.load=false;
                console.error('Error:', error);
               // this.showToast('Error', 'Failed to generate PDF: ' + error.message, 'error');
            })
           
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}