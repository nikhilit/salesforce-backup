global class CaseSAPBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Run the CaseSAPBatch with a batch size of 200
        Database.executeBatch(new CaseSAPBatch(), 200);
    }
}