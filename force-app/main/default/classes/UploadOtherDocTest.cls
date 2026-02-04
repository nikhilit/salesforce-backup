@isTest
public class UploadOtherDocTest {
    @TestSetup
    static void setupData() {
        // Create a test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create a test WorkType
        WorkType wt = new WorkType(Name = 'Test WorkType',EstimatedDuration=60);
        insert wt;

        // Create a test WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WorkOrder',
            AccountId = acc.Id,
            From_Date__c = Date.today(),
            To_Date__c = Date.today().addDays(5),
            Status = 'New',
            Priority = 'High' // Add any field that might be required by your approval process
        );
        insert wo;
        
         Profile p = [SELECT Id FROM Profile WHERE Name = 'Field Agent(O&M)- IPD' LIMIT 1];
        User u = new User(
            Alias = 'tsuser',
            Email = 'testuser' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        
        insert u;
        // 🚩 Submit the WorkOrder into Approval process
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitted for approval');
        req.setObjectId(wo.Id);
        Approval.ProcessResult result = Approval.process(req);

        // 🚩 Add a rejection step
        Approval.ProcessWorkitemRequest workItemReq = new Approval.ProcessWorkitemRequest();
        workItemReq.setComments('Rejected due to missing info');
        workItemReq.setAction('Reject');
        workItemReq.setWorkitemId(result.getNewWorkitemIds()[0]);
        Approval.ProcessResult rejectResult = Approval.process(workItemReq);
    }
    // Utility: Create a dummy WorkOrder
   
    @isTest
    static void testGetApprovalStatus() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        WorkOrder result = UploadOtherDocumentContr.getApprovalStatus(wo.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetApprovalComment_NoSteps() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Test.startTest();
        String comment = UploadOtherDocumentContr.getApprovalComment(wo.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetUploadedFiles_Empty() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Test.startTest();
        List<ContentDocumentLink> files = UploadOtherDocumentContr.getUploadedFiles(wo.Id);
        Test.stopTest();
    }

    @isTest
    static void testUploadFiles() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<String> fileNames = new List<String>{'testfile.txt'};
        List<String> base64Data = new List<String>{EncodingUtil.base64Encode(Blob.valueOf('dummy content'))};
        List<String> fileTypes = new List<String>{'HIRA'};
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Field Agent(O&M)- IPD' LIMIT 1];
        User u = new User(
            Alias = 'tsuser',
            Email = 'testuser' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert u;
        System.runAs(u) {
        Test.startTest();
        UploadOtherDocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
        Test.stopTest();
         }
        }
    @isTest
    static void testUploadFiles1() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<String> fileNames = new List<String>{'testfile.txt'};
        List<String> base64Data = new List<String>{EncodingUtil.base64Encode(Blob.valueOf('dummy content'))};
        List<String> fileTypes = new List<String>{'HIRA'};
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Field Agent Riser' LIMIT 1];
        User u = new User(
            Alias = 'tsuser',
            Email = 'testuser' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert u;
        System.runAs(u) {
        Test.startTest();
        UploadOtherDocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
        Test.stopTest();
         }
        }
    @isTest
    static void testUploadFiles2() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<String> fileNames = new List<String>{'testfile.txt'};
        List<String> base64Data = new List<String>{EncodingUtil.base64Encode(Blob.valueOf('dummy content'))};
        List<String> fileTypes = new List<String>{'HIRA'};
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Rubber Hose Field Agent' LIMIT 1];
        User u = new User(
            Alias = 'tsuser',
            Email = 'testuser' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert u;
        System.runAs(u) {
        Test.startTest();
        UploadOtherDocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
        Test.stopTest();
         }
        }
    @isTest
    static void testUploadFiles3() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<String> fileNames = new List<String>{'testfile.txt'};
        List<String> base64Data = new List<String>{EncodingUtil.base64Encode(Blob.valueOf('dummy content'))};
        List<String> fileTypes = new List<String>{'HIRA'};
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Meter Replacement Field Agent' LIMIT 1];
        User u = new User(
            Alias = 'tsuser',
            Email = 'testuser' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert u;
        System.runAs(u) {
        Test.startTest();
        UploadOtherDocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
        Test.stopTest();
         }
        }
}