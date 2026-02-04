public without sharing class OMAgencyandAgentAfsController {

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


//aboveonewasfirst
@AuraEnabled(cacheable=true)
public static List<ServiceTerritory> getAllAgencies() {

    // Try to find ServiceResource for logged-in user
    List<ServiceResource> srList = [
        SELECT Id
        FROM ServiceResource
        WHERE RelatedRecordId = :UserInfo.getUserId()
        LIMIT 1
    ];

    // ✅ Case 1: Supervisor (has ServiceResource)
    if (!srList.isEmpty()) {
        return [
            SELECT Id, Name
            FROM ServiceTerritory
            WHERE Id IN (
                SELECT ServiceTerritoryId
                FROM ServiceTerritoryMember
                WHERE ServiceResourceId = :srList[0].Id
            )
            AND IsActive = true
        ];
    }

    // ✅ Case 2: AIC user (NO ServiceResource)
    return [
        SELECT Id, Name
        FROM ServiceTerritory
        WHERE IsActive = true
		AND Work_Type__r.Name = 'After Sales Service'
    ];
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



// @AuraEnabled(cacheable=true)
// public static List<ServiceTerritoryMember> getAllAgents() {

//     User userDetail = [
//         SELECT Id, Profile.Name 
//         FROM User 
//         WHERE Id = :UserInfo.getUserId() 
//         LIMIT 1
//     ];

//     System.debug('Current User details: ' + userDetail);

//     // ---------- Supervisor Logic ----------
//     if (userDetail.Profile.Name == 'AIC (O&M- AfterSalesService)' 
//         || userDetail.Profile.Name == 'Supervisor (O&M- AfterSalesService)') 
//     {

//         System.debug('Inside After Sales Supervisor');

//         ServiceResource currentSupervisor = [
//             SELECT Id, Name, RelatedRecordId 
//             FROM ServiceResource 
//             WHERE RelatedRecordId = :userDetail.Id 
//             LIMIT 1
//         ];

//         System.debug('Supervisor ServiceResource: ' + currentSupervisor);

//         List<ServiceTerritoryMember> agents = [
//             SELECT Id, ServiceTerritoryId, ServiceResourceId, Role__c,
//                    ServiceResource.Name,
//                    ServiceResource.RelatedRecord.Name
//             FROM ServiceTerritoryMember
//             WHERE ServiceResource.Supervisor__c = :currentSupervisor.Id
//         ];

//         System.debug('Agents Under Supervisor: ' + agents);

//         return agents;
//     }

//     // ---------- Non-supervisor Logic ----------
//     System.debug('Non supervisor user – returning default STM list.');

//     return [
//         SELECT Id, ServiceTerritoryId, ServiceResourceId, Role__c,
//                ServiceResource.RelatedRecord.Name
//         FROM ServiceTerritoryMember
//         WHERE ServiceResource.Role__c = null
//     ];
// }


//aboveonewasfirst

@AuraEnabled(cacheable=true)
public static List<ServiceTerritoryMember> getAllAgents() {

    User userDetail = [
        SELECT Id, Profile.Name
        FROM User
        WHERE Id = :UserInfo.getUserId()
        LIMIT 1
    ];

    // Check if user has ServiceResource
    List<ServiceResource> srList = [
        SELECT Id
        FROM ServiceResource
        WHERE RelatedRecordId = :userDetail.Id
        LIMIT 1
    ];

    // ✅ Case 1: Supervisor (has ServiceResource)
    if (!srList.isEmpty()) {
        return [
            SELECT Id, ServiceTerritoryId, ServiceResourceId,
                   ServiceResource.Name,
                   ServiceResource.RelatedRecord.Name
            FROM ServiceTerritoryMember
            WHERE ServiceResource.Supervisor__c = :srList[0].Id
        ];
    }

    // ✅ Case 2: AIC (NO ServiceResource → show ALL agents)
    // return [
    //     SELECT Id, ServiceTerritoryId, ServiceResourceId,
    //            ServiceResource.Name,
    //            ServiceResource.RelatedRecord.Name
    //     FROM ServiceTerritoryMember
    //     WHERE ServiceResource.Role__c = null
    // ];

	// ✅ Case 2: AIC user
    // Step 1: Get allowed agencies (After Sales Service)
    List<ServiceTerritory> allowedAgencies = [
        SELECT Id
        FROM ServiceTerritory
        WHERE IsActive = true
        AND Work_Type__r.Name = 'After Sales Service'
    ];

    if (allowedAgencies.isEmpty()) {
        return new List<ServiceTerritoryMember>();
    }

    Set<Id> agencyIds = new Set<Id>();
    for (ServiceTerritory st : allowedAgencies) {
        agencyIds.add(st.Id);
    }

    // Step 2: Get agents only under these agencies
    return [
        SELECT Id, ServiceTerritoryId, ServiceResourceId,
               ServiceResource.Name,
               ServiceResource.RelatedRecord.Name
        FROM ServiceTerritoryMember
        WHERE ServiceTerritoryId IN :agencyIds
        AND ServiceResource.Role__c = null
    ];
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