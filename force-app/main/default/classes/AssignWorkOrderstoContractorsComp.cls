/**
* @File Name : AssignWorkOrderstoContractorsComp.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 24, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 24, 2025 |   | Initial Version
**/

public without sharing class AssignWorkOrderstoContractorsComp {
	 @AuraEnabled
    public static List<ServiceResource> getContractors() {

		try{


		User userDetail = [Select Id,Profile.Name from User Where Id=: UserInfo.getUserId() limit 1];

		system.debug('Current User details::'+ userDetail);
            
        

		if(userDetail.Profile.Name =='RubberHose AIC' || userDetail.Profile.Name=='O&M AIC Rubber Hose'){

			system.debug('inside aic ipd');

			List<User> lstUser = [Select id,profile.Name from User Where Profile.Name IN ('O&M Rubber Hose Supervisor')];

			Set<Id> ipdSupervisorUsers = new Set<Id>();									

				for(User u : lstUser){

				ipdSupervisorUsers.add(u.Id);

				}	

				List<ServiceResource> lstIPDSupervisor	= [Select id,Name,RelatedRecordId from ServiceResource 
															Where RelatedRecordId=:ipdSupervisorUsers];

				return	lstIPDSupervisor;													

		}

		return new List<ServiceResource>();

		}

		catch(Exception e){

			system.debug('Error returning serviceresource ::'+ e.getMessage() + e.getLineNumber());

			return new List<ServiceResource>();

		}
	}

	@AuraEnabled
	public static String assignAgentToAssignContractors(List<String> reactiveValue, String selectedContractorid){

		try {


		system.debug('inside assignAgentToAssignContractors ::');

	 ServiceResource serResource = [select id,name,RelatedRecordId from ServiceResource where id=:selectedContractorid limit 1];

List<WorkOrder> woList = [Select id,OwnerId	 from WorkOrder where Id IN:reactiveValue];
 
 
    for(WorkOrder woUpd : woList){
		woUpd.OwnerId = serResource.RelatedRecordId;
    }
 
    if(!woList.isEmpty()){
 
        update woList;
    }

	return 'Success';	

}
	catch(Exception e){

		system.debug('Error ::'+ e.getMessage() + e.getLineNumber());

		return 'Error';
	}
	}

}