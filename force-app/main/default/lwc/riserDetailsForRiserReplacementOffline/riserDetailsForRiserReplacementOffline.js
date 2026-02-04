import { LightningElement,api,track,wire } from 'lwc';
//import getItemDescriptionOptions from '@salesforce/apex/RiserDetailsForRiserReplacementContr.getItemDescriptionOptions';
//import getItemCodeOptions from '@salesforce/apex/RiserDetailsForRiserReplacementContr.getItemCodeOptions';

//import updateWOLItemRiserReplacement from '@salesforce/apex/RiserDetailsForRiserReplacementContr.updateWOLItemRiserReplacement';
//import materialConsumption from '@salesforce/apex/RiserDetailsForRiserReplacementContr.materialConsumption';
// import floorNumberAndRiserHeightDetails from '@salesforce/apex/RiserDetailsForRiserPaintingContr.floorNumberAndRiserHeightDetails';
// import noOfLeakageAndLeakLocations from '@salesforce/apex/RiserDetailsForRiserPaintingContr.noOfLeakageAndLeakLocations';
// import getNumberOfRisersWO from '@salesforce/apex/RiserDetailsForRiserPaintingContr.getNumberOfRisersWO';
//import getWorkOrderLineItem from '@salesforce/apex/RiserDetailsForRiserReplacementContr.getWorkOrderLineItem';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningAlert from 'lightning/alert';
//lds
import MATERIAL_CONSUMPTION_OBJECT from '@salesforce/schema/Material_Consumption__c';
import ITEM_DESCRIPTION_FIELD from '@salesforce/schema/Material_Consumption__c.Item_Description_Riser_Activity__c';
import ITEM_CODE_FIELD from '@salesforce/schema/Material_Consumption__c.Item_Code_Riser_Activity__c';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo,getObjectInfos } from "lightning/uiObjectInfoApi";

import { createContentDocumentAndVersion} from "lightning/uiRecordApi";
import CONTENT_DOCUMENT from "@salesforce/schema/ContentDocument";
import CONTENT_VERSION from "@salesforce/schema/ContentVersion";
import CONTENT_DOCUMENT_LINK from "@salesforce/schema/ContentDocumentLink";


import ID_FIELD from '@salesforce/schema/WorkOrderLineItem.Id';
import GI_PIPE_FABRICATION_LENGTH from '@salesforce/schema/WorkOrderLineItem.GI_pipe_fabrication_length__c';
import GI_PIPE_ERECTION_LENGTH from '@salesforce/schema/WorkOrderLineItem.GI_pipe_erection_length__c';
import LENGTH_OF_RISER_TESTED from '@salesforce/schema/WorkOrderLineItem.Length_of_Riser_Tested__c';
import NUMBER_OF_LEAKAGE from '@salesforce/schema/WorkOrderLineItem.Number_of_Leakages__c';
import LENGTH_OF_RISER_COMMISSIONED from '@salesforce/schema/WorkOrderLineItem.Length_of_Riser_Commissioned__c';
import RISER_LENGTH from '@salesforce/schema/WorkOrderLineItem.Riser_Length__c';
import RISER_PAINTING from '@salesforce/schema/WorkOrderLineItem.Riser_Painting__c';
import RISER_PAINTED_LENGTH from '@salesforce/schema/WorkOrderLineItem.Riser_Painted_Length__c';
import NUMBER_OF_CLAMPS_REPLACED from '@salesforce/schema/WorkOrderLineItem.Clamps_Replaced__c';
import NUMBER_OF_CRIMP_GUARDS_REPLACED from '@salesforce/schema/WorkOrderLineItem.Crimp_Guards_Replaced__c';
import NUMBER_OF_LATERAL_REPLACEMENTS_DONE from '@salesforce/schema/WorkOrderLineItem.No_Of_Lateral_Replacement_Done__c';
import INSTRUMENT_TYPE_RANGE from '@salesforce/schema/WorkOrderLineItem.Instrument_Type_Range__c';
import CALIBRATION_CERTIFICATE_NO from '@salesforce/schema/WorkOrderLineItem.Calibration_Certificate_No__c';
import CALIBRATION_DATE from '@salesforce/schema/WorkOrderLineItem.Calibration_Date__c';
import CALIBRATION_DUE_DATE from '@salesforce/schema/WorkOrderLineItem.Calibration_Due_Date__c';
import INSTRUMENT_SERIAL_NUMBER from '@salesforce/schema/WorkOrderLineItem.Instrument_Serial_Number__c';
import DURATION from '@salesforce/schema/WorkOrderLineItem.Duration__c';
import TEST_PRESSURE from '@salesforce/schema/WorkOrderLineItem.Test_Pressure__c';
import NO_OF_ACTIVE_CUSTOMERS from '@salesforce/schema/WorkOrderLineItem.No_of_active_customers__c';
import RISER_TESTED_STATUS from '@salesforce/schema/WorkOrderLineItem.Riser_Tested_Status__c';
import REMARK from '@salesforce/schema/WorkOrderLineItem.Remark__c';

import { updateRecord,createRecord,deleteRecord,getRecord } from 'lightning/uiRecordApi';
import ID_WorkStepFIELD from '@salesforce/schema/WorkStep.Id';
import STATUS_FIELD from '@salesforce/schema/WorkStep.Status';
import { refreshApex } from '@salesforce/apex';


import LEAK_LOC_1 from '@salesforce/schema/WorkOrderLineItem.Leak_Locations_1__c';
import LEAK_LOC_2 from '@salesforce/schema/WorkOrderLineItem.Leak_Locations_2__c';
import LEAK_LOC_3 from '@salesforce/schema/WorkOrderLineItem.Leak_Locations_3__c';
import LEAK_LOC_4 from '@salesforce/schema/WorkOrderLineItem.Leak_Locations_4__c';
import LEAK_LOC_5 from '@salesforce/schema/WorkOrderLineItem.Leak_Locations_5__c';
import LEAK_LOC_6 from '@salesforce/schema/WorkOrderLineItem.Leak_Locations_6__c';
import LEAK_LOC_7 from '@salesforce/schema/WorkOrderLineItem.Leak_Locations_7__c';
import LEAK_LOC_8 from '@salesforce/schema/WorkOrderLineItem.Leak_Locations_8__c';
import LEAK_LOC_9 from '@salesforce/schema/WorkOrderLineItem.Leak_Locations_9__c';
import LEAK_LOC_10 from '@salesforce/schema/WorkOrderLineItem.Leak_Locations_10__c';

import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

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

export default class RiserDetailsForRiserReplacementOffline extends LightningElement {

     @track load=false;

    @api workOrderLineItemName='';
    @api workOrderLineItemId;

    @api recordId;

         @track existingMaterialRecords=[];

@track workStepId='';
    @track workStepStatus='';

     //search item description 

     @track searchKey = '';
    @track filteredMaterials = [];
    @track selectedItemCode = '';
    delayTimeout;

    get showDropdown() {
    return this.searchKey && this.filteredMaterials.length > 0;
}


@track showPopup = false;

    @track popupMaterial = {
    itemDescription: '',
    itemCode: '',
    quantity: '',
    filteredMaterials: [],
    showDropdown: false
};


cleanMaterialList() {
    this.materialList = this.materialList.filter(
        m => m.itemDescription && m.quantity
    );
}


    // OPEN POPUP
    openPopup() {
         this.popupMaterial = {
        itemDescription: '',
        itemCode: '',
        quantity: '',
        filteredMaterials: [],
        showDropdown: false
    };

    this.showPopup = true;
    }

