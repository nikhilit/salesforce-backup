/**
* @File Name : O_MWorkOrderAccountInfoController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : May 27, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | May 27, 2025 |   | Initial Version
**/

public without sharing class O_MWorkOrderAccountInfoController {
	 @AuraEnabled(cacheable=true)
    public static Map<String, Account> getAccountInfoFromSA(Id workOrderId) {
        System.debug('Start: getAccountInfoFromWO called with Work Order Id: ' + workOrderId);
        
        try {
            if (workOrderId == null) {
                throw new AuraHandledException('Work Order Id is null');
            }
            
            WorkOrder wo = [
                SELECT Id, AccountId, Account.Name, Account.Phone
                FROM WorkOrder
                WHERE Id = :workOrderId
                LIMIT 1
            ];
            
            if (wo.AccountId == null) {
                System.debug('wo.AccountId : '+wo.AccountId);
                throw new AuraHandledException('No Account associated with this Work Order.');
            }
            
            Account acc = [
                SELECT Id, Name, Phone, Secondary_Telephone__c, Account_Email__c,
                       Account_Type__c,MRU_Code__c,BP_Number__c, CA_Number__c,
                       Meter_Number__c,Plot__c,Customer_Contact_no__c,
                       Building_name__c, Street__c, Colony__c, Wing__c,
                       Floor__c, Flat__c, Road_name__c,Society_Name__c,Location__c,City__c,Postal_Code__c,
                       RH_Due_Date__c
                FROM Account
                WHERE Id = :wo.AccountId
                LIMIT 1
            ];
            
            return new Map<String, Account>{
                'acc' => acc
            };
            
        } catch (Exception ex) {
            System.debug('Exception caught: ' + ex.getMessage());
            System.debug('Exception Line Number: '+ex.getLineNumber());
            System.debug('Exception Stack Trace: '+ex.getStackTraceString());
            throw new AuraHandledException('Apex error: ' + ex.getMessage());
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



 @AuraEnabled
    public static void saveImage(List<FileWrapper> listFiles,String recordId,String reasonUnavailability, String otherRemarkValue, String rMCloserRemark){
        try {
            // ServiceAppointment sa = [
            //     SELECT Id,Visit_Status__c,ParentRecordId
            //     FROM ServiceAppointment 
            //     WHERE Id = :serviceAppointmentId
            //     LIMIT 1
            // ];
            system.debug('Record id ::'+ recordId);
             system.debug('Reason  ::'+ reasonUnavailability);
           //  System.debug('listFiles::'+ listFiles);

            WorkOrder wOrder = [Select id,Reason_for_Unavailability__c,Reason_Other_Remark__c,
                                      RM_Closer_Remark__c from WorkOrder where id =:recordId];

            wOrder.Reason_for_Unavailability__c=reasonUnavailability;
            wOrder.Reason_Other_Remark__c = otherRemarkValue;
            wOrder.RM_Closer_Remark__c =rMCloserRemark;
            update wOrder;

             for (FileWrapper fw : listFiles) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fw.label;
                cv.PathOnClient = fw.fileName +'.jpg';
                cv.VersionData = EncodingUtil.base64Decode(fw.base64Data);
                cv.OwnerId = userInfo.getUserId();
                cv.FirstPublishLocationId = recordId;
                cv.ContentLocation= 'S';
              
                insert cv;
            }

            /*
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

            */

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
    public static string checkWorkStep(string recordId){

        try {

            System.debug('inside check work step method in apex');
             System.debug('Record id::'+ recordId);

       WorkStep worStep = [SELECT Id, Status,Name
			FROM WorkStep
			WHERE ParentRecordId =: recordId AND Name='Upload Site Documents'];

    system.debug('Work step result ::'+ worStep.Status);
        return worStep.Status;
    
    }
    catch(Exception e){
        return 'Error';
    }
			
    }

    @AuraEnabled
    public static string woApprovalStatus(string recordId){


        try {

        WorkOrder wo = [Select id,Approval_Status__c from WorkOrder Where id=: recordId];

        string approvalStatus = wo.Approval_Status__c;

        return approvalStatus;


        }


        catch(Exception e){

            return 'Error';
        }
    }
 
    
}