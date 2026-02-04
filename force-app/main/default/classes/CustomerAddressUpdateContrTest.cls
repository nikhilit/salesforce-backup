@isTest
private class CustomerAddressUpdateContrTest {
    
    @testSetup
    static void setupTestData() {
        String gsRecordTypeID = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        // Create an Account
        Account acc = new Account(
            RecordTypeId=gsRecordTypeID,
            Account_Classification__c ='Person Account',
            Category__c ='Domestic',
            LastName = 'Test Account',
            Flat__c = '101',
            Floor__c = '10',
            Wing__c = 'A',
            Plot__c = 'P1',
            Colony__c = 'Test Colony',
            Road_name__c = 'Test Road',
            Location__c = 'Test Location',
            Building_name__c = 'Test Building',
            Society_Name__c = 'Test Society',
            FirstName__c = 'John',
            LastName__c = 'Doe',
            BP_Number__c = 'BP123'
        );
        insert acc;
        
        String wogsRecordTypeID = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName().get('MGL_Metering').getRecordTypeId();
        // Create WorkOrder linked to Account
        WorkOrder wo = new WorkOrder(
            Subject = 'Test WO',
            Status = 'New',
            RecordTypeId =wogsRecordTypeID,
            AccountId = acc.Id
        );
        insert wo;
        
        // Create ContentVersion for getContentVersion test
        ContentVersion cv = new ContentVersion(
            Title = 'Test Doc',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test content'),
            Document_Type__c = 'Other'
        );
        insert cv;
    }
    
    @isTest
    static void testGetBusinessPartner_found() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Account result = CustomerAddressUpdateContr.getBusinessPartner(wo.Id);
        System.assertNotEquals(null, result, 'Should return Account when WO exists');
        System.assertEquals('101', result.Flat__c, 'Account field should match setup');
    }
    
    @isTest
    static void testGetContentVersion() {
        List<ContentVersion> cvs = CustomerAddressUpdateContr.getContentVersion();
        System.assert(!cvs.isEmpty(), 'Should return ContentVersions');

    }
    
    @isTest
    static void testFieldPicklistValue() {
        List<CustomerAddressUpdateContr.OptionsWrapper> opts = 
            CustomerAddressUpdateContr.fieldPicklistValue('WorkOrder', 'Status');
        System.assert(!opts.isEmpty(), 'Picklist options should be returned');
        System.assertNotEquals(null, opts[0].label, 'Label should be populated');
    }
    
    @isTest
    static void testUploadFiles_success() {
        WorkOrder wo = [SELECT Id,AccountId FROM WorkOrder LIMIT 1];
        
        List<String> fileNames = new List<String>{ 'testfile.txt' };
        List<String> fileData = new List<String>{ EncodingUtil.base64Encode(Blob.valueOf('Test content')) };
        
        Test.startTest();
        String result = CustomerAddressUpdateContr.uploadFiles(
            wo.AccountId, fileNames, fileData,
            '201', '2', 'B', 'P2', 'Colony2', 'Road2', 'Location2', 'Building2', 'Society2',
            'Jane Doe', 'BP999', 'Remark test', wo.Id
        );
        Test.stopTest();
        
        System.assertEquals('success', result, 'Should return success when files are uploaded');
        
        // Verify WorkOrder updated
        WorkOrder updatedWO = [SELECT New_Flat__c, Update_Address_Remark__c FROM WorkOrder WHERE Id = :wo.Id];
        System.assertEquals('201', updatedWO.New_Flat__c);
        System.assertEquals('Remark test', updatedWO.Update_Address_Remark__c);
    }
    
    @isTest
    static void testUploadFiles_error() {
        // Call with empty file list to trigger error return
        WorkOrder wo = [SELECT Id, AccountId FROM WorkOrder LIMIT 1];
        Test.startTest();
        String result = CustomerAddressUpdateContr.uploadFiles(
            wo.AccountId, new List<String>(), new List<String>(),
            '', '', '', '', '', '', '', '', '', '', '', '', wo.Id
        );
        Test.stopTest();
        System.assertEquals('error', result, 'Should return error if no files are uploaded');
    }
    
    @isTest
    static void testUpdateWorkStepStatus() {
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Test.startTest();
        CustomerAddressUpdateContr.updateWorkStepStatus(wo.Id, Label.Update_Customer_Address_Step_Name);
        Test.stopTest();
        
    }
}