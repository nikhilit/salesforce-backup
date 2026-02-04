import { LightningElement, api, wire, track } from "lwc";
import getApprovalStatus from '@salesforce/apex/UploadSiteDocumentContr.getApprovalStatus';
import uploadFiles from '@salesforce/apex/UploadSiteDocumentContr.uploadFiles';
import getUploadedFiles from '@salesforce/apex/UploadSiteDocumentContr.getUploadedFiles';
import checkWorkStep from '@salesforce/apex/UploadSiteDocumentContr.checkWorkStep';
import checkCustomerAvalibility from '@salesforce/apex/UploadSiteDocumentContr.checkCustomerAvalibility';

import getApprovalComment from '@salesforce/apex/UploadSiteDocumentContr.getApprovalComment';
import getApprovalStatusTBT from '@salesforce/apex/UploadSiteDocumentContr.getApprovalStatusTBT';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';


const MAX_BYTES = 1 * 1024 * 1024; // ~1 MB
const MIN_QUALITY = 0.30;
const START_QUALITY = 0.70;
const MAX_WIDTH = 1200;

export default class UploadSiteDocumentTesting extends LightningElement {
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

  //  @track documentTypes=[];
    @track documentTypes=[
    { label: 'Permission Letter', fileName: null },
    { label: 'HIRA', fileName: null },
   // { label: 'TBT', fileName: null },
   // { label: 'Other', fileName: null }
       { label: 'PTW', fileName: null }

  ]; 

  

  connectedCallback(){

    this.checkCustomerAvalibility();
    this.checkWorkStep();
    this.getApprovalStatusTBT();
    this.getApprovalStatus();
    this.loadUploadedFiles();
    this.getApprovalComment();

   
  }

    getApprovalStatusTBT(){
    getApprovalStatusTBT()
    .then( result=> {
        console.log('result of approval status', JSON.stringify(result));
        if(result.Approval_Status_O_M__c !='Approved'){

        this.showToast('Warning', 'Please Upload TBT Documents', 'warning');
        this.handleCancel();
      //  this.showFileUpload=false;
        

        }

    })
    .catch(error => {

        console.log('Error ::',error);
    })
     }

//       checkWorkStepCustomerAvalibility(){
//     console.log('inside check work order step');
//     checkWorkStepCustomerAvalibility({recordId:this.recordId})
//     .then( result => {

//         console.log('Result :::', result);
//         if(result !='Completed'){
//             this.showToast('Warning', 'Please Complete Check Customer Avalibility Task', 'warning');

//             this.isSubmitDisabled=true;
//             this.isClearFile=true;
//             this.isUploadDisabled=true;
//             this.handleCancel();        }
//     })
//     .catch( error => {
//         console.log('Error getting approval ::', error);
//     })
//   } 

  checkWorkStep(){
    console.log('inside check work order step');
    checkWorkStep({recordId:this.recordId})
    .then( result => {

        console.log('Result :::', result);
        if(result !='Completed'){
            this.showToast('Warning', 'Please Complete Riser Activity Possible Task', 'warning');
            this.isSubmitDisabled=true;
            this.isClearFile=true;
            this.isUploadDisabled=true;
            this.handleCancel();
        }
    })
    .catch( error => {
        console.log('Error getting approval ::', error);
    })
  }
 checkCustomerAvalibility(){
    console.log('inside  checkCustomerAvalibility');
    checkCustomerAvalibility({recordId:this.recordId})
    .then( result => {

        console.log('Result check customer avalibility:::', result);
        if(result =='No'){
            this.showToast('Warning', 'You have already checked out', 'warning');
            this.isSubmitDisabled=true;
            this.isClearFile=true;
            this.isUploadDisabled=true;
            this.handleCancel();
        }
    })
    .catch( error => {
        console.log('Error getting approval ::', error);
    })
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
                    this.isSubmitDisabled = true;
                    this.isUploadDisabled = true;
                    this.isClearFile = true;
                      this.approvalStatus=result.Approval_Status__c;
                    //  this.showIPDUploadIcons=true;
                    //  this.showFileUpload=false;
        // if(result.WorkType.Name =='Individual Permanent Disconnection'){
        // this.documentTypes = [
        //     { label: 'HIRA', fileName: null },
        //     { label: 'TBT', fileName: null },
        //     { label: 'Other', fileName: null }
        // ];
        // }

        //   if(result.WorkType.Name !='Individual Permanent Disconnection'){
        // this.documentTypes = [

        //     { label: 'Permission Letter', fileName: null },
        //     { label: 'HIRA', fileName: null },
        //     { label: 'TBT', fileName: null },
        //     { label: 'Other', fileName: null }
        // ];
        // }
    
    

                }
       
