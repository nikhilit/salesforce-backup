/**
* @File Name : CSVBulkController.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : October 5, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | October 5, 2025 |   | Initial Version
**/

public without sharing class CSVBulkController {
    /**
     * Called from LWC after file upload
     * Starts the batch job for CSV processing
     */
    @AuraEnabled
    public static Id startProcessing(Id contentVersionId) {
        if (contentVersionId == null) {
            throw new AuraHandledException('contentVersionId is required');
        }

        // Create status tracker record
        BulkImportStatus__c status = new BulkImportStatus__c(
            Name = 'CSV Import ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss'),
            ContentVersionId__c = contentVersionId,
            Status__c = 'Queued',
            Total_Rows__c = 0,
            Processed_Rows__c = 0,
            Success_Count__c = 0,
            Failure_Count__c = 0
        );
        insert status;

        // Launch the batch
        CSVBulkProcessor batch = new CSVBulkProcessor(contentVersionId, status.Id, 2000);
        Id batchJobId = Database.executeBatch(batch, 1);

        // Update tracker
        status.BatchJobId__c = (String)batchJobId;
        status.Status__c = 'Processing';
        update status;

        return status.Id;
    }

    /**
     * LWC polls this method every few seconds to fetch status
     */
    @AuraEnabled(cacheable=true)
    public static BulkImportStatus__c getStatus(Id batchJobId) {
        if (batchJobId == null) return null;
        return [
            SELECT Id, Name, Status__c, Total_Rows__c, Processed_Rows__c, 
                   Success_Count__c, Failure_Count__c, Error_File_Id__c
            FROM BulkImportStatus__c
            WHERE Id = :batchJobId
            LIMIT 1
        ];
    }
}