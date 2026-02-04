import { LightningElement, track,api } from 'lwc';
import createMaintenanceEntryAndDetailsRecord from '@salesforce/apex/RiserDetailsCaptureContr.createMaintenanceEntryAndDetailsRecord';
import fieldPicklistValue from '@salesforce/apex/RiserDetailsCaptureContr.fieldPicklistValue';
import saveImage from '@salesforce/apex/RiserDetailsCaptureContr.saveImage';
import getItemDescriptionOptions from '@salesforce/apex/RiserDetailsCaptureContr.getItemDescriptionOptions';
import materialConsumption from '@salesforce/apex/RiserDetailsCaptureContr.materialConsumption';
import saveImageNotOk from '@salesforce/apex/RiserDetailsCaptureContr.saveImageNotOk';
import saveImageAnyEncroached from '@salesforce/apex/RiserDetailsCaptureContr.saveImageAnyEncroached';
import flatNumberData from '@salesforce/apex/RiserDetailsCaptureContr.flatNumberData';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class O_MRiserExecutionDetailsComp extends LightningElement {


    @track customerAvailability = '';

    @api recordId;
    @track showCheckBox = true;
    @track load = false;



    @track risersNumber = '';
    @track risersFloors ='';
    @track sampleBP1 = '';
    @track sampleBP2 = '';
    @track boardAvailable='';
    @track newInformationBoarInstalled = '';
    @track objectName = 'Maintenance_Entry__c';
    @track fieldName = 'Type_of_Riser__c';

    @track riserTestedStatusNotOk=false;

    @track ifYesShowanyencroachedcorrosionImageUpload=false;

    @track typeOfRiser;
    @track riserPickListValue;
    @track FinalSave = false;

    @track showMaintenanceEntry = false;
    @track showMaintenanceDetail = false;
    @track showNextButton = true;
    @track shwoPrNext = false;

    @track isFirst=false;
    @track isLast=false;

    @track afterImageRemark='';

    @track imageUploadPage=false;
    @track showRiserNoPick=true;

    @track showEnterFlatNumber=false;

    @track showEnterHolePiecesFlatNumber=false;

    @track showEnterAnacondasReplacedFlatNumber=false;

    @track showNewInformationBoarInstalled=false;

    @track showDetailsAfterSuspectedGas = false;


   // @track imageUploadPage=false;

    @track photoUploadSlots=[];
    noOfPhotos = 6;

       @track notOkPhotoUploadSlots = []; 
       noOfPhotosStatusNotOk = 1;

       @track showAnyEncroachedPhotoUploadSlots = []; 
       noOfPhotosAnyEncroached = 1;


        @track itemDescriptionOptions = [];



    @track currentRiserView = 1;

    @track riserData = [];

    @track showNoOfValvesReplaced=false;

      //  @track leakLocationList = [];



    connectedCallback() {
        console.log('record id::', this.recordId);
        this.getFieldPickListValue();
        this.initializeRiserData();
        this.getItemDescriptionOptions();
        this.setNotOkPhotoUploadSlots();
        this.setAnyEncroachedPhotoUploadSlots();


    }

     handleFlatNumberChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        console.log(`flat number Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        this.flatNumberList[index][field] = value;
    }

     handleHolePieceFlatNumberChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        console.log(`flat number Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        this.holePieceFlatNumberList[index][field] = value;
    }

     handleAnacondasReplacedFlatNumberChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        console.log(`flat number Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        this.anacondasReplacedFlatNumberList[index][field] = value;
    }

     handleSuspectedGasFlatNumberChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        console.log(`Suspected Gas Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        this.suspectedGasFlatNumberList[index][field] = value;
    }



     handleMaterialChange(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        console.log(`Material Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        this.materialList[index][field] = value;
    }

    addFlatNumberRow() {
        console.log('Adding new flat number row');
        this.flatNumberList.push({
            // itemCode: '',
          //  itemDescription: '',
          //  unit: '',
            flatNumber: ''
        });
    }

     addHolePieceFlatNumberRow() {
        console.log('Adding new flat number row');
        this.holePieceFlatNumberList.push({
            // itemCode: '',
          //  itemDescription: '',
          //  unit: '',
            flatNumber: ''
        });
    }

     addAnacondasReplacedFlatNumberRow() {
        console.log('Adding new flat number row');
        this.anacondasReplacedFlatNumberList.push({
            // itemCode: '',
          //  itemDescription: '',
          //  unit: '',
            flatNumber: ''
        });
    }


    addMaterialRow() {
        console.log('Adding new material row');
        this.materialList.push({
            // itemCode: '',
            itemDescription: '',
          //  unit: '',
            quantity: ''
        });
    }

     addSuspectedGasFlatNumberRow() {
        console.log('Adding new material row');
        this.suspectedGasFlatNumberList.push({
                      
          flatNumber: '',
          lIVplugstatus : ''


        });
    }

     getItemDescriptionOptions(){
        getItemDescriptionOptions({})
            .then(result => {
                this.itemDescriptionOptions = result.map(value => ({ label: value, value }));
                console.log('Fetched item description options:', this.itemDescriptionOptions);
            })
            .catch(error => {
                console.error('Error fetching item description options:', error);
            });
}

 removeFlatNumberRow(event) {
        const index = event.target.dataset.index;
        console.log(`Removing flat number row at index: ${index}`);
        if (this.flatNumberList.length > 1) {
            this.flatNumberList.splice(index, 1);
        }
    }

     removeHolePieceFlatNumberRow(event) {
        const index = event.target.dataset.index;
        console.log(`Removing flat number row at index: ${index}`);
        if (this.holePieceFlatNumberList.length > 1) {
            this.holePieceFlatNumberList.splice(index, 1);
        }
    }
    removeSuspectedGasFlatNumberRow(event) {
        const index = event.target.dataset.index;
        console.log(`Removing flat number row at index: ${index}`);
        if (this.suspectedGasFlatNumberList.length > 1) {
            this.suspectedGasFlatNumberList.splice(index, 1);
        }
    }

     removeAnacondasReplacedFlatNumberRow(event) {
        const index = event.target.dataset.index;
        console.log(`Removing flat number row at index: ${index}`);
        if (this.anacondasReplacedFlatNumberList.length > 1) {
            this.anacondasReplacedFlatNumberList.splice(index, 1);
        }
    }

     removeMaterialRow(event) {
        const index = event.target.dataset.index;
        console.log(`Removing material row at index: ${index}`);
        if (this.materialList.length > 1) {
            this.materialList.splice(index, 1);
        }
    }

     hasValidMaterialData() {
        return this.materialList.some(row => 
            (row.itemCode && row.itemCode.trim() !== '') ||
            (row.itemDescription && row.itemDescription.trim() !== '') ||
            (row.unit && row.unit.trim() !== '') ||
            (row.quantity && row.quantity.trim() !== '')
        );
    }

     @track materialList = [{
        itemCode: '',
        itemDescription: '',
        unit: '',
        quantity: ''
    }];

      @track flatNumberList = [{
       // itemCode: '',
       // itemDescription: '',
       // unit: '',
        flatNumber: ''
    }];

      @track holePieceFlatNumberList = [{
       // itemCode: '',
       // itemDescription: '',
       // unit: '',
        flatNumber: ''
    }];

     @track anacondasReplacedFlatNumberList = [{
       // itemCode: '',
       // itemDescription: '',
       // unit: '',
        flatNumber: ''
    }];

      @track suspectedGasFlatNumberList = [{
       // itemCode: '',
       // itemDescription: '',
       // unit: '',
        flatNumber: '',
        lIVplugstatus : ''
    }];

    getFieldPickListValue() {
        fieldPicklistValue({ objectName: this.objectName, fieldName: this.fieldName })
            .then(data => {
                this.typeOfRiser = data;

            })
            .catch(error => {
                console.log('Error ::', error);
            })
    }

    handleSave(event) {

         let id = event.currentTarget.dataset.id;

         
         const hasEmptyFields = this.riserData
            .filter(riser => riser.id == id)
            .some(riser =>
               // riser.name ==='' ||
               riser.riserCategory === '' ||
                riser.suspectedGasLeakageInHouseLock === '' ||
                riser.numberofLeakages === '' ||
                riser.clampsRepl === null ||
                riser.riserTestedStatus ==='' || riser.testPressure ==='' || 
                riser.duration === '' || riser.result === '' ||
                 riser.remark ===''
                // || riser.typeOfRiser === '' || riser.noOfCustomers ==='' 
              //  riser.noOfFloors ===null

                             
                );

               console.log('has empty field:::', hasEmptyFields);


        // if (hasEmptyFields) {
        //      this.showtoast('Warning', 'Please enter All required Fields', 'Warning');
        //      return;
        // }

       // else {
                    this.createMaintenanceEntryAndDetailsRecord();

      //  }
         


         
    }



    handlePicklistChange(event) {

        console.log('handle pick list value ::', event.target.value);
        this.riserPickListValue = event.target.value;

    }

    handleRiserChange(event) {

        this.risersNumber = parseInt(event.target.value, 10);


        if (this.risersNumber >= 1 && this.risersNumber <= 9) {

        this.currentRiserView = 1;
        this.initializeRiserData();
        if(this.risersNumber){
        this.showNextButton=true;
        this.showMaintenanceDetail=false;
        }

        }

        else {
       this.risersNumber = null;
        this.showNextButton = false;
        this.showMaintenanceDetail = false;
      this.showtoast('Warning', 'Please Enter Valid Number.', 'warning');

        }
       // this.handleNextShowDetails();

    }

    handleFloorChange(event){

        this.risersFloors=event.target.value;
        console.log('Inside handle Floor change ::', this.risersFloors);

    }

    handleBP1Change(event){

        this.sampleBP1 = event.target.value;
        console.log('Inside handlebp1change ::', this.sampleBP1);
    }

    handleBP2Change(event){

        this.sampleBP2=event.target.value;
        console.log('Inside handlebp2change :::', this.sampleBP2);
    }

    handleRemarkChange(event){

        this.afterImageRemark = event.target.value;
    }

    handleboardAvailableChange(event){

        this.boardAvailable = event.target.value;

        if(this.boardAvailable=='No'){

            this.showNewInformationBoarInstalled=true;
        }
         if(this.boardAvailable!='No'){

            this.showNewInformationBoarInstalled=false;
            this.newInformationBoarInstalled='';
        }
    }

     handleNewBoarInstalledChange(event){

        this.newInformationBoarInstalled = event.target.value;
    }

mainOrApproachRiserOptions = [
        { label: 'Main Riser', value: 'Main Riser' },
        { label: 'Approach Riser', value: 'Approach Riser' }
    ];

     anyencroachedcorrosionconditionOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

     livConnectivityOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    gasLeakLockCaseOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    typeOfBoard = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

     valvesReplacedOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    resultOptions = [
        { label: 'Ok', value: 'Ok' },
        { label: 'Not Ok', value: 'Not Ok' }
    ];

    typeOfRiserOptions = [
        { label: 'Welded', value: 'Welded' },
        { label: 'Threaded', value: 'Threaded' }
    ];


    

    riserTestedStatusOptions = [
        { label: 'OK', value: 'OK' },
        { label: 'Not OK', value: 'Not OK' },
        { label: 'Maintained and OK', value: 'Maintained and OK' }
    ];

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


    initializeRiserData() {
        this.riserData = Array.from({ length: this.risersNumber }, (_, i) => ({
            id: i + 1,
           // name: '',
           riserCategory : '',
            notOkRemark : '',
            anacondasReplaced: null,
            crimpGuardsReplaced: null,
           // encroachedCorrosion: '',
           anyencroachedcorrosioncondition : '',
            suspectedGasLeakageInHouseLock: '',
            gIPipeLengthReplaced: null,
            holePiecesReplace: null,
          //  leakLocations: '',
           // lIVConnectivity: '',
             lIVConnectivitywithflatno : '',
             leakLocationList: [],   
           // activeConnections: null,
            // maintenanceEntry: '',
          //  newMaterialsUsed: '',
           // clampsRepl: null,
           clampsReplaced : null,
            numberofLeakages: '',
            riserHeightFloorWise: '',
            riserNumber: null,
            riserTestedStatus: '',
            notOkRemark : '',
            valvesReplaced: '',
            numberOfValvesReplaced : '',
            valvesReplacedList : [],
            testPressure : '',
            duration : '',
            result : '',
            noofactivecustomers : '',
          //  noOfFloors : null,
            remark : '',
           // typeOfRiser : '',
            isVisible: true
        }));
    }




    handleMaintainenceDetail(event) {

      
//   if (event.target.label === 'Number of Leakages') {
//           //  this.numberOfLeakages = parseInt(value, 10);
//             this.leakLocationList = Array.from({ length: event.target.value }, (_, i) => ({
//                 index: i + 1,
//                 value: ''
//             }));
//         }
        
//           if (event.target.label.startsWith('LeakLocation')) {
//             const index = parseInt(fieldName.replace('LeakLocation', ''), 10);
//             this.leakLocationList[index - 1].value = value;
//         }

        
//      if (event.target.label === 'Number of Leakages') {

// this.numberOfLeakages =event.target.value;
//      }

        if(event.target.value=='Yes' && event.target.label=='Valves Replaced'){

            this.showNoOfValvesReplaced=true;
        }

        if(event.target.value=='Not OK' && event.target.label=='Riser Tested Status'){

            this.riserTestedStatusNotOk=true;
        }
         if(event.target.value=='Yes' && event.target.label=='Any encroached corrosion condition'){

            this.ifYesShowanyencroachedcorrosionImageUpload=true;
        }
         if(event.target.value=='Yes' && event.target.label=='LIV Connectivity with flat no'){

            this.showEnterFlatNumber=true;
        }

         if(event.target.value !='' && event.target.label=='Hole Pieces Replaced'){

            this.showEnterHolePiecesFlatNumber=true;
        }

         if(event.target.value !='' && event.target.label=='Anacondas Replaced'){

            this.showEnterAnacondasReplacedFlatNumber=true;
        }


        
         if(event.target.value =='Yes' && event.target.label=='Suspected Gas Leakage In House Lock'){

            this.showDetailsAfterSuspectedGas=true;
        }
        const field = event.target.label;
        const value = event.target.value;
        console.log('Field Name ::' + event.target.label);
        console.log('field value::', event.target.value);
        //  if(value=='Not OK'){

        //     this.riserTestedStatusNotOk=true;
        //     console.log('risertestedstatusnotok ::', this.riserTestedStatusNotOk);
        // }

        const current = this.riserData.find(r => r.id === this.currentRiserView);

         if (field  === 'Number Of Valves Replaced') {

            current.numberOfValvesReplaced = value;



          //  this.numberOfLeakages = parseInt(value, 10);
            current.valvesReplacedList = Array.from({ length: value }, (_, i) => ({
                index: i + 1,
                value: '',
                label: `Valves Replaced Location ${i + 1}` 
            }));

                 this.valvesReplacedList = [...current.valvesReplacedList];



        }
        
          if (field .startsWith('Valves Replaced Location')) {
            const index = parseInt(field.replace('Valves Replaced Location', ''), 10) - 1;
           this.valvesReplacedList[index].value = value;

              current.valvesReplacedList = [...this.valvesReplacedList];

        }

          if (field  === 'Number of Leakages') {

            current.numberofLeakages = value;



          //  this.numberOfLeakages = parseInt(value, 10);
            current.leakLocationList = Array.from({ length: value }, (_, i) => ({
                index: i + 1,
                value: '',
                label: `Leak Location ${i + 1}` 

            }));

                 this.leakLocationList = [...current.leakLocationList];

        }
        
          if (field.startsWith('Leak Location')) {
            const index = parseInt(field.replace('Leak Location', ''), 10) - 1;
            this.leakLocationList[index].value = value;

              current.leakLocationList = [...this.leakLocationList];

        }
        if (current) {
            for (let key in current) {
                if (key.toLowerCase().replace(/\s/g, '') === field.toLowerCase().replace(/\s/g, '')) {
                    current[key] = value;
                    break;
                }
            }
        }
    }

    get riserArray() {
        return this.riserData.map(riser => ({
            ...riser,
            isVisible: riser.id === this.currentRiserView
        }));
    }

    
    /*  setPhotoUploadSlots() {
        console.log('Inside method:', this.noOfPhotos);
        this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => {
            const slotNum = index + 1;
            return {
                id: slotNum,
                index: slotNum,
                label: `Photo ${slotNum}`,
                name: `fileUploader${slotNum}`,
                fileName: '',
                uploaded: false,
                previewUrl: ''
            };
        });
        console.log('📸 Photo Upload Slots:', JSON.stringify(this.photoUploadSlots));
    } */



    setAnyEncroachedPhotoUploadSlots() {
        this.showAnyEncroachedPhotoUploadSlots = Array.from({ length: this.noOfPhotosAnyEncroached }, (_, index) => ({
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

    setNotOkPhotoUploadSlots() {
        this.notOkPhotoUploadSlots = Array.from({ length: this.noOfPhotosStatusNotOk }, (_, index) => ({
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

async handleAnyEncroachedFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.showAnyEncroachedPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < showAnyEncroachedPhotoUploadSlots.length; i++) {
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

     async handleFinalAnyEncroachedSave() {
       // const workStepName = 'Letters/Notices';
        const allFilesSelected = this.showAnyEncroachedPhotoUploadSlots.length === 1 &&
            this.showAnyEncroachedPhotoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.load = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
           // this.showtoast('Warning', 'Please Capture 1 photos.', 'warning');
            return;
        }
      

        
        this.load = true;

         var imagesList = [];
                this.showAnyEncroachedPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                var temp = this.uploadFile(imagesList);

        saveImageAnyEncroached({
            listFiles: imagesList,
            recordId: this.recordId,
          
           
        })
        .then((result) => {
          //  this.showtoast('Success', 'Images saved successfully!', 'success');
            this.load = false;
           
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


 async handleNotOkFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.notOkPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < notOkPhotoUploadSlots.length; i++) {
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

     async handleFinalNotSave() {
       // const workStepName = 'Letters/Notices';
        const allFilesSelected = this.notOkPhotoUploadSlots.length === 1 &&
            this.notOkPhotoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.load = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
         
         //   this.showtoast('Warning', 'Please Capture 1 photos.', 'warning');
            return;
        }
      

        
        this.load = true;

         var imagesList = [];
                this.notOkPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                var temp = this.uploadFile(imagesList);

        saveImageNotOk({
            listFiles: imagesList,
            recordId: this.recordId,
          
           
        })
        .then((result) => {
         //   this.showtoast('Success', 'Images saved successfully!', 'success');
            this.load = false;
           
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

    
  hasValidFlatNumberData() {
        return this.flatNumberList.some(row => 
            (row.flatNumber && row.flatNumber.trim() !== '')
        );
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

    createMaintenanceEntryAndDetailsRecord() {

         this.load = true;
        console.log(' Starting handleSavePhotos...');
         console.log(' Base 64 ...', JSON.stringify(this.photoUploadSlots));

         this.riserData.forEach(riser => {
        if (riser.leakLocationList && riser.leakLocationList.length > 0) {
            riser.leakLocationList = riser.leakLocationList.map(item => item.value);
        }
        if (riser.valvesReplacedList && riser.valvesReplacedList.length > 0) {
            riser.valvesReplacedList = riser.valvesReplacedList.map(item => item.value);
        }
    });

         

        createMaintenanceEntryAndDetailsRecord({recordId : this.recordId, riserDetails: this.riserData, riserNumber: this.risersNumber, sampleBP1: this.sampleBP1, sampleBP2: this.sampleBP2, boardAvailable : this.boardAvailable,risersFloors : this.risersFloors, riserPickListValue : this.riserPickListValue, newInformationBoarInstalled : this.newInformationBoarInstalled })
            .then(result => {
                console.log('Result ::', result);
                this.load=false;
                this.showtoast('Success', 'Records Created Successfully', 'Success');

               this.handleFinalAnyEncroachedSave();
             //   this.materialConsumption({recordId :this.recordId, })
                this.setPhotoUploadSlots();
                this.imageUploadPage=true;
                this.showMaintenanceDetail=false;
                this.showRiserNoPick=false;

                this.handleFinalNotSave();

                  if (this.materialList.length > 0 && this.hasValidMaterialData()) {
                console.log('🔧 Saving Material Details:', JSON.stringify(this.materialList));

                materialConsumption({
                    recordId: this.recordId,
                    materialList: this.materialList

                });

                 }

                  if (this.flatNumberList.length > 0 && this.hasValidFlatNumberData()) {
                console.log('🔧 Saving customer name and flat number Details:', JSON.stringify(this.customerNameFlatNumberList));

                flatNumberData({
                    recordId: this.recordId,
                    flatNumberList: this.flatNumberList

                });

                 }
              //  this.handleCancel();

            })
            .catch(error => {
                console.log('Error', error);
            })

    }
/* handle file old 
         handleFile(event) {
        this.photoUploadSlots = event.detail.steps;
        console.log('handleFile this.photoUploadSlots::'+JSON.stringify(this.photoUploadSlots));
    }


*/
    //   handleCancel() {

    //     console.log('inside child close call');
    //     const closeEvent = new CustomEvent('close');
    //     this.dispatchEvent(closeEvent);
    //     console.log('close event ::', closeEvent);

    //    // this.showCaptureRiserDetails=false;
    //    // this.accountView=false;
    //     //  setTimeout(() => {
    //     //     history.back();
    //     // }, 1000);        
    //     //  console.log('inside handle cancel');
       
    // }

    // handle file new code

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



    
    async handleFinalSave() {
       // const workStepName = 'Letters/Notices';
        const allFilesSelected = this.photoUploadSlots.length === 6 &&
            this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.load = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
            this.showtoast('Warning', 'Please Capture 6 photos.', 'warning');
            return;
        }

        if(!this.afterImageRemark){

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
            afterImageRemark : this.afterImageRemark
           
        })
        .then((result) => {
            this.showtoast('Success', 'Images saved successfully!', 'success');
            this.load = false;
           // history.back();
            this.dispatchEvent(new CustomEvent('cancel'));
        })
        .catch(error => {
            this.load = false;
            //console.error('❌ Save error:', JSON.stringify(error, null, 2));
            const message = error?.body?.message || error?.message || 'Unknown error occurred';
            this.showtoast('Error', message, 'error');
        });
    }

 
    
    
    uploadFile(imagesList) {

    }
    
    
    
    
    
    
    

    handleNextShowDetails() {

        if (!this.risersNumber  || !this.sampleBP1  || !this.sampleBP2 || !this.boardAvailable || !this.risersFloors || !this.riserPickListValue ) {
            this.showtoast('Warning', 'Please Enter All Required Fields', 'Warning');
            return;
        }

        

        if (this.currentRiserView == this.risersNumber) {
            this.showMaintenanceDetail = true;
            this.showNextButton = false;
            this.shwoPrNext = false;
           // this.imageUploadPage=true;
            this.shwoPrNext=true;
            this.isFirst=true;
            this.isLast=true
            this.FinalSave = true;

        }
           if (this.currentRiserView != this.risersNumber && this.currentRiserView == 1 ) {
            this.showMaintenanceDetail = true;
            this.showNextButton = false;
            this.shwoPrNext = true;
            this.isFirst=true;
            this.FinalSave=false;

            
           // this.FinalSave = true;

        }
       
        // else if (this.riserPickListValue == '' || this.riserPickListValue == null) {
        //      this.showtoast('Warning', 'Type Of Riser Field Required', 'Warning');

        //  }
        // else {
        //     this.showMaintenanceDetail = true;
        //     this.showNextButton = false;
        //     this.shwoPrNext = true;
        // }
    }

    handleNext(event) {
        console.log('current riser number', this.risersNumber);
        console.log('current riser view', this.currentRiserView);
        console.log('current riser name', JSON.stringify(this.riserArray));
        let id = event.currentTarget.dataset.id;

        console.log('id:::', event.currentTarget.dataset.id);

        console.log('Riser data:::', JSON.stringify(this.riserData));

        this.ifYesShowanyencroachedcorrosionImageUpload=false;
        this.showEnterFlatNumber=false;
         this.riserData.leakLocationList=[];
         this.riserTestedStatusNotOk=false;
         this.showNoOfValvesReplaced=false;
         this.riserData.valvesReplacedList=[];
         this.materialList=[];

        
        const hasEmptyFields = this.riserData
            .filter(riser => riser.id == id)
            .some(riser =>
              //  riser.name ==='' ||
              riser.riserCategory === '' ||
                riser.gasLeakLockCase === '' ||
                riser.numberofLeakages === '' ||
                riser.clampsRepl === null ||
                riser.riserTestedStatus ==='' || riser.testPressure ==='' || 
                riser.duration === '' || riser.result === '' ||
                riser.remark ==='' 
               // || riser.typeOfRiser ==='' || riser.noOfFloors === null ||  riser.noOfCustomers ==='' 
              

            );

            console.log('🔎 Current riser data being validated:', JSON.stringify(this.riserData.find(r => r.id == id), null, 2));


                    console.log('has empty field:::', hasEmptyFields);


        if (hasEmptyFields) {
         //    this.showtoast('Warning', 'Please enter all required fields', 'Warning');
             return;
        }
               
        else if (this.currentRiserView != this.risersNumber) {
            console.log('inside if');
            this.showMaintenanceDetail = true;
            this.isFirst=false;
            this.currentRiserView += 1;
            this.riserData = [...this.riserData];

        }

         if (this.currentRiserView == this.risersNumber) {
            console.log('current riser view and number are same::');
            this.showMaintenanceDetail = true;
            this.shwoPrNext = true;
            this.isFirst=false;
            this.isLast=true;
            this.FinalSave = true;
          //  this.imageUploadPage=true;

        }
        



    }

    handlePrevious() {
        if (this.currentRiserView > 1) {
            console.log('inside handle previous 1');
           this.showMaintenanceDetail = true;
            this.currentRiserView -= 1;
            this.isLast=false;
            this.riserData = [...this.riserData];

        }
        //  else if (this.currentRiserView != this.risersNumber) {
        //     console.log('inside if');
        //     this.showMaintenanceDetail = true;
        //     this.isFirst=false;
        //     this.currentRiserView += 1;
        //     this.riserData = [...this.riserData];

        // }

         if (this.currentRiserView == this.risersNumber) {
            console.log('current riser view and number are same::');
            this.showMaintenanceDetail = true;
            this.shwoPrNext = true;
            this.isFirst=false;
            this.isLast=true;
            this.FinalSave = true;
          //  this.imageUploadPage=true;

        }

         if (this.currentRiserView != this.risersNumber && this.currentRiserView == 1 ) {
            this.showMaintenanceDetail = true;
            this.showNextButton = false;
            this.shwoPrNext = true;
            this.isFirst=true;
            this.FinalSave=false;

            
           // this.FinalSave = true;

        }


    }

   /* old handlefinalsave 
    handleFinalSave(){

        console.log('inside handle final save');
         
     const allFilesSelected = this.photoUploadSlots.length === 6 &&
        this.photoUploadSlots.every(slot => slot.fileName && slot.fileName.trim() !== '');

    if (!allFilesSelected) {
        this.load = false;
        this.showtoast('Warning', 'Please Capture  6 photos.', 'Warning');
        return;
    }
          this.load = true;
        console.log(' Starting handleSavePhotos...');
        console.log('Record id ::', this.recordId);
         console.log(' Base 64 ...', JSON.stringify(this.photoUploadSlots));
              
         saveImage({listFiles:this.photoUploadSlots,recordId:this.recordId})
        .then((result) => {

            console.log('Result ::', result);
           // this.showNext=false;
            
         this.showtoast('Success', 'Images saved successfully!', 'Success');
          this.load = false;

        this.dispatchEvent(new CustomEvent('cancel'));

         // this.handleCancel();          

        })                
            .catch(error => {
                this.load = false;
                console.error('Error updating work order:', error);
                this.error = error;
            });

        
    }  */



    showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }


    // handlePrevious(){

    //     this.showMaintenanceDetail=false;
    //     this.showMaintenanceEntry=true;

    // }

    // handleSection(){
    //     if(this.expandSection ==true && this.collapseSection==false ){
    //         this.collapseSection=true;
    //         this.expandSection=false;
    //     }
    //     else if(this.collapseSection ==true && this.expandSection==false){
    //         this.expandSection=true;
    //         this.collapseSection=false;
    //     }
    // }
    // handleSection1(){
    //     if(this.expandSection1 ==true && this.collapseSection1==false ){
    //         this.collapseSection1=true;
    //         this.expandSection1=false;
    //     }
    //     else if(this.collapseSection1 ==true && this.expandSection1==false){
    //         this.expandSection1=true;
    //         this.collapseSection1=false;
    //     }
    // }



}