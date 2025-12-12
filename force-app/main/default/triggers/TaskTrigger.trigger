trigger TaskTrigger on Task (before insert, before update) {
    if(trigger.isinsert)
    {
        if(Trigger.isbefore)
        {
            TaskTriggerHandler.populatepriorityhigh(Trigger.new);
        }
    }
    
    if(trigger.isupdate && trigger.isbefore)
    {
        TaskTriggerHandler.PermissionCheck(Trigger.new);
    }

}