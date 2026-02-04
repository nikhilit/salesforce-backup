/**
* @File Name : O_MRubberHoseDetailContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : June 3, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 3, 2025 |   | Initial Version
**/

public without sharing class O_MRubberHoseDetailContr {

    @AuraEnabled
    public static string getWOAccountDetails(String recordId){

        system.debug('Record is passed by js::'+ recordId);

        try {

                    system.debug('Record is passed by js::'+ recordId);


        WorkOrder wo = [Select id,AccountId from WorkOrder where id=: recordId];

                system.debug('workorder::'+ wo);


        Account accRecord = [Select id,Meter_Number__c from Account where Id =:wo.AccountId];

              system.debug('accRecord::'+ accRecord);


        string accMeterNumber ='';
        accMeterNumber =accRecord.Meter_Number__c;

        system.debug('Account Meter Number::'+ accMeterNumber);

        return accMeterNumber;

        }
        catch(Exception e){

            system.debug('Error::'+ e.getLineNumber() + e.getMessage());

            return 'e.getMessage() + e.getLineNumber()';
        }
    }

	 @AuraEnabled
    public static void saveRubberHoseDetails(String recordId, String RubberHoseDetails,List<FileWrapper> listFiles,String afterImageRemark) {

		try {

			system.debug('inside update work order rubber hose');
        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(RubberHoseDetails);


    //Material_Utilised__c,
		 WorkOrder wOrder = [
        SELECT Id, Meter_Number_RH__c, Meter_Reading_RH__c,
               Old_Rubber_Hose_Expiry__c, New_Rubber_Hose__c,
               Length_of_new_RH_installed__c, Leakage_Observed__c,
               Leakage_Location__c,RH_Remark__c,Check_Customer_Availability__c
        FROM WorkOrder
        WHERE Id = :recordId
        LIMIT 1
    ];
        wOrder.Meter_Number_RH__c = String.isNotBlank((String)dataMap.get('meterNumber')) ? (String)dataMap.get('meterNumber') : null;
wOrder.Meter_Reading_RH__c = String.isNotBlank((String)dataMap.get('meterReading')) ? (String)dataMap.get('meterReading') : null;

wOrder.Old_Rubber_Hose_Expiry__c = String.isNotBlank((String)dataMap.get('oldHoseExpiry')) ? Date.valueOf((String)dataMap.get('oldHoseExpiry')) : null;
wOrder.New_Rubber_Hose__c = String.isNotBlank((String)dataMap.get('newHoseExpiry')) ? Date.valueOf((String)dataMap.get('newHoseExpiry')) : null;

wOrder.Length_of_new_RH_installed__c = String.isNotBlank((String)dataMap.get('rhLength')) ? (String)dataMap.get('rhLength') : null;
//wOrder.Material_Utilised__c = String.isNotBlank((String)dataMap.get('materialUsed')) ? (String)dataMap.get('materialUsed') : null;
// wOrder.Leakage_Observed__c = String.isNotBlank((String)dataMap.get('numberOfleakageObserved')) ? (String)dataMap.get('numberOfleakageObserved') : null;
//wOrder.Leakage_Location__c = String.isNotBlank((String)dataMap.get('leakagelocations')) ? (String)dataMap.get('leakagelocations') : null;
wOrder.RH_Remark__c = afterImageRemark;
wOrder.Check_Customer_Availability__c = 'Yes';

        update wOrder;

		system.debug('Work order after update::'+ wOrder);

        updateWorkStepStatus(recordId,'Rubber Hose Execution Details');


        List<Object> leakLocationsRaw = (List<Object>) dataMap.get('leakagelocations');

        system.debug('Leak location details::'+ leakLocationsRaw);

       if (leakLocationsRaw != null && !leakLocationsRaw.isEmpty()) {

                system.debug('inside not empty Leak location details::'+ leakLocationsRaw);

    Maintainence_Detail__c md = new Maintainence_Detail__c();

    for (Object obj : leakLocationsRaw) {

        Map<String, Object> locationEntry = (Map<String, Object>) obj;

        Integer index = (Integer) locationEntry.get('index');
        String value = (String) locationEntry.get('value');

        if (index != null && index >= 1 && index <= 10) {
            String fieldName = 'Leak_Location_' + index + '__c';
            md.put(fieldName, value);
        }



        
    }
            md.Work_Order__c = recordId;
            md.Number_of_Leakages__c=String.isNotBlank((String)dataMap.get('numberOfleakageObserved')) ? (String)dataMap.get('numberOfleakageObserved') : null;
            md.Name='Rubber Hose Details';


    insert md;

    system.debug('insert maintenance details::'+ md);
}



		 List<ContentVersion> contentVersions = new List<ContentVersion>();
            
            for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName;
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                contentVersions.add(cv);
            }
            
            insert contentVersions;

			system.debug('content version::'+ contentVersions);
            
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

			system.debug('Document link:: '+ links);

		  

    }

	
	catch(Exception e){
		system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
	}
	}

	public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }

    @AuraEnabled
    public static void saveMaterialDetails(String workOrderId, List<MaterialWrapper> materialList) {
        System.debug('--- Entered saveMaterialDetails ---');
        System.debug('Work Order Id: ' + workOrderId);
        System.debug('Received Material List: ' + materialList);



        List<Material_Consumption__c> toInsert = new List<Material_Consumption__c>();

        for (MaterialWrapper wrapper : materialList) {
            System.debug('Processing MaterialWrapper: ' + JSON.serializePretty(wrapper));
            
            Material_Consumption__c record = new Material_Consumption__c(
                Work_Order__c = workOrderId,
                Item_description_Rubberhose__c = wrapper.itemDescription,
                 Item_Code__c = wrapper.itemCode,

              //  Unit_Rubberhose__c = wrapper.unit,
                Quantity_Rubberhose__c = wrapper.quantity
            );
            toInsert.add(record);
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
            System.debug('Inserted Material Consumption records: ' + toInsert);
        }
    }

    @AuraEnabled
public static List<String> getItemDescriptionOptions() {
    List<String> options = new List<String>();

    // This is the correct way to get the picklist entries for a field
    Schema.DescribeFieldResult fieldResult = Material_Consumption__c.Item_description_Rubberhose__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

    for (Schema.PicklistEntry pe : picklistValues) {
        options.add(pe.getValue());
    }

    return options;
}

public class MaterialWrapper {
        // @AuraEnabled public String itemCode;
        @AuraEnabled public String itemDescription{get;set;}
      @AuraEnabled public String itemCode{get;set;}

        @AuraEnabled public String unit{get;set;}
        @AuraEnabled public Integer quantity{get;set;} // or Decimal if you're always passing a number
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
    public static void uploadRHReplacedServiceNote(String fileName, string base64Data, String recordId) {
     
       
        System.debug('Inside upload file method:::');
 
        System.debug('fileName::' + fileName);
        System.debug('base64Data::' + base64Data);
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);
   
        System.debug('File blob:::'+ fileBlob);
       
 
            ContentVersion cv = new ContentVersion();
             cv.Title = fileName;
             cv.PathOnClient = fileName;
             cv.VersionData = fileBlob;
                System.debug('CV::::'+ cv);
                insert cv;
 
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            link.LinkedEntityId =  recordId;
            link.ShareType = 'I';
            System.debug('Link:::'+ link);
            insert link;            
 
        System.debug('contentversion :::'+ cv);      
         System.debug('Document Link:::'+ link);  
 
        
 
       
   
}
	
}