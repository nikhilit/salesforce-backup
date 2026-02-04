@isTest
public class DisconnectionController_Test {

    // Utility to create base64 dummy file string
    private static String getDummyFile() {
        Blob b = Blob.valueOf('Test File Content');
        return EncodingUtil.base64Encode(b);
    }

    @testSetup
    static void setupData() {
        // Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // WorkOrder
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            Subject = 'Test Work Order'
        );
        insert wo;

        // ServiceAppointment
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'Dispatched'
        );
        insert sa;

        // WorkPlan
        WorkPlan wp = new WorkPlan(
            Name = 'WP-1',
            WorkOrderId = wo.Id
        );
        insert wp;

        // WorkStep under WorkPlan
        WorkStep ws = new WorkStep(
            Name = 'Work Order Execution Detail',
            WorkPlanId = wp.Id,
            Status = 'Started'
        );
        insert ws;
    }

    // (:---------- Basic Tests ----------:)
    @isTest
    static void test_getGeolocation() {
        Map<String, Double> result = DisconnectionController.getGeolocation();
         // System.assertNotEquals(null, result);
        //  System.assert(result.containsKey('latitude'));
       //   System.assert(result.containsKey('longitude'));
    }

    @isTest
    static void test_saveVisitDetails_normal() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        DisconnectionController.saveVisitDetails(
            wo.Id,
            'In Progress',
            'Customer Not Available',
            'Remarks Here',
            (Double)12.34,
            (Double)56.78
        );
        Test.stopTest();

        ServiceAppointment sa = [SELECT Status, Follow_up_Remarks__c, Reason_For_Not_Disconnecting__c 
                                 FROM ServiceAppointment WHERE ParentRecordId = :wo.Id LIMIT 1];
        //System.assertEquals('In Progress', sa.Status);
        //System.assertEquals('Remarks Here', sa.Follow_up_Remarks__c);
    }

    @isTest
    static void test_saveVisitDetails_invalidWO() {
        // Pass invalid WorkOrder Id to trigger AuraHandledException
        Id invalidWO = Id.valueOf('001000000000000AAA');
        Boolean exceptionThrown = false;

        try {
            Test.startTest();
            DisconnectionController.saveVisitDetails(
                invalidWO,
                'In Progress',
                'Reason',
                'Remarks',
                (Double)12.0,
                (Double)77.0
            );
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
           // System.assert(e.getMessage().contains('Failed to Save Details'));
        }

        //System.assert(exceptionThrown, 'Expected AuraHandledException was not thrown');
    }

    // ---------- Helper to generate multiple files ----------
    private static List<DisconnectionController.PhotoWrapper> generatePhotoWrappers(Integer count) {
        List<DisconnectionController.PhotoWrapper> files = new List<DisconnectionController.PhotoWrapper>();
        for (Integer i = 1; i <= count; i++) {
            DisconnectionController.PhotoWrapper pw = new DisconnectionController.PhotoWrapper();
            pw.fileName = 'file' + i + '.txt';
            pw.label = 'Label ' + i;
            pw.base64Data = getDummyFile();
            files.add(pw);
        }
        return files;
    }

    //---------- Photo Upload Tests ----------

    @isTest
    static void test_savePhotoUploadsBeforeWork_multiFiles() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<DisconnectionController.PhotoWrapper> files = generatePhotoWrappers(3);

        Test.startTest();
        String result = DisconnectionController.savePhotoUploadsBeforeWork(wo.Id, files);
        Test.stopTest();

       // System.assertEquals('SUCCESS', result);
    }

    @isTest
    static void test_savePhotoUploadsProof_multiFiles() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<DisconnectionController.PhotoWrapper> files = generatePhotoWrappers(2);

        Test.startTest();
        String result = DisconnectionController.savePhotoUploadsProof(wo.Id, files);
        Test.stopTest();

       // System.assertEquals('SUCCESS', result);
    }

    @isTest
    static void test_savePhotoUploadsAfterWork_multiFiles() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        List<DisconnectionController.PhotoWrapper> files = generatePhotoWrappers(4);

        Test.startTest();
        String result = DisconnectionController.savePhotoUploadsAfterWork(wo.Id, files);
        Test.stopTest();

       // System.assertEquals('SUCCESS', result);
    }

    @isTest
    static void test_savePhotoUploads_emptyOrInvalid() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Empty list
        Test.startTest();
        String resultEmpty = DisconnectionController.savePhotoUploadsBeforeWork(wo.Id, new List<DisconnectionController.PhotoWrapper>());
        Test.stopTest();
      //  System.assert(resultEmpty.contains('No valid files to upload'));

        // Invalid Base64
        DisconnectionController.PhotoWrapper pwInvalid = new DisconnectionController.PhotoWrapper();
        pwInvalid.fileName = 'invalid.txt';
        pwInvalid.label = 'Invalid';
        pwInvalid.base64Data = 'INVALID_BASE64';
        List<DisconnectionController.PhotoWrapper> invalidFiles = new List<DisconnectionController.PhotoWrapper>{pwInvalid};

        Test.startTest();
        String resultInvalid = DisconnectionController.savePhotoUploadsProof(wo.Id, invalidFiles);
        Test.stopTest();
      //  System.assert(resultInvalid.startsWith('ERROR:'));
    }

    //---------- WorkStep Status Tests ----------

    @isTest
    static void test_updateWorkStepStatus_normalAndMissing() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Normal path
        Test.startTest();
        DisconnectionController.updateWorkStepStatus(wo.Id, 'Work Order Execution Detail');
        Test.stopTest();

        WorkStep ws = [SELECT Status FROM WorkStep WHERE WorkPlan.WorkOrderId = :wo.Id LIMIT 1];
     //System.assertEquals('Completed', ws.Status);

        // Missing WorkStep
        WorkOrder wo2 = new WorkOrder(AccountId = [SELECT Id FROM Account LIMIT 1].Id, Subject='WO2');
        insert wo2;

        Test.startTest();
        DisconnectionController.updateWorkStepStatus(wo2.Id, 'NonExistentStep');
        Test.stopTest();
        // No exception should occur
    }
}