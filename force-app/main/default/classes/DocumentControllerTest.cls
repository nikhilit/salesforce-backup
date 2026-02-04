@IsTest
public class DocumentControllerTest {
    @TestSetup
    static void setupTestData() {
        // Create test case
        Case testCase = new Case(Subject = 'Test Case');
        insert testCase;
        
        // Create test content documents
        ContentVersion cv1 = new ContentVersion(
            Title = 'Test Document 1',
            PathOnClient = 'Test1.pdf',
            VersionData = Blob.valueOf('Test Content 1'),
            IsMajorVersion = true
        );
        ContentVersion cv2 = new ContentVersion(
            Title = 'Test Document 2',
            PathOnClient = 'Test2.pdf',
            VersionData = Blob.valueOf('Test Content 2'),
            IsMajorVersion = true
        );
        insert new List<ContentVersion>{cv1, cv2};
        
        // Get ContentDocumentIds
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id OR Id = :cv2.Id];
        
        // Create custom metadata test data (using the MetadataTestUtil pattern)
        // Note: In actual tests, you might need to use SeeAllData=true or mock the metadata
    }
    
    @IsTest
    static void testGetDocumentCategories() {
        // Since we can't insert metadata in tests, we either:
        // 1. Use SeeAllData=true (not recommended)
        // 2. Mock the response (recommended)
        
        Test.startTest();
        // Test with null transfer type
        List<Document_Category__mdt> nullResult = DocumentController.getDocumentCategories(null);
        System.assertEquals(0, nullResult.size(), 'Expected empty list for null transfer type');
        
        // Test with specific transfer type (mock would be needed here)
        List<Document_Category__mdt> result = DocumentController.getDocumentCategories('TestType');
        System.assertNotEquals(null, result, 'Expected non-null result');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetDocumentOptions() {
        Test.startTest();
        // Test with null category
        List<Document_Option__mdt> nullResult = DocumentController.getDocumentOptions(null);
        System.assertEquals(0, nullResult.size(), 'Expected empty list for null category');
        
        // Test with specific category (mock would be needed here)
        List<Document_Option__mdt> result = DocumentController.getDocumentOptions('TestCategory');
        System.assertNotEquals(null, result, 'Expected non-null result');
        Test.stopTest();
    }
    
    @IsTest
    static void testRelateDocumentsToCasesSuccess() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 2];
        
        Map<Id, Map<String, String>> docIdToMetadata = new Map<Id, Map<String, String>>();
        for (ContentVersion cv : contentVersions) {
            docIdToMetadata.put(cv.ContentDocumentId, new Map<String, String>{
                'description' => 'Test Description for ' + cv.ContentDocumentId
            });
        }
        
        Test.startTest();
        DocumentController.relateDocumentsToCases(testCase.Id, docIdToMetadata, 'Test Document Names');
        Test.stopTest();
        
        // Verify ContentDocumentLinks were created
        List<ContentDocumentLink> links = [SELECT Id, ContentDocumentId, LinkedEntityId 
                                         FROM ContentDocumentLink 
                                         WHERE LinkedEntityId = :testCase.Id];
        System.assertEquals(2, links.size(), 'Expected 2 documents to be linked to the case');
        
        // Verify ContentVersions were updated
        List<ContentVersion> updatedVersions = [SELECT Id, Description, Selected_Document_Names__c 
                                               FROM ContentVersion 
                                               WHERE ContentDocumentId IN :docIdToMetadata.keySet()];
        for (ContentVersion cv : updatedVersions) {
            System.assert(cv.Description.startsWith('Test Description for'), 'Description not updated correctly');
            System.assertEquals('Test Document Names', cv.Selected_Document_Names__c, 'Selected document names not set correctly');
        }
    }
    
    @IsTest
    static void testRelateDocumentsToCasesInvalidCase() {
        // Get document IDs
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
        Map<Id, Map<String, String>> docIdToMetadata = new Map<Id, Map<String, String>>{
            contentVersions[0].ContentDocumentId => new Map<String, String>{'description' => 'Test'}
        };
        
        Test.startTest();
        try {
            DocumentController.relateDocumentsToCases('001000000000000', docIdToMetadata, 'Test');
            System.assert(false, 'Expected exception for invalid case ID');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Case not found'), 'Unexpected error message: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testRelateDocumentsToCasesInvalidDocument() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Map<Id, Map<String, String>> docIdToMetadata = new Map<Id, Map<String, String>>{
            '069000000000000' => new Map<String, String>{'description' => 'Test'}
        };
        
        Test.startTest();
        try {
            DocumentController.relateDocumentsToCases(testCase.Id, docIdToMetadata, 'Test');
            System.assert(false, 'Expected exception for invalid document ID');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('documents not found'), 'Unexpected error message: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testRelateDocumentsToCasesEmptyInput() {
        Test.startTest();
        try {
            DocumentController.relateDocumentsToCases(null, null, null);
            System.assert(false, 'Expected exception for empty input');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('required'), 'Unexpected error message: ' + e.getMessage());
        }
        Test.stopTest();
    }
}