@isTest
private class LogoutEventStreamTest {
    @isTest
    static void testLogoutEventTrigger() {
        Profile p=[SELECT Id,name from Profile where Name='Standard User'];
        // Pick any active user for testing
        User testUser = new User(
    Alias = 'towner',
    Email = 'testowner@example.com',
    EmailEncodingKey = 'UTF-8',
    LastName = 'Owner',
    LanguageLocaleKey = 'en_US',
    LocaleSidKey = 'en_US',
            ProfileId=p.Id,
    TimeZoneSidKey = 'America/Los_Angeles',
    Username = 'testowner' + System.currentTimeMillis() + '@example.com'
);
insert testUser;
Attendance__c att = new Attendance__c(
            User__c = testUser.Id,
            Day_In_Timestamp__c = System.now().addHours(-8)
        );
        insert att;

        Break__c br = new Break__c(
            Attendance__c = att.Id,
            Break_Start_Time__c = System.now().addHours(-2)
        );
        insert br;
        // Create a platform event instance
        LogoutEventStream eventRec = new LogoutEventStream(
            UserId    = testUser.Id,
            EventDate = System.now()
        );

        Test.startTest();

        // Publish the event to invoke the trigger
        Database.SaveResult sr = EventBus.publish(eventRec);
        Test.stopTest();
    }
}