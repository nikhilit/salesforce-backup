/**
* @File Name : AS_ErrorLogger.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 10, 2025 |   | Initial Version
**/
public class AS_ErrorLogger {

    public static void log(String className, String methodName, Exception ex, String recordId) {
        String message = ex != null ? ex.getMessage() : 'No exception provided';

        logInternal(className, methodName, message, ex.getStackTraceString(), recordId);
    }

    public static void log(String className, String methodName, String errorMessage, String recordId) {
        logInternal(className, methodName, errorMessage, '', recordId);
    }

    private static void logInternal(String className, String methodName, String message, String stackTrace, String recordId) {
        try {

            Integration_Log__c err = new Integration_Log__c();
            err.Class_Name__c = className;
            err.Method_Name__c = methodName;
            err.Related_Record_Id__c = recordId;
            err.Message__c = message;
            err.Stack_Trace__c = stackTrace;
            insert err;
        } catch (Exception logEx) {
            System.debug('Failed to log error: ' + logEx.getMessage());
        }
    }
}