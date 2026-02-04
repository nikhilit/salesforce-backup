@isTest
public class BulkSmsApiCalloutTest {
    
    // Mock class to simulate external SMS API
    private class BulkSmsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success","message":"SMS sent successfully"}');
            return res;
        }
    }

    @testSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(Name = 'Test Bulk SMS Account');
        insert acc;

        // Create Case
        Case c = new Case(
            AccountId = acc.Id,
            Origin = 'Phone',
            Status = 'New',
            Subject = 'Bulk SMS Case'
        );
        insert c;
    }

    @isTest
    static void testSendBulkSms() {
        // Prepare test data
        Account acc = [SELECT Id,Name FROM Account LIMIT 1];
        Case c = [SELECT Id,CaseNumber FROM Case LIMIT 1];

        // JSON parameters for the future method
        List<String> mobileNumbers = new List<String>{'9999999999'};
        List<String> messages = new List<String>{'Hello {!Name}, your case {!CaseNumber} is created.'};
        List<String> recordIds = new List<String>{c.Id};
        List<Map<String, String>> mergeFieldsList = new List<Map<String, String>>{
            new Map<String, String>{'Name' => acc.Name, 'CaseNumber' => c.CaseNumber}
        };
        List<String> templateIds = new List<String>{'TEMPLATE_123'};

        // Register the HTTP mock
        Test.setMock(HttpCalloutMock.class, new BulkSmsMock());

        Test.startTest();
        BulkSmsApiCallout.sendBulkSmsFuture(
            JSON.serialize(mobileNumbers),
            JSON.serialize(messages),
            JSON.serialize(recordIds),
            JSON.serialize(mergeFieldsList),
            JSON.serialize(templateIds)
        );
        Test.stopTest();

        // Validate Integration Log was inserted
        List<Integration_Log__c> logs = [SELECT Id, Status__c, Response_Body__c, Phone_Number__c, Case__c 
                                         FROM Integration_Log__c];
        System.assert(!logs.isEmpty(), 'Integration Log should be created');
        System.assertEquals('Success', logs[0].Status__c, 'Log should be marked as Success');
        System.assertEquals('9999999999', logs[0].Phone_Number__c, 'Phone number should match');
        System.assertEquals(c.Id, logs[0].Case__c, 'Case should be linked');
    }
      @isTest
    static void testCreateErrorLogCoverage() {
        // Prepare dummy JSON params (but we know config query will fail because no metadata in test context)
        List<String> mobileNumbers = new List<String>{'9999999999'};
        List<String> messages = new List<String>{'Hello Test'};
        List<String> recordIds = new List<String>{'500000000000001'}; // Fake Case Id
        List<Map<String, String>> mergeFieldsList = new List<Map<String, String>>();
        List<String> templateIds = new List<String>{'TEMP1'};

        Test.startTest();
        // No config exists → should throw exception and hit createErrorLog
        BulkSmsApiCallout.sendBulkSmsFuture(
            JSON.serialize(mobileNumbers),
            JSON.serialize(messages),
            JSON.serialize(recordIds),
            JSON.serialize(mergeFieldsList),
            JSON.serialize(templateIds)
        );
        Test.stopTest();

    }
}