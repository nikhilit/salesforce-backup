/**
* @File Name : AicWorkOrderClosureController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 25, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 25, 2025 |   | Initial Version
**/

public without sharing class AicWorkOrderClosureController {
	@AuraEnabled
	public static void updateWorkOrderApprovalStatus(List<String> reactiveValue, string appointmentStatusValue, string Remark){
		
		try {
		System.debug('inside AicWorkOrderClosureController:::updateWorkOrderApprovalStatus');

		User userDetail = [Select Id,Profile.Name from User Where Id=: UserInfo.getUserId() limit 1];


		List<WorkOrder> lstWorkOrder = [Select id,OwnerId,WorkType.Name,Connection__c,Approval_Status_AIC__c,AICRemark__c,AccountId,CaseId from WorkOrder Where Id In: reactiveValue];
	//OnHold_Reason__c
		Set<Id> accountIds = new Set<Id>();
		Set<Id> caseIds = new Set<Id>();
		Set<Id> connectionIds = new Set<Id>();

		Set<Id> updatedWorkorderIds = new Set<Id>();
		System.debug('appointmentStatusValue:: '+appointmentStatusValue);

		for(WorkOrder wo :lstWorkOrder){

			wo.Appointment_Status__c=appointmentStatusValue;
			// wo.Status=workorderStatusValue;
			wo.AICRemark__c = Remark;

			if(appointmentStatusValue =='Completed'){
								
				wo.OwnerId = userDetail.Id;
				updatedWorkorderIds.add(wo.Id);
			}

			if(wo.AccountId !=null && appointmentStatusValue =='Completed'){
			accountIds.add(wo.AccountId);
			}
			if(wo.CaseId !=null && appointmentStatusValue =='Completed'){
            caseIds.add(wo.CaseId);
			}
			if(wo.Connection__c !=null && wo.WorkType.Name=='Rubber Hose Replacement' && appointmentStatusValue=='Completed' ){

				connectionIds.add(wo.Connection__c);
			}
		}

		if(!lstWorkOrder.isEmpty()){

			update lstWorkOrder;
		}
			System.debug('lstWorkOrder::'+lstWorkOrder);
			
		List<WorkOrderShare> workOrderOldOwnerDelete = [select id,AccessLevel,UserOrGroup.Name from WorkOrderShare where ParentId IN:updatedWorkorderIds AND
				UserOrGroup.Profile.name IN('Field Agent Riser','O&M Field Agent Riser Activity','O&M Supervisor IPD','Field Agent(O&M)- IPD','Field Agent(O&M)- IPD','O&M Supervisor DOMESTIC METER CHECKING','O&M Supervisor DOMESTIC METER CHECKING',
				'O&M Rubber Hose Supervisor','Rubber Hose Field Agent', 'Field Agent(O&M)- AfterSalesService' ) ];
	 if (!workOrderOldOwnerDelete.isEmpty()) {
		delete workOrderOldOwnerDelete;
		}
		// List<ServiceAppointment> lstServiceAppointment = [Select id from ServiceAppointment where parentRecordId IN: updatedWorkorderIds];
		// List<ServiceAppointment> toupdateservappointments=new List<ServiceAppointment>();

		// List<AssignedResource> lstAssignedResource = [Select id from AssignedResource where ServiceAppointmentId IN:lstServiceAppointment];

		// List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();

		// if (!lstServiceAppointment.isEmpty()) {
		// 	for (ServiceAppointment sa : lstServiceAppointment) {
		// 		sa.Status = 'Completed';
		// 		saToUpdate.add(sa);
		// 	}
		// }

		// if (!saToUpdate.isEmpty()) {
		// 	System.debug('saToUpdate::'+saToUpdate);
		// 	update saToUpdate;
		// }


		// if(!lstAssignedResource.isEmpty()){
		
		// delete lstAssignedResource;

		// }

		if(!caseIds.isEmpty()){
		List<Case> lstCases = [SELECT Id,Status,Standard_Remarks__c FROM Case WHERE Id IN :caseIds];
			for (Case cs : lstCases) {
   		 cs.Status = 'Actioned by Department'; 
		 cs.Standard_Remarks__c = Remark;
		}

		if(!lstCases.isEmpty()){

			update lstCases;
		}
		System.debug('lstCases::'+lstCases);
		}

		// if(!connectionIds.isEmpty()){

		// 	List<Connection__c> lstConnection = [Select id,Last_Maintenance_Date__c	from Connection__c where Id IN:connectionIds];

		// 	for(Connection__c con : lstConnection){

		// 		con.Last_Maintenance_Date__c = System.today();
		// 	}

		// 	if(!lstConnection.isEmpty()){

		// 		update lstConnection;
		// 	}
		// }	
		}
		catch(Exception e){

			system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
		}
	
	}

	@AuraEnabled
	public static String workorderwithdrawallocation(List<String> reactiveValue){
		
		try {
		System.debug('inside workorderwithdrawallocation');

		if(reactiveValue == null || reactiveValue.isEmpty()){
           return 'No work orders selected.';
        }

		User userDetail = [Select Id,Profile.Name from User Where Id=: UserInfo.getUserId() limit 1];


		List<WorkOrder> lstWorkOrder = [Select id,OwnerId,WorkType.Name,ServiceTerritoryId,Agent__c from WorkOrder Where Id In: reactiveValue];

		Set<Id> updatedWorkorderIds = new Set<Id>();

		for(WorkOrder wo :lstWorkOrder){

			wo.ServiceTerritoryId=null;//lookup
			wo.Agent__c = null;//lookup
			wo.Ownerid=userDetail.id;
		  updatedWorkorderIds.add(wo.Id);
		}

		if(!lstWorkOrder.isEmpty()){
			System.debug('lstWorkOrder::'+lstWorkOrder);
			update lstWorkOrder;
		}

		List<WorkOrderShare> workOrderOldOwnerDelete = [
    SELECT Id, AccessLevel, UserOrGroup.Name, RowCause 
    FROM WorkOrderShare 
    WHERE ParentId IN :updatedWorkorderIds AND UserOrGroup.id != :userDetail.id
    AND UserOrGroup.Profile.Name IN (
        'Field Agent Riser',
        'O&M Field Agent Riser Activity',
        'O&M Supervisor IPD',
        'Field Agent(O&M)- IPD',
        'O&M Supervisor DOMESTIC METER CHECKING',
        'O&M Rubber Hose Supervisor',
        'Rubber Hose Field Agent',
        'Field Agent(O&M)- AfterSalesService'
    )
];

		delete workOrderOldOwnerDelete;

		List<ServiceAppointment> lstServiceAppointment = [Select id from ServiceAppointment where parentRecordId IN: updatedWorkorderIds];
		for (ServiceAppointment sp : lstServiceAppointment) {
			sp.SchedStartTime = null;
			sp.SchedEndTime = null;
		}

		if (!lstServiceAppointment.isEmpty()) {
			update lstServiceAppointment;
		}

		List<AssignedResource> lstAssignedResource = [Select id from AssignedResource where ServiceAppointmentId IN:lstServiceAppointment];


		if(!lstAssignedResource.isEmpty()){
		System.debug('lstAssignedResource:::'+lstAssignedResource);
		delete lstAssignedResource;

		}

		return 'Records Updated Successfully!';
			
		}
		catch(Exception e){

			system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
			 throw new AuraHandledException('Error: ' + e.getMessage());
		}
	
	}

}