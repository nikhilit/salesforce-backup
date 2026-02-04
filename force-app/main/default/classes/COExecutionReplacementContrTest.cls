@isTest
public class COExecutionReplacementContrTest {

    // Utility method to create base test data
    private static WorkOrder createTestWorkOrder() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            AccountId = acc.Id,
            Number_of_Risers__c = '1',
            Number_of_Floors__c = 1
        );
        insert wo;

        return wo;
    }

    @isTest
    static void testGetWorkOrder() {
        WorkOrder wo = createTestWorkOrder();

        Test.startTest();
        WorkOrder result = COExecutionDetailsRiserReplacementContr.getWorkOrder(wo.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'WorkOrder should not be null');
        System.assertEquals(wo.Id, result.Id, 'Should return same WorkOrder');
    }

    @isTest
    static void testSaveCODetails() {
        WorkOrder wo = createTestWorkOrder();

        Test.startTest();
        COExecutionDetailsRiserReplacementContr.saveCODetails(
            wo.Id,
            '2',       
            5,          
            'Welded'    
        );
        Test.stopTest();

        // Assertions
        WorkOrder woAfter = [SELECT Id, Number_of_Risers__c, Number_of_Floors__c, Type_of_Riser__c
                             FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('2', woAfter.Number_of_Risers__c, 'Riser number should be updated');
        System.assertEquals(5, woAfter.Number_of_Floors__c, 'Floors should be updated');
        System.assertEquals('Welded', woAfter.Type_of_Riser__c, 'Riser type should be updated');

        List<WorkOrderLineItem> woli = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :wo.Id];
        System.assertEquals(2, woli.size(), 'Should insert 2 WorkOrderLineItems');
    }

    @isTest
    static void testGetWorkOrderWithInvalidId() {
        Test.startTest();
        // Passing a non-existing Id to cover exception branch
        WorkOrder result = COExecutionDetailsRiserReplacementContr.getWorkOrder('001000000000000AAA');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return an empty WorkOrder instead of null');
    }

    @isTest
    static void testSaveCODetailsWithInvalidRiserNumber() {
        WorkOrder wo = createTestWorkOrder();
    
        Test.startTest();
        // Passing invalid riserNumber (non-numeric) to hit exception handling
        COExecutionDetailsRiserReplacementContr.saveCODetails(
            wo.Id,
            'ABC',      
            3,
            'Threaded'   
        );
        Test.stopTest();
    
        // Assert WorkOrder is unchanged (because exception rolled back update)
        WorkOrder woAfter = [SELECT Number_of_Risers__c, Number_of_Floors__c, Type_of_Riser__c 
                             FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('1', woAfter.Number_of_Risers__c, 
            'Invalid riser number should not overwrite existing value');
    }
}