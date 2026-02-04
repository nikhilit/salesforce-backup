@isTest
private class PopulateApplicationNumberBatchTest {

    @isTest
    static void test_populateApplicationNumberBatch_success() {
        // Step 1: Create Account with Application_Number__c = null (should be updated)
        Account accToUpdate = new Account(
            Name = 'Account To Update',
            Application_Number__c = null
        );
        insert accToUpdate;

        // Step 2: Create Account with Application_Number__c already set (should NOT update)
        Account accNoUpdate = new Account(
            Name = 'Account No Update',
            Application_Number__c = 'EXISTING_APP_NUM'
        );
        insert accNoUpdate;

        // Step 3: Matching Identification_Number__c for accToUpdate
        Identification_Number__c matchingIdNum = new Identification_Number__c(
            BP__c = accToUpdate.Id,
            Type_Desc__c = 'Application Form',
            ID_Number__c = 'APPNUM123'
        );
        insert matchingIdNum;

        // Step 4: Non-matching Identification_Number__c for accNoUpdate (wrong type)
        Identification_Number__c nonMatchingIdNum = new Identification_Number__c(
            BP__c = accNoUpdate.Id,
            Type_Desc__c = 'Other Type',
            ID_Number__c = 'WRONG123'
        );
        insert nonMatchingIdNum;

        Test.startTest();
        Database.executeBatch(new PopulateApplicationNumberBatch(), 200);
        Test.stopTest();

        // Step 5: Query back and validate
        Account updatedAcc = [SELECT Application_Number__c FROM Account WHERE Id = :accToUpdate.Id];
        Account nonUpdatedAcc = [SELECT Application_Number__c FROM Account WHERE Id = :accNoUpdate.Id];

        System.assertEquals('APPNUM123', updatedAcc.Application_Number__c,
            'Account should have been updated with ID_Number__c value');
        System.assertEquals('EXISTING_APP_NUM', nonUpdatedAcc.Application_Number__c,
            'Account should remain unchanged');
    }

    @isTest
    static void test_populateApplicationNumberBatch_noMatches() {
        // Case where nothing matches the query

        // Account with missing BP__c in Identification_Number__c
        Account acc = new Account(Name = 'No Match Account', Application_Number__c = null);
        insert acc;

        Identification_Number__c idNum = new Identification_Number__c(
            BP__c = null, // Will prevent match
            Type_Desc__c = 'Application Form',
            ID_Number__c = 'SHOULD_NOT_MATCH'
        );
        insert idNum;

        Test.startTest();
        Database.executeBatch(new PopulateApplicationNumberBatch(), 200);
        Test.stopTest();

        // Should remain null
        Account result = [SELECT Application_Number__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, result.Application_Number__c, 'No changes should be made.');
    }
}