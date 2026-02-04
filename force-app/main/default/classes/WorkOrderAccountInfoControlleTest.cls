@isTest
public class WorkOrderAccountInfoControlleTest {

    // Helper: Create Operating Hours
    private static Id createOperatingHours() {
        OperatingHours oh = new OperatingHours(
            Name = 'Test Hours',
            TimeZone = 'Asia/Kolkata'
        );
        insert oh;
        return oh.Id;
    }

    // Helper: Create Service Territory
    private static Id createServiceTerritory() {
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory',
            OperatingHoursId = createOperatingHours()
        );
        insert st;
        return st.Id;
    }

    // Helper: Create Work Order
    private static Id createWorkOrder() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Subject = 'Test WO',
            Status = 'New',
            Priority = 'Medium'
        );
        insert wo;
        return wo.Id;
    }

    // Helper: Create Service Appointment safely
    private static Id createServiceAppointment(Id woId) {
        ServiceAppointment sa = new ServiceAppointment(
            //WorkOrderId = woId,
            ServiceTerritoryId = createServiceTerritory(),
            Status = 'New',
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addHours(2),
            Duration = 120,
            DurationType = 'Minutes',
            EarliestStartTime = System.now(),
            DueDate = System.today()
        );
        //insert sa;
        return sa.Id;
    }

    // Helper: Create Group Data (fixed Decimal error)
    private static Id insertGroupData() {
        Group_Master__c gm = new Group_Master__c(
            Name = 'GM1',
            Active__c = true
           // Group_Code__c = 'G001'
        );
        insert gm;

        Group_Code__c gc = new Group_Code__c(
            Name = 'GC1',
            Active__c = true,
            Group_Master__c = gm.Id
          //  Code__c = 'C001'
        );
        insert gc;

        Group_Message__c gmMsg = new Group_Message__c(
            Name = 'Msg1',
            Active__c = true,
            Group_Code__c = gc.Id
        );
        insert gmMsg;

        return gm.Id;
    }

    @isTest
    static void testControllerMethods() {
        Id woId = createWorkOrder();
        Id saId = createServiceAppointment(woId);
        Id groupId = insertGroupData();

        Test.startTest();
        // Call your controller methods here
        // Example:
        //WorkOrderAccountInfoController.getWorkOrderDetails(woId);
       // WorkOrderAccountInfoController.getServiceAppointmentDetails(saId);
        Test.stopTest();
    }
}