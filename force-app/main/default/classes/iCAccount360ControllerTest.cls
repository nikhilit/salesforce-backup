@IsTest
private class iCAccount360ControllerTest {

    // Test Data Setup - Runs once per test class execution
    @testSetup
    static void setupTestData() {
        // Create an Account
        Account acc = new Account(
            Name = 'Test Account',
            Phone = '1234567890',
            Secondary_Telephone__c = '9876543210',
            Account_Email__c = 'test@test.com',
            //Account_Type__c = 'Residential',
            Type = 'Customer',
            MRU_Code__c = 'MRU123',
            BP_Number__c = 'BP123',
            CA_Number__c = 'CA123',
            Building_name__c = 'Test Building',
            Street__c = 'Test Street',
            Colony__c = 'Test Colony',
            Wing__c = 'A',
            Floor__c = '1',
            Flat__c = '101',
            Road_name__c = 'Main Road'
        );
        insert acc;

        // Create WorkOrder linked to Account
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            AccountId = acc.Id,
            Status = 'Open'
        );
        insert wo;

        // Create ServiceAppointment linked to WorkOrder
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'Scheduled',
            SchedStartTime = System.today(),
            SchedEndTime = System.today().addDays(1),
            Follow_up_Remarks__c = 'Follow-up needed'
        );
        insert sa;

        // WorkOrder without Account (for negative test)
        WorkOrder woNoAcc = new WorkOrder(
            Subject = 'WO without Account',
            Status = 'Open'
        );
        insert woNoAcc;
    }

    @IsTest
    static void testGetAccountInfoFromSA_Success() {
        // Get the test WorkOrder created in setup
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE AccountId != null LIMIT 1];

        Test.startTest();
        Map<String, Object> result = iCAccount360Controller.getAccountInfoFromSA(wo.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('acc'), 'Account should be present in result');
        System.assert(result.containsKey('workOrder'), 'WorkOrder should be present in result');
        System.assert(result.containsKey('serviceAppointments'), 'ServiceAppointments should be present');

        Account acc = (Account) result.get('acc');
        //System.assertEquals('Test Account', acc.Name, 'Account name should match');
    }

    @IsTest
    static void testGetAccountInfoFromSA_NullId() {
        Test.startTest();
        try {
            iCAccount360Controller.getAccountInfoFromSA(null);
            System.assert(false, 'Exception should have been thrown for null Id');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Work Order Id is null'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetAccountInfoFromSA_NoAccount() {
        // WorkOrder without Account
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE AccountId = null LIMIT 1];

        Test.startTest();
        try {
            iCAccount360Controller.getAccountInfoFromSA(wo.Id);
            System.assert(false, 'Exception should have been thrown for WorkOrder without Account');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('No Account associated'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetAccountInfoFromSA_InvalidId() {
        Test.startTest();
        
        // Passing random Id not linked to WorkOrder
        //iCAccount360Controller.getAccountInfoFromSA('001000000000000AAA');
        
        Test.stopTest();
    }
}