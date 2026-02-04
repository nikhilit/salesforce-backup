@isTest
private class InboundCallPETriggerTest {

    @isTest
    static void testInboundCallPETrigger() {

        List<InboundCallDetails__e> events = new List<InboundCallDetails__e>();
        events.add(new InboundCallDetails__e(
            PhoneNumber__c = '9876543210',
            Agent_Id__c = 'AG1001'
        ));
        events.add(new InboundCallDetails__e(
            PhoneNumber__c = '9123456780',
            Agent_Id__c = 'AG2002'
        ));

        Test.startTest();
        EventBus.publish(events);
        Test.stopTest(); 
    }
}