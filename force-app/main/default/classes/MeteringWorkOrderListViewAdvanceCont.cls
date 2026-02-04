/**
 * @description Controller for mtrWorkOrderListViewAdvance LWC - Cursor-based pagination
 * @author Kartik Patkar, Appstrail
 * @date 27-01-2026
 */
public with sharing class MeteringWorkOrderListViewAdvanceCont {
    
    /**
     * @description Wrapper class for pagination cursor results
     */
    public class LoadMoreRecordsResult {
        @AuraEnabled public String paginationCursorJson;
        @AuraEnabled public List<Map<String,Object>> records;
        @AuraEnabled public Integer offset;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Boolean hasMore;
        @AuraEnabled public Integer deletedRows;
    }

    private static LoadMoreRecordsResult buildResult(MeteringWorkOrderListViewAdvanceUtils.CursorPage page) {
        LoadMoreRecordsResult result = new LoadMoreRecordsResult();
        result.paginationCursorJson = JSON.serialize(page.paginationCursor);
        result.totalRecords = page.paginationCursor.getNumRecords();

        result.records = new List<Map<String,Object>>();
        if (page.fetchResult == null) {
            result.deletedRows = 0;
            result.offset = result.totalRecords;
            result.hasMore = false;
            return result;
        }

        result.deletedRows = page.fetchResult.getNumDeletedRecords();
        result.offset = page.fetchResult.getNextIndex();
        result.hasMore = result.offset < result.totalRecords;

        for (SObject sobj : page.fetchResult.getRecords()) {
            result.records.add(MeteringWorkOrderListViewAdvanceUtils.flattenRow(sobj, page.soqlFields));
        }
        return result;
    }

    /**
     * @description Load work orders using Pagination Cursor API (View All - no filters)
     * @param paginationCursorJson - The pagination cursor JSON (null for first call)
     * @param start - Starting index for fetching records
     * @param pageSize - Number of records to fetch per page
     * @param recordTypeDevName - Record Type developer name
     * @param fieldJson - JSON string of fields to fetch
     * @param objectApiName - Object API name
     * @param customerCategory - Customer category filter
     * @return LoadMoreRecordsResult with cursor, records, and pagination info
     */
    @AuraEnabled(cacheable=false)
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static LoadMoreRecordsResult loadMoreRecordsWithPagination(
        String paginationCursorJson,
        Integer start,
        Integer pageSize,
        String recordTypeDevName,
        String fieldJson,
        String objectApiName,
        String customerCategory
    ) {
        try {
            MeteringWorkOrderListViewAdvanceUtils.CursorRequest request = new MeteringWorkOrderListViewAdvanceUtils.CursorRequest();
            request.paginationCursorJson = paginationCursorJson;
            request.start = start;
            request.pageSize = pageSize;
            request.recordTypeDevName = recordTypeDevName;
            request.fieldJson = fieldJson;
            request.objectApiName = objectApiName;
            request.customerCategory = customerCategory;
            
            MeteringWorkOrderListViewAdvanceUtils.CursorPage page =
                MeteringWorkOrderListViewAdvanceUtils.fetchViewAllPage(request);
            return buildResult(page);

        } catch (Exception e) {
            System.debug('🔴 ERROR in loadMoreRecordsWithPagination: ' + e.getMessage());
            System.debug('🔴 STACK: ' + e.getStackTraceString());
            throw new AuraHandledException('Error loading records: ' + e.getMessage());
        }
    }

    /**
     * @description Load filtered work orders using Pagination Cursor API
     * @param paginationCursorJson - The pagination cursor JSON (null for first call)
     * @param start - Starting index for fetching records
     * @param pageSize - Number of records to fetch per page
     * @param recordTypeDevName - Record Type developer name
     * @param fieldJson - JSON string of fields to fetch
     * @param objectApiName - Object API name
     * @param customerCategory - Customer category filter
     * @param filters - Map of filter criteria
     * @return LoadMoreRecordsResult with cursor, records, and pagination info
     */
    @AuraEnabled(cacheable=false)
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static LoadMoreRecordsResult loadFilteredRecordsWithPagination(
        String paginationCursorJson,
        Integer start,
        Integer pageSize,
        String recordTypeDevName,
        String fieldJson,
        String objectApiName,
        String customerCategory,
        Map<String,Object> filters
    ) {
        try {
            MeteringWorkOrderListViewAdvanceUtils.CursorRequest request = new MeteringWorkOrderListViewAdvanceUtils.CursorRequest();
            request.paginationCursorJson = paginationCursorJson;
            request.start = start;
            request.pageSize = pageSize;
            request.recordTypeDevName = recordTypeDevName;
            request.fieldJson = fieldJson;
            request.objectApiName = objectApiName;
            request.customerCategory = customerCategory;
            request.filters = filters;
            
            MeteringWorkOrderListViewAdvanceUtils.CursorPage page =
                MeteringWorkOrderListViewAdvanceUtils.fetchFilteredPage(request);
            return buildResult(page);

        } catch (Exception e) {
            System.debug('🔴 ERROR in loadFilteredRecordsWithPagination: ' + e.getMessage());
            System.debug('🔴 STACK: ' + e.getStackTraceString());
            throw new AuraHandledException('Error loading filtered records: ' + e.getMessage());
        }
    }
}