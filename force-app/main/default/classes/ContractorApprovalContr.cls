/**
* @File Name : ContractorApprovalContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 5, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 5, 2025 |   | Initial Version
**/

public without sharing class ContractorApprovalContr {
	@AuraEnabled
	public static void updateWorkOrderApprovalStatus(List<String> reactiveValue, string approvalStatusValue, string Remark){
		
		try {
		System.debug('inside updateWorkOrderApprovalStatus');

		List<WorkOrder> lstWorkOrder = [Select id,Approval_Status_Contractor__c,Contractors_Remark__c from WorkOrder Where Id In: reactiveValue];
	
//OnHold_Reason_Contractor__c
//,ContractorRemark__c
		for(WorkOrder wo :lstWorkOrder){

			wo.Approval_Status_Contractor__c=approvalStatusValue;
			wo.Contractors_Remark__c = Remark;

		}	

		if(!lstWorkOrder.isEmpty()){

			update lstWorkOrder;
		}

		List<WorkOrder> lstWorkOrderMR = [Select id,WorkTypeId,WorkType.Name,CaseId,AccountId,RecordTypeId,Department__c
		 from WorkOrder Where Id In: reactiveValue AND WorkType.Name='Meter Replacement'];


		List<WorkOrder> lstChildWO = new List<Workorder>();

		if(approvalStatusValue=='Rejected'){

			for(WorkOrder womr : lstWorkOrderMR){

				WorkOrder childWO = new WorkOrder();

				childWO.ParentWorkOrderId = womr.Id;
				childWO.CaseId = womr.CaseId;
				childWO.AccountId = womr.AccountId;
								
				childWO.WorkTypeId = womr.WorkTypeId;
				childWO.RecordTypeId = womr.RecordTypeId;

				childWO.Department__c = womr.Department__c;


				lstChildWO.add(childWO);

				
			}
		}

			if(!lstChildWO.isEmpty()){

				insert lstChildWO;

				system.debug('lstChildWO:::'+ lstChildWO);
			}
		}

		
		catch(Exception e){

			system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
		}
	
	}
}