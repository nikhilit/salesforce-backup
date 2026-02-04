trigger CustomAccountTrigger on Account__c (After insert,aFTER UPDATE) {
    if(Trigger.isInsert && trigger.isAfter){
        CustomAccountTriggerHandler.populateRelatedDescription(trigger.new);
    }
}