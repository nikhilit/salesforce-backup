/**
* @File Name : UploadTBTDocumentContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 31, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 31, 2025 |   | Initial Version
**/

public without sharing class UploadTBTDocumentContr {


    
 /*   @AuraEnabled
    public static WorkOrder getApprovalStatus(string recordId) {

        try{

        WorkOrder wOrder = [Select id,Approval_Status__c,WorkType.Name from WorkOrder Where id=:recordId];

    return wOrder;
        //return wOrder.Approval_Status__c ;

    }
    catch(Exception e){

        return new WorkOrder();
       // return 'Error '+ e.getMessage();
    }

    } */

     @AuraEnabled
    public static Document__c getApprovalStatus() {

        try{

            User userDetail = [Select id,Name,UserName from User Where Id=: userInfo.getUserId()];

            Document__c doucmentRecord = [Select id,Submitted_Agent_Name__c,Approval_Status_O_M__c	from Document__c where Submitted_Agent_Name__c=: userDetail.UserName];

          return doucmentRecord;

      //  return doucmentRecord.Approval_Status_O_M__c;

       // WorkOrder wOrder = [Select id,Approval_Status__c,WorkType.Name from WorkOrder Where id=:recordId];

            //return wOrder;
        //return wOrder.Approval_Status__c ;

    }
    catch(Exception e){

        return new Document__c();
       // return 'Error '+ e.getMessage();
    }

    }

    @AuraEnabled
    public static String getApprovalComment(){

        try {

            String recordId;

            string comment='';


              User userDetail = [Select id,Name,UserName from User Where Id=: userInfo.getUserId()];

            List<Document__c> doucmentRecord = [Select id,Submitted_Agent_Name__c,Approval_Status_O_M__c from Document__c where Submitted_Agent_Name__c=: userDetail.UserName limit 1];

        if(!doucmentRecord.isEmpty()){

            recordId = doucmentRecord[0].Id;
        

          ProcessInstanceStep procInst = [SELECT Id, StepStatus, Comments, Actor.Name, CreatedDate 
FROM ProcessInstanceStep where ProcessInstance.TargetObjectId=:recordId 
//and StepStatus !='Started' and StepStatus ='Rejected'
 order by CreatedDate Desc limit 1];
if(procInst.StepStatus !='Rejected'){
    return comment;
}
if(procInst.StepStatus =='Rejected'){
 comment = procInst.Comments;
return comment;
}

        }

return comment;


        }
        catch(Exception e){

return 'Error';
        }

    }

    @AuraEnabled
public static List<ContentDocumentLink> getUploadedFiles() {

    try {
    system.debug('inside get uploaded files'); 

    String recordId;   

      User userDetail = [Select id,Name,UserName from User Where Id=: userInfo.getUserId()];

        List<Document__c> doucmentRecord = [Select id,Submitted_Agent_Name__c,Approval_Status_O_M__c from Document__c where Submitted_Agent_Name__c=: userDetail.UserName limit 1];

    if(!doucmentRecord.isEmpty()){

        recordId = doucmentRecord[0].Id;


    

    List<ContentDocumentLink> lstcontentdocumentlink = [SELECT Id,ContentDocumentId,LinkedEntityId,ContentDocument.Title,
                                                       ContentDocument.LatestPublishedVersion.O_M_Document_Types__c
                                                         FROM ContentDocumentLink WHERE LinkedEntityId =: recordId AND
                                                          SystemModstamp =today order by SystemModstamp desc 
                                                    ];

    system.debug('Return list of content document link::'+ lstcontentdocumentlink);
    return lstcontentdocumentlink;

    }

    return new List<ContentDocumentLink>();
    }
    catch(Exception e){

        System.debug('Error message::' + e.getMessage() + ' ' + e.getLineNumber() );

        return new List<ContentDocumentLink>();
    }
}
        
     @AuraEnabled
        public static void uploadFiles(List<string> fileName, List<string> base64Data, List<string> fileType) {
        
        try {
            system.debug('inside upload file apex class');
            system.debug('File Types ::'+ fileType);

            String recordId;

             User userDetail = [Select id,Name,UserName from User Where Id=: userInfo.getUserId()];

            List<Document__c> doucmentRecord = [Select id,Submitted_Agent_Name__c,Approval_Status_O_M__c from Document__c where Submitted_Agent_Name__c=: userDetail.UserName limit 1];

        if(!doucmentRecord.isEmpty()){

            system.debug('inside if condition document record found');

            recordId = doucmentRecord[0].Id;
        }

        else{

            system.debug('inside else condition document record not found');

            Document__c createDocument = new Document__c();

            createDocument.Submitted_Agent_Name__c = userDetail.UserName;

            insert createDocument;

            system.debug('document record inserted ::'+ createDocument);

            recordId = createDocument.Id;
        }
                                                       
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
                cv.O_M_Document_Types__c=fType;
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

           // updateWorkStepStatus(recordId, 'Upload Site Documents');
           submitForApproval();

        } catch (Exception e) {
            throw new AuraHandledException('Exception::' + e.getMessage() + '\nGet Line Number' + e.getLineNumber());
        }
    }

    
    private static void submitForApproval() {

      try {

      //  system.debug('record id ::'+ recordId);

      String recordId;

        User userDetail = [Select id,Name,UserName,Profile.Name from User Where Id=: userInfo.getUserId()];

            List<Document__c> doucmentRecord = [Select id,Submitted_Agent_Name__c,Approval_Status_O_M__c from Document__c where Submitted_Agent_Name__c=: userDetail.UserName limit 1];

        if(!doucmentRecord.isEmpty()){

            recordId = doucmentRecord[0].Id;

             if(userDetail.Profile.Name =='Field Agent Riser' || userDetail.Profile.Name =='O&M Field Agent Riser Activity'){

  Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    req.setObjectId(recordId);
    req.setProcessDefinitionNameOrId('RiserAICSiteDocumentApprovalProcessTBT'); 
    req.setSkipEntryCriteria(false);

    Approval.ProcessResult result = Approval.process(req);

    if (!result.isSuccess()) {
        throw new AuraHandledException('Approval submission failed. Status: ' + result.getInstanceStatus());
    }


        }

        if(userDetail.Profile.Name =='Field Agent(O&M)- IPD' || userDetail.Profile.Name =='O&M Field Agent IPD' || userDetail.Profile.Name =='O&M Supervisor IPD' ){


        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    req.setObjectId(recordId);
    req.setProcessDefinitionNameOrId('IPDAICSiteDocumentApprovalProcessTBT'); 
    req.setSkipEntryCriteria(false);

    Approval.ProcessResult result = Approval.process(req);

    if (!result.isSuccess()) {
        throw new AuraHandledException('Approval submission failed. Status: ' + result.getInstanceStatus());
    }

        } 

          if(userDetail.Profile.Name =='Domestic Meter Checking Field Agent' || userDetail.Profile.Name =='O&M Field Agent DOMESTIC METER CHECKING' ||  userDetail.Profile.Name =='O&M Supervisor DOMESTIC METER CHECKING' ){


        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    req.setObjectId(recordId);
    req.setProcessDefinitionNameOrId('DMCAICSiteDocumentApprovalProcessTBT'); 
    req.setSkipEntryCriteria(false);

    Approval.ProcessResult result = Approval.process(req);

    if (!result.isSuccess()) {
        throw new AuraHandledException('Approval submission failed. Status: ' + result.getInstanceStatus());
    }

        } 
             
            
             if(userDetail.Profile.Name =='Rubber Hose Field Agent' || userDetail.Profile.Name =='O&M Rubber Hose Supervisor' || userDetail.Profile.Name =='O&M Rubber Hose Field Agent'){

  Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
    req.setObjectId(recordId);
    req.setProcessDefinitionNameOrId('RHAICSiteDocumentApprovalProcessTBT'); 
    req.setSkipEntryCriteria(false);

    Approval.ProcessResult result = Approval.process(req);

    if (!result.isSuccess()) {
        throw new AuraHandledException('Approval submission failed. Status: ' + result.getInstanceStatus());
    }


        }


        }
    
    

        }
        catch(Exception e){

            system.debug('Error call approval process::'+e.getLineNumber() + e.getMessage());
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    

    // @AuraEnabled
    // public static string checkWorkStep(string recordId){

    //     try {

    //         System.debug('inside check work step method in apex');
    //          System.debug('Record id::'+ recordId);

    //    WorkStep worStep = [SELECT Id, Status,Name
	// 		FROM WorkStep
	// 		WHERE ParentRecordId =: recordId AND Name='Check-in'];

    // system.debug('Work step result ::'+ worStep.Status);
    //     return worStep.Status;
    
    // }
    // catch(Exception e){
    //     return 'Error';
    // }
			
    // }
// 	public static void updateWorkStepStatus(Id recordId,String name){
//         List<WorkStep> steps = [
// 			SELECT Id, Status
// 			FROM WorkStep
// 			WHERE ParentRecordId = :recordId
// 			AND Name = :name
// 			LIMIT 1
// 		];
        
//         if (!steps.isEmpty()) {
//             WorkStep ws = steps[0];
//             ws.Status = 'Completed'; // Or whatever picklist value you use
//             update ws;
//         }
// }
}