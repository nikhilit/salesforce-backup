global class OMWorkOrderBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new OMWorkOrderAllocationBatch(), 50);
    }
}