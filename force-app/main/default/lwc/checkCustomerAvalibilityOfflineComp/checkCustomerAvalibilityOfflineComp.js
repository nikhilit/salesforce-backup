import { LightningElement,api,track,wire } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// for offline 09-10-2025
import { createContentDocumentAndVersion, createRecord } from "lightning/uiRecordApi";
import CONTENT_DOCUMENT from "@salesforce/schema/ContentDocument";
import { getObjectInfos } from "lightning/uiObjectInfoApi";
import CONTENT_VERSION from "@salesforce/schema/ContentVersion";
import CONTENT_DOCUMENT_LINK from "@salesforce/schema/ContentDocumentLink";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import DOCUMENT_OBJECT from '@salesforce/schema/Document__c';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Username';
import { getRecord } from 'lightning/uiRecordApi';
import { getListUi } from 'lightning/uiListApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from "@salesforce/apex";

import WORKSTEP_OBJECT from '@salesforce/schema/WorkStep';
import ID_FIELD from '@salesforce/schema/WorkStep.Id';
import STATUS_FIELD from '@salesforce/schema/WorkStep.Status';
import NAME_FIELD from '@salesforce/schema/WorkStep.Name';
import PARENT_FIELD from '@salesforce/schema/WorkStep.ParentRecordId';
import { getFieldValue } from 'lightning/uiRecordApi';

//import getWorkStepStatus from '@salesforce/apex/checkCustomerAvalibilityOfflineContr.getWorkStepStatus';


export default class CheckCustomerAvalibilityOfflineComp extends LightningElement {


@api recordId;
 @track load=false;


    @track uploadingFile = false;
    @track imageUploadPage=false;

        @track userName;

        @track checkInStatus='';

@track workStepId='';

@track ReasonForUnavailability=false;

@track showCheckBox=true;

@track customerNotAvilableRemark='';
get availabilityOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }

    connectedCallback() {

          if (this.wiredDocumentsResult) {
                refreshApex(this.wiredDocumentsResult);
            }

          if (this.wiredUserResult) {
        refreshApex(this.wiredUserResult)
            .then(() => {
                console.log('User info refreshed:', this.userName);
            })
            .catch(err => console.error('Error refreshing user:', err));
         }

       //  this.getWorkStepStatus();

          
        
       }

        @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkSteps', 
        fields: ['WorkStep.Id', 'WorkStep.Name'] 
    })
    wiredWorkStep({ data, error }) {
        if (data) {
            console.log('Related WorkSteps:', data);
            // Filter by Name
            const ws = data.records.find(r => r.fields.Name.value === 'Riser activity Possible');
            if (ws) {

                this.workStepId = ws.id;
                console.log('Selected WorkStep Id for riser activity possible task:', this.workStepId);
            }
        } else if (error) {
            console.error('Error fetching related WorkSteps:', error);
        }
    }

      /* getWorkStepStatus(){

        getWorkStepStatus({workOrderId : this.recordId, name:'Riser activity Possible'})

        .then( result => {

            console.log('WorkStep Id Result:: ', result);
            this.workStepId = result;
        })
        .catch(error => {

                console.log('Error getting workstep id::', error);
        })
       }  */


       async updateWorkStepStatus() {
        try {
            // Prepare field map
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.workStepId;
            fields[STATUS_FIELD.fieldApiName] = 'Completed'; 

            const recordInput = { fields };

            await updateRecord(recordInput);

          //  this.showToast('Success', 'WorkStep updated to Completed', 'success');
           // console.log('✅ WorkStep updated successfully');
        } catch (error) {
           // console.error('⚠️ Error updating WorkStep:', error);
          //  this.showToast('Error', error.body?.message || error.message, 'error');
        }
    }

//offline code 09-10-2025

 @wire(getObjectInfos, {
        objectApiNames: [CONTENT_DOCUMENT, CONTENT_VERSION, CONTENT_DOCUMENT_LINK]
    })

        objectMetadata;


async handleCusAvilSave(){

        this.load=true;

 try {

                console.log('inside try block');

                console.log('customerAvailability ::', this.customerAvailability);
            const fields = {
                
                Id: this.recordId,
                Check_Customer_Availability__c: this.customerAvailability
              
            };

            await updateRecord({ fields });

            await this.updateWorkStepStatus();

           this.showtoast('Success', 'Details saved successfully!', 'success');

             this.load = false;

             this.handleCancel();

        } catch (error) {

             console.log('inside catch block');


            console.log('Error ::', error);
          
        }

}



