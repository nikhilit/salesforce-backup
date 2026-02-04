/**
* @File Name : RiserPaintingCOExecutionDetailsContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : August 2, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 2, 2025 |   | Initial Version
**/

public without sharing class RiserPaintingCOExecutionDetailsContr {


    @AuraEnabled
	public static void createMaintenanceEntryAndDetailsRecord(string recordId, List<MaintenanceEntryWrapper> riserDetails, Decimal riserNumber, Decimal risersFloors, String riserPickListValue, String lengthOfApprocahRiser){

        try { 

            system.debug('Riser number::'+ riserNumber);

          

        Maintenance_Entry__c mEntry = new Maintenance_Entry__c();
         mEntry.Number_of_Risers__c=riserNumber;
        mEntry.Number_of_Floors__c = risersFloors;
        mEntry.Type_of_Riser__c = riserPickListValue;
        mEntry.Length_Of_Approcah_Riser__c = lengthOfApprocahRiser;
         mEntry.Work_Order__c = recordId;

          insert mEntry;

         system.debug('Riser entry created::'+ mEntry);


        List<Maintainence_Detail__c> lstMaintainenceDetails = new List<Maintainence_Detail__c>();


        
		 for (MaintenanceEntryWrapper r : riserDetails) {

            //system.debug('mentry id ::'+ r.id);

            Maintainence_Detail__c entry = new Maintainence_Detail__c();
            entry.Maintenance_Entry__c=mEntry.Id;

        entry.Number_of_Clamps_Replaced__c = r.noofClampsReplaced;


       if (String.isNotBlank(r.riserCategory)) {
        entry.Main_or_Approach_Riser__c = r.riserCategory;
    } 
    

    if (String.isNotBlank(r.lengthPaintedPrimer)) {
        entry.Length_Painted_Primer__c = r.lengthPaintedPrimer;
    }

    if (String.isNotBlank(r.dFTReadingPrimer)) {
        entry.DFT_Reading_Primer__c = r.dFTReadingPrimer;
    }

    if (String.isNotBlank(r.lengthPaintedYellow)) {
        entry.Length_Painted_Yellow__c = r.lengthPaintedYellow;
    }

    if (String.isNotBlank(r.dFTReadingYellow)) {
        entry.DFT_Reading_Yellow__c = r.dFTReadingYellow;
    }

    if (String.isNotBlank(r.lengthPaintedYellow3)) {
        entry.Length_Painted_Yellow_3__c = r.lengthPaintedYellow3;
    }

    if (String.isNotBlank(r.dFTReadingYellow3)) {
        entry.DFT_Reading_Yellow_3__c = r.dFTReadingYellow3;
    }

    if (String.isNotBlank(r.noofCrimpGuardsReplaced)) {
        entry.No_of_Crimp_Guards_Replaced__c = r.noofCrimpGuardsReplaced;
    }

    if (String.isNotBlank(r.id)) {
        entry.RiserNo__c = r.id;
    }

            lstMaintainenceDetails.add(entry);

             
        }

        system.debug('List maintain details::'+ lstMaintainenceDetails);



            if(!lstMaintainenceDetails.isEmpty()){
                insert lstMaintainenceDetails;
            }

                

    //         List<Material_Consumption__c> lstMaterialConsumption = new List<Material_Consumption__c>();

	// 	 for (MaintenanceEntryWrapper r : riserDetails) {

    //     if (r.materialList != null && !r.materialList.isEmpty()) {
    //     for (MaterialWrapper m : r.materialList) {
    //         Material_Consumption__c mat = new Material_Consumption__c();
    //         mat.Work_Order__c = recordId;//lstMaintainenceDetails[0].Id;
    //         mat.Item_Description__c = m.itemDescription;
    //         mat.Quantity__c = m.quantity != null ? Decimal.valueOf(m.quantity) : null;
    //         lstMaterialConsumption.add(mat);
    //     }
    //     }
    //      }

    //     if(!lstMaterialConsumption.isEmpty()){

    //         insert lstMaterialConsumption;
        
    // }
          

     

        }

        catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
        }

	}

     public class MaintenanceEntryWrapper {

      @AuraEnabled public String id {get;set;}

          @AuraEnabled public String riserCategory {get;set;}

      @AuraEnabled public Decimal noofClampsReplaced {get;set;}

    @AuraEnabled public String lengthPaintedPrimer {get;set;}
       @AuraEnabled public String dFTReadingPrimer {get;set;}

     @AuraEnabled public String lengthPaintedYellow {get;set;}
        @AuraEnabled public String dFTReadingYellow {get;set;}

    @AuraEnabled public String lengthPaintedYellow3 {get;set;}
    @AuraEnabled public String dFTReadingYellow3 {get;set;}

    @AuraEnabled public String noofCrimpGuardsReplaced {get;set;}

 @AuraEnabled public List<MaterialWrapper> materialList { get; set; } 

   
}

public class MaterialWrapper {
    @AuraEnabled public Integer id { get; set; }
    @AuraEnabled public String itemDescription { get; set; }
    @AuraEnabled public String quantity { get; set; }
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

@AuraEnabled
    public static void saveAfterPaintingImages(List<FileWrapper> listFiles,String recordId){
        try {
            
            system.debug('Record id ::'+ recordId);
                         
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
    public static void saveBeforePaintingImages(List<FileWrapper> listFiles,String recordId){
        try {
            
            system.debug('Record id ::'+ recordId);
                         
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

    public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
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


}