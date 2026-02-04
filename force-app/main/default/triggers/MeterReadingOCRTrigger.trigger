/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 15-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-06-2025   Kartik Patkar, Appstrail   Initial Version
**/
trigger MeterReadingOCRTrigger on Meter_Reading_OCR__c (before insert,before update, after insert,after update) {

    if (!TriggerController.isTriggerActive('MeterReadingOCRTrigger')) {
        return;
    }

    if(Trigger.isBefore && Trigger.isInsert){
        MeterReadingOCRTriggerHandler.beforeInsert(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        MeterReadingOCRTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isInsert && Trigger.isAfter) {
        MeterReadingOCRTriggerHandler.afterInsert(Trigger.new);
    }
    if(Trigger.isUpdate && Trigger.isAfter){
        MeterReadingOCRTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }

}