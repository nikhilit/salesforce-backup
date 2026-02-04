public without sharing class ServiceAppointmentAsyncHandler {
    
    @future
    public static void updateServiceResourceFuture(List<Id> saIds) {
        List<ServiceAppointment> saList = [
            SELECT Id, ParentRecordId 
            FROM ServiceAppointment 
            WHERE Id IN :saIds
        ];

        Map<String, String> mapWoIdToSaId = new Map<String, String>();
        List<AssignedResource> lstAssignedResourceToCreate = new List<AssignedResource>();

        for(ServiceAppointment sA : saList){
            if(sA.ParentRecordId != null){
                mapWoIdToSaId.put(sA.ParentRecordId, sA.Id);
            }
        }

        if(mapWoIdToSaId.isEmpty()) return;

        for(WorkOrder wo : [
            SELECT Id, Agent__c, R_T_Agency__c
            FROM WorkOrder 
            WHERE Id IN :mapWoIdToSaId.keySet() 
              AND Agent__c != null 
              AND R_T_Agency__c != null
              AND RecordType.DeveloperName = 'MGL_R_T'
        ]){
            lstAssignedResourceToCreate.add(new AssignedResource(
                ServiceAppointmentId = mapWoIdToSaId.get(wo.Id),
                ServiceResourceId = wo.Agent__c
            ));
        }

        if(!lstAssignedResourceToCreate.isEmpty()){
            System.debug('lstAssignedResourceToCreate: '+lstAssignedResourceToCreate);
            insert lstAssignedResourceToCreate;
        }
    }
}