    // CLOSE POPUP
    closePopup() {
        this.showPopup = false;
    }

    handlePopupItemChange(event) {
        this.popupItemDescription = event.target.value;
    }

    @track popupSearchKey = '';
@track popupFilteredMaterials = [];
@track popupSelectedItemCode = '';
handlePopupKeyChange(event) {
    const searchString = event.target.value.trim().toLowerCase();

    window.clearTimeout(this.delayTimeout);
    this.delayTimeout = setTimeout(() => {

        // If input is empty → clear everything
        if (!searchString) {
            this.popupMaterial = {
                ...this.popupMaterial,
                itemDescription: '',
                itemCode: '',              
                filteredMaterials: [],
                showDropdown: false
            };
            return;
        }

        const matches = MATERIALS
            .filter(mat =>
                mat.description.toLowerCase().includes(searchString)
            )
            .slice(0, 10);

        this.popupMaterial = {
            ...this.popupMaterial,
            itemDescription: event.target.value,
            filteredMaterials: matches,
            showDropdown: matches.length > 0
        };

    }, DELAY);
}


handlePopupSelect(event) {
    const code = event.currentTarget.dataset.code;
    const description = event.currentTarget.dataset.description;

    this.popupMaterial.itemDescription = description;
    this.popupMaterial.itemCode = code;
    this.popupMaterial.showDropdown = false;
    this.popupMaterial.filteredMaterials = [];
}


handlePopupQtyChange(event) {
    this.popupMaterial.quantity = event.target.value;
}



get showPopupDropdown() {
    return this.popupFilteredMaterials.length > 0;
}

handlePopupMaterialSelect(event) {
    const code = event.currentTarget.dataset.code;
    const material = MATERIALS.find(m => m.code === code);

    if (material) {
        this.popupItemDescription = material.description;
        this.popupSelectedItemCode = material.code;
        this.popupFilteredMaterials = [];
    }
}

get hasMaterials() {
    return this.materialList.some(
        m => m.itemDescription && m.quantity
    );
}


saveMaterial() {

    this.cleanMaterialList(); 

    const itemDescription = this.popupMaterial.itemDescription?.trim();
    const quantity = this.popupMaterial.quantity?.trim();
  console.log('itemDescription',itemDescription);
  console.log('quantity::',quantity);
    if (!itemDescription || !quantity) {
      
    LightningAlert.open({
                    message: 'Please fill required fields',
                    theme: 'warning',  
                    label: 'Warning'   
                });

    return;
    }

    const nextRowNumber =  this.materialList.length + 1;

    this.materialList = [
        ...this.materialList,
        {
            rowNumber: nextRowNumber,
            itemCode: this.popupMaterial.itemCode,
            itemDescription,
            quantity
        }
    ];

    this.popupMaterial = {
        itemDescription: '',
        itemCode: '',
        quantity: '',
        filteredMaterials: [],
        showDropdown: false
    };

    this.closePopup();
}


    //search item description 


 @track preInstallationPhotoUploadSlots=[];

        noOfPreInstallationPhotos = 1;

    @track giPipeFabricationPhotoUploadSlots=[];

        noOfGiPipeFabricationPhotos = 1;

        @track giPipeErectionPhotoUploadSlots=[];

        noOfGiPipeErectionPhotos = 1;

         @track lengthOfPipelineCommissionedPhotoUploadSlots=[];

        noOfPipelineCommissionedPhotos = 1;

          @track riserLengthPhotoUploadSlots=[];

        noOfRiserLengthPhotos = 1;

          @track itemDescriptionOptions = [];

              @track itemCodeOptions = [];

         @track  filesPreInstallation = undefined;

         @track  filesRiserFabrication = undefined;

         @track  filesRiserErection = undefined;
         @track  filesPipelineCommissioned = undefined;
        @track  filesPostReplacementPicture = undefined;

         @track currentStep = 1;

        get isStep1() {
            return this.currentStep === 1;
        }
        get isStep2() {
            return this.currentStep === 2;
        }
        get isStep3() {
            return this.currentStep === 3;
        }

        handleNext() {
            if (this.currentStep < 3) {
                this.currentStep++;
            }
        }

        handlePrevious() {
            if (this.currentStep > 1) {
                this.currentStep--;
            }
        }
 


          connectedCallback() {

         //  this.getWorkOrderLineItem(); 

           console.log('workorderlineitem id ::',this.workOrderLineItemId);

               this.refreshData();

            
        //  this.setPreInstallationPhotoUploadSlots();
        //  this.setGiPipeFabricationPhotoUploadSlots();
        //  this.setGiPipeErectionPhotoUploadSlots();
        //  this.setLengthOfPipelineCommissionedPhotoUploadSlots();
        //  this.setRiserLengthPhotoUploadSlots();

       // this.getItemDescriptionOptions();
        //this.getItemCodeOptions();


        }

       /*   getItemDescriptionOptions(){
        getItemDescriptionOptions({})
            .then(result => {
                this.itemDescriptionOptions = result.map(value => ({ label: value, value }));
                console.log('Fetched item description options:', this.itemDescriptionOptions);
            })
            .catch(error => {
                console.error('Error fetching item code options:', error);
            });
     }

             getItemCodeOptions(){
        getItemCodeOptions({})
            .then(result => {
                this.itemCodeOptions = result.map(value => ({ label: value, value }));
                console.log('Fetched item description options:', this.itemCodeOptions);
            })
            .catch(error => {
                console.error('Error fetching item code options:', error);
            });

             }  */


              @wire(getObjectInfo, { objectApiName: MATERIAL_CONSUMPTION_OBJECT })
            objectInfo;

             @wire(getObjectInfos, {
    objectApiNames: [ CONTENT_DOCUMENT, CONTENT_VERSION, CONTENT_DOCUMENT_LINK ],
  })
  objectMetadata;





              @wire(getPicklistValues, {  recordTypeId: '$objectInfo.data.defaultRecordTypeId', 
                                             fieldApiName: ITEM_DESCRIPTION_FIELD })
            wiredItemDescription({ data, error }) {
                if (data) {
                    this.itemDescriptionOptions = data.values.map(entry => ({
                        label: entry.label,
                        value: entry.value
                    }));
                    console.log('Item Description Options:', this.itemDescriptionOptions);
                } else if (error) {
                    console.error('Error fetching Item Description picklist values:', error);
                }
            }

             @wire(getPicklistValues, {  recordTypeId: '$objectInfo.data.defaultRecordTypeId', 
                                            fieldApiName: ITEM_CODE_FIELD })
            wiredItemCode({ data, error }) {
                if (data) {
                    this.itemCodeOptions = data.values.map(entry => ({
                        label: entry.label,
                        value: entry.value
                    }));
                    console.log('Item Code Options:', this.itemCodeOptions);
                } else if (error) {
                    console.error('Error fetching Item Code picklist values:', error);
                }
            }

              get fileNamePreInstallation() {
    const file = this.filesPreInstallation && this.filesPreInstallation[0];
    if (file) {
      return file.name;
    }
    return undefined;
  }


    get fileNameRiserFabrication() {
    const file = this.filesRiserFabrication && this.filesRiserFabrication[0];
    if (file) {
      return file.name;
    }
    return undefined;
  }


    get fileNameRiserErection() {
    const file = this.filesRiserErection && this.filesRiserErection[0];
    if (file) {
      return file.name;
    }
    return undefined;
  }

