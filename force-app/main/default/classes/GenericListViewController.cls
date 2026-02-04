public with sharing class GenericListViewController {

    @AuraEnabled(cacheable=true)
    public static List<ListViewConfig__mdt> getListViewConfig(String objectName) {
        return [
            SELECT Field_API_Name__c, Field_Label__c, Show_in_List__c,
                   Use_in_Filter__c, Filter_Type__c, Lookup_Object__c
            FROM ListViewConfig__mdt
            WHERE Object_API_Name__c = :objectName
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRecords(String objectName, Map<String, Object> filters, List<String> fields) {
        String query = 'SELECT Id,' + String.join(fields, ',') + ' FROM ' + objectName;
        if (!filters.isEmpty()) {
            List<String> clauses = new List<String>();
            for (String key : filters.keySet()) {
                Object val = filters.get(key);
                if (val instanceof Map<String, Object>) {
                    Map<String, Object> range = (Map<String, Object>) val;
                    if (range.containsKey('from')) clauses.add(key + ' >= ' + formatValue(range.get('from')));
                    if (range.containsKey('to')) clauses.add(key + ' <= ' + formatValue(range.get('to')));
                } else {
                    clauses.add(key + ' = ' + formatValue(val));
                }
            }
            query += ' WHERE ' + String.join(clauses, ' AND ');
        }
        return formatResults(Database.query(query), fields);
    }

    private static String formatValue(Object val) {
        if (val instanceof String) return '\'' + String.escapeSingleQuotes((String)val) + '\'';
        if (val instanceof Date) return ((Date)val).format();
        return String.valueOf(val);
    }

    private static List<Map<String, Object>> formatResults(List<SObject> records, List<String> fields) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (SObject rec : records) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('Id', rec.Id);
            for (String f : fields) {
                row.put(f, rec.get(f));
            }
            result.add(row);
        }
        return result;
    }
}