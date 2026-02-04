/**
* @File Name : UploadTBTDocumentOfflineCont.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 9, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 9, 2025 |   | Initial Version
**/

public without sharing class UploadTBTDocumentOfflineCont {

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
}