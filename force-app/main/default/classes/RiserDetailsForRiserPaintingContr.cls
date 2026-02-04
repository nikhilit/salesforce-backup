/**
* @File Name : RiserDetailsForRiserPaintingContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 17, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 17, 2025 |   | Initial Version
**/

public without sharing class RiserDetailsForRiserPaintingContr {
	

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



         WorkOrderLineItem getWorkOrderLineItem = [Select Id,Riser_Category__c,
         //Clamps_Replaced__c,
         //Crimp_Guards_Replaced__c,
		 										Length_Painted_Primer__c,Length_Painted_Yellow__c,Length_Painted_Yellow_3__c,
												DFT_Reading_Primer__c,DFT_Reading_Yellow__c,DFT_Reading_Yellow_3__c,
                                               Leakage_Locations_RiserPainting__c,
                                                        No_of_leakages_RiserPainting__c,Floor_No_RiserPainting__c,Riser_Height_RiserPainting__c	
		  	
		 												from WorkOrderLineItem where Id=: recordId];

                                     /* Instrument_Type_Range__c,Calibration_Certificate_No__c,
										                Calibration_Date__c,Calibration_Due_Date__c,Instrument_Serial_Number__c,


                                     */                   


     List<Material_Consumption__c> materials = [
                SELECT Id,
                       Work_Order_Line_Item__c,Item_Code_Riser_Activity__c,Item_Description_Riser_Activity__c,
                       Quantity__c,Material_Row_Number__c
                FROM Material_Consumption__c
                WHERE Work_Order_Line_Item__c = :recordId
            ];


            // List<WorkOrderLineItem_Child_2__c> workOrderLineItemChild2 = [Select id,No_Of_Leakages__c,Work_Order_Line_Item__c,Leakage_Locations__c,Leakage_Row_Number__c
                
            //                                                                             from WorkOrderLineItem_Child_2__c where Work_Order_Line_Item__c =:recordId];

            // List<WorkOrderLineItem_Child__c> lstWOLItemChild = [Select Id,Floor_Number__c,Riser_Height__c,
            //                                                     WOLItemChild_Row_Number__c from WorkOrderLineItem_Child__c 
            //                                                     where Work_Order_Line_Item__c =:recordId];




            wrapper.workOrderLineItem = getWorkOrderLineItem;
            wrapper.materialConsumptions = materials;
          //  wrapper.wolitemChild2 = workOrderLineItemChild2;
          //  wrapper.wolitemChild = lstWOLItemChild;

    }

    catch(Exception e){

        wrapper.workOrderLineItem = new WorkOrderLineItem();
         wrapper.materialConsumptions = new List<Material_Consumption__c>();
        // wrapper.wolitemChild2 = new List<WorkOrderLineItem_Child_2__c>();
       // wrapper.wolitemChild = new List<WorkOrderLineItem_Child__c>();


    }

        return  wrapper;

}

 public class WorkOrderLineItemWrapper {
        @AuraEnabled public WorkOrderLineItem workOrderLineItem { get; set; }
        @AuraEnabled public List<Material_Consumption__c> materialConsumptions { get; set; }
      //  @AuraEnabled public List<WorkOrderLineItem_Child_2__c> wolitemChild2 { get; set; }
      //  @AuraEnabled public List<WorkOrderLineItem_Child__c> wolitemChild { get; set; }

    }


@AuraEnabled
public static string getNumberOfRisersWO(String recordId){

    try {

    WorkOrderLineItem wolineItem = [select Id,WorkOrder.Number_of_Risers__c from workorderlineitem where Id=: recordId];
   
    return  wolineItem.WorkOrder.Number_of_Risers__c;
   
    }

    catch(Exception e){

        system.debug('Error ::'+ e.getLineNumber() + e.getMessage());

        return 'Error';
    }

}

@AuraEnabled
public static void savePaintingNotPossible(string recordId, string paintingNotPossibleRemark ){

    try{

        WorkOrderLineItem wolItemUpdate = [Select id,Is_Riser_Painting_Possible__c,Riser_Painting_Not_Possible_Remark__c from workorderLineItem where id=: recordId limit 1];

       wolItemUpdate.Is_Riser_Painting_Possible__c='No';
        wolItemUpdate.Riser_Painting_Not_Possible_Remark__c=paintingNotPossibleRemark;

        update wolItemUpdate;

    }
    catch(Exception e){

        system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
    }
}

