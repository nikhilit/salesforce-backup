import { LightningElement,api,track,wire } from 'lwc';
//import getItemDescriptionOptions from '@salesforce/apex/RiserDetailsForRiserPaintingContr.getItemDescriptionOptions';
//import getItemCodeOptions from '@salesforce/apex/RiserDetailsForRiserPaintingContr.getItemCodeOptions';

//import updateWOLItemRiserPainting from '@salesforce/apex/RiserDetailsForRiserPaintingContr.updateWOLItemRiserPainting';
//import materialConsumption from '@salesforce/apex/RiserDetailsForRiserPaintingContr.materialConsumption';
//import floorNumberAndRiserHeightDetails from '@salesforce/apex/RiserDetailsForRiserPaintingContr.floorNumberAndRiserHeightDetails';
//import noOfLeakageAndLeakLocations from '@salesforce/apex/RiserDetailsForRiserPaintingContr.noOfLeakageAndLeakLocations';
//import getNumberOfRisersWO from '@salesforce/apex/RiserDetailsForRiserPaintingContr.getNumberOfRisersWO';
//import getWorkOrderLineItem from '@salesforce/apex/RiserDetailsForRiserPaintingContr.getWorkOrderLineItem';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningAlert from 'lightning/alert';

//lds
import { refreshApex } from '@salesforce/apex';

import MATERIAL_CONSUMPTION_OBJECT from '@salesforce/schema/Material_Consumption__c';
import ITEM_DESCRIPTION_FIELD from '@salesforce/schema/Material_Consumption__c.Item_Description_Riser_Activity__c';
import ITEM_CODE_FIELD from '@salesforce/schema/Material_Consumption__c.Item_Code_Riser_Activity__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo,getObjectInfos } from "lightning/uiObjectInfoApi";

import { createContentDocumentAndVersion} from "lightning/uiRecordApi";
import CONTENT_DOCUMENT from "@salesforce/schema/ContentDocument";
import CONTENT_VERSION from "@salesforce/schema/ContentVersion";
import CONTENT_DOCUMENT_LINK from "@salesforce/schema/ContentDocumentLink";

import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import ID_WorkStepFIELD from '@salesforce/schema/WorkStep.Id';
import STATUS_FIELD from '@salesforce/schema/WorkStep.Status';

import WORKSTEP_OBJECT from '@salesforce/schema/WorkStep';
import NAME_FIELD from '@salesforce/schema/WorkStep.Name';
import PARENT_RECORD_FIELD from '@salesforce/schema/WorkStep.ParentRecordId';



import { updateRecord,getRecord,deleteRecord, createRecord } from 'lightning/uiRecordApi';

import ID_FIELD from '@salesforce/schema/WorkOrderLineItem.Id';
import RISER_CATEGORY from '@salesforce/schema/WorkOrderLineItem.Riser_Category__c';
import CLAMPS_REPLACED from '@salesforce/schema/WorkOrderLineItem.Clamps_Replaced__c';
import CRIMP_GUARDS_REPLACED from '@salesforce/schema/WorkOrderLineItem.Crimp_Guards_Replaced__c';
import LENGTH_PAINTED_PRIMER from '@salesforce/schema/WorkOrderLineItem.Length_Painted_Primer__c';
import DFT_READING_PRIMER from '@salesforce/schema/WorkOrderLineItem.DFT_Reading_Primer__c';
import LENGTH_PAINTED_YELLOW from '@salesforce/schema/WorkOrderLineItem.Length_Painted_Yellow__c';
import DFT_READING_YELLOW from '@salesforce/schema/WorkOrderLineItem.DFT_Reading_Yellow__c';
import LENGTH_PAINTED_YELLOW3 from '@salesforce/schema/WorkOrderLineItem.Length_Painted_Yellow_3__c';
import DFT_READING_YELLOW3 from '@salesforce/schema/WorkOrderLineItem.DFT_Reading_Yellow_3__c';
import NO_OF_LEAKAGES from '@salesforce/schema/WorkOrderLineItem.No_of_leakages_RiserPainting__c';
import LEAKAGE_LOCATIONS from '@salesforce/schema/WorkOrderLineItem.Leakage_Locations_RiserPainting__c';
import FLOOR_NO from '@salesforce/schema/WorkOrderLineItem.Floor_No_RiserPainting__c';
import RISER_HEIGHT from '@salesforce/schema/WorkOrderLineItem.Riser_Height_RiserPainting__c';
import INSTRUMENT_TYPE from '@salesforce/schema/WorkOrderLineItem.Instrument_Type_Range__c';
import CALIBRATION_CERT from '@salesforce/schema/WorkOrderLineItem.Calibration_Certificate_No__c';
import CALIBRATION_DATE from '@salesforce/schema/WorkOrderLineItem.Calibration_Date__c';
import CALIBRATION_DUE_DATE from '@salesforce/schema/WorkOrderLineItem.Calibration_Due_Date__c';
import INSTRUMENT_SERIAL from '@salesforce/schema/WorkOrderLineItem.Instrument_Serial_Number__c';

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

