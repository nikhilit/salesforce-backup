@IsTest
public class UploadOtherDocumentContrTest {

    @TestSetup
    static void createWorkOrder() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        WorkType wt = new WorkType(Name = 'Test WorkType', EstimatedDuration = 1);
        insert wt;

        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            WorkTypeId = wt.Id,
            Subject = 'Test WorkOrder',
            Approval_Status__c = 'Pending',
            Status = 'New'      
        );
        insert wo;
    }

    @IsTest
    static void testGetApprovalStatus_Success() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        WorkOrder result = UploadOtherDocumentContr.getApprovalStatus(wo.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'WorkOrder should be returned');
        System.assertEquals(wo.Id, result.Id, 'Returned WorkOrder should match input');
    }

    @IsTest
    static void testGetApprovalStatus_Exception() {
        Test.startTest();
        WorkOrder result = UploadOtherDocumentContr.getApprovalStatus('001000000000000AAA'); 
        Test.stopTest();

        System.assertNotEquals(null, result, 'Method should handle invalid Id gracefully');
    }

    @IsTest
    static void testGetApprovalComment_NoRejected() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(wo.Id);
        Approval.ProcessResult result = Approval.process(req);
    
        Test.startTest();
        String comment = UploadOtherDocumentContr.getApprovalComment(wo.Id);
        Test.stopTest();
    
        // In this case, StepStatus is not "Rejected" => should return ''
        System.assertEquals('', comment, 'Expected empty string when latest step is not rejected');
    }

    @IsTest
    static void testGetUploadedFiles() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            WorkTypeId = wt.Id,
            Subject = 'Test WorkOrder2',
            Approval_Status__c = 'Pending',
            Status = 'New'      
        );
        insert wo;

        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test Content')
        );
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = wo.Id,
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        List<ContentDocumentLink> results = UploadOtherDocumentContr.getUploadedFiles(wo.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'One uploaded file should be returned');
    }
    
    private static String getValidDocumentType() {
        Schema.DescribeFieldResult fieldResult = ContentVersion.O_M_Document_Types__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        return !ple.isEmpty() ? ple[0].getValue() : null;
    }
    
    private static String getSecondValidDocumentType() {
        Schema.DescribeFieldResult fieldResult = ContentVersion.O_M_Document_Types__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        return ple.size() > 1 ? ple[1].getValue() : ple[0].getValue();
    }

    @IsTest
    static void testUploadFiles() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        String validDocType = getValidDocumentType();
        String secondValidDocType = getSecondValidDocumentType();
        
        List<String> fileNames = new List<String>{'TestFile1.pdf', 'TestFile2.pdf'};
        List<String> fileTypes = new List<String>{validDocType, secondValidDocType};
        List<String> base64Data = new List<String>{
            EncodingUtil.base64Encode(Blob.valueOf('Test Content 1')),
            EncodingUtil.base64Encode(Blob.valueOf('Test Content 2'))
        };

        // Create a dummy user with Field Agent profile to hit submitForApproval
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Field Agent(O&M)- IPD' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + System.currentTimeMillis() + '@test.com',
            ProfileId = p.Id
        );
        insert u;

        Test.startTest();
        System.runAs(u) {
            UploadOtherDocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
        }
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :wo.Id
        ];
        System.assert(!links.isEmpty(), 'At least one ContentDocumentLink should exist after upload');
    }
    @IsTest
    static void testUploadFiles2() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        String validDocType = getValidDocumentType();
        String secondValidDocType = getSecondValidDocumentType();
        
        List<String> fileNames = new List<String>{'TestFile1.pdf', 'TestFile2.pdf'};
        List<String> fileTypes = new List<String>{validDocType, secondValidDocType};
        List<String> base64Data = new List<String>{
            EncodingUtil.base64Encode(Blob.valueOf('Test Content 1')),
            EncodingUtil.base64Encode(Blob.valueOf('Test Content 2'))
        };

        // Create a dummy user with Field Agent profile to hit submitForApproval
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Field Agent Riser' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + System.currentTimeMillis() + '@test.com',
            ProfileId = p.Id
        );
        insert u;

        Test.startTest();
        System.runAs(u) {
            UploadOtherDocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
        }
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :wo.Id
        ];
        System.assert(!links.isEmpty(), 'At least one ContentDocumentLink should exist after upload');
    }
    @IsTest
    static void testUploadFiles3() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        String validDocType = getValidDocumentType();
        String secondValidDocType = getSecondValidDocumentType();
        
        List<String> fileNames = new List<String>{'TestFile1.pdf', 'TestFile2.pdf'};
        List<String> fileTypes = new List<String>{validDocType, secondValidDocType};
        List<String> base64Data = new List<String>{
            EncodingUtil.base64Encode(Blob.valueOf('Test Content 1')),
            EncodingUtil.base64Encode(Blob.valueOf('Test Content 2'))
        };

        // Create a dummy user with Field Agent profile to hit submitForApproval
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Rubber Hose Field Agent' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + System.currentTimeMillis() + '@test.com',
            ProfileId = p.Id
        );
        insert u;

        Test.startTest();
        System.runAs(u) {
            UploadOtherDocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
        }
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :wo.Id
        ];
        System.assert(!links.isEmpty(), 'At least one ContentDocumentLink should exist after upload');
    }
    @IsTest
    static void testUploadFiles4() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        String validDocType = getValidDocumentType();
        String secondValidDocType = getSecondValidDocumentType();
        
        List<String> fileNames = new List<String>{'TestFile1.pdf', 'TestFile2.pdf'};
        List<String> fileTypes = new List<String>{validDocType, secondValidDocType};
        List<String> base64Data = new List<String>{
            EncodingUtil.base64Encode(Blob.valueOf('Test Content 1')),
            EncodingUtil.base64Encode(Blob.valueOf('Test Content 2'))
        };

        // Create a dummy user with Field Agent profile to hit submitForApproval
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Meter Replacement Field Agent' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + System.currentTimeMillis() + '@test.com',
            ProfileId = p.Id
        );
        insert u;

        Test.startTest();
        System.runAs(u) {
            UploadOtherDocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
        }
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :wo.Id
        ];
        System.assert(!links.isEmpty(), 'At least one ContentDocumentLink should exist after upload');
    }
}