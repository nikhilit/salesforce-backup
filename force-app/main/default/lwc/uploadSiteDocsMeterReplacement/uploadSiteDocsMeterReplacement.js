import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { createContentDocumentAndVersion, createRecord, updateRecord } from "lightning/uiRecordApi";
import { getObjectInfos } from "lightning/uiObjectInfoApi";
import { getRecord } from 'lightning/uiRecordApi';
import CONTENT_DOCUMENT from "@salesforce/schema/ContentDocument";
import CONTENT_VERSION from "@salesforce/schema/ContentVersion";
import CONTENT_DOCUMENT_LINK from "@salesforce/schema/ContentDocumentLink";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import { refreshApex } from "@salesforce/apex";
import { getListUi } from 'lightning/uiListApi';
import DOCUMENT_OBJECT from '@salesforce/schema/Document__c';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Username';
import WORKSTEP_OBJECT from '@salesforce/schema/WorkStep';
import getApprovalComment from '@salesforce/apex/UploadSiteDocumentMRContr.getApprovalComment';
//import getWorkStepStatus from '@salesforce/apex/checkCustomerAvalibilityOfflineContr.getWorkStepStatus';


//import WORKSTEP_OBJECT from '@salesforce/schema/WorkStep';
import ID_FIELD from '@salesforce/schema/WorkStep.Id';
import STATUS_FIELD from '@salesforce/schema/WorkStep.Status';
import NAME_FIELD from '@salesforce/schema/WorkStep.Name';
import PARENT_FIELD from '@salesforce/schema/WorkStep.ParentRecordId';
import { getFieldValue } from 'lightning/uiRecordApi';



// Work Order fields
import APPROVAL_STATUS_FIELD from "@salesforce/schema/WorkOrder.Approval_Status__c";

export default class UploadSiteDocumentsOfflineComp extends LightningElement {
    @api recordId;   // Work Order Id
     @track showFileUpload=true;
    @track isLoading = false;
    @track uploadingFile = false;
    @track isSubmitDisabled = false;
    @track isUploadDisabled = false;
    @track isClearFile = false;
    @track approvalStatus = '';
    @track checkInStatus = '';
    @track riserActivityStatus = '';
    @track approvalComment = '';
    @track omApprovalStatus = '';
    @track userName;


         @track documentId;
        @track documentRecord;

        @track workStepId='';



    
    wiredRelatedFilesResult;

    

    connectedCallback() {


        if (this.wiredRelatedFilesResult) {
            refreshApex(this.wiredRelatedFilesResult);
        }

         if (this.wiredUserResult) {
        refreshApex(this.wiredUserResult)
            .then(() => {
                console.log('User info refreshed:', this.userName);
            })
            .catch(err => console.error('Error refreshing user:', err));
    }
   // this.forceReloadDocuments();
     if (this.wiredDocumentsResult) {
        refreshApex(this.wiredDocumentsResult);
    }

        this.getApprovalComment();
      //   this.getWorkStepStatus();
    }

//     fetchApprovalComment() {
//     getApprovalComment({ recordId: this.recordId })
//         .then(result => {
//             if (result) {
//                 this.approvalComment = 'Rejected comment: ' + result;
//                 console.log('Final approvalComment set to:', this.approvalComment);

//             }else {
//                 console.log('No approval comment found or not rejected.');
//             }
//         })
//         .catch(error => {
//             console.error('Error fetching approval comment:', error);
//         });
// }

 /* getWorkStepStatus(){

        getWorkStepStatus({workOrderId : this.recordId, name:'Upload Site Documents'})

        .then( result => {

            console.log('WorkStep Id Result:: ', result);
            this.workStepId = result;
        })
        .catch(error => {

                console.log('Error getting workstep id::', error);
        })
       } */

         @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkSteps', // Related List API name on WorkOrder
        fields: ['WorkStep.Id', 'WorkStep.Name']
    })
    wiredWorkStep({ data, error }) {
        if (data) {
            console.log('Related WorkSteps:', data);
            // Filter by Name
            const ws = data.records.find(r => r.fields.Name.value === 'Upload Site Document');
            if (ws) {

                this.workStepId = ws.id;
                console.log('Selected WorkStep Id for riser activity possible task:', this.workStepId);
            }
        } else if (error) {
            console.error('Error fetching related WorkSteps:', error);
        }
    }
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

 getApprovalComment(){
    getApprovalComment({recordId:this.recordId})
    .then( result => {

        console.log('Get approval comment::'+ result);

    if(result !='' && result !=null){
        this.approvalComment='Rejected comment : ' + ' ' + result;
    }
   
    })
    .catch( error => {
        console.log('Error getting approval comment::', error);
    })
  }



