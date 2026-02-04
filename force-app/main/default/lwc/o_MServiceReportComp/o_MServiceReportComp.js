import { LightningElement,api,track } from 'lwc';
import saveServiReportData from '@salesforce/apex/O_MServiceReportContr.saveServiReportData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import serviceReportPdf from '@salesforce/apex/O_MServiceReportContr.serviceReportPdf';
import { NavigationMixin } from 'lightning/navigation';
import getWOrderWType from '@salesforce/apex/O_MServiceReportContr.getWOrderWType';
import checkWorkStep from '@salesforce/apex/O_MServiceReportContr.checkWorkStep';
import uploadFileUnsafeLetter from '@salesforce/apex/O_MServiceReportContr.uploadFileUnsafeLetter';
import getApprovalStatus from '@salesforce/apex/O_MServiceReportContr.getApprovalStatus';
import LightningAlert from 'lightning/alert';
//import DomesticMeterChecking from 'c/domesticMeterChecking';

export default class O_MServiceReportComp extends NavigationMixin(LightningElement) {

@api recordId;
@track showRubberHoseReplFields=false;
@track showMeterReplacementFields = false;
@track showIANDCFields=false;
@track showRiserMaintenenceFields = false;
@track showRiserReplacementFields=false;
@track isload=false;
@track showPreviewButton=false;
@track contentDocumId='';
@track showDomesticMeterChecking = false;
@track showIPDMeterChecking=false;

@track wOWorkType ='';

    connectedCallback() {
        this.getWOrderWType();
      //  this.checkWorkStep();

        this.serviceReportPdf();
        this.getApprovalStatus();
    
    }

    @track fileName = '';
      @track fileData='';

      @track showUploadFile=true;
 
 
    selectedFile;

    /*  getApprovalStatus(){
    getApprovalStatus()
    .then( result=> {
        console.log('result of approval status', JSON.stringify(result));
        if(result.Approval_Status_O_M__c !='Approved'){

        this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
        this.handleCancel();
        this.showRiserMaintenenceFields=false;
        this.showDomesticMeterChecking=false;
        this.showIPDMeterChecking=false;
      
        

        }

    })
    .catch(error => {

        console.log('Error ::',error);
    })
     } */


      getApprovalStatus(){
    getApprovalStatus()
    .then( result=> {


        console.log('result of approval status', JSON.stringify(result));

         if(result.profileName =='O&M Field Agent IPD' || result.profileName =='O&M Supervisor IPD' ||
                    result.profileName =='Field Agent(O&M)- IPD' || 
                result.profileName =='Domestic Meter Checking Field Agent' || result.profileName =='O&M Field Agent DOMESTIC METER CHECKING' ||
                 result.profileName =='O&M Supervisor DOMESTIC METER CHECKING'){

            this.showUploadFile=false;
          }

        if(result.profileName =='Domestic Meter Checking Field Agent' ||
          result.profileName =='O&M Field Agent DOMESTIC METER CHECKING' || result.profileName =='O&M Supervisor DOMESTIC METER CHECKING'
          || result.profileName =='Rubber Hose Field Agent' || result.profileName =='O&M Rubber Hose Supervisor' || result.profileName =='O&M Rubber Hose Field Agent'){

            console.log('inside profile matched:');
        // this.handleCancel();
        //  this.showRiserMaintenenceFields=false;
        // this.showDomesticMeterChecking=false;
        // this.showIPDMeterChecking=false;
       // this.checkOut = false;
       // this.checkIn = false;
          }

         
       else if(result.documentRecordDetail.Approval_Status__c !='Approved' &&
        
        (result.profileName ='O&M Field Agent Riser Activity' ||
          result.profileName =='O&M Field Agent IPD' || result.profileName =='O&M Supervisor IPD'))
{

    

            console.log('inside 2nd if condition');
         
        // this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
        // console.log('inside if condition');
        // this.handleCancel();
        // this.checkOut = false;
        // this.checkIn = false;
        // this.showRiserMaintenenceFields=false;
        // this.showDomesticMeterChecking=false;
        // this.showIPDMeterChecking=false;
        LightningAlert.open({
            message: 'Please Upload TBT Documents',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
        this.handleCancel();
        this.checkOut = false;
        this.checkIn = false;
        this.showRiserMaintenenceFields=false;
        this.showDomesticMeterChecking=false;
        this.showIPDMeterChecking=false;
         });

        }

    })
    .catch(error => {

        console.log('Error ::',error);
    })
     }

