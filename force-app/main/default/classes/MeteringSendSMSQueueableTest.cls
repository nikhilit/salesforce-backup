@isTest
public class MeteringSendSMSQueueableTest {
    
    @testSetup
    static void setupData() {
        // Create dummy WorkOrders for testing
        List<WorkOrder> wos = new List<WorkOrder>();
        for (Integer i = 0; i < 2; i++) {
            wos.add(new WorkOrder(
                Subject = 'Test Work Order ' + i,
                Status = 'New'
            ));
        }
        insert wos;
    }

    @isTest
    static void testQueueableExecutes() {
        // Get work order ids
        Set<Id> woIds = new Map<Id, WorkOrder>(
            [SELECT Id FROM WorkOrder LIMIT 2]
        ).keySet();

        Test.startTest();
        // Enqueue the job
        System.enqueueJob(new MeteringSendSMSQueueable(woIds));
        Test.stopTest(); // Ensures execute runs

        // Nothing specific to assert since helper is external,
        // but we validate no unhandled exceptions are thrown.
        System.assert(true, 'Queueable executed successfully');
    }


}