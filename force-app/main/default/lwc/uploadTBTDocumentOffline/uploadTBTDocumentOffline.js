// fileUpload.js
import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
  createContentDocumentAndVersion,
  createRecord,
} from "lightning/uiRecordApi";
// Imports for forced-prime ObjectInfo metadata work-around
import { getObjectInfos } from "lightning/uiObjectInfoApi";
import CONTENT_DOCUMENT from "@salesforce/schema/ContentDocument";
import CONTENT_VERSION from "@salesforce/schema/ContentVersion";
import CONTENT_DOCUMENT_LINK from "@salesforce/schema/ContentDocumentLink";
//import submitForApproval from '@salesforce/apex/uploadTBTDocumentOfflineContr.submitForApproval';
export default class FileUpload extends LightningElement {
  @api
  recordId;

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

  // Input handlers
  handleFilesInputChange(event) {
    this.files = event.detail.files;
    this.titleValue = this.fileName;
  }

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

  // Handle uploading a file, initiated by user clicking Upload button
  // async handleUploadClick() {
  //   // Make sure we're not already uploading something
  //   if (this.uploadingFile) {
  //     return;
  //   }

  //   // Make sure we have something to upload
  //   const file = this.files && this.files[0];
  //   if (!file) {
  //     return;
  //   }

  //   try {
  //     this.uploadingFile = true;

  //     // Create a ContentDocument and related ContentDocumentVersion for
  //     // the file, effectively uploading it
  //     const contentDocumentAndVersion =
  //       await createContentDocumentAndVersion({
  //         title: this.titleValue,
  //         description: this.descriptionValue,
  //         fileData: file,
  //       });
  //       console.log("ContentDocument and ContentDocumentVersion records created.");

  //     // If component is run in a record context (recordId is set), relate
  //     // the uploaded file to that record
  //     if (this.recordId) {
  //       const contentDocumentId = contentDocumentAndVersion.contentDocument.id;

  //       // Create a ContentDocumentLink (CDL) to associate the uploaded file
  //       // to the Files related list of the target recordId
  //       await this.createContentDocumentLink(this.recordId, contentDocumentId);
  //     }

  //     // Status and state updates
  //     console.log("File upload created and enqueued.");
  //     this.notifySuccess();
  //     this.resetInputs();
  //   } catch (error) {
  //     console.error(error);
  //     this.errorMessage = error;
  //   } finally {
  //     this.uploadingFile = false;
  //   }
  // }

  // Handle uploading all files
async handleUploadClick() {
    if (this.uploadingFile) {
        return;
    }

    if (!this.files || this.files.length === 0) {
        return;
    }

    try {
        this.uploadingFile = true;

        for (let i = 0; i < this.files.length; i++) {
            const file = this.files[i];

            // Use per-file title and description or fallback
            const title = this.titleValue || file.name;
            const description = this.descriptionValue || '';

            // Create ContentDocument + Version (enqueued offline)
            const contentDocumentAndVersion =
                await createContentDocumentAndVersion({
                    title: title,
                    description: description,
                    fileData: file,
                });
            console.log(`File ${file.name} enqueued for upload.`);

            // Link each ContentDocument to the parent record
            if (this.recordId) {
                const contentDocumentId =
                    contentDocumentAndVersion.contentDocument.id;
                await this.createContentDocumentLink(
                    this.recordId,
                    contentDocumentId
                );
            }
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
    //this.submitForApproval();
    console.log("ContentDocumentLink record created.");
  }

  notifySuccess() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Upload Successful",
        message: "Details saved successfully.",
        variant: "success",
      })
    );
  }
}