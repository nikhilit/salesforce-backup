public with sharing class CaseLookupController {

    @AuraEnabled(cacheable=true)
    public static List<CaseOption> getAfterSalesCases() {

        List<CaseOption> options = new List<CaseOption>();

        for (Case c : [
            SELECT Id, CaseNumber, Subject,Sub_Type__c
            FROM Case
            WHERE Department__c = 'AFTER SALES'
            AND Sub_Type__c = 'Bldg. Demolition - Perm Disconnection & Refund Processing.'
            ORDER BY CreatedDate DESC
            LIMIT 200
        ]) {
            options.add(new CaseOption(
                c.Id,
                c.CaseNumber + ' - ' + c.Sub_Type__c
            ));
        }

        return options;
    }

    public class CaseOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public CaseOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }
}