   /* checkWorkStep(){
    console.log('inside check work order step');
    checkWorkStep({recordId:this.recordId})
    .then( result => {

        console.log('Result upload site status:::', result);
        if(result !='Completed'){
            console.log('inside new if');
            this.showtoast('Warning', 'Please Complete CO Execution Detail Task', 'warning');
            this.showMeterReplacementFields=false;
            this.showIANDCFields=false;
            this.showRiserMaintenenceFields=false;
            this.showRiserReplacementFields=false;
          this.showPreviewButton=false;
            this.showRubberHoseReplFields=false;


        }
    })
    .catch( error => {
        console.log('Error getting approval ::', error);
    })
  } */


SatisfactoryNotSatisfactoryOptions  = [
    { label: 'Satisfactory', value: 'Satisfactory' },
    { label: 'Not Satisfactory', value: 'Not Satisfactory' }
];


 serviceReportPdf(){
        serviceReportPdf({recordId : this.recordId})
        .then( result => {

            console.log('Result ::', result);
            if(result !='Error'){
            this.contentDocumId = result;
             this.showPreviewButton=true;
              console.log('inside show preview button');
            }
            if(result=='Error'){

                console.log('inside error preview button');
                this.showPreviewButton=false;
            }
            // if(this.contentDocumId){
            //    this.showPreviewButton=true;
            //   console.log('inside show preview button');

            // }
        })
        .catch(error => {
            console.log('Error :', error);
        })
    }

    //  handlePreviewPDF() {

    //     console.log('inside handle preview click');


    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__namedPage',
    //         attributes: {
    //             pageName: 'filePreview'
    //         },
    //         state: {
    //             selectedRecordId: this.contentDocumId

    //         }
    //     });
  
    //  }

   /*  handlePreviewPDF(){


        console.log('contentversion id ::'+ this.contentDocumId);
    // const fileId = event.currentTarget.dataset.id;

     //console.log('download file id::: '+ fileId);

    const link = document.createElement('a');
   // link.href = `/sfc/servlet.shepherd/document/download/${fileId}`;

     
 
    link.href = `/sfc/servlet.shepherd/version/download/${this.contentDocumId}`;

    link.download = ''; // Use the default file name

    // Append the link to the body (invisible to the user)
    document.body.appendChild(link);
    
    // Programmatically click the link to trigger the download
    link.click();
    
    // Remove the link from the document
    document.body.removeChild(link);

    } */

    handleSaveFile(){


    }

 getWOrderWType(){
        getWOrderWType({recordId :this.recordId})
        .then( result => {
            console.log('Result ::', result);
        this.wOWorkType=result;

         if(this.wOWorkType=='Rubber Hose Replacement'){
         
            this.showRubberHoseReplFields=true;
            this.showMeterReplacementFields=false;
            this.showIANDCFields=false;
            this.showRiserMaintenenceFields=false;
            this.showRiserReplacementFields=false;
             this.showDomesticMeterChecking = false;
             this.showIPDMeterChecking=false;

         }
         if(this.wOWorkType=='Meter Replacement'){
            this.showRubberHoseReplFields=false;
            this.showMeterReplacementFields=true;
            this.showIANDCFields=false;
            this.showRiserMaintenenceFields=false;
            this.showRiserReplacementFields=false;
             this.showDomesticMeterChecking = false;
              this.showIPDMeterChecking=false;



         }
           if(this.wOWorkType=='I&C Comm A, B &C'){
         
            this.showRubberHoseReplFields=false;
            this.showMeterReplacementFields=false;
            this.showIANDCFields=true;
            this.showRiserMaintenenceFields=false;
            this.showRiserReplacementFields=false;
             this.showDomesticMeterChecking = false;
              this.showIPDMeterChecking=false;

         }

          if(this.wOWorkType=='Riser Maintenance'){
         
            this.showRubberHoseReplFields=false;
            this.showMeterReplacementFields=false;
            this.showIANDCFields=false;
            this.showRiserMaintenenceFields=true;
            this.showRiserReplacementFields=false;
             this.showDomesticMeterChecking = false;
              this.showIPDMeterChecking=false;
         }

          if(this.wOWorkType=='Riser Replacement'){

            console.log('inside worktype riser replacement');
         
            this.showRubberHoseReplFields=false;
            this.showMeterReplacementFields=false;
            this.showIANDCFields=false;
            this.showRiserMaintenenceFields=false;
            this.showRiserReplacementFields=true;
             this.showDomesticMeterChecking = false;
              this.showIPDMeterChecking=false;
         }
         if(this.wOWorkType == 'Domestic Meter Checking') {
            this.showDomesticMeterChecking = true;
            this.showRubberHoseReplFields=false;
            this.showMeterReplacementFields=false;
            this.showIANDCFields=false;
            this.showRiserMaintenenceFields=false;
            this.showRiserReplacementFields=false;
             this.showIPDMeterChecking=false;
        }
         if(this.wOWorkType == 'Individual Permanent Disconnection') {
            this.showDomesticMeterChecking = false;
            this.showRubberHoseReplFields=false;
            this.showMeterReplacementFields=false;
            this.showIANDCFields=false;
            this.showRiserMaintenenceFields=false;
            this.showRiserReplacementFields=false;
             this.showIPDMeterChecking=true;
        }
        })
        .catch(error => {
            console.log('Error ::', error);
        })
    }



