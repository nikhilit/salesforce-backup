import { LightningElement, api, track, wire } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { getRecord, updateRecord,deleteRecord } from 'lightning/uiRecordApi';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import ID_FIELD from '@salesforce/schema/WorkOrder.Id';
import SA_ID_FIELD from '@salesforce/schema/ServiceAppointment.Id';
import RISERS from '@salesforce/schema/WorkOrder.Number_of_Risers__c';
import SAMPLE_BP1 from '@salesforce/schema/WorkOrder.Sample_BP_Number_1__c';
import SAMPLE_BP2 from '@salesforce/schema/WorkOrder.Sample_BP_Number_2__c';
import FLOORS from '@salesforce/schema/WorkOrder.Number_of_Floors__c';
import RISER_TYPE from '@salesforce/schema/WorkOrder.Type_of_Riser__c';
import BOARD_AVAILABLE from '@salesforce/schema/WorkOrder.Information_Board_available__c';
import NEW_BOARD from '@salesforce/schema/WorkOrder.New_information_board_installed__c';
import INSTRUMENT_TYPE from '@salesforce/schema/WorkOrder.RM_Instrument_Type_Range__c';
import CAL_CERT from '@salesforce/schema/WorkOrder.RM_Calibration_Certificate_No__c';
import CAL_DATE from '@salesforce/schema/WorkOrder.RM_Calibration_Date__c';
import CAL_DUE from '@salesforce/schema/WorkOrder.RM_Calibration_Due_Date__c';
import SERIAL_NO from '@salesforce/schema/WorkOrder.Instrument_Serial_Number__c';

import COPPER_LEAK from '@salesforce/schema/ServiceAppointment.Is_Any_Copper_Leakage_Found__c';
import COPPER_NOTIF from '@salesforce/schema/ServiceAppointment.CopperLeakageFoundNotificationNo__c';
import CRIMP_LEAK from '@salesforce/schema/ServiceAppointment.Is_Any_Crimp_Guard_Leakage_Found__c';
import CRIMP_NOTIF from '@salesforce/schema/ServiceAppointment.CrimpLeakageFoundNotificationNo__c';
import SR_LEAK from '@salesforce/schema/ServiceAppointment.Is_Any_SR_Leakage_Found__c';
import SR_NOTIF from '@salesforce/schema/ServiceAppointment.SRLeakageFountNotificationNo__c';
import MATERIAL_OBJECT from '@salesforce/schema/Material_Consumption__c';
const WOL_FIELDS = [
    'WorkOrderLineItem.Hole_Pieces_Replaced__c',
    'WorkOrderLineItem.Hole_Pieces_Flat_Numbers__c',
    'WorkOrderLineItem.Valves_Replaced__c',
    'WorkOrderLineItem.Anacondas_Replaced__c',
    'WorkOrderLineItem.Anacondas_Replaced_Flat_Numbers__c',
    'WorkOrderLineItem.LIV_Connectivity_Flat_Numbers__c',

    'WorkOrderLineItem.Riser_Height_Floor_Wise_RM__c',
    'WorkOrderLineItem.GI_Pipe_Length_Replaced_rm__c',
    'WorkOrderLineItem.number_of_liv_connectivity_rm__c',
    'WorkOrderLineItem.Crimp_guards_replaced_rm__c',
    'WorkOrderLineItem.Clamps_replaced_rm__c',

    'WorkOrderLineItem.Number_of_valves_replaced_rm__c',
    'WorkOrderLineItem.Valves_Replaced_Location_1__c',
    'WorkOrderLineItem.Valves_Replaced_Location_2__c',
    'WorkOrderLineItem.Valves_Replaced_Location_3__c',
    'WorkOrderLineItem.Valves_Replaced_Location_4__c',
    'WorkOrderLineItem.Valves_Replaced_Location_5__c',
    'WorkOrderLineItem.Valves_Replaced_Location_6__c',
    'WorkOrderLineItem.Valves_Replaced_Location_7__c',
    'WorkOrderLineItem.Valves_Replaced_Location_8__c',
    'WorkOrderLineItem.Valves_Replaced_Location_9__c',
    'WorkOrderLineItem.Valves_Replaced_Location_10__c',
    'WorkOrderLineItem.Number_of_leakages_rm__c',
    'WorkOrderLineItem.Leak_Locations_1__c',
    'WorkOrderLineItem.Leak_Locations_2__c',
    'WorkOrderLineItem.Leak_Locations_3__c',
    'WorkOrderLineItem.Leak_Locations_4__c',
    'WorkOrderLineItem.Leak_Locations_5__c',
    'WorkOrderLineItem.Leak_Locations_6__c',
    'WorkOrderLineItem.Leak_Locations_7__c',
    'WorkOrderLineItem.Leak_Locations_8__c',
    'WorkOrderLineItem.Leak_Locations_9__c',
    'WorkOrderLineItem.Leak_Locations_10__c',

    'WorkOrderLineItem.Any_encroached_corrosion_condition__c',
    'WorkOrderLineItem.Riser_Category__c',
    'WorkOrderLineItem.Riser_Painting__c',

    'WorkOrderLineItem.Suspected_Gas_Leakage_In_House_Lock__c',
    'WorkOrderLineItem.Test_Pressure__c',
    'WorkOrderLineItem.Duration__c',
    'WorkOrderLineItem.Riser_Tested_Status__c',
    'WorkOrderLineItem.Not_Ok_Remark__c',

    'WorkOrderLineItem.No_of_active_customers__c',
    'WorkOrderLineItem.Remark__c'
];

