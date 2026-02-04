public class ContentVersionStatusHandler {

    public static void handleInsert(List<ContentVersion> newList) {
        if (newList == null || newList.isEmpty()) return;

        List<ContentVersion> versionsToUpdate = new List<ContentVersion>();
        Set<Id> insertedDocIds = new Set<Id>();

        for (ContentVersion cv : newList) {
            if (String.isBlank(cv.Status__c)) {
                cv.Status__c = 'Not Verified';
                versionsToUpdate.add(cv);
            }
            insertedDocIds.add(cv.ContentDocumentId);
        }

        if (!versionsToUpdate.isEmpty()) {
            update versionsToUpdate;
        }

        Map<Id, Set<Id>> caseToDocIds = getCaseDocumentMap(insertedDocIds);
        if (caseToDocIds.isEmpty()) return;

        publishUploadEvents(caseToDocIds);
    }

    private static Map<Id, Set<Id>> getCaseDocumentMap(Set<Id> docIds) {
        Map<Id, Set<Id>> caseToDocIds = new Map<Id, Set<Id>>();
        for (ContentDocumentLink cdl : [
            SELECT LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIds
              AND LinkedEntityId IN (SELECT Id FROM Case)
            WITH SECURITY_ENFORCED
        ]) {
            if (!caseToDocIds.containsKey(cdl.LinkedEntityId)) {
                caseToDocIds.put(cdl.LinkedEntityId, new Set<Id>());
            }
            caseToDocIds.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
        }
        return caseToDocIds;
    }

    private static void publishUploadEvents(Map<Id, Set<Id>> caseToDocIds) {
        List<CaseFileUploadEvent__e> events = new List<CaseFileUploadEvent__e>();
        for (Id caseId : caseToDocIds.keySet()) {
            for (Id docId : caseToDocIds.get(caseId)) {
                events.add(new CaseFileUploadEvent__e(
                    CaseId__c = caseId,
                    DocumentId__c = docId
                ));
            }
        }
        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }
}