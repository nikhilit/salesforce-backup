import { LightningElement, api, track, wire } from 'lwc';
import LightningAlert from 'lightning/alert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
    createContentDocumentAndVersion,
    createRecord
} from 'lightning/uiRecordApi';

import { getObjectInfos } from "lightning/uiObjectInfoApi";
import CONTENT_DOCUMENT from "@salesforce/schema/ContentDocument";
import CONTENT_VERSION from "@salesforce/schema/ContentVersion";
import CONTENT_DOCUMENT_LINK from "@salesforce/schema/ContentDocumentLink";
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { updateRecord } from 'lightning/uiRecordApi';
import WSTEP_ID from '@salesforce/schema/WorkStep.Id';
import WSTEP_STATUS from '@salesforce/schema/WorkStep.Status';

export default class DetailsUploadICComericalComp extends LightningElement {

    @api recordId;

    @track documentTypes = [
        { label: "Before Installation", files: [], counter: 0 },
        { label: "Meter Counter Photo", files: [], counter: 0 },
        { label: "Before and After Pressure Gauge", files: [], counter: 0 },
        { label: "After Installation", files: [], counter: 0 },
        { label: "ESCN", files: [], counter: 0 },
        { label: "Task List", files: [], counter: 0 },
        { label: "Old Meter and New Meter", files: [], counter: 0 },
        { label: "Old Regulator and New Regulator", files: [], counter: 0 },
        { label: "Seal", files: [], counter: 0 },
        { label: "Meter counter running video", files: [], counter: 0 },
        { label: "Installation video", files: [], counter: 0 }
    ];

    @track files = [];

    // popup preview
    @track showPreview = false;
    @track previewUrl = "";

    titleValue = "";
    descriptionValue = "";
    uploadingFile = false;
    isCheckinDone=false;
    isCheckOutDone=false;
     load = false;
       workstepsId;
    
    get isValidateCheckinCheckout(){
    return this.isCheckinDone && !this.isCheckOutDone;
    }


      normalize(text) {
            return text ? text.toLowerCase().replace(/[\s-]/g, '') : '';
        }
    //get related worksteps
     @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkSteps',
        fields: ['WorkStep.Id','WorkStep.Name','WorkStep.Status']
    })
    wiredSteps({ data, error }) {

        if (data && data.records && data.records.length > 0) {

            data.records.forEach(r => {
            const wsName = this.normalize(r.fields.Name.value);

            if (wsName === 'i&ccommericalexecutiondetails') {
                this.workstepsId = r.fields.Id.value;
                console.log('WorkStep ID (I&C):', this.workstepsId);
            }

            if (wsName === 'checkin') {
                const status = r.fields.Status.value;
                this.isCheckinDone = (status?.toLowerCase() === 'completed');
                console.log('Is Check-In Completed?:::', this.isCheckinDone);
            }

            if(wsName === 'checkout'){
                const status =r.fields.Status.value;
                this.isCheckOutDone = (status?.toLowerCase() === 'completed');
                console.log('Is Check-Out Completed?:::', this.isCheckOutDone);
            }
        });

        } else if (error) {
            console.error('Error fetching work steps:', error);
        }
    }

    // Required metadata priming for offline
    @wire(getObjectInfos, {
        objectApiNames: [CONTENT_DOCUMENT, CONTENT_VERSION, CONTENT_DOCUMENT_LINK]
    })
    objectMetadata;

    async handleImageUpload(event) {
    const label = event.target.dataset.label;
    const newFiles = Array.from(event.target.files);

    if (!newFiles.length) return;

    let doc = this.documentTypes.find(d => d.label === label);

    const MAX_IMAGES = 10;
    const MAX_VIDEOS = 2;
    const MAX_SIZE = 2 * 1024 * 1024; // 2MB

    const existingImages = this.files.filter(f => !f.originalFile.type.startsWith("video/")).length;
    const existingVideos = this.files.filter(f => f.originalFile.type.startsWith("video/")).length;

    let newImagesCount = 0;
    let newVideosCount = 0;

    for (let f of newFiles) {
        f.type.startsWith("video/") ? newVideosCount++ : newImagesCount++;
    }

    if (existingImages + newImagesCount > MAX_IMAGES) {
        LightningAlert.open({
            message: `You can upload a maximum of ${MAX_IMAGES} images.`,
            theme: 'warning',
            label: 'Limit Exceeded'
        });
        event.target.value = "";
        return;
    }

    if (existingVideos + newVideosCount > MAX_VIDEOS) {
        LightningAlert.open({
            message: `You can upload a maximum of ${MAX_VIDEOS} videos.`,
            theme: 'warning',
            label: 'Limit Exceeded'
        });
        event.target.value = "";
        return;
    }

    for (let file of newFiles) {

        let finalFile = file;

        if (!file.type.startsWith("video/") && file.size > MAX_SIZE && !file.type.startsWith("application/pdf") ) {
            finalFile = await this.compressImage(file, MAX_SIZE);
        }

        const nextNumber = doc.files.length + 1;
        const uniqueName = `${label} ${nextNumber}`;

        // Store backend usage file entry
        this.files = [...this.files, {
            uniqueName,
            originalFile: finalFile
        }];

        const reader = new FileReader();

        reader.onload = () => {
            const isPDF = finalFile.type === "application/pdf";
            const isVideo = finalFile.type.startsWith("video/");

            let previewData = isVideo
                ? URL.createObjectURL(finalFile)
                : reader.result;

            doc.files.push({
                uniqueName,
                preview: previewData,
                originalFile: finalFile,
                isPDF,
                isVideo
            });

            this.documentTypes = [...this.documentTypes];
        };

        reader.readAsDataURL(finalFile);
    }

    event.target.value = "";
}


