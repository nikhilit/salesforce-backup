import { LightningElement,api,track,wire } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';
import { createRecord, updateRecord, deleteRecord  } from 'lightning/uiRecordApi';
import LightningAlert from 'lightning/alert';
//import getWorkStepAndStatus from '@salesforce/apex/checkCustomerAvalibilityOfflineContr.getWorkStepAndStatus';
import WORKSTEP_OBJECT from '@salesforce/schema/WorkStep';
import NAME_FIELD from '@salesforce/schema/WorkStep.Name';
import PARENT_RECORD_FIELD from '@salesforce/schema/WorkStep.ParentRecordId';

import ID_FIELD from '@salesforce/schema/WorkStep.Id';
import STATUS_FIELD from '@salesforce/schema/WorkStep.Status';
import { getListUi } from 'lightning/uiListApi';
import WORKORDER_OBJECT from '@salesforce/schema/WorkOrder';
import WORKTYPE_OBJECT from '@salesforce/schema/WorkType';
import CONNECTION_FIELD from '@salesforce/schema/WorkOrder.Connection__c';
import RECORDTYPE_FIELD from '@salesforce/schema/WorkOrder.RecordTypeId';
import PARENT_FIELD from '@salesforce/schema/WorkOrder.ParentWorkOrderId';
import WORKTYPE_FIELD from '@salesforce/schema/WorkOrder.WorkTypeId';

import { createContentDocumentAndVersion} from "lightning/uiRecordApi";
import { getObjectInfos,getObjectInfo } from "lightning/uiObjectInfoApi";
import CONTENT_DOCUMENT from "@salesforce/schema/ContentDocument";
import CONTENT_VERSION from "@salesforce/schema/ContentVersion";
import CONTENT_DOCUMENT_LINK from "@salesforce/schema/ContentDocumentLink";


import MATERIAL_CONSUMPTION_OBJECT from '@salesforce/schema/Material_Consumption__c';
import ITEM_DESCRIPTION_FIELD from '@salesforce/schema/Material_Consumption__c.Item_Description_Riser_Activity__c';
import ITEM_CODE_FIELD from '@salesforce/schema/Material_Consumption__c.Item_Code_Riser_Activity__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import WorkOrderLineItemChild_OBJECT from '@salesforce/schema/WorkOrderLineItem_Child__c';


import NUMBER_OF_LEAKAGES from '@salesforce/schema/WorkOrderLineItem.Number_of_Leakages__c';
import CLAMPS_REPLACED from '@salesforce/schema/WorkOrderLineItem.Clamps_Replaced__c';
import CRIMP_GUARDS_REPLACED from '@salesforce/schema/WorkOrderLineItem.Crimp_Guards_Replaced__c';
import HOLE_PIECES_REPLACED from '@salesforce/schema/WorkOrderLineItem.Hole_Pieces_Replaced__c';
import HOLE_PIECES_FLAT_NUMBERS from '@salesforce/schema/WorkOrderLineItem.Hole_Pieces_Flat_Numbers__c';
import VALVES_REPLACED from '@salesforce/schema/WorkOrderLineItem.Valves_Replaced__c';
import NUMBER_OF_VALVES_REPLACED from '@salesforce/schema/WorkOrderLineItem.Number_Of_Valves_Replaced__c';
import ANACONDAS_REPLACED from '@salesforce/schema/WorkOrderLineItem.Anacondas_Replaced__c';
import ANACONDAS_REPLACED_FLAT_NUMBERS from '@salesforce/schema/WorkOrderLineItem.Anacondas_Replaced_Flat_Numbers__c';
import NUMBER_OF_LIV_CONNECTIVITY from '@salesforce/schema/WorkOrderLineItem.Number_of_liv_connectivity__c';
import LIV_CONNECTIVITY_FLAT_NUMBERS from '@salesforce/schema/WorkOrderLineItem.LIV_Connectivity_Flat_Numbers__c';
import GI_PIPE_LENGTH_REPLACED from '@salesforce/schema/WorkOrderLineItem.GI_Pipe_Length_Replaced__c';
import RISER_HEIGHT_FLOOR_WISE from '@salesforce/schema/WorkOrderLineItem.Riser_Height_Floor_Wise__c';
import ANY_ENCROACHED_CORROSION_CONDITION from '@salesforce/schema/WorkOrderLineItem.Any_encroached_corrosion_condition__c';
import RISER_CATEGORY from '@salesforce/schema/WorkOrderLineItem.Riser_Category__c';
import RISER_PAINTING from '@salesforce/schema/WorkOrderLineItem.Riser_Painting__c';
import SUSPECTED_GAS_LEAKAGE_IN_HOUSE_LOCK from '@salesforce/schema/WorkOrderLineItem.Suspected_Gas_Leakage_In_House_Lock__c';
import TEST_PRESSURE from '@salesforce/schema/WorkOrderLineItem.Test_Pressure__c';
import DURATION from '@salesforce/schema/WorkOrderLineItem.Duration__c';
import RISER_TESTED_STATUS from '@salesforce/schema/WorkOrderLineItem.Riser_Tested_Status__c';
import NOT_OK_REMARK from '@salesforce/schema/WorkOrderLineItem.Not_Ok_Remark__c';
import NO_OF_ACTIVE_CUSTOMERS from '@salesforce/schema/WorkOrderLineItem.No_of_active_customers__c';
import REMARK from '@salesforce/schema/WorkOrderLineItem.Remark__c';

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

import VALVE_LOC_1 from '@salesforce/schema/WorkOrderLineItem.Valves_Replaced_Location_1__c';
import VALVE_LOC_2 from '@salesforce/schema/WorkOrderLineItem.Valves_Replaced_Location_2__c';
import VALVE_LOC_3 from '@salesforce/schema/WorkOrderLineItem.Valves_Replaced_Location_3__c';
import VALVE_LOC_4 from '@salesforce/schema/WorkOrderLineItem.Valves_Replaced_Location_4__c';
import VALVE_LOC_5 from '@salesforce/schema/WorkOrderLineItem.Valves_Replaced_Location_5__c';
import VALVE_LOC_6 from '@salesforce/schema/WorkOrderLineItem.Valves_Replaced_Location_6__c';
import VALVE_LOC_7 from '@salesforce/schema/WorkOrderLineItem.Valves_Replaced_Location_7__c';
import VALVE_LOC_8 from '@salesforce/schema/WorkOrderLineItem.Valves_Replaced_Location_8__c';
import VALVE_LOC_9 from '@salesforce/schema/WorkOrderLineItem.Valves_Replaced_Location_9__c';
import VALVE_LOC_10 from '@salesforce/schema/WorkOrderLineItem.Valves_Replaced_Location_10__c';

