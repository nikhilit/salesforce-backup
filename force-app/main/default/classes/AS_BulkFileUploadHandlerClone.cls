public without sharing class AS_BulkFileUploadHandlerClone {
    
    @AuraEnabled
    public static Map<String, String> uploadFileToServer(Id contentDocumentId) {
        try {
            if(contentDocumentId == null) {
                throw new AuraHandledException('ContentDocumentId is null.');
            }
            
            List<ContentVersion> cvList = [
                SELECT Id, ContentDocumentId, Title
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentId
                ORDER BY VersionNumber DESC
                LIMIT 1
            ];
            
            if(cvList.isEmpty()) {
                throw new AuraHandledException('ContentVersion not found.');
            }
            
            ContentVersion cv = cvList[0];
            
            BulkImportStatus__c status = new BulkImportStatus__c(
                Name = 'Bulk Upload - ' + System.now().format(),
            Status__c = 'Uploaded'
                );
            insert status;
            
            ContentDocumentLink link = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = status.Id,
            ShareType = 'V'
                );
            insert link;
            
            System.enqueueJob(new AS_BulkUploadProcessQueueableClone(status.Id, cv.Id));
            
            return new Map<String, String>{
                'bulkImportId' => status.Id
            };
            
        } catch(AuraHandledException e) {
            System.debug('uploadFileToServer Exception: ' + e.getMessage());
            System.debug('uploadFileToServer Exception Line: ' + e.getLineNumber());
            throw e;
        }
        catch(Exception e) {
            System.debug('uploadFileToServer Exception: ' + e.getMessage());
            System.debug('uploadFileToServer Exception Line: ' + e.getLineNumber());
            throw new AuraHandledException('File upload failed: ' + e.getMessage());
        }
    }
}