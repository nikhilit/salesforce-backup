trigger AccountTrigger on Account (before insert,before update,after update,after insert) {
    if (!TriggerController.isTriggerActive('AccountTrigger')) {
        return;
    }
   if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AccountTriggerHandler.handleInsert(Trigger.new);

        }
        if (Trigger.isUpdate) {
            AccountTriggerHandler.handleUpdate(Trigger.new, Trigger.oldMap);
            
        }
    }
    if(Trigger.isBefore){
    AccountTriggerHandler.fillName(Trigger.new,Trigger.oldMap);
    }
     if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        AccountTriggerHandler.updateBillingLatLong(Trigger.new, Trigger.oldMap);
        AccountTriggerHandler.lastModifiedBySAP(Trigger.new);
    }
}