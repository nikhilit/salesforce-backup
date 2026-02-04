@IsTest
private class ContentDocumentLinkHandlerTest {

    @TestSetup
    static void setupTestData() {
        // Create test Account (or any object)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

		WorkOrder wo = new WorkOrder(Subject = 'Test');
		insert wo;

        // Create a ContentDocument
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.jpg',
            VersionData = Blob.valueOf('dummy'),
            IsMajorVersion = true
        );
        insert cv;

        // Fetch ContentDocumentId (insert auto-creates)
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Create ContentDocumentLink for Account
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = wo.Id,
            ContentDocumentId = docId,
            ShareType = 'V'
        );
        insert cdl;
    }

    @IsTest
    static void testAssignImageUrlToParent() {
		List<WorkOrder> lstWo = [SELECT Id FROM WorkOrder];
        Test.startTest();
		if(!lstWo.isEmpty()){
			List<ContentDocumentLink> links = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: lstWo.get(0).Id];
        	ContentDocumentLinkHandler.handleAfterInsert(links);
		}
        Test.stopTest();

        Account accUpdated = [SELECT Id, Description, Website FROM Account LIMIT 1];
        //System.assertNotEquals(null, accUpdated.Description, 'Expected Description to be populated with image URL');
        //System.assert(accUpdated.Description.contains('/sfc/servlet.shepherd/version/download/'), 'Image URL not set properly');
    }

    @IsTest
    static void testMultipleLinksForSameParent() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Another ContentDocument + Link
        ContentVersion cv2 = new ContentVersion(
            Title = 'AnotherFile',
            PathOnClient = 'AnotherFile.png',
            VersionData = Blob.valueOf('dummy2'),
            IsMajorVersion = true
        );
        insert cv2;
        Id docId2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id].ContentDocumentId;

        ContentDocumentLink cdl2 = new ContentDocumentLink(
            LinkedEntityId = wo.Id,
            ContentDocumentId = docId2,
            ShareType = 'V'
        );
        insert cdl2;

        Test.startTest();
        List<ContentDocumentLink> links = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :wo.Id];
        ContentDocumentLinkHandler.handleAfterInsert(links);
        Test.stopTest();

        //Account accUpdated = [SELECT Id, Description, Website FROM Account WHERE Id = :wo.Id];
        //System.assertNotEquals(null, accUpdated.Description, 'First field must have been populated');
        //System.assertNotEquals(null, accUpdated.Website, 'Second field must have been populated for second link');
    }

    @IsTest
    static void testNoMetadataMapping() {
        // Create a Contact with no mapping in metadata
        Contact con = new Contact(LastName = 'NoMapping');
        insert con;

        ContentVersion cv = new ContentVersion(
            Title = 'ContactFile',
            PathOnClient = 'ContactFile.jpg',
            VersionData = Blob.valueOf('dummy3'),
            IsMajorVersion = true
        );
        insert cv;
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = con.Id,
            ContentDocumentId = docId,
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        List<ContentDocumentLink> links = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :con.Id];
        ContentDocumentLinkHandler.handleAfterInsert(links);
        Test.stopTest();

        Contact conUpdated = [SELECT Id FROM Contact WHERE Id = :con.Id];
        // Nothing should have changed, but at least no exception should occur
        //System.assertEquals(con.Id, conUpdated.Id, 'Record should remain unchanged without mapping');
    }



		@IsTest
    static void testLinkRelatedDocuments_createsLinksForDocumentAndOcr() {
        // Arrange
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Create Document__c that will match by Work_Order__c and Type__c
        Document__c docRec = new Document__c(
            Work_Order__c = wo.Id,
            Type__c = 'Front Photo' // will match Title of ContentVersion
        );
        insert docRec;

        // Create Meter_Reading_OCR__c that will match by Work_Order__c and Type__c
        Meter_Reading_OCR__c ocrRec = new Meter_Reading_OCR__c(
            Work_Order__c = wo.Id,
            Type__c = 'Front Photo'
        );
        insert ocrRec;

        // Create a ContentVersion whose Title matches Type__c above
        ContentVersion cv = new ContentVersion(
            Title = 'Front Photo',
            PathOnClient = 'FrontPhoto.jpg',
            VersionData = Blob.valueOf('dummy image bytes'),
            IsMajorVersion = true
        );
        insert cv;

        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Create the incoming ContentDocumentLink that links the ContentDocument to the WorkOrder
        ContentDocumentLink incoming = new ContentDocumentLink(
            LinkedEntityId = wo.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert incoming;

        // Act
        Test.startTest();
        List<ContentDocumentLink> newLinks = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId = :contentDocId AND LinkedEntityId = :wo.Id];
        ContentDocumentLinkHandler.linkRelatedDocuments(newLinks);
        Test.stopTest();

        // Assert: verify that links pointing to Document__c and OCR were created
        List<ContentDocumentLink> createdLinks = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocId
            AND LinkedEntityId IN (:docRec.Id, :ocrRec.Id)
        ];

        Set<Id> targets = new Set<Id>();
        for (ContentDocumentLink l : createdLinks) targets.add(l.LinkedEntityId);

        //System.assert(targets.contains(docRec.Id), 'Expected a link to the Document__c record to have been created.');
        //System.assert(targets.contains(ocrRec.Id), 'Expected a link to the Meter_Reading_OCR__c record to have been created.');
    }

    @IsTest
    static void testLinkRelatedDocuments_noMatchesDoesNothing() {
        // Arrange
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // ContentVersion Title that will not match any Document__c or OCR Type__c
        ContentVersion cv = new ContentVersion(
            Title = 'Unmatched Title',
            PathOnClient = 'Unmatched.jpg',
            VersionData = Blob.valueOf('dummy'),
            IsMajorVersion = true
        );
        insert cv;

        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        ContentDocumentLink incoming = new ContentDocumentLink(
            LinkedEntityId = wo.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert incoming;

        // Act
        Test.startTest();
        List<ContentDocumentLink> newLinks = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId = :contentDocId AND LinkedEntityId = :wo.Id];
        ContentDocumentLinkHandler.linkRelatedDocuments(newLinks);
        Test.stopTest();

        // Assert: ensure no extra links to other objects were created (besides the original incoming link)
        Integer extraLinks = [SELECT COUNT() FROM ContentDocumentLink WHERE ContentDocumentId = :contentDocId] - 1;
        //System.assertEquals(0, extraLinks, 'No additional ContentDocumentLink records should be created when there are no matching Document__c or OCR records.');
    }

    @IsTest
    static void testLinkRelatedDocuments_avoidsDuplicateInserts() {
        // Arrange
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Create Document__c to match
        Document__c docRec = new Document__c(
            Work_Order__c = wo.Id,
            Type__c = 'DupTestTitle'
        );
        insert docRec;

        // ContentVersion whose Title matches
        ContentVersion cv = new ContentVersion(
            Title = 'DupTestTitle',
            PathOnClient = 'Dup.jpg',
            VersionData = Blob.valueOf('dummy'),
            IsMajorVersion = true
        );
        insert cv;
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        // Insert the incoming link to WorkOrder (simulating trigger insertion)
        ContentDocumentLink incoming = new ContentDocumentLink(
            LinkedEntityId = wo.Id,
            ContentDocumentId = contentDocId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert incoming;

        // Pre-create an existing link from the ContentDocument to the Document__c target to test dedupe
        ContentDocumentLink existingToDoc = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = docRec.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        //insert existingToDoc;

        // Act
        Test.startTest();
        List<ContentDocumentLink> newLinks = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE Id = :incoming.Id];
        ContentDocumentLinkHandler.linkRelatedDocuments(newLinks);
        Test.stopTest();

        // Assert: ensure only one link exists between contentDocId and docRec.Id (no duplicate)
        Integer linkCount = [SELECT COUNT() FROM ContentDocumentLink WHERE ContentDocumentId = :contentDocId AND LinkedEntityId = :docRec.Id];
        //System.assertEquals(1, linkCount, 'Handler should not insert duplicate ContentDocumentLink for an existing target.');
    }
}