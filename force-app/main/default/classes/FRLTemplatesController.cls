public with sharing class FRLTemplatesController {
    @AuraEnabled(cacheable=true)
    public static FRL_Template__c getTemplateById(Id templateId) {
        return [
            SELECT Id, Name, Body__c
            FROM FRL_Template__c
            WHERE Id = :templateId
            LIMIT 1
        ];
    }
    @AuraEnabled
    public static Id insertTemplateData(String templateBody) {
        if (String.isBlank(templateBody)) {
            throw new AuraHandledException('Template body cannot be blank.');
        }

        FRL_Template_Data__c data = new FRL_Template_Data__c(
            Template_Body__c = templateBody
        );
        
        insert data;
        
        System.debug('Inserted FRL_Template_Data__c with ID: ' + data.Id);
        return data.Id; // Return the ID for the next step
    }
@AuraEnabled
public static void generatePDF(Id caseId, String dataId, String templateName) {
    try {
        
        Blob pdfBlob;
        // Skip getContent() in tests
        if (!Test.isRunningTest()) {
            // PageReference pdfPage = Page.FRL_PDFGeneratorPage;
            PageReference pdfPage;
            if (templateName == 'Refund Template') {
                pdfPage = Page.FRL_PDFGeneratorPageV2; // <-- your V2 VF page
            } else {
                pdfPage = Page.FRL_PDFGeneratorPage;   // <-- existing VF page
            }
            pdfPage.getParameters().put('caseId', caseId);
            pdfPage.getParameters().put('dataId', dataId);
            pdfBlob = pdfPage.getContent();
            
            
        } else {
            // Dummy blob for testing
            pdfBlob = Blob.valueOf('Dummy PDF content for test');
        }

       ContentVersion cv = new ContentVersion(
            Title = 'Generated_Template_' + Datetime.now().getTime(),
            PathOnClient = 'Template.pdf',
            VersionData = pdfBlob,
            IsMajorVersion = true
        );
        insert cv;

        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = caseId,
            ShareType = 'V'
        );
        insert cdl;
        
        List<FRL_Template_Data__c> frl =[SELECT Id FROM FRL_Template_Data__c where id=:dataId];
        delete frl;
        
    }
    catch (Exception e) {
        throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
    }
}

}