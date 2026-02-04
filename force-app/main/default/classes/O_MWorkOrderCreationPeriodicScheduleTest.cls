@isTest
public class O_MWorkOrderCreationPeriodicScheduleTest {
	 @TestSetup
    static void setupTestData() {
        
        // Create test Account that will be processed by the batch
        Account testAccount = new Account(
            Name = 'Test Account',
            Previous_Maintenance_Date__c = Date.today().addDays(-30)
        );
        insert testAccount;
        
        // Create test WorkType
        WorkType testWorkType = new WorkType(
            Name = 'Riser Maintenance',
            EstimatedDuration = 2.5
        );
        insert testWorkType;
        
        // Create test User
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            FirstName = 'JANAK',
            LastName = 'LANDGE',
            Email = 'testuser@example.com',
            Username = 'testuser11111111111111@example.com.test',
            Alias = 'tuser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id
        );
        insert testUser;
    }
    
    @IsTest
    static void testScheduleExecution() {
        // Mock the batch class to verify it gets executed
        Test.startTest();
        
        // Create instance of schedulable class
        O_MWorkOrderCreationPeriodicSchedule scheduler = new O_MWorkOrderCreationPeriodicSchedule();
        
        // Execute the schedulable class
        scheduler.execute(null);
        
        Test.stopTest();
        
        // Verify the batch was executed by checking for side effects
        // In this case, we expect the batch to create a WorkOrder
        List<WorkOrder> workOrders = [SELECT Id FROM WorkOrder];
        System.assertEquals(1, workOrders.size(), 'Batch should have created one WorkOrder');
    }
    
    @IsTest
    static void testScheduleExecutionWithContext() {
        // Test with actual SchedulableContext
        Test.startTest();
        
        // Create mock SchedulableContext
        SchedulableContext sc = new MockSchedulableContext();
        
        O_MWorkOrderCreationPeriodicSchedule scheduler = new O_MWorkOrderCreationPeriodicSchedule();
        scheduler.execute(sc);
        
        Test.stopTest();
        
    }
    
    // Mock SchedulableContext implementation for testing
    private class MockSchedulableContext implements SchedulableContext {
        public Id getTriggerId() {
            return '01m000000000001AAA';
        }
    }
    
    @IsTest
    static void testScheduleClassCanBeScheduled() {
        // Test that the class can actually be scheduled
        Test.startTest();
        
        String jobName = 'Test_O_MWorkOrderCreationPeriodicSchedule';
        String cronExp = '0 0 13 * * ?'; // Run daily at 1pm
        
        // Schedule the job
        Id jobId = System.schedule(jobName, cronExp, new O_MWorkOrderCreationPeriodicSchedule());
        
        Test.stopTest();
        
    }
}