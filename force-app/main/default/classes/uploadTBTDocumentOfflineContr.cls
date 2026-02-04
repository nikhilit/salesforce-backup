/**
* @File Name : uploadTBTDocumentOfflineContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : September 29, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 29, 2025 |   | Initial Version
**/

public class uploadTBTDocumentOfflineContr {
	
	@AuraEnabled
	Public static void submitForApproval() {

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
    
}