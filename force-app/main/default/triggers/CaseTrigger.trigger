trigger CaseTrigger on Case (before delete) {
    CaseTriggerHandler.CaseDeletionByAdmin(Trigger.old);

}