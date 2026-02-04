@isTest
private class WorkOrderBillControllerTest {
    @isTest
    static void testControllerWithWorkOrder() {
        // Create a WorkOrder (add required fields if your org has validation rules)
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'Open',    // Adjust if required in your org
            Bill_URL__c = '[{"321":"https://test-url.com/bNo/123"}]'
        );
        insert wo;

        // Simulate VF page and pass Id as parameter
        Test.startTest();
        PageReference pageRef = Page.ViewBill; // Replace with your VF page name
        pageRef.getParameters().put('Id', wo.Id);
        pageRef.getParameters().put('bNo', '321');
        Test.setCurrentPage(pageRef);

        // Instantiate controller
        WorkOrderBillController ctrl = new WorkOrderBillController();

        Test.stopTest();

    }

    @isTest
    static void testControllerWithoutId() {
        Test.startTest();
        PageReference pageRef = Page.ViewBill; // Replace with your VF page name
        Test.setCurrentPage(pageRef);

        WorkOrderBillController ctrl = new WorkOrderBillController();
        Test.stopTest();

    }
}