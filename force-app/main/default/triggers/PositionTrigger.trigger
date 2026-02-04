trigger PositionTrigger on Position__c (before insert, After insert) {
    if(Trigger.isInsert){
        if(Trigger.isBefore){
            PositionTriggerHandler.populateDate(Trigger.new);
        }
        else if(Trigger.isAfter){
            PositionTriggerHandler.craeteTask(Trigger.new);
        }
    }
}