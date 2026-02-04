public with sharing class ImageAssignmentInvoker {
    @AuraEnabled
    public static void assignImagesToRecords(List<Id> recordIds, String sObjectType) {
        Map<Id, List<Id>> mapping = new Map<Id, List<Id>>();

        for (Id recordId : recordIds) {
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :recordId
            ];

            List<Id> docIds = new List<Id>();
            for (ContentDocumentLink l : links) {
                docIds.add(l.ContentDocumentId);
            }

            mapping.put(recordId, docIds);
        }

        Database.executeBatch(new BatchAssignImages(sObjectType, mapping), 50);
    }
}