public class CaseStatusUpdateBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Start method: Query Cases that are eligible for update
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status__c, Customer_Information__c, Status
            FROM Case
            WHERE Status = 'New'
        ]);
    }

    // Execute method: process records in batch
    public void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();

        for (Case c : scope) {

            // Default to null to check if status actually changes
            String newStatus = null;

            // 🟢 Open
            if (c.Customer_Information__c != 'SL' &&
                c.Status__c != 'TSCO' &&
                c.Status__c != 'TSRL') {
                newStatus = 'In-Progress';
            }
            // 🟡 Released
            else if (c.Status__c == 'TSRL') {
                newStatus = 'Actioned By Department';
            }
            // 🔴 Closed
            else if (c.Customer_Information__c == 'SL' ||
                     c.Status__c == 'TSCO') {
                newStatus = 'Resolved';
            }

            // Update only if status changes
            if (newStatus != null && c.Status != newStatus) {
                c.Status = newStatus;
                casesToUpdate.add(c);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('✅ Case Status Update Batch finished.');
    }
}