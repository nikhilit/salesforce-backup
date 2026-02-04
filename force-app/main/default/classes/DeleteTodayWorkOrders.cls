global class DeleteTodayWorkOrders implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Fetch WorkOrders created today
        return Database.getQueryLocator(
            'SELECT Id FROM WorkOrder WHERE CreatedDate = TODAY'
        );
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        // Delete each batch
        delete scope;
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch Delete Completed');
    }
}