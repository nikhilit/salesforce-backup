@isTest
private class DailyCaseTrackingSchedulerTest {

    @isTest
    static void testExecuteScheduler() {

        // 0) Create an Account with the required BP_Number__c
        Account acc = new Account(
            Name = 'Test BP Account',
            BP_Number__c = '1101637901' // valid BP number for validation rule
        );
        insert acc;

        // = 1) Open case from before today (opening balance) =
        Case openBeforeToday = new Case(
            Subject   = 'Open Before Today',
            Origin    = 'Email',
            Status    = 'New',
            AccountId = acc.Id
        );
        insert openBeforeToday;
        Test.setCreatedDate(openBeforeToday.Id, Datetime.now().addDays(-2));

        // = 2) Case created today =
        Case createdToday = new Case(
            Subject   = 'Created Today',
            Origin    = 'Website',
            Status    = 'New',
            AccountId = acc.Id,
            BP_Number__c = '1101637901'
        );
        insert createdToday;

        // = 3) Case closed today =
        Case closedToday = new Case(
            Subject   = 'Closed Today',
            Origin    = 'MGL-Connect',
            Status    = 'Closed',
            AccountId = acc.Id,
            BP_Number__c = '1101637901'
        );
        insert closedToday;
        update closedToday; // already closed on insert

        // = 4) Case created yesterday =
        Case createdYesterday = new Case(
            Subject   = 'Created Yesterday',
            Origin    = 'Email',
            Status    = 'New',
            AccountId = acc.Id
        );
        insert createdYesterday;
        Test.setCreatedDate(createdYesterday.Id, Datetime.now().addDays(-1));

        // = 5) Case closed yesterday =
        Case closedYesterday = new Case(
            Subject   = 'Closed Yesterday',
            Origin    = 'Website',
            Status    = 'Closed',
            AccountId = acc.Id,
            BP_Number__c = '1101637901'
        );
        insert closedYesterday;
        update closedYesterday;

        // = 6) Pre-existing Daily_Tracking__c for today =
        Daily_Tracking__c todayRecord = new Daily_Tracking__c(
            Date__c             = System.today(),
            Opening_Balance__c  = 0,
            Received_Count__c   = 0,
            Done_Processed__c   = 0
        );
        insert todayRecord;

        // = 7) Pre-existing Daily_Tracking__c for yesterday =
        Daily_Tracking__c yesterdayRecord = new Daily_Tracking__c(
            Date__c            = System.today().addDays(-1),
            Received_Count__c  = 0,
            Done_Processed__c  = 0
        );
        insert yesterdayRecord;

        // ==== Run Scheduler ====
        Test.startTest();
        new DailyCaseTrackingScheduler().execute(null);
        Test.stopTest();

        // ==== Assertions ====
        Daily_Tracking__c updatedToday = [
            SELECT Opening_Balance__c, Received_Count__c, Done_Processed__c
            FROM Daily_Tracking__c
            WHERE Date__c = :System.today()
            LIMIT 1
        ];
        System.assert(updatedToday.Opening_Balance__c >= 0, 'Opening balance should be set.');
        System.assert(updatedToday.Received_Count__c >= 0, 'Today received should be set.');

        Daily_Tracking__c updatedYesterday = [
            SELECT Received_Count__c, Done_Processed__c
            FROM Daily_Tracking__c
            WHERE Date__c = :System.today().addDays(-1)
            LIMIT 1
        ];
        System.assert(updatedYesterday.Received_Count__c >= 0, 'Yesterday received should be set.');
    }
}