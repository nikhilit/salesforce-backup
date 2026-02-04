public class BulkCaseQueueable implements Queueable {

    private List<Map<String, String>> rows;
    private Integer startIndex;

    private static final Integer CHUNK_SIZE = 180; 

    public BulkCaseQueueable(List<Map<String, String>> rows, Integer startIndex) {
        this.rows = rows;
        this.startIndex = startIndex;
    }

    public void execute(QueueableContext qc) {

        Integer endIndex = Math.min(startIndex + CHUNK_SIZE, rows.size());
        List<Map<String, String>> chunk = new List<Map<String, String>>();

        for (Integer i = startIndex; i < endIndex; i++) {
            chunk.add(rows[i]);
        }

        System.debug(
            'Processing chunk from ' + startIndex + ' to ' + (endIndex - 1)
        );

        BulkCaseCreationForBPs_Processor.process(chunk);

        // Chain next job
        if (endIndex < rows.size()) {
            System.enqueueJob(
                new BulkCaseQueueable(rows, endIndex)
            );
        }
    }
}

// public class BulkCaseQueueable implements Queueable {

//     private List<Map<String, String>> rows;
//     private static final Integer CHUNK_SIZE = 100; // trigger-safe

//     public BulkCaseQueueable(List<Map<String, String>> rows) {
//         this.rows = rows;
//     }

//     public void execute(QueueableContext qc) {

//         System.debug(
//             'BulkCaseQueueable started. Total rows = ' + rows.size()
//         );

//         // 🔹 Build context ONCE (single SOQL + describes)
//         BulkCaseCreationForBPs_Processor.Context ctx =
//             BulkCaseCreationForBPs_Processor.buildContext(rows);

//         Integer total = rows.size();

//         // 🔹 Manual chunking (Apex-safe)
//         for (Integer i = 0; i < total; i += CHUNK_SIZE) {

//             Integer endIndex = Math.min(i + CHUNK_SIZE, total);
//             List<Map<String, String>> chunk = new List<Map<String, String>>();

//             for (Integer j = i; j < endIndex; j++) {
//                 chunk.add(rows[j]);
//             }

//             System.debug(
//                 'Processing chunk ' + i + ' → ' + (endIndex - 1)
//             );

//             BulkCaseCreationForBPs_Processor.process(chunk, ctx);
//         }

//         System.debug('BulkCaseQueueable completed successfully');
//     }
// }