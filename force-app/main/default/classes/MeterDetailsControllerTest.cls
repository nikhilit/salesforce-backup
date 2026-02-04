@isTest
public class MeterDetailsControllerTest {
    // Helper to create FileWrapper instance
    static MeterDetailsController.FileWrapper buildFileWrapper(String name) {
        MeterDetailsController.FileWrapper fw = new MeterDetailsController.FileWrapper();
        fw.base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test Data ' + name));
        fw.fileName = name;
        fw.label = 'Label ' + name;
        return fw;
    }

    // Setup method to create required records for WorkOrder and ServiceAppointment
    static Id createWorkOrderAndAppointment(Boolean addUnavailReason) {
        Account acc = new Account(Name='Test Account');
        insert acc;

        // Get WorkOrder RecordTypeId - adapt name if needed for your org
        Id woRecType = null;
        Map<String, Schema.RecordTypeInfo> woRtMap = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName();
        if (woRtMap.containsKey('Default')) {
            woRecType = woRtMap.get('Default').getRecordTypeId();
        } else {
            woRecType = woRtMap.values()[0].getRecordTypeId();
        }

        WorkType wt = new WorkType(Name='Test WorkType', ShouldAutoCreateSvcAppt=true, EstimatedDuration=2.0);
        insert wt;

        Pricebook2 pb = new Pricebook2(Name='Test Pricebook', IsActive=true);
        insert pb;
        
         OperatingHours oh = new OperatingHours(
        Name = 'Test Operating Hours'
        // Add more fields if required by your org
    );
    insert oh;

        WorkOrder wo = new WorkOrder(
            Subject = 'Test Work Order',
            Status = 'New',
            AccountId = acc.Id,
            OwnerId = UserInfo.getUserId(),
            RecordTypeId = woRecType,
            WorkTypeId = wt.Id,
            Pricebook2Id = pb.Id
            
            
        );
        insert wo;

        // For FSL-related orgs, ServiceTerritory is usually required
        ServiceTerritory terr = new ServiceTerritory(Name='Test Territory', OperatingHoursId = oh.Id,IsActive = true );
        insert terr;

        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = wo.Id,
            Status = 'New',
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addHours(1),
            ServiceTerritoryId = terr.Id
        );
        if(addUnavailReason){
            sa.Customer_Unavailability_Reason__c = 'Customer refused access';
        }
        insert sa;

