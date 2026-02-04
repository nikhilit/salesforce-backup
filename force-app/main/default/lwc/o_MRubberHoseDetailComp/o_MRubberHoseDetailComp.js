import { LightningElement,track,api } from 'lwc';
import saveRubberHoseDetails from '@salesforce/apex/O_MRubberHoseDetailContr.saveRubberHoseDetails';
import saveMaterialDetails from '@salesforce/apex/O_MRubberHoseDetailContr.saveMaterialDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getItemDescriptionOptions from '@salesforce/apex/O_MRubberHoseDetailContr.getItemDescriptionOptions';
import getWOAccountDetails from '@salesforce/apex/O_MRubberHoseDetailContr.getWOAccountDetails';
import uploadRHReplacedServiceNote from '@salesforce/apex/O_MRubberHoseDetailContr.uploadRHReplacedServiceNote';
import LightningAlert from 'lightning/alert';
export default class O_MRubberHoseDetailComp extends NavigationMixin (LightningElement) {

    @api recordId;
    @track showRubberHoseField=true;
    @track load=false;

        @track afterImageCloserRemark='';

        @track showMeterNumber=true;


        @track showOldAndNewExpDate=false; 
        @track showLeftFields = false;

     @track photoUploadSlots=[];
   // noOfPhotos = 6;

    @track installationPhotoUploadSlots=[];

        noOfInstallationPhotos = 1;


    @track meterPhotoUploadSlots=[];

        noOfMeterPhotos =1;

     @track oldRubberHosePhotoUploadSlots=[];

        noOfOldRubberHosePhotos = 1;

    @track newRubberHosePhotoUploadSlots=[];

        noOfNewRubberHosePhotos = 1;





     closerRemarkOptions = [
    { label: 'Complaint attended customer cancelled request', value: 'Complaint attended customer cancelled request' },
    { label: 'Customer query resolved', value: 'Customer query resolved' },
    { label: 'Complaint attended and closed', value: 'Complaint attended and closed' }
   
];

 rhLengthOptions = [
    { label: '1', value: '1' },
    { label: '1.5', value: '1.5' }
   
];

   leakLocationOptions = [
    { label: 'Copper Pipe', value: 'Copper Pipe' },
    { label: 'Appliance valve', value: 'Appliance valve' },
    { label: 'Nozzle', value: 'Nozzle' }
   
];


  @track rubberHose = {
        meterNumber: '',
        meterReading: '',
        oldHoseExpiry: '',
        newHoseExpiry: '',
        rhLength: '',
       // materialUsed: '',
        numberOfleakageObserved: '',
        leakagelocations : []
       // leakagelocations : ''

    };

     numberofLeakagesOptions = [
    { label: '1', value: '1' },
    { label: '2', value: '2' },
    { label: '3', value: '3' },
    { label: '4', value: '4' },
    { label: '5', value: '5' },
    { label: '6', value: '6' },
    { label: '7', value: '7' },
    { label: '8', value: '8' },
    { label: '9', value: '9' },
    { label: '10', value: '10' }
];

  itemCodeOptions = [
    { label: '1030201010011', value: '1030201010011' },
    { label: '1030201010012', value: '1030201010012' },
    { label: '1030203010011', value: '1030203010011' },
    { label: '1030203010012', value: '1030203010012' },
    { label: '1080101020011', value: '1080101020011' },
    { label: '1080201010011', value: '1080201010011' },
    { label: '1110102020011', value: '1110102020011' },
    { label: '1120201010011', value: '1120201010011' },
    { label: '1120203010021', value: '1120203010021' },
    { label: '1120203030011', value: '1120203030011' },
    { label: '1151601010011', value: '1151601010011' }

];

    @track accMeterNo='';

    @track itemDescriptionOptions = [];

    @track materialList = [{
       // itemCode: '',
        itemDescription: '',
        itemCode : '',
      //  unit: '',
        quantity: ''
    }];

    @track fileName = '';
      @track fileData='';
          selectedFile;


