public class BulkCaseCreationBatch
    implements Database.Batchable<Map<String, String>> {

    private List<Map<String, String>> allRows;

    public BulkCaseCreationBatch(List<Map<String, String>> rows) {
        this.allRows = rows;
    }

    public Iterable<Map<String, String>> start(
        Database.BatchableContext bc
    ) {
        System.debug('Batch started. Total rows = ' + allRows.size());
        return allRows;
    }

    public void execute(
        Database.BatchableContext bc,
        List<Map<String, String>> scope
    ) {
        System.debug('Processing batch of size = ' + scope.size());
        BulkCaseCreationForBPs_Processor.process(scope);
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch completed successfully');
    }
}