import COPPER_LEAK_NOTIFICATION from '@salesforce/schema/WorkOrderLineItem.CopperLeakageFoundNotificationNo__c';
import CRIMP_LEAK_NOTIFICATION from '@salesforce/schema/WorkOrderLineItem.CrimpLeakageFoundNotificationNo__c';
import SR_LEAK_NOTIFICATION from '@salesforce/schema/WorkOrderLineItem.SRLeakageFountNotificationNo__c';
import IS_COPPER_LEAK_FOUND from '@salesforce/schema/WorkOrderLineItem.Is_Any_Copper_Leakage_Found__c';
import IS_CRIMP_LEAK_FOUND from '@salesforce/schema/WorkOrderLineItem.Is_Any_Crimp_Guard_Leakage_Found__c';
import IS_SR_LEAK_FOUND from '@salesforce/schema/WorkOrderLineItem.Is_Any_SR_Leakage_Found__c';

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




export default class RiserDetailsForRiserMaintenanceOffline extends LightningElement {

    @track load=false;

    @track anyOneYes=false;
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

    // POPUP INPUT HANDLERS
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
                itemCode: '',              // 🟢 clear code when description empty
                filteredMaterials: [],
                showDropdown: false
            };
            return;
        }

        // Filter materials (limit to 10 like previous)
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

// saveMaterial() {
//     if (!this.popupMaterial.itemDescription || !this.popupMaterial.quantity) {
//         return;
//     }

//     const nextRowNumber = this.materialList.length + 1;

//     this.materialList = [
//         ...this.materialList,
//         {
//             rowNumber: nextRowNumber,
//             itemCode: this.popupMaterial.itemCode,
//             itemDescription: this.popupMaterial.itemDescription,
//             quantity: this.popupMaterial.quantity
//         }
//     ];

//     this.closePopup();
// }

saveMaterial() {

    this.cleanMaterialList(); 

    const itemDescription = this.popupMaterial.itemDescription?.trim();
    const quantity = this.popupMaterial.quantity?.trim();

    // 🚫 STOP empty or whitespace
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

    // ✅ Reset popup COMPLETELY
    this.popupMaterial = {
        itemDescription: '',
        itemCode: '',
        quantity: '',
        filteredMaterials: [],
        showDropdown: false
    };

    this.closePopup();
}


    @track showFlatPopup = false;

@track popupFlat = {
    flatNumber: '',
    livPlugStatus: ''
};

// Open / Close
openFlatPopup() {
    this.popupFlat = { flatNumber: '', livPlugStatus: '' };
    this.showFlatPopup = true;
}

closeFlatPopup() {
    this.showFlatPopup = false;
}

// Handle changes
handlePopupFlatChange(event) {
    const field = event.target.name;
    this.popupFlat[field] = event.target.value;
}

cleanFlatList() {
    this.flatNumberAndLivPlug = this.flatNumberAndLivPlug.filter(
        m => m.flatNumber && m.livPlugStatus
    );
}
get hasFlatdata(){
     return this.flatNumberAndLivPlug.some(
        m => m.flatNumber && m.livPlugStatus
    );
}

// Save flat to list
saveFlat() {
    const flatNumber = this.popupFlat.flatNumber?.trim();
    const livPlugStatus = this.popupFlat.livPlugStatus?.trim();
    this.cleanFlatList();
    if (!flatNumber || !livPlugStatus) {
      LightningAlert.open({
                    message: 'Please fill required fields',
                    theme: 'warning',  
                    label: 'Warning'   
                });

        return;
    }

    const nextRowNumber = this.flatNumberAndLivPlug.length + 1;

    this.flatNumberAndLivPlug = [
        ...this.flatNumberAndLivPlug,
        {
            rowNumber: nextRowNumber,
            flatNumber,
            livPlugStatus
        }
    ];

    this.closeFlatPopup();
}



    leakOptions = [
    { label: 'GI pipe', value: 'GI pipe' },
    { label: 'Union', value: 'Union' },
    { label: 'Hole piece', value: 'Hole piece' },
    { label: 'Anaconda', value: 'Anaconda' },
    { label: 'GI Elbow', value: 'GI Elbow' },
    { label: 'GI Socket', value: 'GI Socket' },
    { label: 'GI Tee', value: 'GI Tee' },
    { label: 'GI Plug', value: 'GI Plug' },
    { label: 'Crimp guard (PE)', value: 'Crimp guard (PE)' },
    { label: 'Copper related', value: 'Copper related' },
    { label: 'GI Valve', value: 'GI Valve' },
    { label: 'GI Nipple', value: 'GI Nipple' }
];


        @track lastRowIndex=0;
        @track lastRowFlatNoPlugIndex='';

        @track  files = undefined;
        @track  filesRiserTestedStatus = undefined;

        @track childWorkOrderReplacementCount = 0;
        @track childWorkOrderPaintingCount = 0;


    @track showEnterHolePiecesFlatNumber=false;
    @track showEnterAnacondasReplacedFlatNumber=false;
    @track ifYesShowanyencroachedcorrosionImageUpload=false;
    @track showDetailsAfterSuspectedGas=false;
    @track riserTestedStatusNotOk =false;
    @track showNoOfValvesReplaced=false;

   


     @track itemDescriptionOptions = [];

     @track itemCodeOptions = [];

     @track existingMaterialRecords=[];
     @track existingFlatNoAndPlugRecords=[];


      riserPaintingOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    @track workStepId='';
    @track workStepStatus='';

    @track riserReplacementWorkTypeId='';

    @track riserPaintingWorkTypeId ='';


     @wire(getObjectInfos, {
    objectApiNames: [ CONTENT_DOCUMENT, CONTENT_VERSION, CONTENT_DOCUMENT_LINK ],
  })
  objectMetadata;

