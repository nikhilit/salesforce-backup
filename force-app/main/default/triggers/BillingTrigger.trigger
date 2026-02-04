trigger BillingTrigger on Billing__c (before insert, before update) {
    if (!TriggerController.isTriggerActive('BillingTrigger')) {
        return;
    }
    if (Trigger.isBefore  && (Trigger.isInsert || Trigger.isUpdate)) {
        BillingHandler.markBillingToBeProcessed(Trigger.new, Trigger.oldMap);
    }
}