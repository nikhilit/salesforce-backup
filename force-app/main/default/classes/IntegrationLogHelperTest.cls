/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 16-06-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-06-2025   Kartik Patkar, Appstrail   Initial Version
**/
@isTest
private class IntegrationLogHelperTest {
    
    @isTest
    static void testCreateIntegrationLog_Success() {
        IntegrationLogHelper.IntegrationLogWrapper wrapper = new IntegrationLogHelper.IntegrationLogWrapper();
        wrapper.statusCode = 200;
        wrapper.status = 'Success';
        wrapper.requestJSON = '{"key": "value"}';
        wrapper.responseJSON = '{"result": "ok"}';
        wrapper.className = 'TestClass';
        wrapper.lineNumber = 42;
        wrapper.requestMethod = 'POST';
        wrapper.endPointURL = 'https://example.com/api';
        wrapper.methodName = 'testMethod';
        wrapper.message = 'Success message';
        wrapper.notificationId = null;
        wrapper.meterReadingOCRID = null;
        
        Test.startTest();
        IntegrationLogHelper.createIntegrationLog(wrapper);
        Test.stopTest();
        
        List<Integration_Log__c> logs = [SELECT Id, Status__c, Class_Name__c, Endpoint_URL__c FROM Integration_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Success', logs[0].Status__c);
        System.assertEquals('TestClass', logs[0].Class_Name__c);
        System.assertEquals('https://example.com/api', logs[0].Endpoint_URL__c);
    }
    
    @isTest
    static void testCreateListIntegrationLog_WithSuccessAndError() {
        List<IntegrationLogHelper.IntegrationLogWrapper> wrappers = new List<IntegrationLogHelper.IntegrationLogWrapper>();
        
        IntegrationLogHelper.IntegrationLogWrapper successLog = new IntegrationLogHelper.IntegrationLogWrapper();
        successLog.status = 'Success';
        successLog.className = 'SuccessClass';
        successLog.requestJSON = '{}';
        successLog.responseJSON = '{}';
        wrappers.add(successLog);
        
        IntegrationLogHelper.IntegrationLogWrapper errorLog = new IntegrationLogHelper.IntegrationLogWrapper();
        errorLog.status = 'Failed';
        errorLog.className = 'ErrorClass';
        errorLog.requestJSON = '{}';
        errorLog.responseJSON = '{}';
        wrappers.add(errorLog);
        
        Test.startTest();
        IntegrationLogHelper.createListIntegrationLog(wrappers);
        Test.stopTest();
        
        List<Integration_Log__c> logs = [SELECT Id, Status__c, Class_Name__c FROM Integration_Log__c];
        System.assertEquals(2, logs.size(), 'Both logs should be inserted if labels enabled');
    }
    
    @isTest
    static void testSafeTruncate() {
        String shortText = 'Short';
        String exactText = 'Exact length text';
        String longText = 'This is a very long string that should be truncated properly because it exceeds the limit.';
        
        // Safe truncate with short input
        System.assertEquals(shortText, IntegrationLogHelper.safeTruncate(shortText, 255));
        
        // Safe truncate with null input
        System.assertEquals(null, IntegrationLogHelper.safeTruncate(null, 255));
        
        // Safe truncate with long input
        String result = IntegrationLogHelper.safeTruncate(longText, 25);
        System.assert(result.endsWith('...'), 'Truncated string should end with "..."');
        System.assertEquals(25, result.length(), 'Truncated string should be exactly max length');
    }
    
    @isTest
    static void testFieldMapping() {
        IntegrationLogHelper.IntegrationLogWrapper wrapper = new IntegrationLogHelper.IntegrationLogWrapper();
        wrapper.statusCode = 500;
        wrapper.status = 'Failed';
        wrapper.requestJSON = 'req';
        wrapper.responseJSON = 'res';
        wrapper.className = 'TestClass';
        wrapper.lineNumber = 10;
        wrapper.requestMethod = 'GET';
        wrapper.endPointURL = 'https://verylongurl.com/some/path';
        wrapper.methodName = 'method';
        wrapper.message = 'error';
        wrapper.notificationId = null;
        wrapper.meterReadingOCRID = null;
        
        Integration_Log__c log = IntegrationLogHelper.fieldMapping(wrapper);
        System.assertEquals('TestClass', log.Class_Name__c);
        System.assertEquals('GET', log.Request_Method__c);
        System.assertEquals('method', log.Method_Name__c);
        System.assertEquals('error', log.Message__c);
        System.assertEquals(null, log.Notification__c);
        System.assertEquals(null, log.Meter_Reading_OCR__c);
    }
}