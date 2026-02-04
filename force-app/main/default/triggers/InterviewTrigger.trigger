trigger InterviewTrigger on Contact (After insert) {
    if(Trigger.isAfter && Trigger.isInsert)
    {
        InterviewHandler.updateAccount(Trigger.new);
    }

}