        //  if (result.WorkType.Name !='Individual Permanent Disconnection' && (result.Approval_Status__c === 'Submitted For Approval' || result.Approval_Status__c === 'Approved')) {
        //     console.log('inside 2 if condition');
        //             this.isSubmitDisabled = true;
        //             this.isUploadDisabled = true;
        //             this.isClearFile = true;
        //              this.approvalStatus=result.Approval_Status__c;

        // this.documentTypes = [
        //     { label: 'Permission Letter', fileName: null },
        //     { label: 'HIRA', fileName: null },
        //     { label: 'TBT', fileName: null },
        //     { label: 'Other', fileName: null }
        // ];
    
                      

        //         }
              
         else if (result.Approval_Status__c === 'Rejected') {
            console.log('inside else condition');
                    this.isSubmitDisabled = false;
                    this.isUploadDisabled = false;
                    this.isClearFile = false;
//  if(result.WorkType.Name =='Individual Permanent Disconnection'){
//                 console.log('inside else first if condition');

//         this.documentTypes = [
//             { label: 'HIRA', fileName: null },
//             { label: 'TBT', fileName: null },
//             { label: 'Other', fileName: null }
//         ];
//         }

        //   if(result.WorkType.Name !='Individual Permanent Disconnection'){
        //     console.log('inside else second if condition');
        // this.documentTypes = [
        //     { label: 'Permission Letter', fileName: null },
        //     { label: 'HIRA', fileName: null },
        //     { label: 'TBT', fileName: null },
        //     { label: 'Other', fileName: null }
        // ];
        // }

       // if(result.Approval_Status__c === 'Rejected'){

         //}
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



//  handleFileChange(event) {
//         console.log('handle file change::');
//        // const file = event.target.files[0];
//         const files = event.target.files;

//         const label = event.target.closest('[data-label]').dataset.label;

//         if (files && label) {
//         for (let file of files) {

//             // const [name, ext = ''] = file.name.split(/\.(?=[^\.]+$)/); 
//             //   const shortFileName = (name.substring(0, 5) || name) + (ext ? `.${ext}` : '');

//             this.fileName.push(file.name);
//             this.fileType.push(label);

//             this.selectedFile.push(file);

             
//             console.log('File Name::: ' + this.fileName);
//             console.log('File length::: ' + this.fileName.length);
//             console.log('File label::: ' + label);

//             console.log('Selected file::: ' + this.selectedFile);

//             const reader = new FileReader();

//             reader.onload = () => {
//                 this.fileData.push(reader.result.split(',')[1]);
//                 const base64 = reader.result.split(',')[1]; 

//                 console.log('File data :: '+ this.fileData);

//                 this.documentTypes = this.documentTypes.map(type => {
//                     if (type.label === label) {
//                         return {
//                             ...type,
//                             fileName: [...(type.fileName || []), file.name], 
//                             file: [...(type.file || []), file],
//                             base64: [...(type.base64 || []), base64],
//                             fileType : [...(type.label || []), label]
//                         };
//                     }
//                     return type;
//                 });

//             };

//             reader.onerror = (error) => {
//                 console.log('Error reading file:', error);
//             };

//             reader.readAsDataURL(file);

//         }

//         }
    
//            event.target.value = null;

//     }

async handleFileChange(event) {

         this.isLoading=true;

    const files = event.target.files;
    const label = event.target.closest('[data-label]').dataset.label;

    if (files && label) {
        for (let file of files) {
            try {
                const dataUrl = await this.readFileAsDataURL(file);
                const mime = file.type || 'application/octet-stream';
                const isImage = mime.startsWith('image/');

                let base64;
                let finalFile;

                if (isImage) {
                    // --- image compression logic ---
                    let compressedDataUrl = dataUrl;
                    let quality = START_QUALITY;
                    let maxWidth = MAX_WIDTH;
                    let byteCount = this.base64ToBytes(this.getBase64FromDataUrl(compressedDataUrl));

                    while (byteCount > MAX_BYTES && quality >= MIN_QUALITY) {
                        compressedDataUrl = await this.compressDataUrl(
                            compressedDataUrl,
                            mime,
                            maxWidth,
                            quality
                        );
                        base64 = this.getBase64FromDataUrl(compressedDataUrl);
                        byteCount = this.base64ToBytes(base64);

                        quality -= 0.10;
                        maxWidth = Math.max(800, Math.floor(maxWidth * 0.85));
                    }

                    base64 = this.getBase64FromDataUrl(compressedDataUrl);
                    finalFile = this.dataUrlToFile(compressedDataUrl, file.name, mime);
                } else {
                    // --- non-image files (PDF, DOCX, etc.) ---
                    base64 = this.getBase64FromDataUrl(dataUrl);
                    finalFile = file; // no compression
                }

                // push to arrays
                this.fileName.push(finalFile.name);
                this.fileType.push(label);
                this.selectedFile.push(finalFile);
                this.fileData.push(base64);

                // update documentTypes
                this.documentTypes = this.documentTypes.map(type => {
                    if (type.label === label) {
                        return {
                            ...type,
                            fileName: [...(type.fileName || []), finalFile.name],
                            file: [...(type.file || []), finalFile],
                            base64: [...(type.base64 || []), base64],
                            fileType: [...(type.fileType || []), label]
                        };
                    }
                    return type;
                });

              this.isLoading=false;


            } catch (error) {

                    this.isLoading=false;

                console.error('Error reading file:', error);
            }
        }
    }

    event.target.value = null;
}



    readFileAsDataURL(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onerror = () => reject(new Error('FileReader failed'));
        reader.onload = () => resolve(reader.result);
        reader.readAsDataURL(file);
    });
}

