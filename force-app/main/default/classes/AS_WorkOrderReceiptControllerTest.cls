@IsTest
private class AS_WorkOrderReceiptControllerTest {

    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            BP_Number__c = 'BP123',
            CA_Number__c = 'CA123'
        );
        insert acc;

        // Create User (as Agent__c & Owner)
        User u = [SELECT Id, Name FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        // Create a custom Agency (if lookup requires record)
        // Using a generic Account to simulate R_T_Agency__r
        Account agency = new Account(Name = 'Test Agency');
        insert agency;

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            AccountId = acc.Id,
            OwnerId = u.Id,
            //Agent__c = u.Id,     
            //R_T_Agency__c = agency.Id,
            Due_Amount__c = 1200.50,
            Payment_Mode__c = 'Cash',
            //Bank_Name__c = 'Test Bank',
            Amount_Received__c = 1000.00,
            Transaction_Id__c = 'TXN123'
        );
        insert wo;
        
        Payment__c pay = new Payment__c(
            Name = 'testCheque',
            Cheque_Number__c = '23123123',
            Work_Order__c = wo.Id
        );
        insert pay;
    }

    @IsTest
    static void testControllerWithValidWorkOrderUPI() {
        WorkOrder wo = [SELECT Id, Account.Name FROM WorkOrder LIMIT 1];

        Test.startTest();
        // Simulate page parameter
        ApexPages.currentPage().getParameters().put('id', wo.Id);
        AS_WorkOrderReceiptController ctrl = new AS_WorkOrderReceiptController();
        Test.stopTest();
    }
    
    @IsTest
    static void testControllerWithValidWorkOrderCheque() {
        WorkOrder wo = [SELECT Id, Account.Name FROM WorkOrder LIMIT 1];

        Test.startTest();
        // Simulate page parameter
        ApexPages.currentPage().getParameters().put('id', wo.Id);
        ApexPages.currentPage().getParameters().put('mode', 'cheque');
        AS_WorkOrderReceiptController ctrl = new AS_WorkOrderReceiptController();
        Test.stopTest();
    }

    @IsTest
    static void testControllerWithoutId() {
        Test.startTest();
        ApexPages.currentPage().getParameters().clear();

        Boolean exceptionThrown = false;
        try {
            new AS_WorkOrderReceiptController();
        } catch (QueryException qe) {
            exceptionThrown = true;
        }
        Test.stopTest();
    }
}