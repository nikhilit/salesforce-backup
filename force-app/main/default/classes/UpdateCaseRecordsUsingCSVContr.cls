public with sharing class UpdateCaseRecordsUsingCSVContr implements Queueable {

    private Id contentDocumentId;
    private Integer batchSize;

    // Constructor
    public UpdateCaseRecordsUsingCSVContr(Id contentDocumentId, Integer batchSize) {
        this.contentDocumentId = contentDocumentId;
        this.batchSize = batchSize != null ? batchSize : 200;
    }

    // Queueable execute method
    public void execute(QueueableContext context) {
        List<Case> allCasesToUpdate = new List<Case>();

        try {
            // Step 1: Read CSV file from ContentVersion
            ContentVersion cv = [
                SELECT VersionData 
                FROM ContentVersion 
                WHERE ContentDocumentId = :contentDocumentId
                ORDER BY VersionNumber DESC
                LIMIT 1
            ];

            String fileBody = cv.VersionData.toString();
            List<String> lines = fileBody.split('\n');

            if (lines.size() <= 1) {
                System.debug('CSV is empty or only header found.');
                return;
            }

            // Step 2: Parse CSV lines
            for (Integer i = 1; i < lines.size(); i++) {
                String line = lines[i].trim();
                if (String.isBlank(line)) continue;

                List<String> row = line.split(',');

                Case cs = new Case();

                if (row.size() > 0 && String.isNotBlank(row[0])) cs.Id = row[0].trim();
                if (row.size() > 1 && String.isNotBlank(row[1])) cs.Work_Order_ID__c = row[1].trim();
                if (row.size() > 2 && String.isNotBlank(row[2])) cs.Approval_Status_AIC__c = row[2].trim();
                if (row.size() > 3 && String.isNotBlank(row[3])) cs.Standard_Remarks__c = row[3].trim();
                if (row.size() > 4 && String.isNotBlank(row[4])) cs.Move_Out_Date_BP__c = Date.valueOf(row[4].trim());

                if (cs.Id != null) allCasesToUpdate.add(cs);
            }

            // Step 3: Batch update manually
            Integer total = allCasesToUpdate.size();
            for (Integer i = 0; i < total; i += batchSize) {
                List<Case> batchToUpdate = new List<Case>();
                for (Integer j = i; j < i + batchSize && j < total; j++) {
                    batchToUpdate.add(allCasesToUpdate[j]);
                }
                update batchToUpdate;
            }

            System.debug(total + ' Case records updated successfully.');

        } catch (Exception e) {
            System.debug('Error processing CSV: ' + e.getMessage() + ' -- ' + e.getStackTraceString());
        }
    }

    // Static helper method to enqueue job
    @AuraEnabled
    public static String enqueueCSVProcessing(Id contentDocumentId) {
        try {
            System.enqueueJob(new UpdateCaseRecordsUsingCSVContr(contentDocumentId, 200));
            return 'CSV processing has been enqueued successfully.';
        } catch (Exception e) {
            return 'Error enqueueing CSV job: ' + e.getMessage();
        }
    }
}