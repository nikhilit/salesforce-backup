import { LightningElement,api,track } from 'lwc';
import getAccountDetails from '@salesforce/apex/BpDetailUpdateContr.getAccountDetails';
import updateAccountDetails from '@salesforce/apex/BpDetailUpdateContr.updateAccountDetails';
import generateAndAttachPdf from '@salesforce/apex/BpDetailUpdateContr.generateAndAttachPdf';
import materialConsumption from '@salesforce/apex/BpDetailUpdateContr.materialConsumption';
import getAccountAndMaterialDetails from '@salesforce/apex/BpDetailUpdateContr.getAccountAndMaterialDetails';
import LightningAlert from 'lightning/alert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const MATERIALS = [
    { code: '1030203010011', description: 'Meter Control Valve 1/2"' },
    //{ code: '1030203010012', description: 'Meter Control Valve 1/2"' },
    { code: '1030204010011', description: 'Riser Isolation Valve 1/2"' },
   // { code: '1030204010012', description: 'Riser Isolation Valve 1/2"' },
    { code: '1030204010021', description: 'Riser Isolation Valve 3/4"' },
   // { code: '1030204010022', description: 'Riser Isolation Valve 3/4"' },
    { code: '1030204010032', description: 'Riser Isolation Valve 1"' },
    { code: '1080101010011', description: 'Copper Tube 12 mm OD x 0.6 mm' },
    { code: '1090103010011', description: 'ERW Pipe (Med Cl) - GI & PC - 1/2" NB' },
    { code: '1090103010021', description: 'ERW Pipe (Med Cl) - GI & PC - 3/4" NB' },
    { code: '1090301010021', description: 'GI Elbow 90 deg 3/4" F/F' },
    { code: '1090301010031', description: 'GI Elbow 90 deg 1" F/F' },
    { code: '1090303010021', description: 'GI Plug 3/4"' },
    { code: '1090303010031', description: 'GI Plug 1"' },
    { code: '1090304010011', description: 'GI Socket 1/2"' },
    { code: '1090304010021', description: 'GI Socket 3/4"' },
    { code: '1090305010031', description: 'GI Reducer 1" x 1/2"' },
    { code: '1090305010041', description: 'GI Reducer 1" x 3/4"' },
    { code: '1090306010021', description: 'GI Equal Tee 3/4"' },
    { code: '1090307010011', description: 'GI Reducing Tee 3/4" x 1/2"' },
    { code: '1090307010021', description: 'GI Reducing Tee 1" x 1/2"' },
    { code: '1090308010011', description: 'GI Nipple 1/2" x 2"' },
    { code: '1090308010131', description: 'GI Nipple 1" x 2"' },
    { code: '1090309010021', description: 'GI Nipple Hex 1/2"' },
    { code: '1090309010031', description: 'GI Nipple Hex 3/4"' },
    { code: '1090310010031', description: 'GI Union 1"' },
    { code: '1090312010011', description: 'GI Reducing Bush 3/4" x 1/2"' },
    { code: '1090401010011', description: 'GI Elbow 90 deg 1/2" F/F (PC)' },
    //{ code: '1090401010012', description: 'GI Elbow 90 deg 1/2" F/F (PC)' },
    { code: '1090401010021', description: 'GI Elbow 90 deg 3/4" F/F (PC)' },
    { code: '1090401010031', description: 'GI Elbow 90 deg 1" F/F (PC)' },
    { code: '1090401020011', description: 'GI Elbow 90 deg 1/2" M/F (PC)' },
    { code: '1090401020021', description: 'GI Elbow 90 deg 3/4" M/F (PC)' },
    { code: '1090403010011', description: 'GI Plug 1/2" (PC)' },
    //{ code: '1090403010012', description: 'GI Plug 1/2" (PC)' },
    { code: '1090403010021', description: 'GI Plug 3/4" (PC)' },
    //{ code: '1090403010022', description: 'GI Plug 3/4" (PC)' },
    { code: '1090403010031', description: 'GI Plug 1" (PC)' },
    { code: '1090404010011', description: 'GI Socket 1/2" (PC)' },
    { code: '1090404010021', description: 'GI Socket 3/4" (PC)' },
    { code: '1090404010031', description: 'GI Socket 1" (PC)' },
    { code: '1090405010021', description: 'GI Reducer 3/4" x 1/2" (PC)' },
    { code: '1090405010041', description: 'GI Reducer 1" x 3/4" (PC)' },
    { code: '1090406010011', description: 'GI Equal Tee 1/2" (PC)' },
    { code: '1090406010021', description: 'GI Equal Tee 3/4" (PC)' },
    { code: '1090406010031', description: 'GI Equal Tee 1" (PC)' },
    { code: '1090407010011', description: 'GI Reducing Tee 3/4" x 1/2" (PC)' },
    { code: '1090407010021', description: 'GI Reducing Tee 1" x 1/2" (PC)' },
    { code: '1090408010011', description: 'GI Nipple 1/2" x 2" (PC)' },
    { code: '1090408010021', description: 'GI Nipple 1/2" x 4" (PC)' },
    //{ code: '1090408010022', description: 'GI Nipple 1/2" x 4" (PC)' },
    { code: '1090408010031', description: 'GI Nipple 1/2" x 6" (PC)' },
    { code: '1090408010061', description: 'GI Nipple 1/2" x 12" (PC)' },
    { code: '1090408010071', description: 'GI Nipple 3/4" x 2" (PC)' },
    { code: '1090408010081', description: 'GI Nipple 3/4" x 4" (PC)' },
    { code: '1090408010091', description: 'GI Nipple 3/4" x 6" (PC)' },
    { code: '1090408010131', description: 'GI Nipple 1" x 2" (PC)' },
    { code: '1090408010141', description: 'GI Nipple 1" x 4" (PC)' },
    { code: '1090408010151', description: 'GI Nipple 1" x 6" (PC)' },
    { code: '1090410010011', description: 'GI Union 1/2" (PC)' },
    { code: '1090410010021', description: 'GI Union 3/4" (PC)' },
    { code: '1090410010031', description: 'GI Union 1" (PC)' },
    { code: '1090412010011', description: 'GI Reducing Bush 3/4" x 1/2" (PC)' },
    { code: '1090412010021', description: 'GI Reducing Bush 1" x 1/2" (PC)' },
    { code: '1100103010011', description: 'ERW Pipe (Heavy Class)-PC-1/2" NB-Direct' },
    { code: '1100103010021', description: 'ERW Pipe (Heavy Class)-PC-3/4" NB-Direct' },
    { code: '1100103010031', description: 'ERW Pipe (Heavy Class) - PC-1" NB Direct' },
    { code: '1100103020011', description: 'ERW Pipe (Heavy Class) -GI&PC- 1/2" NB' },
    { code: '1100103020021', description: 'ERW Pipe (Heavy Class) -GI&PC- 3/4" NB' },
    { code: '1100103020031', description: 'ERW Pipe (Heavy Class) -GI&PC- 1" NB' },
    { code: '1100103020041', description: 'ERW Pipe (Heavy Class) -GI&PC- 1 1/2" NB' },
    { code: '1100201010011', description: 'GI Forge Elbow 90 deg 1/2" F/F' },
    { code: '1100201010021', description: 'GI Forge Elbow 90 deg 3/4" F/F' },
    { code: '1100201010031', description: 'GI Forge Elbow 90 deg 1" F/F' },
    { code: '1100201010041', description: 'GI Forge Elbow 90 deg 1 1/2" F/F' },
    { code: '1100201020011', description: 'GI Forge Elbow 90 deg 1/2" M/F' },
    { code: '1100203010031', description: 'GI Forge Plug 1"' },
    { code: '1100204010011', description: 'GI Forge Coupler 1/2"' },
    { code: '1100204010021', description: 'GI Forge Coupler 3/4"' },
    { code: '1100204010031', description: 'GI Forge Coupler 1"' },
    { code: '1100204010041', description: 'GI Forge Coupler 1 1/2"' },
    { code: '1100205010021', description: 'GI Forge Reducer 3/4" x 1/2"' },
    { code: '1100205010031', description: 'GI Forge Reducer 1" x 1/2"' },
    { code: '1100205010041', description: 'GI Forge Reducer 1" x 3/4"' },
    { code: '1100205010071', description: 'GI Forge Reducer 1 1/2" x 1"' },
    { code: '1100206010011', description: 'GI Forge Equal Tee 1/2"' },
    { code: '1100206010021', description: 'GI Forge Equal Tee 3/4"' },
    { code: '1100206010031', description: 'GI Forge Equal Tee 1"' },
    { code: '1100207010011', description: 'GI Forge Reducing Tee 3/4" x 1/2"' },
    { code: '1100207010021', description: 'GI Forge Reducing Tee 1" x 1/2"' },
    { code: '1100207010031', description: 'GI Forge Reducing Tee 1" x 3/4"' },
    { code: '1100207010041', description: 'GI Forge Reducing Tee 1 1/2" x 1/2"' },
    { code: '1100207010061', description: 'GI Forge Reducing Tee 1 1/2" x 1"' },
    { code: '1100310010021', description: 'GI Forge Union 3/4"' },
    { code: '1100310010031', description: 'GI Forge Union 1"' },
    { code: '1120201020011', description: 'Brass adap 1/2" x 1/2" - flex corr pipe' },
    { code: '1120203010021', description: 'Brass Disconn Union 1/2" x 12 mm (St)' },
    { code: '1120203010031', description: 'Brass Disconn Union 3/4" x 12 mm (St)' },
    { code: '1151501040011', description: 'Flex corr hose 1/2"x300mm(SS316L)PO SLV' },
    { code: '1151501060011', description: 'Rubber washer 1/2" (for flexible hose)' },
    { code: '1162701010081', description: 'PRE-SLEEVED GI HOLE PIECE - 1/2"x261 MM' },
    { code: '1162701010101', description: 'PRE-SLEEVED GI HOLE PIECE - 1/2"x311 MM' },
    { code: '1162701010111', description: 'PRE-SLEEVED GI HOLE PIECE - 1/2"x337 MM' },
    { code: '1162701010121', description: 'PRE-SLEEVED GI HOLE PIECE - 1/2"x362 MM' },
    { code: '1162701010131', description: 'PRE-SLEEVED GI HOLE PIECE - 1/2"x387 MM' }
];
 

  const DELAY = 300;


