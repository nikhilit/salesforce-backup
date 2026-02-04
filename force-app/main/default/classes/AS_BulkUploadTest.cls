@IsTest
private class AS_BulkUploadTest {
    // ------------------------
    // 🧩 Common Setup
    // ------------------------
    @TestSetup
    static void setupData() {
        // Create mock ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
        PathOnClient = 'test.csv',
        VersionData = Blob.valueOf('Name,Value\nTest,123')
            );
        insert cv;
        
        // Create Custom Metadata mocks via Stub MDT if required
        // These are fetched dynamically so no real records are needed here
        
        // Create base BulkImportStatus
        BulkImportStatus__c bis = new BulkImportStatus__c(
            Name = 'Test Bulk Import',
        BatchJobId__c = '750xx0000001234AAA',
        Status__c = 'Uploaded',
        Total_Rows__c = 100,
        Processed_Rows__c = 0,
        Success_Count__c = 0
            );
        insert bis;
    }
    
    // ------------------------
    // 🧩 Helper Mock for HTTP Callouts
    // ------------------------
    private class GenericHttpMock implements HttpCalloutMock {
        String body; Integer code;
        GenericHttpMock(String b, Integer c) { body = b; code = c; }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type','application/json');
            res.setBody(body);
            res.setStatusCode(code);
            return res;
        }
    }
    
    // ------------------------
    // ✅ Test 1: File Upload & Queueable Enqueue
    // ------------------------
    @IsTest
    static void testUploadFileToServer_success() {
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];
        
        Test.startTest();
        Map<String, String> result = AS_BulkFileUploadHandler.uploadFileToServer(cv.ContentDocumentId, 'Collect360');
        Test.stopTest();
        
        System.assertNotEquals(null, result.get('bulkImportId'), 'BulkImportId should return');
        BulkImportStatus__c bis = [SELECT Id, Status__c FROM BulkImportStatus__c WHERE Id = :result.get('bulkImportId')];
        System.assertEquals('Uploaded', bis.Status__c);
    }
    
    // ------------------------
    // ✅ Test 2: UploadFile - Missing ID (Exception)
    // ------------------------
    // @IsTest
    // static void testUploadFileToServer_nullId() {
        //     try {
            //         Test.startTest();
            //         AS_BulkFileUploadHandler.uploadFileToServer(null);
            //         Test.stopTest();
            //         System.assert(false, 'Expected AuraHandledException');
        //     } catch (AuraHandledException e) {
            //         //System.assert(e.getMessage().contains('ContentDocumentId is null'));
        //     }
    // }
    
    // ------------------------
    // ✅ Test 3: Queueable success path
    // ------------------------
    @IsTest
    static void testBulkUploadProcessQueueable_success() {
        BulkImportStatus__c bis = [SELECT Id FROM BulkImportStatus__c LIMIT 1];
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        
        // Mock Access Token response
        String authBody = '{"access_token":"mocked_token"}';
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(authBody, 200));
        
        // Mock Process Request response
        String processBody = '{"state":"JobComplete"}';
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(processBody, 200));
        
        Test.startTest();
        System.enqueueJob(new AS_BulkUploadProcessQueueable(bis.Id, cv.Id, 'Collect360'));
        Test.stopTest();
        
        BulkImportStatus__c updated = [SELECT Id, Status__c FROM BulkImportStatus__c WHERE Id = :bis.Id];
        System.assertEquals('In Progress', updated.Status__c, 'Should mark as Processing');
    }
    
    // ------------------------
    // ✅ Test 4: Queueable failure path
    // ------------------------
    @IsTest
    static void testBulkUploadProcessQueueable_failed() {
        BulkImportStatus__c bis = [SELECT Id FROM BulkImportStatus__c LIMIT 1];
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];
        
        // Mock response for failure
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock('error', 500));
        
        Test.startTest();
        System.enqueueJob(new AS_BulkUploadProcessQueueable(bis.Id, cv.Id, 'Collect360'));
        Test.stopTest();
        
        BulkImportStatus__c updated = [SELECT Id, Status__c FROM BulkImportStatus__c WHERE Id = :bis.Id];
        System.assertEquals('Failed', updated.Status__c, 'Should mark as Failed');
    }
    
    // ------------------------
    // ✅ Test 5: Auth Helper - Access Token Success
    // ------------------------
    @IsTest
    static void testGetAccessToken_success() {
        Map<String, String> auth = new Map<String, String>{
            'endpoint' => 'callout:dummy',
            'header' => '{"client_id":"test"}'
        };
        
        String body = '{"access_token":"abc123"}';
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(body, 200));
        
        Test.startTest();
        String token = AS_BulkUploadAuthHelper.getAccessToken(auth);
        Test.stopTest();
        
        System.assertEquals('abc123', token);
    }
    
    // ------------------------
    // ✅ Test 6: Auth Helper - Error handling
    // ------------------------
    @IsTest
    static void testGetAccessToken_error() {
        Map<String, String> auth = new Map<String, String>{
            'endpoint' => 'callout:dummy',
            'header' => '{"client_id":"test"}'
        };
        
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock('Error', 500));
        
        Test.startTest();
        String token = AS_BulkUploadAuthHelper.getAccessToken(auth);
        Test.stopTest();
        
        System.assertEquals('', token, 'Should return blank token on failure');
    }
    
    // ------------------------
    // ✅ Test 7: Bulk Job Monitor - JobComplete
    // ------------------------
    @IsTest
    static void testBulkJobMonitor_jobComplete() {
        BulkImportStatus__c bis = [SELECT Id FROM BulkImportStatus__c LIMIT 1];
        
        String body = JSON.serialize(new Map<String,Object>{
            'state' => 'JobComplete',
            'numberRecordsProcessed' => 100,
            'numberRecordsTotal' => 100
        });
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(body, 200));
        
        Test.startTest();
        Map<String,Object> result = AS_BulkJobMonitor.pollJobProgress(bis.Id);
        Test.stopTest();
        
        System.assertEquals('JobComplete', result.get('status'));
        BulkImportStatus__c updated = [SELECT Status__c FROM BulkImportStatus__c WHERE Id = :bis.Id];
        System.assertEquals('JobComplete', updated.Status__c);
    }
    
    // ------------------------
    // ✅ Test 8: Bulk Job Monitor - Failed
    // ------------------------
    @IsTest
    static void testBulkJobMonitor_failed() {
        BulkImportStatus__c bis = [SELECT Id FROM BulkImportStatus__c LIMIT 1];
        
        String body = JSON.serialize(new Map<String,Object>{
            'state' => 'Failed',
            'numberRecordsProcessed' => 50,
            'numberRecordsTotal' => 100
        });
        Test.setMock(HttpCalloutMock.class, new GenericHttpMock(body, 200));
        
        Test.startTest();
        Map<String,Object> result = AS_BulkJobMonitor.pollJobProgress(bis.Id);
        Test.stopTest();
        
        System.assertEquals('Failed', result.get('status'));
    }
    
    // ------------------------
    // ✅ Test 9: Bulk Job Monitor - Error 500
    // // ------------------------
    // @IsTest
    // static void testBulkJobMonitor_error() {
        //     BulkImportStatus__c bis = [SELECT Id FROM BulkImportStatus__c LIMIT 1];
        //     Test.setMock(HttpCalloutMock.class, new GenericHttpMock('Internal Error', 500));
        
        //     Test.startTest();
        //     Map<String,Object> result = AS_BulkJobMonitor.pollJobProgress(bis.Id);
        //     Test.stopTest();
        
        //     // System.assertEquals('ERROR', result.get('status'));
    // }
}