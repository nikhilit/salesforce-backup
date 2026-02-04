@isTest
private class WorkOrderLItemRiserReplacementContrTest {

    @isTest
    static void testGetWorkOrderLineItems() {
        // Create a test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create a WorkType (required for WorkOrder)
        WorkType wt = new WorkType(Name = 'Test WorkType',EstimatedDuration=60);
        insert wt;

        // Create a WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            AccountId = acc.Id,
            Status = 'New',
            WorkTypeId = wt.Id
        );
        insert wo;

        // Create WorkOrderLineItem(s)
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        for (Integer i = 0; i < 3; i++) {
            woliList.add(new WorkOrderLineItem(
                WorkOrderId = wo.Id,
                Description = 'Line Item ' + i,
                Riser_Name__c = 'Riser ' + i
            ));
        }
        insert woliList;

        Test.startTest();
        // Call your controller method
        List<WorkOrderLItemRiserReplacementContr.WorkOrderLineItemWrapper> results =
            WorkOrderLItemRiserReplacementContr.getWorkOrderLineItems(wo.Id);
        Test.stopTest();
    }
}