    connectedCallback(){

        console.log('Record id parent to child ::'+ this.recordId);
        this.showMaterialSection = true;
        this.getWOAccountDetails();
        this.setInstallationPhotoUploadSlots();
        this.setMeterPhotoUploadSlots();
        this.setOldRubberHosePhotoUploadSlots();
        this.setNewRubberHosePhotoUploadSlots();

        getItemDescriptionOptions()
            .then(result => {
                this.itemDescriptionOptions = result.map(value => ({ label: value, value }));
                console.log('Fetched item description options:', this.itemDescriptionOptions);
            })
            .catch(error => {
                console.error('Error fetching item description options:', error);
            });
    }

    getWOAccountDetails(){
        console.log('inside getWOAccountDetails method');
         console.log('record id inside method', this.recordId );

        getWOAccountDetails({recordId : this.recordId})
        .then( result => {
            console.log('Result old meter number ::', result);
            this.accMeterNo = result;
        })
        .catch( error => {
            console.log('Error get old meter number:', error.message);
            console.log(JSON.stringify(error)); // Optional: view full error

        })
    }

     handleRemarkChange(event){

        this.afterImageCloserRemark = event.target.value;
    }

    handleMeterNumberPage(){

        this.showOldAndNewExpDate=true;
        this.showMeterNumber=false;

//         console.log('Meter Number ::', this.rubberHose.meterNumber);

//         if(this.rubberHose.meterNumber==''){

//           this.showtoast('Error','Please enter a valid number.','error');
//     return;   
//         }

//   const newVal = Number(this.rubberHose.meterNumber);
//   const oldVal = Number(this.accMeterNo);
//   console.log('New:', newVal, 'Old:', oldVal);

//   if (isNaN(newVal)) {
//     console.log('Not a number');
//     this.showtoast('Error','Please enter a valid number.','error');
//     return;
//   }

//   if (newVal !== oldVal) {
//     console.log('Values do not match');
//          this.showtoast('Warning', 'New meter number does not match previous meter number', 'warning');
//   this.showOldAndNewExpDate=true;
//         this.showMeterNumber=false;
//   }

//   if (newVal == oldVal) {
//     console.log('Values do  match');
//          this.showtoast('Success', 'New meter number match previous meter number', 'success');
//   this.showOldAndNewExpDate=true;
//         this.showMeterNumber=false;
//   }

   //this.showtoast('Success', 'New meter number match previous meter number', 'success');

        // this.showOldAndNewExpDate=true;
        // this.showMeterNumber=false;


    }

     handleMeterNumberValidate(){

        console.log('Meter Number ::', this.rubberHose.meterNumber);

        if(this.rubberHose.meterNumber==''){

           LightningAlert.open({
            message: 'Please enter a valid number.',
            theme: 'error',   // red error dialog
            label: 'Error'    // header text
        });


        //   this.showtoast('Error','Please enter a valid number.','error');
    return;   
        }

  const newVal = Number(this.rubberHose.meterNumber);
  const oldVal = Number(this.accMeterNo);
  console.log('New:', newVal, 'Old:', oldVal);

  if (isNaN(newVal)) {
    console.log('Not a number');
    // this.showtoast('Error','Please enter a valid number.','error');
    LightningAlert.open({
    message: 'Please enter a valid number.',
    theme: 'error',   // red error dialog
    label: 'Error'    // header text
});
    return;
  }

  if (newVal !== oldVal) {
    console.log('Values do not match');
        // this.showtoast('Warning', 'New meter number does not match previous meter number', 'warning');
            LightningAlert.open({
            message: 'New meter number does not match previous meter number.',
            theme: 'warning',
            label: 'Warning'
        });
  }

  if (newVal == oldVal) {
    console.log('Values do  match');
        //  this.showtoast('Success', 'New meter number match previous meter number', 'success');
        LightningAlert.open({
    message: 'New meter number match previous meter number',
    theme: 'success',
    label: 'Success'
});

  
  }

   //this.showtoast('Success', 'New meter number match previous meter number', 'success');

        // this.showOldAndNewExpDate=true;
        // this.showMeterNumber=false;


    }


