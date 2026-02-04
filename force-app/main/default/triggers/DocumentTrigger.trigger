/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 04-07-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   04-07-2025   Kartik Patkar, Appstrail   Initial Version
**/
trigger DocumentTrigger on Document__c (after insert,after update) {

    if (!TriggerController.isTriggerActive('DocumentTrigger')) {
        return;
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            DocumentTriggerHandler.afterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            DocumentTriggerHandler.afterUpdate(Trigger.new,Trigger.oldMap);
        }
    }
}