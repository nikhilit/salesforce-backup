public with sharing class DocumentController {
    @AuraEnabled(cacheable=true)
    public static List<Document_Category__mdt> getDocumentCategories(String transferType) {
        return [
            SELECT Id, MasterLabel, DeveloperName, 
                   Category_Number__c, Category_Name__c, 
                   Is_Parent__c
            FROM Document_Category__mdt
            WHERE Transfer_Type__c = :transferType
            ORDER BY Category_Number__c
        ];
    }

@AuraEnabled(cacheable=true)
public static List<Document_Option__mdt> getDocumentOptions(String categoryDeveloperName) {
    return [
        SELECT Id, Option_Letter__c, Option_Name__c, Is_Required__c, Document_Category__r.DeveloperName
        FROM Document_Option__mdt
        WHERE Document_Category__r.DeveloperName = :categoryDeveloperName
        ORDER BY Option_Letter__c
    ];
}

@AuraEnabled
public static void relateDocumentsToCases(Id caseId, Map<Id, Map<String, String>> documentIdToMetadata, String selectedDocumentNames) {
    try {
        // Validate inputs
        if (caseId == null || documentIdToMetadata == null || documentIdToMetadata.isEmpty()) {
            throw new AuraHandledException('Case ID and Document metadata are required.');
        }
        
        // Verify case exists
        List<Case> cases = [SELECT Id FROM Case WHERE Id = :caseId LIMIT 1];
        if (cases.isEmpty()) {
            throw new AuraHandledException('Case not found with ID: ' + caseId);
        }
        
        // Verify documents exist
        Set<Id> docIds = documentIdToMetadata.keySet();
        List<ContentDocument> existingDocs = [SELECT Id FROM ContentDocument WHERE Id IN :docIds];
        if (existingDocs.size() != docIds.size()) {
            throw new AuraHandledException('One or more documents not found');
        }

        // Prepare lists for DML operations
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        List<ContentVersion> versionsToUpdate = new List<ContentVersion>();
        
        // Query existing versions
        Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, Description, Selected_Document_Names__c 
            FROM ContentVersion 
            WHERE ContentDocumentId IN :docIds AND IsLatest = true
        ]) {
            versionMap.put(cv.ContentDocumentId, cv);
        }

        // Process each document
        for (Id docId : documentIdToMetadata.keySet()) {
            Map<String, String> metadata = documentIdToMetadata.get(docId);
            
            // 1. Create ContentDocumentLink
            links.add(new ContentDocumentLink(
                ContentDocumentId = docId,
                LinkedEntityId = caseId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
            
            // 2. Update ContentVersion with metadata
            if (versionMap.containsKey(docId)) {
                ContentVersion cv = versionMap.get(docId);
                if (metadata.containsKey('description')) {
                    cv.Description = metadata.get('description');
                }
                // Set the selected document names
                cv.Selected_Document_Names__c = selectedDocumentNames;
                versionsToUpdate.add(cv);
            }
        }

        // Perform DML operations
        if (!links.isEmpty()) {
            insert links;
        }
        if (!versionsToUpdate.isEmpty()) {
            update versionsToUpdate;
        }
    } catch (Exception e) {
        System.debug('Error in relateDocumentsToCase: ' + e.getMessage() + ' StackTrace: ' + e.getStackTraceString());
        throw new AuraHandledException('An error occurred while linking documents to the case: ' + e.getMessage());
    }
}
}