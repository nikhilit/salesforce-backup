global class BatchDeleteWorkOrders implements Database.Batchable<SObject>, Database.Stateful {
    
    // Query to select WorkOrders
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id 
            FROM WorkOrder 
            WHERE RecordType.Name = 'MGL R&T' 
              AND CreatedBy.Name = 'Automated User1'
              AND CreatedDate >= 2026-01-14T00:00:00Z
              AND CreatedDate < 2026-01-15T00:00:00Z
        ]);
    }
    
    // Delete each batch
    global void execute(Database.BatchableContext BC, List<WorkOrder> scope) {
        try {
            delete scope;
            System.debug('Deleted ' + scope.size() + ' WorkOrders');
        } catch (DmlException e) {
            System.debug('Error deleting WorkOrders: ' + e.getMessage());
        }
    }
    
    // Finish method (optional, for logging or chaining jobs)
    global void finish(Database.BatchableContext BC) {
        System.debug('BatchDeleteWorkOrders finished.');
    }
}