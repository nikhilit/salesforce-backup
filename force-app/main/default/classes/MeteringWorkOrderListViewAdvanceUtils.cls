/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 02-02-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   02-02-2026   Kartik Patkar, Appstrail   Initial Version
**/

public with sharing class MeteringWorkOrderListViewAdvanceUtils {

    public class CursorRequest {
        @AuraEnabled public String paginationCursorJson;
        @AuraEnabled public Integer start;
        @AuraEnabled public Integer pageSize;

        @AuraEnabled public String recordTypeDevName;
        @AuraEnabled public String fieldJson;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public String customerCategory;

        @AuraEnabled public Map<String,Object> filters;
    }

    public class CursorPage {
        public Database.PaginationCursor paginationCursor;
        public Database.CursorFetchResult fetchResult;
        public List<String> soqlFields;
    }

    private static Integer normalizeStart(Integer start) {
        if (start == null || start < 0) {
            return 0;
        }
        return start;
    }

    private static Integer normalizePageSize(Integer pageSize) {
        if (pageSize == null || pageSize < 1) {
            return 1;
        }
        return pageSize;
    }

    private static Integer clampPageSize(Database.PaginationCursor cursor, Integer start, Integer pageSize) {
        Integer total = cursor.getNumRecords();
        Integer remaining = total - start;
        return Math.min(pageSize, remaining);
    }

    public static CursorPage fetchViewAllPage(CursorRequest request) {
        String fieldJson = request.fieldJson;
        String objectApiName = request.objectApiName;
        String recordTypeDevName = request.recordTypeDevName;
        String customerCategory = request.customerCategory;

        validateRequest(objectApiName, recordTypeDevName);

        List<String> soqlFields = parseSoqlFields(fieldJson);
        Id recordTypeId = getRecordTypeId(objectApiName, recordTypeDevName);

        List<String> whereClauses = new List<String>{
            'RecordTypeId = ' + MeteringWorkOrderListViewAdvanceSoql.quoteId(recordTypeId),
            'Customer_Category__c = ' + MeteringWorkOrderListViewAdvanceSoql.quoteString(customerCategory)
        };

        String soql = MeteringWorkOrderListViewAdvanceSoql.buildSoql(soqlFields, objectApiName, whereClauses);
        Database.PaginationCursor cursor = ensureCursor(request.paginationCursorJson, soql);
        Integer start = normalizeStart(request.start);
        Integer pageSize = normalizePageSize(request.pageSize);

        CursorPage page = new CursorPage();
        page.paginationCursor = cursor;
        page.soqlFields = soqlFields;

        Integer total = cursor.getNumRecords();
        if (total == 0 || start >= total) {
            // No rows to fetch (or already at end). Return an empty page.
            page.fetchResult = null;
            return page;
        }

        pageSize = clampPageSize(cursor, start, pageSize);
        page.fetchResult = cursor.fetchPage(start, pageSize);
        page.soqlFields = soqlFields;
        return page;
    }

    public static CursorPage fetchFilteredPage(CursorRequest request) {
        String fieldJson = request.fieldJson;
        String objectApiName = request.objectApiName;
        String recordTypeDevName = request.recordTypeDevName;
        String customerCategory = request.customerCategory;
        Map<String,Object> filters = request.filters;

        validateRequest(objectApiName, recordTypeDevName);

        List<String> soqlFields = parseSoqlFields(fieldJson);
        Id recordTypeId = getRecordTypeId(objectApiName, recordTypeDevName);

        List<String> whereClauses = new List<String>{
            'RecordTypeId = ' + MeteringWorkOrderListViewAdvanceSoql.quoteId(recordTypeId),
            'Customer_Category__c = ' + MeteringWorkOrderListViewAdvanceSoql.quoteString(customerCategory)
        };

        MeteringWorkOrderListViewAdvanceSoql.addFilteredWhereClauses(whereClauses, filters);

        String soql = MeteringWorkOrderListViewAdvanceSoql.buildSoql(soqlFields, objectApiName, whereClauses);
        Database.PaginationCursor cursor = ensureCursor(request.paginationCursorJson, soql);
        Integer start = normalizeStart(request.start);
        Integer pageSize = normalizePageSize(request.pageSize);

        CursorPage page = new CursorPage();
        page.paginationCursor = cursor;
        page.soqlFields = soqlFields;

        Integer total = cursor.getNumRecords();
        if (total == 0 || start >= total) {
            // No rows to fetch (or already at end). Return an empty page.
            page.fetchResult = null;
            return page;
        }

        pageSize = clampPageSize(cursor, start, pageSize);
        page.fetchResult = cursor.fetchPage(start, pageSize);
        page.soqlFields = soqlFields;
        return page;
    }

    public static List<String> parseSoqlFields(String fieldJson) {
        if (String.isBlank(fieldJson)) {
            fieldJson = '{}';
        }
        Map<String,Object> fm = (Map<String,Object>)JSON.deserializeUntyped(fieldJson);
        List<String> soqlFields = new List<String>(fm.keySet());
        if (!soqlFields.contains('Id')) {
            soqlFields.add('Id');
        }
        return soqlFields;
    }

    private static void validateRequest(String objectApiName, String recordTypeDevName) {
        if (String.isBlank(objectApiName)) {
            throw new AuraHandledException('Missing required parameter: objectApiName');
        }
        if (String.isBlank(recordTypeDevName)) {
            throw new AuraHandledException('Missing required parameter: recordTypeDevName');
        }
    }

    public static Id getRecordTypeId(String objectApiName, String recordTypeDevName) {
        Map<String,Schema.RecordTypeInfo> rtMap = Schema.getGlobalDescribe()
            .get(objectApiName)
            .getDescribe()
            .getRecordTypeInfosByDeveloperName();

        if (!rtMap.containsKey(recordTypeDevName)) {
            throw new AuraHandledException('Invalid Record Type Developer Name: ' + recordTypeDevName);
        }

        return rtMap.get(recordTypeDevName).getRecordTypeId();
    }

    public static Database.PaginationCursor ensureCursor(String paginationCursorJson, String soql) {
        if (String.isBlank(paginationCursorJson)) {
            return Database.getPaginationCursor(soql, AccessLevel.USER_MODE);
        }
        try {
            return (Database.PaginationCursor)JSON.deserialize(paginationCursorJson, Database.PaginationCursor.class);
        } catch (Exception e) {
            // If the client sends an incompatible value (or an old cached shape), fall back to a fresh cursor.
            return Database.getPaginationCursor(soql, AccessLevel.USER_MODE);
        }
    }

    public static Map<String,Object> flattenRow(SObject record, List<String> fields) {
        Map<String,Object> row = new Map<String,Object>();
        for (String fieldPath : fields) {
            row.put(fieldPath, getFieldValueByPath(record, fieldPath));
        }
        return row;
    }

    private static Object getFieldValueByPath(SObject record, String fieldPath) {
        if (record == null || String.isBlank(fieldPath)) {
            return null;
        }
        if (!fieldPath.contains('.')) {
            return record.get(fieldPath);
        }

        List<String> parts = fieldPath.split('\\.');
        SObject current = record;
        for (Integer i = 0; i < parts.size() - 1; i++) {
            if (current == null) {
                return null;
            }
            current = current.getSObject(parts[i]);
        }
        return (current == null) ? null : current.get(parts[parts.size() - 1]);
    }

}