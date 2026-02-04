trigger SecurityDepositTrigger on Security_Deposit__c (before insert, before update) {
    if (!TriggerController.isTriggerActive('SecurityDepositTrigger')) {
        return;
    }
    if (Trigger.isBefore) {
        SecurityDepositTriggerHandler.assignValues(Trigger.new, Trigger.oldMap);
    }
}