const WOL_CHILD_FIELDS = [
    'WorkOrderLineItem_Child__c.Id',
    'WorkOrderLineItem_Child__c.Flat_Number__c',
    'WorkOrderLineItem_Child__c.Liv_Plug_Status__c',
    'WorkOrderLineItem_Child__c.WOLItemChild_Row_Number__c'
];


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

export default class CoExecutionDetailsRiserMaintenanceLDS extends LightningElement {
    @api recordId;
    @api serviceAppointmentId;
    error;
    /* =======================
       UI FLAGS
    ======================= */
    @track load = false;
    @track isReadOnly = false;
    @track showSaveButton = true;

    @track showNewInformationBoarInstalled = false;
    @track showCopperLeakageFound = false;
    @track showCrimpGuardleakageFound = false;
    @track showSRLeakageFound = false;

    /* =======================
       FORM VALUES
    ======================= */
    risersNumber;
    sampleBP1;
    sampleBP2;
    risersFloors;
    riserPickListValue;
    boardAvailable;
    newInformationBoardInstalled;

    instrumentTypeRange;
    calibrationCertificateNo;
    calibrationDate;
    calibrationDueDate;
    instrumentSerialNumber;

    isanycopperleakagefound;
    copperLeakageFoundNotificationNo;

    isanycrimpguardleakagefound;
    crimpLeakageFoundNotificationNo;

    isanySRleakagefound;
    srLeakageFountNotificationNo;
    @track isRiserLocked = false;
    @track isLoading = false;

    existingRisers = [];
    workOrderLineItems = [];
    @track showWorkOrderLineItems=false;

    typeOfRiserOptions = [
        { label: 'Threaded', value: 'Threaded' },
        { label: 'Welded', value: 'Welded' }
    ];

