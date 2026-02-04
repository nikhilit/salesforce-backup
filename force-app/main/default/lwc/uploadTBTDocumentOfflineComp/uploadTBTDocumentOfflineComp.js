import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { createContentDocumentAndVersion, createRecord } from "lightning/uiRecordApi";
import { getObjectInfos } from "lightning/uiObjectInfoApi";
import CONTENT_DOCUMENT from "@salesforce/schema/ContentDocument";
import CONTENT_VERSION from "@salesforce/schema/ContentVersion";
import CONTENT_DOCUMENT_LINK from "@salesforce/schema/ContentDocumentLink";
import { updateRecord } from 'lightning/uiRecordApi';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Username';
import { getListUi } from 'lightning/uiListApi';
import DOCUMENT_OBJECT from '@salesforce/schema/Document__c';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { refreshApex } from '@salesforce/apex'; 
import getApprovalComment from '@salesforce/apex/UploadTBTDocumentOfflineCont.getApprovalComment';


export default class FileUpload extends LightningElement {
  //  @api recordId;

    @track showFileUpload=true;

    @track isLoading = false;
    @track uploadingFile = false;

     @track isSubmitDisabled=false;
    @track isUploadDisabled=false;
    @track isClearFile=false;

    @track relatedFiles=[];

        @track approvalComment = '';


        @track userName;

        @track documentRecord;
        @track documentId;
        @track approvalStatus = '';

       /* wiredDocumentsResult;
        wiredRelatedFilesResult;

      async connectedCallback() {
    try {
        if (this.wiredDocumentsResult) {
            await refreshApex(this.wiredDocumentsResult);
        }
        if (this.wiredRelatedFilesResult) {
            await refreshApex(this.wiredRelatedFilesResult);
        }
    } catch(error) {
        console.error('Error refreshing data on component load:', error);
    }
} */

connectedCallback() {

        this.getApprovalComment();


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
     if (this.wiredRelatedFilesResult) {
        refreshApex(this.wiredRelatedFilesResult);
    }
    //  if (this.wiredApprovalStepResult) {
    //         refreshApex(this.wiredApprovalStepResult);
    //     }
}

/*forceReloadDocuments() {
    const tempId = this.documentId;
    this.documentId = null;
    setTimeout(() => {
        this.documentId = tempId;
    }, 0);
}
*/

 /*commented to check refresh data fast 5-10-2025

 @wire(getRecord, { recordId: USER_ID, fields: [USER_NAME] })
    wiredUser({ error, data }) {
        if (data) {
            this.userName = data.fields.Username.value;
            console.log(' Current Username:', this.userName);
        } else if (error) {
            console.error('Error fetching user:', error);
        }
    } */

    // query approval process comment 
    //  wiredApprovalStepResult; // keep wire result for refresh

    // @wire(getRelatedListRecords, {
    //     parentRecordId: 'a0hfs0000002iPxAAI',
    //     relatedListId: 'ProcessSteps',
    //     fields: [
    //         'ProcessInstanceStep.StepStatus',
    //         'ProcessInstanceStep.Comments',
    //         'ProcessInstanceStep.CreatedDate'
    //     ],
    //     sortBy: ['CreatedDate DESC'],
    //     pageSize: 1
    // })
    // wiredApprovalStep(result) {
    //     this.wiredApprovalStepResult = result; // store result for refresh
    //     const { data, error } = result;

    //     if (data && data.records.length > 0) {
    //         const latestStep = data.records[0];
    //         const status = latestStep.fields.StepStatus.value;
    //         const comment = latestStep.fields.Comments?.value || '';

    //         this.approvalComment = (status === 'Rejected') ? comment : '';
    //     } else if (error) {
    //         console.error('Error fetching approval step:', error);
    //         this.approvalComment = '';
    //     }
    // }

