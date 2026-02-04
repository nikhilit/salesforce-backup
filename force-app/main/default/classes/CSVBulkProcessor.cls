public without sharing class CSVBulkProcessor implements Database.Batchable<String>, Database.Stateful {
    private Id contentVersionId;
    private Id statusRecordId;
    private Integer chunkSize = 2000;

    public CSVBulkProcessor(Id contentVersionId, Id statusRecordId, Integer chunkSize) {
        this.contentVersionId = contentVersionId;
        this.statusRecordId = statusRecordId;
        if (chunkSize != null && chunkSize > 0) this.chunkSize = chunkSize;
    }

    public Iterable<String> start(Database.BatchableContext bc) {
        return new CSVBulkChunkIterable(contentVersionId, chunkSize);
    }

    public void execute(Database.BatchableContext bc, List<String> scope) {
        for (String chunkPayload : scope) {
            List<String> rows = chunkPayload.split('\\n');
            List<WorkOrder> toInsert = new List<WorkOrder>();

            // Skip header if this is the first chunk and header exists
            Boolean headerSkipped = false;

            for (String row : rows) {
                if (String.isBlank(row)) continue;

                // If the first row is the header, skip it
                if (!headerSkipped && row.toLowerCase().contains('subject')) {
                    headerSkipped = true;
                    continue;
                }

                List<String> cols = row.split(',');
                try {
                    WorkOrder wo = new WorkOrder();

                    // --- Map CSV columns to WorkOrder fields ---
                    // CSV Format: Subject, Description, Status, Priority, WorkTypeId, AccountId, AssetId, Street, City
                    wo.Subject = cols.size() > 0 ? cols[0].trim() : null;
                    wo.Description = cols.size() > 1 ? cols[1].trim() : null;
                    wo.Status = cols.size() > 2 ? cols[2].trim() : 'New';
                    wo.Priority = cols.size() > 3 ? cols[3].trim() : 'Medium';

                    // Optional foreign key lookups can be adjusted per your org
                    if (cols.size() > 4 && !String.isBlank(cols[4])) wo.WorkTypeId = cols[4].trim();
                    if (cols.size() > 5 && !String.isBlank(cols[5])) wo.AccountId = cols[5].trim();
                    if (cols.size() > 6 && !String.isBlank(cols[6])) wo.AssetId = cols[6].trim();

                    // Example: set some location info in Address fields (if enabled)
                    if (cols.size() > 7 && !String.isBlank(cols[7])) wo.Street = cols[7].trim();
                    if (cols.size() > 8 && !String.isBlank(cols[8])) wo.City = cols[8].trim();

                    toInsert.add(wo);
                } catch (Exception e) {
                    System.debug('Row parse error: ' + e.getMessage());
                }
            }

            if (!toInsert.isEmpty()) {
                Database.SaveResult[] results = Database.insert(toInsert, false);
                Integer successCount = 0;
                Integer failureCount = 0;

                for (Database.SaveResult r : results) {
                    if (r.isSuccess()) successCount++;
                    else failureCount++;
                }
                updateProgress(results.size(), successCount, failureCount);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        try {
            BulkImportStatus__c s = [SELECT Id, Status__c FROM BulkImportStatus__c WHERE Id = :statusRecordId LIMIT 1];
            s.Status__c = 'Completed';
            update s;
        } catch (Exception e) {
            System.debug('Error in finish: ' + e.getMessage());
        }
    }

    private void updateProgress(Integer processedDelta, Integer successDelta, Integer failureDelta) {
        try {
            BulkImportStatus__c current = [
                SELECT Id, Processed_Rows__c, Success_Count__c, Failure_Count__c
                FROM BulkImportStatus__c WHERE Id = :statusRecordId LIMIT 1
            ];
            current.Processed_Rows__c = (current.Processed_Rows__c == null ? 0 : current.Processed_Rows__c) + processedDelta;
            current.Success_Count__c = (current.Success_Count__c == null ? 0 : current.Success_Count__c) + successDelta;
            current.Failure_Count__c = (current.Failure_Count__c == null ? 0 : current.Failure_Count__c) + failureDelta;
            update current;
        } catch (Exception e) {
            System.debug('Progress update failed: ' + e.getMessage());
        }
    }
}