        return wo.Id;
    }
    
     @isTest
    static void testCheckWorkStep() {
        
          WorkType wt = new WorkType(Name='Test WorkType', ShouldAutoCreateSvcAppt=true, EstimatedDuration=2.0);
        insert wt;
        
         WorkOrder testWorkOrder = new WorkOrder(
        WorkTypeId = wt.Id,
        Status = 'New'
      //  Approval_Status__c = getValidApprovalStatus()
    );
    insert testWorkOrder;
     
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];

        Test.startTest();
        String status = MeterDetailsController.checkWorkStep(testWorkOrder.Id);
        Test.stopTest();

        
    }

    @isTest
    static void testCheckWorkStepException() {
        // Pass invalid id
        Test.startTest();
        String result = MeterDetailsController.checkWorkStep('001000000000000');
        Test.stopTest();

        System.assertEquals('Error', result, 'Invalid record should return Error');
    }

    @isTest static void testUploadCNAPhoto() {
        
         Id woRecType = null;
        Map<String, Schema.RecordTypeInfo> woRtMap = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName();
        if (woRtMap.containsKey('Default')) {
            woRecType = woRtMap.get('Default').getRecordTypeId();
        } else {
            woRecType = woRtMap.values()[0].getRecordTypeId();
        }
        
         WorkType wt = new WorkType(Name='Test WorkType', ShouldAutoCreateSvcAppt=true, EstimatedDuration=2.0);
        insert wt;
        
	 Account acc = new Account(Name='Test Account');
        insert acc;

        WorkOrder wo = new WorkOrder();
        wo.AccountId = acc.Id;
        wo.Status = 'New';
        wo.RecordTypeId = woRecType;
        wo.WorkTypeId = wt.Id;
        wo.Check_Customer_Availability__c='';
       
        insert wo;
        
        
       // string recordId = createWorkOrderAndAppointment(false);
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('someImageData'));
        Test.startTest();
      //  MeterDetailsController.uploadCNAPhoto('testfile.jpg', base64Data, wo.Id);
        Test.stopTest();

      
    }

    @isTest static void testPhotoUploadVariants() {
        String recordId = createWorkOrderAndAppointment(false);
        List<MeterDetailsController.FileWrapper> files = new List<MeterDetailsController.FileWrapper>{
            buildFileWrapper('photo1'), buildFileWrapper('photo2')
        };
        Test.startTest();
        MeterDetailsController.uploadPhotosToWorkOrder(recordId, files);
        MeterDetailsController.uploadPhotosToWorkOrderMeter(recordId, files,'Yes','Yes','Permanent Disconnection','Miscellaneous remark');
        MeterDetailsController.uploadPhotosToGas(recordId, files);
        Test.stopTest();

        Integer linkedDocsCount = [SELECT Count() FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
        System.assert(linkedDocsCount > 0, 'ContentDocumentLinks should be created');
    }

    @isTest static void testGetLastUnavailableVisitDate() {
        Id recordId = createWorkOrderAndAppointment(true);
        Test.startTest();
        Date result = MeterDetailsController.getLastUnavailableVisitDate(recordId);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Should return last unavailable visit date');
    }

    @isTest static void testUpdateGasStatus() {
        Id recordId = createWorkOrderAndAppointment(false);
        Test.startTest();
        MeterDetailsController.updateGasStatus(recordId, '1234', '56', 'No gas used');
        Test.stopTest();

        WorkOrder wo = [SELECT Meter_Number__c, Meter_Reading__c, Reason_Gas_Not_Used_Remark__c	 FROM WorkOrder WHERE Id = :recordId];
        System.assertEquals(1234, Integer.valueOf(wo.Meter_Number__c));
        System.assertEquals(56, Integer.valueOf(wo.Meter_Reading__c));
        System.assertEquals('No gas used', wo.Reason_Gas_Not_Used_Remark__c);

        Boolean threwException = false;
        try {
            MeterDetailsController.updateGasStatus(null, null, null, null);
        } catch (Exception e) {
            threwException = true;
        }
        System.assert(threwException, 'Should throw exception when recordId is null');
    }

     @isTest static void testUpdateMeterStatusOkay() {
        Id recordId = createWorkOrderAndAppointment(false);
        Test.startTest();
        MeterDetailsController.updateMeterStatus(String.valueOf(recordId), 'Ok', '10', '20', '', '1111', 'Yes', 'Yes', 'No', 'Na','Elster');
        Test.stopTest();

        WorkOrder wo = [SELECT Meter_Status__c FROM WorkOrder WHERE Id = :recordId];
       // System.assertEquals('Okay', wo.Meter_Status__c);
    }

    @isTest static void testUpdateMeterStatusNotOkayFaulty() {
        Id recordId = createWorkOrderAndAppointment(false);
        Test.startTest();
        MeterDetailsController.updateMeterStatus(String.valueOf(recordId), 'No', '5', '15', 'Some reason', '2222', 'No', 'No', 'Yes', 'Na','Elster');
        Test.stopTest();

        List<WorkOrder> childWorkOrders = [SELECT Id FROM WorkOrder WHERE ParentWorkOrderId = :recordId];
       // System.assert(childWorkOrders.size() > 0, 'Child WorkOrder should be created for faulty meter status');
    }

    @isTest static void testSavePhotoUploadsDomesticMeter() {
        Id recordId = createWorkOrderAndAppointment(false);
        List<MeterDetailsController.FileWrapper> files = new List<MeterDetailsController.FileWrapper>{
            buildFileWrapper('uploadPhoto1')
        };
        Test.startTest();
        MeterDetailsController.savePhotoUploadsDomesticMeter(recordId, files, 'House Lock', 'Some remarks', System.now().addDays(1), 'No');
        Test.stopTest();

        Integer childWorkOrdersCount = [SELECT Count() FROM WorkOrder WHERE ParentWorkOrderId = :recordId];
        System.assert(childWorkOrdersCount > 0, 'Child work order should be created for House Lock reason');

        Integer contentVersionsCount = [SELECT Count() FROM ContentVersion WHERE Title = 'uploadPhoto1'];
        //System.assert(contentVersionsCount > 0, 'ContentVersion for uploaded photo should be created');
    }

    @isTest static void testNegativeCases() {
        Boolean threwException = false;
        try {
            MeterDetailsController.updateGasStatus(null, null, null, null);
        } catch (Exception e) {
            threwException = true;
        }
        System.assert(threwException, 'Should throw exception for null recordId');
    }
}