public class ServiceContractAccountBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all ServiceContracts where AccountId is null
        return Database.getQueryLocator([
            SELECT Id, Contract_Account_Number__c, Business_Partner_Number__c, AccountId, To_Be_Processed__c
            FROM ServiceContract
			WHERE LastModifiedDate = LAST_N_DAYS:2
        ]);
    }

    public void execute(Database.BatchableContext bc, List<ServiceContract> scope) {
        Set<String> bpNumbers = new Set<String>();

        // Collect BP Numbers
        for (ServiceContract sc : scope) {
            if (String.isNotBlank(sc.Business_Partner_Number__c)) {
                bpNumbers.add(sc.Business_Partner_Number__c);
            }
        }

        // Query matching Accounts
        Map<String, Account> bpToAccountMap = new Map<String, Account>();
        if (!bpNumbers.isEmpty()) {
            for (Account acc : [
                SELECT Id, BP_Number__c
                FROM Account
                WHERE BP_Number__c IN :bpNumbers
            ]) {
                bpToAccountMap.put(acc.BP_Number__c, acc);
            }
        }

        // Update ServiceContracts
        for (ServiceContract sc : scope) {
            if (sc.Business_Partner_Number__c != null && bpToAccountMap.containsKey(sc.Business_Partner_Number__c)) {
                sc.AccountId = bpToAccountMap.get(sc.Business_Partner_Number__c).Id;
                sc.To_Be_Processed__c = false;
            }
        }

        if (!scope.isEmpty()) {
            try {
                Database.update(scope, false); // partial success
            } catch (Exception e) {
                System.debug('Update failed: ' + e.getMessage());
                Error_Logger__c err = Error_LoggerClass.createErrorLogger(
    'ServiceContractAccountBatch', 'execute', null, e.getTypeName(), e.getMessage(), e.getLineNumber(), true
);
insert err;

            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch finished for ServiceContract → AccountId population.');
    }
}