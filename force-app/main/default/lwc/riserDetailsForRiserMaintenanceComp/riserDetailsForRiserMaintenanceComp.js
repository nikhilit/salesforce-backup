import { LightningElement,api,track } from 'lwc';
import getItemDescriptionOptions from '@salesforce/apex/RiserDetailsForRiserMaintenanceContr.getItemDescriptionOptions';
import getItemCodeOptions from '@salesforce/apex/RiserDetailsForRiserMaintenanceContr.getItemCodeOptions';
import updateWOLItem from '@salesforce/apex/RiserDetailsForRiserMaintenanceContr.updateWOLItem';
import materialConsumption from '@salesforce/apex/RiserDetailsForRiserMaintenanceContr.materialConsumption';
import flatNumberAndLivPlug from '@salesforce/apex/RiserDetailsForRiserMaintenanceContr.flatNumberAndLivPlug';
import getWorkOrderLineItem from '@salesforce/apex/RiserDetailsForRiserMaintenanceContr.getWorkOrderLineItem';

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



export default class RiserDetailsForRiserMaintenanceComp extends LightningElement {

    @track load=false;

    @track anyOneYes=false;

    @track showCopperLeakageFound =false;
    @track showCrimpGuardleakageFound = false;

    @api workOrderLineItemName='';
    @api workOrderLineItemId;

    @track showEnterHolePiecesFlatNumber=false;
    @track showEnterAnacondasReplacedFlatNumber=false;
   // @track showEnterFlatNumber=false;
    @track ifYesShowanyencroachedcorrosionImageUpload=false;
    @track showDetailsAfterSuspectedGas=false;
    @track riserTestedStatusNotOk =false;
    @track showNoOfValvesReplaced=false;

    @track showAnyEncroachedPhotoUploadSlots = []; 
       noOfPhotosAnyEncroached = 1;

     @track notOkPhotoUploadSlots = []; 
       noOfPhotosStatusNotOk = 1;


     @track itemDescriptionOptions = [];

     @track itemCodeOptions = [];

             @track lastRowIndex='';

    @track showLekageFoundFields=false;

      riserPaintingOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    testPressureOptions = [
        { label: '250 mbar', value: '250 mbar' }
        
    ];
    durationOptions = [
        { label: '30 min', value: '30 min' }
        
    ];

    //search item description 

     @track searchKey = '';
    @track filteredMaterials = [];
    @track selectedItemCode = '';
    delayTimeout;



    get showDropdown() {
    return this.searchKey && this.filteredMaterials.length > 0;
}

    //search item description 


//  @track objectName = 'Maintenance_Entry__c';
//     @track fieldDescriptionName = 'Item_Description_Riser_Activity__c';

//     @track fieldCodeName = 'Item_Code_Riser_Activity__c';


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

       connectedCallback() {

        console.log('Selected workorderlineitem id::', this.workOrderLineItemId);

         this.getWorkOrderLineItem();

        
         this.setAnyEncroachedPhotoUploadSlots();
         this.setNotOkPhotoUploadSlots();
         this.getItemDescriptionOptions();
        this.getItemCodeOptions();
          

       }


