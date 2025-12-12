trigger LeadTrigger on Lead (before delete, after update) {
    if(trigger.isdelete && trigger.isbefore){
        LeadTriggerHandler.leadDeletionError(trigger.old);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate)
    {
        LeadTriggerHandler.populatetheDescription(Trigger.new, Trigger.oldmap);
    }

}