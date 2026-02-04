/**
* @File Name : O_MServiceReportContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : June 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 11, 2025 |   | Initial Version
**/

public without sharing class O_MServiceReportContr {


     public class serviceReportControllerWrapper {
        @AuraEnabled public WorkOrder documentRecordDetail {get; set;}
        @AuraEnabled public String profileName {get; set;}
    }

  /*  @AuraEnabled
    public static serviceReportControllerWrapper getApprovalStatus() {

        try{

            //userDetail.Profile.Name =='Domestic Meter Checking Field Agent' || userDetail.Profile.Name =='O&M Field Agent DOMESTIC METER CHECKING' ||  userDetail.Profile.Name =='O&M Supervisor DOMESTIC METER CHECKING'
//userDetail.Profile.Name =='Rubber Hose Field Agent' || userDetail.Profile.Name =='O&M Rubber Hose Supervisor' || userDetail.Profile.Name =='O&M Rubber Hose Field Agent'
            User userDetail = [Select id,Name,UserName,Profile.Name from User Where Id=: userInfo.getUserId()];

            Document__c doucmentRecord = [Select id,Submitted_Agent_Name__c,Approval_Status_O_M__c	from Document__c where Submitted_Agent_Name__c=: userDetail.UserName];


         // return doucmentRecord;

          serviceReportControllerWrapper result = new serviceReportControllerWrapper();
            result.documentRecordDetail = doucmentRecord;
            result.profileName = userDetail.Profile.Name;
            return result;

      //  return doucmentRecord.Approval_Status_O_M__c;

       // WorkOrder wOrder = [Select id,Approval_Status__c,WorkType.Name from WorkOrder Where id=:recordId];

            //return wOrder;
        //return wOrder.Approval_Status__c ;

    }
    catch(Exception e){

         return new serviceReportControllerWrapper(); // empty if error


       // return new Document__c();
       // return 'Error '+ e.getMessage();
    }

    } */

      @AuraEnabled
    public static serviceReportControllerWrapper getApprovalStatus() {

        try{

            //userDetail.Profile.Name =='Domestic Meter Checking Field Agent' || userDetail.Profile.Name =='O&M Field Agent DOMESTIC METER CHECKING' ||  userDetail.Profile.Name =='O&M Supervisor DOMESTIC METER CHECKING'
//userDetail.Profile.Name =='Rubber Hose Field Agent' || userDetail.Profile.Name =='O&M Rubber Hose Supervisor' || userDetail.Profile.Name =='O&M Rubber Hose Field Agent'
            User userDetail = [Select id,Name,UserName,Profile.Name from User Where Id=: userInfo.getUserId()];

        ServiceResource serResource = [select id,Name from ServiceResource where RelatedRecordId =: userDetail.Id limit 1];
         

         WorkOrder wo = [select id,Agent_Name_Formula__c,Agent__c,Approval_Status__c  from workorder where Record_Type_Developer_Name__c ='TBT' and Agent__c =:serResource.Id limit 1];

          //  Document__c doucmentRecord = [Select id,Submitted_Agent_Name__c,Approval_Status_O_M__c	from Document__c where Submitted_Agent_Name__c=: userDetail.UserName];



          serviceReportControllerWrapper result = new serviceReportControllerWrapper();
            result.documentRecordDetail = wo;
            result.profileName = userDetail.Profile.Name;
            return result;

     
    }
    catch(Exception e){

         return new serviceReportControllerWrapper(); // empty if error


       
    }

    }

    @AuraEnabled 
    public static string getWOrderWType(string recordId){

        try {

        WorkOrder wOrder = [Select id,WorkType.Name from WorkOrder where id=:recordId];

        return wOrder.WorkType.Name;
    }

    catch(Exception e){
        return 'Error';
    }

    }

    
	@AuraEnabled
	public static string saveServiReportData(string recordId, string serviceReport){


		try {

   Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(serviceReport);

 WorkOrder wOrder = [
        SELECT Id, The_Work_Done__c, Satisfactory__c,
		Not_Satisfactory__c  //,Meter_No_SR__c,Meter_Reading_SR__c	
        FROM WorkOrder
        WHERE Id = :recordId
        LIMIT 1
    ];
String satNoSatValue = (String)dataMap.get('satisfactoryNotSatisfactory');
system.debug('satnosatvalue ::'+ satNoSatValue);

//wOrder.Rubber_Hose_Expiry_Date__c = String.isNotBlank((String)dataMap.get('rubberHoseExpiryDate')) ? Date.valueOf((String)dataMap.get('rubberHoseExpiryDate')) : null;
wOrder.The_Work_Done__c = String.isNotBlank((String)dataMap.get('workDone')) ? (String)dataMap.get('workDone') : null;

if (satNoSatValue == 'Satisfactory') {
    wOrder.Satisfactory__c = true;
   // wOrder.Not_Satisfactory__c = false; 
} 
 else if (satNoSatValue == 'Not Satisfactory') {
    wOrder.Not_Satisfactory__c = true;
   // wOrder.Satisfactory__c = false; 
}
//wOrder.Meter_No_SR__c = String.isNotBlank((String)dataMap.get('meterNumber')) ? (String)dataMap.get('meterNumber') : null;
//wOrder.Meter_Reading_SR__c = String.isNotBlank((String)dataMap.get('meterReading')) ? (String)dataMap.get('meterReading') : null;

        update wOrder;

        system.debug('Updated work order ::'+ wOrder);

	  updateWorkStepStatus(recordId,'Service Report');

        generateAndAttachPdf(recordId);
        //System.enqueueJob(new ServiceReportPdfQueueable(recordId));


	return 'Success';

		}
		catch(Exception e){
            system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
			return  'Error';
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
    public static Id generateAndAttachPdf(String worOrderId) {

        WorkOrder worOrder = [Select id,BP_Number__c from WorkOrder where id=: worOrderId];

        system.debug('Inside generateAndAttachPdf'+ worOrderId);

        PageReference pdfPage = Page.O_MMeterDetails;

        system.debug('Pdfpage :'+ pdfPage);
        pdfPage.getParameters().put('id', worOrderId);
        Blob pdfBlob = pdfPage.getContentAsPDF();

        ContentVersion cv = new ContentVersion(
            Title = 'Service Report' + ' ' + worOrder.BP_Number__c + '.pdf',
            PathOnClient = 'O_MMeterDetails_' + worOrderId + '.pdf',
            VersionData = pdfBlob
        );
        insert cv;

        system.debug('Content version::'+ cv);

        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = worOrderId,
            ShareType = 'V'
        );
        insert cdl;

        system.debug('cdl::'+ cdl);

        return cd.Id;
    }

      @AuraEnabled
    public static String serviceReportPdf(String recordId){

        try {
    ContentDocumentLink conDocu= [SELECT Id,ContentDocumentId,LinkedEntityId,ContentDocument.LatestPublishedVersion.Title,
                                        ContentDocument.LatestPublishedVersion.Id
  FROM ContentDocumentLink WHERE LinkedEntityId =: recordId 
                                        AND ContentDocument.LatestPublishedVersion.Title LIKE '%Service Report%' limit 1];

    ContentVersion conVers = [select Id,Title,ContentDocumentId from ContentVersion where ContentDocumentId=:conDocu.ContentDocumentId ORDER BY VersionNumber DESC 
    LIMIT 1
];
        system.debug('ContentDocumentLink :: '+ conDocu);
        return conVers.Id;   

        }

        catch(Exception e){

            system.debug('Error ::'+ e.getMessage() + ' ' + e.getLineNumber());
            return 'Error';
        }                                     
    }

      @AuraEnabled
    public static string checkWorkStep(string recordId){

        try {

            System.debug('inside check work step method in apex');
             System.debug('Record id::'+ recordId);

       WorkStep worStep = [SELECT Id, Status,Name
			FROM WorkStep
			WHERE ParentRecordId =: recordId AND (Name='CO Execution Detail' OR Name='BP Execution Details' OR Name='Site Details')];

    system.debug('Work step result ::'+ worStep.Status);
        return worStep.Status;
    
    }
    catch(Exception e){
        return 'Error';
    }
			
    }

    @AuraEnabled
    public static void uploadFileUnsafeLetter(String fileName, string base64Data, String recordId) {
     
       
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

         	 updateWorkStepStatus(recordId,'Service Report');

 
        
 
       
   
}
 


}