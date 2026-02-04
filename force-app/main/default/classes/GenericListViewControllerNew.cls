public with sharing class GenericListViewControllerNew {

    public class FilterCondition {
        @AuraEnabled public String field;
        @AuraEnabled public String operator;
        @AuraEnabled public String value;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getListViewData(String objectApiName) {

        // Get Profile Name
        Id profId = UserInfo.getProfileId();
        String profileName = [SELECT Name FROM Profile WHERE Id = :profId].Name;

        // Get Permission Sets
        Set<String> userPermSets = new Set<String>();
        for (PermissionSetAssignment psa : [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
        ]) {
            userPermSets.add(psa.PermissionSet.Name);
        }

        // Fetch CMDT configs for this object
        List<ListView_Config__mdt> configs = [
            SELECT Field_API_Names__c, Filter_JSON__c, 
                   Profile_Name__c, Permission_Set_Name__c
            FROM ListView_Config__mdt
            WHERE Object_API_Name__c = :objectApiName
        ];

        ListView_Config__mdt selectedConfig;

        // Priority 1: Permission Set match
        for (ListView_Config__mdt c : configs) {
            if (String.isNotBlank(c.Permission_Set_Name__c) 
                && userPermSets.contains(c.Permission_Set_Name__c)) {
                selectedConfig = c;
                break;
            }
        }

        // Priority 2: Profile match
        if (selectedConfig == null) {
            for (ListView_Config__mdt c : configs) {
                if (String.isNotBlank(c.Profile_Name__c) && c.Profile_Name__c == profileName) {
                    selectedConfig = c;
                    break;
                }
            }
        }

        // Priority 3: Default config (no profile, no permission set)
        if (selectedConfig == null) {
            for (ListView_Config__mdt c : configs) {
                if (String.isBlank(c.Profile_Name__c) && String.isBlank(c.Permission_Set_Name__c)) {
                    selectedConfig = c;
                    break;
                }
            }
        }

        if (selectedConfig == null) {
            throw new AuraHandledException('No list view configuration found for this user.');
        }

        // --------------------
        // Build Fields
        // --------------------
        List<String> fields = new List<String>();
        if (String.isNotBlank(selectedConfig.Field_API_Names__c)) {
            for (String f : selectedConfig.Field_API_Names__c.split(',')) {
                if (String.isNotBlank(f)) fields.add(f.trim());
            }
        }
        if (fields.isEmpty()) {
            throw new AuraHandledException('No fields configured in metadata for this view.');
        }

        // --------------------
        // Build SOQL
        // --------------------
        String soql = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectApiName;

        if (String.isNotBlank(selectedConfig.Filter_JSON__c)) {
            List<FilterCondition> conditions =
                (List<FilterCondition>) JSON.deserialize(selectedConfig.Filter_JSON__c, List<FilterCondition>.class);

            List<String> whereParts = new List<String>();
            for (FilterCondition f : conditions) {
                if (String.isBlank(f.field) || String.isBlank(f.operator)) continue;

                if (f.operator == 'IN') {
                    whereParts.add(f.field + ' IN ' + f.value);
                } else if (f.operator == 'LAST_N_DAYS') {
                    whereParts.add(f.field + ' = LAST_N_DAYS:' + f.value);
                } else if (f.operator == 'LIKE') {
                    whereParts.add(f.field + ' LIKE ' + '\'' + String.escapeSingleQuotes(f.value) + '\'');
                } else {
                    whereParts.add(f.field + ' ' + f.operator + ' ' + '\'' + String.escapeSingleQuotes(f.value) + '\'');
                }
            }
            if (!whereParts.isEmpty()) {
                soql += ' WHERE ' + String.join(whereParts, ' AND ');
            }
        }

        // --------------------
        // Query Records
        // --------------------
        List<SObject> records = Database.query(soql);

        // --------------------
        // Build Columns
        // --------------------
        List<Map<String, Object>> columns = new List<Map<String, Object>>();
        for (String f : fields) {
            columns.add(new Map<String, Object>{
                'label' => f,
                'fieldName' => f,
                'type' => 'text'
            });
        }

        return new Map<String, Object>{
            'columns' => columns,
            'records' => records
        };
    }
}