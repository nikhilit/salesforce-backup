import { LightningElement, api, track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import {
    createContentDocumentAndVersion,
    createRecord
} from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getObjectInfos } from "lightning/uiObjectInfoApi";
import CONTENT_DOCUMENT from "@salesforce/schema/ContentDocument";
import CONTENT_VERSION from "@salesforce/schema/ContentVersion";
import CONTENT_DOCUMENT_LINK from "@salesforce/schema/ContentDocumentLink";

import WO_ID from '@salesforce/schema/WorkOrder.Id';
import WO_CUSTOMER_AVAILABILITY from '@salesforce/schema/WorkOrder.Check_Customer_Availability__c';
import WO_REASON from '@salesforce/schema/WorkOrder.Reason_ForUnavilability__c';
import LightningAlert from 'lightning/alert';
import WSTEP_ID from '@salesforce/schema/WorkStep.Id';
import WSTEP_STATUS from '@salesforce/schema/WorkStep.Status';
export default class CheckCustomerAvailICCommericalcomp extends LightningElement {

    @api recordId;

    @track customerAvailability;
    @track showCheckBox = true;
    @track customerAvilable = false;
    @track ReasonForUnavailability = false;
    @track isotherreason=false;
    load = false;
    @track reasonentry='';
    @track unavailability;
    @track fileuploading=true;
     workstepsId;

    //get related worksteps
     @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkSteps',
        fields: ['WorkStep.Id','WorkStep.Name','WorkStep.Status']
    })
    wiredSteps({ data, error }) {

        if (data && data.records && data.records.length > 0) {

            let selectedworkst = data.records.find(
                r => r.fields.Name.value === 'Check Customer Availability'
            );

            if (!selectedworkst) {
                console.warn('No "Check Customer Availability" WorkStep found');
                return;
            }

            this.workstepsId = selectedworkst.fields.Id.value;

            console.log('WorkStep ID:', this.workstepsId);

        } else if (error) {
            console.error('Error fetching work steps:', error);
        }
    }


    availabilityOptions = [
        { label: "Yes", value: "Yes" },
        { label: "No", value: "No" }
    ];

    reasonUnavailability = [
    { label: "House Lockout", value: "House Lockout" },
    { label: "Building Demolition", value: "Building Demolition" },
    { label: "Kitchen Renovation", value: "Kitchen Renovation" },
    { label: "Using LPG Stove", value: "Using LPG Stove" },
    { label: "Customer Disinterest", value: "Customer Disinterest" },
    { label: "Refusal of Entry", value: "Refusal of Entry" },
    { label: "Other", value: "Other" }
    ];


    // handle radio button change
    handleAvailabilityChange(event) {
        this.customerAvailability = event.detail.value;

        if (this.customerAvailability === "Yes") {
            this.customerAvilable = true;
            this.ReasonForUnavailability = false;
            this.isotherreason = false;
        } else {
            this.showCheckBox = false;
            this.customerAvilable = true;
            this.ReasonForUnavailability = true;
        }
    }

       handlereasonForUnavailability(event) {
        console.log('event detail value ::', event.detail.value);
        console.log('event detail value ::', event.target.value);

        this.unavailability = event.detail.value;

        if(this.unavailability == 'Other'){
            this.isotherreason=true;
        }else{
             this.isotherreason=false;
        }
    }

    handleReasonEntry(event){
         console.log('handleReasonEntry::event detail value ::', event.detail.value);
        console.log('handleReasonEntry::event detail value ::', event.target.value);
         this.reasonentry = event.detail.value;

    }


    // Save using LDS updateRecord
    async handleCusAvilSave() {

    if (!this.customerAvailability) {
        // this.showToast('Error', 'Select an option', 'error');
         LightningAlert.open({
                message: 'Select an option for availability',
                theme: 'error',   // red error dialog
                label: 'Error'    // header text
            });
        return;
    }

    if(!this.unavailability && this.customerAvailability == 'No'){
        //  this.showToast('Error', 'Please mention the reason.', 'error');
         LightningAlert.open({
                message: 'Please mention the reason.',
                theme: 'warning',   
                label: 'Warning'    
            });
        return;
    }

    this.load = true;

    const fields = {};
    fields[WO_ID.fieldApiName] = this.recordId;
    fields[WO_CUSTOMER_AVAILABILITY.fieldApiName] = this.customerAvailability;
    fields[WO_REASON.fieldApiName] = 
    this.unavailability === 'Other' ? this.reasonentry : this.unavailability;

    const recordInput = { fields };

    const wostepsfields = {};
    wostepsfields[WSTEP_ID.fieldApiName] = this.workstepsId;
    wostepsfields[WSTEP_STATUS.fieldApiName] = 'Completed';


    try {
        await updateRecord(recordInput);
        await updateRecord({ fields: wostepsfields });
        //Upload both photos after saving
        await this.handleUploadClick();
        this.load = false;
        //to go back
        setTimeout(() => {
            history.back();
        }, 500);

        this.showToast('Success', 'Updated Successfully!', 'success');

    } catch (error) {
        this.load = false;
        this.showToast('Error', error.body?.message || error, 'error');
    }
    }

    // handleCusAvilSave() {
    //     if (!this.customerAvailability) {
    //         this.showToast('Error', 'Select an option', 'error');
    //         return;
    //     }

    //     this.load = true;

    //     const fields = {};
    //     fields[WO_ID.fieldApiName] = this.recordId;
    //     fields[WO_CUSTOMER_AVAILABILITY.fieldApiName] = this.customerAvailability;
    //     fields[WO_REASON.fieldApiName]=this.unavailability == 'Other'? this.reasonentry :this.unavailability;
    //     const recordInput = { fields };

    //     updateRecord(recordInput)
    //         .then(() => {
    //             this.load = false;

    //             this.showToast(
    //                 'Success',
    //                 'Customer availability updated successfully',
    //                 'success'
    //             );
    //         })
    //         .catch(error => {
    //             this.load = false;
    //             this.showToast('Error', error.body.message, 'error');
    //         });
    // }


    @track
  files = undefined;

  @track
  uploadingFile = false;

  @track
  titleValue = "";

  @track
  descriptionValue = "";

  @track
  errorMessage = "";
  @track photo1Preview = null;