@wire(getRelatedListRecords, {
    parentRecordId: '$recordId', // WorkOrder Id
    relatedListId: 'WorkSteps', // API Name of the child relationship
    fields: ['WorkStep.Name', 'WorkStep.Status'],
    sortBy: ['CreatedDate DESC'],
    pageSize: 200
})

wiredWorkSteps({ data, error }) {
    if (data) {
        const records = data.records || [];
        console.log('WorkSteps:', records);

        const checkInStep = records.find(r => r.fields.Name.value === 'Check/In');
        const riserStep = records.find(r => r.fields.Name.value === "Check Customers Availability");

        this.checkInStatus = checkInStep ? checkInStep.fields.Status.value : 'Not Found';
        this.riserActivityStatus = riserStep ? riserStep.fields.Status.value : 'Not Found';

        console.log('Check-in Status:', this.checkInStatus);
        console.log('Riser Activity Status:', this.riserActivityStatus);

        if (this.checkInStatus !== 'Completed') {
            this.disableFileControls();
            setTimeout(() => {
                this.showToast('Warning','Please Complete Check In Task', 'warning');
            }, 50);
                 this.handleCancel();

        } else if (this.riserActivityStatus !== 'Completed') {
            this.disableFileControls();
            setTimeout(() => {
                this.showToast('Warning','Please Complete Check Customer Availability Task', 'warning');
            }, 50);
            this.handleCancel();

        } else {
            this.enableFileControls();
        }
    } else if (error) {
        console.error('Error fetching WorkSteps:', error);
    }
}


disableFileControls() {
    this.isSubmitDisabled = true;
    this.isUploadDisabled = true;
    this.isClearFile = true;
}

enableFileControls() {
    this.isSubmitDisabled = false;
    this.isUploadDisabled = false;
    this.isClearFile = false;
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
            this.documentRecord = match.fields;
            this.documentId = match.id;
            const apprStatus = match.fields.Approval_Status_O_M__c.value;
            this.omApprovalStatus = apprStatus;

            console.log('O&M Approval Status:', this.omApprovalStatus);

            if (apprStatus === 'Submitted For Approval' || apprStatus === 'Approved') {
               this.enableFileControls();
            } 
            else if (apprStatus === 'Rejected') {
                this.disableFileControls();

                // Clear previous files after small delay
                setTimeout(() => {
                    let updatedTypes = JSON.parse(JSON.stringify(this.documentTypes));
                    updatedTypes = updatedTypes.map(type => ({
                        ...type,
                        fileName: [],
                        file: [],
                        base64: [],
                        fileType: []
                    }));
                    this.documentTypes = updatedTypes;
                }, 100);
            } 
            else if (apprStatus === 'Pending') {
                this.disableFileControls();

                // Warn user they must upload O&M TBT doc first
                this.showToast(
                    'Warning',
                    'Please Upload TBT Documents',
                    'warning'
                );
                    this.handleCancel();

            }
        } else {
            console.log('No matching O&M TBT Document found');
            this.omApprovalStatus = '';
            this.documentId = null;
        }
    } 
    else if (error) {
        console.error('Error fetching O&M TBT documents:', error);
        this.omApprovalStatus = '';
    }
}



    @wire(getRecord, { recordId: '$recordId', fields: [APPROVAL_STATUS_FIELD] })
