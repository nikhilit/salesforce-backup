trigger InstallationTrigger on Installation__c (before insert, before update) {
    if (!TriggerController.isTriggerActive('InstallationTrigger')) {
        return;
    }
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
	    InstallationTriggerHandler.markInstallationToBeProcessed(Trigger.new, Trigger.oldMap);
    }
}