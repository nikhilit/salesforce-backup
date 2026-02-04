@isTest
private class AS_ErrorLoggerTest {

    @isTest
    static void testLogWithException() {
        // Create a dummy related record for recordId
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Simulate an exception
        Exception testEx;
        try {
            Integer i = 1 / 0; // Force an exception
        } catch (Exception ex) {
            testEx = ex;
        }

        // Call the log method with exception
        Test.startTest();
        AS_ErrorLogger.log('TestClass', 'testLogWithException', testEx, acc.Id);
        Test.stopTest();
    }

    @isTest
    static void testLogWithErrorMessageOnly() {
        // Create dummy record
        Account acc = new Account(Name = 'Another Test Account');
        insert acc;

        // Call the log method with custom error message
        Test.startTest();
        AS_ErrorLogger.log('TestClass', 'testLogWithErrorMessageOnly', 'Custom error occurred', acc.Id);
        Test.stopTest();}

    @isTest
    static void testLoggingFailureHandling() {
        // This will cause an exception inside logInternal (e.g., inserting invalid Integration_Log__c)
        Test.startTest();
        AS_ErrorLogger.log('BadClass', 'BadMethod', 'Bad Message', null);
        Test.stopTest();
    }
}