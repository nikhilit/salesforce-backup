public class BatchAssignImages implements Database.Batchable<SObject> {

    public String sObjectType;
    public Map<Id, List<Id>> recordToDocIdsMap;

    public BatchAssignImages(String sObjectType, Map<Id, List<Id>> recordToDocIdsMap) {
        this.sObjectType = sObjectType;
        this.recordToDocIdsMap = recordToDocIdsMap;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM ' + sObjectType);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Id> recordIds = new List<Id>();
        for (SObject s : scope) {
            recordIds.add(s.Id);
        }

        Map<Id, List<Id>> filteredMap = new Map<Id, List<Id>>();
        for (Id id : recordIds) {
            if (recordToDocIdsMap.containsKey(id)) {
                filteredMap.put(id, recordToDocIdsMap.get(id));
            }
        }

        if (filteredMap.isEmpty()) return;

        Set<Id> allDocIds = new Set<Id>();
        for (List<Id> docIdList : filteredMap.values()) {
            allDocIds.addAll(docIdList);
        }

        Map<Id, Id> docToVersionId = new Map<Id, Id>();
        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :allDocIds
            ORDER BY VersionNumber DESC
        ]) {
            if (!docToVersionId.containsKey(cv.ContentDocumentId)) {
                docToVersionId.put(cv.ContentDocumentId, cv.Id);
            }
        }

        // Fetch metadata mapping
        Map<String, List<String>> objectFieldMap = new Map<String, List<String>>();
        for (ImageFieldMapping__mdt cfg : [SELECT Object_API_Name__c, Field_API_Names__c FROM ImageFieldMapping__mdt]) {
            objectFieldMap.put(cfg.Object_API_Name__c, cfg.Field_API_Names__c.split(','));
        }

        Map<String, List<SObject>> updatesByType = new Map<String, List<SObject>>();

        for (Id recordId : filteredMap.keySet()) {
            String objectApi = recordId.getSObjectType().getDescribe().getName();
            List<String> fieldList = objectFieldMap.get(objectApi);
            if (fieldList == null) continue;

            List<Id> docIds = filteredMap.get(recordId);
            List<String> versionIds = new List<String>();
            for (Id docId : docIds) {
                if (docToVersionId.containsKey(docId)) {
                    versionIds.add(docToVersionId.get(docId));
                }
            }

            SObject recordUpdate = (SObject)Type.forName('Schema.' + objectApi).newInstance();
            recordUpdate.put('Id', recordId);

            for (Integer i = 0; i < Math.min(fieldList.size(), versionIds.size()); i++) {
                recordUpdate.put(fieldList[i].trim(), versionIds[i]);
            }

            if (!updatesByType.containsKey(objectApi)) {
                updatesByType.put(objectApi, new List<SObject>());
            }
            updatesByType.get(objectApi).add(recordUpdate);
        }

        for (String obj : updatesByType.keySet()) {
            update updatesByType.get(obj);
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: add logging or notification
    }
}