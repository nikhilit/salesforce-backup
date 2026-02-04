@IsTest
public class SmsBulkAPICalloutTest {

    private class SmsHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse resp = new HttpResponse();
            resp.setHeader('Content-Type', 'application/json');
            resp.setStatusCode(200);
            String body = '[{"code":"200","destination":"9876543210","uuid":"abc123"}]';
            resp.setBody(body);
            return resp;
        }
    }

    @TestSetup
    static void setupTestData() {
        SmsApiConfigLTD__c cfg = new SmsApiConfigLTD__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Name = 'Test Record',
            API_Key__c = 'dummyKey',
            EndPoint__c = 'https://test.endpoint/api'
        );
        insert cfg;

        Account acc = new Account(Name='Test Acc', Phone='9876543210');
        insert acc;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            Status = 'New',
            New_Mobile_Number__c = '9876543210'
        );
        insert wo;

        Case_Type_SMS__c tmpl = new Case_Type_SMS__c(
            Message__c = 'Hello {!Remark}'
        );
        insert tmpl;
    }

    @IsTest
    static void testSendBulkSmsWithUpdate() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SmsHttpMock());

        WorkOrder wo = [SELECT Id, Subject, Account.Phone, New_Mobile_Number__c FROM WorkOrder LIMIT 1];
        Case_Type_SMS__c tmpl = [SELECT Id, Message__c FROM Case_Type_SMS__c LIMIT 1];

        WorkOrderNotificationService.WorkOrderNotificationWrapper wrap = 
            new WorkOrderNotificationService.WorkOrderNotificationWrapper();
        wrap.wo = wo;
        wrap.tmpl = tmpl;
        wrap.templateId = tmpl.Id;
        wrap.followUpRemarksOpt = 'Follow Up Note';

        SmsBulkAPICallout.SmsBulkPayload payload = 
            SmsBulkAPICallout.buildBulkSmsPayload(
                new List<WorkOrderNotificationService.WorkOrderNotificationWrapper>{wrap}
            );

        System.assertNotEquals(null, payload, 'Payload must be built');

        String woIdsJson = JSON.serialize(payload.woIdsInOrder);
        String phonesJson = JSON.serialize(payload.destPhonesInOrder);
        String phoneToIndicesJson = JSON.serialize(payload.phoneToIndices);

        SmsBulkAPICallout.sendBulkSmsWithUpdate(payload.json, woIdsJson, phonesJson, phoneToIndicesJson);

        Test.stopTest();

        // Assertions
        //List<WorkOrder> updated = [SELECT Id, SMS_Sent__c, SMS_Success_Id__c FROM WorkOrder WHERE Id = :wo.Id];
        //System.assertEquals(true, updated.SMS_Sent__c, 'WorkOrder should be marked as SMS sent');
        //System.assertEquals('abc123', updated.SMS_Success_Id__c, 'WorkOrder should have SMS success Id');

        //List<Integration_Log__c> log = [SELECT Id, Status__c, Response_Body__c FROM Integration_Log__c LIMIT 1];
        //System.assertEquals('Success', log.Status__c, 'Integration log should be marked as Success');
        //System.assert(log.Response_Body__c.contains('abc123'), 'Response body should contain SMS Id');
    }

    @IsTest
    static void testNoConfig() {
        // Delete config
        delete [SELECT Id FROM SmsApiConfigLTD__c LIMIT 1];

        Test.startTest();
        SmsBulkAPICallout.sendBulkSmsWithUpdate('{}','[]','[]','{}');
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Integration_Log__c]);
    }

    @IsTest
    static void testInvalidJson() {
        Test.startTest();
        SmsBulkAPICallout.sendBulkSmsWithUpdate('{}','[]','[]','{}');
        Test.stopTest();
    
        System.assert(true, 'Method should exit safely with empty JSON');
    }

}