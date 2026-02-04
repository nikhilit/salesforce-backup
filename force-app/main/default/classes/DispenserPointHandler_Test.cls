@IsTest
public class DispenserPointHandler_Test {

    @testSetup
    static void setupData() {

        // Create Work Order
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'New'
        );
        insert wo;

        // Existing Dispenser Points (one already Live)
        List<Dispenser_Point__c> dpList = new List<Dispenser_Point__c>{
            new Dispenser_Point__c(
                WorkOrderID__c = wo.Id,
                Dispenser_Number__c='AT5958',
                Dispenser_Name__c='Point_1',
                Live__c = true
            ),
            new Dispenser_Point__c(
                WorkOrderID__c = wo.Id,
                Dispenser_Number__c='AT5968',
				Dispenser_Name__c='Point_2',
                Live__c = false
            )
        };
        insert dpList;
    }

    @IsTest
    static void testInsertLiveDispenserPoint() {

        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Insert new DP with Live = true
        Dispenser_Point__c newDp = new Dispenser_Point__c(
            WorkOrderID__c = wo.Id,
            Dispenser_Number__c='12121',
                Dispenser_Name__c='Point_1_New_1',
            Live__c = true
        );

        Test.startTest();
        insert newDp;
        Test.stopTest();

        // Fetch all related Dispenser Points
        List<Dispenser_Point__c> dpList = [
            SELECT Id, Live__c
            FROM Dispenser_Point__c
            WHERE WorkOrderID__c = :wo.Id
        ];

        Integer liveCount = 0;
        for (Dispenser_Point__c dp : dpList) {
            if (dp.Live__c) {
                liveCount++;
            }
        }
    }

    @IsTest
    static void testUpdateLiveDispenserPoint() {

        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        List<Dispenser_Point__c> dpList = [
            SELECT Id, Live__c
            FROM Dispenser_Point__c
            WHERE WorkOrderID__c = :wo.Id
            ORDER BY CreatedDate
        ];

        // Make sure first record is false and second is true
        dpList[0].Live__c = false;
        dpList[1].Live__c = true;
        update dpList;

        // Now flip Live flag to first record
        dpList[0].Live__c = true;

        Test.startTest();
        update dpList[0];
        Test.stopTest();

        List<Dispenser_Point__c> updatedList = [
            SELECT Id, Live__c
            FROM Dispenser_Point__c
            WHERE WorkOrderID__c = :wo.Id
        ];

        Integer liveCount = 0;
        for (Dispenser_Point__c dp : updatedList) {
            if (dp.Live__c) {
                liveCount++;
            }
        }

    }
}