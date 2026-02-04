@isTest
public class WorkOrderSMSBatchTest {

    @testSetup
    static void setupData() {
        // Create Account with phone
        Account acc = new Account(Name = 'Test Account', Phone = '9876543210');
        insert acc;
        
         // Query first WorkOrder RecordType
        Id woRtId = [SELECT Id FROM RecordType WHERE SObjectType = 'WorkOrder' LIMIT 1].Id;

        // Create WorkOrder linked to account
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'Open',
            AccountId = acc.Id,
            RecordTypeId = woRtId
        );
        insert wo;

        // Insert a dummy template for wrapper
        Case_Type_SMS__c tmpl = new Case_Type_SMS__c(
            Message__c = 'Hello {!Remark}'
        );
        insert tmpl;

        // Insert SmsApiConfigLTD__c org defaults (needed by SmsBulkAPICallout)
        SmsApiConfigLTD__c cfg = new SmsApiConfigLTD__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            API_Key__c = 'dummyKey',
            Name = 'TestRecord',
            EndPoint__c = 'https://test.salesforce.com/services/apexrest/mock'
        );
        insert cfg;

    }

    @isTest
    static void testBatchRunsSuccessfully() {
        // Fetch created WorkOrder + template
        WorkOrder wo = [SELECT Id, Subject, Account.Phone,New_Mobile_Number__c FROM WorkOrder LIMIT 1];
        Case_Type_SMS__c tmpl = [SELECT Id, Message__c FROM Case_Type_SMS__c LIMIT 1];

        // Build wrapper manually
        WorkOrderNotificationService.WorkOrderNotificationWrapper wrapper = 
            new WorkOrderNotificationService.WorkOrderNotificationWrapper();
        wrapper.wo = wo;
        wrapper.tmpl = tmpl;
        wrapper.templateId = tmpl.Id;
        wrapper.followUpRemarksOpt = 'Test Remark';

        List<WorkOrderNotificationService.WorkOrderNotificationWrapper> wrappers =
            new List<WorkOrderNotificationService.WorkOrderNotificationWrapper>{ wrapper };

        Test.startTest();
        Database.executeBatch(new WorkOrderSMSBatch(wrappers), 1);
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Id, Class_Name__c, Status__c FROM Integration_Log__c];
        //System.assert(!logs.isEmpty(), 'Integration log should be inserted');
    }

    @isTest
    static void testBatchWithEmptyWrappers() {
        List<WorkOrderNotificationService.WorkOrderNotificationWrapper> wrappers =
            new List<WorkOrderNotificationService.WorkOrderNotificationWrapper>();

        Test.startTest();
        Database.executeBatch(new WorkOrderSMSBatch(wrappers), 1);
        Test.stopTest();

        // No logs should be inserted for empty input
        List<Integration_Log__c> logs = [SELECT Id FROM Integration_Log__c];
        System.assertEquals(0, logs.size(), 'No logs expected for empty wrapper list');
    }
}