import { LightningElement, api, track } from "lwc";
import getApprovalStatus from '@salesforce/apex/UploadHIRADocumentContr.getApprovalStatus';
import uploadFiles from '@salesforce/apex/UploadHIRADocumentContr.uploadFiles';
import getUploadedFiles from '@salesforce/apex/UploadHIRADocumentContr.getUploadedFiles';
//import checkWorkStep from '@salesforce/apex/UploadHIRADocumentContr.checkWorkStep';
import getApprovalComment from '@salesforce/apex/UploadHIRADocumentContr.getApprovalComment';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UploadHIRADocument extends LightningElement {

  @api recordId;
  @track isLoading=false;

  @track showFileUpload=true;
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
   
    { label: 'HIRA', fileName: null },
  ]; 

  

   connectedCallback(){
//     this.checkWorkStep();
    this.getApprovalStatus();
    this.loadUploadedFiles();
    this.getApprovalComment();

   
  }

//   checkWorkStep(){
//     console.log('inside check work order step');
//     checkWorkStep({recordId:this.recordId})
//     .then( result => {

//         console.log('Result :::', result);
//         if(result !='Completed'){
//             this.showToast('Warning', 'Please Complete Check-in', 'warning');
//             this.isSubmitDisabled=true;
//             this.isClearFile=true;
//             this.isUploadDisabled=true;
//         }
//     })
//     .catch( error => {
//         console.log('Error getting approval ::', error);
//     })
//   }

   getApprovalComment(){
    getApprovalComment({recordId:this.recordId})
    .then( result => {

        console.log('Get approval comment::'+ result);

    if(result !=''){
        this.approvalComment='Rejected comment : ' + ' ' + result;
    }
   
    })
    .catch( error => {
        console.log('Error getting approval comment::', error);
    })
  }

 loadUploadedFiles() {
    getUploadedFiles({ recordId: this.recordId })
        .then(result => {
            console.log('Result uploaded files:::', result);

            this.documentTypes = this.documentTypes.map(type => {
                const uploadedFiles = result
                    .filter(file => file.ContentDocument?.LatestPublishedVersion?.O_M_Document_Types__c === type.label)
                    .map(file => file.ContentDocument.Title);

                const existingNames = type.fileName || [];
                const mergedNames = [...existingNames, ...uploadedFiles];

                return {
                    ...type,
                    fileName: mergedNames
                };
            });
        })
        .catch(error => {
            console.error('Error fetching uploaded files:', error);
        });
}


   getApprovalStatus(){
    getApprovalStatus({recordId : this.recordId})
    .then( result=> {
        console.log('result of approval status', JSON.stringify(result));

        
          if(result.Approval_Status__c === 'Submitted For Approval' || result.Approval_Status__c === 'Approved') {

                    console.log('inside 1 if condition');
                    this.isSubmitDisabled = false;
                    this.isUploadDisabled = false;
                    this.isClearFile = true;
                      this.approvalStatus=result.Approval_Status__c;
                
       
    
    

                }
       
       
              
         else if (result.Approval_Status__c === 'Rejected') {
            console.log('inside else condition');
                    this.isSubmitDisabled = false;
                    this.isUploadDisabled = false;
                    this.isClearFile = false;
                    this.approvalStatus=result.Approval_Status__c;
          
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

      console.log('Approval Status: ',this.approvalStatus);
}
  })
  .catch(error=>{
    console.log(error);
  })
}



 handleFileChange(event) {
        console.log('handle file change::');
       // const file = event.target.files[0];
        const files = event.target.files;

        const label = event.target.closest('[data-label]').dataset.label;

        if (files && label) {
        for (let file of files) {

           
            this.fileName.push(file.name);
            this.fileType.push(label);

            this.selectedFile.push(file);

             
            console.log('File Name::: ' + this.fileName);
            console.log('File length::: ' + this.fileName.length);
            console.log('File label::: ' + label);

            console.log('Selected file::: ' + this.selectedFile);

            const reader = new FileReader();

            reader.onload = () => {
                this.fileData.push(reader.result.split(',')[1]);
                const base64 = reader.result.split(',')[1]; 

                console.log('File data :: '+ this.fileData);

                this.documentTypes = this.documentTypes.map(type => {
                    if (type.label === label) {
                        return {
                            ...type,
                            fileName: [...(type.fileName || []), file.name], 
                            file: [...(type.file || []), file],
                            base64: [...(type.base64 || []), base64],
                            fileType : [...(type.label || []), label]
                        };
                    }
                    return type;
                });

            };

            reader.onerror = (error) => {
                console.log('Error reading file:', error);
            };

            reader.readAsDataURL(file);

        }

        }
    
           event.target.value = null;

    }

     handleUpload(){
        console.log('handle upload :::: ');
        
         if(this.fileName == ''){
            this.showToast('Warning', 'Please select a file to upload.', 'warning');

        }
           console.log('File  name ::: ' + this.fileName);

        let filesProcessed = 0;
        for (let i = 0; i < this.selectedFile.length; i++) {
            const file = this.selectedFile[i];
            console.log('select file  :: '+ this.selectedFile);
            const reader = new FileReader();
    
            reader.onloadend = (()  => {
                const currentIndex = i; 
                return (event) => {
        
                const base64Data = reader.result.split(',')[1];
                console.log('base64Data ::: '+ base64Data);
                this.base64List.push(base64Data);
                filesProcessed++;
    
                if (filesProcessed === this.selectedFile.length) {
                    console.log('inside call uploadfile method');
                    // All files processed
                    this.uploadFile();
                }
            };
              
        })();
        reader.onerror = (error) => {
            console.error('File read error:', error);
        };
            reader.readAsDataURL(file);
    }

}
        
    

    uploadFile(){
        this.isLoading = true;
        console.log('inside upload file::: ');
                console.log('file types::: ', this.fileType);

        uploadFiles({
            recordId : this.recordId,
            fileName: this.fileName,
            base64Data: this.base64List,
            fileType : this.fileType                     
        })
            .then((result) => {
                console.log('result sucess');
                this.showToast('Success', 'Documents Uploaded Successfully!', 'success');
                this.isLoading = false;
                // this.showFieldUpdate=true;
                // this.showFileUpload=false;
                //this.documentTypes='';
                //this.fileName='';    

                this.handleCancel();
               // this.getBusinessPartnerDetails();
            })
            .catch((error) => {

                this.showToast('Error', 'File upload failed: ' + error.body.message, 'error');
                this.isLoading = false;
                  console.log('Error ::: ' + JSON.stringify(error));
            });
    }

