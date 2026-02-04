public with sharing class DynamicListViewController {

    /* =====================================================
       MAIN DATA FETCH (LIST VIEW) - HIGHLY OPTIMIZED
       ===================================================== */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getRecords(
        String objectName,
        List<String> fieldNames,
        Integer pageSize,
        Integer pageNumber,
        String searchKey,
        String sortBy,
        String sortDirection,
        String filters
    ) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            Integer offsetVal = (pageNumber - 1) * pageSize;

            /* ✅ MINIMAL SEARCHABLE FIELDS - ONLY INDEXED */
            List<String> whereConditions = new List<String>();

            if (!String.isBlank(searchKey)) {
                String escapedKey = String.escapeSingleQuotes(searchKey.trim());
                whereConditions.add('WorkOrderNumber = \'' + escapedKey + '\'');
            }

            // Add advanced filters
            if (!String.isBlank(filters)) {
                try {
                    Map<String, Object> filterObj = (Map<String, Object>) JSON.deserialize(filters, Map<String, Object>.class);
                    String filterWhere = buildFilterClause(filterObj);
                    if (!String.isBlank(filterWhere)) {
                        whereConditions.add('(' + filterWhere + ')');
                    }
                } catch (Exception e) {
                    System.debug('⚠️ Filter parsing error: ' + e.getMessage());
                }
            }

            String whereClause = whereConditions.isEmpty()
                ? ''
                : ' WHERE ' + String.join(whereConditions, ' AND ');

            /* ✅ SAFE SORTING - Only indexed fields */
            String orderByClause = ' ORDER BY Id DESC';
            
            if (!String.isBlank(sortBy)) {
                Set<String> safeFields = new Set<String>{
                    'Id', 'WorkOrderNumber', 'CreatedDate', 'LastModifiedDate', 'Status', 'Priority'
                };
                
                if (safeFields.contains(sortBy)) {
                    orderByClause = ' ORDER BY ' + sortBy + ' ' +
                        (sortDirection == 'desc' ? 'DESC' : 'ASC');
                }
            }

            /* ✅ OPTIMIZED QUERY - SIMPLE & FAST */
            String dataQuery =
                'SELECT ' + String.join(fieldNames, ', ') +
                ' FROM ' + objectName +
                whereClause +
                orderByClause +
                ' LIMIT ' + (pageSize+1) +
                ' OFFSET ' + offsetVal;

            System.debug('⚡ QUERY: ' + dataQuery);
            Long startTime = System.currentTimeMillis();

            List<SObject> records = Database.query(dataQuery);
            
            Long endTime = System.currentTimeMillis();
            System.debug('⏱️ Query took: ' + (endTime - startTime) + 'ms');
            System.debug('✅ Records: ' + records.size());

            Boolean hasMore = records.size() > pageSize;

            if (hasMore) {
                records.remove(records.size() - 1);
            }

            result.put('records', records);
            result.put('hasMore', hasMore);
            result.put('pageNumber', pageNumber);
            result.put('error', null);

        } catch (Exception e) {
            System.debug('❌ ERROR: ' + e.getMessage());
            System.debug('❌ STACK: ' + e.getStackTraceString());
            result.put('error', e.getMessage());
            result.put('records', new List<SObject>());
        }

        return result;
    }

    // ===== ADVANCED FILTERING HELPER =====
    private static String buildFilterClause(Map<String, Object> filterObj) {
        String operator = (String) filterObj.get('operator');
        List<Object> filterList = (List<Object>) filterObj.get('filters');
        List<String> conditions = new List<String>();

        if (filterList == null || filterList.isEmpty()) {
            return '';
        }

        for (Object f : filterList) {
            Map<String, Object> filter = (Map<String, Object>) f;
            String field = (String) filter.get('field');
            String filterOp = (String) filter.get('operator');
            String value = (String) filter.get('value');

            if (String.isBlank(field) || String.isBlank(value)) continue;

            String condition = buildCondition(field, filterOp, value);
            if (!String.isBlank(condition)) {
                conditions.add(condition);
            }
        }

        if (conditions.isEmpty()) return '';

        String joinOp = (operator == null || operator == 'AND') ? ' AND ' : ' OR ';
        return String.join(conditions, joinOp);
    }

    private static String buildCondition(String field, String operator, String value) {
        String escapedValue = String.escapeSingleQuotes(value);

        switch on operator {
            when '=' {
                return field + ' = \'' + escapedValue + '\'';
            }
            when '!=' {
                return field + ' != \'' + escapedValue + '\'';
            }
            when '>' {
                return field + ' > \'' + escapedValue + '\'';
            }
            when '<' {
                return field + ' < \'' + escapedValue + '\'';
            }
            when 'contains' {
                return field + ' LIKE \'%' + escapedValue + '%\'';
            }
            when 'startswith' {
                return field + ' LIKE \'' + escapedValue + '%\'';
            }
            when else {
                return null;
            }
        }
    }

    /* =====================================================
       FIELD METADATA (DYNAMIC COLUMNS) - CACHED
       ===================================================== */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getFieldList(String objectName) {

        List<Map<String, String>> fieldsInfo = new List<Map<String, String>>();

        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType == null) return fieldsInfo;

            Map<String, Schema.SObjectField> fieldMap =
                objType.getDescribe().fields.getMap();

            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult d =
                    fieldMap.get(fieldName).getDescribe();

                if (d.isAccessible()) {
                    Map<String, String> fieldData = new Map<String, String>();
                    fieldData.put('label', d.getLabel());
                    fieldData.put('apiName', d.getName());
                    fieldData.put('type', String.valueOf(d.getType()));
                    fieldsInfo.add(fieldData);
                }
            }
            
            System.debug('✅ Fields: ' + fieldsInfo.size());

        } catch (Exception e) {
            System.debug('❌ Error in getFieldList: ' + e.getMessage());
        }

        return fieldsInfo;
    }

    /* =====================================================
       USER COLUMN PREFERENCE - LOAD (CACHED)
       ===================================================== */
    @AuraEnabled(cacheable=true)
    public static String getUserColumnPreference(String objectApiName) {

        try {
            List<User_ListView_Config__c> configs = [
                SELECT Selected_Fields__c
                FROM User_ListView_Config__c
                WHERE User__c = :UserInfo.getUserId()
                AND Object_API_Name__c = :objectApiName
                AND Is_Active__c = true
                LIMIT 1
            ];

            String preference = configs.isEmpty() ? null : configs[0].Selected_Fields__c;
            System.debug('✅ Preference: ' + preference);
            return preference;

        } catch (Exception e) {
            System.debug('❌ Error in getUserColumnPreference: ' + e.getMessage());
            return null;
        }
    }

    /* =====================================================
       USER COLUMN PREFERENCE - SAVE / UPDATE
       ===================================================== */
    @AuraEnabled
    public static void saveUserColumnPreference(
        String objectApiName,
        String selectedFields
    ) {

        try {
            List<User_ListView_Config__c> configs = [
                SELECT Id
                FROM User_ListView_Config__c
                WHERE User__c = :UserInfo.getUserId()
                AND Object_API_Name__c = :objectApiName
                LIMIT 1
            ];

            if (configs.isEmpty()) {
                insert new User_ListView_Config__c(
                    Name = objectApiName + ' - ' + UserInfo.getName(),
                    User__c = UserInfo.getUserId(),
                    Object_API_Name__c = objectApiName,
                    Selected_Fields__c = selectedFields,
                    Is_Active__c = true
                );
                System.debug('✅ Created preference');
            } else {
                configs[0].Selected_Fields__c = selectedFields;
                configs[0].Is_Active__c = true;
                update configs[0];
                System.debug('✅ Updated preference');
            }

        } catch (Exception e) {
            System.debug('❌ Error saving preference: ' + e.getMessage());
        }
    }

        @AuraEnabled
    public static Map<String, Object> importWorkOrdersApex(String csvData, String objectName) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('created', 0);
        result.put('updated', 0);
        result.put('failed', 0);
        result.put('errors', new List<String>());

        try {
            // Parse CSV data
            List<Map<String, Object>> records = (List<Map<String, Object>>) JSON.deserialize(csvData, List<Map<String, Object>>.class);

            System.debug('📥 Importing ' + records.size() + ' records');

            List<SObject> recordsToUpsert = new List<SObject>();
            Integer createdCount = 0;
            Integer updatedCount = 0;
            Integer failedCount = 0;
            List<String> errors = new List<String>();

            for (Map<String, Object> recordData : records) {
                try {
                    SObject newRecord = Schema.getGlobalDescribe().get(objectName).newSObject();

                    // Get field map
                    Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
                        .get(objectName)
                        .getDescribe()
                        .fields
                        .getMap();

                    // Populate fields
                    for (String fieldName : recordData.keySet()) {
                        Object fieldValue = recordData.get(fieldName);
                        
                        if (String.isBlank(fieldName) || fieldValue == null) {
                            continue;
                        }

                        // Check if field exists and is updateable
                        if (fieldMap.containsKey(fieldName.toLowerCase())) {
                            Schema.SObjectField field = fieldMap.get(fieldName.toLowerCase());
                            Schema.DescribeFieldResult fieldDesc = field.getDescribe();

                            if (fieldDesc.isUpdateable() || fieldDesc.isCreateable()) {
                                // Convert value based on field type
                                Schema.DisplayType fieldType = fieldDesc.getType();
                                Object convertedValue = convertValue(String.valueOf(fieldValue), fieldType);
                                newRecord.put(fieldName, convertedValue);
                            }
                        }
                    }

                    recordsToUpsert.add(newRecord);

                } catch (Exception e) {
                    failedCount++;
                    errors.add('Row Error: ' + e.getMessage());
                    System.debug('❌ Row Error: ' + e.getMessage());
                }
            }

            // Upsert records
            if (!recordsToUpsert.isEmpty()) {
                List<Database.UpsertResult> upsertResults = Database.upsert(recordsToUpsert, false);

                for (Database.UpsertResult upsertResult : upsertResults) {
                    if (upsertResult.isSuccess()) {
                        if (upsertResult.isCreated()) {
                            createdCount++;
                        } else {
                            updatedCount++;
                        }
                    } else {
                        failedCount++;
                        for (Database.Error error : upsertResult.getErrors()) {
                            errors.add(error.getMessage());
                        }
                    }
                }
            }

            result.put('created', createdCount);
            result.put('updated', updatedCount);
            result.put('failed', failedCount);
            result.put('errors', errors);

            System.debug('✅ Import Complete - Created: ' + createdCount + ', Updated: ' + updatedCount + ', Failed: ' + failedCount);

        } catch (Exception e) {
            System.debug('❌ Import Error: ' + e.getMessage());
            System.debug('❌ Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Error importing data: ' + e.getMessage());
        }

        return result;
    }

    // Helper method to convert string values to correct field types
    private static Object convertValue(String value, Schema.DisplayType fieldType) {
        if (String.isBlank(value)) {
            return null;
        }

        try {
            switch on fieldType {
                when INTEGER {
                    return Integer.valueOf(value);
                }
                when DOUBLE, PERCENT, CURRENCY {
                    return Double.valueOf(value);
                }
                when BOOLEAN {
                    return Boolean.valueOf(value.toLowerCase());
                }
                when DATE {
                    return Date.valueOf(value);
                }
                when DATETIME {
                    return DateTime.valueOf(value);
                }
                when else {
                    return value;
                }
            }
        } catch (Exception e) {
            System.debug('⚠️ Value conversion error: ' + e.getMessage() + ' for value: ' + value);
            return value;
        }
    }

    /* =====================================================
       INLINE EDITING - UPDATE RECORD
       ===================================================== */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> updateRecord(
        String recordId,
        String objectName,
        String fieldsToUpdate
    ) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            Map<String, Object> fieldsMap = (Map<String, Object>) JSON.deserialize(fieldsToUpdate, Map<String, Object>.class);

            SObject recordToUpdate = Schema.getGlobalDescribe()
                .get(objectName)
                .newSObject(recordId);

            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe()
                .fields
                .getMap();

            for (String fieldName : fieldsMap.keySet()) {
                Object fieldValue = fieldsMap.get(fieldName);

                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                    Schema.SObjectField field = fieldMap.get(fieldName.toLowerCase());
                    Schema.DescribeFieldResult fieldDesc = field.getDescribe();

                    if (fieldDesc.isUpdateable()) {
                        Schema.DisplayType fieldType = fieldDesc.getType();
                        Object convertedValue = convertValue(String.valueOf(fieldValue), fieldType);
                        recordToUpdate.put(fieldName, convertedValue);
                    }
                }
            }

            update recordToUpdate;

            result.put('success', true);
            result.put('message', 'Record updated successfully');
            result.put('recordId', recordId);

            System.debug('✅ Record updated: ' + recordId);

        } catch (Exception e) {
            System.debug('❌ Update Error: ' + e.getMessage());
            result.put('success', false);
            result.put('message', e.getMessage());
            throw new AuraHandledException('Error updating record: ' + e.getMessage());
        }

        return result;
    }

    /* =====================================================
       RECORD DETAILS - LOAD FULL RECORD + RELATED
       ===================================================== */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getRecordDetails(
        String recordId,
        String objectName
    ) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            // Get all fields for this object
            List<String> allFields = new List<String>();
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe()
                .get(objectName)
                .getDescribe()
                .fields
                .getMap();

            for (String fieldName : fieldMap.keySet()) {
                if (fieldMap.get(fieldName).getDescribe().isAccessible()) {
                    allFields.add(fieldName);
                }
            }

            // Query full record
            String query = 'SELECT ' + String.join(allFields, ', ') +
                ' FROM ' + objectName + ' WHERE Id = \'' + recordId + '\' LIMIT 1';

            List<SObject> records = Database.query(query);

            if (!records.isEmpty()) {
                result.put('record', records[0]);
                result.put('details', records[0].getPopulatedFieldsAsMap());
            }

            // Placeholder for related records
            result.put('relatedRecords', new List<Object>());

            System.debug('✅ Record details loaded: ' + recordId);

        } catch (Exception e) {
            System.debug('❌ Details Error: ' + e.getMessage());
            throw new AuraHandledException('Error loading record details: ' + e.getMessage());
        }

        return result;
    }

    /* =====================================================
       ANALYTICS DASHBOARD - METRICS & DISTRIBUTIONS
       ===================================================== */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getAnalytics(
        String objectName,
        List<String> fieldNames,
        String filters
    ) {
        Map<String, Object> result = new Map<String, Object>();

        try {
            // Build where clause with filters
            String whereClause = '';
            if (!String.isBlank(filters)) {
                try {
                    Map<String, Object> filterObj = (Map<String, Object>) JSON.deserialize(filters, Map<String, Object>.class);
                    String filterWhere = buildFilterClause(filterObj);
                    if (!String.isBlank(filterWhere)) {
                        whereClause = ' WHERE ' + filterWhere;
                    }
                } catch (Exception e) {
                    System.debug('⚠️ Filter parsing error: ' + e.getMessage());
                }
            }

            // Count total records
            String countQuery = 'SELECT COUNT() FROM ' + objectName + whereClause;
            Integer totalCount = Database.countQuery(countQuery);

            // Get sample records for distribution
            String dataQuery = 'SELECT Id, Status, Priority FROM ' + objectName +
                whereClause + ' LIMIT 100';

            List<SObject> sampleRecords = Database.query(dataQuery);

            // Build distribution maps
            Map<String, Integer> statusDistribution = new Map<String, Integer>();
            Map<String, Integer> priorityDistribution = new Map<String, Integer>();

            for (SObject record : sampleRecords) {
                String status = String.valueOf(record.get('Status'));
                String priority = String.valueOf(record.get('Priority'));

                statusDistribution.put(status, (statusDistribution.get(status) ?? 0) + 1);
                priorityDistribution.put(priority, (priorityDistribution.get(priority) ?? 0) + 1);
            }

            result.put('totalRecords', totalCount);
            result.put('statusDistribution', statusDistribution);
            result.put('priorityDistribution', priorityDistribution);
            result.put('fieldDistribution', new Map<String, Object>());
            result.put('fieldAverages', new Map<String, Object>());

            System.debug('✅ Analytics loaded: Total=' + totalCount);

        } catch (Exception e) {
            System.debug('❌ Analytics Error: ' + e.getMessage());
            result.put('totalRecords', 0);
            result.put('statusDistribution', new Map<String, Integer>());
            result.put('priorityDistribution', new Map<String, Integer>());
        }

        return result;
    }
}