export default class BpDetailUpdateComp extends LightningElement {


@api accountId;

@api recordId;

@track load=false;

@track accountDetails=[];

@track meterShifted='';

@track showcoppermlclength=false;

//@track coppermlclength='';

@track meterNumber='';

@track meterReading='';

@track regulatorMake='';

@track connectionDone='';

@track leakageTestDone='';

@track gILength='';

@track copperlengthMLClength='';

//search item description 

     @track searchKey = '';
    @track filteredMaterials = [];
    @track selectedItemCode = '';
    delayTimeout;

    @track lastRowIndex='';

    get showDropdown() {
    return this.searchKey && this.filteredMaterials.length > 0;
}

    //search item description 

 riserPaintingOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

     connectionOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];


  @track photoBPUploadSlots=[];

        noOfPhotoBPUploadSlots = 1;

connectedCallback() {
    
    this.getAccountDetails();
   this.setPhotoBPUploadSlots();
   this.getAccountAndMaterialDetails();
   console.log('Work order id ::', this.recordId);


}

getAccountAndMaterialDetails(){

    getAccountAndMaterialDetails({recordId : this.accountId})
    .then(result => {

        console.log('Result getting account and material details ::', result);

         const accountDetails = result.accountDetail;

         console.log('Account details wrapper::', accountDetails);

         this.meterShifted = accountDetails.Meter_Shifted__c;
         if(this.meterShifted =='Yes'){
            this.showcoppermlclength=true;
            this.copperlengthMLClength = accountDetails.Copper_MLC_Length__c;

         }
         this.meterNumber = accountDetails.Meter_Number__c; 
         this.meterReading = accountDetails.Meter_Reading__c;
         this.regulatorMake= accountDetails.Regulator_Make__c;
         this.connectionDone = accountDetails.Connection_Done_Or_Not__c;
         this.leakageTestDone = accountDetails.LeakageTestDone__c;
         this.gILength = accountDetails.GI_Length__c;


         this.materialList = (result.materialConsumptions || []).map((m, index) => {
                return {
                 //   rowNumber: m.Material_Row_Number__c || (index + 1),
                   rowNumber: m.Material_Row_Number__c ? parseInt(m.Material_Row_Number__c, 10) : (index + 1),

                    itemCode: m.Item_Code_Riser_Activity__c,
                    itemDescription: m.Item_Description_Riser_Activity__c,
                    quantity: m.Quantity__c
                };
            });

            console.log('Material List ::', JSON.stringify(this.materialList));

             if (this.materialList.length > 0) {
            const maxRowNumber = Math.max(...this.materialList.map(r => Number(r.rowNumber)));
            this.lastRowIndex = maxRowNumber;
        } else {
            this.lastRowIndex = 0; // start from 0 if no records
        }


    })
    .catch(error => {
        console.log('Error:::', error);
    })
}

