public class MoveInOutSupplementBatch implements Database.Batchable<SObject>, Schedulable {

    // ===== Batch Logic =====
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Premise_Name__c, Premise_Name__r.Supplement__c, BP_Number__c ' +
            'FROM Move_In_Out__c ' +
            'WHERE Supplement_Mismatch__c = TRUE'
        );
    }

    public void execute(Database.BatchableContext bc, List<Move_In_Out__c> scope) {
        Set<Id> bpIds = new Set<Id>();
        for (Move_In_Out__c mio : scope) {
            if (mio.BP_Number__c != null) {
                bpIds.add(mio.BP_Number__c);
            }
        }

        if (bpIds.isEmpty()) return;

        Map<Id, Account> bpMap = new Map<Id, Account>(
            [SELECT Id, Supplement__c FROM Account WHERE Id IN :bpIds]
        );

        List<Account> bpsToUpdate = new List<Account>();
        for (Move_In_Out__c mio : scope) {
            Account acc = bpMap.get(mio.BP_Number__c);
            if (acc != null && acc.Supplement__c != mio.Premise_Name__r.Supplement__c) {
                acc.Supplement__c = mio.Premise_Name__r.Supplement__c;
                bpsToUpdate.add(acc);
            }
        }

        if (!bpsToUpdate.isEmpty()) {
            update bpsToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('MoveInOutSupplementBatch completed successfully.');
    }

    // ===== Scheduler Logic =====
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new MoveInOutSupplementBatch(), 200);
    }
}