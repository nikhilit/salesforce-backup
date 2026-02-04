/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 15-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   15-01-2026   Kartik Patkar, Appstrail   Initial Version
**/
public without sharing class ContentDocumentLinkHelper {
    
    // ✅ Prevent recursion with static variable
    private static Boolean isExecuting = false;
    
    public static void afterInsert(List<ContentDocumentLink> newList){
        // ✅ Check if already executing to prevent recursion
        if(isExecuting) {
            System.debug('ContentDocumentLinkHelper: Skipping execution to prevent recursion');
            return;
        }
        
        isExecuting = true;
        try {

            List<ContentDocumentLink> cdlToProcess = new List<ContentDocumentLink>();
            String documentPrefix = Schema.getGlobalDescribe().get('Document__c').getDescribe().getKeyPrefix();
            System.debug('🔵 Document__c Key Prefix: ' + documentPrefix);

            for(ContentDocumentLink cdl : newList){
                if(cdl.LinkedEntityId != null && cdl.ContentDocumentId != null){
                    String linkedIdPrefix = String.valueOf(cdl.LinkedEntityId).substring(0,3);
                    System.debug('🔵 Linked Entity ID Prefix: ' + linkedIdPrefix);
                    
                    if(linkedIdPrefix == documentPrefix){
                        cdlToProcess.add(cdl);
                    }
                }
            }

            if( cdlToProcess.isEmpty()) {
                return;
            }
            updateDocumentRecordsStatus(cdlToProcess);
        } finally {
            isExecuting = false;
        }
    }

    public static void updateDocumentRecordsStatus(List<ContentDocumentLink> newList){
        Set<Id> docIds = new Set<Id>();
        Set<Id> contentDocIds = new Set<Id>();
        
        for(ContentDocumentLink cdl : newList){
            if(cdl.LinkedEntityId != null && cdl.ContentDocumentId != null){
                docIds.add(cdl.LinkedEntityId);
                contentDocIds.add(cdl.ContentDocumentId);
            }
        }
        
        if(!docIds.isEmpty()){
            
            // ✅ Query Document__c records that need status update
            List<Document__c> meterDocsToUpdate = [
                SELECT Id, Upload_Status__c 
                FROM Document__c 
                WHERE Id IN :docIds 
                AND Upload_Status__c != 'Uploaded' 
                AND Upload_Status__c != 'Pending'
                AND Work_Order__r.RecordType.DeveloperName = 'MGL_Metering'
            ];

            if(meterDocsToUpdate.isEmpty()) {
                return;
            }
            
            // ✅ Update to Pending directly (only once)
            for(Document__c doc : meterDocsToUpdate){
                doc.Upload_Status__c = 'Pending';
            }
            
            update meterDocsToUpdate;
            System.debug('Updated ' + meterDocsToUpdate.size() + ' Document__c records to Pending status');
        }
    }
    public static void sharewithpartnerusers(List<ContentDocumentLink> newList){
    List<ContentDocumentLink> cdlsToUpdate = new List<ContentDocumentLink>();

    for (ContentDocumentLink cdl : newList) {

        // Check if linked record is Scheme__c
        if (cdl.LinkedEntityId != null &&
            String.valueOf(cdl.LinkedEntityId).startsWith(
                Schema.Scheme__c.SObjectType.getDescribe().getKeyPrefix()
            )
        ) {
            cdlsToUpdate.add(
                new ContentDocumentLink(
                    Id = cdl.Id,
                    Visibility = 'AllUsers'
                )
            );
        }
    }

    if (!cdlsToUpdate.isEmpty()) {
        update cdlsToUpdate;
    }
}

}