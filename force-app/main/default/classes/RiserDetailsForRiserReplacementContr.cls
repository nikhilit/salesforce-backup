/**
* @File Name : RiserDetailsForRiserReplacementContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 19, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 19, 2025 |   | Initial Version
**/

public without sharing class RiserDetailsForRiserReplacementContr {
		

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



         WorkOrderLineItem getWorkOrderLineItem = [Select Id, Clamps_Replaced__c, Crimp_Guards_Replaced__c,
		 										GI_pipe_fabrication_length__c,GI_pipe_erection_length__c,Length_of_Riser_Tested__c,
												Number_of_Leakages__c,
                                                Leak_Locations_1__c,Leak_Locations_2__c,Leak_Locations_3__c,
												Leak_Locations_4__c,Leak_Locations_5__c,Leak_Locations_6__c,Leak_Locations_7__c,
												Leak_Locations_8__c,Leak_Locations_9__c,Leak_Locations_10__c,Length_of_Riser_Commissioned__c,
												Riser_Length__c,Riser_Painting__c,Riser_Painted_Length__c,No_Of_Lateral_Replacement_Done__c,
                                                Instrument_Type_Range__c,Calibration_Certificate_No__c,
										                Calibration_Date__c,Calibration_Due_Date__c,Instrument_Serial_Number__c,
                                                        Test_Pressure__c,Duration__c,
                                                        Riser_Tested_Status__c,No_of_active_customers__c,Remark__c 
		  	
		 														from WorkOrderLineItem where Id=: recordId];

     List<Material_Consumption__c> materials = [
                SELECT Id,
                       Work_Order_Line_Item__c,Item_Code_Riser_Activity__c,Item_Description_Riser_Activity__c,
                       Quantity__c,Material_Row_Number__c
                FROM Material_Consumption__c
                WHERE Work_Order_Line_Item__c = :recordId
            ];


            List<WorkOrderLineItem_Child_2__c> workOrderLineItemChild2 = [Select id,No_Of_Leakages__c,Work_Order_Line_Item__c,Leakage_Locations__c,Leakage_Row_Number__c
                
                                                                                        from WorkOrderLineItem_Child_2__c where Work_Order_Line_Item__c =:recordId];


            wrapper.workOrderLineItem = getWorkOrderLineItem;
            wrapper.materialConsumptions = materials;
            wrapper.wolitemChild2 = workOrderLineItemChild2;

    }

    catch(Exception e){

        wrapper.workOrderLineItem = new WorkOrderLineItem();
         wrapper.materialConsumptions = new List<Material_Consumption__c>();
    wrapper.wolitemChild2 = new List<WorkOrderLineItem_Child_2__c>();

    }

        return  wrapper;

}

 public class WorkOrderLineItemWrapper {
        @AuraEnabled public WorkOrderLineItem workOrderLineItem { get; set; }
        @AuraEnabled public List<Material_Consumption__c> materialConsumptions { get; set; }
        @AuraEnabled public List<WorkOrderLineItem_Child_2__c> wolitemChild2 { get; set; }

    }