    typeOfBoard = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    anyencroachedcorrosionconditionOptions=[
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    valvesReplacedOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

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


      livConnectivityOptions = [
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


    @track materialList = [
    {
        rowNumber: 1,
        itemCode: '',
        itemDescription: '',
        quantity: ''
    }
    ];

    lastRowIndex = 1;

    addMaterialRow() {
    this.lastRowIndex += 1;

    this.materialList = [
        ...this.materialList,
        {
            rowNumber: this.lastRowIndex,
            itemCode: '',
            itemDescription: '',
            quantity: ''
        }
    ];
    }

    removeMaterialRow(event) {
    const rowNumber = parseInt(event.target.dataset.rownumber, 10);

    this.materialList = this.materialList.filter(
        row => row.rowNumber !== rowNumber
    );
    }

    handleMaterialChange(event) {
    const rowNumber = parseInt(event.target.dataset.rownumber, 10);
    const field = event.target.name;
    const value = event.detail.value || event.target.value;

    const index = this.materialList.findIndex(
        row => row.rowNumber === rowNumber
    );

    if (index !== -1) {
        this.materialList[index][field] = value;
    }
    }

    hasValidMaterialData() {
    return this.materialList.some(row =>
        row.itemCode ||
        row.itemDescription ||
        (row.quantity !== null && row.quantity !== '')
    );
    }

    saveMaterialConsumption() {

    if (!this.hasValidMaterialData()) {
        this.showToast('Info', 'No material data entered', 'info');
        return;
    }

    const records = this.materialList
        .filter(row =>
            row.itemCode || row.itemDescription || row.quantity
        )
        .map(row => {

            const fields = {
                Work_Order_Line_Item__c: this.recordId,
                Item_Code_Riser_Activity__c: row.itemCode,
                Item_Description_Riser_Activity__c: row.itemDescription,
                Quantity__c: row.quantity,
                Material_Row_Number__c: String(row.rowNumber)
            };

            return createRecord({
                apiName: MATERIAL_OBJECT.objectApiName,
                fields
            });
        });

    Promise.all(records)
        .then(() => {
            this.showToast(
                'Success',
                'Material Consumption saved successfully',
                'success'
            );
        })
        .catch(error => {
            console.error(error);
            this.showToast(
                'Error',
                'Error saving material consumption',
                'error'
            );
        });
    }







   @wire(getRecord, {
    recordId: '$recordId',
    fields: [ RISERS, SAMPLE_BP1, SAMPLE_BP2,FLOORS,RISER_TYPE,
        BOARD_AVAILABLE, NEW_BOARD,INSTRUMENT_TYPE,CAL_CERT,
        CAL_DATE,
        CAL_DUE,
        SERIAL_NO
    ]
})
wiredWO({ data, error }) {

    console.log('recordId from parent:', this.recordId);
    console.log('serviceappointmentid from parent', this.serviceAppointmentId);

    if (data) {
        console.log('Riser Maintenance data:', JSON.stringify(data));

        this.risersNumber = data.fields.Number_of_Risers__c?.value;
        this.sampleBP1 = data.fields.Sample_BP_Number_1__c?.value;
        this.sampleBP2 = data.fields.Sample_BP_Number_2__c?.value;
        this.risersFloors = data.fields.Number_of_Floors__c?.value;
        this.riserPickListValue = data.fields.Type_of_Riser__c?.value;
        this.boardAvailable = data.fields.Information_Board_available__c?.value;
        this.newInformationBoardInstalled =
            data.fields.New_information_board_installed__c?.value;

        this.instrumentTypeRange =
            data.fields.RM_Instrument_Type_Range__c?.value;
        this.calibrationCertificateNo =
            data.fields.RM_Calibration_Certificate_No__c?.value;
        this.calibrationDate =
            data.fields.RM_Calibration_Date__c?.value;
        this.calibrationDueDate =
            data.fields.RM_Calibration_Due_Date__c?.value;
        this.instrumentSerialNumber =
            data.fields.Instrument_Serial_Number__c?.value;

        this.showNewInformationBoarInstalled =
            this.boardAvailable == 'No'?true:false;

        // Make form read-only if data already exists
        this.isReadOnly = !!this.risersNumber;
        console.log('riserPickListValue:::', this.riserPickListValue);
        console.log('this.boardAvailable:::',this.boardAvailable);
    }

    if (error) {
        console.error('Error loading Work Order:', error);
    }
}

    @wire(getRecord, {
    recordId: '$serviceAppointmentId',
    fields: [ COPPER_LEAK,COPPER_NOTIF,CRIMP_LEAK,CRIMP_NOTIF,SR_LEAK,SR_NOTIF
    ]
})
wiredWOServiceAppointment({ data, error }) {

    console.log('recordId from parent:', this.recordId);
    console.log('serviceappointmentid from parent',this.serviceAppointmentId);

    if (data) {
        console.log('Riser Maintenance service appointmentdata:', JSON.stringify(data));

        this.isanycopperleakagefound = data.fields.Is_Any_Copper_Leakage_Found__c?.value;
        this.copperLeakageFoundNotificationNo = data.fields.CopperLeakageFoundNotificationNo__c?.value;
        this.isanycrimpguardleakagefound = data.fields.Is_Any_Crimp_Guard_Leakage_Found__c?.value;
        this.crimpLeakageFoundNotificationNo = data.fields.CrimpLeakageFoundNotificationNo__c?.value;
        this.isanySRleakagefound = data.fields.Is_Any_SR_Leakage_Found__c?.value;
        this.srLeakageFountNotificationNo = data.fields.SRLeakageFountNotificationNo__c?.value;   
        this.showCopperLeakageFound =
            this.isanycopperleakagefound === 'Yes';
        this.showCrimpGuardleakageFound =
            this.isanycrimpguardleakagefound === 'Yes';
        this.showSRLeakageFound =
            this.isanySRleakagefound === 'Yes';
    }

    if (error) {
        console.error('Error loading Service Appointment:', error);
    }
    }

    wiredRisersResult;

    @wire(getRelatedListRecords, {
    parentRecordId: '$recordId',
    relatedListId: 'WorkOrderLineItems',
    fields: ['WorkOrderLineItem.Id', 'WorkOrderLineItem.Riser_Name__c']
    })
    wiredRisers(result) {

    this.wiredRisersResult = result;
    const { data, error } = result;

    if (data) {
        this.existingRisers = data.records;

        if (data.records.length > 0) {
            this.showWorkOrderLineItems = true;
            this.isRiserLocked = true;
            this.riserNumber = data.records.length;

            //sort Riser 1 → Riser N
            const sortedRecords = [...data.records].sort((a, b) => {
                const aNum = parseInt(
                    a.fields.Riser_Name__c?.value.replace('Riser ', ''),
                    10
                );
                const bNum = parseInt(
                    b.fields.Riser_Name__c?.value.replace('Riser ', ''),
                    10
                );
                return aNum - bNum;
            });

            // map after sorting
            this.workOrderLineItems = sortedRecords.map((rec, index) => ({
                recordId: rec.id,
                name: rec.fields.Riser_Name__c?.value,
                index: index + 1
            }));
        }
    }

    if (error) {
        console.error('Error loading risers', error);
    }
    }
   
    handleRiserChange(e) {
         if (this.isRiserLocked) {
        return;
    }
         this.risersNumber = e.target.value; 
    }
    handleSampleBP1Change(e) { 
        this.sampleBP1 = e.target.value; 
    }
    handleSampleBP2Change(e) { 
        this.sampleBP2 = e.target.value; 
    }
    handleFloorChange(e) {
        this.risersFloors = e.target.value; 
    }

    handlePicklistChange(e) { 
        this.riserPickListValue = e.target.value; 
    }

    handleboardAvailableChange(e) {
        this.boardAvailable = e.target.value;
        this.showNewInformationBoarInstalled = this.boardAvailable === 'Yes';
    }

    handleNewBoardInstalledChange(e) {
        this.newInformationBoardInstalled = e.target.value;
    }

    handleCopperLeakageFoundChange(e) {
        this.isanycopperleakagefound = e.target.value;
        this.showCopperLeakageFound = e.target.value == 'Yes';
    }

    handleCopperLeakNotificationNumberChange(e) {
        this.copperLeakageFoundNotificationNo = e.target.value;
    }

    handleCrimpGuardLeakageFoundChange(e) {
        this.isanycrimpguardleakagefound = e.target.value;
        this.showCrimpGuardleakageFound = e.target.value == 'Yes';
    }

    handleCrimpLeakFoundNotificationChange(e) {
        this.crimpLeakageFoundNotificationNo = e.target.value;
    }

    handleSRLeakageFoundChange(e) {
        this.isanySRleakagefound = e.target.value;
        this.showSRLeakageFound = e.target.value == 'Yes';
    }

    handleSrLeakageNotificationChange(e) {
        this.srLeakageFountNotificationNo = e.target.value;
    }

    handleInstrumentType(e) {
         this.instrumentTypeRange = e.target.value; 
    }
    handleCalibrationCertificateNo(e) { 
        this.calibrationCertificateNo = e.target.value; 
    }
    handleCalibrationDate(e) { 
        this.calibrationDate = e.target.value; 
    }
    handleCalibrationDueDate(e) { 
        this.calibrationDueDate = e.target.value; 
        }
    handleInstrumentSerialNumber(e) { 
        this.instrumentSerialNumber = e.target.value; 
    }

    handleWorkOrderLineitemBack(){
    this.showEnterRiserDetails=false;
    this.showWorkOrderLineItems=true; 
    }

    @track riserDrafts = {};

    handleWorkOrderLineitemSave() {
    this.riserDrafts = {
        ...this.riserDrafts,
        [this.workOrderLineItemId]: { ...this.riserMaintenance }
    };

    Promise.all([
        this.updateRiserLineItems(),
        this.saveFlatAndLivPlugRecords(),
        this.saveMaterialConsumption()
    ])
    .then(() => {
        this.showEnterRiserDetails = false;
        this.showWorkOrderLineItems = true;
    })
    .catch(err => {
        console.error(err);
        this.showtoast('Error', 'Failed to save data', 'error');
    });
        console.log(
        'Draft saved',
        JSON.stringify(this.riserDrafts)
    );

    }

    @track workOrderLineItemId='';
    handleOpenModal(event) {
    const recordId = event.currentTarget.dataset.id;
    const name = event.currentTarget.dataset.name;
    this.workOrderLineItemId=recordId;
    this.showEnterRiserDetails=true;
    this.showWorkOrderLineItems=false
    console.log('Open modal for:', recordId, name);
   
    }

    @track leakOptions = [
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

     @track riserMaintenance = {
        numberofLeakages: null,
        leakLocationList: [],
        clampsReplaced : null,
        crimpGuardsReplaced : null,
        holePiecesReplace : null,
        holePiecesFlatNumbers : '',
        valvesReplaced : '',
        numberOfValvesReplaced : null,
        valvesReplacedList : [],
        anacondasReplaced : null,
        anacondasReplacedFlatNumbers : '',
        numberoflivconnectivity : null,
        livConnectivityFlatNumbers : '',
        gIPipeLengthReplaced : null,
        riserHeightFloorWise : null,
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
    };

    
    @track flatNumberAndLivPlug = [{
                
        rowNumber: 1,
        flatNumber: '',
        livPlugStatus: ''
        
    }];
    @track deletedChildIds = [];

    @wire(getRelatedListRecords, {
    parentRecordId: '$workOrderLineItemId',
    relatedListId: 'WorkOrderLineItem_Childs__r',
    fields: WOL_CHILD_FIELDS
    })
    wiredFlatAndPlug({ data, error }) {
        if (data) {
            this.flatNumberAndLivPlug = data.records.map(r => ({
                id: r.id,
                rowNumber: Number(r.fields.WOLItemChild_Row_Number__c?.value),
                flatNumber: r.fields.Flat_Number__c?.value || '',
                livPlugStatus: r.fields.Liv_Plug_Status__c?.value || '',
                isExisting: true
            }));
        }
        if (error) {
            console.error(error);
        }
    }

     @wire(getRelatedListRecords, {
    parentRecordId: '$workOrderLineItemId',
    relatedListId: 'WorkOrderLineItem_Childs__r',
    fields: WOL_CHILD_FIELDS
    })
    wiredFlatAndPlug({ data, error }) {
        if (data) {
            this.flatNumberAndLivPlug = data.records.map(r => ({
                id: r.id,
                rowNumber: Number(r.fields.WOLItemChild_Row_Number__c?.value),
                flatNumber: r.fields.Flat_Number__c?.value || '',
                livPlugStatus: r.fields.Liv_Plug_Status__c?.value || '',
                isExisting: true
            }));
        }
        if (error) {
            console.error(error);
        }
    }

    // @wire(getRelatedListRecords, {
    // parentRecordId: '$workOrderLineItemId',
    // relatedListId: 'Material_Consumptions__r',
    // fields: WOL_CHILD_FIELDS
    // })
    // wiredFlatAndPlug({ data, error }) {
    //     if (data) {
    //         this.flatNumberAndLivPlug = data.records.map(r => ({
    //             id: r.id,
    //             rowNumber: Number(r.fields.WOLItemChild_Row_Number__c?.value),
    //             flatNumber: r.fields.Flat_Number__c?.value || '',
    //             livPlugStatus: r.fields.Liv_Plug_Status__c?.value || '',
    //             isExisting: true
    //         }));
    //     }
    //     if (error) {
    //         console.error(error);
    //     }
    // }




     addFlatAndLivPlugRow() {
    const nextRowNum = this.flatNumberAndLivPlug.length + 1;

    this.flatNumberAndLivPlug = [
        ...this.flatNumberAndLivPlug,
        {
            rowNumber: nextRowNum,
            flatNumber: '',
            livPlugStatus: '',
            isNew: true
        }
    ];
    }


    removeFlatAndLivPlugRow(event) {
    const rowNumber = Number(event.target.dataset.rownumber);

    const row = this.flatNumberAndLivPlug.find(r => r.rowNumber === rowNumber);

    if (row?.id) {
        this.deletedChildIds.push(row.id); 
    }

    this.flatNumberAndLivPlug =
        this.flatNumberAndLivPlug.filter(r => r.rowNumber !== rowNumber);
    }
    saveFlatAndLivPlugRecords() {
    const promises = [];

    // 🔹 Deletes
    this.deletedChildIds.forEach(id => {
        promises.push(deleteRecord(id));
    });

    // 🔹 Create / Update
    this.flatNumberAndLivPlug.forEach(row => {
        if (!row.flatNumber && !row.livPlugStatus) return;

        const fields = {
            Work_Order_Line_Item__c: this.workOrderLineItemId,
            Flat_Number__c: row.flatNumber,
            Liv_Plug_Status__c: row.livPlugStatus,
            WOLItemChild_Row_Number__c: String(row.rowNumber)
        };

        if (row.id) {
            fields.Id = row.id;
            promises.push(updateRecord({ fields }));
        } else {
            promises.push(
                createRecord({
                    apiName: 'WorkOrderLineItem_Child__c',
                    fields
                })
            );
        }
    });

    return Promise.all(promises);
    }



      handleFlatNumberAndLivPlugChange(event) {

          const rowNumber = parseInt(event.target.dataset.rownumber, 10);
          const field = event.target.name;
          const value = event.detail.value || event.target.value;
    console.log(`flat and liv plug Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

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

    @track showEnterRiserDetails=false;

handleRiserMaintainenceDetail(event){

    if (event.target.name === 'riserHeightFloorWise') {
        console.log('inside riser height change');

    let value = event.target.value;
    // If user clears field → store null
    if (value === '' || value === null) {
        this.riserMaintenance.riserHeightFloorWise = null;
        return;
    }
    // Convert to string for regex validation
    const strVal = value.toString();
    const regex = /^\d{1,14}(\.\d{0,4})?$/;
    if (regex.test(strVal)) {
        // valid number → convert to Number
        this.riserMaintenance.riserHeightFloorWise = strVal;
    } else {
        // invalid → set null & show warning
        this.riserMaintenance.riserHeightFloorWise = null;
        event.target.value='';
        this.showtoast(
            'Warning',
            'Enter valid value (max 14 digits before decimal and 4 after).',
            'warning'
        );
    }

    return; 
    }

  if (event.target.name === 'gIPipeLengthReplaced') {
    console.log('inside riser height change');

    let value = event.target.value;

    // If user clears field → store null
    if (value === '' || value === null) {
        this.riserMaintenance.gIPipeLengthReplaced = null;
        return;
    }

    // Convert to string for regex validation
    const strVal = value.toString();
    const regex = /^\d{1,14}(\.\d{0,4})?$/;

    if (regex.test(strVal)) {
        // valid number → convert to Number
        this.riserMaintenance.gIPipeLengthReplaced = strVal;
    } else {
        // invalid → set null & show warning
        this.riserMaintenance.gIPipeLengthReplaced = null;
                event.target.value='';

        this.showtoast(
            'Warning',
            'Enter valid value (max 14 digits before decimal and 4 after).',
            'warning'
        );
    }

    return; 
    }

    if (event.target.name === 'numberoflivconnectivity') {
    let value = event.target.value;
    if (!value) {
        this.riserMaintenance.numberoflivconnectivity = null;
        return;
    }
    const strVal = value.toString();
    const regex = /^\d{1,18}$/;

    if (regex.test(strVal)) {
        this.riserMaintenance.numberoflivconnectivity = Number(value);
    } else {
        this.riserMaintenance.numberoflivconnectivity = null;
        event.target.value='';
        this.showtoast(
            'Warning',
            'Enter a valid number (digits only, max 18 digits).',
            'warning'
        );
    }
    return;
    }

    if (event.target.name === 'crimpGuardsReplaced') {

        let value = event.target.value;

        if (!value) {
            this.riserMaintenance.crimpGuardsReplaced = null;
            return;
        }

    const strVal = value.toString();
    const regex = /^\d{1,18}$/;
        if (regex.test(strVal)) {
            this.riserMaintenance.crimpGuardsReplaced = Number(value);
        } else {
            this.riserMaintenance.crimpGuardsReplaced = null;
            event.target.value='';

            this.showtoast(
                'Warning',
                'Enter a valid number (digits only, max 18 digits).',
                'warning'
            );
        }
        return;
    }

        if (event.target.name === 'clampsReplaced') {

            let value = event.target.value;

            if (!value) {
                this.riserMaintenance.clampsReplaced = null;
                return;
            }
            const strVal = value.toString();
            const regex = /^\d{1,18}$/;
            if (regex.test(strVal)) {
                this.riserMaintenance.clampsReplaced = Number(value);
            } else {
                this.riserMaintenance.clampsReplaced = null;
                event.target.value='';

                this.showtoast(
                    'Warning',
                    'Enter a valid number (digits only, max 18 digits).',
                    'warning'
                );
            }
            return;
        }

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
            this.showAnyEncroachedPhotoUploadSlots =[];
            this.setAnyEncroachedPhotoUploadSlots();
            
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
    

    @wire(getRecord, {
    recordId: '$workOrderLineItemId',
    fields: WOL_FIELDS
        })
        wiredWOL({ data, error }) {
            if (data) {
        const f = data.fields;

        this.riserMaintenance = {
            ...this.riserMaintenance,

            holePiecesReplace: f.Hole_Pieces_Replaced__c?.value ?? null,
            holePiecesFlatNumbers: f.Hole_Pieces_Flat_Numbers__c?.value ?? '',

            valvesReplaced: f.Valves_Replaced__c?.value ?? '',
            anacondasReplaced: f.Anacondas_Replaced__c?.value ?? null,
            anacondasReplacedFlatNumbers: f.Anacondas_Replaced_Flat_Numbers__c?.value ?? '',

            livConnectivityFlatNumbers: f.LIV_Connectivity_Flat_Numbers__c?.value ?? '',

            riserHeightFloorWise: f.Riser_Height_Floor_Wise_RM__c?.value ?? null,
            gIPipeLengthReplaced: f.GI_Pipe_Length_Replaced_rm__c?.value ?? null,

            numberoflivconnectivity: f.number_of_liv_connectivity_rm__c?.value ?? null,
            crimpGuardsReplaced: f.Crimp_guards_replaced_rm__c?.value ?? null,
            clampsReplaced: f.Clamps_replaced_rm__c?.value ?? null,

            numberOfValvesReplaced: f.Number_of_valves_replaced_rm__c?.value ?? null,
            numberofLeakages: f.Number_of_leakages_rm__c?.value ?? null,

            anyencroachedcorrosioncondition: f.Any_encroached_corrosion_condition__c?.value ?? '',
            riserCategory: f.Riser_Category__c?.value ?? '',
            riserPainting: f.Riser_Painting__c?.value ?? '',

            suspectedGasLeakageInHouseLock:
                f.Suspected_Gas_Leakage_In_House_Lock__c?.value ?? '',

            testPressure: f.Test_Pressure__c?.value ?? '',
            duration: f.Duration__c?.value ?? '',
            riserTestedStatus: f.Riser_Tested_Status__c?.value ?? '',
            notOkRemark: f.Not_Ok_Remark__c?.value ?? '',

            noofactivecustomers: f.No_of_active_customers__c?.value ?? null,
            remark: f.Remark__c?.value ?? ''
        };

        if(this.riserMaintenance.suspectedGasLeakageInHouseLock =='Yes'){
                this.showDetailsAfterSuspectedGas=true;
        }

        if(this.riserMaintenance.riserTestedStatus =='Not OK'){
                this.riserTestedStatusNotOk=true;
                this.riserMaintenance.notOkRemark = f.Not_Ok_Remark__c?.value ?? '';
        }

         const leakCount = f.Number_of_leakages_rm__c?.value;

        // keep number as string (same as Apex behavior)
        this.riserMaintenance.numberofLeakages =
            leakCount != null ? leakCount.toString() : null;

        // build leakage locations list
        if (leakCount) {
            this.riserMaintenance.leakLocationList = Array.from(
                { length: leakCount },
                (_, i) => {
                    const fieldApi = `Leak_Locations_${i + 1}__c`;

                    return {
                        id: `${this.workOrderLineItemId}-${i}`,
                        label: `Leakage location ${i + 1}`,
                        value: f[fieldApi]?.value ?? ''
                    };
                }
            );
        } else {
            this.riserMaintenance.leakLocationList = [];
        }

        const valveCount = f.Number_of_valves_replaced_rm__c?.value;

        this.riserMaintenance.numberOfValvesReplaced =
            valveCount != null ? valveCount.toString() : null;

        if (valveCount) {
            this.riserMaintenance.valvesReplacedList = Array.from(
                { length: valveCount },
                (_, i) => {
                    const fieldApi = `Valves_Replaced_Location_${i + 1}__c`;

                    return {
                        id: `${this.workOrderLineItemId}-valve-${i}`,
                        label: `Valves Replaced Location ${i + 1}`,
                        value: f[fieldApi]?.value ?? ''
                    };
                }
            );
        } else {
            this.riserMaintenance.valvesReplacedList = [];
        }


        console.log(
            'WOL loaded via LDS',
            JSON.stringify(this.riserMaintenance)
        );
    }

    if (error) {
        console.error('Error loading WorkOrderLineItem', error);
    }
    }

    buildLeakageFields(fields) {
    // clear all possible leakage fields first (important!)
    for (let i = 1; i <= 10; i++) {
        fields[`Leak_Locations_${i}__c`] = null;
    }

    // repopulate from UI list
    this.riserMaintenance.leakLocationList.forEach((item, index) => {
        fields[`Leak_Locations_${index + 1}__c`] = item.value;
    });
    }

    buildValveFields(fields) {
    // clear old valve locations
    for (let i = 1; i <= 10; i++) {
        fields[`Valves_Replaced_Location_${i}__c`] = null;
    }

    // repopulate from UI
    this.riserMaintenance.valvesReplacedList.forEach((item, index) => {
        fields[`Valves_Replaced_Location_${index + 1}__c`] = item.value;
    });
    }




    buildWolFields(wolId, draft) {
    const fields = {};

    fields['Id'] = wolId;
    fields['Hole_Pieces_Replaced__c'] = draft.holePiecesReplace;
    fields['Hole_Pieces_Flat_Numbers__c'] = draft.holePiecesFlatNumbers;
    fields['Valves_Replaced__c'] = draft.valvesReplaced;
    fields['Anacondas_Replaced__c'] = draft.anacondasReplaced;
    fields['Anacondas_Replaced_Flat_Numbers__c'] = draft.anacondasReplacedFlatNumbers;
    fields['LIV_Connectivity_Flat_Numbers__c'] = draft.livConnectivityFlatNumbers;

    fields['Riser_Height_Floor_Wise_RM__c'] = draft.riserHeightFloorWise;
    fields['GI_Pipe_Length_Replaced_rm__c'] = draft.gIPipeLengthReplaced;

    fields['number_of_liv_connectivity_rm__c'] = draft.numberoflivconnectivity;
    fields['Crimp_guards_replaced_rm__c'] = draft.crimpGuardsReplaced;
    fields['Clamps_replaced_rm__c'] = draft.clampsReplaced;
    
    fields['Number_of_valves_replaced_rm__c'] =fields['Number_of_valves_replaced_rm__c'] =
    draft.numberOfValvesReplaced != null
        ? Number(draft.numberOfValvesReplaced)
        : null;

    fields['Number_of_leakages_rm__c'] = fields['Number_of_leakages_rm__c'] =
    draft.numberofLeakages != null
        ? Number(draft.numberofLeakages)
        : null;


    fields['Any_encroached_corrosion_condition__c'] = draft.anyencroachedcorrosioncondition;
    fields['Riser_Category__c'] = draft.riserCategory;
    fields['Riser_Painting__c'] = draft.riserPainting;

    fields['Suspected_Gas_Leakage_In_House_Lock__c'] = draft.suspectedGasLeakageInHouseLock;
    fields['Test_Pressure__c'] = draft.testPressure;
    fields['Duration__c'] = draft.duration;
    fields['Riser_Tested_Status__c'] = draft.riserTestedStatus;
    fields['Not_Ok_Remark__c'] = draft.notOkRemark;

    fields['No_of_active_customers__c'] = draft.noofactivecustomers;
    fields['Remark__c'] = draft.remark;

    return fields;
    }

    updateSingleRiser(wolId, draft) {
    const fields = this.buildWolFields(wolId, draft);
    console.log('fields:::from updatesingleriser::'+JSON.stringify(fields));
    this.buildLeakageFields(fields);
    this.buildValveFields(fields);
    return updateRecord({ fields });
    }

    updateRiserLineItems() {
    const promises = [];

    console.log('updateRiserLineItems::');

    Object.keys(this.riserDrafts).forEach(wolId => {
        promises.push(
            this.updateSingleRiser(wolId, this.riserDrafts[wolId])
        );
    });

    return Promise.all(promises);
    }



   handleSave() {
    this.load = true;

    const woFields = {};
    woFields[ID_FIELD.fieldApiName] = this.recordId;
    woFields[RISERS.fieldApiName] = this.risersNumber;
    woFields[SAMPLE_BP1.fieldApiName] = this.sampleBP1;
    woFields[SAMPLE_BP2.fieldApiName] = this.sampleBP2;
    woFields[FLOORS.fieldApiName] = this.risersFloors;
    woFields[RISER_TYPE.fieldApiName] = this.riserPickListValue;
    woFields[BOARD_AVAILABLE.fieldApiName] = this.boardAvailable;
    woFields[NEW_BOARD.fieldApiName] = this.newInformationBoardInstalled;
    woFields[INSTRUMENT_TYPE.fieldApiName] = this.instrumentTypeRange;
    woFields[CAL_CERT.fieldApiName] = this.calibrationCertificateNo;
    woFields[CAL_DATE.fieldApiName] = this.calibrationDate;
    woFields[CAL_DUE.fieldApiName] = this.calibrationDueDate;
    woFields[SERIAL_NO.fieldApiName] = this.instrumentSerialNumber;

    const saFields = {};
    saFields[SA_ID_FIELD.fieldApiName] = this.serviceAppointmentId;
    saFields[COPPER_LEAK.fieldApiName] = this.isanycopperleakagefound;
    saFields[COPPER_NOTIF.fieldApiName] = this.copperLeakageFoundNotificationNo;
    saFields[CRIMP_LEAK.fieldApiName] = this.isanycrimpguardleakagefound;
    saFields[CRIMP_NOTIF.fieldApiName] = this.crimpLeakageFoundNotificationNo;
    saFields[SR_LEAK.fieldApiName] = this.isanySRleakagefound;
    saFields[SR_NOTIF.fieldApiName] = this.srLeakageFountNotificationNo;

    const promises = [];
    promises.push(updateRecord({ fields: woFields }));

    if (this.serviceAppointmentId) {
        promises.push(updateRecord({ fields: saFields }));
    }

    Promise.all(promises)
        .then(() => {
            // create risers ONLY after save succeeds
            return this.createRiserLineItems();
        })
         .then(() => {
            return refreshApex(this.wiredRisersResult);
        })
        .then(() => {
            this.showToast(
                'Success',
                'Work Order and Service Appointment saved successfully',
                'success'
            );
        })
        .catch(error => {
            this.showToast(
                'Error',
                error?.body?.message || 'Error while saving records',
                'error'
            );
            console.error(error);
        })
        .finally(() => {
            this.load = false;
        });
    }


createRiserLineItems() {
    if (this.isRiserLocked || !this.risersNumber) {
        return Promise.resolve();
    }

    const count = parseInt(this.risersNumber, 10);
    const promises = [];

    for (let i = 1; i <= count; i++) {
        promises.push(
            createRecord({
                apiName: 'WorkOrderLineItem',
                fields: {
                    Riser_Name__c: `Riser ${i}`,
                    WorkOrderId: this.recordId
                }
            })
        );
    }

    return Promise.all(promises)
        .then(() => {
            this.isRiserLocked = true; 
            this.showWorkOrderLineItems = true;

        })
        .catch(error => {
            console.error('Error creating risers', error);
            throw error;
        });
}



    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

}