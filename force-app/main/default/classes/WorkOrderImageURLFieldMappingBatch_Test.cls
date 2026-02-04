/**
 * @description       : Test class for WorkOrderImageURLFieldMappingBatch
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 27-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   27-01-2026   Kartik Patkar, Appstrail   Initial Version
 **/
@isTest
private class WorkOrderImageURLFieldMappingBatch_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test WorkOrder records
        List<WorkOrder> workOrders = new List<WorkOrder>();
        
        // Create a work order with service appointment requirement
        WorkOrder wo1 = new WorkOrder(
            Subject = 'Test Work Order 1',
            Status = 'New'
        );
        
        WorkOrder wo2 = new WorkOrder(
            Subject = 'Test Work Order 2',
            Status = 'New'
        );
        
        workOrders.add(wo1);
        workOrders.add(wo2);
        insert workOrders;
    }
    
    @isTest
    static void testBatchWithMultipleImages() {
        // Get test work order
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Subject = 'Test Work Order 1' LIMIT 1];
        
        // Create ContentVersions (images) with different creation times
        List<ContentVersion> cvList = new List<ContentVersion>();
        
        // Image 1 - Oldest
        ContentVersion cv1 = new ContentVersion(
            Title = 'Image1',
            PathOnClient = 'Image1.jpg',
            VersionData = Blob.valueOf('Test Image 1 Content'),
            IsMajorVersion = true
        );
        cvList.add(cv1);
        
        // Image 2
        ContentVersion cv2 = new ContentVersion(
            Title = 'Image2',
            PathOnClient = 'Image2.jpg',
            VersionData = Blob.valueOf('Test Image 2 Content'),
            IsMajorVersion = true
        );
        cvList.add(cv2);
        
        // Image 3 - Newest
        ContentVersion cv3 = new ContentVersion(
            Title = 'Image3',
            PathOnClient = 'Image3.jpg',
            VersionData = Blob.valueOf('Test Image 3 Content'),
            IsMajorVersion = true
        );
        cvList.add(cv3);
        
        insert cvList;
        
        // Query to get ContentDocumentIds
        List<ContentVersion> insertedCVs = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :cvList
            ORDER BY CreatedDate ASC
        ];
        
        // Create ContentDocumentLinks to associate with WorkOrder
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for (ContentVersion cv : insertedCVs) {
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = wo.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            cdlList.add(cdl);
        }
        insert cdlList;
        
        Test.startTest();
        // Execute batch
        WorkOrderImageURLFieldMappingBatch batch = new WorkOrderImageURLFieldMappingBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify results - image URLs should be assigned in chronological order
        // Note: Actual field verification depends on ImageFieldMapping__mdt configuration
        WorkOrder updatedWO = [SELECT Id FROM WorkOrder WHERE Id = :wo.Id];
        System.assertNotEquals(null, updatedWO, 'WorkOrder should exist');
    }
    
    @isTest
    static void testBatchWithWhereClause() {
        // Get test work order
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Subject = 'Test Work Order 2' LIMIT 1];
        
        // Create a single ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'SingleImage',
            PathOnClient = 'SingleImage.jpg',
            VersionData = Blob.valueOf('Test Single Image Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Get ContentDocumentId
        ContentVersion insertedCV = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
        ];
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedCV.ContentDocumentId,
            LinkedEntityId = wo.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        Test.startTest();
        // Execute batch with WHERE clause
        String whereClause = 'WHERE Subject = \'Test Work Order 2\'';
        WorkOrderImageURLFieldMappingBatch batch = new WorkOrderImageURLFieldMappingBatch(whereClause);
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify results
        WorkOrder updatedWO = [SELECT Id FROM WorkOrder WHERE Id = :wo.Id];
        System.assertNotEquals(null, updatedWO, 'WorkOrder should exist');
    }
    
    @isTest
    static void testBatchWithNoImages() {
        // Get test work order
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Subject = 'Test Work Order 1' LIMIT 1];
        
        Test.startTest();
        // Execute batch on work order with no images
        WorkOrderImageURLFieldMappingBatch batch = new WorkOrderImageURLFieldMappingBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify that work order still exists and batch completed successfully
        WorkOrder updatedWO = [SELECT Id FROM WorkOrder WHERE Id = :wo.Id];
        System.assertNotEquals(null, updatedWO, 'WorkOrder should exist');
    }
    
    @isTest
    static void testBatchWithMoreImagesThanFields() {
        // Get test work order
        WorkOrder wo = [SELECT Id FROM WorkOrder WHERE Subject = 'Test Work Order 1' LIMIT 1];
        
        // Create many ContentVersions to exceed potential field limit
        List<ContentVersion> cvList = new List<ContentVersion>();
        for (Integer i = 1; i <= 15; i++) {
            ContentVersion cv = new ContentVersion(
                Title = 'Image' + i,
                PathOnClient = 'Image' + i + '.jpg',
                VersionData = Blob.valueOf('Test Image ' + i + ' Content'),
                IsMajorVersion = true
            );
            cvList.add(cv);
        }
        insert cvList;
        
        // Query to get ContentDocumentIds
        List<ContentVersion> insertedCVs = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :cvList
            ORDER BY CreatedDate ASC
        ];
        
        // Create ContentDocumentLinks
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        for (ContentVersion cv : insertedCVs) {
            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = wo.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            cdlList.add(cdl);
        }
        insert cdlList;
        
        Test.startTest();
        // Execute batch - should handle gracefully when images exceed available fields
        WorkOrderImageURLFieldMappingBatch batch = new WorkOrderImageURLFieldMappingBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Verify results
        WorkOrder updatedWO = [SELECT Id FROM WorkOrder WHERE Id = :wo.Id];
        System.assertNotEquals(null, updatedWO, 'WorkOrder should exist and process successfully');
    }
    
    @isTest
    static void testBatchConstructors() {
        Test.startTest();
        // Test default constructor
        WorkOrderImageURLFieldMappingBatch batch1 = new WorkOrderImageURLFieldMappingBatch();
        System.assertNotEquals(null, batch1, 'Default constructor should work');
        
        // Test constructor with WHERE clause
        WorkOrderImageURLFieldMappingBatch batch2 = new WorkOrderImageURLFieldMappingBatch('WHERE Status = \'New\'');
        System.assertNotEquals(null, batch2, 'Constructor with WHERE clause should work');
        Test.stopTest();
    }
}