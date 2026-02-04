/**
* @File Name : AssignServiceAppointmentToAgentContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : June 4, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 4, 2025 |   | Initial Version
**/

public without sharing class AssignServiceAppointmentToAgentContr {
    


	  @AuraEnabled
    public static List<ServiceResource> getContractorAgents() {



		try{


		User userDetail = [Select Id,Profile.Name from User Where Id=: UserInfo.getUserId() limit 1];

		system.debug('Current User details::'+ userDetail);
            
            

		if(userDetail.Profile.Name =='AIC (O&M- IPD)' || userDetail.Profile.Name=='O&M AIC IPD'){

			system.debug('inside aic ipd');

			List<User> lstUser = [Select id,profile.Name from User Where Profile.Name IN ('Supervisor (O&M- IPD)', 'O&M Supervisor IPD','O&M Field Agent IPD')];

			Set<Id> ipdSupervisorUsers = new Set<Id>();									

				for(User u : lstUser){

				ipdSupervisorUsers.add(u.Id);

				}	

				List<ServiceResource> lstIPDSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:ipdSupervisorUsers];

				return	lstIPDSupervisor;													

		}

		if(userDetail.Profile.Name =='Supervisor (O&M- IPD)' || userDetail.Profile.Name=='O&M Supervisor IPD'){

			system.debug('inside ipd supervisor');

			

				ServiceResource currentSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:userDetail.Id limit 1];

			system.debug('serviceresource current supervisor::'+ currentSupervisor);
			List<ServiceResource> lstSupervisorAndAgents = [Select id,Name,Supervisor__c from ServiceResource
																where Id=:currentSupervisor.id OR Supervisor__c=:currentSupervisor.id];


			system.debug('list of agents::'+ lstSupervisorAndAgents);
				return	lstSupervisorAndAgents;		


		}

		if(userDetail.Profile.Name =='RubberHose AIC' || userDetail.Profile.Name=='O&M AIC Rubber Hose'){

			system.debug('inside aic rubber aic');

			List<User> lstUser = [Select id,profile.Name from User Where Profile.Name IN ('Supervisor (O&M)', 'O&M Rubber Hose Supervisor','O&M Rubber Hose Field Agent')];

			Set<Id> ipdSupervisorUsers = new Set<Id>();									

				for(User u : lstUser){

				ipdSupervisorUsers.add(u.Id);

				}	

				List<ServiceResource> lstIPDSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:ipdSupervisorUsers];

				return	lstIPDSupervisor;													

		}

		if(userDetail.Profile.Name =='AIC (O&M- I&CCommercialMaintenance)'){

			system.debug('inside aic i&c commerical maintenance');

			List<User> lstUser = [Select id,profile.Name from User Where Profile.Name IN ('Supervisor (O&M-I&CCommercialMaintenance)', 'Field Agent(O&M)-I&CCommercialMaintenance')];

			Set<Id> ipdSupervisorUsers = new Set<Id>();									

				for(User u : lstUser){

				ipdSupervisorUsers.add(u.Id);

				}	

				List<ServiceResource> lstIPDSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:ipdSupervisorUsers];

				return	lstIPDSupervisor;													

		}

		if(userDetail.Profile.Name =='Supervisor (O&M-I&CCommercialMaintenance)'){

			system.debug('inside i&c commerical maintenance supervisor');

			

				ServiceResource currentSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:userDetail.Id limit 1];

			system.debug('serviceresource current supervisor::'+ currentSupervisor);
			List<ServiceResource> lstSupervisorAndAgents = [Select id,Name,Supervisor__c from ServiceResource
																where  Supervisor__c=:currentSupervisor.id];


			system.debug('list of agents::'+ lstSupervisorAndAgents);
				return	lstSupervisorAndAgents;			


		}

		if(userDetail.Profile.Name =='Supervisor (O&M)' || userDetail.Profile.Name=='O&M Rubber Hose Supervisor'){

			system.debug('inside rubberhose supervisor');

			

				ServiceResource currentSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:userDetail.Id limit 1];

			system.debug('serviceresource current supervisor::'+ currentSupervisor);
			List<ServiceResource> lstSupervisorAndAgents = [Select id,Name,Supervisor__c from ServiceResource
																where  Supervisor__c=:currentSupervisor.id];


			system.debug('list of agents::'+ lstSupervisorAndAgents);
				return	lstSupervisorAndAgents;			


		}


		if(userDetail.Profile.Name =='AIC (O&M- Domestic Meter Checking)' || userDetail.Profile.Name=='O&M AIC DOMESTIC METER CHECKING'){

			system.debug('inside aic ipd');

			List<User> lstUser = [Select id,profile.Name from User Where Profile.Name IN ('Supervisor (O&M)', 'O&M Supervisor DOMESTIC METER CHECKING', 'O&M Field Agent DOMESTIC METER CHECKING')];

			Set<Id> ipdSupervisorUsers = new Set<Id>();									

				for(User u : lstUser){

				ipdSupervisorUsers.add(u.Id);

				}	

				List<ServiceResource> lstIPDSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:ipdSupervisorUsers];

				return	lstIPDSupervisor;													

		}

		if(userDetail.Profile.Name =='Supervisor (O&M- Domestic Meter Checking)' || userDetail.Profile.Name=='O&M Supervisor DOMESTIC METER CHECKING'){

			system.debug('inside ipd supervisor');

			

				ServiceResource currentSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:userDetail.Id limit 1];

			system.debug('serviceresource current supervisor::'+ currentSupervisor);
			List<ServiceResource> lstSupervisorAndAgents = [Select id,Name,Supervisor__c from ServiceResource
																where Id=:currentSupervisor.id OR Supervisor__c=:currentSupervisor.id];


			system.debug('list of agents::'+ lstSupervisorAndAgents);
				return	lstSupervisorAndAgents;		


		}

		if(userDetail.Profile.Name =='Supervisor (O&M- AfterSalesService)'){

			system.debug('inside after sales supervisor');

			

				ServiceResource currentSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:userDetail.Id limit 1];

			system.debug('serviceresource current supervisor::'+ currentSupervisor);
			List<ServiceResource> lstSupervisorAndAgents = [Select id,Name,Supervisor__c from ServiceResource
																where  Supervisor__c=:currentSupervisor.id];


			system.debug('list of agents::'+ lstSupervisorAndAgents);
				return	lstSupervisorAndAgents;		

			

		} 

		if(userDetail.Profile.Name =='Supervisor (O&M- Meter Replacement)'){

			system.debug('inside after sales supervisor');

			

				ServiceResource currentSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:userDetail.Id limit 1];

			system.debug('serviceresource current supervisor::'+ currentSupervisor);
			List<ServiceResource> lstSupervisorAndAgents = [Select id,Name,Supervisor__c from ServiceResource
																where  Supervisor__c=:currentSupervisor.id];


			system.debug('list of agents::'+ lstSupervisorAndAgents);
				return	lstSupervisorAndAgents;		

			

		} 

		return new List<ServiceResource>();

		}

		catch(Exception e){

			system.debug('Error returning serviceresource ::'+ e.getMessage() + e.getLineNumber());

			return new List<ServiceResource>();

		}
      
	  
	  
	  /*  try {
            System.debug('DEBUG: Entered getCurrentContractorAgent');
            ServiceResource contractor = [
                SELECT Id, Agency__c
                FROM ServiceResource
                WHERE RelatedRecordId = :UserInfo.getUserId()
                AND (Role__c = 'Contractor' OR Service_Resource_Type__c='Contractor')
                LIMIT 1
            ];

            System.debug('DEBUG: Contractor: ' + contractor);

			List<ServiceTerritoryMember> lstSTM = [Select id,ServiceResource.Name,serviceResource.Role__c,serviceResource.Service_Resource_Type__c
							 from ServiceTerritoryMember where ServiceTerritoryId =: contractor.Agency__c
														AND (serviceResource.Role__c='' AND serviceResource.Service_Resource_Type__c !='Contractor') ];


            System.debug('DEBUG: Found Agents: ' + lstSTM);
            return lstSTM;
        } catch (Exception e) {
            System.debug('DEBUG: Exception in getNormalAgents: ' + e.getMessage());
            throw new AuraHandledException('Error fetching agents: ' + e.getMessage());
        } */
    }

	@AuraEnabled
	public static String assignAgentToAssignResource(List<String> reactiveValue, String selectedAgentId,DateTime selectedDateTime , DateTime selectedEndDateTime){

		try {


		system.debug('inside ssignAgentToAssignResource ::');

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
        }

        if (upSeApp.SchedEndTime == null || String.valueOf(upSeApp.SchedEndTime).trim() == '') {
							system.debug('inside end date empty');

							if(selectedEndDateTime !=null){

			 upSeApp.SchedEndTime = selectedEndDateTime;

							}else{

							 upSeApp.SchedEndTime = upSeApp.SchedStartTime.addDays(3);


							}


        }
		//upSeApp.Status='Dispatched';
			}
			update lstSerAppointment;
		}
		system.debug('inside ssignAgentToAssignResource ::');

				system.debug('Reactive values ::'+ reactiveValue);

			//Set<Id> selectedAgentNotAssignedId  = new Set<Id>();

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
		// if((!selectedAgentNotAssignedId.contains(serApp.Id))){
		
		AssignedResource assResource = new AssignedResource();

		assResource.ServiceAppointmentId=serApp.Id;
		assResource.ServiceResourceId=selectedAgentId;

		lstAssResource.add(assResource);

		system.debug('assResource ::'+ assResource);

		//}

	}

	if(!lstAssResource.isEmpty()){

		insert lstAssResource;
		system.debug('lstAssResource ::'+ lstAssResource);

	for(ServiceAppointment serApp : lstSerAppointment){

	serApp.Status = 'Dispatched';

	}

	update lstSerAppointment;

	system.debug('lstSerAppointment ::'+ lstSerAppointment);

	// Set<Id> updWOIds = new Set<Id>();

	// if(!lstAssResource.isEmpty()){

	// for(AssignedResource assRes : lstAssResource){

	// 	updWOIds.add(assRes.ServiceAppointment.ParentRecordId);

	// }
	// }

List<WorkOrder> woList = [Select id,OwnerId,Technician_Assigned__c,Agent__c,Agent__r.RelatedRecordId,Assigned_Resource_Date__c	 from WorkOrder where Id IN:reactiveValue];
 
 ServiceResource serResource = [select id,name,RelatedRecordId from ServiceResource where id=:selectedAgentId limit 1];
 
    for(WorkOrder woUpd : woList){
 
        woUpd.Technician_Assigned__c = true;
		woUpd.Agent__c = selectedAgentId;
		woUpd.Assigned_Resource_Date__c	= System.today();
		woUpd.OwnerId = serResource.RelatedRecordId;
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