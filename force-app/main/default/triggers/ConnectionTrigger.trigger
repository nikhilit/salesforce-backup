trigger ConnectionTrigger on Connection__c (before insert,before update) {
   if (!TriggerController.isTriggerActive('ConnectionTrigger')) {
        return;
    }
    ConnectionTriggerHandler.updateName(Trigger.new, Trigger.oldMap);
}