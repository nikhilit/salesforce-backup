public class ServiceResourceHandler {

    public static void createServiceTerritoryMembers(List<ServiceResource> newResources, Map<Id, ServiceResource> oldMap) {
        OperatingHours baseCalendar = [
            SELECT Id FROM OperatingHours WHERE Name = 'Base Calendar' LIMIT 1
        ];

        List<ServiceTerritoryMember> membersToInsert = new List<ServiceTerritoryMember>();
        List<ServiceTerritoryMember> membersToUpdate = new List<ServiceTerritoryMember>();
        Set<Id> resourceIds = new Set<Id>();
        Map<Id, Id> resourceToTerritory = new Map<Id, Id>();
        Map<Id, ServiceResource> resourceMap = new Map<Id, ServiceResource>();

        for(ServiceResource sr : newResources) {
            if(sr.Agency__c != null && sr.IsActive) {
                resourceIds.add(sr.Id);
                resourceToTerritory.put(sr.Id, sr.Agency__c);
                resourceMap.put(sr.Id, sr);
            }
        }

        if(!resourceIds.isEmpty()) {
            Map<String, ServiceTerritoryMember> existingMembers = new Map<String, ServiceTerritoryMember>();
            for(ServiceTerritoryMember stm : [
                SELECT Id, ServiceResourceId, ServiceTerritoryId, EffectiveStartDate, EffectiveEndDate
                FROM ServiceTerritoryMember
                WHERE ServiceResourceId IN :resourceIds
            ]) {
                existingMembers.put(stm.ServiceResourceId + '-' + stm.ServiceTerritoryId, stm);
            }

            for(Id srId : resourceToTerritory.keySet()) {
                Id stId = resourceToTerritory.get(srId);
                String key = srId + '-' + stId;
                ServiceResource sr = resourceMap.get(srId);

                if(existingMembers.containsKey(key)) {
                    ServiceTerritoryMember stm = existingMembers.get(key);
                    Boolean needsUpdate = false;
                    if(stm.EffectiveStartDate != sr.Start_Date__c) {
                        stm.EffectiveStartDate = sr.Start_Date__c;
                        needsUpdate = true;
                    }
                    if(stm.EffectiveEndDate != sr.End_Date__c) {
                        stm.EffectiveEndDate = sr.End_Date__c;
                        needsUpdate = true;
                    }
                    if(needsUpdate) {
                        membersToUpdate.add(stm);
                    }
                } else {
                    ServiceTerritoryMember stm = new ServiceTerritoryMember();
                    stm.ServiceResourceId = srId;
                    stm.ServiceTerritoryId = stId;
                    stm.EffectiveStartDate = sr.Start_Date__c;
                    stm.EffectiveEndDate = sr.End_Date__c;
                    stm.OperatingHoursId = baseCalendar.Id;
                    membersToInsert.add(stm);
                }
            }
        }

        if(!membersToInsert.isEmpty()) {
            insert membersToInsert;
        }
        if(!membersToUpdate.isEmpty()) {
            update membersToUpdate;
        }
    }

    //  Handles user freeze/unfreeze and work order reassignment
    public static void handleFreezeActions(List<ServiceResource> newList, Map<Id, ServiceResource> oldMap) {
        List<Id> userIdsToFreeze = new List<Id>();
        List<Id> userIdsToUnfreeze = new List<Id>();
        List<Id> serviceResourceIdsToReassign = new List<Id>();

        for (ServiceResource sr : newList) {
            ServiceResource oldSr = oldMap.get(sr.Id);
            if (oldSr == null || sr.RelatedRecordId == null) continue;

            if (oldSr.IsActive && !sr.IsActive) {
                userIdsToFreeze.add(sr.RelatedRecordId);
                serviceResourceIdsToReassign.add(sr.Id);
            } else if (!oldSr.IsActive && sr.IsActive) {
                userIdsToUnfreeze.add(sr.RelatedRecordId);
            }
        }

        if (!userIdsToFreeze.isEmpty()) {
            freezeUsers(userIdsToFreeze);
        }
        if (!userIdsToUnfreeze.isEmpty()) {
            unfreezeUsers(userIdsToUnfreeze);
        }
        if (!serviceResourceIdsToReassign.isEmpty()) {
            reassignWorkOrdersToAgency(serviceResourceIdsToReassign);
        }
    }

    //  Freeze Users
    private static void freezeUsers(List<Id> userIds) {
        List<UserLogin> toFreeze = new List<UserLogin>();
        for (UserLogin ul : [SELECT Id FROM UserLogin WHERE UserId IN :userIds]) {
            ul.IsFrozen = true;
            toFreeze.add(ul);
        }
        if (!toFreeze.isEmpty()) update toFreeze;
    }

    // Unfreeze Users
    private static void unfreezeUsers(List<Id> userIds) {
        List<UserLogin> toUnfreeze = new List<UserLogin>();
        for (UserLogin ul : [SELECT Id FROM UserLogin WHERE UserId IN :userIds]) {
            ul.IsFrozen = false;
            toUnfreeze.add(ul);
        }
        if (!toUnfreeze.isEmpty()) update toUnfreeze;
    }

   private static void reassignWorkOrdersToAgency(List<Id> serviceResourceIds) {
    // Step 1: Get AssignedResources and their related WorkOrders
    List<AssignedResource> assignedResources = [
        SELECT Id,
               ServiceAppointmentId,
               ServiceAppointment.ParentRecordId
        FROM AssignedResource
        WHERE ServiceResourceId IN :serviceResourceIds
    ];
    
    // Step 2: Collect WorkOrder IDs from ParentRecordId
    Set<Id> workOrderIds = new Set<Id>();
    for (AssignedResource ar : assignedResources) {
        if (ar.ServiceAppointment != null && ar.ServiceAppointment.ParentRecordId != null) {
            workOrderIds.add(ar.ServiceAppointment.ParentRecordId);
        }
    }
    
    // Step 3: Fetch and update related WorkOrders
    List<WorkOrder> workOrdersToUpdate = [
        SELECT Id, Appointment_Status__c
        FROM WorkOrder
        WHERE Id IN :workOrderIds
    ];
    
    for (WorkOrder wo : workOrdersToUpdate) {
        wo.Appointment_Status__c = 'Unattempted';
    }
    
    if (!workOrdersToUpdate.isEmpty()) {
        update workOrdersToUpdate;
    }

    // Optional: delete assigned resources if needed
    if (!assignedResources.isEmpty()) {
        delete assignedResources;
    }
}


}