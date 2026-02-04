@isTest
private class SmsApiHelper_Test {

    // Fake HTTP mock class
    private class MockHttpResponse implements HttpCalloutMock {
        Integer statusCode;
        String responseBody;
        public MockHttpResponse(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            return res;
        }
    }

    @testSetup
    static void setupTestData() {
		// Insert default config record
        SmsApiConfig__c config = new SmsApiConfig__c(
            EndPoint__c = 'https://fakeendpoint.com/sendsms',
            username__c = 'testuser',
            password__c = 'testpass',
            sender__c = 'MGL',
            type__c = 'TEXT',
            Name='test SMS',
            Sender_Metering__c='test',
            Send_to_Default__c=true,
            Default_Number__c='7867786778'
        );
        insert config;
        
        // Create Account + WorkOrder
        Account acc = new Account(Name = 'Test Account', BP_Number__c = 'BP123');
        insert acc;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id
        );
        insert wo;
    }

    @isTest
    static void testSendSmsSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"msg":"OK"}'));

        Test.startTest();
        String result = SmsApiHelper.sendSMS('9876543210', 'Hello', 'TEMPLATE1', [SELECT Id FROM WorkOrder LIMIT 1].Id);
        Test.stopTest();
    }

    @isTest
    static void testSendSmsFailure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(500, '{"error":"fail"}'));

        Test.startTest();
        String result = SmsApiHelper.sendSMS('9876543210', 'Failure test', 'TEMPLATE2', [SELECT Id FROM WorkOrder LIMIT 1].Id);
        Test.stopTest();
	}

    @isTest
    static void testSendSmsException() {
        // Force exception by setting mock to null (invalid state)
        Test.setMock(HttpCalloutMock.class, null);

        Test.startTest();
        String result = SmsApiHelper.sendSMS('9876543210', 'Exception test', 'TEMPLATE3', [SELECT Id FROM WorkOrder LIMIT 1].Id);
        Test.stopTest();
	}
}