// detectMimeType(dataUrl) {
//     if (!dataUrl) return null;
//     const match = dataUrl.match(/^data:(image\/[a-zA-Z]+);base64,/);
//     return match ? match[1] : null;
// }

detectMimeType(dataUrl) {
    if (!dataUrl) return null;
    const match = dataUrl.match(/^data:([^;]+);base64,/); // ✅ captures everything before ;base64
    return match ? match[1] : null;
}

compressDataUrl(dataUrl, mime, maxWidth, quality) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.onload = () => {
            let { width, height } = img;
            if (width > maxWidth) {
                const scale = maxWidth / width;
                width = Math.round(width * scale);
                height = Math.round(height * scale);
            }
            const canvas = document.createElement('canvas');
            canvas.width = width;
            canvas.height = height;
            const ctx = canvas.getContext('2d');
            ctx.drawImage(img, 0, 0, width, height);
            try {
                const out = canvas.toDataURL(mime || 'image/jpeg', quality);
                resolve(out);
            } catch (err) {
                reject(err);
            }
        };
        img.onerror = reject;
        img.src = dataUrl;
    });
}

getBase64FromDataUrl(dataUrl) {
    return dataUrl.split(',')[1];
}

base64ToBytes(base64) {
    if (!base64) return 0;
    const padding = (base64.endsWith('==')) ? 2 : (base64.endsWith('=') ? 1 : 0);
    return Math.round((base64.length * 3) / 4) - padding;
}

 dataUrlToFile(dataUrl, fileName, mimeType) {
        const byteString = atob(dataUrl.split(',')[1]);
        const ab = new ArrayBuffer(byteString.length);
        const ia = new Uint8Array(ab);
        for (let i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
        }
        return new File([ab], fileName, { type: mimeType });
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
// old site document code
// import { LightningElement, api, wire, track } from "lwc";
// import getApprovalStatus from '@salesforce/apex/UploadSiteDocumentContr.getApprovalStatus';
// import uploadFiles from '@salesforce/apex/UploadSiteDocumentContr.uploadFiles';
// import getUploadedFiles from '@salesforce/apex/UploadSiteDocumentContr.getUploadedFiles';
// import checkWorkStep from '@salesforce/apex/UploadSiteDocumentContr.checkWorkStep';
// import checkWorkStepCheckin from '@salesforce/apex/UploadSiteDocumentContr.checkWorkStepCheckin';

// import getApprovalComment from '@salesforce/apex/UploadSiteDocumentContr.getApprovalComment';
// import getApprovalStatusTBT from '@salesforce/apex/UploadSiteDocumentContr.getApprovalStatusTBT';

// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// export default class UploadSiteDocumentTesting extends LightningElement {
//   @api recordId;
//   @track isLoading=false;

//   @track showFileUpload=true;
//   @track fileName=[];
//   @track selectedFile=[];
//   @track fileData=[];


//   @track showIPDUploadIcons=false;

//   @track approvalComment='';

//   @track fileType = [];

//     @track isSubmitDisabled=false;
//     @track isUploadDisabled=false;
//     @track isClearFile=false;

//    @track uploadedFileNames=[];
//   @track base64List=[];

//   @track approvalStatus='';

//     @track selectedFileData = '';

//   //  @track documentTypes=[];
//     @track documentTypes=[
//     { label: 'Permission Letter', fileName: null },
//     { label: 'HIRA', fileName: null },
//    // { label: 'TBT', fileName: null },
//    // { label: 'Other', fileName: null }
//        { label: 'PTW', fileName: null }

//   ]; 

  

//   connectedCallback(){

//     this.checkWorkStepCheckin();
//     this.checkWorkStep();
//     this.getApprovalStatusTBT();
//     this.getApprovalStatus();
//     this.loadUploadedFiles();
//     this.getApprovalComment();

   
//   }

//     getApprovalStatusTBT(){
//     getApprovalStatusTBT()
//     .then( result=> {
//         console.log('result of approval status', JSON.stringify(result));
//         if(result.Approval_Status_O_M__c !='Approved'){

//         this.showToast('Warning', 'Please Upload TBT Documents', 'warning');
//         this.handleCancel();
//       //  this.showFileUpload=false;
        

//         }

//     })
//     .catch(error => {

//         console.log('Error ::',error);
//     })
//      }

//       checkWorkStepCheckin(){
//     console.log('inside check work order step');
//     checkWorkStepCheckin({recordId:this.recordId})
//     .then( result => {

//         console.log('Result :::', result);
//         if(result !='Completed'){
//             this.showToast('Warning', 'Please Complete Check In Task', 'warning');

//             this.isSubmitDisabled=true;
//             this.isClearFile=true;
//             this.isUploadDisabled=true;
//             this.handleCancel();        }
//     })
//     .catch( error => {
//         console.log('Error getting approval ::', error);
//     })
//   }

//   checkWorkStep(){
//     console.log('inside check work order step');
//     checkWorkStep({recordId:this.recordId})
//     .then( result => {

//         console.log('Result :::', result);
//         if(result !='Completed'){
//             this.showToast('Warning', 'Please Complete Riser Activity Possible Task', 'warning');
//             this.isSubmitDisabled=true;
//             this.isClearFile=true;
//             this.isUploadDisabled=true;
//             this.handleCancel();
//         }
//     })
//     .catch( error => {
//         console.log('Error getting approval ::', error);
//     })
//   }

//    getApprovalComment(){
//     getApprovalComment({recordId:this.recordId})
//     .then( result => {

//         console.log('Get approval comment::'+ result);

//     if(result !='' && result !=null){
//         this.approvalComment='Rejected comment : ' + ' ' + result;
//     }
   
//     })
//     .catch( error => {
//         console.log('Error getting approval comment::', error);
//     })
//   }

//  loadUploadedFiles() {
//     getUploadedFiles({ recordId: this.recordId })
//         .then(result => {
//             console.log('Result uploaded files:::', result);

//             this.documentTypes = this.documentTypes.map(type => {
//                 const uploadedFiles = result
//                     .filter(file => file.ContentDocument?.LatestPublishedVersion?.O_M_Document_Types__c === type.label)
//                     .map(file => file.ContentDocument.Title);

//                 const existingNames = type.fileName || [];
//                 const mergedNames = [...existingNames, ...uploadedFiles];

//                 return {
//                     ...type,
//                     fileName: mergedNames
//                 };
//             });
//         })
//         .catch(error => {
//             console.error('Error fetching uploaded files:', error);
//         });
// }


//    getApprovalStatus(){
//     getApprovalStatus({recordId : this.recordId})
//     .then( result=> {
//         console.log('result of approval status', JSON.stringify(result));

        
//           if(result.Approval_Status__c === 'Submitted For Approval' || result.Approval_Status__c === 'Approved') {

//                     console.log('inside 1 if condition');
//                     this.isSubmitDisabled = true;
//                     this.isUploadDisabled = true;
//                     this.isClearFile = true;
//                       this.approvalStatus=result.Approval_Status__c;
//                     //  this.showIPDUploadIcons=true;
//                     //  this.showFileUpload=false;
//         // if(result.WorkType.Name =='Individual Permanent Disconnection'){
//         // this.documentTypes = [
//         //     { label: 'HIRA', fileName: null },
//         //     { label: 'TBT', fileName: null },
//         //     { label: 'Other', fileName: null }
//         // ];
//         // }

//         //   if(result.WorkType.Name !='Individual Permanent Disconnection'){
//         // this.documentTypes = [

//         //     { label: 'Permission Letter', fileName: null },
//         //     { label: 'HIRA', fileName: null },
//         //     { label: 'TBT', fileName: null },
//         //     { label: 'Other', fileName: null }
//         // ];
//         // }
    
    

//                 }
       
//         //  if (result.WorkType.Name !='Individual Permanent Disconnection' && (result.Approval_Status__c === 'Submitted For Approval' || result.Approval_Status__c === 'Approved')) {
//         //     console.log('inside 2 if condition');
//         //             this.isSubmitDisabled = true;
//         //             this.isUploadDisabled = true;
//         //             this.isClearFile = true;
//         //              this.approvalStatus=result.Approval_Status__c;

//         // this.documentTypes = [
//         //     { label: 'Permission Letter', fileName: null },
//         //     { label: 'HIRA', fileName: null },
//         //     { label: 'TBT', fileName: null },
//         //     { label: 'Other', fileName: null }
//         // ];
    
                      

//         //         }
              
//          else if (result.Approval_Status__c === 'Rejected') {
//             console.log('inside else condition');
//                     this.isSubmitDisabled = false;
//                     this.isUploadDisabled = false;
//                     this.isClearFile = false;
// //  if(result.WorkType.Name =='Individual Permanent Disconnection'){
// //                 console.log('inside else first if condition');

// //         this.documentTypes = [
// //             { label: 'HIRA', fileName: null },
// //             { label: 'TBT', fileName: null },
// //             { label: 'Other', fileName: null }
// //         ];
// //         }

//         //   if(result.WorkType.Name !='Individual Permanent Disconnection'){
//         //     console.log('inside else second if condition');
//         // this.documentTypes = [
//         //     { label: 'Permission Letter', fileName: null },
//         //     { label: 'HIRA', fileName: null },
//         //     { label: 'TBT', fileName: null },
//         //     { label: 'Other', fileName: null }
//         // ];
//         // }

//        // if(result.Approval_Status__c === 'Rejected'){

//          //}
//                     this.approvalStatus=result.Approval_Status__c;
          
//                     setTimeout(() => {
//         let updatedTypes = JSON.parse(JSON.stringify(this.documentTypes));
//         updatedTypes = updatedTypes.map(type => ({
//             ...type,
//             fileName: [],
//             file: [],
//             base64: [],
//             fileType: []
//         }));
//         this.documentTypes = updatedTypes;
//     }, 100); 

//       console.log('Approval Status: ',this.approvalStatus);
// }
//   })
//   .catch(error=>{
//     console.log(error);
//   })
// }



//  handleFileChange(event) {
//         console.log('handle file change::');
//        // const file = event.target.files[0];
//         const files = event.target.files;

//         const label = event.target.closest('[data-label]').dataset.label;

//         if (files && label) {
//         for (let file of files) {

//             // const [name, ext = ''] = file.name.split(/\.(?=[^\.]+$)/); 
//             //   const shortFileName = (name.substring(0, 5) || name) + (ext ? `.${ext}` : '');

//             this.fileName.push(file.name);
//             this.fileType.push(label);

//             this.selectedFile.push(file);

             
//             console.log('File Name::: ' + this.fileName);
//             console.log('File length::: ' + this.fileName.length);
//             console.log('File label::: ' + label);

//             console.log('Selected file::: ' + this.selectedFile);

//             const reader = new FileReader();

//             reader.onload = () => {
//                 this.fileData.push(reader.result.split(',')[1]);
//                 const base64 = reader.result.split(',')[1]; 

//                 console.log('File data :: '+ this.fileData);

//                 this.documentTypes = this.documentTypes.map(type => {
//                     if (type.label === label) {
//                         return {
//                             ...type,
//                             fileName: [...(type.fileName || []), file.name], 
//                             file: [...(type.file || []), file],
//                             base64: [...(type.base64 || []), base64],
//                             fileType : [...(type.label || []), label]
//                         };
//                     }
//                     return type;
//                 });

//             };

//             reader.onerror = (error) => {
//                 console.log('Error reading file:', error);
//             };

//             reader.readAsDataURL(file);

//         }

//         }
    
//            event.target.value = null;

//     }

//      handleUpload(){
//         console.log('handle upload :::: ');
        
//          if(this.fileName == ''){
//             this.showToast('Warning', 'Please select a file to upload.', 'warning');

//         }
//            console.log('File  name ::: ' + this.fileName);

//         let filesProcessed = 0;
//         for (let i = 0; i < this.selectedFile.length; i++) {
//             const file = this.selectedFile[i];
//             console.log('select file  :: '+ this.selectedFile);
//             const reader = new FileReader();
    
//             reader.onloadend = (()  => {
//                 const currentIndex = i; 
//                 return (event) => {
        
//                 const base64Data = reader.result.split(',')[1];
//                 console.log('base64Data ::: '+ base64Data);
//                 this.base64List.push(base64Data);
//                 filesProcessed++;
    
//                 if (filesProcessed === this.selectedFile.length) {
//                     console.log('inside call uploadfile method');
//                     // All files processed
//                     this.uploadFile();
//                 }
//             };
              
//         })();
//         reader.onerror = (error) => {
//             console.error('File read error:', error);
//         };
//             reader.readAsDataURL(file);
//     }

// }
        
    

//     uploadFile(){
//         this.isLoading = true;
//         console.log('inside upload file::: ');
//                 console.log('file types::: ', this.fileType);

//         uploadFiles({
//             recordId : this.recordId,
//             fileName: this.fileName,
//             base64Data: this.base64List,
//             fileType : this.fileType                     
//         })
//             .then((result) => {
//                 console.log('result sucess');
//                 this.showToast('Success', 'Documents Uploaded Successfully!', 'success');
//                 this.isLoading = false;
//                 // this.showFieldUpdate=true;
//                 // this.showFileUpload=false;
//                 //this.documentTypes='';
//                 //this.fileName='';    

//                 this.handleCancel();
//                // this.getBusinessPartnerDetails();
//             })
//             .catch((error) => {

//                 this.showToast('Error', 'File upload failed: ' + error.body.message, 'error');
//                 this.isLoading = false;
//                   console.log('Error ::: ' + JSON.stringify(error));
//             });
//     }

// // handleClearFile(event) {
// //         const label = event.target.dataset.label;
// //         console.log('label:', label);
// //         const index = this.fileName.findIndex((name, i) => {
// //             return this.documentTypes[i]?.label === label;
// //         });
// //         if (index !==-1) {
// //             this.fileName.splice(index, 1);
// //             this.selectedFile.splice(index, 1);
// //             this.fileData.splice(index, 1);
// //             console.log('fileName ::: '+ this.fileName);
// //         }

// //         this.documentTypes = this.documentTypes.map(type => {
// //             if (type.label === label) {
// //                 return {
// //                     ...type,
// //                     file: null,
// //                     fileName: '',
// //                     base64: ''
// //                 };
// //             }
// //             return type;
// //         }); 
// //     }

// handleClearFile(event) {
//     const label = event.target.dataset.label;
//     const nameToRemove = event.target.dataset.name;
//     console.log('Clearing file:', nameToRemove, 'from label:', label);

//     // Update documentTypes
//     this.documentTypes = this.documentTypes.map(type => {
//         if (type.label === label && Array.isArray(type.fileName)) {
//             const index = type.fileName.indexOf(nameToRemove);
//             if (index !== -1) {
//                 // Remove the specific file from arrays in that document type
//                 const updatedFileNames = [...type.fileName];
//                 updatedFileNames.splice(index, 1);

//                 const updatedFiles = type.file ? [...type.file] : [];
//                 updatedFiles.splice(index, 1);

//                 const updatedBase64s = type.base64 ? [...type.base64] : [];
//                 updatedBase64s.splice(index, 1);

//                 return {
//                     ...type,
//                     fileName: updatedFileNames,
//                     file: updatedFiles,
//                     base64: updatedBase64s
//                 };
//             }
//         }
//         return type;
//     });

//     // Optionally clean from flat arrays if you're maintaining them too
//     const globalIndex = this.fileName.indexOf(nameToRemove);
//     if (globalIndex !== -1) {
//         this.fileName.splice(globalIndex, 1);
//         this.selectedFile.splice(globalIndex, 1);
//         this.fileData.splice(globalIndex, 1);
//     }

//     console.log('Updated fileName:', this.fileName);
// }


//     handleCancel() {
//            setTimeout(() => {
//             history.back();
//         }, 1000); 
//       }

//       showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
//     }

   
// }