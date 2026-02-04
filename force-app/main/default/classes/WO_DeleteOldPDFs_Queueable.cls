/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 30-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   21-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
public without sharing class WO_DeleteOldPDFs_Queueable implements Queueable, Database.AllowsCallouts {

    List<Id> woIds;
    String jobKey;

    public WO_DeleteOldPDFs_Queueable(List<Id> woIds){
        this.woIds = woIds;
    }
    
    public WO_DeleteOldPDFs_Queueable(List<Id> woIds, String jobKey){
        this.woIds = woIds;
        this.jobKey = jobKey;
    }

    public void execute(QueueableContext qc){

        System.debug(LoggingLevel.WARN, '[WO Progress] WO_DeleteOldPDFs_Queueable start. woIds=' + (woIds == null ? 0 : woIds.size()) + ', jobKey=' + jobKey);
        
        // Update job status
        if(jobKey != null){
            System.debug(LoggingLevel.WARN, '[WO Progress] WO_DeleteOldPDFs_Queueable publishing step 1/4');
            WorkOrderBulkApprovalController.updateJobStatus(jobKey, 'Verifying...', 1, 4);
        } else {
            System.debug(LoggingLevel.WARN, '[WO Progress] WO_DeleteOldPDFs_Queueable jobKey is NULL - no Platform Event will be published');
        }

        List<ContentDocumentLink> existingLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :woIds
            AND (ContentDocument.Title LIKE 'Live_Update_%' 
                 OR ContentDocument.Title LIKE '%_JT_%')
        ];

        Set<Id> docIds = new Set<Id>();
        for(ContentDocumentLink cdl : existingLinks){
            docIds.add(cdl.ContentDocumentId);
        }

        if(!docIds.isEmpty()){
            List<ContentDocument> docs = [
                SELECT Id FROM ContentDocument WHERE Id IN :docIds
            ];
            delete docs;
        }

        // Chain next job
        if (Test.isRunningTest()) {
            return;
        }
        System.debug(LoggingLevel.WARN, '[WO Progress] WO_DeleteOldPDFs_Queueable enqueue next WO_GeneratePDFs_Queueable. jobKey=' + jobKey);
        System.enqueueJob(new WO_GeneratePDFs_Queueable(woIds, jobKey));
    }
}