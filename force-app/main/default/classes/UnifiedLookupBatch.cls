public class UnifiedLookupBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    private List<String> objectNamesToProcess;
    private Integer currentIndex;
    private String objectName;
    private List<Batch_Object_Control__mdt> settings;
    private Set<String> fields;
    private Map<String, Schema.SObjectType> globalDescribe;
    private Map<String, Map<String, Id>> lookupIdMaps; // Cache for text to Id mappings per lookup field

    public UnifiedLookupBatch(List<String> objectNamesToProcess, Integer currentIndex, String objectName) {
        this.objectNamesToProcess = objectNamesToProcess;
        this.currentIndex = currentIndex;
        this.objectName = objectName;
        this.globalDescribe = Schema.getGlobalDescribe();
        this.lookupIdMaps = new Map<String, Map<String, Id>>();

        this.settings = [
            SELECT Object_API_Name__c, Process_Enabled__c, Text_Field_Name__c, 
                   Lookup_Field_Name__c, Parent_Object_Field__c
            FROM Batch_Object_Control__mdt
            WHERE Process_Enabled__c = true AND Object_API_Name__c = :objectName
        ];

        if (!globalDescribe.containsKey(objectName) || settings.isEmpty()) {
            this.fields = new Set<String>(); // Empty to skip
            return;
        }

        Map<String, Schema.SObjectField> fieldMap = globalDescribe.get(objectName).getDescribe().fields.getMap();
        this.fields = new Set<String>{ 'Id', 'To_be_processed__c' };

        for (Batch_Object_Control__mdt s : settings) {
            if (fieldMap.containsKey(s.Text_Field_Name__c) && fieldMap.containsKey(s.Lookup_Field_Name__c)) {
                fields.add(s.Text_Field_Name__c);
                fields.add(s.Lookup_Field_Name__c);
            }
        }

        if (fields.size() <= 2) {
            this.fields = new Set<String>(); // Empty to skip
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (fields.isEmpty()) {
            return Database.getQueryLocator('SELECT Id FROM ' + objectName + ' WHERE Id = null'); // Empty query
        }

        String query = 'SELECT ' + String.join(new List<String>(fields), ',') +
               ' FROM ' + objectName +
               ' WHERE To_be_processed__c = true';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> records) {
        if (records.isEmpty()) return;

        // Build mapping from text value to lookup Ids, using cache
        Map<String, Set<String>> textValuesMap = new Map<String, Set<String>>();
        for (Batch_Object_Control__mdt meta : settings) {
            textValuesMap.put(meta.Lookup_Field_Name__c, new Set<String>());
        }

        for (SObject record : records) {
            for (Batch_Object_Control__mdt meta : settings) {
                Object val = record.get(meta.Text_Field_Name__c);
                if (val != null) {
                    textValuesMap.get(meta.Lookup_Field_Name__c).add(String.valueOf(val));
                }
            }
        }

        for (Batch_Object_Control__mdt meta : settings) {
            Set<String> values = textValuesMap.get(meta.Lookup_Field_Name__c);
            if (values == null || values.isEmpty()) continue;

            Map<String, Id> cachedMap = lookupIdMaps.get(meta.Lookup_Field_Name__c);
            if (cachedMap == null) {
                cachedMap = new Map<String, Id>();
                lookupIdMaps.put(meta.Lookup_Field_Name__c, cachedMap);
            }

            Set<String> newValues = new Set<String>();
            for (String val : values) {
                if (!cachedMap.containsKey(val)) {
                    newValues.add(val);
                }
            }

            if (newValues.isEmpty()) continue;

            String matchField = meta.Parent_Object_Field__c;
            String lookupObject = resolveLookupObject(objectName, meta.Lookup_Field_Name__c, globalDescribe);

            if (String.isBlank(lookupObject) || String.isBlank(matchField)) continue;

            try {
                String q = 'SELECT ' + matchField + ', Id FROM ' + lookupObject +
                           ' WHERE ' + matchField + ' IN :newValues';
                for (SObject sob : Database.query(q)) {
                    cachedMap.put(String.valueOf(sob.get(matchField)), (Id)sob.get('Id'));
                }
            } catch (Exception ex) {
                insert Error_LoggerClass.createErrorLogger('UnifiedLookupBatch', lookupObject, null, ex.getTypeName(), ex.getMessage(), ex.getLineNumber(), true);
                continue;
            }
        }

        List<SObject> toUpdate = new List<SObject>();
        for (SObject record : records) {
            Boolean modified = false;
            for (Batch_Object_Control__mdt meta : settings) {
                String txtVal = String.valueOf(record.get(meta.Text_Field_Name__c));
                Map<String, Id> lookupMap = lookupIdMaps.get(meta.Lookup_Field_Name__c);
                if (lookupMap != null && lookupMap.containsKey(txtVal)) {
                    Id current = (Id)record.get(meta.Lookup_Field_Name__c);
                    Id target = lookupMap.get(txtVal);
                    if (current != target) {
                        record.put(meta.Lookup_Field_Name__c, target);
                        modified = true;
                    }
                }
            }
            if (modified) {
                record.put('To_be_processed__c', false);
                toUpdate.add(record);
            }
        }

        if (!toUpdate.isEmpty()) {
            for (List<SObject> chunk : chunkList(toUpdate, 200)) {
                Database.SaveResult[] results = Database.update(chunk, false);
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        insert Error_LoggerClass.createErrorLogger(
                            'UnifiedLookupBatch', objectName, chunk[i].Id,
                            'DML', results[i].getErrors()[0].getMessage(), -1, false
                        );
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Chain next job if more objectNames left
        if (currentIndex + 1 < objectNamesToProcess.size()) {
            System.enqueueJob(new UnifiedLookupQueueable(objectNamesToProcess, currentIndex + 1));
        }
    }

    @TestVisible
    private static String resolveLookupObject(String objectName, String lookupField, Map<String, Schema.SObjectType> globalDescribe) {
        try {
            if (globalDescribe.containsKey(objectName)) {
                Map<String, Schema.SObjectField> fieldMap = globalDescribe.get(objectName).getDescribe().fields.getMap();
                if (fieldMap.containsKey(lookupField)) {
                    Schema.DescribeFieldResult fieldDesc = fieldMap.get(lookupField).getDescribe();
                    List<Schema.SObjectType> refTo = fieldDesc.getReferenceTo();
                    if (!refTo.isEmpty()) return refTo[0].getDescribe().getName();
                }
            }
        } catch (Exception ex) {
            insert Error_LoggerClass.createErrorLogger(
                'UnifiedLookupBatch', objectName, null, ex.getTypeName(), ex.getMessage(), ex.getLineNumber(), true
            );
        }
        return null;
    }

    @TestVisible
    private static List<List<SObject>> chunkList(List<SObject> fullList, Integer size) {
        List<List<SObject>> allChunks = new List<List<SObject>>();
        for (Integer i = 0; i < fullList.size(); i += size) {
            List<SObject> chunk = new List<SObject>();
            for (Integer j = i; j < Math.min(i + size, fullList.size()); j++) {
                chunk.add(fullList[j]);
            }
            allChunks.add(chunk);
        }
        return allChunks;
    }
}