    // handleOldAndNewExpDatePage(){

    //      if (!this.rubberHose.oldHoseExpiry || !this.rubberHose.newHoseExpiry) {
    //          this.showtoast('Warning', 'Please enter rubber hose expiry fields', 'Warning');
    //          return;
    //     }else {
            
    //     this.showOldAndNewExpDate=false;
    //     this.showMeterNumber=false;
    //     this.showLeftFields=true;

    //     }
    // }



//     handleOldAndNewExpDatePage() {

//     if (!this.rubberHose.oldHoseExpiry || !this.rubberHose.newHoseExpiry) {
//          this.showtoast('Warning', 'Please enter rubber hose expiry fields', 'Warning');
//         return;
//     }

//     const today = new Date();
//     const expiryDate = new Date(this.rubberHose.oldHoseExpiry);

//     const sixMonthsAgo = new Date();
//     sixMonthsAgo.setDate(today.getDate() - 180);

//     // Validate oldhoseexpiry
//     if (expiryDate < sixMonthsAgo || expiryDate > today) {
//         this.showtoast(
//             'Warning',
//             'Old hose expiry date is invalid.',
//             'warning'
//         );
//         return;
//     }

//     console.log('oldhoseexpiry::satisfied');

//        this.showOldAndNewExpDate=false;
//         this.showMeterNumber=false;
//         this.showLeftFields=true;
//  }

    handleOldAndNewExpDatePage() {

    if (!this.rubberHose.oldHoseExpiry || !this.rubberHose.newHoseExpiry) {
        LightningAlert.open({
            message: 'Please enter rubber hose expiry fields.',
            theme: 'warning',
            label: 'Warning'
        });
        return;
    }

    const today = new Date();
    const expiryDate = new Date(this.rubberHose.oldHoseExpiry);

    const sixMonthsAgo = new Date();
    sixMonthsAgo.setDate(today.getDate() - 180);

    if (expiryDate < sixMonthsAgo || expiryDate > today) {
        LightningAlert.open({
            message: 'Old hose expiry date is invalid.',
            theme: 'warning',
            label: 'Warning'
        });
        return;
    }

    this.showOldAndNewExpDate = false;
    this.showMeterNumber = false;
    this.showLeftFields = true;
}


    handleOldAndNewExpDatePagePrevious(){

        this.showOldAndNewExpDate=false;
        this.showMeterNumber=true;
        this.showLeftFields=false;
    }

    handleShowExpDatePage(){

         this.showOldAndNewExpDate=true;
        this.showMeterNumber=false;
        this.showLeftFields=false;
    }

      setPhotoUploadSlots() {

         const customLabels = ['Meter Counter Photo','Meter & Regulator Installation Photo',  
                                    'Old Rubber Hose Image' ,'New Rubber Hose Image','RH Replaced Service Note', 
                                    'Unsafe Letter Issued'];

        this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label: customLabels[index] || `Photo ${slotNum}`,
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }

