@IsTest
private class DocumentTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        // Create WorkOrders
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName='MGL_Metering' AND SobjectType='WorkOrder' LIMIT 1];
        WorkOrder wo1 = new WorkOrder(
            RecordTypeId = rt.Id,
            Status = 'New',
            Subject = 'WO1'
        );
        insert wo1;
        // Create test Document__c records
        List<Document__c> docs = new List<Document__c>();
        for (Integer i = 0; i < 3; i++) {
            docs.add(new Document__c(
                File_Name__c = 'Test Document ' + i,
                Upload_Status__c = (i == 0 ? 'Pending' : 'Uploaded'), // First record triggers upload logic
                BP_Number__c = 'BP' + i,
                Work_Order__c = wo1.Id
            ));
        }
        insert docs;

        // Create ContentDocument and ContentVersion records to link
        List<ContentVersion> versions = new List<ContentVersion>();
        for (Document__c doc : docs) {
            ContentVersion cv = new ContentVersion(
                Title = doc.Name,
                PathOnClient = doc.Name + '.pdf',
                VersionData = Blob.valueOf('Test File Content'),
                IsMajorVersion = true
            );
            versions.add(cv);
        }
        insert versions;

        // Link ContentDocument to Document__c via ContentDocumentLink
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Integer i = 0; i < docs.size(); i++) {
            ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId = docs[i].Id,
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :versions[i].Id].ContentDocumentId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            links.add(cdl);
        }
        insert links;
    }

    @IsTest
    static void testAfterInsertPendingDocument() {
        Test.startTest();
        // Disable real HTTP uploads in future method
        DocumentTriggerHandler.disableUploadsInTests = true;
        
		RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName='MGL_Metering' AND SobjectType='WorkOrder' LIMIT 1];
        WorkOrder wo1 = new WorkOrder(
            RecordTypeId = rt.Id,
            Status = 'New',
            Subject = 'WO2'
        );
        insert wo1;
        Document__c pendingDoc = new Document__c(
            File_Name__c = 'Pending Insert',
            Upload_Status__c = 'Pending',
            BP_Number__c = 'BP999',
            Work_Order__c=wo1.Id
        );
        insert pendingDoc;

        Test.stopTest();

       
    }

    @IsTest
    static void testAfterUpdateChangeToPending() {
        Document__c existingDoc = [SELECT Id, Upload_Status__c FROM Document__c WHERE Upload_Status__c = 'Uploaded' LIMIT 1];
        Test.startTest();
        DocumentTriggerHandler.disableUploadsInTests = true;

        existingDoc.Upload_Status__c = 'Pending';
        update existingDoc;
        Test.stopTest();

    }

    @IsTest
    static void testAfterUpdateNoChange() {
        Document__c existingDoc = [SELECT Id, Upload_Status__c FROM Document__c LIMIT 1];
        Test.startTest();
        DocumentTriggerHandler.disableUploadsInTests = true;

        // Updating without changing Upload_Status__c
        existingDoc.File_Name__c = 'Updated Name Only';
        update existingDoc;
        Test.stopTest();

    }

    @IsTest
    static void testFutureMethodHandlesEmptyRecords() {
        Test.startTest();
        // Call future method directly with empty set
        DocumentTriggerHandler.checkDocumentUpload(new Set<Id>());
        Test.stopTest();
    }

    @IsTest
    static void testFutureMethodWithMockedS3() {
        DocumentTriggerHandler.disableUploadsInTests = false;
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName='MGL_Metering' AND SobjectType='WorkOrder' LIMIT 1];
        WorkOrder wo1 = new WorkOrder(
            RecordTypeId = rt.Id,
            Status = 'New',
            Subject = 'WO3'
        );
        insert wo1;
        // Simulate a document for which S3 responses are mocked
        Document__c doc = new Document__c(
            File_Name__c = 'Doc for Mock S3',
            Upload_Status__c = 'Pending',
            BP_Number__c = 'BP001',
            Work_Order__c=wo1.Id
        );
        insert doc;

        Test.startTest();
        // Execute future method
        DocumentTriggerHandler.checkDocumentUpload(new Set<Id>{doc.Id});
        Test.stopTest();
	}
}