          getWorkOrderLineItem(){

        getWorkOrderLineItem({recordId : this.workOrderLineItemId})

        .then( result => {

            console.log('Result get workorderlineitem ::', JSON.stringify(result.workOrderLineItem));
            console.log('Result get material list ::', JSON.stringify(result.materialConsumptions));


        /*Select Id,Number_of_Leakages__c,Clamps_Replaced__c,
										Crimp_Guards_Replaced__c,Hole_Pieces_Replaced__c,Hole_Pieces_Flat_Numbers__c,
										Valves_Replaced__c,Number_Of_Valves_Replaced__c,Anacondas_Replaced__c,Anacondas_Replaced_Flat_Numbers__c,
										LIV_Connectivity_with_flat_no__c,LIV_Connectivity_Flat_Numbers__c,GI_Pipe_Length_Replaced__c,Riser_Height_Floor_Wise__c,
										Any_encroached_corrosion_condition__c,Riser_Category__c,Suspected_Gas_Leakage_In_House_Lock__c,Test_Pressure__c,Duration__c	,	
										Riser_Tested_Status__c,Not_Ok_Remark__c,No_of_active_customers__c,Remark__c,Instrument_Type_Range__c,Calibration_Certificate_No__c,
										Calibration_Date__c,Calibration_Due_Date__c,Leak_Locations_1__c,Leak_Locations_2__c,Leak_Locations_3__c,Leak_Locations_4__c,Leak_Locations_5__c,
										Leak_Locations_6__c,Leak_Locations_7__c,Leak_Locations_8__c,Leak_Locations_9__c,Leak_Locations_10__c,Valves_Replaced_Location_1__c,Valves_Replaced_Location_2__c,
										Valves_Replaced_Location_3__c,Valves_Replaced_Location_4__c,Valves_Replaced_Location_5__c,Valves_Replaced_Location_6__c,Valves_Replaced_Location_7__c,Valves_Replaced_Location_8__c,
										Valves_Replaced_Location_9__c,Valves_Replaced_Location_10__c	



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
        livConnectivityFlatNumbers : '',
        gIPipeLengthReplaced : '',
        riserHeightFloorWise : null,

        anyencroachedcorrosioncondition : '',
        riserCategory : '',
        suspectedGasLeakageInHouseLock : '',
        testPressure : '',

        duration : '',
        riserTestedStatus : '',
        notOkRemark : '',
        noofactivecustomers : null,

        remark : '',
        instrumentTypeRange : '',
        calibrationCertificateNo : '',
        calibrationDueDate : null,
        calibrationDate : null

         isanycopperleakagefound : '',
        copperLeakageFoundNotificationNo : '',
        isanycrimpguardleakagefound : '',
        crimpLeakageFoundNotificationNo : '',
        isanySRleakagefound : '',
        srLeakageFountNotificationNo : ''

 CopperLeakageFoundNotificationNo__c,CrimpLeakageFoundNotificationNo__c,SRLeakageFountNotificationNo__c,
                                        Is_Any_Copper_Leakage_Found__c,Is_Any_Crimp_Guard_Leakage_Found__c,Is_Any_SR_Leakage_Found__c	
					

        */
            

             const woLineItem = result.workOrderLineItem;

             this.riserMaintenance.isanycopperleakagefound=woLineItem.Is_Any_Copper_Leakage_Found__c;
             this.riserMaintenance.isanycrimpguardleakagefound=woLineItem.Is_Any_Crimp_Guard_Leakage_Found__c;
            // this.riserMaintenance.isanySRleakagefound=woLineItem.Is_Any_SR_Leakage_Found__c;

        //      if(woLineItem.Is_Any_Copper_Leakage_Found__c =='Yes' || woLineItem.Is_Any_Crimp_Guard_Leakage_Found__c =='Yes' || woLineItem.Is_Any_SR_Leakage_Found__c){

        //         this.anyOneYes=true;

        //         this.riserMaintenance.copperLeakageFoundNotificationNo=woLineItem.CopperLeakageFoundNotificationNo__c;
        //      this.riserMaintenance.crimpLeakageFoundNotificationNo=woLineItem.CrimpLeakageFoundNotificationNo__c;
        //    //  this.riserMaintenance.srLeakageFountNotificationNo=woLineItem.SRLeakageFountNotificationNo__c;
        //      }

        if(woLineItem.Is_Any_Copper_Leakage_Found__c =='Yes'){   

                this.showCopperLeakageFound=true;
              this.riserMaintenance.copperLeakageFoundNotificationNo=woLineItem.CopperLeakageFoundNotificationNo__c;

               

             }

             if(woLineItem.Is_Any_Crimp_Guard_Leakage_Found__c =='Yes'){

                this.showCrimpGuardleakageFound=true;
               this.riserMaintenance.crimpLeakageFoundNotificationNo=woLineItem.CrimpLeakageFoundNotificationNo__c;
   

             }

             

             


             this.riserMaintenance.numberofLeakages = woLineItem.Number_of_leakages_rm__c != null
        ? woLineItem.Number_of_leakages_rm__c.toString()
        : null;
             //woLineItem.Number_of_leakages_rm__c;

             if(woLineItem.Number_of_leakages_rm__c){

        this.riserMaintenance.leakLocationList = Array.from(
        { length: woLineItem.Number_of_leakages_rm__c },
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

                if(woLineItem.Number_of_valves_replaced_rm__c){

        this.riserMaintenance.valvesReplacedList = Array.from(
        { length: woLineItem.Number_of_valves_replaced_rm__c },
        (_, i) => {
            const fieldName = `Valves_Replaced_Location_${i + 1}__c`;
            return {
                id: `${Date.now()}-${i}`,
                label: `Valves Replaced Location ${i + 1}`,
                value: woLineItem[fieldName] || '' // take from Apex or keep blank
            };
        }
    );
             }

               this.riserMaintenance.clampsReplaced = woLineItem.Clamps_replaced_rm__c;
               this.riserMaintenance.crimpGuardsReplaced = woLineItem.Crimp_guards_replaced_rm__c;

              this.riserMaintenance.holePiecesReplace = woLineItem.Hole_Pieces_Replaced__c;
               this.riserMaintenance.holePiecesFlatNumbers = woLineItem.Hole_Pieces_Flat_Numbers__c;


            if(woLineItem.Valves_Replaced__c){
                this.showNoOfValvesReplaced=true;
               this.riserMaintenance.valvesReplaced = woLineItem.Valves_Replaced__c;
               this.riserMaintenance.numberOfValvesReplaced =  woLineItem.Number_of_valves_replaced_rm__c != null
        ? woLineItem.Number_of_valves_replaced_rm__c.toString()
        : null;
            }
              this.riserMaintenance.anacondasReplaced = woLineItem.Anacondas_Replaced__c;
               this.riserMaintenance.anacondasReplacedFlatNumbers = woLineItem.Anacondas_Replaced_Flat_Numbers__c;

              this.riserMaintenance.valvesReplaced = woLineItem.Valves_Replaced__c;
               this.riserMaintenance.numberOfValvesReplaced =  woLineItem.Number_of_valves_replaced_rm__c != null
        ? woLineItem.Number_of_valves_replaced_rm__c.toString()
        : null;

              this.riserMaintenance.anacondasReplaced = woLineItem.Anacondas_Replaced__c;
               this.riserMaintenance.anacondasReplacedFlatNumbers = woLineItem.Anacondas_Replaced_Flat_Numbers__c;

              this.riserMaintenance.numberoflivconnectivity = woLineItem.number_of_liv_connectivity_rm__c;

            //  this.riserMaintenance.numberoflivconnectivity = woLineItem.Number_of_liv_connectivity__c;

           //  this.riserMaintenance.lIVConnectivitywithflatno = woLineItem.LIV_Connectivity_with_flat_no__c;

               this.riserMaintenance.livConnectivityFlatNumbers = woLineItem.LIV_Connectivity_Flat_Numbers__c;

              this.riserMaintenance.gIPipeLengthReplaced = woLineItem.GI_Pipe_Length_Replaced_rm__c;
               this.riserMaintenance.riserHeightFloorWise = woLineItem.Riser_Height_Floor_Wise_RM__c;


         this.riserMaintenance.anyencroachedcorrosioncondition = woLineItem.Any_encroached_corrosion_condition__c;
               this.riserMaintenance.riserCategory = woLineItem.Riser_Category__c;

               this.riserMaintenance.riserPainting = woLineItem.Riser_Painting__c;


              this.riserMaintenance.suspectedGasLeakageInHouseLock = woLineItem.Suspected_Gas_Leakage_In_House_Lock__c;

              if(woLineItem.Suspected_Gas_Leakage_In_House_Lock__c =='Yes'){

                this.showDetailsAfterSuspectedGas=true;
              }
             
             if(woLineItem.Test_Pressure__c != '' && woLineItem.Test_Pressure__c != null){
              this.riserMaintenance.testPressure = woLineItem.Test_Pressure__c;
             }

              if(woLineItem.Test_Pressure__c == '' && woLineItem.Test_Pressure__c ==null){
              this.riserMaintenance.testPressure = this.riserMaintenance.testPressure;
             }

                if(woLineItem.Duration__c !='' && woLineItem.Duration__c !=null){

                 this.riserMaintenance.duration = woLineItem.Duration__c;
                }
                 if(woLineItem.Duration__c =='' && woLineItem.Duration__c ==null){

                 this.riserMaintenance.duration = this.riserMaintenance.duration;
                }


                 if(woLineItem.Riser_Tested_Status__c){

                    console.log('inside riser test satus found',woLineItem.Riser_Tested_Status__c );

               this.riserMaintenance.riserTestedStatus = woLineItem.Riser_Tested_Status__c;

               console.log('riserMaintenance riserTestedStatus::', this.riserMaintenance.riserTestedStatus);

                 }

            if(woLineItem.Riser_Tested_Status__c =='Not OK'){

                this.riserTestedStatusNotOk=true;
              this.riserMaintenance.notOkRemark = woLineItem.Not_Ok_Remark__c;

            }
               this.riserMaintenance.noofactivecustomers = woLineItem.No_of_active_customers__c;


          this.riserMaintenance.remark = woLineItem.Remark__c;
             
             //  this.riserMaintenance.instrumentTypeRange = woLineItem.Instrument_Type_Range__c;

             // this.riserMaintenance.calibrationCertificateNo = woLineItem.Calibration_Certificate_No__c;
             //  this.riserMaintenance.calibrationDueDate = woLineItem.Calibration_Due_Date__c;

             //  this.riserMaintenance.calibrationDate = woLineItem.Calibration_Date__c;


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


        this.flatNumberAndLivPlug = (result.flatAndPlugDetails || []).map((m, index) => {
                return {
                   // rowNumber: m.WOLItemChild_Row_Number__c || (index + 1),
                   rowNumber: m.WOLItemChild_Row_Number__c ? parseInt(m.WOLItemChild_Row_Number__c, 10) : (index + 1),
                    flatNumber: m.Flat_Number__c,
                    livPlugStatus: m.Liv_Plug_Status__c
                };
            });

            console.log('Material List ::', JSON.stringify(this.materialList));

        //     this.riserPainting.riserCategory = woLineItem.Riser_Category__c;

        //     if(woLineItem.Clamps_Replaced__c){

        //       this.clampReplacement=true;

        //     this.riserPainting.noOfClampsReplaced = woLineItem.Clamps_Replaced__c;

        //     }

        //  if(woLineItem.Length_Painted_Primer__c || woLineItem.DFT_Reading_Primer__c){

        //     this.epoxyPaintPrimer=true;
        //      this.riserPainting.lengthPaintedPrimer = woLineItem.Length_Painted_Primer__c;
        //     this.riserPainting.dFTReadingPrimer = woLineItem.DFT_Reading_Primer__c;

        //  }
            
        //  if(woLineItem.Length_Painted_Yellow__c || woLineItem.DFT_Reading_Yellow__c){

        //     this.coat2PaintYellow=true;

        //     this.riserPainting.lengthPaintedYellow = woLineItem.Length_Painted_Yellow__c;
        //     this.riserPainting.dFTReadingYellow = woLineItem.DFT_Reading_Yellow__c;

        //      }

        //    if(woLineItem.Length_Painted_Yellow_3__c || woLineItem.DFT_Reading_Yellow_3__c){

        //     this.coat3PaintYellow=true;
        //     this.riserPainting.lengthPaintedYellow3 = woLineItem.Length_Painted_Yellow_3__c;
        //     this.riserPainting.dFTReadingYellow3 = woLineItem.DFT_Reading_Yellow_3__c;

        //    }

        //      if(woLineItem.Crimp_Guards_Replaced__c){

        //         this.crimpGuardReplacement=true;
        //   this.riserPainting.noofCrimpGuardsReplaced = woLineItem.Crimp_Guards_Replaced__c;

        //      }


        //     this.riserPainting.instrumentTypeRange = woLineItem.Instrument_Type_Range__c;
        //      this.riserPainting.calibrationCertificateNo = woLineItem.Calibration_Certificate_No__c;


        //       this.riserPainting.calibrationDate = woLineItem.Calibration_Date__c;
        //      this.riserPainting.calibrationDueDate = woLineItem.Calibration_Due_Date__c;



        //      this.materialList = (result.materialConsumptions || []).map((m, index) => {
        //         return {
        //             rowNumber: m.Material_Row_Number__c || (index + 1),
        //             itemCode: m.Item_Code_Riser_Activity__c,
        //             itemDescription: m.Item_Description_Riser_Activity__c,
        //             quantity: m.Quantity__c
        //         };
        //     });

        //     console.log('Material List ::', JSON.stringify(this.materialList));

        //     console.log('leakage location and number::', JSON.stringify(result.wolitemChild2));


        //              if(result.wolitemChild2){

        //                 this.leakageRectification=true;

        //      this.noOfLeakagesLeakageLocations = (result.wolitemChild2 || []).map((m, index) => {
        //         return {
        //             rowNumber: m.Leakage_Row_Number__c || (index + 1),
        //             noOfLeakages: m.No_Of_Leakages__c,
        //             leakageLocations: m.Leakage_Locations__c
        //         };
        //     });

        //              }
        })
        .catch(Error => {

            console.log('Error ::', Error);
        })
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

    //   riserTestedStatusOptions = [
    //     { label: 'OK', value: 'OK' },
    //     { label: 'Not OK', value: 'Not OK' },
    //     { label: 'Maintained and OK', value: 'Maintained and OK' }
    // ];

     riserTestedStatusOptions = [
        { label: 'Check and Found OK', value: 'Check and Found OK' },
        { label: 'Not OK', value: 'Not OK' },
        { label: 'Rectified and Found OK', value: 'Rectified and Found OK' }
    ];

     getItemDescriptionOptions(){
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
       // lIVConnectivitywithflatno : '',
        numberoflivconnectivity : null,
        livConnectivityFlatNumbers : '',
        gIPipeLengthReplaced : null,
        riserHeightFloorWise : null,
        anyencroachedcorrosioncondition : '',
        riserCategory : '',
        riserPainting : '',
        suspectedGasLeakageInHouseLock : '',
        testPressure : '250 mbar',
        duration : '30 min',
        riserTestedStatus : '',
        notOkRemark : '',
        noofactivecustomers : null,
        remark : '',
        // instrumentTypeRange : '',
        // calibrationCertificateNo : '',
        // calibrationDueDate : null,
        // calibrationDate : null,
      
        isanycopperleakagefound : '',
        copperLeakageFoundNotificationNo : '',
        isanycrimpguardleakagefound : '',
        crimpLeakageFoundNotificationNo : '',
        // isanySRleakagefound : '',
        // srLeakageFountNotificationNo : ''

    };



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

 if(event.target.value=='Main Riser' && event.target.label=='Riser Category'){  
                                        

            this.showLekageFoundFields=true;
            this.riserMaintenance.isanycopperleakagefound = '';
            this.riserMaintenance.copperLeakageFoundNotificationNo = '';
            this.riserMaintenance.isanycrimpguardleakagefound = '';
            this.riserMaintenance.crimpLeakageFoundNotificationNo='';
            this.showCopperLeakageFound=false;
            this.showCrimpGuardleakageFound=false;
        }
         if(event.target.value=='Approach Riser' && event.target.label=='Riser Category'){  
                                        

            this.showLekageFoundFields=false;
              this.riserMaintenance.isanycopperleakagefound = '';
            this.riserMaintenance.copperLeakageFoundNotificationNo = '';
            this.riserMaintenance.isanycrimpguardleakagefound = '';
            this.riserMaintenance.crimpLeakageFoundNotificationNo='';
            this.showCopperLeakageFound=false;
            this.showCrimpGuardleakageFound=false;
        }

         if(event.target.value=='Yes' && event.target.label=='Is Any Copper Leakage Found'){  
                                        

            this.showCopperLeakageFound=true;
        }
         if(event.target.value !='Yes' && event.target.label=='Is Any Copper Leakage Found'){  
                                        

            this.showCopperLeakageFound=false;
            this.riserMaintenance.copperLeakageFoundNotificationNo='';
        }
          if(event.target.value=='Yes' && event.target.label=='Is Any Crimp Guard Leakage Found'){  
                                        

            this.showCrimpGuardleakageFound=true;
        }
         if(event.target.value !='Yes' && event.target.label=='Is Any Crimp Guard Leakage Found'){  
                                        

            this.showCrimpGuardleakageFound=false;
            this.riserMaintenance.crimpLeakageFoundNotificationNo ='';
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
        //  if((event.target.value !='Not OK' || event.target.value!='OK' || event.target.value!='Maintained and OK') && event.target.label=='Riser Tested Status'){

        //     this.riserTestedStatusNotOk=false;
        //     this.riserMaintenance.notOkRemark='';
        //     this.notOkPhotoUploadSlots=[];
        //     this.setNotOkPhotoUploadSlots();

        // }
         if(event.target.value=='Yes' && event.target.label=='Any encroached corrosion condition'){

            this.ifYesShowanyencroachedcorrosionImageUpload=true;
        }
         if(event.target.value=='No' && event.target.label=='Any encroached corrosion condition'){

            this.ifYesShowanyencroachedcorrosionImageUpload=false;
            this.showAnyEncroachedPhotoUploadSlots =[];
            this.setAnyEncroachedPhotoUploadSlots();
            
        }
        //  if(event.target.value=='Yes' && event.target.label=='LIV Connectivity with flat no'){

        //     this.showEnterFlatNumber=true;
        // }
        //  if(event.target.value=='No' && event.target.label=='LIV Connectivity with flat no'){

        //     this.showEnterFlatNumber=false;
        //     this.riserMaintenance.livConnectivityFlatNumbers='';
        //     this.riserMaintenance.numberoflivconnectivity = '';
        // }

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

    //   @track suspectedGasFlatNumberList = [{
    //    // itemCode: '',
    //    // itemDescription: '',
    //    // unit: '',
    //    riserName : this.workOrderLineItemName,
    //     flatNumber: '',
    //     lIVplugstatus : ''
    // }];

    //  addSuspectedGasFlatNumberRow() {
    //     console.log('Adding new material row');
    //     this.suspectedGasFlatNumberList.push({

    //     riserName : this.workOrderLineItemName,       
    //       flatNumber: '',
    //       lIVplugstatus : ''


    //     });

    //         this.suspectedGasFlatNumberList = [...this.suspectedGasFlatNumberList];

    // }

    //   removeSuspectedGasFlatNumberRow(event) {
    //     const index = event.target.dataset.index;
    //     console.log(`Removing flat number row at index: ${index}`);
    //     if (this.suspectedGasFlatNumberList.length > 1) {
    //         this.suspectedGasFlatNumberList.splice(index, 1);
    //     }
    // }

    //    handleSuspectedGasFlatNumberChange(event) {
    //     const index = event.target.dataset.index;
    //     const field = event.target.name;
    //     const value = event.detail.value || event.target.value;

    //     console.log(`Suspected Gas Change - Index: ${index}, Field: ${field}, Value: ${value}`);
    //     this.suspectedGasFlatNumberList[index][field] = value;

    //      this.suspectedGasFlatNumberList[index].riserName = this.workOrderLineItemName;


    //     console.log('handlesuspectedgasflatnumberchnage ::', JSON.stringify(this.suspectedGasFlatNumberList));
    // }


    

   

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

    // hasValidMaterialData() {
    //     return this.materialList.some(row => 
    //         (row.itemCode && row.itemCode.trim() !== '') ||
    //         (row.itemDescription && row.itemDescription.trim() !== '') ||
    //         (row.quantity && row.quantity.trim() !== '')
    //     );
    // }

   /* 

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

       // console.log('selected for delete row number::', parseInt(event.target.dataset.rownumber, 10);
        
        const rowNumber = parseInt(event.target.dataset.rownumber, 10); 
        
        console.log('Row number for delete ::', rowNumber);

    this.materialList = this.materialList.filter(row => row.rowNumber !== rowNumber);
        // const index = event.target.dataset.index;
        // console.log(`Removing material row at index: ${index}`);
        // if (this.materialList.length > 1) {
        //     this.materialList.splice(index, 1);
        // }

        //  const index = event.target.dataset.index;
        // console.log(`Removing material row at index: ${index}`);
        // if (this.materialList.length > 1) {
        //     this.materialList.splice(index, 1);
        // }
        //    this.materialList = this.materialList.filter(row => row.rowNumber !== rowNumber);
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
        return this.materialList.some(row => 
            (row.itemCode && row.itemCode.trim() !== '') ||
            (row.itemDescription && row.itemDescription.trim() !== '') ||
            (row.quantity && row.quantity.trim() !== '')
        );
    } */


    @track flatNumberAndLivPlug = [{
                
        rowNumber: 1,
        flatNumber: '',
        livPlugStatus: ''
        
    }];

     addFlatAndLivPlugRow() {
        console.log('Adding new falt number and liv plug row');

        const nextRowNum = this.flatNumberAndLivPlug.length + 1; // simple increment

        this.flatNumberAndLivPlug.push({
            
             rowNumber: nextRowNum,
             flatNumber: '',
             livPlugStatus: ''
        });
    }

     removeFlatAndLivPlugRow(event) {

        const rowNumber = parseInt(event.target.dataset.rownumber, 10); // convert to number

         this.flatNumberAndLivPlug = this.flatNumberAndLivPlug.filter(row => row.rowNumber !== rowNumber);
     
        // const index = event.target.dataset.index;
        // console.log(`Removing flat and liv plug row at index: ${index}`);
        // if (this.flatNumberAndLivPlug.length > 1) {
        //     this.flatNumberAndLivPlug.splice(index, 1);
        // }
    }

      handleFlatNumberAndLivPlugChange(event) {

          const rowNumber = parseInt(event.target.dataset.rownumber, 10);
         const field = event.target.name;
             const value = event.detail.value || event.target.value;

    //console('row number handle change flat::', rowNumber);

    console.log(`flat and liv plug Change - RowNumber: ${rowNumber}, Field: ${field}, Value: ${value}`);

    // Find row by rowNumber
    const rowIndex = this.flatNumberAndLivPlug.findIndex(row => row.rowNumber === rowNumber);
    if (rowIndex !== -1) {
        this.flatNumberAndLivPlug[rowIndex][field] = value;
    }

        // const index = event.target.dataset.index;
        // const field = event.target.name;
        // const value = event.detail.value || event.target.value;

        // console.log(`Flat Number and liv plug change - Index: ${index}, Field: ${field}, Value: ${value}`);
        // this.flatNumberAndLivPlug[index][field] = value;
    }


      hasValidFlatNumberAndLivPlugData() {
        return this.flatNumberAndLivPlug.some(row => 
            (row.flatNumber && row.flatNumber.trim() !== '') ||
            (row.livPlugStatus && row.livPlugStatus.trim() !== '') 
        );
    }



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
        let slot = showAnyEncroachedPhotoUploadSlots[i];
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
        console.log('✅ Final showAnyEncroachedPhotoUploadSlots set');
    } 


    async handleNotOkFile(event) {
        console.log('📥 inside handleFile');
       // let newSlots = event.detail.steps;
        this.notOkPhotoUploadSlots =event.detail.steps;

        for (let i = 0; i < notOkPhotoUploadSlots.length; i++) {
        let slot = notOkPhotoUploadSlots[i];
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

    handleSave(){

     
        this.load=true;

         if (this.riserMaintenance.riserHeightFloorWise == null) {
            this.showtoast('Warning', 'Please Enter Riser Height Floor Wise', 'Warning');
            this.load=false;
            return;
        }

        console.log('inside handle save method');

         const jsonData = JSON.stringify(this.riserMaintenance);


                var imagesList = [];
              

                this.notOkPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                 this.showAnyEncroachedPhotoUploadSlots.forEach(item => {
                    imagesList.push({
                        base64Data: item.base64Data,
                        fileName: item.fileName,
                        label: item.label
                    })
                })

                           


                var temp = this.uploadFile(imagesList);



            console.log('Final image list data::', JSON.stringify(imagesList));



       // createMaintenanceEntryAndDetailsRecord({recordId : this.recordId, riserDetails: this.riserData,  })

        updateWOLItem({recordId : this.workOrderLineItemId, riserData: jsonData, listFiles: imagesList })

        .then( result => {

            console.log('Result after updating workorderlineitem::', result);
            //this.showtoast('Success', 'Details saved successfully!', 'Success');
            console.log('Material list type:', typeof this.materialList, this.materialList);
                             LightningAlert.open({
            message: 'Details Saved Successfully.',
            theme: 'success',   // red error dialog
            label: 'Success'    // header text
        }).then(() => {
                 this.load=false;

                this.handleBack();
         });

            //  if (this.materialList.length > 0 && this.hasValidMaterialData()) {
                console.log('Saving Material Details:', JSON.stringify(this.materialList));

                 const materialsToSend = this.materialList.map(m => ({
        rowNumber: parseInt(m.rowNumber, 10),
        itemCode: m.itemCode || '',
        itemDescription: m.itemDescription || '',
        quantity: parseInt(m.quantity || 0, 10)
    }));

                materialConsumption({
                    recordId: this.workOrderLineItemId,
                    //materialList: this.materialList
                     materialList: materialsToSend


                });

            //    }


                //   if (this.flatNumberAndLivPlug.length > 0 && this.hasValidFlatNumberAndLivPlugData()) {
                // console.log('🔧 Saving flat number and liv plug Details:', JSON.stringify(this.flatNumberAndLivPlug));

                // flatNumberAndLivPlug({
                //     recordId: this.workOrderLineItemId,
                //     flatNumberAndLivPlug: this.flatNumberAndLivPlug

                // });

                //  }

                 

            this.load=false;

            this.handleBack();
            

        })
        .catch(error => {

            // console.log('Error updating workorderlineitem::', Error);
            // this.load=false;

            console.error('⚠️ Error updating workorderlineitem:', JSON.stringify(error, null, 2));
    if (error && error.body && error.body.message) {
        console.error('➡️ Apex Error Message:', error.body.message);
    }
    this.load = false;
            
        })
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