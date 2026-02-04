trigger MoveInOutTrigger on Move_In_Out__c (before insert,before update) {
        if (!TriggerController.isTriggerActive('MoveInOutTrigger')) {
        return;
    }
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
       MoveInOutTriggerHandler.markMoveOutToBeProcessed(Trigger.new, Trigger.oldMap);
    }
}