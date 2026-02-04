@isTest
public class ServiceContractAccountBatchTest {

    @testSetup
    static void setupData() {
        // Create Accounts with BP Numbers
        List<Account> accList = new List<Account>();
        for (Integer i = 1; i <= 3; i++) {
            accList.add(new Account(
                Name = 'Test Account ' + i,
                BP_Number__c = 'BP' + i
            ));
        }
        insert accList;

        // Create ServiceContracts with matching & non-matching BP Numbers
        List<ServiceContract> scList = new List<ServiceContract>();

        // Matching ServiceContracts
        for (Integer i = 1; i <= 3; i++) {
            scList.add(new ServiceContract(
                Contract_Account_Number__c = 'CA' + i,
                Business_Partner_Number__c = 'BP' + i,
                To_Be_Processed__c = true
            ));
        }

        // Non-matching ServiceContract (no Account for this BP)
        scList.add(new ServiceContract(
            Contract_Account_Number__c = 'CA4',
            Business_Partner_Number__c = 'BP999',
            To_Be_Processed__c = true
        ));

        insert scList;
    }

    @isTest
    static void testBatchUpdatesServiceContracts() {
        Test.startTest();
        // Run batch
        ServiceContractAccountBatch scBatch = new ServiceContractAccountBatch();
        Database.executeBatch(scBatch, 200);
        Test.stopTest();
    }
}