@AuraEnabled
public static void updateWOLItemRiserReplacement(String recordId, String riserReplacement,List<FileWrapper> listFiles){

try {

	system.debug('inside update wolitem riser painting ::'+ recordId);

		 Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(riserReplacement);

		 WorkOrderLineItem updateWorkOrderLineItem = [Select Id, Clamps_Replaced__c, Crimp_Guards_Replaced__c,
		 										GI_pipe_fabrication_length__c,GI_pipe_erection_length__c,Length_of_Riser_Tested__c,
												Number_of_Leakages__c,
                                                Leak_Locations_1__c,Leak_Locations_2__c,Leak_Locations_3__c,
												Leak_Locations_4__c,Leak_Locations_5__c,Leak_Locations_6__c,Leak_Locations_7__c,
												Leak_Locations_8__c,Leak_Locations_9__c,Leak_Locations_10__c,Length_of_Riser_Commissioned__c,
												Riser_Length__c,Riser_Painting__c,Riser_Painted_Length__c,No_Of_Lateral_Replacement_Done__c,
                                                Instrument_Type_Range__c,Calibration_Certificate_No__c,
										                Calibration_Date__c,Calibration_Due_Date__c,Instrument_Serial_Number__c,Test_Pressure__c,Duration__c,
                                                        Riser_Tested_Status__c,No_of_active_customers__c,Remark__c 
		  	
		 														from WorkOrderLineItem where Id=: recordId];




updateWorkOrderLineItem.GI_pipe_fabrication_length__c    = dataMap.get('giPipeFabricationlength') != null ? String.valueOf(dataMap.get('giPipeFabricationlength')) : null;
updateWorkOrderLineItem.GI_pipe_erection_length__c   = dataMap.get('gipipeerectionlength') != null ? String.valueOf(dataMap.get('gipipeerectionlength')) : null;


updateWorkOrderLineItem.Length_of_Riser_Tested__c = (String) dataMap.get('lengthofRiserTested');


updateWorkOrderLineItem.Length_of_Riser_Commissioned__c  = (String) dataMap.get('lengthofRiserCommissioned');
updateWorkOrderLineItem.Riser_Length__c = (String) dataMap.get('riserLength');
updateWorkOrderLineItem.Riser_Painting__c  = (String) dataMap.get('riserPainting');

updateWorkOrderLineItem.Riser_Painted_Length__c = (String) dataMap.get('riserPaintedLength');

updateWorkOrderLineItem.Crimp_Guards_Replaced__c = (String) dataMap.get('numberofCrimpGuardstobeReplaced');
updateWorkOrderLineItem.Clamps_Replaced__c = (String) dataMap.get('numberofClampstobeReplaced');
updateWorkOrderLineItem.Number_of_Leakages__c = (String) dataMap.get('numberofleakage');

updateWorkOrderLineItem.No_Of_Lateral_Replacement_Done__c = (String) dataMap.get('numberOfLateralReplacementsDone');


updateWorkOrderLineItem.Instrument_Type_Range__c = (String) dataMap.get('instrumentTypeRange');
updateWorkOrderLineItem.Calibration_Certificate_No__c = (String) dataMap.get('calibrationCertificateNo');
updateWorkOrderLineItem.Calibration_Date__c = dataMap.get('calibrationDate') != null ? Date.valueOf((String)dataMap.get('calibrationDate')) : null;
updateWorkOrderLineItem.Calibration_Due_Date__c = dataMap.get('calibrationDueDate') != null ? Date.valueOf((String)dataMap.get('calibrationDueDate')) : null;
updateWorkOrderLineItem.Instrument_Serial_Number__c	 = (String) dataMap.get('instrumentSerialNumber');


updateWorkOrderLineItem.Test_Pressure__c = (String) dataMap.get('testPressure');
updateWorkOrderLineItem.Duration__c   = (String) dataMap.get('duration');
updateWorkOrderLineItem.Riser_Tested_Status__c = (String) dataMap.get('riserTestedStatus');

updateWorkOrderLineItem.No_of_active_customers__c = dataMap.get('noofactivecustomers') != null ? Decimal.valueOf((String)dataMap.get('noofactivecustomers')) : null;
updateWorkOrderLineItem.Remark__c   = (String) dataMap.get('remark');


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

update updateWorkOrderLineItem;



/*
 if (dataMap.containsKey('riserPainting') && String.valueOf(dataMap.get('riserPainting')) == 'Yes') {

        system.debug('inside if conditon true');

       WorkOrderLineItem woId = [Select id,WorkOrderId from WorkOrderLineItem where id=: recordId];

        WorkType woType = [Select id,name from WorkType where name='Riser Painting'];

        system.debug('worderorderid from wolitem ::'+ woId.WorkOrderId);

        system.debug('work type::'+ woType);

        List<WorkOrder> countWO = [select id,ParentWorkOrderId from workorder where ParentWorkOrderId =: woId.WorkOrderId ];

        if(countWO.size() < 1){

         Id woOMRecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('MGL O&M').getRecordTypeId();

       
        WorkOrder wo = new WorkOrder();

        wo.ParentWorkOrderId = woId.WorkOrderId;
        wo.WorkTypeId = woType.Id;
        wo.RecordTypeId =woOMRecordTypeId;

        insert wo;

        system.debug('child workorder created::'+ wo);

        ServiceAppointment serAppUpdate = [Select id,ParentRecordId,SchedStartTime,SchedEndTime from ServiceAppointment where ParentRecordId=: wo.Id];


        serAppUpdate.SchedStartTime=System.now();
        serAppUpdate.SchedEndTime=serAppUpdate.SchedStartTime.addDays(3);

        update serAppUpdate;

        system.debug('serviceappointment updated::'+ serAppUpdate);
        }

     } */

   List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {

                  if(fw.base64Data !=''){

              system.debug('inside listfile found');
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
            }
            }
            
            insert contentVersions;
            
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

        
        

    //  if (dataMap.containsKey('riserPainting') && String.valueOf(dataMap.get('riserPainting')) == 'Yes') {

    //     system.debug('inside if conditon true');

    //    WorkOrderLineItem woId = [Select id,WorkOrderId from WorkOrderLineItem where id=: recordId];

    //     WorkType woType = [Select id,name from WorkType where name='Riser Painting'];

    //     system.debug('worderorderid from wolitem ::'+ woId.WorkOrderId);

    //     system.debug('work type::'+ woType);
       
    //     WorkOrder wo = new WorkOrder();

    //     wo.ParentWorkOrderId = woId.WorkOrderId;
    //     wo.WorkTypeId = woType.Id;

    //     insert wo;

    //     system.debug('child workorder created::'+ wo);

    //     ServiceAppointment serAppUpdate = [Select id,ParentRecordId,SchedStartTime,SchedEndTime from ServiceAppointment where ParentRecordId=: wo.Id];


    //     serAppUpdate.SchedStartTime=System.now();
    //     serAppUpdate.SchedEndTime=serAppUpdate.SchedStartTime.addDays(3);

    //     update serAppUpdate;

    //     system.debug('serviceappointment updated::'+ serAppUpdate);

    //  }
										

}

catch(Exception e){

	system.debug('Error update wolItem riser painting::'+ e.getLineNumber() + e.getMessage());
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
      
                    if (!lstMaterialConsumption.isEmpty()) {
                        delete lstMaterialConsumption;
                    }
        
                  }

        }

           catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        }



     /*   try {

          List<Material_Consumption__c> lstMaterConsumption = new List<Material_Consumption__c>();


        for (MaterialWrapper wrapper : materialList) {
            System.debug('Processing MaterialWrapper: ' + JSON.serializePretty(wrapper));
            
            Material_Consumption__c record = new Material_Consumption__c(
                Work_Order_Line_Item__c = recordId,
                Item_Code_Riser_Activity__c = wrapper.itemCode,
                Item_Description_Riser_Activity__c = wrapper.itemDescription,
                Quantity__c	 = wrapper.quantity,
               Material_Row_Number__c	= string.valueOf(wrapper.rowNumber)

            );
            lstMaterConsumption.add(record);

        }

        if (!lstMaterConsumption.isEmpty()) {
            insert lstMaterConsumption;
            System.debug('Inserted Material Consumption records: ' + lstMaterConsumption);
        }

        }

           catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        } */


    }

    public class MaterialWrapper {

        @AuraEnabled public Integer rowNumber{get;set;}
         @AuraEnabled public String itemCode{get;set;}
        @AuraEnabled public String itemDescription{get;set;}
        @AuraEnabled public Integer quantity{get;set;} 
    }

	  @AuraEnabled
    public static void floorNumberAndRiserHeightDetails(String recordId,  List<FloorNumberAndRiserHeightWrapper> floorNumberAndRiserHeight){


        try {

          List<WorkOrderLineItem_Child__c> lstWOLIChild = new List<WorkOrderLineItem_Child__c>();


        for (FloorNumberAndRiserHeightWrapper wrapper : floorNumberAndRiserHeight) {

            System.debug('Processing floor number and riser height : ' + JSON.serializePretty(wrapper));
            
            WorkOrderLineItem_Child__c  record = new WorkOrderLineItem_Child__c(
                Work_Order_Line_Item__c = recordId,
                Floor_Number__c = wrapper.floorNumber,
                Riser_Height__c	 = wrapper.riserHeight
            );
            lstWOLIChild.add(record);

        }

        if (!lstWOLIChild.isEmpty()) {
            insert lstWOLIChild;
            System.debug('Inserted workorderlineitemchild records: ' + lstWOLIChild);
        }

        }

           catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        }


    }

     public class FloorNumberAndRiserHeightWrapper {
         @AuraEnabled public String floorNumber{get;set;}
        @AuraEnabled public String riserHeight{get;set;}
    }


	  @AuraEnabled
    public static void noOfLeakageAndLeakLocations(String recordId,  List<NoOfLeakageAndLeakLocationsWrapper> noOfLeakagesLeakageLocations){


        try {

          List<WorkOrderLineItem_Child_2__c> lstWOLIChild = new List<WorkOrderLineItem_Child_2__c>();


        for (NoOfLeakageAndLeakLocationsWrapper wrapper : noOfLeakagesLeakageLocations) {

            System.debug('Processing no of leakage and leakage locations : ' + JSON.serializePretty(wrapper));
            
            WorkOrderLineItem_Child_2__c  record = new WorkOrderLineItem_Child_2__c(
                Work_Order_Line_Item__c = recordId,
                No_Of_Leakages__c	 = wrapper.noOfLeakages,
                Leakage_Locations__c = wrapper.leakageLocations
            );
            lstWOLIChild.add(record);

        }

        if (!lstWOLIChild.isEmpty()) {
            insert lstWOLIChild;
            System.debug('Inserted workorderlineitemchild records: ' + lstWOLIChild);
        }

        }

           catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        }


    }

     public class NoOfLeakageAndLeakLocationsWrapper {
         @AuraEnabled public String noOfLeakages{get;set;}
        @AuraEnabled public String leakageLocations{get;set;}
    }



}