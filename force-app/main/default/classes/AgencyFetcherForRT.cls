public without sharing class AgencyFetcherForRT {

    public static Id recordTypeId = Schema.SObjectType.ServiceTerritory.getRecordTypeInfosByDeveloperName().get('R_T').getRecordTypeId();
    
    @AuraEnabled(cacheable=true)
    public static List<ServiceTerritory> getAllAgencies() {
        Id recordTypeId = Schema.SObjectType.ServiceTerritory
            .getRecordTypeInfosByDeveloperName()
            .get('R_T').getRecordTypeId();

        return [
            SELECT Id, Name 
            FROM ServiceTerritory
            WHERE IsActive = true AND RecordTypeId = :recordTypeId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceTerritoryMember> getAllAgents() {
        return [
            SELECT Id, ServiceTerritoryId, ServiceResourceId,
                ServiceResource.RelatedRecord.Name
            FROM ServiceTerritoryMember
            WHERE ServiceResource.Service_Resource_Type__c IN ('Collection Agent', 'I&C Agent')
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<ServiceTerritoryMember> getAgentsByAgency(Id agencyId) {
        return [
            SELECT Id, ServiceResourceId, ServiceResource.RelatedRecord.Name
            FROM ServiceTerritoryMember
            WHERE ServiceTerritoryId = :agencyId
            AND ServiceResource.Service_Resource_Type__c IN ('Collection Agent', 'I&C Agent')
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
    public static void assignAgency(
        List<Id> workOrderIds,
        Id agencyId,
        Id agentId,
        //Id workTypeId,
        Datetime startDate,
        Datetime endDate
    ) {
        try {
            if (workOrderIds == null || workOrderIds.isEmpty()) {
                throw new AuraHandledException('No WorkOrder IDs provided.');
            }

            if (agencyId == null || agentId == null || startDate == null || endDate == null) {
                throw new AuraHandledException('All fields are required.');
            }

            // // Get Contractor
            // Id contractorUserId = [SELECT RelatedRecordId
            //                          FROM ServiceResource
            //                         WHERE Agency__c = :agencyId 
            //                           AND Service_Resource_Type__c = 'Contractor'
            //                         LIMIT 1].RelatedRecordId;

            List<WorkOrder> workOrdersToUpdate = new List<WorkOrder>();
            List<ServiceAppointment> appointments = new List<ServiceAppointment>();
            Map<Id, Id> workOrderToAppointmentMap = new Map<Id, Id>();
            Map<Id, ServiceAppointment> saMap = new Map<Id, ServiceAppointment>();

            List<WorkOrder> workOrders = [SELECT Id, AccountId, 
                                                 Account.PersonContactId 
                                            FROM WorkOrder 
                                           WHERE Id IN :workOrderIds];

            for (WorkOrder wOrder : workOrders) {

                // Get Contact ID from related Account
                Id contactId;
                if (wOrder.Account.PersonContactId != null) {
                    contactId = wOrder.Account.PersonContactId;
                }

                // Update Work Order
                WorkOrder wo = new WorkOrder(
                    Id = wOrder.Id,
                    R_T_Agency__c = agencyId,
                    Agent__c = agentId,
                    //WorkTypeId = workTypeId,
                    StartDate = startDate,
                    EndDate = endDate,
                    //OwnerId = contractorUserId,
                    Assiged_to_Agency__c = true
                );
                workOrdersToUpdate.add(wo);
 
                // Create or update Service Appointment
                ServiceAppointment sa = new ServiceAppointment(
                    ParentRecordId = wOrder.Id,
                    ServiceTerritoryId = agencyId,
                    //WorkTypeId = workTypeId,
                    EarliestStartTime = startDate,
                    ContactId = contactId,
                    DueDate = endDate,
                    Status = 'In Progress'
                );
                saMap.put(wOrder.Id, sa);
            }

            // Update Work Orders
            update workOrdersToUpdate;

            //Delete existing ServiceAppointments (if any)
            delete [SELECT Id FROM ServiceAppointment WHERE ParentRecordId IN :workOrderIds];

            upsert saMap.values();

            // List<AssignedResource> assignedResources = new List<AssignedResource>();

            // for (Id woId : workOrderIds) {
            //     if (saMap.containsKey(woId)) {
            //         AssignedResource ar = new AssignedResource(
            //             ServiceAppointmentId = saMap.get(woId).Id,
            //             ServiceResourceId = agentId
            //         );
            //         assignedResources.add(ar);
            //     }
            // }

            // insert assignedResources;

        } catch (Exception e) {

            AS_ErrorLogger.log('AgencyFetcherForRT', 'assignAgency', e, workOrderIds.get(0));
        }
    }
}