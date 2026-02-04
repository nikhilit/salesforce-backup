public class UnifiedLookupQueueable implements Queueable, Database.AllowsCallouts, Schedulable {
    @TestVisible
    private List<String> objectNamesToProcess;
    @TestVisible
    private Integer currentIndex;

    public UnifiedLookupQueueable() {
        // Empty constructor to support scheduled run
    }

    public UnifiedLookupQueueable(List<String> objectNamesToProcess, Integer currentIndex) {
        this.objectNamesToProcess = objectNamesToProcess;
        this.currentIndex = currentIndex;
    }

    public void execute(QueueableContext context) {
        if (currentIndex >= objectNamesToProcess.size()) return;

        String objectName = objectNamesToProcess[currentIndex];
        // Enqueue the batch for the current object
        Database.executeBatch(new UnifiedLookupBatch(objectNamesToProcess, currentIndex, objectName), 2000);
    }

    // Schedulable execute
    public void execute(SchedulableContext sc) {
        List<String> defaultObjectList = new List<String>{
            'Identification_Number__c'
        };

        System.enqueueJob(new UnifiedLookupQueueable(defaultObjectList, 0));
    }
}