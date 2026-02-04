@isTest
private class MoveInOutSupplementBatchTest {

    @testSetup
    static void setupData() {
        String supplementOld = 'OLD_SUPP';
        String supplementNew = 'NEW_SUPP';
        
        // Create Account (BP)
        Account acc = new Account(
            Name = 'Test BP Account',
            Supplement__c = supplementOld
        );
        insert acc;

        // Create Premise record with different Supplement__c
        Premise__c premise = new Premise__c(
            Name = 'Test Premise',
            Supplement__c = supplementNew
        );
        insert premise;

        // Create Move_In_Out__c record with mismatch flag = TRUE
        Move_In_Out__c mio = new Move_In_Out__c(
            Name = 'Test MIO',
            BP_Number__c = acc.Id,
            Premise_Name__c = premise.Id
            
        );
        insert mio;
    }

    @isTest
    static void testBatchExecution() {
        // Run batch with controlled size (1)
        Test.startTest();
        Database.executeBatch(new MoveInOutSupplementBatch(), 1);
        Test.stopTest();

        // Verify Account was updated correctly
        Account updatedAcc = [SELECT Supplement__c FROM Account LIMIT 1];
        System.assertEquals('NEW_SUPP', updatedAcc.Supplement__c,
            'Supplement__c should be updated to match the Premise Supplement__c');
    }

   

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String cronExp = '0 0 23 * * ?'; // Run daily at 11 PM
        System.schedule('Test MoveInOutSupplementBatch Job', cronExp, new MoveInOutSupplementBatch());
        Test.stopTest();

        CronTrigger ct = [SELECT State FROM CronTrigger WHERE CronJobDetail.Name = 'Test MoveInOutSupplementBatch Job' LIMIT 1];
        System.assertEquals('WAITING', ct.State, 'Scheduled job should be waiting');
    }
}