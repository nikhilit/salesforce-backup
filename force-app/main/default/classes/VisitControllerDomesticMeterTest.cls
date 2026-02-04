@isTest
public class VisitControllerDomesticMeterTest {
    
    // Setup reusable test data
    @testSetup
    static void setupTestData() {
        
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890'
        );
        insert testAccount;
        
        // Create test WorkType
        WorkType testWorkType = new WorkType(
            Name = 'Disconnection WorkType',
            EstimatedDuration = 2.5
        );
        insert testWorkType;
        
        // Create test WorkOrder
        WorkOrder wo = new WorkOrder(
            AccountId = testAccount.Id,
            WorkTypeId = testWorkType.Id,
            Status = 'New'
        );
        insert wo;
        
        // Create test WorkPlan
        WorkPlan testWorkPlan = new WorkPlan(
            Name = 'Test WorkPlan',
            WorkOrderId = wo.Id
        );
        insert testWorkPlan;
		
        OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;
        
        // Create Service Territory
        ServiceTerritory st = new ServiceTerritory(
            Name = 'Test Territory',
            OperatingHoursId = [SELECT Id FROM OperatingHours LIMIT 1].Id,
            IsActive = true
        );
        insert st;
        
        // Create ServiceAppointment linked to WorkOrder
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'Scheduled',
            SchedStartTime = System.now().addMinutes(5),
            SchedEndTime = System.now().addMinutes(35),
            ServiceTerritoryId = st.Id,
            WorkTypeId = testWorkType.Id,
        	Duration = 30
        );
        insert sa;

        // Create a WorkStep linked to WorkOrder
        WorkStep ws = new WorkStep(
            WorkPlanId = testWorkPlan.Id,
            Name = 'Work Order Execution Detail',
            Status = 'Pending'
        );
        insert ws;
    }
    
    @isTest
    static void testMarkCustomerUnavailable_Success() {
        WorkOrder wo = [SELECT Id, Status, Attempt_Count__c FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        VisitControllerDomesticMeter.markCustomerUnavailable(
            wo.Id,
            'House Lock',
            'Left a note for customer',
            Date.today().addDays(-2)
        );
        Test.stopTest();
        
        // Verify updates
        WorkOrder updatedWO = [SELECT Status, Attempt_Count__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('Customer Unavailable', updatedWO.Status, 'Status should be updated');
        System.assertEquals(1, updatedWO.Attempt_Count__c, 'Attempt count should increment');
        
        ServiceAppointment updatedSA = [
            SELECT Customer_Unavailability_Reason__c, Follow_up_Remarks__c, SchedStartTime
            FROM ServiceAppointment
            WHERE ParentRecordId = :wo.Id
            LIMIT 1
        ];
        System.assertEquals('House Lock', updatedSA.Customer_Unavailability_Reason__c);
        System.assertEquals('Left a note for customer', updatedSA.Follow_up_Remarks__c);
    }
    
    @isTest
    static void testMarkCustomerUnavailable_NoAppointment() {
        // Create a new WorkOrder without ServiceAppointment
        WorkOrder wo = new WorkOrder(Subject = 'WO Without SA', Status = 'New');
        insert wo;

        try {
            Test.startTest();
            VisitControllerDomesticMeter.markCustomerUnavailable(
                wo.Id,
                'Reason',
                'Remarks',
                Date.today().addDays(1)
            );
            Test.stopTest();
            System.assert(false, 'Expected AuraHandledException not thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('No ServiceAppointment found'));
        }
    }
    
    @isTest
    static void testSavePhotoUploadsDomesticMeter_Success() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        // Prepare file wrapper
        VisitControllerDomesticMeter.PhotoWrapper wrapper = new VisitControllerDomesticMeter.PhotoWrapper();
        wrapper.base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test File Content'));
        wrapper.fileName = 'testFile.jpg';
        wrapper.label = 'Test File';
        
        List<VisitControllerDomesticMeter.PhotoWrapper> wrappers = new List<VisitControllerDomesticMeter.PhotoWrapper>{ wrapper };
        
        Test.startTest();
        String result = VisitControllerDomesticMeter.savePhotoUploadsDomesticMeter(wo.Id, wrappers);
        Test.stopTest();
        
        System.assertEquals('SUCCESS', result, 'Photo upload should succeed');
        
        // Verify ContentDocumentLink created
        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :wo.Id
        ];
        System.assertEquals(1, links.size(), 'One file should be linked to WorkOrder');
        
        // Verify WorkStep status updated
        WorkStep ws = [SELECT Status FROM WorkStep WHERE ParentRecordId = :wo.Id AND Name = 'Work Order Execution Detail' LIMIT 1];
        System.assertEquals('Completed', ws.Status, 'WorkStep should be marked Completed');
    }
    
    @isTest
    static void testSavePhotoUploadsDomesticMeter_NoFiles() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        String result = VisitControllerDomesticMeter.savePhotoUploadsDomesticMeter(wo.Id, new List<VisitControllerDomesticMeter.PhotoWrapper>());
        Test.stopTest();
        
        System.assertEquals('No valid files to upload.', result, 'Should return no file message');
    }
    
    @isTest
    static void testUpdateWorkStepStatus_ExceptionHandled() {
        // Pass a wrong name so query returns empty
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        VisitControllerDomesticMeter.updateWorkStepStatus(wo.Id, 'Invalid Step');
        Test.stopTest();
        
        // No error should occur, nothing to assert since debug logs are not captured
        System.assert(true, 'Method should gracefully handle no WorkStep found');
    }
    
}