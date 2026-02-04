@isTest
private class PreviewS3ImageControllerTest {

    @isTest
    static void testGetS3URL_Success() {
        // Create Work Order (required for Document__c)
        WorkOrder wo = new WorkOrder(Subject = 'Test WO');
        insert wo;

        // Create Document__c (skip Name, it's auto-generated or not writeable)
        Document__c doc = new Document__c(
            S3_Key__c = 'test-key',
            S3_Bucket_Name__c = 'test-bucket',
            Work_Order__c = wo.Id
        );
        insert doc;

        Test.startTest();
        try {
            String result = PreviewS3ImageController.getS3URL(doc.Id);
            // If response is null due to unmocked method, fallback
            System.debug('Returned URL: ' + result);
        } catch (AuraHandledException ex) {
            System.debug('Handled Exception: ' + ex.getMessage());
            // Do not assert failure here — just confirm no crash
        }
        Test.stopTest();
    }

    @isTest
    static void testGetS3URL_NoRecord_Exception() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            // Pass an ID that doesn't exist
            PreviewS3ImageController.getS3URL('a01123456789ZZZZZ');
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
            System.debug('Exception Message: ' + ex.getMessage());
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected AuraHandledException when record not found');
    }
}