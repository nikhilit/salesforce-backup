/**
* @File Name : CreateAssignAgentFromConnectionContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 29, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 29, 2025 |   | Initial Version
**/

public without sharing class CreateAssignAgentFromConnectionContr {

	
	
	public static void createAssignedResource(List<ServiceAppointment> lstServiceAppointment){


		try {
String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                                            .get('MGL_Metering').getRecordTypeId();

			Set<Id> worOrderId = new Set<Id>();

			 for (ServiceAppointment sa : lstServiceAppointment) {
   				 if (sa.ParentRecordId != null) {

				worOrderId.add(sa.ParentRecordId); 
			 }
			 }

             system.debug('work order map id::'+ worOrderId);

Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>(
    [SELECT Id, StartDate,RecordTypeId FROM WorkOrder WHERE Id IN :worOrderId AND RecordTypeId!=:meteringRecordTypeId]
);

  System.debug('WorkOrder Map: ' + woMap);

List<ServiceAppointment> saToUpdate = new List<ServiceAppointment>();

for (ServiceAppointment sa : lstServiceAppointment) {
    if(woMap.containsKey(sa.ParentRecordId)){
        WorkOrder wo = woMap.get(sa.ParentRecordId); // ✅ Use Map.get()
        if (wo != null && wo.StartDate != null) {
            
            sa.SchedStartTime = wo.StartDate;
            sa.SchedEndTime = wo.StartDate.addDays(3);
            saToUpdate.add(sa);
        }
    }
}

if (!saToUpdate.isEmpty()) {
    update saToUpdate;
    System.debug('✅ Updated Service Appointments: ' + saToUpdate);
}




	
	}
	catch(Exception e){

		system.debug('Error ::'+ e.getLineNumber() + e.getMessage());
	}


	}

    public static void createAssignedResourceRecord(List<ServiceAppointment> lstServiceAppointment){

        try {
            String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                                            .get('MGL_Metering').getRecordTypeId();
		 Set<Id> ownerIds = new Set<Id>();
        for (ServiceAppointment sa : lstServiceAppointment) {
            if (sa.OwnerId != null) {
                ownerIds.add(sa.OwnerId);
            }
        }

        Set<Id> serAppIds = new Set<Id>();
            Set<Id> setWorkOrderId=new Set<Id>();
        for(ServiceAppointment serApp : lstServiceAppointment){
                if (serApp.ParentRecordId != null) {
                    setWorkOrderId.add(serApp.ParentRecordId);
                }
            serAppIds.add(serApp.Id);
            
        }
            
            Map<Id, WorkOrder> woMap = new Map<Id, WorkOrder>(
    [SELECT Id, StartDate,RecordTypeId FROM WorkOrder WHERE Id IN :setWorkOrderId AND RecordTypeId!=:meteringRecordTypeId]
);


		system.debug('Serviceappointment ownerids ::'+ ownerIds);

		 Map<Id, ServiceResource> userIdToServiceResourceMap = new Map<Id, ServiceResource>();
        for (ServiceResource sr : [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId IN :ownerIds
        ]) {
            userIdToServiceResourceMap.put(sr.RelatedRecordId, sr);
        }

				system.debug('userIdToServiceResourceMap  ::'+userIdToServiceResourceMap);


		List<AssignedResource> lstAssignedResource = new List<AssignedResource>();

		for(ServiceAppointment serAppointment : lstServiceAppointment){
		 ServiceResource sr = userIdToServiceResourceMap.get(serAppointment.OwnerId);
            if(serAppointment.ParentRecordId !=null && woMap.containsKey(serAppointment.ParentRecordId)){
                
                if (sr != null) {
    
                    system.debug('inside create assigned resource');
                AssignedResource assResource = new AssignedResource();
                assResource.ServiceAppointmentId = serAppointment.Id;
                assResource.ServiceResourceId = sr.Id;
    
                lstAssignedResource.add(assResource);
    
                        system.debug('assResource  ::'+ assResource);
    
    
                }
            }

		}

		if(!lstAssignedResource.isEmpty()){

			system.debug('lstAssignedResource  ::'+ lstAssignedResource);


			insert lstAssignedResource;


		}

        List<ServiceAppointment> lstServiceAppointmentUpdate =[Select id,Status,ParentRecord.RecordTypeId from ServiceAppointment where Id IN: serAppIds AND ParentRecord.RecordTypeId!=:meteringRecordTypeId];

        for(ServiceAppointment lstUpdateSerAppo : lstServiceAppointmentUpdate){
	
            lstUpdateSerAppo.Status='Dispatched';
        }

        if(!lstServiceAppointmentUpdate.isEmpty()){

            update lstServiceAppointmentUpdate;
        }


        }

        catch(Exception e){
            system.debug('error:'+ e.getMessage() + e.getLineNumber());
        }

    }
}