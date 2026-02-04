@isTest
private class WO_AttachPDFs_Queueable_Test {

    // Utility: Create ContentDocument + Version quickly
    private static Id createDummyContentDocument() {
        ContentVersion cv = new ContentVersion(
            Title = '_JT_DummyFile.pdf',
            PathOnClient = 'dummy.pdf',
            VersionData = Blob.valueOf('dummy')
        );
        insert cv;

        cv = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id
        ];

        return cv.ContentDocumentId;
    }

    @testSetup
    static void setupData() {

        Account acc = new Account(Name = 'TestAcc', BP_Number__c = '1001',Representative_Company__c ='OMC');
        insert acc;

        // WorkOrder for testing
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            AccountId = acc.Id,
            From_Date__c = Date.today(),
            To_Date__c = Date.today().addDays(1)
        );
        insert wo;

        // Create two dummy content docs that should be DELETED
        Id oldDoc1 = createDummyContentDocument();
        Id oldDoc2 = createDummyContentDocument();

        insert new ContentDocumentLink(
            LinkedEntityId = wo.Id,
            ContentDocumentId = oldDoc1,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        insert new ContentDocumentLink(
            LinkedEntityId = wo.Id,
            ContentDocumentId = oldDoc2,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
    }

    @isTest
static void testQueueableChainExecution() {

    WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

    Test.startTest();

    // Run all 3 queueables inside a single async window
    System.enqueueJob(new WO_DeleteOldPDFs_Queueable(new List<Id>{wo.Id}));
    System.enqueueJob(new WO_GeneratePDFs_Queueable(new List<Id>{wo.Id}));

    Test.stopTest(); // ALL queueables finish here
}

}