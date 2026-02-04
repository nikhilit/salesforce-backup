/**
* @description       : 
* @author            : Kartik Patkar Appstrail
* @group             : 
* @last modified on  : 26-11-2025
* @last modified by  : Kartik Patkar Appstrail 
* Modifications Log
* Ver   Date         Author                     Modification
* 1.0   26-11-2025   Kartik Patkar, Appstrail   Initial Version
**/
public class ContentDocumentLinkHandler {
    
    // public static void handleAfterInsert(List<ContentDocumentLink> newLinks) {
    //     // Load metadata
    //     Map<String, List<String>> objectFieldMap = new Map<String, List<String>>();
    //     for (ImageFieldMapping__mdt config : [
    //         SELECT Object_API_Name__c, Field_API_Names__c FROM ImageFieldMapping__mdt
    //     ]) {
    //         List<String> fields = config.Field_API_Names__c.split(',');
    //         objectFieldMap.put(config.Object_API_Name__c.trim(), fields);
    //     }
    
    //     // Group by parent Id
    //     Map<Id, List<ContentDocumentLink>> parentToLinks = new Map<Id, List<ContentDocumentLink>>();
    
    //     for (ContentDocumentLink cdl : newLinks) {
    
    //         Id cdlId = cdl.LinkedEntityId;
    
    //         if (!parentToLinks.containsKey(cdlId)) {
    //             parentToLinks.put(cdlId, new List<ContentDocumentLink>());
    //         }
    //         parentToLinks.get(cdlId).add(cdl);
    //     }
    
    //     Map<String, SObjectField[]> objectToFieldsMap = new Map<String, SObjectField[]>();
    
    //     Map<Id, SObject> recordsToUpdate = new Map<Id, SObject>();
    
    //     for (Id parentId : parentToLinks.keySet()) {
    
    //         String objectType = parentId.getSObjectType().getDescribe().getName();
    
    //         if (!objectFieldMap.containsKey(objectType)) continue;
    
    //         List<String> fieldNames = objectFieldMap.get(objectType);
    //         String fieldList = String.join(fieldNames, ',');
    
    //         String query = 'SELECT Id, ' + fieldList + ' FROM ' + objectType + ' WHERE Id = :parentId LIMIT 1';
    //         SObject record = Database.query(query);
    
    //         List<ContentDocumentLink> links = parentToLinks.get(parentId);
    
    //         for (ContentDocumentLink link : links) {
    //             ContentVersion cv = [
    //                 SELECT Id FROM ContentVersion
    //                 WHERE ContentDocumentId = :link.ContentDocumentId
    //                 ORDER BY CreatedDate DESC LIMIT 1
    //             ];
    //             String imageUrl = '/sfc/servlet.shepherd/version/download/' + cv.Id;
    
    //             Boolean assigned = false;
    //             for (String field : fieldNames) {
    //                 if (record.get(field) == null) {
    //                     record.put(field, imageUrl);
    //                     assigned = true;
    //                     break;
    //                 }
    //             }
    
    //             if (assigned) {
    //                 recordsToUpdate.put(record.Id, record);
    //             }
    //         }
    //     }
    
