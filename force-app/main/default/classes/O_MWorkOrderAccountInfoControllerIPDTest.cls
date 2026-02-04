@IsTest
private class O_MWorkOrderAccountInfoControllerIPDTest {
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
            Name = 'Test WorkType',
            EstimatedDuration = 2.5
        );
        insert testWorkType;
        
        // Create test WorkOrder
        WorkOrder testWorkOrder = new WorkOrder(
            AccountId = testAccount.Id,
            WorkTypeId = testWorkType.Id,
            Status = 'New',
            Approval_Status__c = 'Pending'
        );
        insert testWorkOrder;
        
        // Create test WorkStep
        //WorkStep testWorkStep = new WorkStep(
            //Name = 'Upload Site Document',
            //ParentRecordId = testWorkOrder.Id,
            //Status = 'Not Started'
        //);
       // insert testWorkStep;
        
        // Create another WorkStep for CO Execution Detail
        //WorkStep testWorkStep2 = new WorkStep(
            //Name = 'CO Execution Detail',
            //ParentRecordId = testWorkOrder.Id,
            //Status = 'Not Started'
        //);
       // insert testWorkStep2;
    }
    
    @IsTest
    static void testGetAccountInfoFromSA_Success() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        Map<String, Account> result = O_MWorkOrderAccountInfoControllerIPD.getAccountInfoFromSA(testWorkOrder.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('acc'), 'Result should contain account key');
        Account returnedAccount = result.get('acc');
    }
    
    @IsTest
    static void testGetAccountInfoFromSA_NullWorkOrderId() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            O_MWorkOrderAccountInfoControllerIPD.getAccountInfoFromSA(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for null WorkOrderId');
    }
    
    @IsTest
    static void testGetAccountInfoFromSA_NoAccount() {
        // Create WorkOrder without Account
        WorkType testWorkType = [SELECT Id FROM WorkType LIMIT 1];
        WorkOrder woWithoutAccount = new WorkOrder(
            WorkTypeId = testWorkType.Id,
            Status = 'New'
        );
        insert woWithoutAccount;
        
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            O_MWorkOrderAccountInfoControllerIPD.getAccountInfoFromSA(woWithoutAccount.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown when no Account is associated');
    }
    
    @IsTest
    static void testFieldPicklistValue() {
        Test.startTest();
        List<O_MWorkOrderAccountInfoControllerIPD.OptionsWrapper> result = 
            O_MWorkOrderAccountInfoControllerIPD.fieldPicklistValue('Account', 'Account_Type__c');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(!result.isEmpty(), 'Picklist values should be returned');
    }
    
    @IsTest
    static void testSaveImage_Success() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        // Prepare test data
        List<O_MWorkOrderAccountInfoControllerIPD.FileWrapper> files = new List<O_MWorkOrderAccountInfoControllerIPD.FileWrapper>();
        O_MWorkOrderAccountInfoControllerIPD.FileWrapper fw = new O_MWorkOrderAccountInfoControllerIPD.FileWrapper();
        fw.base64Data = 'testBase64Data';
        fw.fileName = 'testFile';
        fw.label = 'Test Label';
        files.add(fw);
        
        Test.startTest();
        O_MWorkOrderAccountInfoControllerIPD.saveImage(
            files, 
            testWorkOrder.Id, 
            'Customer Not Available', 
            'Test Remark', 
            'Test RM Closer Remark'
        );
        Test.stopTest();
        
        // Verify WorkOrder updates
        WorkOrder updatedWO = [SELECT Reason_for_Unavailability__c, Reason_Other_Remark__c, RM_Closer_Remark__c 
                              FROM WorkOrder WHERE Id = :testWorkOrder.Id];
        System.assertEquals('Customer Not Available', updatedWO.Reason_for_Unavailability__c, 'Reason should be updated');
        System.assertEquals('Test Remark', updatedWO.Reason_Other_Remark__c, 'Remark should be updated');
        System.assertEquals('Test RM Closer Remark', updatedWO.RM_Closer_Remark__c, 'RM Closer Remark should be updated');
        
        // Verify ContentVersion was created
        List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion WHERE FirstPublishLocationId = :testWorkOrder.Id];
       // System.assertEquals(1, contentVersions.size(), 'ContentVersion should be created');
       // System.assertEquals('Test Label', contentVersions[0].Title, 'ContentVersion title should match');
        
        // Verify WorkStep was updated
       // WorkStep updatedStep = [SELECT Status FROM WorkStep WHERE ParentRecordId = :testWorkOrder.Id AND Name = 'CO Execution Detail'];
       // System.assertEquals('Completed', updatedStep.Status, 'WorkStep status should be updated to Completed');
    }
    
    @IsTest
    static void testSaveImage_Exception() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            O_MWorkOrderAccountInfoControllerIPD.saveImage(null, null, null, null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Exception should be thrown for invalid parameters');
    }
    
    @IsTest
    static void testGetWOrderWType_Success() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        String result = O_MWorkOrderAccountInfoControllerIPD.getWOrderWType(testWorkOrder.Id);
        Test.stopTest();
        
        System.assertEquals('Test WorkType', result, 'WorkType name should match');
    }
    
    @IsTest
    static void testGetWOrderWType_Error() {
        Test.startTest();
        String result = O_MWorkOrderAccountInfoControllerIPD.getWOrderWType(null);
        Test.stopTest();
        
        System.assertEquals('Error', result, 'Should return Error for invalid input');
    }
    
    @IsTest
    static void testCheckWorkStep_Success() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        String result = O_MWorkOrderAccountInfoControllerIPD.checkWorkStep(testWorkOrder.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCheckWorkStep_Error() {
        Test.startTest();
        String result = O_MWorkOrderAccountInfoControllerIPD.checkWorkStep(null);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testWoApprovalStatus_Success() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        String result = O_MWorkOrderAccountInfoControllerIPD.woApprovalStatus(testWorkOrder.Id);
        Test.stopTest();
        
        System.assertEquals('Pending', result, 'Approval status should match');
    }
    
    @IsTest
    static void testWoApprovalStatus_Error() {
        Test.startTest();
        String result = O_MWorkOrderAccountInfoControllerIPD.woApprovalStatus(null);
        Test.stopTest();
        
        System.assertEquals('Error', result, 'Should return Error for invalid input');
    }
    
    @IsTest
    static void testUpdateWorkStepStatus() {
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        Test.startTest();
        O_MWorkOrderAccountInfoControllerIPD.updateWorkStepStatus(testWorkOrder.Id, 'Upload Site Document');
        Test.stopTest();
        
        //WorkStep updatedStep = [SELECT Status FROM WorkStep WHERE ParentRecordId = :testWorkOrder.Id AND Name = 'Upload Site Document'];
        //System.assertEquals('Completed', updatedStep.Status, 'WorkStep status should be updated to Completed');
    }
}