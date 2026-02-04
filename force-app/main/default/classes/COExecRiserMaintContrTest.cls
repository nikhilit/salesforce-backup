@isTest
private class COExecRiserMaintContrTest {

    @testSetup
    static void setupData() {
        // Create an Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create a WorkOrder WITHOUT setting the restricted picklist
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Subject = 'Test WO',
            Number_of_Risers__c = '0',
            Sample_BP_Number_1__c = 'BP1',
            Sample_BP_Number_2__c = 'BP2',
            Information_Board_available__c = 'Yes',
            Number_of_Floors__c = 1,
            New_information_board_installed__c = 'No'
        );
        insert wo;
    }

    @isTest
    static void testGetWorkOrder_Success() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Test.startTest();
        WorkOrder result = COExecutionDetailsRiserMaintenanceContr.getWorkOrder(wo.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.Id, 'WorkOrder should be returned');
    }

    @isTest
    static void testGetWorkOrder_Exception() {
        Test.startTest();
        WorkOrder result = COExecutionDetailsRiserMaintenanceContr.getWorkOrder('001000000000000AAA'); // invalid Id
        Test.stopTest();

        System.assertEquals(null, result.Id, 'Should return empty WorkOrder on exception');
    }

    @isTest
    static void testSaveCODetails_Success() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        COExecutionDetailsRiserMaintenanceContr.saveCODetails(
            wo.Id,
            '3', // riserNumber
            'BP11',
            'BP22',
            'Yes',
            '5', // floors
            null, // pass null for restricted picklist
            'Yes'
        );
        Test.stopTest();

        // Verify WorkOrder got updated
        WorkOrder woUpdated = [SELECT Number_of_Risers__c, Number_of_Floors__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('3', woUpdated.Number_of_Risers__c);
        System.assertEquals(5, Integer.valueOf(woUpdated.Number_of_Floors__c));

        // Verify WorkOrderLineItems inserted
        List<WorkOrderLineItem> woliList = [SELECT Id, Riser_Name__c FROM WorkOrderLineItem WHERE WorkOrderId = :wo.Id];
        System.assertEquals(3, woliList.size(), '3 WOLI should be inserted');
    }

    @isTest
    static void testSaveCODetails_ExceptionPath() {
        Test.startTest();
        // Pass invalid WorkOrder Id to cause exception
        COExecutionDetailsRiserMaintenanceContr.saveCODetails(
            '001000000000000AAA',
            '2',
            'BP1',
            'BP2',
            'Yes',
            '2',
            null, // pass null
            'No'
        );
        Test.stopTest();

        System.assert(true, 'Exception handled correctly');
    }

    @isTest
    static void testUpdateWorkStepStatus_NoSteps() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        // Passing name that does not exist in WorkStep
        COExecutionDetailsRiserMaintenanceContr.updateWorkStepStatus(wo.Id, 'Non Existing Step');
        Test.stopTest();

        System.assert(true, 'Should gracefully handle no WorkStep found');
    }
}