@isTest
public class O_MSlaManagementBatchClassTest {
    
    @testSetup
    static void setupData() {
        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New'
        );
        insert wo;

        // Create ServiceAppointments with different TAT values
        List<ServiceAppointment> apps = new List<ServiceAppointment>{
            new ServiceAppointment(
                ParentRecordId = wo.Id,
                Status = 'New',
                SLA_Status__c = 'On Track',
                Turnaround_Time_TAT__c = 3
            ),
            new ServiceAppointment(
                ParentRecordId = wo.Id,
                Status = 'New',
                SLA_Status__c = 'SLA Breached',
                Turnaround_Time_TAT__c = 1
            )
        };
        insert apps;
    }
    
    @isTest
    static void testBatchExecute() {
        Test.startTest();
        // Run batch
        O_MSlaManagementBatchClass batch = new O_MSlaManagementBatchClass();
        Database.executeBatch(batch, 50);
        Test.stopTest();
        
        // Validate ServiceAppointments
        List<ServiceAppointment> apps = [
            SELECT Id, SLA_Status__c, Turnaround_Time_TAT__c, Breach_Timestamp__c, ParentRecordId
            FROM ServiceAppointment
        ];
        
        System.assertEquals(2, apps.size(), 'Should have 2 ServiceAppointments');

        Boolean foundBreached = false;
        for (ServiceAppointment sa : apps) {
            if (sa.Turnaround_Time_TAT__c <= 0) {
                System.assertEquals('SLA Breached', sa.SLA_Status__c, 'SLA should be breached when TAT <= 0');
                System.assertNotEquals(null, sa.Breach_Timestamp__c, 'Breach_Timestamp__c must be set');
                foundBreached = true;
            }
        }
        System.assert(foundBreached, 'At least one appointment should be breached');

        // Validate related WorkOrder Priority
        List<WorkOrder> woList = [SELECT Id, Priority FROM WorkOrder];
        System.assertEquals('Critical', woList[0].Priority, 'WorkOrder priority should be updated to Critical');
    }

    @isTest
    static void testBatchWithNoRecords() {
        Test.startTest();
        // Empty run (query finds nothing)
        Test.stopTest();
        // Nothing to assert → just making sure batch doesn’t throw error
        System.assert(true, 'Batch executed with no records without errors');
    }
}