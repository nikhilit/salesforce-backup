public without sharing class AS_BulkFileUploadHandler {
    
    @AuraEnabled
    public static Map<String, String> uploadFileToServer(Id contentDocumentId, String mode) {
        try {
            if(contentDocumentId == null) {
                throw new AuraHandledException('ContentDocumentId is null.');
            }
            
            ContentVersion cv = [
                SELECT Id, ContentDocumentId, Title
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentId
                ORDER BY VersionNumber DESC
                LIMIT 1
            ];
            
            BulkImportStatus__c status = new BulkImportStatus__c(
                Name = 'Bulk Upload - ' + System.now().format(),
            Status__c = 'Uploaded',
            Mode__c = mode
                );
            insert status;
            
            ContentDocumentLink link = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = status.Id,
            ShareType = 'V'
                );
            insert link;
            
            System.enqueueJob(new AS_BulkUploadProcessQueueable(status.Id, cv.Id, mode));
            
            return new Map<String, String>{
                'bulkImportId' => status.Id
            };
            
        } catch(Exception e) {
            System.debug('uploadFileToServer Exception: ' + e.getMessage());
            System.debug('uploadFileToServer Exception Line: ' + e.getLineNumber());
            throw new AuraHandledException('File upload failed: ' + e.getMessage());
        }
    }
}