/**
 * @description SOQL helpers for cursor-based pagination.
 */
public with sharing class MeteringWorkOrderListViewAdvanceSoql {

    public static String quoteString(String value) {
        if (value == null) {
            return 'NULL';
        }
        return '\'' + String.escapeSingleQuotes(value) + '\'';
    }

    public static String quoteId(Id value) {
        return quoteString((String)value);
    }

    public static String dateLiteral(Date value) {
        return String.valueOf(value);
    }

    public static String inStrings(List<String> values) {
        List<String> quoted = new List<String>();
        for (String v : values) {
            if (!String.isBlank(v)) {
                quoted.add(quoteString(v));
            }
        }
        if (quoted.isEmpty()) {
            return '(NULL)';
        }
        return '(' + String.join(quoted, ',') + ')';
    }

    public static void addFilteredWhereClauses(List<String> whereClauses, Map<String,Object> filters) {
        if (filters == null) {
            return;
        }

        // IN (...) filters
        Map<String,String> inSpec = new Map<String,String>{
            'bpNumbers' => 'BP_Number__c',
            'caNumbers' => 'CA_Number__c'
        };
        for (String key : inSpec.keySet()) {
            List<String> values = getFilterStringList(filters, key);
            if (values != null && !values.isEmpty()) {
                whereClauses.add(inSpec.get(key) + ' IN ' + inStrings(values));
            }
        }

        // Date filters
        Date fromDt = parseDate(getFilterString(filters, 'fromDate'));
        if (fromDt != null) {
            whereClauses.add('Appointment_Date__c >= ' + dateLiteral(fromDt));
        }
        Date toDt = parseDate(getFilterString(filters, 'toDate'));
        if (toDt != null) {
            whereClauses.add('Appointment_Date__c <= ' + dateLiteral(toDt));
        }

        // LIKE filter
        String meterPattern = likePattern(getFilterString(filters, 'meterNumber'));
        if (meterPattern != null) {
            whereClauses.add('Meter_Number__c LIKE ' + quoteString(meterPattern));
        }

        // Equality filters
        Map<String,String> eqSpec = new Map<String,String>{
            'agency' => 'Agency__c',
            'agent' => 'Assigned_Agent__c',
            'groupMasterId' => 'Group_Master__c',
            'groupCodeId' => 'Group_Code__c',
            'groupMessageId' => 'Group_Message__c',
            'appointmentStatus' => 'Appointment_Status__c',
            'mruCategoryValue' => 'MRU_Category__c',
            'approvalStatus' => 'Approval_Status__c',
            'area' => 'Area__c',
            'gaWiseValue' => 'GA_Wise__c',
            'locationValue' => 'Location__c'
        };
        for (String key : eqSpec.keySet()) {
            String value = getFilterString(filters, key);
            if (!String.isBlank(value)) {
                whereClauses.add(eqSpec.get(key) + ' = ' + quoteString(value));
            }
        }
    }

    public static String buildSoql(List<String> soqlFields, String objectApiName, List<String> whereClauses) {
        List<String> normalizedWhere = new List<String>();
        if (whereClauses != null) {
            for (String clause : whereClauses) {
                if (!String.isBlank(clause)) {
                    normalizedWhere.add(clause.trim());
                }
            }
        }

        String base = 'SELECT ' + String.join(soqlFields, ',') +
            ' FROM ' + objectApiName;

        if (normalizedWhere.isEmpty()) {
            return base + ' ORDER BY CreatedDate DESC';
        }

        return base +
            ' WHERE ' + String.join(normalizedWhere, ' AND ') +
            ' ORDER BY CreatedDate DESC';
    }

    private static Date parseDate(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        return Date.valueOf(value);
    }

    private static String likePattern(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        return '%' + value + '%';
    }

    private static String getFilterString(Map<String,Object> filters, String key) {
        if (filters == null || !filters.containsKey(key) || filters.get(key) == null) {
            return null;
        }
        return String.valueOf(filters.get(key));
    }

    private static List<String> getFilterStringList(Map<String,Object> filters, String key) {
        if (filters == null || !filters.containsKey(key) || filters.get(key) == null) {
            return null;
        }
        Object raw = filters.get(key);
        if (raw instanceof List<Object>) {
            List<String> out = new List<String>();
            for (Object o : (List<Object>)raw) {
                if (o != null) {
                    out.add(String.valueOf(o));
                }
            }
            return out;
        }
        if (raw instanceof List<String>) {
            return (List<String>)raw;
        }
        return null;
    }
}