// handleImageUpload(event) {
    
//     const label = event.target.dataset.label;
//     const newFiles = Array.from(event.target.files);

//     if (!newFiles.length) return;

//     let doc = this.documentTypes.find(d => d.label === label);

//     const MAX_IMAGES = 10;
//     const MAX_VIDEOS = 2;
//     const MAX_SIZE = 3 * 1024 * 1024;

//     // Count existing images and videos
//     const existingImages = this.files.filter(f => !f.originalFile.type.startsWith("video/")).length;
//     const existingVideos = this.files.filter(f => f.originalFile.type.startsWith("video/")).length;

//     // Check limits
//     let newImagesCount = 0;
//     let newVideosCount = 0;

//     for (let f of newFiles) {
//         if (f.type.startsWith("video/")) newVideosCount++;
//         else newImagesCount++;
//     }

//     if (existingImages + newImagesCount > MAX_IMAGES) {
//         LightningAlert.open({
//             message: `You can upload a maximum of ${MAX_IMAGES} images.`,
//             theme: 'warning',
//             label: 'Limit Exceeded'
//         });
//         event.target.value = "";
//         return;
//     }

//     if (existingVideos + newVideosCount > MAX_VIDEOS) {
//         LightningAlert.open({
//             message: `You can upload a maximum of ${MAX_VIDEOS} videos.`,
//             theme: 'warning',
//             label: 'Limit Exceeded'
//         });
//         event.target.value = "";
//         return;
//     }

//     // Check individual file sizes
//     const oversizedFiles = newFiles.filter(f => f.size > MAX_SIZE);
//     if (oversizedFiles.length > 0) {
//         LightningAlert.open({
//             message: `Some files exceed 2MB and cannot be uploaded.`,
//             theme: 'warning',
//             label: 'File Too Large'
//         });
//         event.target.value = "";
//         return;
//     }

//     newFiles.forEach(file => {
//         const nextNumber = doc.files.length + 1;
//         const uniqueName = `${label} ${nextNumber}`;

//         // Store backend file list
//         this.files = [...this.files, {
//             uniqueName: uniqueName,
//             originalFile: file
//         }];
//         const reader = new FileReader();
//           reader.onload = () => {
//     const isPDF = file.type === "application/pdf";
//     const isVideo = file.type.startsWith("video/");

