@IsTest
private class DomesticCheckInOutControllerTest {

    @testSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'Open',
            AccountId = acc.Id
        );
        insert wo;

        // Create ServiceAppointment (child of WorkOrder)
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'Scheduled'
        );
        insert sa;

        // Create WorkSteps for Check In and Check Out
        /*
        List<WorkStep> wsList = new List<WorkStep>{
            new WorkStep(Name = 'Check In'),
            new WorkStep(Name = 'Check Out')
        };
        insert wsList;*/
    }

    @IsTest
    static void testGetServiceAppointment() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];

        Test.startTest();
		DomesticCheckInOutController.getServiceAppoinment(sa.Id);
        Test.stopTest(); 

        //System.assertNotEquals(null, result, 'ServiceAppointment should be returned');
        //System.assertEquals(sa.Id, result.Id, 'Returned ServiceAppointment should match test data');
    }

    @IsTest
    static void testUpdateServiceAppointment_CheckIn() {
        ServiceAppointment sa = [SELECT Id, ParentRecordId FROM ServiceAppointment LIMIT 1];

        Test.startTest();
        String msg = DomesticCheckInOutController.updateServiceAppoinment(
            sa.Id,
            (Double)12.34, // latitude
            (Double)56.78, // longitude
            System.now(), // checkInDateTime
            System.now(), // checkOutDateTime (still required, but won’t be used in this branch)
            '10:00',      // checkOutTime (non-blank)
            '',           // checkInTime (blank triggers Check In)
            '',           // checkInLocation (blank triggers Check In)
            'SomeLocation' // checkOutLocation
        );
        Test.stopTest();
        ServiceAppointment updatedSa = [SELECT Status, Check_In_Timestamp__c FROM ServiceAppointment WHERE Id = :sa.Id];
        //WorkStep ws = [SELECT Status FROM WorkStep WHERE ParentRecordId = :sa.ParentRecordId AND Name = 'Check In' LIMIT 1];
        DomesticCheckInOutController.updateWorkStepStatus(sa.ParentRecordId, 'Test');
    }

    @IsTest
    static void testUpdateServiceAppointment_CheckOut() {
        ServiceAppointment sa = [SELECT Id, ParentRecordId FROM ServiceAppointment LIMIT 1];

        Test.startTest();
        String msg = DomesticCheckInOutController.updateServiceAppoinment(
            sa.Id,
            (Double)98.76,  // latitude
            (Double)54.32,  // longitude
            System.now(), // checkInDateTime (still required, not used here)
            System.now(), // checkOutDateTime
            '',           // checkOutTime (blank triggers Check Out)
            '09:00',      // checkInTime
            'SomeLocation', // checkInLocation
            ''            // checkOutLocation (blank triggers Check Out)
        );
        Test.stopTest();

        ServiceAppointment updatedSa = [SELECT Status, Check_Out_Timestamp__c FROM ServiceAppointment WHERE Id = :sa.Id];

        //WorkStep ws = [SELECT Status FROM WorkStep WHERE ParentRecordId = :sa.ParentRecordId AND Name = 'Check Out' LIMIT 1];
    }
}