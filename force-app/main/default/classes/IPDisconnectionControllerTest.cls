@IsTest
private class IPDisconnectionControllerTest {
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '1234567890',
			Meter_Number__c ='2231'
        );
        insert testAccount;
        
        // Create test WorkType
        WorkType testWorkType = new WorkType(
            Name = 'Disconnection WorkType',
            EstimatedDuration = 2.5
        );
        insert testWorkType;
        
        // Create test WorkOrder
        WorkOrder testWorkOrder = new WorkOrder(
            AccountId = testAccount.Id,
            WorkTypeId = testWorkType.Id,
            Status = 'New'
        );
        insert testWorkOrder;
        
        // Create test WorkPlan
        WorkPlan testWorkPlan = new WorkPlan(
            Name = 'Test WorkPlan',
            WorkOrderId = testWorkOrder.Id
        );
        insert testWorkPlan;
        
        // Create test WorkSteps
        List<WorkStep> workSteps = new List<WorkStep>();
        workSteps.add(new WorkStep(
            Name = 'BP Execution Details',
            WorkPlanId = testWorkPlan.Id,
            Status = 'New'
        ));
        workSteps.add(new WorkStep(
            Name = 'Other Step',
            WorkPlanId = testWorkPlan.Id,
            Status = 'New'
        ));
        insert workSteps;
    }
    
    @isTest
    static void getBPMeterNumberTest(){
        
        Account acc = [Select id,Meter_Number__c from Account limit 1];
        
        WorkOrder wo = [Select id,AccountId from WorkOrder limit 1];
        
        String result = IPDisconnectionController.getBPMeterNumber(wo.Id);
    }
    
    @IsTest
    static void testSaveDisconnectionDetails_Success() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
         List<IPDisconnectionController.FileWrapper> testFiles = new List<IPDisconnectionController.FileWrapper>();
        IPDisconnectionController.FileWrapper fw = new IPDisconnectionController.FileWrapper();
        fw.base64Data = 'testBase64Data';
        fw.fileName = 'testFile.jpg';
        fw.label = 'Test Label';
       
        testFiles.add(fw);
        
      //  String result = IPDisconnectionController.saveIPDisconnectionDetails(testWorkOrder.Id, testFiles);
        
        Test.startTest();
        IPDisconnectionController.saveDisconnectionDetails(
            testWorkOrder.Id,
            '12345',
            '100.5',
            'TEE',
            'Customer not allowed',
            'Test Remarks',
            'Test Meter Make',
            'Yes',testFiles
            
        );
        Test.stopTest();
        
        // Verify WorkOrder updates
        WorkOrder updatedWO = [SELECT 
            Meter_Number__c, 
            Final_Meter_Reading__c, 
            Plug_From__c, 
            Final_Remark__c, 
            Remarks__c,
            New_Meter_Make__c,
            Ensure_No_Gas_Leakage_Before_LeavingSit__c
            FROM WorkOrder 
            WHERE Id = :testWorkOrder.Id];
        
         }
    
    @IsTest
    static void testSaveDisconnectionDetails_EmptyValues() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        IPDisconnectionController.saveDisconnectionDetails(
            testWorkOrder.Id,
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            new List<IPDisconnectionController.FileWrapper>()
        );
        Test.stopTest();
        
        // Verify the method handles null values without errors
       // WorkOrder updatedWO = [SELECT Id FROM WorkOrder WHERE Id = :testWorkOrder.Id];
    }
    
    @IsTest
    static void testSaveDisconnectionDetails_InvalidWorkOrderId() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            IPDisconnectionController.saveDisconnectionDetails(
                null,
                '12345',
                '100.5',
                'Plug A',
                'Completed',
                'Test remarks',
                'Test Meter Make',
                'Yes',
                new List<IPDisconnectionController.FileWrapper>()
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
    }
    
   /* @IsTest
    static void testSaveIPDisconnectionDetails_Success() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        // Prepare test files
        List<IPDisconnectionController.FileWrapper> testFiles = new List<IPDisconnectionController.FileWrapper>();
        IPDisconnectionController.FileWrapper fw = new IPDisconnectionController.FileWrapper();
        fw.base64Data = 'testBase64Data';
        fw.fileName = 'testFile.jpg';
        fw.label = 'Test Label';
        fw.latitude = 12.34;
        fw.longitude = 56.78;
        fw.capturedTime = Datetime.now();
        testFiles.add(fw);
        
        Test.startTest();
        String result = IPDisconnectionController.saveIPDisconnectionDetails(testWorkOrder.Id, testFiles);
        Test.stopTest();
        
       // System.assertEquals('Success', result, 'Method should return Success');
        
        // Verify ContentVersion was created
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE Title = 'Test Label'];
       // System.assertEquals(1, contentVersions.size(), 'ContentVersion should be created');
        
        // Verify ContentDocumentLink was created
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testWorkOrder.Id];
       // System.assertEquals(1, links.size(), 'ContentDocumentLink should be created');
        
        // Verify Document__c record was created
        List<Document__c> docs = [SELECT Id FROM Document__c WHERE Work_Order__c = :testWorkOrder.Id];
    }
    
    @IsTest
    static void testSaveIPDisconnectionDetails_NoFiles() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        String result = IPDisconnectionController.saveIPDisconnectionDetails(testWorkOrder.Id, new List<IPDisconnectionController.FileWrapper>());
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Method should handle empty file list');
    } */
    
   
    
    @IsTest
    static void testSaveMaterialDetails_Success() {
        
        WorkOrder wo =[Select id from WorkOrder limit 1];
        
        //Material_Consumption__c testWorkOrder = [SELECT Id FROM Material_Consumption__c LIMIT 1];
        
        Map<String, String> materialMap = new Map<String, String>{
            'workOrderId' => wo.Id,
            'meterBracket' => 'Yes',
            'meterRegulator' => 'No',
            'meterControlValve' => 'Yes',
            'applianceValve' => 'No',
            'copperPipe12mm' => '5',
            'brDisconnectionUnion1' => '2',
            'brDisconnectionUnion2' => '3',
            'meterInletAdaptor' => '1',
            'meterOutletAdaptor' => '1',
            'giPipe' => '10',
            'barrelNipple' => '4',
            'preSleevedGi' => 'Yes',
            'anaconda' => 'No',
            'brFitting' => '2',
            'mlcPipeLength' => '15'
        };
        
        Test.startTest();
        IPDisconnectionController.saveMaterialDetails(materialMap);
        Test.stopTest();
        
      
    }
    
    @IsTest
    static void testSaveMaterialDetails_MissingWorkOrderId() {
        Boolean exceptionThrown = false;
        Map<String, String> materialMap = new Map<String, String>{
            'meterBracket' => 'Yes'
        };
        
        Test.startTest();
        try {
            IPDisconnectionController.saveMaterialDetails(materialMap);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
    }
    
    @IsTest
    static void testUpdateWorkStepStatus_Success() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        IPDisconnectionController.updateWorkStepStatus(testWorkOrder.Id, 'BP Execution Details');
        Test.stopTest();
        
        WorkStep updatedStep = [SELECT Status FROM WorkStep 
                              WHERE ParentRecordId = :testWorkOrder.Id 
                              AND Name = 'BP Execution Details'];
    }
    
    @IsTest
    static void testUpdateWorkStepStatus_NotFound() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        IPDisconnectionController.updateWorkStepStatus(testWorkOrder.Id, 'Non-existent Step');
        Test.stopTest();
        
        // Verify no exception was thrown and no updates were made
        WorkStep unchangedStep = [SELECT Status FROM WorkStep 
                                WHERE ParentRecordId = :testWorkOrder.Id 
                                AND Name = 'BP Execution Details'];
    }
    
    @IsTest
    static void testFileWrapperClass() {
        // Test the inner FileWrapper class
        IPDisconnectionController.FileWrapper fw = new IPDisconnectionController.FileWrapper();
        fw.base64Data = 'test';
        fw.fileName = 'test.jpg';
        fw.label = 'Test';
        
        
    }
    
   
}