    //     if (!recordsToUpdate.isEmpty()) {
    //         update recordsToUpdate.values();
    //     }
    // }
    
    
    public static void handleAfterInsert(List<ContentDocumentLink> newLinks) {
        
        if (newLinks.isEmpty()) return;
        
        // Step 1: Load Metadata Config (only once)
        Map<String, List<String>> objectFieldMap = new Map<String, List<String>>();
        for (ImageFieldMapping__mdt config : [SELECT Object_API_Name__c, Field_API_Names__c FROM ImageFieldMapping__mdt]) {
            if (String.isNotBlank(config.Object_API_Name__c) && String.isNotBlank(config.Field_API_Names__c)) {
                List<String> fields = new List<String>();
                for (String f : config.Field_API_Names__c.split(',')) {
                    fields.add(f.trim());
                }
                objectFieldMap.put(config.Object_API_Name__c.trim(), fields);//WorkOrder=>ImageUrl1__c,ImageUrl2__c,ImageUrl3__c,ImageUrl4__c,ImageUrl5__c,
            }
        }
        
        // Step 2: Group ContentDocumentLinks by parent
        Map<Id, List<ContentDocumentLink>> parentToLinks = new Map<Id, List<ContentDocumentLink>>();
        for (ContentDocumentLink cdl : newLinks) {
            if (cdl.LinkedEntityId == null) continue;
            
            Id parentId = cdl.LinkedEntityId;
            String objectType = parentId.getSObjectType().getDescribe().getName();
            if (!objectFieldMap.containsKey(objectType)) continue;
            
            String firstThreeChars = String.valueOf(parentId).substring(0, 3);
            if (firstThreeChars == '0WO') {
                if (!parentToLinks.containsKey(cdl.LinkedEntityId)) {
                    parentToLinks.put(cdl.LinkedEntityId, new List<ContentDocumentLink>());
                }
                parentToLinks.get(cdl.LinkedEntityId).add(cdl);//WorkOrder=>ImageUrl1__c,ImageUrl2__c,ImageUrl3__c,ImageUrl4__c,ImageUrl5__c,,SA_Id=>CV_2
            }
        }
        
        if (parentToLinks.isEmpty()) return;
        
        // Step 3: Collect all ContentDocumentIds
        Set<Id> allDocIds = new Set<Id>();
        for (ContentDocumentLink link : newLinks) {
            if (link.ContentDocumentId != null) {
                allDocIds.add(link.ContentDocumentId);
            }
        }
        
        // Step 4: Get latest ContentVersions in bulk
        Map<Id, Id> docToLatestVersion = new Map<Id, Id>();
        for (ContentDocument cd : [
            SELECT Id, LatestPublishedVersionId
            FROM ContentDocument
            WHERE Id IN :allDocIds
        ]) {
            if (cd.LatestPublishedVersionId != null) {
                docToLatestVersion.put(cd.Id, cd.LatestPublishedVersionId);
            }
        }

        // Added by Aliyaj
        // Query ContentVersion fields
        Map<Id, ContentVersion> versionMap = new Map<Id, ContentVersion>();
        if (!docToLatestVersion.isEmpty()) {
            versionMap = new Map<Id, ContentVersion>([
                SELECT Id, Title, VersionNumber, PathOnClient, ContentSize, FileType, Description
                FROM ContentVersion
                WHERE Id IN :docToLatestVersion.values()
            ]);
        }
        
        // Step 5: Build queries for parents by object type (bulkified)
        Map<String, Set<Id>> objectToIds = new Map<String, Set<Id>>();
        for (Id parentId : parentToLinks.keySet()) {//WO_Id=>CV_1,SA_Id=>CV_2
            String objectType = parentId.getSObjectType().getDescribe().getName();
            if (!objectFieldMap.containsKey(objectType)) continue;
            
            if (!objectToIds.containsKey(objectType)) {
                objectToIds.put(objectType, new Set<Id>());
            }
            objectToIds.get(objectType).add(parentId);//WorkOrder=>WO1, WO2, WO3
        }
        
        // Step 6: Query all parents in bulk
        Map<Id, SObject> parentRecords = new Map<Id, SObject>();
        for (String objectType : objectToIds.keySet()) {
            
            List<String> fields = objectFieldMap.get(objectType);
            
            if (!objectFieldMap.containsKey(objectType)) continue;
            
            if (fields.isEmpty()) continue;
            
            String fieldList = String.join(fields, ',');
            Set<Id> setIds = objectToIds.get(objectType);
            
            String query = 'SELECT Id, RecordType.DeveloperName, WorkType.Name, ' + fieldList + ' FROM ' + objectType + ' WHERE Id IN :setIds';
            for (SObject sobj : Database.query(query)) {
                parentRecords.put(sobj.Id, sobj);
            }
        }
        
        // Step 7: Assign image URLs
        Map<Id, SObject> recordsToUpdate = new Map<Id, SObject>();
        for (Id parentId : parentToLinks.keySet()) {
            if (!parentRecords.containsKey(parentId)) continue;
            
            String objectType = parentId.getSObjectType().getDescribe().getName(); 
            
            if (!objectFieldMap.containsKey(objectType)) continue;
            
            List<String> fieldNames = objectFieldMap.get(objectType);
            if (fieldNames == null || fieldNames.isEmpty()) continue;
            
            SObject record = parentRecords.get(parentId);
            // Added by Aliyaj
            SObject rt = record.getSObject('RecordType');
            String rtDevName = rt != null ? (String) rt.get('DeveloperName') : null;

            String labelValue = System.Label.AS_FieldSenseFlowLabel;

            List<String> labelValues = new List<String>();

            for (String item : labelValue.toLowerCase().split(',')) {
                labelValues.add(item.trim());
            }

            SObject workType = record.getSObject('WorkType');
            String wtName = workType != null ? (String) workType.get('Name') : null;

            Boolean isFieldSense =
                wtName != null &&
                labelValues.contains(wtName.toLowerCase());

            List<ContentDocumentLink> links = parentToLinks.get(parentId);
            
            for (ContentDocumentLink link : links) {
                if (!docToLatestVersion.containsKey(link.ContentDocumentId)) continue;
                
                Id cvId = docToLatestVersion.get(link.ContentDocumentId);
                // Added by Aliyaj
                ContentVersion cv = versionMap.get(cvId); // versionMap from earlier
                if (cv == null) continue;

                String imageUrl = '/sfc/servlet.shepherd/version/download/' + cvId;

                // Added by Aliyaj
                // Check if this is a FollowUp_Image for MGL_R_T
                Boolean isFollowUp =
                cv.Title != null &&
                cv.Title.contains('FollowUp_Image_'); 

                // ---------------- FOLLOW UP IMAGES ----------------
                if (rtDevName == 'MGL_R_T' && isFieldSense) {
                    Boolean assigned = false;

                    for (String field : fieldNames) {

                        // Skip ImageUrl1 & ImageUrl2 for follow-up
                        if (isFollowUp && (field == 'ImageUrl1__c' || field == 'ImageUrl2__c')) {
                            continue;
                        }

                        if (!isFollowUp && (field == 'ImageUrl3__c' || field == 'ImageUrl4__c')) {
                            continue;
                        }

                        if (record.get(field) == null) {
                            record.put(field, imageUrl);
                            assigned = true;
                            break;
                        } 
                        else if (String.valueOf(record.get(field)).contains(cvId)) {
                            break;
                        }
                    }

                    if (assigned) {
                        recordsToUpdate.put(parentId, record);
                    }
                    continue;
                }
                
                // Default logic for other images
                Boolean assigned = false;
                for (String field : fieldNames) {
                    
                    if (record.get(field) == null) {
                        record.put(field, imageUrl);
                        assigned = true;
                        break;
                    }else if(String.valueOf(record.get(field)).contains(cvId)){
                        continue;
                    }
                }
                
                if (assigned) {
                    recordsToUpdate.put(parentId, record);
                }
            }
        }
        
        // Enable bypass
        Metering_Bypass_Validation__c bs = Metering_Bypass_Validation__c.getInstance(UserInfo.getUserId());
        if (bs == null) {
            bs = new Metering_Bypass_Validation__c();
            bs.SetupOwnerId = UserInfo.getUserId();
        }
        bs.Bypass__c = true;
        upsert bs;
        
        // Step 8: Update in bulk
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate.values();
        }
        
