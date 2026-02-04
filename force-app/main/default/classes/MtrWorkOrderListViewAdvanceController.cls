/**
 * @description Controller for mtrWorkOrderListViewAdvance LWC - Cursor-based pagination
 * @author Kartik Patkar, Appstrail
 * @date 20-01-2026
 */
public with sharing class MtrWorkOrderListViewAdvanceController {
    
    /**
     * @description Wrapper class for pagination cursor results
     */
    public class LoadMoreRecordsResult {
        @AuraEnabled public Database.PaginationCursor paginationCursor;
        @AuraEnabled public List<Map<String,Object>> records;
        @AuraEnabled public Integer offset;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Boolean hasMore;
        @AuraEnabled public Integer deletedRows;
    }

    /**
     * @description Load work orders using Pagination Cursor API (View All - no filters)
     * @param paginationCursor - The pagination cursor (null for first call)
     * @param start - Starting index for fetching records
     * @param pageSize - Number of records to fetch per page
     * @param recordTypeDevName - Record Type developer name
     * @param fieldJson - JSON string of fields to fetch
     * @param objectApiName - Object API name
     * @param customerCategory - Customer category filter
     * @return LoadMoreRecordsResult with cursor, records, and pagination info
     */
    @AuraEnabled(cacheable=false)
    public static LoadMoreRecordsResult loadMoreRecordsWithPagination(
        Database.PaginationCursor paginationCursor,
        Integer start,
        Integer pageSize,
        String recordTypeDevName,
        String fieldJson,
        String objectApiName,
        String customerCategory
    ) {
        try {
            // Parse field JSON
            Map<String,Object> fm = (Map<String,Object>)JSON.deserializeUntyped(fieldJson);
            List<String> soqlFields = new List<String>(fm.keySet());
            if (!soqlFields.contains('Id')) soqlFields.add('Id');

            // Get RecordTypeId
            Map<String,Schema.RecordTypeInfo> rtMap = Schema.getGlobalDescribe()
                .get(objectApiName)
                .getDescribe()
                .getRecordTypeInfosByDeveloperName();
            
            if (!rtMap.containsKey(recordTypeDevName)) {
                throw new AuraHandledException('Invalid Record Type Developer Name: ' + recordTypeDevName);
            }
            Id recordTypeId = rtMap.get(recordTypeDevName).getRecordTypeId();

            // Build SOQL query
            String soql = 'SELECT ' + String.join(soqlFields, ',') +
                         ' FROM ' + objectApiName +
                         ' WHERE RecordTypeId = :recordTypeId' +
                         ' AND Customer_Category__c = :customerCategory' +
                         ' ORDER BY CreatedDate DESC';

            System.debug('🔵 Pagination SOQL: ' + soql);

            // Create cursor if null (first call)
            if (paginationCursor == null) {
                paginationCursor = Database.getPaginationCursor(soql, AccessLevel.USER_MODE);
                System.debug('🔵 Created new pagination cursor');
            }

            // Fetch page of records
            LoadMoreRecordsResult result = new LoadMoreRecordsResult();
            Database.CursorFetchResult fetchResult = paginationCursor.fetchPage(start, pageSize);
            
            result.paginationCursor = paginationCursor;
            result.totalRecords = paginationCursor.getNumRecords();
            result.deletedRows = fetchResult.getNumDeletedRecords();
            result.offset = fetchResult.getNextIndex();
            result.hasMore = result.offset < result.totalRecords;

            // Flatten the records
            List<SObject> rawRecords = fetchResult.getRecords();
            result.records = new List<Map<String,Object>>();
            for (SObject sobj : rawRecords) {
                result.records.add(flattenRow(sobj, soqlFields));
            }

            System.debug('🟢 Fetched ' + result.records.size() + ' records, offset: ' + result.offset + '/' + result.totalRecords);
            if (result.deletedRows > 0) {
                System.debug('🟡 Deleted rows: ' + result.deletedRows);
            }

            return result;

        } catch (Exception e) {
            System.debug('🔴 ERROR in loadMoreRecordsWithPagination: ' + e.getMessage());
            System.debug('🔴 STACK: ' + e.getStackTraceString());
            throw new AuraHandledException('Error loading records: ' + e.getMessage());
        }
    }

    /**
     * @description Load filtered work orders using Pagination Cursor API
     * @param paginationCursor - The pagination cursor (null for first call)
     * @param start - Starting index for fetching records
     * @param pageSize - Number of records to fetch per page
     * @param bpNumbers - List of BP numbers to filter
     * @param caNumbers - List of CA numbers to filter
     * @param fromDate - Start date filter
     * @param toDate - End date filter
     * @param agency - Agency filter
     * @param agent - Agent filter
     * @param groupMasterId - Group Master ID filter
     * @param groupCodeId - Group Code ID filter
     * @param groupMessageId - Group Message ID filter
     * @param appointmentStatus - Appointment Status filter
     * @param meterNumber - Meter Number filter
     * @param mruCategoryValue - MRU Category filter
     * @param approvalStatus - Approval Status filter
     * @param area - Area filter
     * @param gaWiseValue - GA Wise filter
     * @param locationValue - Location filter
     * @param recordTypeDevName - Record Type developer name
     * @param fieldJson - JSON string of fields to fetch
     * @param objectApiName - Object API name
     * @param customerCategory - Customer category filter
     * @return LoadMoreRecordsResult with cursor, records, and pagination info
     */
    @AuraEnabled(cacheable=false)
    public static LoadMoreRecordsResult loadFilteredRecordsWithPagination(
        Database.PaginationCursor paginationCursor,
        Integer start,
        Integer pageSize,
        List<String> bpNumbers,
        List<String> caNumbers,
        String fromDate,
        String toDate,
        String agency,
        String agent,
        String groupMasterId,
        String groupCodeId,
        String groupMessageId,
        String appointmentStatus,
        String meterNumber,
        String mruCategoryValue,
        String approvalStatus,
        String area,
        String gaWiseValue,
        String locationValue,
        String recordTypeDevName,
        String fieldJson,
        String objectApiName,
        String customerCategory
    ) {
        try {
            // Parse field JSON
            Map<String,Object> fm = (Map<String,Object>)JSON.deserializeUntyped(fieldJson);
            List<String> soqlFields = new List<String>(fm.keySet());
            if (!soqlFields.contains('Id')) soqlFields.add('Id');

            // Get RecordTypeId
            Map<String,Schema.RecordTypeInfo> rtMap = Schema.getGlobalDescribe()
                .get(objectApiName)
                .getDescribe()
                .getRecordTypeInfosByDeveloperName();
            
            if (!rtMap.containsKey(recordTypeDevName)) {
                throw new AuraHandledException('Invalid Record Type Developer Name: ' + recordTypeDevName);
            }
            Id recordTypeId = rtMap.get(recordTypeDevName).getRecordTypeId();

            // Build SOQL query with filters
            String soql = 'SELECT ' + String.join(soqlFields, ',') +
                         ' FROM ' + objectApiName +
                         ' WHERE RecordTypeId = :recordTypeId' +
                         ' AND Customer_Category__c = :customerCategory';

            // Add filter conditions
            if (bpNumbers != null && !bpNumbers.isEmpty()) {
                soql += ' AND BP_Number__c IN :bpNumbers';
            }
            if (caNumbers != null && !caNumbers.isEmpty()) {
                soql += ' AND CA_Number__c IN :caNumbers';
            }
            if (!String.isBlank(fromDate)) {
                soql += ' AND Appointment_Date__c >= ' + fromDate;
            }
            if (!String.isBlank(toDate)) {
                soql += ' AND Appointment_Date__c <= ' + toDate;
            }
            if (!String.isBlank(agency)) {
                soql += ' AND Agency__c = :agency';
            }
            if (!String.isBlank(agent)) {
                soql += ' AND Assigned_Agent__c = :agent';
            }
            if (!String.isBlank(groupMasterId)) {
                soql += ' AND Group_Master__c = :groupMasterId';
            }
            if (!String.isBlank(groupCodeId)) {
                soql += ' AND Group_Code__c = :groupCodeId';
            }
            if (!String.isBlank(groupMessageId)) {
                soql += ' AND Group_Message__c = :groupMessageId';
            }
            if (!String.isBlank(appointmentStatus)) {
                soql += ' AND Appointment_Status__c = :appointmentStatus';
            }
            if (!String.isBlank(meterNumber)) {
                soql += ' AND Meter_Number__c LIKE \'%' + String.escapeSingleQuotes(meterNumber) + '%\'';
            }
            if (!String.isBlank(mruCategoryValue)) {
                soql += ' AND MRU_Category__c = :mruCategoryValue';
            }
            if (!String.isBlank(approvalStatus)) {
                soql += ' AND Approval_Status__c = :approvalStatus';
            }
            if (!String.isBlank(area)) {
                soql += ' AND Area__c = :area';
            }
            if (!String.isBlank(gaWiseValue)) {
                soql += ' AND GA_Wise__c = :gaWiseValue';
            }
            if (!String.isBlank(locationValue)) {
                soql += ' AND Location__c = :locationValue';
            }

            soql += ' ORDER BY CreatedDate DESC';

            System.debug('🔵 Filtered Pagination SOQL: ' + soql);

            // Create cursor if null (first call)
            if (paginationCursor == null) {
                paginationCursor = Database.getPaginationCursor(soql, AccessLevel.USER_MODE);
                System.debug('🔵 Created new filtered pagination cursor');
            }

            // Fetch page of records
            LoadMoreRecordsResult result = new LoadMoreRecordsResult();
            Database.CursorFetchResult fetchResult = paginationCursor.fetchPage(start, pageSize);
            
            result.paginationCursor = paginationCursor;
            result.totalRecords = paginationCursor.getNumRecords();
            result.deletedRows = fetchResult.getNumDeletedRecords();
            result.offset = fetchResult.getNextIndex();
            result.hasMore = result.offset < result.totalRecords;

            // Flatten the records
            List<SObject> rawRecords = fetchResult.getRecords();
            result.records = new List<Map<String,Object>>();
            for (SObject sobj : rawRecords) {
                result.records.add(flattenRow(sobj, soqlFields));
            }

            System.debug('🟢 Filtered fetch: ' + result.records.size() + ' records, offset: ' + result.offset + '/' + result.totalRecords);
            if (result.deletedRows > 0) {
                System.debug('🟡 Deleted rows: ' + result.deletedRows);
            }

            return result;

        } catch (Exception e) {
            System.debug('🔴 ERROR in loadFilteredRecordsWithPagination: ' + e.getMessage());
            System.debug('🔴 STACK: ' + e.getStackTraceString());
            throw new AuraHandledException('Error loading filtered records: ' + e.getMessage());
        }
    }

    /**
     * @description Flatten SObject row into Map<String,Object>
     * @param record - SObject to flatten
     * @param fields - List of field API names
     * @return Map<String,Object> - Flattened record
     */
    private static Map<String,Object> flattenRow(SObject record, List<String> fields) {
        Map<String,Object> row = new Map<String,Object>();
        
        for (String fieldPath : fields) {
            Object value = null;
            
            if (fieldPath.contains('.')) {
                // Handle relationship fields
                List<String> parts = fieldPath.split('\\.');
                SObject current = record;
                
                for (Integer i = 0; i < parts.size() - 1; i++) {
                    if (current != null) {
                        current = current.getSObject(parts[i]);
                    }
                }
                
                if (current != null) {
                    value = current.get(parts[parts.size() - 1]);
                }
            } else {
                // Direct field
                value = record.get(fieldPath);
            }
            
            row.put(fieldPath, value);
        }
        
        return row;
    }
}