import { LightningElement,api,track } from 'lwc';
import saveImage from '@salesforce/apex/CheckCustomerAvilablityContr.saveImage';
import updateWorkOrder from '@salesforce/apex/CheckCustomerAvilablityContr.updateWorkOrder';
import getWOrderWType from '@salesforce/apex/CheckCustomerAvilablityContr.getWOrderWType';
//import fieldPicklistValue from '@salesforce/apex/O_MWorkOrderAccountInfoController.fieldPicklistValue';
import customerNameAndFlatNumberData from '@salesforce/apex/CheckCustomerAvilablityContr.customerNameAndFlatNumberData';
import getApprovalStatus from '@salesforce/apex/CheckCustomerAvilablityContr.getApprovalStatus';
import checkWorkStep from '@salesforce/apex/CheckCustomerAvilablityContr.checkWorkStep';
import uploadFiles from '@salesforce/apex/CheckCustomerAvilablityContr.uploadFiles';
import LightningAlert from 'lightning/alert';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';


const MAX_BYTES = 1 * 1024 * 1024; // ~1 MB
const MIN_QUALITY = 0.30;
const START_QUALITY = 0.70;
const MAX_WIDTH = 1200;


export default class CheckCustomerAvailabilityComp extends LightningElement {

@api recordId;

@track wOWorkType='';

@track ReasonForUnavailability=false;

@track showCheckBox=true;

@track showEnterCustomerNameFlatNumber=false;

@track customerNotAvilableRemark='';
get availabilityOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }


