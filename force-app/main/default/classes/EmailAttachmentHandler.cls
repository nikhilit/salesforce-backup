public without sharing class EmailAttachmentHandler {
    
    public static void convertEmailAttachments(List<Attachment> attachments) {
        List<ContentVersion> filesToCreate = new List<ContentVersion>();
        Set<Id> attachmentsToDelete = new Set<Id>();
        
        // Get parent EmailMessage IDs
        Set<Id> emailMessageIds = new Set<Id>();
        for (Attachment att : attachments) {
            emailMessageIds.add(att.ParentId);
        }
        
        // Get related Case IDs
        Map<Id, Id> emailToCaseMap = new Map<Id, Id>();
        for (EmailMessage em : [
            SELECT Id, ParentId 
            FROM EmailMessage 
            WHERE Id IN :emailMessageIds AND ParentId != null
        ]) {
            emailToCaseMap.put(em.Id, em.ParentId);
        }
        
        // Convert attachments to ContentVersion
        for (Attachment att : attachments) {
            if (emailToCaseMap.containsKey(att.ParentId)) {
                ContentVersion cv = new ContentVersion();
                cv.Title = att.Name;
                cv.PathOnClient = att.Name;
                cv.VersionData = att.Body;
                cv.FirstPublishLocationId = emailToCaseMap.get(att.ParentId);
                cv.IsMajorVersion = true;
                filesToCreate.add(cv);
                attachmentsToDelete.add(att.Id);
            }
        }
        
        // Insert files and delete attachments in separate transactions
        if (!filesToCreate.isEmpty()) {
            insert filesToCreate;
            
            // Delete attachments in a future method to avoid mixed DML
            if (!attachmentsToDelete.isEmpty()) {
                deleteAttachmentsAsync(attachmentsToDelete);
            }
        }
    }
    
    @future
    private static void deleteAttachmentsAsync(Set<Id> attachmentIds) {
        List<Attachment> toDelete = [SELECT Id FROM Attachment WHERE Id IN :attachmentIds];
        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
}