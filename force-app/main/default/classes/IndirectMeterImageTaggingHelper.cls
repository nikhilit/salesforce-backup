/**
 * @description       : 
 * @author            : Kartik Patkar Appstrail
 * @group             : 
 * @last modified on  : 02-02-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   02-12-2025   Kartik Patkar, Appstrail   Initial Version
**/
public with sharing class IndirectMeterImageTaggingHelper {
    
    public static void attachFileToWorkOrder(List<ContentVersion> newList) {
        
        // 1. Collect BP Numbers for filtering WOs
        Set<String> setBPNumbers = new Set<String>();
        Map<Id, ContentVersion> mapCVIdToCV = new Map<Id, ContentVersion>();
        
        for (ContentVersion cv : newList) {
            if (cv.In_Direct_Meter_Reading__c == true && cv.BP_Number__c != null) {
                setBPNumbers.add(cv.BP_Number__c);
                mapCVIdToCV.put(cv.Id, cv);
            }
        }
        if (setBPNumbers.isEmpty()) return;

        String meteringRecordTypeId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                                            .get('MGL_Metering').getRecordTypeId();
        
        // 2. Query existing Work Orders
        List<WorkOrder> existingWOList = [
            SELECT Id, WorkOrderNumber, Meter_Reading_Doc_Number__c, BP_Number__c,
                Scheduled_Date__c, Indirect_Reading_Received__c
            FROM WorkOrder
            WHERE BP_Number__c IN :setBPNumbers
            AND Appointment_Status__c != 'Completed'
            AND Expired__c = false
            AND RecordTypeId = :meteringRecordTypeId
            AND Indirect_Reading_Received__c = false
            ORDER BY CreatedDate DESC
        ];
        
        Map<String, WorkOrder> bpToExistingWO = new Map<String, WorkOrder>();
        for (WorkOrder wo : existingWOList) {
            if (!bpToExistingWO.containsKey(wo.BP_Number__c))
                bpToExistingWO.put(wo.BP_Number__c, wo);
        }
        
        // 3. Get Accounts for BP Numbers
        Map<String, Account> bpToAccount = new Map<String, Account>();
        for (Account acc : [
            SELECT Id, Name, BP_Number__c
            FROM Account
            WHERE BP_Number__c IN :setBPNumbers
        ]) {
            bpToAccount.put(acc.BP_Number__c, acc);
        }

        List<Group_Master__c> groupMasters = [
            SELECT Id, Name, Group_Code__c
            FROM Group_Master__c WHERE Group_Code__c=10 LIMIT 1
        ];
        
        // TEMP STORAGE
        List<WorkOrder> newWorkOrders = new List<WorkOrder>();
        Map<String, WorkOrder> bpToNewWO = new Map<String, WorkOrder>();
        
        List<WorkOrder> woUpdates = new List<WorkOrder>();
        List<ContentDocument> contentDocsToUpdate = new List<ContentDocument>();
        
        // Map of CV → OCR/Document (temporary)
        Map<Id, Meter_Reading_OCR__c> cvToOCR = new Map<Id, Meter_Reading_OCR__c>();
        Map<Id, Document__c> cvToDocument = new Map<Id, Document__c>();
        
        // 4. Create / Update Work Orders
        for (ContentVersion cv : newList) {
            if (!cv.In_Direct_Meter_Reading__c || cv.BP_Number__c == null) continue;
            
            String bpNum = cv.BP_Number__c;
            WorkOrder wo;
            
            // Existing WO
            if (bpToExistingWO.containsKey(bpNum)) {
                wo = bpToExistingWO.get(bpNum);
            }
            // New WO
            else {
                if (!bpToAccount.containsKey(bpNum)) continue;

                wo = new WorkOrder(
                    AccountId = bpToAccount.get(bpNum).Id,
                    Appointment_Type__c = 'Interim',
                    Status = 'New',
                    RecordTypeId=meteringRecordTypeId
                );
                newWorkOrders.add(wo);
                bpToNewWO.put(bpNum, wo);
            }
            
            wo.Indirect_Reading_Received__c = true;
            
            if (cv.Meter_Reading_Value__c != null && cv.Meter_Reading_Value__c.isNumeric())
                wo.Meter_Reading__c = Decimal.valueOf(cv.Meter_Reading_Value__c);
            
            wo.Meter_Reading_Date__c = cv.Meter_Reading_Date__c;
            wo.Indirect_Submission_Mode__c = cv.Mode__c;
            wo.Meter_Reading_Submited_By__c = cv.Meter_Reading_Submited_By__c;

            if(!groupMasters.isEmpty())
                wo.Group_Master__c = groupMasters[0].Id;
            
            if (!woUpdates.contains(wo))
                woUpdates.add(wo);
            
            // Rename ContentDocument
            ContentDocument cd = new ContentDocument(Id = cv.ContentDocumentId);
            cd.Title = DocumentHelper.generateDocumentKey(
                wo.Meter_Reading_Doc_Number__c,
                bpNum,
                wo.Scheduled_Date__c,
                wo.WorkOrderNumber
            );
            cd.Description = cv.Title;
            contentDocsToUpdate.add(cd);
            
            // Prepare OCR draft
            Meter_Reading_OCR__c ocr = new Meter_Reading_OCR__c(
                BP_Number__c = bpNum,
                Status__c = 'Draft'
            );
            cvToOCR.put(cv.Id, ocr);
            
            // Prepare Document__c draft
            Document__c doc = new Document__c(
                File_Name__c = cd.Title,
                BP_Number__c = bpNum
            );
            cvToDocument.put(cv.Id, doc);
        }
        
        // 5. Insert newly created WOs
        if (!newWorkOrders.isEmpty())
            insert newWorkOrders;
        
        // Merge maps
        for (String bp : bpToNewWO.keySet())
            bpToExistingWO.put(bp, bpToNewWO.get(bp));
        
        // 6. Patch OCR + Document__c with correct WO Ids
        for (Id cvId : cvToOCR.keySet()) {
            ContentVersion cv = mapCVIdToCV.get(cvId);
            WorkOrder wo = bpToExistingWO.get(cv.BP_Number__c);
            cvToOCR.get(cvId).Work_Order__c = wo.Id;
        }
        
        for (Id cvId : cvToDocument.keySet()) {
            ContentVersion cv = mapCVIdToCV.get(cvId);
            WorkOrder wo = bpToExistingWO.get(cv.BP_Number__c);
            cvToDocument.get(cvId).Work_Order__c = wo.Id;
        }
        
        // 7. Update records
        if (!woUpdates.isEmpty()) update woUpdates;
        if (!contentDocsToUpdate.isEmpty()) update contentDocsToUpdate;
        
        // 8. Insert documents
        insert cvToOCR.values();
        insert cvToDocument.values();
        
        // ****************************
        // 9. SAFE CDL CREATION (NO DUPLICATES)
        // ****************************

        // Fetch existing CDL for these documents
        Set<String> existingKeys = new Set<String>();
        List<Id> docIds = new List<Id>();
        for (ContentVersion cv : mapCVIdToCV.values()) {
            docIds.add(cv.ContentDocumentId);
        }

        for (ContentDocumentLink c : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :docIds
        ]) {
            existingKeys.add(c.ContentDocumentId + '|' + c.LinkedEntityId);
        }

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();

        for (Id cvId : mapCVIdToCV.keySet()) {
            ContentVersion cv = mapCVIdToCV.get(cvId);
            WorkOrder wo = bpToExistingWO.get(cv.BP_Number__c);
            Meter_Reading_OCR__c ocr = cvToOCR.get(cvId);
            Document__c doc = cvToDocument.get(cvId);

            // WO link
            if (!existingKeys.contains(cv.ContentDocumentId + '|' + wo.Id)) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = cv.ContentDocumentId,
                    LinkedEntityId = wo.Id,
                    ShareType = 'I',
                    Visibility = 'AllUsers'
                ));
            }

            // OCR link
            if (!existingKeys.contains(cv.ContentDocumentId + '|' + ocr.Id)) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = cv.ContentDocumentId,
                    LinkedEntityId = ocr.Id,
                    ShareType = 'I',
                    Visibility = 'AllUsers'
                ));
            }

            // Document__c link
            if (!existingKeys.contains(cv.ContentDocumentId + '|' + doc.Id)) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = cv.ContentDocumentId,
                    LinkedEntityId = doc.Id,
                    ShareType = 'I',
                    Visibility = 'AllUsers'
                ));
            }
        }

        if (!links.isEmpty())
            insert links;

        // 10. Update OCR to Pending
        for (Meter_Reading_OCR__c ocr : cvToOCR.values())
            ocr.Status__c = 'Pending';

        update cvToOCR.values();
        
        // 11. Update Document__c to Pending
        for (Document__c d : cvToDocument.values())
            d.Upload_Status__c = 'Pending';

        update cvToDocument.values();
    }
}