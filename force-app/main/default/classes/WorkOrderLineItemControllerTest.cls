@isTest
private class WorkOrderLineItemControllerTest {

    @testSetup
    static void setupTestData() {
        // Create a WorkOrder record
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            Status = 'New' // Make sure this is a valid picklist value
        );
        insert wo;

        // Create related WorkOrderLineItem records
        List<WorkOrderLineItem> lineItems = new List<WorkOrderLineItem>();
        for (Integer i = 1; i <= 3; i++) {
            lineItems.add(new WorkOrderLineItem(
                WorkOrderId = wo.Id,
                Riser_Name__c = 'Riser ' + i
            ));
        }
        insert lineItems;
    }

    @isTest
    static void testGetWorkOrderLineItems() {
        // Query the WorkOrder
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Call the method
        List<WorkOrderLineItemController.WorkOrderLineItemWrapper> result =
            WorkOrderLineItemController.getWorkOrderLineItems(wo.Id);

        // Verify the results
        System.assertEquals(3, result.size(), 'There should be 3 line items returned');

        // Verify index and names
        for (Integer i = 0; i < result.size(); i++) {
            System.assertEquals(i + 1, result[i].index, 'Index should match');
            System.assertEquals('Riser ' + (i + 1), result[i].name, 'Riser name should match');
            System.assertNotEquals(null, result[i].recordId, 'Record Id should not be null');
        }
    }
}