   get fileNamePipelineCommissioned() {
    const file = this.filesPipelineCommissioned && this.filesPipelineCommissioned[0];
    if (file) {
      return file.name;
    }
    return undefined;
  }

  get fileNamePostReplacementPicture() {
    const file = this.filesPostReplacementPicture && this.filesPostReplacementPicture[0];
    if (file) {
      return file.name;
    }
    return undefined;
  }


             handleFilePreInstallation(event) {
   
             this.filesPreInstallation = event.detail.files;

         }

           handleFileRiserFabrication(event) {
   
             this.filesRiserFabrication = event.detail.files;

         }

         handleFileRiserErection(event) {
   
             this.filesRiserErection = event.detail.files;

         }

         handleFilePipelineCommissioned(event) {
   
             this.filesPipelineCommissioned = event.detail.files;

         }

         handlefilePostReplacementPicture(event) {
   
             this.filesPostReplacementPicture = event.detail.files;

         }



          async handleUploadClickPreInstallation() {

        console.log('inside handle file upload riser tested status');

    if (!this.filesPreInstallation || this.filesPreInstallation.length === 0) {
        return;
    }

    try {
        this.load = true;

        console.log('insdie try block insdie riser tested status');

        for (let i = 0; i < this.filesPreInstallation.length; i++) {
            const file = this.filesPreInstallation[i];

            // Use per-file title and description or fallback
            const title =  file.name;
            console.log('title ::', title);
            const description = 'Pre Installation Photo';
            console.log('description ::', description);

            const contentDocumentAndVersion =
                await createContentDocumentAndVersion({
                    title: title,
                    description: description,
                    fileData: file,
                });

            if (this.workOrderLineItemId) {
                console.log('inside if condition workOrderLineItemId found::', this.workOrderLineItemId);
                const contentDocumentId =
                    contentDocumentAndVersion.contentDocument.id;
                await this.createContentDocumentLink(
                    this.workOrderLineItemId,
                    contentDocumentId
                );
            }
        }
    
    } catch (error) {
        console.error(error);
    } finally {
        this.load = false;
    }
}


 async handleUploadClickRiserFabrication() {

        console.log('inside handle file upload riser tested status');

    if (!this.filesRiserFabrication || this.filesRiserFabrication.length === 0) {
        return;
    }

    try {
        this.load = true;

        console.log('insdie try block insdie riser tested status');

        for (let i = 0; i < this.filesRiserFabrication.length; i++) {
            const file = this.filesRiserFabrication[i];

            // Use per-file title and description or fallback
            const title =  file.name;
            console.log('title ::', title);
            const description = 'Riser Fabrication Photo';
            console.log('description ::', description);

            const contentDocumentAndVersion =
                await createContentDocumentAndVersion({
                    title: title,
                    description: description,
                    fileData: file,
                });

            if (this.workOrderLineItemId) {
                console.log('inside if condition workOrderLineItemId found::', this.workOrderLineItemId);
                const contentDocumentId =
                    contentDocumentAndVersion.contentDocument.id;
                await this.createContentDocumentLink(
                    this.workOrderLineItemId,
                    contentDocumentId
                );
            }
        }
    
    } catch (error) {
        console.error(error);
    } finally {
        this.load = false;
    }
}

 async handleUploadClickRiserErection() {

        console.log('inside handle file upload riser tested status');

    if (!this.filesRiserErection || this.filesRiserErection.length === 0) {
        return;
    }

    try {
        this.load = true;

        console.log('insdie try block insdie riser tested status');

        for (let i = 0; i < this.filesRiserErection.length; i++) {
            const file = this.filesRiserErection[i];

            // Use per-file title and description or fallback
            const title =  file.name;
            console.log('title ::', title);
            const description = 'Riser Erection Photo';
            console.log('description ::', description);

            const contentDocumentAndVersion =
                await createContentDocumentAndVersion({
                    title: title,
                    description: description,
                    fileData: file,
                });

            if (this.workOrderLineItemId) {
                console.log('inside if condition workOrderLineItemId found::', this.workOrderLineItemId);
                const contentDocumentId =
                    contentDocumentAndVersion.contentDocument.id;
                await this.createContentDocumentLink(
                    this.workOrderLineItemId,
                    contentDocumentId
                );
            }
        }
    
    } catch (error) {
        console.error(error);
    } finally {
        this.load = false;
    }
}

async handleUploadClickPipelineCommissioned() {

        console.log('inside handle file upload riser tested status');

    if (!this.filesPipelineCommissioned || this.filesPipelineCommissioned.length === 0) {
        return;
    }

    try {
        this.load = true;

        console.log('insdie try block insdie riser tested status');

        for (let i = 0; i < this.filesPipelineCommissioned.length; i++) {
            const file = this.filesPipelineCommissioned[i];

            // Use per-file title and description or fallback
            const title =  file.name;
            console.log('title ::', title);
            const description = 'Pipeline Commissioned Photo';
            console.log('description ::', description);

            const contentDocumentAndVersion =
                await createContentDocumentAndVersion({
                    title: title,
                    description: description,
                    fileData: file,
                });

            if (this.workOrderLineItemId) {
                console.log('inside if condition workOrderLineItemId found::', this.workOrderLineItemId);
                const contentDocumentId =
                    contentDocumentAndVersion.contentDocument.id;
                await this.createContentDocumentLink(
                    this.workOrderLineItemId,
                    contentDocumentId
                );
            }
        }
    
    } catch (error) {
        console.error(error);
    } finally {
        this.load = false;
    }
}


async handleUploadClickPostReplacementPicture() {

        console.log('inside handle file upload riser tested status');

    if (!this.filesPostReplacementPicture || this.filesPostReplacementPicture.length === 0) {
        return;
    }

    try {
        this.load = true;

        console.log('insdie try block insdie riser tested status');

        for (let i = 0; i < this.filesPostReplacementPicture.length; i++) {
            const file = this.filesPostReplacementPicture[i];

            // Use per-file title and description or fallback
            const title =  file.name;
            console.log('title ::', title);
            const description = 'Post Replacement Picture Photo';
            console.log('description ::', description);

            const contentDocumentAndVersion =
                await createContentDocumentAndVersion({
                    title: title,
                    description: description,
                    fileData: file,
                });

            if (this.workOrderLineItemId) {
                console.log('inside if condition workOrderLineItemId found::', this.workOrderLineItemId);
                const contentDocumentId =
                    contentDocumentAndVersion.contentDocument.id;
                await this.createContentDocumentLink(
                    this.workOrderLineItemId,
                    contentDocumentId
                );
            }
        }
    
    } catch (error) {
        console.error(error);
    } finally {
        this.load = false;
    }
}

async createContentDocumentLink(workOrderLineItemId, contentDocumentId) {
    await createRecord({
      apiName: "ContentDocumentLink",
      fields: {
        LinkedEntityId: workOrderLineItemId,
        ContentDocumentId: contentDocumentId,
        ShareType: "V",
      },
    });
    console.log("ContentDocumentLink record created.");
  }





