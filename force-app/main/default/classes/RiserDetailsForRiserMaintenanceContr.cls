/**
* @File Name : RiserDetailsForRiserMaintenanceContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 16, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 16, 2025 |   | Initial Version
**/

public without sharing class RiserDetailsForRiserMaintenanceContr {
	 @AuraEnabled
public static List<String> getItemDescriptionOptions() {
    List<String> options = new List<String>();

    // This is the correct way to get the picklist entries for a field
    Schema.DescribeFieldResult fieldResult = Material_Consumption__c.Item_Description_Riser_Activity__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

    for (Schema.PicklistEntry pe : picklistValues) {
        options.add(pe.getValue());
    }

    return options;
}

 @AuraEnabled
public static List<String> getItemCodeOptions() {
    List<String> options = new List<String>();

    // This is the correct way to get the picklist entries for a field
    Schema.DescribeFieldResult fieldResult = Material_Consumption__c.Item_Code_Riser_Activity__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

    for (Schema.PicklistEntry pe : picklistValues) {
        options.add(pe.getValue());
    }

    return options;
}


@AuraEnabled
public static WorkOrderLineItemWrapper getWorkOrderLineItem(String recordId){

             WorkOrderLineItemWrapper wrapper = new WorkOrderLineItemWrapper();


    try {
/*
Number_of_Leakages__c,Number_Of_Valves_Replaced__c,Clamps_Replaced__c,Crimp_Guards_Replaced__c,
Number_of_liv_connectivity__c, //GI_Pipe_Length_Replaced__c,Riser_Height_Floor_Wise__c,
*/

WorkOrderLineItem getWorkOrderLineItem = [Select Id,Riser_Height_Floor_Wise_RM__c,number_of_liv_connectivity_rm__c,
                                            Crimp_guards_replaced_rm__c,Clamps_replaced_rm__c,Number_of_valves_replaced_rm__c,GI_Pipe_Length_Replaced_rm__c,
                                            Number_of_leakages_rm__c,
                                        Hole_Pieces_Replaced__c,Hole_Pieces_Flat_Numbers__c,
										Valves_Replaced__c,
                                        Anacondas_Replaced__c,Anacondas_Replaced_Flat_Numbers__c,
                                        LIV_Connectivity_Flat_Numbers__c,                                      
										Any_encroached_corrosion_condition__c,Riser_Category__c,Riser_Painting__c,Suspected_Gas_Leakage_In_House_Lock__c,Test_Pressure__c,Duration__c	,	
										Riser_Tested_Status__c,Not_Ok_Remark__c,No_of_active_customers__c,Remark__c,
                                        Leak_Locations_1__c,Leak_Locations_2__c,Leak_Locations_3__c,Leak_Locations_4__c,Leak_Locations_5__c,
										Leak_Locations_6__c,Leak_Locations_7__c,Leak_Locations_8__c,Leak_Locations_9__c,Leak_Locations_10__c,
                                        Valves_Replaced_Location_1__c,Valves_Replaced_Location_2__c,
										Valves_Replaced_Location_3__c,Valves_Replaced_Location_4__c,Valves_Replaced_Location_5__c,Valves_Replaced_Location_6__c,Valves_Replaced_Location_7__c,Valves_Replaced_Location_8__c,
										Valves_Replaced_Location_9__c,Valves_Replaced_Location_10__c,
                                        CopperLeakageFoundNotificationNo__c,CrimpLeakageFoundNotificationNo__c,
                                        Is_Any_Copper_Leakage_Found__c,Is_Any_Crimp_Guard_Leakage_Found__c
                                                                                                  
											from WorkOrderLineItem Where Id=: recordId];
       
/* CopperLeakageFoundNotificationNo__c,CrimpLeakageFoundNotificationNo__c,SRLeakageFountNotificationNo__c,
    Is_Any_Copper_Leakage_Found__c,Is_Any_Crimp_Guard_Leakage_Found__c,Is_Any_SR_Leakage_Found__c	
					

*/

     List<Material_Consumption__c> materials = [
                SELECT Id,
                       Work_Order_Line_Item__c,Item_Code_Riser_Activity__c,Item_Description_Riser_Activity__c,
                       Quantity__c,Material_Row_Number__c
                FROM Material_Consumption__c
                WHERE Work_Order_Line_Item__c = :recordId
            ];


 List<WorkOrderLineItem_Child__c> lstWOLIChild = [Select id,Work_Order_Line_Item__c,Flat_Number__c,
                                                  Liv_Plug_Status__c,WOLItemChild_Row_Number__c from
                                   WorkOrderLineItem_Child__c Where Work_Order_Line_Item__c=: recordId ];


                 


            wrapper.workOrderLineItem = getWorkOrderLineItem;
            wrapper.materialConsumptions = materials;
           wrapper.flatAndPlugDetails =  lstWOLIChild;

    }

    catch(Exception e){

        wrapper.workOrderLineItem = new WorkOrderLineItem();
         wrapper.materialConsumptions = new List<Material_Consumption__c>();
         wrapper.flatAndPlugDetails = new List<WorkOrderLineItem_Child__c>();

    }

        return  wrapper;

}

 public class WorkOrderLineItemWrapper {
        @AuraEnabled public WorkOrderLineItem workOrderLineItem { get; set; }
        @AuraEnabled public List<Material_Consumption__c> materialConsumptions { get; set; }
        @AuraEnabled public List<WorkOrderLineItem_Child__c> flatAndPlugDetails { get; set; }

    }

   

	@AuraEnabled
	public static string updateWOLItem(String recordId, String riserData,List<FileWrapper> listFiles){

		try{

			system.debug('Record id::'+ recordId);

			system.debug('Riser data ::'+ riserData);

			//system.debug('After deserialized ::'+ JSON.deserializeUntyped(riserData);

		  Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(riserData);


			WorkOrderLineItem updateWorkOrderLineItem = [Select Id,WorkOrderId,Riser_Height_Floor_Wise_RM__c,number_of_liv_connectivity_rm__c,
                                            Crimp_guards_replaced_rm__c,Clamps_replaced_rm__c,Number_of_valves_replaced_rm__c,GI_Pipe_Length_Replaced_rm__c,
                                            Number_of_leakages_rm__c,           
                                        Hole_Pieces_Replaced__c,Hole_Pieces_Flat_Numbers__c, Valves_Replaced__c,
                                        Anacondas_Replaced__c,Anacondas_Replaced_Flat_Numbers__c, LIV_Connectivity_Flat_Numbers__c,                                     
										Any_encroached_corrosion_condition__c,Riser_Category__c,Riser_Painting__c,Suspected_Gas_Leakage_In_House_Lock__c,Test_Pressure__c,Duration__c	,	
										Riser_Tested_Status__c,Not_Ok_Remark__c,No_of_active_customers__c,Remark__c,
                                        Leak_Locations_1__c,Leak_Locations_2__c,Leak_Locations_3__c,Leak_Locations_4__c,Leak_Locations_5__c,
										Leak_Locations_6__c,Leak_Locations_7__c,Leak_Locations_8__c,Leak_Locations_9__c,Leak_Locations_10__c,
                                        Valves_Replaced_Location_1__c,Valves_Replaced_Location_2__c,
										Valves_Replaced_Location_3__c,Valves_Replaced_Location_4__c,Valves_Replaced_Location_5__c,Valves_Replaced_Location_6__c,Valves_Replaced_Location_7__c,Valves_Replaced_Location_8__c,
										Valves_Replaced_Location_9__c,Valves_Replaced_Location_10__c,
                                        CopperLeakageFoundNotificationNo__c,CrimpLeakageFoundNotificationNo__c,
                                        Is_Any_Copper_Leakage_Found__c,Is_Any_Crimp_Guard_Leakage_Found__c
                                        					
											from WorkOrderLineItem Where Id=: recordId];

/*
 CopperLeakageFoundNotificationNo__c,CrimpLeakageFoundNotificationNo__c,SRLeakageFountNotificationNo__c,
   Is_Any_Copper_Leakage_Found__c,Is_Any_Crimp_Guard_Leakage_Found__c,Is_Any_SR_Leakage_Found__c	


*/



//updateWorkOrderLineItem.Hole_Pieces_Replaced__c  = dataMap.get('holePiecesReplace') != null ? Decimal.valueOf((String)dataMap.get('holePiecesReplace')) : null;
if (dataMap.containsKey('holePiecesReplace') && dataMap.get('holePiecesReplace') != null) {
    updateWorkOrderLineItem.Hole_Pieces_Replaced__c = 
        Decimal.valueOf(String.valueOf(dataMap.get('holePiecesReplace')));
} else {
    updateWorkOrderLineItem.Hole_Pieces_Replaced__c = null;
}
updateWorkOrderLineItem.Hole_Pieces_Flat_Numbers__c = (String) dataMap.get('holePiecesFlatNumbers');
updateWorkOrderLineItem.Valves_Replaced__c  = (String) dataMap.get('valvesReplaced');
//updateWorkOrderLineItem.Anacondas_Replaced__c = dataMap.get('anacondasReplaced') != null ? Decimal.valueOf((String)dataMap.get('anacondasReplaced')) : null;

updateWorkOrderLineItem.Anacondas_Replaced__c =
    dataMap.get('anacondasReplaced') != null 
        ? Decimal.valueOf(String.valueOf(dataMap.get('anacondasReplaced'))) 
        : null;
updateWorkOrderLineItem.Anacondas_Replaced_Flat_Numbers__c  = (String) dataMap.get('anacondasReplacedFlatNumbers');
//updateWorkOrderLineItem.LIV_Connectivity_with_flat_no__c   = (String) dataMap.get('lIVConnectivitywithflatno');


updateWorkOrderLineItem.LIV_Connectivity_Flat_Numbers__c    = (String) dataMap.get('livConnectivityFlatNumbers');

// new field for number data type store 

updateWorkOrderLineItem.Riser_Height_Floor_Wise_RM__c =    dataMap.get('riserHeightFloorWise') == null ? null :
    (dataMap.get('riserHeightFloorWise') instanceof Decimal
        ? (Decimal)dataMap.get('riserHeightFloorWise')
        : Decimal.valueOf((String)dataMap.get('riserHeightFloorWise')));

    updateWorkOrderLineItem.GI_Pipe_Length_Replaced_rm__c =   dataMap.get('gIPipeLengthReplaced') == null ? null :
    (dataMap.get('gIPipeLengthReplaced') instanceof Decimal
        ? (Decimal)dataMap.get('gIPipeLengthReplaced')
        : Decimal.valueOf((String)dataMap.get('gIPipeLengthReplaced')));



updateWorkOrderLineItem.number_of_liv_connectivity_rm__c	=   dataMap.get('numberoflivconnectivity') == null
    ? null
    : (Decimal)dataMap.get('numberoflivconnectivity');

  updateWorkOrderLineItem.Crimp_guards_replaced_rm__c   =  dataMap.get('crimpGuardsReplaced') == null
    ? null
    : (Decimal)dataMap.get('crimpGuardsReplaced');

updateWorkOrderLineItem.Clamps_replaced_rm__c    = dataMap.get('clampsReplaced') == null
    ? null
    : (Decimal)dataMap.get('clampsReplaced');

    updateWorkOrderLineItem.Number_of_valves_replaced_rm__c  =  dataMap.get('numberOfValvesReplaced') == null || String.isBlank((String)dataMap.get('numberOfValvesReplaced'))
    ? null
    : Decimal.valueOf((String)dataMap.get('numberOfValvesReplaced'));
updateWorkOrderLineItem.Number_of_leakages_rm__c =  dataMap.get('numberofLeakages') == null || String.isBlank((String)dataMap.get('numberofLeakages'))
    ? null
    : Decimal.valueOf((String)dataMap.get('numberofLeakages'));



/* need to uncomment and take input from html
updateWorkOrderLineItem.Number_of_liv_connectivity__c	= (String) dataMap.get('numberoflivconnectivity');
updateWorkOrderLineItem.Crimp_Guards_Replaced__c   = dataMap.get('crimpGuardsReplaced') != null ? String.valueOf(dataMap.get('crimpGuardsReplaced')) : null;
updateWorkOrderLineItem.Clamps_Replaced__c    = dataMap.get('clampsReplaced') != null ? String.valueOf(dataMap.get('clampsReplaced')) : null;
updateWorkOrderLineItem.Number_Of_Valves_Replaced__c  = (String) dataMap.get('numberOfValvesReplaced');
updateWorkOrderLineItem.GI_Pipe_Length_Replaced__c = (String) dataMap.get('gIPipeLengthReplaced');
updateWorkOrderLineItem.Number_of_Leakages__c = (String) dataMap.get('numberofLeakages');

updateWorkOrderLineItem.Riser_Height_Floor_Wise__c = (String) dataMap.get('riserHeightFloorWise');

*/
// updateWorkOrderLineItem.Riser_Height_Floor_Wise__c =
//     dataMap.get('riserHeightFloorWise') != null 
//         ? String.valueOf(dataMap.get('riserHeightFloorWise')) 
//         : null;
updateWorkOrderLineItem.Any_encroached_corrosion_condition__c = (String) dataMap.get('anyencroachedcorrosioncondition');
updateWorkOrderLineItem.Riser_Category__c  = (String) dataMap.get('riserCategory');
updateWorkOrderLineItem.Riser_Painting__c  = (String) dataMap.get('riserPainting');


updateWorkOrderLineItem.Suspected_Gas_Leakage_In_House_Lock__c = (String) dataMap.get('suspectedGasLeakageInHouseLock');
updateWorkOrderLineItem.Test_Pressure__c = (String) dataMap.get('testPressure');
updateWorkOrderLineItem.Duration__c   = (String) dataMap.get('duration');
updateWorkOrderLineItem.Riser_Tested_Status__c = (String) dataMap.get('riserTestedStatus');
updateWorkOrderLineItem.Not_Ok_Remark__c = (String) dataMap.get('notOkRemark');

//updateWorkOrderLineItem.No_of_active_customers__c = dataMap.get('noofactivecustomers') != null ? Decimal.valueOf((String)dataMap.get('noofactivecustomers')) : null;

updateWorkOrderLineItem.No_of_active_customers__c =
    dataMap.get('noofactivecustomers') != null
        ? Integer.valueOf(String.valueOf(dataMap.get('noofactivecustomers')))
        : null;
updateWorkOrderLineItem.Remark__c   = (String) dataMap.get('remark');
// updateWorkOrderLineItem.Instrument_Type_Range__c = (String) dataMap.get('instrumentTypeRange');
// updateWorkOrderLineItem.Calibration_Certificate_No__c = (String) dataMap.get('calibrationCertificateNo');
// updateWorkOrderLineItem.Calibration_Date__c = dataMap.get('calibrationDate') != null ? Date.valueOf((String)dataMap.get('calibrationDate')) : null;
// updateWorkOrderLineItem.Calibration_Due_Date__c = dataMap.get('calibrationDueDate') != null ? Date.valueOf((String)dataMap.get('calibrationDueDate')) : null;


updateWorkOrderLineItem.Is_Any_Copper_Leakage_Found__c = (String) dataMap.get('isanycopperleakagefound');
updateWorkOrderLineItem.Is_Any_Crimp_Guard_Leakage_Found__c = (String) dataMap.get('isanycrimpguardleakagefound');
updateWorkOrderLineItem.CopperLeakageFoundNotificationNo__c	 = (String) dataMap.get('copperLeakageFoundNotificationNo');
updateWorkOrderLineItem.CrimpLeakageFoundNotificationNo__c = (String) dataMap.get('crimpLeakageFoundNotificationNo');

//updateWorkOrderLineItem.SRLeakageFountNotificationNo__c = (String) dataMap.get('srLeakageFountNotificationNo');
//updateWorkOrderLineItem.Is_Any_SR_Leakage_Found__c = (String) dataMap.get('isanySRleakagefound');





 // Handle Leak Locations
if (dataMap.containsKey('leakLocationList') && dataMap.get('leakLocationList') != null) {
    List<Object> leakList = (List<Object>) dataMap.get('leakLocationList');
    System.debug('inside leak location list: ' + leakList);

    for (Integer i = 0; i < 10; i++) {
        String fieldName = 'Leak_Locations_' + (i + 1) + '__c';

        if (i < leakList.size()) {
            Map<String, Object> leakItem = (Map<String, Object>) leakList[i];
            updateWorkOrderLineItem.put(fieldName, String.valueOf(leakItem.get('value')));
        } else {
            // Clear any extra fields beyond the list size
            updateWorkOrderLineItem.put(fieldName, null);
        }
    }
}

// Handle Valves Replaced Locations
if (dataMap.containsKey('valvesReplacedList') && dataMap.get('valvesReplacedList') != null) {
    List<Object> valveList = (List<Object>) dataMap.get('valvesReplacedList');
    System.debug('inside valves replaced list: ' + valveList);

    for (Integer i = 0; i < 10; i++) {
        String fieldName = 'Valves_Replaced_Location_' + (i + 1) + '__c';

        if (i < valveList.size()) {
            Map<String, Object> valveItem = (Map<String, Object>) valveList[i];
            updateWorkOrderLineItem.put(fieldName, String.valueOf(valveItem.get('value')));
        } else {
            // Clear unused fields
            updateWorkOrderLineItem.put(fieldName, null);
        }
    }
}

		update updateWorkOrderLineItem;

		system.debug('Updated workorderlineitem ::'+ updateWorkOrderLineItem);

        system.debug('lstfile data::'+ listFiles);


        	 List<ContentVersion> contentVersions = new List<ContentVersion>();

             System.debug('before lstfile check');

           //  if (listFiles !=null || !listFiles.isEmpty()) {


            
            for (FileWrapper fw : listFiles) {

                if(fw.base64Data !=''){

                      system.debug('inside listfile found');

                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName;
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
            }
            }
            
            insert contentVersions;

			//system.debug('content version::'+ contentVersions);
            
            // Map ContentVersion Id to ContentDocumentId
            Map<Id, Id> versionToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ]) {
                versionToDocMap.put(cv.Id, cv.ContentDocumentId);
            }
            
            // Create ContentDocumentLinks to associate files with the given record
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();
            for (Id versionId : versionToDocMap.keySet()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = versionToDocMap.get(versionId),
                LinkedEntityId = recordId,
                ShareType = 'V', // View permission
                Visibility = 'AllUsers'
                    ));
            }
            
            insert links;


              // String childWOId='';

           List<WorkOrder> childWorkOrderReplacement = [Select Id,ParentWorkOrderId,WorkType.Name from workorder Where ParentWorkOrderId =:updateWorkOrderLineItem.WorkOrderId And worktype.name='Riser Replacement'];

             system.debug('childWorkOrderReplacement::'+ childWorkOrderReplacement.size());

             system.debug('anyencroachedcorrosioncondition::'+ dataMap.get('anyencroachedcorrosioncondition'));

        if((String)dataMap.get('anyencroachedcorrosioncondition') == 'Yes'
           && childWorkOrderReplacement.size() < 1) {

            system.debug('inside anyencroachedcorrosioncondition yes');



            WorkOrder woTag = [Select id,Connection__c from WorkOrder where id=: updateWorkOrderLineItem.WorkOrderId];

            WorkType wType = [Select id from WorkType where Name='Riser Replacement'];

            WorkOrder createdReplacementWO = new WorkOrder();

            createdReplacementWO.ParentWorkOrderId = woTag.Id;
            createdReplacementWO.WorkTypeId = wType.Id;
            createdReplacementWO.Connection__c = woTag.Connection__c;


            insert createdReplacementWO;

            system.debug('Workorder created for riser replacement'+ createdReplacementWO);

            ServiceAppointment serApp = [Select id,ParentRecordId,SchedStartTime,SchedEndTime from ServiceAppointment where ParentRecordId=:createdReplacementWO.Id];

            serApp.SchedStartTime = system.now();

            serApp.SchedEndTime = serApp.SchedStartTime.addDays(3);

            update serApp;

            system.debug('serApp :: '+ serApp);



        }

            	      system.debug('riserPainting::'+ dataMap.get('riserPainting'));

                   List<WorkOrder> childWorkOrderPainting = [Select Id,ParentWorkOrderId,WorkType.Name from workorder Where ParentWorkOrderId =:updateWorkOrderLineItem.WorkOrderId And worktype.name='Riser Painting'];

             system.debug('childWorkOrder::'+ childWorkOrderPainting.size());


          if((String)dataMap.get('riserPainting') == 'Yes' && childWorkOrderPainting.size() < 1) {

            system.debug('inside riserPainting yes');

            WorkOrder woTag = [Select id,Connection__c from WorkOrder where id=: updateWorkOrderLineItem.WorkOrderId];

            WorkType wType = [Select id from WorkType where Name='Riser Painting'];

            WorkOrder createdPaintingWO = new WorkOrder();

            createdPaintingWO.ParentWorkOrderId = woTag.Id;
            createdPaintingWO.WorkTypeId = wType.Id;
            createdPaintingWO.Connection__c = woTag.Connection__c;


            insert createdPaintingWO;

            system.debug('Workorder created for riser painting'+ createdPaintingWO);

            ServiceAppointment serApp = [Select id,ParentRecordId,SchedStartTime,SchedEndTime from ServiceAppointment where ParentRecordId=:createdPaintingWO.Id];

            serApp.SchedStartTime = system.now();

            serApp.SchedEndTime = serApp.SchedStartTime.addDays(3);

            update serApp;

            system.debug('serApp :: '+ serApp);



        }
             

			//system.debug('Document link:: '+ links);

			return 'Success';

		}
		catch(Exception e){

            AS_ErrorLogger.log('RiserDetailsForRiserMaintenanceContr', 'updateWOLItem', e, recordId);


			system.debug('Error updating workorderlineitem ::'+ e.getMessage() + e.getLineNumber());

			return 'Error';
		}


}

