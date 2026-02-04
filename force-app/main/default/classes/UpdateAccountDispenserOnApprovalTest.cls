@isTest
public class UpdateAccountDispenserOnApprovalTest {
	@testSetup
    static void setupData() {

        // Create an Account (CNG/LNG)
        Account acc = new Account(
            Name = 'CNG Outlet',
            Category__c = 'CNG/LNG'
        );
        insert acc;

        // Create WorkOrder with Approval_Status__c = Approved
        WorkOrder wo = new WorkOrder(
            Subject = 'WO1',
            AccountId = acc.Id,
            Approval_Status__c = 'Approved'
        );
        insert wo;

        // Create Account Dispenser
        Account_Dispensor__c ad = new Account_Dispensor__c(
            Name = 'AD1',
            Closing_Reading__c = 10
        );
        insert ad;

        // Create Dispenser Point (Live = true)
        Dispenser_Point__c dp = new Dispenser_Point__c(
            WorkOrderID__c = wo.Id,
            Live__c = true,
            Account_Dispensor__c = ad.Id,
            Closing_Reading__c = 50,
            Dispenser_Number__c='1'
        );
        insert dp;

        // Another DP for same WO (should not override FIRST)
        Dispenser_Point__c dp2 = new Dispenser_Point__c(
            WorkOrderID__c = wo.Id,
            Live__c = true,
            Account_Dispensor__c = ad.Id,
            Closing_Reading__c = 55,
            Dispenser_Number__c='2'
        );
        insert dp2;
    }

    @isTest
    static void testBatchProcess() {

        // Fetch WO
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        UpdateAccountDispenserOnApproval batchObj = new UpdateAccountDispenserOnApproval();
        Database.executeBatch(batchObj, 50);
        Test.stopTest();

    }

    @isTest
    static void testUpdateMeterReadingsDirectCall() {

        // Get WO Id
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        UpdateAccountDispenserOnApproval.updateMeterReadings(new List<Id>{wo.Id});
        Test.stopTest();

    }
}