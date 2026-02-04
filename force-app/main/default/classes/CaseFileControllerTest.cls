@isTest
private class CaseFileControllerTest {

    @TestSetup
    static void setupData() {
        // Create test Case
        Case c = new Case(Subject = 'Test Case', Transfer_Type__c = 'Mortgaged Transfer');
        insert c;

        // Create 2 ContentVersions (which will auto-create ContentDocuments)
        ContentVersion cv1 = new ContentVersion(
            Title = 'Doc 1',
            PathOnClient = 'Doc1.pdf',
            VersionData = Blob.valueOf('File content 1'),
            IsMajorVersion = true
        );
        ContentVersion cv2 = new ContentVersion(
            Title = 'Doc 2',
            PathOnClient = 'Doc2.pdf',
            VersionData = Blob.valueOf('File content 2'),
            IsMajorVersion = true
        );
        insert new List<ContentVersion>{cv1, cv2};

        // Update custom fields
        List<ContentVersion> cvsToUpdate = [
            SELECT Id, Title, Status__c, Type_Of_Document__c, Remarks__c, Reason_for_Rejection__c, Selected_Document_Names__c
            FROM ContentVersion
        ];
        for (ContentVersion cv : cvsToUpdate) {
            cv.Status__c = cv.Title.endsWith('1') ? 'Not Verified' : 'Verified';
            cv.Type_Of_Document__c = cv.Title.endsWith('1') ? 'ID Proof' : 'Cheque';
            cv.Remarks__c = 'Some remarks for ' + cv.Title;
            cv.Reason_for_Rejection__c = cv.Title.endsWith('1') ? 'Incorrect Document' : null;
            cv.Selected_Document_Names__c = cv.Title + ' selected docs';
        }
        update cvsToUpdate;

        // Link both ContentDocuments to Case
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion]) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = c.Id,
                ShareType = 'V'
            ));
        }
        insert links;
    }

    @isTest
    static void testGetFilesForCase() {
        Id caseId = [SELECT Id FROM Case LIMIT 1].Id;

        Test.startTest();
        List<CaseFileController.FileWrapper> files = CaseFileController.getFilesForCase(caseId);
        Test.stopTest();
    }

    @isTest
    static void testUpdateFileFields_AllUpdates() {
        ContentVersion cv = [SELECT Id FROM ContentVersion WHERE Title = 'Doc 1' LIMIT 1];

        Test.startTest();
        CaseFileController.updateFileFields(
            cv.Id,
            'Verified',
            'Incorrect Document',
            'Cheque',
            'Updated remarks',
            'Doc1.pdf,Doc2.pdf'
        );
        Test.stopTest();
    }

    @isTest
    static void testUpdateFileFields_SingleFieldOnly() {
        ContentVersion cv = [SELECT Id, Status__c FROM ContentVersion WHERE Title = 'Doc 2' LIMIT 1];
        String originalStatus = cv.Status__c;

        Test.startTest();
        CaseFileController.updateFileFields(
            cv.Id,
            'Rejected',
            null, null, null,
            null
        );
        Test.stopTest();
    }

    @isTest
    static void testUpdateFileFields_NoChanges() {
        ContentVersion cv = [SELECT Id, Status__c FROM ContentVersion WHERE Title = 'Doc 1' LIMIT 1];
        String origStatus = cv.Status__c;

        Test.startTest();
        CaseFileController.updateFileFields(
            cv.Id,
            null, null, null, null,
            null
        );
        Test.stopTest();
    }

    @isTest
    static void testPicklistValueMethods() {
        Test.startTest();
        List<String> docTypes = CaseFileController.getTypeOfDocumentOptions();
        List<String> statuses = CaseFileController.getStatusOptions();
        List<String> reasons = CaseFileController.getReasonOptions();
        Test.stopTest();
    }

    @isTest
    static void testGetTransferTypeFromCase() {
        Id cid = [SELECT Id FROM Case LIMIT 1].Id;

        Test.startTest();
        String transferType = CaseFileController.getTransferTypeFromCase(cid);
        Test.stopTest();

    }

    @isTest
    static void testGetTransferTypeFromCase_MissingId() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            CaseFileController.getTransferTypeFromCase(null);
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
    }

    @isTest
    static void testFileWrapperConstructor() {
        CaseFileController.FileWrapper fw = new CaseFileController.FileWrapper(
            'Title1', 'PDF', 'Test User', '2025-01-01', 'cvId123',
            'Remarks here', 'Not Verified', 'Passport', 'ReasonX', 'Selected.doc'
        );
    }
}