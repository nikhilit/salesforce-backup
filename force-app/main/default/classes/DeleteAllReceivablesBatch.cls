public class DeleteAllReceivablesBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query Receivable__c records, limited to 1 million for safe deletion
        return Database.getQueryLocator('SELECT Id FROM Receivable__c LIMIT 10000000');
    }

    public void execute(Database.BatchableContext bc, List<Receivable__c> scope) {
        try {
            if (!scope.isEmpty()) {
                delete scope;
                System.debug('Deleted ' + scope.size() + ' Receivable__c records.');
            }
        } catch (DmlException e) {
            System.debug('❌ Error deleting Receivable__c records: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('✅ Completed deletion of up to 1 million Receivable__c records.');
    }
}