@track photo2Preview = null;

get photo1Class() {
    return this.photo1Preview ? "photo-box green-box" : "photo-box pink-box";
}

get photo2Class() {
    return this.photo2Preview ? "photo-box green-box" : "photo-box pink-box";
}
openFile1() {
    this.template.querySelector('input[data-id="photo1"]').click();
}

openFile2() {
    this.template.querySelector('input[data-id="photo2"]').click();
}
@track documentTypes = [
    { label: 'Photo 1', uploaded: false, previewUrl: '', className: 'preview-container pink' },
    { label: 'Photo 2', uploaded: false, previewUrl: '', className: 'preview-container pink' }
];

handlePhotoUpload(event) {
    this.files = event.detail.files;
    this.titleValue = this.fileName;

    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();

    reader.onload = () => {
        const imageUrl = reader.result;

        if (event.target.dataset.id === "photo1") {
            this.photo1Preview = imageUrl;
        } else {
            this.photo2Preview = imageUrl;
        }
    };

    reader.readAsDataURL(file);
}



  // Object metadata, or "ObjectInfo", is required for creating records
  // while offline. Use the getObjectInfos adapter to "force-prime" the
  // necessary object metadata. This is a work-around for the static analyzer
  // not knowing enough about the file object schema.
  @wire(getObjectInfos, {
    objectApiNames: [ CONTENT_DOCUMENT, CONTENT_VERSION, CONTENT_DOCUMENT_LINK ],
  })
  objectMetadata;

  // Getter used for local-only processing. Not needed for offline caching.
  // eslint-disable-next-line @salesforce/lwc-graph-analyzer/no-getter-contains-more-than-return-statement
  get fileName() {
    // eslint-disable-next-line @salesforce/lwc-graph-analyzer/no-unsupported-member-variable-in-member-expression
    const file = this.files && this.files[0];
    if (file) {
      return file.name;
    }
    return undefined;
  }

//   handleImageUpload(event) {
//     const label = event.target.dataset.label;
//     const file = event.target.files[0];
//     if (!file) return;

//     this.files = event.target.files;
//     this.titleValue = event.detail.value;

//     const reader = new FileReader();

//     reader.onload = () => {
//         this.documentTypes = this.documentTypes.map(doc => {
//             if (doc.label === label) {
//                 return {
//                     ...doc,
//                     uploaded: true,
//                     previewUrl: reader.result,
//                     fileName: file.name,
//                     base64Data: reader.result.split(",")[1]
//                 };
//             }
//             return doc;
//         });
//     };

//     reader.readAsDataURL(file);
// }

handleImageUpload(event) {
    const label = event.target.dataset.label;
    const file = event.target.files[0];
    console.log('handleImageUpload::');
   const newFiles = Array.from(event.target.files);
    console.log('this.files::'+JSON.stringify(this.files));
    this.titleValue = file.name; 

    if (!this.files) {
        this.files = [];
    }

    // Add new files to the existing array
    this.files = [...this.files, ...newFiles];

    // Show uploaded file names
    const names = this.files.map(f => f.name);
    LightningAlert.open({
        message: names.join('\n'),
        theme: 'warning',
        label: 'Uploaded Files'
    });

    if (!file) return;

    const reader = new FileReader();

    reader.onload = () => {
        this.documentTypes = this.documentTypes.map(doc => {
            if (doc.label === label) {
                return {
                    ...doc,
                    uploaded: true,
                    previewUrl: reader.result,
                    fileName: file.name,
                    base64Data: reader.result.split(",")[1]
                };
            }
            return doc;
        });
    };

    reader.readAsDataURL(file);
}



  // Input handlers
