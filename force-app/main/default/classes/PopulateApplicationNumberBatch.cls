public class PopulateApplicationNumberBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, ID_Number__c, Type_Desc__c, BP__c, 
                   BP__r.Application_Number__c
            FROM Identification_Number__c
            WHERE Type_Desc__c = 'Application Form'
             AND BP__c != null
			AND LastModifiedDate = LAST_N_DAYS:2
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Identification_Number__c> scope) {
        Map<Id, String> bpIdToAppNumber = new Map<Id, String>();

        for (Identification_Number__c record : scope) {
            if (record.BP__c != null) {
                if (record.BP__r.Application_Number__c != record.ID_Number__c) {
                    bpIdToAppNumber.put(record.BP__c, record.ID_Number__c);
                }
            }
        }

        List<Account> bpToUpdate = new List<Account>();

        for (Id bpId : bpIdToAppNumber.keySet()) {
            bpToUpdate.add(new Account(
                Id = bpId,
                Application_Number__c = bpIdToAppNumber.get(bpId)
            ));
        }

        if (!bpToUpdate.isEmpty()) {
            update bpToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('PopulateApplicationNumberBatch completed.');
    }
}