@isTest
public class MeteringMROSyncToSapApiHelperTest {
    
    // Mock HTTP class
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok"}');
            return res;
        }
    }
    
    private class FailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"status":"error"}');
            return res;
        }
    }
    
    private class ExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Force an exception
            throw new CalloutException('Simulated exception');
        }
    }
    
    @testSetup
    static void setupData() {
        // Create MRO record
        Meter_Reading_Order__c mro = new Meter_Reading_Order__c(
            Name = 'Test MRO',
            Meter_Reading_Doc_Number__c = '123' // adjust based on actual fields in your org
        );
        insert mro;
        
        // Create field mappings
        List<MRO_Sync_to_SAP_Field_Mapping__c> mappings = new List<MRO_Sync_to_SAP_Field_Mapping__c>{
            new MRO_Sync_to_SAP_Field_Mapping__c(
                Active__c = true,
                Object_Api_Name__c = 'Meter_Reading_Order__c',
                Field_Api_Name__c = 'Name',
                External_Field_Name__c = 'ExternalName'
            ),
            new MRO_Sync_to_SAP_Field_Mapping__c(
                Active__c = false, // inactive should be skipped
                Object_Api_Name__c = 'Meter_Reading_Order__c',
                Field_Api_Name__c = 'Some_Field__c',
                External_Field_Name__c = 'ExternalValue'
            )
        };
        insert mappings;
    }
    
    @isTest
    static void testSyncToSAP_Success() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        
        Meter_Reading_Order__c mro = [SELECT Id FROM Meter_Reading_Order__c LIMIT 1];
        
        // Fake config record
        MRO_Sync_to_SAP_API_Config__mdt config = new MRO_Sync_to_SAP_API_Config__mdt(
            DeveloperName = 'TestConfig',
            MasterLabel = 'Test Config',
            Endpoint_URL__c = 'https://test.salesforce.com',
            Content_Type__c = 'application/json',
            X_CSRF_Token__c = '123'
        );
        
        Test.startTest();
        String result = MeteringMROSyncToSapApiHelper.syncToSAP('{"key":"value"}', mro.Id, config);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSyncToSAP_Failure() {
        Test.setMock(HttpCalloutMock.class, new FailureMock());
        
        Meter_Reading_Order__c mro = [SELECT Id FROM Meter_Reading_Order__c LIMIT 1];
        MRO_Sync_to_SAP_API_Config__mdt config = new MRO_Sync_to_SAP_API_Config__mdt(
            DeveloperName = 'TestConfig2',
            MasterLabel = 'Test Config 2',
            Endpoint_URL__c = 'https://test.salesforce.com',
            Content_Type__c = 'application/json',
            X_CSRF_Token__c = 'token'
        );
        
        Test.startTest();
        String result = MeteringMROSyncToSapApiHelper.syncToSAP('{"key":"value"}', mro.Id, config);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSyncToSAP_ConfigMissing() {
        Meter_Reading_Order__c mro = [SELECT Id FROM Meter_Reading_Order__c LIMIT 1];
        
        Test.startTest();
        String result = MeteringMROSyncToSapApiHelper.syncToSAP('{"key":"value"}', mro.Id, null);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSyncToSAP_Exception() {
        Test.setMock(HttpCalloutMock.class, new ExceptionMock());
        
        Meter_Reading_Order__c mro = [SELECT Id FROM Meter_Reading_Order__c LIMIT 1];
        MRO_Sync_to_SAP_API_Config__mdt config = new MRO_Sync_to_SAP_API_Config__mdt(
            DeveloperName = 'TestConfig3',
            MasterLabel = 'Test Config 3',
            Endpoint_URL__c = 'https://test.salesforce.com',
            Content_Type__c = 'application/json',
            X_CSRF_Token__c = 'token'
        );
        
        Test.startTest();
        String result = MeteringMROSyncToSapApiHelper.syncToSAP('{"key":"value"}', mro.Id, config);
        Test.stopTest();
        
    }
    
    @isTest
    static void testPayloadBuilder() {
        Meter_Reading_Order__c mro = [SELECT Id, Name FROM Meter_Reading_Order__c LIMIT 1];
        List<MRO_Sync_to_SAP_Field_Mapping__c> mappings = [SELECT Id, Active__c, Object_Api_Name__c, Field_Api_Name__c, External_Field_Name__c 
                                                           FROM MRO_Sync_to_SAP_Field_Mapping__c];
        
        String payload = MeteringMROSyncToSapApiHelper.payloadBuilder(mro, mappings);
        
    }

}