//   handleFilesInputChange(event) {
//     this.files = event.detail.files;
//     this.titleValue = this.fileName;
//   }

  handleTitleInputChange(event) {
    this.titleValue = event.detail.value;
  }

  handleDescriptionInputChange(event) {
    this.descriptionValue = event.detail.value;
  }

  // Restore UI to default state
  resetInputs() {
    this.files = [];
    this.titleValue = "";
    this.descriptionValue = "";
    this.errorMessage = "";
  }


    async handleUploadClick() {
    if (this.uploadingFile) return;
    if (!this.files || this.files.length === 0) return;

     const filelength=this.files.length;
    LightningAlert.open({
    message: filelength,
    theme: 'warning',
    label: 'Uploaded Files'
    });
    this.uploadingFile = true;
    try {
        for (let file of this.files) {
            const contentDocumentAndVersion = await createContentDocumentAndVersion({
                title: file.name,
                description: this.descriptionValue || '',
                fileData: file
            });

            if (this.recordId) {
                const contentDocumentId = contentDocumentAndVersion.contentDocument.id;
                await this.createContentDocumentLink(this.recordId, contentDocumentId);
            }

            console.log(`Uploaded: ${file.name}`);
        }

        this.notifySuccess();
        this.resetInputs();
    } catch (error) {
        console.error(error);
        this.errorMessage = error;
    } finally {
        this.uploadingFile = false;
    }
}



// async handleUploadClick() {

//     if (!this.files || this.files.length === 0) {
//         return;
//     }

//     this.uploadingFile = true;
//     const filelength=this.files.length;
//     LightningAlert.open({
//     message: filelength,
//     theme: 'warning',
//     label: 'Uploaded Files'
// });

//     try {
//         for (let i = 0; i < this.files.length; i++) {
//             const file = this.files[i];

//             const contentDocumentAndVersion =
//                 await createContentDocumentAndVersion({
//                     title: file.name,
//                     description: '',
//                     fileData: file
//                 });

//             if (this.recordId) {
//                 await this.createContentDocumentLink(
//                     this.recordId,
//                     contentDocumentAndVersion.contentDocument.id
//                 );
//             }
//         }

//         this.notifySuccess();
//     } catch (error) {
//         console.error(error);
//     } finally {
//         this.uploadingFile = false;
//     }
// }


 // Handle uploading a file, initiated by user clicking Upload button
//   async handleUploadClick() {
//     if (this.uploadingFile) {
//       return;
//     }

//     // Make sure we have something to upload
//     const file = this.files && this.files[0];
//     if (!file) {
//       return;
//     }

//     try {
//       this.uploadingFile = true;

//       // Create a ContentDocument and related ContentDocumentVersion for
//       // the file, effectively uploading it
//       const contentDocumentAndVersion =
//         await createContentDocumentAndVersion({
//           title: this.titleValue,
//           description: this.descriptionValue,
//           fileData: file,
//         });
//         console.log("ContentDocument and ContentDocumentVersion records created.");

//       // If component is run in a record context (recordId is set), relate
//       // the uploaded file to that record
//       if (this.recordId) {
//         const contentDocumentId = contentDocumentAndVersion.contentDocument.id;

//         // Create a ContentDocumentLink (CDL) to associate the uploaded file
//         // to the Files related list of the target recordId
//         await this.createContentDocumentLink(this.recordId, contentDocumentId);
//       }

//       console.log("File upload created and enqueued.");
//       this.notifySuccess();
//       this.resetInputs();
//     } catch (error) {
//       console.error(error);
//       this.errorMessage = error;
//     } finally {
//       this.uploadingFile = false;
//     }
//   }

  // Create link between new file upload and target record
  async createContentDocumentLink(recordId, contentDocumentId) {
    await createRecord({
      apiName: "ContentDocumentLink",
      fields: {
        LinkedEntityId: recordId,
        ContentDocumentId: contentDocumentId,
        ShareType: "V",
      },
    });
    console.log("ContentDocumentLink record created.");
  }

  notifySuccess() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Upload Successful",
        message: "File enqueued for upload.",
        variant: "success",
      })
    );
  }

    showToast(title, msg, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: msg,
                variant: variant
            })
        );
    }
}