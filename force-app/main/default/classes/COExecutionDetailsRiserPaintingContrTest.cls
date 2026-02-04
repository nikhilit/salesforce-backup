@isTest
public class COExecutionDetailsRiserPaintingContrTest {

    @testSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert testAccount;

        // Create test WorkType
        WorkType testWorkType = new WorkType(
            Name = 'Disconnection WorkType',
            EstimatedDuration = 2.5
        );
        insert testWorkType;

        // Create test WorkOrder (with required fields)
        WorkOrder testWorkOrder = new WorkOrder(
            AccountId = testAccount.Id,
            WorkTypeId = testWorkType.Id,
            Status = 'New',
            Subject = 'Test WorkOrder',
            Number_of_Risers__c = '3',
            Number_of_Floors__c = 1,
            Type_of_Riser__c = 'Welded',
            Length_Of_Approcah_Riser__c = '1'
        );
        insert testWorkOrder;

        // Create test WorkPlan
        WorkPlan testWorkPlan = new WorkPlan(
            Name = 'Test WorkPlan',
            WorkOrderId = testWorkOrder.Id
        );
        insert testWorkPlan;

        // Create test WorkSteps (under WorkPlan)
        List<WorkStep> workSteps = new List<WorkStep>();
        workSteps.add(new WorkStep(
            Name = 'CO Execution Detail',
            WorkPlanId = testWorkPlan.Id,
            Status = 'New' 
        ));
        workSteps.add(new WorkStep(
            Name = 'Other Step',
            WorkPlanId = testWorkPlan.Id,
            Status = 'New'
        ));
        insert workSteps;
    }

    @isTest
    static void testGetWorkOrder_Success() {
        WorkOrder testWo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        WorkOrder result = COExecutionDetailsRiserPaintingContr.getWorkOrder(testWo.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'WorkOrder should not be null');
        System.assertEquals(testWo.Id, result.Id, 'WorkOrder Id should match');
    }

    @isTest
    static void testGetWorkOrder_Failure() {
        Test.startTest();
        WorkOrder result = COExecutionDetailsRiserPaintingContr.getWorkOrder('invalidId');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return an empty WorkOrder object');
        System.assertEquals(null, result.Id, 'Empty WorkOrder should not have an Id');
    }

    @isTest
    static void testSaveCODetails_InsertsWOLIsAndUpdatesWorkStep() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        COExecutionDetailsRiserPaintingContr.saveCODetails(wo.Id,'3',1,'Welded','1');
        Test.stopTest();

        List<WorkOrderLineItem> wolis = [
            SELECT Id, Riser_Name__c, WorkOrderId
            FROM WorkOrderLineItem
            WHERE WorkOrderId = :wo.Id
            ORDER BY Riser_Name__c
        ];

        System.assertEquals(3, wolis.size(), '3 WOLIs should have been inserted');
        System.assertEquals('Riser 1', wolis[0].Riser_Name__c);
        System.assertEquals('Riser 2', wolis[1].Riser_Name__c);
        System.assertEquals('Riser 3', wolis[2].Riser_Name__c);

        WorkStep ws = [
            SELECT Id, Status
            FROM WorkStep
            WHERE Name = 'CO Execution Detail'
            LIMIT 1
        ];
        System.assertEquals('Completed', ws.Status, 'WorkStep status should be updated to Completed');
    }
}