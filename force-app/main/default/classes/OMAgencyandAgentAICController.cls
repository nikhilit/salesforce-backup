/**
* @File Name : OMAgencyandAgentController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 28, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 28, 2025 |   | Initial Version
**/

public without sharing class OMAgencyandAgentAICController {

// @AuraEnabled(cacheable=true)
// public static List<ServiceTerritory> getAllAgencies() {

//     ServiceResource sr = [
//         SELECT Id 
//         FROM ServiceResource 
//         WHERE RelatedRecordId = :UserInfo.getUserId()
//         LIMIT 1
//     ];

//     List<ServiceTerritory> agencies = [
//         SELECT Id, Name
//         FROM ServiceTerritory
//         WHERE Id IN (
//             SELECT ServiceTerritoryId
//             FROM ServiceTerritoryMember
//             WHERE ServiceResourceId = :sr.Id
//         )
//         AND IsActive = true
//     ];

//     return agencies;
// }


@AuraEnabled(cacheable=true)
public static List<ServiceTerritory> getAllAgencies() {

try {

User userDetail = [Select Id,Profile.Name from User Where Id=: UserInfo.getUserId() limit 1];

		system.debug('Current User details::'+ userDetail);
            
            

		if(userDetail.Profile.Name =='AIC (O&M- Meter Replacement)'){

			system.debug('inside aic ipd');

			List<User> lstUser = [Select id,profile.Name from User Where Profile.Name IN ('Field Agent(O&M- Meter Replacement)')];

			Set<Id> mrSupervisorUsers = new Set<Id>();									

				for(User u : lstUser){

				mrSupervisorUsers.add(u.Id);

				}	

				List<ServiceResource> lstMRSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:mrSupervisorUsers];


					List<ServiceTerritoryMember> lstSerTeMember = [SELECT ServiceTerritoryId
																		FROM ServiceTerritoryMember
																		WHERE ServiceResourceId  IN:lstMRSupervisor];

			Set<Id> serterIds = new Set<Id>();

			for(ServiceTerritoryMember sertMemb : lstSerTeMember){

				serterIds.add(sertMemb.ServiceTerritoryId);
			}


			List<ServiceTerritory> lstServiceTerritory = [SELECT Id, Name FROM ServiceTerritory where Id IN: serterIds];
				
		
    		return lstServiceTerritory;

		}

		return new List<ServiceTerritory>();

}

catch(Exception e){

	System.debug('Error returning service territory ::'+ e.getLineNumber() + e.getMessage());

			return new List<ServiceTerritory>();

}
}


//  @AuraEnabled(cacheable=true)
//     public static List<ServiceTerritory> getAllAgencies() {
//         Id recordTypeId = Schema.SObjectType.ServiceTerritory
//             .getRecordTypeInfosByDeveloperName()
//             .get('O_M').getRecordTypeId();

