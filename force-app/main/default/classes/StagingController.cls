public class StagingController {
    public Staging__c record {get; set;}
    public StagingController(ApexPages.StandardController std) {
        record = (Staging__c)std.getRecord();
    }
    public void startBatch() {
        record.Status__c = 'Processing';
        update record;
        Id batchId = Database.executeBatch(new CSVProcessorBatch(record.Id), 200); // Batch size 200
    }
}