//     let previewData;

//     if (isVideo) {
//         const blob = new Blob([file], { type: file.type });
//         previewData = URL.createObjectURL(blob);
//         } else {
//             previewData = reader.result; // allowed for PDFs/images
//         }

//         doc.files.push({
//             uniqueName,
//             preview: previewData,
//             originalFile: file,
//             isPDF,
//             isVideo
//         });

//         this.documentTypes = [...this.documentTypes];
//         };

//             reader.readAsDataURL(file);
//         });

//         event.target.value = "";
//     }



compressImage(file, maxSize = 2 * 1024 * 1024) {
    return new Promise((resolve) => {
        const img = new Image();
        const reader = new FileReader();

        reader.onload = (e) => {
            img.src = e.target.result;
        };

        img.onload = () => {
            const canvas = document.createElement("canvas");
            const ctx = canvas.getContext("2d");

            let width = img.width;
            let height = img.height;

            // Scale image down if too large
            const MAX_WIDTH = 2000;
            if (width > MAX_WIDTH) {
                height *= MAX_WIDTH / width;
                width = MAX_WIDTH;
            }

            canvas.width = width;
            canvas.height = height;
            ctx.drawImage(img, 0, 0, width, height);

            let quality = 0.9;
            let compressedDataUrl;

            do {
                compressedDataUrl = canvas.toDataURL("image/jpeg", quality);
                quality -= 0.05;

                // Stop if quality too low
                if (quality < 0.1) break;
            } while (this.dataURLtoFile(compressedDataUrl, file.name).size > maxSize);

            const finalFile = this.dataURLtoFile(compressedDataUrl, file.name);
            resolve(finalFile);
        };

        reader.readAsDataURL(file);
    });
}

dataURLtoFile(dataurl, filename) {
    var arr = dataurl.split(','),
        mime = arr[0].match(/:(.*?);/)[1],
        bstr = atob(arr[1]),
        n = bstr.length,
        u8arr = new Uint8Array(n);

    while (n--) u8arr[n] = bstr.charCodeAt(n);

    return new File([u8arr], filename, { type: mime });
}



// handleImageUpload(event) {
//     const label = event.target.dataset.label;
//     const newFiles = Array.from(event.target.files);

//     if (!newFiles.length) return;

//     let doc = this.documentTypes.find(d => d.label === label);

//     newFiles.forEach(file => {
//         const nextNumber = doc.files.length + 1;
//         const uniqueName = `${label} ${nextNumber}`;

//         // Store backend file list
//         this.files = [...this.files, {
//             uniqueName: uniqueName,
//             originalFile: file
//         }];

//         // UI preview
//         const reader = new FileReader();
//         reader.onload = () => {
//             doc.files.push({
//                 uniqueName: uniqueName,
//                 preview: reader.result,
//                 originalFile: file // IMPORTANT!!
//             });

//             this.documentTypes = [...this.documentTypes];
//         };
//         reader.readAsDataURL(file);
//     });

