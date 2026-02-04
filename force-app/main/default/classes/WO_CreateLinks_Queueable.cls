/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 30-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   22-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
public class WO_CreateLinks_Queueable implements Queueable {

    List<Id> woIds;
    List<Id> versionIds;
    String jobKey;

    public WO_CreateLinks_Queueable(List<Id> woIds, List<Id> versionIds){
        this.woIds = woIds;
        this.versionIds = versionIds;
    }
    
    public WO_CreateLinks_Queueable(List<Id> woIds, List<Id> versionIds, String jobKey){
        this.woIds = woIds;
        this.versionIds = versionIds;
        this.jobKey = jobKey;
    }

    public void execute(QueueableContext qc){

        System.debug(LoggingLevel.WARN, '[WO Progress] WO_CreateLinks_Queueable start. woIds=' + (woIds == null ? 0 : woIds.size()) + ', versionIds=' + (versionIds == null ? 0 : versionIds.size()) + ', jobKey=' + jobKey);
        
        // Update job status - Linking PDFs
        if(jobKey != null){
            System.debug(LoggingLevel.WARN, '[WO Progress] WO_CreateLinks_Queueable publishing step 3/4');
            WorkOrderBulkApprovalController.updateJobStatus(jobKey, 'Linking PDFs to Work Orders...', 3, 4);
        } else {
            System.debug(LoggingLevel.WARN, '[WO Progress] WO_CreateLinks_Queueable jobKey is NULL - no Platform Event will be published');
        }

        if(versionIds == null || versionIds.isEmpty()){
            System.debug('No version IDs passed.');
            return;
        }

        // Query ContentDocumentIds freshly
        Map<Id, Id> versionToDoc = new Map<Id, Id>();
        for(ContentVersion cv : [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :versionIds
        ]){
            versionToDoc.put(cv.Id, cv.ContentDocumentId);
        }

        if(versionToDoc.isEmpty()) return;

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        Integer index = 0;

        for(Id woId : woIds){

            links.add(new ContentDocumentLink(
                LinkedEntityId = woId,
                ContentDocumentId = versionToDoc.get(versionIds[index]),
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
            index++;

            links.add(new ContentDocumentLink(
                LinkedEntityId = woId,
                ContentDocumentId = versionToDoc.get(versionIds[index]),
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
            index++;
        }

        insert links;
        
        // Update job status - Completed
        if(jobKey != null){
            System.debug(LoggingLevel.WARN, '[WO Progress] WO_CreateLinks_Queueable publishing step 4/4 (Completed)');
            WorkOrderBulkApprovalController.updateJobStatus(jobKey, 'Completed', 4, 4);
        }

        // Run batch with chunk size = 40
        // Database.executeBatch(new WO_UpdateSendEmail_Batch(woIds), 40);


        // List<WorkOrder> wos = [SELECT Id FROM WorkOrder WHERE Id IN :woIds];
        // for(WorkOrder wo : wos){
        //     wo.Send_Email__c = true;
        // }
        // update wos;
    }
}