//         return [
//             SELECT Id, Name 
//             FROM ServiceTerritory
//             WHERE IsActive = true AND RecordTypeId = :recordTypeId
//         ];
//     }
@AuraEnabled
public static List<ServiceResource> getAllAgents() {

 	User userDetail = [Select Id,Profile.Name from User Where Id=: UserInfo.getUserId() limit 1];

		system.debug('Current User details::'+ userDetail);
            
            

		if(userDetail.Profile.Name =='AIC (O&M- Meter Replacement)'){

			system.debug('inside aic ipd');

			List<User> lstUser = [Select id,profile.Name from User Where Profile.Name IN ('Field Agent(O&M- Meter Replacement)')];

			Set<Id> mrSupervisorUsers = new Set<Id>();									

				for(User u : lstUser){

				mrSupervisorUsers.add(u.Id);

				}	

				List<ServiceResource> lstMRSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:mrSupervisorUsers];

				return	lstMRSupervisor;													

		}

				return new List<ServiceResource>();

}


	// @AuraEnabled(cacheable=true)
    // public static List<ServiceTerritoryMember> getAllAgents() {
    //     return [
    //         SELECT Id, ServiceTerritoryId, ServiceResourceId,Role__c,
    //             ServiceResource.RelatedRecord.Name
    //         FROM ServiceTerritoryMember
    //         WHERE ServiceResource.Role__c = null
    //     ];
    // }


	 @AuraEnabled(cacheable=true)
    public static List<ServiceTerritoryMember> getAgentsByAgency(Id agencyId) {
        return [
            SELECT Id, ServiceResourceId, ServiceResource.RelatedRecord.Name
            FROM ServiceTerritoryMember
            WHERE ServiceTerritoryId = :agencyId
            AND ServiceResource.Role__c = null
        ];
    }

	@AuraEnabled(cacheable=true)
    public static List<ServiceTerritory> getAgenciesByAgent(Id agentId) {
        return [
            SELECT Id, Name
            FROM ServiceTerritory
            WHERE Id IN (
                SELECT ServiceTerritoryId
                FROM ServiceTerritoryMember
                WHERE ServiceResourceId = :agentId
            )
        ];
    }

    @AuraEnabled
	public static String assignAgency(List<String> reactiveValue,Id agencyId, Id selectedAgentId,DateTime selectedDateTime , DateTime selectedEndDateTime){

		try {
        if (reactiveValue == null || reactiveValue.isEmpty()) {
            return 'No work orders selected.';
        }

		system.debug('inside ssignAgentToAssignResource ::');

         // 2️⃣ Check if selected Agent belongs to selected Agency (Service Territory)
        List<ServiceTerritoryMember> checkMember = [
            SELECT Id, ServiceTerritoryId, ServiceResourceId 
            FROM ServiceTerritoryMember
            WHERE ServiceTerritoryId = :agencyId
              AND ServiceResourceId = :selectedAgentId
            LIMIT 1
        ];

        if (checkMember.isEmpty()) {
            System.debug('Selected agent does NOT belong to the selected agency. Please choose another agent.');
            // return 'Selected agent does NOT belong to the selected agency. Please choose another agent.';
              throw new AuraHandledException('Selected agent does NOT belong to the selected agency. Please choose another agent.');
        }

		List<ServiceAppointment> lstSerAppointment = [Select id,SchedStartTime,SchedEndTime,Status,ParentRecordId,Work_Order__c from ServiceAppointment where ParentRecordId IN: reactiveValue];

		if(!lstSerAppointment.isEmpty()){

			system.debug('indie check empty ser app');

			for(ServiceAppointment upSeApp : lstSerAppointment){


				upSeApp.Work_Order__c = upSeApp.ParentRecordId;
			 if (upSeApp.SchedStartTime == null || String.valueOf(upSeApp.SchedStartTime).trim() == '') {
				system.debug('inside start date empty');

				if(selectedDateTime !=null){
			 upSeApp.SchedStartTime = selectedDateTime;
				}
				else {
            	upSeApp.SchedStartTime = System.now();
				}

                upSeApp.ServiceTerritoryId = agencyId;
        }

        if (upSeApp.SchedEndTime == null || String.valueOf(upSeApp.SchedEndTime).trim() == '') {
							system.debug('inside end date empty');

							if(selectedEndDateTime !=null){
			                upSeApp.SchedEndTime = selectedEndDateTime;
							}else{
							 upSeApp.SchedEndTime = upSeApp.SchedStartTime.addDays(3);
							}
        }
			}
			update lstSerAppointment;
		}
		system.debug('inside ssignAgentToAssignResource ::');

				system.debug('Reactive values ::'+ reactiveValue);
	List<AssignedResource> allReadyassignedResource =[select id,ServiceResourceId,ServiceAppointmentId from 
													AssignedResource where ServiceAppointmentId IN:lstSerAppointment 
													 ];

		system.debug('allReadyassignedResource ::'+ allReadyassignedResource);


		Set<Id> needUpdSerApp = new Set<Id>();

		Set<Id> assignedResoId = new Set<Id>();


		for(AssignedResource assResDel : allReadyassignedResource){

			system.debug('inside find assigned resource list');

			assignedResoId.add(assResDel.Id);
			needUpdSerApp.add(assResDel.ServiceAppointmentId);

		}

		List<AssignedResource> deleteAssignResource = [Select id from AssignedResource Where id IN:assignedResoId];

		system.debug('list of need to delete assigned resource::'+ deleteAssignResource);

		delete deleteAssignResource;

		system.debug('after delete list of need to delete assigned resource::'+ deleteAssignResource);


		Set<Id> updWOrder = new Set<Id>();

		List<serviceappointment> upddelAssiResServiceApp =[Select id,ParentRecordId,SchedStartTime,SchedEndTime,Status from ServiceAppointment Where Id IN:needUpdSerApp];

		for(ServiceAppointment addWOrderId : upddelAssiResServiceApp){

			updWOrder.add(addWOrderId.ParentRecordId);
		}


		for(ServiceAppointment updSerApp : upddelAssiResServiceApp){


			updSerApp.SchedStartTime=null;
			updSerApp.SchedEndTime=null;


			if (updSerApp.SchedStartTime == null || String.valueOf(updSerApp.SchedStartTime).trim() == '') {
				system.debug('inside start date empty');
				if(selectedDateTime !=null){
					system.debug('insde selected time no empty');
			 updSerApp.SchedStartTime = selectedDateTime;
				}
				else {
					system.debug('insde selected time  empty');
            	updSerApp.SchedStartTime = System.now();

				}
                
        }

        if (updSerApp.SchedEndTime == null || String.valueOf(updSerApp.SchedEndTime).trim() == '') {
							system.debug('inside end date empty');

							if(selectedEndDateTime !=null){
            system.debug('insde selected end time no empty');
			 updSerApp.SchedEndTime = selectedEndDateTime;
							}else{
				system.debug('insde selected end time empty');
				updSerApp.SchedEndTime = updSerApp.SchedStartTime.addDays(3);
							}
			
		}

		}

		if (!upddelAssiResServiceApp.isEmpty()) {
   		 update upddelAssiResServiceApp;
		 system.debug('upddelAssiResServiceApp::'+upddelAssiResServiceApp);
		}

		List<WorkOrder> updWOAgAppStatusField = [Select id,Agent__c,Appointment_Status__c from WorkOrder where id IN:updWOrder];

		for(WorkOrder woUpdField : updWOAgAppStatusField){

			woUpdField.Agent__c = null;
			woUpdField.Appointment_Status__c ='Unattempted';
		}

		if(!updWOAgAppStatusField.isEmpty()){
			update updWOAgAppStatusField;
		}


	List<AssignedResource> lstAssResource = new List<AssignedResource>();

	for(ServiceAppointment serApp : lstSerAppointment){
		system.debug('inside for loop');
		AssignedResource assResource = new AssignedResource();

		assResource.ServiceAppointmentId=serApp.Id;
		assResource.ServiceResourceId=selectedAgentId;
		lstAssResource.add(assResource);

		system.debug('assResource ::'+ assResource);
	}

	if(!lstAssResource.isEmpty()){

		insert lstAssResource;
		system.debug('lstAssResource ::'+ lstAssResource);

	for(ServiceAppointment serApp : lstSerAppointment){

	serApp.Status = 'Dispatched';


	}

	update lstSerAppointment;

	system.debug('lstSerAppointment ::'+ lstSerAppointment);
    List<WorkOrder> woList = [Select id,OwnerId,Technician_Assigned__c,Agent__c,Agent__r.RelatedRecordId,Assigned_Resource_Date__c	 from WorkOrder where Id IN:reactiveValue];
    ServiceResource serResource = [select id,name,RelatedRecordId from ServiceResource where id=:selectedAgentId limit 1];
 
    for(WorkOrder woUpd : woList){
         woUpd.Technician_Assigned__c = true;
		woUpd.Agent__c = selectedAgentId;
        woUpd.ServiceTerritoryId=agencyId;
		woUpd.Assigned_Resource_Date__c	= System.today();
		woUpd.OwnerId = serResource.RelatedRecordId;
        woUpd.StartDate = selectedDateTime;
        woUpd.EndDate = selectedEndDateTime;
    }
 
    if(!woList.isEmpty()){
 
        update woList;
		system.debug('woList ::'+ woList);
    }
	}

	return 'Success';

	}
	catch(Exception e){

		system.debug('Error ::'+ e.getMessage() + e.getLineNumber());

		return 'Error';
	}
	}


}