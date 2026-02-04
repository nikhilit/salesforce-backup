// public without sharing class BulkCaseCreationForBPs {

//     @AuraEnabled
//     public static String insertCases(List<Map<String, String>> rows) {
//         if (rows == null || rows.isEmpty()) {
//             return null;
//         }

//         Id jobId = System.enqueueJob(
//             new BulkCaseQueueable(rows, 0)
//         );

//         return String.valueOf(jobId);
//     }
// }


public without sharing class BulkCaseCreationForBPs {

    @AuraEnabled
    public static String insertCases(List<Map<String, String>> rows) {

        if (rows == null || rows.isEmpty()) {
            return null;
        }

        // Batch size = 180 (safe with triggers, milestones, flows)
        Id batchJobId = Database.executeBatch(
            new BulkCaseCreationBatch(rows),
            180
        );

        return String.valueOf(batchJobId);
    }
}