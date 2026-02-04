import { LightningElement,api,track } from 'lwc';
import fieldPicklistValue from '@salesforce/apex/RiserPaintingCOExecutionDetailsContr.fieldPicklistValue';
import getItemDescriptionOptions from '@salesforce/apex/RiserPaintingCOExecutionDetailsContr.getItemDescriptionOptions';
import saveAfterPaintingImages from '@salesforce/apex/RiserPaintingCOExecutionDetailsContr.saveAfterPaintingImages';
import saveBeforePaintingImages from '@salesforce/apex/RiserPaintingCOExecutionDetailsContr.saveBeforePaintingImages';
import createMaintenanceEntryAndDetailsRecord from '@salesforce/apex/RiserPaintingCOExecutionDetailsContr.createMaintenanceEntryAndDetailsRecord';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

let materialIdCounter = 1; 


export default class RiserPaintingCOExecutionDetailsComp extends LightningElement {

 @api recordId;

 @track load = false;

    @track photoUploadSlots=[];
        noOfPhotos;

    @track afterPaintingPhotoUploadSlots=[];
        afterPaintingNoOfPhotos;    

@track showAfterPaintingImages=false;

@track showMainEntry=true;

    @track risersNumber = '';
    @track risersFloors ='';
    @track lengthOfApprocahRiser='';

        @track typeOfRiser;
    @track riserPickListValue;

    @track showNextButton=false;
     @track showMaintenanceDetail = false;
     @track shwoPrNext = false;

    @track isFirst=false;
    @track isLast=false;

     @track FinalSave = false;

         @track riserData = [];

        @track itemDescriptionOptions = [];

        @track showHeightOfRiser=false;



mainOrApproachRiserOptions = [
        { label: 'Main Riser', value: 'Main Riser' },
        { label: 'Approach Riser', value: 'Approach Riser' }
    ];


     @track objectName = 'Maintenance_Entry__c';
    @track fieldName = 'Type_of_Riser__c';

        @track currentRiserView = 1;


        connectedCallback() {
            this.getFieldPickListValue();
            this.initializeRiserData();
          this.getItemDescriptionOptions();
         this.setAfterPaintingPhotoUploadSlots();



        }

  getFieldPickListValue() {
        fieldPicklistValue({ objectName: this.objectName, fieldName: this.fieldName })
            .then(data => {
                this.typeOfRiser = data;

            })
            .catch(error => {
                console.log('Error ::', error);
            })
    }

