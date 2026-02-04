@isTest
public class DeleteAllReceivablesBatchTest {
    
    @testSetup
    static void setupTestData() {
        List<Receivable__c> receivables = new List<Receivable__c>();
        for (Integer i = 0; i < 5; i++) {
            receivables.add(new Receivable__c(Name = 'Test Receivable ' + i));
        }
        insert receivables;
    }

    @isTest
    static void testDeleteAllReceivablesBatch() {
        // Verify records exist before running batch
        Integer beforeCount = [SELECT COUNT() FROM Receivable__c];
        System.assert(beforeCount > 0, 'Setup failed — Receivable__c records not inserted.');

        // Run the batch
        Test.startTest();
        DeleteAllReceivablesBatch batch = new DeleteAllReceivablesBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify all records deleted
        Integer afterCount = [SELECT COUNT() FROM Receivable__c];
        System.assertEquals(0, afterCount, 'All Receivable__c records should have been deleted.');
    }
}