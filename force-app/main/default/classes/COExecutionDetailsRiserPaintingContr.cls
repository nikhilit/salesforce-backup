/**
* @File Name : COExecutionDetailsRiserPaintingContr.cls
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

public without sharing class COExecutionDetailsRiserPaintingContr {
	
	@AuraEnabled
	public static WorkOrder getWorkOrder(String recordId){

		try {


			WorkOrder wo =[Select Id,Number_of_Risers__c,							
									Number_of_Floors__c,Type_of_Riser__c,
									Length_Of_Approcah_Riser__c from WorkOrder where Id=: recordId];

			return wo;
		}
		catch(Exception e){

			return new WorkOrder();
		}
	}

	
	@AuraEnabled
	public static void saveCODetails(string recordId, String riserNumber,  Decimal risersFloors, String riserPickListValue, String approcahRiserLength ){

		try {

			system.debug('record id::'+ recordId);

		WorkOrder woUpdate = [Select Id,Number_of_Risers__c,							
									Number_of_Floors__c,Type_of_Riser__c,
									Length_Of_Approcah_Riser__c 
									from WorkOrder where Id=: recordId];

		woUpdate.Number_of_Risers__c =	riserNumber;
		woUpdate.Number_of_Floors__c =risersFloors;
		woUpdate.Type_of_Riser__c = riserPickListValue;
	    woUpdate.Length_Of_Approcah_Riser__c = approcahRiserLength;

		Update woUpdate;

		Integer riserNumberValue = Integer.valueOf(riserNumber);

		List<WorkOrderLineItem> lstWorkOrderLineItem = new List<WorkOrderLineItem>();

		for(Integer i=1; i<= riserNumberValue; i++){

			WorkOrderLineItem wolitem = new WorkOrderLineItem();

			wolitem.Riser_Name__c	= 'Riser ' + i;
			wolitem.WorkOrderId = recordId;

			lstWorkOrderLineItem.add(wolitem);
		}

		if(!lstWorkOrderLineItem.isEmpty()){

			insert lstWorkOrderLineItem;

			system.debug('WorkOrderLineItem inserted ::'+ lstWorkOrderLineItem);
		}

//List<FileWrapper> listFiles
		//   List<ContentVersion> contentVersions = new List<ContentVersion>();
            
        //     for (FileWrapper fw : listFiles) {
        //         ContentVersion cv = new ContentVersion();
        //         cv.Title = fw.label;
        //         cv.PathOnClient = fw.fileName +'.jpg';
        //         cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
        //         contentVersions.add(cv);
        //     }
            
        //     insert contentVersions;
            
        //     // Map ContentVersion Id to ContentDocumentId
        //     Map<Id, Id> versionToDocMap = new Map<Id, Id>();
        //     for (ContentVersion cv : [
        //     SELECT Id, ContentDocumentId 
        //     FROM ContentVersion 
        //     WHERE Id IN :contentVersions
        // ]) {
        //         versionToDocMap.put(cv.Id, cv.ContentDocumentId);
        //     }
            
        //     // Create ContentDocumentLinks to associate files with the given record
        //     List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        //     for (Id versionId : versionToDocMap.keySet()) {
        //         links.add(new ContentDocumentLink(
        //             ContentDocumentId = versionToDocMap.get(versionId),
        //         LinkedEntityId = recordId,
        //         ShareType = 'V', // View permission
        //         Visibility = 'AllUsers'
        //             ));
        //     }
            
        //     insert links;


		updateWorkStepStatus(recordId,'CO Execution Detail');



		}

		catch(Exception e){

			System.debug('Error updateworkorder details::'+ e.getLineNumber() + e.getMessage());
		}
	}

	//  public class FileWrapper{
    //     @AuraEnabled public String base64Data{get;set;}
    //     @AuraEnabled public String fileName{get;set;}
    //     @AuraEnabled public String label{get;set;}
    // }


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
            ws.Status = 'Completed'; 
            update ws;
        }
    }

}