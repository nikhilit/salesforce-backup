public class PopulateCANumberBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch all ServiceContracts where Contract_Account_Number__c is not null
        // and AccountId is populated
        return Database.getQueryLocator([
            SELECT Id, AccountId, Contract_Account_Number__c
            FROM ServiceContract
            WHERE AccountId != null
              AND Contract_Account_Number__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<ServiceContract> scope) {
        Map<Id, String> accountToCA = new Map<Id, String>();

        // Build a mapping of AccountId → Contract_Account_Number__c
        for (ServiceContract sc : scope) {
            if (sc.AccountId != null && sc.Contract_Account_Number__c != null) {
                accountToCA.put(sc.AccountId, sc.Contract_Account_Number__c);
            }
        }

        if (accountToCA.isEmpty()) return;

        List<Account> accountsToUpdate = new List<Account>();

        // Query Accounts to update
        for (Account acc : [
            SELECT Id, CA_Number__c
            FROM Account
            WHERE Id IN :accountToCA.keySet()
        ]) {
            acc.CA_Number__c = accountToCA.get(acc.Id);
            accountsToUpdate.add(acc);
        }

        if (!accountsToUpdate.isEmpty()) {
            try {
                update accountsToUpdate;
                System.debug('✅ Updated ' + accountsToUpdate.size() + ' Account records.');
            } catch (DmlException e) {
                System.debug('❌ Error updating Accounts: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('✅ PopulateCANumberBatch completed at ' + Datetime.now());
    }
}