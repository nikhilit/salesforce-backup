@IsTest
private class DisconnectionNoticeForDomesticCtrlTest {

    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(
            FirstName__c = 'John',
            LastName__c = 'Doe',
            CA_Number__c = 'CA12345',
            BP_Number__c = 'BP98765',
            Flat__c = '101',
            Floor__c = '1',
            Building_name__c = 'Skyline Tower',
            Street__c = 'Main Street',
            City__c = 'Metropolis',
            Postal_Code__c = '123456',
            Name = 'John Doe Household'
        );
        insert acc;

        // Create WorkOrder linked to Account
        WorkOrder wo = new WorkOrder(
            Subject = 'Disconnection WO',
            AccountId = acc.Id,
            Status = 'Open',
            Due_Amount__c = 2500.50,
            StartDate = System.today(),
            EndDate = System.today().addDays(10)
        );
        insert wo;
    }

    @IsTest
    static void testControllerWithValidWorkOrder() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        // Simulate VF page param
        ApexPages.currentPage().getParameters().put('id', wo.Id);
        DisconnectionNoticeForDomesticController ctrl = new DisconnectionNoticeForDomesticController();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, ctrl.todayDate, 'Today date should be set');
        System.assertNotEquals(null, ctrl.referenceNumber, 'Reference number should be generated');
        System.assertEquals('CA12345', ctrl.caNumber, 'CA Number should match test data');
        System.assertEquals('BP98765', ctrl.bpNumber, 'BP Number should match test data');
        System.assertEquals('John Doe', ctrl.customerName, 'Customer name should match concatenated fields');
        System.assertEquals('101', ctrl.flat);
        System.assertEquals('1', ctrl.floor);
        System.assertEquals('Skyline Tower', ctrl.building);
        System.assertEquals('Main Street', ctrl.street);
        System.assertEquals('Metropolis', ctrl.city);
        System.assertEquals('123456', ctrl.postalCode);
        System.assertEquals(2500.50, ctrl.pendingAmount, 'Pending amount should match test data');
    }

    @IsTest
    static void testControllerWithoutId() {
        Test.startTest();
        // No Id param provided
        ApexPages.currentPage().getParameters().clear();
        DisconnectionNoticeForDomesticController ctrl = new DisconnectionNoticeForDomesticController();
        Test.stopTest();

        // Validate error message is added
        List<ApexPages.Message> msgs = ApexPages.getMessages();
        System.assertEquals(1, msgs.size(), 'One error message should be present');
        System.assertEquals('Work Order ID not provided.', msgs[0].getSummary());
    }
}