    setAfterPaintingPhotoUploadSlots() {
        this.afterPaintingPhotoUploadSlots = Array.from({ length: this.afterPaintingNoOfPhotos}, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label: `After Painting ${index + 1}`,
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    
}





  setPhotoUploadSlots() {
        this.photoUploadSlots = Array.from({ length: this.noOfPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label: `Before Painting ${index + 1}`,
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));
    }


 handleSave(event) {

         let id = event.currentTarget.dataset.id;

         
         const hasEmptyFields = this.riserData
            .filter(riser => riser.id == id)
            .some(riser =>

            riser.clampReplacement === false 
            
        //   || riser.noofClampsReplaced === null ||
        //     riser.epoxyPaintPrimer == false ||
        //     riser.lengthPaintedPrimer == ''||
        //     riser.dFTReadingPrimer == ''||
        //     riser.coat2PaintYellow == false ||
        //     riser.lengthPaintedYellow == ''||
        //     riser.dFTReadingYellow == ''||
        //     riser.coat3PaintYellow == false ||
        //     riser.lengthPaintedYellow3 == '' ||
        //     riser.dFTReadingYellow3 == '' ||
        //     riser.leakageRectification == false ||
        //    riser.crimpGuardReplacement == false ||
        //    riser.noofCrimpGuardsReplaced == null 
                                          
                );

         console.log('🔎 Current riser data being validated:', JSON.stringify(this.riserData.find(r => r.id == id), null, 2));


               console.log('has empty field:::', hasEmptyFields);


        if (hasEmptyFields) {
             this.showtoast('Warning', 'Please enter All required Fields', 'Warning');
             return;
        }

        else {
                    this.createMaintenanceEntryAndDetailsRecord();

        }
         
         
    }

      createMaintenanceEntryAndDetailsRecord() {

         this.load = true;
        console.log(' Starting handleSavePhotos...');
         console.log(' Base 64 ...', JSON.stringify(this.photoUploadSlots));

    //      this.riserData.forEach(riser => {
    //     if (riser.leakLocationList && riser.leakLocationList.length > 0) {
    //         riser.leakLocationList = riser.leakLocationList.map(item => item.value);
    //     }
    //     if (riser.valvesReplacedList && riser.valvesReplacedList.length > 0) {
    //         riser.valvesReplacedList = riser.valvesReplacedList.map(item => item.value);
    //     }
    // });

        console.log('Riser data ::', JSON.stringify(this.riserData));

         

        createMaintenanceEntryAndDetailsRecord({recordId : this.recordId, riserDetails: this.riserData, riserNumber: this.risersNumber, risersFloors: this.risersFloors, riserPickListValue: this.riserPickListValue, lengthOfApprocahRiser : this.lengthOfApprocahRiser})
            .then(result => {
                console.log('Result ::', result);
              //  this.showtoast('Success', 'Records Created Successfully', 'Success');

                 this.load=false;


             //  this.handleFinalAnyEncroachedSave();
             //   this.materialConsumption({recordId :this.recordId, })
              //  this.setPhotoUploadSlots();


                this.handleBeforePaintingFinalSave();


                this.showAfterPaintingImages=true;

                this.showMaintenanceDetail=false;
               this.showMainEntry=false;

               this.setAfterPaintingPhotoUploadSlots();

               // this.showRiserNoPick=false;

               // this.handleFinalNotSave();

              // this.load=false;

                //   if (this.materialList.length > 0 && this.hasValidMaterialData()) {
                // console.log('🔧 Saving Material Details:', JSON.stringify(this.materialList));

                // materialConsumption({
                //     recordId: this.recordId,
                //     materialList: this.materialList

                // });

                //  }

                //   if (this.flatNumberList.length > 0 && this.hasValidFlatNumberData()) {
                // console.log('🔧 Saving customer name and flat number Details:', JSON.stringify(this.customerNameFlatNumberList));

                // flatNumberData({
                //     recordId: this.recordId,
                //     flatNumberList: this.flatNumberList

                // });

               //  }
              //  this.handleCancel();

            })
            .catch(error => {
               // this.load=false;
                console.log('Error', error);
            })

    }



    async handleAfterPaintingFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.afterPaintingPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < afterPaintingPhotoUploadSlots.length; i++) {
        let slot = afterPaintingPhotoUploadSlots[i];
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


    
 async handleAfterPaintingFinalSave() {
       // const workStepName = 'Letters/Notices';
        const allFilesSelected = this.afterPaintingPhotoUploadSlots.length === this.risersNumber &&
            this.afterPaintingPhotoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.load = false;
            console.log('📸 Final slot data before save:', JSON.stringify(this.afterPaintingPhotoUploadSlots, null, 2));
            this.showtoast('Warning', 'Please Capture Required photos.', 'warning');
            return;
        }
      

        
        this.load = true;

         var imagesList = [];
                this.afterPaintingPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                var temp = this.uploadFile(imagesList);

        saveAfterPaintingImages({
            listFiles: imagesList,
            recordId: this.recordId,
          
           
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


    async handleBeforePaintingFinalSave() {
       // const workStepName = 'Letters/Notices';
     const allFilesSelected = this.photoUploadSlots.length === this.risersNumber &&
            this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
           // this.load = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
           // this.showtoast('Warning', 'Please Capture All photos.', 'warning');
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

        saveBeforePaintingImages({
            listFiles: imagesList,
            recordId: this.recordId,
          
           
        })
        .then((result) => {
          //  this.showtoast('Success', 'Images saved successfully!', 'success');
            this.load = false;
           
           // history.back();

           // this.dispatchEvent(new CustomEvent('cancel'));
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
    





     handleRiserChange(event) {

        this.risersNumber = parseInt(event.target.value, 10);


        if (this.risersNumber >= 1 && this.risersNumber <= 9) {

        this.currentRiserView = 1;
        this.initializeRiserData();
        if(this.risersNumber){
        this.showNextButton=true;
        this.showMaintenanceDetail=false;
       this.noOfPhotos = this.risersNumber; 
        this.setPhotoUploadSlots();
        this.afterPaintingNoOfPhotos=this.risersNumber;
        // this.afterPaintingNoOfPhotos = this.risersNumber;
        // this.setAfterPaintingPhotoUploadSlots();

        }

        }

        else {
       this.risersNumber = null;
        this.showNextButton = false;
        this.showMaintenanceDetail = false;
      this.showtoast('Warning', 'Please Enter Valid Number.', 'warning');

        }

        this.handleBeforePaintingFinalSave();
       // this.handleNextShowDetails();

    }

    handleFloorChange(event){

        this.risersFloors=event.target.value;
        console.log('Inside handle Floor change ::', this.risersFloors);

    }

     handlePicklistChange(event) {

        console.log('handle pick list value ::', event.target.value);
        this.riserPickListValue = event.target.value;

    }

      handleMaterialChange(event) {
        // const index = event.target.dataset.index;
        // const field = event.target.name;
        // const value = event.detail.value || event.target.value;

        // console.log(`Material Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        // this.materialList[index][field] = value;
          const riserId = parseInt(event.target.closest('[data-id]').dataset.id, 10);
    const materialId = event.target.dataset.materialId;
    const label = event.target.label;
    const value = event.detail.value;

    const riser = this.riserData.find(r => r.id === riserId);
    if (riser) {
        const material = riser.materialList.find(m => m.id == materialId);
        if (material) {
            if (label === 'Item Description') {
                material.itemDescription = value;
            } else if (label === 'Quantity') {
                material.quantity = value;
            }
        }
    }
    
    }

        handleNoOfLeakagesAndLocationsChange(event){

         const index = event.target.dataset.index;
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        console.log(`No of leakage and location Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        this.noofLeakagesAndLocations[index][field] = value;

        console.log('No of leakage and locations ::', JSON.stringify(this.noofLeakagesAndLocations));

        }

     handleFloorNumberAndRiserHeight(event){

        //  const index = event.target.dataset.index;
        // const field = event.target.name;
        // const value = event.detail.value || event.target.value;

        // console.log(`Floor number and riser height change - Index: ${index}, Field: ${field}, Value: ${value}`);
        // this.floorNumberAndRiserHeight[index][field] = value;

        // console.log('No of leakage and locations ::', JSON.stringify(this.floorNumberAndRiserHeight));
    const riserId = parseInt(event.target.closest('[data-id]').dataset.id, 10);
    const flatAndFloorId = event.target.dataset.flatAndFloorId;
    const label = event.target.label;
    const value = event.detail.value;

    const riser = this.riserData.find(r => r.id === riserId);
    if (riser) {
        const flatAndFloor = riser.floorNumberAndRiserHeight.find(m => m.id == flatAndFloorId);
        if (flatAndFloor) {
            if (label === 'Floor Number') {
                flatAndFloor.floorNumber = value;
            } else if (label === 'Riser Height') {
                flatAndFloor.riserHeight = value;
            }
        }
    }


        }

    handleRiserLengthChange(event){

        this.lengthOfApprocahRiser = event.target.value;
        console.log('Inside riser length change ::', this.lengthOfApprocahRiser);
    }

 get riserArray() {
        return this.riserData.map(riser => ({
            ...riser,
            isVisible: riser.id === this.currentRiserView
        }));
    }


     handleMaintainenceDetail(event) {
         
        const field = event.target.label;

        

                let value;
            if (event.target.type === 'checkbox') {
                value = event.target.checked;
            } else {
                value = event.target.value;
            }
        console.log('Field Name ::' + field);
        console.log('field value::', value);

        if(field=='Riser Category' && value=='Main Riser'){

            this.showHeightOfRiser=true;
        }
         if(field=='Riser Category' && value!='Main Riser'){

            this.showHeightOfRiser=false;
        }

      

       // const current = this.riserData.find(r => r.id === this.currentRiserView);

    const index = this.riserData.findIndex(r => r.id === this.currentRiserView);

      if(field =='Clamp Replacement' && value==false){
        console.log('inside clmap replacment unchecked');
            this.riserData[index].clampReplacement ='';
        }

          if(field =='Epoxy Paint Primer' && value==false){
            this.riserData[index].lengthPaintedPrimer ='';
            this.riserData[index].dFTReadingPrimer ='';

        }

          if(field =='Coat 2 Paint Yellow' && value==false){
            this.riserData[index].lengthPaintedYellow ='';
            this.riserData[index].dFTReadingYellow ='';

        }

          if(field =='Coat 3 Paint Yellow' && value==false){
            this.riserData[index].lengthPaintedYellow3 ='';
            this.riserData[index].dFTReadingYellow3 ='';

        }

     if(field =='No. of Crimp Guards Replaced' && value==false){
            this.riserData[index].noofCrimpGuardsReplaced ='';

        }

        




      
    // const nestedIndex = event.target.dataset.nestedIndex;


       if (index !== -1) {
        const updated = { ...this.riserData[index] };

        if (field === 'noofLeakages' || field === 'leakageLocations') {
            // Update nested noofLeakagesAndLocations field
            const leakList = [...updated.noofLeakagesAndLocations];
            leakList[nestedIndex][field] = value;
            updated.noofLeakagesAndLocations = leakList;
        } else {

        // Dynamically map label to key
        for (let key in updated) {
            if (key.toLowerCase().replace(/\s/g, '') === field.toLowerCase().replace(/\s/g, '')) {
                updated[key] = value;

                // Optional: clear field if checkbox unchecked
                if (key === 'clampReplacement' && !value) {
                    updated.noofClampsReplaced = null;
                }

                break;
            }
        }
        }

        const newData = [...this.riserData];
        newData[index] = updated;
        this.riserData = newData; // Triggers reactivity
    }

        // if (current) {
        //     for (let key in current) {
        //         if (key.toLowerCase().replace(/\s/g, '') === field.toLowerCase().replace(/\s/g, '')) {
        //             current[key] = value;
        //             break;
        //         }
        //     }
        // }
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



     handleNextShowDetails() {

        console.log('inside handle next show details');

        console.log('risernumber ::', this.riserNumber);

        if (!this.risersNumber  || !this.lengthOfApprocahRiser  ||  !this.risersFloors || !this.riserPickListValue ) {
            this.showtoast('Warning', 'Please Enter All Required Fields', 'warning');
            return;
        }

         const allFilesSelected = this.photoUploadSlots.length === this.risersNumber &&
            this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
           // this.load = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
            this.showtoast('Warning', 'Please Capture All photos.', 'warning');
            return;
        }

         


       // this.captureBeforePaintingImages = true; 

        if (this.currentRiserView == this.risersNumber) {

            console.log('inside currentriserview equal riser number');
            this.showMaintenanceDetail = true;
            this.showNextButton = false;
            this.shwoPrNext = false;
           
            this.shwoPrNext=true;
            this.isFirst=true;
            this.isLast=true
            this.FinalSave = true;

        }
           if (this.currentRiserView != this.risersNumber && this.currentRiserView == 1 ) {
            
            console.log('inside currentriserview not equal to riser number');

            this.showMaintenanceDetail = true;
            this.showNextButton = false;
            this.shwoPrNext = true;
            this.isFirst=true;
            this.FinalSave=false;

            

        }
       

       
      
    }

     handleNext(event) {
        console.log('current riser number', this.risersNumber);
        console.log('current riser view', this.currentRiserView);
        console.log('current riser name', JSON.stringify(this.riserArray));
        let id = event.currentTarget.dataset.id;

        console.log('id:::', event.currentTarget.dataset.id);

        console.log('Riser data:::', JSON.stringify(this.riserData));

      
        // this.materialList=[];

        
        const hasEmptyFields = this.riserData
            .filter(riser => riser.id == id)
            .some(riser =>
            
             riser.clampReplacement === false
        //     || riser.noofClampsReplaced === null ||
        //     riser.epoxyPaintPrimer == false ||
        //     riser.lengthPaintedPrimer == ''||
        //     riser.dFTReadingPrimer == ''||
        //     riser.coat2PaintYellow == false ||
        //     riser.lengthPaintedYellow == ''||
        //     riser.dFTReadingYellow == ''||
        //     riser.coat3PaintYellow == false ||
        //     riser.lengthPaintedYellow3 == '' ||
        //     riser.dFTReadingYellow3 == '' ||
        //     riser.leakageRectification == false ||
        //    riser.crimpGuardReplacement == false ||
        //    riser.noofCrimpGuardsReplaced == null 
          

            );

            console.log('🔎 Current riser data being validated:', JSON.stringify(this.riserData.find(r => r.id == id), null, 2));


                    console.log('has empty field:::', hasEmptyFields);


        if (hasEmptyFields) {
             this.showtoast('Warning', 'Please enter all required fields', 'warning');
             return;
        }
               
        else if (this.currentRiserView != this.risersNumber) {
            console.log('inside if');
            this.showMaintenanceDetail = true;
            this.isFirst=false;
            this.currentRiserView += 1;
            this.riserData = [...this.riserData];

            this.materialList = this.riserData.find(r => r.id == this.currentRiserView)?.materialList || [];
            this.floorNumberAndRiserHeight = this.riserData.find(r => r.id == this.currentRiserView)?.floorNumberAndRiserHeight || [];


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

                this.materialList = this.riserData.find(r => r.id == this.currentRiserView)?.materialList || [];
                this.floorNumberAndRiserHeight = this.riserData.find(r => r.id == this.currentRiserView)?.floorNumberAndRiserHeight || [];


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






    initializeRiserData() {
        this.riserData = Array.from({ length: this.risersNumber }, (_, i) => ({

            id: i + 1,
             riserCategory : '',
           clampReplacement : false,
           noofClampsReplaced : null,
            epoxyPaintPrimer : false,
            lengthPaintedPrimer : '',
            dFTReadingPrimer : '',
            coat2PaintYellow : false,
            lengthPaintedYellow : '',
            dFTReadingYellow : '',
            coat3PaintYellow : false,
            lengthPaintedYellow3 : '',
            dFTReadingYellow3 : '',
            leakageRectification : false,
           crimpGuardReplacement : false,
           noofCrimpGuardsReplaced : null,
           heightofriserfloorwise : false,
            isVisible: true,

             materialList : [{
             id: i+1, 
             itemDescription: '',
            quantity: ''
            }],
              floorNumberAndRiserHeight : [{
                id: i+1,
                floorNumber: '',
                riserHeight: ''
    }]

         
        }));
    }

    //  @track materialList = [{
    //      riserId: '',
    //     itemDescription: '',
    //     quantity: ''
    // }];

     addMaterialRow(event) {

    //     const riserId = event.currentTarget.dataset.id;

    //       const riser = this.riserData.find(r => r.id === riserId);


    //     console.log('Adding new material row');
    //    // this.materialList.push({

    //         if (riser) {

    //         riser.materialList.push({

    //         riserId: riserId,
    //         itemDescription: '',
    //         quantity: ''
    //     });
    //         }

       const riserId = parseInt(event.currentTarget.dataset.id, 10);
        const riser = this.riserData.find(r => r.id === riserId);
        if (riser) {
            riser.materialList.push({
            id: Date.now() + Math.random(), 
            riserNumber : '',
            itemDescription: '',
                quantity: ''
            });
        }
    }

     removeMaterialRow(event) {
        // const index = event.target.dataset.index;
        // console.log(`Removing material row at index: ${index}`);
        // if (this.materialList.length > 1) {
        //     this.materialList.splice(index, 1);
        // }

       const riserId = parseInt(event.target.dataset.id, 10);
    const materialId = event.target.dataset.materialId;
    const riser = this.riserData.find(r => r.id === riserId);
    if (riser) {
        riser.materialList = riser.materialList.filter(m => m.id != materialId);
    }
    }

     hasValidMaterialData() {
        // return this.materialList.some(row => 
        //     (row.itemDescription && row.itemDescription.trim() !== '') ||
        //     (row.quantity && row.quantity.trim() !== '')
        // );
         return this.riserData.some(riser =>
            riser.materialList.some(row =>
                (row.itemDescription && row.itemDescription.trim() !== '') ||
                (row.quantity && row.quantity.trim() !== '')
            )
        );
    }




@track noofLeakagesAndLocations = [{
        riserId: '',
        noofLeakages: '',
      leakageLocations: ''
    }];

     addLeakNumberAndLocationRow(event) {

    const riserId = event.currentTarget.dataset.id;

        console.log('Adding new flat number row');
        console.log("riser id::", riserId);
        this.noofLeakagesAndLocations.push({
          riserId: riserId,
             noofLeakages: '',
             leakageLocations: ''
        });
    }

     addFloorNumberAndRiserHeight(event) {

    const riserId = event.currentTarget.dataset.id;

        console.log('Adding new flat number row');
        console.log("riser id::", riserId);
        this.floorNumberAndRiserHeight.push({
            id: Date.now() + Math.random(), 
            riserNumber : '',        
             floorNumber: '',
             riserHeight: ''
        });
    }



 removeLeakNumberAndLocationRow(event) {
        const index = event.target.dataset.index;
        console.log(`Removing leakage and leak location row at index: ${index}`);
        if (this.noofLeakagesAndLocations.length > 1) {
            this.noofLeakagesAndLocations.splice(index, 1);
        }
    }

    // removeFloorNumberAndRiserHeight(event) {
    //     const index = event.target.dataset.index;
    //     console.log(`Removing leakage and leak location row at index: ${index}`);
    //     if (this.noofLeakagesAndLocations.length > 1) {
    //         this.noofLeakagesAndLocations.splice(index, 1);
    //     }
    // }


    // @track floorNumberAndRiserHeight = [{
    //     riserId: '',
    //     floorNumber: '',
    //   riserHeight: ''
    // }];

     addfloorNumberAndRiserHeightRow(event) {

    // const riserId = event.currentTarget.dataset.id;

    //     console.log('Adding new floor number and riser height row');
    //     console.log("riser id::", riserId);
    //     this.floorNumberAndRiserHeight.push({
    //       riserId: riserId,
    //          floorNumber: '',
    //          riserHeight: ''
    //     });

     const riserId = parseInt(event.currentTarget.dataset.id, 10);
        const riser = this.riserData.find(r => r.id === riserId);
        if (riser) {
            riser.floorNumberAndRiserHeight.push({
            id: Date.now() + Math.random(), 
            riserNumber : '',
           floorNumber: '',
           riserHeight: ''
            });
        }
    }



        removefloorNumberAndRiserHeightRow(event) {
        // const index = event.target.dataset.index;
        // console.log(`Removing floor number and riser height row at index: ${index}`);
        // if (this.floorNumberAndRiserHeight.length > 1) {
        //     this.floorNumberAndRiserHeight.splice(index, 1);
        // }

         const riserId = parseInt(event.target.dataset.id, 10);
    const materialId = event.target.dataset.materialId;
    const riser = this.riserData.find(r => r.id === riserId);
    if (riser) {
        riser.floorNumberAndRiserHeight = riser.floorNumberAndRiserHeight.filter(m => m.id != materialId);
    }

    //       const riserId = parseInt(event.target.dataset.id, 10);
    // const flatAndFloorId = event.target.dataset.flatAndFloorId;
    // const riser = this.riserData.find(r => r.id === riserId);
    // if (riser) {
    //     riser.floorNumberAndRiserHeight = riser.floorNumberAndRiserHeight.filter(m => m.id != flatAndFloorId);
    // }
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





showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }
     

}