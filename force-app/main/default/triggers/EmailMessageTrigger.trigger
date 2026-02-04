trigger EmailMessageTrigger on EmailMessage (after insert,before insert) {
    if (!TriggerController.isTriggerActive('EmailMessageTrigger')) {
        return;
    }
    if(Trigger.isBefore && Trigger.isInsert){
        EmailMessageTriggerHandler.processIncomingEmails(Trigger.new);
        
    }
     // AFTER INSERT → for outbound CRM Forms acknowledgment
    if (Trigger.isAfter && Trigger.isInsert) {
        EmailMessageTriggerHandler.validateAttendanceForOutgoingEmails(Trigger.new);
       // EmailMessageTriggerHandler.processCRMFormsAcknowledgement(Trigger.new);
    }
}