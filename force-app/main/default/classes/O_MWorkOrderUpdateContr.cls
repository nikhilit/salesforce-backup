/**
* @File Name : O_MWorkOrderUpdateContr.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : June 11, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | June 11, 2025 |   | Initial Version
**/

public class O_MWorkOrderUpdateContr {
	
	public static void deleteDocumentsAfterReject(List<Id> workOrderIds) {
        if (workOrderIds.isEmpty()) return;

        // Query ContentDocumentLink with non-empty document type
        List<ContentDocumentLink> linksToDelete = [
            SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :workOrderIds
            AND ContentDocument.LatestPublishedVersion.O_M_Document_Types__c != null
            AND ContentDocument.LatestPublishedVersion.O_M_Document_Types__c != ''
        ];

        // Delete the links (this unlinks documents from Work Orders)
        if (!linksToDelete.isEmpty()) {
            delete linksToDelete;
        }
    }
}