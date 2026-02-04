trigger CaseTypeSMSTrigger on Case_Type_SMS__c (before insert) {
    
    /* if (!TriggerController.isTriggerActive('CaseTypeSMSTrigger')) {
        return;
    } */
    
    if (Trigger.isBefore && Trigger.isInsert) {
         
        CaseTypeSMSTriggerHandler.updateQrcId(Trigger.new);
   }

}