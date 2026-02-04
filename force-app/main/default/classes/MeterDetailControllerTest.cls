@isTest
public class MeterDetailControllerTest {
    
    /*// Reusable base64 string (represents "Test file")
    private static final String BASE64_STRING = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));

    // Helper wrapper for savePhotoUploadsDomesticMeter
    public class FileWrapper {
        @AuraEnabled public String fileName;
        @AuraEnabled public String label;
        @AuraEnabled public String base64Data;
    }
    
    @testSetup
    static void setupData() {
        // Create Account
        Account acc = new Account(Name='Test Account');
        insert acc;

        // Create WorkType
        WorkType wt = new WorkType(Name='Test WT');
        insert wt;

        // Create Parent WorkOrder
        WorkOrder wo = new WorkOrder(
            Subject='Test WO',
            AccountId=acc.Id,
            WorkTypeId=wt.Id,
            Status='New'
        );
        insert wo;

        // Create ServiceAppointment linked to WorkOrder
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId=wo.Id,
            SchedStartTime=System.now().addDays(-5),
            SchedEndTime=System.now().addDays(-5).addHours(2),
            Customer_Unavailability_Reason__c='House Lock',
            Status='Scheduled'
        );
        insert sa;

        // Create WorkStep linked to WorkOrder
        WorkStep ws = new WorkStep(
            Name='Site Details',
            Status='Not Started'
        );
        insert ws;
    }
    
    @isTest
    static void testGetLastUnavailableVisitDate() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        Date lastDate = MeterDetailsController.getLastUnavailableVisitDate(wo.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, lastDate, 'Last unavailable visit date should not be null');
    }
    
    @isTest
    static void testUploadCNAPhoto() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        MeterDetailsController.uploadCNAPhoto(
            'TestFile.jpg',
            BASE64_STRING,
            wo.Id
        );
        Test.stopTest();
        
        // Verify ContentDocumentLink was created
        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :wo.Id
        ];
        System.assert(!links.isEmpty(), 'ContentDocumentLink should be created');
    }
    
    @isTest
    static void testSavePhotoUploadsDomesticMeter() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        // Prepare wrapper list
        List<FileWrapper> wrappers = new List<FileWrapper>();
        FileWrapper fw = new FileWrapper();
        fw.fileName = 'TestPhoto';
        fw.label = 'Label';
        fw.base64Data = BASE64_STRING;
        wrappers.add(fw);

        Test.startTest();
        MeterDetailsController.savePhotoUploadsDomesticMeter(
            wo.Id,
            wrappers,
            'House Lock', // Reason
            'Testing Remarks',
            System.now().addDays(2), // Future date for reschedule
            'No' // selectedOption
        );
        Test.stopTest();
        
        // Verify child WorkOrder created
        List<WorkOrder> childWos = [SELECT Id, ParentWorkOrderId FROM WorkOrder WHERE ParentWorkOrderId = :wo.Id];
        System.assert(!childWos.isEmpty(), 'Child WorkOrder should be created');
        
        // Verify ServiceAppointment updated
        List<ServiceAppointment> saList = [SELECT Id, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE ParentRecordId = :childWos[0].Id];
        if (!saList.isEmpty()) {
            System.assert(saList[0].SchedEndTime == saList[0].SchedStartTime.addDays(3), 'SchedEndTime should be +3 days');
        }

        // Verify WorkStep updated
        List<WorkStep> wsList = [SELECT Id, Status FROM WorkStep WHERE ParentRecordId = :wo.Id AND Name = 'Site Details'];
        System.assertEquals('Completed', wsList[0].Status, 'WorkStep status should be updated');
    }*/
}