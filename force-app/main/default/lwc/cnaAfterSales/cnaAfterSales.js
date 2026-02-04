import { LightningElement, api, track } from 'lwc';
import submitUnsuccessfulVisit from '@salesforce/apex/UnsuccessfulVisitControllerIP.submitUnsuccessfulVisit';
//import savePhotoUploadsIP from '@salesforce/apex/UnsuccessfulVisitControllerIP.savePhotoUploadsIP';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CnaAfterSales extends LightningElement {
    @api recordId;
    @track selectedReason = '';
    @track notes = '';
    @track previewUrl = '';
@track previewFileName = '';
@track isPreviewImage = false;
@track isPreviewPdf = false;
@track showPreviewModal = false;


    
    @track showForm = true;
    @track photoUploadSlots = [];
   // noOfPhotos = 1;
    @track imageUploadPage = false;
    @track showRemarks = false;
  //  @track followUpDate = null;
@track showFollowUpDate = false;

        @track load = false;

        @track selectedDateTime;




    reasonOptions = [
        { label: 'House Lock', value: 'House Lock' },
        { label: 'Customer Not Available', value: 'Customer Not Available' },
        { label: 'Customer Not Interested', value: 'Customer Not Interested' },
        { label: 'Customer Asked to Reschedule', value: 'Customer Asked to Reschedule' },
        { label: 'Customer Did Not Respond to Calls', value: 'Customer Did Not Respond to Calls' },
        { label: 'Wrong or Incomplete Address', value: 'Wrong or Incomplete Address' },
        { label: 'Access Not Provided by Security or Society', value: 'Access Not Provided by Security or Society' },
        { label: 'Customer Refused Work', value: 'Customer Refused Work' },
        { label: 'Documentation Not Ready', value: 'Documentation Not Ready' },
        { label: 'Payment Not Ready', value: 'Payment Not Ready' },
        { label: 'Meter Location Not Accessible', value: 'Meter Location Not Accessible' },
        { label: 'Safety Issue at Site', value: 'Safety Issue at Site' },
        { label: 'No Permission for Work from Society or Building', value: 'No Permission for Work from Society or Building' },
        { label: 'Others', value: 'Others' },
    ];

    remarkRequiredReasons = [
    'Others',
    'Customer Not Available',
    'Customer Not Interested',
    'Customer Asked to Reschedule',
    'Customer Did Not Respond to Calls',
    'Wrong or Incomplete Address',
    'Access Not Provided by Security or Society',
    'Customer Out of Station',
    'Customer Refused Work',
    'Documentation Not Ready',
    'Payment Not Ready',
    'Meter Location Not Accessible',
    'Safety Issue at Site',
    'No Permission for Work from Society or Building'
    ];


    
    connectedCallback(){
       // this.setPhotoUploadSlots();
        console.log('record id::', this.recordId);
    }

    setPhotoUploadSlots(count = 1) {
    // default to 1 slot for the reason, but can pass >1 later if needed
    this.photoUploadSlots = Array.from({ length: count }, (_, index) => ({
        id: Date.now() + index,
        index: index + 1,
        label: this.selectedReason || 'Photo',
        fileName: '',
        uploaded: false,
        previewUrl: '',
        base64Data: '',
        isPdf: false,
        isImage: false
    }));
}




// async handleFile(event) {
//         console.log('📥 inside handleFile');
//        // let newSlots = event.detail.steps;
//         this.photoUploadSlots =event.detail.steps;

//         for (let i = 0; i < photoUploadSlots.length; i++) {
//         let slot = photoUploadSlots[i];
//             console.log(`🔄 Processing Photo ${i + 1}`);

//             if (slot.base64Data) {
//                 try {
//                     // Add prefix if missing
//                     const fullBase64 = slot.base64Data.startsWith('data:image')
//                         ? slot.base64Data
//                         : `data:image/jpeg;base64,${slot.base64Data}`;

//                     // 🔍 Original size in MB
//                     const originalBytes = atob(fullBase64.split(',')[1]).length;
//                     const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
//                     console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

//                     // Convert to blob and compress
//                     const blob = this.base64ToBlob(fullBase64);
//                     const imageUrl = URL.createObjectURL(blob);
//                     const compressedBlob = await this.compressImageFromURL(imageUrl);

//                     // Convert compressed Blob back to base64
//                     const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
//                     const compressedBytes = atob(compressedBase64).length;
//                     const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
//                     console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

//                     // Store compressed result
//                     slot.base64Data = compressedBase64;

//                 } catch (error) {
//                 //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);

//                 // Only show toast if compressed base64 is not usable
//                 if (!slot.base64Data || slot.base64Data.length < 100) {
//                 console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
//                 } else {
//                     console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
//                 }
//             }