// handleClearFile(event) {
//         const label = event.target.dataset.label;
//         console.log('label:', label);
//         const index = this.fileName.findIndex((name, i) => {
//             return this.documentTypes[i]?.label === label;
//         });
//         if (index !==-1) {
//             this.fileName.splice(index, 1);
//             this.selectedFile.splice(index, 1);
//             this.fileData.splice(index, 1);
//             console.log('fileName ::: '+ this.fileName);
//         }

//         this.documentTypes = this.documentTypes.map(type => {
//             if (type.label === label) {
//                 return {
//                     ...type,
//                     file: null,
//                     fileName: '',
//                     base64: ''
//                 };
//             }
//             return type;
//         }); 
//     }

handleClearFile(event) {
    const label = event.target.dataset.label;
    const nameToRemove = event.target.dataset.name;
    console.log('Clearing file:', nameToRemove, 'from label:', label);

    // Update documentTypes
    this.documentTypes = this.documentTypes.map(type => {
        if (type.label === label && Array.isArray(type.fileName)) {
            const index = type.fileName.indexOf(nameToRemove);
            if (index !== -1) {
                // Remove the specific file from arrays in that document type
                const updatedFileNames = [...type.fileName];
                updatedFileNames.splice(index, 1);

                const updatedFiles = type.file ? [...type.file] : [];
                updatedFiles.splice(index, 1);

                const updatedBase64s = type.base64 ? [...type.base64] : [];
                updatedBase64s.splice(index, 1);

                return {
                    ...type,
                    fileName: updatedFileNames,
                    file: updatedFiles,
                    base64: updatedBase64s
                };
            }
        }
        return type;
    });

    // Optionally clean from flat arrays if you're maintaining them too
    const globalIndex = this.fileName.indexOf(nameToRemove);
    if (globalIndex !== -1) {
        this.fileName.splice(globalIndex, 1);
        this.selectedFile.splice(globalIndex, 1);
        this.fileData.splice(globalIndex, 1);
    }

    console.log('Updated fileName:', this.fileName);
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