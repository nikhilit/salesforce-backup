/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 22-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   13-08-2025   Kartik Patkar, Appstrail   Initial Version
**/
trigger MeterReadingScheduleTrigger on Meter_Reading_Schedule__c (after update , before insert, before update) {

    if (!TriggerController.isTriggerActive('MeterReadingScheduleTrigger')) {
        return;
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        MeterReadingScheduleHandler.handleAgentUpdate(Trigger.new, Trigger.oldMap);
        MeteringCommunicationHelper.afterInsertUpdateMRS(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        MeterReadingScheduleHandler.validateOverlappingSchedules(Trigger.new, Trigger.oldMap);
        MeterReadingScheduleHandler.validateActiveSchedule(Trigger.new, Trigger.oldMap); 
        // MeterReadingScheduleHandler.scheduleToBeActive(Trigger.new, Trigger.oldMap);
    }
}