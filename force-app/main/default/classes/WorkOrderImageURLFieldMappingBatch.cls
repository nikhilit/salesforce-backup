/**
 * @description       : Batch class to assign WorkOrder image URLs based on chronological order of attachments
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 27-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   27-01-2026   Kartik Patkar, Appstrail   Initial Version
 **/
public class WorkOrderImageURLFieldMappingBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private List<String> IMAGE_FIELDS = new List<String>();
    private String query;

    public WorkOrderImageURLFieldMappingBatch() {
        loadMetadataFields();
        buildQuery();
    }
    
    public WorkOrderImageURLFieldMappingBatch(String whereClause) {
        loadMetadataFields();
        buildQuery(whereClause);
    }
    
    // ✅ Load metadata-driven fields
    private void loadMetadataFields() {
        IMAGE_FIELDS.clear(); // Clear to prevent duplicates
        Set<String> fieldSet = new Set<String>(); // Use set to ensure uniqueness
        
        for (ImageFieldMapping__mdt cfg :
        [SELECT Field_API_Names__c
             FROM ImageFieldMapping__mdt
             WHERE Object_API_Name__c = 'WorkOrder']) {
            
            if (String.isNotBlank(cfg.Field_API_Names__c)) {
                for (String f : cfg.Field_API_Names__c.split(',')) {
                    fieldSet.add(f.trim());
                }
            }
        }
        
        IMAGE_FIELDS.addAll(fieldSet);
    }
    
    // ✅ Build SOQL
    private void buildQuery(String whereClause) {
        String fieldList = String.join(IMAGE_FIELDS, ',');
        query = 'SELECT Id, ' + fieldList + ' FROM WorkOrder ' + whereClause;
    }
    
    private void buildQuery() {
        buildQuery('');
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<WorkOrder> scope) {
        System.debug('scope: ' + scope);
        System.debug('IMAGE_FIELDS: ' + IMAGE_FIELDS);
        
        Set<Id> woIds = new Set<Id>();
        for (WorkOrder wo : scope) woIds.add(wo.Id);

        // ✅ Fetch Content Document Links ordered by creation date (oldest to newest)
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId,
                   LinkedEntityId,
                   ContentDocument.Title,
                   ContentDocument.LatestPublishedVersionId,
                   ContentDocument.CreatedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :woIds
            ORDER BY LinkedEntityId, ContentDocument.CreatedDate ASC
        ];

        // ✅ Group ContentDocuments by WorkOrder (maintaining chronological order)
        Map<Id, List<ContentDocument>> woToDocs = new Map<Id, List<ContentDocument>>();
        for (ContentDocumentLink cdl : links) {
            if (!woToDocs.containsKey(cdl.LinkedEntityId)) {
                woToDocs.put(cdl.LinkedEntityId, new List<ContentDocument>());
            }
            woToDocs.get(cdl.LinkedEntityId).add(cdl.ContentDocument);
        }

        List<WorkOrder> updates = new List<WorkOrder>();

        // ✅ Assign URLs to WorkOrder based on chronological order
        for (WorkOrder wo : scope) {

            // Clear all image fields before assigning
            for (String f : IMAGE_FIELDS) {
                wo.put(f, null);
            }

            if (!woToDocs.containsKey(wo.Id)) {
                updates.add(wo);
                continue;
            }

            List<ContentDocument> docs = woToDocs.get(wo.Id);
            
            // ✅ Assign each document to the corresponding field index based on chronological order
            for (Integer i = 0; i < docs.size() && i < IMAGE_FIELDS.size(); i++) {
                ContentDocument cd = docs[i];
                String url = '/sfc/servlet.shepherd/version/download/' + cd.LatestPublishedVersionId;
                wo.put(IMAGE_FIELDS[i], url);
            }

            updates.add(wo);
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('✅ WorkOrder Image URL Field Mapping Batch Completed.');
    }
}