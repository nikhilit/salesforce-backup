public with sharing class CustomLookupController {
    @AuraEnabled(cacheable=true)
    public static List<sObject> searchRecords(String objectApiName, String searchKey) {
        List<sObject> sObjectList = new List<sObject>();
        
        // Ensure that objectApiName is valid and searchKey is not blank
        if (String.isNotBlank(searchKey) && isValidObject(objectApiName)) {
            String key = '%' + searchKey + '%';

            // Construct the dynamic query with proper binding
            String queryString = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(objectApiName) + 
                                 ' WHERE Name LIKE :key LIMIT 10';

            try {
                // Execute the query with safe binding for the searchKey
                sObjectList = Database.query(queryString);
            } catch (Exception e) {
                // Debug log for catching any issues
                System.debug('Error executing query: ' + e.getMessage());
                throw new AuraHandledException('Failed to retrieve records');
            }
        }
        
        return sObjectList;
    }

    // Helper method to check if the object exists in the org's schema
    private static Boolean isValidObject(String objectApiName) {
        try {
            // Check if the object exists in the schema
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            return sObjectType != null;
        } catch (Exception e) {
            System.debug('Invalid object API name: ' + objectApiName);
            return false;
        }
    }
}