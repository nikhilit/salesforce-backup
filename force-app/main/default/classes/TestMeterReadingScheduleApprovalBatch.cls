@isTest
private class TestMeterReadingScheduleApprovalBatch {

    @testSetup
    static void setupData() {
        // Insert Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Insert WorkOrder — minimal required fields
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'New',
            AccountId = acc.Id
            // Leave Assigned_Meter_Reader__c = null (to avoid type error)
        );
        insert wo;
    }

    @isTest
    static void testBatchExecutionWithDefaultConstructor() {
        Test.startTest();
        MeterReadingScheduleApprovalBatch batch = new MeterReadingScheduleApprovalBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }

    @isTest
    static void testBatchExecutionWithCustomQuery() {
        // Corrected: INCLUDE Assigned_Meter_Reader__c in SELECT to avoid SObjectException
        String customQuery = 'SELECT Id, Assigned_Meter_Reader__c, CreatedDate, AccountId, Meter_Reading__c, Customer_BP_Number__c,' +
                             'Scheduled_Date__c, Customer_Category__c,' +
                             'Meter_Reading_Order__c, Meter_Reading_Schedule__c, MRU__c, Appointment_Status__c, BP_Number__c,' +
                             'Metering_Agency__c, Portion__c, Meter_Reading_Unit__c, Building_Name__c, Postal_Code__c,' +
                             'Location__c, Road_Name__c FROM WorkOrder';

        Test.startTest();
        MeterReadingScheduleApprovalBatch batch = new MeterReadingScheduleApprovalBatch(null, customQuery, true);
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }
}