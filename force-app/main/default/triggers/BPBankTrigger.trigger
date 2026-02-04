trigger BPBankTrigger on BP_Bank_Details__c (before insert) {
	if (!TriggerController.isTriggerActive('BPBankTrigger')) {
        return;
    }
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        BPBankTriggerHandler.markBPBankToBeProcessed(Trigger.new, Trigger.oldMap);
    }
}