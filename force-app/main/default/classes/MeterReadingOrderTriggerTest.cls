@isTest
public class MeterReadingOrderTriggerTest {
    
    // Mock HTTP response for SAP callout
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        MockHttpResponseGenerator(Integer code, String body) {
            this.statusCode = code;
            this.responseBody = body;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
    
    @testSetup
    static void setupData() {
        
        // Insert field mapping metadata substitute
        MRO_Sync_to_SAP_Field_Mapping__c fieldMapping = new MRO_Sync_to_SAP_Field_Mapping__c(
            Field_Api_Name__c = 'Name',
            External_Field_Name__c = 'ExternalName',
            Object_Api_Name__c = 'Meter_Reading_Order__c',
            Active__c = true
        );
        insert fieldMapping;
    }
    
    @isTest
    static void testAfterInsert_Success() {
        Test.startTest();
        // Set mock success response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"result":"ok"}'));
        
        // Create MRO record with Ready for Sync
        Meter_Reading_Order__c mro = new Meter_Reading_Order__c(
            Name = 'MRO Test',
            Sync_Status__c = 'Ready for Sync',
            Meter_Reading_Doc_Number__c = '123'
        );
        insert mro;
        
        // Run async future
        Test.stopTest();
    }
    
    @isTest
    static void testAfterUpdate_Failed() {
        // Set mock failure response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, '{"error":"failure"}'));
        
        // Create first with non-sync status
        Meter_Reading_Order__c mro = new Meter_Reading_Order__c(
            Name = 'MRO Fail Test',
            Meter_Reading_Doc_Number__c = '1234'
        );
        insert mro;
        
        Test.startTest();
        // Update to Ready for Sync
        mro.Sync_Status__c = 'Ready for Sync';
        update mro;
        Test.stopTest();
        
    }
    
    @isTest
    static void testNoFieldMapping() {
        // Delete existing mappings
        delete [SELECT Id FROM MRO_Sync_to_SAP_Field_Mapping__c];
        
        Test.startTest();
        // Create MRO with Ready for Sync
        Meter_Reading_Order__c mro = new Meter_Reading_Order__c(
            Name = 'MRO No Mapping',
            Sync_Status__c = 'Ready for Sync',
            Meter_Reading_Doc_Number__c = '1232323'
        );
        insert mro;
        Test.stopTest();
    }

}