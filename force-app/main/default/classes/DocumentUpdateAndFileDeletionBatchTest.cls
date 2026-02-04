@IsTest
private class DocumentUpdateAndFileDeletionBatchTest {

    @IsTest
    static void testBatchUpdatesOnlyMatchingRecords() {
        DocumentTriggerHandler.disableUploadsInTests = true;

        List<WorkOrder> wos = new List<WorkOrder>();
        for (Integer i = 0; i < 5; i++) {
            wos.add(new WorkOrder(Subject = 'WO ' + i, Status = 'Open'));
        }
        insert wos;

        List<Document__c> shouldUpdate = new List<Document__c>();
        for (Integer i = 0; i < 5; i++) {
            shouldUpdate.add(new Document__c(
                BP_Number__c     = 'BP' + i,
                Upload_Status__c = 'Draft',
                Work_Order__c    = wos[i].Id
            ));
        }

        List<Document__c> shouldNotUpdate = new List<Document__c>();

        shouldNotUpdate.add(new Document__c(
            BP_Number__c     = 'X1',
            Upload_Status__c = 'Submitted',
            Work_Order__c    = wos[0].Id
        ));

        shouldNotUpdate.add(new Document__c(
            BP_Number__c     = null,
            Upload_Status__c = 'Draft',
            Work_Order__c    = wos[1].Id
        ));

        insert shouldUpdate;
        insert shouldNotUpdate;

        Test.startTest();
        Database.executeBatch(new DocumentUpdateAndFileDeletionBatch(), 200);
        Test.stopTest();

        List<Document__c> updated = [SELECT Id, Upload_Status__c FROM Document__c WHERE Id IN :shouldUpdate];
        for (Document__c d : updated) {
            System.assertEquals('Pending', d.Upload_Status__c, 'Draft doc should be updated to Pending');
        }

        List<Document__c> skipped = [SELECT Id, Upload_Status__c FROM Document__c WHERE Id IN :shouldNotUpdate];
        System.assertEquals('Submitted', skipped[0].Upload_Status__c, 'Submitted doc should remain unchanged');
        System.assertEquals('Draft',     skipped[1].Upload_Status__c, 'Doc with null BP should remain Draft');
    }
}