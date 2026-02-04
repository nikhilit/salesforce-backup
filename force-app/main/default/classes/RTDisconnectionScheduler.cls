global class RTDisconnectionScheduler implements Database.Batchable<SObject>, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Account_Email__c,Temp_Disconnection_Email_send_date__c
            FROM Account
            WHERE Account_Email__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : scope) {
            accountIds.add(acc.Id);
        }

        if (!accountIds.isEmpty()) {
            RTDisconnectionHandler.processAccounts(accountIds);
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional logging or post-processing
        System.debug('RTDisconnectionScheduler batch execution completed.');
    }

    // Optional: allow scheduling through UI or Apex
    global void execute(SchedulableContext sc) {
        RTDisconnectionScheduler batch = new RTDisconnectionScheduler();
        Database.executeBatch(batch, 200); // recommended scope size
    }
}