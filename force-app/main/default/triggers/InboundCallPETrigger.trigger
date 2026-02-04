trigger InboundCallPETrigger on InboundCallDetails__e (after insert) {
    List<Inbound_Call__c> callsToInsert = new List<Inbound_Call__c>();
    for (InboundCallDetails__e evt : Trigger.new) {
        Inbound_Call__c callRec = new Inbound_Call__c(
            PhoneNumber__c = evt.PhoneNumber__c,
            Agent_Id__c = evt.Agent_Id__c,
            Status__c='New'
        );
        callsToInsert.add(callRec);
    }
    if (!callsToInsert.isEmpty()) {
        insert callsToInsert;
    }
}