wiredWorkOrder({ data, error }) {
    if (data) {
        const status = data.fields.Approval_Status__c.value;
        //this.approvalStatus = status;

        if (status === 'Submitted For Approval' || status === 'Approved') {
             this.approvalStatus = status;
            this.isSubmitDisabled = true;
            this.isUploadDisabled = true;
            this.isClearFile = true;
        } 
         if(status === 'Pending'){

               this.isSubmitDisabled = false;
                this.isUploadDisabled = false;
                this.isClearFile = false; 
                this.approvalStatus='';
            }
        
        
        else if (status === 'Rejected') {
             this.approvalStatus = status;
            this.isSubmitDisabled = false;
            this.isUploadDisabled = false;
            this.isClearFile = false;


              this.isLoading=true;

              this.relatedFiles = [];


            setTimeout(() => {
                    let updatedTypes = JSON.parse(JSON.stringify(this.documentTypes));
                    updatedTypes = updatedTypes.map(type => ({
                        ...type,
                        fileName: [],
                        file: [],
                        base64: [],
                        fileType: []
                    }));
                    this.documentTypes = updatedTypes;
                    refreshApex(this.wiredDocumentsResult)
                        .then(() => {
                            console.log('🔄 Data refreshed after rejection');
                        })
                        .catch(err => console.error('⚠️ Error refreshing data:', err));
                                   }, 100);
                                }

                this.isLoading=false;

        console.log('WorkOrder Approval Status:', this.approvalStatus);
    } else if (error) {
        console.error('Error fetching WorkOrder:', error);
        this.approvalStatus = '';
         this.documentId = null;

    }
}

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'ContentDocumentLinks',
        fields: [
            'ContentDocumentLink.ContentDocumentId',
            'ContentDocumentLink.ContentDocument.Title',
            'ContentDocumentLink.ContentDocument.Description',
            'ContentDocumentLink.SystemModstamp'
        ],
        sortBy: 'SystemModstamp'
    })
    wiredRelatedFiles(result) {
        this.wiredRelatedFilesResult = result;
        const { data, error } = result;

        if (data) {
            const today = new Date().toISOString().split("T")[0];
            this.relatedFiles = (data.records || []).filter(file => {
                const fileDate = file.fields.SystemModstamp.value.split("T")[0];
                const isDeleted = file.fields.ContentDocument.value.fields.IsDeleted?.value;
                return fileDate === today && !isDeleted;
            });

            console.log('Related files (today only):', this.relatedFiles);

            this.documentTypes = this.documentTypes.map(type => {
                const uploadedFiles = this.relatedFiles
                    .filter(file =>
                        file.fields.ContentDocument.value.fields.Description &&
                        file.fields.ContentDocument.value.fields.Description.value === type.label
                    )
                    .map(file => file.fields.ContentDocument.value.fields.Title.value);

                return {
                    ...type,
                    fileName: uploadedFiles,
                    file: type.file || []
                };
            });
        } else if (error) {
            console.error('Error fetching related files:', error);
            this.relatedFiles = [];
        }
    }

    @track documentTypes = [
        { label: 'Permission Letter', fileName: [], file: [], base64: [] },
        { label: 'HIRA', fileName: [], file: [], base64: [] },
        { label: 'Others', fileName: [], file: [], base64: [] }

    ];

    @wire(getObjectInfos, {
        objectApiNames: [CONTENT_DOCUMENT, CONTENT_VERSION, CONTENT_DOCUMENT_LINK]
    })
    objectMetadata;

handleFilesInputChange(event) {
    this.isLoading = true;

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

    this.isLoading = false;
    event.target.value = null; 
}

    handleClearFile(event) {
        const label = event.target.dataset.label;
        const nameToRemove = event.target.dataset.name;

        this.documentTypes = this.documentTypes.map(type => {
            if (type.label === label) {
                const index = type.fileName.indexOf(nameToRemove);
                if (index > -1) {
                    const fileName = [...type.fileName];
                    const file = [...type.file];
                    fileName.splice(index, 1);
                    file.splice(index, 1);
                    return { ...type, fileName, file };
                }
            }
            return type;
        });

        console.log('File cleared:', nameToRemove);
    }


//     async updateUploadSiteDocumentsStep() {
//     try {
//         console.log('Fetching related WorkSteps for Upload Site Documents...');

//         const response = await getRelatedListRecords({
//             parentRecordId: this.recordId,
//             relatedListId: 'WorkSteps',
//             fields: ['WorkStep.Name', 'WorkStep.Status'],
//             sortBy: ['CreatedDate DESC'],
//             pageSize: 200
//         });

//         const records = response.records || [];
//         console.log('WorkSteps fetched:', records);

