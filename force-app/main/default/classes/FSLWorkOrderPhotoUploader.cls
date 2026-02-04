public with sharing class FSLWorkOrderPhotoUploader {
 
    @AuraEnabled
    public static Id uploadPhoto(Id workOrderId, String fileName, String base64Data) {
        if (workOrderId == null || String.isBlank(fileName) || String.isBlank(base64Data)) {
            throw new AuraHandledException('Missing required parameters.');
        }
 
        // Decode base64
        Blob fileBlob = EncodingUtil.base64Decode(base64Data);
 
        // Create ContentVersion record
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;                      // File title visible to user
        cv.PathOnClient = fileName;         // File path required
        cv.VersionData = fileBlob;                // File data
        insert cv;
 
        // Get ContentDocumentId to link it to Work Order
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
 
        // Link ContentDocument to the Work Order record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId = workOrderId;         // Work Order Id
        cdl.ShareType = 'V';                      // Viewer permission
        cdl.Visibility = 'AllUsers';
        insert cdl;
 
        return cv.Id;
 
       
    }
}