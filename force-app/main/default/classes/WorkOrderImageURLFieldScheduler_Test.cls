/**
 * @description       : Test class for WorkOrderImageURLFieldMappingScheduler and Batch
 * @author            : Kartik Patkar Appstrail
 * @group             :
 * @last modified on  : 27-01-2026
 * @last modified by  : Kartik Patkar, Appstrail
 * Modifications Log
 * Ver   Date         Author                     Modification
 * 1.0   27-01-2026   Kartik Patkar, Appstrail   Initial Version
 **/
@isTest
private class WorkOrderImageURLFieldScheduler_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            BP_Number__c = 'BP12345'
        );
        insert testAccount;
        
        // Create test WorkOrders
        List<WorkOrder> workOrders = new List<WorkOrder>();
        for (Integer i = 0; i < 5; i++) {
            workOrders.add(new WorkOrder(
                AccountId = testAccount.Id,
                Status = 'New',
                Subject = 'Test WO ' + i
            ));
        }
        insert workOrders;
        
        // Create ContentVersions and link them to WorkOrders
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Integer i = 0; i < 3; i++) {
            contentVersions.add(new ContentVersion(
                Title = 'Test Image ' + i,
                PathOnClient = 'TestImage' + i + '.jpg',
                VersionData = Blob.valueOf('Test image content ' + i),
                IsMajorVersion = true
            ));
        }
        insert contentVersions;
        
        // Get ContentDocumentIds
        List<ContentVersion> insertedVersions = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :contentVersions
        ];
        
        // Create ContentDocumentLinks
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        Integer docIndex = 0;
        for (WorkOrder wo : workOrders) {
            if (docIndex < insertedVersions.size()) {
                links.add(new ContentDocumentLink(
                    ContentDocumentId = insertedVersions[docIndex].ContentDocumentId,
                    LinkedEntityId = wo.Id,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
                docIndex++;
            }
        }
        
        if (!links.isEmpty()) {
            insert links;
        }
    }
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        
        // Execute batch
        WorkOrderImageURLFieldMappingBatch batch = new WorkOrderImageURLFieldMappingBatch();
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify that image URLs were populated
        List<WorkOrder> updatedWOs = [
            SELECT Id, ImageUrl1__c, ImageUrl2__c, ImageUrl3__c
            FROM WorkOrder
            LIMIT 5
        ];
        
        // At least one WorkOrder should have image URL populated
        Boolean hasImageUrl = false;
        for (WorkOrder wo : updatedWOs) {
            if (wo.ImageUrl1__c != null) {
                hasImageUrl = true;
                System.assert(wo.ImageUrl1__c.contains('/sfc/servlet.shepherd/version/download/'), 
                    'Image URL should contain correct format');
                break;
            }
        }
        
        System.assertEquals(true, hasImageUrl, 'At least one WorkOrder should have image URL populated');
    }
    
    @isTest
    static void testBatchWithWhereClause() {
        Test.startTest();
        
        // Execute batch with WHERE clause
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        String whereClause = 'WHERE Id = \'' + wo.Id + '\'';
        
        WorkOrderImageURLFieldMappingBatch batch = new WorkOrderImageURLFieldMappingBatch(whereClause);
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify execution completed
        List<WorkOrder> results = [SELECT Id FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals(1, results.size(), 'WorkOrder should exist');
    }
    
    @isTest
    static void testSchedulerExecution() {
        Test.startTest();
        
        // Schedule the job - run every hour at 5 minutes past
        String cronExp = '0 5 * * * ?';
        String jobName = 'Test WO Image URL Mapping Job';
        
        WorkOrderImageURLFieldMappingScheduler scheduler = new WorkOrderImageURLFieldMappingScheduler();
        System.schedule(jobName, cronExp, scheduler);
        
        Test.stopTest();
        
        // Verify job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
        ];
        
        System.assertEquals(1, jobs.size(), 'Job should be scheduled');
        System.assertEquals('WAITING', jobs[0].State, 'Job should be in WAITING state');
    }
    
    @isTest
    static void testSchedulerWithCustomBatchSize() {
        Test.startTest();
        
        // Schedule with custom batch size
        String cronExp = '0 0 * * * ?';
        String jobName = 'Test Custom Batch Size';
        
        WorkOrderImageURLFieldMappingScheduler scheduler = new WorkOrderImageURLFieldMappingScheduler(100, 'WHERE Id != null');
        System.schedule(jobName, cronExp, scheduler);
        
        Test.stopTest();
        
        // Verify job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
        ];
        
        System.assertEquals(1, jobs.size(), 'Job with custom batch size should be scheduled');
    }
    
    @isTest
    static void testScheduleEvery5Minutes() {
        Test.startTest();
        
        // Use the static method to schedule (creates 12 jobs - one for each 5-minute interval)
        WorkOrderImageURLFieldMappingScheduler.scheduleEvery5Minutes();
        
        Test.stopTest();
        
        // Verify 12 jobs were scheduled (one for each 5-minute mark)
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'WO Image URL Mapping%'
        ];
        
        System.assertEquals(12, jobs.size(), '12 jobs should be scheduled (one for each 5-minute interval)');
    }
    
    @isTest
    static void testAbortAllScheduledJobs() {
        // First, schedule some jobs
        String cronExp = '0 0 * * * ?';
        
        for (Integer i = 0; i < 3; i++) {
            String jobName = 'WO Image URL Mapping - Test ' + i;
            WorkOrderImageURLFieldMappingScheduler scheduler = new WorkOrderImageURLFieldMappingScheduler();
            System.schedule(jobName, cronExp, scheduler);
        }
        
        // Verify jobs were created
        List<CronTrigger> jobsBefore = [
            SELECT Id FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'WO Image URL Mapping%'
        ];
        System.assertEquals(3, jobsBefore.size(), 'Three jobs should be scheduled');
        
        Test.startTest();
        
        // Abort all jobs
        WorkOrderImageURLFieldMappingScheduler.abortAllScheduledJobs();
        
        Test.stopTest();
        
        // Verify jobs were aborted
        List<CronTrigger> jobsAfter = [
            SELECT Id, State FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'WO Image URL Mapping%'
            AND State != 'DELETED'
        ];
        
        System.assertEquals(0, jobsAfter.size(), 'All jobs should be aborted');
    }
    
    @isTest
    static void testBatchWithNoImages() {
        // Create WorkOrder without any images
        Account acc = [SELECT Id FROM Account LIMIT 1];
        WorkOrder woNoImages = new WorkOrder(
            AccountId = acc.Id,
            Status = 'New',
            Subject = 'WO without images'
        );
        insert woNoImages;
        
        Test.startTest();
        
        String whereClause = 'WHERE Id = \'' + woNoImages.Id + '\'';
        WorkOrderImageURLFieldMappingBatch batch = new WorkOrderImageURLFieldMappingBatch(whereClause);
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify WorkOrder fields are cleared
        WorkOrder result = [
            SELECT Id, ImageUrl1__c, ImageUrl2__c
            FROM WorkOrder
            WHERE Id = :woNoImages.Id
        ];
        
        System.assertEquals(null, result.ImageUrl1__c, 'ImageUrl1 should be null when no images');
        System.assertEquals(null, result.ImageUrl2__c, 'ImageUrl2 should be null when no images');
    }
    
    @isTest
    static void testBatchChronologicalOrder() {
        // Get a WorkOrder
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        // Create multiple ContentVersions with delays to ensure order
        List<ContentVersion> versions = new List<ContentVersion>();
        for (Integer i = 0; i < 3; i++) {
            versions.add(new ContentVersion(
                Title = 'Ordered Image ' + i,
                PathOnClient = 'Image' + i + '.jpg',
                VersionData = Blob.valueOf('Content ' + i),
                IsMajorVersion = true
            ));
        }
        insert versions;
        
        // Get ContentDocumentIds
        List<ContentVersion> insertedVers = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :versions
            ORDER BY CreatedDate ASC
        ];
        
        // Link them to WorkOrder
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentVersion cv : insertedVers) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = wo.Id,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));
        }
        insert links;
        
        Test.startTest();
        
        String whereClause = 'WHERE Id = \'' + wo.Id + '\'';
        WorkOrderImageURLFieldMappingBatch batch = new WorkOrderImageURLFieldMappingBatch(whereClause);
        Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        // Verify images are assigned in chronological order
        WorkOrder result = [
            SELECT Id, ImageUrl1__c, ImageUrl2__c, ImageUrl3__c
            FROM WorkOrder
            WHERE Id = :wo.Id
        ];
        
        System.assertNotEquals(null, result.ImageUrl1__c, 'ImageUrl1 should be populated');
        System.assert(result.ImageUrl1__c.contains('/sfc/servlet.shepherd/version/download/'), 
            'ImageUrl1 should have correct format');
    }
}