export default class RiserDetailsForRiserPaintingOfflineComp extends LightningElement {


  @track load=false;

    // @api workOrderLineItemName;
    // @api workOrderLineItemId='';

    @api recordId;

     @api workOrderLineItemName='';
    @api workOrderLineItemId;

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



      @track photoUploadSlots=[];
        noOfPhotos=1;


        
    @track afterPaintingPhotoUploadSlots=[];
        afterPaintingNoOfPhotos=1; 

     //   @track risersNumber=''; 


    @track showHeightOfRiser=false;
    @track heightofriserfloorwise=false;
    @track clampReplacement=false;
    @track epoxyPaintPrimer=false;
    @track coat2PaintYellow=false;
    @track coat3PaintYellow=false;
    @track leakageRectification=false;
    @track crimpGuardReplacement=false;

    @track workStepId='';
    @track workStepStatus='';

      @track itemDescriptionOptions = [];

     @track itemCodeOptions = [];

     mainOrApproachRiserOptions = [
        { label: 'Main Riser', value: 'Main Riser' },
        { label: 'Approach Riser', value: 'Approach Riser' }
    ];

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

        
    @wire(getObjectInfo, { objectApiName: MATERIAL_CONSUMPTION_OBJECT })
            objectInfo;

             @wire(getObjectInfos, {
    objectApiNames: [ CONTENT_DOCUMENT, CONTENT_VERSION, CONTENT_DOCUMENT_LINK ],
  })
  objectMetadata;


    connectedCallback() {
        
        console.log('WOLItem Record Id inside offline::',this.workOrderLineItemId);

        this.refreshData();
       // this.getWorkOrderLineItem();
       //  this.getItemDescriptionOptions();
      //  this.getItemCodeOptions();
       // this.getNumberOfRisersWO(); 
        
        //  this.setPhotoUploadSlots();
        //  this.setAfterPaintingPhotoUploadSlots();


    }

   /*  getItemDescriptionOptions(){
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

             } */


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

            //  getNumberOfRisersWO(){
    
            //     getNumberOfRisersWO({recordId : this.workOrderLineItemId})

            //     .then(result => {

            //         console.log('Number of riser ::', result);
            //         this.risersNumber=result;
            //        // this.noOfPhotos=result;
            //        // this.afterPaintingNoOfPhotos=result;
            //           this.setPhotoUploadSlots();
            //           this.setAfterPaintingPhotoUploadSlots();
            //     })
            //     .catch(error => {

            //         console.log('Error ::', error);

            //     })

            //  }




          /*   getWorkOrderLineItem(){

        getWorkOrderLineItem({recordId : this.workOrderLineItemId})

        .then( result => {

            console.log('Result get workorderlineitem ::', JSON.stringify(result));


             const woLineItem = result.workOrderLineItem;


            this.riserPainting.riserCategory = woLineItem.Riser_Category__c;

            if(woLineItem.Riser_Category__c == 'Main Riser'){

                this.showHeightOfRiser=true;
            }

        
            if(woLineItem.Clamps_Replaced__c){

              this.clampReplacement=true;

            this.riserPainting.noOfClampsReplaced = woLineItem.Clamps_Replaced__c;

            }

         if(woLineItem.Length_Painted_Primer__c || woLineItem.DFT_Reading_Primer__c){

            this.epoxyPaintPrimer=true;
             this.riserPainting.lengthPaintedPrimer = woLineItem.Length_Painted_Primer__c;
            this.riserPainting.dFTReadingPrimer = woLineItem.DFT_Reading_Primer__c;

         }
            
         if(woLineItem.Length_Painted_Yellow__c || woLineItem.DFT_Reading_Yellow__c){

            this.coat2PaintYellow=true;

            this.riserPainting.lengthPaintedYellow = woLineItem.Length_Painted_Yellow__c;
            this.riserPainting.dFTReadingYellow = woLineItem.DFT_Reading_Yellow__c;

             }

           if(woLineItem.Length_Painted_Yellow_3__c || woLineItem.DFT_Reading_Yellow_3__c){

            this.coat3PaintYellow=true;
            this.riserPainting.lengthPaintedYellow3 = woLineItem.Length_Painted_Yellow_3__c;
            this.riserPainting.dFTReadingYellow3 = woLineItem.DFT_Reading_Yellow_3__c;

           }

             if(woLineItem.Crimp_Guards_Replaced__c){

                this.crimpGuardReplacement=true;
          this.riserPainting.noofCrimpGuardsReplaced = woLineItem.Crimp_Guards_Replaced__c;

             }


            this.riserPainting.instrumentTypeRange = woLineItem.Instrument_Type_Range__c;
             this.riserPainting.calibrationCertificateNo = woLineItem.Calibration_Certificate_No__c;


              this.riserPainting.calibrationDate = woLineItem.Calibration_Date__c;
             this.riserPainting.calibrationDueDate = woLineItem.Calibration_Due_Date__c;
             this.riserPainting.instrumentSerialNumber = woLineItem.Instrument_Serial_Number__c;



             this.materialList = (result.materialConsumptions || []).map((m, index) => {
                return {
                   rowNumber: m.Material_Row_Number__c ? parseInt(m.Material_Row_Number__c, 10) : (index + 1),

                    itemCode: m.Item_Code_Riser_Activity__c,
                    itemDescription: m.Item_Description_Riser_Activity__c,
                    quantity: m.Quantity__c
                };
            });

            console.log('Material List ::', JSON.stringify(this.materialList));

             if(woLineItem.No_of_leakages_RiserPainting__c	|| woLineItem.Leakage_Locations_RiserPainting__c){

                this.leakageRectification=true;
          this.riserPainting.noOfLeakages = woLineItem.No_of_leakages_RiserPainting__c;
            this.riserPainting.leakageLocations = woLineItem.Leakage_Locations_RiserPainting__c;


             }
              if(woLineItem.Riser_Height_RiserPainting__c	|| woLineItem.Floor_No_RiserPainting__c){

                this.heightofriserfloorwise=true;
          this.riserPainting.riserHeight = woLineItem.Riser_Height_RiserPainting__c;
            this.riserPainting.floorNumber = woLineItem.Floor_No_RiserPainting__c;


             }


          
        })
        .catch(Error => {

            console.log('Error ::', Error);
        })
    }
*/


