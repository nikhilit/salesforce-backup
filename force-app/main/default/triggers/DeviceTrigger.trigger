trigger DeviceTrigger on Device__c (before insert, before update) {
    if (!TriggerController.isTriggerActive('DeviceTrigger')) {
        return;
    }
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        DeviceTriggerHandler.markDevicesToBeProcessed(Trigger.new,Trigger.oldMap);
    }
}