@AuraEnabled
public static void updateWOLItemRiserPainting(String recordId, String riserPainting,List<FileWrapper> listFiles){

try {

	system.debug('inside update wolitem riser painting ::'+ recordId);

		 Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(riserPainting);

		 WorkOrderLineItem updateWorkOrderLineItem = [Select Id,Riser_Category__c,
         //Clamps_Replaced__c,
         //Crimp_Guards_Replaced__c,
		 										Length_Painted_Primer__c,Length_Painted_Yellow__c,Length_Painted_Yellow_3__c,
												DFT_Reading_Primer__c,DFT_Reading_Yellow__c,DFT_Reading_Yellow_3__c,
                                                Leakage_Locations_RiserPainting__c,
                                                        No_of_leakages_RiserPainting__c,Floor_No_RiserPainting__c,Riser_Height_RiserPainting__c,
                                                        Is_Riser_Painting_Possible__c
		  	
		 														from WorkOrderLineItem where Id=: recordId];

                       /*Instrument_Type_Range__c,Calibration_Certificate_No__c,
										                Calibration_Date__c,Calibration_Due_Date__c,Instrument_Serial_Number__c,

                       */                                         

updateWorkOrderLineItem.Is_Riser_Painting_Possible__c ='Yes';
updateWorkOrderLineItem.Riser_Category__c = (String) dataMap.get('riserCategory');
//need to uncomment this
//updateWorkOrderLineItem.Crimp_Guards_Replaced__c   = dataMap.get('noofCrimpGuardsReplaced') != null ? String.valueOf(dataMap.get('noofCrimpGuardsReplaced')) : null;
//updateWorkOrderLineItem.Clamps_Replaced__c    = dataMap.get('noOfClampsReplaced') != null ? String.valueOf(dataMap.get('noOfClampsReplaced')) : null;


updateWorkOrderLineItem.Length_Painted_Primer__c = (String) dataMap.get('lengthPaintedPrimer');
updateWorkOrderLineItem.DFT_Reading_Primer__c = (String) dataMap.get('dFTReadingPrimer');


updateWorkOrderLineItem.Length_Painted_Yellow__c  = (String) dataMap.get('lengthPaintedYellow');
updateWorkOrderLineItem.DFT_Reading_Yellow__c = (String) dataMap.get('dFTReadingYellow');

updateWorkOrderLineItem.Length_Painted_Yellow_3__c  = (String) dataMap.get('lengthPaintedYellow3');
updateWorkOrderLineItem.DFT_Reading_Yellow_3__c = (String) dataMap.get('dFTReadingYellow3');
updateWorkOrderLineItem.No_of_leakages_RiserPainting__c = (String) dataMap.get('noOfLeakages');
updateWorkOrderLineItem.Leakage_Locations_RiserPainting__c = (String) dataMap.get('leakageLocations');

updateWorkOrderLineItem.Floor_No_RiserPainting__c = (String) dataMap.get('floorNumber');
updateWorkOrderLineItem.Riser_Height_RiserPainting__c = (String) dataMap.get('riserHeight');


// updateWorkOrderLineItem.Instrument_Type_Range__c = (String) dataMap.get('instrumentTypeRange');
// updateWorkOrderLineItem.Calibration_Certificate_No__c = (String) dataMap.get('calibrationCertificateNo');
// updateWorkOrderLineItem.Calibration_Date__c = dataMap.get('calibrationDate') != null ? Date.valueOf((String)dataMap.get('calibrationDate')) : null;
// updateWorkOrderLineItem.Calibration_Due_Date__c = dataMap.get('calibrationDueDate') != null ? Date.valueOf((String)dataMap.get('calibrationDueDate')) : null;
// updateWorkOrderLineItem.Instrument_Serial_Number__c = (String) dataMap.get('instrumentSerialNumber');


update updateWorkOrderLineItem;

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


    }

    public class MaterialWrapper {

         @AuraEnabled public Integer rowNumber{get;set;}
         @AuraEnabled public String itemCode{get;set;}
        @AuraEnabled public String itemDescription{get;set;}
        @AuraEnabled public Integer quantity{get;set;} 
    }

	/*
    @AuraEnabled
     public static void floorNumberAndRiserHeightDetails(String recordId,  List<FloorNumberAndRiserHeightWrapper> floorNumberAndRiserHeight){


         try {

          List<WorkOrderLineItem_Child__c> lstWOLIChild = new List<WorkOrderLineItem_Child__c>();

         List<WorkOrderLineItem_Child__c> lstWOLItemChild = [Select id,WOLItemChild_Row_Number__c,Work_Order_Line_Item__c
                                                                      from WorkOrderLineItem_Child__c Where
                                                                       Work_Order_Line_Item__c=: recordId ];

        Set<string> uniqueRowNumber = new Set<String>();

        for(WorkOrderLineItem_Child__c woliC : lstWOLItemChild){

            uniqueRowNumber.add(woliC.WOLItemChild_Row_Number__c);
        }


        for (FloorNumberAndRiserHeightWrapper wrapper : floorNumberAndRiserHeight) {
            System.debug('Processing flat number and liv plug : ' + JSON.serializePretty(wrapper));

            if (!uniqueRowNumber.contains(String.valueOf(wrapper.rowNumber))) {

            
            WorkOrderLineItem_Child__c record = new WorkOrderLineItem_Child__c(
                Work_Order_Line_Item__c = recordId,
               Floor_Number__c = wrapper.floorNumber,
                Riser_Height__c	 = wrapper.riserHeight,
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
                for (FloorNumberAndRiserHeightWrapper wrapperWChild : floorNumberAndRiserHeight) {
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

     public class FloorNumberAndRiserHeightWrapper {

          @AuraEnabled public Integer rowNumber{get;set;}

         @AuraEnabled public String floorNumber{get;set;}
        @AuraEnabled public String riserHeight{get;set;}
    } */


	 /* add leakage location code 
      @AuraEnabled
    public static void noOfLeakageAndLeakLocations(String recordId,  List<NoOfLeakageAndLeakLocationsWrapper> noOfLeakagesLeakageLocations){

          try {

          List<WorkOrderLineItem_Child_2__c> lstWOLIChild = new List<WorkOrderLineItem_Child_2__c>();

         List<WorkOrderLineItem_Child_2__c> lstWOLItemChild = [Select id,Leakage_Row_Number__c,Work_Order_Line_Item__c
                                                                      from WorkOrderLineItem_Child_2__c Where
                                                                       Work_Order_Line_Item__c=: recordId ];

        Set<string> uniqueRowNumber = new Set<String>();

        for(WorkOrderLineItem_Child_2__c woliC : lstWOLItemChild){

            uniqueRowNumber.add(woliC.Leakage_Row_Number__c);
        }


        for (NoOfLeakageAndLeakLocationsWrapper wrapper : noOfLeakagesLeakageLocations) {
            System.debug('Processing flat number and liv plug : ' + JSON.serializePretty(wrapper));

            if (!uniqueRowNumber.contains(String.valueOf(wrapper.rowNumber))) {

            
            WorkOrderLineItem_Child_2__c record = new WorkOrderLineItem_Child_2__c(
                Work_Order_Line_Item__c = recordId,
                No_Of_Leakages__c	 = wrapper.noOfLeakages,
                Leakage_Locations__c = wrapper.leakageLocations,
                Leakage_Row_Number__c = string.valueOf(wrapper.rowNumber)

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

        List<WorkOrderLineItem_Child_2__c> existingRecords = [SELECT Id,Leakage_Row_Number__c 
                                                            FROM WorkOrderLineItem_Child_2__c 
                                                            WHERE Work_Order_Line_Item__c = :recordId
                                                            ];

                Set<String> currentRowNumbers = new Set<String>();
                for (NoOfLeakageAndLeakLocationsWrapper wrapperWChild : noOfLeakagesLeakageLocations) {
                    currentRowNumbers.add(String.valueOf(wrapperWChild.rowNumber));
                }

                Set<String> existingRowNumbers = new Set<String>();
                for (WorkOrderLineItem_Child_2__c mc : existingRecords) {
                    existingRowNumbers.add(mc.Leakage_Row_Number__c);
                }

                List<WorkOrderLineItem_Child_2__c> recordsToDelete = new List<WorkOrderLineItem_Child_2__c>();
                for (WorkOrderLineItem_Child_2__c flatAndPlug : existingRecords) {
                    if (!currentRowNumbers.contains(flatAndPlug.Leakage_Row_Number__c)) {
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

     public class NoOfLeakageAndLeakLocationsWrapper {

         @AuraEnabled public Integer rowNumber{get;set;}

         @AuraEnabled public String noOfLeakages{get;set;}
        @AuraEnabled public String leakageLocations{get;set;}
    } 

    */



}