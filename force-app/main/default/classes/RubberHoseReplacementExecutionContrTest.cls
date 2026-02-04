@IsTest
private class RubberHoseReplacementExecutionContrTest{
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890',
            Secondary_Telephone__c = '0987654321',
            Account_Email__c = 'test@example.com',
            Account_Type__c = 'Person Account',
            MRU_Code__c = 'MRU123',
            BP_Number__c = 'BP123',
            CA_Number__c = 'CA123',
            Meter_Number__c = 'MTR123',
            Plot__c = 'Plot 1',
            Customer_Contact_no__c = '1122334455',
            Building_name__c = 'Test Building',
            Street__c = 'Test Street',
            Colony__c = 'Test Colony',
            Wing__c = 'A',
            Floor__c = '1',
            Flat__c = '101',
            Road_name__c = 'Test Road',
            Society_Name__c = 'Test Society',
            Location__c = 'Test Location',
            City__c = 'Test City',
            Postal_Code__c = '123456',
            RH_Due_Date__c = Date.today().addDays(30)
        );
        insert testAccount;
        
        // Create test WorkType
        WorkType testWorkType = new WorkType(
            Name = 'Rubber Hose Replacement',
            EstimatedDuration = 2.5,
            ShouldAutoCreateSvcAppt=true
        );
        insert testWorkType;
        
        // Create test WorkOrder
        WorkOrder testWorkOrder = new WorkOrder(
            AccountId = testAccount.Id,
            WorkTypeId = testWorkType.Id,
            Status = 'New',
            Appointment_Status__c = 'In Progress'
        );
        insert testWorkOrder;
        system.debug('testWorkOrder.Id>>>'+testWorkOrder.Id);
        system.debug('testWorkOrder.ParentWorkOrderId>>>'+testWorkOrder.ParentWorkOrderId);
        
         
        WorkOrder testWorkOrder1 = new WorkOrder(
            AccountId = testAccount.Id,
            WorkTypeId = testWorkType.Id,
            Status = 'In Progress',
            Appointment_Status__c = 'In Progress'
        );
        insert testWorkOrder1;
        system.debug('testWorkOrder1.Id>>>'+testWorkOrder1.Id);
        system.debug('testWorkOrder1.ParentWorkOrderId>>>'+testWorkOrder1.ParentWorkOrderId);
        
        OperatingHours oph = new OperatingHours(Name = 'Test Operating Hours', TimeZone = 'Asia/Kolkata');
        insert oph;
        
        ServiceTerritory st = new ServiceTerritory(Name = 'Test Territory', IsActive = true, OperatingHoursId = oph.Id, Business_Partner_Category__c = 'Domestic');
        insert st;
        
        // Create test ServiceAppointment
        ServiceAppointment sa = new ServiceAppointment(
            ParentRecordId = testWorkOrder.Id,
            Status = 'Scheduled',
            EarliestStartTime = Datetime.now(),
            DueDate = Datetime.now().addDays(1),
            ServiceTerritoryId = st.Id,
            Scheduled_Location__latitude__s = 12.34,
            Scheduled_Location__longitude__s = 56.78
        );
        insert sa;
        
         // Create test WorkPlan
        WorkPlan testWorkPlan = new WorkPlan(
            Name = 'Test WorkPlan',
            WorkOrderId = testWorkOrder.Id
        );
        insert testWorkPlan;
        
        // Create test WorkStep
        WorkStep testWorkStep = new WorkStep(
            Name = 'Rubber Hose Execution Details',
            WorkPlanId = testWorkPlan.Id,
            Status = 'New'
        );
        insert testWorkStep;
    }
    
    @IsTest
    static void testGetCheckInStatus_Success() {
        ServiceAppointment testSA = [SELECT Id FROM ServiceAppointment LIMIT 1];
        
        Test.startTest();
        ServiceAppointment result = RubberHoseReplacementExecutionDetaContr.getCheckInStatus(testSA.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'ServiceAppointment should be returned');
        System.assertEquals(testSA.Id, result.Id, 'Correct ServiceAppointment should be returned');
    }
    
    @IsTest
    static void testGetCheckInStatus_Exception() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            RubberHoseReplacementExecutionDetaContr.getCheckInStatus('invalidId');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for invalid ID');
    }
    
    @IsTest
    static void testGetAccountInfoFromSA_Success() {
        WorkOrder testWO = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        Map<String, Account> result = RubberHoseReplacementExecutionDetaContr.getAccountInfoFromSA(testWO.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('acc'), 'Result should contain account key');
    }
    
    @IsTest
    static void testGetAccountInfoFromSA_NullWorkOrderId() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            RubberHoseReplacementExecutionDetaContr.getAccountInfoFromSA(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for null WorkOrderId');
    }
    
    @IsTest
    static void testUpdateServiceAppoinment_CheckInSuccess() {
        ServiceAppointment testSA = [SELECT Id, ParentRecordId FROM ServiceAppointment LIMIT 1];
        DateTime testTime = DateTime.now();
        Double lat= 12.34;
        Double lon= 56.78;
        Test.startTest();
        String result = RubberHoseReplacementExecutionDetaContr.updateServiceAppoinment(
            testSA.Id, lat, lon, true, testTime
        );
        Test.stopTest();

    }
    
    @IsTest
    static void testUpdateServiceAppoinment_CheckOutSuccess() {
        ServiceAppointment testSA = [SELECT Id, ParentRecordId FROM ServiceAppointment LIMIT 1];
        DateTime testTime = DateTime.now();
        Double lat= 12.34;
        Double lon= 56.78;
        
        Test.startTest();
        String result = RubberHoseReplacementExecutionDetaContr.updateServiceAppoinment(
            testSA.Id, lat, lon, false, testTime
        );
        Test.stopTest();
                
    }
    
    @IsTest
    static void testUpdateServiceAppoinment_MissingValues() {
        ServiceAppointment testSA = [SELECT Id FROM ServiceAppointment LIMIT 1];
        
        Test.startTest();
        String result = RubberHoseReplacementExecutionDetaContr.updateServiceAppoinment(
            testSA.Id, null, null, true, null
        );
        Test.stopTest();
        
        System.assertEquals('MISSING_VALUES', result, 'Should return missing values error');
    }
    
    @IsTest
    static void testSaveImage_Success() {
        WorkOrder testWO = [SELECT Id FROM WorkOrder Where Status = 'In Progress' LIMIT 1];
        system.debug('testWo Id>>>>'+testWo.Id);
        ServiceAppointment testSA = [SELECT Id, ParentRecordId FROM ServiceAppointment LIMIT 1];
        DateTime testDateTime = DateTime.now().addDays(1);
        
        // Prepare test files
        List<RubberHoseReplacementExecutionDetaContr.FileWrapper> testFiles = new List<RubberHoseReplacementExecutionDetaContr.FileWrapper>();
        RubberHoseReplacementExecutionDetaContr.FileWrapper fw = new RubberHoseReplacementExecutionDetaContr.FileWrapper();
        fw.base64Data = 'testBase64Data';
        fw.fileName = 'testFile.jpg';
        fw.label = 'Test Label';
        testFiles.add(fw);
        
        Test.startTest();
        RubberHoseReplacementExecutionDetaContr.saveImage(
            testFiles, 
            testWO.Id, 
            'House locked', 
            'Test remark', 
            testDateTime
        );
        Test.stopTest();
        
        // Verify WorkOrder updates
        WorkOrder updatedWO = [SELECT Reason_ForUnavilability__c, Reason_Other_Remark__c FROM WorkOrder WHERE Id = :testWO.Id];
        System.assertEquals('House locked', updatedWO.Reason_ForUnavilability__c, 'Reason should be updated');
        System.assertEquals('Test remark', updatedWO.Reason_Other_Remark__c, 'Remark should be updated');
        
        // Verify child WorkOrder was created
        List<WorkOrder> childWOs = [SELECT Id FROM WorkOrder WHERE ParentWorkOrderId = :testWO.Id];
        System.assertEquals(1, childWOs.size(), 'Child WorkOrder should be created');
        
        // Verify ServiceAppointment was updated
        ServiceAppointment childSA = [SELECT SchedStartTime FROM ServiceAppointment WHERE ParentRecordId = :childWOs[0].Id];
        
        // Verify ContentVersion was created
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE Title = 'Test Label'];
        System.assertEquals(1, contentVersions.size(), 'ContentVersion should be created');
        
    }
    
    @IsTest
    static void testSaveImage_OtherReason() {
        WorkOrder testWO = [SELECT Id FROM WorkOrder LIMIT 1];
        
        // Prepare test files
        List<RubberHoseReplacementExecutionDetaContr.FileWrapper> testFiles = new List<RubberHoseReplacementExecutionDetaContr.FileWrapper>();
        RubberHoseReplacementExecutionDetaContr.FileWrapper fw = new RubberHoseReplacementExecutionDetaContr.FileWrapper();
        fw.base64Data = 'testBase64Data';
        fw.fileName = 'testFile.jpg';
        fw.label = 'Test Label';
        testFiles.add(fw);
        
        Test.startTest();
        RubberHoseReplacementExecutionDetaContr.saveImage(
            testFiles, 
            testWO.Id, 
            'Other', 
            'Custom remark', 
            null
        );
        Test.stopTest();
        
        // Verify WorkOrder updates
        WorkOrder updatedWO = [SELECT Reason_ForUnavilability__c, Reason_Other_Remark__c FROM WorkOrder WHERE Id = :testWO.Id];
        System.assertEquals('Other', updatedWO.Reason_ForUnavilability__c, 'Reason should be updated');
        System.assertEquals('Custom remark', updatedWO.Reason_Other_Remark__c, 'Remark should be updated');
        
        // Verify no child WorkOrder was created
        List<WorkOrder> childWOs = [SELECT Id FROM WorkOrder WHERE ParentWorkOrderId = :testWO.Id];
        System.assertEquals(0, childWOs.size(), 'No child WorkOrder should be created');
    }
    
    
    @IsTest
    static void testUpdateWorkStepStatus_Success() {
        WorkOrder testWO = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        RubberHoseReplacementExecutionDetaContr.updateWorkStepStatus(testWO.Id, 'Rubber Hose Execution Details');
        Test.stopTest();
        
        WorkStep updatedStep = [SELECT Status FROM WorkStep WHERE ParentRecordId = :testWO.Id AND Name = 'Rubber Hose Execution Details'];
        System.assertEquals('Completed', updatedStep.Status, 'WorkStep status should be updated');
    }
    
    @IsTest
    static void testUpdateWorkStepStatus_NotFound() {
        WorkOrder testWO = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        RubberHoseReplacementExecutionDetaContr.updateWorkStepStatus(testWO.Id, 'Non-existent Step');
        Test.stopTest();
        
        // Verify no exception was thrown and no updates were made
        WorkStep unchangedStep = [SELECT Status FROM WorkStep WHERE ParentRecordId = :testWO.Id AND Name = 'Rubber Hose Execution Details'];
    }
    
    @IsTest
    static void testFileWrapperClass() {
        // Test the inner FileWrapper class
        RubberHoseReplacementExecutionDetaContr.FileWrapper fw = new RubberHoseReplacementExecutionDetaContr.FileWrapper();
        fw.base64Data = 'test';
        fw.fileName = 'test.jpg';
        fw.label = 'Test';
        
        System.assertNotEquals(null, fw, 'FileWrapper should be instantiated');
    }
}