//             } else {
//                 console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
//             }
//         }

//        // this.photoUploadSlots = newSlots;
//         console.log('✅ Final photoUploadSlots set');
//     } 



    
    // async base64ToBlob(base64Data) {
    //     const byteString = atob(base64Data.split(',')[1]);
    //     const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];
    //     const ab = new ArrayBuffer(byteString.length);
    //     const ia = new Uint8Array(ab);
    //     for (let i = 0; i < byteString.length; i++) {
    //         ia[i] = byteString.charCodeAt(i);
    //     }
    //     return new Blob([ab], { type: mimeString });
    // }

    // async compressImageFromURL(imageUrl) {
    //     return new Promise((resolve, reject) => {
    //         const img = new Image();

    //         img.onload = () => {
    //             try {
    //                 const canvas = document.createElement('canvas');
    //                 const ctx = canvas.getContext('2d');
    //                 const maxWidth = 1600;
    //                 const maxHeight = 1600;
    //                 let width = img.width;
    //                 let height = img.height;

    //                 const ratio = Math.min(maxWidth / width, maxHeight / height);
    //                 width *= ratio;
    //                 height *= ratio;

    //                 canvas.width = width;
    //                 canvas.height = height;
    //                 ctx.drawImage(img, 0, 0, width, height);

    //                     try {
    //                         canvas.toBlob(
    //                             (blob) => {
    //                                 if (blob) {
    //                                     resolve(blob);
    //                                 } else {
    //                                     console.warn('⚠️ toBlob returned null. Possibly tainted canvas or unsupported format.');
    //                                     reject(new Error('Canvas compression failed. Blob was null.'));
    //                                 }
    //                             },
    //                             'image/jpeg',
    //                             9.1
    //                         );
    //                     } catch (err) {
    //                         console.error('❌ Error during canvas.toBlob execution:', err);
    //                         reject(new Error('Exception during canvas.toBlob: ' + err.message));
    //                     }
    //             } catch (error) {
    //                 reject(new Error('Error during image compression: ' + error.message));
    //             }
    //         };

    //         img.onerror = () => {
    //             reject(new Error('Error loading image.'));
    //         };

    //         img.crossOrigin = 'anonymous';
    //         img.src = imageUrl;
    //     });
    // }

    // async convertBlobToBase64(blob) {
    //     return new Promise((resolve, reject) => {
    //         const reader = new FileReader();
    //         reader.onload = () => resolve(reader.result.split(',')[1]);
    //         reader.onerror = reject;
    //         reader.readAsDataURL(blob);
    //     });
    // }




//  setPhotoUploadSlots() {
//         this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => ({
//             id: index + 1,
//             index: index + 1,
//             // label: `House Lock`,
//             label: this.selectedReason || 'Photo',
//             name: `fileUploader${index + 1}`,
//             fileName: '',
//             uploaded: false,
//             previewUrl: '',
//             base64Data: ''
//         }));
//     }

triggerFileUpload(event) {
    const inputName = event.currentTarget.dataset.input;
    const fileInput = this.template.querySelector(`input[data-input="${inputName}"]`);
    if (fileInput) fileInput.click();
}
async handleFilesInputChange(event) {
    const files = Array.from(event.target.files || []);
    if (!files.length) return;

    for (let file of files) {
        let fileName = file.name;
        const isPdf = file.type === "application/pdf";
        const isImage = file.type && file.type.startsWith("image/");

        // if image, compress then convert to base64, else convert file directly
        let base64;
        let previewUrl;

        if (isImage) {
            const compressedBlob = await this.compressImageFromFile(file);
            base64 = await this.convertBlobToBase64(compressedBlob);
            previewUrl = URL.createObjectURL(compressedBlob);
        } else {
            // PDF or other: read as base64 and create data url for preview
            base64 = await this.convertToBase64(file);
            previewUrl = `data:${file.type};base64,${base64}`;
        }

        // push into photoUploadSlots
        this.photoUploadSlots = [
            ...this.photoUploadSlots,
            {
                id: Date.now() + Math.random(),
                fileName: fileName,
                previewUrl: previewUrl,
                base64Data: base64,
                isPdf: isPdf,
                isImage: isImage,
                uploaded: true
            }
        ];
    }
}

convertToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result.split(',')[1]);
        reader.onerror = reject;
        reader.readAsDataURL(file);
    });
}
async compressImageFromFile(file) {
    const imageBitmap = await createImageBitmap(file);
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');

    const maxDim = 1600;
    let { width, height } = imageBitmap;
    const ratio = Math.min(maxDim / width, maxDim / height);

    width *= ratio;
    height *= ratio;

    canvas.width = width;
    canvas.height = height;
    ctx.drawImage(imageBitmap, 0, 0, width, height);

    return new Promise((resolve) => {
        canvas.toBlob((blob) => resolve(blob), 'image/jpeg', 0.85);
    });
}
convertBlobToBase64(blob) {
    return new Promise((resolve) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result.split(',')[1]);
        reader.readAsDataURL(blob);
    });
}
openPreviewModal(event) {
    this.previewUrl = event.currentTarget.dataset.url;
    this.previewFileName = event.currentTarget.dataset.name;

    this.isPreviewImage = this.previewUrl.startsWith("blob:") || this.previewUrl.startsWith("data:image");
    this.isPreviewPdf = this.previewUrl.includes("pdf");

    this.showPreviewModal = true;
}

closePreviewModal() {
    this.showPreviewModal = false;
}





    handleReasonChange(event) {

    this.notes='';
    const selectedValue = event.detail.value;
    console.log('select reason::', event.target.value);
    const selectedOption = this.reasonOptions.find(opt => opt.value === selectedValue);

    this.selectedReason = selectedOption ? selectedOption.label : '';

   // this.showRemarks = this.selectedReason === 'Others';
   this.showRemarks = this.remarkRequiredReasons.includes(this.selectedReason);

    // this.imageUploadPage = this.selectedReason === 'House Lock';
    // this.showFollowUpDate = this.selectedReason === 'House Lock';

    // // Only create slots if photo section is needed
    // if (this.imageUploadPage) {
    //     this.setPhotoUploadSlots();
    // } else {
    //     console.log('inside photo upload slot');
    //     this.photoUploadSlots = []; // reset
    // }

    // Allow photo upload for ALL reasons
this.imageUploadPage = true;

// Follow-up date ONLY for House Lock
this.showFollowUpDate = (this.selectedReason === 'House Lock');

// Always create 1 photo slot for every reason
//this.setPhotoUploadSlots();

}

// handleFollowUpDateChange(event) {
//     this.followUpDate = event.detail.value;
// }

 handleDateTimeChange(event){

        console.log('date time::', event.target.value);

          const selected = event.target.value;


         //    this.selectedDateTime = event.target.value;

const now = new Date();
  const selDate = new Date(selected);

  // Normalize both to midnight to ignore time
  now.setHours(0, 0, 0, 0);
  selDate.setHours(0, 0, 0, 0);

  if (selDate < now) {

    this.showtoast('Warning', 'Please Select Correct Date', 'warning');
    event.target.value = '';
    this.selectedDateTime = null;
  } else {
    this.selectedDateTime = selected;
  }

    }


handleNotesChange(event) {
    this.notes = event.target.value;
}



handleSubmit() {

    this.load = true;

    // -------------------------------
    // VALIDATIONS
    // -------------------------------
    if (!this.selectedReason) {
        this.showtoast('Warning', 'Please Select Reason For Unsuccessful Visit.', 'warning');
        this.load = false;
        return;
    }

    if (this.selectedReason === 'House Lock' && !this.selectedDateTime) {
        this.showtoast('Warning', 'Please Select Follow-up Visit Date.', 'warning');
        this.load = false;
        return;
    }

    if (this.remarkRequiredReasons.includes(this.selectedReason) && !this.notes.trim()) {
        this.showtoast('Warning', 'Please Enter Remark.', 'warning');
        this.load = false;
        return;
    }

    // -------------------------------
    // PHOTO VALIDATION
    // -------------------------------
    const validPhotos = this.photoUploadSlots.filter(
        photo => photo.base64Data && photo.fileName
    );

    if (validPhotos.length === 0) {
        this.showtoast('Warning', 'Please capture at least one photo.', 'warning');
        this.load = false;
        return;
    }

    // -------------------------------
    // PREPARE DATA FOR APEX
    // -------------------------------
    const imagesList = validPhotos.map(item => ({
        base64Data: item.base64Data,
        fileName: item.fileName,
        label: this.selectedReason
    }));

    console.log('📤 Sending imagesList:', JSON.stringify(imagesList));

    // -------------------------------
    // CALL APEX METHOD
    // -------------------------------
    submitUnsuccessfulVisit({
        workOrderId: this.recordId,
        reason: this.selectedReason,
        notes: this.notes,
        followUpDate: this.selectedDateTime,
        listFiles: imagesList
    })
    .then(result => {

        console.log('Apex Response:', result);
        this.showtoast('Success', 'Details Saved Successfully.', 'success');

        this.dispatchEvent(new CustomEvent('cancel'));
    })
    .catch(error => {
        console.error('❌ Error:', error);
        this.showtoast('Error', 'Submission Failed. Check Console.', 'error');
    })
    .finally(() => {
        this.load = false;
    });
}


//   uploadFile(imagesList) {

//     }


 showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}