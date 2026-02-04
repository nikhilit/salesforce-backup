/**
* @File Name : CheckCustomerAvilablityContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 23, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 23, 2025 |   | Initial Version
**/

public without sharing class CheckCustomerAvilablityContr {


     @AuraEnabled
    public static WorkOrder getApprovalStatus() {

        try{

            User userDetail = [Select id,Name,UserName from User Where Id=: userInfo.getUserId()];

             ServiceResource serResource = [select id,Name from ServiceResource where RelatedRecordId =: userDetail.Id limit 1];
         

         WorkOrder wo = [select id,Agent_Name_Formula__c,Agent__c,Approval_Status__c  from workorder where Record_Type_Developer_Name__c ='TBT' and Agent__c =:serResource.Id limit 1];


          //  Document__c doucmentRecord = [Select id,Submitted_Agent_Name__c,Approval_Status_O_M__c	from Document__c where Submitted_Agent_Name__c=: userDetail.UserName];

          return wo;

      //  return doucmentRecord.Approval_Status_O_M__c;

       // WorkOrder wOrder = [Select id,Approval_Status__c,WorkType.Name from WorkOrder Where id=:recordId];

            //return wOrder;
        //return wOrder.Approval_Status__c ;

    }
    catch(Exception e){

        return new WorkOrder();
       // return 'Error '+ e.getMessage();
    }

    }

     @AuraEnabled
    public static string checkWorkStep(string recordId){

        try {

            System.debug('inside check work step method in apex');
             System.debug('Record id::'+ recordId);

       WorkStep worStep = [SELECT Id, Status,Name
			FROM WorkStep
			WHERE ParentRecordId =: recordId AND Name='Check-in'];

    system.debug('Work step result ::'+ worStep.Status);
        return worStep.Status;
    
    }
    catch(Exception e){
        return 'Error';
    }
			
    }


	@AuraEnabled
	public static void updateWorkOrder(String recordId, String customerAvailability){

		  WorkOrder wo =[Select Id,Check_Customer_Availability__c from WorkOrder where Id=: recordId ];
			
			wo.Id = recordId;
            wo.Check_Customer_Availability__c = customerAvailability;
            

            update wo;

         updateWorkStepStatus(recordId,'Riser activity Possible');

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
    public static void customerNameAndFlatNumberData(String recordId,  List<CustomerNameFlatNumberWrapper> customerNameFlatNumberList){


        try {

          List<Maintenance_Detail_Child__c> lstMaintenanceDetailChild = new List<Maintenance_Detail_Child__c>();

        for (CustomerNameFlatNumberWrapper wrapper : customerNameFlatNumberList) {
            System.debug('Processing MaterialWrapper: ' + JSON.serializePretty(wrapper));
            
            Maintenance_Detail_Child__c record = new Maintenance_Detail_Child__c(
                Work_Order__c = recordId,
                Customer_Name__c = wrapper.customerName,
                Flat_Number__c	 = wrapper.flatNumber,
                Type__c = 'Premises Locked'
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

    public class CustomerNameFlatNumberWrapper {
        @AuraEnabled public String customerName{get;set;}
        @AuraEnabled public String flatNumber{get;set;} 
    }


@AuraEnabled
    public static void saveImage(String recordId,String reasonUnavailability, String otherRemarkValue, String customerAvailability, String maintenanceDoneYearOfAMC){
        try {

            //List<FileWrapper> listFiles,
          
            system.debug('Record id ::'+ recordId);
             system.debug('Reason  ::'+ reasonUnavailability);

            WorkOrder wOrder = [Select id,Reason_ForUnavilability__c,Reason_Other_Remark__c,
                                      RM_Closer_Remark__c,Check_Customer_Availability__c,
                                      Maintenancealreadydone_yearofAMC__c
                                       from WorkOrder where id =:recordId];

            wOrder.Reason_ForUnavilability__c=reasonUnavailability;
            wOrder.Reason_Other_Remark__c = otherRemarkValue;
           // wOrder.RM_Closer_Remark__c =rMCloserRemark;
            wOrder.Check_Customer_Availability__c= customerAvailability;
            wOrder.Maintenancealreadydone_yearofAMC__c = maintenanceDoneYearOfAMC;
            update wOrder;

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

            
          /*  List<ContentVersion> contentVersions = new List<ContentVersion>();
            
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
            
            insert links; */

            

          updateWorkStepStatus(recordId,'Riser activity Possible');




        } catch (Exception ex) {
             System.debug('Exception:::::>>> ' + ex.getMessage() + ' ' + ex.getLineNumber());
            throw new AuraHandledException('Error updating work order: ' + ex.getMessage());

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
        public static void uploadFiles(List<string> fileName, List<string> base64Data, List<string> fileType, String recordId) {
        
        try {
            system.debug('inside upload file apex class');
            system.debug('File Types ::'+ fileType);

                                                       
            List<ContentVersion> lstContentVersion = new List<ContentVersion>();
            List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>();
            
            for (Integer i = 0; i < fileName.size(); i++) {
                String name = fileName[i];
                String base64 = base64Data[i];
                String fType = fileType[i];
                Blob fileBlob = EncodingUtil.base64Decode(base64);
                
                
                ContentVersion cv = new ContentVersion();
                cv.Title = name;
                cv.PathOnClient = name;
                cv.VersionData = fileBlob;
                cv.Description = 'Reason for Cancellation images';
               // cv.O_M_Document_Types__c=fType;
                System.debug('CV::::'+ cv);
                lstContentVersion.add(cv);
                
                
            }
            
            if(!lstContentVersion.isEmpty()){
                system.debug('ContentVersion::'+ lstContentVersion);
                insert lstContentVersion;
                
            }
            
            for (ContentVersion insertedCV : lstContentVersion) {
                // ContentDocument cd = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :insertedCV.Id LIMIT 1];
                
                ContentDocumentLink link = new ContentDocumentLink();
                link.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :insertedCV.Id].ContentDocumentId;
                link.LinkedEntityId = recordId;
                link.ShareType = 'I';
                system.debug('Contentdocumentlink ::'+ link);
                lstContentDocumentLink.add(link);
            }
            
            if(!lstContentDocumentLink.isEmpty()){
                
                insert lstContentDocumentLink;

                system.debug('After insert content document link ::'+ lstContentDocumentLink);
            }


        } catch (Exception e) {
            throw new AuraHandledException('Exception::' + e.getMessage() + '\nGet Line Number' + e.getLineNumber());
        }
    }

	 public class FileWrapper{
        @AuraEnabled public String base64Data{get;set;}
        @AuraEnabled public String fileName{get;set;}
        @AuraEnabled public String label{get;set;}
    }


}