/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 24-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   13-08-2025   Kartik Patkar, Appstrail   Initial Version
**/
public class MeterReadingScheduleHandler {
    public static void handleAgentUpdate(List<Meter_Reading_Schedule__c> newList, Map<Id, Meter_Reading_Schedule__c> oldMap) {
        Map<Id, Id> scheduleToAgentMap = new Map<Id, Id>();
        Map<Id, Date> scheduleToDateMap = new Map<Id, Date>();
        
        Set<Id> agentIds = new Set<Id>();
        Set<Id> scheduleIdsForAgentUpdate = new Set<Id>();
        Set<Id> scheduleIdsForDateUpdate = new Set<Id>();
        
        for (Meter_Reading_Schedule__c newRec : newList) {
            Meter_Reading_Schedule__c oldRec = oldMap.get(newRec.Id);
            
            if (newRec.Status__c == 'Pending') {
                // Check agent update
                if (newRec.Agent__c != null && newRec.Agent__c != oldRec.Agent__c) {
                    scheduleToAgentMap.put(newRec.Id, newRec.Agent__c);
                    agentIds.add(newRec.Agent__c);
                    scheduleIdsForAgentUpdate.add(newRec.Id);
                }
                
                // Check date update
                if (
                    newRec.Meter_Reading_Completion_Date__c != null &&
                    newRec.Meter_Reading_Completion_Date__c != oldRec.Meter_Reading_Completion_Date__c
                ) {
                    scheduleToDateMap.put(newRec.Id, newRec.Meter_Reading_Completion_Date__c);
                    scheduleIdsForDateUpdate.add(newRec.Id);
                }
            }
        }
        
        if (!scheduleToAgentMap.isEmpty()) {
            updateWorkOrderAgent(newList, scheduleToAgentMap, agentIds);
        }
        
        if (!scheduleToDateMap.isEmpty()) {
            updateWorkOrderEndDate(newList, scheduleToDateMap);
        }
    }
    
    Public static void updateWorkOrderEndDate(List<Meter_Reading_Schedule__c> newList,Map<Id, Date> scheduleToAgentMap){
        
        if (scheduleToAgentMap.isEmpty()) return;
        
        // Query WorkOrders related to the Meter Reading Schedules
        List<WorkOrder> workOrdersToUpdate = [
            SELECT Id, Meter_Reading_Schedule__c,Assigned_Meter_Reader__c
            FROM WorkOrder
            WHERE Meter_Reading_Schedule__c IN :scheduleToAgentMap.keySet()
        ];
        system.debug('workOrdersToUpdate::'+workOrdersToUpdate);
        Set<Id> setAppointments = new Set<Id>();
        for (WorkOrder wo : workOrdersToUpdate) {
            setAppointments.add(wo.Id);
        }

        Map<Id,ServiceAppointment> appointmentMap = new Map<Id,ServiceAppointment>();
        for(ServiceAppointment sa : [SELECT Id, ParentRecordId, SchedEndTime FROM ServiceAppointment
                                    WHERE ParentRecordId IN :setAppointments]) {
                        
            if(sa.ParentRecordId != null) {
                appointmentMap.put(sa.ParentRecordId, sa);
            }
        }

        List<ServiceAppointment> updateServiceAppointments = new List<ServiceAppointment>();
        List<WorkOrder> updatedWOs = new List<WorkOrder>();
        for (WorkOrder wo : workOrdersToUpdate) {
            Date endDate = scheduleToAgentMap.get(wo.Meter_Reading_Schedule__c);
            if (endDate != null) {
                wo.EndDate = endDate;
                updatedWOs.add(wo);

                if( appointmentMap.containsKey(wo.Id)) {
                    ServiceAppointment sa = appointmentMap.get(wo.Id);
                    if (sa != null) {
                        Time endTime = Time.newInstance(19, 30, 0, 0); // 7:30 PM
                        sa.SchedEndTime = DateTime.newInstance(endDate, endTime);
                        updateServiceAppointments.add(sa);
                    }
                }
            }
        }
        
        // Enable bypass
        Metering_Bypass_Validation__c bs = Metering_Bypass_Validation__c.getInstance(UserInfo.getUserId());
        if (bs == null) {
            bs = new Metering_Bypass_Validation__c();
            bs.SetupOwnerId = UserInfo.getUserId();
        }
        bs.Bypass__c = true;
        upsert bs;
        
        if (!updatedWOs.isEmpty()) {
            update updatedWOs;
        }

        if (!updateServiceAppointments.isEmpty()) {
            update updateServiceAppointments;
        }
        
        // Disable bypass
        bs.Bypass__c = false;
        upsert bs;
    }
    
