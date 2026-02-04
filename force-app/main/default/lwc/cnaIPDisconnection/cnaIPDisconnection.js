import { LightningElement, api, track } from 'lwc';
import submitUnsuccessfulVisit from '@salesforce/apex/UnsuccessfulVisitControllerIP.submitUnsuccessfulVisit';
//import savePhotoUploadsIP from '@salesforce/apex/UnsuccessfulVisitControllerIP.savePhotoUploadsIP';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningAlert from 'lightning/alert';


export default class UnsuccessfulVisitForm extends LightningElement {
    @api recordId;
    @track selectedReason = '';
    @track notes = '';

    
    @track showForm = true;
    @track photoUploadSlots = [];
    noOfPhotos = 1;
    @track imageUploadPage = false;
    @track showRemarks = false;
  //  @track followUpDate = null;
@track showFollowUpDate = false;

        @track load = false;

        @track selectedDateTime;




    reasonOptions = [
        { label: 'House Lock', value: 'House Lock' },
        { label: 'Customer Not Interested', value: 'Customer Not Interested' },
        { label: 'Name Transfer Required', value: 'Name Transfer Required' },
        { label: 'Customer Will Submit Query via Link', value: 'Customer Will Submit Query via Link' },
        { label: 'Contractor Query', value: 'Contractor Query' },

        { label: 'Meter collected by demolition team', value: 'Meter collected by demolition team' },
        { label: 'Wrong number / house visited / house lock', value: 'Wrong number / house visited / house lock' },
        { label: 'Conflict between customer and new flat owner / builder', value: 'Conflict between customer and new flat owner / builder' },
        { label: 'Duplicate complaint', value: 'Duplicate complaint' },
        { label: 'Temporary disconnection', value: 'Temporary disconnection' },
        { label: 'Building collapsed', value: 'Building collapsed' },
        { label: 'Customer out of station', value: 'Customer out of station' },

        { label: 'Others', value: 'Others' },
    ];

    
    connectedCallback(){
        this.setPhotoUploadSlots();
        console.log('record id::', this.recordId);
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
            label: `House Lock`,
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }



    handleReasonChange(event) {

    this.notes='';
    const selectedValue = event.detail.value;
    console.log('select reason::', event.target.value);
    const selectedOption = this.reasonOptions.find(opt => opt.value === selectedValue);

    this.selectedReason = selectedOption ? selectedOption.label : '';

    this.showRemarks = this.selectedReason === 'Others';
    this.imageUploadPage = this.selectedReason === 'House Lock';
    this.showFollowUpDate = this.selectedReason === 'House Lock';

    // Only create slots if photo section is needed
    if (this.imageUploadPage) {
        this.setPhotoUploadSlots();
    } else {
        console.log('inside photo upload slot');
        this.photoUploadSlots = []; // reset
    }
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

    LightningAlert.open({
            message: 'Please Select Correct Date',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
   // this.showtoast('Warning', 'Please Select Correct Date', 'warning');
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

        this.load=true;

    // if (!this.selectedReason) {
    //     this.dispatchEvent(new ShowToastEvent({
    //         title: 'Error',
    //         message: 'Please select a reason.',
    //         variant: 'error'
    //     }));
    //             this.load=false;

    //     return;
    // }

    if(this.selectedReason ==''){

        LightningAlert.open({
            message: 'Please Select Reason For Unsuccessful Visit',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
        //  this.showtoast('Warning', 'Please Select Reason For Unsuccessful Visit.', 'warning');
        this.load=false;
        return;
    }

    if (this.selectedReason === 'House Lock' && !this.selectedDateTime) {

                LightningAlert.open({
            message: 'Please Select Follow-up Visit Date',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });

   
     // this.showtoast('Warning', 'Please Select Follow-up Visit Date.', 'warning');

  this.load=false;

    return;
}


    if (this.selectedReason === 'Others' && !this.notes.trim()) {

                LightningAlert.open({
            message: 'Please Enter Remark',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });

       
       // this.showtoast('Warning', 'Please Enter Remark.', 'warning');
         this.load=false;
        return;
    }

   // console.log('select reason insde::', this.selectedReason);

   // const requiresPhoto = this.selectedReason === 'House Lock';
   // const allUploaded = this.photoUploadSlots.every(slot => slot.uploaded && slot.base64Data);

    // if (requiresPhoto && !allUploaded) {
    //     this.dispatchEvent(new ShowToastEvent({
    //         title: 'Error',
    //         message: 'Please upload a photo for House Lock scenario.',
    //         variant: 'error'
    //     }));
    //                     this.load=false;

    //     return;
    // }

    //  const allFilesSelected = this.photoUploadSlots.length === 1 &&
    //         this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

    //     if (!allFilesSelected) {
    //         this.load = false;
    //         //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
    //         //this.showtoast('Warning', 'Please Capture 1 photos.', 'warning');
    //         this.dispatchEvent(new ShowToastEvent({
    //         title: 'Error',
    //         message: 'Please upload a photo for House Lock scenario.',
    //         variant: 'error'
    //     }));
    //         return;
    //     }


     const allFilesSelected = this.photoUploadSlots.length === 1 &&
            this.photoUploadSlots.every(slot => slot.fileName && slot.fileName.trim() !== '');
            if (!allFilesSelected && this.selectedReason =='House Lock') {

                console.log('selected reason ::', this.selectedReason);
                        LightningAlert.open({
            message: 'Please capture photo',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });

            //    this.showtoast('Warning', 'Please capture photo.', 'warning');
                this.load=false;
                return;
            }



    console.log('📸 Sending photoUploadSlots:', JSON.stringify(this.photoUploadSlots));
   // this.isLoading = true;

    var imagesList = [];
                this.photoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                 var temp = this.uploadFile(imagesList);


            submitUnsuccessfulVisit({workOrderId: this.recordId, reason: this.selectedReason, notes: this.notes, followUpDate: this.selectedDateTime,listFiles: imagesList }) 

            .then(result => {

                console.log('result submit unsuccessfull visit :::', result);

                this.load=false;

                    LightningAlert.open({
            message: 'Details Saved Successfully',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        });

               // this.showtoast('Success', 'Details Saved Successfully.', 'success');
                
             this.dispatchEvent(new CustomEvent('cancel'));



            })    
            .catch(error => {

                this.load=false;

                console.log('Error ::', error);
            })




    // const photoUploadPromise = requiresPhoto
    //     ? savePhotoUploadsIP({
    //         recordId: this.recordId,
    //         listFiles: this.imagesList
    //     })
    //     : Promise.resolve('SKIPPED');

    // photoUploadPromise
    // .then(uploadResult => {
    //     if (uploadResult.includes('ERROR')) {
    //         this.load=false;

    //         throw new Error(uploadResult);
    //     }

        // return submitUnsuccessfulVisit({
        //     workOrderId: this.recordId,
        //     reason: this.selectedReason,
        //     notes: this.notes || '',
        //     followUpDate: this.followUpDate
        // });
   // })
    // .then(() => {
    //     this.dispatchEvent(new ShowToastEvent({
    //         title: 'Success',
    //         message: 'Unsuccessful visit recorded successfully.',
    //         variant: 'success'
    //     }));
    //        this.load=false;

    //     this.showForm = false;
    //       this.dispatchEvent(new CustomEvent('cancel'));

    // })
    // .catch(error => {
    //     console.error('❌ Error during submission:', error);
    //     this.dispatchEvent(new ShowToastEvent({
    //         title: 'Error',
    //         message: this.getErrorMessage(error),
    //         variant: 'error'
    //     }));
    //                     this.load=false;

    // })
    // .finally(() => {
    //    this.load=false;

    // });
}

  uploadFile(imagesList) {

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