    @track riserPainting = {

        riserCategory : '',
        noOfClampsReplaced : null,
        lengthPaintedPrimer : '',
        dFTReadingPrimer : '',
        lengthPaintedYellow : '',
        dFTReadingYellow : '',
        lengthPaintedYellow3 : '',
        dFTReadingYellow3 : '',
        noOfLeakages : '',
        leakageLocations : '',
        riserHeight : '',
        floorNumber : '',
        noofCrimpGuardsReplaced : null
        // instrumentTypeRange : '',
        // calibrationCertificateNo : '',
        // calibrationDate : null,
        // calibrationDueDate : null,
        // instrumentSerialNumber : ''


    };


     handleRiserPaintingDetail(event){

 const field = event.target.label;
    // const value = event.target.value;
    //const fieldLabel = event.target.label;
 const fieldName = event.target.name;

  let value;
            if (event.target.type === 'checkbox') {
                value = event.target.checked;
            } else {
                value = event.target.value;
            }

             if(field=='Riser Category' && value=='Main Riser'){

            this.showHeightOfRiser=true;
        }
         if(field=='Riser Category' && value!='Main Riser'){

            this.showHeightOfRiser=false;
        }

          if(field =='Height of riser floor wise' && value==true){
        console.log('inside Height of riser floor wise check');

            this.heightofriserfloorwise=true;
        }

         if(field =='Height of riser floor wise' && value==false){
        console.log('inside Height of riser floor wise unchecked');
        this.heightofriserfloorwise=false;
        this.riserPainting.floorNumber='';
        this.riserPainting.riserHeight='';

        }

        
         if(field =='Clamp Replacement' && value==true){
        this.clampReplacement=true;
        }

         if(field =='Clamp Replacement' && value==false){
        this.clampReplacement=false;
        }

          if(field =='Epoxy Paint Primer' && value==true){
        this.epoxyPaintPrimer=true;
        }

         if(field =='Epoxy Paint Primer' && value==false){
        this.epoxyPaintPrimer=false;
        }

          if(field =='Coat 2 Paint Yellow' && value==true){
        this.coat2PaintYellow=true;
        }

         if(field =='Coat 2 Paint Yellow' && value==false){
        this.coat2PaintYellow=false;
        }

           if(field =='Coat 3 Paint Yellow' && value==true){
        this.coat3PaintYellow=true;
        }

         if(field =='Coat 3 Paint Yellow' && value==false){
        this.coat3PaintYellow=false;
        }

          if(field =='Leakage Rectification' && value==true){
        this.leakageRectification=true;
        }

         if(field =='Leakage Rectification' && value==false){
        this.leakageRectification=false;
        }

            if(field =='Crimp Guard Replacement' && value==true){
        this.crimpGuardReplacement=true;
        }

         if(field =='Crimp Guard Replacement' && value==false){
        this.crimpGuardReplacement=false;
        }



        if (field) {
            this.riserPainting[fieldName] = value;
        }

        console.log('riserPainting list details::', JSON.stringify(this.riserPainting));

    }

            @track lastRowIndex='';
          //   rowsToDelete = [];

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



//old materiallist code

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

       // console.log('selected for delete row number::', parseInt(event.target.dataset.rownumber, 10);
        
    //     const rowNumber = parseInt(event.target.dataset.rownumber, 10); 
        
    //     console.log('Row number for delete ::', rowNumber);

    // this.materialList = this.materialList.filter(row => row.rowNumber !== rowNumber);

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

