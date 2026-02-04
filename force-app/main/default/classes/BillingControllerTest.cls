@isTest
public class BillingControllerTest {
    @isTest
    static void testGetBillingsByAccount() {
        // Step 1: Create test Account
        Account acc = new Account(Name = 'Test Account',BP_Number__c='');
        insert acc;

        // Step 2: Create test Billing records linked to Account
        Billing__c bill1 = new Billing__c(
            Account__c = acc.Id,
            Print_Doc_Number__c = 'PDOC-001',
            Billing_Doc_Number__c = 'BDOC-001',
            Invoice_Number__c = 'INV-001',
            Bill_Date__c = Date.today().addDays(-5),
            Period_From__c = Date.today().addDays(-30),
            Period_To__c = Date.today().addDays(-5),
            Due_Amount__c = 1000,
            Due_Date__c = Date.today().addDays(10)
        );

        Billing__c bill2 = new Billing__c(
            Account__c = acc.Id,
            Print_Doc_Number__c = 'PDOC-002',
            Billing_Doc_Number__c = 'BDOC-002',
            Invoice_Number__c = 'INV-002',
            Bill_Date__c = Date.today().addDays(-2),
            Period_From__c = Date.today().addDays(-20),
            Period_To__c = Date.today().addDays(-2),
            Due_Amount__c = 2000,
            Due_Date__c = Date.today().addDays(15)
        );

        insert new List<Billing__c>{ bill1, bill2 };

        // Step 3: Call the controller method
        Test.startTest();
        List<Billing__c> results = BillingController.getBillingsByAccount(acc.Id);
        Test.stopTest();

    }
}