     getApprovalComment(){
    getApprovalComment({})
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


   //trying again refresh apex

   wiredDocumentsResult;

@wire(getListUi, {
    objectApiName: DOCUMENT_OBJECT,
    listViewApiName: 'O_M_TBT_Documents', 
    pageSize: 200
})
wiredDocuments(result) {
    this.wiredDocumentsResult = result;  // store wire result for refresh
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

            if(apprStatus === 'Submitted For Approval' || apprStatus === 'Approved'){
                this.isSubmitDisabled = true;
                this.isUploadDisabled = true;
                this.isClearFile = true;
             this.approvalStatus = match.fields.Approval_Status_O_M__c.value;


            }
            if(apprStatus === 'Pending'){

               this.isSubmitDisabled = false;
                this.isUploadDisabled = false;
                this.isClearFile = false; 
                this.approvalStatus='';
            }
            else if(apprStatus === 'Rejected'){
                this.isSubmitDisabled = false;
                this.isUploadDisabled = false;
                this.isClearFile = false;

                this.approvalStatus = match.fields.Approval_Status_O_M__c.value;


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

          //  this.approvalStatus = apprStatus;

            console.log('Found Document Id:', this.documentId);
            console.log('Approval Status:', this.approvalStatus);
        } else {
            console.log('No matching Document found');
            this.approvalStatus = '';
             this.documentId = null;

        }
    } else if (error) {
        console.error('Error fetching documents:', error);
        this.approvalStatus = '';
    }
}



/* this method code is working need to uncomment

    @wire(getListUi, {
        objectApiName: DOCUMENT_OBJECT,
        listViewApiName: 'O_M_TBT_Documents', 
        pageSize: 200
    })
    wiredDocuments({ error, data }) {
        if (data && this.userName) {
            const records = data.records.records;
           // console.log('All Document records:', records);

            const match = records.find(
                rec =>
                    rec.fields.Submitted_Agent_Name__c.value === this.userName
            );

            if (match) {
                this.documentRecord = match.fields;
                this.documentId = match.id;
                const apprStatus = match.fields.Approval_Status_O_M__c.value;

                if(apprStatus === 'Submitted For Approval' || apprStatus ==='Approved'){

                     this.isSubmitDisabled = true;
                    this.isUploadDisabled = true;
                    this.isClearFile = true;
                    this.approvalStatus = match.fields.Approval_Status_O_M__c.value;

                    //  this.approvalStatus=result.Approval_Status_O_M__c;
                }
                else if(apprStatus === 'Rejected'){

                     this.isSubmitDisabled = false;
                    this.isUploadDisabled = false;
                    this.isClearFile = false;
                    this.approvalStatus = match.fields.Approval_Status_O_M__c.value;

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

                    //  this.approvalStatus=result.Approval_Status_O_M__c;
                }

                console.log('Found Document Id:', this.documentId);
                console.log('Approval Status:', this.approvalStatus);

            } else {
                console.log(' No matching Document found');
                this.approvalStatus = ''; 

            }
        } else if (error) {
            console.error('Error fetching documents:', error);
          this.approvalStatus = ''; 

        }
    }  */