@wire(getObjectInfo, { objectApiName: MATERIAL_CONSUMPTION_OBJECT })
objectInfo;





       connectedCallback() {
        console.log('Selected workorderlineitem id::', this.workOrderLineItemId);
           if (this.wiredWorkOrderReplacementResult) {
            refreshApex(this.wiredWorkOrderReplacementResult);
        }
           if (this.wiredWorkOrderPaintingResult) {
            refreshApex(this.wiredWorkOrderPaintingResult);
        }
            this.refreshData();
       // this.getWorkStepAndStatus();
             console.log('Workorder id:::', this.recordId);
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
   


       @track parentRecord;

        @wire(getRecord, { recordId: '$recordId', fields: [CONNECTION_FIELD, RECORDTYPE_FIELD] })
        wiredParent({ data, error }) {
            if (data) {
                this.parentRecord = data;
                console.log('Parent WorkOrder:', this.parentRecord);
            } else if (error) {
                console.error(error);
            }
        }


 @track workTypeRecords = []; 

    @wire(getListUi, {
        objectApiName: WORKTYPE_OBJECT,
        listViewApiName: 'O_M_Work_Types',
        pageSize: 200
    })
    wiredWorkTypes({ data, error }) {
        console.log('inside checking data or not');
        if (data) {

            console.log('inside if getting worktype::', JSON.stringify(data));
            const records = data.records.records;


            // Filter only the ones we want
                    const filtered = records.filter(rec =>
                ['Riser Replacement', 'Riser Painting'].includes(rec.fields.Name.value)
            );

            this.workTypeRecords = filtered.map(rec => ({
                id: rec.id,
                name: rec.fields.Name.value
            }));

           
            console.log('Filtered WorkTypes:', JSON.stringify(this.workTypeRecords));
         
        } else if (error) {
            console.error('⚠️ Error fetching WorkTypes:', error);
        }
    }

      
    wiredWorkOrderReplacementResult;

    @wire(getListUi, {
        objectApiName: WORKORDER_OBJECT,
        listViewApiName: 'Riser_Replacement_WorkOrders', 
        pageSize: 200
    })
    wiredRiserReplacementWorkOrders(result) {
        this.wiredWorkOrderReplacementResult = result;
        const { data, error } = result;

        if (data) {
            const records = data.records.records;

            console.log('record length::', records.length);

            console.log('Records data::', JSON.stringify(records));

            console.log('inside childworkorder if conditon');

             const riserReplacementRecord = this.workTypeRecords.find(
                    rec => rec.name === 'Riser Replacement'
                                                        );
        const riserReplacementId = riserReplacementRecord?.id;

        this.riserReplacementWorkTypeId = riserReplacementId;

        console.log('checking workorder id::', this.recordId);

                  const filtered = records.filter(
                      rec => rec.fields.ParentWorkOrder?.value?.fields?.Id?.value === this.recordId &&
                              rec.fields.WorkType?.value?.fields?.Id?.value === riserReplacementId
                     );

        this.childWorkOrderReplacementCount = filtered.length;
        console.log('Filtered child WOs:', JSON.stringify(filtered));
        console.log('Count of child WOs:', this.childWorkOrderReplacementCount);

        } else if (error) {
            console.error('Error fetching WorkOrders:', error);
        }
    }

     wiredWorkOrderPaintingResult;

    @wire(getListUi, {
        objectApiName: WORKORDER_OBJECT,
        listViewApiName: 'Riser_Painting_WorkOrders', 
        pageSize: 200
    })
    wiredRiserPaintingWorkOrders(result) {
        this.wiredWorkOrderPaintingResult = result;
        const { data, error } = result;

        if (data) {
            const records = data.records.records;

            console.log('record length painting::', records.length);

            console.log('Records data::', JSON.stringify(records));

            console.log('inside childworkorder painting if conditon');

             const riserPaintingRecord = this.workTypeRecords.find(
                    rec => rec.name === 'Riser Painting'
                                                        );
        const riserPaintingtId = riserPaintingRecord?.id;

        this.riserPaintingWorkTypeId = riserPaintingtId;

        console.log('riser painting id::', riserPaintingtId);

        console.log('checking workorder id::', this.recordId);

                  const filtered = records.filter(
                      rec => rec.fields.ParentWorkOrder?.value?.fields?.Id?.value == this.recordId &&
                              rec.fields.WorkType?.value?.fields?.Id?.value == riserPaintingtId
                     );

        this.childWorkOrderPaintingCount = filtered.length;
        console.log('Filtered child WOs painting:', JSON.stringify(filtered));
        console.log('Count of child WOs painting:', this.childWorkOrderPaintingCount);

        } else if (error) {
            console.error('Error fetching WorkOrders:', error);
        }
    }

   async createRiserReplacementChildWorkOrder() {

    console.log('inside creating child workorder anyencroachedcorrosioncondition ::',this.riserMaintenance.anyencroachedcorrosioncondition)
    console.log('during creation of child childWorkOrderReplacementCount:: ', this.childWorkOrderReplacementCount);
    console.log('worktype ::', this.riserReplacementWorkTypeId);
    if (this.riserMaintenance?.anyencroachedcorrosioncondition === 'Yes' 
        && this.childWorkOrderReplacementCount < 1) {

          //  this.showtoast('Success', 'inside childWorkOrderReplacementCount less than one condition', 'success');


        console.log('Conditions met: creating child WorkOrder');

        // Ensure parent record and WorkTypeId exist
        if (!this.parentRecord || !this.riserReplacementWorkTypeId) {
            console.error('Missing required data for child WorkOrder creation');
            return;
        }

        const fields = {};
        fields[PARENT_FIELD.fieldApiName] = this.recordId;
        fields[WORKTYPE_FIELD.fieldApiName] = this.riserReplacementWorkTypeId;
        fields[CONNECTION_FIELD.fieldApiName] = this.parentRecord.fields.Connection__c.value;
        fields[RECORDTYPE_FIELD.fieldApiName] = this.parentRecord.fields.RecordTypeId.value;

        const recordInput = { apiName: WORKORDER_OBJECT.objectApiName, fields };

        createRecord(recordInput);
           

    } else {
       //     this.showtoast('Success', 'inside else createRiserReplacementChildWorkOrder method', 'success');

        console.log('Conditions not met: child WorkOrder not created');
    }
}

 async createRiserPaintingChildWorkOrder() {

    console.log('inside creating child workorder riserpaitning ::',this.riserMaintenance.riserPainting)
    console.log('during creation of child childWorkOrderPaintingCount:: ', this.childWorkOrderPaintingCount);
    console.log('worktype ::', this.riserPaintingWorkTypeId);
    if (this.riserMaintenance?.riserPainting === 'Yes' 
        && this.childWorkOrderPaintingCount < 1) {

        console.log('Conditions met: creating child WorkOrder riser painting');

        // Ensure parent record and WorkTypeId exist
        if (!this.parentRecord || !this.riserPaintingWorkTypeId) {
            console.error('Missing required data for child WorkOrder creation');
            return;
        }

        const fields = {};
        fields[PARENT_FIELD.fieldApiName] = this.recordId;
        fields[WORKTYPE_FIELD.fieldApiName] = this.riserPaintingWorkTypeId;
        fields[CONNECTION_FIELD.fieldApiName] = this.parentRecord.fields.Connection__c.value;
        fields[RECORDTYPE_FIELD.fieldApiName] = this.parentRecord.fields.RecordTypeId.value;

        const recordInput = { apiName: WORKORDER_OBJECT.objectApiName, fields };

        createRecord(recordInput);
            // .then(child => {
            //     console.log('Riser Replacement Child WorkOrder created:', child.id);
            // })
            // .catch(error => {
            //     console.error('❌ Error creating child WorkOrder:', error);
            // });

    } else {
      //   this.showtoast('Success', 'inside else createRiserPaintingChildWorkOrder method', 'success');

        console.log('Conditions not met: child WorkOrder not created');
    }
}



        async updateWorkStepStatus() {
        try {
            // Prepare field map
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.workStepId;
            fields[STATUS_FIELD.fieldApiName] = 'Completed'; 

            const recordInput = { fields };

            await updateRecord(recordInput);

          //  this.showToast('Success', 'WorkStep updated to Completed', 'success');
           // console.log('✅ WorkStep updated successfully');
        } catch (error) {
           // console.error('⚠️ Error updating WorkStep:', error);
          //  this.showToast('Error', error.body?.message || error.message, 'error');
        }
    }


        async refreshData() {
        console.log('🔄 Refreshing related list data...');
        try {
            if (this.wiredMaterialResult) await refreshApex(this.wiredMaterialResult);
            if (this.wiredFlatResult) await refreshApex(this.wiredFlatResult);
            console.log('✅ Data refreshed successfully!');

        } catch (error) {
            console.error('❌ Error refreshing data:', error);
        }
    }
      

       async handleUploadClick() {

        console.log('inside handle file upload');

    if (!this.files || this.files.length === 0) {
        return;
    }

    try {
        this.load = true;

        console.log('insdie try block');

        for (let i = 0; i < this.files.length; i++) {
            const file = this.files[i];

            // Use per-file title and description or fallback
            const title =  file.name;
            console.log('title ::', title);
            const description = 'Any encroached corrosion condition selected yes Photo';
            console.log('description ::', description);

            // Create ContentDocument + Version (enqueued offline)
            const contentDocumentAndVersion =
                await createContentDocumentAndVersion({
                    title: title,
                    description: description,
                    fileData: file,
                });
           // console.log(`File ${file.name} enqueued for upload.`);

            // Link each ContentDocument to the parent record
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

      //  this.notifySuccess();
      //  this.resetInputs();
    } catch (error) {
        console.error(error);
      //  this.errorMessage = error;
    } finally {
        this.load = false;
    }
}

 async handleUploadClickRiserTestedStatus() {

        console.log('inside handle file upload riser tested status');

    if (!this.filesRiserTestedStatus || this.filesRiserTestedStatus.length === 0) {
        return;
    }

    try {
        this.load = true;

        console.log('insdie try block insdie riser tested status');

        for (let i = 0; i < this.filesRiserTestedStatus.length; i++) {
            const file = this.filesRiserTestedStatus[i];

            // Use per-file title and description or fallback
            const title =  file.name;
            console.log('title ::', title);
            const description = 'Riser Tested Status Photo';
            console.log('description ::', description);

            // Create ContentDocument + Version (enqueued offline)
            const contentDocumentAndVersion =
                await createContentDocumentAndVersion({
                    title: title,
                    description: description,
                    fileData: file,
                });
           // console.log(`File ${file.name} enqueued for upload.`);

            // Link each ContentDocument to the parent record
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

      //  this.notifySuccess();
      //  this.resetInputs();
    } catch (error) {
        console.error(error);
      //  this.errorMessage = error;
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
    //this.submitForApproval();
    console.log("ContentDocumentLink record created.");
  }


    wiredMaterialResult;
    wiredFlatResult;	

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

    @wire(getRelatedListRecords, {
        parentRecordId: '$workOrderLineItemId',
        relatedListId: 'WorkOrderLineItem_Childs__r',
        fields: [
            'WorkOrderLineItem_Child__c.Id',
            'WorkOrderLineItem_Child__c.Flat_Number__c',
            'WorkOrderLineItem_Child__c.Liv_Plug_Status__c',
            'WorkOrderLineItem_Child__c.WOLItemChild_Row_Number__c'
        ],
        sortBy: ['WOLItemChild_Row_Number__c']
    })
    wiredChildRecords(result) {
        this.wiredFlatResult = result; // store for refresh
        const { data, error } = result;
        if (data) {
            this.flatNumberAndLivPlug = data.records.map(rec => ({
                id: rec.fields.Id.value,
                rowNumber: rec.fields.WOLItemChild_Row_Number__c?.value || '',
                flatNumber: rec.fields.Flat_Number__c?.value || '',
                livPlugStatus: rec.fields.Liv_Plug_Status__c?.value || ''
            }));
             if (this.flatNumberAndLivPlug.length > 0) {
                
             this.existingFlatNoAndPlugRecords = JSON.parse(JSON.stringify(this.flatNumberAndLivPlug));        
            console.log('existing flat no and plug records data::', JSON.stringify(this.existingFlatNoAndPlugRecords));

            const maxRowNumber = Math.max(...this.flatNumberAndLivPlug.map(r => Number(r.rowNumber)));
            this.lastRowFlatNoPlugIndex = maxRowNumber;
        } else {
            this.lastRowFlatNoPlugIndex = 0; 
        }
        } else if (error) {
            console.error('⚠️ Error fetching child records:', error);
        }
    }





        wiredWorkOrderLineItemResult; // store wire result reference

    @wire(getRecord, { recordId: '$workOrderLineItemId', fields: [  NUMBER_OF_LEAKAGES,
        CLAMPS_REPLACED,
        CRIMP_GUARDS_REPLACED,
        HOLE_PIECES_REPLACED,
        HOLE_PIECES_FLAT_NUMBERS,
        VALVES_REPLACED,
        NUMBER_OF_VALVES_REPLACED,
        ANACONDAS_REPLACED,
        ANACONDAS_REPLACED_FLAT_NUMBERS,
       // LIV_CONNECTIVITY_WITH_FLAT_NO,
        NUMBER_OF_LIV_CONNECTIVITY,
        LIV_CONNECTIVITY_FLAT_NUMBERS,
        GI_PIPE_LENGTH_REPLACED,
        RISER_HEIGHT_FLOOR_WISE,
        ANY_ENCROACHED_CORROSION_CONDITION,
        RISER_CATEGORY,
        RISER_PAINTING,
        SUSPECTED_GAS_LEAKAGE_IN_HOUSE_LOCK,
        TEST_PRESSURE,
        DURATION,
        RISER_TESTED_STATUS,
        NOT_OK_REMARK,
        NO_OF_ACTIVE_CUSTOMERS,
        REMARK,
        LEAK_LOC_1, LEAK_LOC_2, LEAK_LOC_3, LEAK_LOC_4, LEAK_LOC_5,
        LEAK_LOC_6, LEAK_LOC_7, LEAK_LOC_8, LEAK_LOC_9, LEAK_LOC_10,
        VALVE_LOC_1, VALVE_LOC_2, VALVE_LOC_3, VALVE_LOC_4, VALVE_LOC_5,
        VALVE_LOC_6, VALVE_LOC_7, VALVE_LOC_8, VALVE_LOC_9, VALVE_LOC_10,
        COPPER_LEAK_NOTIFICATION,
        CRIMP_LEAK_NOTIFICATION,
        SR_LEAK_NOTIFICATION,
        IS_COPPER_LEAK_FOUND,
        IS_CRIMP_LEAK_FOUND,
        IS_SR_LEAK_FOUND] })

    wiredWorkOrderLineItem(result) {
    this.wiredWorkOrderLineItemResult  = result; 
    console.log('wiredWorkOrderLineItemResult ::', JSON.stringify(result));
    const { data, error } = result;

    if (data) {

        console.log('inside data found using wire::', JSON.stringify(data));

         this.riserMaintenance.isanycopperleakagefound=data.fields.Is_Any_Copper_Leakage_Found__c.value;
             this.riserMaintenance.isanycrimpguardleakagefound=data.fields.Is_Any_Crimp_Guard_Leakage_Found__c.value;
             this.riserMaintenance.isanySRleakagefound=data.fields.Is_Any_SR_Leakage_Found__c.value;

             if(data.fields.Is_Any_Copper_Leakage_Found__c.value =='Yes' ||  data.fields.Is_Any_Crimp_Guard_Leakage_Found__c.value =='Yes' || data.fields.Is_Any_SR_Leakage_Found__c.value){

                this.anyOneYes=true;

                this.riserMaintenance.copperLeakageFoundNotificationNo=data.fields.CopperLeakageFoundNotificationNo__c.value;
             this.riserMaintenance.crimpLeakageFoundNotificationNo=data.fields.CrimpLeakageFoundNotificationNo__c.value;
             this.riserMaintenance.srLeakageFountNotificationNo=data.fields.SRLeakageFountNotificationNo__c.value;
             }

               this.riserMaintenance.numberofLeakages = data.fields.Number_of_Leakages__c.value;


            const numLeakages = data.fields.Number_of_Leakages__c?.value || '';
        this.riserMaintenance.numberofLeakages = numLeakages;

        this.riserMaintenance.leakLocationList = Array.from({ length: numLeakages }, (_, i) => {
            const fieldName = `Leak_Locations_${i + 1}__c`;
            const fieldVal = data.fields[fieldName]?.value || '';
            return {
                id: `${Date.now()}-${i}`,
                label: `Leakage Location ${i + 1}`,
                value: fieldVal
            };
        });

        console.log('leakLocationList:', JSON.stringify(this.riserMaintenance.leakLocationList));

        const numValves = data.fields.Number_Of_Valves_Replaced__c?.value || 0;
        this.riserMaintenance.numberOfValvesReplaced = numValves;

        this.riserMaintenance.valvesReplacedList = Array.from({ length: numValves }, (_, i) => {
            const fieldName = `Valves_Replaced_Location_${i + 1}__c`;
            const fieldVal = data.fields[fieldName]?.value || '';
            return {
                id: `${Date.now()}-${i}`,
                label: `Valves Replaced Location ${i + 1}`,
                value: fieldVal
            };
        });

        console.log('valvesReplacedList:', JSON.stringify(this.riserMaintenance.valvesReplacedList));

    


             this.riserMaintenance.clampsReplaced = data.fields.Clamps_Replaced__c.value;
               this.riserMaintenance.crimpGuardsReplaced = data.fields.Crimp_Guards_Replaced__c.value;

              this.riserMaintenance.holePiecesReplace = data.fields.Hole_Pieces_Replaced__c.value;
               this.riserMaintenance.holePiecesFlatNumbers = data.fields.Hole_Pieces_Flat_Numbers__c.value;


            if(data.fields.Valves_Replaced__c.value){
                this.showNoOfValvesReplaced=true;
               this.riserMaintenance.valvesReplaced = data.fields.Valves_Replaced__c.value;
               this.riserMaintenance.numberOfValvesReplaced = data.fields.Number_Of_Valves_Replaced__c.value;
            }
              this.riserMaintenance.anacondasReplaced = data.fields.Anacondas_Replaced__c.value;
               this.riserMaintenance.anacondasReplacedFlatNumbers = data.fields.Anacondas_Replaced_Flat_Numbers__c.value;

              this.riserMaintenance.valvesReplaced = data.fields.Valves_Replaced__c.value;
               this.riserMaintenance.numberOfValvesReplaced = data.fields.Number_Of_Valves_Replaced__c.value;

              this.riserMaintenance.anacondasReplaced = data.fields.Anacondas_Replaced__c.value;
               this.riserMaintenance.anacondasReplacedFlatNumbers = data.fields.Anacondas_Replaced_Flat_Numbers__c.value;

              this.riserMaintenance.numberoflivconnectivity = data.fields.Number_of_liv_connectivity__c.value;

            // this.riserMaintenance.lIVConnectivitywithflatno = data.fields.LIV_Connectivity_with_flat_no__c.value;

               this.riserMaintenance.livConnectivityFlatNumbers = data.fields.LIV_Connectivity_Flat_Numbers__c.value;

              this.riserMaintenance.gIPipeLengthReplaced = data.fields.GI_Pipe_Length_Replaced__c.value;
               this.riserMaintenance.riserHeightFloorWise = data.fields.Riser_Height_Floor_Wise__c.value;


               this.riserMaintenance.anyencroachedcorrosioncondition = data.fields.Any_encroached_corrosion_condition__c.value;
             if(this.riserMaintenance.anyencroachedcorrosioncondition =='Yes'){

                this.ifYesShowanyencroachedcorrosionImageUpload=true;
             }
             
               this.riserMaintenance.riserCategory = data.fields.Riser_Category__c.value;

               this.riserMaintenance.riserPainting = data.fields.Riser_Painting__c.value;


              this.riserMaintenance.suspectedGasLeakageInHouseLock = data.fields.Suspected_Gas_Leakage_In_House_Lock__c.value;

              if(data.fields.Suspected_Gas_Leakage_In_House_Lock__c.value =='Yes'){

                this.showDetailsAfterSuspectedGas=true;
              }
               this.riserMaintenance.testPressure = data.fields.Test_Pressure__c.value;

                 this.riserMaintenance.duration = data.fields.Duration__c.value;

                 if(data.fields.Riser_Tested_Status__c.value){

                    console.log('inside riser test satus found',data.fields.Riser_Tested_Status__c.value );

               this.riserMaintenance.riserTestedStatus = data.fields.Riser_Tested_Status__c.value;

               console.log('riserMaintenance riserTestedStatus::', this.riserMaintenance.riserTestedStatus);

                 }

            if(data.fields.Riser_Tested_Status__c.value =='Not OK' || data.fields.Riser_Tested_Status__c.value =='Check and Found OK' 
                || data.fields.Riser_Tested_Status__c.value =='Rectified and Found OK'){

                this.riserTestedStatusNotOk=true;
              this.riserMaintenance.notOkRemark = data.fields.Not_Ok_Remark__c.value;

            }
               this.riserMaintenance.noofactivecustomers = data.fields.No_of_active_customers__c.value;

          this.riserMaintenance.remark = data.fields.Remark__c.value;
        

    } else if (error) {
        console.error(' Error fetching user:', error);
    }
}


     numberofLeakagesOptions = [
    { label: '0', value: '0' },
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

 numberofValvesOptions = [
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

  valvesReplacedOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

      livConnectivityOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

      anyencroachedcorrosionconditionOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    mainOrApproachRiserOptions = [
        { label: 'Main Riser', value: 'Main Riser' },
        { label: 'Approach Riser', value: 'Approach Riser' }
    ];

     gasLeakLockCaseOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    

     riserTestedStatusOptions = [
        { label: 'Check and Found OK', value: 'Check and Found OK' },
        { label: 'Not OK', value: 'Not OK' },
        { label: 'Rectified and Found OK', value: 'Rectified and Found OK' }
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

             handleBack(){

                this.dispatchEvent(new CustomEvent('cancel'));



             }



 @track riserMaintenance = {
        numberofLeakages: '',
        leakLocationList: [],
        clampsReplaced : null,
        crimpGuardsReplaced : null,
        holePiecesReplace : null,
        holePiecesFlatNumbers : '',
       // holePieceFlatNumberList : [],
        valvesReplaced : '',
        numberOfValvesReplaced : '',
        valvesReplacedList : [],
        anacondasReplaced : null,
        anacondasReplacedFlatNumbers : '',
        lIVConnectivitywithflatno : '',
        numberoflivconnectivity : '',
        livConnectivityFlatNumbers : '',
        gIPipeLengthReplaced : '',
        riserHeightFloorWise : '',
        anyencroachedcorrosioncondition : '',
        riserCategory : '',
        riserPainting : '',
        suspectedGasLeakageInHouseLock : '',
        testPressure : '',
        duration : '',
        riserTestedStatus : '',
        notOkRemark : '',
        noofactivecustomers : null,
        remark : '',
        isanycopperleakagefound : '',
        copperLeakageFoundNotificationNo : '',
        isanycrimpguardleakagefound : '',
        crimpLeakageFoundNotificationNo : '',
        isanySRleakagefound : '',
        srLeakageFountNotificationNo : ''

    };



    handleRiserMaintainenceDetail(event){

         if(event.target.value=='Yes' && (event.target.label=='Is Any Copper Leakage Found' || 
                                        event.target.label=='Is Any Crimp Guard Leakage Found' ||
                                     event.target.label=='Is Any SR Leakage Found')){

            this.anyOneYes=true;
        }
         

         if(event.target.value=='Yes' && event.target.label=='Valves Replaced'){

            this.showNoOfValvesReplaced=true;
        }
        if(event.target.value=='No' && event.target.label=='Valves Replaced'){

            this.showNoOfValvesReplaced=false;
            this.riserMaintenance.valvesReplacedList=[];
            this.riserMaintenance.numberOfValvesReplaced='';
        }

        if((event.target.value=='Not OK' || event.target.value=='Check and Found OK' || event.target.value=='Rectified and Found OK') && event.target.label=='Riser Tested Status'){

            this.riserTestedStatusNotOk=true;
        }
      
         if(event.target.value=='Yes' && event.target.label=='Any encroached corrosion condition'){

            this.ifYesShowanyencroachedcorrosionImageUpload=true;
        }
         if(event.target.value=='No' && event.target.label=='Any encroached corrosion condition'){

            this.ifYesShowanyencroachedcorrosionImageUpload=false;
            
        }

         if(event.target.value !='' && event.target.label=='Hole Pieces Replaced'){

            this.showEnterHolePiecesFlatNumber=true;
        }

         if(event.target.value !='' && event.target.label=='Anacondas Replaced'){

            this.showEnterAnacondasReplacedFlatNumber=true;
        }
          if(event.target.value =='' && event.target.label=='Anacondas Replaced'){

            this.showEnterAnacondasReplacedFlatNumber=false;
            this.riserMaintenance.anacondasReplacedFlatNumbers='';
        }


        
         if(event.target.value =='Yes' && event.target.label=='Suspected Gas Leakage In House Lock'){

            this.showDetailsAfterSuspectedGas=true;
        }
         if(event.target.value =='No' && event.target.label=='Suspected Gas Leakage In House Lock'){

            this.showDetailsAfterSuspectedGas=false;
            this.suspectedGasFlatNumberList=[];
        }


     const field = event.target.name;
        const value = event.target.value;
        const fieldLabel = event.target.label;

        console.log('event value::', event.target.value);

     if (field === 'numberofLeakages') {

         this.riserMaintenance.numberofLeakages = value; // store number as string

        this.riserMaintenance.leakLocationList = Array.from(
                { length: value },
                (_, i) => ({
                    id: `${Date.now()}-${i}`, // unique & stable
                    label: `Leakage location ${i + 1}`,
                    value: ''
                })
            );
        }

     if (fieldLabel && fieldLabel.startsWith('Leakage location')) {
        const index = parseInt(fieldLabel.replace('Leakage location ', ''), 10) - 1;
        if (this.riserMaintenance.leakLocationList[index]) {
            this.riserMaintenance.leakLocationList[index].value = value;
            this.riserMaintenance.leakLocationList = [...this.riserMaintenance.leakLocationList];
        }
    }


     if (field === 'numberOfValvesReplaced') {

         this.riserMaintenance.numberOfValvesReplaced = value; // store number as string

        this.riserMaintenance.valvesReplacedList = Array.from(
                { length: value },
                (_, i) => ({
                    id: `${Date.now()}-${i}`, // unique & stable
                    label: `Valves Replaced Location ${i + 1}`,
                    value: ''
                })
            );
        }

     if (fieldLabel && fieldLabel.startsWith('Valves Replaced Location')) {
        const index = parseInt(fieldLabel.replace('Valves Replaced Location ', ''), 10) - 1;
        if (this.riserMaintenance.valvesReplacedList[index]) {
            this.riserMaintenance.valvesReplacedList[index].value = value;
            this.riserMaintenance.valvesReplacedList = [...this.riserMaintenance.valvesReplacedList];
        }
    }
        

        if (field) {
            this.riserMaintenance[field] = value;
        }

        console.log('riserMaintenance list details::', JSON.stringify(this.riserMaintenance));

    }


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


    @track flatNumberAndLivPlug = [{
            
        id:'',
        rowNumber: 0,
        flatNumber: '',
        livPlugStatus: ''
        
    }];

     addFlatAndLivPlugRow() {
        console.log('Adding new falt number and liv plug row');

        this.lastRowFlatNoPlugIndex++; 

        this.flatNumberAndLivPlug.push({
            
             rowNumber: this.lastRowFlatNoPlugIndex,
             flatNumber: '',
             livPlugStatus: ''
        });
    }

        rowsToFlatNoPlugDelete = [];


     removeFlatAndLivPlugRow(event) {


         const rowNumber = parseInt(event.currentTarget.dataset.rownumber, 10);

    const row = this.flatNumberAndLivPlug.find(r => Number(r.rowNumber) === rowNumber);

    if (row) {
        if (row.id) {
            this.rowsToFlatNoPlugDelete.push(row.id);
        }

        this.flatNumberAndLivPlug = this.flatNumberAndLivPlug.filter(r => Number(r.rowNumber) !== rowNumber);
    }

    console.log('flatNumberAndLivPlug after remove:', JSON.stringify(this.flatNumberAndLivPlug));
    console.log('Rows marked for deletion:', JSON.stringify(this.rowsToFlatNoPlugDelete));

       
    }

      handleFlatNumberAndLivPlugChange(event) {

          const rowNumber = parseInt(event.target.dataset.rownumber, 10);
         const field = event.target.name;
             const value = event.detail.value || event.target.value;


    console.log(`flat and liv plug Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    // Find row by rowNumber
    const rowIndex = this.flatNumberAndLivPlug.findIndex(row => row.rowNumber === rowNumber);
    if (rowIndex !== -1) {
        this.flatNumberAndLivPlug[rowIndex][field] = value;
    }

       
    }


      hasValidFlatNumberAndLivPlugData() {
        return this.flatNumberAndLivPlug.some(row => 
            (row.flatNumber && row.flatNumber.trim() !== '') ||
            (row.livPlugStatus && row.livPlugStatus.trim() !== '') 
        );
    }


    async handleSave(){

        this.load=true;

       try {
         const fields = {
        Id: this.workOrderLineItemId,
        [IS_COPPER_LEAK_FOUND.fieldApiName]: this.riserMaintenance.isanycopperleakagefound,
        [IS_CRIMP_LEAK_FOUND.fieldApiName]: this.riserMaintenance.isanycrimpguardleakagefound,
        [IS_SR_LEAK_FOUND.fieldApiName]: this.riserMaintenance.isanySRleakagefound,
        [COPPER_LEAK_NOTIFICATION.fieldApiName]: this.riserMaintenance.copperLeakageFoundNotificationNo,
        [CRIMP_LEAK_NOTIFICATION.fieldApiName]: this.riserMaintenance.crimpLeakageFoundNotificationNo,
        [SR_LEAK_NOTIFICATION.fieldApiName]: this.riserMaintenance.srLeakageFountNotificationNo,
        [NUMBER_OF_LEAKAGES.fieldApiName]: this.riserMaintenance.numberofLeakages,   
        [NUMBER_OF_VALVES_REPLACED.fieldApiName]: this.riserMaintenance.numberOfValvesReplaced,
        [CLAMPS_REPLACED.fieldApiName]: this.riserMaintenance.clampsReplaced,
        [CRIMP_GUARDS_REPLACED.fieldApiName]: this.riserMaintenance.crimpGuardsReplaced,
        [HOLE_PIECES_REPLACED.fieldApiName]: this.riserMaintenance.holePiecesReplace,
        [HOLE_PIECES_FLAT_NUMBERS.fieldApiName]: this.riserMaintenance.holePiecesFlatNumbers,
        [VALVES_REPLACED.fieldApiName]: this.riserMaintenance.valvesReplaced,
        [NUMBER_OF_VALVES_REPLACED.fieldApiName]: this.riserMaintenance.numberOfValvesReplaced,
        [ANACONDAS_REPLACED.fieldApiName]: this.riserMaintenance.anacondasReplaced,
        [ANACONDAS_REPLACED_FLAT_NUMBERS.fieldApiName]: this.riserMaintenance.anacondasReplacedFlatNumbers,
        [NUMBER_OF_LIV_CONNECTIVITY.fieldApiName]: this.riserMaintenance.numberoflivconnectivity,
      //  [LIV_CONNECTIVITY_WITH_FLAT_NO.fieldApiName]: this.riserMaintenance.lIVConnectivitywithflatno,
        [LIV_CONNECTIVITY_FLAT_NUMBERS.fieldApiName]: this.riserMaintenance.livConnectivityFlatNumbers,
        [GI_PIPE_LENGTH_REPLACED.fieldApiName]: this.riserMaintenance.gIPipeLengthReplaced,
        [RISER_HEIGHT_FLOOR_WISE.fieldApiName]: this.riserMaintenance.riserHeightFloorWise,
        [ANY_ENCROACHED_CORROSION_CONDITION.fieldApiName]: this.riserMaintenance.anyencroachedcorrosioncondition,
        [RISER_CATEGORY.fieldApiName]: this.riserMaintenance.riserCategory,
        [RISER_PAINTING.fieldApiName]: this.riserMaintenance.riserPainting,
        [SUSPECTED_GAS_LEAKAGE_IN_HOUSE_LOCK.fieldApiName]: this.riserMaintenance.suspectedGasLeakageInHouseLock,
        [TEST_PRESSURE.fieldApiName]: this.riserMaintenance.testPressure,
        [DURATION.fieldApiName]: this.riserMaintenance.duration,
        [RISER_TESTED_STATUS.fieldApiName]: this.riserMaintenance.riserTestedStatus,
        [NOT_OK_REMARK.fieldApiName]: this.riserMaintenance.notOkRemark,
        [NO_OF_ACTIVE_CUSTOMERS.fieldApiName]: this.riserMaintenance.noofactivecustomers,
        [REMARK.fieldApiName]: this.riserMaintenance.remark,
       
    };

      const leakLocationFields = [
            LEAK_LOC_1, LEAK_LOC_2, LEAK_LOC_3, LEAK_LOC_4, LEAK_LOC_5,
            LEAK_LOC_6, LEAK_LOC_7, LEAK_LOC_8, LEAK_LOC_9, LEAK_LOC_10
        ];

        const valveLocationFields = [
            VALVE_LOC_1, VALVE_LOC_2, VALVE_LOC_3, VALVE_LOC_4, VALVE_LOC_5,
            VALVE_LOC_6, VALVE_LOC_7, VALVE_LOC_8, VALVE_LOC_9, VALVE_LOC_10
        ];

    
     this.riserMaintenance.leakLocationList.forEach((item, index) => {
    const leakField = leakLocationFields[index];
    if (leakField) {
        fields[leakField.fieldApiName] = item.value || null; // allow empty overwrite
    }
});

        this.riserMaintenance.valvesReplacedList.forEach((item, index) => {
            if (valveLocationFields[index]) {
                fields[valveLocationFields[index].fieldApiName] = item.value;
            }
        });

     await updateRecord({ fields });
     await this.saveMaterialConsumption();
     await this.saveFlatNoPlug();
     await this.handleUploadClick();
     await this.handleUploadClickRiserTestedStatus();
      await this.createRiserReplacementChildWorkOrder();
      await this.createRiserPaintingChildWorkOrder();

     if(this.workStepStatus !='Completed'){

        console.log('inside workstep status not equal completed');
     await this.updateWorkStepStatus();

     }


            this.showtoast('Success', 'Details saved successfully', 'success');
            this.load=false;
            this.handleBack();
            await this.refreshData();

       }

        catch (error) {
            console.error('Error saving data:', error);
            this.showToast('Error', error.body?.message || 'Failed to save data', 'error');
        } finally {
            this.load = false;
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

     async saveFlatNoPlug() {
        console.log('Running flat no and plug comparison...');

            const recordsToInsert = this.flatNumberAndLivPlug.filter(r => !r.id);
            console.log('Records to insert flat no and plug:', JSON.stringify(recordsToInsert));

            for (const mat of recordsToInsert) {
                const fields = {
                        Work_Order_Line_Item__c : this.workOrderLineItemId,
                        Flat_Number__c : mat.flatNumber,
                        Liv_Plug_Status__c : mat.livPlugStatus,
                        WOLItemChild_Row_Number__c	: String(mat.rowNumber)
                        };
                await createRecord({ apiName: WorkOrderLineItemChild_OBJECT.objectApiName, fields });
            }

       // console.log('rows to delete flat no and plug::', JSON.stringify(this.rowsToFlatNoPlugDelete));

            const validRowsToDelete = this.rowsToFlatNoPlugDelete.filter(id => id && id.length === 18);
        console.log('Records to delete flat no and plug:', JSON.stringify(validRowsToDelete));

        for (const id of validRowsToDelete) {
            try {
                await deleteRecord(id);
                console.log('Deleted record flat no and plug:', id);
            } catch (err) {
                console.error('Error deleting record flat no and plug:', err, 'Id:', id);
            }
        }

        // Clear rowsToDelete after save
        this.rowsToFlatNoPlugDelete = [];


        console.log('flat no and plug create/delete complete.');
    }

     get fileName() {
    const file = this.files && this.files[0];
    if (file) {
      return file.name;
    }
    return undefined;
  }
    get fileNameRiserTestedStatus() {
    const file = this.filesRiserTestedStatus && this.filesRiserTestedStatus[0];
    if (file) {
      return file.name;
    }
    return undefined;
  }


     handleFilesInputChange(event) {
    this.files = event.detail.files;

  }

   handleFileRiserTestedStatusChange(event) {
    this.filesRiserTestedStatus = event.detail.files;

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