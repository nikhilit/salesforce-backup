/**
* @File Name : checkCustomerAvalibilityIPDContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 18, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 18, 2025 |   | Initial Version
**/

public without sharing class checkCustomerAvalibilityIPDContr {
	
	@AuraEnabled
	public static void updateWorkOrder(String recordId, String customerAvailability){

		  WorkOrder wo =[Select Id,Check_Customer_Availability__c from WorkOrder where Id=: recordId ];
			
			wo.Id = recordId;
            wo.Check_Customer_Availability__c = customerAvailability;
            
            update wo;

         updateWorkStepStatus(recordId,'Check Customer Availability');

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
    public static string checkWorkStepCheckin(string recordId){

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
    public static string getWOrderWType(string recordId){

        try {

        WorkOrder wOrder = [Select id,WorkType.Name from WorkOrder where Id=:recordId];

        return wOrder.WorkType.Name;
    }

    catch(Exception e){
        return 'Error';
    }

    }

     public class CheckInControllerWrapper {
        @AuraEnabled public WorkOrder documentRecordDetail {get; set;}
        @AuraEnabled public String profileName {get; set;}
    }

      @AuraEnabled
    public static CheckInControllerWrapper getApprovalStatus() {

        try{

            //userDetail.Profile.Name =='Domestic Meter Checking Field Agent' || userDetail.Profile.Name =='O&M Field Agent DOMESTIC METER CHECKING' ||  userDetail.Profile.Name =='O&M Supervisor DOMESTIC METER CHECKING'
//userDetail.Profile.Name =='Rubber Hose Field Agent' || userDetail.Profile.Name =='O&M Rubber Hose Supervisor' || userDetail.Profile.Name =='O&M Rubber Hose Field Agent'
            User userDetail = [Select id,Name,UserName,Profile.Name from User Where Id=: userInfo.getUserId()];
            System.debug(userDetail+'userDetail');

        ServiceResource serResource = [select id,Name from ServiceResource where RelatedRecordId =: userDetail.Id limit 1];
          System.debug(serResource+'serResource');

         WorkOrder wo = [select id,Agent_Name_Formula__c,Agent__c,Approval_Status__c  from workorder where Record_Type_Developer_Name__c ='TBT' and Agent__c =:serResource.Id limit 1];

          //  Document__c doucmentRecord = [Select id,Submitted_Agent_Name__c,Approval_Status_O_M__c	from Document__c where Submitted_Agent_Name__c=: userDetail.UserName];



          CheckInControllerWrapper result = new CheckInControllerWrapper();
            result.documentRecordDetail = wo;
            result.profileName = userDetail.Profile.Name;
            return result;

     
    }
    catch(Exception e){

         return new CheckInControllerWrapper(); // empty if error


       
    }

    }


}