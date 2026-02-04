@isTest
private class WorkOrderImageBatch_Test {

    @testSetup
    static void setup() {

        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New'
        );
        insert wo;
        
        // File 1
        ContentVersion cv1 = new ContentVersion(
            Title = 'Pic1',
            PathOnClient = 'pic1.jpg',
            VersionData = Blob.valueOf('Test Image 1')
        );
        insert cv1;

        // File 2
        ContentVersion cv2 = new ContentVersion(
            Title = 'Pic2',
            PathOnClient = 'pic2.jpg',
            VersionData = Blob.valueOf('Test Image 2')
        );
        insert cv2;

        // File 3
        ContentVersion cv3 = new ContentVersion(
            Title = 'Pic3',
            PathOnClient = 'pic3.jpg',
            VersionData = Blob.valueOf('Test Image 3')
        );
        insert cv3;

        // Retrieve ContentDocument Ids
        Id cd1 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id].ContentDocumentId;
        Id cd2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv2.Id].ContentDocumentId;
        Id cd3 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv3.Id].ContentDocumentId;

        List<ContentDocumentLink> links = new List<ContentDocumentLink>{
            new ContentDocumentLink(ContentDocumentId = cd1, LinkedEntityId = wo.Id, ShareType = 'V'),
            new ContentDocumentLink(ContentDocumentId = cd2, LinkedEntityId = wo.Id, ShareType = 'V'),
            new ContentDocumentLink(ContentDocumentId = cd3, LinkedEntityId = wo.Id, ShareType = 'V')
        };
        insert links;
    }


    @isTest
    static void testBatchDefault() {
        Test.startTest();
        Database.executeBatch(new WorkOrderImageBatch(), 10);
        Test.stopTest();

    }


    @isTest
    static void testBatchWithWhere() {

        Test.startTest();
        Database.executeBatch(new WorkOrderImageBatch('WHERE Status = \'New\''), 10);
        Test.stopTest();
    }


    @isTest
    static void testImageOrder() {

        Test.startTest();
        Database.executeBatch(new WorkOrderImageBatch(), 10);
        Test.stopTest();

    }
}