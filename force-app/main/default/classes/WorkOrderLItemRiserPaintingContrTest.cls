@isTest
public class WorkOrderLItemRiserPaintingContrTest {

    @TestSetup
    static void setupTestData() {
        // Create Account for WorkOrder
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create WorkType for WorkOrder
        WorkType wt = new WorkType(Name = 'Painting', EstimatedDuration = 2.0, DurationType = 'Hours');
        insert wt;

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            WorkTypeId = wt.Id,
            Status = 'New'
        );
        insert wo;

        // Create WorkOrderLineItems
        List<WorkOrderLineItem> items = new List<WorkOrderLineItem>();
        items.add(new WorkOrderLineItem(WorkOrderId = wo.Id, Riser_Name__c = 'Riser A'));
        items.add(new WorkOrderLineItem(WorkOrderId = wo.Id, Riser_Name__c = 'Riser B'));
        insert items;
    }

    @isTest
    static void testGetWorkOrderLineItems() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        List<WorkOrderLItemRiserPaintingContr.WorkOrderLineItemWrapper> wrapperList =
            WorkOrderLItemRiserPaintingContr.getWorkOrderLineItems(wo.Id);
        Test.stopTest();

        // Verify the wrapper list size and values
        System.assertEquals(2, wrapperList.size(), 'There should be 2 line items');
        System.assertEquals('Riser A', wrapperList[0].name, 'First wrapper name should match');
        System.assertEquals('Riser B', wrapperList[1].name, 'Second wrapper name should match');
        System.assertEquals(1, wrapperList[0].index, 'Index should start at 1');
        System.assertEquals(2, wrapperList[1].index, 'Index should increment correctly');
    }
}