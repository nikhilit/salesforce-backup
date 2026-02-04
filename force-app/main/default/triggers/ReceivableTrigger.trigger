trigger ReceivableTrigger on Receivable__c (before insert,before update) {
if (!TriggerController.isTriggerActive('ReceivableTrigger')) {
        return;
    }
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
       ReceivableTriggerHandler.markReceivablesToBeProcessed(Trigger.new, Trigger.oldMap);
    }
}