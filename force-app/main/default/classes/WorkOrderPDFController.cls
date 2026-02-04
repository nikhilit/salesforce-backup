// File: WorkOrderPDFController.cls
public with sharing class WorkOrderPDFController {
    public List<WorkOrder> workOrders { get; set; }

    public WorkOrderPDFController() {
        String ids = ApexPages.currentPage().getParameters().get('ids');
        workOrders = [SELECT Id, Subject, Status, Description FROM WorkOrder WHERE Id IN :ids.split(',')];
    }

    @AuraEnabled
    public static void generateAndAttachPDF(List<Id> workOrderIds) {
        List<ContentVersion> versions = new List<ContentVersion>();

        for (Id woId : workOrderIds) {
            try {
                PageReference pdfPage = Page.WorkOrderPDF;
                pdfPage.getParameters().put('ids', woId);
                Blob pdfBlob = pdfPage.getContent();

                ContentVersion version = new ContentVersion();
                version.Title = 'WorkOrder_' + woId;
                version.PathOnClient = 'WorkOrder_' + woId + '.pdf';
                version.VersionData = pdfBlob;
                version.Description = 'Auto-generated Work Order PDF';
                version.FirstPublishLocationId = woId;
                versions.add(version);
            } catch (Exception e) {
                System.debug('Error generating PDF for ' + woId + ': ' + e.getMessage());
            }
        }

        if (!versions.isEmpty()) {
            insert versions;
        }
    }
}