async handleFinalSave() {

console.log('inside details saved offline');

      if(!this.unavailability){

  this.showtoast('Warning', 'Please Select Reason.', 'warning');

    return;
    }


     if(!this.otherRemarkValue && this.otherRemark){

  this.showtoast('Warning', 'Please Enter Remark.', 'warning');

    return;
    }

     if(!this.maintenanceDoneYearOfAMC && this.yearOfAMC){

  this.showtoast('Warning', 'Maintenance already done-year of AMC is Required.', 'warning');

    return;
    }

     if (this.uploadingFile) return;

         const hasFiles = this.documentTypes.some(type => type.file && type.file.length > 0);

        if (!hasFiles) {
        this.load = false;
        this.showtoast('Warning', 'Please select file', 'warning');
        return;
    }

        this.uploadingFile = true;
        this.load = true;


             try {
            for (const type of this.documentTypes) {
                if (!type.file || type.file.length === 0) continue;

                for (const file of type.file) {
                    console.log('Uploading file:', file.name);

                    // const description = type.label;

                    const description = 'Reason for cancellation';

                    const contentDoc = await createContentDocumentAndVersion({
                        title: file.name,
                        description: description,
                        fileData: file,

                    });

                    if (this.recordId) {
                        await createRecord({
                            apiName: 'ContentDocumentLink',
                            fields: {
                                LinkedEntityId: this.recordId,
                                ContentDocumentId: contentDoc.contentDocument.id,
                                ShareType: 'V'
                            }
                        });
                    }

                    console.log('Uploaded:', file.name);
                }
            }

              const fields = {
                
                Id: this.recordId,
                Reason_ForUnavilability__c: this.unavailability,
                Reason_Other_Remark__c: this.otherRemarkValue,
                Check_Customer_Availability__c: this.customerAvailability,
                Maintenancealreadydone_yearofAMC__c: this.maintenanceDoneYearOfAMC
            };

            await updateRecord({ fields });

           await this.updateWorkStepStatus();

           this.showtoast('Success', 'Details saved successfully!', 'success');

             this.load = false;

             this.handleCancel();


            // Reset after upload
            this.documentTypes = this.documentTypes.map(t => ({ ...t, fileName: [], file: [] }));
        } 
         
          

         catch (error) {

             console.log('inside catch block');

            this.load=false;

             let message = 'Unknown error occurred';
    if (Array.isArray(error.body)) {
        message = error.body.map(e => e.message).join(', ');
    } else if (error.body && error.body.message) {
        message = error.body.message;
    } else if (error.message) {
        message = error.message;
    }

    this.showtoast('Error', 'File upload failed: ' + message, 'error');
         
        }
        finally {
            this.uploadingFile = false;
            this.load = false;
        }


}

@wire(getRelatedListRecords, {
    parentRecordId: '$recordId',
    relatedListId: 'WorkSteps', 
    fields: ['WorkStep.Name', 'WorkStep.Status'],
    sortBy: ['CreatedDate DESC'],
    pageSize: 200
})

wiredWorkSteps({ data, error }) {
    if (data) {
        const records = data.records || [];
        console.log('WorkSteps:', records);

        const checkInStep = records.find(r => r.fields.Name.value === 'Check-in');

        this.checkInStatus = checkInStep ? checkInStep.fields.Status.value : 'Not Found';

        console.log('Check-in Status:', this.checkInStatus);

        if (this.checkInStatus !== 'Completed') {


                this.showtoast('Warning','Please Complete Check In Task', 'warning');
        
                 this.showCheckBox = false;

               this.handleCancel();

        }

    }
       
}

wiredUserResult; // store wire result reference

@wire(getRecord, { recordId: USER_ID, fields: [USER_NAME] })
wiredUser(result) {
    this.wiredUserResult = result; // store the full wire result for refresh
    const { data, error } = result;

    if (data) {
        this.userName = data.fields.Username.value;
        console.log('Current Username:', this.userName);
           if (this.wiredDocumentsResult) {
            refreshApex(this.wiredDocumentsResult);
        }
    } else if (error) {
        console.error(' Error fetching user:', error);
    }
}


//O&MWarningStatus

wiredDocumentsResult;

@wire(getListUi, {
    objectApiName: DOCUMENT_OBJECT,
    listViewApiName: 'O_M_TBT_Documents',
    pageSize: 200
})
wiredDocuments(result) {
    this.wiredDocumentsResult = result;
    const { data, error } = result;

    if (data && this.userName) {
        const records = data.records.records;
        const match = records.find(
            rec => rec.fields.Submitted_Agent_Name__c.value === this.userName
        );

        if (match) {
        
            const apprStatus = match.fields.Approval_Status_O_M__c.value;

          

            if (apprStatus != 'Approved') {
              this.showCheckBox = false;
              this.showtoast('Warning','Please Upload TBT Documents', 'warning');             
              this.handleCancel();
            }    
        }
        }
    
}



