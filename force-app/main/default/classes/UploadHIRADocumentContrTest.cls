@IsTest
public class UploadHIRADocumentContrTest {
    
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
    
    
    @IsTest
    static void testGetApprovalStatus() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        WorkOrder result = UploadHIRADocumentContr.getApprovalStatus(wo.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'WorkOrder should not be null');
        System.assertEquals(wo.Id, result.Id, 'Returned WorkOrder Id should match');
    }
     @isTest
    static void testUploadFilesForAllProfiles1() {
        // Query our test WorkOrder
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
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
        // Prepare dummy file data
        List<String> fileNames = new List<String>{ 'testfile.txt' };
        List<String> base64Data = new List<String>{ EncodingUtil.base64Encode(Blob.valueOf('dummy content')) };
        List<String> fileTypes = new List<String>{ 'HIRA' };

        // Get a valid user (system admin usually works)
        // Run the method inside runAs (simulating different users)
        System.runAs(u) {
            Test.startTest();
            UploadHIRADocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
            Test.stopTest();
        }

       
    }
     @isTest
    static void testUploadFilesForAllProfiles2() {
        // Query our test WorkOrder
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
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
        // Prepare dummy file data
        List<String> fileNames = new List<String>{ 'testfile.txt' };
        List<String> base64Data = new List<String>{ EncodingUtil.base64Encode(Blob.valueOf('dummy content')) };
        List<String> fileTypes = new List<String>{ 'HIRA' };

        // Get a valid user (system admin usually works)
        // Run the method inside runAs (simulating different users)
        System.runAs(u) {
            Test.startTest();
            UploadHIRADocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
            Test.stopTest();
        }

       
    }
    @isTest
    static void testUploadFilesForAllProfiles3() {
        // Query our test WorkOrder
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
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
        // Prepare dummy file data
        List<String> fileNames = new List<String>{ 'testfile.txt' };
        List<String> base64Data = new List<String>{ EncodingUtil.base64Encode(Blob.valueOf('dummy content')) };
        List<String> fileTypes = new List<String>{ 'HIRA' };

        // Get a valid user (system admin usually works)
        // Run the method inside runAs (simulating different users)
        System.runAs(u) {
            Test.startTest();
            UploadHIRADocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
            Test.stopTest();
        }

       
    }
    @isTest
    static void testUploadFilesForAllProfiles() {
        // Query our test WorkOrder
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Prepare dummy file data
        List<String> fileNames = new List<String>{ 'testfile.txt' };
        List<String> base64Data = new List<String>{ EncodingUtil.base64Encode(Blob.valueOf('dummy content')) };
        List<String> fileTypes = new List<String>{ 'HIRA' };

        // Get a valid user (system admin usually works)
        User u = [SELECT Id, Profile.Name FROM User WHERE IsActive = true AND Alias='tsuser' LIMIT 1];

        // Run the method inside runAs (simulating different users)
        System.runAs(u) {
            Test.startTest();
            UploadHIRADocumentContr.uploadFiles(wo.Id, fileNames, base64Data, fileTypes);
            Test.stopTest();
        }

       
    }
    @IsTest
    static void testGetApprovalCommentRejected() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        String comment = UploadHIRADocumentContr.getApprovalComment(wo.Id);
        Test.stopTest();
        
    }
    // Helper method to create a user with given Profile name
    private static User createUserWithProfile(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

        User u = new User(
            Alias = 'tusr',
            Email = profileName.replace(' ', '') + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = profileName.left(40), // avoid long names
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = profileName.replace(' ', '') + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

   
    @IsTest
    static void testGetUploadedFiles() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Create ContentVersion (this automatically creates ContentDocument)
        ContentVersion cVersion = new ContentVersion(
            Title = 'Test Doc',
            PathOnClient = 'Test.pdf',
            VersionData = Blob.valueOf('Test Data')
        );
        insert cVersion;

        Id contentDocId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cVersion.Id
        ].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = wo.Id,
            ShareType = 'V'
        );
        insert cdl;
        
        Test.startTest();
        List<ContentDocumentLink> files = UploadHIRADocumentContr.getUploadedFiles(wo.Id);
        Test.stopTest();
        
        System.assert(!files.isEmpty(), 'Files should be returned');
        System.assertEquals('Test Doc', files[0].ContentDocument.Title, 'Document Title should match');
    }
}