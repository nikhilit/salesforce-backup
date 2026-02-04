public with sharing class WorkOrderPDFGenerator {
    @AuraEnabled
    public static void generateAndAttachPDFs(List<Id> workOrderIds) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for (Id woId : workOrderIds) {
            PageReference pdfPage = Page.WorkOrderPDF;
            pdfPage.getParameters().put('id', woId);
            Blob pdfBlob = pdfPage.getContentAsPDF();

            WorkOrder wo = [SELECT WorkOrderNumber FROM WorkOrder WHERE Id = :woId LIMIT 1];

            ContentVersion cv = new ContentVersion(
                Title = 'WorkOrder_' + wo.WorkOrderNumber,
                PathOnClient = 'WorkOrder_' + wo.WorkOrderNumber + '.pdf',
                VersionData = pdfBlob,
                IsMajorVersion = true
            );
            contentVersions.add(cv);
        }

        insert contentVersions;

        List<ContentDocumentLink> docLinks = new List<ContentDocumentLink>();

        for (ContentVersion cv : [
            SELECT Id, ContentDocumentId, Title 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ]) {
            ContentDocumentLink link = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = [SELECT Id FROM WorkOrder WHERE WorkOrderNumber = :cv.Title.replace('WorkOrder_', '') LIMIT 1].Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            docLinks.add(link);
        }

        insert docLinks;
    }
}