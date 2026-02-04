/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 05-10-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   05-10-2025   Kartik Patkar, Appstrail   Initial Version
**/
public without sharing class MeterReadingScheduleHelper {

    /**
    * @description 
    * @author Kartik Patkar, Appstrail | 05-10-2025 
    * @param List<WorkOrder> newList 
    * @param List<WorkOrder> oldList 
    **/
    public static void updateScheduleCounts(List<WorkOrder> newList, List<WorkOrder> oldList) {
        Set<Id> scheduleIds = new Set<Id>();
        String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                                            .get('MGL_Metering').getRecordTypeId();

        // 🔹 Collect all impacted schedule IDs (old + new)
        if (newList != null) {
            for (WorkOrder wo : newList) {
                if (wo.Meter_Reading_Schedule__c != null && wo.RecordTypeId == meteringRecordTypeId)
                    scheduleIds.add(wo.Meter_Reading_Schedule__c);
            }
        }
        if (oldList != null) {
            for (WorkOrder wo : oldList) {
                if (wo.Meter_Reading_Schedule__c != null && wo.RecordTypeId == meteringRecordTypeId)
                    scheduleIds.add(wo.Meter_Reading_Schedule__c);
            }
        }

        if (scheduleIds.isEmpty()) return;

        // 🔹 Query relevant Work Orders (no CASE WHEN — all handled in Apex)
        List<WorkOrder> workOrders = [
            SELECT Id, Appointment_Status__c, Meter_Reading_Schedule__c
            FROM WorkOrder
            WHERE Meter_Reading_Schedule__c IN :scheduleIds 
            AND RecordTypeId = :meteringRecordTypeId
        ];

        // 🔹 Prepare counters
        Map<Id, Map<String, Integer>> statusCountMap = new Map<Id, Map<String, Integer>>();

        for (WorkOrder wo : workOrders) {
            if (!statusCountMap.containsKey(wo.Meter_Reading_Schedule__c)) {
                statusCountMap.put(wo.Meter_Reading_Schedule__c, new Map<String, Integer>{
                    'Completed' => 0,
                    'Incomplete' => 0,
                    'Unattempted' => 0,
                    'Total' => 0
                });
            }

            Map<String, Integer> counters = statusCountMap.get(wo.Meter_Reading_Schedule__c);

            counters.put('Total', counters.get('Total') + 1);

            if (wo.Appointment_Status__c == 'Completed')
                counters.put('Completed', counters.get('Completed') + 1);
            else if (wo.Appointment_Status__c == 'Incomplete')
                counters.put('Incomplete', counters.get('Incomplete') + 1);
            else if (wo.Appointment_Status__c == 'Unattempted')
                counters.put('Unattempted', counters.get('Unattempted') + 1);
        }

        // 🔹 Prepare updates for Meter_Reading_Schedule__c
        List<Meter_Reading_Schedule__c> schedulesToUpdate = new List<Meter_Reading_Schedule__c>();

        for (Id schedId : scheduleIds) {
            Map<String, Integer> c = statusCountMap.containsKey(schedId)
                ? statusCountMap.get(schedId)
                : new Map<String, Integer>{
                    'Completed' => 0,
                    'Incomplete' => 0,
                    'Unattempted' => 0,
                    'Total' => 0
                };

            schedulesToUpdate.add(new Meter_Reading_Schedule__c(
                Id = schedId,
                Completed_Count__c = c.get('Completed'),
                Incompleted_Count__c = c.get('Incomplete'),
                Unattempted_Count__c = c.get('Unattempted'),
                No_of_Customer__c = c.get('Total')
            ));
        }

        if (!schedulesToUpdate.isEmpty())
            update schedulesToUpdate;
    }

    /**
    * @description 
    * @author Kartik Patkar, Appstrail | 05-10-2025 
    * @param List<WorkOrder> deletedWorkOrders 
    **/
    public static void mROtoUnallocatedBucket(List<WorkOrder> deletedWorkOrders) {
        if (deletedWorkOrders == null || deletedWorkOrders.isEmpty()) return;

        String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                                        .get('MGL_Metering').getRecordTypeId();


        Set<Id> mroIds = new Set<Id>();
        for (WorkOrder wo : deletedWorkOrders) {
            if (wo.Meter_Reading_Order__c != null && wo.RecordTypeId == meteringRecordTypeId) {
                mroIds.add(wo.Meter_Reading_Order__c);
            }
        }

        if (!mroIds.isEmpty()) {
            List<Meter_Reading_Order__c> mroToUpdate = new List<Meter_Reading_Order__c>();
            for (Meter_Reading_Order__c mro : [SELECT Id, Created_Order__c FROM Meter_Reading_Order__c WHERE Id IN :mroIds]) {
                mro.Created_Order__c = false;
                mroToUpdate.add(mro);
            }
            if (!mroToUpdate.isEmpty()) {
                update mroToUpdate;
            }
        }
    }
}