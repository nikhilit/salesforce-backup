public with sharing class WorkOrderPhotoUploader {
    @AuraEnabled
    public static void uploadWithStatus(String workOrderId, String fileName, String base64Data, String statusValue) {
        // Decode image base64 (strip prefix if needed)
        if (base64Data.startsWithIgnoreCase('data:image')) {
            base64Data = base64Data.substringAfter(',');
        }

        // Insert the image as ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = '/' + fileName;
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        insert cv;

        // Link the file to the Work Order
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = workOrderId;
        cdl.ShareType = 'V'; // Viewer
        cdl.Visibility = 'AllUsers';
        insert cdl;

        // Optional: update status if provided
        if (!String.isBlank(statusValue)) {
            WorkOrder wo = [SELECT Id, Status FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
            wo.Status = statusValue;
            update wo;
        }
    }
}