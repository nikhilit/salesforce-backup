<<<<<<< HEAD
trigger TaskTrigger on Task (before insert) {
    if (!TriggerController.isTriggerActive('TaskTrigger')) {
        return;
    }
	TaskTriggerHandler.attachAccount(Trigger.new);
=======
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

>>>>>>> e604021b64f33882bfed07c2bfed265ad53326cf
}