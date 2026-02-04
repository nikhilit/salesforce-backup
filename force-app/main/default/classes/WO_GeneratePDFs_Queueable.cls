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
public without sharing class WO_GeneratePDFs_Queueable implements Queueable, Database.AllowsCallouts {

    List<Id> woIds;
    String jobKey;

    public WO_GeneratePDFs_Queueable(List<Id> woIds){
        this.woIds = woIds;
    }
    
    public WO_GeneratePDFs_Queueable(List<Id> woIds, String jobKey){
        this.woIds = woIds;
        this.jobKey = jobKey;
    }

    public void execute(QueueableContext qc){

        System.debug(LoggingLevel.WARN, '[WO Progress] WO_GeneratePDFs_Queueable start. woIds=' + (woIds == null ? 0 : woIds.size()) + ', jobKey=' + jobKey);
        
        // Update job status
        if(jobKey != null){
            System.debug(LoggingLevel.WARN, '[WO Progress] WO_GeneratePDFs_Queueable publishing step 2/4');
            WorkOrderBulkApprovalController.updateJobStatus(jobKey, 'Generating PDFs...', 2, 4);
        } else {
            System.debug(LoggingLevel.WARN, '[WO Progress] WO_GeneratePDFs_Queueable jobKey is NULL - no Platform Event will be published');
        }

        List<WorkOrder> wos = [
            SELECT Id, Account.BP_Number__c, Account.Name,
                   From_Date__c, To_Date__c,
                   Customer_Representative__c, BP_Number__c
            FROM WorkOrder
            WHERE Id IN :woIds
        ];

        List<ContentVersion> versions = new List<ContentVersion>();

        for(WorkOrder wo : wos){

            PageReference page1 = Page.JointTicketPdf;
            page1.getParameters().put('id', wo.Id);

            Blob blob1 = Test.isRunningTest() ? Blob.valueOf('test')
                            : page1.getContentAsPDF();

            String fileName1 =
                (wo.Customer_Representative__c != null ? wo.Customer_Representative__c : 'Unknown') + '_JT_' +
                (wo.BP_Number__c != null ? wo.BP_Number__c : 'NA') + '_' + 
                (wo.Account != null && wo.Account.Name != null ? wo.Account.Name : 'Unknown') + '_' +
                (wo.From_Date__c != null ? wo.From_Date__c.format() : 'NA') + '_' + 
                (wo.To_Date__c != null ? wo.To_Date__c.format() : 'NA') + '.pdf';

            versions.add(new ContentVersion(
                Title = fileName1,
                PathOnClient = 'JT1.pdf',
                VersionData = blob1
            ));

            PageReference page2 = Page.JointTicketPdf2;
            page2.getParameters().put('id', wo.Id);
            Blob blob2 = Test.isRunningTest() ? Blob.valueOf('test')
                            : page2.getContentAsPDF();

            String bpNumber = (wo.Account != null && wo.Account.BP_Number__c != null) 
                              ? wo.Account.BP_Number__c : 'NA';
            String fromDate = (wo.From_Date__c != null) ? wo.From_Date__c.format() : 'NA';
            String toDate = (wo.To_Date__c != null) ? wo.To_Date__c.format() : 'NA';

            versions.add(new ContentVersion(
                Title = 'Live_Update_' + bpNumber + '_' + fromDate + '_' + toDate + '.pdf',
                PathOnClient = 'JT2.pdf',
                VersionData = blob2
            ));
        }

        insert versions;
        
        List<Id> versionIds=new List<Id>();
        for(ContentVersion ver:versions){
            versionIds.add(ver.Id);
        }

        // chain next job
        if (Test.isRunningTest()) {
            return;
        }
        System.debug(LoggingLevel.WARN, '[WO Progress] WO_GeneratePDFs_Queueable enqueue next WO_CreateLinks_Queueable. jobKey=' + jobKey);
        System.enqueueJob(new WO_CreateLinks_Queueable(woIds, versionIds, jobKey));
    }
}