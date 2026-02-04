/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 05-06-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   05-06-2025   Kartik Patkar, Appstrail   Initial Version
**/
trigger NotificationTrigger on Notification__c (after insert,after update) {

    if (!TriggerController.isTriggerActive('NotificationTrigger')) {
        return;
    }

    if(Trigger.isInsert && Trigger.isAfter) {
        NotificationTriggerHandler.afterInsert(Trigger.new);
    }
    if(Trigger.isUpdate && Trigger.isAfter) {
        NotificationTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }

}