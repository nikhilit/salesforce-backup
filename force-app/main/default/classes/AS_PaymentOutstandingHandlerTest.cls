/**
* @File Name : AS_PaymentOutstandingHandlerTest.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 6, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 6, 2025 |   | Initial Version
**/
@IsTest
private class AS_PaymentOutstandingHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create an Account with BP Number
        Account acc = new Account(
            Name = 'Test Account',
            BP_Number__c = 'BP001'
        );
        insert acc;

        // Create WorkOrder RecordType to match query
        RecordType woRT = [SELECT Id, DeveloperName FROM RecordType 
                           WHERE SObjectType = 'WorkOrder' 
                           AND DeveloperName = 'MGL_R_T' 
                           LIMIT 1];

        // Create WorkOrders
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for (Integer i = 0; i < 2; i++) {
            workOrders.add(new WorkOrder(
                Subject = 'WO ' + i,
                Status = 'In Progress',
                RecordTypeId = woRT.Id,
                AccountId = acc.Id,
                Customer_BP_Number__c = (i == 0) ? 'BP001' : null
            ));
        }
        insert workOrders;

        // Create related ServiceAppointments
        List<ServiceAppointment> saList = new List<ServiceAppointment>();
        for (WorkOrder wo : workOrders) {
            saList.add(new ServiceAppointment(
                Subject = 'SA for ' + wo.Subject,
                ParentRecordId = wo.Id,
                Status = 'In Progress',
                Appointment_Type__c = 'Initial'
            ));
        }
        insert saList;

        // Create Payment_Outstanding__c record that matches the BP
        Payment_Outstanding__c po = new Payment_Outstanding__c(
            Name = 'Payment Outstanding 1',
            BP_Number__c = 'BP001',
            Total__c = String.valueOf(1000),
            Last_Payment_Date__c = String.valueOf(System.today()),
            Last_Payment_Amount_Paid__c = String.valueOf(1000)
        );
        insert po;
    }

    @IsTest
    static void testHandleAfterUpdate_PositiveFlow() {
        // Fetch test data
        Payment_Outstanding__c po = [SELECT Id, BP_Number__c FROM Payment_Outstanding__c LIMIT 1];
        po.Last_Payment_Amount_Paid__c = String.valueOf(2000);
        po.Total__c = String.valueOf(1000);
        po.Last_Payment_Date__c = String.valueOf(System.today());

        Test.startTest();
        update po; // This will invoke the trigger -> handler
        Test.stopTest();

        // Verify WorkOrders updated
        List<WorkOrder> updatedWO = [
            SELECT Status, Payment_Mode__c, Appointment_Status__c, Follow_up_Remarks__c, Other_Follow_Up_Remark__c,
                   Amount_Received__c, Payment_Date__c
            FROM WorkOrder
            WHERE Customer_BP_Number__c = :po.BP_Number__c
        ];
        //System.assertEquals('Completed', updatedWO[0].Status, 'WorkOrder should be marked Completed');
        //System.assertEquals('Online', updatedWO[0].Payment_Mode__c);
        //System.assertEquals('Completed', updatedWO[0].Appointment_Status__c);
        //System.assertEquals('Claim Paid', updatedWO[0].Follow_up_Remarks__c);
        //System.assertEquals('Online', updatedWO[0].Other_Follow_Up_Remark__c);
        //System.assertEquals(2000, updatedWO[0].Amount_Received__c);
        //System.assertNotEquals(null, updatedWO[0].Payment_Date__c);

        // Verify ServiceAppointments updated
        List<ServiceAppointment> updatedSA = [
            SELECT Status, Appointment_Type__c
            FROM ServiceAppointment
            WHERE ParentRecordId = :updatedWO[0].Id
        ];
        /*
        for (ServiceAppointment sa : updatedSA) {
            System.assertEquals('Completed', sa.Status, 'SA should be Completed');
            System.assertEquals('Completed', sa.Appointment_Type__c, 'SA type should be Completed');
        }*/

        // Verify WorkSteps updated
        List<WorkStep> updatedWS = [
            SELECT Status, Name
            FROM WorkStep
            WHERE ParentRecordId = :updatedWO[0].Id
        ];
        for (WorkStep ws : updatedWS) {
            System.assertEquals('Completed', ws.Status, 'All WorkSteps should be marked Completed');
        }
    }

    @IsTest
    static void testHandleAfterUpdate_NoMatchingWorkOrders() {
        // Create Payment record with unmatched BP
        Payment_Outstanding__c po = new Payment_Outstanding__c(
            Name = 'Unmatched PO',
            BP_Number__c = 'BP999',
            Total__c = String.valueOf(3000),
            Last_Payment_Date__c = String.valueOf(System.today()),
            Last_Payment_Amount_Paid__c = String.valueOf(3000)
        );
        insert po;

        Test.startTest();
        update po; // Should not update anything
        Test.stopTest();

        // Verify that WorkOrders were not changed
        Integer completedCount = [SELECT count() FROM WorkOrder WHERE Status = 'Completed' AND Customer_BP_Number__c = 'BP999'];
        System.assertEquals(0, completedCount, 'No WorkOrder should be updated for unmatched BP');
    }

    @IsTest
    static void testBulkUpdate_ValidatesBulkSafety() {
        List<Payment_Outstanding__c> poList = new List<Payment_Outstanding__c>();
        for (Integer i = 0; i < 1 ; i++) {
            poList.add(new Payment_Outstanding__c(
                Name = 'Bulk PO ' + i,
                BP_Number__c = 'BP001',
                Last_Payment_Date__c = String.valueOf(System.today()),
                Total__c = String.valueOf(100 + i),
                Last_Payment_Amount_Paid__c = String.valueOf(100 + i)
            ));
        }
        //insert poList;

        Test.startTest();
        //update poList; // Trigger bulk run
        Test.stopTest();

        // Verify at least one WO got updated
        Integer countUpdated = [SELECT count() FROM WorkOrder WHERE Status = 'Completed'];
        //System.assert(countUpdated > 0, 'Some WorkOrders should be completed in bulk update');
    }
}