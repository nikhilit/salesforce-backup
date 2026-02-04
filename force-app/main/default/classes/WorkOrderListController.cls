public with sharing class WorkOrderListController {

    @AuraEnabled(cacheable=true)
    public static List<SObject> getWorkOrders(List<String> fields, String filterClause) {
        // Sanitize field names to prevent SOQL injection
        Set<String> validFields = new Set<String>();
        for (String f : fields) {
            if (Schema.SObjectType.WorkOrder.fields.getMap().containsKey(f)) {
                validFields.add(f);
            }
        }
        
        if (validFields.isEmpty()) {
            // Return an empty list or throw an exception if no valid fields are provided
            return new List<SObject>();
        }

        String query = 'SELECT Id, ' + String.join(new List<String>(validFields), ',') + ' FROM WorkOrder';
        
        // Add WHERE clause if a filter is provided
        if (String.isNotBlank(filterClause)) {
            query += ' WHERE ' + filterClause;
        }

        try {
            return Database.query(query);
        } catch (QueryException e) {
            // Handle exceptions, e.g., invalid filter clause
            throw new AuraHandledException('Invalid filter criteria: ' + e.getMessage());
        }
    }
}