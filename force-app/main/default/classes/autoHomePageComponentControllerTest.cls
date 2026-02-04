@IsTest
private class autoHomePageComponentControllerTest {

    @TestSetup
    static void setupTestData() {
        // No extra data needed since the controller works with the running user
    }

    @IsTest
    static void testGetUserName_Positive() {
        User testUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Test.startTest();
        autoHomePageComponentController.UserWrapper result = autoHomePageComponentController.getUserName();
        Test.stopTest();

        System.assertNotEquals(null, result, 'The returned wrapper should not be null');

        System.assertEquals(testUser.Name, result.userName, 'The username should match the running user');
    }

    @IsTest
    static void testGetUserName_Edge() {
        Test.startTest();
        autoHomePageComponentController.UserWrapper result = autoHomePageComponentController.getUserName();
        Test.stopTest();

        System.assert(result != null, 'Wrapper must not be null');
        System.assertNotEquals('', result.userName, 'Username should not be blank');
    }
}