//         // Find "Upload Site Documents" step
//         const uploadStep = records.find(
//             rec => rec.fields.Name.value === 'Upload Site Documents'
//         );

//         if (uploadStep) {
//             const stepId = uploadStep.id;
//             console.log('Found Upload Site Documents step Id:', stepId);

//             const fields = {
//                 Id: stepId,
//                 Status: 'Completed'
//             };

//             await updateRecord({ fields });
//             console.log('Upload Site Documents WorkStep updated to Completed');
//         } else {
//             console.warn('Upload Site Documents WorkStep not found for this Work Order.');
//         }

//     } catch (error) {
//         console.error('Error updating Upload Site Documents WorkStep:', error);
//     }
// }


    async handleUploadClick() {
        this.isLoading = true;


    // if (this.checkInStatus !== 'Completed') {
    //     this.showToast('Warning', 'Please complete Check-in Task', 'warning');
    //     this.isLoading = false;
    //      this.handleCancel();

    //     return;
    // }

    // if (this.riserActivityStatus !== 'Completed') {
    //     this.showToast('Warning', 'Please complete Riser Activity Possible Task', 'warning');
    //     this.isLoading = false;
    //      this.handleCancel();

    //     return;
    // }



        if (this.uploadingFile) return;

        const hasFiles = this.documentTypes.some(type => type.file && type.file.length > 0);
        if (!hasFiles) {
            this.isLoading = false;
            this.showToast('Warning', 'Please select file', 'warning');
            return;
        }

        this.uploadingFile = true;

        try {
            for (const type of this.documentTypes) {
                if (!type.file || type.file.length === 0) continue;

                for (const file of type.file) {

                    console.log('Uploading file:', file.name);
                    const description = type.label;

                    const contentDoc = await createContentDocumentAndVersion({
                        title: file.name,
                        description: description,
                        fileData: file,
                    });

                    // Link file directly to Work Order
                    await createRecord({
                        apiName: 'ContentDocumentLink',
                        fields: {
                            LinkedEntityId: this.recordId, // Work Order
                            ContentDocumentId: contentDoc.contentDocument.id,
                            ShareType: 'V'
                        }
                    });
                }
            }

            //  Update WorkOrder.Approval_Status__c
            // const fields = {};
            // fields["Id"] = this.recordId;
            // fields[APPROVAL_STATUS_FIELD.fieldApiName] = "Calling Approval Process";

              const fields = {
            Id: this.recordId, 
            Approval_Status__c: 'Calling Approval Process' 
        };

            await updateRecord({ fields });

          await this.updateWorkStepStatus();

           
            console.log('Field updated successfully');

            this.showToast('Success', 'Documents Uploaded Successfully', 'success');

            

            this.handleCancel();



            this.documentTypes = this.documentTypes.map(t => ({ ...t, fileName: [], file: [] }));

           
        } catch (error) {
            console.error('Upload error:', error);
            this.isLoading = false;
          //  this.showToast('Error', `Record Id ${this.recordId}`, 'error');

           // this.showToast('Error', 'Failed to upload files', 'error');
            this.handleCancel();
        } finally {
            this.uploadingFile = false;
            this.isLoading = false;
        }
    }

      handleRefresh() {

         this.getApprovalComment();

    
    if (this.wiredDocumentsResult || this.wiredRelatedFilesResult) {
        this.isLoading = true; //  start loading spinner

        Promise.all([
            this.wiredDocumentsResult ? refreshApex(this.wiredDocumentsResult) : Promise.resolve(),
            this.wiredRelatedFilesResult ? refreshApex(this.wiredRelatedFilesResult) : Promise.resolve()
        ])
            .then(() => {
                 console.log(' refreshApex completed successfully');

                this.showToast('Refreshed', 'Latest data loaded successfully', 'success');
                            this.isLoading = false;

            })
            .catch(error => {
                console.error('Error refreshing:', error);
               // const message = error?.body?.message || error.message || 'Unknown error';
               // this.showToast('Error', 'Failed to refresh: ' + message, 'error');
                            this.isLoading = false;

            })
            .finally(() => {
                this.isLoading = false; 
            });
    }
}

    handleCancel() {
        setTimeout(() => {
            history.back();
        }, 1000);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}