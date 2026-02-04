/**
 * @description       :
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 03-11-2025
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   03-11-2025   Kartik Patkar, Appstrail   Initial Version
 **/
public class WorkOrderImageBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private static List<String> IMAGE_FIELDS = new List<String>();
    private String query;
    
    public WorkOrderImageBatch() {
        loadMetadataFields();
        buildQuery();
    }
    
    public WorkOrderImageBatch(String whereClause) {
        loadMetadataFields();
        buildQuery(whereClause);
    }
    
    // ✅ Load metadata-driven fields
    private void loadMetadataFields() {
        for (ImageFieldMapping__mdt cfg :
        [SELECT Field_API_Names__c
             FROM ImageFieldMapping__mdt
             WHERE Object_API_Name__c = 'WorkOrder']) {
            
            if (String.isNotBlank(cfg.Field_API_Names__c)) {
                for (String f : cfg.Field_API_Names__c.split(',')) {
                    IMAGE_FIELDS.add(f.trim());
                }
            }
        }
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
        loadMetadataFields();
        System.debug('scope: ' + scope);
        System.debug('IMAGE_FIELDS: ' + IMAGE_FIELDS);
        Set<Id> woIds = new Set<Id>();
        for (WorkOrder wo : scope) woIds.add(wo.Id);

        // ✅ Fetch Content Document Links
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId,
                   LinkedEntityId,
                   ContentDocument.Title,
                   ContentDocument.LatestPublishedVersionId,
                   ContentDocument.CreatedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :woIds
            ORDER BY ContentDocument.CreatedDate ASC
        ];

        // ✅ Fetch Document Master mapping
        List<Document_Master__c> documentMasters = [
            SELECT Id, Document_Name__c, Type__c, Order__c, Compress_Image__c
            FROM Document_Master__c
            WHERE Active__c = TRUE
              AND Type__c = 'MRS Start Metering'
            ORDER BY Order__c ASC
        ];

        // ✅ Build case-sensitive mapping: Document Name → Order (1-based)
        Map<String, Integer> docNameToOrder = new Map<String, Integer>();
        for (Document_Master__c dm : documentMasters) {
            if (dm.Document_Name__c != null && dm.Order__c != null) {
                docNameToOrder.put(dm.Document_Name__c, Integer.valueOf(dm.Order__c));
            }
        }

        // ✅ Group ContentDocument objects by WorkOrder
        Map<Id, List<ContentDocument>> woToDocs = new Map<Id, List<ContentDocument>>();
        for (ContentDocumentLink cdl : links) {
            if (!woToDocs.containsKey(cdl.LinkedEntityId)) {
                woToDocs.put(cdl.LinkedEntityId, new List<ContentDocument>());
            }
            woToDocs.get(cdl.LinkedEntityId).add(cdl.ContentDocument);
        }

        List<WorkOrder> updates = new List<WorkOrder>();

        // ✅ Assign URLs to WorkOrder based on Document Master order
        for (WorkOrder wo : scope) {

            // Clear all image fields before assigning
            for (String f : IMAGE_FIELDS) {
                wo.put(f, null);
            }

            if (!woToDocs.containsKey(wo.Id)) {
                updates.add(wo);
                continue;
            }

            // Process each ContentDocument for this work order
            for (ContentDocument cd : woToDocs.get(wo.Id)) {

                if (cd.Title == null) continue;

                // ✅ Case-sensitive matching
                if (!docNameToOrder.containsKey(cd.Title)) {
                    continue; // skip unmatched
                }

                Integer orderNum = docNameToOrder.get(cd.Title);  // 1-based
                Integer fieldIdx = orderNum - 1;                 // convert to 0-based index

                // ✅ Ensure index is valid
                if (fieldIdx >= 0 && fieldIdx < IMAGE_FIELDS.size()) {
                    String url = '/sfc/servlet.shepherd/version/download/' + cd.LatestPublishedVersionId;
                    wo.put(IMAGE_FIELDS[fieldIdx], url);
                }
            }

            updates.add(wo);
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('✅ WorkOrder Image Assignment Batch Completed.');
    }
}