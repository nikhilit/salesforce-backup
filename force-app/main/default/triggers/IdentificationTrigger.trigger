trigger IdentificationTrigger on Identification_Number__c (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        IdentificationNumberHandler.markIdentificationsToBeProcessed(Trigger.new, Trigger.oldMap);
    }
}