@isTest
private class ReplaceQuestionMarkInOriginBatchTest {

    @isTest
    static void testBatch_ReplacesQuestionMark() {
        // Create test Cases
        List<Case> cases = new List<Case>{
            new Case(Origin = 'Email--'),
            new Case(Origin = 'Phone-- Support'),
            new Case(Origin = 'Web'), // no ?
            new Case(Origin = '-- Only')
        };
        insert cases;

        // Run the batch
        Test.startTest();
        ReplaceQuestionMarkInOriginBatch batchJob = new ReplaceQuestionMarkInOriginBatch();
        Database.executeBatch(batchJob, 200); // small scope size for test coverage
        Test.stopTest();
    }
}