     setInstallationPhotoUploadSlots() {

            this.installationPhotoUploadSlots = Array.from({ length: this.noOfInstallationPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Installation Photo' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));


    }

     setMeterPhotoUploadSlots() {

            this.meterPhotoUploadSlots = Array.from({ length: this.noOfMeterPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Meter Photo' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }

     setOldRubberHosePhotoUploadSlots() {

            this.oldRubberHosePhotoUploadSlots = Array.from({ length: this.noOfOldRubberHosePhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Old Rubber Hose Image' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }

     setNewRubberHosePhotoUploadSlots() {

            this.newRubberHosePhotoUploadSlots = Array.from({ length: this.noOfNewRubberHosePhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'New Rubber Hose Image' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }





/* old setphotouploadslots

    setPhotoUploadSlots() {
        console.log('Inside method:', this.noOfPhotos);  
          const customLabels = ['Meter Counter Photo','Meter & Regulator Installation Photo',  
                                    'Old Rubber Hose Image' ,'New Rubber Hose Image','RH Replaced Service Note', 
                                    'Unsafe Letter Issued'];


        this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: customLabels[index] || `Photo ${slotNum}`,  
               // label: `Photo ${slotNum}`,
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: ''
            };
        });
        console.log('📸 Photo Upload Slots:', JSON.stringify(this.photoUploadSlots));
    } */


    handleRubberHoseDetail(event) {
        const field = event.target.name;
        const value = event.target.value;
        const fieldLabel = event.target.label;


         if (field  === 'numberOfleakageObserved') {

            console.log('inside field name number of leakage observed');

            this.rubberHose.numberOfleakageObserved = value;

            console.log('number of leakage observed::', this.rubberHose.numberOfleakageObserved);



          //  this.numberOfLeakages = parseInt(value, 10);
            this.rubberHose.leakagelocations = Array.from({ length: value }, (_, i) => ({
                index: i + 1,
                value: '',
                label: `Leakage location ${i + 1}` 
            }));

                 this.rubberHose.leakagelocations = [...this.rubberHose.leakagelocations];



        }
        
          if (fieldLabel .startsWith('Leakage location')) {
            console.log('inside leak location field change');
            const index = parseInt(fieldLabel.replace('Leakage location', ''), 10) - 1;
           this.rubberHose.leakagelocations[index].value = value;

              this.rubberHose.leakagelocations = [...this.rubberHose.leakagelocations];

        }


          if (field === 'oldHoseExpiry') {

        const today = new Date();
        const expiryDate = new Date(value);

        const sixMonthsAgo = new Date();
        sixMonthsAgo.setDate(today.getDate() - 180);

        //  expiry < (today - 180 days)  OR expiry > today
        if (expiryDate < sixMonthsAgo || expiryDate > today) {

            //  this.showtoast('Warning', 'Old hose expiry date is invalid.', 'warning');
        LightningAlert.open({
            message: 'Old hose expiry date is invalid.',
            theme: 'warning',
            label: 'Warning'
        });
          
        } else {
           console.log('oldhoseexpiry::satisfied');
        }

        this.rubberHose.oldHoseExpiry = value;
    }

    
        if (field) {
            this.rubberHose[field] = value;
        }

    }


     handleFileChange(event) {
        console.log('handle file change::');
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name;
            this.selectedFile = file;
            console.log('File Name::: ' + this.fileName);
            const reader = new FileReader();
 
            reader.onload = () => {
                this.fileData = reader.result.split(',')[1];
                console.log('File data :: '+ this.fileData);
            this.handleUpload();
 
            };
 
            reader.onerror = (error) => {
                console.log('Error reading file:', error);
            };
 
            reader.readAsDataURL(file);
 
 
        }
    }
 
    handleUpload() {
       
        console.log('handle upload :::: ');
        if (this.fileData && this.fileName) {
            console.log('File  name ::: ' + this.fileName);
           // console.log('File file data ::: ' + this.fileName);
 
            const reader = new FileReader();
            reader.onloadend = () => {
                const base64Data = reader.result.split(',')[1];
                this.selectedFileData = base64Data;
                console.log('base64data ::: '+ base64Data);
                console.log('upload file ::: '+ this.fileName);
             // this.uploadFile(this.fileName, base64Data);
 
 
            };
            reader.readAsDataURL(this.selectedFile);
        }
        else if(this.fileName == ''){
               LightningAlert.open({
            message: 'Please select a file to upload.',
            theme: 'warning',
            label: 'Warning'
        });
            // this.showtoast('Warning', 'Please select a file to upload.', 'warning');
 
        }
    }
 
     uploadServiceNotFile() {
 
       // this.isLoading = true;
        console.log('inside upload file::: ');
       
       
        uploadRHReplacedServiceNote({
            fileName: this.fileName,
            base64Data: this.selectedFileData,
            recordId : this.recordId
           
        })
            .then(result => {
                console.log('result sucess');

             //  this.showtoast('Success', 'Document Uploaded Successfully.', 'Success');

             //  this.handleCancel();

                   // this.showSubmit = true;
 
            })
            .catch(error =>{
 
              console.log('Error', error);
            })
     }

    handleMaterialChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        console.log(`Material Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        this.materialList[index][field] = value;
    }

    addMaterialRow() {
        console.log('Adding new material row');
        this.materialList.push({
            // itemCode: '',
            itemDescription: '',
            itemCode : '',
           // unit: '',
            quantity: ''
        });
    }

    removeMaterialRow(event) {
        const index = event.target.dataset.index;
        console.log(`Removing material row at index: ${index}`);
        if (this.materialList.length > 1) {
            this.materialList.splice(index, 1);
        }
    }

    handleNextShowUpload(){
      
        // if (!this.rubberHose.oldHoseExpiry || !this.rubberHose.newHoseExpiry) {
        //      this.showtoast('Warning', 'Please enter all required fields', 'Warning');
        //      return;
        // }
      //  else {
        this.imageUploadPage=true;
        this.showRubberHoseField=false;
        this.setPhotoUploadSlots();
     //   }
    }

    //handle file old

//  handleFile(event) {
//         this.photoUploadSlots = event.detail.steps;
//         console.log('handleFile this.photoUploadSlots::'+JSON.stringify(this.photoUploadSlots));
//     }

// handle file new code

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





    async handleInstallationPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.installationPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < installationPhotoUploadSlots.length; i++) {
        let slot = installationPhotoUploadSlots[i];
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


    async handleMeterPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.meterPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < meterPhotoUploadSlots.length; i++) {
        let slot = meterPhotoUploadSlots[i];
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

    async handleOldRubberHosePhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.oldRubberHosePhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < oldRubberHosePhotoUploadSlots.length; i++) {
        let slot = oldRubberHosePhotoUploadSlots[i];
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


    async handleNewRubberHosePhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.newRubberHosePhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < newRubberHosePhotoUploadSlots.length; i++) {
        let slot = newRubberHosePhotoUploadSlots[i];
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


    //  async handleFile(event) {
    //     console.log('📥 inside handleFile');
    //     let newSlots = event.detail.steps;

    //     for (let i = 0; i < newSlots.length; i++) {
    //     let slot = newSlots[i];
    //         console.log(`🔄 Processing Photo ${i + 1}`);

    //         if (slot.base64Data) {
    //             try {
    //                 // Add prefix if missing
    //                 const fullBase64 = slot.base64Data.startsWith('data:image')
    //                     ? slot.base64Data
    //                     : `data:image/jpeg;base64,${slot.base64Data}`;

    //                 // 🔍 Original size in MB
    //                 const originalBytes = atob(fullBase64.split(',')[1]).length;
    //                 const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
    //                 console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

    //                 // Convert to blob and compress
    //                 const blob = this.base64ToBlob(fullBase64);
    //                 const imageUrl = URL.createObjectURL(blob);
    //                 const compressedBlob = await this.compressImageFromURL(imageUrl);

    //                 // Convert compressed Blob back to base64
    //                 const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
    //                 const compressedBytes = atob(compressedBase64).length;
    //                 const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
    //                 console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

    //                 // Store compressed result
    //                 slot.base64Data = compressedBase64;

    //             } catch (error) {
    //             //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);

    //             // Only show toast if compressed base64 is not usable
    //             if (!slot.base64Data || slot.base64Data.length < 100) {
    //             console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
    //             } else {
    //                 console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
    //             }
    //         }


    //         } else {
    //             console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
    //         }
    //     }

    //     this.photoUploadSlots = newSlots;
    //     console.log('✅ Final photoUploadSlots set');
    // } 



    /* old base64blob
    base64ToBlob(base64Data) {
        const byteString = atob(base64Data.split(',')[1]);
        const mimeString = base64Data.split(',')[0].split(':')[1].split(';')[0];
        const ab = new ArrayBuffer(byteString.length);
        const ia = new Uint8Array(ab);
        for (let i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
        }
        return new Blob([ab], { type: mimeString });
    }

    compressImageFromURL(imageUrl) {
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

    convertBlobToBase64(blob) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(blob);
        });
    } */

    hasValidMaterialData() {
        return this.materialList.some(row => 
           // (row.itemCode && row.itemCode.trim() !== '') ||
            (row.itemDescription && row.itemDescription.trim() !== '') ||
            (row.itemCode && row.itemCode.trim() !== '') ||

          //  (row.unit && row.unit.trim() !== '') ||
            (row.quantity && row.quantity.trim() !== '')
        );
    }

    //  async handleFile(event) {
    //     console.log('📥 inside handleFile');
    //     //let newSlots = event.detail.steps;
    //     this.photoUploadSlots =event.detail.steps;
    //     for (let i = 0; i < photoUploadSlots.length; i++) {
    //     let slot = photoUploadSlots[i];
    //         console.log(`🔄 Processing Photo ${i + 1}`);

    //         if (slot.base64Data) {
    //             try {
    //                 // Add prefix if missing
    //                 const fullBase64 = slot.base64Data.startsWith('data:image')
    //                     ? slot.base64Data
    //                     : `data:image/jpeg;base64,${slot.base64Data}`;

    //                 // 🔍 Original size in MB
    //                 const originalBytes = atob(fullBase64.split(',')[1]).length;
    //                 const originalMB = (originalBytes / (1024 * 1024)).toFixed(2);
    //                 console.log(`📷 Original Size of Photo ${i + 1}: ${originalMB} MB`);

    //                 // Convert to blob and compress
    //                 const blob = this.base64ToBlob(fullBase64);
    //                 const imageUrl = URL.createObjectURL(blob);
    //                 const compressedBlob = await this.compressImageFromURL(imageUrl);

    //                 // Convert compressed Blob back to base64
    //                 const compressedBase64 = await this.convertBlobToBase64(compressedBlob);
    //                 const compressedBytes = atob(compressedBase64).length;
    //                 const compressedMB = (compressedBytes / (1024 * 1024)).toFixed(2);
    //                 console.log(`📉 Compressed Size of Photo ${i + 1}: ${compressedMB} MB`);

    //                 // Store compressed result
    //                 slot.base64Data = compressedBase64;

    //             } catch (error) {
    //             //console.error(`❌ Compression failed for Photo ${i + 1}:`, error);

    //             // Only show toast if compressed base64 is not usable
    //             if (!slot.base64Data || slot.base64Data.length < 100) {
    //             console.error(`❌ Compression failed for Photo ${i + 1}:`, error?.message || JSON.stringify(error) || 'Unknown error');
    //             } else {
    //                 console.warn(`⚠️ Compression threw error but base64 still present for Photo ${i + 1}`);
    //             }
    //         }


    //         } else {
    //             console.warn(`⚠️ Skipped Photo ${i + 1}: base64Data missing.`);
    //         }
    //     }

    //   //  this.photoUploadSlots = newSlots;
    //     console.log('✅ Final photoUploadSlots set');
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

     async handleFinalSave() {
       // const workStepName = 'Letters/Notices';
        // const allFilesSelected = this.photoUploadSlots.length === 6 &&
        //     this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        // if (!allFilesSelected) {
        //     this.load = false;
        //     //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
        //     this.showtoast('Warning', 'Please Capture 6 photos.', 'warning');
        //     return;
        // }

        if(!this.afterImageCloserRemark){

        //  this.showtoast('Warning', 'Please Enter Remark.', 'warning');
           LightningAlert.open({
            message: 'Please Enter Remark.',
            theme: 'warning',
            label: 'Warning'
        });
         return;
 
        }

       

        this.load = true;

          var imagesList = [];
                // this.photoUploadSlots.forEach(item => {
                //     imagesList.push({
                //         base64Data: item.base64Data,
                //         fileName: item.fileName,
                //         label: item.label
                //     })
                // })

                this.installationPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                 this.meterPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                  this.oldRubberHosePhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

              this.newRubberHosePhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })




                var temp = this.uploadFile(imagesList);

            const jsonData = JSON.stringify(this.rubberHose);

            console.log('RubberHoseDetails ::', jsonData);

            console.log('Final image list data::', JSON.stringify(imagesList));


        saveRubberHoseDetails({
          recordId: this.recordId,
          RubberHoseDetails: jsonData,
          listFiles: imagesList,
          afterImageRemark : this.afterImageCloserRemark

          
           
        })
        .then((result) => {

            console.debug('Result ::', result);
            if (this.materialList.length > 0 && this.hasValidMaterialData()) {

                saveMaterialDetails({
                    workOrderId: this.recordId,
                    materialList: this.materialList
                })
                .then(() => {
                console.log('Material details saved.');
            }).catch(error => {
                console.log('Error material save::', error);
            })



            }

            if(this.fileName && this.selectedFileData){

                this.uploadServiceNotFile();
            }


            // this.showtoast('Success', 'Details saved successfully!', 'success');
            LightningAlert.open({
                message: 'Details saved successfully!',
                theme: 'success',
                label: 'Success'
            });

            this.load = false;
           // history.back();
            this.dispatchEvent(new CustomEvent('cancel'));
        })
        .catch(error => {
            this.load = false;
            //console.error('❌ Save error:', JSON.stringify(error, null, 2));
            const message = error?.body?.message || error?.message || 'Unknown error occurred';
          //  this.showtoast('Error', message, 'error');
        });
    }

 
    
    
    uploadFile(imagesList) {

    }

/* old handleFinalSave
  handleFinalSave() {
    console.log('Inside handleFinalSave');

    const allFilesSelected = this.photoUploadSlots.length === 6 &&
        this.photoUploadSlots.every(slot => slot.fileName && slot.fileName.trim() !== '');
    console.log('allFilesSelected::', allFilesSelected);

    if (!allFilesSelected) {
        console.warn('Missing required photos');
        this.showtoast('Warning', 'Please capture 6 photos.', 'warning');
        return;
    }

    this.load = true;

    const jsonData = JSON.stringify(this.rubberHose);
    console.log('Rubber Hose JSON Data:', jsonData);




    // Save Rubber Hose Details + Photos
    saveRubberHoseDetails({
        recordId: this.recordId,
        RubberHoseDetails: jsonData,
        listFiles: this.photoUploadSlots
    })
        .then(result => {
            console.log('✅ Rubber Hose details saved:', result);
            console.log('⚠️ materialList:', JSON.stringify(this.materialList));

            // Save Material Consumption Details if applicable
            if (this.showMaterialSection && this.materialList.length > 0 && this.hasValidMaterialData()) {
                console.log('🔧 Saving Material Details:', JSON.stringify(this.materialList));

                saveMaterialDetails({
                    workOrderId: this.recordId,
                    materialList: this.materialList
                })
                    .then(matResult => {
                        console.log('✅ Material details saved:', JSON.stringify(matResult));

                        this.showtoast('Success', 'Record Updated Successfully.', 'success');
                        this.dispatchEvent(new CustomEvent('cancel'));

                        this.load = false;
                    })
                    .catch(error => {
                        console.error('❌ Error saving material details:', error);
                        this.showtoast('Error', 'Failed to save material details.', 'error');
                        this.load = false;
                    });

            } else {
                this.showtoast('Success', 'Record Updated Successfully.', 'success');
                this.load = false;
              this.dispatchEvent(new CustomEvent('cancel'));


            }
        })
        .catch(error => {
            console.error('❌ Error saving rubber hose details:', error);
            this.showtoast('Error', 'Failed to save rubber hose details.', 'error');
            this.load = false;
        });
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