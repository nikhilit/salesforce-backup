public with sharing class BillingController {
    @AuraEnabled(cacheable=true)
    public static List<Billing__c> getBillingsByAccount(Id accountId) {
        return [
            SELECT Id,
                   Print_Doc_Number__c,
                   Billing_Doc_Number__c,
                   Invoice_Number__c,
                   Bill_Date__c,
                   Period_From__c,
                   Period_To__c,
                   Due_Amount__c,
                   Due_Date__c,
                   Document_Date__c,
                   Posting_Date__c
            FROM Billing__c
            WHERE Account__c = :accountId
             ORDER BY Posting_Date__c DESC LIMIT 6
        ];
    }
}