 @track serviceReport = {
        rubberHoseExpiryDate: null,
        workDone: '',
        satisfactoryNotSatisfactory: '',
        meterNumber: '',
        meterReading: ''
        
    };

    handleServiceReportDetails(event){

        const field = event.target.name;
        const value = event.target.value;

        if (field) {
            this.serviceReport[field] = value;
        }
    }

     handleCancel() {


         setTimeout(() => {
            history.back();
        }, 1000);        
         console.log('inside handle cancel');
       
    }

    handleSave(){

        if(!this.serviceReport.workDone || !this.serviceReport.satisfactoryNotSatisfactory){

            console.log('inside if error');
          // this.showtoast('Warning','Please enter required fields.','warning');
            LightningAlert.open({
            message: 'Please enter required fields.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
            return;
         }

     this.isload = true;

    const jsonData = JSON.stringify(this.serviceReport);

    console.log('Json data :::', jsonData);
        saveServiReportData({recordId : this.recordId, serviceReport : jsonData})
        .then( result => {
            console.log('Result ::', result);
    //           this.showtoast('Success','Record Updated Successfully.','Success');
    //    this.isload=false;
    //     this.handleCancel();
         LightningAlert.open({
            message: 'Record Updated Successfully.',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
        this.isload=false;
        this.handleCancel();
         });
        })
        .catch(error => {
            this.isload=false;
            console.log('Error :', error);
        })
         
    }

   handleFileChange(event) {
        console.log('handle file change::');
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name;
            this.selectedFile = file;
            console.log('File Name::: ' + this.fileName);
            const reader = new FileReader();
 
            reader.onload = () => {
                this.fileData = reader.result.split(',')[1];
                console.log('File data :: '+ this.fileData);
           // this.handleUpload();
 
            };
 
            reader.onerror = (error) => {
                console.log('Error reading file:', error);
            };
 
            reader.readAsDataURL(file);
 
 
        }
    }
 
    handleSaveFile() {

        this.isload=true;

        if(!this.fileData && !this.fileName){

        //   this.showtoast('Warning', 'Please select a file to upload.', 'warning');
        //   this.isload=false;
           LightningAlert.open({
            message: 'Please select a file to upload.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
        this.isload=false;
         });
          return;

        }
       
        console.log('handle upload :::: ');
        if (this.fileData && this.fileName) {
            console.log('File  name ::: ' + this.fileName);
           // console.log('File file data ::: ' + this.fileName);
 
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64Data = reader.result.split(',')[1];
                this.selectedFileData = base64Data;
                console.log('base64data ::: '+ base64Data);
                console.log('upload file ::: '+ this.fileName);
              this.uploadFile(this.fileName, base64Data);
 
 
            };
            reader.readAsDataURL(this.selectedFile);
        }
        else if(this.fileName == ''){
 
          //  this.showtoast('Warning', 'Please select a file to upload.', 'warning');
             LightningAlert.open({
            message: 'Please select a file to upload.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
        }
    }
 
     uploadFile() {
 
       // this.isLoading = true;
        console.log('inside upload file::: ');
       
       
        uploadFileUnsafeLetter({
            fileName: this.fileName,
            base64Data: this.selectedFileData,
            recordId : this.recordId
           
        })
            .then(result => {
                console.log('result sucess');

            //    this.showtoast('Success', 'Document Uploaded Successfully.', 'Success');
            //    this.load=false;
            //    this.handleCancel();

            LightningAlert.open({
            message: 'Document Uploaded Successfully.',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                      this.load=false;
               this.handleCancel();

         });
                   // this.showSubmit = true;
 
            })
            .catch(error =>{
 
              console.log('Error', error);
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