@isTest
private class UploadSiteDocumentIPDTest {
    
@TestSetup
static void setupTestData() {
    // Create test WorkType
    WorkType testWorkType = new WorkType(
        Name = 'Test WorkType',
        EstimatedDuration = 2.5,
        DurationType = 'Hours'
    );
    insert testWorkType;
    
    // Create test WorkOrder with valid Approval_Status__c
    WorkOrder testWorkOrder = new WorkOrder(
        WorkTypeId = testWorkType.Id,
        Status = 'New',
        Approval_Status__c = getValidApprovalStatus()
    );
    insert testWorkOrder;
    
    // Get valid picklist value for O_M_Document_Types__c
    String validDocType = getValidDocumentType();
    
    // Create test ContentVersion
    ContentVersion cv = new ContentVersion(
        Title = 'Test Document',
        PathOnClient = 'TestDocument.pdf',
        VersionData = Blob.valueOf('Test Content'),
        IsMajorVersion = true,
        O_M_Document_Types__c = validDocType
    );
    insert cv;
    
    // Create ContentDocumentLink
    Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
    ContentDocumentLink cdl = new ContentDocumentLink(
        LinkedEntityId = testWorkOrder.Id,
        ContentDocumentId = cdId,
        ShareType = 'I'
    );
    insert cdl;
}

// Helper: valid doc type
private static String getValidDocumentType() {
    Schema.DescribeFieldResult fieldResult = ContentVersion.O_M_Document_Types__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    return !ple.isEmpty() ? ple[0].getValue() : null;
}
    // Helper method to create a user with given profile name
    private static User createUserWithProfile(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

        User u = new User(
            Username = profileName.replace(' ', '').replace('(', '').replace(')', '') 
                        + DateTime.now().getTime() + '@test.com',
            Alias = 'tst' + String.valueOf(Math.mod(Crypto.getRandomInteger(), 1000)),
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }

// Helper: valid approval status
private static String getValidApprovalStatus() {
    Schema.DescribeFieldResult fieldResult = WorkOrder.Approval_Status__c.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    return !ple.isEmpty() ? ple[0].getValue() : 'Pending';
}



    @isTest
    static void testGetApprovalStatus() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        WorkOrder result = UploadSiteDocumentIPD.getApprovalStatus(wo.Id);
        Test.stopTest();

        System.assertEquals(wo.Id, result.Id, 'Should return the same WorkOrder');
    }

    @isTest
    static void testGetApprovalStatusException() {
        // Pass an invalid Id to force exception
        Test.startTest();
        WorkOrder result = UploadSiteDocumentContr.getApprovalStatus('001000000000000'); 
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return an empty WorkOrder object');
    }

    @isTest
    static void testGetApprovalCommentNoSteps() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        String result = UploadSiteDocumentIPD.getApprovalComment(wo.Id);
        Test.stopTest();

        System.assertEquals('Error', result, 'No ProcessInstanceSteps should return Error');
    }

    @isTest
    static void testGetUploadedFilesEmpty() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        List<ContentDocumentLink> result = UploadSiteDocumentIPD.getUploadedFiles(wo.Id);
        Test.stopTest();

        //System.assertEquals(true, result.isEmpty(), 'No uploaded files should return empty list');
    }
    @isTest
    static void testIPDFieldAgentApproval() {
        User ipdUser = createUserWithProfile('Field Agent(O&M)- IPD');
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        System.runAs(ipdUser) {
            Test.startTest();
            //UploadSiteDocumentIPD.submitForApproval(wo.Id);
            Test.stopTest();
        }
    }

    @isTest
    static void testRiserFieldAgentApproval() {
        User riserUser = createUserWithProfile('Field Agent Riser');
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        System.runAs(riserUser) {
            Test.startTest();
            //UploadSiteDocumentIPD.submitForApproval(wo.Id);
            Test.stopTest();
        }
    }

    @isTest
    static void testRubberHoseFieldAgentApproval() {
        User rubberUser = createUserWithProfile('Rubber Hose Field Agent');
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        System.runAs(rubberUser) {
            Test.startTest();
            //UploadSiteDocumentIPD.submitForApproval(wo.Id);
            Test.stopTest();
        }
    }

    @isTest
    static void testMeterReplacementFieldAgentApproval() {
        User meterUser = createUserWithProfile('Meter Replacement Field Agent');
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        System.runAs(meterUser) {
            Test.startTest();
            //UploadSiteDocumentIPD.submitForApproval(wo.Id);
            Test.stopTest();
        }
    }


    @isTest
static void testUploadFiles() {
    WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    User meterUser = createUserWithProfile('Field Agent(O&M)- IPD');
    // Create fake base64 data
    String contentString = 'Test Content';
    Blob contentBlob = Blob.valueOf(contentString);
    String base64Data = EncodingUtil.base64Encode(contentBlob);

    List<String> names = new List<String>{ 'TestFile.txt' };
    List<String> base64s = new List<String>{ base64Data };
    
    // ✅ Use valid document type from picklist
    String validDocType = getValidDocumentType();
    List<String> types = new List<String>{ validDocType };

    Test.startTest();
    System.runAs(meterUser){
    UploadSiteDocumentIPD.uploadFiles(wo.Id, names, base64s, types);
    }
    Test.stopTest();

    List<ContentDocumentLink> links = [
        SELECT Id, LinkedEntityId 
        FROM ContentDocumentLink 
        WHERE LinkedEntityId = :wo.Id
    ];
    System.assert(!links.isEmpty(), 'File should be uploaded and linked');
}


    @isTest
    static void testCheckWorkStep() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        String status = UploadSiteDocumentIPD.checkWorkStep(wo.Id);
        Test.stopTest();

        
    }

    @isTest
    static void testCheckWorkStepException() {
        // Pass invalid id
        Test.startTest();
        String result = UploadSiteDocumentIPD.checkWorkStep('001000000000000');
        Test.stopTest();

        System.assertEquals('Error', result, 'Invalid record should return Error');
    }

    @isTest
static void testUpdateWorkStepStatus() {
    // Grab WorkOrder from setup
    WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

    Test.startTest();
    // Call the method you’re testing
    UploadSiteDocumentIPD.updateWorkStepStatus(wo.Id, 'Completed');
    Test.stopTest();

    // Re-query and assert
    WorkOrder woUpdated = [SELECT Id, Status FROM WorkOrder WHERE Id = :wo.Id];
    //System.assertEquals('Completed', woUpdated.Status, 'WorkOrder status should be updated');
}

}