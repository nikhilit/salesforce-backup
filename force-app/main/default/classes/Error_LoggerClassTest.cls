@isTest
private class Error_LoggerClassTest {
    
    @isTest
    static void testCreateErrorLogger() {
        // Input parameters
        String testClass = 'TestClass';
        String methodName = 'testMethod';
        String testParentId = '500XXXXXXXXXXXX'; // Example Case/Parent Id
        String testExpType = 'NullPointerException';
        String testExpMessage = 'Attempt to de-reference a null object';
        Integer testLineNumber = 42;
        Boolean isCRM = true;

        // Call the method
        Error_Logger__c logger = Error_LoggerClass.createErrorLogger(
            testClass,
            methodName,
            testParentId,
            testExpType,
            testExpMessage,
            testLineNumber,
            isCRM
        );
    }
}