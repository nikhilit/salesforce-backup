global with sharing class DeleteUnAttemptedRandomVisits implements Database.Batchable<SObject>, Schedulable {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Payment_Remark__c
            FROM WorkOrder
            WHERE Status = 'New'
            AND CreatedDate = TODAY
            AND RecordType.Name = 'MGL R&T'
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<WorkOrder> scope) {
        List<WorkOrder> toDelete = new List<WorkOrder>();
        
        try {
            for (WorkOrder wo : scope) {
                if (wo.Payment_Remark__c != null &&
                wo.Payment_Remark__c.contains('Random Payment')) {
                    toDelete.add(wo);
                }
            }
            
            if (!toDelete.isEmpty()) {
                delete toDelete;
            }
        }catch (Exception e) {
            AS_ErrorLogger.log('DeleteUnAttemptedRandomVisits', 'execute', e.getMessage(), null);
        }
    }
    
    global void finish(Database.BatchableContext bc) {
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new DeleteUnAttemptedRandomVisits(), 200);
    }
}