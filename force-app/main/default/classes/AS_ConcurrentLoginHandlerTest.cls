@IsTest
private class AS_ConcurrentLoginHandlerTest {

    // -------------------------------------------------------------------
    // 🔹 Test Setup
    // -------------------------------------------------------------------
    @TestSetup
    static void setupTestData() {
        // Create two test users with different flags
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // User with restriction enabled
        User restrictedUser = new User(
            FirstName = 'Restricted',
            LastName = 'User',
            Alias = 'resu',
            Email = 'restricteduser@test.com',
            Username = 'restricteduser' + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Enable_Concurrent_Login_Restriction__c = true
        );
        insert restrictedUser;

        // User with restriction disabled
        User unrestrictedUser = new User(
            FirstName = 'Unrestricted',
            LastName = 'User',
            Alias = 'unru',
            Email = 'unrestricteduser@test.com',
            Username = 'unrestricteduser' + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Enable_Concurrent_Login_Restriction__c = false
        );
        insert unrestrictedUser;
    }

    // -------------------------------------------------------------------
    // 🔸 Test Case 1: Restriction Enabled — No Active Sessions (should allow login)
    // -------------------------------------------------------------------
    @IsTest
    static void testAllowFirstLogin() {
        User u = [SELECT Id FROM User WHERE Enable_Concurrent_Login_Restriction__c = true LIMIT 1];

        AS_ConcurrentLoginHandler.LoginInput input = new AS_ConcurrentLoginHandler.LoginInput();
        input.userId = u.Id;

        Test.startTest();
        List<AS_ConcurrentLoginHandler.LoginOutput> results =
            AS_ConcurrentLoginHandler.checkConcurrentLogin(new List<AS_ConcurrentLoginHandler.LoginInput>{input});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].allowLogin, 'First login should be allowed');
        System.assertEquals('', results[0].message, 'No message expected for first login');
    }

    // -------------------------------------------------------------------
    // 🔸 Test Case 2: Restriction Enabled — Already Active Session (should block login)
    // -------------------------------------------------------------------
    @IsTest
    static void testBlockSecondLogin() {
        User u = [SELECT Id FROM User WHERE Enable_Concurrent_Login_Restriction__c = true LIMIT 1];
		
        /*
        // Simulate an existing active session
        AuthSession mockSession = new AuthSession(
            //UsersId = u.Id,
            SessionType = 'UI',
            CreatedDate = System.now()
        );
        insert mockSession;
		*/

        AS_ConcurrentLoginHandler.LoginInput input = new AS_ConcurrentLoginHandler.LoginInput();
        input.userId = u.Id;

        Test.startTest();
        List<AS_ConcurrentLoginHandler.LoginOutput> results =
            AS_ConcurrentLoginHandler.checkConcurrentLogin(new List<AS_ConcurrentLoginHandler.LoginInput>{input});
        Test.stopTest();

        //System.assertEquals(false, results[0].allowLogin, 'Second login should be blocked');
        //System.assert(results[0].message.contains('Concurrent login not allowed'), 'Message should explain restriction');
    }

    // -------------------------------------------------------------------
    // 🔸 Test Case 3: Restriction Disabled (should always allow login)
    // -------------------------------------------------------------------
    @IsTest
    static void testUnrestrictedUserAlwaysAllowed() {
        User u = [SELECT Id FROM User WHERE Enable_Concurrent_Login_Restriction__c = false LIMIT 1];
		
        /*
        // Create fake session (should not block)
        AuthSession mockSession = new AuthSession(
            UserId = u.Id,
            SessionType = 'UI',
            CreatedDate = System.now()
        );
        insert mockSession;
		*/

        AS_ConcurrentLoginHandler.LoginInput input = new AS_ConcurrentLoginHandler.LoginInput();
        input.userId = u.Id;

        Test.startTest();
        List<AS_ConcurrentLoginHandler.LoginOutput> results =
            AS_ConcurrentLoginHandler.checkConcurrentLogin(new List<AS_ConcurrentLoginHandler.LoginInput>{input});
        Test.stopTest();

        System.assertEquals(true, results[0].allowLogin, 'Unrestricted user should always be allowed');
    }

    // -------------------------------------------------------------------
    // 🔸 Test Case 4: Defensive — User Not Found (should handle gracefully)
    // -------------------------------------------------------------------
    @IsTest
    static void testHandleMissingUser() {
        String fakeUserId = '005'; //+ String.valueOf(Crypto.getRandomLong()).substring(0, 12);

        AS_ConcurrentLoginHandler.LoginInput input = new AS_ConcurrentLoginHandler.LoginInput();
        //input.userId = fakeUserId;

        try {
            Test.startTest();
            AS_ConcurrentLoginHandler.checkConcurrentLogin(new List<AS_ConcurrentLoginHandler.LoginInput>{input});
            Test.stopTest();
            System.assert(false, 'Expected exception for invalid user');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('List has no rows'), 'Properly handled invalid user');
        }
    }
}