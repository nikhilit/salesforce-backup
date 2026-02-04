@IsTest
private class AccountFieldSyncBatchTest {

    @IsTest
    static void test_EmailSync_Success_And_PartialFailure() {

        List<Account> accounts = new List<Account>{
            // ✅ Valid email change → should update
            new Account(
                Name = 'Valid Email Update',
                Email_Id__c = 'new1@test.com',
                Account_Email__c = 'old1@test.com'
            ),

            // ❌ Invalid email → update should fail but batch must continue
            new Account(
                Name = 'Invalid Email Update',
                Email_Id__c = 'invalid_email!',
                Account_Email__c = 'old2@test.com'
            ),

            // ✅ Same email → should NOT be added to update list
            new Account(
                Name = 'No Change Email',
                Email_Id__c = 'same@test.com',
                Account_Email__c = 'same@test.com'
            )
        };

        insert accounts;

        Test.startTest();
        Database.executeBatch(new AccountFieldSyncBatch(), 200);
        Test.stopTest();

        Map<Id, Account> accMap = new Map<Id, Account>([
            SELECT Email_Id__c, Account_Email__c
            FROM Account
            WHERE Id IN :accounts
        ]);

        // ✅ ASSERTIONS

        // 1️⃣ Valid email updated
        System.assertEquals(
            'new1@test.com',
            accMap.get(accounts[0].Id).Account_Email__c,
            'Valid email should be synced'
        );

        // 2️⃣ Invalid email should NOT overwrite old value
        System.assertEquals(
            'old2@test.com',
            accMap.get(accounts[1].Id).Account_Email__c,
            'Invalid email update should fail and retain old value'
        );

        // 3️⃣ No-change record should remain unchanged
        System.assertEquals(
            'same@test.com',
            accMap.get(accounts[2].Id).Account_Email__c,
            'Same email should not be updated'
        );
    }

    @IsTest
    static void test_SchedulableExecution() {

        Account acc = new Account(
            Name = 'Scheduler Test',
            Email_Id__c = 'scheduler@test.com',
            Account_Email__c = 'oldscheduler@test.com'
        );
        insert acc;

        Test.startTest();
        String cron = '0 0 0 1 1 ? 2099';
        System.schedule(
            'AccountFieldSyncBatch Scheduler Test',
            cron,
            new AccountFieldSyncBatch()
        );
        Test.stopTest();

        Account updated = [
            SELECT Account_Email__c
            FROM Account
            WHERE Id = :acc.Id
        ];
    }

    @IsTest
    static void test_NoEligibleRecords() {

        // Email fields same → WHERE clause should exclude this record
        Account acc = new Account(
            Name = 'No Eligible Record',
            Email_Id__c = 'same@test.com',
            Account_Email__c = 'same@test.com'
        );
        insert acc;

        Test.startTest();
        Database.executeBatch(new AccountFieldSyncBatch(), 200);
        Test.stopTest();

        Account reloaded = [
            SELECT Account_Email__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            'same@test.com',
            reloaded.Account_Email__c,
            'No update should occur when emails match'
        );
    }
}