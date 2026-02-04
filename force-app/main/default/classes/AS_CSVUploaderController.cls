/**
* @File Name : AS_CSVUploaderController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 8, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 8, 2025 |   | Initial Version
**/
   
public without sharing class AS_CSVUploaderController {

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
    public static Map<String, Object> uploadCSVBatch(String objectName, List<Map<String, String>> csvRecords) {

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
                System.debug('============records=1111========>>>>'+records.size());


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

                // Replace external values with Ids + apply fallbacks
                // for (Map<String, String> row : records) {
                //     for (String targetField : lookupMaps.keySet()) {
                //         Map<String, Id> idMap = lookupMaps.get(targetField);
                //         if (row.containsKey(targetField) && idMap.containsKey(row.get(targetField))) {
                //             row.put(targetField, idMap.get(row.get(targetField)));
                //         }
                //     }

                //     // --- FALLBACK HANDLING ---
                //     // RecordTypeId fallback to MGL_R_T if metadata-based lookup didn't resolve
                //     if (supportedObjects.containsKey('RecordTypeId')) {
                //         if (!row.containsKey('RecordTypeId') || String.isBlank(row.get('RecordTypeId'))) {
                //             RecordType rt = [
                //                 SELECT Id 
                //                 FROM RecordType 
                //                 WHERE DeveloperName = 'MGL_R_T' 
                //                 AND SObjectType = 'WorkOrder' 
                //                 LIMIT 1
                //             ];
                //             if (rt != null) {
                //                 row.put('RecordTypeId', rt.Id);
                //             }
                //         }
                //     }
                // }

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
                System.debug('============records=2222========>>>>'+records.size());


                // System.debug('============supportedObjects=========>>>>'+supportedObjects);
                // System.debug('============supportedFields=========>>>>'+supportedFields);
                // System.debug('============evmByColumn=========>>>>'+evmByColumn);
                // System.debug('============objectName=========>>>>'+objectName);
                // System.debug('============records=1111========>>>>'+records);

        
                // Set<String> accountBPNumbers = new Set<String>();
                // Set<String> portionNames     = new Set<String>();
                // Set<String> recordTypeNames  = new Set<String>();
                // Set<String> workTypeNames    = new Set<String>();

                // for (Map<String, String> row : records) {
                //     if (row.containsKey('AccountId') && String.isNotBlank(row.get('AccountId'))) {
                //         accountBPNumbers.add(row.get('AccountId'));
                //     }
                //     if (row.containsKey('Portion__c') && String.isNotBlank(row.get('Portion__c'))) {
                //         portionNames.add(row.get('Portion__c'));
                //     }
                //     if (row.containsKey('WorkTypeId') && String.isNotBlank(row.get('WorkTypeId'))) {
                //         workTypeNames.add(row.get('WorkTypeId'));
                //     }
                //     if (row.containsKey('RecordTypeId') && String.isNotBlank(row.get('RecordTypeId'))) {
                //         recordTypeNames.add(row.get('RecordTypeId'));
                //     }
                // }

                // System.debug('============accountBPNumbers=========>>>>'+accountBPNumbers);
                // System.debug('============portionNames=========>>>>'+portionNames);
                // System.debug('============workTypeNames=========>>>>'+workTypeNames);
                // System.debug('============recordTypeNames=========>>>>'+recordTypeNames);

                // Map<String, Id> accountMap = new Map<String, Id>();

                // if (!accountBPNumbers.isEmpty()) {
                //     for (Account acc : [SELECT Id, BP_Number__c
                //                           FROM Account
                //                          WHERE BP_Number__c IN :accountBPNumbers]) {
                //         accountMap.put(acc.BP_Number__c, acc.Id);
                //     }
                // }

                // Map<String, Id> portionMap = new Map<String, Id>();

                // if (!portionNames.isEmpty()) {
                //     for (Portion__c p : [SELECT Id, Name
                //                            FROM Portion__c
                //                           WHERE Name IN :portionNames]) {
                //         portionMap.put(p.Name, p.Id);
                //     }
                // }

                // Map<String, Id> recordTypeMap = new Map<String, Id>();

                // System.debug('============recordTypeNames=========>>>>'+recordTypeNames);

                // if (!recordTypeNames.isEmpty()) {
                //     for (RecordType rt : [SELECT Id, DeveloperName 
                //                             FROM RecordType
                //                            WHERE DeveloperName IN :recordTypeNames
                //                              AND SObjectType = 'WorkOrder']) {
                //         recordTypeMap.put(rt.DeveloperName, rt.Id);
                //     }
                // }

                // System.debug('============recordTypeMap=========>>>>'+recordTypeMap);

                // // Default fallback RecordType if missing
                // if (!recordTypeMap.containsKey('MGL_R_T')) {
                //     RecordType rtDefault = [SELECT Id FROM RecordType
                //                              WHERE DeveloperName = 'MGL_R_T' 
                //                                AND SObjectType = 'WorkOrder'
                //                              LIMIT 1];
                //     recordTypeMap.put('RecordTypeId', rtDefault.Id);
                // }

                // Map<String, Id> workTypeMap = new Map<String, Id>();

                // if (!workTypeNames.isEmpty()) {
                //     for (WorkType wt : [SELECT Id, Name
                //                           FROM WorkType
                //                          WHERE Name IN :workTypeNames]) {
                //         workTypeMap.put(wt.Name, wt.Id);
                //     }
                // }

                // System.debug('============accountMap=========>>>>'+accountMap);
                // System.debug('============portionMap=========>>>>'+portionMap);
                // System.debug('============recordTypeMap=========>>>>'+recordTypeMap);
                // System.debug('============workTypeMap=========>>>>'+workTypeMap);

                // for (Map<String, String> row : records) {
                    
                //     if (row.containsKey('AccountId') && accountMap.containsKey(row.get('AccountId'))) {
                //         row.put('AccountId', accountMap.get(row.get('AccountId')));
                //     }
                //     if (row.containsKey('Portion__c') && portionMap.containsKey(row.get('Portion__c'))) {
                //         row.put('Portion__c', portionMap.get(row.get('Portion__c')));
                //     }
                //     if (row.containsKey('WorkTypeId') && workTypeMap.containsKey(row.get('WorkTypeId'))) {
                //         row.put('WorkTypeId', workTypeMap.get(row.get('WorkTypeId')));
                //     }

                //     if(row.containsKey('RecordTypeId') && !recordTypeMap.containsKey(row.get('RecordTypeId'))){
                //         if(recordTypeMap.containsKey('RecordTypeId')){
                //             row.put('RecordTypeId', recordTypeMap.get('RecordTypeId'));    
                //         }
                //     }else if (!row.containsKey('RecordTypeId') && recordTypeMap.containsKey('RecordTypeId')) {
                //         row.put('RecordTypeId', recordTypeMap.get('RecordTypeId'));
                //     }else if(row.containsKey('RecordTypeId') && recordTypeMap.containsKey(row.get('RecordTypeId'))){
                //         row.put('RecordTypeId', workTypeMap.get(row.get('RecordTypeId')));
                //     }
                // }
            }else{
                records = csvRecords;
            }

            System.debug('============records=2222========>>>>'+records);
             System.debug('============records Size ========>>>>'+records.size());

        } catch (Exception ex) {
            AS_ErrorLogger.log('AS_CSVUploaderController', 'uploadCSVBatch', ex, null);
        }

        return uploadCSVBatch(records, objectName, '');
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

        // if(objectApiName=='Account'){
        //     externalIdField='BP_Number__c';
        // }

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
                                    //obj.put(field, parseFlexibleDate(value));
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
        //SObjectField externalField = Schema.getGlobalDescribe().get(objectApiName)
        //.getDescribe().fields.getMap().get(externalIdField);
        System.debug('The Result before is-->'+sObjectsToUpsert.size());   
        Database.UpsertResult[] results = Database.upsert(sObjectsToUpsert, false); 
        System.debug('The Result after is-->'+results.size());       

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
                /*Integer month = Integer.valueOf(parts[0]);
                Integer day = Integer.valueOf(parts[1]);
                Integer year = Integer.valueOf(parts[2]);*/
                //change to DD/MM/YY
                Integer day = Integer.valueOf(parts[0]);
                Integer month = Integer.valueOf(parts[1]);
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
                    /*Integer month = Integer.valueOf(parts[0]);
                    Integer day = Integer.valueOf(parts[1]);
                    Integer year = Integer.valueOf(parts[2]);*/
                    //change to DD MM YY
                    Integer day = Integer.valueOf(parts[0]);
                    Integer month = Integer.valueOf(parts[1]);
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
}