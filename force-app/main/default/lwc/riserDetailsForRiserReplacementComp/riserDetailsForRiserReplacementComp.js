import { LightningElement,api,track } from 'lwc';
import getItemDescriptionOptions from '@salesforce/apex/RiserDetailsForRiserReplacementContr.getItemDescriptionOptions';
import getItemCodeOptions from '@salesforce/apex/RiserDetailsForRiserReplacementContr.getItemCodeOptions';
import updateWOLItemRiserReplacement from '@salesforce/apex/RiserDetailsForRiserReplacementContr.updateWOLItemRiserReplacement';
import materialConsumption from '@salesforce/apex/RiserDetailsForRiserReplacementContr.materialConsumption';
// import floorNumberAndRiserHeightDetails from '@salesforce/apex/RiserDetailsForRiserPaintingContr.floorNumberAndRiserHeightDetails';
// import noOfLeakageAndLeakLocations from '@salesforce/apex/RiserDetailsForRiserPaintingContr.noOfLeakageAndLeakLocations';
// import getNumberOfRisersWO from '@salesforce/apex/RiserDetailsForRiserPaintingContr.getNumberOfRisersWO';
import getWorkOrderLineItem from '@salesforce/apex/RiserDetailsForRiserReplacementContr.getWorkOrderLineItem';

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

export default class RiserDetailsForRiserReplacementComp extends LightningElement {

     @track load=false;

    @api workOrderLineItemName='';
    @api workOrderLineItemId;


 //search item description 

     @track searchKey = '';
    @track filteredMaterials = [];
    @track selectedItemCode = '';
    delayTimeout;

    @track lastRowIndex='';


      get showDropdown() {
    return this.searchKey && this.filteredMaterials.length > 0;
}



    // search item description

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


          connectedCallback() {

           this.getWorkOrderLineItem(); 
            
         this.setPreInstallationPhotoUploadSlots();
         this.setGiPipeFabricationPhotoUploadSlots();
         this.setGiPipeErectionPhotoUploadSlots();
         this.setLengthOfPipelineCommissionedPhotoUploadSlots();
         this.setRiserLengthPhotoUploadSlots();

        this.getItemDescriptionOptions();
        this.getItemCodeOptions();


        }

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




                 getWorkOrderLineItem(){

        getWorkOrderLineItem({recordId : this.workOrderLineItemId})

        .then( result => {

            console.log('Result get workorderlineitem ::', JSON.stringify(result));


    /*

Clamps_Replaced__c,Crimp_Guards_Replaced__c,
	GI_pipe_fabrication_length__c,GI_pipe_erection_length__c,Length_of_Riser_Tested__c,
		Number_of_Leakages__c,Leak_Locations_1__c,Leak_Locations_2__c,Leak_Locations_3__c,
	Leak_Locations_4__c,Leak_Locations_5__c,Leak_Locations_6__c,Leak_Locations_7__c,
		Leak_Locations_8__c,Leak_Locations_9__c,Leak_Locations_10__c,Length_of_Riser_Commissioned__c,
	Riser_Length__c,Riser_Painting__c,Riser_Painted_Length__c,No_Of_Lateral_Replacement_Done__c,
     Instrument_Type_Range__c,Calibration_Certificate_No__c,
        Calibration_Date__c,Calibration_Due_Date__c 

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
        calibrationDueDate : null

                                        
    */
          

             const woLineItem = result.workOrderLineItem;


           // this.riserPainting.riserCategory = woLineItem.Riser_Category__c;

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

              //  this.riserTesting=true;
              //  this.showNoOfLeakages=true;
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



             this.materialList = (result.materialConsumptions || []).map((m, index) => {
                return {
                   // rowNumber: m.Material_Row_Number__c || (index + 1),
                
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


            // console.log('leakage location and number::', JSON.stringify(result.wolitemChild2));


            //          if(result.wolitemChild2){

            //             this.leakageRectification=true;

            //  this.noOfLeakagesLeakageLocations = (result.wolitemChild2 || []).map((m, index) => {
            //     return {
            //         rowNumber: m.Leakage_Row_Number__c || (index + 1),
            //         noOfLeakages: m.No_Of_Leakages__c,
            //         leakageLocations: m.Leakage_Locations__c
            //     };
            // });

            //          }
        })
        .catch(Error => {

            console.log('Error ::', Error);
        })
    }

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





   /* materail list picklist value old code 
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

         const rowNumber = parseInt(event.target.dataset.rownumber, 10); 
        
        console.log('Row number for delete ::', rowNumber);

    this.materialList = this.materialList.filter(row => row.rowNumber !== rowNumber);

        
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

    // Find row by rowNumber
    const rowIndex = this.materialList.findIndex(row => row.rowNumber === rowNumber);
    if (rowIndex !== -1) {
        this.materialList[rowIndex][field] = value;
    }


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
    } */

// materiallist search functionality


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


 uploadFile(imagesList) {

             }


     handleSave(){

        console.log('inside save method');



        this.load=true;

            const jsonData = JSON.stringify(this.riserReplacement);

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

            //  if (this.materialList.length > 0 && this.hasValidMaterialData()) {
            //     console.log('🔧 Saving Material Details:', JSON.stringify(this.materialList));

            //     materialConsumption({
            //         recordId: this.workOrderLineItemId,
            //         materialList: this.materialList

            //     });

            //      }


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
            this.load=false;
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