    /* getWorkOrderLineItem(){

        getWorkOrderLineItem({recordId : this.workOrderLineItemId})

        .then( result => {

            console.log('Result get workorderlineitem ::', JSON.stringify(result));

             const woLineItem = result.workOrderLineItem;

            if(woLineItem.GI_pipe_fabrication_length__c){

                this.gIpipefabrication=true;
                this.showGiPipeFabricationLength=true;
                this.riserReplacement.giPipeFabricationlength=woLineItem.GI_pipe_fabrication_length__c;
            }

             if(woLineItem.GI_pipe_erection_length__c){

                this.gIPipeErection=true;
                this.showGiPipeErection=true;
                this.riserReplacement.gipipeerectionlength=woLineItem.GI_pipe_erection_length__c;
            }

             if(woLineItem.Length_of_Riser_Tested__c){

                this.riserTesting=true;
                this.showNoOfLeakages=true;
                this.riserReplacement.lengthofRiserTested=woLineItem.Length_of_Riser_Tested__c;
            }

            if(woLineItem.Number_of_Leakages__c){

               this.riserReplacement.numberofleakage=woLineItem.Number_of_Leakages__c;
            }

            if(woLineItem.Number_of_Leakages__c){

        this.riserReplacement.leakLocationList = Array.from(
        { length: woLineItem.Number_of_Leakages__c },
        (_, i) => {
            const fieldName = `Leak_Locations_${i + 1}__c`;
            return {
                id: `${Date.now()}-${i}`,
                label: `Leakage location ${i + 1}`,
                value: woLineItem[fieldName] || '' // take from Apex or keep blank
            };
        }
    );
             }

            if(woLineItem.Length_of_Riser_Commissioned__c){

                this.riserTestingandCommissioning=true;
                this.showRiserTestingAndCommissioning=true;
                this.riserReplacement.lengthofRiserCommissioned=woLineItem.Length_of_Riser_Commissioned__c;
            }

            
             if(woLineItem.Riser_Length__c){

                this.oldRiserRemoved=true;
                this.showRiserLength=true;
                this.riserReplacement.riserLength=woLineItem.Riser_Length__c;
            }

            if(woLineItem.Riser_Painting__c){

                 this.riserPainting=true;
                this.showRiserPaintingRequired=true;
                this.riserReplacement.riserPainting=woLineItem.Riser_Painting__c;
               this.riserReplacement.riserPaintedLength=woLineItem.Riser_Painted_Length__c;

            }

             if(woLineItem.Clamps_Replaced__c){

                 this.clampReplacement=true;
                this.showClampReplacedQuantity=true;
                this.riserReplacement.numberofClampstobeReplaced=woLineItem.Clamps_Replaced__c;

            }

             if(woLineItem.Crimp_Guards_Replaced__c){

                 this.crimpGuardReplacement=true;
                this.showCrimpsReplacedQuantity=true;
                this.riserReplacement.numberofCrimpGuardstobeReplaced=woLineItem.Crimp_Guards_Replaced__c;

            }

             if(woLineItem.No_Of_Lateral_Replacement_Done__c){

                 this.lateralReplacement=true;
                this.showLateralReplacementDone=true;
                this.riserReplacement.numberOfLateralReplacementsDone=woLineItem.No_Of_Lateral_Replacement_Done__c;

            }

             this.riserReplacement.instrumentTypeRange = woLineItem.Instrument_Type_Range__c;
             this.riserReplacement.calibrationCertificateNo = woLineItem.Calibration_Certificate_No__c;


              this.riserReplacement.calibrationDate = woLineItem.Calibration_Date__c;
             this.riserReplacement.calibrationDueDate = woLineItem.Calibration_Due_Date__c;
              this.riserReplacement.instrumentSerialNumber = woLineItem.Instrument_Serial_Number__c;

            this.riserReplacement.duration = woLineItem.Duration__c;
             this.riserReplacement.testPressure = woLineItem.Test_Pressure__c;
              this.riserReplacement.noofactivecustomers = woLineItem.No_of_active_customers__c;
             this.riserReplacement.riserTestedStatus = woLineItem.Riser_Tested_Status__c;
              this.riserReplacement.remark = woLineItem.Remark__c;
            
        })
        .catch(Error => {

            console.log('Error ::', Error);
        })
    } */

     riserTestedStatusOptions = [
         { label: 'Check and Found OK', value: 'Check and Found OK' },
        { label: 'Not OK', value: 'Not OK' },
        { label: 'Rectified and Found OK', value: 'Rectified and Found OK' }
        // { label: 'OK', value: 'OK' },
        // { label: 'Not OK', value: 'Not OK' },
        // { label: 'Maintained and OK', value: 'Maintained and OK' }
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


 riserPaintingOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];



         

          @track showGiPipeFabricationLength=false;

        @track showGiPipeErection=false;

        @track showNoOfLeakages = false;

        @track showRiserTestingAndCommissioning = false;

        @track showRiserLength=false;

        @track showCrimpsReplacedQuantity = false;

        @track showClampReplacedQuantity=false;

        @track showLateralReplacementDone =false;

         @track gIpipefabrication=false;
         @track gIPipeErection=false;

         @track riserTesting=false;
         @track riserTestingandCommissioning=false;
         @track oldRiserRemoved=false;
         @track clampReplacement=false;
         @track lateralReplacement=false;

         @track crimpGuardReplacement=false;

         @track riserPainting=false;

         @track showRiserPaintingRequired = false;



      






 handleCheckBoxChange(event){

            console.log('check box change label::', event.target.label);

            const label = event.target.label;

            const value =  event.target.checked;


         if(label=='Riser Painting' && value==true){

                this.riserPainting=value;

            this.showRiserPaintingRequired=true;
            }
             if(label=='Riser Painting' && value==false){


                this.riserPainting=value;

            this.showRiserPaintingRequired=false;
            

           // this.giPipeFabricationPhotoUploadSlots = [];
            }


            if(label=='Riser Fabrication' && value==true){

                this.gIpipefabrication=value;

            this.showGiPipeFabricationLength=true;
            }
             if(label=='Riser Fabrication' && value==false){


                this.gIpipefabrication=value;

            this.showGiPipeFabricationLength=false;

            this.giPipeFabricationPhotoUploadSlots =[];

            this.setGiPipeFabricationPhotoUploadSlots();

           // this.giPipeFabricationPhotoUploadSlots = [];
            }


             if(label=='Riser Erection' && value==true){

                    this.gIPipeErection=value;
            this.showGiPipeErection=true;
            }
             if(label=='Riser Erection' && value==false){

                this.gIPipeErection=value;

            this.showGiPipeErection=false;
            this.giPipeErectionPhotoUploadSlots=[];
            this.setGiPipeErectionPhotoUploadSlots();
            }


             if(label=='Riser Testing' && value==true){

                this.riserTesting=value;
            this.showNoOfLeakages=true;
            }
             if(label=='Riser Testing' && value==false){

                this.riserTesting=value;

            this.showNoOfLeakages=false;
            this.showLeakLocationsFields=false;

          

            }

             if(label=='Riser Testing and Commissioning' && value==true){

                this.riserTestingandCommissioning=value;
            this.showRiserTestingAndCommissioning=true;
            }
             if(label=='Riser Testing and Commissioning' && value==false){

                this.riserTestingandCommissioning=value;

            this.showRiserTestingAndCommissioning=false;
            this.lengthOfPipelineCommissionedPhotoUploadSlots=[];
            this.setLengthOfPipelineCommissionedPhotoUploadSlots();
            }

            if(label=='Old Riser Removed' && value==true){

                this.oldRiserRemoved=value;
            this.showRiserLength=true;
            }
             if(label=='Old Riser Removed' && value==false){

              this.oldRiserRemoved=value;

            this.showRiserLength=false;
            this.riserLengthPhotoUploadSlots=[];
            this.setRiserLengthPhotoUploadSlots();
            }

              if(label=='Clamp Installement' && value==true){

                this.clampReplacement=value;
            this.showClampReplacedQuantity=true;
            }
             if(label=='Clamp Installement' && value==false){

              this.clampReplacement=value;

            this.showClampReplacedQuantity=false;
            }

            if(label=='Crimp Guard Replacement' && value==true){

                this.crimpGuardReplacement=value;
            this.showCrimpsReplacedQuantity=true;
            }
             if(label=='Crimp Guard Replacement' && value==false){

              this.clampReplacement=value;

            this.showCrimpsReplacedQuantity=false;
            }

               if(label=='Lateral Replacement' && value==true){

                this.lateralReplacement=value;
            this.showLateralReplacementDone=true;
            }
             if(label=='Lateral Replacement' && value==false){
                this.lateralReplacement=value;

            this.showLateralReplacementDone=false;
            }

        }