handleFileChange(event){

        this.load = true;

        const label = event.target.dataset.label;
        const files = Array.from(event.target.files);

        console.log('Files selected:', files);

        const updatedTypes = this.documentTypes.map(type => {
            if (type.label === label) {
                const newFileNames = [...(type.fileName || []), ...files.map(f => f.name)];
                const newFiles = [...(type.file || []), ...files];
                return {
                    ...type,
                    fileName: newFileNames,
                    file: newFiles
                };
            }
            return type;
        });

        this.documentTypes = updatedTypes;
        console.log('Updated documentTypes:', this.documentTypes);

        this.load = false;
        event.target.value = null; 
    

}
    
       reasonUnavailability = [
  { "label": "Access Denied by Customer", "value": "Access Denied by Customer" },
  { "label": "Building Under Development", "value": "Building Under Development" },
  { "label": "Location Not Found", "value": "Location Not Found" },
  { "label": "Building Under Renovation", "value": "Building Under Renovation" },
  { "label": "Riser Inside Duct", "value": "Riser Inside Duct" },
  { "label": "Maintenance Already Done - Year of AMC", "value": "Maintenance Already Done - Year of AMC" },
  { "label": "Riser Encroached by Customer", "value": "Riser Encroached by Customer" },
  { "label": "Others", "value": "Others" }
];

    @track yearOfAMC=false;
    @track maintenanceDoneYearOfAMC='';


        @track customerAvailability='';
        @track customerNotAvilable = false;
        @track customerAvilable = false;
        @track otherRemark=false;
        @track otherRemarkValue='';



  @track fileName=[];
  @track selectedFile=[];
  @track fileData=[];


  @track showIPDUploadIcons=false;

  @track approvalComment='';

  @track fileType = [];

    @track isSubmitDisabled=false;
    @track isUploadDisabled=false;
    @track isClearFile=false;

   @track uploadedFileNames=[];
  @track base64List=[];

  @track approvalStatus='';

    @track selectedFileData = '';

    @track documentTypes=[
   
    { label: 'Upload Images', fileName: [], file: [], base64: [] }

  ]; 

          @track unavailability;




        
    

   



handleChangeYearOfAMC(event){

    console.log('Maintennace year done change ::', event.target.value);

    this.maintenanceDoneYearOfAMC=event.target.value;


}


         handleAvailabilityChange(event) {
        if(event.target.value == 'Yes'){

        this.customerAvailability = event.target.value;
        this.customerAvilable=true;
        this.customerNotAvilable = false;
        this.customerNotAvilableRemark='';
        this.ReasonForUnavailability=false;
        this.imageUploadPage=false;


        }
        if(event.target.value == 'No'){

        this.customerAvailability = event.target.value;
            this.customerAvilable=false;
            this.showCheckBox=false;
        this.ReasonForUnavailability=true;
        this.imageUploadPage=true;

            
        }

         }

          handlereasonForUnavailability(event) {
        console.log('event detail value ::', event.detail.value);
        console.log('event detail value ::', event.target.value);

        this.unavailability = event.detail.value;

        if(this.unavailability =='Others'){

            this.otherRemark=true;
            this.yearOfAMC = false;
            this.otherRemarkValue='';
            this.maintenanceDoneYearOfAMC='';

        }

        if(this.unavailability !='Others'){

                this.otherRemark=true;
            this.otherRemarkValue='';
          this.maintenanceDoneYearOfAMC='';


        }

         if(this.unavailability =='Maintenance Already Done - Year of AMC'){

            this.yearOfAMC = true;

            this.otherRemark=true;
            this.otherRemarkValue='';
            this.maintenanceDoneYearOfAMC='';


        }

         if(this.unavailability !='Maintenance Already Done - Year of AMC'){

            this.yearOfAMC = false;
              this.otherRemarkValue='';
            this.maintenanceDoneYearOfAMC='';

        }

        if(event.target.value=='Premises Locked'){

            this.otherRemark=true;
            this.otherRemarkValue='';
            this.maintenanceDoneYearOfAMC='';


        }
    }

    handleOtherRemark(event){

        this.otherRemarkValue = event.target.value;
    }

  handleCustomerNotAvilableRemark(event){

        this.customerNotAvilableRemark = event.target.value;
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