      handleMaterialChange(event) {
        // const index = event.target.dataset.index;
        // const field = event.target.name;
        // const value = event.detail.value || event.target.value;

        // console.log(`Material Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        // this.materialList[index][field] = value;

    //        const rowNumber = parseInt(event.target.dataset.rownumber, 10);
    // const field = event.target.name;
    // const value = event.detail.value || event.target.value;

    // console.log(`Material Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    // // Find row by rowNumber
    // const rowIndex = this.materialList.findIndex(row => row.rowNumber === rowNumber);
    // if (rowIndex !== -1) {
    //     this.materialList[rowIndex][field] = value;
    // }

     const rowNumber = parseInt(event.target.dataset.rownumber, 10);
    const field = event.target.name;
    const value = event.detail.value || event.target.value;

    console.log(`Material Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    const rowIndex = this.materialList.findIndex(row => row.rowNumber === rowNumber);
    if (rowIndex !== -1) {
        this.materialList[rowIndex][field] = value;
    }
    }


      hasValidMaterialData() {
        return this.materialList.some(row => 
            (row.itemCode && row.itemCode.trim() !== '') ||
            (row.itemDescription && row.itemDescription.trim() !== '') ||
            (row.quantity && row.quantity.trim() !== '')
        );
    } */



    /* Need to delete this

      @track materialList = [{
        rowNumber: 1 ,
        itemCode: '',
        itemDescription: '',
        quantity: ''
    }];

     addMaterialRow() {
        console.log('Adding new material row');
          const nextRowNum = this.materialList.length + 1; // simple increment

        this.materialList.push({

             rowNumber: nextRowNum,
             itemCode: '',
            itemDescription: '',
            quantity: ''
        });
    }

     removeMaterialRow(event) {

        const rowNumber = parseInt(event.target.dataset.rownumber, 10); // convert to number

    this.materialList = this.materialList.filter(row => row.rowNumber !== rowNumber);
        // const rowNumber  = event.target.dataset.rownumber; 
       // console.log(`Removing material row at index: ${index}`);
        // if (this.materialList.length > 1) {
        //     this.materialList.splice(index, 1);
          //  console.log(`Removing row with rowNumber: ${rowNumber}`);

        // }
          //  this.materialList = this.materialList.filter(row => row.rowNumber !== rowNumber);
              //  this.materialList = this.materialList.filter(row => row.rowNumber !== String(row.rowNumber));

    }

      handleMaterialChange(event) {
        // const index = event.target.dataset.index;
        // const field = event.target.name;
        // const value = event.detail.value || event.target.value;

        // console.log(`Material Change - Index: ${index}, Field: ${field}, Value: ${value}`);
        // this.materialList[index][field] = value;

            const rowNumber = parseInt(event.target.dataset.rownumber, 10);
    const field = event.target.name;
    const value = event.detail.value || event.target.value;

    console.log(`Material Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    // Find row by rowNumber
    const rowIndex = this.materialList.findIndex(row => row.rowNumber === rowNumber);
    if (rowIndex !== -1) {
        this.materialList[rowIndex][field] = value;
    }

    }


      hasValidMaterialData() {
        // return this.materialList.some(row => 
        //     (row.itemCode && row.itemCode.trim() !== '') ||
        //     (row.itemDescription && row.itemDescription.trim() !== '') ||
        //     (row.quantity && row.quantity.trim() !== '')
        // );
        return this.materialList.some(row => 
        (row.itemCode && row.itemCode.trim() !== '') ||
        (row.itemDescription && row.itemDescription.trim() !== '') ||
        (row.quantity !== null && row.quantity !== undefined && row.quantity !== '')
    );
    } */



 /*floor number and height or riser floor wise add multiple code
 @track floorNumberAndRiserHeight = [{

        rowNumber: 1 ,
        floorNumber: '',
        riserHeight: ''
        
    }];

     addfloorNumberAndRiserHeightRow() {

         const nextRowNum = this.floorNumberAndRiserHeight.length + 1; // simple increment
       
        this.floorNumberAndRiserHeight.push({
         
             rowNumber: nextRowNum,
             floorNumber: '',
             riserHeight: ''
        });
    }

     removefloorNumberAndRiserHeightRow(event) {

         const rowNumber = parseInt(event.target.dataset.rownumber, 10); // convert to number

         this.floorNumberAndRiserHeight = this.floorNumberAndRiserHeight.filter(row => row.rowNumber !== rowNumber);
     

        // const index = event.target.dataset.index;
        // if (this.floorNumberAndRiserHeight.length > 1) {
        //     this.floorNumberAndRiserHeight.splice(index, 1);
        // }

        // const rowNumber  = event.target.dataset.rowNumber; 
       // console.log(`Removing floor and riser height row at index: ${index}`);
        // if (this.materialList.length > 1) {
        //     this.materialList.splice(index, 1);
        // }
         //   this.floorNumberAndRiserHeight = this.floorNumberAndRiserHeight.filter(row => row.rowNumber !== rowNumber);
    }

      handlefloorNumberAndRiserHeightChange(event) {


         const rowNumber = parseInt(event.target.dataset.rownumber, 10);
         const field = event.target.name;
             const value = event.detail.value || event.target.value;

    //console('row number handle change flat::', rowNumber);

    console.log(`floor and riser height Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    // Find row by rowNumber
    const rowIndex = this.floorNumberAndRiserHeight.findIndex(row => row.rowNumber === rowNumber);
    if (rowIndex !== -1) {
        this.floorNumberAndRiserHeight[rowIndex][field] = value;
    }

        // const index = event.target.dataset.index;
        // const field = event.target.name;
        // const value = event.detail.value || event.target.value;

        // console.log(`Floor Number and riser height change - Index: ${index}, Field: ${field}, Value: ${value}`);
        // this.floorNumberAndRiserHeight[index][field] = value;

//    const rowNumber = parseInt(event.target.dataset.rownumber, 10);
//     const field = event.target.name;
//     const value = event.detail.value || event.target.value;

//     console.log(`floor and height Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

//     // Find row by rowNumber
//     const rowIndex = this.floorNumberAndRiserHeight.findIndex(row => row.rowNumber === rowNumber);
//     if (rowIndex !== -1) {
//         this.floorNumberAndRiserHeight[rowIndex][field] = value;
//     }
    }


      hasValidfloorNumberAndRiserHeightData() {
        return this.floorNumberAndRiserHeight.some(row => 
            (row.floorNumber && row.floorNumber.trim() !== '') ||
            (row.riserHeight && row.riserHeight.trim() !== '') 
        );
    } */

/* Number of add leakage  code 

    @track noOfLeakagesLeakageLocations = [{
               
        rowNumber: 1 ,
        noOfLeakages: '',
        leakageLocations: ''
        
    }];

     addnoOfLeakagesLeakageLocationsRow() {
         const nextRowNum = this.noOfLeakagesLeakageLocations.length + 1; // simple increment
        this.noOfLeakagesLeakageLocations.push({
                   
             rowNumber: nextRowNum,
             noOfLeakages: '',
             leakageLocations: ''
        });
    }

     removenoOfLeakagesLeakageLocationsRow(event) {

         const rowNumber = parseInt(event.target.dataset.rownumber, 10); // convert to number

         this.noOfLeakagesLeakageLocations = this.noOfLeakagesLeakageLocations.filter(row => row.rowNumber !== rowNumber);
     

        
        // const index = event.target.dataset.index;
        // if (this.noOfLeakagesLeakageLocations.length > 1) {
        //     this.noOfLeakagesLeakageLocations.splice(index, 1);
        // }

       //  const rowNumber  = event.target.dataset.rowNumber; 
       // console.log(`Removing leakage locations row at index: ${index}`);
        // if (this.materialList.length > 1) {
        //     this.materialList.splice(index, 1);
        // }
         //   this.noOfLeakagesLeakageLocations = this.noOfLeakagesLeakageLocations.filter(row => row.rowNumber !== rowNumber);

    }

      handlenoOfLeakagesLeakageLocationsChange(event) {

          const rowNumber = parseInt(event.target.dataset.rownumber, 10);
         const field = event.target.name;
             const value = event.detail.value || event.target.value;

    //console('row number handle change flat::', rowNumber);

    console.log(`No of leakage and location Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    // Find row by rowNumber
    const rowIndex = this.noOfLeakagesLeakageLocations.findIndex(row => row.rowNumber === rowNumber);
    if (rowIndex !== -1) {
        this.noOfLeakagesLeakageLocations[rowIndex][field] = value;
    }


        // const index = event.target.dataset.index;
        // const field = event.target.name;
        // const value = event.detail.value || event.target.value;

        // console.log(`No of leakage and leakage locations change - Index: ${index}, Field: ${field}, Value: ${value}`);
        // this.noOfLeakagesLeakageLocations[index][field] = value;

    // const rowNumber = parseInt(event.target.dataset.rownumber, 10);
    // const field = event.target.name;
    // const value = event.detail.value || event.target.value;

    // console.log(`leakage change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    // // Find row by rowNumber
    // const rowIndex = this.noOfLeakagesLeakageLocations.findIndex(row => row.rowNumber === rowNumber);
    // if (rowIndex !== -1) {
    //     this.noOfLeakagesLeakageLocations[rowIndex][field] = value;
    // }
    }


      hasValidnoOfLeakagesLeakageLocationsData() {
        return this.noOfLeakagesLeakageLocations.some(row => 
            (row.noOfLeakages && row.noOfLeakages.trim() !== '') ||
            (row.leakageLocations && row.leakageLocations.trim() !== '') 
        );
    } */


       handleBack(){

                this.dispatchEvent(new CustomEvent('cancel'));

             }

             wiredWorkOrderLineItemResult;

@wire(getRecord, {
    recordId: '$workOrderLineItemId',
    fields: [
        RISER_CATEGORY,
        CLAMPS_REPLACED,
        CRIMP_GUARDS_REPLACED,
        LENGTH_PAINTED_PRIMER,
        DFT_READING_PRIMER,
        LENGTH_PAINTED_YELLOW,
        DFT_READING_YELLOW,
        LENGTH_PAINTED_YELLOW3,
        DFT_READING_YELLOW3,
        NO_OF_LEAKAGES,
        LEAKAGE_LOCATIONS,
        FLOOR_NO,
        RISER_HEIGHT,
        INSTRUMENT_TYPE,
        CALIBRATION_CERT,
        CALIBRATION_DATE,
        CALIBRATION_DUE_DATE,
        INSTRUMENT_SERIAL
    ]
})
wiredWorkOrderLineItem(result) {
    this.wiredWorkOrderLineItemResult = result;
    if (result.data) {
        const f = result.data.fields;

        /*

             const woLineItem = result.workOrderLineItem;


            this.riserPainting.riserCategory = woLineItem.Riser_Category__c;

            if(woLineItem.Riser_Category__c == 'Main Riser'){

                this.showHeightOfRiser=true;
            }

        
            if(woLineItem.Clamps_Replaced__c){

              this.clampReplacement=true;

            this.riserPainting.noOfClampsReplaced = woLineItem.Clamps_Replaced__c;

            }

         if(woLineItem.Length_Painted_Primer__c || woLineItem.DFT_Reading_Primer__c){

            this.epoxyPaintPrimer=true;
             this.riserPainting.lengthPaintedPrimer = woLineItem.Length_Painted_Primer__c;
            this.riserPainting.dFTReadingPrimer = woLineItem.DFT_Reading_Primer__c;

         }
            
         if(woLineItem.Length_Painted_Yellow__c || woLineItem.DFT_Reading_Yellow__c){

            this.coat2PaintYellow=true;

            this.riserPainting.lengthPaintedYellow = woLineItem.Length_Painted_Yellow__c;
            this.riserPainting.dFTReadingYellow = woLineItem.DFT_Reading_Yellow__c;

             }

           if(woLineItem.Length_Painted_Yellow_3__c || woLineItem.DFT_Reading_Yellow_3__c){

            this.coat3PaintYellow=true;
            this.riserPainting.lengthPaintedYellow3 = woLineItem.Length_Painted_Yellow_3__c;
            this.riserPainting.dFTReadingYellow3 = woLineItem.DFT_Reading_Yellow_3__c;

           }

             if(woLineItem.Crimp_Guards_Replaced__c){

                this.crimpGuardReplacement=true;
          this.riserPainting.noofCrimpGuardsReplaced = woLineItem.Crimp_Guards_Replaced__c;

             }


            this.riserPainting.instrumentTypeRange = woLineItem.Instrument_Type_Range__c;
             this.riserPainting.calibrationCertificateNo = woLineItem.Calibration_Certificate_No__c;


              this.riserPainting.calibrationDate = woLineItem.Calibration_Date__c;
             this.riserPainting.calibrationDueDate = woLineItem.Calibration_Due_Date__c;
             this.riserPainting.instrumentSerialNumber = woLineItem.Instrument_Serial_Number__c;






        */
        this.riserPainting = {
            riserCategory: f.Riser_Category__c?.value || '',
            noOfClampsReplaced: f.Clamps_Replaced__c?.value || null,
            noofCrimpGuardsReplaced: f.Crimp_Guards_Replaced__c?.value || null,
            lengthPaintedPrimer: f.Length_Painted_Primer__c?.value || '',
            dFTReadingPrimer: f.DFT_Reading_Primer__c?.value || '',
            lengthPaintedYellow: f.Length_Painted_Yellow__c?.value || '',
            dFTReadingYellow: f.DFT_Reading_Yellow__c?.value || '',
            lengthPaintedYellow3: f.Length_Painted_Yellow_3__c?.value || '',
            dFTReadingYellow3: f.DFT_Reading_Yellow_3__c?.value || '',
            noOfLeakages: f.No_of_leakages_RiserPainting__c?.value || '',
            leakageLocations: f.Leakage_Locations_RiserPainting__c?.value || '',
            floorNumber: f.Floor_No_RiserPainting__c?.value || '',
            riserHeight: f.Riser_Height_RiserPainting__c?.value || ''
            // instrumentTypeRange: f.Instrument_Type_Range__c?.value || '',
            // calibrationCertificateNo: f.Calibration_Certificate_No__c?.value || '',
            // calibrationDate: f.Calibration_Date__c?.value || null,
            // calibrationDueDate: f.Calibration_Due_Date__c?.value || null,
            // instrumentSerialNumber: f.Instrument_Serial_Number__c?.value || ''
        };
        console.log('✅ Loaded Riser Painting:', JSON.stringify(this.riserPainting));

        this.showHeightOfRiser = this.riserPainting.riserCategory === 'Main Riser';
        this.clampReplacement = !!this.riserPainting.noOfClampsReplaced;
        this.crimpGuardReplacement = !!this.riserPainting.noofCrimpGuardsReplaced;
        this.epoxyPaintPrimer = !!(this.riserPainting.lengthPaintedPrimer || this.riserPainting.dFTReadingPrimer);
        this.coat2PaintYellow = !!(this.riserPainting.lengthPaintedYellow || this.riserPainting.dFTReadingYellow);
        this.coat3PaintYellow = !!(this.riserPainting.lengthPaintedYellow3 || this.riserPainting.dFTReadingYellow3);
         this.leakageRectification = !!(this.riserPainting.noOfLeakages || this.riserPainting.leakageLocations);
        this.heightofriserfloorwise = !!(this.riserPainting.riserHeight || this.riserPainting.floorNumber);

    } else if (result.error) {
        console.error('❌ Error fetching WorkOrderLineItem:', result.error);
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

        @track  filesBeforePainting = undefined;
        @track  filesAfterPainting = undefined;


         get fileNameBeforePainting() {
    const file = this.filesBeforePainting && this.filesBeforePainting[0];
    if (file) {
      return file.name;
    }
    return undefined;
  }

    get fileNameAfterPainting() {
    const file = this.filesAfterPainting && this.filesAfterPainting[0];
    if (file) {
      return file.name;
    }
    return undefined;
  }


        handleFilesBeforePainting(event) {
   
             this.filesBeforePainting = event.detail.files;

         }

         handleFilesAfterPainting(event) {
   
             this.filesAfterPainting = event.detail.files;

         }


         async handleUploadClickBeforePainting() {

        console.log('inside handle file upload riser tested status');

    if (!this.filesBeforePainting || this.filesBeforePainting.length === 0) {
        return;
    }

    try {
        this.load = true;

        console.log('insdie try block insdie riser tested status');

        for (let i = 0; i < this.filesBeforePainting.length; i++) {
            const file = this.filesBeforePainting[i];

            // Use per-file title and description or fallback
            const title =  file.name;
            console.log('title ::', title);
            const description = 'Before Painting Photo';
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

 async handleUploadClickAfterPainting() {

        console.log('inside handle file upload riser tested status');

    if (!this.filesAfterPainting || this.filesAfterPainting.length === 0) {
        return;
    }

    try {
        this.load = true;

        console.log('insdie try block insdie riser tested status');

        for (let i = 0; i < this.filesAfterPainting.length; i++) {
            const file = this.filesAfterPainting[i];

            // Use per-file title and description or fallback
            const title =  file.name;
            console.log('title ::', title);
            const description = 'After Painting Photo';
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

    

        this.load=true;

    console.log('🔹 Riser Painting Data before saving:', JSON.stringify(this.riserPainting));

    const formatDate = (value) => {
        if (!value) return null;
        const dateObj = new Date(value);
        if (isNaN(dateObj.getTime())) return null;
        return dateObj.toISOString().split('T')[0]; // → 'YYYY-MM-DD'
    };

    const riserPainting = {
        riserCategory: this.riserPainting.riserCategory,
        noOfClampsReplaced: this.riserPainting.noOfClampsReplaced,
        noofCrimpGuardsReplaced: this.riserPainting.noofCrimpGuardsReplaced,
        lengthPaintedPrimer: this.riserPainting.lengthPaintedPrimer,
        dFTReadingPrimer: this.riserPainting.dFTReadingPrimer,
        lengthPaintedYellow: this.riserPainting.lengthPaintedYellow,
        dFTReadingYellow: this.riserPainting.dFTReadingYellow,
        lengthPaintedYellow3: this.riserPainting.lengthPaintedYellow3,
        dFTReadingYellow3: this.riserPainting.dFTReadingYellow3,
        noOfLeakages: this.riserPainting.noOfLeakages,
        leakageLocations: this.riserPainting.leakageLocations,
        floorNumber: this.riserPainting.floorNumber,
        riserHeight: this.riserPainting.riserHeight
        // instrumentTypeRange: this.riserPainting.instrumentTypeRange,
        // calibrationCertificateNo: this.riserPainting.calibrationCertificateNo,
        // calibrationDate: formatDate(this.riserPainting.calibrationDate),       
        // calibrationDueDate: formatDate(this.riserPainting.calibrationDueDate), 
        // instrumentSerialNumber: this.riserPainting.instrumentSerialNumber
    };

    
       await this.updateWOLItemRiserPaintingLDS(this.workOrderLineItemId, riserPainting);
       await this.saveMaterialConsumption();
       await this.handleUploadClickBeforePainting();
       await this.handleUploadClickAfterPainting();

        if(this.workStepStatus !='Completed'){

        console.log('inside workstep status not equal completed');
     await this.updateWorkStepStatus();

     }

     await this.refreshData();


        this.showtoast('Success','Details Saved Successfully.','success');


                 this.load=false;

                this.handleBack();

    
    
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







  async updateWOLItemRiserPaintingLDS(workOrderLineItemId, riserPainting) {
    try {
        console.log('Updating WOLI via LDS:', workOrderLineItemId);

        const fields = {};
        fields[ID_FIELD.fieldApiName] = workOrderLineItemId;
        fields[RISER_CATEGORY.fieldApiName] = riserPainting.riserCategory;
        fields[CLAMPS_REPLACED.fieldApiName] = riserPainting.noOfClampsReplaced;
        fields[CRIMP_GUARDS_REPLACED.fieldApiName] = riserPainting.noofCrimpGuardsReplaced;

        fields[LENGTH_PAINTED_PRIMER.fieldApiName] = riserPainting.lengthPaintedPrimer;
        fields[DFT_READING_PRIMER.fieldApiName] = riserPainting.dFTReadingPrimer;

        fields[LENGTH_PAINTED_YELLOW.fieldApiName] = riserPainting.lengthPaintedYellow;
        fields[DFT_READING_YELLOW.fieldApiName] = riserPainting.dFTReadingYellow;

        fields[LENGTH_PAINTED_YELLOW3.fieldApiName] = riserPainting.lengthPaintedYellow3;
        fields[DFT_READING_YELLOW3.fieldApiName] = riserPainting.dFTReadingYellow3;

        fields[NO_OF_LEAKAGES.fieldApiName] = riserPainting.noOfLeakages;
        fields[LEAKAGE_LOCATIONS.fieldApiName] = riserPainting.leakageLocations;
        fields[FLOOR_NO.fieldApiName] = riserPainting.floorNumber;
        fields[RISER_HEIGHT.fieldApiName] = riserPainting.riserHeight;

        // fields[INSTRUMENT_TYPE.fieldApiName] = riserPainting.instrumentTypeRange;
        // fields[CALIBRATION_CERT.fieldApiName] = riserPainting.calibrationCertificateNo;
        // fields[CALIBRATION_DATE.fieldApiName] = riserPainting.calibrationDate;
        // fields[CALIBRATION_DUE_DATE.fieldApiName] = riserPainting.calibrationDueDate;
        // fields[INSTRUMENT_SERIAL.fieldApiName] = riserPainting.instrumentSerialNumber;

        const recordInput = { fields };

        await updateRecord(recordInput);

    } catch (error) {
        console.error('Error updating WOLI via LDS:', error);
       
    }
}


/*handleSave(){

        console.log('inside save method');

        console.log('Material list::', JSON.stringify(this.materialList));

        this.load=true;

            const jsonData = JSON.stringify(this.riserPainting);

    

         

        


       


                 this.showtoast('Success','Details Saved Successfully.','success');


                 this.load=false;

                this.handleBack();


        })

        .catch(error => {

            console.log('Error ::', error);
        })

    } */


        


 /*   handleSave(){

        console.log('inside save method');

        console.log('Material list::', JSON.stringify(this.materialList));

      //   console.log('🔧 Saving no of leakage and leakage locations Details:', JSON.stringify(this.noOfLeakagesLeakageLocations));


        this.load=true;

            const jsonData = JSON.stringify(this.riserPainting);

    //   const allFilesSelected = this.photoUploadSlots.length === this.risersNumber &&
    //         this.photoUploadSlots.every(slot => slot.fileName && slot.base64Data);

    //     if (!allFilesSelected) {
    //         this.load = false;
    //         //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
    //         this.showtoast('Warning', 'Please Capture Before Painting photo.', 'warning');
    //         return;
    //     }

        //   const allFilesSelectedAfter = this.afterPaintingPhotoUploadSlots.length === this.risersNumber &&
        //     this.afterPaintingPhotoUploadSlots.every(slot => slot.fileName && slot.base64Data);

        // if (!allFilesSelectedAfter) {
        //     this.load = false;
        //     //console.log('📸 Final slot data before save:', JSON.stringify(this.photoUploadSlots, null, 2));
        //     this.showtoast('Warning', 'Please Capture After Painting photo.', 'warning');
        //     return;
        // }

          var imagesList = [];
                this.photoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                  this.afterPaintingPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })


                 var temp = this.uploadFile(imagesList);

        


        updateWOLItemRiserPainting({recordId : this.workOrderLineItemId, riserPainting : jsonData,listFiles: imagesList })
        .then( result => {

            console.log('result after update riser painting details::', result);

             if (this.materialList.length > 0 && this.hasValidMaterialData()) {
                console.log('🔧 Saving Material Details:', JSON.stringify(this.materialList));

                materialConsumption({
                    recordId: this.workOrderLineItemId,
                    materialList: this.materialList

                });

                 }

                //     if (this.floorNumberAndRiserHeight.length > 0 && this.hasValidfloorNumberAndRiserHeightData()) {
                // console.log('🔧 Saving floor number and riser height Details:', JSON.stringify(this.floorNumberAndRiserHeight));

                // floorNumberAndRiserHeightDetails({
                //     recordId: this.workOrderLineItemId,
                //     floorNumberAndRiserHeight: this.floorNumberAndRiserHeight

                // });

                //  }

                //   if (this.noOfLeakagesLeakageLocations.length > 0 && this.hasValidnoOfLeakagesLeakageLocationsData()) {
                // console.log('🔧 Saving no of leakage and leakage locations Details:', JSON.stringify(this.noOfLeakagesLeakageLocations));

                // noOfLeakageAndLeakLocations({
                //     recordId: this.workOrderLineItemId,
                //     noOfLeakagesLeakageLocations: this.noOfLeakagesLeakageLocations

                // });

                //  }


                 this.showtoast('Success','Details Saved Successfully.','success');


                 this.load=false;

                this.handleBack();


        })

        .catch(error => {

            console.log('Error ::', error);
        })

    } */

    //  uploadFile(imagesList) {

        //      }

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


async handleAfterPaintingFile(event) {
        console.log('📥 inside handleFile');
        //let newSlots = event.detail.steps;
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