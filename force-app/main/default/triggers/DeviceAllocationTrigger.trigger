trigger DeviceAllocationTrigger on Device_Allocation__c (before insert, before update) {
    if (!TriggerController.isTriggerActive('DeviceAllocationTrigger')) return;

    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        DeviceAllocationTriggerHandler.handleInactiveAllocations(Trigger.new, Trigger.oldMap);
    }
}