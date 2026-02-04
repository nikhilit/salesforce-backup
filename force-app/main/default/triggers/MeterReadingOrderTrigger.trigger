/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 21-09-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   21-09-2025   Kartik Patkar, Appstrail   Initial Version
**/
trigger MeterReadingOrderTrigger on Meter_Reading_Order__c (after insert, after update) {

    if(!TriggerController.isTriggerActive('MeterReadingOrderTrigger')){
        return;
    }

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            MeterReadingOrderTriggerHandler.afterInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            MeterReadingOrderTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }

}