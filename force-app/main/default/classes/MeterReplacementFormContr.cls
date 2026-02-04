/**
* @File Name : MeterReplacementFormContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : June 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 10, 2025 |   | Initial Version
**/

public without sharing class MeterReplacementFormContr {
 

    @AuraEnabled
public static String saveMeterReplDetails(String recordId, List<FileWrapper> listFiles,String newMeter,String oldMeter) {


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

            // Update meter readings
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Id = :recordId LIMIT 1];
        wo.Previous_Meter_Reading__c = oldMeter;
        wo.New_Meter_Reading__c = newMeter;
        update wo;

		
		  updateWorkStepStatus(recordId,'CO Execution Detail');
		return 'SUCCESS';

		} catch(Exception e) {
    System.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
    return 'ERROR: ' + e.getMessage();
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