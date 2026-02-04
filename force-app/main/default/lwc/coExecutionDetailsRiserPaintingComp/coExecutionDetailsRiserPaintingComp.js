import { LightningElement,api,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningAlert from 'lightning/alert';
import getWorkOrder from '@salesforce/apex/COExecutionDetailsRiserPaintingContr.getWorkOrder';
import saveCODetails from '@salesforce/apex/COExecutionDetailsRiserPaintingContr.saveCODetails';


export default class CoExecutionDetailsRiserPaintingComp extends LightningElement {

    @api recordId;
    @track load = false;

        @track isReadOnly=false;




    @track risersNumber = '';
    @track risersFloors ='';
    @track riserPickListValue;
    @track approcahRiserLength='';

     @track showWorkOrderLineItems=false;


    //@track showBeforeImage=false;

    //   @track photoUploadSlots=[];
    //     noOfPhotos;

        
    // @track afterPaintingPhotoUploadSlots=[];
    //     afterPaintingNoOfPhotos;  

     @track showSaveButton=true;


       typeOfRiserOptions = [
        { label: 'Welded', value: 'Welded' },
        { label: 'Threaded', value: 'Threaded' }
    ];


      connectedCallback() {
        
        this.getWorkOrder();
       // this.setAfterPaintingPhotoUploadSlots();

    }

    getWorkOrder(){

        getWorkOrder({recordId : this.recordId})

        .then( result => {

            console.log('Result getWorkOrder ::', JSON.stringify(result));
            if(result.Number_of_Risers__c){

               // this.showSaveButton = false;

                this.isReadOnly=true;


                this.risersNumber=result.Number_of_Risers__c;
                
                this.risersFloors = result.Number_of_Floors__c;
              
                this.riserPickListValue = result.Type_of_Riser__c;

                this.approcahRiserLength= result.Length_Of_Approcah_Riser__c;

                this.showWorkOrderLineItems=true;         


            }
            if(result.Number_of_Risers__c ==''){

                this.showSaveButton=true;
            }
        })
        .catch(Error => {

            console.log('Error ::', Error);
        })
    }



  handleRiserChange(event) {

        this.risersNumber = parseInt(event.target.value, 10);


        if (this.risersNumber >= 0 && this.risersNumber <= 25) {

      //  this.noOfPhotos = this.risersNumber; 
        this.showBeforeImage=true;
       // this.setPhotoUploadSlots();
       // this.afterPaintingNoOfPhotos=this.risersNumber;

        }

        else {
       this.risersNumber = null;
       
      //this.showtoast('Warning', 'Please Enter Valid Number.', 'warning');
      LightningAlert.open({
            message: 'Please Enter Valid Number.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        });
        }

    }

    handleFloorChange(event){

        this.risersFloors=event.target.value;
        console.log('Inside handle Floor change ::', this.risersFloors);

    }

      handlePicklistChange(event) {

        console.log('handle pick list value ::', event.target.value);
        this.riserPickListValue = event.target.value;

    }

 handleLengthChange(event) {

        console.log('handle length change value ::', event.target.value);
        this.approcahRiserLength = event.target.value;

    }

     handleSave(){

         if(this.load){
            return;
        }

        this.load=true;

          if (this.risersNumber === null || this.risersNumber === undefined || this.risersNumber === ''
          ||  !this.risersFloors || !this.riserPickListValue || !this.approcahRiserLength ) {
            // this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
            // this.load=false;
            LightningAlert.open({
            message: 'Please Enter All Required Fields',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
                    this.load=false;
         });
            return;
        }

        //  const allFilesSelected = this.photoUploadSlots.length === this.risersNumber &&
        //     this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        // if (!allFilesSelected) {
        //     this.load = false;
        //     //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
        //     this.showtoast('Warning', 'Please Capture All photos.', 'warning');
        //     return;
        // }
      

        

        //  var imagesList = [];
        //         this.photoUploadSlots.forEach(item => {
        //             imagesList.push({
        //                 base64Data: item.base64Data,
        //                 fileName: item.fileName,
        //                 label: item.label
        //             })
        //         })

        //listFiles: imagesList

        //         var temp = this.uploadFile(imagesList);

        // saveBeforePaintingImages({
        //     listFiles: imagesList,
        //     recordId: this.recordId,
          
           
        // })

        saveCODetails({recordId : this.recordId, riserNumber: this.risersNumber,risersFloors : this.risersFloors, riserPickListValue : this.riserPickListValue, approcahRiserLength : this.approcahRiserLength})
    
        .then(result => {

            //  this.showtoast('Success', 'Details Saved Successfully', 'success');
            // console.log('Result savecodetails::', result);
            //  this.load=false;
            // // this.handleCancel();
            // this.dispatchEvent(new CustomEvent ('cancel'));
             LightningAlert.open({
            message: 'Details Saved Successfully',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                    this.load=false;
                    this.dispatchEvent(new CustomEvent ('cancel'));
         });


        })
        .catch(Error => {

            console.log('Error savecodetails::', Error);
          this.load=false;

        })
    }


    //   uploadFile(imagesList) {

    // }
    

//      setPhotoUploadSlots() {
//         this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => ({
//             id: index + 1,
//             index: index + 1,
//             label: `Before Painting ${index + 1}`,
//             name: `fileUploader${index + 1}`,
//             fileName: '',
//             uploaded: false,
//             previewUrl: '',
//             base64Data: ''
//         }));
//     }


//      setAfterPaintingPhotoUploadSlots() {
//         this.afterPaintingPhotoUploadSlots = Array.from({ length: this.afterPaintingNoOfPhotos}, (_, index) => ({
//             id: index + 1,
//             index: index + 1,
//             label: `After Painting ${index + 1}`,
//             name: `fileUploader${index + 1}`,
//             fileName: '',
//             uploaded: false,
//             previewUrl: '',
//             base64Data: ''
//         }));
    
// }


// async handleFile(event) {
//         console.log('📥 inside handleFile');
//         //let newSlots = event.detail.steps;
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

//       //  this.photoUploadSlots = newSlots;
//         console.log('✅ Final photoUploadSlots set');
//     } 






//       async base64ToBlob(base64Data) {
//         const byteString = atob(base64Data.split(',')[1]);
//         const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];
//         const ab = new ArrayBuffer(byteString.length);
//         const ia = new Uint8Array(ab);
//         for (let i = 0; i < byteString.length; i++) {
//             ia[i] = byteString.charCodeAt(i);
//         }
//         return new Blob([ab], { type: mimeString });
//     }

//   async compressImageFromURL(imageUrl) {
//         return new Promise((resolve, reject) => {
//             const img = new Image();

//             img.onload = () => {
//                 try {
//                     const canvas = document.createElement('canvas');
//                     const ctx = canvas.getContext('2d');
//                     const maxWidth = 2400;
//                     const maxHeight = 2400;
//                     let width = img.width;
//                     let height = img.height;

//                     const ratio = Math.min(maxWidth / width, maxHeight / height);
//                     width *= ratio;
//                     height *= ratio;

//                     canvas.width = width;
//                     canvas.height = height;
//                     ctx.drawImage(img, 0, 0, width, height);

//                         try {
//                             canvas.toBlob(
//                                 (blob) => {
//                                     if (blob) {
//                                         resolve(blob);
//                                     } else {
//                                         console.warn('⚠️ toBlob returned null. Possibly tainted canvas or unsupported format.');
//                                         reject(new Error('Canvas compression failed. Blob was null.'));
//                                     }
//                                 },
//                                 'image/jpeg',
//                                 9.1
//                             );
//                         } catch (err) {
//                             console.error('❌ Error during canvas.toBlob execution:', err);
//                             reject(new Error('Exception during canvas.toBlob: ' + err.message));
//                         }
//                 } catch (error) {
//                     reject(new Error('Error during image compression: ' + error.message));
//                 }
//             };

//             img.onerror = () => {
//                 reject(new Error('Error loading image.'));
//             };

//             img.crossOrigin = 'anonymous';
//             img.src = imageUrl;
//         });
//     }

//    async convertBlobToBase64(blob) {
//         return new Promise((resolve, reject) => {
//             const reader = new FileReader();
//             reader.onload = () => resolve(reader.result.split(',')[1]);
//             reader.onerror = reject;
//             reader.readAsDataURL(blob);
//         });
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