public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }

 @AuraEnabled
    public static void materialConsumption(String recordId,  List<MaterialWrapper> materialList){


        try {

            system.debug('inside material consumption');

          List<Material_Consumption__c> lstMaterConsumption = new List<Material_Consumption__c>();

          List<Material_Consumption__c> lstMaterialConsumption = [Select id,Material_Row_Number__c from Material_Consumption__c Where Work_Order_Line_Item__c=: recordId ];

        Set<string> uniqueRowNumber = new Set<String>();

        for(Material_Consumption__c matCons : lstMaterialConsumption){

            uniqueRowNumber.add(matCons.Material_Row_Number__c);
        }

        for (MaterialWrapper wrapper : materialList) {
            System.debug('Processing MaterialWrapper: ' + JSON.serializePretty(wrapper));

          if (!uniqueRowNumber.contains(String.valueOf(wrapper.rowNumber))) {
            
            Material_Consumption__c record = new Material_Consumption__c(
                Work_Order_Line_Item__c = recordId,
                Item_Code_Riser_Activity__c = wrapper.itemCode,
                Item_Description_Riser_Activity__c = wrapper.itemDescription,
                Quantity__c	 = wrapper.quantity,
                 Material_Row_Number__c	= string.valueOf(wrapper.rowNumber)

            );
            lstMaterConsumption.add(record);
          }else {

            System.debug('Skipping rowNumber ' + wrapper.rowNumber + ' as it already exists.');

          }


         


        }

        if (!lstMaterConsumption.isEmpty()) {
            insert lstMaterConsumption;
            System.debug('Inserted Material Consumption records: ' + lstMaterConsumption);
        }

         List<Material_Consumption__c> existingRecords = [SELECT Id, Material_Row_Number__c 
                                                            FROM Material_Consumption__c 
                                                            WHERE Work_Order_Line_Item__c = :recordId
                                                            ];

                Set<String> currentRowNumbers = new Set<String>();
                for (MaterialWrapper wrapperMaDe : materialList) {
                    currentRowNumbers.add(String.valueOf(wrapperMaDe.rowNumber));
                }

                Set<String> existingRowNumbers = new Set<String>();
                for (Material_Consumption__c mc : existingRecords) {
                    existingRowNumbers.add(mc.Material_Row_Number__c);
                }

                List<Material_Consumption__c> recordsToDelete = new List<Material_Consumption__c>();
                for (Material_Consumption__c mc : existingRecords) {
                    if (!currentRowNumbers.contains(mc.Material_Row_Number__c)) {
                        recordsToDelete.add(mc);
                    }
                }

                if (!recordsToDelete.isEmpty()) {
                    delete recordsToDelete;
                }

                 if (materialList == null || materialList.isEmpty()) {
        // List<Material__c> existingMaterials = [
        //     SELECT Id FROM Material__c WHERE WorkOrderLineItem__c = :recordId
        // ];
        if (!lstMaterialConsumption.isEmpty()) {
            delete lstMaterialConsumption;
        }
        
    }

        }

           catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        }


    }

    public class MaterialWrapper {
               
        @AuraEnabled public Integer rowNumber{get;set;}

         @AuraEnabled public String itemCode{get;set;}
        @AuraEnabled public String itemDescription{get;set;}
        @AuraEnabled public Integer quantity{get;set;} 
    }

     @AuraEnabled
    public static void flatNumberAndLivPlug(String recordId,  List<FlatNumberAndLivPlugWrapper> flatNumberAndLivPlug){


        try {

          List<WorkOrderLineItem_Child__c> lstWOLIChild = new List<WorkOrderLineItem_Child__c>();

         List<WorkOrderLineItem_Child__c> lstWOLItemChild = [Select id,WOLItemChild_Row_Number__c,Work_Order_Line_Item__c
                                                                      from WorkOrderLineItem_Child__c Where
                                                                       Work_Order_Line_Item__c=: recordId ];

        Set<string> uniqueRowNumber = new Set<String>();

        for(WorkOrderLineItem_Child__c woliC : lstWOLItemChild){

            uniqueRowNumber.add(woliC.WOLItemChild_Row_Number__c);
        }


        for (FlatNumberAndLivPlugWrapper wrapper : flatNumberAndLivPlug) {
            System.debug('Processing flat number and liv plug : ' + JSON.serializePretty(wrapper));

            if (!uniqueRowNumber.contains(String.valueOf(wrapper.rowNumber))) {

            
            WorkOrderLineItem_Child__c record = new WorkOrderLineItem_Child__c(
                Work_Order_Line_Item__c = recordId,
                Flat_Number__c = wrapper.flatNumber,
                Liv_Plug_Status__c = wrapper.livPlugStatus,
                WOLItemChild_Row_Number__c	= string.valueOf(wrapper.rowNumber)

            );
            lstWOLIChild.add(record);
            }else {

            System.debug('Skipping rowNumber ' + wrapper.rowNumber + ' as it already exists.');

          }

        }

        if (!lstWOLIChild.isEmpty()) {
            insert lstWOLIChild;
            System.debug('Inserted workorderlineitemchild records: ' + lstWOLIChild);
        }

        List<WorkOrderLineItem_Child__c> existingRecords = [SELECT Id, WOLItemChild_Row_Number__c 
                                                            FROM WorkOrderLineItem_Child__c 
                                                            WHERE Work_Order_Line_Item__c = :recordId
                                                            ];

                Set<String> currentRowNumbers = new Set<String>();
                for (FlatNumberAndLivPlugWrapper wrapperWChild : flatNumberAndLivPlug) {
                    currentRowNumbers.add(String.valueOf(wrapperWChild.rowNumber));
                }

                Set<String> existingRowNumbers = new Set<String>();
                for (WorkOrderLineItem_Child__c mc : existingRecords) {
                    existingRowNumbers.add(mc.WOLItemChild_Row_Number__c);
                }

                List<WorkOrderLineItem_Child__c> recordsToDelete = new List<WorkOrderLineItem_Child__c>();
                for (WorkOrderLineItem_Child__c flatAndPlug : existingRecords) {
                    if (!currentRowNumbers.contains(flatAndPlug.WOLItemChild_Row_Number__c)) {
                        recordsToDelete.add(flatAndPlug);
                    }
                }

                if (!recordsToDelete.isEmpty()) {
                    delete recordsToDelete;
                }

        }

           catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        }


    }

     public class FlatNumberAndLivPlugWrapper {

         @AuraEnabled public Integer rowNumber{get;set;}

         @AuraEnabled public String flatNumber{get;set;}
        @AuraEnabled public String livPlugStatus{get;set;}
    }


}