    public static void validateOverlappingSchedules(List<Meter_Reading_Schedule__c> newList, Map<Id, Meter_Reading_Schedule__c> oldMap) {
        Set<Id> agentIds = new Set<Id>();
        
        for (Meter_Reading_Schedule__c mrs : newList) {
            if (mrs.Agent__c != null) {
                agentIds.add(mrs.Agent__c);
            }
        }
        
        if (agentIds.isEmpty()) return;
        
        
        // Fetch potentially overlapping existing records
        List<Meter_Reading_Schedule__c> existingSchedules = [
            SELECT Id, Name, Agent__c, Meter_Reading_Start_Date__c, Meter_Reading_Completion_Date__c
            FROM Meter_Reading_Schedule__c
            WHERE Agent__c IN :agentIds
        ];
        
        for (Meter_Reading_Schedule__c current : newList) {
            if (current.Agent__c == null || current.Meter_Reading_Start_Date__c == null || current.Meter_Reading_Completion_Date__c == null) continue;
            
            for (Meter_Reading_Schedule__c existing : existingSchedules) {
                if (existing.Id == current.Id) continue;
                
                Boolean isOverlapping =
                    current.Meter_Reading_Start_Date__c <= existing.Meter_Reading_Completion_Date__c &&
                    current.Meter_Reading_Completion_Date__c>= existing.Meter_Reading_Start_Date__c &&
                    current.Agent__c == existing.Agent__c;
                
                if (isOverlapping) {
                    //current.addError('Record is overlapping with existing Schedule: ' + existing.Name);
                    break;
                }
            }
        }
    }
    
    
    public static void validateActiveSchedule(List<Meter_Reading_Schedule__c> newList, Map<Id, Meter_Reading_Schedule__c> oldMap) {
        Set<Id> agentIds = new Set<Id>();
        
        for (Meter_Reading_Schedule__c mrs : newList) {
            if (mrs.Active__c == true && mrs.Agent__c != null) {
                agentIds.add(mrs.Agent__c);
            }
        }
        
        if (agentIds.isEmpty()) return;
        
        // Query existing active records for those agents
        List<Meter_Reading_Schedule__c> existingActiveSchedules = [
        SELECT Id, Name, Agent__c
        FROM Meter_Reading_Schedule__c
        WHERE Active__c = true AND Agent__c IN :agentIds
    ];
        
        Map<Id, Meter_Reading_Schedule__c> agentToExistingActiveMap = new Map<Id, Meter_Reading_Schedule__c>();
        
        for (Meter_Reading_Schedule__c existing : existingActiveSchedules) {
            agentToExistingActiveMap.put(existing.Agent__c, existing);
        }
        
        for (Meter_Reading_Schedule__c current : newList) {
            if (current.Active__c == true && current.Agent__c != null) {
                Meter_Reading_Schedule__c existing = agentToExistingActiveMap.get(current.Agent__c);
                
                // Check if the existing active record is not the same as the one being updated
                if (existing != null && existing.Id != current.Id) {
                    current.addError('Schedule Record is already active: ' + existing.Name);
                }
            }
        }
    }
    Public static void updateWorkOrderAgent(List<Meter_Reading_Schedule__c> newList,Map<Id, Id> scheduleToAgentMap,Set<Id> agentIds){
        if (scheduleToAgentMap.isEmpty()) return;
        
        // Query ServiceTerritoryMembers to get Agency
        Map<Id, ServiceTerritoryMember> agentToSTMMap = new Map<Id, ServiceTerritoryMember>();
        for (ServiceTerritoryMember stm : [
            SELECT Id, ServiceResourceId, ServiceTerritoryId
            FROM ServiceTerritoryMember
            WHERE ServiceResourceId IN :agentIds
        ]) {
            agentToSTMMap.put(stm.ServiceResourceId, stm);
        }
        system.debug('agentToSTMMap::'+agentToSTMMap);
        // Update Meter_Reading_Schedule__c with Agency__c
        List<Meter_Reading_Schedule__c> schedulesToUpdate = new List<Meter_Reading_Schedule__c>();
        for (Meter_Reading_Schedule__c newRec : newList) {
            if (scheduleToAgentMap.containsKey(newRec.Id)) {
                Id agentId = scheduleToAgentMap.get(newRec.Id);
                ServiceTerritoryMember stm = agentToSTMMap.get(agentId);
                system.debug('stm::'+stm);
                if (stm != null) {
                    Meter_Reading_Schedule__c updatedSchedule = new Meter_Reading_Schedule__c(
                        Id = newRec.Id,
                    Agency__c = stm.ServiceTerritoryId
                        );
                    schedulesToUpdate.add(updatedSchedule);
                }
            }
        }
        
        if (!schedulesToUpdate.isEmpty()) {
            update schedulesToUpdate;
        }
        
        // Query WorkOrders related to the Meter Reading Schedules
        
        List<WorkOrder> workOrdersToUpdate = [
            SELECT Id, Meter_Reading_Schedule__c,Assigned_Meter_Reader__c
            FROM WorkOrder
            WHERE Meter_Reading_Schedule__c IN :scheduleToAgentMap.keySet()
        ];
        system.debug('workOrdersToUpdate::'+workOrdersToUpdate);
        List<WorkOrder> updatedWOs = new List<WorkOrder>();
        for (WorkOrder wo : workOrdersToUpdate) {
            Id agentId = scheduleToAgentMap.get(wo.Meter_Reading_Schedule__c);
            system.debug('agentId::'+agentId);
            ServiceTerritoryMember stm = agentToSTMMap.get(agentId);
            if (agentId != null && stm != null) {
                wo.Assigned_Meter_Reader__c = agentId;
                wo.Metering_Agency__c = stm.ServiceTerritoryId;
                updatedWOs.add(wo);
            }
        }
        
        // Enable bypass
        Metering_Bypass_Validation__c bs = Metering_Bypass_Validation__c.getInstance(UserInfo.getUserId());
        if (bs == null) {
            bs = new Metering_Bypass_Validation__c();
            bs.SetupOwnerId = UserInfo.getUserId();
        }
        bs.Bypass__c = true;
        upsert bs;
        
        if (!updatedWOs.isEmpty()) {
            update updatedWOs;
        }
        
         // Disable bypass
        bs.Bypass__c = false;
        upsert bs;
    }

    public static void scheduleToBeActive(List<Meter_Reading_Schedule__c> newList, Map<Id, Meter_Reading_Schedule__c> oldMap){
        Set<Id> agentIds = new Set<Id>();
        for( Meter_Reading_Schedule__c newRec : newList) {
            if(newRec.Active__c==true && (oldMap==null || newRec.Active__c!=oldMap.get(newRec.Id).Active__c)){
                agentIds.add(newRec.Agent__c);
            }
        }
        if(agentIds.isEmpty()) return;
        // Query existing active records for those agents
        List<Meter_Reading_Schedule__c> existingActiveSchedules = [
            SELECT Id, Name, Agent__c
            FROM Meter_Reading_Schedule__c
            WHERE Active__c = true AND Agent__c IN :agentIds
        ];
        Map<Id, Meter_Reading_Schedule__c> agentToExistingActiveMap = new Map<Id, Meter_Reading_Schedule__c>();
        for (Meter_Reading_Schedule__c existing : existingActiveSchedules) {
            existing.Active__c = false; // Deactivate existing active schedules
        }
        if(!existingActiveSchedules.isEmpty()) {
            update existingActiveSchedules; // Update existing active schedules to inactive
        }
    }

    // public static void after
}