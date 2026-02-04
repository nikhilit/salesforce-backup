@isTest
private class UpdateCustomerControllerTest_MeterNumber {

    @testSetup
    static void setupTestData() {
        // Step 1: Create Account
        Account acc = new Account(
            Name = 'Test Account',
            Phone = '9999999999',
            Secondary_Telephone__c = '7777777777',
            Meter_Number__c = 'MTR-001',
            Account_Email__c = 'test@example.com'
        );
        insert acc;

        // Step 2: Create WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;

        // Step 3: Create WorkSteps (AFTER WorkOrder is inserted)
        List<WorkStep> steps = new List<WorkStep>{
            new WorkStep(
                Name = Label.Update_Meter_Number_Step_Name,
               // ParentRecordId = wo.Id,
                Status = 'Pending'
            ),
            new WorkStep(
                Name = Label.Update_Customer_Contact_Step_Name,
               // ParentRecordId = wo.Id,
                Status = 'Pending'
            )
        };
      //  insert steps;
    }

    @isTest static void testGetAccountRec() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        UpdateCustomerController.getAccountRec(wo.Id);
    }

    @isTest static void testGetAccountRecordDetails() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        UpdateCustomerController.getAccountRecordDetails(wo.Id);
    }

    @isTest static void testUpdateCustomerMeterNumber() {
        WorkOrder wo = [SELECT Id, AccountId FROM WorkOrder LIMIT 1];
        UpdateCustomerController.updateCustomerMeterNumber(
            wo.Id, 'MTR-002', 'Updated meter', wo.AccountId
        );
    }

    @isTest static void testUpdateCustomerContact() {
        WorkOrder wo = [SELECT Id, AccountId FROM WorkOrder LIMIT 1];
        UpdateCustomerController.updateCustomerContact(
            wo.Id, '9876543210', '9123456789', '9988776655',
            'Updated contact', wo.AccountId, 'newemail@example.com'
        );
    }

    @isTest static void testUpdateWorkStepStatus_NoSteps() {
        Account acc = new Account(Name = 'Temp');
        insert acc;

        WorkOrder wo = new WorkOrder(
            Subject = 'WO Without Steps',
            AccountId = acc.Id,
            Status = 'New'
        );
        insert wo;

        UpdateCustomerController.updateWorkStepStatus(wo.Id, 'Non-Existing Step');
    }

    @isTest static void testGetAccountRec_Exception() {
        try {
            UpdateCustomerController.getAccountRec(null);
        } catch (Exception e) {}
    }

    @isTest static void testGetAccountRecordDetails_Exception() {
        try {
            UpdateCustomerController.getAccountRecordDetails(null);
        } catch (Exception e) {}
    }

    @isTest static void testUpdateCustomerMeterNumber_Exception() {
        try {
            UpdateCustomerController.updateCustomerMeterNumber(null, null, null, null);
        } catch (Exception e) {}
    }

    @isTest static void testUpdateCustomerContact_Exception() {
        try {
            UpdateCustomerController.updateCustomerContact(null, null, null, null, null, null, null);
        } catch (Exception e) {}
    }
}