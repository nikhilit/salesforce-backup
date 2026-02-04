@isTest
private class SmsApiCalloutTest {

    // Mock HTTP callout class
    private class MockSmsCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"sent"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testSendSmsFuture() {
        // Register the mock
        Test.setMock(HttpCalloutMock.class, new MockSmsCallout());

        // Insert config record (only one so getOrgDefaults() returns it)
        SmsApiConfig__c config = new SmsApiConfig__c(
            Name = 'Default',
            EndPoint__c = 'https://api.smsprovider.com/send',
            username__c = 'testUser',
            password__c = 'testPass',
            sender__c = 'MGLCRM',
            type__c = 'text'
        );
        insert config;

        // Insert a dummy Case
        Case c = new Case(Subject = 'Test SMS', Status = 'New');
        insert c;

        // Prepare merge fields
        Map<String, String> mergeFields = new Map<String, String>{
            'Name'        => 'John Doe',
            'flatname'    => '101',
            'buildingname'=> 'Sky Towers',
            'CaseNumber'  => c.CaseNumber
        };

        String messageTemplate = 'Dear {!Name}, your case {!CaseNumber} is registered for {!flatname}, {!buildingname}.';
        String templateId = 'TEMP123';

        Test.startTest();
        // Call exactly matching method signature
        SmsApiCallout.sendSmsFuture(
            '9876543210',      // mobile
            messageTemplate,   // message
            String.valueOf(c.Id), // caseIdStr
            mergeFields,       // mergeFields
            templateId,
            'MGLCRM'
        );
        
        Test.stopTest(); // Forces @future to execute now
    }
        @isTest
    static void testSendSmsFuture1() {
        // Register the mock
        Test.setMock(HttpCalloutMock.class, new MockSmsCallout());

        // Insert config record (only one so getOrgDefaults() returns it)
        SmsApiConfig__c config = new SmsApiConfig__c(
            Name = 'Default',
            EndPoint__c = 'https://api.smsprovider.com/send',
            username__c = 'testUser',
            password__c = 'testPass',
            sender__c = 'MGLCRM',
            type__c = 'text'
        );
        insert config;

        // Insert a dummy Case
        
        WorkOrder wo = new WorkOrder(
                Subject = 'Test WO',
                Status = 'New',
                StartDate = Date.today(),
                EndDate = Date.today()
            );
            insert wo;
        // Prepare merge fields
        Map<String, String> mergeFields = new Map<String, String>{
            'Name'        => 'John Doe',
            'flatname'    => '101',
            'buildingname'=> 'Sky Towers',
            'CaseNumber'  => wo.Id
        };

        String messageTemplate = 'Dear {!Name}, your case {!CaseNumber} is registered for {!flatname}, {!buildingname}.';
        String templateId = 'TEMP123';

        Test.startTest();
        // Call exactly matching method signature
        SmsApiCallout.sendSmsFuture(
            '9876543210',      // mobile
            messageTemplate,   // message
            String.valueOf(wo.Id), // caseIdStr
            mergeFields,       // mergeFields
            templateId,
            'MGLCRM'
        );
        
        Test.stopTest(); // Forces @future to execute now
    }
        @isTest
    static void sendSmsFutureWorkOrder() {
        // Register the mock
        Test.setMock(HttpCalloutMock.class, new MockSmsCallout());

        // Insert config record (only one so getOrgDefaults() returns it)
        SmsApiConfig__c config = new SmsApiConfig__c(
            Name = 'Default',
            EndPoint__c = 'https://api.smsprovider.com/send',
            username__c = 'testUser',
            password__c = 'testPass',
            sender__c = 'MGLCRM',
            type__c = 'text'
        );
        insert config;

        // Insert a dummy Case
        Case c = new Case(Subject = 'Test SMS', Status = 'New');
        insert c;

        // Prepare merge fields
        Map<String, String> mergeFields = new Map<String, String>{
            'Name'        => 'John Doe',
            'flatname'    => '101',
            'buildingname'=> 'Sky Towers',
            'CaseNumber'  => c.CaseNumber
        };

        String messageTemplate = 'Dear {!Name}, your case {!CaseNumber} is registered for {!flatname}, {!buildingname}.';
        String templateId = 'TEMP123';

        Test.startTest();
        // Call exactly matching method signature
        SmsApiCallout.sendSmsFutureWorkOrder(
            '',
            '9876543210',      // mobile
            messageTemplate,   // message
            String.valueOf(c.Id), // caseIdStr
            mergeFields,       // mergeFields
            templateId,
            'MGLCRM'
        );
        
        Test.stopTest(); // Forces @future to execute now
    }
}