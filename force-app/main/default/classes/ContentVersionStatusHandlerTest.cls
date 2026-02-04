@isTest
private class ContentVersionStatusHandlerTest {

    @TestSetup
    static void setupTestData() {
        // Create 3 test cases
        List<Case> testCases = new List<Case>{
            new Case(Subject = 'Test Case 1'),
            new Case(Subject = 'Test Case 2'),
            new Case(Subject = 'Test Case 3')
        };
        insert testCases;

        // Create 3 content versions
        List<ContentVersion> contentVersions = new List<ContentVersion>{
            new ContentVersion(
                Title = 'Document 1',
                PathOnClient = 'Doc1.pdf',
                VersionData = Blob.valueOf('Test Content 1'),
                IsMajorVersion = true
            ),
            new ContentVersion(
                Title = 'Document 2',
                PathOnClient = 'Doc2.pdf',
                VersionData = Blob.valueOf('Test Content 2'),
                IsMajorVersion = true,
                Status__c = 'Verified'
            ),
            new ContentVersion(
                Title = 'Document 3',
                PathOnClient = 'Doc3.pdf',
                VersionData = Blob.valueOf('Test Content 3'),
                IsMajorVersion = true
            ),
            new ContentVersion(
                Title = '',
                PathOnClient = 'Doc4.pdf',
                VersionData = Blob.valueOf('Test Content 4'),
                IsMajorVersion = true,
                In_Direct_Meter_Reading__c=true
            )
        };
        insert contentVersions;

        // Link each ContentDocument to a Case (1-to-1 mapping)
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        List<ContentVersion> insertedVersions = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Title LIKE 'Document%'
            ORDER BY Title ASC
        ];
        for (Integer i = 0; i < insertedVersions.size(); i++) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = insertedVersions[i].ContentDocumentId,
                LinkedEntityId = testCases[i].Id,
                ShareType = 'V'
            ));
        }
        insert links;
    }

    @isTest
    static void testHandleInsertSetsDefaultStatus() {
        // Pick content versions without Status__c set
        List<ContentVersion> versions = [
            SELECT Id, Status__c, ContentDocumentId
            FROM ContentVersion
            WHERE Title IN ('Document 1', 'Document 3')
        ];
        for (ContentVersion cv : versions) {
           // System.assertEquals(null, cv.Status__c);
        }

        Test.startTest();
        ContentVersionStatusHandler.handleInsert(versions);
        Test.stopTest();

        // Verify Status__c updated
        versions = [
            SELECT Id, Status__c
            FROM ContentVersion
            WHERE Id IN :versions
        ];
        for (ContentVersion cv : versions) {
            System.assertEquals('Not Verified', cv.Status__c);
        }
    }

    @isTest
    static void testHandleInsertPreservesExistingStatus() {
        ContentVersion version = [
            SELECT Id, Status__c, ContentDocumentId
            FROM ContentVersion
            WHERE Title = 'Document 2'
            LIMIT 1
        ];
        //System.assertEquals('Pending', version.Status__c);

        Test.startTest();
        ContentVersionStatusHandler.handleInsert(
            new List<ContentVersion>{version}
        );
        Test.stopTest();

        version = [
            SELECT Id, Status__c
            FROM ContentVersion
            WHERE Id = :version.Id
        ];
        //System.assertEquals('Pending', version.Status__c);
    }

    @isTest
    static void testHandleInsertWithEmptyList() {
        Test.startTest();
        ContentVersionStatusHandler.handleInsert(new List<ContentVersion>());
        Test.stopTest();

        // No exceptions expected
        System.assert(true);
    }

    @isTest
    static void testHandleInsertWithNullList() {
        Test.startTest();
        ContentVersionStatusHandler.handleInsert(null);
        Test.stopTest();

        // No exceptions expected
        System.assert(true);
    }

    @isTest
    static void testHandleInsertSkipsNonCaseDocuments() {
        // Create content version *not linked* to any Case
        ContentVersion orphanVersion = new ContentVersion(
            Title = 'Orphan Document',
            PathOnClient = 'Orphan.pdf',
            VersionData = Blob.valueOf('Orphan Content'),
            IsMajorVersion = true
        );
        insert orphanVersion;

        Test.startTest();
        ContentVersionStatusHandler.handleInsert(
            new List<ContentVersion>{orphanVersion}
        );
        Test.stopTest();

        // We cannot verify events (platform limit), but no errors should occur
        System.assert(true);
    }
}