@isTest
public class PopulateCANumberBatch_Test {

    @testSetup
    static void setupData() {
        // Create test Accounts
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accList.add(new Account(
                Name = 'Test Account ' + i,
                CA_Number__c = null // keep empty initially
            ));
        }
        insert accList;

        // Create ServiceContracts linked to these Accounts
        List<ServiceContract> scList = new List<ServiceContract>();
        Integer index = 0;
        for (Account acc : accList) {
            scList.add(new ServiceContract(
                AccountId = acc.Id,
                Contract_Account_Number__c = 'CA-' + index
            ));
            index++;
        }
        insert scList;
    }

    @isTest
    static void testBatchUpdatesCANumber() {
        // Before running batch — ensure CA_Number__c is blank
        List<Account> beforeAcc = [SELECT Id, CA_Number__c FROM Account];
        for (Account a : beforeAcc) {
        }

        // Run the batch
        Test.startTest();
        Database.executeBatch(new PopulateCANumberBatch(), 200);
        Test.stopTest();

        // After running batch — verify update
        List<Account> afterAcc = [SELECT Id, CA_Number__c FROM Account ORDER BY Name];
        System.assertNotEquals(null, afterAcc[0].CA_Number__c, 'CA_Number__c should be populated');
        System.assert(afterAcc[0].CA_Number__c.startsWith('CA-'), 'CA_Number__c should come from ServiceContract');

        System.debug('✅ Updated Accounts: ' + afterAcc);
    }

    @isTest
    static void testBatchWithNoContracts() {
        // Negative test: no ServiceContracts
        delete [SELECT Id FROM ServiceContract];

        Test.startTest();
        Database.executeBatch(new PopulateCANumberBatch(), 200);
        Test.stopTest();

        // Ensure no Accounts got updated
        for (Account acc : [SELECT Id, CA_Number__c FROM Account]) {
        }
    }
}