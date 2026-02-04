@isTest
private class MRSMROReassignController_Test {

    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Meter Reading Schedule
        Meter_Reading_Schedule__c mrs = new Meter_Reading_Schedule__c(
            Meter_Reading_Start_Date__c = Date.today(),
            Meter_Reading_Completion_Date__c = Date.today().addDays(5)
        );
        insert mrs;

        // Create Work Orders related to MRS
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for (Integer i = 0; i < 5; i++) {
            workOrders.add(new WorkOrder(
                AccountId = acc.Id,
                Meter_Reading_Schedule__c = mrs.Id,
                Appointment_Status__c = (i < 3) ? 'Unattempted' : 'Completed',
                Customer_BP_Number__c = 'BP-' + i,
                Building_Name__c = 'Building-' + i,
                StartDate = Date.today(),
                EndDate = Date.today().addDays(1)
            ));
        }
        insert workOrders;
    }

    @isTest
    static void test_getCurrentMRURecord_success() {
        Meter_Reading_Schedule__c mrs = [SELECT Id FROM Meter_Reading_Schedule__c LIMIT 1];
        Test.startTest();
        Meter_Reading_Schedule__c result = MRSMROReassignController.getCurrentMRURecord(mrs.Id);
        Test.stopTest();

    }

    @isTest
    static void test_getCurrentMRURecord_invalidId() {
        Test.startTest();
        Meter_Reading_Schedule__c result = MRSMROReassignController.getCurrentMRURecord('001000000000001AAA');
        Test.stopTest();

    }

    @isTest
    static void test_getMRSRelatedWorkOrders_withOffset() {
        Meter_Reading_Schedule__c mrs = [SELECT Id FROM Meter_Reading_Schedule__c LIMIT 1];

        Test.startTest();
        List<WorkOrder> result = MRSMROReassignController.getMRSRelatedWorkOrders(mrs.Id, 2, 0);
        Test.stopTest();

    }

    @isTest
    static void test_getMRSRelatedWorkOrdersNoOffset() {
        Meter_Reading_Schedule__c mrs = [SELECT Id FROM Meter_Reading_Schedule__c LIMIT 1];

        Test.startTest();
        List<WorkOrder> result = MRSMROReassignController.getMRSRelatedWorkOrdersNoOffset(mrs.Id);
        Test.stopTest();

    }

    @isTest
    static void test_getMRSRelatedWorkOrders_noRecordsFound() {
        Test.startTest();
        List<WorkOrder> result = MRSMROReassignController.getMRSRelatedWorkOrders('a00000000000001AAA', 10, 0);
        Test.stopTest();

    }
}