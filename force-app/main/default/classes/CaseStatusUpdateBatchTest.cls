@isTest
public class CaseStatusUpdateBatchTest {
    
    @testSetup
    static void setupTestData() {
        List<Case> caseList = new List<Case>();
        

        // Case with Task Released
        caseList.add(new Case(
            Status__c = 'Task Released',
            Origin = 'Phone',
            Subject = 'Test Case 1'
        ));

        // Case with Task Outstanding
        caseList.add(new Case(
            Status__c = 'Task Outstanding',
            Origin = 'Email',
            Subject = 'Test Case 2'
        ));

        // Case with Task Completed
        caseList.add(new Case(
            Status__c = 'Task Completed',
            Origin = 'Web',
            Subject = 'Test Case 3'
        ));

        // Case with other status (should remain unchanged)
        caseList.add(new Case(
            Status__c = 'Other Status',
            Origin = 'Phone',
            Subject = 'Test Case 4'        ));

        insert caseList;
    }
    
    @isTest
    static void testBatchExecution() {
        // Execute batch
        Test.startTest();
        Database.executeBatch(new CaseStatusUpdateBatch(), 200);
        Test.stopTest();
    }
}