setPhotoBPUploadSlots() {

            this.photoBPUploadSlots = Array.from({ length: this.noOfPhotoBPUploadSlots }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Photo 1' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));

     }



getAccountDetails(){

    getAccountDetails({recordId : this.accountId})
    .then(result => {

        this.accountDetails = result;
    })
    .catch(error => {

        console.log('error::',error);
    })
}


handleMeterShifted(event){

    console.log('event target value::', event.target.value);

    this.meterShifted=event.target.value;

    if(this.meterShifted=='Yes'){

        this.showcoppermlclength=true;
    }
    if(this.meterShifted=='No'){

        this.showcoppermlclength=false;
    }
}


// handleCopperMlcChange(event){

//     console.log('event target value::', event.target.value);

//     this.coppermlclength=event.target.value;

// }

handleMeterNumberChange(event){

     console.log('event target value::', event.target.value);

    this.meterNumber=event.target.value;

}


handleMeterReadingChange(event){

     console.log('event target value::', event.target.value);

    this.meterReading=event.target.value;

}

handleRegulatorMakeChange(event){

     console.log('event target value::', event.target.value);

    this.regulatorMake=event.target.value;

}

handleConnectionDoneChange(event){

     console.log('event target value::', event.target.value);

    this.connectionDone=event.target.value;

}

handleLeakageTestDoneChange(event){

     console.log('event target value::', event.target.value);

    this.leakageTestDone=event.target.value;

}


handleGiLengthChange(event){

    console.log('event target value::', event.target.value);

    this.gILength=event.target.value;
}

handlecopperlengthMLClengthChange(event){

    console.log('event target value::', event.target.value);

    this.copperlengthMLClength=event.target.value;
}


  async handleBPFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.photoBPUploadSlots =event.detail.steps;

        for (let i = 0; i < photoBPUploadSlots.length; i++) {
        let slot = photoBPUploadSlots[i];
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

    handleBack(){

     this.dispatchEvent(new CustomEvent('cancel'));

    }

      @track materialList = [
        {
            rowNumber: 1,
            itemCode: '',
            itemDescription: '',
            quantity: '',
            filteredMaterials: [],
            showDropdown: false
        }
    ];

    delayTimeout;

    // 🔍 When user types in search box
    handleKeyChange(event) {
        const rowNumber = parseInt(event.target.dataset.rownumber, 10);
        const searchString = event.target.value.trim().toLowerCase();

        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.materialList = this.materialList.map(row => {
                if (row.rowNumber === rowNumber) {

                     if (!searchString) {
                    return {
                        ...row,
                        itemDescription: '',
                        itemCode: '',          // 🟢 clears code when description empty
                        filteredMaterials: [],
                        showDropdown: false
                    };
                }
                    const matches = searchString
                        ? MATERIALS.filter(mat =>
                              mat.description
                                  .toLowerCase()
                                  .includes(searchString)
                          ).slice(0, 10)
                        : [];
                    return {
                        ...row,
                        itemDescription: event.target.value,
                        filteredMaterials: matches,
                        showDropdown: matches.length > 0
                    };
                }
                return { ...row, showDropdown: false }; // hide others
            });
        }, DELAY);
    }

    // 🖱️ Select from dropdown
    handleSelect(event) {
        const rowNumber = parseInt(event.currentTarget.dataset.rownumber, 10);
        const description = event.currentTarget.dataset.description;
        const code = event.currentTarget.dataset.code;

        this.materialList = this.materialList.map(row =>
            row.rowNumber === rowNumber
                ? {
                      ...row,
                      itemDescription: description,
                      itemCode: code,
                      showDropdown: false,
                      filteredMaterials: []
                  }
                : { ...row, showDropdown: false }
        );
    }

    // 🧮 Handle other input changes (like quantity)
    handleMaterialChange(event) {
        const rowNumber = parseInt(event.target.dataset.rownumber, 10);
        const field = event.target.name;
        const value = event.detail.value || event.target.value;

        this.materialList = this.materialList.map(row =>
            row.rowNumber === rowNumber ? { ...row, [field]: value } : row
        );
    }

    // ➕ Add new row
    addMaterialRow() {
       // const nextRowNum = this.materialList.length + 1;
               this.lastRowIndex++; 

        const newRow = {
            rowNumber: this.lastRowIndex,
            itemCode: '',
            itemDescription: '',
            quantity: '',
            filteredMaterials: [],
            showDropdown: false
        };
        this.materialList = [...this.materialList, newRow];
    }

    // ❌ Remove a row
    removeMaterialRow(event) {
        console.log('inside remove material row', event.target.dataset.rownumber);
        
        const rowNumber = parseInt(event.target.dataset.rownumber, 10);
        this.materialList = this.materialList.filter(
            row => row.rowNumber !== rowNumber
        );
        console.log('Materail list after remove materail ::', JSON.stringify(this.materialList));
    }
    hasValidMaterialData() {
    return this.materialList.some(row => 
        (row.itemCode && row.itemCode.trim() !== '') ||
        (row.itemDescription && row.itemDescription.trim() !== '') ||
        (row.quantity !== null && row.quantity !== undefined && row.quantity !== '')
    );
}

