/**
* @File Name : RiserDetailsCaptureContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : May 15, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 15, 2025 |   | Initial Version
**/

public without sharing class RiserDetailsCaptureContr {
	
	@AuraEnabled
	public static void createMaintenanceEntryAndDetailsRecord(string recordId, List<MaintenanceEntryWrapper> riserDetails, Decimal riserNumber, String sampleBP1, String sampleBP2, String boardAvailable, String risersFloors, String riserPickListValue, String newInformationBoarInstalled){

        try { 

                   system.debug('Riser details::'+ riserDetails);
            system.debug('Riser number::'+ riserNumber);

          

        Maintenance_Entry__c mEntry = new Maintenance_Entry__c();
        mEntry.Number_of_Risers__c=riserNumber;
        mEntry.Sample_BP_Number_1__c = sampleBP1;
        mEntry.Sample_BP_Number_2__c = sampleBP2;
        mEntry.Information_Board_available__c = boardAvailable;
        mEntry.Number_of_Floors__c = Decimal.valueOf(risersFloors);
        mEntry.Type_of_Riser__c = riserPickListValue;
        mEntry.New_information_boar_installed__c = newInformationBoarInstalled;

       // mEntry.Type_of_Riser__c=String.isNotBlank(riserType) ? riserType : '';
        mEntry.Work_Order__c = recordId;

        insert mEntry;

        system.debug('Riser entry created::'+ mEntry);



        List<Maintainence_Detail__c> lstMaintainenceDetails = new List<Maintainence_Detail__c>();
        
		 for (MaintenanceEntryWrapper r : riserDetails) {

            Maintainence_Detail__c entry = new Maintainence_Detail__c();
            entry.Maintenance_Entry__c=mEntry.Id;
          //  entry.Name = r.name;
           entry.Main_or_Approach_Riser__c = r.riserCategory;
            entry.Riser_Tested_Not_Ok_Remark__c = r.notOkRemark;

           entry.Anacondas_Replaced__c = r.anacondasReplaced;
            entry.Crimp_Guards_Replaced__c = r.crimpGuardsReplaced;
           entry.Encroached_Corrosion__c = r.anyencroachedcorrosioncondition;
            entry.Gas_Leak_Lock_Case__c = r.suspectedGasLeakageInHouseLock;
            entry.GI_Pipe_Length_Replaced__c = r.gIPipeLengthReplaced;
            entry.Hole_Pieces_Replaced__c = r.holePiecesReplace;
          //  entry.Leak_Locations__c = r.leakLocations;
            entry.LIV_Connectivity__c = r.lIVConnectivitywithflatno;
           // entry.Active_Connections__c	 = r.activeConnections;
          //  entry.New_Materials_Used__c = r.newMaterialsUsed;
            entry.Number_of_Clamps_Replaced__c = r.clampsReplaced;
            entry.Number_of_Leakages__c = r.numberofLeakages;
            entry.Riser_Height_Floor_Wise__c = r.riserHeightFloorWise;
            entry.Riser_Number__c = r.riserNumber;
            entry.Riser_Tested_Status__c = r.riserTestedStatus;
          entry.Valves_Replaced__c = r.valvesReplaced;
       //  entry.No_Of_Floors__c = r.noOfFloors;

          entry.Test_Pressure__c = r.testPressure;
            entry.Duration__c = r.duration;
            entry.Result__c = r.result;
          entry.No_of_Customers__c = r.noofactivecustomers;
         entry.Remark__c = r.remark;
        // entry.Type_of_Riser__c= r.typeOfRiser;

         if (r.leakLocationList != null) {
            system.debug('inside leak location list');
            system.debug('leak location list::'+ r.leakLocationList);
        for (Integer i = 0; i < Math.min(r.leakLocationList.size(), 10); i++) {
            String fieldName = 'Leak_Location_' + (i + 1) + '__c';
            entry.put(fieldName, r.leakLocationList[i]);
        }
    }

    if (r.valvesReplacedList != null) {
         system.debug('inside valves replaced list');
            system.debug('valves replaced list::'+ r.valvesReplacedList);
        for (Integer i = 0; i < Math.min(r.valvesReplacedList.size(), 10); i++) {
            String fieldName = 'Valves_Replaced_Location_' + (i + 1) + '__c';
            entry.put(fieldName, r.valvesReplacedList[i]);
        }
    }

    
            lstMaintainenceDetails.add(entry);
        }

        system.debug('List maintain details::'+ lstMaintainenceDetails);

            if(!lstMaintainenceDetails.isEmpty()){
                insert lstMaintainenceDetails;
            }

          
           // updateWorkStepStatus(recordId,'Work Order Execution Details');

     

        }

        catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        }

	}



     @AuraEnabled
    public static void flatNumberData(String recordId,  List<FlatNumberWrapper> flatNumberList){


        try {

          List<Maintenance_Detail_Child__c> lstMaintenanceDetailChild = new List<Maintenance_Detail_Child__c>();

        for (FlatNumberWrapper wrapper : flatNumberList) {
            System.debug('Processing MaterialWrapper: ' + JSON.serializePretty(wrapper));
            
            Maintenance_Detail_Child__c record = new Maintenance_Detail_Child__c(
                Work_Order__c = recordId,
                live_connectivity_Flat_Number__c = wrapper.flatNumber,
                Type__c = 'LIV connectivity	'
            );
            lstMaintenanceDetailChild.add(record);
        }

        if (!lstMaintenanceDetailChild.isEmpty()) {
            insert lstMaintenanceDetailChild;
            System.debug('Inserted Material Consumption records: ' + lstMaintenanceDetailChild);
        }

        }

           catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        }


    }

    public class FlatNumberWrapper {
        @AuraEnabled public String flatNumber{get;set;} 
    }

    @AuraEnabled
    public static void materialConsumption(String recordId,  List<MaterialWrapper> materialList){


        try {

          List<Material_Consumption__c> lstMaterConsumption = new List<Material_Consumption__c>();

        for (MaterialWrapper wrapper : materialList) {
            System.debug('Processing MaterialWrapper: ' + JSON.serializePretty(wrapper));
            
            Material_Consumption__c record = new Material_Consumption__c(
                Work_Order__c = recordId,
                Item_description__c = wrapper.itemDescription,
               // Unit__c = wrapper.unit,
                Quantity__c	 = wrapper.quantity
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
        }


    }

    public class MaterialWrapper {
        // @AuraEnabled public String itemCode;
        @AuraEnabled public String itemDescription{get;set;}
       // @AuraEnabled public String unit{get;set;}
        @AuraEnabled public Integer quantity{get;set;} // or Decimal if you're always passing a number
    }

     @AuraEnabled
public static List<String> getItemDescriptionOptions() {
    List<String> options = new List<String>();

    // This is the correct way to get the picklist entries for a field
    Schema.DescribeFieldResult fieldResult = Material_Consumption__c.Item_Description__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

    for (Schema.PicklistEntry pe : picklistValues) {
        options.add(pe.getValue());
    }

    return options;
}



    
   public class MaintenanceEntryWrapper {
 //   @AuraEnabled public String name {get;set;}
      @AuraEnabled public String riserCategory {get;set;}
    @AuraEnabled public String notOkRemark {get;set;}

     @AuraEnabled public Decimal anacondasReplaced {get;set;}
     @AuraEnabled public Decimal crimpGuardsReplaced {get;set;}
     @AuraEnabled public String anyencroachedcorrosioncondition {get;set;}
     @AuraEnabled public String suspectedGasLeakageInHouseLock {get;set;}
    @AuraEnabled public Decimal gIPipeLengthReplaced {get;set;}
    @AuraEnabled public Decimal holePiecesReplace {get;set;}
    @AuraEnabled public String leakLocations {get;set;}
    @AuraEnabled public String lIVConnectivitywithflatno {get;set;}
   // @AuraEnabled public Decimal activeConnections {get;set;}
    @AuraEnabled public String newMaterialsUsed {get;set;}
    @AuraEnabled public Decimal clampsReplaced {get;set;}
    @AuraEnabled public String numberofLeakages {get;set;}
    @AuraEnabled public String riserHeightFloorWise {get;set;}
    @AuraEnabled public Decimal riserNumber {get;set;}
    @AuraEnabled public String riserTestedStatus {get;set;}
    @AuraEnabled public String valvesReplaced {get;set;}
   // @AuraEnabled public String noOfFloors {get;set;}


    @AuraEnabled public String testPressure {get;set;}
    @AuraEnabled public String duration {get;set;}
    @AuraEnabled public String result {get;set;}
    @AuraEnabled public String noofactivecustomers {get;set;}
    @AuraEnabled public String remark {get;set;}
   // @AuraEnabled public String typeOfRiser {get;set;}

 @AuraEnabled public List<String> leakLocationList {get;set;}
  @AuraEnabled public List<String> valvesReplacedList {get;set;}




}



 @AuraEnabled
    public static void saveImage(List<FileWrapper> listFiles,String recordId, String afterImageRemark){
        try {
            
            system.debug('Record id ::'+ recordId);
          //   System.debug('listFiles::'+ listFiles);

  WorkOrder wo =[Select Id,RM_Remark__c from WorkOrder where Id=: recordId ];

            wo.Id = recordId;
            wo.RM_Remark__c = afterImageRemark;
            

            update wo;

          //  String userId = userInfo.getUserId();

       /*  for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                cv.OwnerId = userInfo.getUserId();
                cv.FirstPublishLocationId = recordId;
                cv.ContentLocation= 'S';
              
                insert cv;
            } */

            
         
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
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

            

          updateWorkStepStatus(recordId,'CO Execution Detail');




        } catch (Exception ex) {
             System.debug('❌ Exception: ' + ex.getMessage() + ' ' + ex.getLineNumber());
            throw new AuraHandledException('Error updating work order: ' + ex.getMessage());

        }
    }

     @AuraEnabled
    public static void saveImageNotOk(List<FileWrapper> listFiles,String recordId){
        try {
          
                              
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName;
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
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

            





        } catch (Exception ex) {
             System.debug('❌ Exception: ' + ex.getMessage() + ' ' + ex.getLineNumber());
            throw new AuraHandledException('Error updating work order: ' + ex.getMessage());

        }
    }

      @AuraEnabled
    public static void saveImageAnyEncroached(List<FileWrapper> listFiles,String recordId){
        try {
          
                              
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName;
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
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

            





        } catch (Exception ex) {
             System.debug('❌ Exception: ' + ex.getMessage() + ' ' + ex.getLineNumber());
            throw new AuraHandledException('Error updating work order: ' + ex.getMessage());

        }
    }


     public static void updateWorkStepStatus(Id workOrderId,String name){
        List<WorkStep> steps = [
			SELECT Id, Status
			FROM WorkStep
			WHERE ParentRecordId = :workOrderId
			AND Name = :name
			LIMIT 1
		];
        
        if (!steps.isEmpty()) {
            WorkStep ws = steps[0];
            ws.Status = 'Completed'; // Or whatever picklist value you use
            update ws;
        }
     }


	@AuraEnabled 
	public static List<OptionsWrapper> fieldPicklistValue(String objectName,String fieldName){
    List<OptionsWrapper> optionList=new List<OptionsWrapper>();
    Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
    Schema.DescribeSObjectResult r = s.getDescribe();
    Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
    Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for( Schema.PicklistEntry pickListVal : ple){
        OptionsWrapper option=new OptionsWrapper();
        option.label=pickListVal.getLabel();
        option.value=pickListVal.getValue();
        optionList.add(option);
    }
    return optionList;
}
 
public class OptionsWrapper{
    @AuraEnabled public String label{get;set;}
    @AuraEnabled public String value{get;set;}
}

public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }

    
 
}