    wiredRelatedFilesResult;

@wire(getRelatedListRecords, {
    parentRecordId: '$documentId',
    relatedListId: 'ContentDocumentLinks',
    fields: [
        'ContentDocumentLink.ContentDocumentId',
        'ContentDocumentLink.ContentDocument.Title',
        'ContentDocumentLink.ContentDocument.Description', // Description holds type
        'ContentDocumentLink.SystemModstamp'
    ],
    sortBy: 'SystemModstamp'
})
wiredRelatedFiles(result) {
    this.wiredRelatedFilesResult = result; // keep for refresh
    console.log('docuemnt uploaded files::', JSON.stringify(result));
    const { data, error } = result;

    if (data) {
        console.log('inside data found::', JSON.stringify(data));
        //  const today = new Date().toISOString().split("T")[0];
        //     this.relatedFiles = (data.records || []).filter(file => {
        //         const fileDate = file.fields.SystemModstamp.value.split("T")[0];
        //         const isDeleted = file.fields.ContentDocument.value.fields.IsDeleted?.value;
        //         return  !isDeleted && fileDate == today ;
        //     });//

 const today = new Date();
    const todayYear = today.getFullYear();
    const todayMonth = today.getMonth();
    const todayDate = today.getDate();

    this.relatedFiles = (data.records || []).filter(file => {
        const fileTime = new Date(file.fields.SystemModstamp.value);
        const isDeleted = file.fields.ContentDocument.value.fields.IsDeleted?.value;

        return (
            fileTime.getFullYear() === todayYear &&
            fileTime.getMonth() === todayMonth &&
            fileTime.getDate() === todayDate &&
            !isDeleted
        );
    });
   
        console.log('Related files (today only):', this.relatedFiles);



        // Map files to documentTypes by Description
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


 
/* working fine but refresh latested data not showing on same day uploaded
     @wire(getRelatedListRecords, {
        parentRecordId: '$documentId',
        relatedListId: 'ContentDocumentLinks',
        fields: [
            'ContentDocumentLink.ContentDocumentId',
            'ContentDocumentLink.ContentDocument.Title',
            'ContentDocumentLink.ContentDocument.Description', // Description holds type
            'ContentDocumentLink.SystemModstamp'
        ],
        sortBy: 'SystemModstamp'
    })
    wiredRelatedFiles({ error, data }) {
        if (data) {
            this.relatedFiles = data.records || [];
            console.log('Related files:', this.relatedFiles);

            // Map files to documentTypes by Description
            this.documentTypes = this.documentTypes.map(type => {
                const uploadedFiles = this.relatedFiles
                    .filter(file =>
                        file.fields.ContentDocument.value.fields.Description &&
                        file.fields.ContentDocument.value.fields.Description.value === type.label
                    )
                    .map(file => file.fields.ContentDocument.value.fields.Title.value);

                const existingNames = type.fileName || [];
                const mergedNames = [...existingNames, ...uploadedFiles];

                return {
                    ...type,
                    fileName: mergedNames,
                    file: type.file || []
                };
            });

        } else if (error) {
            console.error('Error fetching related files:', error);
            this.relatedFiles = [];
        }
    } */


    @track documentTypes = [
        { label: 'TBT', fileName: [], file: [], base64: [] }
    ];

    @wire(getObjectInfos, {
        objectApiNames: [CONTENT_DOCUMENT, CONTENT_VERSION, CONTENT_DOCUMENT_LINK]
    })
    objectMetadata;

   /* handleFilesInputChange(event) {
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
    } */

//     handleFilesInputChange(event) {
//     this.isLoading = true;
//     const label = event.target.dataset.label;
//     const files = Array.from(event.target.files);

//     const readFileAsBase64 = (file) => {
//         return new Promise((resolve, reject) => {
//             const reader = new FileReader();
//             reader.onload = () => {
//                 const base64 = reader.result.split(',')[1];
//                 resolve({ name: file.name, base64 });
//             };
//             reader.onerror = reject;
//             reader.readAsDataURL(file);
//         });
//     };

//     Promise.all(files.map(f => readFileAsBase64(f)))
//         .then(results => {
//             const updatedTypes = this.documentTypes.map(type => {
//                 if (type.label === label) {
//                     const newFileNames = [...(type.fileName || []), ...results.map(r => r.name)];
//                     const newFiles = [...(type.file || []), ...results];
//                     return { ...type, fileName: newFileNames, file: newFiles };
//                 }
//                 return type;
//             });
//             this.documentTypes = updatedTypes;
//             console.log('✅ Base64 ready documentTypes:', JSON.stringify(this.documentTypes));
//         })
//         .catch(error => {
//             console.error('File read error:', error);
//             this.showToast('Error', 'Unable to read file: ' + error.message, 'error');
//         })
//         .finally(() => {
//             this.isLoading = false;
//             event.target.value = null;
//         });
// }

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

    async handleUploadClick() {


        if (this.uploadingFile) return;

         const hasFiles = this.documentTypes.some(type => type.file && type.file.length > 0);

        if (!hasFiles) {
        this.isLoading = false;
        this.showToast('Warning', 'Please select file', 'warning');
        return;
    }

        this.uploadingFile = true;
        this.isLoading = true;


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

                    if (this.documentId) {
                        await createRecord({
                            apiName: 'ContentDocumentLink',
                            fields: {
                                LinkedEntityId: this.documentId,
                                ContentDocumentId: contentDoc.contentDocument.id,
                                ShareType: 'V'
                            }
                        });
                    }

                    console.log('Uploaded:', file.name);
                }
            }

             const fields = {
            Id: this.documentId, 
            Approval_Status_O_M__c: 'Calling Approval Process' 
        };

        await updateRecord({ fields });
        console.log('Field updated successfully');

            this.showToast('Success', 'Documents Uploaded Successfully', 'success');
            
                 this.handleCancel();


            // Reset after upload
            this.documentTypes = this.documentTypes.map(t => ({ ...t, fileName: [], file: [] }));
        } catch (error) {
            console.error('Upload error:', error);
            this.isLoading = false
        
           let message = 'Unknown error occurred';
    if (Array.isArray(error.body)) {
        message = error.body.map(e => e.message).join(', ');
    } else if (error.body && error.body.message) {
        message = error.body.message;
    } else if (error.message) {
        message = error.message;
    }

   // this.showToast('Error', 'File upload failed: ' + message, 'error');

        this.showToast('Warning', 'Please Capture Image', 'warning');

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
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}