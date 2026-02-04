trigger PremiseTrigger on Premise__c (before insert, before update) {
    if (!TriggerController.isTriggerActive('PremiseTrigger')) {
        return;
    }
    PremiseTriggerHandler.markPremisesToBeProcessed(Trigger.new, Trigger.oldMap);
}