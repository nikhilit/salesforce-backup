@isTest
public class DeleteDuplicateAccountsBatchTest {

    @testSetup
    static void setupData() {
        List<Billing__c> billingList = new List<Billing__c>();

        // Group 1 (DOC1) → 3 records
        billingList.add(new Billing__c(Name='Bill DOC1 - Oldest', Print_Doc_Number__c='DOC1'));
        billingList.add(new Billing__c(Name='Bill DOC1 - Middle', Print_Doc_Number__c='DOC1'));
        billingList.add(new Billing__c(Name='Bill DOC1 - Latest', Print_Doc_Number__c='DOC1'));

        // Group 2 (DOC2) → 2 records
        billingList.add(new Billing__c(Name='Bill DOC2 - Oldest', Print_Doc_Number__c='DOC2'));
        billingList.add(new Billing__c(Name='Bill DOC2 - Latest', Print_Doc_Number__c='DOC2'));

        // Group 3 (DOC3) → only 1 record (should remain untouched)
        billingList.add(new Billing__c(Name='Bill DOC3 - Single', Print_Doc_Number__c='DOC3'));

        insert billingList;
    }

    @isTest
    static void testDuplicateCleanup() {
        Test.startTest();
        Database.executeBatch(new DeleteDuplicateAccountsBatch(), 200);
        Test.stopTest();
    }
}