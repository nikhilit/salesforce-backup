public without sharing class UpdateRemarksController {

    //{"AccountId" : "Account|BP_Number__c", "Portion__c" : "Portion__c|Name", "RecordTypeId" : "RecordType|DeveloperName", "WorkTypeId" : "WorkType|Name"} 
    //{"Agent__c" : "ServiceResource|Name", "R_T_Agency__c" : "ServiceTerritory|Name"}
    public static Map<String, Object> supportedObjects   = new Map<String, Object>();

    //{"BP Number" : "AccountId", "Portion Name" : "Portion__c", "RecordType Name" : "RecordTypeId", "WorkType Name" : "WorkTypeId"}
    //{"Agent" : "Agent__c", "Agency" : "R_T_Agency__c"}
    public static Map<String, Object> supportedFields    = new Map<String, Object>();

    //{"MGL R&T":"MGL_R_T", "MGL Metering":"MGL_Metering"}
    //{"Disconnection Notice":"Disconnection Notice (R&T)", "Payment Collection":"Payment Collection(R&T)"}
    public static Map<String, Map<String, Object>> evmByColumn = new Map<String, Map<String, Object>>();

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getObjectList() {
        
        List<Map<String, String>> objectList = new List<Map<String, String>>();
        List<String> objectNames = new List<String>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        for (MGL_Setting__mdt record : [SELECT Supported_Objects__c 
                                        FROM MGL_Setting__mdt 
                                        WHERE DeveloperName = 'UploadUtilityObjects']) {

            if (!String.isBlank(record.Supported_Objects__c)) {
                objectNames.addAll(record.Supported_Objects__c.split(','));
            }
        }

        for (String apiName : objectNames) {
            if (globalDescribe.containsKey(apiName)) {
                Schema.SObjectType objType = globalDescribe.get(apiName);
                String label = objType.getDescribe().getLabel();
                objectList.add(new Map<String, String>{
                    'label' => label,
                    'value' => apiName
                });
            }
        }

        return objectList;
    }

    @AuraEnabled
    public static Map<String, Object> uploadCSVBatch(String objectName, List<Map<String, String>> csvRecords, String externalIdField) {

        if (csvRecords.isEmpty()) {
            AS_ErrorLogger.log('AS_CSVUploaderController', 'uploadCSVBatch', 'No records found in the uploaded file.', null);
            return new Map<String, Object>{
                'successCount' => 0,
                'errors' => new List<Map<String, String>>{
                    new Map<String, String>{ 'Error' => 'No records found in the uploaded file.' }
                },
                'successes' => new List<Map<String, String>>()
            };
        }

        List<Map<String, String>> records = new List<Map<String, String>>();

        try {

            if (objectName == 'WorkOrder') {

                for (MGL_Setting__mdt setting : [SELECT Label, Supported_Objects__c, Supported_Fields__c, 
                                                        Expected_Value_Mappings__c, Column_Name__c
                                                   FROM MGL_Setting__mdt]) {

                    if (setting.Supported_Objects__c != null && setting.Label == 'CSV Upload Supported Objects (Target)') {
                        supportedObjects = (Map<String, Object>) JSON.deserializeUntyped(setting.Supported_Objects__c);
                    }
                    if (setting.Supported_Fields__c != null && setting.Label == 'CSV Upload Supported Fields (Source)') {
                        supportedFields = (Map<String, Object>) JSON.deserializeUntyped(setting.Supported_Fields__c);
                    }
                    if (setting.Expected_Value_Mappings__c != null && setting.Supported_Objects__c == objectName) {
                        evmByColumn.put(
                            setting.Column_Name__c,
                            (Map<String, Object>) JSON.deserializeUntyped(setting.Expected_Value_Mappings__c)
                        );
                    }
                }

                for (Map<String, String> row : csvRecords) {
                    Map<String, String> transformedRow = new Map<String, String>();
                    for (String csvCol : row.keySet()) {
                        String apiField = (String) supportedFields.get(csvCol);
                        if (String.isNotBlank(apiField)) {
                            transformedRow.put(apiField, row.get(csvCol));
                        } else {
                            // if column is not mapped, keep as-is
                            transformedRow.put(csvCol, row.get(csvCol));
                        }
                    }
                    records.add(transformedRow);
                }

                for (Map<String, String> row : records) {
                    for (String apiField : row.keySet()) {
                        if (evmByColumn.containsKey(apiField)) {
                            String originalVal = row.get(apiField);
                            if (String.isNotBlank(originalVal)) {
                                for (String evmKey : evmByColumn.get(apiField).keySet()) {
                                    if (originalVal.toLowerCase() == evmKey.toLowerCase()) {
                                        row.put(apiField, (String) evmByColumn.get(apiField).get(evmKey));
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }

                System.debug('============records=1111========>>>>'+records);


                // Build lookup queries dynamically using supportedObjects
                Map<String, Map<String, Id>> lookupMaps = new Map<String, Map<String, Id>>();

                for (String fieldApi : supportedObjects.keySet()) {
                    String mapping = (String) supportedObjects.get(fieldApi); 
                    if (String.isBlank(mapping) || !mapping.contains('|')) continue;

                    String[] parts = mapping.split('\\|'); // ObjectName|FieldName
                    String objectNameToQuery = parts[0];
                    String lookupField = parts[1];

                    // Collect unique values for this field
                    Set<String> uniqueValues = new Set<String>();
                    for (Map<String, String> row : records) {
                        if (row.containsKey(fieldApi) && String.isNotBlank(row.get(fieldApi))) {
                            uniqueValues.add(row.get(fieldApi));
                        }
                    }

                    if (!uniqueValues.isEmpty()) {
                        String soql = 'SELECT Id, ' + lookupField + ' FROM ' + objectNameToQuery +
                                    ' WHERE ' + lookupField + ' IN :uniqueValues';
                        List<SObject> relatedRecords = Database.query(soql);

                        Map<String, Id> idMap = new Map<String, Id>();
                        for (SObject sobj : relatedRecords) {
                            idMap.put((String) sobj.get(lookupField), (Id) sobj.get('Id'));
                        }
                        lookupMaps.put(fieldApi, idMap);
                    }
                }

                // ---- Pre-compute default RecordType (single SOQL, only if any row needs it) ----
                Id defaultWorkOrderRtId;
                if (supportedObjects.containsKey('RecordTypeId')) {
                    Boolean anyMissingRt = false;
                    for (Map<String, String> r : records) {
                        if (!r.containsKey('RecordTypeId') || String.isBlank(r.get('RecordTypeId'))) {
                            anyMissingRt = true; break;
                        }
                    }
                    if (anyMissingRt) {
                        List<RecordType> rts = [
                            SELECT Id
                            FROM RecordType
                            WHERE DeveloperName = 'MGL_R_T'
                            AND SObjectType = 'WorkOrder'
                            LIMIT 1
                        ];
                        if (!rts.isEmpty()) defaultWorkOrderRtId = rts[0].Id;
                    }
                }

                for (Map<String, String> row : records) {
                    // Convert external references using the pre-built lookupMaps
                    for (String targetField : lookupMaps.keySet()) {
                        Map<String, Id> idMap = lookupMaps.get(targetField);
                        if (row.containsKey(targetField)) {
                            String extVal = row.get(targetField);
                            if (!String.isBlank(extVal)) {
                                // trim to avoid misses due to stray spaces
                                Id mapped = idMap.get(extVal.trim());
                                if (mapped != null) {
                                    row.put(targetField, mapped);
                                }
                            }
                        }
                    }

                    if (supportedObjects.containsKey('RecordTypeId')) {
                        if ((!row.containsKey('RecordTypeId') || String.isBlank(row.get('RecordTypeId')))
                            && defaultWorkOrderRtId != null) {
                            row.put('RecordTypeId', defaultWorkOrderRtId);
                        }
                    }
                }


                System.debug('============records=2222========>>>>'+records);
            } else {
                records = csvRecords;
            }

            System.debug('============records=2222========>>>>'+records);

        } catch (Exception ex) {
            AS_ErrorLogger.log('AS_CSVUploaderController', 'uploadCSVBatch', ex, null);
        }

        return uploadCSVBatch(records, objectName, externalIdField);
    }

    public static Map<String, Object> uploadCSVBatch( List<Map<String, String>> records, String objectApiName, String externalIdField ) {

        if (String.isBlank(objectApiName)) {
            AS_ErrorLogger.log('AS_CSVUploaderController', 'uploadCSVBatch', 'Object type is required.', null);
            return new Map<String, Object>{
                'successCount' => 0,
                'errors' => new List<Map<String, String>>{
                    new Map<String, String>{ 'Error' => 'Object type is required.' }
                },
                'successes' => new List<Map<String, String>>()
            };
        }


        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectApiName);
        if (sObjType == null) {
            AS_ErrorLogger.log('AS_CSVUploaderController', 'getObjectList', 'Invalid object name', null); 
            return new Map<String, Object>{
                'successCount' => 0,
                'errors' => new List<Map<String, String>>{
                    new Map<String, String>{ 'Error' => 'Invalid object name.' }
                },
                'successes' => new List<Map<String, String>>()
            };
        }

        // Set default external ID field for Account
        if(objectApiName == 'Account' && String.isBlank(externalIdField)){
            externalIdField = 'BP_Number__c';
        }

        Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();
        List<SObject> sObjectsToUpsert = new List<SObject>();
        List<Map<String, String>> errors = new List<Map<String, String>>();
        List<Map<String, String>> exceptions = new List<Map<String, String>>();
        List<Map<String, String>> successes = new List<Map<String, String>>();

        // Keep track of original row data for mapping
        Map<Integer, Map<String, String>> indexToRowMap = new Map<Integer, Map<String, String>>();

        Integer rowIndex = 0;

        for (Map<String, String> row : records) {
            try {
                SObject obj = sObjType.newSObject();

                for (String field : row.keySet()) {
                    if (fieldMap.containsKey(field)) {
                        String value = row.get(field);
                        if (String.isBlank(value)) continue;

                        Schema.SObjectField sfield = fieldMap.get(field);
                        Schema.DescribeFieldResult fieldDescribe = sfield.getDescribe();
                        Schema.DisplayType fieldType = fieldDescribe.getType();

                        try {
                            switch on fieldType {
                                when String, TextArea, Phone, Email, Url, EncryptedString, Id {
                                    obj.put(field, value);
                                }

                                when Boolean {
                                    obj.put(field, value.toLowerCase() == 'true');
                                }

                                when Integer {
                                    obj.put(field, Integer.valueOf(value));
                                }

                                when Double, Percent, Currency {
                                    obj.put(field, Decimal.valueOf(value));
                                }

                                when Date {
                                    Date parsedDate = parseFlexibleDate(value);
                                    if (parsedDate != null) obj.put(field, parsedDate);
                                }

                               when DateTime {
                                    Date d = parseFlexibleDate(value);
                                    if (d != null) {
                                        DateTime dt = DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0));
                                        dt = dt.addMinutes(UserInfo.getTimezone().getOffset(dt) / (1000 * 60)); 
                                        obj.put(field, dt);
                                    } else {
                                        DateTime parsed = parseFlexibleDateTime(value);
                                        if (parsed != null) {
                                            DateTime dt = DateTime.newInstance(parsed.date(), Time.newInstance(0, 0, 0, 0));
                                            dt = dt.addMinutes(UserInfo.getTimezone().getOffset(dt) / (1000 * 60)); 
                                            obj.put(field, dt);
                                        }
                                    }
                                }

                                when Picklist, Reference {
                                    obj.put(field, value);
                                }

                                when else {
                                    String skipped = 'Skipped unsupported field: ' + field + ' (type: ' + fieldType + ')';
                                    if (!row.containsKey('Warnings')) {
                                        row.put('Warnings', skipped);
                                    } else {
                                        row.put('Warnings', row.get('Warnings') + '; ' + skipped);
                                    }
                                }
                            }
                        } catch (Exception conversionEx) {
                            row.put('Error', 'Conversion error in field ' + field + ': ' + conversionEx.getMessage());
                            exceptions.add(row);
                            continue;
                        }
                    }
                }
                
                sObjectsToUpsert.add(obj);
                indexToRowMap.put(rowIndex, row);
                rowIndex++;
            } catch (Exception e) {
                row.put('Error', e.getMessage()); exceptions.add(row);
                String id = !records.isEmpty() ? records[0].get('Id') : null; AS_ErrorLogger.log('AS_CSVUploaderController', 'uploadCSVBatch', e, id);
            }
        }

        // Perform DML with partial success
        Database.UpsertResult[] results;
        
        if (String.isNotBlank(externalIdField) && fieldMap.containsKey(externalIdField)) {
            // Use external ID field for upsert
            Schema.SObjectField externalIdFieldToken = fieldMap.get(externalIdField);
            results = Database.upsert(sObjectsToUpsert, externalIdFieldToken, false);
        } else {
            // Regular upsert without external ID
            results = Database.upsert(sObjectsToUpsert, false);
        }

        for (Integer i = 0; i < results.size(); i++) {
            Map<String, String> originalRow = indexToRowMap.get(i);

            if (results[i].isSuccess()) {
                originalRow.put('Id', results[i].getId());
                successes.add(originalRow);
            } else if(!results[i].isSuccess()){
                String errorMessage = results[i].getErrors().isEmpty() ? 'Unknown error' : results[i].getErrors()[0].getMessage();
                originalRow.put('Error', errorMessage);
                errors.add(originalRow);
            }
        }

        return new Map<String, Object>{
            'successCount' => successes.size(),
            'errors' => errors,
            'successes' => successes,
            'exceptions' => exceptions,
            'supportedFields' => supportedFields
        };    
    }
    
    @AuraEnabled
    public static void uploadLargeCSVChunk(List<Map<String, String>> records, String objectName, String externalIdField) {
        System.enqueueJob(new AS_CSVChunkProcessor(records, objectName, externalIdField));
    }

    @TestVisible
    private static Date parseFlexibleDate(String input) {
        input = input.trim();
        if (input.contains('/')) {
            // Format: MM/dd/yyyy or M/d/yyyy
            List<String> parts = input.split('/');
            if (parts.size() == 3) {
                Integer month = Integer.valueOf(parts[0]);
                Integer day = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(parts[2]);
                return Date.newInstance(year, month, day);
            }
        } else if (input.contains('-')) {
            List<String> parts = input.split('-');
            if (parts.size() == 3) {
                // Try yyyy-MM-dd first
                if (parts[0].length() == 4) {
                    Integer year = Integer.valueOf(parts[0]);
                    Integer month = Integer.valueOf(parts[1]);
                    Integer day = Integer.valueOf(parts[2]);
                    return Date.newInstance(year, month, day);
                } else {
                    // Fallback: MM-dd-yyyy
                    Integer month = Integer.valueOf(parts[0]);
                    Integer day = Integer.valueOf(parts[1]);
                    Integer year = Integer.valueOf(parts[2]);
                    return Date.newInstance(year, month, day);
                }
            }
        }
        
        AS_ErrorLogger.log('AS_CSVUploaderController', 'parseFlexibleDate', 'Unrecognized date format: ' + input, null); return null;
    }
    
    @TestVisible
    private static DateTime parseFlexibleDateTime(String input) {
        input = input.trim();

        // Try parsing "yyyy-MM-dd HH:mm:ss"
        if (input.contains('T')) {
            input = input.replace('T', ' ');
        }

        List<String> dateTimeParts = input.split(' ');
        if (dateTimeParts.size() != 2) {
            AS_ErrorLogger.log('AS_CSVUploaderController', 'parseFlexibleDateTime', 'Unrecognized datetime format: ' + input, null); return null;
        }

        Date datePart = parseFlexibleDate(dateTimeParts[0]);
        List<String> timeParts = dateTimeParts[1].split(':');

        if (timeParts.size() < 2) {
            AS_ErrorLogger.log('AS_CSVUploaderController', 'parseFlexibleDateTime', 'Invalid time format: ' + input, null); return null;
        }

        Integer hour = Integer.valueOf(timeParts[0]);
        Integer minute = Integer.valueOf(timeParts[1]);
        Integer second = timeParts.size() >= 3 ? Integer.valueOf(timeParts[2]) : 0;

        return DateTime.newInstance(datePart, Time.newInstance(hour, minute, second, 0));
    }

    // Inner class for chunk processing
    public class AS_CSVChunkProcessor implements Queueable {
        private List<Map<String, String>> records;
        private String objectName;
        private String externalIdField;

        public AS_CSVChunkProcessor(List<Map<String, String>> records, String objectName, String externalIdField) {
            this.records = records;
            this.objectName = objectName;
            this.externalIdField = externalIdField;
        }

        public void execute(QueueableContext context) {
            uploadCSVBatch(records, objectName, externalIdField);
        }
    }
}