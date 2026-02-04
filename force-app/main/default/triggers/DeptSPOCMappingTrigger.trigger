trigger DeptSPOCMappingTrigger on Departments_SPOC_Mapping__c (before insert) {
   /* if (!TriggerController.isTriggerActive('DeptSPOCMappingTrigger')) {
        return;
    } */
    
    if (Trigger.isBefore && Trigger.isInsert) {
         
        DeptSPOCMappingTriggerHandler.updateQrcDrsSpocIds(Trigger.new);
   }

}