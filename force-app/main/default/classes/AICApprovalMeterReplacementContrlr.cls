/**
* @File Name : AICApprovalMeterReplacementContrlr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 9, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 9, 2025 |   | Initial Version
**/

public class AICApprovalMeterReplacementContrlr {
	@AuraEnabled
	public static void updateWorkOrderApprovalStatus(List<String> reactiveValue, string approvalStatusValue, string Remark){
		
		try {
		System.debug('inside updateWorkOrderApprovalStatus');

		User userDetail = [Select Id,Profile.Name from User Where Id=: UserInfo.getUserId() limit 1];


		List<WorkOrder> lstWorkOrder = [Select id,OwnerId,WorkType.Name,Connection__c,Approval_Status_AIC__c,AICRemark__c,AccountId,CaseId from WorkOrder Where Id In: reactiveValue];
	//OnHold_Reason__c
		//Set<Id> accountIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();
		Set<Id> connectionIds = new Set<Id>();

		Set<Id> updatedWorkorderIds = new Set<Id>();

		for(WorkOrder wo :lstWorkOrder){

			wo.Approval_Status_AIC__c=approvalStatusValue;
			wo.AICRemark__c = Remark;

			if(approvalStatusValue=='Approved'){

				system.debug('approval status approved');				
				wo.OwnerId = userDetail.Id;
				updatedWorkorderIds.add(wo.Id);
			}

			// if(wo.AccountId !=null && approvalStatusValue =='Approved'){
					
			// system.debug('accountid not equal null and status approved');				

			// accountIds.add(wo.AccountId);
			// }
			if(wo.CaseId !=null && approvalStatusValue =='Approved'){

				system.debug('caseid not equal null and status approved');				

            caseIds.add(wo.CaseId);
			}
			if(wo.Connection__c !=null && wo.WorkType.Name=='Riser Maintenance' && approvalStatusValue=='Approved'){

				system.debug('connection not equal null and status approved and work type riser maintenance');				

				connectionIds.add(wo.Connection__c);
			}
			


		}

		if(!lstWorkOrder.isEmpty()){

			update lstWorkOrder;
		}

		// if(!accountIds.isEmpty()){
		// List<Account> lstAccounts = [SELECT Id, Move_Out_Date__c FROM Account WHERE Id IN :accountIds];
		// 	for (Account acc : lstAccounts) {
   		//    acc.Move_Out_Date__c = Date.valueOf(moveOutDate);

		// } 

		// if(!lstAccounts.isEmpty()){
		// 	update lstAccounts;
		// }

		//}

		


	//	if(approvalStatusValue =='Approved' && Remark !=''){

		if(!caseIds.isEmpty()){
		List<Case> lstCases = [SELECT Id,Status,Standard_Remarks__c FROM Case WHERE Id IN :caseIds];
			for (Case cs : lstCases) {
   		 cs.Status = 'Actioned by Department'; 
		 cs.Standard_Remarks__c = Remark;
		// cs.Work_Order_ID__c = '0WOfs000001LKoLGAW';

		 //cs.Move_Out_Date__c=Date.valueOf(moveOutDate);
		}

		if(!lstCases.isEmpty()){

			update lstCases;
		}

		}

		if(!connectionIds.isEmpty()){

			List<Connection__c> lstConnection = [Select id,Last_Maintenance_Date__c	from Connection__c where Id IN:connectionIds];

			for(Connection__c con : lstConnection){

				con.Last_Maintenance_Date__c = System.today();
			}

			if(!lstConnection.isEmpty()){

				update lstConnection;
			}
		}

		List<WorkOrderShare> workOrderOldOwnerDelete = [select id,AccessLevel,UserOrGroup.Name from WorkOrderShare where ParentId IN:updatedWorkorderIds and
				UserOrGroup.Profile.name IN('Field Agent Riser','O&M Field Agent Riser Activity','O&M Supervisor IPD','Field Agent(O&M)- IPD','Field Agent(O&M)- IPD','O&M Supervisor DOMESTIC METER CHECKING','O&M Supervisor DOMESTIC METER CHECKING', 'Field Agent(O&M)- AfterSalesService') ];

		delete workOrderOldOwnerDelete;

		List<ServiceAppointment> lstServiceAppointment = [Select id from ServiceAppointment where parentRecordId IN: updatedWorkorderIds];

		List<AssignedResource> lstAssignedResource = [Select id from AssignedResource where ServiceAppointmentId IN:lstServiceAppointment];


		if(!lstAssignedResource.isEmpty()){
		
		delete lstAssignedResource;

		}
		
		}
		catch(Exception e){

			system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
		}
	
	}
}