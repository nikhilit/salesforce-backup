@IsTest
private class UpdateCaseDRSBatchTest {

    @TestSetup
    static void setupTestData() {
        // Create DRS Master record
        DRS__c drsMaster = new DRS__c(
            Name = '001 Suman Nagar, Chembur'
        );
        insert drsMaster;

        // Create test Account linked to DRS Master
        Account testAccount = new Account(
            Name = 'Test Account',
            DRS_Master__c = drsMaster.Id
        );
        insert testAccount;

        // Create Cases with NULL DRS_Name__c for testing
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            testCases.add(new Case(
                AccountId = testAccount.Id,
                DRS_Name__c = null
            ));
        }
        insert testCases;
    }

    @IsTest
    static void testBatchStartMethod() {
        Database.executeBatch(new UpdateCaseDRSBatch(), 100);
    }
}