trigger TaskTrigger on Task (before insert) {
    if (!TriggerController.isTriggerActive('TaskTrigger')) {
        return;
    }
	TaskTriggerHandler.attachAccount(Trigger.new);
}