handleSave(){

    console.log('inside save method');

    this.load=true;

    const allFilesSelected = this.photoBPUploadSlots.length === 1 &&
            this.photoBPUploadSlots.every(slot => slot.fileName && slot.base64Data);

        if (!allFilesSelected) {
            this.load = false;
            //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
            // this.showtoast('Warning', 'Please Capture photo.', 'warning');
            // this.load=false;
             LightningAlert.open({
            message: 'Please Capture photo.',
            theme: 'warning',   // red error dialog
            label: 'Warning'    // header text
        }).then(() => {
                    this.load=false;
         });
            return;
        }

        console.log('inside before method call');

    updateAccountDetails({recordId :this.accountId,worOrderId : this.recordId,meterShifted : this.meterShifted,
                                 meterNumber : this.meterNumber, meterReading : this.meterReading, regulatorMake : this.regulatorMake, 
                                 connectionDone : this.connectionDone, leakageTestDone :this.leakageTestDone, gILength : this.gILength,
                                 copperlengthMLClength : this.copperlengthMLClength,listFiles: this.photoBPUploadSlots })


        .then(result => {

            console.log('Result ::', result);

            console.log('workorder id::', this.recordId);
            console.log('account id::', this.accountId);

              console.log('Saving Material Details:', JSON.stringify(this.materialList));

                 const materialsToSend = this.materialList.map(m => ({
        rowNumber: parseInt(m.rowNumber, 10),
        itemCode: m.itemCode || '',
        itemDescription: m.itemDescription || '',
        quantity: parseInt(m.quantity || 0, 10)
    }));

                materialConsumption({
                    recordId: this.accountId,
                    //materialList: this.materialList
                     materialList: materialsToSend


                });

            generateAndAttachPdf({worOrderId : this.recordId, accId : this.accountId});
                     
        //    this.showtoast('Success', 'Details Saved Successfully.', 'success');
        //    this.load=false;

        //    this.handleBack();
        LightningAlert.open({
            message: 'Please Capture photo.',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                    this.load=false;
                    this.handleBack();
         });

        })

        .catch(error => {

            console.log('Error ::', error);
            this.load=false;
        })
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