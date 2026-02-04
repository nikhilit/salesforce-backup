trigger ChronologyTrigger on Chronology__c (before insert,before update) {
if (!TriggerController.isTriggerActive('ChronologyTrigger')) {
        return;
    }
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        ChronologyTriggerHandler.markChronologyToBeProcessed(Trigger.new,Trigger.oldMap);
    }
}