          @track riserReplacement = {

        giPipeFabricationlength : null,
        gipipeerectionlength : null,
        lengthofRiserTested : '',
        numberofleakage : '',
        leakLocationList :[],
        lengthofRiserCommissioned : '',
        riserLength : '',
        riserPainting : '',
        riserPaintedLength : '',
        numberofClampstobeReplaced : '',
        numberofCrimpGuardstobeReplaced : '',
        numberOfLateralReplacementsDone : '',
         instrumentTypeRange : '',
        calibrationCertificateNo : '',
        calibrationDate : null,
        calibrationDueDate : null,
        instrumentSerialNumber : '',
         duration : '',
         testPressure : '',
         noofactivecustomers : null,
         riserTestedStatus : '',
          remark : ''

    };

     handleBack(){

                this.dispatchEvent(new CustomEvent('cancel'));



             }


    handleRiserReplacementDetailChange(event){


        // const field = event.target.name;
          const value = event.detail.value || event.target.value;
      //  const fieldLabel = event.target.label;

 const field = event.target.label;

  const fieldName = event.target.name;

    console.log('fieldName::', fieldName);
    console.log('field::', field);


        if(field =='Riser Painting' && value=='Yes'){

          //  this.riserPaintingYesShowSaveButton=true;
         //   this.showRisePaintingNoFields=false;
          //  this.showRiserSaveBackNextButton=false;
        }

          if(field =='Riser Painting' && value=='No'){

          //  this.riserPaintingYesShowSaveButton=false;
          //  this.showRisePaintingNoFields=true;
          //  this.showRiserSaveBackNextButton=true;

        }


        if (fieldName  === 'numberofleakage' && value !='') {

            this.showLeakLocationsFields=true;

        }


         if (fieldName === 'numberofleakage') {

         this.riserReplacement.numberofleakage = value; // store number as string

        this.riserReplacement.leakLocationList = Array.from(
                { length: value },
                (_, i) => ({
                    id: `${Date.now()}-${i}`, // unique & stable
                    label: `Leakage location ${i + 1}`,
                    value: ''
                })
            );
        }

     if (field && field.startsWith('Leakage location')) {
        const index = parseInt(field.replace('Leakage location ', ''), 10) - 1;
        if (this.riserReplacement.leakLocationList[index]) {
            this.riserReplacement.leakLocationList[index].value = value;
            this.riserReplacement.leakLocationList = [...this.riserReplacement.leakLocationList];
        }
    }




         if (field) {
            this.riserReplacement[fieldName] = value;
        }


        console.log('riserPainting list details::', JSON.stringify(this.riserReplacement));


    }

        wiredMaterialResult;


     @wire(getRelatedListRecords, {
        parentRecordId: '$workOrderLineItemId',
        relatedListId: 'Material_Consumptions__r',
        fields: [
            'Material_Consumption__c.Id',
            'Material_Consumption__c.Item_Code_Riser_Activity__c',
            'Material_Consumption__c.Item_Description_Riser_Activity__c',
            'Material_Consumption__c.Quantity__c',
            'Material_Consumption__c.Material_Row_Number__c'
        ],
        sortBy: ['Material_Row_Number__c']
    })
    wiredMaterialConsumption(result) {
        this.wiredMaterialResult = result; // store for refresh
        const { data, error } = result;
        if (data) {
            this.materialList = data.records.map(rec => ({
                id: rec.fields.Id.value,
                rowNumber: rec.fields.Material_Row_Number__c?.value || '',
                itemCode: rec.fields.Item_Code_Riser_Activity__c?.value || '',
                itemDescription: rec.fields.Item_Description_Riser_Activity__c?.value || '',
                quantity: rec.fields.Quantity__c?.value || ''
            }));
             this.existingMaterialRecords = JSON.parse(JSON.stringify(this.materialList));        
            console.log('existing material records data::', JSON.stringify(this.existingMaterialRecords));

             if (this.materialList.length > 0) {
            const maxRowNumber = Math.max(...this.materialList.map(r => Number(r.rowNumber)));
            this.lastRowIndex = maxRowNumber;
        } else {
            this.lastRowIndex = 0; // start from 0 if no records
        }

        console.log('lastRowIndex set to:', this.lastRowIndex);
        } else if (error) {
            console.error('⚠️ Error fetching material:', error);
        }
    }




        @track lastRowIndex='';
       // rowsToDelete = [];

    // old materiallist code

    /*  @track materialList = [{

        id:'',
        rowNumber: 0 ,
        itemCode: '',
        itemDescription: '',
        quantity: ''
    }];

     addMaterialRow() {

        console.log('Adding new material row');

        this.lastRowIndex++; 


    // const nextRowNum = this.materialList.length + 1; // simple increment

        this.materialList.push({

             rowNumber: this.lastRowIndex,
             itemCode: '',
            itemDescription: '',
            quantity: ''
        });
    }

     removeMaterialRow(event) {

         const rowNumber = parseInt(event.currentTarget.dataset.rownumber, 10);

    const row = this.materialList.find(r => Number(r.rowNumber) === rowNumber);

    if (row) {
        if (row.id) {
            this.rowsToDelete.push(row.id);
        }

        this.materialList = this.materialList.filter(r => Number(r.rowNumber) !== rowNumber);
    }

    console.log('materialList after remove:', JSON.stringify(this.materialList));
    console.log('Rows marked for deletion:', JSON.stringify(this.rowsToDelete));

    //      const rowNumber = parseInt(event.target.dataset.rownumber, 10); 
        
    //     console.log('Row number for delete ::', rowNumber);

    // this.materialList = this.materialList.filter(row => row.rowNumber !== rowNumber);

        
    //     const rowNumber = parseInt(event.target.dataset.rownumber, 10); // convert to number

    // this.materialList = this.materialList.filter(row => row.rowNumber !== rowNumber);
        // const index = event.target.dataset.index;
        // console.log(`Removing material row at index: ${index}`);
        // if (this.materialList.length > 1) {
        //     this.materialList.splice(index, 1);
        // }
         // const rowNumber  = event.target.dataset.rownumber; 
       // console.log(`Removing material row at index: ${index}`);
        // if (this.materialList.length > 1) {
        //     this.materialList.splice(index, 1);
          //  console.log(`Removing row with rowNumber: ${rowNumber}`);

        // }
         //   this.materialList = this.materialList.filter(row => row.rowNumber !== rowNumber);
    }

      handleMaterialChange(event) {

          const rowNumber = parseInt(event.target.dataset.rownumber, 10);
    const field = event.target.name;
    const value = event.detail.value || event.target.value;

    console.log(`Material Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    const rowIndex = this.materialList.findIndex(row => row.rowNumber === rowNumber);
    if (rowIndex !== -1) {
        this.materialList[rowIndex][field] = value;
    }

    // const rowNumber = parseInt(event.target.dataset.rownumber, 10);
    // const field = event.target.name;
    // const value = event.detail.value || event.target.value;

    // console.log(`Material Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    // // Find row by rowNumber
    // const rowIndex = this.materialList.findIndex(row => row.rowNumber === rowNumber);
    // if (rowIndex !== -1) {
    //     this.materialList[rowIndex][field] = value;
    // }


        // const index = event.target.dataset.index;
        // const field = event.target.name;
        // const value = event.detail.value || event.target.value;

        // console.log(`Material Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        // this.materialList[index][field] = value;
    //       const rowNumber = parseInt(event.target.dataset.rownumber, 10);
    // const field = event.target.name;
    // const value = event.detail.value || event.target.value;

    // console.log(`Material Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    // // Find row by rowNumber
    // const rowIndex = this.materialList.findIndex(row => row.rowNumber === rowNumber);
    // if (rowIndex !== -1) {
    //     this.materialList[rowIndex][field] = value;
    // }
    }


      hasValidMaterialData() {
        return this.materialList.some(row => 
            (row.itemCode && row.itemCode.trim() !== '') ||
            (row.itemDescription && row.itemDescription.trim() !== '') ||
            (row.quantity && row.quantity.trim() !== '')
        );
    }
*/

