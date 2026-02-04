public with sharing class CaseSearchController {

    public class SearchResultWrapper {
        @AuraEnabled public String recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String objectApi;
        @AuraEnabled public String EmailId;
        @AuraEnabled public String SecondaryTelephone;
        @AuraEnabled public String Phone;
    }

    // Method to get API value from label for Category field
    private static String getCategoryApiValue(String label) {
        if(String.isBlank(label)) return label;
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get('Case');
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get('Category__c').getDescribe();
        
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive() && entry.getLabel() == label) {
                return entry.getValue();
            }
        }
        return label; // Return original if not found
    }

    // Method to get label mappings for Category field
    private static Map<String, String> getCategoryLabelMappings() {
        Map<String, String> apiToLabelMap = new Map<String, String>();
        
        for (Schema.PicklistEntry entry : Case.Category__c.getDescribe().getPicklistValues()) {
            if(entry.isActive()) {
                apiToLabelMap.put('Category__c_' + entry.getValue(), entry.getLabel());
            }
        }
        
        return apiToLabelMap;
    }

    // Convert API names to labels for display in search results
    private static List<Case> convertCategoryApiToLabels(List<Case> cases) {
        if(cases == null || cases.isEmpty()) return cases;
        
        Map<String, String> categoryMappings = getCategoryLabelMappings();
        
        for(Case caseRec : cases) {
            if(caseRec.Category__c != null && categoryMappings.containsKey('Category__c_' + caseRec.Category__c)) {
                caseRec.Category__c = categoryMappings.get('Category__c_' + caseRec.Category__c);
            }
        }
        
        return cases;
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> searchCases(
        String firstName,
        String lastName,
        String caNumber,
        String bpNumber,
        String teleNumber,
        String connection,
        String email,
        String caseNumber
    ) {
        List<String> inputs = new List<String>{firstName, lastName, caNumber, bpNumber, teleNumber, connection, email, caseNumber};
        Integer filledCount = 0;
        Boolean leadSearchAllowed = false;
        for (String val : inputs) {
            if (!String.isBlank(val)) filledCount++;
        }
        if (filledCount == 0) return new List<Case>();

        // --- Resolve CA Number → BP → Account ---
        Set<Id> accountIdsFromCA = new Set<Id>();
        if (!String.isBlank(caNumber)) {
            Set<String> bpNumbers = new Set<String>();
            // for (Move_In_Out__c service : [
            //     SELECT Business_Partner__c
            //     FROM Move_In_Out__c
            //     WHERE Contract_Account__c LIKE :('%' + String.escapeSingleQuotes(caNumber) + '%') AND Move_Out__c != null ORDER BY Move_Out__c DESC
            // ]) {
            //     if (service.Business_Partner__c != null) bpNumbers.add(service.Business_Partner__c);
            // }
            for (ServiceContract service : [
              SELECT AccountId,Contract_Account_Number__c 
                FROM ServiceContract 
               WHERE Contract_Account_Number__c =:caNumber
                AND AccountId != null]) {
                if (service.AccountId != null) bpNumbers.add(service.AccountId);
            }

            if (!bpNumbers.isEmpty()) {
                for (Account acc : [
                    SELECT Id
                    FROM Account
                    WHERE Id IN :bpNumbers
                    ORDER BY CreatedDate DESC
                    LIMIT 200
                ]) accountIdsFromCA.add(acc.Id);
            }
        }

        // --- Case search by CaseNumber only ---
        if (!String.isBlank(caseNumber) && filledCount == 1) {
            List<Case> caseResults = [
                SELECT Id, CaseNumber, Docket_Number__c, Account.Name, Lead__r.FirstName, Lead__r.LastName,
                       Category__c, Sub_Type__c, Status, Owner.Name, CreatedDate,Type__c,Account.Room__c
                FROM Case
                // WHERE CaseNumber LIKE :('%' + String.escapeSingleQuotes(caseNumber) + '%')
                //    OR Docket_Number__c LIKE :('%' + String.escapeSingleQuotes(caseNumber) + '%')
                WHERE CaseNumber = :String.escapeSingleQuotes(caseNumber)
   OR Docket_Number__c = :String.escapeSingleQuotes(caseNumber)

                ORDER BY CreatedDate DESC
                LIMIT 200
            ];
            
            // Convert Category API names to labels before returning
            return convertCategoryApiToLabels(caseResults);
        }

        // --- Build dynamic Account query ---
        String accQuery = 'SELECT Id FROM Account WHERE Id != null';
        if (!String.isBlank(firstName)) accQuery += ' AND FirstName__c LIKE \'%' + String.escapeSingleQuotes(firstName) + '%\'';
        if (!String.isBlank(lastName)) accQuery += ' AND LastName__c LIKE \'%' + String.escapeSingleQuotes(lastName) + '%\'';
        if (!String.isBlank(caNumber) && !accountIdsFromCA.isEmpty()) accQuery += ' AND Id IN :accountIdsFromCA';
        // if (!String.isBlank(bpNumber)) accQuery += ' AND BP_Number__c LIKE \'%' + String.escapeSingleQuotes(bpNumber) + '%\'';
        // if (!String.isBlank(teleNumber)) accQuery += ' AND Phone LIKE \'%' + String.escapeSingleQuotes(teleNumber) + '%\'';
        if (!String.isBlank(bpNumber))accQuery += ' AND BP_Number__c = \'' + String.escapeSingleQuotes(bpNumber) + '\'';
        if (!String.isBlank(teleNumber))accQuery += ' AND Phone = \'' + String.escapeSingleQuotes(teleNumber) + '\'';
        if (!String.isBlank(email)) accQuery += ' AND Account_Email__c LIKE \'%' + String.escapeSingleQuotes(email) + '%\'';
        if (!String.isBlank(connection)) accQuery += ' AND Connection_Object__c LIKE \'%' + String.escapeSingleQuotes(connection) + '%\'';
        accQuery += ' ORDER BY CreatedDate DESC LIMIT 200';

        List<Account> accList = Database.query(accQuery);

        // --- If accounts found, fetch their cases ---
        if (!accList.isEmpty()) {
            Set<Id> accIds = new Set<Id>();
            for (Account acc : accList) accIds.add(acc.Id);

            String caseWhere = '';
            if (!String.isBlank(caseNumber)) {
           //caseWhere = ' AND (CaseNumber LIKE \'%' + String.escapeSingleQuotes(caseNumber) + '%\' OR Docket_Number__c LIKE \'%' + String.escapeSingleQuotes(caseNumber) + '%\')';
          caseWhere = ' AND (CaseNumber = \'' + String.escapeSingleQuotes(caseNumber) + '\' OR Docket_Number__c = \'' + String.escapeSingleQuotes(caseNumber) + '\')';
            }

            List<Case> accountCases = Database.query(
                'SELECT Id, CaseNumber, Docket_Number__c, Account.Name, Lead__r.FirstName, Lead__r.LastName,' +
                ' Category__c, Sub_Type__c,Type__c, Status, Owner.Name, CreatedDate,Account.Room__c' +
                ' FROM Case WHERE AccountId IN :accIds' + caseWhere +
                ' ORDER BY CreatedDate DESC LIMIT 200'
            );

            if (!accountCases.isEmpty()) {
                // Convert Category API names to labels before returning
                return convertCategoryApiToLabels(accountCases);
            }
        }

        // --- Lead search fallback ---
        leadSearchAllowed = (
            (!String.isBlank(firstName) || !String.isBlank(lastName) || 
             !String.isBlank(teleNumber) || !String.isBlank(email))
            && String.isBlank(connection)
            && String.isBlank(bpNumber)
            && String.isBlank(caNumber)
        );
        System.debug('leadSearchAllowed = ' + leadSearchAllowed);

        if (leadSearchAllowed) {
            String leadQuery = 'SELECT Id FROM Lead WHERE Id != null';
            if (!String.isBlank(firstName)) leadQuery += ' AND FirstName LIKE \'%' + String.escapeSingleQuotes(firstName) + '%\'';
            if (!String.isBlank(lastName)) leadQuery += ' AND LastName LIKE \'%' + String.escapeSingleQuotes(lastName) + '%\'';
            // if (!String.isBlank(teleNumber)) leadQuery += ' AND Phone LIKE \'%' + String.escapeSingleQuotes(teleNumber) + '%\'';
            if (!String.isBlank(teleNumber))leadQuery += ' AND Phone = \'' + String.escapeSingleQuotes(teleNumber) + '\'';
            if (!String.isBlank(email)) leadQuery += ' AND Email LIKE \'%' + String.escapeSingleQuotes(email) + '%\'';
            leadQuery += ' ORDER BY CreatedDate DESC LIMIT 200';

            List<Lead> leadList = Database.query(leadQuery);

            if (!leadList.isEmpty()) {
                Set<Id> leadIds = new Set<Id>();
                for (Lead l : leadList) leadIds.add(l.Id);

                String caseWhere = '';
                if (!String.isBlank(caseNumber)) {
                   // caseWhere = ' AND (CaseNumber LIKE \'%' + String.escapeSingleQuotes(caseNumber) + '%\' OR Docket_Number__c LIKE \'%' + String.escapeSingleQuotes(caseNumber) + '%\')';
                caseWhere = ' AND (CaseNumber = \'' + String.escapeSingleQuotes(caseNumber) + '\' OR Docket_Number__c = \'' + String.escapeSingleQuotes(caseNumber) + '\')';

                }

                List<Case> leadCases = Database.query(
                    'SELECT Id, CaseNumber, Docket_Number__c, Account.Name, Lead__r.FirstName, Lead__r.LastName,' +
                    ' Category__c, Sub_Type__c,Type__c,Status, Owner.Name, CreatedDate,Account.Room__c' +
                    ' FROM Case WHERE Lead__c IN :leadIds' + caseWhere +
                    ' ORDER BY CreatedDate DESC LIMIT 200'
                );
                
                // Convert Category API names to labels before returning
                return convertCategoryApiToLabels(leadCases);
            }
        }

        return new List<Case>();
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getCasesByPhone(String phoneNumber) {
        try {
            List<Account> accs = [
                SELECT Id FROM Account
                //WHERE Phone LIKE :('%' + String.escapeSingleQuotes(phoneNumber) + '%')
                Where phone =:String.escapeSingleQuotes(phoneNumber)
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];
            List<Lead> leads = [
                SELECT Id FROM Lead
                //WHERE Phone LIKE :('%' + String.escapeSingleQuotes(phoneNumber) + '%')
                Where phone =:String.escapeSingleQuotes(phoneNumber)
                ORDER BY CreatedDate DESC
                LIMIT 5
            ];

            List<Case> caseResults = new List<Case>();

            if (!accs.isEmpty()) {
                Set<Id> accIds = new Set<Id>();
                for (Account acc : accs) accIds.add(acc.Id);
                caseResults = [
                    SELECT Id, CaseNumber, Docket_Number__c, Account.Name, Lead__r.FirstName, Lead__r.LastName,
                           Category__c, Sub_Type__c, Status, Owner.Name, CreatedDate,Type__c,Account.Room__c
                    FROM Case
                    WHERE AccountId IN :accIds
                    ORDER BY CreatedDate DESC
                    LIMIT 200
                ];
            } else if (!leads.isEmpty()) {
                Set<Id> leadIds = new Set<Id>();
                for (Lead l : leads) leadIds.add(l.Id);
                caseResults = [
                    SELECT Id, CaseNumber, Docket_Number__c, Account.Name, Lead__r.FirstName, Lead__r.LastName,
                           Category__c, Sub_Type__c, Status, Owner.Name, CreatedDate,Type__c,Account.Room__c
                    FROM Case
                    WHERE Lead__c IN :leadIds
                    ORDER BY CreatedDate DESC
                    LIMIT 200
                ];
            }

            // Convert Category API names to labels before returning
            return convertCategoryApiToLabels(caseResults);
        } catch (Exception e) {
            return new List<Case>();
        }
    }

    // Add method to get Category options for UI (if needed)
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getCategoryOptions() {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get('Case');
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get('Category__c').getDescribe();
        
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
            }
        }
        return options;
    }

    // Wrapper class for picklist options
    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}