        // Disable bypass
        bs.Bypass__c = false;
        upsert bs;
        
    }
    
    // public static void handleAfterInsertLink(List<ContentDocumentLink> newLinks) {
    //     Set<Id> contentDocIds = new Set<Id>();
    //     Map<Id, Id> docToServiceResource = new Map<Id, Id>();
    
    //     for (ContentDocumentLink cdl : newLinks) {
    //         if (cdl.LinkedEntityId != null && String.valueOf(cdl.LinkedEntityId).startsWith('08p')) {
    //             contentDocIds.add(cdl.ContentDocumentId);
    //             docToServiceResource.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
    //         }
    //     }
    
    //     if (contentDocIds.isEmpty()) return;
    
    //     List<ContentVersion> contentVersions = [
    //         SELECT Id, Title, ContentDocumentId
    //         FROM ContentVersion
    //         WHERE ContentDocumentId IN :contentDocIds
    //         ORDER BY CreatedDate DESC
    //     ];
    
    //     List<ServiceResource> toUpdate = new List<ServiceResource>();
    
    //     for (ContentVersion cv : contentVersions) {
    //         if (cv.Title == 'Agent Profile Image') {
    //             Id serviceResourceId = docToServiceResource.get(cv.ContentDocumentId);
    //             String imageUrl = '/sfc/servlet.shepherd/version/download/' + cv.Id;
    
    //             toUpdate.add(new ServiceResource(
    //                 Id = serviceResourceId,
    //                 Agent_Image__c = imageUrl
    //             ));
    //         }
    //     }
    
    //     if (!toUpdate.isEmpty()) {
    //         update toUpdate;
    //     }
    // }
    
    
    
    public static void linkRelatedDocuments(List<ContentDocumentLink> newLinks) {
        if (newLinks.isEmpty()) return;
        
        // 1) Consider only links that were just created to a WorkOrder
        Map<Id, Id> woIdByDocId = new Map<Id, Id>(); // ContentDocumentId -> WorkOrderId
        for (ContentDocumentLink cdl : newLinks) {
            if (cdl.LinkedEntityId != null &&
                cdl.LinkedEntityId.getSObjectType() == WorkOrder.SObjectType &&
                cdl.ContentDocumentId != null) {
                    woIdByDocId.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
                }
        }
        if (woIdByDocId.isEmpty()) return;
        
        Set<Id> woIds = new Set<Id>(woIdByDocId.values());
        Set<Id> contentDocIds = new Set<Id>(woIdByDocId.keySet());
        
        // 2) Get latest ContentVersion titles for those documents
        //    (Title must match the "photo name" that Apex uses as Type__c)
        Map<Id, String> titleByDocId = new Map<Id, String>(); // ContentDocumentId -> Title
        for (ContentVersion cv : [
            SELECT ContentDocumentId, Title, IsLatest
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocIds
            AND IsLatest = true
        ]) {
            titleByDocId.put(cv.ContentDocumentId, cv.Title);
        }
        
        // Build (WO, Title) keys we need to fetch
        Set<String> wantedTitles = new Set<String>();
        for (Id docId : contentDocIds) {
            String t = titleByDocId.get(docId);
            if (t != null) wantedTitles.add(t);
        }
        if (wantedTitles.isEmpty()) return;
        
        Map<String, Id> docRecIdByKey = new Map<String, Id>();      // WO|Title -> Document__c.Id
        Map<String, Id> ocrRecIdByKey = new Map<String, Id>();      // WO|Title -> OCR__c.Id
        
        for (Document__c d : [
            SELECT Id, Work_Order__c, Type__c
            FROM Document__c
            WHERE Work_Order__c IN :woIds
            AND Type__c IN :wantedTitles
        ]) {
            docRecIdByKey.put(d.Work_Order__c + '|' + d.Type__c, d.Id);
        }
        for (Meter_Reading_OCR__c o : [
            SELECT Id, Work_Order__c, Type__c
            FROM Meter_Reading_OCR__c
            WHERE Work_Order__c IN :woIds
            AND Type__c IN :wantedTitles
        ]) {
            ocrRecIdByKey.put(o.Work_Order__c + '|' + o.Type__c, o.Id);
        }
        
        // 4) Prepare precise links (per file → matching records only)
        List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();
        // Track (ContentDocumentId, LinkedEntityId) to avoid dup inserts in this txn
        Set<String> pairDeDupe = new Set<String>();
        
        // Optional: prefetch existing links for de-dup (small scope)
        Set<Id> allTargets = new Set<Id>();
        for (Id docId : contentDocIds) {
            Id woId = woIdByDocId.get(docId);
            String title = titleByDocId.get(docId);
            if (woId == null || String.isBlank(title)) continue;
            
            String key = woId + '|' + title;
            Id docRecId = docRecIdByKey.get(key);
            Id ocrRecId = ocrRecIdByKey.get(key);
            if (docRecId != null) allTargets.add(docRecId);
            if (ocrRecId != null) allTargets.add(ocrRecId);
        }
        Map<String, Boolean> existing = new Map<String, Boolean>();
        if (!allTargets.isEmpty()) {
            for (ContentDocumentLink ex : [
                SELECT ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN :contentDocIds
                AND LinkedEntityId IN :allTargets
            ]) {
                existing.put(ex.ContentDocumentId + '|' + ex.LinkedEntityId, true);
            }
        }
        
        for (Id docId : contentDocIds) {
            Id woId = woIdByDocId.get(docId);
            String title = titleByDocId.get(docId);
            if (woId == null || String.isBlank(title)) continue;
            
            String key = woId + '|' + title;
            
            // Link to matching Document__c (always, if present)
            Id docRecId = docRecIdByKey.get(key);
            if (docRecId != null) {
                String pair = docId + '|' + docRecId;
                if (!existing.containsKey(pair) && pairDeDupe.add(pair)) {
                    toInsert.add(new ContentDocumentLink(
                        ContentDocumentId = docId,
                        LinkedEntityId    = docRecId,
                        ShareType         = 'V',
                        Visibility        = 'AllUsers'
                    ));
                }
            }
            
            // Link to matching OCR record ONLY if present
            Id ocrRecId = ocrRecIdByKey.get(key);
            if (ocrRecId != null) {
                String pair = docId + '|' + ocrRecId;
                if (!existing.containsKey(pair) && pairDeDupe.add(pair)) {
                    toInsert.add(new ContentDocumentLink(
                        ContentDocumentId = docId,
                        LinkedEntityId    = ocrRecId,
                        ShareType         = 'V',
                        Visibility        = 'AllUsers'
                    ));
                }
            }
        }
        
        if (!toInsert.isEmpty()) {
            try {
                insert toInsert;
            } catch (DmlException e) {
                System.debug(' CDL insert failed: ' + e.getMessage());
            }
        }
    }
    
    // public static void linkRelatedDocuments(List<ContentDocumentLink> newLinks) {
    //     if (newLinks.isEmpty()) return;
    
    //     //  Only consider new CDLs linking to WorkOrder
    //     Map<Id, Id> woToDocMap = new Map<Id, Id>();
    //     Set<Id> contentDocIds = new Set<Id>();
    //     for (ContentDocumentLink cdl : newLinks) {
    //         if (cdl.LinkedEntityId != null &&
    //             cdl.LinkedEntityId.getSObjectType() == WorkOrder.SObjectType) {
    //             woToDocMap.put(cdl.LinkedEntityId, cdl.ContentDocumentId);
    //             contentDocIds.add(cdl.ContentDocumentId);
    //         }
    //     }
    //     if (woToDocMap.isEmpty()) return;
    
    //     Set<Id> workOrderIds = woToDocMap.keySet();
    
    //     //  Get ContentVersion titles for matching ContentDocuments
    //     Map<Id, String> cvTitleMap = new Map<Id, String>();
    //     for (ContentVersion cv : [
    //         SELECT ContentDocumentId, Title
    //         FROM ContentVersion
    //         WHERE ContentDocumentId IN :contentDocIds
    //         ORDER BY CreatedDate DESC
    //     ]) {
    //         cvTitleMap.put(cv.ContentDocumentId, cv.Title);
    //     }
    
    //     //  Get Document__c and OCR records for these WorkOrders
    //     Map<String, Id> docKeyMap = new Map<String, Id>();
    //     for (Document__c d : [
    //         SELECT Id, Work_Order__c, Type__c
    //         FROM Document__c
    //         WHERE Work_Order__c IN :workOrderIds
    //     ]) {
    //         docKeyMap.put(d.Work_Order__c + '|' + d.Type__c, d.Id);
    //     }
    
    //     Map<String, Id> ocrKeyMap = new Map<String, Id>();
    //     for (Meter_Reading_OCR__c o : [
    //         SELECT Id, Work_Order__c, Type__c
    //         FROM Meter_Reading_OCR__c
    //         WHERE Work_Order__c IN :workOrderIds
    //     ]) {
    //         ocrKeyMap.put(o.Work_Order__c + '|' + o.Type__c, o.Id);
    //     }
    
    //     //  Query existing CDLs to avoid duplicates
    //     Set<Id> allTargetIds = new Set<Id>();
    //     allTargetIds.addAll(docKeyMap.values());
    //     allTargetIds.addAll(ocrKeyMap.values());
    
    //     Set<String> existingPairs = new Set<String>();
    //     if (!allTargetIds.isEmpty()) {
    //         for (ContentDocumentLink existing : [
    //             SELECT ContentDocumentId, LinkedEntityId
    //             FROM ContentDocumentLink
    //             WHERE ContentDocumentId IN :contentDocIds
    //             AND LinkedEntityId IN :allTargetIds
    //         ]) {
    //             existingPairs.add(existing.ContentDocumentId + '|' + existing.LinkedEntityId);
    //         }
    //     }
    
    //     / Build new CDLs for matching records only
    //     List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();
    //     for (Id woId : woToDocMap.keySet()) {
    //         Id cDocId = woToDocMap.get(woId);
    //         String title = cvTitleMap.get(cDocId);
    //         if (String.isBlank(title)) continue;
    
    //         // Link to Document__c
    //         Id docId = docKeyMap.get(woId + '|' + title);
    //         if (docId != null &&
    //             !existingPairs.contains(cDocId + '|' + docId)) {
    //             toInsert.add(new ContentDocumentLink(
    //                 ContentDocumentId = cDocId,
    //                 LinkedEntityId   = docId,
    //                 ShareType        = 'V',
    //                 Visibility       = 'AllUsers'
    //             ));
    //         }
    
    //         // Link to OCR record (if exists)
    //         Id ocrId = ocrKeyMap.get(woId + '|' + title);
    //         if (ocrId != null &&
    //             !existingPairs.contains(cDocId + '|' + ocrId)) {
    //             toInsert.add(new ContentDocumentLink(
    //                 ContentDocumentId = cDocId,
    //                 LinkedEntityId   = ocrId,
    //                 ShareType        = 'V',
    //                 Visibility       = 'AllUsers'
    //             ));
    //         }
    //     }
    
    //     //  Final safe insert
    //     if (!toInsert.isEmpty()) {
    //         try {
    //             insert toInsert;
    //         } catch (DmlException e) {
    //             System.debug(' CDL insert failed: ' + e.getMessage());
    //         }
    //     }
    // }
    
    /**
* @description
* Post-sync workaround for offline images.
* If a ContentDocument is linked to a ServiceAppointment (offline upload),
* this method links the same ContentDocument to the parent WorkOrder
* AFTER sync, restoring online parity.
*
*/
    public static void handleOfflineImageLinking(List<ContentDocumentLink> newLinks) {
        
        if (newLinks == null || newLinks.isEmpty()) return;
        
        // Step 1: Collect SA-linked documents
        Map<Id, Set<Id>> saToDocIds = new Map<Id, Set<Id>>();
        Set<Id> saIds = new Set<Id>();
        
        for (ContentDocumentLink cdl : newLinks) {
            if (cdl.LinkedEntityId != null &&
                cdl.LinkedEntityId.getSObjectType() == ServiceAppointment.SObjectType &&
                cdl.ContentDocumentId != null) {
                    
                    saIds.add(cdl.LinkedEntityId);
                    
                    if (!saToDocIds.containsKey(cdl.LinkedEntityId)) {
                        saToDocIds.put(cdl.LinkedEntityId, new Set<Id>());
                    }
                    saToDocIds.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
                }
        }
        
        if (saIds.isEmpty()) return;
        
        // Step 2: Resolve ServiceAppointment → WorkOrder
        Map<Id, Id> saToWoMap = new Map<Id, Id>();
        for (ServiceAppointment sa : [
            SELECT Id, ParentRecordId
            FROM ServiceAppointment
            WHERE Id IN :saIds
        ]) {
            if (sa.ParentRecordId != null) {
                saToWoMap.put(sa.Id, sa.ParentRecordId);
            }
        }
        
        if (saToWoMap.isEmpty()) return;
        
        // Step 3: Fetch existing ContentDocumentLinks to avoid duplicates
        Set<Id> woIds = new Set<Id>(saToWoMap.values());
        Set<Id> docIds = new Set<Id>();
        for (Set<Id> ids : saToDocIds.values()) {
            docIds.addAll(ids);
        }
        
        Set<String> existingPairs = new Set<String>();
        for (ContentDocumentLink existing : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIds
            AND LinkedEntityId IN :woIds
        ]) {
            existingPairs.add(existing.ContentDocumentId + '|' + existing.LinkedEntityId);
        }
        
        // Step 4: Prepare missing links
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        
        for (Id saId : saToDocIds.keySet()) {
            Id woId = saToWoMap.get(saId);
            if (woId == null) continue;
            
            for (Id docId : saToDocIds.get(saId)) {
                String key = docId + '|' + woId;
                if (existingPairs.contains(key)) continue;
                
                linksToInsert.add(new ContentDocumentLink(
                    ContentDocumentId = docId,
                    LinkedEntityId    = woId,
                    ShareType         = 'V',
                    Visibility        = 'AllUsers'
                ));
            }
        }
        
        // Step 5: Insert safely
        if (!linksToInsert.isEmpty()) {
            try {
                insert linksToInsert;
            } catch (DmlException e) {
                System.debug('Offline SA→WO image linking failed: ' + e.getMessage());
            }
        }
    }
    
}