//     event.target.value = "";
// }

    handlePreviewClick(event) {
    const label = event.target.dataset.label;
    const uniqueName = event.target.dataset.uniquename;

    const doc = this.documentTypes.find(d => d.label === label);
    const file = doc.files.find(f => f.uniqueName === uniqueName);

    this.previewUrl = file.preview;

    this.previewIsPDF = file.isPDF;
    this.previewIsVideo = file.isVideo;
    this.previewIsImage = !file.isPDF && !file.isVideo;

    // 👇 Force DOM refresh for video
    this.previewKey = Date.now();

    this.showPreview = true;
    }

    // handlePreviewClick(event) {
    //     const label = event.target.dataset.label;
    //     const name = event.target.dataset.name;

    //     const doc = this.documentTypes.find(d => d.label === label);
    //     const file = doc.files.find(f => f.name === name);

    //     this.previewUrl = file.preview;
    //     this.showPreview = true;
    // }

    closePreview() {
        this.showPreview = false;
        this.previewUrl = "";
    }

    handleDeleteClick(event) {
    const uniqueName = event.target.dataset.uniquename;
    if (!uniqueName) return;

    // 1️⃣ FIRST remove from backend using the ORIGINAL uniqueName
    this.files = this.files.filter(f => f.uniqueName !== uniqueName);

    // 2️⃣ Remove from UI
    let doc = this.documentTypes.find(d =>
        d.files.some(f => f.uniqueName === uniqueName)
    );
    if (!doc) return;

    doc.files = doc.files.filter(f => f.uniqueName !== uniqueName);

    // 3️⃣ Renumber UI files
    doc.files = doc.files.map((f, index) => ({
        ...f,
        uniqueName: `${doc.label} ${index + 1}`
    }));

    // 4️⃣ Renumber backend to match UI
    this.files = this.files.map(b => {
        const updated = doc.files.find(ui => ui.originalFile === b.originalFile);
        return updated ? { ...b, uniqueName: updated.uniqueName } : b;
    });

    this.documentTypes = [...this.documentTypes];

    LightningAlert.open({
        message: "File Removed",
        theme: "warning",
        label: "Deleted"
    });
}

    handleTitleInputChange(event) {
        this.titleValue = event.detail.value;
    }

    handleDescriptionInputChange(event) {
        this.descriptionValue = event.detail.value;
    }

    resetInputs() {
        this.files = [];
        this.titleValue = "";
        this.descriptionValue = "";
        this.errorMessage = "";
    }

    async handleUploadClick() {

           if (!this.isCheckinDone) {
            console.log('checkin is not done::');
             LightningAlert.open({
                message: 'Please Checkin Before Upload Site Documents.',
                theme: 'warning',   
                label: 'Warning'    
            });
            return;
        }

        console.log('this.uploadingFile::',this.uploadingFile);
        if (this.uploadingFile) return;
        if (!this.files || this.files.length === 0) return;

        const filelength = this.files.length;

        LightningAlert.open({
            message: filelength,
            theme: 'warning',
            label: 'Uploaded Files'
        });

        this.uploadingFile = true;

        this.load = true;
         const wostepsfields = {};
    wostepsfields[WSTEP_ID.fieldApiName] = this.workstepsId;
    wostepsfields[WSTEP_STATUS.fieldApiName] = 'Completed';

        try {
             const uploadPromises = this.files.map(async file => {
            const docResult = await createContentDocumentAndVersion({
                title: file.uniqueName,
                description: '',
                fileData: file.originalFile
            });

            const contentDocumentId = docResult.contentDocument.id;

            if (this.recordId && contentDocumentId) {
                await createRecord({
                    apiName: "ContentDocumentLink",
                    fields: {
                        LinkedEntityId: this.recordId,
                        ContentDocumentId: contentDocumentId,
                        ShareType: "V"
                    }
                });
            }
        });

        // run all uploads in parallel
        await Promise.all(uploadPromises);
            // for (let file of this.files) {

            //     const docResult = await createContentDocumentAndVersion({
            //          title: file.uniqueName,            // use unique name
            //     description: '',
            //     fileData: file.originalFile
            //         // title: file.name,
            //         // description: this.descriptionValue || '',
            //         // fileData: file
            //     });

            //     const contentDocumentId = docResult.contentDocument.id;

            //     if (this.recordId && contentDocumentId) {
            //         await createRecord({
            //             apiName: "ContentDocumentLink",
            //             fields: {
            //                 LinkedEntityId: this.recordId,
            //                 ContentDocumentId: contentDocumentId,
            //                 ShareType: "V"
            //             }
            //         });
            //     }
            // }
        await updateRecord({ fields: wostepsfields });
            this.load = false;
        setTimeout(() => {
            history.back();
        }, 500);

            this.showToast("Success", "Files uploaded successfully", "success");
            this.resetInputs();

        } catch (error) {
            console.error(error);
            this.errorMessage = error;
        } finally {
            this.uploadingFile = false;
        }
    }

    /* ===========================
        TOAST HELPER
    ============================*/
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}