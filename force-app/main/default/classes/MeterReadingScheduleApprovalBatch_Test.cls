@isTest
private class MeterReadingScheduleApprovalBatch_Test  {
    
    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account', BP_Number__c = 'BP123');
        insert acc;
        
        // Create User for Assigned_Meter_Reader__c
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email='testuser@example.com',
            EmailEncodingKey='UTF-8',
            LastName='User',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=p.Id,
            TimeZoneSidKey='America/New_York',
            UserName='testuser'+System.currentTimeMillis()+'@example.com'
        );
        insert u;
        
        ServiceResource res=new ServiceResource();
        res.RelatedRecordId=u.Id;
        res.Name='User';
        insert res;
        
        Meter_Reading_Schedule__c mrsRec=new Meter_Reading_Schedule__c();
        insert mrsRec;

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            AccountId = acc.Id,
            Assigned_Meter_Reader__c = res.Id,
            Meter_Reading_Schedule__c = mrsRec.Id,
            Scheduled_Date__c = Date.today()
        );
        insert wo;
    }
    
    @isTest
    static void testDefaultConstructorAndStart() {
        Test.startTest();
        MeterReadingScheduleApprovalBatch batch = new MeterReadingScheduleApprovalBatch();
        Database.QueryLocator ql = batch.start(null);
        System.assertNotEquals(null, ql, 'QueryLocator should not be null');
        Test.stopTest();
    }
    
    @isTest
    static void testParameterizedConstructorWithMrsId() {
        Meter_Reading_Schedule__c mrsRec=[SELECT Id FROM Meter_Reading_Schedule__c LIMIT 1];
        Test.startTest();
        MeterReadingScheduleApprovalBatch batch = new MeterReadingScheduleApprovalBatch(mrsRec.Id, null, false);
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
    }
    
    @isTest
    static void testParameterizedConstructorWithCustomQuery() {
        String customQuery = 'SELECT Id, WorkOrderNumber, Assigned_Meter_Reader__c FROM WorkOrder WHERE Assigned_Meter_Reader__c != null';
        Test.startTest();
        MeterReadingScheduleApprovalBatch batch = new MeterReadingScheduleApprovalBatch(null, customQuery, true);
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
    }

    @isTest
    static void testExecuteAndFinish() {
        List<WorkOrder> wos = [SELECT Id, WorkOrderNumber, Assigned_Meter_Reader__c, Meter_Reading_Schedule__c FROM WorkOrder];
        
        Test.startTest();
        MeterReadingScheduleApprovalBatch batch = new MeterReadingScheduleApprovalBatch(wos[0].Meter_Reading_Schedule__c, null, false);
        Database.executeBatch(batch, 1); // small batch size for coverage
        Test.stopTest();
    }
}