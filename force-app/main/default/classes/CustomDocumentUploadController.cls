public with sharing class CustomDocumentUploadController {

    @AuraEnabled(cacheable=true)
    public static List<DocumentWrapper> getCaseDocuments(String caseId) {
        System.debug('🎯 getCaseDocuments called with caseId: ' + caseId);
        
        List<DocumentWrapper> result = new List<DocumentWrapper>();

        if (String.isBlank(caseId)) {
            System.debug('⚠️ Empty caseId provided');
            return result;
        }

        try {
            List<ContentDocumentLink> documentLinks = [
                SELECT 
                    ContentDocumentId,
                    ContentDocument.Title,
                    ContentDocument.FileExtension,
                    ContentDocument.LatestPublishedVersionId,
                    ContentDocument.CreatedDate
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :caseId
                ORDER BY ContentDocument.CreatedDate DESC
            ];

            System.debug('📊 Found ' + documentLinks.size() + ' document links');
            
            for (ContentDocumentLink cdl : documentLinks) {
                System.debug('📄 Document: ' + cdl.ContentDocument.Title + 
                           ' (ID: ' + cdl.ContentDocumentId + ')');
                
                result.add(new DocumentWrapper(
                    cdl.ContentDocumentId,
                    cdl.ContentDocument.Title,
                    cdl.ContentDocument.FileExtension,
                    cdl.ContentDocument.LatestPublishedVersionId
                ));
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('❌ Error in getCaseDocuments: ' + e.getMessage() + 
                       ' at line ' + e.getLineNumber());
            throw new AuraHandledException('Error retrieving documents: ' + e.getMessage());
        }
    }

@AuraEnabled
public static String getPreviewUrl(String contentVersionId, String fileExtension) {
    String baseUrl = URL.getOrgDomainUrl().toExternalForm();
    String fileExt = fileExtension != null ? fileExtension.toLowerCase() : '';
    
    // Use the same pattern as your reference code
    return baseUrl + '/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=' + contentVersionId;
}

    public class DocumentWrapper {
        @AuraEnabled public String ContentDocumentId { get; set; }
        @AuraEnabled public String Title { get; set; }
        @AuraEnabled public String FileExtension { get; set; }
        @AuraEnabled public String LatestPublishedVersionId { get; set; }

        public DocumentWrapper(
            String docId,
            String title,
            String ext,
            String versionId
        ) {
            this.ContentDocumentId = docId;
            this.Title = title;
            this.FileExtension = ext;
            this.LatestPublishedVersionId = versionId;
        }
    }
}