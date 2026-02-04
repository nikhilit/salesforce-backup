public class CaseSAPBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [SELECT Id FROM Case WHERE To_be_Updated_in_SAP__c = 'true' AND AccountId!=null]
        );
    }

    public void execute(Database.BatchableContext bc, List<Case> scope) {
        List<String> ids = new List<String>();
        for (Case c : scope) ids.add(c.Id);

        if (!ids.isEmpty()) {
            System.enqueueJob(new CaseUpdateToSAP(ids));
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('CaseSAPBatch finished.');
    }
    public void execute(SchedulableContext sc) {
        // Schedule will run this — it kicks off the batch job
        CaseSAPBatch batch = new CaseSAPBatch();
        Database.executeBatch(batch, 200); // You can adjust batch size
    }
}