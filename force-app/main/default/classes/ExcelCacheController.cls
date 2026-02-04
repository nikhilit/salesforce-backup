/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 16-10-2025
 * @last modified by  : Kartik Patkar Appstrail 
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   16-10-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class ExcelCacheController {

    private static final String CACHE_NAME = 'ExcelCache';

    // Store base64 Excel string
    @AuraEnabled
    public static void storeData(String cacheKey, String base64Excel) {
        if (String.isBlank(cacheKey) || String.isBlank(base64Excel)) {
            throw new AuraHandledException('Cache key and data must be non-empty.');
        }

        // Get the session cache partition
        Cache.SessionPartition cache = Cache.Session.getPartition(CACHE_NAME);
        cache.put(cacheKey, base64Excel);
    }

    // Retrieve base64 Excel string
    public static String getData(String cacheKey) {
        Cache.SessionPartition cache = Cache.Session.getPartition(CACHE_NAME);
        String cachedData = (String) cache.get(cacheKey);
        return cachedData != null ? cachedData : '';
    }
}