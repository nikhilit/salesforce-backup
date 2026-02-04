global class UpdateCaseDRSBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, DRS_Name__c, Account.DRS_Master__r.Name
            FROM Case
            WHERE DRS_Name__c = NULL
            AND Account.DRS_Master__r.Name != NULL
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Case> toUpdate = new List<Case>();

        for (Case c : scope) {
            if (c.Account != null && c.Account.DRS_Master__r != null) {
                c.DRS_Name__c = c.Account.DRS_Master__r.Name;
                c.To_be_Updated_in_SAP__c='false';
                toUpdate.add(c);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        
    }
}