@track imageUploadPage=true;

       connectedCallback() {
           console.log('showCheckBox form',this.showCheckBox); 
            this.setPhotoUploadSlots();
            this.getApprovalStatus();
             this.getWOrderWType();
             this.checkWorkStep();
       // this.fieldPicklistValue();


       }

       /* tbt document from documnet__c object
         getApprovalStatus(){
    getApprovalStatus()
    .then( result=> {
        console.log('result of approval status', JSON.stringify(result));
        if(result.Approval_Status_O_M__c !='Approved'){

        this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
        this.handleCancel();
        this.showCheckBox = false;
        

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
        if(result.Approval_Status__c !='Approved'){

        // this.showtoast('Warning', 'Please Upload TBT Documents', 'warning');
        // this.handleCancel();
        // this.showCheckBox = false;
         LightningAlert.open({
            message: 'Please Upload TBT Documents',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
        this.handleCancel();
        this.showCheckBox = false;
         });

        }

    })
    .catch(error => {

        console.log('Error ::',error);
    })
     }

     checkWorkStep(){
    console.log('inside check work order step');
    checkWorkStep({recordId:this.recordId})
    .then( result => {

        console.log('Result :::', result);
        if(result !='Completed'){
            // this.showtoast('Warning', 'Please Complete Check In Task', 'warning');
            //  this.showCheckBox = false;
            //  this.handleCancel();
              LightningAlert.open({
            message: 'Please Complete Check In Task',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
        this.handleCancel();
        this.showCheckBox = false;
         });

        }
    })
    .catch( error => {
        console.log('Error getting approval ::', error);
    })
  }

       @track load=false;

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

//  @track photoUploadSlots=[];
//     noOfPhotos = 2;



    @track yearOfAMC=false;
    @track maintenanceDoneYearOfAMC='';


        @track customerAvailability='';
        @track customerNotAvilable = false;
        @track customerAvilable = false;
        @track otherRemark=false;
        @track otherRemarkValue='';
       //  @track showNext=false;

        @track ReasonForUnavailability=false;


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
   
    { label: 'Upload Images', fileName: null },
  ]; 

    // @track rMCloserRemark ='';



     // @track reasonUnavailability = [];


    //   @track objectName='WorkOrder';
    //   @track fieldName='Reason_for_Unavailability__c';

          @track unavailability;


    //   fieldPicklistValue(){
    //     fieldPicklistValue({objectName:this.objectName, fieldName:this.fieldName})
    //     .then( result => {
    //         console.log('Rsult of picklist ::', result);
    //         this.reasonUnavailability=result;
    //         })
    //     .catch(error => {
    //             console.error('Error loading picklist values:', error);
    //         });
    // }

    async handleFileChange(event) {

         this.load=true;

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

              this.load=false;


            } catch (error) {

                    this.load=false;

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
            // this.showtoast('Warning', 'Please select a file to upload.', 'warning');
            // this.load=false;
             LightningAlert.open({
            message: 'Please select a file to upload.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
                    this.load=false;

         });

            return;
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
        this.load = true;
        console.log('inside upload file::: ');
                console.log('file types::: ', this.fileType);

        uploadFiles({
           // recordId : this.recordId,
            fileName: this.fileName,
            base64Data: this.base64List,
            fileType : this.fileType ,
            recordId : this.recordId                    
        })
            .then((result) => {
                console.log('result sucess');
             //   this.showToast('Success', 'Documents Uploaded Successfully!', 'success');
                this.load = false;
                // this.showFieldUpdate=true;
                // this.showFileUpload=false;
                //this.documentTypes='';
                //this.fileName='';    

              //  this.handleCancel();
               // this.getBusinessPartnerDetails();
            })
            .catch((error) => {

             //   this.showToast('Error', 'File upload failed: ' + error.body.message, 'error');
                this.load = false;
                  console.log('Error ::: ' + JSON.stringify(error));
            });
    }


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

handleChangeYearOfAMC(event){

    console.log('Maintennace year done change ::', event.target.value);

    this.maintenanceDoneYearOfAMC=event.target.value;


}



         getWOrderWType(){
        getWOrderWType({recordId :this.recordId})
        .then( result => {
            console.log('Result ::', result);
        this.wOWorkType=result;

        })
        .catch(error => {
            console.log('Error ::', error);
        })
    }


         handleAvailabilityChange(event) {
        if(event.target.value == 'Yes'){

        this.customerAvailability = event.target.value;
        this.customerAvilable=true;
        this.customerNotAvilable = false;
        this.customerNotAvilableRemark='';
        this.ReasonForUnavailability=false;


        }
        if(event.target.value == 'No'){

        this.customerAvailability = event.target.value;
            this.customerAvilable=false;

               if(this.wOWorkType=='Riser Maintenance'){
          

                this.ReasonForUnavailability=true;
                this.showCheckBox=false;
              //   this.showNext=true;

          //   this.fieldPicklistValue();

        }

         if(this.wOWorkType=='Riser Painting'){
          

                this.ReasonForUnavailability=true;
                this.showCheckBox=false;
             //    this.showNext=true;
              
           //  this.fieldPicklistValue();

        }

        if(this.wOWorkType=='Riser Replacement'){
          

                this.ReasonForUnavailability=true;
                this.showCheckBox=false;
              //   this.showNext=true;

           //  this.fieldPicklistValue();

        }

        }

         }

          handlereasonForUnavailability(event) {
        console.log('event detail value ::', event.detail.value);
        console.log('event detail value ::', event.target.value);

        this.unavailability = event.detail.value;

        if(this.unavailability =='Others'){

            this.otherRemark=true;
            this.showEnterCustomerNameFlatNumber=false;
            this.yearOfAMC = false;
            this.otherRemarkValue='';
            this.maintenanceDoneYearOfAMC='';

        }

        if(this.unavailability !='Others'){

          //  this.otherRemark=false;

                this.otherRemark=true;
            this.otherRemarkValue='';
          this.maintenanceDoneYearOfAMC='';


        }

         if(this.unavailability =='Maintenance Already Done - Year of AMC'){

          //  this.otherRemark=false;
            this.yearOfAMC = true;
            this.showEnterCustomerNameFlatNumber=false;

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

            this.showEnterCustomerNameFlatNumber=true;
           // this.otherRemark=false;
            this.otherRemark=true;
            this.otherRemarkValue='';
            this.maintenanceDoneYearOfAMC='';


        }
    }

     @track customerNameFlatNumberList = [{
       // itemCode: '',
       // itemDescription: '',
       // unit: '',
       customerName : '',
         flatNumber: ''
    }];

     addCustomerNameFlatNumberRow() {
        console.log('Adding new customer name and flat number row');
        this.customerNameFlatNumberList.push({
           customerName : '',
            flatNumber: ''
        });
    }

    removeCustomerNameFlatNumberRow(event) {
        const index = event.target.dataset.index;
        console.log(`Removing customer name and flat number row at index: ${index}`);
        if (this.customerNameFlatNumberList.length > 1) {
            this.customerNameFlatNumberList.splice(index, 1);
        }
    }


     handleCustomerNameFlatNumberChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        console.log(`customer name and flat number Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        this.customerNameFlatNumberList[index][field] = value;
    }

      hasValidCustomerNameFlatNumberData() {
        return this.customerNameFlatNumberList.some(row => 
           (row.customerName && row.customerName.trim() !== '') ||
            (row.flatNumber && row.flatNumber.trim() !== '')
        );
    }


    handleOtherRemark(event){

        this.otherRemarkValue = event.target.value;
    }

    // handleRMCloserRemark(event){

    //     this.rMCloserRemark = event.target.value;
    // }


  handleCustomerNotAvilableRemark(event){

        this.customerNotAvilableRemark = event.target.value;
    }

  /*  handleImageCapturePage() {

         if(!this.unavailability){

  this.showtoast('Warning', 'Please Select Reason.', 'warning');

    return;
    }

     if(!this.otherRemarkValue && this.otherRemark){

  this.showtoast('Warning', 'Remark is required.', 'warning');

    return;
    }

     if(!this.maintenanceDoneYearOfAMC && this.yearOfAMC){

  this.showtoast('Warning', 'Maintenance already done-year of AMC is Required.', 'warning');

    return;
    }
       
       // this.formSecondPage = false;
        this.setPhotoUploadSlots();
        this.imageUploadPage = true;
      //  this.showNext=false;
      //  console.log('show next ::'+ this.showNext);
    } */

    //  handleRMCloserRemark(event){

    //     this.rMCloserRemark = event.target.value;
    // }

     handleCancel() {
         setTimeout(() => {
            history.back();
        }, 1000); 
      
        
      }


    handleCusAvilSave(){

        this.load=true;

        updateWorkOrder({recordId : this.recordId, customerAvailability : this.customerAvailability})
        .then( result => {

            console.debug('Result ::', result);
             this.showtoast('Success', 'Details saved successfully!', 'success');
            this.load=false;
             this.handleCancel();
              LightningAlert.open({
            message: 'Details saved successfully!',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
        this.handleCancel();
            this.load=false;
         });


        })
        .catch(error => {

            console.debug('Error:::', error);
            this.load=false;
        })

    }

      async handleFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.photoUploadSlots =event.detail.steps;

        for (let i = 0; i < photoUploadSlots.length; i++) {
        let slot = photoUploadSlots[i];
            console.log(`🔄 Processing Photo ${i + 1}`);

            if (slot.base64Data) {
                try {
                    // Add prefix if missing
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;

                    // 🔍 Original size in MB
                    const originalBytes = atob(fullBase64.split(',')[1]).length;
                    const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

                    // Convert to blob and compress
                    const blob = this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);

                    // Convert compressed Blob back to base64
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    const compressedBytes = atob(compressedBase64).length;
                    const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

                    // Store compressed result
                    slot.base64Data = compressedBase64;

                } catch (error) {
                //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);

                // Only show toast if compressed base64 is not usable
                if (!slot.base64Data || slot.base64Data.length < 100) {
                console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
                } else {
                    console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
                }
            }


            } else {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
            }
        }

       // this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set');
    } 



    
   async handleFinalSave() {
       // const workStepName = 'Letters/Notices';
        // const allFilesSelected = this.photoUploadSlots.length === 2 &&
        //     this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        // if (!allFilesSelected) {
        //     this.load = false;
        //     //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
        //     this.showtoast('Warning', 'Please Capture 2 photos.', 'warning');
        //     return;
        // }

        // if(!this.rMCloserRemark){

        //  this.showtoast('Warning', 'Please Enter Closer Remark.', 'warning');
        // return;
        // }

           if(!this.unavailability){

 // this.showtoast('Warning', 'Please Select Reason.', 'warning');
 LightningAlert.open({
            message: 'Please Select Reason.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });

    return;
    }

//      if(!this.otherRemarkValue && this.otherRemark){

//   this.showtoast('Warning', 'Remark is required.', 'warning');

//     return;
//     }

//      if(!this.maintenanceDoneYearOfAMC && this.yearOfAMC){

//   this.showtoast('Warning', 'Maintenance already done-year of AMC is Required.', 'warning');

//     return;
//     }

         if(!this.otherRemarkValue && this.otherRemark){

  //this.showtoast('Warning', 'Please Enter Remark.', 'warning');
 LightningAlert.open({
            message: 'Please Enter Remark.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
    return;
    }

     if(!this.maintenanceDoneYearOfAMC && this.yearOfAMC){

 // this.showtoast('Warning', 'Maintenance already done-year of AMC is Required.', 'warning');
 LightningAlert.open({
            message: 'Maintenance already done-year of AMC is Required.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
    return;
    }

     if(this.fileName == ''){
           // this.showtoast('Warning', 'Please select a file to upload.', 'warning');
           // this.load=false;
             LightningAlert.open({
            message: 'Please select a file to upload.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
                    this.load=false;
         });

            return;
        }
        else if(this.fileName != ''){

             this.handleUpload();
        }

        this.load = true;

        //  var imagesList = [];
        //         this.photoUploadSlots.forEach(item => {
        //             imagesList.push({
        //                 base64Data: item.base64Data,
        //                 fileName: item.fileName,
        //                 label: item.label
        //             })
        //         })

        //         var temp = this.uploadFile(imagesList);



        saveImage({
          //  listFiles: imagesList,
            recordId: this.recordId,
            reasonUnavailability : this.unavailability,
            otherRemarkValue : this.otherRemarkValue,
           // rMCloserRemark : this.rMCloserRemark,
            customerAvailability : this.customerAvailability,
            maintenanceDoneYearOfAMC : this.maintenanceDoneYearOfAMC
           
        })
        .then((result) => {

            // this.showtoast('Success', 'Details saved successfully!', 'success');
            // this.load = false;
            //  this.handleCancel();
            LightningAlert.open({
            message: 'Please select a file to uploadDetails saved successfully!.',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                    this.load=false;
                                 this.handleCancel();

         });
              if (this.customerNameFlatNumberList.length > 0 && this.hasValidCustomerNameFlatNumberData()) {
                console.log('🔧 Saving customer name and flat number Details:', JSON.stringify(this.customerNameFlatNumberList));

                customerNameAndFlatNumberData({
                    recordId: this.recordId,
                    customerNameFlatNumberList: this.customerNameFlatNumberList

                });

                 }

           // history.back();

         //   this.dispatchEvent(new CustomEvent('cancel'));
        })
        .catch(error => {
            this.load = false;
            //console.error('❌ Save error:', JSON.stringify(error, null, 2));
            const message = error?.body?.message || error?.message || 'Unknown error occurred';
            this.showtoast('Error', message, 'error');
        });
    }

    //  uploadFile(imagesList) {

    // }

    async base64ToBlob(base64Data) {
        const byteString = atob(base64Data.split(',')[1]);
        const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];
        const ab = new ArrayBuffer(byteString.length);
        const ia = new Uint8Array(ab);
        for (let i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
        }
        return new Blob([ab], { type: mimeString });
    }

    async compressImageFromURL(imageUrl) {
        return new Promise((resolve, reject) => {
            const img = new Image();

            img.onload = () => {
                try {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');
                    const maxWidth = 1600;
                    const maxHeight = 1600;
                    let width = img.width;
                    let height = img.height;

                    const ratio = Math.min(maxWidth / width, maxHeight / height);
                    width *= ratio;
                    height *= ratio;

                    canvas.width = width;
                    canvas.height = height;
                    ctx.drawImage(img, 0, 0, width, height);

                        try {
                            canvas.toBlob(
                                (blob) => {
                                    if (blob) {
                                        resolve(blob);
                                    } else {
                                        console.warn('⚠️ toBlob returned null. Possibly tainted canvas or unsupported format.');
                                        reject(new Error('Canvas compression failed. Blob was null.'));
                                    }
                                },
                                'image/jpeg',
                                9.1
                            );
                        } catch (err) {
                            console.error('❌ Error during canvas.toBlob execution:', err);
                            reject(new Error('Exception during canvas.toBlob: ' + err.message));
                        }
                } catch (error) {
                    reject(new Error('Error during image compression: ' + error.message));
                }
            };

            img.onerror = () => {
                reject(new Error('Error loading image.'));
            };

            img.crossOrigin = 'anonymous';
            img.src = imageUrl;
        });
    }

    async convertBlobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    }

     setPhotoUploadSlots() {
        this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label: `Photo ${index + 1}`,
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }



  /*  setPhotoUploadSlots() {
        this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label: `Photo ${index + 1}`,
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }

  async handleFile(event) {
        console.log('📥 inside handleFile');
        //let newSlots = event.detail.steps;
        this.photoUploadSlots =event.detail.steps;
        for (let i = 0; i < photoUploadSlots.length; i++) {
        let slot = photoUploadSlots[i];
            console.log(`🔄 Processing Photo ${i + 1}`);

            if (slot.base64Data) {
                try {
                    // Add prefix if missing
                    const fullBase64 = slot.base64Data.startsWith('data:image')
                        ? slot.base64Data
                        : `data:image/jpeg;base64,${slot.base64Data}`;

                    // 🔍 Original size in MB
                    const originalBytes = atob(fullBase64.split(',')[1]).length;
                    const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

                    // Convert to blob and compress
                    const blob = this.base64ToBlob(fullBase64);
                    const imageUrl = URL.createObjectURL(blob);
                    const compressedBlob = await this.compressImageFromURL(imageUrl);

                    // Convert compressed Blob back to base64
                    const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
                    const compressedBytes = atob(compressedBase64).length;
                    const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
                    console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

                    // Store compressed result
                    slot.base64Data = compressedBase64;

                } catch (error) {
                //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);

                // Only show toast if compressed base64 is not usable
                if (!slot.base64Data || slot.base64Data.length < 100) {
                console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
                } else {
                    console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
                }
            }


            } else {
                console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
            }
        }

      //  this.photoUploadSlots = newSlots;
        console.log('✅ Final photoUploadSlots set');
    } 


      async base64ToBlob(base64Data) {
        const byteString = atob(base64Data.split(',')[1]);
        const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];
        const ab = new ArrayBuffer(byteString.length);
        const ia = new Uint8Array(ab);
        for (let i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
        }
        return new Blob([ab], { type: mimeString });
    }

  async compressImageFromURL(imageUrl) {
        return new Promise((resolve, reject) => {
            const img = new Image();

            img.onload = () => {
                try {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');
                    const maxWidth = 2400;
                    const maxHeight = 2400;
                    let width = img.width;
                    let height = img.height;

                    const ratio = Math.min(maxWidth / width, maxHeight / height);
                    width *= ratio;
                    height *= ratio;

                    canvas.width = width;
                    canvas.height = height;
                    ctx.drawImage(img, 0, 0, width, height);

                        try {
                            canvas.toBlob(
                                (blob) => {
                                    if (blob) {
                                        resolve(blob);
                                    } else {
                                        console.warn('⚠️ toBlob returned null. Possibly tainted canvas or unsupported format.');
                                        reject(new Error('Canvas compression failed. Blob was null.'));
                                    }
                                },
                                'image/jpeg',
                                9.1
                            );
                        } catch (err) {
                            console.error('❌ Error during canvas.toBlob execution:', err);
                            reject(new Error('Exception during canvas.toBlob: ' + err.message));
                        }
                } catch (error) {
                    reject(new Error('Error during image compression: ' + error.message));
                }
            };

            img.onerror = () => {
                reject(new Error('Error loading image.'));
            };

            img.crossOrigin = 'anonymous';
            img.src = imageUrl;
        });
    }

   async convertBlobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    }

     async handleCustNotAvialSave() {
       // const workStepName = 'Letters/Notices';
        const allFilesSelected = this.photoUploadSlots.length === 1 &&
            this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.load = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
            this.showtoast('Warning', 'Please Capture 1 photo.', 'warning');
            return;
        }

        if(!this.customerNotAvilableRemark){

         this.showtoast('Warning', 'Please Enter Remark.', 'warning');
         return;
 
        }

       

        this.load = true;

          var imagesList = [];
                this.photoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                var temp = this.uploadFile(imagesList);


        saveImage({
            listFiles: imagesList,
            recordId: this.recordId,
            customerNotAvilableRemark : this.customerNotAvilableRemark,
            customerAvailability : this.customerAvailability
           
        })
        .then((result) => {
            this.showtoast('Success', 'Details saved successfully!', 'success');
            this.load = false;
             this.handleCancel();
        })
        .catch(error => {
            this.load = false;
            const message = error?.body?.message || error?.message || 'Unknown error occurred';
            this.showtoast('Error', message, 'error');
        });
    }

 
    
    
    uploadFile(imagesList) {

    }


    */


     showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }




}