  @track materialList = [
        {
            id:'',
            rowNumber: 0,
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

     handleMaterialChange(event) {
       

           const rowNumber = parseInt(event.target.dataset.rownumber, 10);
    const field = event.target.name;
    const value = event.detail.value || event.target.value;

    console.log(`Material Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    const rowIndex = this.materialList.findIndex(row => row.rowNumber === rowNumber);
    if (rowIndex !== -1) {
        this.materialList[rowIndex][field] = value;
    }
    }

   
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

        rowsToDelete = [];


     removeMaterialRow(event) {

    const rowNumber = parseInt(event.currentTarget.dataset.rownumber, 10);

    const row = this.materialList.find(r => Number(r.rowNumber) === rowNumber);

    if (row) {
        if (row.id) {
            this.rowsToDelete.push(row.id);
        }

        this.materialList = this.materialList.filter(r => Number(r.rowNumber) !== rowNumber);
    }

    console.log('materialList after remove:', JSON.stringify(this.materialList));
    console.log('Rows marked for deletion:', JSON.stringify(this.rowsToDelete));

    }


   

    hasValidMaterialData() {
    return this.materialList.some(row => 
        (row.itemCode && row.itemCode.trim() !== '') ||
        (row.itemDescription && row.itemDescription.trim() !== '') ||
        (row.quantity !== null && row.quantity !== undefined && row.quantity !== '')
    );
}




 setPreInstallationPhotoUploadSlots() {

            this.preInstallationPhotoUploadSlots = Array.from({ length: this.noOfPreInstallationPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Pre Installation' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));


    }

      setGiPipeFabricationPhotoUploadSlots() {

            this.giPipeFabricationPhotoUploadSlots = Array.from({ length: this.noOfGiPipeFabricationPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Riser Fabrication' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));

    }

     setGiPipeErectionPhotoUploadSlots() {

            this.giPipeErectionPhotoUploadSlots = Array.from({ length: this.noOfGiPipeErectionPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Riser Erection' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));

     }

     setLengthOfPipelineCommissionedPhotoUploadSlots() {

            this.lengthOfPipelineCommissionedPhotoUploadSlots = Array.from({ length: this.noOfPipelineCommissionedPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Pipeline Commissioned' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));

     }

     setRiserLengthPhotoUploadSlots() {

            this.riserLengthPhotoUploadSlots = Array.from({ length: this.noOfRiserLengthPhotos }, (_, index) => ({
            id: index + 1,
            index: index + 1,
            label:  'Post Replacement Picture' ,      
            name: `fileUploader${index + 1}`,
            fileName: '',
            uploaded: false,
            previewUrl: '',
            base64Data: ''
        }));

     }





         async handlePreInstallationPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.preInstallationPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < preInstallationPhotoUploadSlots.length; i++) {
        let slot = preInstallationPhotoUploadSlots[i];
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


    async handleGiPipeFabricationPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.giPipeFabricationPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < giPipeFabricationPhotoUploadSlots.length; i++) {
        let slot = giPipeFabricationPhotoUploadSlots[i];
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


     async handleGiPipeErectionPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.giPipeErectionPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < giPipeErectionPhotoUploadSlots.length; i++) {
        let slot = giPipeErectionPhotoUploadSlots[i];
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

     async handlelengthOfPipelineCommissionedPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.lengthOfPipelineCommissionedPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < lengthOfPipelineCommissionedPhotoUploadSlots.length; i++) {
        let slot = lengthOfPipelineCommissionedPhotoUploadSlots[i];
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


      async handleRiserLengthPhotoFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.riserLengthPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < riserLengthPhotoUploadSlots.length; i++) {
        let slot = riserLengthPhotoUploadSlots[i];
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


    @wire(getRecord, {
        recordId: '$workOrderLineItemId',
        fields: [
            GI_PIPE_FABRICATION_LENGTH, GI_PIPE_ERECTION_LENGTH, LENGTH_OF_RISER_TESTED,
            NUMBER_OF_LEAKAGE, DURATION, TEST_PRESSURE, RISER_TESTED_STATUS, REMARK, NO_OF_ACTIVE_CUSTOMERS,
            LENGTH_OF_RISER_COMMISSIONED,RISER_LENGTH,RISER_PAINTING,RISER_PAINTED_LENGTH,NUMBER_OF_CLAMPS_REPLACED,
            NUMBER_OF_CRIMP_GUARDS_REPLACED,NUMBER_OF_LATERAL_REPLACEMENTS_DONE,INSTRUMENT_TYPE_RANGE,CALIBRATION_CERTIFICATE_NO,
            CALIBRATION_DATE,CALIBRATION_DUE_DATE,INSTRUMENT_SERIAL_NUMBER,
            LEAK_LOC_1, LEAK_LOC_2, LEAK_LOC_3, LEAK_LOC_4, LEAK_LOC_5, LEAK_LOC_6, LEAK_LOC_7, LEAK_LOC_8, LEAK_LOC_9, LEAK_LOC_10
        ]
    })
    wiredWorkOrderLineItem({ error, data }) {
        if (data) {
            const f = data.fields;

              const numberOfLeakages = f.Number_of_Leakages__c?.value || '';

            this.riserReplacement = {
                giPipeFabricationlength: f.GI_pipe_fabrication_length__c?.value || '',
                gipipeerectionlength: f.GI_pipe_erection_length__c?.value || '',
                lengthofRiserTested: f.Length_of_Riser_Tested__c?.value || '',
               // numberofleakage: f.Number_of_Leakages__c?.value || '',
                numberofleakage : numberOfLeakages,
                lengthofRiserCommissioned : f.Length_of_Riser_Commissioned__c?.value || '',
                riserLength : f.Riser_Length__c?.value || '',
                riserPainting : f.Riser_Painting__c?.value || '',
                riserPaintedLength : f.Riser_Painted_Length__c?.value || '',
                numberofClampstobeReplaced : f.Clamps_Replaced__c?.value || '',
                numberofCrimpGuardstobeReplaced : f.Crimp_Guards_Replaced__c?.value || '',

                numberOfLateralReplacementsDone : f.No_Of_Lateral_Replacement_Done__c?.value || '',

                instrumentTypeRange : f.Instrument_Type_Range__c?.value || '',
                calibrationCertificateNo : f.Calibration_Certificate_No__c?.value || '',
                calibrationDate : f.Calibration_Date__c?.value || '',
                calibrationDueDate : f.Calibration_Due_Date__c?.value || '',
                 instrumentSerialNumber : f.Instrument_Serial_Number__c?.value || '',

                duration: f.Duration__c?.value || '',
                testPressure: f.Test_Pressure__c?.value || '',
                riserTestedStatus: f.Riser_Tested_Status__c?.value || '',
                remark: f.Remark__c?.value || '',
                noofactivecustomers: f.No_of_active_customers__c?.value || null,
                leakLocationList: Array.from({ length: numberOfLeakages }, (_, i) => {
                const fieldName = `Leak_Locations_${i + 1}__c`;
                return {
                    id: `${Date.now()}-${i}`,
                    label: `Leakage location ${i + 1}`,
                    value: f[fieldName]?.value || ''
                };
            })
        };
                // leakLocationList: [
                //     { value: f.Leak_Locations_1__c?.value || '' },
                //     { value: f.Leak_Locations_2__c?.value || '' },
                //     { value: f.Leak_Locations_3__c?.value || '' },
                //     { value: f.Leak_Locations_4__c?.value || '' },
                //     { value: f.Leak_Locations_5__c?.value || '' },
                //     { value: f.Leak_Locations_6__c?.value || '' },
                //     { value: f.Leak_Locations_7__c?.value || '' },
                //     { value: f.Leak_Locations_8__c?.value || '' },
                //     { value: f.Leak_Locations_9__c?.value || '' },
                //     { value: f.Leak_Locations_10__c?.value || '' }
                // ]
           // };

            this.gIpipefabrication = !!f.GI_pipe_fabrication_length__c?.value;
        this.showGiPipeFabricationLength = !!f.GI_pipe_fabrication_length__c?.value;

        this.gIPipeErection = !!f.GI_pipe_erection_length__c?.value;
        this.showGiPipeErection = !!f.GI_pipe_erection_length__c?.value;

        this.riserTesting = !!f.Length_of_Riser_Tested__c?.value;
        this.showNoOfLeakages = !!f.Length_of_Riser_Tested__c?.value;

        this.riserTestingandCommissioning = !!f.Length_of_Riser_Commissioned__c?.value;
        this.showRiserTestingAndCommissioning = !!f.Length_of_Riser_Commissioned__c?.value;

        this.oldRiserRemoved = !!f.Riser_Length__c?.value;
        this.showRiserLength = !!f.Riser_Length__c?.value;

        this.riserPainting = !!f.Riser_Painting__c?.value;
        this.showRiserPaintingRequired = !!f.Riser_Painting__c?.value;

        this.clampReplacement = !!f.Clamps_Replaced__c?.value;
        this.showClampReplacedQuantity = !!f.Clamps_Replaced__c?.value;

        this.crimpGuardReplacement = !!f.Crimp_Guards_Replaced__c?.value;
        this.showCrimpsReplacedQuantity = !!f.Crimp_Guards_Replaced__c?.value;

         this.lateralReplacement = !!f.No_Of_Lateral_Replacement_Done__c?.value;
         this.showLateralReplacementDone = !!f.No_Of_Lateral_Replacement_Done__c?.value;

        this.leakageRectification = !!f.Number_of_Leakages__c?.value;

        } else if (error) {
            console.error('❌ Error loading WorkOrderLineItem:', error);
        }
    }


    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'WorkSteps', // Related List API name on WorkOrder
        fields: ['WorkStep.Id', 'WorkStep.Name', 'WorkStep.Status']
    })
    wiredWorkSteps({ data, error }) {
        if (data) {
            console.log('Related WorkSteps:', JSON.stringify(data));
            // Filter by Name
            const ws = data.records.find(r => r.fields.Name.value == 'Riser Execution Details');
            if (ws) {
                this.workStepStatus = ws.fields.Status.value;

                this.workStepId = ws.id;
                console.log('Selected WorkStep Id:', this.workStepId, 'Status:', this.workStepStatus);
            }
        } else if (error) {
            console.error('Error fetching related WorkSteps:', error);
        }
    }
   


      async updateWorkStepStatus() {
        try {
            // Prepare field map

            console.log('workstep id ::', this.workStepId);
            const fields = {};
            fields[ID_WorkStepFIELD.fieldApiName] = this.workStepId;
            fields[STATUS_FIELD.fieldApiName] = 'Completed'; 

            const recordInput = { fields };

            await updateRecord(recordInput);


          //  this.showToast('Success', 'WorkStep updated to Completed', 'success');
            console.log('✅ WorkStep updated successfully');
        } catch (error) {
            console.error('⚠️ Error updating WorkStep:', error);
          //  this.showToast('Error', error.body?.message || error.message, 'error');
        }
    }


async refreshData() {
        console.log('🔄 Refreshing related list data...');
        try {
            if (this.wiredMaterialResult) await refreshApex(this.wiredMaterialResult);
            console.log('✅ Data refreshed successfully!');

        } catch (error) {
            console.error('❌ Error refreshing data:', error);
        }
    }


     async handleSave() {

        try {

        this.load=true;

    console.log('Riser Replacement Data before saving:', JSON.stringify(this.riserReplacement));

    const formatDate = (value) => {
        if (!value) return null;
        const dateObj = new Date(value);
        if (isNaN(dateObj.getTime())) return null;
        return dateObj.toISOString().split('T')[0]; 
    };

     const riserReplacement = {
            giPipeFabricationlength: this.riserReplacement.giPipeFabricationlength,
            gipipeerectionlength: this.riserReplacement.gipipeerectionlength,
            lengthofRiserTested: this.riserReplacement.lengthofRiserTested,
            numberofleakage: this.riserReplacement.numberofleakage,
           // leakLocationList: this.riserReplacement.leakLocationList,
            lengthofRiserCommissioned: this.riserReplacement.lengthofRiserCommissioned,
            riserLength: this.riserReplacement.riserLength,
            riserPainting: this.riserReplacement.riserPainting,
            riserPaintedLength: this.riserReplacement.riserPaintedLength,
            numberofClampstobeReplaced: this.riserReplacement.numberofClampstobeReplaced,
            numberofCrimpGuardstobeReplaced: this.riserReplacement.numberofCrimpGuardstobeReplaced,
            numberOfLateralReplacementsDone: this.riserReplacement.numberOfLateralReplacementsDone,
            instrumentTypeRange: this.riserReplacement.instrumentTypeRange,
            calibrationCertificateNo: this.riserReplacement.calibrationCertificateNo,
            calibrationDate: formatDate(this.riserReplacement.calibrationDate),
            calibrationDueDate: formatDate(this.riserReplacement.calibrationDueDate),
            instrumentSerialNumber: this.riserReplacement.instrumentSerialNumber,
            duration: this.riserReplacement.duration,
            testPressure: this.riserReplacement.testPressure,
            noofactivecustomers: this.riserReplacement.noofactivecustomers,
            riserTestedStatus: this.riserReplacement.riserTestedStatus,
            remark: this.riserReplacement.remark
        };

        

        const leakLocationList = this.riserReplacement?.leakLocationList || [];

        console.log('Leak location list:', JSON.stringify(this.riserReplacement.leakLocationList));

    
       await this.updateWOLItemRiserPaintingLDS(this.workOrderLineItemId, riserReplacement, leakLocationList);

       await this.saveMaterialConsumption();
       await this.handleUploadClickPreInstallation();

        await this.handleUploadClickRiserFabrication();
       await this.handleUploadClickRiserErection();
       await this.handleUploadClickPipelineCommissioned();
       await this.handleUploadClickPostReplacementPicture();

        if(this.workStepStatus !='Completed'){

        console.log('inside workstep status not equal completed');
     await this.updateWorkStepStatus();

     }
          await this.refreshData();




    //    await this.handleUploadClickBeforePainting();
    //    await this.handleUploadClickAfterPainting();

    //     if(this.workStepStatus !='Completed'){

    //     console.log('inside workstep status not equal completed');
    //  await this.updateWorkStepStatus();

    //  }



        this.showtoast('Success','Details Saved Successfully.','success');


                 this.load=false;

                this.handleBack();

        }
        catch(error){
this.load=false;
console.error('❌ Error updating WorkOrderLineItem:', 
        JSON.stringify(error, Object.getOwnPropertyNames(error), 2)
    );

    if (error?.body?.output?.errors?.length) {
        console.error('🧾 Detailed LDS Errors:', 
            JSON.stringify(error.body.output.errors, null, 2)
        );
    }    }
}



async updateWOLItemRiserPaintingLDS(workOrderLineItemId, riserReplacement, leakLocationList = []) {
    try {
        const fields = {};

        console.log('inside update wolitem id::', workOrderLineItemId);

        fields[ID_FIELD.fieldApiName] = workOrderLineItemId;

        fields[GI_PIPE_FABRICATION_LENGTH.fieldApiName] = riserReplacement.giPipeFabricationlength;
        fields[GI_PIPE_ERECTION_LENGTH.fieldApiName] = riserReplacement.gipipeerectionlength;
        fields[LENGTH_OF_RISER_TESTED.fieldApiName] = riserReplacement.lengthofRiserTested;
        fields[NUMBER_OF_LEAKAGE.fieldApiName] = riserReplacement.numberofleakage;
        //fields[LEAK_LOCATION_LIST.fieldApiName] = riserReplacement.leakLocationList?.join(', ') || null;
        fields[LENGTH_OF_RISER_COMMISSIONED.fieldApiName] = riserReplacement.lengthofRiserCommissioned;
        fields[RISER_LENGTH.fieldApiName] = riserReplacement.riserLength;
        fields[RISER_PAINTING.fieldApiName] = riserReplacement.riserPainting;
        fields[RISER_PAINTED_LENGTH.fieldApiName] = riserReplacement.riserPaintedLength;
        fields[NUMBER_OF_CLAMPS_REPLACED.fieldApiName] = riserReplacement.numberofClampstobeReplaced;
        fields[NUMBER_OF_CRIMP_GUARDS_REPLACED.fieldApiName] = riserReplacement.numberofCrimpGuardstobeReplaced;
        fields[NUMBER_OF_LATERAL_REPLACEMENTS_DONE.fieldApiName] = riserReplacement.numberOfLateralReplacementsDone;
        fields[INSTRUMENT_TYPE_RANGE.fieldApiName] = riserReplacement.instrumentTypeRange;
        fields[CALIBRATION_CERTIFICATE_NO.fieldApiName] = riserReplacement.calibrationCertificateNo;
        fields[CALIBRATION_DATE.fieldApiName] = riserReplacement.calibrationDate;
        fields[CALIBRATION_DUE_DATE.fieldApiName] = riserReplacement.calibrationDueDate;
        fields[INSTRUMENT_SERIAL_NUMBER.fieldApiName] = riserReplacement.instrumentSerialNumber;
       
       

        fields[DURATION.fieldApiName] = riserReplacement.duration || null;
        fields[TEST_PRESSURE.fieldApiName] = riserReplacement.testPressure || null;
        fields[RISER_TESTED_STATUS.fieldApiName] = riserReplacement.riserTestedStatus || null;
        fields[REMARK.fieldApiName] = riserReplacement.remark || null;
        fields[NO_OF_ACTIVE_CUSTOMERS.fieldApiName] =
            riserReplacement.noofactivecustomers !== null && riserReplacement.noofactivecustomers !== ''
                ? Number(riserReplacement.noofactivecustomers)
                : null;


     const leakLocationFields = [
            LEAK_LOC_1, LEAK_LOC_2, LEAK_LOC_3, LEAK_LOC_4, LEAK_LOC_5,
            LEAK_LOC_6, LEAK_LOC_7, LEAK_LOC_8, LEAK_LOC_9, LEAK_LOC_10
        ];
       


       leakLocationList.forEach((item, index) => {
    const leakField = leakLocationFields[index];
    if (leakField) {
        fields[leakField.fieldApiName] = item.value || null; // allow empty overwrite
    }
        });


        const recordInput = { fields };
        console.log('Updating WorkOrderLineItem with fields:', JSON.stringify(recordInput));

        await updateRecord(recordInput);

        console.log('✅ WorkOrderLineItem updated successfully');
    } catch (error) {
        console.error('❌ Error updating WorkOrderLineItem:', error);
       // throw error;
    }
}


async saveMaterialConsumption() {
        console.log('Running material consumption comparison...');

            const recordsToInsert = this.materialList.filter(r => !r.id);
            console.log('Records to insert:', JSON.stringify(recordsToInsert));

            for (const mat of recordsToInsert) {
                const fields = {
                    Work_Order_Line_Item__c: this.workOrderLineItemId,
                    Item_Code_Riser_Activity__c: mat.itemCode,
                    Item_Description_Riser_Activity__c: mat.itemDescription,
                    Quantity__c: mat.quantity,
                    Material_Row_Number__c: String(mat.rowNumber)
                        };
                await createRecord({ apiName: MATERIAL_CONSUMPTION_OBJECT.objectApiName, fields });
            }

        console.log('rows to delete::', JSON.stringify(this.rowsToDelete));

            const validRowsToDelete = this.rowsToDelete.filter(id => id && id.length === 18);
        console.log('Records to delete:', JSON.stringify(validRowsToDelete));

        for (const id of validRowsToDelete) {
            try {
                await deleteRecord(id);
                console.log('Deleted record:', id);
            } catch (err) {
                console.error('Error deleting record:', err, 'Id:', id);
            }
        }

        // Clear rowsToDelete after save
        this.rowsToDelete = [];


        console.log('Material consumption create/delete complete.');
    }




 


   /*  handleSave(){

        console.log('inside save method');



        this.load=true;

            const jsonData = JSON.stringify(this.riserReplacement);

    

          var imagesList = [];

                this.preInstallationPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                 this.giPipeFabricationPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                 this.giPipeErectionPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                 this.lengthOfPipelineCommissionedPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                   this.riserLengthPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })
                


                 var temp = this.uploadFile(imagesList);

                 console.log('image list :::', JSON.stringify(imagesList));

        
        console.log('after image list');

        updateWOLItemRiserReplacement({recordId : this.workOrderLineItemId, riserReplacement : jsonData,listFiles: imagesList })
        .then( result => {

            console.log('result after update riser replacement details::', result);

             if (this.materialList.length > 0 && this.hasValidMaterialData()) {
                console.log('🔧 Saving Material Details:', JSON.stringify(this.materialList));

                materialConsumption({
                    recordId: this.workOrderLineItemId,
                    materialList: this.materialList

                });

                 }
                 this.showtoast('Success','Details Saved Successfully.','success');


                 this.load=false;

                this.handleBack();


        })

        .catch(error => {

            console.log('Error ::', error);
            this.load=false;
        })

    } */

    
//  uploadFile(imagesList) {

//              }




     showtoast(title, msg, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(event);
    }


}