@IsTest
private class MeterReadingScheduleHelper_Test {

    @TestSetup
    static void setupData() {
        // Create Record Type for Work Order (simulate MGL_Metering)
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'WorkOrder' AND DeveloperName = 'MGL_Metering' LIMIT 1];

        // Create Meter Reading Schedules
        List<Meter_Reading_Schedule__c> schedules = new List<Meter_Reading_Schedule__c>();
        for (Integer i = 0; i < 2; i++) {
            schedules.add(new Meter_Reading_Schedule__c(
            ));
        }
        insert schedules;

        // Create Meter Reading Orders
        List<Meter_Reading_Order__c> mros = new List<Meter_Reading_Order__c>();
        for (Integer i = 0; i < 3; i++) {
            mros.add(new Meter_Reading_Order__c(
                Name = 'MRO ' + i,
                Created_Order__c = true,
                Business_Partner_Consumer_ID__c='1223322'+i,
                Meter_Reading_Doc_Number__c='mordoc'+i
            ));
        }
        insert mros;

        // Create Work Orders for testing updateScheduleCounts
        List<WorkOrder> workOrders = new List<WorkOrder>{
            new WorkOrder(
                Subject = 'WO Completed',
                RecordTypeId = rt.Id,
                Appointment_Status__c = 'Completed',
                Meter_Reading_Schedule__c = schedules[0].Id,
                Meter_Reading_Order__c = mros[0].Id
            ),
            new WorkOrder(
                Subject = 'WO Incomplete',
                RecordTypeId = rt.Id,
                Appointment_Status__c = 'Incomplete',
                Meter_Reading_Schedule__c = schedules[0].Id,
                Meter_Reading_Order__c = mros[1].Id
            ),
            new WorkOrder(
                Subject = 'WO Unattempted',
                RecordTypeId = rt.Id,
                Appointment_Status__c = 'Unattempted',
                Meter_Reading_Schedule__c = schedules[1].Id,
                Meter_Reading_Order__c = mros[2].Id
            )
        };
        insert workOrders;
    }

    @IsTest
    static void test_updateScheduleCounts() {
        // Fetch data
        List<WorkOrder> newList = [SELECT Id, Appointment_Status__c, RecordTypeId, Meter_Reading_Schedule__c FROM WorkOrder];
        List<WorkOrder> oldList = newList.deepClone(true, true, true);

        Test.startTest();
        MeterReadingScheduleHelper.updateScheduleCounts(newList, oldList);
        Test.stopTest();

        // Validate that Meter_Reading_Schedule__c fields were updated correctly
        Map<Id, Meter_Reading_Schedule__c> updatedSchedules = new Map<Id, Meter_Reading_Schedule__c>(
            [SELECT Id, Completed_Count__c, Incompleted_Count__c, Unattempted_Count__c, No_of_Customer__c FROM Meter_Reading_Schedule__c]
        );

        // Schedule 0 should have 1 completed, 1 incomplete (2 total)
        System.assertEquals(1, updatedSchedules.values()[0].Completed_Count__c, 'Completed count should be 1');
        System.assertEquals(1, updatedSchedules.values()[0].Incompleted_Count__c, 'Incomplete count should be 1');
        System.assertEquals(0, updatedSchedules.values()[0].Unattempted_Count__c, 'Unattempted count should be 0');
        System.assertEquals(2, updatedSchedules.values()[0].No_of_Customer__c, 'Total should be 2');

        // Schedule 1 should have 1 unattempted (1 total)
        System.assertEquals(0, updatedSchedules.values()[1].Completed_Count__c, 'Completed count should be 0');
        System.assertEquals(0, updatedSchedules.values()[1].Incompleted_Count__c, 'Incomplete count should be 0');
        System.assertEquals(1, updatedSchedules.values()[1].Unattempted_Count__c, 'Unattempted count should be 1');
        System.assertEquals(1, updatedSchedules.values()[1].No_of_Customer__c, 'Total should be 1');
    }

    @IsTest
    static void test_mROtoUnallocatedBucket() {
        // Fetch WorkOrders and related MROs
        List<WorkOrder> workOrders = [SELECT Id, Meter_Reading_Order__c, RecordTypeId FROM WorkOrder WHERE Meter_Reading_Order__c != null];
        List<Meter_Reading_Order__c> beforeMROs = [SELECT Id, Created_Order__c FROM Meter_Reading_Order__c];

        // Ensure they are initially true
        for (Meter_Reading_Order__c mro : beforeMROs) {
            System.assertEquals(true, mro.Created_Order__c, 'Precondition: Created_Order__c should be true before deletion');
        }

        // Simulate delete trigger
        Test.startTest();
        MeterReadingScheduleHelper.mROtoUnallocatedBucket(workOrders);
        Test.stopTest();

        // Validate updates
        List<Meter_Reading_Order__c> updatedMROs = [SELECT Id, Created_Order__c FROM Meter_Reading_Order__c];
        for (Meter_Reading_Order__c mro : updatedMROs) {
            System.assertEquals(false, mro.Created_Order__c, 'Created_Order__c should be set to false after delete');
        }
    }
}